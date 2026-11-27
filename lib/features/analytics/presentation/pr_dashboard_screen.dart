import 'dart:async';

import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../services/unit_service.dart';
import '../../../util/design_constants.dart';
import '../../../util/timeframe_label_formatter.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart'
    as adaptive_pickers;
import '../../../widgets/common/seamless_loading_overlay.dart';
import '../../../widgets/common/summary_card.dart';
import '../../exercise_catalog/domain/exercise_metrics.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../../exercise_catalog/domain/repositories/exercise_catalog_repository.dart';
import '../../exercise_catalog/presentation/exercise_detail_screen.dart';
import '../../statistics/domain/timeframe_block.dart';
import '../../statistics/presentation/statistics_formatter.dart';
import '../../workout/data/sources/workout_local_data_source.dart';

typedef PeriodRecordsLoader =
    Future<PeriodPersonalRecordsResult> Function(DateTime start, DateTime end);

class PRDashboardScreen extends StatefulWidget {
  final PeriodRecordsLoader? loadPeriodRecords;

  const PRDashboardScreen({super.key, this.loadPeriodRecords});

  @override
  State<PRDashboardScreen> createState() => _PRDashboardScreenState();
}

class _PRDashboardScreenState extends State<PRDashboardScreen> {
  static const List<ExerciseMetric> _recordTypes = [
    ExerciseMetric.maxWeight,
    ExerciseMetric.est1rm,
    ExerciseMetric.volume,
    ExerciseMetric.distance,
    ExerciseMetric.duration,
    ExerciseMetric.pace,
  ];

  bool _isRolling = true;
  bool _isLoading = true;
  bool _hasAnyCompletedWorkouts = true;

  TimeframeBlock _activeBlock = TimeframeBlock.month;
  DateTime _anchorDate = DateTime.now();
  ExerciseMetric _selectedMetric = ExerciseMetric.maxWeight;

  final List<TimeframeBlock> _validBlocks = const [
    TimeframeBlock.week,
    TimeframeBlock.month,
    TimeframeBlock.threeMonths,
    TimeframeBlock.year,
    TimeframeBlock.maxBlock,
  ];

  List<String> _timeRanges(AppLocalizations l10n) => [
    l10n.filter7DaysShort,
    l10n.filter1MonthShort,
    l10n.filter3MonthsShort,
    l10n.filter1YearShort,
    l10n.filterMax,
  ];

  Map<ExerciseMetric, List<PeriodPersonalRecord>> _recordsByMetric = const {};

  @override
  void initState() {
    super.initState();
    unawaited(
      TelemetryService.instance.trackScreenView(
        screenName: ScreenName.prDashboard,
      ),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final bounds = _isRolling
        ? _activeBlock.getRollingBounds()
        : _activeBlock.getBounds(_anchorDate, DateTime(2020));
    final queryEnd = _isRolling
        ? bounds.end
        : DateTime(
            bounds.end.year,
            bounds.end.month,
            bounds.end.day,
            23,
            59,
            59,
            999,
          );

    final loader =
        widget.loadPeriodRecords ??
        ((DateTime start, DateTime end) => WorkoutLocalDataSource.instance
            .getPeriodPersonalRecords(start: start, end: end));

    final result = await loader(bounds.start, queryEnd);

    if (!mounted) return;
    setState(() {
      _hasAnyCompletedWorkouts = result.hasAnyCompletedWorkouts;
      _recordsByMetric = result.recordsByMetric;
      _isLoading = false;
    });
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  String _metricLabel(ExerciseMetric metric, AppLocalizations l10n) =>
      switch (metric) {
        ExerciseMetric.est1rm => l10n.exerciseMetricEst1RM,
        ExerciseMetric.maxWeight => l10n.exerciseMetricMaxWeight,
        ExerciseMetric.volume => l10n.exerciseMetricVolume,
        ExerciseMetric.distance => l10n.exerciseMetricDistance,
        ExerciseMetric.duration => l10n.exerciseMetricDuration,
        ExerciseMetric.pace => l10n.exerciseMetricPace,
      };

  String _formatDisplayWeight(
    double weightKg,
    UnitService unitService, {
    int? fractionDigits,
  }) {
    final displayWeight = unitService.convertDisplayValue(
      weightKg,
      UnitDimension.weight,
    );
    if (fractionDigits == 0) {
      return displayWeight.round().toString();
    }
    return StatisticsPresentationFormatter.formatWeight(displayWeight);
  }

  String _formatDisplayDistance(double distanceKm, UnitService unitService) {
    final displayDistance = unitService.convertDisplayValue(
      distanceKm,
      UnitDimension.distance,
    );
    return displayDistance
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0*$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _formatClockDuration(int seconds) {
    final clamped = seconds < 0 ? 0 : seconds;
    final hours = clamped ~/ 3600;
    final mins = (clamped % 3600) ~/ 60;
    final secs = clamped % 60;
    if (hours > 0) {
      return '$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDurationDelta(int seconds) {
    final clamped = seconds < 0 ? 0 : seconds;
    final mins = clamped ~/ 60;
    final secs = clamped % 60;
    return mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
  }

  double _paceSecondsInUserUnit(double secondsPerKm, UnitService unitService) {
    if (unitService.isMetric) return secondsPerKm;
    return secondsPerKm / UnitService.kmToMi(1.0);
  }

  String _formatPace(double secondsPerKm, UnitService unitService) {
    final totalSecs = _paceSecondsInUserUnit(secondsPerKm, unitService).round();
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '$mins:${secs.toString().padLeft(2, '0')} / ${unitService.suffixFor(UnitDimension.distance)}';
  }

  String _formatDelta(PeriodPersonalRecord record, UnitService unitService) {
    final weightUnit = unitService.suffixFor(UnitDimension.weight);
    final distanceUnit = unitService.suffixFor(UnitDimension.distance);
    return switch (record.metric) {
      ExerciseMetric.est1rm || ExerciseMetric.maxWeight =>
        '+${_formatDisplayWeight(record.deltaValue, unitService)} $weightUnit',
      ExerciseMetric.volume =>
        '+${_formatDisplayWeight(record.deltaValue, unitService, fractionDigits: 0)} $weightUnit',
      ExerciseMetric.distance =>
        '+${_formatDisplayDistance(record.deltaValue, unitService)} $distanceUnit',
      ExerciseMetric.duration => '+${_formatDurationDelta(record.deltaValue.round())}',
      ExerciseMetric.pace =>
        '-${_formatDurationDelta(_paceSecondsInUserUnit(record.deltaValue, unitService).round())} / $distanceUnit',
    };
  }

  String _formatRecordPerformance(
    PeriodPersonalRecord record,
    UnitService unitService,
  ) {
    final weightUnit = unitService.suffixFor(UnitDimension.weight);
    final distanceUnit = unitService.suffixFor(UnitDimension.distance);

    switch (record.metric) {
      case ExerciseMetric.maxWeight:
        final weightText =
            '${_formatDisplayWeight(record.weightKg ?? record.newValue, unitService)} $weightUnit';
        if (record.reps != null && record.reps! > 0) {
          return '$weightText × ${record.reps}';
        }
        if (record.durationSeconds != null && record.durationSeconds! > 0) {
          return '$weightText · ${_formatClockDuration(record.durationSeconds!)}';
        }
        return weightText;
      case ExerciseMetric.est1rm:
        final e1rmText =
            '${_formatDisplayWeight(record.newValue, unitService)} $weightUnit';
        if (record.weightKg != null &&
            record.weightKg! > 0 &&
            record.reps != null &&
            record.reps! > 0) {
          final setWeightText =
              '${_formatDisplayWeight(record.weightKg!, unitService)} $weightUnit';
          return '$e1rmText · $setWeightText × ${record.reps}';
        }
        return e1rmText;
      case ExerciseMetric.volume:
        final volText =
            '${_formatDisplayWeight(record.newValue, unitService, fractionDigits: 0)} $weightUnit';
        if (record.weightKg != null &&
            record.weightKg! > 0 &&
            record.reps != null &&
            record.reps! > 0) {
          final setWeightText =
              '${_formatDisplayWeight(record.weightKg!, unitService)} $weightUnit';
          return '$volText · $setWeightText × ${record.reps}';
        }
        return volText;
      case ExerciseMetric.distance:
        final distText =
            '${_formatDisplayDistance(record.newValue, unitService)} $distanceUnit';
        if (record.durationSeconds != null && record.durationSeconds! > 0) {
          return '$distText · ${_formatClockDuration(record.durationSeconds!)}';
        }
        return distText;
      case ExerciseMetric.duration:
        final durText = _formatClockDuration(record.newValue.round());
        if (record.distanceKm != null && record.distanceKm! > 0) {
          return '$durText · ${_formatDisplayDistance(record.distanceKm!, unitService)} $distanceUnit';
        }
        return durText;
      case ExerciseMetric.pace:
        final paceText = _formatPace(record.newValue, unitService);
        if (record.distanceKm != null && record.distanceKm! > 0) {
          return '$paceText · ${_formatDisplayDistance(record.distanceKm!, unitService)} $distanceUnit';
        }
        return paceText;
    }
  }

  String _formatRecordDate(DateTime date) {
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(date);
  }

  List<PeriodPersonalRecord> _mockRecordsForColdStart() {
    final now = DateTime.now();
    return [
      PeriodPersonalRecord(
        metric: _selectedMetric,
        exerciseName: 'Bench Press',
        previousValue: 80.0,
        newValue: 85.0,
        deltaValue: 5.0,
        improvementPct: 6.25,
        achievedAt: now.subtract(const Duration(days: 1)),
        weightKg: 72.5,
        reps: 5,
      ),
      PeriodPersonalRecord(
        metric: _selectedMetric,
        exerciseName: 'Squats',
        previousValue: 100.0,
        newValue: 108.0,
        deltaValue: 8.0,
        improvementPct: 8.0,
        achievedAt: now.subtract(const Duration(days: 3)),
        weightKg: 95.0,
        reps: 5,
      ),
    ];
  }

  Future<void> _openExerciseDetail(
    String exerciseName, {
    String? exerciseId,
  }) async {
    final trimmed = exerciseName.trim();
    if (trimmed.isEmpty) return;

    Exercise? exercise;
    try {
      final repo = context.read<IExerciseCatalogRepository>();
      if (exerciseId != null && exerciseId.isNotEmpty) {
        exercise = await repo.getExerciseByUuid(exerciseId);
      }
      exercise ??= await repo.getExerciseByName(trimmed);
    } catch (_) {
      exercise = null;
    }
    exercise ??= await WorkoutLocalDataSource.instance.getExerciseByName(
      trimmed,
    );
    if (!mounted || exercise == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(exercise: exercise!),
      ),
    );
  }

  Widget _buildRecordTypeDropdown(BuildContext context) {
    return PlatformAdaptiveChipDropdown<ExerciseMetric>(
      key: const ValueKey('pr_dashboard_record_type_menu'),
      selectedValue: _selectedMetric,
      selectedLabel: _metricLabel(_selectedMetric, l10n),
      onSelected: (metric) {
        if (metric == _selectedMetric) return;
        setState(() => _selectedMetric = metric);
      },
      items: [
        for (final metric in _recordTypes)
          PlatformAdaptivePopupMenuItem<ExerciseMetric>(
            value: metric,
            label: _metricLabel(metric, l10n),
          ),
      ],
    );
  }

  Widget _buildTwoColumnGrid(List<Widget> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : const SizedBox();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(child: right),
            ],
          ),
        ),
      );
      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: DesignConstants.spacingS));
      }
    }
    return Column(children: rows);
  }

  Widget _buildRecordCard(
    BuildContext context,
    PeriodPersonalRecord record,
    UnitService unitService,
  ) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return SummaryCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingM,
        vertical: DesignConstants.spacingS,
      ),
      onTap: () => _openExerciseDetail(
        record.exerciseName,
        exerciseId: record.exerciseId,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRecordPerformance(record, unitService),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDelta(record, unitService)} · ${_formatRecordDate(record.achievedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignConstants.spacingS),
          Icon(
            LucideIcons.chevron_right,
            size: 16,
            color: mutedColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(
    BuildContext context,
    List<PeriodPersonalRecord> records,
  ) {
    final unitService = context.watch<UnitService>();
    final strongestBreakthrough = records.isEmpty ? null : records.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTwoColumnGrid([
          ValueSummaryCard(
            value: '${records.length}',
            label: l10n.analyticsNewBestPerformances,
            subtitle: l10n.analyticsInTimeframe,
          ),
          ValueSummaryCard(
            value: strongestBreakthrough == null
                ? '–'
                : _formatDelta(strongestBreakthrough, unitService),
            label: l10n.analyticsStrongestBreakthrough,
            subtitle: strongestBreakthrough == null
                ? l10n.analyticsNoRecordYet
                : strongestBreakthrough.exerciseName,
            onTap: strongestBreakthrough == null
                ? null
                : () => _openExerciseDetail(
                    strongestBreakthrough.exerciseName,
                    exerciseId: strongestBreakthrough.exerciseId,
                  ),
          ),
        ]),
        const SizedBox(height: DesignConstants.spacingS),
        if (records.isEmpty)
          SummaryCard(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: DesignConstants.spacingS,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  l10n.analyticsNoRecordsInPeriod,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < records.length; i++) ...[
                _buildRecordCard(context, records[i], unitService),
                if (i + 1 < records.length)
                  const SizedBox(height: DesignConstants.spacingS),
              ],
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight + 56;

    final showColdStartOverlay = !_isLoading && !_hasAnyCompletedWorkouts;
    final activeRecords = _recordsByMetric[_selectedMetric] ?? const [];
    final displayRecords = showColdStartOverlay
        ? _mockRecordsForColdStart()
        : activeRecords;

    Widget bodyContent = _buildBodyContent(context, displayRecords);

    if (showColdStartOverlay) {
      bodyContent = ActiveGapOverlay(
        message: l10n.analyticsNoRecordsInPeriod,
        background: Skeletonizer(
          enabled: true,
          child: IgnorePointer(child: bodyContent),
        ),
      );
    }

    final timeframeFilter = TimeRangeFilter(
      ranges: _timeRanges(l10n),
      selectedIndex: _validBlocks.indexOf(_activeBlock),
      onSelected: (index) {
        setState(() {
          _activeBlock = _validBlocks[index];
          _isRolling = _activeBlock != TimeframeBlock.maxBlock;
          _anchorDate = DateTime.now();
        });
        _loadData();
      },
      onPrevious: _activeBlock == TimeframeBlock.maxBlock
          ? null
          : () {
              setState(() {
                final currentBounds = _activeBlock.getBounds(
                  DateTime.now(),
                  DateTime(2020),
                );
                final myBounds = _activeBlock.getBounds(
                  _anchorDate,
                  DateTime(2020),
                );
                final isOngoing =
                    !_isRolling &&
                    myBounds.start.isAtSameMomentAs(currentBounds.start);

                if (isOngoing) {
                  _isRolling = true;
                } else if (_isRolling) {
                  _isRolling = false;
                  _anchorDate = _activeBlock.shift(DateTime.now(), -1);
                } else {
                  _anchorDate = _activeBlock.shift(_anchorDate, -1);
                }
              });
              _loadData();
            },
      onNext: _activeBlock == TimeframeBlock.maxBlock
          ? null
          : () {
              setState(() {
                if (_isRolling) {
                  _isRolling = false;
                  _anchorDate = DateTime.now();
                } else {
                  final previousAnchor = _activeBlock.shift(DateTime.now(), -1);
                  final previousBounds = _activeBlock.getBounds(
                    previousAnchor,
                    DateTime(2020),
                  );
                  final myBounds = _activeBlock.getBounds(
                    _anchorDate,
                    DateTime(2020),
                  );
                  final isPreviousToOngoing =
                      !_isRolling &&
                      myBounds.start.isAtSameMomentAs(previousBounds.start);

                  if (isPreviousToOngoing) {
                    _isRolling = true;
                  } else {
                    _anchorDate = _activeBlock.shift(_anchorDate, 1);
                  }
                }
              });
              _loadData();
            },
      displayDate: _isRolling
          ? TimeframeLabelFormatter.formatRolling(_activeBlock, l10n)
          : TimeframeLabelFormatter.format(_activeBlock, _anchorDate, l10n),
      onTapDateDisplay: () async {
        final selected = await adaptive_pickers.showAdaptiveTimeframePicker(
          context: context,
          activeBlock: _activeBlock,
          initialAnchor: _anchorDate,
          earliestAvailableDay: DateTime(2020),
          initialIsRolling: _isRolling,
        );
        if (selected != null) {
          setState(() {
            _anchorDate = selected.anchorDate;
            _isRolling = selected.isRolling;
          });
          _loadData();
        }
      },
      nextEnabled: _activeBlock == TimeframeBlock.maxBlock
          ? false
          : (_isRolling
                ? true
                : !_activeBlock
                      .getBounds(_anchorDate, DateTime(2020))
                      .start
                      .isAtSameMomentAs(
                        _activeBlock
                            .getBounds(DateTime.now(), DateTime(2020))
                            .start,
                      )),
      showDateNavigation: _activeBlock != TimeframeBlock.maxBlock,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.prDashboardTitle,
        bottom: timeframeFilter,
      ),
      body: SeamlessLoadingOverlay(
        isLoading: _isLoading,
        isEmpty: false,
        extendBodyBehindAppBar: true,
        child: SingleChildScrollView(
          padding: DesignConstants.screenPadding.copyWith(
            top: topPadding + DesignConstants.spacingS,
            bottom: DesignConstants.bottomContentSpacer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: l10n.analyticsNewBestPerformances,
                isFirst: true,
                action: _buildRecordTypeDropdown(context),
              ),
              bodyContent,
            ],
          ),
        ),
      ),
    );
  }
}
