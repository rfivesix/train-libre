import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../util/timeframe_label_formatter.dart';
import '../../../../widgets/common/global_app_bar.dart';
import '../../../../widgets/common/card_morph_route.dart';
import '../../../../widgets/common/time_range_filter.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../widgets/common/morph_source.dart';
import '../../../../widgets/common/app_section_header.dart';
import '../../../../widgets/common/platform_adaptive_pickers.dart'
    as adaptive_pickers;
import '../../../analytics/domain/models/chart_data_point.dart';
import '../../../profile/presentation/widgets/measurement_chart_widget.dart';
import '../../../../services/unit_service.dart';
import 'analytics_chart_defaults.dart';
import '../../../statistics/data/water_analytics_data_adapter.dart';
import '../../../statistics/domain/timeframe_block.dart';

class WaterSectionCard extends StatefulWidget {
  const WaterSectionCard({
    super.key,
    required this.block,
    required this.anchor,
    required this.isRolling,
    this.adapter = const WaterAnalyticsDataAdapter(),
  });

  final TimeframeBlock block;
  final DateTime anchor;
  final bool isRolling;
  final WaterAnalyticsDataAdapter adapter;

  @override
  State<WaterSectionCard> createState() => _WaterSectionCardState();
}

class _WaterSectionCardState extends State<WaterSectionCard> {
  late Future<WaterPeriodSummary> _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(WaterSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block != widget.block ||
        oldWidget.anchor != widget.anchor ||
        oldWidget.isRolling != widget.isRolling) {
      _load();
    }
  }

  void _load() {
    _summary = widget.adapter.fetchSummary(
      range: WaterAnalyticsDataAdapter.rangeFor(
        block: widget.block,
        anchor: widget.anchor,
        isRolling: widget.isRolling,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return FutureBuilder<WaterPeriodSummary>(
      future: _summary,
      builder: (context, snapshot) {
        final units = Provider.of<UnitService>(context);
        final data = snapshot.data;
        final average = data?.averageMilliliters ?? 0;
        final target = data?.targetMilliliters ?? 3000;
        final progress = target > 0 ? (average / target * 100).round() : 0;
        final hasData = data != null && data.trackedDays > 0;
        Widget buildCard({VoidCallback? onTap}) => SummaryCard(
              margin: EdgeInsets.zero,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(DesignConstants.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.water,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(LucideIcons.chevron_right, size: 18),
                      ],
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    if (snapshot.connectionState != ConnectionState.done)
                      const LinearProgressIndicator(minHeight: 2)
                    else if (!hasData)
                      Text(
                        l10n.statisticsWaterNoData,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      )
                    else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_displayWaterValue(average, units).toStringAsFixed(1)} ${_waterUnit(units)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: DesignConstants.spacingS),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              l10n.statisticsWaterDailyAverage,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignConstants.spacingXS),
                      Text(
                        l10n.statisticsWaterGoalProgress(progress),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: DesignConstants.spacingM),
                      _WaterSparkline(summary: data),
                    ],
                  ],
                ),
              ),
            );

        return MorphSourceScope(
          builder: (context, setHidden) => Builder(
            builder: (cardContext) => buildCard(
              onTap: data == null
                  ? null
                  : () => Navigator.of(context).push(
                        CardMorphRoute<void>(
                          sourceContext: cardContext,
                          sourceBuilder: (_) => buildCard(),
                          onSourceVisibilityChanged: setHidden,
                          builder: (_) => WaterStatisticsScreen(
                            summary: data,
                            initialBlock: widget.block,
                            initialAnchorDate: widget.anchor,
                            initialIsRolling: widget.isRolling,
                          ),
                        ),
                      ),
            ),
          ),
        );
      },
    );
  }
}

class _WaterSparkline extends StatelessWidget {
  const _WaterSparkline({required this.summary});

  final WaterPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final values = summary.dailyIntakes;
    final tracked = values.where((day) => day.isTracked).toList();
    if (tracked.isEmpty) return const SizedBox(height: 38);
    final minimum = tracked
        .map((day) => day.milliliters / 1000)
        .reduce((a, b) => a < b ? a : b);
    final maximum = tracked
        .map((day) => day.milliliters / 1000)
        .reduce((a, b) => a > b ? a : b);
    final spread = (maximum - minimum).clamp(0.0, double.infinity);
    final padding = spread == 0 ? 0.5 : spread * 0.18;
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 48,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (values.length - 1).clamp(1, 100000).toDouble(),
          minY: minimum - padding,
          maxY: maximum + padding,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            AnalyticsChartDefaults.straightLine(
              spots: [
                for (var index = 0; index < values.length; index++)
                  if (values[index].isTracked)
                    FlSpot(index.toDouble(), values[index].milliliters / 1000)
                  else
                    FlSpot.nullSpot,
              ],
              color: color,
              barWidth: 3.2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, bar) {
                  final index = bar.spots.indexOf(spot);
                  return index == 0 || index == bar.spots.length - 1;
                },
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).cardColor,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.22),
                    color.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaterStatisticsScreen extends StatefulWidget {
  const WaterStatisticsScreen(
      {super.key,
      required this.summary,
      required this.initialBlock,
      required this.initialAnchorDate,
      required this.initialIsRolling});

  final WaterPeriodSummary summary;
  final TimeframeBlock initialBlock;
  final DateTime initialAnchorDate;
  final bool initialIsRolling;

  @override
  State<WaterStatisticsScreen> createState() => _WaterStatisticsScreenState();
}

class _WaterStatisticsScreenState extends State<WaterStatisticsScreen> {
  static const _blocks = [
    TimeframeBlock.week,
    TimeframeBlock.month,
    TimeframeBlock.threeMonths,
    TimeframeBlock.sixMonths,
    TimeframeBlock.maxBlock,
  ];
  late TimeframeBlock _block;
  late DateTime _anchor;
  late bool _rolling;
  late Future<WaterPeriodSummary> _future;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _anchor = widget.initialAnchorDate;
    _block = _blocks.contains(widget.initialBlock)
        ? widget.initialBlock
        : TimeframeBlock.week;
    _rolling = widget.initialIsRolling;
    _load(
      initialRange: widget.initialBlock == _block ? widget.summary.range : null,
    );
  }

  void _load({DateTimeRange? initialRange}) {
    final range = initialRange ??
        (_rolling
            ? _block.getRollingBounds()
            : _block.getBounds(_anchor, DateTime(2020)));
    _future = const WaterAnalyticsDataAdapter().fetchSummary(range: range);
  }

  void _changeBlock(int index) {
    setState(() {
      _block = _blocks[index];
      _rolling = _block != TimeframeBlock.maxBlock;
      _anchor = DateTime.now();
      _load();
    });
  }

  void _shiftTimeframe(bool backwards) {
    setState(() {
      final now = DateTime.now();
      final currentBounds = _block.getBounds(now, DateTime(2020));
      final selectedBounds = _block.getBounds(_anchor, DateTime(2020));
      final isOngoing = !_rolling &&
          selectedBounds.start.isAtSameMomentAs(currentBounds.start);

      if (backwards) {
        if (isOngoing) {
          _rolling = true;
        } else if (_rolling) {
          _rolling = false;
          _anchor = _block.shift(now, -1);
        } else {
          _anchor = _block.shift(_anchor, -1);
        }
      } else if (_rolling) {
        _rolling = false;
        _anchor = now;
      } else {
        final previousAnchor = _block.shift(now, -1);
        final previousBounds = _block.getBounds(previousAnchor, DateTime(2020));
        if (selectedBounds.start.isAtSameMomentAs(previousBounds.start)) {
          _rolling = true;
        } else {
          _anchor = _block.shift(_anchor, 1);
        }
      }
      _load();
    });
  }

  bool get _nextEnabled {
    if (_block == TimeframeBlock.maxBlock || _rolling) return false;
    final now = DateTime.now();
    final currentBounds = _block.getBounds(now, DateTime(2020));
    final selectedBounds = _block.getBounds(_anchor, DateTime(2020));
    return !selectedBounds.start.isAtSameMomentAs(currentBounds.start);
  }

  Future<void> _pickDate() async {
    final picked = await adaptive_pickers.showAdaptiveTimeframePicker(
      context: context,
      activeBlock: _block,
      initialAnchor: _anchor,
      initialIsRolling: _rolling,
      earliestAvailableDay: DateTime(2020),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _anchor = picked.anchorDate;
      _rolling = picked.isRolling;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: GlobalAppBar(
          title: l10n.water,
          actions: [
            IconButton(
              tooltip: l10n.shareAsText,
              onPressed: _share,
              icon: Icon(DesignConstants.adaptiveShareIcon),
            ),
          ],
          bottom: TimeRangeFilter(
            ranges: [
              l10n.filter7DaysShort,
              l10n.filter1MonthShort,
              l10n.filter3MonthsShort,
              l10n.filter6MonthsShort,
              l10n.filterMax
            ],
            selectedIndex: _blocks.indexOf(_block),
            onSelected: _changeBlock,
            displayDate: _rolling
                ? TimeframeLabelFormatter.formatRolling(_block, l10n)
                : TimeframeLabelFormatter.format(_block, _anchor, l10n),
            onPrevious: _block == TimeframeBlock.maxBlock
                ? null
                : () => _shiftTimeframe(true),
            onNext: _nextEnabled ? () => _shiftTimeframe(false) : null,
            onTapDateDisplay:
                _block == TimeframeBlock.maxBlock ? null : _pickDate,
            nextEnabled: _nextEnabled,
            showDateNavigation: _block != TimeframeBlock.maxBlock,
          )),
      body: FutureBuilder<WaterPeriodSummary>(
        future: _future,
        builder: (context, snapshot) {
          final units = Provider.of<UnitService>(context);
          final summary = snapshot.data;
          if (summary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final dateFormat = DateFormat.yMMMMEEEEd(l10n.localeName);
          final trackedDays = summary.dailyIntakes
              .where((day) => day.isTracked)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          return CupertinoScrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 4,
            thicknessWhileDragging: 8,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.only(
                      top: DesignConstants.spacingS,
                      bottom: DesignConstants.spacingS,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MeasurementChartWidget.fromData(
                            dataPoints: [
                              for (final day in summary.dailyIntakes)
                                if (day.isTracked)
                                  ChartDataPoint(
                                    date: day.date,
                                    value: _displayWaterValue(
                                      day.milliliters,
                                      units,
                                    ),
                                  ),
                            ],
                            axisMode: MeasurementChartAxisMode.day,
                            domainDateRange: summary.range,
                            unit: _waterUnit(units),
                            edgeToEdge: true,
                            smoothWeightTrend: false,
                            referenceLineValue: _displayWaterValue(
                              summary.targetMilliliters,
                              units,
                            ),
                            idleValueLabel:
                                '${_displayWaterValue(summary.averageMilliliters, units).toStringAsFixed(1)} ${_waterUnit(units)}',
                            idleDateLabel: l10n.statisticsWaterDailyAverage,
                            selectedDateLabelBuilder: (date) =>
                                DateFormat.yMMMd(l10n.localeName).format(date),
                          ),
                          const SizedBox(height: DesignConstants.spacingXL),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal:
                                  DesignConstants.screenPaddingHorizontal,
                            ),
                            child: AppSectionHeader(
                              title: l10n.all_measurements,
                            ),
                          ),
                          const SizedBox(height: DesignConstants.spacingS),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      DesignConstants.screenPaddingHorizontal,
                      0,
                      DesignConstants.screenPaddingHorizontal,
                      DesignConstants.cardPadding.bottom,
                    ),
                    sliver: SliverList.builder(
                      itemCount: trackedDays.length,
                      itemBuilder: (context, index) {
                        final day = trackedDays[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: DesignConstants.spacingS,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  dateFormat.format(day.date),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(width: DesignConstants.spacingM),
                              Text(
                                '${_displayWaterValue(day.milliliters, units).toStringAsFixed(1)} ${_waterUnit(units)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _share() async {
    final summary = await _future;
    if (!mounted) return;
    final units = context.read<UnitService>();
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(l10n.localeName);
    final rangeLabel = _rolling
        ? TimeframeLabelFormatter.formatRolling(_block, l10n)
        : TimeframeLabelFormatter.format(_block, _anchor, l10n);
    final lines = <String>[
      l10n.water,
      rangeLabel,
      '${l10n.statisticsWaterDailyAverage}: ${_displayWaterValue(summary.averageMilliliters, units).toStringAsFixed(1)} ${_waterUnit(units)}',
      '${summary.trackedDays} ${l10n.statisticsMicronutrientsLoggedDays}',
      '',
      for (final day in summary.dailyIntakes.where((day) => day.isTracked))
        '${dateFormat.format(day.date)}: ${_displayWaterValue(day.milliliters, units).toStringAsFixed(1)} ${_waterUnit(units)}',
    ];
    await SharePlus.instance.share(
      ShareParams(text: lines.join('\n'), subject: l10n.water),
    );
  }
}

double _displayWaterValue(int milliliters, UnitService units) => units.isMetric
    ? milliliters / 1000
    : units.convertDisplayValue(milliliters.toDouble(), UnitDimension.liquid);

String _waterUnit(UnitService units) =>
    units.isMetric ? 'L' : units.suffixFor(UnitDimension.liquid);
