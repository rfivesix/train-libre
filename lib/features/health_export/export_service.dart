import 'contracts/health_export_adapter.dart';
import 'data/health_export_data_source.dart';
import 'data/health_export_identity_store.dart';
import 'data/health_export_status_store.dart';
import 'models/export_models.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../services/telemetry/telemetry_service.dart';

class HealthExportResult {
  const HealthExportResult({
    required this.platform,
    required this.success,
    this.message,
  });

  final HealthExportPlatform platform;
  final bool success;
  final String? message;
}

class _DomainExportOutcome {
  const _DomainExportOutcome({required this.success, this.error});

  final bool success;
  final String? error;
}

class HealthExportService {
  static const int maxWriteBatchSize = 1000;

  HealthExportService({
    required List<HealthExportAdapter> adapters,
    HealthExportDataSource? dataSource,
    HealthExportStatusStore? statusStore,
    HealthExportIdentityStore? identityStore,
  })  : _adapters = {for (final adapter in adapters) adapter.platform: adapter},
        _dataSource = dataSource ?? HealthExportDataSource(),
        _statusStore = statusStore ?? HealthExportStatusStore(),
        _identityStore = identityStore ?? HealthExportIdentityStore();

  final Map<HealthExportPlatform, HealthExportAdapter> _adapters;
  final HealthExportDataSource _dataSource;
  final HealthExportStatusStore _statusStore;
  final HealthExportIdentityStore _identityStore;

  Future<void> setPlatformEnabled(
    HealthExportPlatform platform,
    bool enabled,
  ) async {
    await _statusStore.setPlatformEnabled(platform, enabled);
    for (final domain in HealthExportDomain.values) {
      await _statusStore.markDomainState(
        platform: platform,
        domain: domain,
        state: enabled ? HealthExportState.idle : HealthExportState.disabled,
        lastError: null,
      );
    }
  }

  Future<bool> isPlatformEnabled(HealthExportPlatform platform) {
    return _statusStore.isPlatformEnabled(platform);
  }

  Future<Map<HealthExportPlatform, HealthExportPlatformStatus>> getStatuses() {
    return _statusStore.readStatuses();
  }

  Future<HealthExportResult> requestPermissions(
    HealthExportPlatform platform,
  ) async {
    final adapter = _adapters[platform];
    if (adapter == null) {
      return HealthExportResult(
        platform: platform,
        success: false,
        message: 'Adapter unavailable',
      );
    }

    try {
      final availability = await adapter.getAvailability();
      if (availability != HealthExportAvailability.available) {
        await setPlatformEnabled(platform, false);
        return HealthExportResult(
          platform: platform,
          success: false,
          message: availability == HealthExportAvailability.notInstalled
              ? 'Platform not installed'
              : 'Platform unavailable',
        );
      }

      final granted = await adapter.requestPermissions();
      if (!granted) {
        await setPlatformEnabled(platform, false);
        return HealthExportResult(
          platform: platform,
          success: false,
          message: 'Permission denied',
        );
      }

      await setPlatformEnabled(platform, true);
      return HealthExportResult(platform: platform, success: true);
    } on PlatformException catch (error) {
      await _statusStore.setPlatformEnabled(platform, false);
      final state = _isPermissionDenied(error)
          ? HealthExportState.permissionRequired
          : HealthExportState.failed;
      for (final domain in HealthExportDomain.values) {
        await _statusStore.markDomainState(
          platform: platform,
          domain: domain,
          state: state,
          lastError: error.toString(),
        );
      }
      return HealthExportResult(
        platform: platform,
        success: false,
        message: _isPermissionDenied(error)
            ? 'Permission denied'
            : error.message ?? 'Platform unavailable',
      );
    }
  }

  Future<HealthExportResult> exportNow(
    HealthExportPlatform platform, {
    int? lookbackDays,
  }) async {
    final adapter = _adapters[platform];
    if (adapter == null) {
      return HealthExportResult(
        platform: platform,
        success: false,
        message: 'Adapter unavailable',
      );
    }

    final enabled = await _statusStore.isPlatformEnabled(platform);
    if (!enabled) {
      return HealthExportResult(
        platform: platform,
        success: false,
        message: 'Export disabled',
      );
    }

    final availability = await adapter.getAvailability();
    if (availability != HealthExportAvailability.available) {
      await setPlatformEnabled(platform, false);
      return HealthExportResult(
        platform: platform,
        success: false,
        message: availability == HealthExportAvailability.notInstalled
            ? 'Platform not installed'
            : 'Platform unavailable',
      );
    }

    final statuses = await _statusStore.readStatuses();
    final platformStatus =
        statuses[platform] ?? HealthExportPlatformStatus.initial(platform);
    final checkpoints = _domainIncrementalCheckpoints(platformStatus);
    // Advance successful checkpoints only to the instant before the payload
    // snapshot. Mutations arriving while native writes are in flight then stay
    // eligible for the coordinator's queued rerun instead of being skipped.
    final nowUtc = DateTime.now().toUtc();
    // Drift's SQLite DateTime columns are second-precision. Round down and
    // overlap by one second so a write in the boundary second cannot compare
    // older than the persisted checkpoint. Fingerprints suppress duplicates.
    final exportBoundaryUtc = DateTime.fromMillisecondsSinceEpoch(
      (nowUtc.millisecondsSinceEpoch ~/ 1000) * 1000,
      isUtc: true,
    ).subtract(const Duration(seconds: 1));

    final measurementsPayload = await _dataSource.loadMeasurements(
      options: HealthExportLoadOptions(
        // Per-domain incremental cutoff:
        // null checkpoint => full-history backfill only for this domain.
        lookbackDays: checkpoints[HealthExportDomain.measurements] == null
            ? null
            : lookbackDays,
        updatedSinceUtc: checkpoints[HealthExportDomain.measurements],
        platform: platform,
      ),
    );
    final nutritionPayload = await _dataSource.loadNutrition(
      options: HealthExportLoadOptions(
        lookbackDays: checkpoints[HealthExportDomain.nutritionHydration] == null
            ? null
            : lookbackDays,
        updatedSinceUtc: checkpoints[HealthExportDomain.nutritionHydration],
        platform: platform,
      ),
    );
    final hydrationPayload = await _dataSource.loadHydration(
      options: HealthExportLoadOptions(
        lookbackDays: checkpoints[HealthExportDomain.nutritionHydration] == null
            ? null
            : lookbackDays,
        updatedSinceUtc: checkpoints[HealthExportDomain.nutritionHydration],
        platform: platform,
      ),
    );
    final workoutsPayload = await _dataSource.loadWorkouts(
      options: HealthExportLoadOptions(
        lookbackDays: checkpoints[HealthExportDomain.workouts] == null
            ? null
            : lookbackDays,
        updatedSinceUtc: checkpoints[HealthExportDomain.workouts],
        platform: platform,
      ),
    );
    final payload = HealthExportPayload(
      measurements: measurementsPayload,
      nutrition: nutritionPayload,
      hydration: hydrationPayload,
      workouts: workoutsPayload,
    );

    final domainOutcomes = <HealthExportDomain, _DomainExportOutcome>{};

    domainOutcomes[HealthExportDomain.measurements] = await _exportDomain(
      platform: platform,
      domain: HealthExportDomain.measurements,
      successCheckpointUtc: exportBoundaryUtc,
      writer: () async {
        final pending = await _prepareRecords<ExportMeasurementRecord>(
          platform: platform,
          domain: HealthExportDomain.measurements,
          records: payload.measurements,
          keyOf: (record) => record.idempotencyKey,
          fingerprintOf: (record) => record.payloadFingerprint,
          withIdentity: (record, id, revision) =>
              record.withExportIdentity(id, revision),
        );
        final writeable = platform == HealthExportPlatform.healthConnect
            ? pending
                .where((record) => record.type != ExportMeasurementType.bmi)
                .toList(growable: false)
            : pending;
        // Android Health Connect currently does not support BMI in this writer path.
        for (final batch in _chunkRecords(writeable)) {
          await adapter.writeMeasurementsBatch(batch);
          await _commitRecords(
            platform: platform,
            domain: HealthExportDomain.measurements,
            records: batch,
            keyOf: (record) => record.idempotencyKey,
            fingerprintOf: (record) => record.payloadFingerprint,
            externalIdOf: (record) => record.externalId!,
            revisionOf: (record) => record.exportRevision!,
          );
          await _statusStore.markExported(
            platform: platform,
            domain: HealthExportDomain.measurements,
            idempotencyKeys: batch.map((record) => record.idempotencyKey),
          );
        }
      },
    );

    domainOutcomes[HealthExportDomain.nutritionHydration] = await _exportDomain(
      platform: platform,
      domain: HealthExportDomain.nutritionHydration,
      successCheckpointUtc: exportBoundaryUtc,
      writer: () async {
        final pendingNutrition = await _prepareRecords<ExportNutritionRecord>(
          platform: platform,
          domain: HealthExportDomain.nutritionHydration,
          records: payload.nutrition,
          keyOf: (record) => record.idempotencyKey,
          fingerprintOf: (record) => record.payloadFingerprint,
          withIdentity: (record, id, revision) =>
              record.withExportIdentity(id, revision),
        );
        final pendingHydration = await _prepareRecords<ExportHydrationRecord>(
          platform: platform,
          domain: HealthExportDomain.nutritionHydration,
          records: payload.hydration,
          keyOf: (record) => record.idempotencyKey,
          fingerprintOf: (record) => record.payloadFingerprint,
          withIdentity: (record, id, revision) =>
              record.withExportIdentity(id, revision),
        );

        var nutritionExportedCount = 0;
        var hydrationExportedCount = 0;
        final nutritionChunkExportedKeys = <String>[];
        final hydrationChunkExportedKeys = <String>[];
        final nutritionFailures = <String>[];
        final hydrationFailures = <String>[];

        for (final batch in _chunkRecords(pendingNutrition)) {
          try {
            await adapter.writeNutritionBatch(batch);
            await _commitRecords(
              platform: platform,
              domain: HealthExportDomain.nutritionHydration,
              records: batch,
              keyOf: (record) => record.idempotencyKey,
              fingerprintOf: (record) => record.payloadFingerprint,
              externalIdOf: (record) => record.externalId!,
              revisionOf: (record) => record.exportRevision!,
            );
            nutritionChunkExportedKeys.addAll(
              batch.map((record) => record.idempotencyKey),
            );
            nutritionExportedCount += batch.length;
          } catch (error) {
            if (_isPermissionDenied(error)) rethrow;
            for (final record in batch) {
              try {
                await adapter.writeNutrition(record);
                await _commitRecords(
                  platform: platform,
                  domain: HealthExportDomain.nutritionHydration,
                  records: [record],
                  keyOf: (item) => item.idempotencyKey,
                  fingerprintOf: (item) => item.payloadFingerprint,
                  externalIdOf: (item) => item.externalId!,
                  revisionOf: (item) => item.exportRevision!,
                );
                nutritionChunkExportedKeys.add(record.idempotencyKey);
                nutritionExportedCount += 1;
              } catch (recordError) {
                if (_isPermissionDenied(recordError)) rethrow;
                nutritionFailures.add('${record.idempotencyKey}: $recordError');
              }
            }
          }
          await _statusStore.markExported(
            platform: platform,
            domain: HealthExportDomain.nutritionHydration,
            idempotencyKeys: [
              ...nutritionChunkExportedKeys,
              ...hydrationChunkExportedKeys,
            ],
          );
          nutritionChunkExportedKeys.clear();
          hydrationChunkExportedKeys.clear();
        }
        for (final batch in _chunkRecords(pendingHydration)) {
          try {
            await adapter.writeHydrationBatch(batch);
            await _commitRecords(
              platform: platform,
              domain: HealthExportDomain.nutritionHydration,
              records: batch,
              keyOf: (record) => record.idempotencyKey,
              fingerprintOf: (record) => record.payloadFingerprint,
              externalIdOf: (record) => record.externalId!,
              revisionOf: (record) => record.exportRevision!,
            );
            hydrationChunkExportedKeys.addAll(
              batch.map((record) => record.idempotencyKey),
            );
            hydrationExportedCount += batch.length;
          } catch (error) {
            if (_isPermissionDenied(error)) rethrow;
            for (final record in batch) {
              try {
                await adapter.writeHydration(record);
                await _commitRecords(
                  platform: platform,
                  domain: HealthExportDomain.nutritionHydration,
                  records: [record],
                  keyOf: (item) => item.idempotencyKey,
                  fingerprintOf: (item) => item.payloadFingerprint,
                  externalIdOf: (item) => item.externalId!,
                  revisionOf: (item) => item.exportRevision!,
                );
                hydrationChunkExportedKeys.add(record.idempotencyKey);
                hydrationExportedCount += 1;
              } catch (recordError) {
                if (_isPermissionDenied(recordError)) rethrow;
                hydrationFailures.add('${record.idempotencyKey}: $recordError');
              }
            }
          }
          await _statusStore.markExported(
            platform: platform,
            domain: HealthExportDomain.nutritionHydration,
            idempotencyKeys: [
              ...nutritionChunkExportedKeys,
              ...hydrationChunkExportedKeys,
            ],
          );
          nutritionChunkExportedKeys.clear();
          hydrationChunkExportedKeys.clear();
        }

        if (nutritionFailures.isNotEmpty || hydrationFailures.isNotEmpty) {
          final nutritionSummary = nutritionFailures.isEmpty
              ? 'nutrition=success($nutritionExportedCount/${pendingNutrition.length})'
              : 'nutrition=failed(${pendingNutrition.length - nutritionFailures.length}/${pendingNutrition.length}, first=${nutritionFailures.first})';
          final hydrationSummary = hydrationFailures.isEmpty
              ? 'hydration=success($hydrationExportedCount/${pendingHydration.length})'
              : 'hydration=failed(${pendingHydration.length - hydrationFailures.length}/${pendingHydration.length}, first=${hydrationFailures.first})';
          throw StateError(
            'Nutrition/Hydration export details: $nutritionSummary; $hydrationSummary',
          );
        }
      },
    );

    domainOutcomes[HealthExportDomain.workouts] = await _exportDomain(
      platform: platform,
      domain: HealthExportDomain.workouts,
      successCheckpointUtc: exportBoundaryUtc,
      writer: () async {
        final pending = await _prepareRecords<ExportWorkoutRecord>(
          platform: platform,
          domain: HealthExportDomain.workouts,
          records: payload.workouts,
          keyOf: (record) => record.idempotencyKey,
          fingerprintOf: (record) => record.payloadFingerprint,
          withIdentity: (record, id, revision) =>
              record.withExportIdentity(id, revision),
        );
        for (final batch in _chunkRecords(pending)) {
          await adapter.writeWorkoutsBatch(batch);
          await _commitRecords(
            platform: platform,
            domain: HealthExportDomain.workouts,
            records: batch,
            keyOf: (record) => record.idempotencyKey,
            fingerprintOf: (record) => record.payloadFingerprint,
            externalIdOf: (record) => record.externalId!,
            revisionOf: (record) => record.exportRevision!,
          );
          await _statusStore.markExported(
            platform: platform,
            domain: HealthExportDomain.workouts,
            idempotencyKeys: batch.map((record) => record.idempotencyKey),
          );
        }
      },
    );

    final success = domainOutcomes.values.every((value) => value.success);
    final message = success
        ? null
        : domainOutcomes.entries
            .where((entry) => !entry.value.success)
            .map(
              (entry) =>
                  '${entry.key.name} failed${entry.value.error == null ? '' : ': ${entry.value.error}'}',
            )
            .join(' | ');
    if (success) {
      unawaited(TelemetryService.instance.trackFeatureUsed(
        featureKey: platform == HealthExportPlatform.appleHealth
            ? FeatureKey.appleHealthExported
            : FeatureKey.healthConnectExported,
      ));
    }
    return HealthExportResult(
      platform: platform,
      success: success,
      message: message,
    );
  }

  Future<_DomainExportOutcome> _exportDomain({
    required HealthExportPlatform platform,
    required HealthExportDomain domain,
    required DateTime successCheckpointUtc,
    required Future<void> Function() writer,
  }) async {
    try {
      await _statusStore.markDomainState(
        platform: platform,
        domain: domain,
        state: HealthExportState.exporting,
        lastError: null,
      );
      await writer();
      await _statusStore.markDomainState(
        platform: platform,
        domain: domain,
        state: HealthExportState.success,
        lastError: null,
        lastSuccessUtc: successCheckpointUtc,
      );
      return const _DomainExportOutcome(success: true);
    } catch (error) {
      final permissionRequired = _isPermissionDenied(error);
      await _statusStore.markDomainState(
        platform: platform,
        domain: domain,
        state: permissionRequired
            ? HealthExportState.permissionRequired
            : HealthExportState.failed,
        lastError: error.toString(),
      );
      return _DomainExportOutcome(success: false, error: error.toString());
    }
  }

  bool _isPermissionDenied(Object error) =>
      error is PlatformException && error.code == 'permission_denied';

  Future<List<T>> _prepareRecords<T>({
    required HealthExportPlatform platform,
    required HealthExportDomain domain,
    required Iterable<T> records,
    required String Function(T record) keyOf,
    required String Function(T record) fingerprintOf,
    required T Function(T record, String externalId, int revision) withIdentity,
  }) async {
    final prepared = <T>[];
    for (final record in records) {
      final identity = await _identityStore.prepare(
        platform: platform,
        domain: domain,
        sourceKey: keyOf(record),
        payloadFingerprint: fingerprintOf(record),
      );
      if (identity == null) continue;
      prepared.add(
        withIdentity(record, identity.externalId, identity.revision),
      );
    }
    return prepared;
  }

  Future<void> _commitRecords<T>({
    required HealthExportPlatform platform,
    required HealthExportDomain domain,
    required Iterable<T> records,
    required String Function(T record) keyOf,
    required String Function(T record) fingerprintOf,
    required String Function(T record) externalIdOf,
    required int Function(T record) revisionOf,
  }) async {
    for (final record in records) {
      await _identityStore.commit(
        platform: platform,
        domain: domain,
        sourceKey: keyOf(record),
        identity: PreparedHealthExportIdentity(
          externalId: externalIdOf(record),
          revision: revisionOf(record),
          payloadFingerprint: fingerprintOf(record),
        ),
      );
    }
  }

  Map<HealthExportDomain, DateTime?> _domainIncrementalCheckpoints(
    HealthExportPlatformStatus status,
  ) {
    // Conservative per-domain checkpointing:
    // each domain advances independently; a failed/missing domain checkpoint
    // only triggers full-history reload for that domain, not all domains.
    final checkpoints = <HealthExportDomain, DateTime?>{};
    for (final domain in HealthExportDomain.values) {
      checkpoints[domain] = status.statusFor(domain).lastSuccessfulExportAtUtc;
    }
    return checkpoints;
  }

  List<List<T>> _chunkRecords<T>(List<T> records) {
    if (records.isEmpty) return <List<T>>[];
    final chunks = <List<T>>[];
    for (var i = 0; i < records.length; i += maxWriteBatchSize) {
      final end = (i + maxWriteBatchSize) > records.length
          ? records.length
          : (i + maxWriteBatchSize);
      chunks.add(records.sublist(i, end));
    }
    return chunks;
  }
}
