import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/database_helper.dart';
import '../../data/drift_database.dart' as db_model;

class HealthNutritionDay {
  const HealthNutritionDay({
    required this.day,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sugar,
    this.fiber,
    this.salt,
  });

  final DateTime day;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? sugar;
  final double? fiber;
  final double? salt;

  String get externalId =>
      'nutrition-day:${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  String get fingerprint => sha256
      .convert(
        utf8.encode(
          [
            day.toIso8601String(),
            calories,
            protein,
            carbs,
            fat,
            sugar,
            fiber,
            salt,
          ].join('|'),
        ),
      )
      .toString();

  factory HealthNutritionDay.fromMap(Map<dynamic, dynamic> map) {
    double value(String key) => ((map[key] as num?) ?? 0).toDouble();
    double? optional(String key) => (map[key] as num?)?.toDouble();
    final rawDay = DateTime.parse(map['day'] as String);
    return HealthNutritionDay(
      day: DateTime(rawDay.year, rawDay.month, rawDay.day),
      calories: value('calories'),
      protein: value('protein'),
      carbs: value('carbs'),
      fat: value('fat'),
      sugar: optional('sugar'),
      fiber: optional('fiber'),
      salt: optional('salt'),
    );
  }
}

class HealthNutritionImportStatus {
  const HealthNutritionImportStatus({
    required this.available,
    required this.readGranted,
    this.historyAvailable = true,
    this.historyGranted = true,
  });

  final bool available;
  final bool readGranted;
  final bool historyAvailable;
  final bool historyGranted;
  bool get limitedHistory => !historyAvailable || !historyGranted;

  factory HealthNutritionImportStatus.fromMap(Map<dynamic, dynamic> map) =>
      HealthNutritionImportStatus(
        available: map['available'] == true,
        readGranted: map['readGranted'] == true,
        historyAvailable: map['historyAvailable'] != false,
        historyGranted: map['historyGranted'] != false,
      );
}

class HealthNutritionImportResult {
  const HealthNutritionImportResult({
    required this.imported,
    required this.updated,
    required this.unchanged,
    required this.skippedLocalChanges,
    required this.limitedHistory,
  });

  final int imported;
  final int updated;
  final int unchanged;
  final int skippedLocalChanges;
  final bool limitedHistory;
}

class HealthNutritionImportService {
  HealthNutritionImportService({bool? isIos, DatabaseHelper? databaseHelper})
    : _isIos = isIos ?? Platform.isIOS,
      _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  static const _enabledKey = 'health_nutrition_import_enabled';
  static const _iosChannel = MethodChannel(
    'trainlibre.health/import_nutrition_apple_health',
  );
  static const _androidChannel = MethodChannel(
    'trainlibre.health/import_nutrition_health_connect',
  );

  final bool _isIos;
  final DatabaseHelper _dbHelper;
  MethodChannel get _channel => _isIos ? _iosChannel : _androidChannel;
  String get _platform => _isIos ? 'appleHealth' : 'healthConnect';

  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_enabledKey) ?? false;

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<HealthNutritionImportStatus> getStatus() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getStatus');
    return HealthNutritionImportStatus.fromMap(raw ?? const {});
  }

  Future<HealthNutritionImportResult?> requestAccessAndImport() async {
    final granted =
        await _channel.invokeMethod<bool>('requestPermissions') == true;
    await setEnabled(granted);
    return granted ? importNow() : null;
  }

  Future<HealthNutritionImportResult?> importIfEnabled({
    bool force = false,
  }) async {
    if (!await isEnabled()) return null;
    final prefs = await SharedPreferences.getInstance();
    final lastRun = DateTime.tryParse(
      prefs.getString('health_nutrition_import_last_run') ?? '',
    );
    if (!force &&
        lastRun != null &&
        DateTime.now().difference(lastRun) < const Duration(hours: 6)) {
      return null;
    }
    return importNow();
  }

  Future<HealthNutritionImportResult?> importNow() async {
    final status = await getStatus();
    if (!status.available || !status.readGranted) return null;
    final now = DateTime.now().toUtc();
    final from = status.limitedHistory
        ? now.subtract(const Duration(days: 30))
        : DateTime.utc(1970);
    final raw = await _channel.invokeMethod<List<dynamic>>(
      'readNutritionDays',
      {'fromUtcIso': from.toIso8601String(), 'toUtcIso': now.toIso8601String()},
    );
    var imported = 0;
    var updated = 0;
    var unchanged = 0;
    var skippedLocalChanges = 0;
    for (final row in raw ?? const <dynamic>[]) {
      final day = HealthNutritionDay.fromMap(row as Map<dynamic, dynamic>);
      final result = await _upsert(day);
      switch (result) {
        case _ImportOutcome.imported:
          imported++;
          break;
        case _ImportOutcome.updated:
          updated++;
          break;
        case _ImportOutcome.unchanged:
          unchanged++;
          break;
        case _ImportOutcome.localChange:
          skippedLocalChanges++;
          break;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'health_nutrition_import_last_run',
      DateTime.now().toIso8601String(),
    );
    return HealthNutritionImportResult(
      imported: imported,
      updated: updated,
      unchanged: unchanged,
      skippedLocalChanges: skippedLocalChanges,
      limitedHistory: status.limitedHistory,
    );
  }

  Future<_ImportOutcome> _upsert(HealthNutritionDay day) async {
    final database = await _dbHelper.database;
    final timestamp = day.day;
    return database.transaction(() async {
      final existing = await database
          .customSelect(
            '''SELECT local_macro_entry_id, payload_fingerprint, sync_state
           FROM health_nutrition_import_records
           WHERE platform = ? AND external_record_id = ?''',
            variables: [
              drift.Variable.withString(_platform),
              drift.Variable.withString(day.externalId),
            ],
          )
          .getSingleOrNull();
      if (existing != null) {
        final state = existing.read<String>('sync_state');
        if (state != 'active') return _ImportOutcome.localChange;
        if (existing.read<String>('payload_fingerprint') == day.fingerprint) {
          return _ImportOutcome.unchanged;
        }
        final id = existing.read<String>('local_macro_entry_id');
        await (database.update(
          database.macroEntries,
        )..where((row) => row.id.equals(id))).write(
          db_model.MacroEntriesCompanion(
            consumedAt: drift.Value(timestamp),
            name: drift.Value(_displayName),
            calories: drift.Value(day.calories),
            protein: drift.Value(day.protein),
            carbs: drift.Value(day.carbs),
            fat: drift.Value(day.fat),
            sugar: drift.Value(day.sugar),
            fiber: drift.Value(day.fiber),
            salt: drift.Value(day.salt),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
        await database.customStatement(
          '''UPDATE health_nutrition_import_records
             SET payload_fingerprint = ?, imported_at = ?
             WHERE platform = ? AND external_record_id = ?''',
          [
            day.fingerprint,
            DateTime.now().millisecondsSinceEpoch,
            _platform,
            day.externalId,
          ],
        );
        return _ImportOutcome.updated;
      }

      final id = const Uuid().v4();
      await database
          .into(database.macroEntries)
          .insert(
            db_model.MacroEntriesCompanion.insert(
              id: drift.Value(id),
              consumedAt: timestamp,
              mealType: 'mealtypeSnack',
              name: drift.Value(_displayName),
              amount: const drift.Value(null),
              amountUnit: const drift.Value(null),
              isFluid: const drift.Value(false),
              calories: day.calories,
              protein: day.protein,
              carbs: day.carbs,
              fat: day.fat,
              sugar: drift.Value(day.sugar),
              fiber: drift.Value(day.fiber),
              salt: drift.Value(day.salt),
              caffeine: const drift.Value(null),
              calculatedNutrient: 'calories',
            ),
          );
      await database.customStatement(
        '''INSERT INTO health_nutrition_import_records
           (platform, external_record_id, local_macro_entry_id,
            payload_fingerprint, sync_state, imported_at)
           VALUES (?, ?, ?, ?, 'active', ?)''',
        [
          _platform,
          day.externalId,
          id,
          day.fingerprint,
          DateTime.now().millisecondsSinceEpoch,
        ],
      );
      return _ImportOutcome.imported;
    });
  }

  String get _displayName => _isIos ? 'Apple Health' : 'Health Connect';
}

enum _ImportOutcome { imported, updated, unchanged, localChange }
