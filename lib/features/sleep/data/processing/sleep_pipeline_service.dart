// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/drift_database.dart';
import '../../../../util/cancellation_token.dart';
import '../../domain/metrics/nightly_metrics_calculator.dart';
import '../../domain/metrics/sleep_regularity_index.dart';
import '../../domain/sleep_domain.dart';
import '../../domain/scoring/sleep_scoring_engine.dart';
import '../../platform/ingestion/sleep_ingestion_models.dart';
import '../mapping/health_connect_mapper.dart';
import '../mapping/healthkit_mapper.dart';
import '../persistence/dao/sleep_canonical_dao.dart';
import '../persistence/dao/sleep_nightly_analyses_dao.dart';
import '../persistence/dao/sleep_raw_imports_dao.dart';
import '../persistence/sleep_persistence_models.dart';
import 'timeline_repair.dart';

class SleepPipelineRunResult {
  const SleepPipelineRunResult({
    required this.importedSessions,
    required this.analyzedNights,
  });

  final int importedSessions;
  final int analyzedNights;
}

class SleepPipelineBackgroundTaskParams {
  final SleepRawIngestionBatch batch;
  final String normalizationVersion;
  final String analysisVersion;
  final DateTime importedAt;
  final List<SleepCanonicalSessionRecord> lookbackSessions;
  final List<SleepCanonicalStageSegmentRecord> lookbackSegments;
  final List<SleepNightlyAnalysisRecord> lookbackAnalyses;

  SleepPipelineBackgroundTaskParams({
    required this.batch,
    required this.normalizationVersion,
    required this.analysisVersion,
    required this.importedAt,
    required this.lookbackSessions,
    required this.lookbackSegments,
    required this.lookbackAnalyses,
  });
}

class SleepPipelineBackgroundTaskResult {
  final List<SleepRawImportCompanion> rawRows;
  final List<SleepCanonicalSessionCompanion> sessionRows;
  final List<SleepCanonicalStageSegmentCompanion> segmentRows;
  final List<SleepCanonicalHeartRateSampleCompanion> hrRows;
  final List<SleepNightlyAnalysisCompanion> analysisRows;

  SleepPipelineBackgroundTaskResult({
    required this.rawRows,
    required this.sessionRows,
    required this.segmentRows,
    required this.hrRows,
    required this.analysisRows,
  });
}

class SleepPipelineService {
  SleepPipelineService({
    required AppDatabase database,
    bool ownsDatabase = false,
  })  : _database = database,
        _ownsDatabase = ownsDatabase {
    _rawDao = SleepRawImportsDao(_database);
    _sessionsDao = SleepCanonicalSessionsDao(_database);
    _segmentsDao = SleepCanonicalStageSegmentsDao(_database);
    _hrDao = SleepCanonicalHeartRateSamplesDao(_database);
    _analysesDao = SleepNightlyAnalysesDao(_database);
  }

  final AppDatabase _database;
  final bool _ownsDatabase;
  late final SleepRawImportsDao _rawDao;
  late final SleepCanonicalSessionsDao _sessionsDao;
  late final SleepCanonicalStageSegmentsDao _segmentsDao;
  late final SleepCanonicalHeartRateSamplesDao _hrDao;
  late final SleepNightlyAnalysesDao _analysesDao;

  Future<SleepPipelineRunResult> runImport({
    required SleepRawIngestionBatch batch,
    String normalizationVersion = 'sleep-import-v1',
    String analysisVersion = 'sleep-health-score-v3',
    bool forceRecompute = false,
    DateTime? recomputeFromInclusive,
    DateTime? recomputeToExclusive,
    CancellationToken? token,
    void Function(int index, int total)? onProgress,
  }) async {
    token?.throwIfCancelled();
    final normalizedBatch = _dedupeProgressiveSessions(batch);
    if (normalizedBatch.sessions.isEmpty) {
      return const SleepPipelineRunResult(
        importedSessions: 0,
        analyzedNights: 0,
      );
    }

    final totalSessions = normalizedBatch.sessions.length;

    final importedAt = DateTime.now().toUtc();
    final from = recomputeFromInclusive ??
        normalizedBatch.sessions
            .map((s) => s.startAtUtc)
            .reduce((a, b) => a.isBefore(b) ? a : b);
    final to = recomputeToExclusive ??
        normalizedBatch.sessions
            .map((s) => s.endAtUtc)
            .reduce((a, b) => a.isAfter(b) ? a : b)
            .add(const Duration(seconds: 1));

    token?.throwIfCancelled();

    if (forceRecompute) {
      final sessionsToRecompute = await _sessionsDao.findByDateRange(
        fromInclusive: from,
        toExclusive: to,
      );

      final rawImportIdsSet = <String>{};
      final nightDatesSet = <String>{};
      for (final session in sessionsToRecompute) {
        if (session.rawImportId != null) {
          rawImportIdsSet.add(session.rawImportId!);
        }
        nightDatesSet.add(_nightKey(session.endedAt));
      }
      final rawImportIds = rawImportIdsSet.toList(growable: false);
      final nightDates = nightDatesSet.toList(growable: false)..sort();
      token?.throwIfCancelled();
      if (nightDates.isNotEmpty) {
        await _analysesDao.deleteByNightRange(
          fromNightDateInclusive: nightDates.first,
          toNightDateInclusive: nightDates.last,
        );
      } else {
        final toInclusive = to.subtract(const Duration(milliseconds: 1));
        await _analysesDao.deleteByNightRange(
          fromNightDateInclusive: _nightKey(from),
          toNightDateInclusive: _nightKey(toInclusive),
        );
      }
      token?.throwIfCancelled();
      await _sessionsDao.deleteByDateRange(
        fromInclusive: from,
        toExclusive: to,
      );
      token?.throwIfCancelled();
      await _rawDao.deleteByIds(rawImportIds);
    }

    token?.throwIfCancelled();

    // Pre-fetch lookback data for regularity calculation
    final targetNightsSet = <DateTime>{};
    for (final session in normalizedBatch.sessions) {
      targetNightsSet.add(_normalizeDay(session.endAtUtc.toLocal()));
    }
    final targetNights = targetNightsSet.toList(growable: false)..sort();
    final earliestNight = targetNights.first;
    final latestNight = targetNights.last;
    final lookbackFromInclusive =
        earliestNight.subtract(const Duration(days: 30));
    final lookbackToExclusive = latestNight.add(const Duration(days: 1));

    final lookbackSessions = await _sessionsDao.findByDateRange(
      fromInclusive: lookbackFromInclusive,
      toExclusive: lookbackToExclusive,
    );
    token?.throwIfCancelled();
    final lookbackSessionIds = lookbackSessions.map((s) => s.id).toList();
    final lookbackSegments =
        await _segmentsDao.findBySessionIds(lookbackSessionIds);
    token?.throwIfCancelled();
    final lookbackAnalyses = await _analysesDao.findByNightRange(
      fromNightDateInclusive: _nightKey(lookbackFromInclusive),
      toNightDateInclusive: _nightKey(lookbackToExclusive),
    );

    token?.throwIfCancelled();

    onProgress?.call(0, totalSessions + 5);

    // Offload heavy processing to background isolate
    final result = await compute(
      _runSleepPipelineBackground,
      SleepPipelineBackgroundTaskParams(
        batch: normalizedBatch,
        normalizationVersion: normalizationVersion,
        analysisVersion: analysisVersion,
        importedAt: importedAt,
        lookbackSessions: lookbackSessions,
        lookbackSegments: lookbackSegments,
        lookbackAnalyses: lookbackAnalyses,
      ),
    );

    token?.throwIfCancelled();

    var insertedSessions = 0;
    await _database.transaction(() async {
      final skipSessionIds = <String>{};
      final rawImportIdsToDelete = <String>[];

      for (var i = 0; i < totalSessions; i++) {
        token?.throwIfCancelled();
        onProgress?.call(i + 1, totalSessions + 5);
        final session = normalizedBatch.sessions[i];

        final overlapping = await _sessionsDao.findByDateRange(
          fromInclusive: session.startAtUtc,
          toExclusive: session.endAtUtc,
        );

        final otherOverlapping =
            overlapping.where((s) => s.id != session.recordId).toList();
        bool shouldSkip = false;

        if (otherOverlapping.isNotEmpty) {
          final incomingStart = session.startAtUtc;
          final incomingEnd = session.endAtUtc;
          final incomingDuration = incomingEnd.difference(incomingStart);

          for (final existing in otherOverlapping) {
            final existingStart = existing.startedAt;
            final existingEnd = existing.endedAt;
            final existingDuration = existingEnd.difference(existingStart);

            // 1. Exact Boundary Match: Allow update/overwrite by deleting existing.
            if (incomingStart.isAtSameMomentAs(existingStart) &&
                incomingEnd.isAtSameMomentAs(existingEnd)) {
              await _sessionsDao.deleteById(existing.id);
              rawImportIdsToDelete.add('raw:${existing.id}');
              continue;
            }

            // 2. Envelopment Logic:
            // Is incoming session completely enveloped by a superior (longer) existing session?
            final isEnveloped = !incomingStart.isBefore(existingStart) &&
                !incomingEnd.isAfter(existingEnd);

            if (isEnveloped && existingDuration > incomingDuration) {
              shouldSkip = true;
              break;
            }

            // Conversely, if incoming session completely envelopes an existing one,
            // we treat it as a superior replacement and remove the old fragment.
            final envelopesExisting = !existingStart.isBefore(incomingStart) &&
                !existingEnd.isAfter(incomingEnd);
            if (envelopesExisting && incomingDuration > existingDuration) {
              await _sessionsDao.deleteById(existing.id);
              rawImportIdsToDelete.add('raw:${existing.id}');
            }
          }
        }

        if (shouldSkip) {
          skipSessionIds.add(session.recordId);
          continue;
        }

        await _sessionsDao.deleteById(session.recordId);
      }

      token?.throwIfCancelled();

      if (rawImportIdsToDelete.isNotEmpty) {
        await _rawDao.deleteByIds(rawImportIdsToDelete);
      }

      final filteredRawRows = result.rawRows.where((row) {
        return !skipSessionIds.contains(_rawImportSessionId(row.id));
      }).toList(growable: false);
      final filteredSessionRows = result.sessionRows
          .where((row) => !skipSessionIds.contains(row.id))
          .toList(growable: false);
      final filteredSegmentRows = result.segmentRows
          .where((row) => !skipSessionIds.contains(row.sessionId))
          .toList(growable: false);
      final filteredHrRows = result.hrRows
          .where((row) => !skipSessionIds.contains(row.sessionId))
          .toList(growable: false);
      final filteredAnalysisRows = result.analysisRows
          .where((row) => !skipSessionIds.contains(row.sessionId))
          .toList(growable: false);

      token?.throwIfCancelled();

      await _rawDao.upsertBatch(filteredRawRows);
      onProgress?.call(totalSessions + 1, totalSessions + 5);
      await _sessionsDao.upsertBatch(filteredSessionRows);
      onProgress?.call(totalSessions + 2, totalSessions + 5);
      await _segmentsDao.upsertBatch(filteredSegmentRows);
      onProgress?.call(totalSessions + 3, totalSessions + 5);
      await _hrDao.upsertBatch(filteredHrRows);
      onProgress?.call(totalSessions + 4, totalSessions + 5);
      await _analysesDao.upsertBatch(filteredAnalysisRows);
      onProgress?.call(totalSessions + 5, totalSessions + 5);
      insertedSessions = filteredSessionRows.length;
    });

    token?.throwIfCancelled();

    _database.notifyUpdates({
      const TableUpdate('sleep_raw_imports'),
      const TableUpdate('sleep_canonical_sessions'),
      const TableUpdate('sleep_canonical_stage_segments'),
      const TableUpdate('sleep_canonical_heart_rate_samples'),
      const TableUpdate('sleep_nightly_analyses'),
    });

    return SleepPipelineRunResult(
      importedSessions: insertedSessions,
      analyzedNights: insertedSessions,
    );
  }

  static SleepPipelineBackgroundTaskResult _runSleepPipelineBackground(
    SleepPipelineBackgroundTaskParams params,
  ) {
    final batch = params.batch;
    final normalizationVersion = params.normalizationVersion;
    final analysisVersion = params.analysisVersion;
    final importedAt = params.importedAt;

    final rawMapped = _mapBatch(batch);
    final mapped = _mergeOverlappingSleepData(rawMapped);
    final segmentsBySession = <String, List<SleepStageSegment>>{};
    for (final segment in mapped.stageSegments) {
      segmentsBySession
          .putIfAbsent(segment.sessionId, () => <SleepStageSegment>[])
          .add(segment);
    }
    final hrBySession = <String, List<HeartRateSample>>{};
    for (final sample in mapped.heartRateSamples) {
      hrBySession
          .putIfAbsent(sample.sessionId, () => <HeartRateSample>[])
          .add(sample);
    }

    final rawRows = batch.sessions
        .map(
          (session) => SleepRawImportCompanion(
            id: 'raw:${session.recordId}',
            sourcePlatform: session.sourcePlatform,
            sourceAppId: session.sourceAppId,
            sourceConfidence: session.sourceConfidence,
            sourceRecordHash: session.sourceRecordHash ??
                _hashRecord('raw:${session.recordId}'),
            importStatus: 'success',
            importedAt: importedAt,
            payloadJson: jsonEncode(<String, dynamic>{
              'recordId': session.recordId,
              'startAtUtc': session.startAtUtc.toIso8601String(),
              'endAtUtc': session.endAtUtc.toIso8601String(),
              'platformSessionType': session.platformSessionType,
            }),
          ),
        )
        .toList(growable: false);

    // Filter out lookback sessions that are being replaced by the incoming batch
    // BOLT OPTIMIZATION: Replaced chained .map().where().toList() and nested .any()
    // with a single-pass calculation to avoid O(N*M) time complexity and array allocations.
    final mappedSessionIds = <String>{};
    for (final s in mapped.sessions) {
      mappedSessionIds.add(s.id);
    }

    final activeLookbackSessions = <SleepSession>[];
    for (final row in params.lookbackSessions) {
      final existing = _toDomainSession(row);
      if (mappedSessionIds.contains(existing.id)) continue;

      bool hasOverlap = false;
      for (final incoming in mapped.sessions) {
        if (incoming.startAtUtc.isBefore(existing.endAtUtc) &&
            incoming.endAtUtc.isAfter(existing.startAtUtc)) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        activeLookbackSessions.add(existing);
      }
    }

    final allSessions = [...activeLookbackSessions, ...mapped.sessions];

    // Group target sessions by local wake day string
    final sessionsByNight = <String, List<SleepSession>>{};
    for (final s in allSessions) {
      final night = _nightKey(s.endAtUtc.toLocal());
      sessionsByNight.putIfAbsent(night, () => []).add(s);
    }

    // Classify core sleep vs naps
    final classifications = <String, SleepSessionType>{};
    for (final entry in sessionsByNight.entries) {
      final nightSessions = entry.value;
      if (nightSessions.isEmpty) continue;

      final hasMain = nightSessions.any((s) =>
          s.endAtUtc.difference(s.startAtUtc) >= const Duration(hours: 3));
      if (!hasMain) {
        nightSessions.sort((a, b) {
          final durA = a.endAtUtc.difference(a.startAtUtc);
          final durB = b.endAtUtc.difference(b.startAtUtc);
          return durB.compareTo(durA);
        });
        classifications[nightSessions.first.id] = SleepSessionType.mainSleep;
        for (var i = 1; i < nightSessions.length; i++) {
          classifications[nightSessions[i].id] = SleepSessionType.nap;
        }
      } else {
        for (final s in nightSessions) {
          final duration = s.endAtUtc.difference(s.startAtUtc);
          if (duration >= const Duration(hours: 3)) {
            classifications[s.id] = SleepSessionType.mainSleep;
          } else {
            classifications[s.id] = SleepSessionType.nap;
          }
        }
      }
    }

    final sessionRows = mapped.sessions
        .map(
          (session) => SleepCanonicalSessionCompanion(
            id: session.id,
            rawImportId: 'raw:${session.id}',
            sourcePlatform: session.sourcePlatform,
            sourceAppId: session.sourceAppId,
            sourceConfidence: session.sourceConfidence,
            sourceRecordHash: session.sourceRecordHash ??
                _hashRecord('session:${session.id}'),
            normalizationVersion: normalizationVersion,
            sessionType:
                (classifications[session.id] ?? SleepSessionType.unknown).name,
            startedAt: session.startAtUtc,
            endedAt: session.endAtUtc,
            timezone: null,
            importedAt: importedAt,
            normalizedAt: importedAt,
          ),
        )
        .toList(growable: true);

    // Also include re-classified active lookback sessions
    for (final dbSession in params.lookbackSessions) {
      final domain = _toDomainSession(dbSession);
      final isActive = activeLookbackSessions.any((s) => s.id == domain.id);
      if (!isActive) continue;

      final newType = classifications[domain.id];
      if (newType != null && newType.name != dbSession.sessionType) {
        sessionRows.add(
          SleepCanonicalSessionCompanion(
            id: dbSession.id,
            rawImportId: dbSession.rawImportId,
            sourcePlatform: dbSession.sourcePlatform,
            sourceAppId: dbSession.sourceAppId,
            sourceConfidence: dbSession.sourceConfidence,
            sourceRecordHash: dbSession.sourceRecordHash,
            normalizationVersion: dbSession.normalizationVersion,
            sessionType: newType.name,
            startedAt: dbSession.startedAt,
            endedAt: dbSession.endedAt,
            timezone: dbSession.timezone,
            importedAt: dbSession.importedAt,
            normalizedAt: dbSession.normalizedAt,
          ),
        );
      }
    }

    final segmentRows = mapped.stageSegments
        .map(
          (segment) => SleepCanonicalStageSegmentCompanion(
            id: segment.id,
            sessionId: segment.sessionId,
            sourcePlatform: segment.sourcePlatform,
            sourceAppId: segment.sourceAppId,
            sourceConfidence: segment.sourceConfidence,
            sourceRecordHash: segment.sourceRecordHash ??
                _hashRecord('segment:${segment.id}'),
            normalizationVersion: normalizationVersion,
            stage: segment.stage.name,
            startedAt: segment.startAtUtc,
            endedAt: segment.endAtUtc,
            importedAt: importedAt,
            normalizedAt: importedAt,
          ),
        )
        .toList(growable: false);

    final hrRows = mapped.heartRateSamples
        .map(
          (sample) => SleepCanonicalHeartRateSampleCompanion(
            id: sample.id,
            sessionId: sample.sessionId,
            sourcePlatform: sample.sourcePlatform,
            sourceAppId: sample.sourceAppId,
            sourceConfidence: sample.sourceConfidence,
            sourceRecordHash:
                sample.sourceRecordHash ?? _hashRecord('hr:${sample.id}'),
            normalizationVersion: normalizationVersion,
            sampledAt: sample.sampledAtUtc,
            bpm: sample.bpm,
            importedAt: importedAt,
            normalizedAt: importedAt,
          ),
        )
        .toList(growable: false);

    final activeLookbackSessionsRecords =
        params.lookbackSessions.where((dbSession) {
      return activeLookbackSessions.any((s) => s.id == dbSession.id);
    }).toList();

    final regularityByNight = _buildRegularityByNight(
      targetSessions: mapped.sessions,
      lookbackSessions: activeLookbackSessionsRecords,
      lookbackSegments: params.lookbackSegments,
      currentBatchSegments: mapped.stageSegments,
    );

    final rollingMidSleepSdByNight = _buildRollingMidSleepSdByNight(
      targetSessions: mapped.sessions,
      lookbackSessions: activeLookbackSessionsRecords,
    );

    final targetNights =
        mapped.sessions.map((s) => _nightKey(s.endAtUtc.toLocal())).toSet();
    final analysisRows = <SleepNightlyAnalysisCompanion>[];

    final lookbackSegmentsBySession = <String, List<SleepStageSegment>>{};
    for (final row in params.lookbackSegments) {
      lookbackSegmentsBySession
          .putIfAbsent(row.sessionId, () => <SleepStageSegment>[])
          .add(_toDomainStageSegment(row));
    }

    for (final entry in sessionsByNight.entries) {
      final night = entry.key;
      if (!targetNights.contains(night)) continue;

      final nightSessions = entry.value;
      if (nightSessions.isEmpty) continue;

      nightSessions.sort((a, b) {
        final durA = a.endAtUtc.difference(a.startAtUtc);
        final durB = b.endAtUtc.difference(b.startAtUtc);
        return durB.compareTo(durA);
      });

      final coreSession = nightSessions.first;
      final napSessions = nightSessions.skip(1).toList();

      final sessionMetrics = <String, NightlySleepMetrics>{};
      final sessionAvgHr = <String, double?>{};
      final sessionRepairedSegments = <String, List<SleepStageSegment>>{};

      for (final s in nightSessions) {
        List<SleepStageSegment> segments;
        double? avgHr;
        if (mapped.sessions.any((incoming) => incoming.id == s.id)) {
          segments = segmentsBySession[s.id] ?? const [];
          final hr = hrBySession[s.id] ?? const [];
          avgHr = hr.isEmpty
              ? null
              : hr.fold<double>(0, (sum, item) => sum + item.bpm) / hr.length;
        } else {
          segments = lookbackSegmentsBySession[s.id] ?? const [];
          final matches =
              params.lookbackAnalyses.where((a) => a.sessionId == s.id);
          final existingAnalysis = matches.isNotEmpty ? matches.first : null;
          avgHr = existingAnalysis?.restingHeartRateBpm;
        }

        final repaired = repairSleepTimeline(session: s, segments: segments);
        sessionRepairedSegments[s.id] = repaired;
        sessionMetrics[s.id] = calculateNightlySleepMetrics(
          session: s,
          repairedSegments: repaired,
        );
        sessionAvgHr[s.id] = avgHr;
      }

      var combinedTotalSleepMinutes = 0;
      var combinedTimeInBedSeconds = 0;
      var combinedTotalSleepTimeSeconds = 0;
      var combinedWasoMinutes = 0;
      var combinedInterruptionsCount = 0;

      var combinedLightSeconds = 0;
      var combinedDeepSeconds = 0;
      var combinedRemSeconds = 0;
      var combinedAsleepUnspecifiedSeconds = 0;

      for (final s in nightSessions) {
        final m = sessionMetrics[s.id]!;
        combinedTotalSleepMinutes += m.totalSleepTime.inMinutes;
        combinedTimeInBedSeconds += m.timeInBed.inSeconds;
        combinedTotalSleepTimeSeconds += m.totalSleepTime.inSeconds;
        combinedWasoMinutes += m.wakeAfterSleepOnset.inMinutes;
        combinedInterruptionsCount += m.interruptionsCount;

        combinedLightSeconds +=
            m.stageDurations[CanonicalSleepStage.light]?.inSeconds ?? 0;
        combinedDeepSeconds +=
            m.stageDurations[CanonicalSleepStage.deep]?.inSeconds ?? 0;
        combinedRemSeconds +=
            m.stageDurations[CanonicalSleepStage.rem]?.inSeconds ?? 0;
        combinedAsleepUnspecifiedSeconds += m
                .stageDurations[CanonicalSleepStage.asleepUnspecified]
                ?.inSeconds ??
            0;
      }

      bool hasLight = false;
      bool hasDeep = false;
      bool hasRem = false;
      bool hasUnspecified = false;

      for (final s in nightSessions) {
        final m = sessionMetrics[s.id]!;
        if (m.stageDurations.containsKey(CanonicalSleepStage.light))
          hasLight = true;
        if (m.stageDurations.containsKey(CanonicalSleepStage.deep))
          hasDeep = true;
        if (m.stageDurations.containsKey(CanonicalSleepStage.rem))
          hasRem = true;
        if (m.stageDurations.containsKey(CanonicalSleepStage.asleepUnspecified))
          hasUnspecified = true;
      }

      final combinedSleepEfficiencyPct = combinedTimeInBedSeconds == 0
          ? 0.0
          : (combinedTotalSleepTimeSeconds / combinedTimeInBedSeconds) * 100.0;

      final combinedLightPct = !hasLight || combinedTotalSleepTimeSeconds == 0
          ? null
          : (combinedLightSeconds / combinedTotalSleepTimeSeconds) * 100.0;
      final combinedDeepPct = !hasDeep || combinedTotalSleepTimeSeconds == 0
          ? null
          : (combinedDeepSeconds / combinedTotalSleepTimeSeconds) * 100.0;
      final combinedRemPct = !hasRem || combinedTotalSleepTimeSeconds == 0
          ? null
          : (combinedRemSeconds / combinedTotalSleepTimeSeconds) * 100.0;
      final combinedAsleepUnspecifiedPct = !hasUnspecified ||
              combinedTotalSleepTimeSeconds == 0
          ? null
          : (combinedAsleepUnspecifiedSeconds / combinedTotalSleepTimeSeconds) *
              100.0;

      final coreLocalStart = coreSession.startAtUtc.toLocal();
      final coreSleepOnsetHourLocal =
          coreLocalStart.hour + (coreLocalStart.minute / 60.0);

      final regularityResult = regularityByNight[night];

      final coreScoreInput = SleepScoringInput(
        durationMinutes: combinedTotalSleepMinutes,
        sleepEfficiencyPct: combinedSleepEfficiencyPct,
        wasoMinutes: combinedWasoMinutes,
        regularitySri: regularityResult?.sri,
        regularityValidDays: regularityResult?.validDays ?? 0,
        regularityValidComparisonPairs: regularityResult?.validComparisonPairs,
        lightSleepPct: combinedLightPct,
        deepSleepPct: combinedDeepPct,
        remSleepPct: combinedRemPct,
        asleepUnspecifiedPct: combinedAsleepUnspecifiedPct,
        stageDataConfidence: _timelineConfidence(
            sessionRepairedSegments[coreSession.id] ?? const []),
        sourcePlatform: coreSession.sourcePlatform,
        sourceAppId: coreSession.sourceAppId,
        sleepOnsetHourLocal: coreSleepOnsetHourLocal,
        rollingMidSleepSd: rollingMidSleepSdByNight[night],
      );

      final coreScore = calculateSleepScore(
        coreScoreInput,
        config: SleepScoringConfig(analysisVersion: analysisVersion),
      );

      analysisRows.add(
        SleepNightlyAnalysisCompanion(
          id: 'analysis:${coreSession.id}',
          sessionId: coreSession.id,
          sourcePlatform: coreSession.sourcePlatform,
          sourceAppId: coreSession.sourceAppId,
          sourceConfidence: coreSession.sourceConfidence,
          sourceRecordHash: coreSession.sourceRecordHash ??
              _hashRecord('analysis:${coreSession.id}'),
          normalizationVersion: normalizationVersion,
          analysisVersion: analysisVersion,
          nightDate: night,
          score: coreScore.score,
          totalSleepMinutes: combinedTotalSleepMinutes,
          sleepEfficiencyPct: combinedSleepEfficiencyPct,
          restingHeartRateBpm: sessionAvgHr[coreSession.id],
          interruptionsCount: combinedInterruptionsCount,
          interruptionsWakeMinutes: combinedWasoMinutes,
          scoreCompleteness: coreScore.completeness,
          regularitySri: coreScore.regularityScore,
          regularityValidDays: coreScore.regularityValidDays,
          regularityIsStable: coreScore.regularityStable,
          scoreBreakdownJson: jsonEncode(coreScore.toJson()),
          analyzedAt: importedAt,
        ),
      );

      for (final nap in napSessions) {
        final m = sessionMetrics[nap.id]!;
        analysisRows.add(
          SleepNightlyAnalysisCompanion(
            id: 'analysis:${nap.id}',
            sessionId: nap.id,
            sourcePlatform: nap.sourcePlatform,
            sourceAppId: nap.sourceAppId,
            sourceConfidence: nap.sourceConfidence,
            sourceRecordHash:
                nap.sourceRecordHash ?? _hashRecord('analysis:${nap.id}'),
            normalizationVersion: normalizationVersion,
            analysisVersion: analysisVersion,
            nightDate: night,
            score: null,
            totalSleepMinutes: m.totalSleepTime.inMinutes,
            sleepEfficiencyPct: m.sleepEfficiencyPct,
            restingHeartRateBpm: sessionAvgHr[nap.id],
            interruptionsCount: m.interruptionsCount,
            interruptionsWakeMinutes: m.wakeAfterSleepOnset.inMinutes,
            scoreCompleteness: 0.0,
            regularitySri: null,
            regularityValidDays: 0,
            regularityIsStable: null,
            scoreBreakdownJson: null,
            analyzedAt: importedAt,
          ),
        );
      }
    }

    return SleepPipelineBackgroundTaskResult(
      rawRows: rawRows,
      sessionRows: sessionRows,
      segmentRows: segmentRows,
      hrRows: hrRows,
      analysisRows: analysisRows,
    );
  }

  static _MappedBatch _mergeOverlappingSleepData(_MappedBatch mapped) {
    if (mapped.sessions.isEmpty) return mapped;

    // Sort sessions by onset time (startAtUtc)
    final sorted = List<SleepSession>.from(mapped.sessions)
      ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));

    final mergedSessions = <SleepSession>[];
    final sessionIdMap =
        <String, String>{}; // Map from original sessionId to merged sessionId

    var current = sorted.first;
    sessionIdMap[current.id] = current.id;

    for (var i = 1; i < sorted.length; i++) {
      final next = sorted[i];

      // Overlap or connect continuously: next.startAtUtc <= current.endAtUtc
      if (next.startAtUtc.isBefore(current.endAtUtc) ||
          next.startAtUtc.isAtSameMomentAs(current.endAtUtc)) {
        final latestEnd = next.endAtUtc.isAfter(current.endAtUtc)
            ? next.endAtUtc
            : current.endAtUtc;

        current = SleepSession(
          id: current.id,
          startAtUtc: current.startAtUtc,
          endAtUtc: latestEnd,
          sessionType: current.sessionType,
          sourcePlatform: current.sourcePlatform,
          sourceAppId: current.sourceAppId,
          sourceRecordHash: current.sourceRecordHash,
          sourceConfidence: current.sourceConfidence,
          stageConfidence: current.stageConfidence,
          overallConfidence: current.overallConfidence,
          normalizationVersion: current.normalizationVersion,
        );
        sessionIdMap[next.id] = current.id;
      } else {
        mergedSessions.add(current);
        current = next;
        sessionIdMap[current.id] = current.id;
      }
    }
    mergedSessions.add(current);

    // Update segments and samples sessionIds
    final updatedSegments = mapped.stageSegments.map((s) {
      final targetId = sessionIdMap[s.sessionId];
      if (targetId != null && targetId != s.sessionId) {
        return SleepStageSegment(
          id: s.id,
          sessionId: targetId,
          stage: s.stage,
          startAtUtc: s.startAtUtc,
          endAtUtc: s.endAtUtc,
          sourcePlatform: s.sourcePlatform,
          sourceAppId: s.sourceAppId,
          sourceRecordHash: s.sourceRecordHash,
          sourceConfidence: s.sourceConfidence,
          stageConfidence: s.stageConfidence,
        );
      }
      return s;
    }).toList();

    final updatedSamples = mapped.heartRateSamples.map((s) {
      final targetId = sessionIdMap[s.sessionId];
      if (targetId != null && targetId != s.sessionId) {
        return HeartRateSample(
          id: s.id,
          sessionId: targetId,
          sampledAtUtc: s.sampledAtUtc,
          bpm: s.bpm,
          sourcePlatform: s.sourcePlatform,
          sourceAppId: s.sourceAppId,
          sourceRecordHash: s.sourceRecordHash,
          sourceConfidence: s.sourceConfidence,
        );
      }
      return s;
    }).toList();

    return _MappedBatch(
      sessions: mergedSessions,
      stageSegments: updatedSegments,
      heartRateSamples: updatedSamples,
    );
  }

  static _MappedBatch _mapBatch(SleepRawIngestionBatch batch) {
    final platform = batch.sessions.first.sourcePlatform.toLowerCase();
    if (platform.contains('apple') || platform.contains('healthkit')) {
      final mapped = const HealthKitMapper().map(batch);
      return _MappedBatch(
        sessions: mapped.sessions,
        stageSegments: mapped.stageSegments,
        heartRateSamples: mapped.heartRateSamples,
      );
    }
    final mapped = const HealthConnectMapper().map(batch);
    return _MappedBatch(
      sessions: mapped.sessions,
      stageSegments: mapped.stageSegments,
      heartRateSamples: mapped.heartRateSamples,
    );
  }

  static String _nightKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  static const String _unknownSourceAppId = 'unknown_source';

  static SleepRawIngestionBatch _dedupeProgressiveSessions(
    SleepRawIngestionBatch batch,
  ) {
    if (batch.sessions.length <= 1) return batch;
    final winners = <String, SleepIngestionSession>{};
    for (final session in batch.sessions) {
      final key = _sessionDedupKey(session);
      final existing = winners[key];
      if (existing == null || session.endAtUtc.isAfter(existing.endAtUtc)) {
        winners[key] = session;
      }
    }
    if (winners.length == batch.sessions.length) return batch;
    final sessions = winners.values.toList(growable: false)
      ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));
    final sessionIds = sessions.map((session) => session.recordId).toSet();
    return SleepRawIngestionBatch(
      sessions: sessions,
      stageSegments: batch.stageSegments
          .where((segment) => sessionIds.contains(segment.sessionRecordId))
          .toList(growable: false),
      heartRateSamples: batch.heartRateSamples
          .where((sample) => sessionIds.contains(sample.sessionRecordId))
          .toList(growable: false),
    );
  }

  static String _sessionDedupKey(SleepIngestionSession session) {
    final sourceKey = session.sourceAppId ?? _unknownSourceAppId;
    return '${session.startAtUtc.toIso8601String()}|${session.sourcePlatform}|$sourceKey';
  }

  static String _rawImportSessionId(String rawImportId) {
    if (rawImportId.startsWith('raw:')) {
      return rawImportId.substring(4);
    }
    return rawImportId;
  }

  static String _hashRecord(String value) =>
      sha1.convert(utf8.encode(value)).toString();

  static Map<String, SleepRegularityIndexResult> _buildRegularityByNight({
    required List<SleepSession> targetSessions,
    required List<SleepCanonicalSessionRecord> lookbackSessions,
    required List<SleepCanonicalStageSegmentRecord> lookbackSegments,
    required List<SleepStageSegment> currentBatchSegments,
  }) {
    if (targetSessions.isEmpty) return const {};
    final targetNights = targetSessions
        .map((session) => _normalizeDay(session.endAtUtc))
        .toSet()
        .toList(growable: false)
      ..sort();

    final dayBuilders = <String, _RegularityDayBuilder>{};

    // Merge sessions: current batch takes precedence over lookback from DB
    final allSessions = <String, SleepSession>{};
    for (final row in lookbackSessions) {
      allSessions[row.id] = _toDomainSession(row);
    }
    for (final session in targetSessions) {
      allSessions[session.id] = session;
    }

    // Merge segments: current batch takes precedence
    final allSegmentsBySessionId = <String, List<SleepStageSegment>>{};
    for (final row in lookbackSegments) {
      allSegmentsBySessionId
          .putIfAbsent(row.sessionId, () => <SleepStageSegment>[])
          .add(_toDomainStageSegment(row));
    }

    // Overwrite with current batch segments (grouped efficiently)
    final currentBatchSegmentsMap = <String, List<SleepStageSegment>>{};
    for (final segment in currentBatchSegments) {
      currentBatchSegmentsMap
          .putIfAbsent(segment.sessionId, () => <SleepStageSegment>[])
          .add(segment);
    }
    for (final entry in currentBatchSegmentsMap.entries) {
      allSegmentsBySessionId[entry.key] = entry.value;
    }

    for (final session in allSessions.values) {
      final segments = allSegmentsBySessionId[session.id] ?? const [];
      if (segments.isEmpty) continue;
      final repaired = repairSleepTimeline(
        session: session,
        segments: segments,
      );
      for (final segment in repaired) {
        if (!_isSleepStage(segment.stage)) continue;
        _markSleepSegmentAcrossDays(segment, dayBuilders);
      }
    }

    final dailyStates = dayBuilders.values
        .map((builder) => builder.toState())
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    final byNight = <String, SleepRegularityIndexResult>{};
    for (final night in targetNights) {
      final history =
          dailyStates.where((state) => !state.day.isAfter(night)).toList();
      final sri = calculateSleepRegularityIndex(dailyStates: history);
      byNight[_nightKey(night)] = sri;
    }
    return byNight;
  }

  static Map<String, double> _buildRollingMidSleepSdByNight({
    required List<SleepSession> targetSessions,
    required List<SleepCanonicalSessionRecord> lookbackSessions,
  }) {
    if (targetSessions.isEmpty) return const {};

    final targetNights = targetSessions
        .map((session) => _normalizeDay(session.endAtUtc.toLocal()))
        .toSet()
        .toList(growable: false)
      ..sort();

    final allSessions = <String, SleepSession>{};
    for (final row in lookbackSessions) {
      allSessions[row.id] = _toDomainSession(row);
    }
    for (final session in targetSessions) {
      allSessions[session.id] = session;
    }

    final sessionsList = allSessions.values.toList();
    // Group by night local wake day and keep only the longest session per day (Core Sleep Session)
    final sessionsByNight = <String, SleepSession>{};
    for (final s in sessionsList) {
      final night = _nightKey(s.endAtUtc.toLocal());
      final existing = sessionsByNight[night];
      if (existing == null ||
          s.endAtUtc.difference(s.startAtUtc) >
              existing.endAtUtc.difference(existing.startAtUtc)) {
        sessionsByNight[night] = s;
      }
    }
    final coreSessionsList = sessionsByNight.values.toList()
      ..sort((a, b) => a.endAtUtc.compareTo(b.endAtUtc));

    final byNight = <String, double>{};

    // BOLT OPTIMIZATION: Replaced chained .where().toList(), .map().toList(), and
    // .map().reduce() with a single-pass loop to eliminate intermediate array allocations
    // and redundant iterations.
    for (final night in targetNights) {
      final windowStart = night.subtract(const Duration(days: 14));

      final midSleeps = <double>[];
      double sum = 0.0;

      for (final s in coreSessionsList) {
        final d = _normalizeDay(s.endAtUtc.toLocal());
        if (!d.isBefore(windowStart) && !d.isAfter(night)) {
          final localStart = s.startAtUtc.toLocal();
          double onset = localStart.hour + (localStart.minute / 60.0);
          if (onset > 12.0) {
            onset -= 24.0;
          }
          final durationMinutes = s.endAtUtc.difference(s.startAtUtc).inMinutes;
          double ms = onset + ((durationMinutes / 60.0) / 2.0);
          while (ms < 0) {
            ms += 24.0;
          }
          while (ms >= 24.0) {
            ms -= 24.0;
          }
          midSleeps.add(ms);
          sum += ms;
        }
      }

      if (midSleeps.length < 2) {
        byNight[_nightKey(night)] = 0.0;
        continue;
      }

      final mean = sum / midSleeps.length;
      double varianceSum = 0.0;
      for (final ms in midSleeps) {
        varianceSum += math.pow(ms - mean, 2);
      }
      final variance = varianceSum / (midSleeps.length - 1);
      byNight[_nightKey(night)] = math.sqrt(variance);
    }

    return byNight;
  }

  static SleepSession _toDomainSession(SleepCanonicalSessionRecord row) {
    return SleepSession(
      id: row.id,
      startAtUtc: row.startedAt,
      endAtUtc: row.endedAt,
      sessionType: _parseSessionType(row.sessionType),
      sourcePlatform: row.sourcePlatform,
      sourceAppId: row.sourceAppId,
      sourceRecordHash: row.sourceRecordHash,
      sourceConfidence: row.sourceConfidence,
      stageConfidence: _parseStageConfidence(row.sourceConfidence),
      overallConfidence: _parseOverallConfidence(row.sourceConfidence),
      normalizationVersion: row.normalizationVersion,
    );
  }

  static SleepStageSegment _toDomainStageSegment(
    SleepCanonicalStageSegmentRecord row,
  ) {
    return SleepStageSegment(
      id: row.id,
      sessionId: row.sessionId,
      stage: _parseStage(row.stage),
      startAtUtc: row.startedAt,
      endAtUtc: row.endedAt,
      sourcePlatform: row.sourcePlatform,
      sourceAppId: row.sourceAppId,
      sourceRecordHash: row.sourceRecordHash,
      sourceConfidence: row.sourceConfidence,
      stageConfidence: _parseStageConfidence(row.sourceConfidence),
    );
  }

  static SleepSessionType _parseSessionType(String value) {
    return SleepSessionType.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => SleepSessionType.unknown,
    );
  }

  static CanonicalSleepStage _parseStage(String value) {
    return CanonicalSleepStage.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => CanonicalSleepStage.unknown,
    );
  }

  static SleepStageConfidence _parseStageConfidence(String? value) {
    return switch ((value ?? '').toLowerCase()) {
      'high' => SleepStageConfidence.high,
      'medium' => SleepStageConfidence.medium,
      'low' => SleepStageConfidence.low,
      _ => SleepStageConfidence.unknown,
    };
  }

  static SleepOverallConfidence _parseOverallConfidence(String? value) {
    return switch ((value ?? '').toLowerCase()) {
      'high' => SleepOverallConfidence.high,
      'medium' => SleepOverallConfidence.medium,
      'low' => SleepOverallConfidence.low,
      _ => SleepOverallConfidence.unknown,
    };
  }

  static SleepStageConfidence _timelineConfidence(
      List<SleepStageSegment> segments) {
    if (segments.isEmpty) return SleepStageConfidence.unknown;
    if (segments.every(
      (segment) => segment.stageConfidence == SleepStageConfidence.unknown,
    )) {
      return SleepStageConfidence.unknown;
    }
    if (segments.any(
      (segment) => segment.stageConfidence == SleepStageConfidence.low,
    )) {
      return SleepStageConfidence.low;
    }
    if (segments.any(
      (segment) => segment.stageConfidence == SleepStageConfidence.medium,
    )) {
      return SleepStageConfidence.medium;
    }
    if (segments.any(
      (segment) => segment.stageConfidence == SleepStageConfidence.high,
    )) {
      return SleepStageConfidence.high;
    }
    return SleepStageConfidence.unknown;
  }

  static bool _isSleepStage(CanonicalSleepStage stage) {
    return stage == CanonicalSleepStage.light ||
        stage == CanonicalSleepStage.deep ||
        stage == CanonicalSleepStage.rem ||
        stage == CanonicalSleepStage.asleepUnspecified;
  }

  static DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _dayKey(DateTime value) => _nightKey(_normalizeDay(value));

  static void _markSleepSegmentAcrossDays(
    SleepStageSegment segment,
    Map<String, _RegularityDayBuilder> dayBuilders,
  ) {
    var day = _normalizeDay(segment.startAtUtc);
    final lastDay = _normalizeDay(segment.endAtUtc);
    while (!day.isAfter(lastDay)) {
      final dayStart = day;
      final dayEnd = dayStart.add(const Duration(days: 1));
      final overlapStart =
          segment.startAtUtc.isAfter(dayStart) ? segment.startAtUtc : dayStart;
      final overlapEnd =
          segment.endAtUtc.isBefore(dayEnd) ? segment.endAtUtc : dayEnd;
      if (overlapEnd.isAfter(overlapStart)) {
        final builder = dayBuilders.putIfAbsent(
          _dayKey(dayStart),
          () => _RegularityDayBuilder(dayStart),
        );
        final startMinute = overlapStart.difference(dayStart).inMinutes;
        final endSeconds = overlapEnd.difference(dayStart).inSeconds;
        final endMinute = ((endSeconds + 59) ~/ 60).clamp(
          0,
          sleepRegularityMinutesPerDay,
        );
        builder.markSleep(
          startMinute: startMinute,
          endMinuteExclusive: endMinute,
        );
      }
      day = day.add(const Duration(days: 1));
    }
  }

  Future<void> dispose() async {
    if (_ownsDatabase) {
      await _database.close();
    }
  }
}

class _MappedBatch {
  const _MappedBatch({
    required this.sessions,
    required this.stageSegments,
    required this.heartRateSamples,
  });

  final List<SleepSession> sessions;
  final List<SleepStageSegment> stageSegments;
  final List<HeartRateSample> heartRateSamples;
}

class _RegularityDayBuilder {
  _RegularityDayBuilder(this.day);

  final DateTime day;
  // Binary 1-minute day state for SRI: default wake (0), sleep minutes marked as 1.
  final Uint8List _sleepByMinute = Uint8List(sleepRegularityMinutesPerDay);
  bool _hasSleepData = false;

  void markSleep({required int startMinute, required int endMinuteExclusive}) {
    final start = startMinute.clamp(0, sleepRegularityMinutesPerDay - 1);
    final end = endMinuteExclusive.clamp(0, sleepRegularityMinutesPerDay);
    if (end <= start) return;
    for (var minute = start; minute < end; minute++) {
      _sleepByMinute[minute] = 1;
    }
    _hasSleepData = true;
  }

  DailySleepWakeState toState() {
    return DailySleepWakeState(
      day: day,
      sleepByMinute: _sleepByMinute,
      hasSleepData: _hasSleepData,
    );
  }
}
