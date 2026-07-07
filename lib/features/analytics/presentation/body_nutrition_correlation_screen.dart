import '../../statistics/domain/timeframe_block.dart';
import 'package:flutter/material.dart';

import '../../statistics/presentation/widgets/body_nutrition_normalized_trend_chart.dart';
import '../../statistics/domain/statistics_range_policy.dart';
import '../../statistics/presentation/statistics_formatter.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/body_nutrition_analytics_utils.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/common.dart';
import 'package:provider/provider.dart';
import '../../../services/unit_service.dart';
import '../../../util/timeframe_label_formatter.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart' as adaptive_pickers;

class BodyNutritionCorrelationScreen extends StatefulWidget {
  final int initialRangeIndex;

  const BodyNutritionCorrelationScreen({super.key, this.initialRangeIndex = 1});

  @override
  State<BodyNutritionCorrelationScreen> createState() =>
      _BodyNutritionCorrelationScreenState();
}

class _BodyNutritionCorrelationScreenState
    extends State<BodyNutritionCorrelationScreen> {
  final _rangePolicy = StatisticsRangePolicyService.instance;
  bool _isLoading = true;
  
  TimeframeBlock _activeBlock = TimeframeBlock.month;
  DateTime _anchorDate = DateTime.now();

  final List<TimeframeBlock> _validBlocks = const [
    TimeframeBlock.week,
    TimeframeBlock.month,
    TimeframeBlock.threeMonths,
    TimeframeBlock.sixMonths,
    TimeframeBlock.maxBlock,
  ];

  BodyNutritionAnalyticsResult? _analytics;
  bool _loadFailed = false;
  int _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    final index = widget.initialRangeIndex.clamp(0, 4);
    _activeBlock = _validBlocks[index];
    _load();
  }

  Future<void> _load() async {
    final loadEpoch = ++_loadEpoch;
    setState(() => _isLoading = true);
    try {
      final analytics = await BodyNutritionAnalyticsUtils.build(
        selectedBlockType: _activeBlock,
        anchorDate: _anchorDate,
      );
      if (!mounted || loadEpoch != _loadEpoch) return;
      setState(() {
        _analytics = analytics;
        _loadFailed = false;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || loadEpoch != _loadEpoch) return;
      setState(() {
        _analytics = null;
        _loadFailed = true;
        _isLoading = false;
      });
    }
  }

  List<String> _ranges(AppLocalizations l10n) => [
        l10n.filter7DaysShort,
        l10n.filter1MonthShort,
        l10n.filter3MonthsShort,
        l10n.filter6MonthsShort,
        l10n.filterMax,
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.bodyNutritionCorrelationTitle),
      body: _isLoading && _analytics == null
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? _buildUnavailableState(l10n)
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: DesignConstants.screenPadding.top + topPadding,
                        bottom: DesignConstants.bottomContentSpacer,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TimeRangeFilter(
                            ranges: _ranges(l10n),
                            selectedIndex: _validBlocks.indexOf(_activeBlock),
                            onSelected: (index) {
                              setState(() {
                                _activeBlock = _validBlocks[index];
                              });
                              _load();
                            },
                            onPrevious: _activeBlock == TimeframeBlock.maxBlock ? null : () {
                              setState(() {
                                _anchorDate = _activeBlock.shift(_anchorDate, -1);
                              });
                              _load();
                            },
                            onNext: _activeBlock == TimeframeBlock.maxBlock ? null : () {
                              setState(() {
                                _anchorDate = _activeBlock.shift(_anchorDate, 1);
                              });
                              _load();
                            },
                            displayDate: TimeframeLabelFormatter.format(_activeBlock, _anchorDate, l10n),
                            onTapDateDisplay: () async {
                              final selected = await adaptive_pickers.showAdaptiveTimeframePicker(
                                context: context,
                                activeBlock: _activeBlock,
                                initialAnchor: _anchorDate,
                                earliestAvailableDay: DateTime(2020),
                              );
                              if (selected != null) {
                                setState(() {
                                  _anchorDate = selected;
                                });
                                _load();
                              }
                            },
                            nextEnabled: _activeBlock != TimeframeBlock.maxBlock && _anchorDate.isBefore(DateTime.now()),
                          ),
                          const SizedBox(height: DesignConstants.spacingM),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignConstants.screenPaddingHorizontal,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSummaryCard(l10n, _analytics!),
                                const SizedBox(height: DesignConstants.spacingM),
                                AppSectionHeader(
                                  title: l10n.analyticsBodyNutritionTrendContext,
                                ),
                                _buildTrendComparisonCard(l10n, _analytics!),
                                const SizedBox(height: DesignConstants.spacingM),
                                AppSectionHeader(
                                  title: l10n.analyticsInterpretationTitle,
                                ),
                                _buildInterpretationCard(l10n, _analytics!),
                              ],
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

  Widget _buildUnavailableState(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: DesignConstants.screenPadding,
        child: SummaryCard(
          child: Padding(
            padding: const EdgeInsets.all(DesignConstants.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loadFailed ? l10n.error : l10n.analyticsInsightNotEnoughData,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: DesignConstants.spacingS),
                Text(
                  _loadFailed
                      ? l10n.aiErrorNetwork
                      : l10n.analyticsInsightNotEnoughData,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Removed _buildRangeChips

  Widget _buildSummaryCard(
    AppLocalizations l10n,
    BodyNutritionAnalyticsResult data,
  ) {
    final unitService = Provider.of<UnitService>(context);
    final currentWeight = data.currentWeightKg == null
        ? '-'
        : '${unitService.convertDisplayValue(data.currentWeightKg!, UnitDimension.weight).toStringAsFixed(1)} ${unitService.suffixFor(UnitDimension.weight)}';
    final weightChange = data.weightChangeKg == null
        ? '-'
        : '${data.weightChangeKg! >= 0 ? '+' : '-'}${unitService.convertDisplayValue(data.weightChangeKg!.abs(), UnitDimension.weight).toStringAsFixed(1)} ${unitService.suffixFor(UnitDimension.weight)}';
    final avgCalories = data.loggedCalorieDays <= 0
        ? '-'
        : '${data.avgDailyCalories.round()} ${l10n.analyticsKcalPerDay}';

    final confidenceLabel =
        StatisticsPresentationFormatter.bodyNutritionConfidenceLabel(
            l10n, data.confidence);

    final relationship =
        StatisticsPresentationFormatter.bodyNutritionRelationshipLabel(
      l10n,
      data.relationship,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n.sectionBodyNutrition,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 430 ? 2 : 4;
            return GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: DesignConstants.spacingS,
              mainAxisSpacing: DesignConstants.spacingS,
              childAspectRatio: crossAxisCount == 2 ? 2.45 : 2.65,
              children: [
                ValueSummaryCard(
                    label: l10n.metricsCurrentWeight, value: currentWeight),
                ValueSummaryCard(
                    label: l10n.metricsWeightChange, value: weightChange),
                ValueSummaryCard(
                    label: l10n.metricsAvgCalories, value: avgCalories),
                ValueSummaryCard(
                  label: l10n.analyticsWeightTrendLabel,
                  value: StatisticsPresentationFormatter
                      .bodyNutritionTrendDirectionLabel(
                          l10n, data.weightTrend.direction),
                ),
                ValueSummaryCard(
                  label: l10n.analyticsCaloriesTrendLabel,
                  value: StatisticsPresentationFormatter
                      .bodyNutritionTrendDirectionLabel(
                          l10n, data.calorieTrend.direction),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: DesignConstants.spacingM),
        AppInfoRow(
          padding: EdgeInsets.zero,
          title: relationship,
          subtitle:
              '${l10n.analyticsEffectiveRangeLabel}: ${_effectiveRangeDisclosure()}\n$confidenceLabel • ${l10n.analyticsBasedOnDataCoverage(data.weightDays, data.loggedCalorieDays)}',
        ),
      ],
    );
  }

  Widget _buildTrendComparisonCard(
    AppLocalizations l10n,
    BodyNutritionAnalyticsResult data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.analyticsBodyNutritionNormalizedHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _legendDot(
              color: Theme.of(context).colorScheme.primary,
              label: l10n.analyticsWeightTrendLabel,
              shape: BoxShape.circle,
            ),
            _legendDot(
              color: const Color(0xFFF97316),
              label: l10n.analyticsCaloriesTrendLabel,
              shape: BoxShape.rectangle,
            ),
          ],
        ),
        const SizedBox(height: 10),
        RepaintBoundary(
          child: SizedBox(
            height: 250,
            child: BodyNutritionNormalizedTrendChart(
              range: data.range,
              weightSeries: data.weightDaily,
              calorieSeries: data.caloriesDaily
                  .where((point) => point.value > 0)
                  .toList(growable: false),
              edgeToEdge: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendDot({
    required Color color,
    required String label,
    required BoxShape shape,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: shape,
            borderRadius:
                shape == BoxShape.rectangle ? BorderRadius.circular(2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildInterpretationCard(
    AppLocalizations l10n,
    BodyNutritionAnalyticsResult data,
  ) {
    final relationship =
        StatisticsPresentationFormatter.bodyNutritionRelationshipLabel(
      l10n,
      data.relationship,
    );
    final confidence =
        StatisticsPresentationFormatter.bodyNutritionConfidenceLabel(
      l10n,
      data.confidence,
    );
    final hint = _confidenceHint(l10n, data.confidence);
    final disclaimer = l10n.analyticsCorrelationDisclaimer;

    return AppInfoRow(
      padding: EdgeInsets.zero,
      title: relationship,
      subtitle: '$confidence\n$hint\n\n$disclaimer',
    );
  }

  String _confidenceHint(
    AppLocalizations l10n,
    BodyNutritionConfidence confidence,
  ) {
    return switch (confidence) {
      BodyNutritionConfidence.high =>
        l10n.analyticsBodyNutritionConfidenceHighHint,
      BodyNutritionConfidence.moderate =>
        l10n.analyticsBodyNutritionConfidenceModerateHint,
      BodyNutritionConfidence.low =>
        l10n.analyticsBodyNutritionConfidenceLowHint,
      BodyNutritionConfidence.insufficient =>
        l10n.analyticsInsightNotEnoughData,
    };
  }

  String _effectiveRangeDisclosure() {
    final resolved = _rangePolicy.resolve(
      metricId: StatisticsMetricId.bodyNutritionTrend,
      selectedBlockType: _activeBlock, 
      now: _anchorDate,
      earliestAvailableDay: _analytics?.range.start,
    );
    final days = resolved.effectiveDays;
    final l10n = AppLocalizations.of(context)!;
    if (days == null || days <= 0) {
      return TimeframeLabelFormatter.format(_activeBlock, _anchorDate, l10n);
    }
    if (_activeBlock == TimeframeBlock.maxBlock) {
      return '$days ${l10n.analyticsDayUnitLabel}';
    }
    return TimeframeLabelFormatter.format(_activeBlock, _anchorDate, l10n);
  }
}
