import 'package:flutter/material.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../statistics/domain/statistics_range_policy.dart';
import '../../statistics/presentation/statistics_formatter.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/seamless_loading_overlay.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/common.dart';
import 'package:provider/provider.dart';
import '../../../services/unit_service.dart';

class PRDashboardScreen extends StatefulWidget {
  const PRDashboardScreen({super.key});

  @override
  State<PRDashboardScreen> createState() => _PRDashboardScreenState();
}

class _PRDashboardScreenState extends State<PRDashboardScreen> {
  final _rangePolicy = StatisticsRangePolicyService.instance;
  bool _isLoading = true;
  int _selectedWindowDays = 30;

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
    final improvements =
        WorkoutLocalDataSource.instance.getNotablePrImprovements(
      daysWindow: _rangePolicy
              .resolve(
                metricId: StatisticsMetricId.prNotableImprovements,
                selectedDays: _selectedWindowDays,
              )
              .effectiveDays ??
          _selectedWindowDays,
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
                  Row(
                    children: [
                      _windowChip(7, l10n.filter7Days),
                      _windowChip(30, l10n.filter30Days),
                      _windowChip(90, l10n.filter3Months),
                      _windowChip(3650, l10n.filterAll),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
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

  Widget _windowChip(int days, String label) {
    final selected = _selectedWindowDays == days;
    return Padding(
      padding: const EdgeInsets.only(right: DesignConstants.spacingS),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (value) {
          if (!value || selected) return;
          setState(() => _selectedWindowDays = days);
          _loadData();
        },
      ),
    );
  }
}
