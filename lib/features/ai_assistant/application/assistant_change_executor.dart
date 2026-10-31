import 'dart:io';

import '../../../data/database_helper.dart';
import '../../diary/data/meal_photo_store.dart';
import '../../diary/domain/models/macro_entry.dart';
import '../../diary/domain/models/meal_capture_meta.dart';
import '../../diary/domain/models/meal_entry.dart';
import '../../diary/domain/repositories/diary_repository.dart';
import '../../../features/sharing/share_link_repository.dart';
import '../domain/assistant_change_proposal.dart';

import 'package:uuid/uuid.dart';

/// Applies only a proposal that has already passed the in-app user review.
/// All payloads are decoded by the existing portable import codec first.
class AssistantChangeExecutor {
  const AssistantChangeExecutor({
    ShareLinkRepository sharing = const ShareLinkRepository(),
    this.diaryRepository,
  }) : _sharing = sharing;

  final ShareLinkRepository _sharing;
  final IDiaryRepository? diaryRepository;

  Future<void> apply(
    AssistantChangeProposal proposal, {
    List<File> mealPhotos = const [],
    String? providerId,
    String? modelId,
  }) async {
    final database = DatabaseHelper.instance.dbInstance;
    final payload = proposal.payload;
    switch (proposal.operation) {
      case AssistantChangeOperation.create:
        switch (payload.type) {
          case 'routine':
            await _sharing.importRoutine(payload);
          case 'recipe':
            await _sharing.import(payload);
          case 'plan':
            await _sharing.import(payload);
          case 'meal_entry':
            await _createMealEntry(
              proposal,
              mealPhotos: mealPhotos,
              providerId: providerId,
              modelId: modelId,
            );
          default:
            throw const FormatException('Unsupported change proposal.');
        }
      case AssistantChangeOperation.update:
        final targetId = proposal.targetId!;
        switch (payload.type) {
          case 'routine':
            final target = await (database.select(
              database.routines,
            )..where((row) => row.id.equals(targetId))).getSingleOrNull();
            if (target == null) throw StateError('Routine no longer exists.');
            await _sharing.replaceRoutine(target.localId, payload);
          case 'recipe':
            final target = await (database.select(
              database.meals,
            )..where((row) => row.id.equals(targetId))).getSingleOrNull();
            if (target == null) throw StateError('Recipe no longer exists.');
            await _sharing.replaceRecipe(target.localId, payload);
          case 'plan':
            final target = await (database.select(
              database.trainingPlans,
            )..where((row) => row.id.equals(targetId))).getSingleOrNull();
            if (target == null) throw StateError('Plan no longer exists.');
            await _sharing.replacePlan(
              target.id,
              payload,
              nextCycle: proposal.nextCycle,
            );
          default:
            throw const FormatException('Unsupported change proposal.');
        }
    }
  }

  Future<void> _createMealEntry(
    AssistantChangeProposal proposal, {
    required List<File> mealPhotos,
    required String? providerId,
    required String? modelId,
  }) async {
    final repository = diaryRepository;
    if (repository == null) {
      throw StateError('Diary storage is unavailable for meal logging.');
    }
    if (mealPhotos.length != proposal.sourceImageAttachmentIds.length) {
      throw StateError('The meal photo sources do not match the draft.');
    }
    final mealId = proposal.createdRecordId;
    if (mealId == null) {
      throw StateError('The meal draft is missing its stable record id.');
    }
    if (await repository.getMealEntryById(mealId) != null) {
      return;
    }
    final data = proposal.payload.data;
    final consumedAt = DateTime.parse(data['consumedAt'] as String);
    final mealType = data['mealType'] as String;
    final rawItems = data['items'] as List;
    final storedPhotos = <MealPhotoPaths>[];
    try {
      for (final source in mealPhotos) {
        if (!await source.exists()) {
          throw FileSystemException(
            'Meal photo is no longer available',
            source.path,
          );
        }
        final stored = await MealPhotoStore.instance.save(source);
        if (stored == null) {
          throw FileSystemException(
            'Could not persist meal photo',
            source.path,
          );
        }
        storedPhotos.add(stored);
      }

      const uuid = Uuid();
      final extraPhotoPaths = storedPhotos
          .skip(1)
          .map((photo) => photo.photoPath)
          .toList(growable: false);
      final captureMeta = MealCaptureMeta(
        provider: providerId,
        model: modelId,
        nutritionEngine: 'directEstimate',
        extraPhotoPaths: extraPhotoPaths,
      );
      final mealEntry = MealEntry(
        id: mealId,
        title: proposal.payload.name.trim(),
        consumedAt: consumedAt,
        mealType: mealType,
        source: storedPhotos.isEmpty ? 'aiText' : 'aiPhoto',
        photoPath: storedPhotos.isEmpty ? null : storedPhotos.first.photoPath,
        photoThumbPath: storedPhotos.isEmpty
            ? null
            : storedPhotos.first.thumbPath,
        captureMeta: captureMeta.toJson(),
      );
      final macroEntries = rawItems
          .map((raw) {
            final item = Map<String, dynamic>.from(raw as Map);
            final protein = (item['protein'] as num).toDouble();
            final carbs = (item['carbs'] as num).toDouble();
            final fat = (item['fat'] as num).toDouble();
            return MacroEntry(
              id: uuid.v4(),
              mealEntryId: mealId,
              timestamp: consumedAt,
              mealType: mealType,
              name: (item['name'] as String).trim(),
              amount: (item['grams'] as num).toDouble(),
              amountUnit: 'g',
              calories: protein * 4 + carbs * 4 + fat * 9,
              protein: protein,
              carbs: carbs,
              fat: fat,
              sugar: (item['sugar'] as num?)?.toDouble(),
              fiber: (item['fiber'] as num?)?.toDouble(),
              salt: (item['salt'] as num?)?.toDouble(),
              caffeine: (item['caffeine'] as num?)?.toDouble(),
              calculatedNutrient: 'calories',
            );
          })
          .toList(growable: false);
      await repository.insertMealEntryWithMacroEntries(mealEntry, macroEntries);
    } catch (_) {
      if (storedPhotos.isNotEmpty) {
        await MealPhotoStore.instance.delete(
          photoPath: storedPhotos.first.photoPath,
          thumbPath: storedPhotos.first.thumbPath,
          extraPaths: storedPhotos
              .skip(1)
              .map((photo) => photo.photoPath)
              .toList(growable: false),
        );
      }
      rethrow;
    }
  }
}
