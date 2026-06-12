// lib/core/infrastructure/backup_manager.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

import '../../data/database_helper.dart';
import '../../data/drift_database.dart' as db;
import '../../features/diary/data/sources/diary_local_data_source.dart';
import '../../features/diary/data/sources/meal_local_data_source.dart';
import '../../features/profile/data/sources/profile_local_data_source.dart';
import '../../features/supplements/data/sources/supplement_local_data_source.dart';
import '../../features/steps/data/sources/steps_local_data_source.dart';
import '../../features/workout/data/sources/workout_local_data_source.dart';
import '../../features/diary/domain/models/food_item.dart';
import '../../features/app/domain/models/train_libre_backup.dart';
import '../../util/encryption_util.dart';
import '../../util/cancellation_token.dart';
import '../../features/diary/data/sources/product_local_data_source.dart';
import '../../services/storage/saf_storage_service.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class BackupManager {
  static final BackupManager instance = BackupManager();
  static const String currentBackupAppName = 'Train Libre';
  static const String currentBackupFilePrefix = 'train-libre-backup';
  static const String currentAutoBackupFilePrefix = 'train-libre-auto';
  static const String currentApplicationId = 'com.rfivesix.trainlibre';

  // Backwards compatibility for tests
  static const int currentSchemaVersion = 4;
  static const List<String> legacyBackupAppNames = ['Hypertrack'];
  static const List<String> legacyApplicationIds = ['com.rfivesix.hypertrack'];
  static const List<String> legacyBackupFilePrefixes = ['hypertrack-backup'];

  final DatabaseHelper _dbHelper;
  final DiaryLocalDataSource _diaryDb;
  final ProductLocalDataSource _productDb;
  final WorkoutLocalDataSource _workoutDb;
  final ProfileLocalDataSource _profileDb;
  final SupplementLocalDataSource _supplementDb;
  final MealLocalDataSource _mealDb;
  final StepsLocalDataSource _stepsDb;
  final SharedPreferencesLoader _prefsLoader;

  BackupManager({
    DatabaseHelper? dbHelper,
    DatabaseHelper? userDb, // Backwards compatibility for tests
    DiaryLocalDataSource? diaryDb,
    ProductLocalDataSource? productDb,
    WorkoutLocalDataSource? workoutDb,
    ProfileLocalDataSource? profileDb,
    SupplementLocalDataSource? supplementDb,
    MealLocalDataSource? mealDb,
    StepsLocalDataSource? stepsDb,
    SharedPreferencesLoader? prefsLoader,
  })  : _dbHelper = dbHelper ?? userDb ?? DatabaseHelper.instance,
        _prefsLoader = prefsLoader ?? SharedPreferences.getInstance,
        _diaryDb = diaryDb ??
            DiaryLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance),
        _productDb = productDb ??
            ProductLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance),
        _workoutDb = workoutDb ??
            WorkoutLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance),
        _profileDb = profileDb ??
            ProfileLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance),
        _supplementDb = supplementDb ??
            SupplementLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance),
        _mealDb = mealDb ??
            MealLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance),
        _stepsDb = stepsDb ??
            StepsLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance);

  ui.Rect _sharePositionOrigin() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return const ui.Rect.fromLTWH(0, 0, 1, 1);
    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return ui.Rect.fromLTWH(
        0, 0, math.max(1, logicalSize.width), math.max(1, logicalSize.height));
  }

  Future<Map<String, dynamic>> generateBackupPayload([
    CancellationToken? token,
    void Function(String tableName, double progress)? onProgress,
  ]) async {
    token?.throwIfCancelled();
    onProgress?.call('food_entries', 0.05);
    final dbInst = _dbHelper.dbInstance;
    final foodEntries = await _diaryDb.getAllFoodEntries();
    token?.throwIfCancelled();

    onProgress?.call('meals', 0.10);
    final mealTemplates = await _mealDb.getMealTemplatesForBackup();
    token?.throwIfCancelled();

    onProgress?.call('water', 0.15);
    final fluidEntries = await _diaryDb.getAllFluidEntries();
    token?.throwIfCancelled();

    onProgress?.call('favorites', 0.20);
    final favoriteBarcodes = await _productDb.getFavoriteBarcodes();
    token?.throwIfCancelled();

    onProgress?.call('measurements', 0.25);
    final measurementSessions = await _profileDb.getMeasurementSessions();
    token?.throwIfCancelled();

    onProgress?.call('food_items', 0.30);
    final customProductRows = await (dbInst.select(dbInst.products)
          ..where((t) => t.source.equals('user')))
        .get();
    final customFoodItems = customProductRows
        .map((row) => FoodItem(
            barcode: row.barcode,
            name: row.name,
            brand: row.brand ?? '',
            calories: row.calories,
            protein: row.protein,
            carbs: row.carbs,
            fat: row.fat,
            source: FoodItemSource.user,
            sugar: row.sugar ?? 0.0,
            fiber: row.fiber ?? 0.0,
            salt: row.salt ?? 0.0,
            isLiquid: row.isLiquid,
            category: row.category))
        .toList();
    token?.throwIfCancelled();

    onProgress?.call('routines', 0.35);
    final routines = await _workoutDb.getAllRoutinesWithDetails();
    token?.throwIfCancelled();

    onProgress?.call('workouts', 0.40);
    final workoutLogs = await _workoutDb.getFullWorkoutLogs();
    token?.throwIfCancelled();

    onProgress?.call('supplements', 0.45);
    final supplements = await _supplementDb.getAllSupplements();
    token?.throwIfCancelled();

    onProgress?.call('supplement_logs', 0.50);
    final supplementLogs = await _supplementDb.getAllSupplementLogsForBackup();
    token?.throwIfCancelled();

    onProgress?.call('exercises', 0.55);
    final customExercises = await _workoutDb.getCustomExercises();
    token?.throwIfCancelled();

    onProgress?.call('goals', 0.60);
    final goalsHistoryRows =
        await dbInst.select(dbInst.dailyGoalsHistory).get();
    final dailyGoalsHistory = goalsHistoryRows
        .map((r) => {
              'targetCalories': r.targetCalories,
              'targetProtein': r.targetProtein,
              'targetCarbs': r.targetCarbs,
              'targetFat': r.targetFat,
              'targetWater': r.targetWater,
              'targetSteps': r.targetSteps,
              'createdAt': r.createdAt.toIso8601String(),
            })
        .toList();
    token?.throwIfCancelled();

    onProgress?.call('supplement_settings', 0.65);
    final suppHistoryRows =
        await dbInst.select(dbInst.supplementSettingsHistory).join([
      drift.leftOuterJoin(
        dbInst.supplements,
        dbInst.supplements.id
            .equalsExp(dbInst.supplementSettingsHistory.supplementId),
      ),
    ]).get();
    final supplementSettingsHistory = suppHistoryRows.map((row) {
      final sHistory = row.readTable(dbInst.supplementSettingsHistory);
      final supplement = row.readTableOrNull(dbInst.supplements);
      return {
        'supplementId': sHistory.supplementId,
        'supplementLegacyLocalId': supplement?.localId,
        'isTracked': sHistory.isTracked,
        'dose': sHistory.dose,
        'dailyGoal': sHistory.dailyGoal,
        'dailyLimit': sHistory.dailyLimit,
        'createdAt': sHistory.createdAt.toIso8601String(),
      };
    }).toList();
    token?.throwIfCancelled();

    onProgress?.call('settings', 0.70);
    final settingsRows = await (dbInst.select(dbInst.appSettings)
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.localId, mode: drift.OrderingMode.desc)
          ]))
        .get();
    final settingsRow = settingsRows.isEmpty ? null : settingsRows.first;
    final Map<String, dynamic>? appSettingsMap = settingsRow != null
        ? {
            'userId': settingsRow.userId,
            'themeMode': settingsRow.themeMode,
            'unitSystem': settingsRow.unitSystem,
            'targetCalories': settingsRow.targetCalories,
            'targetProtein': settingsRow.targetProtein,
            'targetCarbs': settingsRow.targetCarbs,
            'targetFat': settingsRow.targetFat,
            'targetWater': settingsRow.targetWater,
            'targetSteps': settingsRow.targetSteps,
          }
        : null;
    token?.throwIfCancelled();

    onProgress?.call('profile', 0.75);
    final profileRows = await (dbInst.select(dbInst.profiles)
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.localId, mode: drift.OrderingMode.desc)
          ]))
        .get();
    final profileRow = profileRows.isEmpty ? null : profileRows.first;
    final Map<String, dynamic>? profileMap = profileRow != null
        ? {
            'id': profileRow.id,
            'username': profileRow.username,
            'isCoach': profileRow.isCoach,
            'visibility': profileRow.visibility,
            'birthday': profileRow.birthday?.toIso8601String(),
            'height': profileRow.height,
            'gender': profileRow.gender,
            'profileImagePath': profileRow.profileImagePath,
          }
        : null;
    token?.throwIfCancelled();

    onProgress?.call('steps', 0.80);
    final healthStepRows = await dbInst.select(dbInst.healthStepSegments).get();
    final healthStepSegments = healthStepRows
        .map((r) => {
              'provider': r.provider,
              'sourceId': r.sourceId,
              'startAt': r.startAt.toUtc().toIso8601String(),
              'endAt': r.endAt.toUtc().toIso8601String(),
              'stepCount': r.stepCount,
              'externalKey': r.externalKey,
            })
        .toList();
    token?.throwIfCancelled();

    final prefs = await _prefsLoader();
    final userPrefs = <String, dynamic>{
      for (String key in prefs.getKeys()) key: prefs.get(key)
    };

    final backup = TrainLibreBackup(
        schemaVersion: currentSchemaVersion,
        foodEntries: foodEntries,
        mealTemplates: mealTemplates,
        fluidEntries: fluidEntries,
        favoriteBarcodes: favoriteBarcodes,
        customFoodItems: customFoodItems,
        measurementSessions: measurementSessions,
        routines: routines,
        workoutLogs: workoutLogs,
        userPreferences: userPrefs,
        supplements: supplements,
        supplementLogs: supplementLogs,
        customExercises: customExercises,
        dailyGoalsHistory: dailyGoalsHistory,
        supplementSettingsHistory: supplementSettingsHistory,
        appSettings: appSettingsMap,
        profile: profileMap,
        healthStepSegments: healthStepSegments);
    final payload = backup.toJson();
    payload['appName'] = currentBackupAppName;
    payload['applicationId'] = currentApplicationId;
    payload['backupFilePrefix'] = currentBackupFilePrefix;
    payload['generatedAtUtc'] = DateTime.now().toUtc().toIso8601String();

    onProgress?.call('sleep_raw_imports', 0.85);
    payload['sleep_raw_imports'] = await _fetchTable('sleep_raw_imports');
    token?.throwIfCancelled();

    onProgress?.call('sleep_sessions', 0.88);
    payload['sleep_canonical_sessions'] = await _fetchTable('sleep_canonical_sessions');
    token?.throwIfCancelled();

    onProgress?.call('sleep_stages', 0.90);
    payload['sleep_canonical_stage_segments'] = await _fetchTable('sleep_canonical_stage_segments');
    token?.throwIfCancelled();

    onProgress?.call('sleep_hr', 0.92);
    payload['sleep_canonical_heart_rate_samples'] = await _fetchTable('sleep_canonical_heart_rate_samples');
    token?.throwIfCancelled();

    onProgress?.call('sleep_analyses', 0.94);
    payload['sleep_nightly_analyses'] = await _fetchTable('sleep_nightly_analyses');
    token?.throwIfCancelled();

    onProgress?.call('pulse_data', 0.96);
    payload['pulse_hourly_aggregates'] = await _fetchTable('pulse_hourly_aggregates');
    payload['pulse_aggregate_metadata'] = await _fetchTable('pulse_aggregate_metadata');
    token?.throwIfCancelled();

    onProgress?.call('cardio_data', 0.98);
    payload['cardio_activities'] = await _fetchTable('cardio_activities');
    payload['cardio_samples'] = await _fetchTable('cardio_samples');
    payload['user_food_overrides'] = await _fetchTable('user_food_overrides');
    token?.throwIfCancelled();

    onProgress?.call('done', 1.0);
    return payload;
  }

  Future<List<Map<String, dynamic>>> _fetchTable(String tableName) async {
    try {
      final rows = await _dbHelper.dbInstance.customSelect('SELECT * FROM $tableName').get();
      return rows.map((r) => Map<String, dynamic>.from(r.data)).toList();
    } catch (e) {
      debugPrint('Error fetching table $tableName: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> generateBackupPayloadForTesting() =>
      generateBackupPayload();

  Future<String> _generateBackupJson([
    CancellationToken? token,
    void Function(String tableName, double progress)? onProgress,
  ]) async {
    final payload = await generateBackupPayload(token, onProgress);
    token?.throwIfCancelled();
    return compute(jsonEncode, payload);
  }

  Future<bool> exportFullBackup([
    CancellationToken? token,
    void Function(String tableName, double progress)? onProgress,
  ]) async {
    try {
      final jsonString = await _generateBackupJson(token, onProgress);
      token?.throwIfCancelled();
      return await _writeAndShareFile(jsonString, currentBackupFilePrefix);
    } catch (e) {
      if (e is OperationCanceledException) {
        rethrow;
      }
      return false;
    }
  }

  Future<bool> exportFullBackupEncrypted(
    String passphrase, [
    CancellationToken? token,
    void Function(String tableName, double progress)? onProgress,
  ]) async {
    try {
      final jsonString = await _generateBackupJson(token, onProgress);
      token?.throwIfCancelled();
      final wrapper =
          await EncryptionUtil.encryptString(jsonString, passphrase);
      token?.throwIfCancelled();
      final wrappedJson = await compute(jsonEncode, wrapper);
      token?.throwIfCancelled();
      return await _writeAndShareFile(
          wrappedJson, '$currentBackupFilePrefix-enc');
    } catch (e) {
      if (e is OperationCanceledException) {
        rethrow;
      }
      return false;
    }
  }

  Future<bool> _writeAndShareFile(String content, String baseName) async {
    final tempDir = await getTemporaryDirectory();
    final ts = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final file = File('${tempDir.path}/$baseName-[$ts].json');
    await file.writeAsString(content);
    final res = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: '$currentBackupAppName Backup $ts',
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
    if (await file.exists()) await file.delete();
    return res.status == ShareResultStatus.success;
  }

  Future<bool> importFullBackupAuto(
    String filePath, {
    String? passphrase,
    CancellationToken? token,
    void Function(String tableName, double progress)? onProgress,
  }) async {
    try {
      token?.throwIfCancelled();
      onProgress?.call('reading_backup', 0.0);
      final raw = await File(filePath).readAsString();
      token?.throwIfCancelled();

      onProgress?.call('decrypting_backup', 0.05);
      final jsonMapRaw = await compute(jsonDecode, raw) as Map<String, dynamic>;
      Map<String, dynamic> payload;
      if (jsonMapRaw['enc'] != null) {
        final clearText =
            await EncryptionUtil.decryptToString(jsonMapRaw, passphrase ?? "");
        payload = await compute(jsonDecode, clearText) as Map<String, dynamic>;
      } else {
        payload = jsonMapRaw;
      }
      token?.throwIfCancelled();
      return await _importBackupPayload(payload, token, onProgress);
    } catch (e) {
      if (e is OperationCanceledException) {
        rethrow;
      }
      return false;
    }
  }

  Future<bool> importBackupPayloadForTesting(Map<String, dynamic> payload) =>
      _importBackupPayload(payload);

  bool _isAcceptedBackupMetadata(Map<String, dynamic> payload) {
    final rawAppName = payload['appName']?.toString().trim();
    final rawApplicationId = payload['applicationId']?.toString().trim();
    final rawFilePrefix = payload['backupFilePrefix']?.toString().trim();

    final allowedAppNames = <String>{
      currentBackupAppName,
      ...legacyBackupAppNames,
    };
    final allowedApplicationIds = <String>{
      currentApplicationId,
      ...legacyApplicationIds,
    };
    final allowedFilePrefixes = <String>{
      currentBackupFilePrefix,
      ...legacyBackupFilePrefixes,
    };

    if (rawAppName != null &&
        rawAppName.isNotEmpty &&
        !allowedAppNames.contains(rawAppName)) {
      return false;
    }
    if (rawApplicationId != null &&
        rawApplicationId.isNotEmpty &&
        !allowedApplicationIds.contains(rawApplicationId)) {
      return false;
    }
    if (rawFilePrefix != null &&
        rawFilePrefix.isNotEmpty &&
        !allowedFilePrefixes.contains(rawFilePrefix)) {
      return false;
    }
    return true;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final normalized = value.trim();
      return int.tryParse(normalized) ?? double.tryParse(normalized)?.toInt();
    }
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value.trim());
    return null;
  }

  List<Map<String, dynamic>> _sanitizeHealthSegments(
    List<Map<String, dynamic>> rawSegments,
  ) {
    final sanitized = <Map<String, dynamic>>[];
    for (final row in rawSegments) {
      final provider = row['provider']?.toString().trim();
      final externalKey = row['externalKey']?.toString().trim();
      final startAt = _asDateTime(row['startAt']);
      final endAt = _asDateTime(row['endAt']);
      final stepCount = _asInt(row['stepCount']);
      if (provider == null ||
          provider.isEmpty ||
          externalKey == null ||
          externalKey.isEmpty ||
          startAt == null ||
          endAt == null ||
          !endAt.isAfter(startAt) ||
          stepCount == null ||
          stepCount < 0) {
        debugPrint(
          'Skipping malformed health_step_segments row during backup import.',
        );
        continue;
      }
      final sourceId = row['sourceId']?.toString().trim();
      sanitized.add(<String, dynamic>{
        'provider': provider,
        'sourceId': (sourceId == null || sourceId.isEmpty) ? null : sourceId,
        'startAt': startAt.toUtc().toIso8601String(),
        'endAt': endAt.toUtc().toIso8601String(),
        'stepCount': stepCount,
        'externalKey': externalKey,
      });
    }
    return sanitized;
  }

  Future<bool> _importBackupPayload(
    Map<String, dynamic> payload, [
    CancellationToken? token,
    void Function(String tableName, double progress)? onProgress,
  ]) async {
    if (!_isAcceptedBackupMetadata(payload)) {
      debugPrint('Backup metadata rejected.');
      return false;
    }

    final backup = TrainLibreBackup.fromJson(payload);
    final prefs = await _prefsLoader();

    // Capture the original preference state to rollback on failure
    final originalPrefs = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      originalPrefs[key] = prefs.get(key);
    }

    final dbInst = _dbHelper.dbInstance;
    bool success = false;

    try {
      token?.throwIfCancelled();
      onProgress?.call('preferences', 0.10);
      await prefs.clear();

      await dbInst.transaction(() async {
        // Defer foreign key checks so tables can be cleared and populated in any order safely
        await dbInst.customStatement('PRAGMA defer_foreign_keys = ON');

        token?.throwIfCancelled();
        onProgress?.call('clear_database', 0.15);

        // Clear dynamic sleep and pulse tables first
        await dbInst.customStatement('DELETE FROM sleep_nightly_analyses');
        await dbInst.customStatement('DELETE FROM sleep_canonical_stage_segments');
        await dbInst.customStatement('DELETE FROM sleep_canonical_heart_rate_samples');
        await dbInst.customStatement('DELETE FROM sleep_canonical_sessions');
        await dbInst.customStatement('DELETE FROM sleep_raw_imports');
        await dbInst.customStatement('DELETE FROM pulse_hourly_aggregates');
        await dbInst.customStatement('DELETE FROM pulse_aggregate_metadata');
        await dbInst.customStatement('DELETE FROM user_food_overrides');
        await dbInst.delete(dbInst.cardioSamples).go();
        await dbInst.delete(dbInst.cardioActivities).go();

        // Clear general user tables
        await dbInst.delete(dbInst.dailyGoalsHistory).go();
        await dbInst.delete(dbInst.supplementSettingsHistory).go();
        await dbInst.customStatement('DELETE FROM health_step_segments');
        await dbInst.customStatement('DELETE FROM health_export_records');
        await dbInst.delete(dbInst.supplementLogs).go();
        await dbInst.delete(dbInst.fluidLogs).go();
        await dbInst.delete(dbInst.nutritionLogs).go();
        await dbInst.delete(dbInst.measurements).go();
        await dbInst.delete(dbInst.mealItems).go();
        await dbInst.delete(dbInst.favorites).go();
        await dbInst.delete(dbInst.supplements).go();
        await dbInst.delete(dbInst.meals).go();
        await dbInst.delete(dbInst.appSettings).go();
        await dbInst.delete(dbInst.profiles).go();
        await (dbInst.delete(dbInst.products)..where((t) => t.source.equals('user'))).go();

        // Clear workout tables
        await dbInst.delete(dbInst.setLogs).go();
        await dbInst.delete(dbInst.workoutLogs).go();
        await dbInst.delete(dbInst.routineSetTemplates).go();
        await dbInst.delete(dbInst.routineExercises).go();
        await dbInst.delete(dbInst.routines).go();
        await (dbInst.delete(dbInst.exercises)..where((tbl) => tbl.isCustom.equals(true))).go();

        token?.throwIfCancelled();
        onProgress?.call('preferences', 0.25);

        for (final entry in backup.userPreferences.entries) {
          final k = entry.key, v = entry.value;
          if (v is bool) {
            await prefs.setBool(k, v);
          } else if (v is int) {
            await prefs.setInt(k, v);
          } else if (v is double) {
            await prefs.setDouble(k, v);
          } else if (v is String) {
            await prefs.setString(k, v);
          } else if (v is List && v.every((e) => e is String)) {
            await prefs.setStringList(k, v.cast<String>());
          }
        }
        token?.throwIfCancelled();

        onProgress?.call('user_data', 0.35);
        await _dbHelper.importUserData(
            foodEntries: backup.foodEntries,
            fluidEntries: backup.fluidEntries,
            favoriteBarcodes: backup.favoriteBarcodes,
            measurementSessions: backup.measurementSessions,
            supplements: backup.supplements,
            supplementLogs: backup.supplementLogs);
        token?.throwIfCancelled();

        onProgress?.call('custom_foods', 0.50);
        await dbInst.batch((batch) {
          for (final item in backup.customFoodItems) {
            batch.insert(
              dbInst.products,
              db.ProductsCompanion(
                barcode: drift.Value(item.barcode),
                name: drift.Value(item.name),
                brand: drift.Value(item.brand),
                calories: drift.Value(item.calories),
                protein: drift.Value(item.protein),
                carbs: drift.Value(item.carbs),
                fat: drift.Value(item.fat),
                sugar: drift.Value(item.sugar),
                fiber: drift.Value(item.fiber),
                salt: drift.Value(item.salt),
                source: const drift.Value('user'),
                isLiquid: drift.Value(item.isLiquid ?? false),
                category: drift.Value(item.category),
                id: drift.Value(
                  item.barcode.startsWith('user_')
                      ? item.barcode
                      : 'user_${item.barcode}',
                ),
                caffeine: drift.Value(item.caffeineMgPer100ml),
                caffeineMgPer100g: drift.Value(item.caffeineMgPer100g),
                isFluid: drift.Value(item.isFluid),
                nameDe: drift.Value(item.nameDe),
                nameEn: drift.Value(item.nameEn),
                ingredientsText: drift.Value(item.ingredientsText),
                ingredientsAnalysisTags: drift.Value(item.ingredientsAnalysisTags != null ? jsonEncode(item.ingredientsAnalysisTags) : null),
                additivesTags: drift.Value(item.additivesTags != null ? jsonEncode(item.additivesTags) : null),
                productQuantity: drift.Value(item.productQuantity),
                productQuantityUnit: drift.Value(item.productQuantityUnit),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
          }
        });
        token?.throwIfCancelled();

        onProgress?.call('meals', 0.60);
        await _mealDb.importMealTemplates(backup.mealTemplates);
        token?.throwIfCancelled();

        onProgress?.call('workouts', 0.70);
        await _workoutDb.importWorkoutData(
            routines: backup.routines, workoutLogs: backup.workoutLogs);
        token?.throwIfCancelled();

        onProgress?.call('custom_exercises', 0.80);
        await _workoutDb.importCustomExercises(backup.customExercises);
        token?.throwIfCancelled();

        // Import DailyGoalsHistory
        if (backup.dailyGoalsHistory.isNotEmpty) {
          onProgress?.call('goals_history', 0.85);
          for (final row in backup.dailyGoalsHistory) {
            final targetCalories = _asInt(row['targetCalories']);
            final targetProtein = _asInt(row['targetProtein']);
            final targetCarbs = _asInt(row['targetCarbs']);
            final targetFat = _asInt(row['targetFat']);
            final targetWater = _asInt(row['targetWater']);
            final createdAt = _asDateTime(row['createdAt']);
            if (targetCalories == null ||
                targetProtein == null ||
                targetCarbs == null ||
                targetFat == null ||
                targetWater == null ||
                createdAt == null) {
              debugPrint(
                'Skipping malformed daily_goals_history row during backup import.',
              );
              continue;
            }
            await dbInst.into(dbInst.dailyGoalsHistory).insert(
                  db.DailyGoalsHistoryCompanion(
                    targetCalories: drift.Value(targetCalories),
                    targetProtein: drift.Value(targetProtein),
                    targetCarbs: drift.Value(targetCarbs),
                    targetFat: drift.Value(targetFat),
                    targetWater: drift.Value(targetWater),
                    targetSteps: drift.Value(
                      _asInt(row['targetSteps']) ?? 8000,
                    ),
                    createdAt: drift.Value(createdAt),
                  ),
                  mode: drift.InsertMode.insertOrReplace,
                );
          }
        }
        token?.throwIfCancelled();

        // Import SupplementSettingsHistory
        if (backup.supplementSettingsHistory.isNotEmpty) {
          onProgress?.call('supplement_history', 0.88);
          final supplementRows = await dbInst.select(dbInst.supplements).get();
          final validSupplementIds = supplementRows.map((s) => s.id).toSet();
          final supplementIdByLegacyLocalId = <String, String>{
            for (final row in supplementRows) row.localId.toString(): row.id,
          };
          await dbInst.batch((batch) {
            for (final row in backup.supplementSettingsHistory) {
              final supplementIdRaw = row['supplementId']?.toString().trim();
              final legacyLocalIdRaw = row['supplementLegacyLocalId'];
              final legacyLocalId = _asInt(legacyLocalIdRaw)?.toString() ??
                  legacyLocalIdRaw?.toString().trim();
              final mappedId = (supplementIdRaw != null &&
                      validSupplementIds.contains(supplementIdRaw))
                  ? supplementIdRaw
                  : (legacyLocalId != null
                      ? supplementIdByLegacyLocalId[legacyLocalId]
                      : null);
              final isTracked = _asBool(row['isTracked']);
              final dose = _asDouble(row['dose']);
              final createdAt = _asDateTime(row['createdAt']);
              if (mappedId == null ||
                  isTracked == null ||
                  dose == null ||
                  createdAt == null) {
                debugPrint(
                  'Skipping malformed supplement_settings_history row during backup import.',
                );
                continue;
              }
              batch.insert(
                dbInst.supplementSettingsHistory,
                db.SupplementSettingsHistoryCompanion(
                  supplementId: drift.Value(mappedId),
                  isTracked: drift.Value(isTracked),
                  dose: drift.Value(dose),
                  dailyGoal: drift.Value(_asDouble(row['dailyGoal'])),
                  dailyLimit: drift.Value(_asDouble(row['dailyLimit'])),
                  createdAt: drift.Value(createdAt),
                ),
                mode: drift.InsertMode.insertOrReplace,
              );
            }
          });
        }
        token?.throwIfCancelled();

        String? restoredUserId;

        // Import Profile
        if (backup.profile != null) {
          onProgress?.call('profile', 0.90);
          final p = backup.profile!;
          final profileId = p['id']?.toString().trim();
          if (profileId != null && profileId.isNotEmpty) {
            restoredUserId = profileId;
            await dbInst.into(dbInst.profiles).insert(
                  db.ProfilesCompanion(
                    id: drift.Value(profileId),
                    username: drift.Value(p['username']?.toString()),
                    isCoach: drift.Value(_asBool(p['isCoach']) ?? false),
                    visibility: drift.Value(
                      p['visibility']?.toString() ?? 'private',
                    ),
                    birthday: drift.Value(_asDateTime(p['birthday'])),
                    height: drift.Value(_asInt(p['height'])),
                    gender: drift.Value(p['gender']?.toString()),
                    profileImagePath: drift.Value(
                      p['profileImagePath']?.toString(),
                    ),
                  ),
                  mode: drift.InsertMode.insertOrReplace,
                );
          }
        }
        token?.throwIfCancelled();

        // Import AppSettings
        if (backup.appSettings != null) {
          onProgress?.call('settings', 0.92);
          final s = backup.appSettings!;
          final candidateUserId = s['userId']?.toString().trim();
          if (restoredUserId == null &&
              candidateUserId != null &&
              candidateUserId.isNotEmpty) {
            restoredUserId = candidateUserId;
          }

          if (restoredUserId != null) {
            final userId = restoredUserId;
            final existingProfile = await (dbInst.select(
              dbInst.profiles,
            )..where((t) => t.id.equals(userId)))
                .getSingleOrNull();

            // Ensure FK target exists even when profile payload is absent.
            if (existingProfile == null) {
              await dbInst.into(dbInst.profiles).insert(
                    db.ProfilesCompanion(
                      id: drift.Value(userId),
                      visibility: const drift.Value('private'),
                      isCoach: const drift.Value(false),
                    ),
                    mode: drift.InsertMode.insertOrReplace,
                  );
            }

            await dbInst.into(dbInst.appSettings).insert(
                  db.AppSettingsCompanion(
                    userId: drift.Value(userId),
                    themeMode: drift.Value(s['themeMode']?.toString() ?? 'system'),
                    unitSystem:
                        drift.Value(s['unitSystem']?.toString() ?? 'metric'),
                    targetCalories: drift.Value(
                      _asInt(s['targetCalories']) ?? 2500,
                    ),
                    targetProtein: drift.Value(_asInt(s['targetProtein']) ?? 180),
                    targetCarbs: drift.Value(_asInt(s['targetCarbs']) ?? 250),
                    targetFat: drift.Value(_asInt(s['targetFat']) ?? 80),
                    targetWater: drift.Value(_asInt(s['targetWater']) ?? 3000),
                    targetSteps: drift.Value(
                      _asInt(s['targetSteps']) ?? 8000,
                    ),
                  ),
                  mode: drift.InsertMode.insertOrReplace,
                );
          }
        }
        token?.throwIfCancelled();

        if (backup.healthStepSegments.isNotEmpty) {
          onProgress?.call('health_steps', 0.94);
          final sanitizedSegments = _sanitizeHealthSegments(
            backup.healthStepSegments,
          );
          if (sanitizedSegments.isNotEmpty) {
            final companions = sanitizedSegments.map((row) {
              return db.HealthStepSegmentsCompanion.insert(
                provider: row['provider'],
                sourceId: drift.Value(row['sourceId']),
                startAt: DateTime.parse(row['startAt']),
                endAt: DateTime.parse(row['endAt']),
                stepCount: row['stepCount'],
                externalKey: row['externalKey'],
              );
            }).toList();
            await _stepsDb.upsertHealthStepSegments(companions);
          }
        }
        token?.throwIfCancelled();

        // Restore dynamic sleep/pulse/cardio tables
        onProgress?.call('sleep_raw_imports', 0.95);
        await _importTable('sleep_raw_imports', payload['sleep_raw_imports']);
        token?.throwIfCancelled();

        onProgress?.call('sleep_sessions', 0.96);
        await _importTable('sleep_canonical_sessions', payload['sleep_canonical_sessions']);
        token?.throwIfCancelled();

        onProgress?.call('sleep_stages', 0.97);
        await _importTable('sleep_canonical_stage_segments', payload['sleep_canonical_stage_segments']);
        token?.throwIfCancelled();

        onProgress?.call('sleep_hr', 0.98);
        await _importTable('sleep_canonical_heart_rate_samples', payload['sleep_canonical_heart_rate_samples']);
        token?.throwIfCancelled();

        onProgress?.call('sleep_analyses', 0.99);
        await _importTable('sleep_nightly_analyses', payload['sleep_nightly_analyses']);
        token?.throwIfCancelled();

        onProgress?.call('pulse_data', 0.995);
        await _importTable('pulse_hourly_aggregates', payload['pulse_hourly_aggregates']);
        await _importTable('pulse_aggregate_metadata', payload['pulse_aggregate_metadata']);
        token?.throwIfCancelled();

        onProgress?.call('cardio_data', 0.999);
        await _importTable('cardio_activities', payload['cardio_activities']);
        await _importTable('cardio_samples', payload['cardio_samples']);
        await _importTable('user_food_overrides', payload['user_food_overrides']);
        token?.throwIfCancelled();
      });
      success = true;
    } catch (e) {
      debugPrint('Backup import failed: $e');

      // Rollback preferences state on failure or cancellation
      await prefs.clear();
      for (final entry in originalPrefs.entries) {
        final k = entry.key, v = entry.value;
        if (v is bool) {
          await prefs.setBool(k, v);
        } else if (v is int) {
          await prefs.setInt(k, v);
        } else if (v is double) {
          await prefs.setDouble(k, v);
        } else if (v is String) {
          await prefs.setString(k, v);
        } else if (v is List && v.every((e) => e is String)) {
          await prefs.setStringList(k, v.cast<String>());
        }
      }
      rethrow;
    }

    if (success) {
      onProgress?.call('done', 1.0);
    }
    debugPrint("Backup import succeeded.");
    return true;
  }

  Future<void> _importTable(String tableName, List<dynamic>? rows) async {
    if (rows == null || rows.isEmpty) return;
    final dbInst = _dbHelper.dbInstance;
    await dbInst.customStatement('DELETE FROM $tableName');
    for (final row in rows) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      final columns = map.keys.toList();
      final placeholders = List.filled(columns.length, '?').join(', ');
      final values = columns.map((col) => map[col]).toList();
      final sql = 'INSERT OR REPLACE INTO $tableName (${columns.join(', ')}) VALUES ($placeholders)';
      await dbInst.customStatement(sql, values);
    }
  }

  Future<bool> runAutoBackupIfDue({
    Duration interval = const Duration(days: 1),
    bool encrypted = false,
    String? passphrase,
    int retention = 7,
    String? dirPath,
    bool force = false,
  }) async {
    try {
      final prefs = await _prefsLoader();
      final lastBackupMillis = prefs.getInt('last_auto_backup_timestamp') ?? 0;
      final lastBackup = DateTime.fromMillisecondsSinceEpoch(lastBackupMillis);

      if (!force && DateTime.now().difference(lastBackup) < interval) {
        return false;
      }

      final jsonString = await _generateBackupJson();
      String content = jsonString;
      String suffix = '';

      if (encrypted && passphrase != null) {
        final wrapper =
            await EncryptionUtil.encryptString(jsonString, passphrase);
        content = await compute(jsonEncode, wrapper);
        suffix = '-enc';
      }

      final savedDir = prefs.getString('auto_backup_dir');
      final treeUri = prefs.getString('auto_backup_tree_uri');
      final isAndroidSaf = Platform.isAndroid && treeUri != null && treeUri.trim().isNotEmpty;

      if (isAndroidSaf) {
        final ts = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final fileName = '$currentAutoBackupFilePrefix$suffix-[$ts].json';
        String? savedSafPath;
        try {
          savedSafPath = await SafStorageService.instance.writeTextFileToTree(
            treeUri: treeUri,
            fileName: fileName,
            content: content,
          );
        } catch (e) {
          debugPrint('Auto-backup SAF write threw error: $e');
        }

        if (savedSafPath != null) {
          await prefs.setInt('last_auto_backup_timestamp',
              DateTime.now().millisecondsSinceEpoch);
          await prefs.setString('auto_backup_last_file_path', savedSafPath);
          await prefs.setString('auto_backup_last_dir_used', savedDir ?? 'SAF Shared Storage');
          await prefs.setBool('auto_backup_last_used_fallback', false);
          await prefs.remove('auto_backup_last_error');

          if (retention > 0) {
            try {
              await SafStorageService.instance.pruneAutoBackupsInTree(
                treeUri: treeUri,
                filePrefix: currentAutoBackupFilePrefix,
                retention: retention,
              );
            } catch (e) {
              debugPrint('Auto-backup SAF prune failed: $e');
            }
          }
          return true;
        } else {
          debugPrint('Auto-backup SAF write returned null, falling back to local sandbox...');
        }
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final directory = await resolveWritableBackupDirectory(
        docsDir: docsDir,
        dirPath: dirPath,
        savedDir: savedDir,
      );

      final chosenPath = (dirPath != null && dirPath.trim().isNotEmpty)
          ? dirPath.trim()
          : (savedDir != null && savedDir.trim().isNotEmpty ? savedDir.trim() : null);
      final isFallbackUsed = chosenPath != null && directory.path != chosenPath;

      final ts = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File(p.join(
          directory.path, '$currentAutoBackupFilePrefix$suffix-[$ts].json'));

      await directory.create(recursive: true);
      await file.writeAsString(content, flush: true);
      await prefs.setInt(
          'last_auto_backup_timestamp', DateTime.now().millisecondsSinceEpoch);

      await prefs.setString('auto_backup_last_file_path', file.path);
      await prefs.setString('auto_backup_last_dir_used', directory.path);
      await prefs.setBool('auto_backup_last_used_fallback', isFallbackUsed);
      await prefs.remove('auto_backup_last_error');

      // Handle retention
      if (retention > 0) {
        final files = directory
            .listSync()
            .whereType<File>()
            .where((f) =>
                p.basename(f.path).startsWith(currentAutoBackupFilePrefix))
            .toList();
        if (files.length > retention) {
          files.sort(
              (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
          for (var i = 0; i < files.length - retention; i++) {
            await files[i].delete();
          }
        }
      }

      return true;
    } catch (e) {
      try {
        final prefs = await _prefsLoader();
        await prefs.setString('auto_backup_last_error', e.toString());
        await prefs.remove('auto_backup_last_file_path');
        await prefs.setBool('auto_backup_last_used_fallback', false);
      } catch (_) {}
      return false;
    }
  }

  static Future<Map<String, double>?> _getWorkoutHeartRate(String workoutLogId, DateTime startTime, DateTime endTime) async {
    final dbInst = DatabaseHelper.instance.dbInstance;
    // 1. Try to read from cardio_samples
    try {
      final rows = await dbInst.customSelect('''
        SELECT s.data_json
        FROM cardio_activities a
        JOIN cardio_samples s ON a.id = s.cardio_activity_id
        WHERE a.workout_log_id = ? AND s.data_type = 'HeartRate'
      ''', variables: [drift.Variable<String>(workoutLogId)]).get();
      if (rows.isNotEmpty) {
        final dataJson = rows.first.read<String>('data_json');
        final decoded = jsonDecode(dataJson);
        if (decoded is List && decoded.isNotEmpty) {
          double min = double.infinity;
          double max = double.negativeInfinity;
          double sum = 0;
          int count = 0;
          for (final item in decoded) {
            double? bpm;
            if (item is num) {
              bpm = item.toDouble();
            } else if (item is Map) {
              bpm = (item['bpm'] ?? item['value'])?.toDouble();
            }
            if (bpm != null && bpm > 0) {
              min = math.min(min, bpm);
              max = math.max(max, bpm);
              sum += bpm;
              count++;
            }
          }
          if (count > 0) {
            return {'min': min, 'max': max, 'avg': sum / count};
          }
        }
      }
    } catch (_) {}

    // 2. Fallback to overlapping pulse aggregates
    try {
      final startMs = startTime.millisecondsSinceEpoch;
      final endMs = endTime.millisecondsSinceEpoch;
      final rows = await dbInst.customSelect('''
        SELECT min_bpm, max_bpm, sum_bpm, sample_count
        FROM pulse_hourly_aggregates
        WHERE bucket_end_ms > ? AND bucket_start_ms < ?
      ''', variables: [drift.Variable<int>(startMs), drift.Variable<int>(endMs)]).get();
      if (rows.isNotEmpty) {
        double min = double.infinity;
        double max = double.negativeInfinity;
        double sum = 0;
        int totalCount = 0;
        for (final r in rows) {
          final count = r.read<num>('sample_count').toInt();
          if (count > 0) {
            min = math.min(min, r.read<double>('min_bpm'));
            max = math.max(max, r.read<double>('max_bpm'));
            sum += r.read<double>('sum_bpm');
            totalCount += count;
          }
        }
        if (totalCount > 0) {
          return {'min': min, 'max': max, 'avg': sum / totalCount};
        }
      }
    } catch (_) {}

    return null;
  }

  Future<bool> exportNutritionAsCsv() async {
    final entries = await _diaryDb.getAllFoodEntries();
    final fluidEntries = await _diaryDb.getAllFluidEntries();
    if (entries.isEmpty && fluidEntries.isEmpty) return false;

    final barcodes = entries.map((e) => e.barcode).toSet().toList();
    final products = await _productDb.getProductsByBarcodes(barcodes);
    final pMap = {for (var p in products) p.barcode: p};

    List<List<dynamic>> rows = [
      [
        'date',
        'time',
        'food',
        'type',
        'grams_ml',
        'calories',
        'protein_g',
        'carbs_g',
        'fat_g',
        'sugar_g',
        'fiber_g',
        'caffeine_mg',
        'water_liquids_ml'
      ]
    ];

    for (final e in entries) {
      final p = pMap[e.barcode];
      if (p != null) {
        final ratio = e.quantityInGrams / 100.0;
        final calories = p.calories * ratio;
        final protein = p.protein * ratio;
        final carbs = p.carbs * ratio;
        final fat = p.fat * ratio;
        final sugar = (p.sugar ?? 0.0) * ratio;
        final fiber = (p.fiber ?? 0.0) * ratio;
        final caffeine = (p.caffeineMgPer100g ?? p.caffeineMgPer100ml ?? 0.0) * ratio;
        
        rows.add([
          DateFormat('yyyy-MM-dd').format(e.timestamp),
          DateFormat('HH:mm').format(e.timestamp),
          p.name,
          'Essen',
          e.quantityInGrams,
          calories.toStringAsFixed(1),
          protein.toStringAsFixed(1),
          carbs.toStringAsFixed(1),
          fat.toStringAsFixed(1),
          sugar.toStringAsFixed(1),
          fiber.toStringAsFixed(1),
          caffeine.toStringAsFixed(1),
          0
        ]);
      }
    }

    for (final f in fluidEntries) {
      final ratio = f.quantityInMl / 100.0;
      final calories = (f.kcal ?? 0) * ratio;
      final carbs = (f.carbsPer100ml ?? 0.0) * ratio;
      final sugar = (f.sugarPer100ml ?? 0.0) * ratio;
      final caffeine = (f.caffeinePer100ml ?? 0.0) * ratio;

      rows.add([
        DateFormat('yyyy-MM-dd').format(f.timestamp),
        DateFormat('HH:mm').format(f.timestamp),
        f.name,
        'Trinken',
        f.quantityInMl,
        calories.toStringAsFixed(1),
        0.0.toStringAsFixed(1),
        carbs.toStringAsFixed(1),
        0.0.toStringAsFixed(1),
        sugar.toStringAsFixed(1),
        0.0.toStringAsFixed(1),
        caffeine.toStringAsFixed(1),
        f.quantityInMl
      ]);
    }

    final csvData = csv.encode(rows);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/nutrition_history.csv');
    await file.writeAsString(csvData);
    final res = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Nutrition History',
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
    await file.delete();
    return res.status == ShareResultStatus.success;
  }

  Future<bool> exportWorkoutsAsCsv() async {
    final logs = await _workoutDb.getFullWorkoutLogs();
    if (logs.isEmpty) return false;
    List<List<dynamic>> rows = [
      [
        'start_time',
        'end_time',
        'routine_name',
        'exercise_name',
        'set_type',
        'weight_kg',
        'reps',
        'rest_time_seconds',
        'is_completed',
        'log_order',
        'distance_km',
        'duration_seconds',
        'rpe',
        'rir',
        'set_notes',
        'workout_notes'
      ]
    ];
    for (final l in logs) {
      for (final s in l.sets) {
        rows.add([
          l.startTime.toIso8601String(),
          l.endTime?.toIso8601String() ?? '',
          l.routineName ?? '',
          s.exerciseName,
          s.setType,
          s.weightKg ?? 0.0,
          s.reps ?? 0,
          s.restTimeSeconds ?? 0,
          s.isCompleted == true ? 1 : 0,
          s.logOrder ?? 0,
          s.distanceKm ?? 0.0,
          s.durationSeconds ?? 0,
          s.rpe ?? 0,
          s.rir ?? 0,
          s.notes ?? '',
          l.notes ?? ''
        ]);
      }
    }

    final csvData = csv.encode(rows);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/workout_history.csv');
    await file.writeAsString(csvData);
    final res = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Workout History',
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
    await file.delete();
    return res.status == ShareResultStatus.success;
  }

  Future<bool> exportMeasurementsAsCsv() async {
    final dbInst = _dbHelper.dbInstance;
    final tempDir = await getTemporaryDirectory();
    final List<XFile> shareFiles = [];

    // 1. Measurements CSV
    final sessions = await _profileDb.getMeasurementSessions();
    List<List<dynamic>> measurementRows = [
      ['date', 'type', 'value', 'unit']
    ];
    for (final s in sessions) {
      for (final m in s.measurements) {
        measurementRows.add([
          DateFormat('yyyy-MM-dd').format(s.timestamp),
          m.type,
          m.value,
          m.unit
        ]);
      }
    }
    final mCsv = csv.encode(measurementRows);
    final mFile = File('${tempDir.path}/measurements.csv');
    await mFile.writeAsString(mCsv);
    shareFiles.add(XFile(mFile.path, mimeType: 'text/csv'));

    // 2. Sleep History CSV
    try {
      final sleepRows = await dbInst.customSelect('''
        SELECT a.*, s.started_at, s.ended_at
        FROM sleep_nightly_analyses a
        JOIN sleep_canonical_sessions s ON a.session_id = s.id
        ORDER BY a.night_date ASC
      ''').get();

      final stageRows = await dbInst.customSelect('''
        SELECT session_id, stage, started_at, ended_at
        FROM sleep_canonical_stage_segments
      ''').get();

      final Map<String, Map<String, double>> sessionStages = {};
      for (final row in stageRows) {
        final sessionId = row.read<String>('session_id');
        final stage = row.read<String>('stage').toLowerCase();
        final startedAt = row.read<int>('started_at');
        final endedAt = row.read<int>('ended_at');
        final minutes = (endedAt - startedAt) / 60000.0;
        sessionStages.putIfAbsent(sessionId, () => {});
        
        String canonicalStage = 'light';
        if (stage.contains('deep')) {
          canonicalStage = 'deep';
        } else if (stage.contains('rem')) {
          canonicalStage = 'rem';
        } else if (stage.contains('awake') || stage.contains('wake')) {
          canonicalStage = 'awake';
        }
        
        sessionStages[sessionId]![canonicalStage] = (sessionStages[sessionId]![canonicalStage] ?? 0.0) + minutes;
      }

      List<List<dynamic>> sleepCsvRows = [
        [
          'Date',
          'Start Time',
          'End Time',
          'Total Minutes',
          'Deep Minutes',
          'Light Minutes',
          'REM Minutes',
          'Awake Minutes',
          'Sleep Score'
        ]
      ];
      for (final r in sleepRows) {
        final sessionId = r.read<String>('session_id');
        final startTime = DateTime.fromMillisecondsSinceEpoch(r.read<int>('started_at'));
        final endTime = DateTime.fromMillisecondsSinceEpoch(r.read<int>('ended_at'));
        final stages = sessionStages[sessionId] ?? {};
        
        sleepCsvRows.add([
          r.read<String>('night_date'),
          startTime.toIso8601String(),
          endTime.toIso8601String(),
          r.readNullable<int>('total_sleep_minutes') ?? 0,
          (stages['deep'] ?? 0.0).toStringAsFixed(1),
          (stages['light'] ?? 0.0).toStringAsFixed(1),
          (stages['rem'] ?? 0.0).toStringAsFixed(1),
          (stages['awake'] ?? 0.0).toStringAsFixed(1),
          r.readNullable<double>('score') ?? 0.0
        ]);
      }
      final sCsv = csv.encode(sleepCsvRows);
      final sFile = File('${tempDir.path}/sleep_history.csv');
      await sFile.writeAsString(sCsv);
      shareFiles.add(XFile(sFile.path, mimeType: 'text/csv'));
    } catch (_) {}

    // 3. Steps History CSV
    try {
      final stepRows = await dbInst.customSelect('''
        SELECT 
          date(datetime(start_at, 'unixepoch', 'localtime')) AS day_local,
          SUM(step_count) AS total_steps,
          COALESCE(source_id, provider) AS source_key
        FROM health_step_segments
        GROUP BY day_local, source_key
        ORDER BY day_local ASC
      ''').get();

      List<List<dynamic>> stepsCsvRows = [
        ['Date', 'Total Steps', 'Core Source Origin']
      ];
      for (final r in stepRows) {
        stepsCsvRows.add([
          r.read<String>('day_local'),
          r.read<int>('total_steps'),
          r.read<String>('source_key')
        ]);
      }
      final stepsCsvStr = csv.encode(stepsCsvRows);
      final stepsFile = File('${tempDir.path}/steps_history.csv');
      await stepsFile.writeAsString(stepsCsvStr);
      shareFiles.add(XFile(stepsFile.path, mimeType: 'text/csv'));
    } catch (_) {}

    // 4. Heart Rate History CSV
    try {
      final baselineRows = await dbInst.customSelect('''
        SELECT bucket_start_ms, min_bpm, max_bpm, sum_bpm, sample_count
        FROM pulse_hourly_aggregates
        ORDER BY bucket_start_ms ASC
      ''').get();

      final workoutList = await dbInst.customSelect('''
        SELECT id, local_id, routine_name_snapshot, start_time, end_time
        FROM workout_logs
        WHERE status = 'completed' AND end_time IS NOT NULL
      ''').get();

      List<List<dynamic>> hrCsvRows = [
        ['Date/Timestamp', 'Context', 'Min BPM', 'Max BPM', 'Avg BPM']
      ];
      for (final r in baselineRows) {
        final t = DateTime.fromMillisecondsSinceEpoch(r.read<int>('bucket_start_ms'));
        final count = r.read<num>('sample_count').toInt();
        final avg = count > 0 ? r.read<double>('sum_bpm') / count : 0.0;
        hrCsvRows.add([
          t.toIso8601String(),
          'Daily Baseline',
          r.read<double>('min_bpm'),
          r.read<double>('max_bpm'),
          avg.toStringAsFixed(1)
        ]);
      }

      for (final w in workoutList) {
        final wId = w.read<String>('id');
        final startTime = DateTime.fromMillisecondsSinceEpoch(w.read<int>('start_time'));
        final endTime = DateTime.fromMillisecondsSinceEpoch(w.read<int>('end_time'));
        final hr = await _getWorkoutHeartRate(wId, startTime, endTime);
        if (hr != null) {
          hrCsvRows.add([
            startTime.toIso8601String(),
            'Workout Session ID: $wId',
            hr['min']!,
            hr['max']!,
            hr['avg']!.toStringAsFixed(1)
          ]);
        }
      }
      final hrCsvStr = csv.encode(hrCsvRows);
      final hrFile = File('${tempDir.path}/heart_rate_history.csv');
      await hrFile.writeAsString(hrCsvStr);
      shareFiles.add(XFile(hrFile.path, mimeType: 'text/csv'));
    } catch (_) {}

    if (shareFiles.isEmpty) return false;

    final res = await SharePlus.instance.share(
      ShareParams(
        files: shareFiles,
        subject: 'Measurements & Activity History',
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
    for (final f in shareFiles) {
      final file = File(f.path);
      if (await file.exists()) await file.delete();
    }
    return res.status == ShareResultStatus.success;
  }

  static Future<Directory> resolveWritableBackupDirectory({
    required Directory docsDir,
    String? dirPath,
    String? savedDir,
    String? externalFallbackDir,
  }) async {
    final defaultDir = Directory(p.join(docsDir.path, 'backups'));
    final candidates = <String>[
      if (dirPath != null && dirPath.trim().isNotEmpty) dirPath.trim(),
      if (savedDir != null && savedDir.trim().isNotEmpty) savedDir.trim(),
      if (externalFallbackDir != null && externalFallbackDir.trim().isNotEmpty)
        externalFallbackDir.trim(),
      defaultDir.path,
    ];

    for (final candidate in candidates) {
      final directory = Directory(candidate);
      try {
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final probe = File(p.join(directory.path, '.train-libre-write-probe'));
        await probe.writeAsString('ok', flush: true);
        if (await probe.exists()) {
          await probe.delete();
        }
        return directory;
      } catch (e) {
        debugPrint('Auto-backup directory not writable ($candidate): $e');
      }
    }

    throw const FileSystemException('No writable auto-backup directory found');
  }
}

@visibleForTesting
Future<String> encodeBackupJsonPayloadForTesting(
  Map<String, dynamic> payload,
) {
  return compute(jsonEncode, payload);
}

@visibleForTesting
Future<Map<String, dynamic>> decodeBackupJsonPayloadForTesting(
    String source) async {
  final decoded = await compute(jsonDecode, source);
  if (decoded is! Map) {
    throw const FormatException('Backup JSON root must be an object.');
  }
  return decoded.cast<String, dynamic>();
}
