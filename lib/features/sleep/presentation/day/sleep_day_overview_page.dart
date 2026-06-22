import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/database_helper.dart';
import '../../../../generated/app_localizations.dart';
import '../../../settings/presentation/settings_screen.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../data/repository/sleep_query_repository.dart';
import '../../data/sleep_day_repository.dart';
import '../../domain/aggregation/sleep_period_aggregations.dart';
import '../../platform/sleep_sync_service.dart';
import '../../domain/sleep_domain.dart';
import '../details/sleep_data_unavailable_card.dart';
import '../month/sleep_month_overview_page.dart';
import '../week/sleep_week_overview_page.dart';
import '../widgets/sleep_period_scope_layout.dart';
import '../widgets/sleep_metric_tile_grid.dart';
import '../widgets/sleep_score_breakdown_card.dart';
import '../widgets/sleep_score_card.dart';
import '../widgets/sleep_timeline_card.dart';
import 'sleep_day_view_model.dart' hide SleepPeriodScope;
import 'package:flutter_lucide/flutter_lucide.dart';

class SleepDayOverviewPage extends StatefulWidget {
  const SleepDayOverviewPage({
    super.key,
    SleepDayDataRepository? repository,
    SleepDayViewModel? viewModel,
    SleepQueryRepository? queryRepository,
    SleepPeriodScope? initialScope,
    DateTime? selectedDay,
    SleepImportService? syncService,
  })  : _repository = repository,
        _viewModel = viewModel,
        _queryRepository = queryRepository,
        _initialScope = initialScope,
        _selectedDay = selectedDay,
        _syncService = syncService;

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
    _anchorDay = _normalizeDate(
      widget._selectedDay ?? widget._viewModel?.selectedDay ?? DateTime.now(),
    );
    _scope = widget._initialScope ?? SleepPeriodScope.day;
    _ownsDayViewModel = widget._viewModel == null;
    _dayViewModel = widget._viewModel ??
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
        child: _buildScopeContent(context),
      ),
    );
  }

  Widget _buildScopeContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_scope) {
      case SleepPeriodScope.day:
        return const _SleepDayOverviewContent();
      case SleepPeriodScope.week:
        if (_isLoadingWeek || _weekAggregation == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final aggregation = _weekAggregation!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeekSummaryCard(aggregation: aggregation),
            const SizedBox(height: _sleepOverviewSectionSpacing),
            WeekWindowCard(aggregation: aggregation),
            const SizedBox(height: _sleepOverviewSectionSpacing),
            WeekScoreStrip(aggregation: aggregation, onTapDay: _selectDay),
            if (aggregation.days.every((day) => day.score == null)) ...[
              const SizedBox(height: _sleepOverviewSectionSpacing),
              SleepDataUnavailableCard(
                message: l10n.sleepWeekNoScoredNights,
                margin: EdgeInsets.zero,
              ),
            ],
          ],
        );
      case SleepPeriodScope.month:
        if (_isLoadingMonth || _monthAggregation == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final aggregation = _monthAggregation!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonthSummaryCard(aggregation: aggregation),
            const SizedBox(height: _sleepOverviewSectionSpacing),
            MonthCalendarGrid(aggregation: aggregation, onTapDay: _selectDay),
            if (aggregation.days.every((day) => day.score == null)) ...[
              const SizedBox(height: _sleepOverviewSectionSpacing),
              SleepDataUnavailableCard(
                message: l10n.sleepMonthNoScoredNights,
                margin: EdgeInsets.zero,
              ),
            ],
          ],
        );
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
  const _SleepDayOverviewContent();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SleepDayViewModel>();
    final overview = model.overview;
    if (model.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (overview == null) {
      return _SleepEmptyStateCard(
        onOpenSettings: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          if (!context.mounted) return;
          await context.read<SleepDayViewModel>().load();
        },
        onImportNow: model.importNow,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SleepTimelineCard(overview: overview),
        if (overview.allSessions.length > 1) ...[
          const SizedBox(height: _sleepOverviewSectionSpacing),
          _SleepIntervalsCard(overview: overview),
        ],
        const SizedBox(height: _sleepOverviewSectionSpacing),
        SleepScoreCard(overview: overview),
        const SizedBox(height: _sleepOverviewSectionSpacing),
        if (overview.scoringResult != null) ...[
          SleepScoreBreakdownCard(scoringResult: overview.scoringResult!),
          const SizedBox(height: _sleepOverviewSectionSpacing),
        ],
        SleepMetricTileGrid(overview: overview),
      ],
    );
  }
}

class _SleepIntervalsCard extends StatefulWidget {
  const _SleepIntervalsCard({required this.overview});

  final SleepDayOverviewData overview;

  @override
  State<_SleepIntervalsCard> createState() => _SleepIntervalsCardState();
}

class _SleepIntervalsCardState extends State<_SleepIntervalsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sessions = widget.overview.allSessions;

    if (sessions.length <= 1) return const SizedBox.shrink();

    final isDark = theme.brightness == Brightness.dark;
    final countBadgeBg = isDark
        ? const Color(0xFF065F46).withValues(alpha: 0.3)
        : const Color(0xFFD1FAE5);
    final countBadgeText =
        isDark ? const Color(0xFF34D399) : const Color(0xFF065F46);

    return SummaryCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
            child: Padding(
              padding: const EdgeInsets.all(DesignConstants.spacingL),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.sleepIntervalsDrawerTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS, vertical: 2),
                    decoration: BoxDecoration(
                      color: countBadgeBg,
                      borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
                    ),
                    child: Text(
                      '${sessions.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: countBadgeText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingM),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(LucideIcons.chevron_down),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: DesignConstants.spacingL,
                    right: DesignConstants.spacingL,
                    top: DesignConstants.spacingM,
                    bottom: DesignConstants.spacingL,
                  ),
                  itemCount: sessions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: DesignConstants.spacingM),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final startLocal = session.startAtUtc.toLocal();
                    final endLocal = session.endAtUtc.toLocal();
                    final duration =
                        session.endAtUtc.difference(session.startAtUtc);

                    final isCore =
                        session.sessionType == SleepSessionType.mainSleep;
                    final typeText = isCore
                        ? l10n.sleepSessionTypeCore
                        : l10n.sleepSessionTypeNap;
                    final badgeColor = isCore ? cs.primary : cs.secondary;

                    return Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Center(
                            child: Icon(
                              isCore
                                  ? LucideIcons.moon
                                  : LucideIcons.alarm_clock,
                              size: 20,
                              color: isCore ? cs.primary : cs.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignConstants.spacingM),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: DesignConstants.spacingXS),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            typeText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignConstants.spacingM),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                '${_formatTime(startLocal)} - ${_formatTime(endLocal)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (startLocal.day != endLocal.day) ...[
                                const SizedBox(width: DesignConstants.spacingXS),
                                Text(
                                  '(+1)',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }
}

class _SleepEmptyStateCard extends StatelessWidget {
  const _SleepEmptyStateCard({
    required this.onOpenSettings,
    required this.onImportNow,
  });

  final VoidCallback onOpenSettings;
  final Future<bool> Function() onImportNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SummaryCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.sleepEmptyDayNoData),
            const SizedBox(height: DesignConstants.spacingS),
            Text(l10n.sleepEmptyDayConnectMessage),
            const SizedBox(height: DesignConstants.spacingM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(LucideIcons.settings),
                  label: Text(l10n.sleepOpenSettingsButton),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final ok = await onImportNow();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? l10n.sleepImportFinishedRefreshing
                              : l10n.sleepImportUnavailableSettingsHint,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.refresh_cw),
                  label: Text(l10n.sleepImportNowButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
