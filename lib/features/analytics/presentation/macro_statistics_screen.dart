// lib/features/analytics/presentation/macro_statistics_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../theme/app_colors.dart';
import '../../../util/design_constants.dart';
import '../../../util/timeframe_label_formatter.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/macro_badge_row.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart'
    as adaptive_pickers;
import '../../../widgets/common/summary_card.dart';
import '../../statistics/data/macro_analytics_data_adapter.dart';
import '../../statistics/domain/timeframe_block.dart';
import 'widgets/macro_history_stacked_bar_chart.dart';

/// Screen displaying historical macronutrient distribution and caloric intake.
class MacroStatisticsScreen extends StatefulWidget {
  final int initialRangeIndex;
  final DateTime? initialAnchorDate;
  final bool? initialIsRolling;

  const MacroStatisticsScreen({
    super.key,
    this.initialRangeIndex = 0,
    this.initialAnchorDate,
    this.initialIsRolling,
  });

  @override
  State<MacroStatisticsScreen> createState() => _MacroStatisticsScreenState();
}

class _MacroStatisticsScreenState extends State<MacroStatisticsScreen> {
  final MacroAnalyticsDataAdapter _adapter = const MacroAnalyticsDataAdapter();

  TimeframeBlock _activeBlock = TimeframeBlock.week;
  DateTime _anchorDate = DateTime.now();
  bool _isRolling = true;
  DailyMacroIntake? _selectedDay;

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
    if (widget.initialAnchorDate != null) {
      _anchorDate = widget.initialAnchorDate!;
    }
    if (widget.initialIsRolling != null) {
      _isRolling = widget.initialIsRolling!;
    }
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
        _selectedDay = null;
      });
    } catch (_) {
      if (!mounted || loadEpoch != _loadEpoch) return;
      setState(() {
        _summary = null;
        _isLoading = false;
        _selectedDay = null;
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
                      _isRolling = false;
                    });
                    _load();
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
                                myBounds.start.isAtSameMomentAs(
                                    currentBounds.start);

                            if (isOngoing) {
                              _isRolling = true;
                            } else if (_isRolling) {
                              _isRolling = false;
                              _anchorDate = _activeBlock.shift(
                                  DateTime.now(), -1);
                            } else {
                              _anchorDate =
                                  _activeBlock.shift(_anchorDate, -1);
                            }
                          });
                          _load();
                        },
                  onNext: _activeBlock == TimeframeBlock.maxBlock
                      ? null
                      : () {
                          setState(() {
                            if (_isRolling) {
                              _isRolling = false;
                              _anchorDate = DateTime.now();
                            } else {
                              final previousAnchor = _activeBlock
                                  .shift(DateTime.now(), -1);
                              final previousBounds = _activeBlock.getBounds(
                                  previousAnchor, DateTime(2020));
                              final myBounds = _activeBlock.getBounds(
                                  _anchorDate, DateTime(2020));
                              final isPreviousToOngoing = !_isRolling &&
                                  myBounds.start.isAtSameMomentAs(
                                      previousBounds.start);

                              if (isPreviousToOngoing) {
                                _isRolling = true;
                              } else {
                                _anchorDate = _activeBlock.shift(
                                    _anchorDate, 1);
                              }
                            }
                          });
                          _load();
                        },
                  displayDate: _isRolling
                      ? TimeframeLabelFormatter.formatRolling(
                          _activeBlock, l10n)
                      : TimeframeLabelFormatter.format(
                          _activeBlock, _anchorDate, l10n),
                  onTapDateDisplay: () async {
                    final selected = await adaptive_pickers
                        .showAdaptiveTimeframePicker(
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
                      _load();
                    }
                  },
                  nextEnabled: _activeBlock == TimeframeBlock.maxBlock
                      ? false
                      : (_isRolling
                          ? false
                          : !_activeBlock
                              .getBounds(_anchorDate, DateTime(2020))
                              .start
                              .isAtSameMomentAs(_activeBlock
                                  .getBounds(
                                      DateTime.now(), DateTime(2020))
                                  .start)),
                  showDateNavigation:
                      _activeBlock != TimeframeBlock.maxBlock,
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
                // Main Stacked Bar Chart (starts from very left edge of screen)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 0,
                    right: DesignConstants.spacingM,
                  ),
                  child: _summary != null
                      ? MacroHistoryStackedBarChart(
                          dailyIntakes: _summary!.dailyIntakes,
                          range: _summary!.range,
                          is7Days: _activeBlock == TimeframeBlock.week,
                          selectedDay: _selectedDay,
                          onDaySelected: (day) =>
                              setState(() => _selectedDay = day),
                        )
                      : const SizedBox(
                          height: 220,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                ),
                const SizedBox(height: DesignConstants.spacingM),

                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.spacingL,
                  ),
                  child: _buildLegend(
                    context,
                    proteinColor: proteinColor,
                    fatColor: fatColor,
                    carbsColor: carbsColor,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingL),

                // Daily Breakdown List
                _buildDailyBreakdown(context),
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
    final summary = _summary;
    final selected = _selectedDay;

    // When a day is hovered/selected via press-and-hold, show its exact values.
    // Otherwise fall back to the period averages.
    final bool showDay = selected != null;

    final calText = showDay
        ? '${selected.calories}'
        : (summary != null ? '${summary.avgCalories}' : '--');
    final protText = showDay
        ? '${selected.proteinGrams.toStringAsFixed(0)} g'
        : (summary != null
            ? '${summary.avgProtein.toStringAsFixed(0)} g'
            : '--');
    final fatText = showDay
        ? '${selected.fatGrams.toStringAsFixed(0)} g'
        : (summary != null
            ? '${summary.avgFat.toStringAsFixed(0)} g'
            : '--');
    final carbsText = showDay
        ? '${selected.carbsGrams.toStringAsFixed(0)} g'
        : (summary != null
            ? '${summary.avgCarbs.toStringAsFixed(0)} g'
            : '--');

    // Sub-label distinguishes "avg" mode from "selected day" mode
    final calLabel = showDay ? 'Kalorien' : 'Ø Kalorien';
    final protLabel = showDay ? 'Protein' : 'Ø Protein';
    final fatLabel = showDay ? 'Fett' : 'Ø Fett';
    final carbsLabel = showDay ? 'Carbs' : 'Ø Carbs';

    return Row(
      children: [
        Expanded(
          child: _buildMetricCol(
            context,
            label: calLabel,
            value: calText,
            unit: 'kcal',
            color: calColor,
          ),
        ),
        Expanded(
          child: _buildMetricCol(
            context,
            label: protLabel,
            value: protText,
            color: proteinColor,
          ),
        ),
        Expanded(
          child: _buildMetricCol(
            context,
            label: fatLabel,
            value: fatText,
            color: fatColor,
          ),
        ),
        Expanded(
          child: _buildMetricCol(
            context,
            label: carbsLabel,
            value: carbsText,
            color: carbsColor,
          ),
        ),
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


  Widget _buildDailyBreakdown(BuildContext context) {
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
        const AppSectionHeader(
          title: 'Tagesverlauf',
          padding: EdgeInsets.symmetric(horizontal: DesignConstants.spacingL),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacingL,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trackedDays.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: DesignConstants.spacingS),
            itemBuilder: (context, index) {
              final day = trackedDays[index];
              final dateStr = DateFormat.yMMMEd(locale).format(day.date);

              return SummaryCard(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.spacingM,
                    vertical: DesignConstants.spacingS,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      MacroBadgeRow(
                        kcal: day.calories,
                        protein: day.proteinGrams,
                        fat: day.fatGrams,
                        carbs: day.carbsGrams,
                        useBadges: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
