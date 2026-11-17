import '../../../../data/drift_database.dart';
import '../persistence/dao/sleep_canonical_dao.dart';
import '../../domain/derived/nightly_sleep_analysis.dart';
import '../../domain/sleep_enums.dart';
import '../persistence/dao/sleep_nightly_analyses_dao.dart';
import '../persistence/sleep_persistence_models.dart';
import '../processing/sleep_pipeline_service.dart';

abstract class SleepQueryRepository {
  Future<NightlySleepAnalysis?> getNightlyAnalysisByDate(DateTime day);
  Future<List<NightlySleepAnalysis>> getAnalysesInRange({
    required DateTime fromInclusive,
    required DateTime toInclusive,
  });
}

class DriftSleepQueryRepository implements SleepQueryRepository {
  DriftSleepQueryRepository({
    required this._database,
    this._ownsDatabase = false,
  }) {
    _dao = SleepNightlyAnalysesDao(_database);
    _sessionsDao = SleepCanonicalSessionsDao(_database);
  }

  final AppDatabase _database;
  final bool _ownsDatabase;
  late final SleepNightlyAnalysesDao _dao;
  late final SleepCanonicalSessionsDao _sessionsDao;
  Future<int>? _historyMigration;

  Future<void> _ensureHistory() async {
    await (_historyMigration ??= SleepPipelineService(database: _database)
        .recomputeStoredHistory());
  }

  @override
  Future<NightlySleepAnalysis?> getNightlyAnalysisByDate(DateTime day) async {
    await _ensureHistory();
    final key = _nightKey(day);
    final rows = await _dao.findByNightRange(
      fromNightDateInclusive: key,
      toNightDateInclusive: key,
    );
    if (rows.isEmpty) return null;

    final sessionsById = await _loadSessionsById(rows.map((r) => r.sessionId));
    final sortedRows = List<SleepNightlyAnalysisRecord>.from(rows)
      ..sort((a, b) => _comparePrimary(a, b, sessionsById));
    final primaryRow = sortedRows.first;
    return _toDomain(primaryRow, sessionsById[primaryRow.sessionId]);
  }

  @override
  Future<List<NightlySleepAnalysis>> getAnalysesInRange({
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    await _ensureHistory();
    final rows = await _dao.findByNightRange(
      fromNightDateInclusive: _nightKey(fromInclusive),
      toNightDateInclusive: _nightKey(toInclusive),
    );
    final sessionIds = rows.map((row) => row.sessionId).toSet();
    final sessionsById = await _loadSessionsById(sessionIds);
    final byNight = <String, SleepNightlyAnalysisRecord>{};
    for (final row in rows) {
      final current = byNight[row.nightDate];
      if (current == null || _comparePrimary(row, current, sessionsById) < 0) {
        byNight[row.nightDate] = row;
      }
    }
    return byNight.values
        .map((row) => _toDomain(row, sessionsById[row.sessionId]))
        .toList(growable: false);
  }

  int _comparePrimary(
    SleepNightlyAnalysisRecord a,
    SleepNightlyAnalysisRecord b,
    Map<String, SleepCanonicalSessionRecord> sessions,
  ) {
    if (a.score != null && b.score == null) return -1;
    if (b.score != null && a.score == null) return 1;
    Duration length(SleepNightlyAnalysisRecord row) {
      final session = sessions[row.sessionId];
      return session == null
          ? Duration.zero
          : session.endedAt.difference(session.startedAt);
    }

    final byLength = length(b).compareTo(length(a));
    return byLength != 0 ? byLength : b.analyzedAt.compareTo(a.analyzedAt);
  }

  Future<Map<String, SleepCanonicalSessionRecord>> _loadSessionsById(
    Iterable<String> sessionIds,
  ) async {
    final map = <String, SleepCanonicalSessionRecord>{};
    for (final sessionId in sessionIds) {
      final session = await _sessionsDao.findById(sessionId);
      if (session != null) {
        map[sessionId] = session;
      }
    }
    return map;
  }

  NightlySleepAnalysis _toDomain(
    SleepNightlyAnalysisRecord record,
    SleepCanonicalSessionRecord? session,
  ) {
    return NightlySleepAnalysis(
      id: record.id,
      sessionId: record.sessionId,
      nightDate: DateTime.parse(record.nightDate),
      analysisVersion: record.analysisVersion,
      normalizationVersion: record.normalizationVersion,
      analyzedAtUtc: record.analyzedAt.toUtc(),
      score: record.score,
      totalSleepMinutes: record.totalSleepMinutes,
      sleepEfficiencyPct: record.sleepEfficiencyPct,
      restingHeartRateBpm: record.restingHeartRateBpm,
      interruptionsCount: record.interruptionsCount,
      interruptionsWakeMinutes: record.interruptionsWakeMinutes,
      scoreCompleteness: record.scoreCompleteness,
      regularitySri: record.regularitySri,
      regularityValidDays: record.regularityValidDays,
      regularityStable: record.regularityIsStable,
      sleepQuality: _qualityFromScore(record.score),
      sessionStartAtUtc: session?.startedAt.toUtc(),
      sessionEndAtUtc: session?.endedAt.toUtc(),
      sourcePlatform: record.sourcePlatform,
      sourceAppId: record.sourceAppId,
      sourceRecordHash: record.sourceRecordHash,
    );
  }

  SleepQualityBucket _qualityFromScore(double? score) {
    if (score == null) return SleepQualityBucket.unavailable;
    if (score >= 80) return SleepQualityBucket.good;
    if (score >= 60) return SleepQualityBucket.average;
    return SleepQualityBucket.poor;
  }

  String _nightKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  Future<void> dispose() async {
    if (_ownsDatabase) {
      await _database.close();
    }
  }
}
