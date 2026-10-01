import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database_helper.dart';
import '../../data/drift_database.dart' as db_model;

/// The native bridge deliberately returns raw Health Connect identity and
/// revision metadata.  Keeping it separate from the UI prevents imported
/// values from accidentally looking like manually entered measurements.
class HealthConnectWeightRecord {
  const HealthConnectWeightRecord({
    required this.recordId,
    required this.lastModifiedAtUtc,
    required this.timestampUtc,
    required this.weightKg,
    required this.sourcePackageName,
  });

  final String recordId;
  final DateTime? lastModifiedAtUtc;
  final DateTime timestampUtc;
  final double weightKg;
  final String sourcePackageName;

  String get fingerprint => sha256
      .convert(utf8.encode(
          '$timestampUtc|${weightKg.toStringAsPrecision(15)}|$sourcePackageName'))
      .toString();

  factory HealthConnectWeightRecord.fromMap(Map<dynamic, dynamic> map) =>
      HealthConnectWeightRecord(
        recordId: map['recordId'] as String,
        lastModifiedAtUtc:
            DateTime.tryParse(map['lastModifiedAtUtcIso'] as String? ?? '')
                ?.toUtc(),
        timestampUtc: DateTime.parse(map['timestampUtcIso'] as String).toUtc(),
        weightKg: (map['weightKg'] as num).toDouble(),
        sourcePackageName: map['sourcePackageName'] as String? ?? '',
      );
}

class HealthConnectWeightImportStatus {
  const HealthConnectWeightImportStatus({
    required this.available,
    required this.historyAvailable,
    required this.readGranted,
    required this.historyGranted,
  });

  final bool available;
  final bool historyAvailable;
  final bool readGranted;
  final bool historyGranted;

  bool get isLimited => !historyAvailable || !historyGranted;

  factory HealthConnectWeightImportStatus.fromMap(Map<dynamic, dynamic> map) =>
      HealthConnectWeightImportStatus(
        available: map['available'] == true,
        historyAvailable: map['historyAvailable'] == true,
        readGranted: map['readGranted'] == true,
        historyGranted: map['historyGranted'] == true,
      );
}

class HealthConnectWeightImportPlatform {
  static const MethodChannel _channel =
      MethodChannel('trainlibre.health/import_weight_health_connect');

  Future<HealthConnectWeightImportStatus> getStatus() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getStatus');
    return HealthConnectWeightImportStatus.fromMap(raw ?? const {});
  }

  Future<bool> requestPermissions() async =>
      (await _channel.invokeMethod<bool>('requestPermissions')) == true;

  Future<List<HealthConnectWeightRecord>> readWeights({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final raw = await _channel.invokeMethod<List<dynamic>>('readWeights', {
      'fromUtcIso': fromUtc.toUtc().toIso8601String(),
      'toUtcIso': toUtc.toUtc().toIso8601String(),
    });
    return (raw ?? const [])
        .map((row) =>
            HealthConnectWeightRecord.fromMap(row as Map<dynamic, dynamic>))
        .toList(growable: false);
  }
}

class HealthConnectWeightImportResult {
  const HealthConnectWeightImportResult({
    required this.imported,
    required this.updated,
    required this.limitedHistory,
  });
  final int imported;
  final int updated;
  final bool limitedHistory;
}

/// Kaltstart-Import only.  A full scan is intentional: #669 deliberately does
/// not introduce Changes tokens, and a full scan is what lets old scale values
/// be updated safely.
class HealthConnectWeightImportService {
  static const _enabledKey = 'health_connect_weight_import_enabled';

  HealthConnectWeightImportService({
    HealthConnectWeightImportPlatform? platform,
    DatabaseHelper? databaseHelper,
    bool? isAndroid,
  })  : _platform = platform ?? HealthConnectWeightImportPlatform(),
        _dbHelper = databaseHelper ?? DatabaseHelper.instance,
        _isAndroid = isAndroid ?? Platform.isAndroid;

  final HealthConnectWeightImportPlatform _platform;
  final DatabaseHelper _dbHelper;
  final bool _isAndroid;

  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_enabledKey) ?? false;

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<HealthConnectWeightImportStatus> getStatus() => _platform.getStatus();

  Future<HealthConnectWeightImportResult?> requestAccessAndImport() async {
    if (!_isAndroid) return null;
    final granted = await _platform.requestPermissions();
    await setEnabled(granted);
    if (!granted) return null;
    return importNow();
  }

  Future<HealthConnectWeightImportResult?> importOnColdStart() async {
    if (!_isAndroid) return null;
    if (!await isEnabled()) return null;
    return importNow();
  }

  Future<HealthConnectWeightImportResult?> importNow() async {
    if (!_isAndroid) return null;
    final status = await _platform.getStatus();
    if (!status.available || !status.readGranted) return null;
    final now = DateTime.now().toUtc();
    final from = status.isLimited
        ? now.subtract(const Duration(days: 30))
        : DateTime.utc(1970);
    final records = await _platform.readWeights(fromUtc: from, toUtc: now);
    var imported = 0;
    var updated = 0;
    for (final record in records) {
      final result = await _upsert(record);
      if (result == _WeightUpsert.imported) imported++;
      if (result == _WeightUpsert.updated) updated++;
    }
    return HealthConnectWeightImportResult(
      imported: imported,
      updated: updated,
      limitedHistory: status.isLimited,
    );
  }

  Future<_WeightUpsert> _upsert(HealthConnectWeightRecord record) async {
    final db = await _dbHelper.database;
    return db.transaction(() async {
      final existing = await db.customSelect(
        '''SELECT local_measurement_id, last_modified_at, payload_fingerprint
           FROM health_import_records
           WHERE platform = ? AND domain = ? AND external_record_id = ?''',
        variables: [
          drift.Variable.withString('healthConnect'),
          drift.Variable.withString('weight'),
          drift.Variable.withString(record.recordId),
        ],
      ).getSingleOrNull();
      final modifiedMillis = record.lastModifiedAtUtc?.millisecondsSinceEpoch;
      if (existing == null) {
        final row = await db.into(db.measurements).insertReturning(
              db_model.MeasurementsCompanion.insert(
                type: 'weight',
                value: record.weightKg,
                unit: 'kg',
                date: record.timestampUtc,
                legacySessionId: drift.Value(
                  record.timestampUtc.millisecondsSinceEpoch,
                ),
              ),
            );
        await db.customStatement(
          '''INSERT INTO health_import_records
             (platform, domain, external_record_id, local_measurement_id, last_modified_at, payload_fingerprint)
             VALUES (?, ?, ?, ?, ?, ?)''',
          [
            'healthConnect',
            'weight',
            record.recordId,
            row.localId,
            modifiedMillis,
            record.fingerprint
          ],
        );
        return _WeightUpsert.imported;
      }
      final previousModified = existing.readNullable<int>('last_modified_at');
      final previousFingerprint = existing.read<String>('payload_fingerprint');
      final changed = (modifiedMillis != null &&
              (previousModified == null ||
                  modifiedMillis > previousModified)) ||
          ((modifiedMillis == null || modifiedMillis == previousModified) &&
              previousFingerprint != record.fingerprint);
      if (!changed) return _WeightUpsert.unchanged;
      await (db.update(db.measurements)
            ..where((table) => table.localId
                .equals(existing.read<int>('local_measurement_id'))))
          .write(
        db_model.MeasurementsCompanion(
          value: drift.Value(record.weightKg),
          date: drift.Value(record.timestampUtc),
          legacySessionId: drift.Value(
            record.timestampUtc.millisecondsSinceEpoch,
          ),
          updatedAt: drift.Value(DateTime.now().toUtc()),
        ),
      );
      await db.customStatement(
        '''UPDATE health_import_records SET last_modified_at = ?, payload_fingerprint = ?
           WHERE platform = ? AND domain = ? AND external_record_id = ?''',
        [
          modifiedMillis,
          record.fingerprint,
          'healthConnect',
          'weight',
          record.recordId
        ],
      );
      return _WeightUpsert.updated;
    });
  }
}

enum _WeightUpsert { imported, updated, unchanged }
