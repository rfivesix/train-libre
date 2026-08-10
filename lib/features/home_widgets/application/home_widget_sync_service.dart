import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/infrastructure/user_preferences_repository.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/unit_service.dart';
import '../../diary/domain/calculate_daily_nutrition_use_case.dart';
import '../../diary/domain/models/food_item.dart';
import '../../diary/domain/repositories/diary_repository.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../../profile/domain/repositories/profile_repository.dart';
import '../../../services/profile_service.dart';
import '../../statistics/domain/recovery_payload_models.dart';
import '../../steps/data/steps_aggregation_repository.dart';
import '../../supplements/domain/repositories/supplement_repository.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../workout/domain/models/workout_log.dart';
import '../../workout/domain/repositories/workout_repository.dart';
import '../data/home_widget_channel.dart';
import '../domain/build_home_widget_snapshot.dart';
import '../domain/models/home_widget_snapshot.dart';
import 'workout_heatmap_publisher.dart';

/// Keeps the iOS Home Screen widgets in sync with the diary.
///
/// ## Why this recomputes instead of reusing `DiaryViewModel`
///
/// `DiaryViewModel.dailyNutrition` follows `selectedDate`, which is whatever day
/// the user happens to be browsing. Publishing that would push a historical day
/// to the Home Screen the moment somebody scrolls back through their diary. This
/// service therefore always resolves the *logical today* itself and reads that
/// day, independent of any UI state.
///
/// ## Why there is no polling
///
/// Nutrition data cannot change while the app is closed — HealthKit nutrition
/// and hydration are write-only in this app, only steps/sleep/heart rate are
/// ever read back. So a snapshot written on every mutation is not an
/// approximation, it is exact, and a periodic refresh would only spend the
/// widget's limited daily reload budget on data that provably did not change.
/// Reads the raw recovery analytics map.
///
/// A function rather than a repository because recovery analytics live on
/// `WorkoutLocalDataSource` and are not part of `IWorkoutRepository` — this is
/// the narrowest seam that still lets a test stand in for the database.
typedef RecoveryAnalyticsFetcher = Future<Map<String, dynamic>> Function();

class HomeWidgetSyncService {
  final IDiaryRepository _diaryRepo;
  final SupplementRepository _supplementRepo;
  final IProfileRepository? _profileRepo;
  final IWorkoutRepository? _workoutRepo;
  final StepsAggregationRepository _stepsRepo;
  final RecoveryAnalyticsFetcher _fetchRecoveryAnalytics;
  final WorkoutHeatmapPublisher _heatmapPublisher;
  final UnitService _unitService;
  final HomeWidgetChannel _channel;
  final UserPreferencesRepository _prefsRepo =
      UserPreferencesRepository.instance;
  final CalculateDailyNutritionUseCase _calculateUseCase =
      CalculateDailyNutritionUseCase();

  HomeWidgetSyncService({
    required IDiaryRepository diaryRepo,
    required SupplementRepository supplementRepo,
    required UnitService unitService,
    IProfileRepository? profileRepo,
    IWorkoutRepository? workoutRepo,
    StepsAggregationRepository? stepsRepo,
    RecoveryAnalyticsFetcher? fetchRecoveryAnalytics,
    WorkoutHeatmapPublisher heatmapPublisher = const WorkoutHeatmapPublisher(),
    HomeWidgetChannel channel = const HomeWidgetChannel(),
  })  : _diaryRepo = diaryRepo,
        _supplementRepo = supplementRepo,
        _profileRepo = profileRepo,
        _workoutRepo = workoutRepo,
        _stepsRepo = stepsRepo ?? HealthStepsAggregationRepository(),
        _fetchRecoveryAnalytics = fetchRecoveryAnalytics ??
            (() => WorkoutLocalDataSource.instance.getRecoveryAnalytics()),
        _heatmapPublisher = heatmapPublisher,
        _unitService = unitService,
        _channel = channel;

  Timer? _debounce;
  bool _isRunning = false;
  bool _needsReRun = false;

  /// How long the four statistics sections are reused before being recomputed.
  ///
  /// The nutrition tiles are cheap and exact, so they are rebuilt on every
  /// mutation. The statistics sections are neither: recovery analytics scan two
  /// weeks of set logs and the steps aggregation talks to HealthKit. Recomputing
  /// them every time somebody logs a glass of water would put a database sweep
  /// and a health query behind an action that cannot possibly have changed
  /// either. Anything that *does* change them calls [invalidateStatistics].
  static const Duration statisticsMaxAge = Duration(minutes: 15);

  _StatisticsSections? _statistics;
  DateTime? _statisticsComputedAt;

  /// Coalesces the burst of calls a single user action produces (insert, then
  /// the diary reload, then the health sync) into one snapshot write.
  void scheduleRefresh({
    required AppLocalizations l10n,
    required bool isAiEnabled,
  }) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(refresh(l10n: l10n, isAiEnabled: isAiEnabled));
    });
  }

  /// Drops the cached statistics sections so the next refresh recomputes them.
  ///
  /// Call after anything the four statistics widgets show: a finished workout,
  /// a new measurement, a steps sync.
  void invalidateStatistics() {
    _statistics = null;
    _statisticsComputedAt = null;
  }

  /// Rebuilds the snapshot for the logical today and hands it to iOS.
  ///
  /// Never throws: a failure here must not take down whatever diary operation
  /// triggered it.
  /// [forceStatistics] recomputes the four statistics sections even if the
  /// cached ones have not aged out yet. Pass it from the paths that are about
  /// to hand the screen back to the user — backgrounding, above all.
  Future<void> refresh({
    required AppLocalizations l10n,
    required bool isAiEnabled,
    bool forceStatistics = false,
  }) async {
    if (!await _channel.isSupported()) return;

    if (_isRunning) {
      _needsReRun = true;
      return;
    }
    _isRunning = true;
    _needsReRun = false;

    try {
      final now = DateTime.now();
      final day = _logicalToday(now);

      final goals = await _diaryRepo.watchGoalsForDate(day).first;
      final foodEntries = await _diaryRepo.watchEntriesForDate(day).first;
      final fluidEntries = await _diaryRepo.watchFluidEntriesForDate(day).first;

      final archiveIds = <int>{};
      final barcodes = <String>{};
      for (final entry in foodEntries) {
        if (entry.archiveLocalId != null) {
          archiveIds.add(entry.archiveLocalId!);
        } else {
          barcodes.add(entry.barcode);
        }
      }

      final archiveProducts = archiveIds.isEmpty
          ? <int, FoodItem>{}
          : await _diaryRepo.getProductsByArchiveIds(archiveIds.toList());

      final legacyProducts = <String, FoodItem>{};
      if (barcodes.isNotEmpty) {
        for (final p in await _diaryRepo.getProductsByBarcodes(
          barcodes.toList(),
        )) {
          legacyProducts[p.barcode] = p;
        }
      }

      final state = _calculateUseCase.execute(
        goals: goals,
        targetSugar: await _prefsRepo.getTargetSugar() ?? 50,
        targetFiber: await _prefsRepo.getTargetFiber() ?? 30,
        targetSalt: await _prefsRepo.getTargetSalt() ?? 6,
        targetCaffeine: await _prefsRepo.getTargetCaffeine() ?? 400,
        foodEntries: foodEntries,
        fluidEntries: fluidEntries,
        foodProductsByBarcode: legacyProducts,
        foodProductsByArchiveLocalId: archiveProducts,
        // Workout logs feed only `DailyNutritionState.workoutSummary`, never
        // `summary` — and the widget renders `summary`. Everything that *does*
        // feed `summary` is loaded above; supplements are included because they
        // populate `summary.caffeine`.
        workoutLogs: const [],
        supplementsForDate:
            await _supplementRepo.watchSupplementsForDate(day).first,
        allSupplements: await _supplementRepo.getAllSupplements(),
        todaysSupplementLogs:
            await _supplementRepo.watchSupplementLogsForDate(day).first,
      );

      final statistics = await _resolveStatistics(
        l10n: l10n,
        now: now,
        force: forceStatistics,
      );

      final snapshot = buildHomeWidgetSnapshot(
        nutrition: state.summary,
        extraNutrient: await _prefsRepo.getOverviewExtraNutrient(),
        l10n: l10n,
        unitService: _unitService,
        isAiEnabled: isAiEnabled,
        now: now,
        recovery: statistics.recovery,
        steps: statistics.steps,
        measurements: statistics.measurements,
        lastWorkout: statistics.lastWorkout,
      );

      await _channel.writeSnapshot(snapshot);
    } catch (e, st) {
      debugPrint('HomeWidgetSyncService.refresh failed: $e\n$st');
    } finally {
      _isRunning = false;
      if (_needsReRun) {
        _needsReRun = false;
        unawaited(refresh(l10n: l10n, isAiEnabled: isAiEnabled));
      }
    }
  }

  /// The cached statistics sections, recomputing them when they have aged out.
  ///
  /// Each of the four is gathered independently and each failure is contained:
  /// no HealthKit permission must not cost the user their recovery widget.
  Future<_StatisticsSections> _resolveStatistics({
    required AppLocalizations l10n,
    required DateTime now,
    bool force = false,
  }) async {
    final cached = _statistics;
    final computedAt = _statisticsComputedAt;
    if (!force &&
        cached != null &&
        computedAt != null &&
        now.difference(computedAt) < statisticsMaxAge) {
      return cached;
    }

    final results = await Future.wait([
      _buildRecovery(l10n),
      _buildSteps(now),
      _buildMeasurements(l10n),
      _buildLastWorkout(l10n, now),
    ]);

    final sections = _StatisticsSections(
      recovery: results[0] as HomeWidgetRecovery?,
      steps: results[1] as HomeWidgetSteps?,
      measurements: results[2] as List<HomeWidgetMeasurementMetric>,
      lastWorkout: results[3] as HomeWidgetLastWorkout?,
    );

    _statistics = sections;
    _statisticsComputedAt = now;
    return sections;
  }

  Future<HomeWidgetRecovery?> _buildRecovery(AppLocalizations l10n) async {
    try {
      final raw = await _fetchRecoveryAnalytics();
      return buildHomeWidgetRecovery(
        payload: RecoveryAnalyticsPayload.fromMap(raw),
        l10n: l10n,
      );
    } catch (e) {
      debugPrint('HomeWidgetSyncService recovery section failed: $e');
      return null;
    }
  }

  Future<HomeWidgetSteps?> _buildSteps(DateTime now) async {
    try {
      final isTrackingEnabled = await _stepsRepo.isTrackingEnabled();
      final today = DateTime(now.year, now.month, now.day);
      final range = await _stepsRepo.getRangeAggregation(
        endDate: today,
        daysBack: 7,
      );
      final todayAggregation = await _stepsRepo.getDayAggregation(today);

      return buildHomeWidgetSteps(
        dailyTotals: range.dailyTotals,
        todaySteps: todayAggregation.totalSteps,
        dailyGoal: await _stepsRepo.getCurrentTargetStepsOrDefault(),
        isTrackingEnabled: isTrackingEnabled,
        now: now,
      );
    } catch (e) {
      debugPrint('HomeWidgetSyncService steps section failed: $e');
      return null;
    }
  }

  Future<List<HomeWidgetMeasurementMetric>> _buildMeasurements(
    AppLocalizations l10n,
  ) async {
    final repo = _profileRepo;
    if (repo == null) return const [];
    try {
      return buildHomeWidgetMeasurements(
        sessions: await repo.getMeasurementSessions(),
        l10n: l10n,
        unitService: _unitService,
      );
    } catch (e) {
      debugPrint('HomeWidgetSyncService measurements section failed: $e');
      return const [];
    }
  }

  /// How far back the widget looks for a last workout.
  ///
  /// Someone who has not trained in half a year is better served by the "ready
  /// for your first workout?" state than by a card celebrating a session they
  /// have long forgotten.
  static const int lastWorkoutLookbackDays = 180;

  Future<HomeWidgetLastWorkout?> _buildLastWorkout(
    AppLocalizations l10n,
    DateTime now,
  ) async {
    final repo = _workoutRepo;
    if (repo == null) return null;
    try {
      final logs = await repo.getWorkoutLogsForDateRange(
        now.subtract(const Duration(days: lastWorkoutLookbackDays)),
        now,
      );
      // The query orders by start time descending, but a workout started
      // earlier can end later, and "last workout" means the one that finished
      // last.
      WorkoutLog? newest;
      for (final log in logs) {
        final end = log.endTime;
        if (end == null) continue;
        if (newest == null || end.isAfter(newest.endTime!)) newest = log;
      }

      final id = newest?.id;
      return buildHomeWidgetLastWorkout(
        log: newest,
        l10n: l10n,
        unitService: _unitService,
        // Names the file rendered for *this* workout, so a snapshot can never
        // point the widget at another session's map.
        heatmapImageName: id == null
            ? null
            : await _resolveHeatmap(workoutId: id, log: newest!),
      );
    } catch (e) {
      debugPrint('HomeWidgetSyncService last workout section failed: $e');
      return null;
    }
  }

  /// The heatmap file name for [workoutId], rendering it first if it is not
  /// already in the App Group.
  ///
  /// Returns null when there is nothing to draw — a cardio-only session has no
  /// muscles to shade — so the widget can fall back rather than point at a file
  /// that will never appear.
  Future<String?> _resolveHeatmap({
    required int workoutId,
    required WorkoutLog log,
  }) async {
    final name = HomeWidgetChannel.workoutHeatmapFileName(workoutId);
    // Rendering is cheap but not free, and the file survives app launches. The
    // id is part of the name, so a hit is always the right picture.
    if (await _channel.sharedFileExists(name)) return name;

    final repo = _workoutRepo;
    if (repo == null) return null;

    final exercises = <String, Exercise>{};
    for (final set in log.sets) {
      if (exercises.containsKey(set.exerciseName)) continue;
      final exercise = await repo.resolveExerciseForSetLog(set);
      if (exercise != null) exercises[set.exerciseName] = exercise;
    }
    if (exercises.isEmpty) return null;

    final rendered = await _heatmapPublisher.publish(
      workoutId: workoutId,
      exercises: exercises.values,
      // `ProfileService()` is a singleton the app initializes at startup — the
      // same instance the in-app heatmap reads its silhouette from.
      gender: ProfileService().gender.toBodyGender(),
    );
    return rendered ? name : null;
  }

  Future<void> clear() => _channel.clearSnapshot();

  void dispose() {
    _debounce?.cancel();
  }

  /// Same rule as `resolveDiaryInitialDate`, applied to date-only.
  DateTime _logicalToday(DateTime now) {
    final base = now.hour < 3 ? now.subtract(const Duration(days: 1)) : now;
    return DateTime(base.year, base.month, base.day);
  }
}

/// The four statistics sections of one snapshot, cached together because they
/// are computed and expire together.
class _StatisticsSections {
  final HomeWidgetRecovery? recovery;
  final HomeWidgetSteps? steps;
  final List<HomeWidgetMeasurementMetric> measurements;
  final HomeWidgetLastWorkout? lastWorkout;

  const _StatisticsSections({
    required this.recovery,
    required this.steps,
    required this.measurements,
    required this.lastWorkout,
  });
}
