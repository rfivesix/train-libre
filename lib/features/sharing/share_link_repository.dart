import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart' as db;
import '../diary/data/sources/product_local_data_source.dart';
import '../diary/domain/models/food_item.dart';
import '../exercise_catalog/domain/models/exercise.dart';
import '../workout/data/manual_training_plan_repository.dart';
import '../workout/data/sources/workout_local_data_source.dart';
import '../workout/domain/models/manual_training_plan.dart';
import '../workout/domain/models/routine.dart';
import '../workout/domain/models/set_template.dart';
import '../workout/domain/models/set_log.dart';
import 'share_link_codec.dart';

class ShareLinkRepository {
  const ShareLinkRepository();

  Future<ShareLinkPayload> forRecipe(Map<String, dynamic> meal) async {
    final id = meal['id'] as int;
    final rows = await DatabaseHelper.instance.getMealItems(id);
    final items = <Map<String, dynamic>>[];
    for (final row in rows) {
      final barcode = row['barcode'] as String?;
      final product = barcode == null
          ? null
          : await ProductLocalDataSource.instance.getProductByBarcode(barcode);
      if (product == null) {
        throw const FormatException('A recipe ingredient is unavailable');
      }
      items.add({
        'barcode': product.barcode,
        'name': product.name,
        'grams': row['quantity_in_grams'],
        'unit': product.isLiquid == true || product.isFluid ? 'ml' : 'g',
        'kcal': product.calories,
        'protein': product.protein,
        'carbs': product.carbs,
        'fat': product.fat,
      });
    }
    if (items.isEmpty) throw const FormatException('Recipe has no items');
    return ShareLinkPayload('recipe', meal['name'] as String, {
      'notes': meal['notes'],
      'portions': (meal['serving_count'] as num?)?.toInt(),
      'cookedWeightInGrams': meal['cooked_weight_in_grams'],
      'items': items,
    });
  }

  /// Validates the payload before writing and imports under fresh local IDs.
  Future<void> import(ShareLinkPayload payload) async {
    payload = ShareLinkPayload.fromJson(payload.toJson());
    await DatabaseHelper.instance.dbInstance.transaction(() async {
      switch (payload.type) {
        case 'routine':
          await _importRoutine(payload);
        case 'plan':
          await _importPlan(payload);
        case 'recipe':
          await _importRecipe(payload);
        case 'workout':
          await _importWorkout(payload);
        default:
          throw const FormatException('Unsupported share type');
      }
    });
  }

  Future<Routine> _importRoutine(ShareLinkPayload payload) async {
    final source = WorkoutLocalDataSource.instance;
    final rows = payload.data['exercises'] as List;
    final parsed = rows.map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final name = row['name'];
      final sets = row['sets'];
      if (name is! String ||
          name.trim().isEmpty ||
          sets is! List ||
          sets.length > 100) {
        throw const FormatException('Invalid routine exercise');
      }
      return row;
    }).toList();

    final routine = await source.createRoutine(payload.name.trim());
    for (final row in parsed) {
      final uuid = row['uuid'] as String?;
      final name = row['name'] as String;
      Exercise? exercise =
          uuid == null ? null : await source.getExerciseByUuid(uuid);
      exercise ??= await source.getExerciseByName(name);
      exercise ??= await source.insertExercise(Exercise.single(
        languageCode: 'en',
        name: name,
        categoryName: row['category'] as String? ?? 'Strength',
        primaryMuscles: (row['muscles'] as List?)?.cast<String>() ?? const [],
        secondaryMuscles:
            (row['secondaryMuscles'] as List?)?.cast<String>() ?? const [],
        trackingType: row['tracking'] as String?,
        loadMode: row['loadMode'] as String?,
        primaryEquipment: row['equipment'] as String?,
      ));
      if (exercise.id == null) throw StateError('Exercise import failed');
      final entry = await source.addExerciseToRoutine(
        routine.id!,
        exercise.id!,
        initialSetCount: 0,
      );
      if (entry == null || entry.id == null) {
        throw StateError('Routine exercise import failed');
      }
      final templates = (row['sets'] as List).map((raw) {
        final set = Map<String, dynamic>.from(raw as Map);
        return SetTemplate(
          setType: set['type'] as String? ?? 'normal',
          targetReps: set['reps'] as String?,
          targetWeight: (set['weight'] as num?)?.toDouble(),
          targetRir: (set['rir'] as num?)?.toInt(),
          targetRepMin: set['repMin'] as int?,
          targetRepMax: set['repMax'] as int?,
        );
      }).toList();
      await source.replaceSetTemplatesForExercise(entry.id!, templates);
      await source.updatePauseTime(entry.id!, (row['pause'] as num?)?.toInt());
      await source.updateSupersetGroup(
          entry.id!, (row['superset'] as num?)?.toInt());
      await source.updateRoutineExerciseNotes(
          entry.id!, row['notes'] as String?);
      await source.updateProgressionData(
          entry.id!, row['progression'] as String?);
    }
    return (await source.getRoutineById(routine.id!))!;
  }

  Future<void> _importPlan(ShareLinkPayload payload) async {
    final kind = TrainingPlanKind.values.byName(payload.data['kind'] as String);
    final rows = payload.data['days'] as List;
    if (rows.isEmpty ||
        rows.length > 14 ||
        (kind == TrainingPlanKind.week && rows.length != 7)) {
      throw const FormatException('Invalid plan length');
    }
    final repository = ManualTrainingPlanRepository();
    final days = <TrainingPlanDay>[];
    final imported = <String, TrainingPlanDay>{};
    for (final raw in rows) {
      if (raw == null) {
        days.add(const TrainingPlanDay());
        continue;
      }
      final nested =
          ShareLinkPayload.fromJson(Map<String, dynamic>.from(raw as Map));
      if (nested.type != 'routine') {
        throw const FormatException('Invalid plan day');
      }
      final key = jsonEncode(nested.toJson());
      var day = imported[key];
      if (day == null) {
        day = await repository.dayFromRoutine(await _importRoutine(nested));
        imported[key] = day;
      }
      days.add(day);
    }
    await repository.createPlan(
      name: payload.name,
      kind: kind,
      days: days,
      activate: false,
    );
  }

  Future<void> _importRecipe(ShareLinkPayload payload) async {
    final rows = payload.data['items'] as List;
    if (rows.isEmpty) throw const FormatException('Recipe has no items');
    final items = rows.map((raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      if (item['barcode'] is! String ||
          item['name'] is! String ||
          item['grams'] is! num ||
          (item['grams'] as num) <= 0) {
        throw const FormatException('Invalid recipe ingredient');
      }
      return item;
    }).toList();
    final products = ProductLocalDataSource.instance;
    final importedBarcodes = <String, String>{};
    for (final item in items) {
      final barcode = item['barcode'] as String;
      if (importedBarcodes.containsKey(barcode)) continue;
      final existing = await products.getProductByBarcode(barcode);
      final calories = (item['kcal'] as num?)?.round() ?? 0;
      final protein = (item['protein'] as num?)?.toDouble() ?? 0;
      final carbs = (item['carbs'] as num?)?.toDouble() ?? 0;
      final fat = (item['fat'] as num?)?.toDouble() ?? 0;
      if (existing != null &&
          existing.name == item['name'] &&
          existing.calories == calories &&
          existing.protein == protein &&
          existing.carbs == carbs &&
          existing.fat == fat) {
        importedBarcodes[barcode] = barcode;
        continue;
      }
      final targetBarcode =
          existing == null ? barcode : 'shared:${const Uuid().v4()}';
      await products.insertProduct(FoodItem(
        barcode: targetBarcode,
        name: item['name'] as String,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        isLiquid: item['unit'] == 'ml',
        isFluid: item['unit'] == 'ml',
      ));
      importedBarcodes[barcode] = targetBarcode;
    }
    final mealId = await DatabaseHelper.instance.insertMeal(
      name: payload.name,
      notes: payload.data['notes'] as String?,
      servingCount: (payload.data['portions'] as num?)?.toInt(),
      cookedWeightInGrams:
          (payload.data['cookedWeightInGrams'] as num?)?.toInt(),
    );
    for (final item in items) {
      await DatabaseHelper.instance.addMealItem(
        mealId: mealId,
        barcode: importedBarcodes[item['barcode']]!,
        amount: (item['grams'] as num).toDouble(),
      );
    }
  }

  Future<void> _importWorkout(ShareLinkPayload payload) async {
    final database = DatabaseHelper.instance.dbInstance;
    final data = payload.data;
    final startedAt = DateTime.parse(data['start'] as String);
    final endedAt =
        data['end'] == null ? null : DateTime.parse(data['end'] as String);
    final row = await database.into(database.workoutLogs).insertReturning(
          db.WorkoutLogsCompanion(
            routineNameSnapshot: drift.Value(payload.name),
            startTime: drift.Value(startedAt),
            endTime: drift.Value(endedAt),
            status: const drift.Value('completed'),
            notes: drift.Value(data['notes'] as String?),
          ),
        );
    final source = WorkoutLocalDataSource.instance;
    for (final raw in data['sets'] as List) {
      final set = Map<String, dynamic>.from(raw as Map);
      final uuid = set['exercise_id'] as String?;
      final name = set['exercise_name'] as String;
      final exercise =
          (uuid == null ? null : await source.getExerciseByUuid(uuid)) ??
              await source.getExerciseByName(name);
      set.remove('id');
      set.remove('workoutLogId');
      set.remove('exerciseId');
      set['workout_log_id'] = row.localId;
      set['exercise_id'] = exercise?.uuid;
      await source.insertSetLog(SetLog.fromMap(set));
    }
  }
}
