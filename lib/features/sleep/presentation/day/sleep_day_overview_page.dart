import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../data/database_helper.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/common.dart';

import '../../../../util/design_constants.dart';
import '../../data/repository/sleep_query_repository.dart';
import '../../data/sleep_day_repository.dart';
import '../../domain/aggregation/sleep_period_aggregations.dart';
import '../../platform/sleep_sync_service.dart';
import '../../domain/sleep_domain.dart';

import '../month/sleep_month_overview_page.dart';
import '../week/sleep_week_overview_page.dart';
import '../widgets/sleep_period_scope_layout.dart';
import '../widgets/sleep_dashboard_details.dart';
import '../widgets/sleep_metric_tile_grid.dart';
import '../widgets/sleep_score_breakdown_card.dart';
import '../widgets/sleep_score_card.dart';
import '../widgets/sleep_timeline_card.dart';
import 'sleep_day_view_model.dart' hide SleepPeriodScope;

import 'dart:async';

import '../../../../services/telemetry/telemetry_service.dart';

class SleepDayOverviewPage extends StatefulWidget {
  const SleepDayOverviewPage({
    super.key,
    this._repository,
    this._viewModel,
    this._queryRepository,
    this._initialScope,
    this._selectedDay,
    this._syncService,
  });

  final SleepDayDataRepository? _repository;
  final SleepDayViewModel? _viewModel;
  final SleepQueryRepository? _queryRepository;
  final SleepPeriodScope? _initialScope;
  final DateTime? _selectedDay;
  final SleepImportService? _syncService;

  @override
  State<SleepDayOverviewPage> createState() => _SleepDayOverviewPageState();
}

const _sleepOverviewSectionSpacing = DesignConstants.spacingM;

class _SleepDayOverviewPageState extends State<SleepDayOverviewPage> {
  late final SleepDayViewModel _dayViewModel;
  late final bool _ownsDayViewModel;
  late DateTime _anchorDay;
  SleepPeriodScope _scope = SleepPeriodScope.day;
  SleepQueryRepository? _queryRepository;
  bool _isLoadingWeek = false;
  bool _isLoadingMonth = false;
  WeekSleepAggregation? _weekAggregation;
  MonthSleepAggregation? _monthAggregation;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      TelemetryService.instance.trackScreenView(
        screenName: ScreenName.sleepOverview,
      ),
    );
    _anchorDay = _normalizeDate(
      widget._selectedDay ?? widget._viewModel?.selectedDay ?? DateTime.now(),
    );
    _scope = widget._initialScope ?? SleepPeriodScope.day;
    _ownsDayViewModel = widget._viewModel == null;
    _dayViewModel =
        widget._viewModel ??
        SleepDayViewModel(
          repository: widget._repository ?? SleepDayRepository(),
          syncService: widget._syncService,
          selectedDay: _anchorDay,
        );
    _dayViewModel.load();
    _queryRepository = widget._queryRepository;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _queryRepository ??= _readQueryRepositoryFromProvider();
      _loadScopeData();
      if (_queryRepository == null) unawaited(_ensureQueryRepository());
      _hasInitialized = true;
    }
  }

  @override
  void dispose() {
    if (_ownsDayViewModel) {
      _dayViewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ChangeNotifierProvider.value(
      value: _dayViewModel,
      child: SleepPeriodScopeLayout(
        appBarTitle: l10n.sleepSectionTitle,
        selectedScope: _scope,
        anchorDate: _anchorDay,
        onScopeChanged: _onScopeChanged,
        onShiftPeriod: _shiftPeriod,
        onAnchorChanged: (selection) {
          final date = selection.anchorDate;
          setState(() {
            _anchorDay = date;
          });
          _loadScopeData();
        },
        child: _buildScopeContent(context),
      ),
    );
  }

  Widget _buildScopeContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_scope) {
      case SleepPeriodScope.day:
        return _SleepDayOverviewContent(repository: _queryRepository);
      case SleepPeriodScope.week:
        if (_isLoadingWeek) {
          return const Center(child: CircularProgressIndicator());
        }
        final aggregation = _weekAggregation;
        final hasNoData =
            aggregation == null ||
            aggregation.days.every((day) => day.score == null);

        final displayAggregation = hasNoData
            ? const SleepPeriodAggregationEngine().aggregateWeek(
                weekStart: _anchorDay.subtract(
                  Duration(days: _anchorDay.weekday - DateTime.monday),
                ),
                analyses: getMockWeekAnalyses(
                  _anchorDay.subtract(
                    Duration(days: _anchorDay.weekday - DateTime.monday),
                  ),
                ),
              )
            : aggregation;

        Widget weekContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeekSummaryCard(aggregation: displayAggregation),
            const SizedBox(height: _sleepOverviewSectionSpacing),
            WeekWindowCard(
              aggregation: displayAggregation,
              onTapDay: _selectDay,
            ),
          ],
        );

        if (hasNoData) {
          weekContent = ActiveGapOverlay(
            message: l10n.emptyStateActiveGapOverlay,
            background: Skeletonizer(
              enabled: true,
              child: IgnorePointer(child: weekContent),
            ),
          );
        }
        return weekContent;

      case SleepPeriodScope.month:
        if (_isLoadingMonth) {
          return const Center(child: CircularProgressIndicator());
        }
        final aggregation = _monthAggregation;
        final hasNoData =
            aggregation == null ||
            aggregation.days.every((day) => day.score == null);

        final displayAggregation = hasNoData
            ? const SleepPeriodAggregationEngine().aggregateMonth(
                monthStart: DateTime(_anchorDay.year, _anchorDay.month, 1),
                analyses: getMockMonthAnalyses(
                  DateTime(_anchorDay.year, _anchorDay.month, 1),
                ),
              )
            : aggregation;

        Widget monthContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonthSummaryCard(aggregation: displayAggregation),
            const SizedBox(height: _sleepOverviewSectionSpacing),
            MonthCalendarGrid(
              aggregation: displayAggregation,
              onTapDay: _selectDay,
            ),
          ],
        );

        if (hasNoData) {
          monthContent = ActiveGapOverlay(
            message: l10n.emptyStateActiveGapOverlay,
            background: Skeletonizer(
              enabled: true,
              child: IgnorePointer(child: monthContent),
            ),
          );
        }
        return monthContent;
    }
  }

  void _onScopeChanged(SleepPeriodScope scope) {
    if (_scope == scope) return;
    setState(() => _scope = scope);
    _loadScopeData();
  }

  void _shiftPeriod(int direction) {
    if (direction == 0) return;
    setState(() {
      switch (_scope) {
        case SleepPeriodScope.day:
          _anchorDay = _anchorDay.add(Duration(days: direction));
          break;
        case SleepPeriodScope.week:
          _anchorDay = _anchorDay.add(Duration(days: 7 * direction));
          break;
        case SleepPeriodScope.month:
          _anchorDay = DateTime(
            _anchorDay.year,
            _anchorDay.month + direction,
            1,
          );
          break;
      }
    });
    _loadScopeData();
  }

  void _selectDay(DateTime day) {
    setState(() {
      _anchorDay = _normalizeDate(day);
      _scope = SleepPeriodScope.day;
    });
    _loadScopeData();
  }

  Future<void> _loadScopeData() async {
    switch (_scope) {
      case SleepPeriodScope.day:
        await _dayViewModel.setSelectedDay(_anchorDay);
        break;
      case SleepPeriodScope.week:
        await _loadWeek();
        break;
      case SleepPeriodScope.month:
        await _loadMonth();
        break;
    }
  }

  Future<void> _loadWeek() async {
    final repo = await _ensureQueryRepository();
    if (repo == null) return;
    setState(() => _isLoadingWeek = true);
    try {
      final weekStart = _anchorDay.subtract(
        Duration(days: _anchorDay.weekday - DateTime.monday),
      );
      final analyses = await repo.getAnalysesInRange(
        fromInclusive: weekStart,
        toInclusive: weekStart.add(const Duration(days: 6)),
      );
      final aggregation = const SleepPeriodAggregationEngine().aggregateWeek(
        weekStart: weekStart,
        analyses: analyses,
      );
      if (!mounted) return;
      setState(() {
        _weekAggregation = aggregation;
        _isLoadingWeek = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('SleepDayOverviewPage: failed to load week data: $e');
      setState(() => _isLoadingWeek = false);
    }
  }

  Future<void> _loadMonth() async {
    final repo = await _ensureQueryRepository();
    if (repo == null) return;
    setState(() => _isLoadingMonth = true);
    try {
      final monthStart = DateTime(_anchorDay.year, _anchorDay.month, 1);
      final monthEnd = DateTime(_anchorDay.year, _anchorDay.month + 1, 0);
      final analyses = await repo.getAnalysesInRange(
        fromInclusive: monthStart,
        toInclusive: monthEnd,
      );
      final aggregation = const SleepPeriodAggregationEngine().aggregateMonth(
        monthStart: monthStart,
        analyses: analyses,
      );
      if (!mounted) return;
      setState(() {
        _monthAggregation = aggregation;
        _isLoadingMonth = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('SleepDayOverviewPage: failed to load month data: $e');
      setState(() => _isLoadingMonth = false);
    }
  }

  Future<SleepQueryRepository?> _ensureQueryRepository() async {
    if (_queryRepository != null) return _queryRepository;
    final database = await DatabaseHelper.instance.database;
    if (!mounted) return null;
    setState(
      () => _queryRepository = DriftSleepQueryRepository(database: database),
    );
    return _queryRepository;
  }

  SleepQueryRepository? _readQueryRepositoryFromProvider() {
    try {
      return Provider.of<SleepQueryRepository>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }

  DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _SleepDayOverviewContent extends StatelessWidget {
  const _SleepDayOverviewContent({required this.repository});
  final SleepQueryRepository? repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.watch<SleepDayViewModel>();
    final overview = model.overview;
    if (model.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final isMock = overview == null;
    final displayOverview = overview ?? getMockDayOverview(model.selectedDay);
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SleepScoreCard(overview: displayOverview),
        const SizedBox(height: _sleepOverviewSectionSpacing),
        if (displayOverview.scoringResult != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingL,
            ),
            child: SleepScoreBreakdownCard(
              scoringResult: displayOverview.scoringResult!,
            ),
          ),
          const SizedBox(height: _sleepOverviewSectionSpacing),
        ],
        SleepTimelineCard(
          key: ValueKey('timeline-${displayOverview.session.id}'),
          overview: displayOverview,
        ),
        const SizedBox(height: _sleepOverviewSectionSpacing),
        SleepGoalCard(
          overview: displayOverview,
          repository: isMock ? null : repository,
        ),
        const SizedBox(height: _sleepOverviewSectionSpacing),
        SleepNightHeartCharts(
          key: ValueKey('heart-${displayOverview.session.id}'),
          overview: displayOverview,
          repository: isMock ? null : repository,
        ),
        const SizedBox(height: _sleepOverviewSectionSpacing),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacingL,
          ),
          child: SleepMetricTileGrid(overview: displayOverview),
        ),
      ],
    );

    if (isMock) {
      content = ActiveGapOverlay(
        message: l10n.emptyStateActiveGapOverlay,
        background: Skeletonizer(
          enabled: true,
          child: IgnorePointer(child: content),
        ),
      );
    }

    return content;
  }
}

SleepDayOverviewData getMockDayOverview(DateTime day) {
  final start = DateTime(day.year, day.month, day.day, 22, 30);
  final end = DateTime(day.year, day.month, day.day + 1, 6, 30);
  return SleepDayOverviewData(
    analysis: NightlySleepAnalysis(
      id: 'mock',
      sessionId: 'mock_session',
      nightDate: day,
      analysisVersion: '1',
      normalizationVersion: '1',
      analyzedAtUtc: DateTime.now(),
      score: 86.0,
      totalSleepMinutes: 480,
      sleepEfficiencyPct: 90.0,
      restingHeartRateBpm: 60.0,
      interruptionsCount: 1,
      interruptionsWakeMinutes: 10,
      sleepQuality: SleepQualityBucket.good,
      scoreBreakdownJson: const {
        'score': 86.0,
        'state': 'good',
        'completeness': 1.0,
        'durationScore': 88.0,
        'continuityScore': 100.0,
        'deepScore': 90.0,
        'remScore': 78.0,
        'regularityScore': 82.0,
        'regularityValidDays': 7,
        'regularityUsed': true,
        'regularityStable': true,
      },
    ),
    session: SleepSession(
      id: 'mock_session',
      startAtUtc: start.toUtc(),
      endAtUtc: end.toUtc(),
      sessionType: SleepSessionType.mainSleep,
      sourcePlatform: 'mock',
    ),
    timelineSegments: [
      SleepStageSegment(
        id: 'mock_stage_1',
        sessionId: 'mock_session',
        startAtUtc: start.toUtc(),
        endAtUtc: start.add(const Duration(hours: 2)).toUtc(),
        stage: CanonicalSleepStage.light,
        sourcePlatform: 'mock',
      ),
      SleepStageSegment(
        id: 'mock_stage_2',
        sessionId: 'mock_session',
        startAtUtc: start.add(const Duration(hours: 2)).toUtc(),
        endAtUtc: start.add(const Duration(hours: 4)).toUtc(),
        stage: CanonicalSleepStage.deep,
        sourcePlatform: 'mock',
      ),
      SleepStageSegment(
        id: 'mock_stage_3',
        sessionId: 'mock_session',
        startAtUtc: start.add(const Duration(hours: 4)).toUtc(),
        endAtUtc: start.add(const Duration(hours: 5)).toUtc(),
        stage: CanonicalSleepStage.rem,
        sourcePlatform: 'mock',
      ),
      SleepStageSegment(
        id: 'mock_stage_4',
        sessionId: 'mock_session',
        startAtUtc: start.add(const Duration(hours: 5)).toUtc(),
        endAtUtc: end.toUtc(),
        stage: CanonicalSleepStage.light,
        sourcePlatform: 'mock',
      ),
    ],
    stageDataConfidence: SleepStageConfidence.high,
    totalSleepMinutes: 480,
    sleepHrAvg: 62.0,
    baselineSleepHr: 60.0,
    deltaSleepHr: 2.0,
    interruptionsCount: 1,
    interruptionsWakeDuration: const Duration(minutes: 10),
    deepDuration: const Duration(hours: 1, minutes: 30),
    lightDuration: const Duration(hours: 5),
    remDuration: const Duration(hours: 1, minutes: 30),
    allSessions: [
      SleepSession(
        id: 'mock_session',
        startAtUtc: start.toUtc(),
        endAtUtc: end.toUtc(),
        sessionType: SleepSessionType.mainSleep,
        sourcePlatform: 'mock',
      ),
    ],
  );
}

List<NightlySleepAnalysis> getMockWeekAnalyses(DateTime weekStart) {
  return List.generate(7, (i) {
    final date = weekStart.add(Duration(days: i));
    return NightlySleepAnalysis(
      id: 'mock_$i',
      sessionId: 'mock_session_$i',
      nightDate: date,
      analysisVersion: '1',
      normalizationVersion: '1',
      analyzedAtUtc: date,
      score: [72.0, 85.0, 64.0, 78.0, 91.0, 80.0, 75.0][i],
      totalSleepMinutes: [420, 480, 390, 460, 520, 470, 440][i],
      sleepEfficiencyPct: 90.0,
      restingHeartRateBpm: 60.0,
      interruptionsCount: 1,
      interruptionsWakeMinutes: 10,
      sleepQuality: SleepQualityBucket.good,
    );
  });
}

List<NightlySleepAnalysis> getMockMonthAnalyses(DateTime monthStart) {
  final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
  return List.generate(daysInMonth, (i) {
    final date = monthStart.add(Duration(days: i));
    final double score = 65.0 + (i * 7 % 26);
    final int minutes = 400 + (i * 13 % 120);
    return NightlySleepAnalysis(
      id: 'mock_$i',
      sessionId: 'mock_session_$i',
      nightDate: date,
      analysisVersion: '1',
      normalizationVersion: '1',
      analyzedAtUtc: date,
      score: score,
      totalSleepMinutes: minutes,
      sleepEfficiencyPct: 90.0,
      restingHeartRateBpm: 60.0,
      interruptionsCount: 1,
      interruptionsWakeMinutes: 10,
      sleepQuality: SleepQualityBucket.good,
    );
  });
}
