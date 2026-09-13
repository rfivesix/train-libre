import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../statistics/domain/timeframe_block.dart';
import '../../statistics/presentation/statistics_formatter.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/seamless_loading_overlay.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/app_segmented_control.dart';
import 'package:provider/provider.dart';
import '../../../services/unit_service.dart';
import '../../../util/timeframe_label_formatter.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart'
    as adaptive_pickers;
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';

enum _RecordOverview { recent, repRange }

class PRDashboardScreen extends StatefulWidget {
  const PRDashboardScreen({super.key});

  @override
  State<PRDashboardScreen> createState() => _PRDashboardScreenState();
}

class _PRDashboardScreenState extends State<PRDashboardScreen> {
  bool _isRolling = true;
  bool _isLoading = true;

  TimeframeBlock _activeBlock = TimeframeBlock.month;
  DateTime _anchorDate = DateTime.now();

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

  List<Map<String, dynamic>> _recentPrs = [];
  List<Map<String, dynamic>> _notableImprovements = [];
  Map<String, Map<String, dynamic>?> _prsByRepRange = const {};
  _RecordOverview _recordOverview = _RecordOverview.recent;

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.prDashboard));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final recent = WorkoutLocalDataSource.instance.getRecentGlobalPRs(limit: 8);
    final repRange =
        WorkoutLocalDataSource.instance.getAllTimePRsByRepBracket();
    final bounds = _isRolling
        ? _activeBlock.getRollingBounds()
        : _activeBlock.getBounds(_anchorDate, DateTime(2020));
    final daysBack =
        DateTime.now().difference(bounds.start).inDays.clamp(1, 3650);

    final improvements =
        WorkoutLocalDataSource.instance.getNotablePrImprovements(
      daysWindow: daysBack,
      limit: 100,
      sortByRecentDate: true,
    );

    final results = await Future.wait([
      recent,
      repRange,
      improvements,
    ]);

    if (!mounted) return;
    setState(() {
      _recentPrs = results[0] as List<Map<String, dynamic>>;
      _prsByRepRange = results[1] as Map<String, Map<String, dynamic>?>;
      _notableImprovements = results[2] as List<Map<String, dynamic>>;
      _isLoading = false;
    });
  }

  String _perfLabel(Map<String, dynamic> row) {
    final weight = (row['weight'] as num).toDouble();
    final reps = (row['reps'] as num).toInt();
    final unitService = Provider.of<UnitService>(context);
    final displayWeight =
        unitService.convertDisplayValue(weight, UnitDimension.weight);
    final weightText =
        StatisticsPresentationFormatter.formatWeight(displayWeight);
    return '$weightText ${context.read<UnitService>().suffixFor(UnitDimension.weight)} x $reps';
  }

  String _formatDisplayWeight(double weightKg) {
    final unitService = context.read<UnitService>();
    final displayWeight = unitService.convertDisplayValue(
      weightKg,
      UnitDimension.weight,
    );
    return StatisticsPresentationFormatter.formatWeight(displayWeight);
  }

  String _formatRecordDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(date);
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    final hasNoData = _recentPrs.isEmpty && _notableImprovements.isEmpty;
    final displayNotable =
        hasNoData ? getMockNotableImprovements() : _notableImprovements;
    final displayRecent = hasNoData ? getMockRecentPrs() : _recentPrs;
    final displayByRepRange =
        hasNoData ? getMockPrsByRepRange() : _prsByRepRange;

    Widget bodyContent = _buildBodyContent(
      displayNotable,
      displayRecent,
      displayByRepRange,
    );

    if (hasNoData) {
      bodyContent = ActiveGapOverlay(
        message: l10n.analyticsNoRecordsInPeriod,
        background: Skeletonizer(
          enabled: true,
          child: IgnorePointer(child: bodyContent),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.prDashboardTitle),
      body: SeamlessLoadingOverlay(
        isLoading: _isLoading,
        isEmpty: false, // Handle empty state at timeframe/content level
        extendBodyBehindAppBar: true,
        child: SingleChildScrollView(
          padding: DesignConstants.screenPadding.copyWith(
            top: DesignConstants.screenPadding.top + topPadding,
            bottom: DesignConstants.bottomContentSpacer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(title: l10n.analyticsNewBestPerformances),
              TimeRangeFilter(
                ranges: _timeRanges(l10n),
                selectedIndex: _validBlocks.indexOf(_activeBlock),
                onSelected: (index) {
                  setState(() {
                    _activeBlock = _validBlocks[index];
                    _isRolling = false;
                  });
                  _loadData();
                },
                onPrevious: _activeBlock == TimeframeBlock.maxBlock
                    ? null
                    : () {
                        setState(() {
                          final currentBounds = _activeBlock.getBounds(
                              DateTime.now(), DateTime(2020));
                          final myBounds = _activeBlock.getBounds(
                              _anchorDate, DateTime(2020));
                          final isOngoing = !_isRolling &&
                              myBounds.start
                                  .isAtSameMomentAs(currentBounds.start);

                          if (isOngoing) {
                            _isRolling = true;
                          } else if (_isRolling) {
                            _isRolling = false;
                            _anchorDate =
                                _activeBlock.shift(DateTime.now(), -1);
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
                            final previousAnchor =
                                _activeBlock.shift(DateTime.now(), -1);
                            final previousBounds = _activeBlock.getBounds(
                                previousAnchor, DateTime(2020));
                            final myBounds = _activeBlock.getBounds(
                                _anchorDate, DateTime(2020));
                            final isPreviousToOngoing = !_isRolling &&
                                myBounds.start
                                    .isAtSameMomentAs(previousBounds.start);

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
                    : TimeframeLabelFormatter.format(
                        _activeBlock, _anchorDate, l10n),
                onTapDateDisplay: () async {
                  final selected =
                      await adaptive_pickers.showAdaptiveTimeframePicker(
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
                            .isAtSameMomentAs(_activeBlock
                                .getBounds(DateTime.now(), DateTime(2020))
                                .start)),
                showDateNavigation: _activeBlock != TimeframeBlock.maxBlock,
              ),
              const SizedBox(height: DesignConstants.spacingS),
              bodyContent,
            ],
          ),
        ),
      ),
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

  Widget _buildRecentRecordRow(Map<String, dynamic> record) {
    final achievedAt = record['achievedAt'] as DateTime?;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        record['exerciseName'] as String,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: achievedAt == null ? null : Text(_formatRecordDate(achievedAt)),
      trailing: Text(
        _perfLabel(record),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  List<Map<String, dynamic>> getMockNotableImprovements() {
    return [
      {
        'exerciseName': 'Bench Press',
        'previousBestE1rm': 80.0,
        'recentBestE1rm': 85.0,
        'improvementPct': 6.25,
        'achievedAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'exerciseName': 'Squat',
        'previousBestE1rm': 100.0,
        'recentBestE1rm': 108.0,
        'improvementPct': 8.0,
        'achievedAt': DateTime.now().subtract(const Duration(days: 3)),
      },
    ];
  }

  List<Map<String, dynamic>> getMockRecentPrs() {
    return [
      {
        'exerciseName': 'Bench Press',
        'weight': 82.5,
        'reps': 5,
        'achievedAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'exerciseName': 'Squat',
        'weight': 105.0,
        'reps': 3,
        'achievedAt': DateTime.now().subtract(const Duration(days: 4)),
      },
    ];
  }

  Map<String, Map<String, dynamic>?> getMockPrsByRepRange() {
    return {
      '1 RM': {'exerciseName': 'Squat', 'weight': 115.0, 'reps': 1},
      '2–3 RM': {'exerciseName': 'Bench Press', 'weight': 85.0, 'reps': 3},
      '4–6 RM': {'exerciseName': 'Squat', 'weight': 105.0, 'reps': 5},
      '7–10 RM': {'exerciseName': 'Deadlift', 'weight': 130.0, 'reps': 8},
      '11–15 RM': null,
      '15+ RM': null,
    };
  }

  Widget _buildBodyContent(
    List<Map<String, dynamic>> notableImprovements,
    List<Map<String, dynamic>> recentPrs,
    Map<String, Map<String, dynamic>?> prsByRepRange,
  ) {
    final strongestImprovement = notableImprovements.isEmpty
        ? null
        : notableImprovements.reduce(
            (strongest, candidate) =>
                (candidate['improvementPct'] as num).toDouble() >
                        (strongest['improvementPct'] as num).toDouble()
                    ? candidate
                    : strongest,
          );
    final unit = context.read<UnitService>().suffixFor(UnitDimension.weight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTwoColumnGrid([
          ValueSummaryCard(
            value: '${notableImprovements.length}',
            label: l10n.analyticsNewBestPerformances,
            subtitle: l10n.analyticsInTimeframe,
          ),
          ValueSummaryCard(
            value: strongestImprovement == null
                ? '–'
                : '+${_formatDisplayWeight((strongestImprovement['recentBestE1rm'] as num).toDouble() - (strongestImprovement['previousBestE1rm'] as num).toDouble())} $unit',
            label: l10n.analyticsStrongestBreakthrough,
            subtitle: strongestImprovement == null
                ? l10n.analyticsNoRecordYet
                : strongestImprovement['exerciseName'] as String,
          ),
        ]),
        const SizedBox(height: DesignConstants.spacingS),
        SummaryCard(
          child: notableImprovements.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(DesignConstants.spacingM),
                  child: Text(l10n.analyticsNoPrTrendInWindow),
                )
              : Column(
                  children: notableImprovements.asMap().entries.map((
                    entry,
                  ) {
                    final row = entry.value;
                    final previous =
                        (row['previousBestE1rm'] as num).toDouble();
                    final recent = (row['recentBestE1rm'] as num).toDouble();
                    final improvement =
                        (row['improvementPct'] as num).toDouble();
                    final achievedAt = row['achievedAt'] as DateTime?;

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        row['exerciseName'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${achievedAt == null ? '' : '${_formatRecordDate(achievedAt)} · '}${l10n.analyticsE1rmProgress(_formatDisplayWeight(previous), _formatDisplayWeight(recent), unit)}',
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${improvement.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: DesignConstants.spacingL),
        AppSectionHeader(title: l10n.analyticsRecordOverview),
        AppSegmentedControl<_RecordOverview>(
          children: {
            _RecordOverview.recent: l10n.analyticsRecentlySet,
            _RecordOverview.repRange: l10n.analyticsByRepetitionRange,
          },
          groupValue: _recordOverview,
          onValueChanged: (value) => setState(() => _recordOverview = value),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        if (_recordOverview == _RecordOverview.recent)
          SummaryCard(
            child: recentPrs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(DesignConstants.spacingM),
                    child: Text(l10n.noWorkoutDataLabel),
                  )
                : Column(
                    children: recentPrs
                        .map(_buildRecentRecordRow)
                        .toList(growable: false),
                  ),
          )
        else
          _buildTwoColumnGrid(
            prsByRepRange.entries.map((entry) {
              final data = entry.value;
              final hasData = data != null;
              return ValueSummaryCard(
                label: entry.key.replaceAll(
                  ' RM',
                  l10n.analyticsRepRangeSuffix,
                ),
                value: hasData
                    ? l10n.analyticsPerfWithReps(
                        _formatDisplayWeight(
                          (data['weight'] as num).toDouble(),
                        ),
                        (data['reps'] as num).toInt(),
                        unit,
                      )
                    : '–',
                subtitle: hasData
                    ? data['exerciseName'] as String
                    : l10n.analyticsNoRecordYet,
              );
            }).toList(),
          ),
      ],
    );
  }
}
