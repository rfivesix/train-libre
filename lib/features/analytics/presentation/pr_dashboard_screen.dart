import 'package:flutter/material.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../statistics/domain/timeframe_block.dart';
import '../../statistics/presentation/statistics_formatter.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/seamless_loading_overlay.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/common.dart';
import 'package:provider/provider.dart';
import '../../../services/unit_service.dart';
import '../../../util/timeframe_label_formatter.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart' as adaptive_pickers;

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
  List<Map<String, dynamic>> _allTimePrs = [];
  List<Map<String, dynamic>> _notableImprovements = [];
  Map<String, Map<String, dynamic>?> _prsByRepRange = const {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final recent = WorkoutLocalDataSource.instance.getRecentGlobalPRs(limit: 8);
    final allTime = WorkoutLocalDataSource.instance.getAllTimeGlobalPRs(
      limit: 10,
    );
    final repRange =
        WorkoutLocalDataSource.instance.getAllTimePRsByRepBracket();
    final bounds = _activeBlock.getBounds(_anchorDate, DateTime(2020));
    final daysBack = DateTime.now().difference(bounds.start).inDays.clamp(1, 3650);

    final improvements =
        WorkoutLocalDataSource.instance.getNotablePrImprovements(
      daysWindow: daysBack,
      limit: 6,
    );

    final results = await Future.wait([
      recent,
      allTime,
      repRange,
      improvements,
    ]);

    if (!mounted) return;
    setState(() {
      _recentPrs = results[0] as List<Map<String, dynamic>>;
      _allTimePrs = results[1] as List<Map<String, dynamic>>;
      _prsByRepRange = results[2] as Map<String, Map<String, dynamic>?>;
      _notableImprovements = results[3] as List<Map<String, dynamic>>;
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
    return '$weightText ${unitService.suffixFor(UnitDimension.weight)} x $reps';
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.prDashboardTitle),
      body: SeamlessLoadingOverlay(
        isLoading: _isLoading,
        isEmpty: _recentPrs.isEmpty && _allTimePrs.isEmpty && _notableImprovements.isEmpty,
        extendBodyBehindAppBar: true,
        child: SingleChildScrollView(
              padding: DesignConstants.screenPadding.copyWith(
                top: DesignConstants.screenPadding.top + topPadding,
                bottom: DesignConstants.bottomContentSpacer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(title: l10n.analyticsNotableImprovements),
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
                    onPrevious: _activeBlock == TimeframeBlock.maxBlock ? null : () {
                      setState(() {
                        final currentBounds = _activeBlock.getBounds(DateTime.now(), DateTime(2020));
                        final myBounds = _activeBlock.getBounds(_anchorDate, DateTime(2020));
                        final isOngoing = !_isRolling && myBounds.start.isAtSameMomentAs(currentBounds.start);
                        
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
                    onNext: _activeBlock == TimeframeBlock.maxBlock ? null : () {
                      setState(() {
                        if (_isRolling) {
                          _isRolling = false;
                          _anchorDate = DateTime.now();
                        } else {
                          final previousAnchor = _activeBlock.shift(DateTime.now(), -1);
                          final previousBounds = _activeBlock.getBounds(previousAnchor, DateTime(2020));
                          final myBounds = _activeBlock.getBounds(_anchorDate, DateTime(2020));
                          final isPreviousToOngoing = !_isRolling && myBounds.start.isAtSameMomentAs(previousBounds.start);
                          
                          if (isPreviousToOngoing) {
                            _isRolling = true;
                          } else {
                            _anchorDate = _activeBlock.shift(_anchorDate, 1);
                          }
                        }
                      });
                      _loadData();
                    },
                    displayDate: _isRolling ? TimeframeLabelFormatter.formatRolling(_activeBlock, l10n) : TimeframeLabelFormatter.format(_activeBlock, _anchorDate, l10n),
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
                    nextEnabled: _activeBlock == TimeframeBlock.maxBlock ? false : (_isRolling ? true : !_activeBlock.getBounds(_anchorDate, DateTime(2020)).start.isAtSameMomentAs(_activeBlock.getBounds(DateTime.now(), DateTime(2020)).start)),
                  ),const SizedBox(height: DesignConstants.spacingS),
                  SummaryCard(
                    child: _notableImprovements.isEmpty
                        ? Padding(
                            padding:
                                const EdgeInsets.all(DesignConstants.spacingM),
                            child: Text(l10n.analyticsNoPrTrendInWindow),
                          )
                        : Column(
                            children: _notableImprovements.asMap().entries.map((
                              entry,
                            ) {
                              final row = entry.value;
                              final previous =
                                  (row['previousBestE1rm'] as num).toDouble();
                              final recent =
                                  (row['recentBestE1rm'] as num).toDouble();
                              final improvement =
                                  (row['improvementPct'] as num).toDouble();
                              final delta = recent - previous;

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                /*
                                leading: entry.key == _topMomentumIndex
                                    ? Icon(
                                        LucideIcons.trending_up,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      )
                                    : null,
                                */
                                title: Text(
                                  row['exerciseName'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  l10n.analyticsE1rmProgress(
                                    StatisticsPresentationFormatter
                                        .formatWeight(
                                      previous,
                                    ),
                                    StatisticsPresentationFormatter
                                        .formatWeight(
                                      recent,
                                    ),
                                  ),
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
                                    Text(
                                      'Δ ${StatisticsPresentationFormatter.formatWeight(delta)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                  AppSectionHeader(title: l10n.analyticsRecentRecords),
                  SummaryCard(
                    child: _recentPrs.isEmpty
                        ? Padding(
                            padding:
                                const EdgeInsets.all(DesignConstants.spacingM),
                            child: Text(l10n.noWorkoutDataLabel),
                          )
                        : Column(
                            children: _recentPrs.asMap().entries.map((entry) {
                              return _buildRankedRow(
                                rank: entry.key + 1,
                                exerciseName:
                                    entry.value['exerciseName'] as String,
                                valueLabel: _perfLabel(entry.value),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                  AppSectionHeader(title: l10n.allTimeRecordsLabel),
                  _allTimePrs.isEmpty
                      ? Text(
                          l10n.noWorkoutDataLabel,
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      : _buildTwoColumnGrid(
                          _allTimePrs.asMap().entries.map((entry) {
                            return ValueSummaryCard(
                              label: '#${entry.key + 1}',
                              value: _perfLabel(entry.value),
                              subtitle:
                                  entry.value['exerciseName'] as String,
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: DesignConstants.spacingL),
                  AppSectionHeader(title: l10n.prsByRepRangeLabel),
                  _buildTwoColumnGrid(
                    _prsByRepRange.entries.map((entry) {
                      final data = entry.value;
                      final hasData = data != null;
                      return ValueSummaryCard(
                        label: entry.key.replaceAll(
                          'RM',
                          l10n.analyticsRepRangeSuffix,
                        ),
                        value: hasData
                            ? l10n.analyticsPerfWithReps(
                                StatisticsPresentationFormatter.formatWeight(
                                  (data['weight'] as num).toDouble(),
                                ),
                                (data['reps'] as num).toInt(),
                              )
                            : '–',
                        subtitle: hasData
                            ? data['exerciseName'] as String
                            : l10n.analyticsNoRecordYet,
                      );
                    }).toList(),
                  ),

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

  Widget _buildRankedRow({
    required int rank,
    required String exerciseName,
    required String valueLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank.',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              exerciseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: DesignConstants.spacingM),
          Text(
            valueLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Removed _windowChip
}
