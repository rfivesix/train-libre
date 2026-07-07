import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/health/steps_sync_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/seamless_loading_overlay.dart';
import '../../../widgets/common/time_range_filter.dart';
import '../../../util/timeframe_label_formatter.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart' as adaptive_pickers;
import '../../statistics/domain/timeframe_block.dart';

import '../data/steps_aggregation_repository.dart';
import '../domain/steps_models.dart';
import 'statistics_steps_card.dart';
import 'widgets/steps_day_chart.dart';
import 'widgets/steps_month_chart.dart';
import 'widgets/steps_week_chart.dart';

class StepsModuleScreen extends StatefulWidget {
  const StepsModuleScreen({
    super.key,
    this.repository,
    this.initialScope = StepsScope.day,
    this.initialDate,
    this.targetStepsLoader,
    this.stepsProviderNameLoader,
  });

  final StepsAggregationRepository? repository;
  final StepsScope initialScope;
  final DateTime? initialDate;
  final Future<int> Function()? targetStepsLoader;
  final Future<String> Function()? stepsProviderNameLoader;

  @override
  State<StepsModuleScreen> createState() => _StepsModuleScreenState();
}

class _StepsModuleScreenState extends State<StepsModuleScreen> {
  late final StepsAggregationRepository _repository;
  
  TimeframeBlock _activeBlock = TimeframeBlock.day;
  DateTime _anchorDate = DateTime.now();

  final List<TimeframeBlock> _validBlocks = const [
    TimeframeBlock.day,
    TimeframeBlock.week,
    TimeframeBlock.month,
  ];

  List<String> _timeRanges(AppLocalizations l10n) => [
        l10n.stepsModuleDay,
        l10n.filter7DaysShort,
        l10n.filter1MonthShort,
      ];

  StepsScope get _scope {
    switch (_activeBlock) {
      case TimeframeBlock.day: return StepsScope.day;
      case TimeframeBlock.week: return StepsScope.week;
      case TimeframeBlock.month: return StepsScope.month;
      default: return StepsScope.day;
    }
  }
  bool _isLoading = true;
  DayStepsAggregation? _dayData;
  WeekStepsAggregation? _weekData;
  MonthStepsAggregation? _monthData;
  DateTime? _lastUpdatedAtUtc;
  int _targetSteps = StepsSyncService.defaultStepsGoal;
  String _stepsProviderRaw = 'local';
  StreamSubscription<DayStepsAggregation>? _dayStepsSubscription;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? HealthStepsAggregationRepository();
    
    switch (widget.initialScope) {
      case StepsScope.day: _activeBlock = TimeframeBlock.day; break;
      case StepsScope.week: _activeBlock = TimeframeBlock.week; break;
      case StepsScope.month: _activeBlock = TimeframeBlock.month; break;
    }
    
    final seed = widget.initialDate ?? DateTime.now();
    _anchorDate = DateTime(seed.year, seed.month, seed.day);
    _loadScopeData();
  }

  @override
  void dispose() {
    _dayStepsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadScopeData() async {
    _dayStepsSubscription?.cancel();
    setState(() => _isLoading = true);
    try {
      final anchor = _anchorDate;
      final targetStepsFuture = widget.targetStepsLoader?.call() ??
          DatabaseHelper.instance.getCurrentTargetStepsOrDefault();
      final providerNameFuture =
          widget.stepsProviderNameLoader?.call() ?? _loadProviderName();

      _lastUpdatedAtUtc = await _repository.getLastUpdatedAt();
      _targetSteps = await targetStepsFuture;
      _stepsProviderRaw = await providerNameFuture;

      switch (_scope) {
        case StepsScope.day:
          _dayStepsSubscription =
              _repository.watchDayAggregation(anchor).listen(
            (data) {
              if (!mounted) return;
              setState(() {
                _dayData = data;
                _isLoading = false;
              });
            },
            onError: (e) {
              debugPrint('StepsModuleScreen: failed to watch day data: $e');
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
          );
          break;
        case StepsScope.week:
          _weekData = await _repository.getWeekAggregation(anchor);
          if (mounted) {
            setState(() => _isLoading = false);
          }
          break;
        case StepsScope.month:
          _monthData = await _repository.getMonthAggregation(anchor);
          if (mounted) {
            setState(() => _isLoading = false);
          }
          break;
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('StepsModuleScreen: failed to load scope data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<String> _loadProviderName() async {
    final providerFilter = await StepsSyncService().getProviderFilter();
    return StepsSyncService.providerFilterToRaw(providerFilter);
  }

  // Removed _onScopeChanged, _shiftPeriod, _canShiftForward, _startOfWeek, _periodLabel

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    final showSummaryCard = _scope == StepsScope.month;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: AppLocalizations.of(context)!.steps),
      body: Padding(
        padding: DesignConstants.screenPadding.copyWith(
          top: DesignConstants.screenPadding.top + topPadding,
          left: 0,
          right: 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TimeRangeFilter(
              ranges: _timeRanges(AppLocalizations.of(context)!),
              selectedIndex: _validBlocks.indexOf(_activeBlock),
              onSelected: (index) {
                setState(() {
                  _activeBlock = _validBlocks[index];
                });
                _loadScopeData();
              },
              onPrevious: () {
                setState(() {
                  _anchorDate = _activeBlock.shift(_anchorDate, -1);
                });
                _loadScopeData();
              },
              onNext: () {
                setState(() {
                  _anchorDate = _activeBlock.shift(_anchorDate, 1);
                });
                _loadScopeData();
              },
              displayDate: TimeframeLabelFormatter.format(_activeBlock, _anchorDate, AppLocalizations.of(context)!),
              onTapDateDisplay: () async {
                final selected = await adaptive_pickers.showAdaptiveTimeframePicker(
                  context: context,
                  activeBlock: _activeBlock,
                  initialAnchor: _anchorDate,
                  earliestAvailableDay: DateTime(2020),
                );
                if (selected != null) {
                  setState(() {
                    _anchorDate = selected;
                  });
                  _loadScopeData();
                }
              },
              nextEnabled: _activeBlock.getBounds(_anchorDate, DateTime(2020)).end.isBefore(DateTime.now()),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Expanded(
              child: SeamlessLoadingOverlay(
                isLoading: _isLoading,
                isEmpty: _dayData == null && _weekData == null && _monthData == null,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.cardPaddingInternal,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TrendCanvas(
                        key: ValueKey(_scope),
                        scope: _scope,
                        dayData: _dayData,
                        weekData: _weekData,
                        monthData: _monthData,
                        dailyGoal: _targetSteps,
                      ),
                      if (showSummaryCard) ...[
                        const SizedBox(height: DesignConstants.spacingS),
                        _buildScopeSummaryCard(context),
                      ],
                      if (!showSummaryCard)
                        const SizedBox(height: DesignConstants.spacingS),
                      if (_lastUpdatedAtUtc != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignConstants.spacingS,
                            vertical: DesignConstants.spacingXS,
                          ),
                          child: Text(
                            _lastUpdatedLabel(context, _lastUpdatedAtUtc!),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline,
                                ),
                          ),
                        ),
                      const BottomContentSpacer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeSummaryCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final title = l10n.steps;
    final todayLabel = l10n.today;
    final totalLabel = l10n.stepsModuleTotalSteps;
    final providerName = _providerDisplayName(_stepsProviderRaw, l10n);
    final safeGoal =
        _targetSteps > 0 ? _targetSteps : StepsSyncService.defaultStepsGoal;

    switch (_scope) {
      case StepsScope.day:
        final data = _dayData;
        final subtitle = data == null
            ? '${l10n.today} • $providerName'
            : '${DateFormat.MMMd(localeCode).format(data.date)} • $providerName';
        final dayBucket = StepsBucket(
          start: data?.date ?? _anchorDate,
          steps: data?.totalSteps ?? 0,
        );
        return StatisticsStepsCard(
          title: title,
          chipText: subtitle,
          currentSteps: data?.totalSteps ?? 0,
          currentStepsSubtitle: todayLabel,
          dailyTotals: [dayBucket],
          dailyGoal: safeGoal,
          showChevron: false,
        );
      case StepsScope.week:
        final data = _weekData;
        final subtitle = '${l10n.stepsModuleThisWeek} • $providerName';
        return StatisticsStepsCard(
          title: title,
          chipText: subtitle,
          currentSteps: data?.totalSteps ?? 0,
          currentStepsSubtitle: totalLabel,
          dailyTotals: data?.dailyTotals ?? const [],
          dailyGoal: safeGoal,
          showChevron: false,
        );
      case StepsScope.month:
        final data = _monthData;
        final subtitle = '${l10n.stepsModuleThisMonth} • $providerName';
        return StatisticsStepsCard(
          title: title,
          chipText: subtitle,
          currentSteps: data?.totalSteps ?? 0,
          currentStepsSubtitle: totalLabel,
          dailyTotals: data?.dailyTotals ?? const [],
          dailyGoal: safeGoal,
          showChevron: false,
        );
    }
  }

  String _lastUpdatedLabel(BuildContext context, DateTime timestampUtc) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).toString();
    final timeText = DateFormat.Hm(localeCode).format(timestampUtc.toLocal());
    return l10n.stepsModuleUpdated(timeText);
  }

  String _providerDisplayName(String providerRaw, AppLocalizations l10n) {
    switch (providerRaw) {
      case 'appleHealth':
        return l10n.statisticsProviderAppleHealth;
      case 'healthConnect':
        return l10n.statisticsProviderHealthConnect;
      case 'withings':
        return l10n.statisticsProviderWithings;
      case 'garmin':
        return l10n.statisticsProviderGarmin;
      case 'fitbit':
        return l10n.statisticsProviderFitbit;
      default:
        return l10n.statisticsProviderLocal;
    }
  }
}

class _TrendCanvas extends StatelessWidget {
  const _TrendCanvas({
    super.key,
    required this.scope,
    required this.dayData,
    required this.weekData,
    required this.monthData,
    required this.dailyGoal,
  });

  final StepsScope scope;
  final DayStepsAggregation? dayData;
  final WeekStepsAggregation? weekData;
  final MonthStepsAggregation? monthData;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (scope) {
        StepsScope.day => StepsDayChart(
            key: const ValueKey('day-canvas'),
            date: dayData?.date,
            buckets: dayData?.hourlyBuckets ?? const [],
            dailyGoal: dailyGoal,
          ),
        StepsScope.week => StepsWeekChart(
            key: const ValueKey('week-canvas'),
            weekStart: weekData?.weekStart,
            buckets: weekData?.dailyTotals ?? const [],
            dailyGoal: dailyGoal,
          ),
        StepsScope.month => StepsMonthChart(
            key: const ValueKey('month-canvas'),
            monthStart: monthData?.monthStart,
            buckets: monthData?.dailyTotals ?? const [],
            dailyGoal: dailyGoal,
          ),
      },
    );
  }
}
