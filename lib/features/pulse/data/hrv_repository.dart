import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart';
import '../application/pulse_tracking_service.dart';

import '../domain/hrv_models.dart';
export '../domain/hrv_models.dart';

/// HRV is opt-in through the existing pulse setting. HealthKit cannot tell us
/// whether an empty response means no data or a denied read permission.
class HealthHrvRepository {
  HealthHrvRepository({
    this.database,
    PulseTrackingSettingsService? trackingService,
    MethodChannel? channel,
    bool? isIos,
  }) : _tracking = trackingService ?? PulseTrackingService(),
       _channel = channel ?? const MethodChannel('trainlibre.health/steps'),
       _isIos = isIos ?? Platform.isIOS;
  final AppDatabase? database;
  final PulseTrackingSettingsService _tracking;
  final MethodChannel _channel;
  final bool _isIos;
  static const _requestedKey = 'pulse_hrv_authorization_requested_v1';
  static Future<void>? _authorizationInFlight;

  Future<void> _ensureAuthorization() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_requestedKey) == true) return;
    await (_authorizationInFlight ??= () async {
      try {
        // This requests only types that have not previously been requested.
        if (await _tracking.requestPermissions()) {
          await prefs.setBool(_requestedKey, true);
        }
      } finally {
        _authorizationInFlight = null;
      }
    }());
  }

  Future<HrvSummary> getSummary({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    if (!_isIos) {
      return const HrvSummary(state: HrvState.unavailable, samples: []);
    }
    if (!await _tracking.isTrackingEnabled()) {
      return const HrvSummary(state: HrvState.disabled, samples: []);
    }
    if (!toUtc.isAfter(fromUtc)) {
      return const HrvSummary(state: HrvState.noData, samples: []);
    }
    final db = database ?? await DatabaseHelper.instance.database;
    await db.customStatement('''CREATE TABLE IF NOT EXISTS pulse_hrv_samples (
      native_id TEXT PRIMARY KEY NOT NULL, source_id TEXT NOT NULL,
      start_ms INTEGER NOT NULL, end_ms INTEGER NOT NULL, sdnn_ms REAL NOT NULL
    )''');
    try {
      await _ensureAuthorization();
      final rows =
          await _channel.invokeListMethod<dynamic>('readHrvSamples', {
            'fromUtcIso': fromUtc.toUtc().toIso8601String(),
            'toUtcIso': toUtc.toUtc().toIso8601String(),
          }) ??
          [];
      final parsed = <HrvSample>[];
      for (final value in rows) {
        if (value is! Map) continue;
        final row = Map<dynamic, dynamic>.from(value);
        final startText = row['startUtcIso'];
        final endText = row['endUtcIso'];
        final rawMs = row['sdnnMs'];
        final rawId = row['nativeId'];
        final start = startText is String
            ? DateTime.tryParse(startText)?.toUtc()
            : null;
        final end = endText is String
            ? DateTime.tryParse(endText)?.toUtc()
            : null;
        final ms = rawMs is num ? rawMs.toDouble() : null;
        final id = rawId is String ? rawId : null;
        if (start == null ||
            start.isBefore(fromUtc) ||
            !start.isBefore(toUtc) ||
            end == null ||
            end.isBefore(start) ||
            ms == null ||
            !ms.isFinite ||
            ms <= 0 ||
            id == null ||
            id.isEmpty) {
          continue;
        }
        parsed.add(
          HrvSample(
            startUtc: start,
            endUtc: end,
            sdnnMs: ms,
            sourceId: row['sourceId'] is String
                ? row['sourceId'] as String
                : '',
            nativeId: id,
          ),
        );
      }
      if (!await _tracking.isTrackingEnabled()) {
        return const HrvSummary(state: HrvState.disabled, samples: []);
      }
      // An empty result may mean denied access; never delete cached records on it.
      await db.transaction(() async {
        for (final sample in parsed) {
          await db.customStatement(
            'INSERT OR REPLACE INTO pulse_hrv_samples (native_id, source_id, start_ms, end_ms, sdnn_ms) VALUES (?, ?, ?, ?, ?)',
            [
              sample.nativeId,
              sample.sourceId,
              sample.startUtc.millisecondsSinceEpoch,
              sample.endUtc.millisecondsSinceEpoch,
              sample.sdnnMs,
            ],
          );
        }
      });
      // Display the current HealthKit result, not stale cached measurements.
      // An empty response can reflect revoked/limited authorization or deletion.
      final unique = <String, HrvSample>{
        for (final sample in parsed) sample.nativeId: sample,
      };
      final samples = unique.values.toList()
        ..sort((a, b) => a.startUtc.compareTo(b.startUtc));
      return HrvSummary(
        state: samples.isEmpty ? HrvState.noData : HrvState.available,
        samples: samples,
      );
    } catch (_) {
      return const HrvSummary(state: HrvState.queryFailed, samples: []);
    }
  }
}
