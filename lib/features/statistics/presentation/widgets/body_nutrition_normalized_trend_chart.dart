import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../services/haptic_feedback_service.dart';

import '../../../../generated/app_localizations.dart';
import '../../../analytics/presentation/widgets/analytics_chart_defaults.dart';
import '../../domain/analytics_state.dart';
import '../../domain/body_nutrition_analytics_models.dart';
import '../../../../services/unit_service.dart';

class BodyNutritionNormalizedTrendChart extends StatefulWidget {
  const BodyNutritionNormalizedTrendChart({
    super.key,
    required this.range,
    required this.weightSeries,
    required this.calorieSeries,
    this.compact = false,
    this.edgeToEdge = false,
  });

  final DateTimeRange? range;
  final List<DailyValuePoint> weightSeries;
  final List<DailyValuePoint> calorieSeries;
  final bool compact;
  final bool edgeToEdge;

  @override
  State<BodyNutritionNormalizedTrendChart> createState() =>
      _BodyNutritionNormalizedTrendChartState();
}

class _BodyNutritionNormalizedTrendChartState
    extends State<BodyNutritionNormalizedTrendChart> {
  int? _lastVibratedIndex;
  List<LineBarSpot>? _activeTooltipSpots;

  @override
  Widget build(BuildContext context) {
    final range = widget.range;
    final weightSeries = widget.weightSeries;
    final calorieSeries = widget.calorieSeries;
    final compact = widget.compact;

    final l10n = AppLocalizations.of(context)!;
    if (weightSeries.isEmpty || calorieSeries.isEmpty || range == null) {
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
      DateTime.utc(range.end.year, range.end.month, range.end.day)
              .difference(firstDay)
              .inDays +
          1,
    );
    final maxXInt = math.max(0, spanDays - 1);
    final maxX = math.max(1, maxXInt).toDouble();

    final unitService = Provider.of<UnitService>(context);

    // Convert weight series (stored in metric kg) into display units according
    // to the user's preference so scales, ticks and tooltips show the right
    // values (kg or lbs).
    final displayWeightSeries = weightSeries
        .map((p) => DailyValuePoint(
              day: p.day,
              value: unitService.convertDisplayValue(
                p.value,
                UnitDimension.weight,
              ),
            ))
        .toList(growable: false);

    final weightScale = _SeriesScale.fromSeries(
      displayWeightSeries,
      unit: unitService.suffixFor(UnitDimension.weight),
      fractionDigits: 1,
      minVariance: 2.0,
    );
    final calorieScale = _SeriesScale.fromSeries(
      calorieSeries,
      unit: 'kcal',
      fractionDigits: 0,
      minVariance: 200.0,
    );

    final weightPoints = _buildPoints(
      series: displayWeightSeries,
      firstDay: firstDay,
      maxX: maxX,
      scale: weightScale,
      aggregationMethod: AggregationMethod.average,
    );
    final caloriePoints = _buildPoints(
      series: calorieSeries,
      firstDay: firstDay,
      maxX: maxX,
      scale: calorieScale,
      aggregationMethod: AggregationMethod.average,
    );
    // Debug: when used as compact (hub), print range and last raw-series dates
    assert(() {
      if (compact) {
        try {
          final lastWeight =
              weightSeries.isNotEmpty ? weightSeries.last.day : null;
          final lastCal =
              calorieSeries.isNotEmpty ? calorieSeries.last.day : null;
          debugPrint(
              '[chart-debug] compact range=${range.start}..${range.end} spanDays=$spanDays');
          debugPrint(
              '[chart-debug] weightSeries count=${weightSeries.length} last=$lastWeight');
          debugPrint(
              '[chart-debug] calorieSeries count=${calorieSeries.length} last=$lastCal');
        } catch (e, st) {
          debugPrint('[chart-debug] error reading series: $e\n$st');
        }
      }
      return true;
    }());
    if (weightPoints.isEmpty || caloriePoints.isEmpty) {
      return AnalyticsChartDefaults.stateView(
        context: context,
        l10n: l10n,
        status: AnalyticsStatus.insufficient,
        insufficientLabel: l10n.analyticsInsightNotEnoughData,
      );
    }

    final series = [
      _ChartSeries(
        label: l10n.analyticsWeightTrendLabel(
            context.read<UnitService>().suffixFor(UnitDimension.weight)),
        color: Theme.of(context).colorScheme.primary,
        scale: weightScale,
        points: weightPoints,
        dotShape: _SeriesDotShape.circle,
      ),
      _ChartSeries(
        label: l10n.analyticsCaloriesTrendLabel,
        color: const Color(0xFFF97316),
        scale: calorieScale,
        points: caloriePoints,
        dotShape: _SeriesDotShape.square,
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
        handleBuiltInTouches: true,
        touchSpotThreshold: 18,
        touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
          if (event is FlPanEndEvent || event is FlTapUpEvent) {
            _lastVibratedIndex = null;
            if (_activeTooltipSpots != null) {
              setState(() {
                _activeTooltipSpots = null;
              });
            }
            return;
          }
          final spots = response?.lineBarSpots;
          if (spots != null && spots.isNotEmpty) {
            final idx = spots.first.spotIndex;
            if (idx != _lastVibratedIndex) {
              _lastVibratedIndex = idx;
              if (HapticFeedbackService.instance.isEnabled) {
                HapticFeedback.lightImpact();
              }
            }
            if (_activeTooltipSpots != spots) {
              setState(() {
                _activeTooltipSpots = spots;
              });
            }
          }
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) => List<LineTooltipItem?>.filled(
            touchedSpots.length,
            null,
            growable: false,
          ),
        ),
      ),
      titlesData: compact
          ? AnalyticsChartDefaults.hiddenTitles
          : FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: !widget.edgeToEdge,
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
                  showTitles: !widget.edgeToEdge,
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
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
      lineBarsData: series
          .map(
            (seriesConfig) => AnalyticsChartDefaults.straightLine(
              spots: seriesConfig.points
                  .map((point) => point.spot)
                  .toList(growable: false),
              barWidth: compact ? 3.2 : 4.0,
              isStrokeCapRound: true,
              color: seriesConfig.color,
              belowBarData: seriesConfig.label ==
                      l10n.analyticsWeightTrendLabel(context
                          .read<UnitService>()
                          .suffixFor(UnitDimension.weight))
                  ? BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          seriesConfig.color.withValues(alpha: 0.22),
                          seriesConfig.color.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    )
                  : BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          seriesConfig.color.withValues(alpha: 0.08),
                          seriesConfig.color.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, bar) {
                  if (seriesConfig.points.length <= 2) {
                    return true;
                  }
                  final index = bar.spots.indexOf(spot);
                  return index == 0 || index == bar.spots.length - 1;
                },
                getDotPainter: (spot, percent, bar, index) {
                  final strokeColor = Theme.of(context).scaffoldBackgroundColor;
                  return switch (seriesConfig.dotShape) {
                    _SeriesDotShape.circle => FlDotCirclePainter(
                        radius: compact ? 3.0 : 4.5,
                        color: seriesConfig.color,
                        strokeWidth: 2,
                        strokeColor: strokeColor,
                      ),
                    _SeriesDotShape.square => FlDotSquarePainter(
                        size: compact ? 6.0 : 8.0,
                        color: seriesConfig.color,
                        strokeWidth: 2,
                        strokeColor: strokeColor,
                      ),
                  };
                },
              ),
            ),
          )
          .toList(growable: false),
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

      // Ticks to label
      final leftTicks = [1.0, 0.5, 0.0];
      final rightTicks = [1.0, 0.5, 0.0];

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
              for (final tick in leftTicks)
                Positioned(
                  top: yToTop(tick) - 8,
                  left: leftInset,
                  child: _axisTitle(context, tick, weightScale),
                ),
              // Right Y-axis labels drawn on top
              for (final tick in rightTicks)
                Positioned(
                  top: yToTop(tick) - 8,
                  right: rightInset,
                  child:
                      _axisTitle(context, tick, calorieScale, alignRight: true),
                ),
              if (_activeTooltipSpots != null &&
                  _activeTooltipSpots!.isNotEmpty)
                _buildTooltipOverlay(
                  context: context,
                  series: series,
                  touchedSpots: _activeTooltipSpots!,
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
    required double maxX,
    required _SeriesScale scale,
    AggregationMethod aggregationMethod = AggregationMethod.average,
  }) {
    final Map<int, List<DailyValuePoint>> groupedByX = {};
    final maxXInt = maxX.round();
    for (final point in series) {
      final xIndex = _xOf(point.day, firstDay).round();
      final y = point.value;
      if (!y.isFinite || xIndex < 0 || xIndex > maxXInt) continue;
      groupedByX.putIfAbsent(xIndex, () => []).add(point);
    }

    final deduplicatedByX = <int, _ChartPoint>{};
    groupedByX.forEach((xIndex, points) {
      final day = points.first.day;
      final sum = points.map((p) => p.value).reduce((a, b) => a + b);
      final accumulatedValue = (aggregationMethod == AggregationMethod.sum)
          ? sum
          : sum / points.length;

      deduplicatedByX[xIndex] = _ChartPoint(
        day: day,
        rawValue: accumulatedValue,
        spot: FlSpot(xIndex.toDouble(), scale.toPlotValue(accumulatedValue)),
      );
    });

    final orderedPoints = deduplicatedByX.values.toList(growable: true)
      ..sort((a, b) => a.spot.x.compareTo(b.spot.x));
    if (orderedPoints.isEmpty) {
      return const [];
    }
    final firstPoint = orderedPoints.first;
    final lastPoint = orderedPoints.last;
    if (firstPoint.spot.x > 0) {
      orderedPoints.insert(
        0,
        _ChartPoint(
          day: firstPoint.day,
          rawValue: firstPoint.rawValue,
          spot: FlSpot(0, firstPoint.spot.y),
        ),
      );
    }
    if (lastPoint.spot.x < maxXInt) {
      orderedPoints.add(
        _ChartPoint(
          day: lastPoint.day,
          rawValue: lastPoint.rawValue,
          spot: FlSpot(maxXInt.toDouble(), lastPoint.spot.y),
        ),
      );
    }

    return orderedPoints;
  }

  double _xOf(DateTime day, DateTime firstDay) {
    final d1 = DateTime.utc(day.year, day.month, day.day);
    final d2 = DateTime.utc(firstDay.year, firstDay.month, firstDay.day);
    return d1.difference(d2).inDays.toDouble();
  }

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
    required List<LineBarSpot> touchedSpots,
    required double chartWidth,
    required double totalHeight,
    required double plotHeight,
    required double maxX,
  }) {
    final firstSpot = touchedSpots.first;
    final seriesIndex = firstSpot.barIndex;
    if (seriesIndex < 0 || seriesIndex >= series.length) {
      return const SizedBox.shrink();
    }

    final selectedSeries = series[seriesIndex];
    final pointIndex = firstSpot.spotIndex;
    if (pointIndex < 0 || pointIndex >= selectedSeries.points.length) {
      return const SizedBox.shrink();
    }

    final point = selectedSeries.points[pointIndex];
    final tooltipWidth = 192.0;
    final tooltipHeight = 74.0 + (touchedSpots.length - 1) * 20.0;
    final xCenter = (firstSpot.x / maxX) * chartWidth;
    final left = (xCenter - tooltipWidth / 2)
        .clamp(12.0, chartWidth - tooltipWidth - 12.0);
    final top = ((1 - point.spot.y) * plotHeight - tooltipHeight - 12.0)
        .clamp(8.0, totalHeight - tooltipHeight - 48.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseStyle = Theme.of(context).textTheme.bodySmall!;
    final dateText = DateFormat.MMMd().format(point.day);

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
                  ? const Color(0xFF2A2A2A)
                  : Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                for (final spot in touchedSpots)
                  _buildTooltipRow(context, series, spot),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTooltipRow(
    BuildContext context,
    List<_ChartSeries> series,
    LineBarSpot touchedSpot,
  ) {
    final seriesIndex = touchedSpot.barIndex;
    if (seriesIndex < 0 || seriesIndex >= series.length) {
      return const SizedBox.shrink();
    }

    final selectedSeries = series[seriesIndex];
    final pointIndex = touchedSpot.spotIndex;
    if (pointIndex < 0 || pointIndex >= selectedSeries.points.length) {
      return const SizedBox.shrink();
    }

    final point = selectedSeries.points[pointIndex];
    return Text(
      '${selectedSeries.label}: ${selectedSeries.scale.formatRaw(point.rawValue)}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: selectedSeries.color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
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
    required this.dotShape,
  });

  final String label;
  final Color color;
  final _SeriesScale scale;
  final List<_ChartPoint> points;
  final _SeriesDotShape dotShape;
}

enum _SeriesDotShape { circle, square }

class _SeriesScale {
  const _SeriesScale({
    required this.min,
    required this.max,
    required this.unit,
    required this.fractionDigits,
  });

  factory _SeriesScale.fromSeries(
    List<DailyValuePoint> series, {
    required String unit,
    required int fractionDigits,
    double minVariance = 0.0,
  }) {
    final finiteValues = series
        .map((point) => point.value)
        .where((value) => value.isFinite)
        .toList(growable: false);
    if (finiteValues.isEmpty) {
      return _SeriesScale(
        min: 0,
        max: 1,
        unit: unit,
        fractionDigits: fractionDigits,
      );
    }

    double min = finiteValues.reduce(math.min);
    double max = finiteValues.reduce(math.max);
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
    );
  }

  final double min;
  final double max;
  final String unit;
  final int fractionDigits;

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
    return '${_formatNumber(fromPlotValue(normalizedValue), fractionDigits)} $unit';
  }

  String formatRaw(double rawValue) {
    return '${_formatNumber(rawValue, fractionDigits)} $unit';
  }
}

String _formatNumber(double value, int fractionDigits) {
  final normalized = value.abs() < 0.0001 ? 0.0 : value;
  if (fractionDigits <= 0) {
    return NumberFormat.decimalPattern().format(normalized.round());
  }

  final fixed = normalized.toStringAsFixed(fractionDigits);
  final parts = fixed.split('.');
  final whole = NumberFormat.decimalPattern().format(int.parse(parts[0]));
  return parts.length == 1 ? whole : '$whole.${parts[1]}';
}

enum AggregationMethod { average, sum }
