import 'dart:collection';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../services/haptic_feedback_service.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../analytics/presentation/widgets/analytics_chart_defaults.dart';
import '../../domain/analytics_state.dart';
import '../../domain/body_nutrition_analytics_models.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/weight_smoothing_util.dart';

class BodyNutritionNormalizedTrendChart extends StatefulWidget {
  const BodyNutritionNormalizedTrendChart({
    super.key,
    required this.range,
    required this.weightSeries,
    required this.calorieSeries,
    this.incompleteNutritionDays = const {},
    this.compact = false,
    this.edgeToEdge = false,
  });

  final DateTimeRange? range;
  final List<DailyValuePoint> weightSeries;
  final List<DailyValuePoint> calorieSeries;
  final Set<DateTime> incompleteNutritionDays;
  final bool compact;
  final bool edgeToEdge;

  @override
  State<BodyNutritionNormalizedTrendChart> createState() =>
      _BodyNutritionNormalizedTrendChartState();
}

class _BodyNutritionNormalizedTrendChartState
    extends State<BodyNutritionNormalizedTrendChart> {
  double? _activeX;

  @override
  void didUpdateWidget(BodyNutritionNormalizedTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) _activeX = null;
  }

  @override
  Widget build(BuildContext context) {
    final range = widget.range;
    final compact = widget.compact;

    final l10n = AppLocalizations.of(context)!;
    if (range == null ||
        (widget.weightSeries.isEmpty && widget.calorieSeries.isEmpty)) {
      return AnalyticsChartDefaults.stateView(
        context: context,
        l10n: l10n,
        status: AnalyticsStatus.insufficient,
        insufficientLabel: l10n.analyticsInsightNotEnoughData,
      );
    }

    final firstDay = DateTime.utc(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final spanDays = math.max(
      1,
      DateTime.utc(
            range.end.year,
            range.end.month,
            range.end.day,
          ).difference(firstDay).inDays +
          1,
    );
    final maxX = math.max(1, spanDays - 1).toDouble();

    bool isInRange(DailyValuePoint point) {
      final offset = _dayOffset(point.day, firstDay);
      return offset >= 0 && offset < spanDays;
    }

    final excludedDays = {
      for (final day in widget.incompleteNutritionDays)
        DateTime.utc(day.year, day.month, day.day),
    };
    final calorieSeries = widget.calorieSeries
        .where((point) {
          final day = point.day;
          return point.value.isFinite &&
              point.value > 0 &&
              isInRange(point) &&
              !excludedDays.contains(
                DateTime.utc(day.year, day.month, day.day),
              );
        })
        .toList(growable: false);

    final locale = Localizations.localeOf(context).toString();
    final unitService = Provider.of<UnitService>(context);

    // Convert weight series (stored in metric kg) into display units according
    // to the user's preference so scales, ticks and tooltips show the right
    // values (kg or lbs).
    final rawDisplayWeightSeries = widget.weightSeries
        .where(
          (point) =>
              point.value.isFinite && point.value > 0 && isInRange(point),
        )
        .map(
          (p) => DailyValuePoint(
            day: p.day,
            value: unitService.convertDisplayValue(
              p.value,
              UnitDimension.weight,
            ),
          ),
        )
        .toList(growable: false);

    // Always use EWMA smoothed weight trend curve (matching alpha = 0.35)
    // so fluctuations do not obscure true long-term weight correlation.
    final displayWeightSeries = WeightSmoothingUtil.calculateEwmaDailyPoints(
      rawDisplayWeightSeries,
    );

    final weightScale = _SeriesScale.fromSeries(
      displayWeightSeries,
      unit: unitService.suffixFor(UnitDimension.weight),
      fractionDigits: 1,
      minVariance: 2.0,
      locale: locale,
    );
    final calorieScale = _SeriesScale.fromSeries(
      calorieSeries,
      unit: 'kcal',
      fractionDigits: 0,
      minVariance: 200.0,
      locale: locale,
    );

    final weightPoints = _buildPoints(
      series: displayWeightSeries,
      firstDay: firstDay,
      scale: weightScale,
    );
    final caloriePoints = _buildPoints(
      series: calorieSeries,
      firstDay: firstDay,
      scale: calorieScale,
    );
    if (weightPoints.isEmpty && caloriePoints.isEmpty) {
      return AnalyticsChartDefaults.stateView(
        context: context,
        l10n: l10n,
        status: AnalyticsStatus.insufficient,
        insufficientLabel: l10n.analyticsInsightNotEnoughData,
      );
    }

    final series = [
      if (weightPoints.isNotEmpty)
        _ChartSeries(
          label: l10n.analyticsWeightTrendLabel(weightScale.unit),
          color: Theme.of(context).colorScheme.primary,
          scale: weightScale,
          points: weightPoints,
          kind: _SeriesKind.weight,
        ),
      if (caloriePoints.isNotEmpty)
        _ChartSeries(
          label: l10n.analyticsCaloriesTrendLabel,
          color: const Color(0xFFF97316),
          scale: calorieScale,
          points: caloriePoints,
          kind: _SeriesKind.calories,
        ),
    ];

    final xLabelPositions = _xLabelPositions(spanDays);

    final chartData = LineChartData(
      clipData: const FlClipData.all(),
      minX: 0,
      maxX: maxX,
      minY: -0.06,
      maxY: 1.06,
      baselineY: -0.06,
      gridData: compact
          ? AnalyticsChartDefaults.noGrid
          : FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 0.5,
            ),
      borderData: AnalyticsChartDefaults.noBorder,
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: false,
        touchSpotThreshold: 18,
        touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
          final x = event.isInterestedForInteractions
              ? response?.lineBarSpots?.firstOrNull?.x
              : null;
          if (x == _activeX) return;
          setState(() => _activeX = x);
          if (x != null && HapticFeedbackService.instance.isEnabled) {
            HapticFeedback.lightImpact();
          }
        },
      ),
      titlesData: compact
          ? AnalyticsChartDefaults.hiddenTitles
          : FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: !widget.edgeToEdge && weightPoints.isNotEmpty,
                  reservedSize: 52,
                  interval: 0.5,
                  getTitlesWidget: (value, meta) {
                    if (!_isPrimaryTick(value)) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: _axisTitle(context, value, weightScale),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: !widget.edgeToEdge && caloriePoints.isNotEmpty,
                  reservedSize: 56,
                  interval: 0.5,
                  getTitlesWidget: (value, meta) {
                    if (!_isPrimaryTick(value)) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: _axisTitle(
                        context,
                        value,
                        calorieScale,
                        alignRight: true,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final rounded = value.round();
                    if (!xLabelPositions.contains(rounded)) {
                      return const SizedBox.shrink();
                    }
                    final day = firstDay.add(Duration(days: rounded));
                    final isStartLabel = rounded == 0;
                    final isEndLabel = rounded == spanDays - 1;
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      fitInside: SideTitleFitInsideData.fromTitleMeta(
                        meta,
                        enabled: widget.edgeToEdge,
                        distanceFromEdge: 16.0,
                      ),
                      child: Text(
                        DateFormat('dd.MM').format(day),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        textAlign: isStartLabel
                            ? TextAlign.left
                            : isEndLabel
                            ? TextAlign.right
                            : TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
      lineBarsData: [for (final item in series) _buildLine(context, item)],
    );

    final chartWidget = LineChart(chartData);

    if (widget.edgeToEdge) {
      const double totalHeight = 250.0;
      const double minY = -0.06;
      const double maxY = 1.06;
      const double yRange = maxY - minY;
      const double leftInset = 16.0;
      const double rightInset = 16.0;

      double yToTop(double y) => (maxY - y) / yRange * (totalHeight - 42.0);

      const ticks = [1.0, 0.5, 0.0];
      final activeX = _activeX;

      return SizedBox(
        width: double.infinity,
        height: totalHeight,
        child: OverflowBox(
          maxWidth: MediaQuery.of(context).size.width,
          minWidth: MediaQuery.of(context).size.width,
          maxHeight: totalHeight,
          minHeight: totalHeight,
          child: Stack(
            children: [
              chartWidget,
              // Left Y-axis labels drawn on top
              for (final tick in ticks)
                if (weightPoints.isNotEmpty)
                  Positioned(
                    top: yToTop(tick) - 8,
                    left: leftInset,
                    child: _axisTitle(context, tick, weightScale),
                  ),
              // Right Y-axis labels drawn on top
              for (final tick in ticks)
                if (caloriePoints.isNotEmpty)
                  Positioned(
                    top: yToTop(tick) - 8,
                    right: rightInset,
                    child: _axisTitle(
                      context,
                      tick,
                      calorieScale,
                      alignRight: true,
                    ),
                  ),
              if (activeX != null)
                _buildTooltipOverlay(
                  context: context,
                  series: series,
                  activeX: activeX,
                  chartWidth: MediaQuery.of(context).size.width,
                  totalHeight: totalHeight,
                  plotHeight: totalHeight - 42.0,
                  maxX: maxX,
                ),
            ],
          ),
        ),
      );
    }

    return chartWidget;
  }

  List<_ChartPoint> _buildPoints({
    required List<DailyValuePoint> series,
    required DateTime firstDay,
    required _SeriesScale scale,
  }) {
    final groupedByX = <int, ({double sum, int count})>{};
    for (final point in series) {
      final x = _dayOffset(point.day, firstDay);
      final previous = groupedByX[x];
      groupedByX[x] = (
        sum: (previous?.sum ?? 0.0) + point.value,
        count: (previous?.count ?? 0) + 1,
      );
    }

    final orderedX = groupedByX.keys.toList()..sort();
    return orderedX
        .map((x) {
          final group = groupedByX[x]!;
          final value = group.sum / group.count;
          return _ChartPoint(
            day: firstDay.add(Duration(days: x)),
            rawValue: value,
            spot: FlSpot(x.toDouble(), scale.toPlotValue(value)),
          );
        })
        .toList(growable: false);
  }

  LineChartBarData _buildLine(BuildContext context, _ChartSeries series) {
    final compact = widget.compact;
    final isWeight = series.kind == _SeriesKind.weight;
    final strokeColor = Theme.of(context).scaffoldBackgroundColor;
    final spots = [for (final point in series.points) point.spot];
    final indicators = [
      for (final (index, spot) in spots.indexed)
        if (spot.x == _activeX) index,
    ];

    return AnalyticsChartDefaults.straightLine(
      spots: spots,
      barWidth: compact ? 3.2 : 4.0,
      isStrokeCapRound: true,
      color: series.color,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            series.color.withValues(alpha: isWeight ? 0.22 : 0.08),
            series.color.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      dotData: FlDotData(
        show: true,
        checkToShowDot: (spot, _) => spot == spots.first || spot == spots.last,
        getDotPainter: (_, _, _, _) => switch (series.kind) {
          _SeriesKind.weight => FlDotCirclePainter(
            radius: compact ? 3.0 : 4.5,
            color: series.color,
            strokeWidth: 2,
            strokeColor: strokeColor,
          ),
          _SeriesKind.calories => FlDotSquarePainter(
            size: compact ? 6.0 : 8.0,
            color: series.color,
            strokeWidth: 2,
            strokeColor: strokeColor,
          ),
        },
      ),
    ).copyWith(showingIndicators: indicators);
  }

  int _dayOffset(DateTime day, DateTime firstDay) =>
      DateTime.utc(day.year, day.month, day.day).difference(firstDay).inDays;

  Set<int> _xLabelPositions(int spanDays) {
    if (spanDays <= 1) return {0};
    final interval = (spanDays / 4).ceil().clamp(1, 10000);
    final positions = <int>{0, spanDays - 1};
    for (var i = interval; i < spanDays - 1; i += interval) {
      positions.add(i);
    }
    return positions;
  }

  bool _isPrimaryTick(double value) {
    return (value - 0).abs() < 0.0001 ||
        (value - 0.5).abs() < 0.0001 ||
        (value - 1).abs() < 0.0001;
  }

  Widget _axisTitle(
    BuildContext context,
    double normalizedValue,
    _SeriesScale scale, {
    bool alignRight = false,
  }) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    // Build a hard (blurRadius: 0) multi-directional shadow that follows the
    // text shape instead of producing a rectangular block.
    final hardShadows = [
      for (final dx in <double>[-2, -1, 0, 1, 2])
        for (final dy in <double>[-2, -1, 0, 1, 2])
          if (dx != 0 || dy != 0)
            Shadow(color: bgColor, offset: Offset(dx, dy), blurRadius: 0),
    ];
    return Text(
      scale.formatTick(normalizedValue),
      maxLines: 1,
      softWrap: false,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        shadows: hardShadows,
      ),
    );
  }

  Widget _buildTooltipOverlay({
    required BuildContext context,
    required List<_ChartSeries> series,
    required double activeX,
    required double chartWidth,
    required double totalHeight,
    required double plotHeight,
    required double maxX,
  }) {
    final rows = <(_ChartSeries, _ChartPoint)>[];
    for (final item in series) {
      final point = item.points.where((p) => p.spot.x == activeX).firstOrNull;
      if (point != null) rows.add((item, point));
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    final point = rows.first.$2;
    final tooltipWidth = math.min(192.0, chartWidth - 24.0);
    final tooltipHeight = 74.0 + (rows.length - 1) * 20.0;
    final xCenter = (activeX / maxX) * chartWidth;
    final left = (xCenter - tooltipWidth / 2).clamp(
      12.0,
      chartWidth - tooltipWidth - 12.0,
    );
    final top = ((1 - point.spot.y) * plotHeight - tooltipHeight - 12.0).clamp(
      8.0,
      totalHeight - tooltipHeight - 48.0,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseStyle = Theme.of(context).textTheme.bodySmall!;
    final locale = Localizations.localeOf(context).toString();
    final dateText = DateFormat.MMMd(locale).format(point.day);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: tooltipWidth,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? DesignConstants.summaryCardDarkMode
                  : DesignConstants.summaryCardSecondaryLightMode,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: baseStyle.copyWith(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                for (final (item, point) in rows)
                  Text(
                    '${item.label}: ${item.scale.formatRaw(point.rawValue)}',
                    style: baseStyle.copyWith(
                      color: item.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPoint {
  const _ChartPoint({
    required this.day,
    required this.rawValue,
    required this.spot,
  });

  final DateTime day;
  final double rawValue;
  final FlSpot spot;
}

class _ChartSeries {
  const _ChartSeries({
    required this.label,
    required this.color,
    required this.scale,
    required this.points,
    required this.kind,
  });

  final String label;
  final Color color;
  final _SeriesScale scale;
  final List<_ChartPoint> points;
  final _SeriesKind kind;
}

enum _SeriesKind { weight, calories }

class _SeriesScale {
  const _SeriesScale({
    required this.min,
    required this.max,
    required this.unit,
    required this.fractionDigits,
    this.locale,
  });

  factory _SeriesScale.fromSeries(
    List<DailyValuePoint> series, {
    required String unit,
    required int fractionDigits,
    double minVariance = 0.0,
    String? locale,
  }) {
    bool hasData = false;
    double min = double.infinity;
    double max = double.negativeInfinity;

    for (final point in series) {
      final value = point.value;
      if (value.isFinite) {
        hasData = true;
        if (value < min) min = value;
        if (value > max) max = value;
      }
    }

    if (!hasData) {
      return _SeriesScale(
        min: 0,
        max: 1,
        unit: unit,
        fractionDigits: fractionDigits,
        locale: locale,
      );
    }
    final span = max - min;
    if (span < minVariance) {
      final mid = (min + max) / 2;
      min = mid - (minVariance / 2);
      max = mid + (minVariance / 2);
    }

    return _SeriesScale(
      min: min,
      max: max,
      unit: unit,
      fractionDigits: fractionDigits,
      locale: locale,
    );
  }

  final double min;
  final double max;
  final String unit;
  final int fractionDigits;
  final String? locale;

  double toPlotValue(double rawValue) {
    final span = max - min;
    if (!span.isFinite || span.abs() < 0.0001) {
      return 0.5;
    }
    return ((rawValue - min) / span).clamp(0.0, 1.0);
  }

  double fromPlotValue(double normalizedValue) {
    final span = max - min;
    if (!span.isFinite || span.abs() < 0.0001) {
      return max;
    }
    return min + (span * normalizedValue);
  }

  String formatTick(double normalizedValue) {
    return '${_formatNumber(fromPlotValue(normalizedValue), fractionDigits, locale)} $unit';
  }

  String formatRaw(double rawValue) {
    return '${_formatNumber(rawValue, fractionDigits, locale)} $unit';
  }
}

String _formatNumber(double value, int fractionDigits, String? locale) {
  final normalized = value.abs() < 0.0001 ? 0.0 : value;
  if (fractionDigits <= 0) {
    return NumberFormat.decimalPattern(locale).format(normalized.round());
  }

  return NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: fractionDigits,
  ).format(normalized);
}
