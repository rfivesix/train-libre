import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';

import '../../../services/profile_service.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../statistics/domain/analytics_state.dart';
import '../../statistics/domain/statistics_range_policy.dart';
import '../../statistics/presentation/statistics_formatter.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import 'widgets/analytics_chart_defaults.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/seamless_loading_overlay.dart';
import '../../../widgets/common/common.dart';
import '../../workout/presentation/widgets/muscle_color_helper.dart';
import '../../exercise_catalog/domain/body_slug_mapper.dart';
import '../../../widgets/common/dual_body_highlighter.dart';
import '../../../util/timeframe_label_formatter.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart' as adaptive_pickers;
import '../../statistics/domain/timeframe_block.dart';

class MuscleGroupAnalyticsScreen extends StatefulWidget {
  const MuscleGroupAnalyticsScreen({super.key});

  @override
  State<MuscleGroupAnalyticsScreen> createState() =>
      _MuscleGroupAnalyticsScreenState();
}

class _MuscleGroupAnalyticsScreenState
    extends State<MuscleGroupAnalyticsScreen> {
  bool _isRolling = true;
  static const _maxMuscleBars = 8;
  final _rangePolicy = StatisticsRangePolicyService.instance;
  bool _isLoading = true;
  
  TimeframeBlock _activeBlock = TimeframeBlock.month;
  DateTime _anchorDate = DateTime.now();

  final List<TimeframeBlock> _validBlocks = const [
    TimeframeBlock.week,
    TimeframeBlock.month,
    TimeframeBlock.threeMonths,
    TimeframeBlock.sixMonths,
  ];

  List<String> _timeRanges(AppLocalizations l10n) => [
        l10n.filter7DaysShort,
        l10n.filter1MonthShort,
        l10n.filter3MonthsShort,
        l10n.filter6MonthsShort,
      ];


  Map<String, dynamic> _analytics = const {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final bounds = _activeBlock.getBounds(_anchorDate, DateTime(2020));
    final daysBack = DateTime.now().difference(bounds.start).inDays.clamp(1, 3650);

    final weeksBack = _rangePolicy.resolveWeeksBack(
      metricId: StatisticsMetricId.muscleAnalytics,
      effectiveDays: daysBack,
    );

    final data = await WorkoutLocalDataSource.instance.getMuscleGroupAnalytics(
      daysBack: daysBack,
      weeksBack: weeksBack,
    );

    if (!mounted) return;

    setState(() {
      _analytics = data;
      _isLoading = false;
    });
  }

  String _formatCompact(num value) {
    return StatisticsPresentationFormatter.compactNumber(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final muscles = (_analytics['muscles'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .where(
          (m) => !StatisticsPresentationFormatter.isOtherCategoryLabel(
            m['muscleGroup'] as String?,
          ),
        )
        .toList(growable: false);

    final undertrained =
        (_analytics['undertrained'] as List<dynamic>? ?? const [])
            .cast<String>();
    final dataQualityOk = (_analytics['dataQualityOk'] as bool?) ?? false;

    final workload = <String, double>{};
    for (final m in muscles) {
      final name = m['muscleGroup'] as String?;
      final sets = (m['equivalentSets'] as num?)?.toDouble() ?? 0.0;
      if (name != null && sets > 0.0) {
        workload[name] = sets;
      }
    }
    final highlights =
        MuscleColorHelper.mapVolumeToPrimaryColors(context, workload);

    final double totalWeeks =
        ((_analytics['daysBack'] as int?) ?? 7) / 7.0;

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.muscleAnalyticsTitle),
      body: SeamlessLoadingOverlay(
        isLoading: _isLoading,
        isEmpty: _analytics.isEmpty,
        extendBodyBehindAppBar: true,
        child: SingleChildScrollView(
              padding: DesignConstants.screenPadding.copyWith(
                top: DesignConstants.screenPadding.top + topPadding,
                bottom: DesignConstants.bottomContentSpacer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(l10n.analyticsPeriodLabel),
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
                  ),const SizedBox(height: DesignConstants.spacingM),
                  _sectionLabel(l10n.analyticsRecentDistributionHeatmap),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          if (workload.isEmpty)
                            AnalyticsChartDefaults.stateView(
                              context: context,
                              l10n: l10n,
                              status: AnalyticsStatus.empty,
                              emptyLabel: l10n.noWorkoutDataLabel,
                            )
                          else ...[
                            RepaintBoundary(
                              child: _buildBodyHeatmap(
                                context,
                                highlights,
                                muscles,
                              ),
                            ),
                          ],
                          const SizedBox(height: DesignConstants.spacingS),
                          Text(
                            l10n.analyticsRadarVolumeCaption,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  _sectionLabel(
                    l10n.analyticsWeeklySetsByMuscle,
                    isPrimary: true,
                  ),
                  RepaintBoundary(
                    child: _buildWeeklySetsCard(muscles, totalWeeks),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  _sectionLabel(l10n.analyticsFrequencyByMuscle),
                  RepaintBoundary(
                    child: _buildFrequencyCard(muscles),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  _sectionLabel(l10n.analyticsGuidanceTitle),
                  const SizedBox(height: DesignConstants.spacingXS),
                  Text(
                    dataQualityOk
                        ? l10n.analyticsGuidanceDirectionalDisclaimer
                        : l10n.analyticsGuidanceSoftenedDisclaimer,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  Text(
                    _guidanceLabel(dataQualityOk, undertrained),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildBodyHeatmap(
    BuildContext context,
    List<BodyPartHighlightData> highlights,
    List<Map<String, dynamic>> muscles,
  ) {
    return DualBodyHighlighter(
      gender: context.watch<ProfileService>().gender.toBodyGender(),
      frontHighlights: BodySlugMapper.forSide(highlights, BodySide.front),
      backHighlights: BodySlugMapper.forSide(highlights, BodySide.back),
      height: 320,
      onBodyPartTap: (slug, data) {
        final matched = muscles.firstWhere(
          (m) => BodySlugMapper.fromRawName(m['muscleGroup'] as String? ?? '')
              .contains(slug),
          orElse: () => const <String, dynamic>{},
        );
        if (matched.isNotEmpty) {
          _showMuscleDetail(matched);
        }
      },
    );
  }

  void _showMuscleDetail(Map<String, dynamic> muscle) {
    final l10n = AppLocalizations.of(context)!;
    final group = muscle['muscleGroup'] as String;
    final name = StatisticsPresentationFormatter.muscleGroupLabel(l10n, group);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: DesignConstants.spacingL),
                _buildDetailRow(
                  l10n.exerciseMetricVolume,
                  _formatCompact(
                    (muscle['equivalentSets'] as num).toDouble(),
                  ),
                  l10n.analyticsUnitSets,
                ),
                _buildDetailRow(
                  l10n.analyticsFrequencyByMuscle,
                  (muscle['frequencyPerWeek'] as num).toStringAsFixed(1),
                  l10n.analyticsPerWeekAbbrev,
                ),
                const SizedBox(height: DesignConstants.spacingM),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            '$value $unit',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySetsCard(List<Map<String, dynamic>> muscles, double totalWeeks) {
    final l10n = AppLocalizations.of(context)!;
    if (muscles.isEmpty) {
      return SizedBox(
        height: 180,
        child: AnalyticsChartDefaults.stateView(
          context: context,
          l10n: l10n,
          status: AnalyticsStatus.empty,
          emptyLabel: l10n.noWorkoutDataLabel,
          height: 180,
        ),
      );
    }

    final items = muscles
        .map(
          (m) => {
            'muscleGroup': m['muscleGroup'] as String,
            // Use total equivalent sets for the selected period instead of average per week
            'value': (m['equivalentSets'] as num).toDouble(),
          },
        )
        .where(
          (m) => !StatisticsPresentationFormatter.isOtherCategoryLabel(
            m['muscleGroup'] as String?,
          ),
        )
        .where((m) => (m['value'] as double) > 0)
        .toList()
      ..sort(
        (a, b) => (b['value'] as double).compareTo(a['value'] as double),
      );

    final labels = items
        .take(_maxMuscleBars)
        .map(
          (e) => StatisticsPresentationFormatter.muscleGroupLabel(
            l10n,
            e['muscleGroup'] as String,
          ),
        )
        .toList();

    final totalEquivalentSets = muscles.fold<double>(
      0.0,
      (sum, m) => sum + (m['equivalentSets'] as num).toDouble(),
    );
    final totalPerWeek = totalEquivalentSets / totalWeeks;

    return _buildMuscleBarChart(
      items: items.take(_maxMuscleBars).toList(),
      labels: labels,
      unit: l10n.analyticsUnitSets,
      emptyLabel: l10n.noWorkoutDataLabel,
      yAxisLabel:
          '${l10n.analyticsWeeklySetsByMuscle} (${l10n.analyticsUnitSets})',
      footer: l10n.analyticsWeekTotalEquivalentSets(
        totalPerWeek.toStringAsFixed(1),
      ),
      chartHeight: 260,
      emphasize: true,
    );
  }

  Widget _buildFrequencyCard(List<Map<String, dynamic>> muscles) {
    final l10n = AppLocalizations.of(context)!;
    final items = muscles
        .map(
          (m) => {
            'muscleGroup': m['muscleGroup'] as String,
            'value': (m['frequencyPerWeek'] as num).toDouble(),
          },
        )
        .where((m) => (m['value'] as double) > 0)
        .toList()
      ..sort(
        (a, b) => (b['value'] as double).compareTo(a['value'] as double),
      );

    final labels = items
        .take(_maxMuscleBars)
        .map(
          (e) => StatisticsPresentationFormatter.muscleGroupLabel(
            l10n,
            e['muscleGroup'] as String,
          ),
        )
        .toList();

    return _buildMuscleBarChart(
      items: items.take(_maxMuscleBars).toList(),
      labels: labels,
      unit: '/${l10n.analyticsPerWeekAbbrev}',
      emptyLabel: l10n.noWorkoutDataLabel,
      yAxisLabel:
          '${l10n.analyticsFrequencyByMuscle} (/${l10n.analyticsPerWeekAbbrev})',
      footer: l10n.analyticsFrequencyRuleFooter,
    );
  }

  Widget _buildMuscleBarChart({
    required List<Map<String, dynamic>> items,
    required List<String> labels,
    required String unit,
    required String emptyLabel,
    required String footer,
    required String yAxisLabel,
    double chartHeight = 220,
    bool emphasize = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return SizedBox(
        height: chartHeight,
        child: AnalyticsChartDefaults.stateView(
          context: context,
          l10n: l10n,
          status: AnalyticsStatus.empty,
          emptyLabel: emptyLabel,
          height: chartHeight,
        ),
      );
    }

    final values = items.map((e) => (e['value'] as num).toDouble()).toList();

    final rawMax =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final double computedMaxY;
    double tickInterval;

    if (rawMax <= 5) {
      computedMaxY = 5.0;
      tickInterval = 1.0;
    } else if (rawMax <= 10) {
      computedMaxY = 10.0;
      tickInterval = 2.0;
    } else if (rawMax <= 20) {
      computedMaxY = 20.0;
      tickInterval = 4.0;
    } else {
      computedMaxY = (rawMax * 1.15).ceilToDouble();
      tickInterval = (computedMaxY / 5).ceilToDouble();
      if (tickInterval == 0) {
        tickInterval = 1.0;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (emphasize)
          Container(
            margin: const EdgeInsets.only(bottom: DesignConstants.spacingS),
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingS,
              vertical: DesignConstants.spacingXS,
            ),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              l10n.analyticsEquivalentSetsExplainer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        AnalyticsChartDefaults.axisTitleLabel(
          context,
          'Y: $yAxisLabel',
        ),
        const SizedBox(height: DesignConstants.spacingS),
        SizedBox(
          height: chartHeight,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              gridData: AnalyticsChartDefaults.themeAwareCompactGrid(context),
              borderData: AnalyticsChartDefaults.noBorder,
              maxY: computedMaxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBorderRadius: BorderRadius.circular(16),
                  tooltipMargin: 12,
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  getTooltipColor: (_) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return isDark
                        ? const Color(0xFF2A2A2A)
                        : Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.95);
                  },
                  tooltipBorder: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.08),
                  ),
                  getTooltipItem: (group, _, rod, __) {
                    final index = group.x.toInt();
                    final label = labels[index];
                    final value = values[index];
                    return BarTooltipItem(
                      '$label\n${_formatCompact(value)} $unit',
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ) ??
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    );
                  },
                ),
              ),
              titlesData: AnalyticsChartDefaults.standardTitles(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: tickInterval,
                    getTitlesWidget: (value, meta) =>
                        AnalyticsChartDefaults.tickLabel(
                      context,
                      _formatCompact(value),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      final label = labels[index];
                      final compact = label.length > 8
                          ? '${label.substring(0, 8)}...'
                          : label;
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        angle: -45 * 3.141592653589793 / 180,
                        child: AnalyticsChartDefaults.tickLabel(
                          context,
                          compact,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: values
                  .asMap()
                  .entries
                  .map(
                    (entry) => BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          width: emphasize ? 16 : 14,
                          borderRadius: BorderRadius.circular(4),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        AnalyticsChartDefaults.axisTitleLabel(
          context,
          'X: ${l10n.analyticsViewByMuscle}',
        ),
        const SizedBox(height: 6),
        Text(
          footer,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }

  String _guidanceLabel(bool dataQualityOk, List<String> undertrained) {
    final l10n = AppLocalizations.of(context)!;
    return StatisticsPresentationFormatter.muscleGuidanceLabel(
      l10n,
      dataQualityOk,
      undertrained,
    );
  }

  Widget _sectionLabel(String text, {bool isPrimary = false}) {
    return AppSectionHeader(
      title: text,
      padding: isPrimary
          ? const EdgeInsets.only(
              left: DesignConstants.spacingXS,
              bottom: DesignConstants.spacingS,
              top: DesignConstants.spacingXS)
          : null,
    );
  }
}
