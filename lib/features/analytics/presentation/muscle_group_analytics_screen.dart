import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:skeletonizer/skeletonizer.dart';
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
import '../../exercise_catalog/domain/exercise_classification_labels.dart';
import '../../../widgets/common/dual_body_highlighter.dart';
import '../../../util/timeframe_label_formatter.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart'
    as adaptive_pickers;
import '../../statistics/domain/timeframe_block.dart';
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';

class MuscleGroupAnalyticsScreen extends StatefulWidget {
  const MuscleGroupAnalyticsScreen({super.key});

  @override
  State<MuscleGroupAnalyticsScreen> createState() =>
      _MuscleGroupAnalyticsScreenState();
}

enum _MuscleAnalyticsView { chart, grid }

class _MuscleGroupAnalyticsScreenState
    extends State<MuscleGroupAnalyticsScreen> {
  bool _isRolling = true;
  static const _maxMuscleBars = 8;
  final _rangePolicy = StatisticsRangePolicyService.instance;
  bool _isLoading = true;
  _MuscleAnalyticsView _view = _MuscleAnalyticsView.grid;
  bool _showTotalVolume = false;

  TimeframeBlock _activeBlock = TimeframeBlock.week;
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
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.muscleGroupAnalytics));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final bounds = _isRolling
        ? _activeBlock.getRollingBounds()
        : _activeBlock.getBounds(_anchorDate, DateTime(2020));
    final daysBack =
        DateTime.now().difference(bounds.start).inDays.clamp(1, 3650);

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

    final hasNoData = _analytics.isEmpty;
    final displayAnalytics = hasNoData ? getMockAnalytics() : _analytics;

    final muscles = (displayAnalytics['muscles'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .where((m) {
      final group = m['muscleGroup'] as String?;
      return group != 'unclassified' &&
          !StatisticsPresentationFormatter.isOtherCategoryLabel(group);
    }).toList(growable: false);

    final movementPatterns =
        (displayAnalytics['movementPatterns'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .where((pattern) => pattern['movementPattern'] != 'unclassified')
            .toList(growable: false);

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
        ((displayAnalytics['daysBack'] as int?) ?? 7) / 7.0;

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    Widget bodyContent = _buildMuscleContent(
      context,
      muscles,
      movementPatterns,
      totalWeeks,
      highlights,
      l10n,
    );

    if (hasNoData) {
      bodyContent = ActiveGapOverlay(
        message: "Keine Volumenverteilung vorhanden",
        background: Skeletonizer(
          enabled: true,
          child: IgnorePointer(child: bodyContent),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.muscleAnalyticsTitle,
        actions: [_buildViewToggle(l10n)],
      ),
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
              bodyContent,
              _buildVolumeModeToggle(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle(AppLocalizations l10n) {
    final showGrid = _view == _MuscleAnalyticsView.chart;
    return IconButton(
      tooltip: showGrid
          ? l10n.analyticsSwitchToOverview
          : l10n.analyticsSwitchToChart,
      icon: Icon(
        showGrid ? LucideIcons.grid_2x2 : LucideIcons.chart_no_axes_column,
      ),
      onPressed: () {
        setState(() {
          _view =
              showGrid ? _MuscleAnalyticsView.grid : _MuscleAnalyticsView.chart;
        });
      },
    );
  }

  Widget _buildVolumeModeToggle(AppLocalizations l10n) {
    final showWeekly = !_showTotalVolume;
    return Center(
      child: Tooltip(
        message: showWeekly
            ? l10n.analyticsVolumeTotal
            : l10n.analyticsVolumeWeeklyAverage,
        child: TextButton.icon(
          icon: const Icon(LucideIcons.calendar_days, size: 16),
          label: Text(
            showWeekly
                ? l10n.analyticsVolumeWeeklyAverage
                : l10n.analyticsVolumeTotal,
          ),
          onPressed: () {
            setState(() => _showTotalVolume = !_showTotalVolume);
          },
        ),
      ),
    );
  }

  double _displayVolumeValue(double value, double totalWeeks) {
    return _showTotalVolume ? value : value / totalWeeks;
  }

  String _volumeUnit(AppLocalizations l10n) {
    return _showTotalVolume
        ? l10n.analyticsUnitSets
        : '${l10n.analyticsUnitSets} / ${l10n.analyticsPerWeekAbbrev}';
  }

  String _volumeSectionTitle(AppLocalizations l10n, String totalTitle) {
    return _showTotalVolume
        ? totalTitle
        : '$totalTitle (${l10n.analyticsVolumeWeeklyAverage})';
  }

  Widget _volumeContextChip(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
      ),
      child: Text(
        _showTotalVolume
            ? l10n.analyticsVolumeTotal
            : l10n.analyticsVolumeWeeklyAverage,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
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
    final name = _muscleLabel(l10n, group);

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
                  l10n.analyticsWorkSets,
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

  Widget _buildWeeklySetsCard(
      List<Map<String, dynamic>> muscles, double totalWeeks) {
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
            // Coverage uses direct primary-muscle working-set counts.
            'value': _displayVolumeValue(
              (m['equivalentSets'] as num).toDouble(),
              totalWeeks,
            ),
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
          (e) => _muscleLabel(l10n, e['muscleGroup'] as String),
        )
        .toList();

    final totalWorkingSets = muscles.fold<double>(
      0.0,
      (sum, m) => sum + (m['equivalentSets'] as num).toDouble(),
    );
    final totalPerWeek = totalWorkingSets / totalWeeks;

    return _buildMuscleBarChart(
      items: items.take(_maxMuscleBars).toList(),
      labels: labels,
      unit: l10n.analyticsUnitSets,
      emptyLabel: l10n.noWorkoutDataLabel,
      yAxisLabel: '${l10n.analyticsWorkingSetsByMuscle} (${_volumeUnit(l10n)})',
      footer: _showTotalVolume
          ? l10n.analyticsTotalWorkingSets(
              _formatCompact(totalWorkingSets),
            )
          : l10n.analyticsAverageWorkingSetsPerWeek(
              totalPerWeek.toStringAsFixed(1),
            ),
      chartHeight: 260,
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
          (e) => _muscleLabel(l10n, e['muscleGroup'] as String),
        )
        .toList();

    return _buildMuscleBarChart(
      items: items.take(_maxMuscleBars).toList(),
      labels: labels,
      unit: '/${l10n.analyticsPerWeekAbbrev}',
      emptyLabel: l10n.noWorkoutDataLabel,
      yAxisLabel:
          '${l10n.analyticsFrequencyByMuscle} (/${l10n.analyticsPerWeekAbbrev})',
      footer: l10n.analyticsFrequencyWorkingSetFooter,
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
    String? xAxisLabel,
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
                        ? DesignConstants.summaryCardDarkMode
                        : DesignConstants.summaryCardSecondaryLightMode;
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
                                color: Theme.of(context).colorScheme.onSurface,
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
                    reservedSize: 120,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      final label = labels[index];
                      return SideTitleWidget(
                        meta: meta,
                        space: 28,
                        angle: -52 * 3.141592653589793 / 180,
                        child: Transform.translate(
                          offset: const Offset(-20, 0),
                          child: SizedBox(
                            width: 112,
                            height: 40,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
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
                          width: 14,
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
          'X: ${xAxisLabel ?? l10n.analyticsViewByMuscle}',
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

  String _muscleLabel(AppLocalizations l10n, String raw) {
    return StatisticsPresentationFormatter.muscleGroupLabel(l10n, raw);
  }

  String _movementPatternLabel(BuildContext context, String raw) {
    if (raw == 'other') {
      return AppLocalizations.of(context)!.analyticsPatternOther;
    }
    return ExerciseClassificationLabels.movementPattern(context, raw) ?? raw;
  }

  Widget _sectionLabel(
    String text, {
    bool isPrimary = false,
    Widget? action,
  }) {
    return AppSectionHeader(
      title: text,
      action: action,
      padding: isPrimary
          ? const EdgeInsets.only(
              left: DesignConstants.spacingXS,
              bottom: DesignConstants.spacingS,
              top: DesignConstants.spacingXS)
          : null,
    );
  }

  Map<String, dynamic> getMockAnalytics() {
    return {
      'daysBack': 7,
      'muscles': [
        {
          'muscleGroup': 'chest',
          'equivalentSets': 12.0,
          'frequencyPerWeek': 3.0
        },
        {
          'muscleGroup': 'back',
          'equivalentSets': 10.0,
          'frequencyPerWeek': 2.0
        },
        {
          'muscleGroup': 'quads',
          'equivalentSets': 8.0,
          'frequencyPerWeek': 2.0
        },
        {
          'muscleGroup': 'shoulders',
          'equivalentSets': 6.0,
          'frequencyPerWeek': 1.0
        },
        {
          'muscleGroup': 'biceps',
          'equivalentSets': 4.0,
          'frequencyPerWeek': 2.0
        },
        {
          'muscleGroup': 'triceps',
          'equivalentSets': 4.0,
          'frequencyPerWeek': 2.0
        },
      ],
      'movementPatterns': [
        {'movementPattern': 'horizontal_push', 'setCount': 12.0},
        {'movementPattern': 'vertical_pull', 'setCount': 8.0},
      ],
    };
  }

  Widget _buildMuscleContent(
    BuildContext context,
    List<Map<String, dynamic>> muscles,
    List<Map<String, dynamic>> movementPatterns,
    double totalWeeks,
    List<BodyPartHighlightData> highlights,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(l10n.analyticsRecentDistributionHeatmap),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RepaintBoundary(
              child: _buildBodyHeatmap(
                context,
                highlights,
                muscles,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.analyticsPrimaryMuscleCoverageCaption,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingM),
        if (_view == _MuscleAnalyticsView.grid)
          _buildGridContent(
            context,
            muscles,
            movementPatterns,
            totalWeeks,
            l10n,
          )
        else ...[
          _sectionLabel(
            _volumeSectionTitle(l10n, l10n.analyticsWorkingSetsByMuscle),
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
          _buildMovementPatternContent(
            context,
            movementPatterns,
            totalWeeks,
            l10n,
          ),
          const SizedBox(height: DesignConstants.spacingM),
        ],
      ],
    );
  }

  Widget _buildGridContent(
    BuildContext context,
    List<Map<String, dynamic>> muscles,
    List<Map<String, dynamic>> movementPatterns,
    double totalWeeks,
    AppLocalizations l10n,
  ) {
    final sortedMuscles = List<Map<String, dynamic>>.from(muscles)
      ..sort((a, b) {
        final bySets = ((b['equivalentSets'] as num?)?.toDouble() ?? 0)
            .compareTo((a['equivalentSets'] as num?)?.toDouble() ?? 0);
        if (bySets != 0) return bySets;
        return _muscleLabel(l10n, a['muscleGroup'] as String).compareTo(
          _muscleLabel(l10n, b['muscleGroup'] as String),
        );
      });
    final sortedPatterns = List<Map<String, dynamic>>.from(movementPatterns)
      ..sort((a, b) {
        final bySets = ((b['setCount'] as num?)?.toDouble() ?? 0)
            .compareTo((a['setCount'] as num?)?.toDouble() ?? 0);
        if (bySets != 0) return bySets;
        return _movementPatternLabel(context, a['movementPattern'] as String)
            .compareTo(
          _movementPatternLabel(context, b['movementPattern'] as String),
        );
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          l10n.analyticsWorkingSetsByMuscle,
          action: _volumeContextChip(context, l10n),
        ),
        _buildTwoColumnGrid(
          sortedMuscles
              .map(
                (muscle) => ValueSummaryCard(
                  value:
                      '${_formatCompact(_displayVolumeValue((muscle['equivalentSets'] as num?)?.toDouble() ?? 0, totalWeeks))} ${l10n.analyticsUnitSets}',
                  label: _muscleLabel(l10n, muscle['muscleGroup'] as String),
                  subtitle: l10n.analyticsAverageFrequencyPerWeek(
                    ((muscle['frequencyPerWeek'] as num?)?.toDouble() ?? 0)
                        .toStringAsFixed(1),
                  ),
                  useSecondarySurface: true,
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: DesignConstants.spacingM),
        _sectionLabel(
          l10n.analyticsWorkingSetsByPattern,
          action: _volumeContextChip(context, l10n),
        ),
        _buildTwoColumnGrid(
          sortedPatterns
              .map(
                (pattern) => ValueSummaryCard(
                  value:
                      '${_formatCompact(_displayVolumeValue((pattern['setCount'] as num?)?.toDouble() ?? 0, totalWeeks))} ${l10n.analyticsUnitSets}',
                  label: _movementPatternLabel(
                    context,
                    pattern['movementPattern'] as String,
                  ),
                  useSecondarySurface: true,
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: DesignConstants.spacingM),
      ],
    );
  }

  Widget _buildTwoColumnGrid(List<Widget> items) {
    final rows = <Widget>[];
    for (var index = 0; index < items.length; index += 2) {
      final right =
          index + 1 < items.length ? items[index + 1] : const SizedBox();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: items[index]),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(child: right),
            ],
          ),
        ),
      );
      if (index + 2 < items.length) {
        rows.add(const SizedBox(height: DesignConstants.spacingS));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildMovementPatternContent(
    BuildContext context,
    List<Map<String, dynamic>> movementPatterns,
    double totalWeeks,
    AppLocalizations l10n,
  ) {
    final items = movementPatterns
        .map(
          (pattern) => <String, dynamic>{
            'value': _displayVolumeValue(
              (pattern['setCount'] as num?)?.toDouble() ?? 0.0,
              totalWeeks,
            ),
            'movementPattern':
                pattern['movementPattern'] as String? ?? 'unclassified',
          },
        )
        .where((pattern) => (pattern['value'] as double) > 0)
        .toList()
      ..sort(
        (a, b) => (b['value'] as double).compareTo(a['value'] as double),
      );
    final labels = items
        .take(_maxMuscleBars)
        .map(
          (pattern) => _movementPatternLabel(
            context,
            pattern['movementPattern'] as String,
          ),
        )
        .toList();
    final totalSets = items.fold<double>(
      0,
      (sum, pattern) => sum + (pattern['value'] as double),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          _volumeSectionTitle(l10n, l10n.analyticsWorkingSetsByPattern),
        ),
        Text(
          l10n.analyticsMovementPatternCoverageCaption,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: DesignConstants.spacingM),
        RepaintBoundary(
          child: _buildMuscleBarChart(
            items: items.take(_maxMuscleBars).toList(),
            labels: labels,
            unit: _volumeUnit(l10n),
            emptyLabel: l10n.noWorkoutDataLabel,
            yAxisLabel:
                '${l10n.analyticsWorkingSetsByPattern} (${_volumeUnit(l10n)})',
            xAxisLabel: l10n.analyticsCoverageMovementPatterns,
            footer: _showTotalVolume
                ? l10n.analyticsTotalWorkingSets(_formatCompact(totalSets))
                : l10n.analyticsAverageWorkingSetsPerWeek(
                    _formatCompact(totalSets),
                  ),
            chartHeight: 280,
          ),
        ),
      ],
    );
  }
}
