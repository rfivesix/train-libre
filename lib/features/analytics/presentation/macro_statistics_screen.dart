// lib/features/analytics/presentation/macro_statistics_screen.dart

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  final TimeframeBlock initialBlock;
  final DateTime? initialAnchorDate;
  final bool? initialIsRolling;
  final MacroAnalyticsDataAdapter adapter;

  const MacroStatisticsScreen({
    super.key,
    this.initialBlock = TimeframeBlock.week,
    this.initialAnchorDate,
    this.initialIsRolling,
    this.adapter = const MacroAnalyticsDataAdapter(),
  });

  @override
  State<MacroStatisticsScreen> createState() => _MacroStatisticsScreenState();
}

class _MacroStatisticsScreenState extends State<MacroStatisticsScreen> {
  final ScrollController _scrollController = ScrollController();

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(
      TelemetryService.instance.trackScreenView(
        screenName: ScreenName.bodyNutritionCorrelation,
      ),
    );
    _activeBlock = _validBlocks.contains(widget.initialBlock)
        ? widget.initialBlock
        : TimeframeBlock.week;
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

      final summary = await widget.adapter.fetchSummary(range: bounds);
      if (!mounted || loadEpoch != _loadEpoch) return;

      final resolvedSummary = _activeBlock == TimeframeBlock.maxBlock
          ? summary.trimmedToFirstTracked()
          : summary;

      setState(() {
        _summary = resolvedSummary;
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

    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 56;

    final timeframeFilter = TimeRangeFilter(
      ranges: _ranges(l10n),
      selectedIndex: _validBlocks.indexOf(_activeBlock),
      onSelected: (index) {
        setState(() {
          _activeBlock = _validBlocks[index];
          _isRolling = _activeBlock != TimeframeBlock.maxBlock;
          _anchorDate = DateTime.now();
        });
        _load();
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
              _load();
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
          _load();
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

    final isInitialLoading = _isLoading && _summary == null;
    final hasNoChartData =
        !_isLoading && (_summary == null || _summary!.trackedDays == 0);
    final useMockData =
        isInitialLoading || _summary == null || _summary!.trackedDays == 0;
    final mockRange = _activeBlock == TimeframeBlock.maxBlock
        ? TimeframeBlock.month.getRollingBounds()
        : (_isRolling
              ? _activeBlock.getRollingBounds()
              : _activeBlock.getBounds(_anchorDate, DateTime(2020)));
    final displaySummary = useMockData
        ? MacroPeriodSummary.mockPreview(mockRange)
        : _summary!;

    Widget bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!useMockData &&
            _activeBlock == TimeframeBlock.maxBlock &&
            displaySummary.dailyIntakes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingL,
            ),
            child: Text(
              _formatMaxRangeLabel(context, displaySummary.range),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
        ],

        // 4-Metric Average Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacingL,
          ),
          child: _buildMetricsHeader(
            context,
            summary: displaySummary,
            selected: useMockData ? null : _selectedDay,
            calColor: calColor,
            proteinColor: proteinColor,
            fatColor: fatColor,
            carbsColor: carbsColor,
          ),
        ),
        if (!useMockData && displaySummary.incompleteDays > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignConstants.spacingL,
              DesignConstants.spacingS,
              DesignConstants.spacingL,
              0,
            ),
            child: Text(
              l10n.nutritionStatisticsDayCoverage(
                displaySummary.trackedDays,
                displaySummary.incompleteDays,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: DesignConstants.spacingM),
        // Main Stacked Bar Chart (starts from very left edge of screen)
        Padding(
          padding: const EdgeInsets.only(
            left: 0,
            right: DesignConstants.spacingM,
          ),
          child: MacroHistoryStackedBarChart(
            dailyIntakes: displaySummary.dailyIntakes,
            range: displaySummary.range,
            is7Days: _activeBlock == TimeframeBlock.week,
            selectedDay: useMockData ? null : _selectedDay,
            onDaySelected: useMockData
                ? null
                : (day) => setState(() => _selectedDay = day),
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
            summary: displaySummary,
            proteinColor: proteinColor,
            fatColor: fatColor,
            carbsColor: carbsColor,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),

        // Daily Breakdown List
        _buildDailyBreakdown(
          context,
          summary: displaySummary,
          maxItems: useMockData ? 3 : null,
        ),
      ],
    );

    if (hasNoChartData) {
      bodyContent = ActiveGapOverlay(
        message: l10n.emptyStateActiveGapOverlay,
        background: Skeletonizer(
          enabled: true,
          child: IgnorePointer(child: bodyContent),
        ),
      );
    } else if (useMockData) {
      bodyContent = Skeletonizer(
        enabled: true,
        child: IgnorePointer(child: bodyContent),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.nutrition, bottom: timeframeFilter),
      body: Stack(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: false),
            child: CupertinoScrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 4,
              thicknessWhileDragging: 8,
              mainAxisMargin: 0,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  top: topPadding + DesignConstants.spacingS,
                  bottom: DesignConstants.bottomContentSpacer,
                ),
                child: bodyContent,
              ),
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
    required MacroPeriodSummary summary,
    required DailyMacroIntake? selected,
    required Color calColor,
    required Color proteinColor,
    required Color fatColor,
    required Color carbsColor,
  }) {
    final showAverage =
        summary.trackedDays > 0 || summary.incompleteDays == 0;

    // When a day is hovered/selected via press-and-hold, show its exact values.
    // Otherwise fall back to the period averages.
    final bool showDay = selected != null;

    final calText = showDay
        ? '${selected.calories}'
        : (showAverage ? '${summary.avgCalories}' : '--');
    final protText = showDay
        ? '${selected.proteinGrams.toStringAsFixed(0)} g'
        : (showAverage ? '${summary.avgProtein.toStringAsFixed(0)} g' : '--');
    final fatText = showDay
        ? '${selected.fatGrams.toStringAsFixed(0)} g'
        : (showAverage ? '${summary.avgFat.toStringAsFixed(0)} g' : '--');
    final carbsText = showDay
        ? '${selected.carbsGrams.toStringAsFixed(0)} g'
        : (showAverage ? '${summary.avgCarbs.toStringAsFixed(0)} g' : '--');

    final l10n = AppLocalizations.of(context)!;

    // Sub-label distinguishes "avg" mode from "selected day" mode
    final calLabel = showDay ? l10n.calories : 'Ø ${l10n.calories}';
    final protLabel = showDay ? l10n.protein : 'Ø ${l10n.protein}';
    final fatLabel = showDay ? l10n.fat : 'Ø ${l10n.fat}';
    final carbsLabel = showDay
        ? l10n.analyticsCarbsShort
        : 'Ø ${l10n.analyticsCarbsShort}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildMetricCard(
              context,
              label: calLabel,
              value: calText,
              unit: 'kcal',
              color: calColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMetricCard(
              context,
              label: protLabel,
              value: protText,
              color: proteinColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMetricCard(
              context,
              label: fatLabel,
              value: fatText,
              color: fatColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMetricCard(
              context,
              label: carbsLabel,
              value: carbsText,
              color: carbsColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMaxRangeLabel(BuildContext context, DateTimeRange range) {
    final locale = Localizations.localeOf(context).toString();
    final fmt = DateFormat.yMMM(locale);
    return '${fmt.format(range.start)} – ${fmt.format(range.end)}';
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String label,
    required String value,
    String? unit,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceBase = isDark
        ? DesignConstants.summaryCardSecondaryDarkMode
        : DesignConstants.summaryCardSecondaryLightMode;
    final valueStyle =
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ) ??
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceBase,
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Keep the value slot at a constant unscaled line height so
              // FittedBox.scaleDown on wider values (e.g. 4-digit calories)
              // never shrinks the card vertically while scrubbing.
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Text('0', maxLines: 1, style: valueStyle),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      style: valueStyle,
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 2),
                      Text(
                        unit,
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context, {
    required MacroPeriodSummary summary,
    required Color proteinColor,
    required Color fatColor,
    required Color carbsColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final hasTarget =
        summary.dailyIntakes.any((d) => (d.targetCalories ?? 0) > 0);
    final calColor =
        Theme.of(context).extension<MacroColors>()?.calories ?? Colors.orange;
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 16,
      runSpacing: 6,
      children: [
        _legendItem(context, l10n.protein, proteinColor),
        _legendItem(context, l10n.fat, fatColor),
        _legendItem(context, l10n.carbs, carbsColor),
        if (hasTarget)
          _legendDashedItem(
            context,
            l10n.analyticsCalorieTargetLine,
            calColor.withValues(alpha: 0.8),
          ),
      ],
    );
  }

  Widget _legendDashedItem(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 5, height: 2, color: color),
              Container(width: 5, height: 2, color: color),
            ],
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
    required MacroPeriodSummary summary,
    int? maxItems,
  }) {
    final theme = Theme.of(context);
    if (summary.dailyIntakes.isEmpty) {
      return const SizedBox.shrink();
    }

    var trackedDays = summary.dailyIntakes
        .where((d) => d.hasData)
        .toList()
        .reversed
        .toList();
    if (trackedDays.isEmpty) return const SizedBox.shrink();
    if (maxItems != null && trackedDays.length > maxItems) {
      trackedDays = trackedDays.sublist(0, maxItems);
    }

    final locale = Localizations.localeOf(context).toString();
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n.analyticsDailyBreakdown,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacingL,
          ),
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
            separatorBuilder: (_, _) =>
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
