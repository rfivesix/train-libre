// lib/features/diary/presentation/dialogs/quantity_log_flow.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/database_helper.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/base_food_language_service.dart';
import '../../../../services/haptic_feedback_service.dart';
import '../../../../services/theme_service.dart';
import '../../../../util/date_util.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../domain/models/fluid_entry.dart';
import '../../domain/models/food_entry.dart';
import '../../domain/models/food_item.dart';
import '../../../supplements/domain/models/supplement.dart';
import '../../../supplements/domain/models/supplement_log.dart';
import 'quantity_dialog_content.dart';

/// What the quantity sheet hands back once the user confirms.
typedef QuantitySelection = ({
  int quantity,
  DateTime timestamp,
  String mealType,
  bool isLiquid,
  double? sugarPer100ml,
  double? caffeinePer100ml,
});

/// Asks for amount, meal type and time for [item].
///
/// Lives here rather than on a screen because more than one entry point needs
/// the same sheet — the diary, the add-food flow and the barcode a live capture
/// session picked up all end in the exact same question.
Future<QuantitySelection?> showQuantityMenu(
  BuildContext context,
  FoodItem item, {
  DateTime? initialDate,
  String? initialMealType,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();

  return showGlassBottomMenu<QuantitySelection>(
    context: context,
    title: () {
      final themeService = Provider.of<ThemeService>(context, listen: false);
      final baseFoodLang = BaseFoodLanguageService.resolveLanguageCode(
        choice: themeService.baseFoodLanguage,
        context: context,
      );
      return item.source == FoodItemSource.base
          ? item.getLocalizedName(context, languageCode: baseFoodLang)
          : item.getLocalizedName(context);
    }(),
    contentBuilder: (ctx, _) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuantityDialogContent(
            key: dialogStateKey,
            item: item,
            initialMealType: initialMealType,
            initialTimestamp: (initialDate ?? DateTime.now()).withCurrentTime,
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  label: l10n.cancel,
                  tooltip: l10n.cancel,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.primary(
                  onPressed: () {
                    final state = dialogStateKey.currentState;
                    if (state == null) return;
                    final quantity = int.tryParse(state.quantityText);
                    if (quantity == null || quantity <= 0) return;
                    final sugar = double.tryParse(
                      state.sugarText.replaceAll(',', '.'),
                    );
                    final caffeine = double.tryParse(
                      state.caffeineText.replaceAll(',', '.'),
                    );
                    Navigator.of(ctx).pop((
                      quantity: quantity,
                      timestamp: state.selectedDateTime,
                      mealType: state.selectedMealType,
                      isLiquid: state.isLiquid,
                      sugarPer100ml: sugar,
                      caffeinePer100ml: caffeine,
                    ));
                  },
                  label: l10n.add_button,
                  tooltip: l10n.add_button,
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// Asks for the amount and writes the entry. Returns true when something was
/// actually logged, so the caller knows whether to refresh.
Future<bool> logFoodItemWithQuantity(
  BuildContext context,
  FoodItem item, {
  DateTime? initialDate,
  String? initialMealType,
  required String telemetrySource,
}) async {
  final selection = await showQuantityMenu(
    context,
    item,
    initialDate: initialDate,
    initialMealType: initialMealType,
  );
  if (selection == null || !context.mounted) return false;

  final entry = FoodEntry(
    barcode: item.barcode,
    timestamp: selection.timestamp,
    quantityInGrams: selection.quantity,
    mealType: selection.mealType,
  );

  final entryId = await DatabaseHelper.instance.insertFoodEntry(
    entry,
    telemetrySource: telemetrySource,
  );

  if (selection.isLiquid) {
    final fluidEntryId = await DatabaseHelper.instance.insertFluidEntry(
      FluidEntry(
        timestamp: selection.timestamp,
        quantityInMl: selection.quantity,
        name: item.name,
        kcal: (item.calories / 100 * selection.quantity).round(),
        sugarPer100ml: selection.sugarPer100ml,
        carbsPer100ml: selection.sugarPer100ml,
        caffeinePer100ml: selection.caffeinePer100ml,
        linkedFoodEntryId: entryId,
      ),
    );

    final caffeinePer100ml = selection.caffeinePer100ml;
    if (caffeinePer100ml != null && caffeinePer100ml > 0) {
      await _logCaffeineDose(
        doseMg: caffeinePer100ml * selection.quantity / 100,
        timestamp: selection.timestamp,
        foodEntryId: entryId,
        fluidEntryId: fluidEntryId,
      );
    }
  }

  HapticFeedbackService.instance.confirmationFeedback();
  return true;
}

/// Records the caffeine represented by a logged liquid and links it to the
/// food/fluid entries so edits and deletions keep the diary total in sync.
Future<void> _logCaffeineDose({
  required double doseMg,
  required DateTime timestamp,
  required int foodEntryId,
  required int fluidEntryId,
}) async {
  final supplements = await DatabaseHelper.instance.getAllSupplements();
  final caffeine = supplements.firstWhere(
    (supplement) => supplement.isCaffeine,
    orElse: () => Supplement(
      name: 'Caffeine',
      defaultDose: 100,
      unit: 'mg',
      dailyLimit: 400,
      code: 'caffeine',
      isBuiltin: true,
    ),
  );
  final caffeineId =
      caffeine.id ?? await DatabaseHelper.instance.insertSupplement(caffeine);

  await DatabaseHelper.instance.insertSupplementLog(
    SupplementLog(
      supplementId: caffeineId,
      dose: doseMg,
      unit: 'mg',
      timestamp: timestamp,
      sourceFoodEntryId: foodEntryId,
      sourceFluidEntryId: fluidEntryId,
    ),
  );
}
