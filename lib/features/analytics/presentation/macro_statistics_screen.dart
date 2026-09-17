// lib/features/analytics/presentation/macro_statistics_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../theme/app_colors.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../statistics/data/macro_analytics_data_adapter.dart';
import '../../statistics/domain/timeframe_block.dart';
import 'widgets/macro_history_stacked_bar_chart.dart';

/// Screen displaying historical macronutrient distribution and caloric intake.
class MacroStatisticsScreen extends StatefulWidget {
  final int initialRangeIndex;

  const MacroStatisticsScreen({
    super.key,
    this.initialRangeIndex = 0,
  });

  @override
  State<MacroStatisticsScreen> createState() => _MacroStatisticsScreenState();
}

class _MacroStatisticsScreenState extends State<MacroStatisticsScreen> {
  final MacroAnalyticsDataAdapter _adapter = const MacroAnalyticsDataAdapter();

  TimeframeBlock _activeBlock = TimeframeBlock.week;
  DateTime _anchorDate = DateTime.now();
  bool _isRolling = true;

  final List<TimeframeBlock> _validBlocks = const [
    TimeframeBlock.week,
    TimeframeBlock.month,
    TimeframeBlock.threeMonths,
    TimeframeBlock.sixMonths,
    TimeframeBlock.year,
    TimeframeBlock.maxBlock,
  ];

  MacroPeriodSummary? _summary;
  bool _isLoading = true;
  int _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance.trackScreenView(
      screenName: ScreenName.bodyNutritionCorrelation,
    ));
    final index = widget.initialRangeIndex.clamp(0, _validBlocks.length - 1);
    _activeBlock = _validBlocks[index];
    _load();
  }

  Future<void> _load() async {
    final loadEpoch = ++_loadEpoch;
    setState(() => _isLoading = true);

    try {
      final bounds = _isRolling
          ? _activeBlock.getRollingBounds()
          : _activeBlock.getBounds(_anchorDate, DateTime(2020));

      final summary = await _adapter.fetchSummary(range: bounds);
      if (!mounted || loadEpoch != _loadEpoch) return;

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || loadEpoch != _loadEpoch) return;
      setState(() {
        _summary = null;
        _isLoading = false;
      });
    }
  }

  List<String> _ranges(AppLocalizations l10n) => [
        l10n.filter7DaysShort,
        l10n.filter1MonthShort,
        l10n.filter3MonthsShort,
        l10n.filter6MonthsShort,
        l10n.filter1YearShort,
        l10n.filterMax,
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final macroColors = theme.extension<MacroColors>();

    final proteinColor = macroColors?.protein ?? Colors.red;
    final carbsColor = macroColors?.carbs ?? Colors.green.shade400;
    final fatColor = macroColors?.fat ?? Colors.purple.shade300;
    final calColor = macroColors?.calories ?? Colors.orange;

    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.nutrition,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: DesignConstants.screenPadding.top + topPadding,
              bottom: DesignConstants.bottomContentSpacer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Range Filter
                TimeRangeFilter(
                  ranges: _ranges(l10n),
                  selectedIndex: _validBlocks.indexOf(_activeBlock),
                  onSelected: (index) {
                    setState(() {
                      _activeBlock = _validBlocks[index];
                      _isRolling = true;
                      _anchorDate = DateTime.now();
                    });
                    _load();
                  },
                  showDateNavigation: false,
                ),
                const SizedBox(height: DesignConstants.spacingL),

                // 4-Metric Average Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.spacingL,
                  ),
                  child: _buildMetricsHeader(
                    context,
                    calColor: calColor,
                    proteinColor: proteinColor,
                    fatColor: fatColor,
                    carbsColor: carbsColor,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingL),

                // Main Stacked Bar Chart Card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.spacingL,
                  ),
                  child: SummaryCard(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: DesignConstants.cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_summary != null)
                            MacroHistoryStackedBarChart(
                              dailyIntakes: _summary!.dailyIntakes,
                              range: _summary!.range,
                            )
                          else
                            const SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          const SizedBox(height: DesignConstants.spacingM),
                          const Divider(height: 1),
                          const SizedBox(height: DesignConstants.spacingS),
                          // Legend
                          _buildLegend(
                            context,
                            proteinColor: proteinColor,
                            fatColor: fatColor,
                            carbsColor: carbsColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingXL),

                // Daily Breakdown List
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.spacingL,
                  ),
                  child: _buildDailyBreakdown(
                    context,
                    proteinColor: proteinColor,
                    fatColor: fatColor,
                    carbsColor: carbsColor,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Positioned(
              top: topPadding + DesignConstants.spacingM,
              right: DesignConstants.spacingM,
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsHeader(
    BuildContext context, {
    required Color calColor,
    required Color proteinColor,
    required Color fatColor,
    required Color carbsColor,
  }) {
    final theme = Theme.of(context);
    final summary = _summary;

    final calText = summary != null ? '${summary.avgCalories}' : '--';
    final protText =
        summary != null ? '${summary.avgProtein.toStringAsFixed(0)} g' : '--';
    final fatText =
        summary != null ? '${summary.avgFat.toStringAsFixed(0)} g' : '--';
    final carbsText =
        summary != null ? '${summary.avgCarbs.toStringAsFixed(0)} g' : '--';

    final locale = Localizations.localeOf(context).toString();
    String rangeText = '';
    if (summary != null) {
      final start = DateFormat.MMMd(locale).format(summary.range.start);
      final end = DateFormat.yMMMd(locale).format(summary.range.end);
      rangeText = '$start – $end';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCol(
                context,
                label: 'Kalorien',
                value: calText,
                unit: 'kcal',
                color: calColor,
              ),
            ),
            Expanded(
              child: _buildMetricCol(
                context,
                label: 'Protein',
                value: protText,
                color: proteinColor,
              ),
            ),
            Expanded(
              child: _buildMetricCol(
                context,
                label: 'Fett',
                value: fatText,
                color: fatColor,
              ),
            ),
            Expanded(
              child: _buildMetricCol(
                context,
                label: 'Carbs',
                value: carbsText,
                color: carbsColor,
              ),
            ),
          ],
        ),
        if (rangeText.isNotEmpty) ...[
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            rangeText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCol(
    BuildContext context, {
    required String label,
    required String value,
    String? unit,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(
    BuildContext context, {
    required Color proteinColor,
    required Color fatColor,
    required Color carbsColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem(context, 'Protein', proteinColor),
        _legendItem(context, 'Fett', fatColor),
        _legendItem(context, 'Kohlenhydrate', carbsColor),
      ],
    );
  }

  Widget _legendItem(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyBreakdown(
    BuildContext context, {
    required Color proteinColor,
    required Color fatColor,
    required Color carbsColor,
  }) {
    final theme = Theme.of(context);
    final summary = _summary;
    if (summary == null || summary.dailyIntakes.isEmpty) {
      return const SizedBox.shrink();
    }

    final trackedDays =
        summary.dailyIntakes.where((d) => d.hasData).toList().reversed.toList();
    if (trackedDays.isEmpty) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tagesverlauf',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingM),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: trackedDays.length,
          separatorBuilder: (_, __) => const SizedBox(height: DesignConstants.spacingS),
          itemBuilder: (context, index) {
            final day = trackedDays[index];
            final dateStr = DateFormat.yMMMEd(locale).format(day.date);

            final carbsKcal = day.carbsGrams * 4;
            final proteinKcal = day.proteinGrams * 4;
            final fatKcal = day.fatGrams * 9;
            final totalKcal = max(1.0, carbsKcal + proteinKcal + fatKcal);

            final pPct = (proteinKcal / totalKcal * 100).round();
            final fPct = (fatKcal / totalKcal * 100).round();
            final cPct = (carbsKcal / totalKcal * 100).round();

            return SummaryCard(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingM,
                  vertical: DesignConstants.spacingS,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$pPct% P (${day.proteinGrams.toStringAsFixed(0)}g) • $fPct% F (${day.fatGrams.toStringAsFixed(0)}g) • $cPct% C (${day.carbsGrams.toStringAsFixed(0)}g)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${day.calories} kcal',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
