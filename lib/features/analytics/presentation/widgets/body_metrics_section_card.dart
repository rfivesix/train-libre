import 'package:material_ui/material_ui.dart';

import '../../../../util/design_constants.dart';

import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../../statistics/domain/body_nutrition_analytics_models.dart';
import '../../../statistics/presentation/statistics_formatter.dart';
import '../../../statistics/presentation/widgets/body_nutrition_normalized_trend_chart.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class BodyMetricsSectionCard extends StatelessWidget {
  final SectionLoadState<BodyNutritionAnalyticsResult> state;
  final String? rangeLabel;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  const BodyMetricsSectionCard({
    super.key,
    required this.state,
    this.rangeLabel,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.bodyNutrition;
    final title = l10n.sectionBodyNutrition;

    if (state.hasError && !state.hasData) {
      return AnalyticsCardBase.buildSectionErrorCard(
        context,
        l10n,
        onRetry,
        sectionId,
        title,
      );
    }

    final body = state.data;
    final unitService = Provider.of<UnitService>(context);
    final weightUnit = unitService.suffixFor(UnitDimension.weight);
    final weightValue = body?.currentWeightKg == null
        ? '-'
        : '${unitService.convertDisplayValue(body!.currentWeightKg!, UnitDimension.weight).toStringAsFixed(1)} $weightUnit';
    final weightChangeValue = body?.weightChangeKg == null
        ? '-'
        : '${body!.weightChangeKg! >= 0 ? '+' : '-'}${unitService.convertDisplayValue(body.weightChangeKg!.abs(), UnitDimension.weight).toStringAsFixed(1)} $weightUnit';
    final caloriesValue = body == null || body.loggedCalorieDays <= 0
        ? '-'
        : '${body.avgDailyCalories.round()} ${l10n.analyticsKcalPerDay}';
    final relationship = body == null
        ? l10n.analyticsInsightNotEnoughData
        : StatisticsPresentationFormatter.bodyNutritionRelationshipLabel(
            l10n,
            body.relationship,
          );
    final confidenceLabel = body == null
        ? l10n.analyticsInsufficientConfidenceLabel
        : StatisticsPresentationFormatter.bodyNutritionConfidenceLabel(
            l10n,
            body.confidence,
          );

    return AnalyticsCardBase.decorateSectionCard(
      context,
      state: state,
      child: SummaryCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnalyticsCardBase.buildHeaderWithChevron(
                context,
                label: title,
                chipText: rangeLabel,
              ),
              const SizedBox(height: DesignConstants.spacingM),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ValueSummaryCard(
                        label: l10n.metricsCurrentWeight,
                        value: weightValue,
                        disableShadow: true,
                        useSecondarySurface: true,
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingS),
                    Expanded(
                      child: ValueSummaryCard(
                        label: l10n.metricsWeightChange,
                        value: weightChangeValue,
                        disableShadow: true,
                        useSecondarySurface: true,
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingS),
                    Expanded(
                      child: ValueSummaryCard(
                        label: l10n.metricsAvgCalories,
                        value: caloriesValue,
                        disableShadow: true,
                        useSecondarySurface: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignConstants.spacingM),
              SizedBox(
                height: 76,
                child: BodyNutritionNormalizedTrendChart(
                  range: body?.range,
                  weightSeries: body?.weightDaily ?? const [],
                  calorieSeries: body?.caloriesDaily ?? const [],
                  incompleteNutritionDays:
                      body?.incompleteNutritionDays ?? const {},
                  compact: true,
                ),
              ),
              const SizedBox(height: DesignConstants.spacingS),
              Row(
                children: [
                  _legendDot(
                    context,
                    color: Theme.of(context).colorScheme.primary,
                    label: l10n.analyticsBodyNutritionTotalWeightLabel(
                      weightUnit,
                    ),
                    shape: BoxShape.circle,
                  ),
                  const SizedBox(width: DesignConstants.spacingM),
                  _legendDot(
                    context,
                    color: const Color(0xFFF97316),
                    label: l10n.analyticsBodyNutritionTotalCaloriesLabel,
                    shape: BoxShape.rectangle,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$relationship · $confidenceLabel',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(
    BuildContext context, {
    required Color color,
    required String label,
    BoxShape shape = BoxShape.circle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: shape,
            borderRadius: shape == BoxShape.rectangle
                ? BorderRadius.circular(2)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
