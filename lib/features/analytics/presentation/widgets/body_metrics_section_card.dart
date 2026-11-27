import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/empty_states/card_empty_state_overlay.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../../statistics/domain/body_nutrition_analytics_models.dart';
import '../../../statistics/domain/timeframe_block.dart';
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
    final isEmpty =
        !state.isLoading &&
        !state.hasError &&
        state.hasData &&
        !(body?.hasAnyData ?? false);
    final isInitialLoading = state.isLoading && !state.hasData;
    final displayBody = (isEmpty || isInitialLoading)
        ? BodyNutritionAnalyticsResult.mockPreview(
            body?.range ?? TimeframeBlock.month.getRollingBounds(),
          )
        : body;
    final unitService = Provider.of<UnitService>(context);
    final locale = Localizations.localeOf(context).toString();
    final weightUnit = unitService.suffixFor(UnitDimension.weight);
    final weightChangeValue = displayBody?.weightChangeKg == null
        ? '-'
        : StatisticsPresentationFormatter.formatLocalizedWeightChange(
            displayBody!.weightChangeKg!,
            unitService,
            locale: locale,
          );
    final caloriesValue = displayBody == null || displayBody.loggedCalorieDays <= 0
        ? '-'
        : '${displayBody.avgDailyCalories.round()} ${l10n.analyticsKcalPerDay}';

    Widget bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
            range: displayBody?.range,
            weightSeries: displayBody?.weightDaily ?? const [],
            calorieSeries: displayBody?.caloriesDaily ?? const [],
            incompleteNutritionDays:
                displayBody?.incompleteNutritionDays ?? const {},
            compact: true,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Wrap(
          spacing: DesignConstants.spacingM,
          runSpacing: DesignConstants.spacingXS,
          children: [
            _legendDot(
              context,
              color: Theme.of(context).colorScheme.primary,
              label: l10n.analyticsBodyNutritionTotalWeightLabel(weightUnit),
              shape: BoxShape.circle,
            ),
            _legendDot(
              context,
              color: const Color(0xFFF97316),
              label: l10n.analyticsBodyNutritionTotalCaloriesLabel,
              shape: BoxShape.rectangle,
            ),
          ],
        ),
      ],
    );

    if (isEmpty) {
      bodyContent = CardEmptyStateOverlay(
        isEmpty: true,
        message: l10n.statisticsEmptyBody,
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        child: bodyContent,
      );
    } else if (isInitialLoading) {
      bodyContent = Skeletonizer(
        enabled: true,
        child: IgnorePointer(child: bodyContent),
      );
    }

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
              bodyContent,
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
