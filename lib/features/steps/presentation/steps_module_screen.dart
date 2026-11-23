import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/health/steps_sync_service.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../util/design_constants.dart';
import '../../../util/timeframe_label_formatter.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart'
    as adaptive_pickers;
import '../../../widgets/common/seamless_loading_overlay.dart';
import '../../../widgets/common/time_range_filter.dart';
import '../../statistics/domain/timeframe_block.dart';
import '../data/steps_aggregation_repository.dart';
import '../domain/steps_models.dart';
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
  });

  final StepsAggregationRepository? repository;
  final StepsScope initialScope;
  final DateTime? initialDate;
  final Future<int> Function()? targetStepsLoader;

  @override
  State<StepsModuleScreen> createState() => _StepsModuleScreenState();
}

class _StepsModuleScreenState extends State<StepsModuleScreen> {
  static const _scopes = [StepsScope.day, StepsScope.week, StepsScope.month];
  static final _earliestPickerDate = DateTime(2020);

  late final StepsAggregationRepository _repository;
  late StepsScope _scope;
  late DateTime _anchorDate;

  TimeframeBlock get _activeBlock => switch (_scope) {
    StepsScope.day => TimeframeBlock.day,
    StepsScope.week => TimeframeBlock.week,
    StepsScope.month => TimeframeBlock.month,
  };

  bool _isLoading = true;
  bool _loadFailed = false;
  DayStepsAggregation? _dayData;
  WeekStepsAggregation? _weekData;
  MonthStepsAggregation? _monthData;
  int _dailyGoal = StepsSyncService.defaultStepsGoal;
  int _requestId = 0;
  StreamSubscription<DayStepsAggregation>? _dayStepsSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(
      TelemetryService.instance.trackScreenView(
        screenName: ScreenName.stepsOverview,
      ),
    );
    _repository = widget.repository ?? HealthStepsAggregationRepository();
    _scope = widget.initialScope;
    _anchorDate = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
    _loadScopeData();
  }

  @override
  void dispose() {
    _dayStepsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadScopeData() async {
    final requestId = ++_requestId;
    final anchor = _anchorDate;
    final scope = _scope;
    _dayStepsSubscription?.cancel();
    _dayStepsSubscription = null;
    setState(() {
      _isLoading = true;
      _loadFailed = false;
      _dayData = null;
      _weekData = null;
      _monthData = null;
    });

    bool isCurrent() => mounted && requestId == _requestId;

    void handleError(Object error) {
      if (!isCurrent()) return;
      debugPrint('StepsModuleScreen: failed to load steps: $error');
      setState(() {
        _isLoading = false;
        _loadFailed = _dayData == null;
      });
    }

    try {
      final goal =
          await (widget.targetStepsLoader?.call() ??
              _repository.getCurrentTargetStepsOrDefault());
      if (!isCurrent()) return;
      _dailyGoal = goal > 0 ? goal : StepsSyncService.defaultStepsGoal;

      switch (scope) {
        case StepsScope.day:
          _dayStepsSubscription = _repository
              .watchDayAggregation(anchor)
              .listen((data) {
                if (!isCurrent()) return;
                setState(() {
                  _dayData = data;
                  _isLoading = false;
                  _loadFailed = false;
                });
              }, onError: handleError);
        case StepsScope.week:
          final data = await _repository.getWeekAggregation(anchor);
          if (!isCurrent()) return;
          setState(() {
            _weekData = data;
            _isLoading = false;
          });
        case StepsScope.month:
          final data = await _repository.getMonthAggregation(anchor);
          if (!isCurrent()) return;
          setState(() {
            _monthData = data;
            _isLoading = false;
          });
      }
    } catch (error) {
      handleError(error);
    }
  }

  void _selectDate(DateTime date) {
    _anchorDate = DateUtils.dateOnly(date);
    _loadScopeData();
  }

  Future<void> _pickDate() async {
    final selected = await adaptive_pickers.showAdaptiveTimeframePicker(
      context: context,
      activeBlock: _activeBlock,
      initialAnchor: _anchorDate,
      earliestAvailableDay: _earliestPickerDate,
      initialIsRolling: false,
      supportRolling: false,
    );
    if (mounted && selected != null) {
      _selectDate(selected.anchorDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeframeFilter = TimeRangeFilter(
      ranges: [
        l10n.stepsModuleDay,
        l10n.filter7DaysShort,
        l10n.filter1MonthShort,
      ],
      selectedIndex: _scopes.indexOf(_scope),
      onSelected: (index) {
        _scope = _scopes[index];
        _loadScopeData();
      },
      onPrevious: () => _selectDate(_activeBlock.shift(_anchorDate, -1)),
      onNext: () => _selectDate(_activeBlock.shift(_anchorDate, 1)),
      displayDate: TimeframeLabelFormatter.format(
        _activeBlock,
        _anchorDate,
        l10n,
      ),
      onTapDateDisplay: _pickDate,
      nextEnabled: _activeBlock
          .getBounds(_anchorDate, _earliestPickerDate)
          .end
          .isBefore(DateTime.now()),
    );
    final appBar = GlobalAppBar(title: l10n.steps, bottom: timeframeFilter);
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Padding(
        padding: EdgeInsets.only(
          top: padding.top + appBar.preferredSize.height,
        ),
        child: SeamlessLoadingOverlay(
          isLoading: _isLoading,
          isEmpty: true,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              DesignConstants.cardPaddingInternal,
              DesignConstants.spacingL,
              DesignConstants.cardPaddingInternal,
              padding.bottom + DesignConstants.spacingXL,
            ),
            child: _loadFailed
                ? Text(l10n.noData)
                : switch (_scope) {
                    StepsScope.day => StepsDayChart(
                      data: _dayData,
                      dailyGoal: _dailyGoal,
                    ),
                    StepsScope.week => StepsWeekChart(
                      data: _weekData,
                      dailyGoal: _dailyGoal,
                    ),
                    StepsScope.month => StepsMonthChart(
                      data: _monthData,
                      anchorDate: _anchorDate,
                      dailyGoal: _dailyGoal,
                    ),
                  },
          ),
        ),
      ),
    );
  }
}
