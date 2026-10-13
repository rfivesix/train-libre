// lib/widgets/nutrition_summary_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/daily_nutrition.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/card_morph_route.dart';
import '../../../../widgets/common/glass_progress_bar.dart';
import '../../../../widgets/common/morph_source.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../analytics/presentation/widgets/micronutrient_section_card.dart';

/// A comprehensive summary widget for daily nutrition and macro tracking.
///
/// Displays multiple [GlassProgressBar]s in a grid-like layout for calories,
/// water, protein, carbs, and fats. Can be expanded to show sub-macros like sugar.
class NutritionSummaryWidget extends StatelessWidget {
  /// The daily nutrition data to display.
  final DailyNutrition nutritionData;

  /// Whether to show the expanded set of macros (e.g., sugar, fiber, salt, caffeine).
  final bool isExpandedView;
  final bool showSugarInOverview;
  final String extraNutrient;
  final DateTime? selectedDate;

  /// Localization instance for labels.
  final AppLocalizations l10n;

  const NutritionSummaryWidget({
    super.key,
    required this.nutritionData,
    this.isExpandedView = false,
    this.showSugarInOverview = false,
    this.extraNutrient = 'fiber',
    this.selectedDate,
    required this.l10n,
  });

  Widget _buildExtraNutrientBar(
    AppLocalizations l10n,
    DailyNutrition nutritionData,
  ) {
    final key = extraNutrient.toLowerCase();
    if (key == 'sugar') {
      return GlassProgressBar(
        label: l10n.sugar,
        unit: 'g',
        value: nutritionData.sugar,
        target: nutritionData.targetSugar.toDouble(),
        color: Colors.pink.shade200,
      );
    } else if (key == 'salt') {
      return GlassProgressBar(
        label: l10n.salt,
        unit: 'g',
        value: nutritionData.salt,
        target: nutritionData.targetSalt.toDouble(),
        color: Colors.grey.shade500,
      );
    } else {
      return GlassProgressBar(
        label: l10n.fiber,
        unit: 'g',
        value: nutritionData.fiber,
        target: nutritionData.targetFiber.toDouble(),
        color: Colors.brown.shade400,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitService = context.watch<UnitService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: GlassProgressBar(
                        label: l10n.calories,
                        unit: 'kcal',
                        value: nutritionData.calories.toDouble(),
                        target: nutritionData.targetCalories.toDouble(),
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    Expanded(
                      child: GlassProgressBar(
                        label: l10n.water,
                        unit: unitService.suffixFor(UnitDimension.liquid),
                        value: unitService.convertDisplayValue(
                          nutritionData.water.toDouble(),
                          UnitDimension.liquid,
                        ),
                        target: unitService.convertDisplayValue(
                          nutritionData.targetWater.toDouble(),
                          UnitDimension.liquid,
                        ),
                        color: Colors.blue,
                      ),
                    ),
                    if (!isExpandedView) ...[
                      const SizedBox(height: DesignConstants.spacingS),
                      Expanded(
                        child: _buildExtraNutrientBar(l10n, nutritionData),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: GlassProgressBar(
                        label: l10n.protein,
                        unit: 'g',
                        value: nutritionData.protein.toDouble(),
                        target: nutritionData.targetProtein.toDouble(),
                        color: DesignConstants.brandRedColor,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    Expanded(
                      child: GlassProgressBar(
                        label: l10n.carbs,
                        unit: 'g',
                        value: nutritionData.carbs.toDouble(),
                        target: nutritionData.targetCarbs.toDouble(),
                        color: Colors.green.shade400,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    Expanded(
                      child: GlassProgressBar(
                        label: l10n.fat,
                        unit: 'g',
                        value: nutritionData.fat.toDouble(),
                        target: nutritionData.targetFat.toDouble(),
                        color: Colors.purple.shade300,
                      ),
                    ),
                  ],
                ),
              ),
              if (isExpandedView) ...[
                const SizedBox(width: DesignConstants.spacingS),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: GlassProgressBar(
                          label: l10n.sugar,
                          unit: 'g',
                          value: nutritionData.sugar,
                          target: nutritionData.targetSugar.toDouble(),
                          color: Colors.pink.shade200,
                        ),
                      ),
                      const SizedBox(height: DesignConstants.spacingS),
                      Expanded(
                        child: GlassProgressBar(
                          label: l10n.fiber,
                          unit: 'g',
                          value: nutritionData.fiber,
                          target: nutritionData.targetFiber.toDouble(),
                          color: Colors.brown.shade400,
                        ),
                      ),
                      const SizedBox(height: DesignConstants.spacingS),
                      Expanded(
                        child: GlassProgressBar(
                          label: l10n.salt,
                          unit: 'g',
                          value: nutritionData.salt,
                          target: nutritionData.targetSalt.toDouble(),
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: DesignConstants.spacingS),
                      Expanded(
                        child: GlassProgressBar(
                          label: l10n.supplement_caffeine,
                          unit: 'mg',
                          value: nutritionData.caffeine,
                          target: nutritionData.targetCaffeine.toDouble(),
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (selectedDate != null)
          _MicronutrientDiaryShortcut(
            date: selectedDate!,
            title: l10n.statisticsMicronutrientsTitle,
            subtitle: l10n.statisticsMicronutrientsPreviewSubtitle,
          ),
      ],
    );
  }
}

class _MicronutrientDiaryShortcut extends StatelessWidget {
  const _MicronutrientDiaryShortcut({
    required this.date,
    required this.title,
    required this.subtitle,
  });

  final DateTime date;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildCard({VoidCallback? onTap}) => SummaryCard(
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.only(
            top: DesignConstants.spacingS,
          ),
          child: Semantics(
            button: true,
            container: true,
            label: '$title, $subtitle',
            child: InkWell(
              onTap: onTap,
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusL),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.spacingM,
                    vertical: DesignConstants.spacingXS,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: DesignConstants.spacingM),
                      Icon(
                        LucideIcons.chevron_right,
                        color: theme.colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

    return MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardContext) => buildCard(
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardContext,
                sourceBuilder: (_) => buildCard(),
                onSourceVisibilityChanged: setHidden,
                builder: (_) => MicronutrientStatisticsScreen(initialDay: date),
              ),
            );
          },
        ),
      ),
    );
  }
}
