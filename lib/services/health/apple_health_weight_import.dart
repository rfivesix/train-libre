import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database_helper.dart';
import '../../data/drift_database.dart' as db_model;
import 'health_connect_weight_import.dart';

class AppleHealthWeightRecord {
  const AppleHealthWeightRecord({
    required this.recordId,
    required this.timestampUtc,
    required this.weightKg,
    required this.sourceBundleId,
    this.measurementType = 'weight',
    this.unit = 'kg',
  });

  final String recordId;
  final DateTime timestampUtc;
  final double weightKg;
  final String sourceBundleId;
  final String measurementType;
  final String unit;

  String get fingerprint => sha256
      .convert(utf8.encode(
        '$timestampUtc|${weightKg.toStringAsPrecision(15)}|$sourceBundleId',
      ))
      .toString();

  factory AppleHealthWeightRecord.fromMap(Map<dynamic, dynamic> map) =>
      AppleHealthWeightRecord(
        recordId: map['recordId'] as String,
        timestampUtc: DateTime.parse(map['timestampUtcIso'] as String).toUtc(),
        weightKg:
            ((map['value'] as num?) ?? (map['weightKg'] as num)).toDouble(),
        sourceBundleId: map['sourceBundleId'] as String? ?? '',
        measurementType: map['measurementType'] as String? ?? 'weight',
        unit: map['unit'] as String? ?? 'kg',
      );
}

class AppleHealthWeightImportPlatform {
  static const MethodChannel _channel =
      MethodChannel('trainlibre.health/import_weight_apple_health');

  Future<HealthConnectWeightImportStatus> getStatus() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getStatus');
    return HealthConnectWeightImportStatus.fromMap(raw ?? const {});
  }

  Future<bool> requestPermissions() async =>
      (await _channel.invokeMethod<bool>('requestPermissions')) == true;

  Future<List<AppleHealthWeightRecord>> readWeights({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final raw = await _channel.invokeMethod<List<dynamic>>('readWeights', {
      'fromUtcIso': fromUtc.toUtc().toIso8601String(),
      'toUtcIso': toUtc.toUtc().toIso8601String(),
    });
    return (raw ?? const [])
        .map((row) =>
            AppleHealthWeightRecord.fromMap(row as Map<dynamic, dynamic>))
        .toList(growable: false);
  }
}

/// Imports weight records from other Apple Health sources. HealthKit samples
/// are immutable, so their UUID is a stable identity and a changed source
/// value arrives as a new sample instead of mutating an existing one.
class AppleHealthWeightImportService implements WeightImportService {
  static const _enabledKey = 'apple_health_weight_import_enabled';

  AppleHealthWeightImportService({
    AppleHealthWeightImportPlatform? platform,
    DatabaseHelper? databaseHelper,
    bool? isIOS,
  })  : _platform = platform ?? AppleHealthWeightImportPlatform(),
        _dbHelper = databaseHelper ?? DatabaseHelper.instance,
        _isIOS = isIOS ?? Platform.isIOS;

  final AppleHealthWeightImportPlatform _platform;
  final DatabaseHelper _dbHelper;
  final bool _isIOS;

  @override
  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_enabledKey) ?? false;

  @override
  Future<void> setEnabled(bool enabled) async {
    await (await SharedPreferences.getInstance()).setBool(_enabledKey, enabled);
  }

  @override
  Future<HealthConnectWeightImportStatus> getStatus() => _platform.getStatus();

  @override
  Future<HealthConnectWeightImportResult?> requestAccessAndImport() async {
    if (!_isIOS) return null;
    final granted = await _platform.requestPermissions();
    await setEnabled(granted);
    if (!granted) return null;
    try {
      return await importNow();
    } on PlatformException {
      // HealthKit deliberately does not disclose read authorization in the
      // request callback. A denied read is only observable by the first
      // query, so do not leave the Settings switch falsely enabled.
      await setEnabled(false);
      rethrow;
    }
  }

  @override
  Future<HealthConnectWeightImportResult?> importOnColdStart() async {
    if (!_isIOS || !await isEnabled()) return null;
    return importNow();
  }

  @override
  Future<HealthConnectWeightImportResult?> importNow() async {
    if (!_isIOS) return null;
    final status = await _platform.getStatus();
    if (!status.available || !status.readGranted) return null;
    final records = await _platform.readWeights(
      fromUtc: DateTime.utc(1970),
      toUtc: DateTime.now().toUtc(),
    );
    var imported = 0;
    for (final record in records) {
      if (await _upsert(record) == _AppleWeightUpsert.imported) imported++;
    }
    return HealthConnectWeightImportResult(
      imported: imported,
      updated: 0,
      limitedHistory: false,
    );
  }

  Future<_AppleWeightUpsert> _upsert(AppleHealthWeightRecord record) async {
    final db = await _dbHelper.database;
    return db.transaction(() async {
      final existing = await db.customSelect(
        '''SELECT local_measurement_id FROM health_import_records
           WHERE platform = ? AND domain = ? AND external_record_id = ?''',
        variables: [
          drift.Variable.withString('appleHealth'),
          drift.Variable.withString(record.measurementType),
          drift.Variable.withString(record.recordId),
        ],
      ).getSingleOrNull();
      if (existing != null) return _AppleWeightUpsert.unchanged;
      final row = await db.into(db.measurements).insertReturning(
            db_model.MeasurementsCompanion.insert(
              type: record.measurementType,
              value: record.weightKg,
              unit: record.unit,
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
          'appleHealth',
          record.measurementType,
          record.recordId,
          row.localId,
          null,
          record.fingerprint,
        ],
      );
      return _AppleWeightUpsert.imported;
    });
  }
}

enum _AppleWeightUpsert { imported, unchanged }
