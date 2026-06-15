// lib/widgets/compact_nutrition_bar.dart

import 'package:flutter/material.dart';
import '../../domain/models/daily_nutrition.dart';
import '../../../../util/design_constants.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/glass_progress_bar.dart';

/// A compact visual overview of daily nutrition and hydration progress.
///
/// Displays progress bars for calories, protein, and water intake.
class CompactNutritionBar extends StatelessWidget {
  /// The [nutritionData] to visualize in this bar.
  final DailyNutrition nutritionData;
  const CompactNutritionBar({super.key, required this.nutritionData});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        GlassProgressBar(
          label: l10n.calories,
          value: nutritionData.calories.toDouble(),
          target: nutritionData.targetCalories.toDouble(),
          unit: 'kcal',
          color: Colors.orange,
        ),
        const SizedBox(height: DesignConstants.spacingM),
        GlassProgressBar(
          label: l10n.protein,
          value: nutritionData.protein.toDouble(),
          target: nutritionData.targetProtein.toDouble(),
          unit: 'g',
          color: Colors.red.shade400,
        ),
        const SizedBox(height: DesignConstants.spacingM),
        GlassProgressBar(
          label: l10n.water,
          value: nutritionData.water / 1000,
          target: nutritionData.targetWater / 1000,
          unit: 'L',
          color: Colors.blue,
        ),
      ],
    );
  }
}
