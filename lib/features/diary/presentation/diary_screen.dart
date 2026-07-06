import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/database_helper.dart';
import '../domain/models/daily_nutrition.dart';
import 'dialogs/fluid_dialog_content.dart';
import 'dialogs/quantity_dialog_content.dart';
import '../../../generated/app_localizations.dart';
import '../domain/repositories/diary_repository.dart';
import '../../supplements/domain/repositories/supplement_repository.dart';
import '../../workout/domain/repositories/workout_repository.dart';
import '../domain/models/fluid_entry.dart';
import '../domain/models/food_entry.dart';
import '../domain/models/food_item.dart';
import '../domain/models/tracked_food_item.dart';
import '../../supplements/domain/models/tracked_supplement.dart';
import 'add_food_screen.dart';
import 'add_food_navigation_result.dart';
import '../../supplements/presentation/supplement_hub_screen.dart';
import '../../../util/date_util.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'widgets/nutrition_summary_widget.dart';
import '../../supplements/presentation/widgets/supplement_summary_widget.dart';
import '../../../widgets/common/macro_badge_row.dart';
import 'diary_view_model.dart';
import '../../../services/theme_service.dart';
import '../../../services/base_food_language_service.dart';
import '../../workout/presentation/workout_history_screen.dart';
import '../../workout/presentation/widgets/todays_workout_summary_card.dart';
import 'widgets/weight_chart_card.dart';
import 'widgets/steps_summary_card.dart';
import 'widgets/sleep_summary_card.dart';
import 'widgets/pulse_summary_card.dart';
import 'widgets/food_entry_tile.dart';
import 'widgets/fluid_entry_tile.dart';
import 'widgets/recommendation_banner.dart';
import 'meal_screen.dart';
import '../../../core/infrastructure/share_service.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// The central hub for tracking and viewing daily nutritional and activity data.
///
/// Displays a comprehensive overview of calories, macros, supplements, and workouts
/// for a selected date. Allows users to manage food entries, fluid intake, and
/// view historical measurements like weight.
class DiaryScreen extends StatelessWidget {
  final DateTime? initialDate;
  final GlobalKey<DiaryScreenState>? contentKey;

  const DiaryScreen({super.key, this.initialDate, this.contentKey});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DiaryViewModel(
        nutritionRepo: context.read<IDiaryRepository>(),
        supplementRepo: context.read<SupplementRepository>(),
        workoutRepo: context.read<IWorkoutRepository>(),
        initialDate: initialDate,
      ),
      child: _DiaryScreenContent(key: contentKey ?? key),
    );
  }
}

class _DiaryScreenContent extends StatefulWidget {
  const _DiaryScreenContent({super.key});

  @override
  State<_DiaryScreenContent> createState() => DiaryScreenState();
}

class DiaryScreenState extends State<_DiaryScreenContent> {
  final GlobalKey _macroSummaryKey = GlobalKey();
  final ShareService _shareService = const ShareService();

  DiaryViewModel get viewModel => context.read<DiaryViewModel>();
  ValueNotifier<DateTime> get selectedDateNotifier =>
      viewModel.selectedDateNotifier;

  Future<void> showShareMenu() async {
    final l10n = AppLocalizations.of(context)!;
    await showGlassBottomMenu<void>(
      context: context,
      title: l10n.share,
      actions: [
        GlassMenuAction(
          icon: LucideIcons.image,
          label: l10n.shareAsImage,
          onTap: () async {
            try {
              await _shareService.shareWidgetAsImage(_macroSummaryKey);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.shareFailed)),
                );
              }
            }
          },
        ),
        GlassMenuAction(
          icon: LucideIcons.text_initial,
          label: l10n.shareAsTextOrCopy,
          onTap: () async {
            try {
              await _shareService.shareDailyLogAsText(viewModel.selectedDate,
                  l10n: l10n);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.shareFailed)),
                );
              }
            }
          },
        ),
      ],
    );
  }

  void setSelectedDate(DateTime date) {
    context.read<DiaryViewModel>().setSelectedDate(date);
  }

  Future<void> syncHealthData({bool forceStepsRefresh = false}) async {
    await context
        .read<DiaryViewModel>()
        .syncHealthData(forceStepsRefresh: forceStepsRefresh);
  }

  @Deprecated('Use setSelectedDate or syncHealthData instead')
  Future<void> loadDataForDate(DateTime date,
      {bool queueIfInFlight = false, bool forceStepsRefresh = false}) async {
    setSelectedDate(date);
    if (forceStepsRefresh) {
      await syncHealthData(forceStepsRefresh: true);
    }
  }

  Future<void> _deleteFoodEntry(int id) async {
    final viewModel = context.read<DiaryViewModel>();
    await viewModel.deleteFoodEntry(id);
  }

  Future<void> _deleteFluidEntry(int id) async {
    final viewModel = context.read<DiaryViewModel>();
    await viewModel.deleteFluidEntry(id);
  }

  Future<void> _editFluidEntry(FluidEntry entry) async {
    if (entry.linkedFoodEntryId != null) {
      TrackedFoodItem? trackedItem;
      // Search in all meals for the linked food entry
      for (var mealList in viewModel.entriesByMeal.values) {
        for (var item in mealList) {
          if (item.entry.id == entry.linkedFoodEntryId) {
            trackedItem = item;
            break;
          }
        }
        if (trackedItem != null) break;
      }

      if (trackedItem != null) {
        // Reuse the existing food edit logic
        await _editFoodEntry(trackedItem);
        return;
      }
    }

    // Standalone fluid entry edit (e.g. water added via FAB)
    final l10n = AppLocalizations.of(context)!;
    final key = GlobalKey<FluidDialogContentState>();

    await showGlassBottomMenu(
      context: context,
      title: l10n.add_liquid_title, // Reuse the same title or similar
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FluidDialogContent(
              key: key,
              initialQuantity: entry.quantityInMl,
              initialTimestamp: entry.timestamp,
              initialName: entry.name,
              initialSugar: entry.sugarPer100ml,
              initialCaffeine: entry.caffeinePer100ml,
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: close,
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final vm = viewModel;
                      final state = key.currentState;
                      if (state == null) return;
                      final quantity = int.tryParse(state.quantityText);
                      if (quantity == null || quantity <= 0) return;

                      final name = state.nameText;
                      final sugar = double.tryParse(
                        state.sugarText.replaceAll(',', '.'),
                      );
                      final caffeine = double.tryParse(
                        state.caffeineText.replaceAll(',', '.'),
                      );
                      final kcal = (sugar != null)
                          ? ((sugar / 100) * quantity * 4).round()
                          : null;

                      final updated = FluidEntry(
                        id: entry.id,
                        timestamp: state.selectedDateTime,
                        quantityInMl: quantity,
                        name: name,
                        kcal: kcal,
                        sugarPer100ml: sugar,
                        carbsPer100ml: sugar,
                        caffeinePer100ml: caffeine,
                        linkedFoodEntryId: entry.linkedFoodEntryId,
                      );

                      try {
                        await vm.updateFluidEntry(updated);

                        // Update caffeine dose
                        await vm.logCaffeineDose(
                          (caffeine ?? 0) * (quantity / 100.0),
                          state.selectedDateTime,
                          fluidEntryId: entry.id,
                        );

                        close();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.error)),
                        );
                      }
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _editFoodEntry(TrackedFoodItem trackedItem) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();
    final vm = viewModel;

    final result = await showGlassBottomMenu<
        ({
          int quantity,
          DateTime timestamp,
          String mealType,
          bool isLiquid,
          double? sugarPer100ml,
          double? caffeinePer100ml,
        })?>(
      context: context,
      title: trackedItem.item.getLocalizedName(context),
      contentBuilder: (ctx, close) {
        final linkedFluid = vm.fluidEntries
            .where((f) => f.linkedFoodEntryId == trackedItem.entry.id)
            .firstOrNull;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog content, now used as bottom-sheet content
            QuantityDialogContent(
              key: dialogStateKey,
              item: trackedItem.item,
              initialQuantity: trackedItem.entry.quantityInGrams,
              initialTimestamp: trackedItem.entry.timestamp,
              initialMealType: trackedItem.entry.mealType,
              initialIsLiquid: linkedFluid != null ? true : null,
              initialSugar: linkedFluid?.sugarPer100ml,
              initialCaffeine: linkedFluid?.caffeinePer100ml,
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: close,
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final state = dialogStateKey.currentState;
                      if (state != null) {
                        final quantity = int.tryParse(state.quantityText);
                        final caffeine = double.tryParse(
                          state.caffeineText.replaceAll(',', '.'),
                        );
                        final sugar = double.tryParse(
                          state.sugarText.replaceAll(',', '.'),
                        );

                        if (quantity != null && quantity > 0) {
                          close();
                          // Return the correct anonymous tuple here.
                          Navigator.of(ctx).pop((
                            quantity: quantity,
                            timestamp: state.selectedDateTime,
                            mealType: state.selectedMealType,
                            isLiquid: state.isLiquid,
                            sugarPer100ml: sugar,
                            caffeinePer100ml: caffeine,
                          ));
                        }
                      }
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    // Continue processing the result data.
    if (result != null) {
      if (!mounted) return;
      final updatedEntry = FoodEntry(
        id: trackedItem.entry.id,
        barcode: trackedItem.item.barcode,
        quantityInGrams: result.quantity,
        timestamp: result.timestamp,
        mealType: result.mealType,
      );
      await vm.updateFoodEntry(updatedEntry);

      // 1. Delete FluidEntry if linked.
      if (trackedItem.entry.id != null) {
        await vm.deleteFluidEntryByLinkedFoodId(
          trackedItem.entry.id!,
        );
      }
      // 2. Recreate FluidEntry if it is now liquid.
      if (result.isLiquid) {
        final newFluidEntry = FluidEntry(
          timestamp: result.timestamp,
          quantityInMl: result.quantity,
          name: trackedItem.item.name,
          kcal: (trackedItem.item.calories / 100 * result.quantity).round(),
          sugarPer100ml: result.sugarPer100ml,
          carbsPer100ml: result.sugarPer100ml, // Spiegeln
          caffeinePer100ml: result.caffeinePer100ml,
          linkedFoodEntryId: trackedItem.entry.id, // Preserve the link
        );
        await vm.insertFluidEntry(newFluidEntry);
      }

      // 3. Update/delete caffeine log in every case.
      await vm.logCaffeineDose(
        (result.caffeinePer100ml ?? 0) * (result.quantity / 100.0),
        result.timestamp,
        foodEntryId: trackedItem.entry.id,
      );
      // No manual reload needed, state is reactive
    }
  }

  /// Creates a blank meal stub in the DB and routes to [MealScreen] with the
  /// filtered solid diary entries pre-populated so the user can author their
  /// own template title before committing.
  Future<void> _saveAsMealTemplate(
    List<TrackedFoodItem> solidItems,
    AppLocalizations l10n,
  ) async {
    // Create a temporary meal row (name will be set by the user in MealScreen).
    final newMealId = await DatabaseHelper.instance.insertMeal(
      name: '', // intentionally blank — user must fill it in
      notes: '',
    );

    // Convert TrackedFoodItem list to the raw map format MealScreen expects.
    final prefill = solidItems
        .map(
          (ti) => <String, dynamic>{
            'barcode': ti.item.barcode,
            'quantity_in_grams': ti.entry.quantityInGrams,
          },
        )
        .toList();

    if (!mounted) return;

    final meal = <String, dynamic>{
      'id': newMealId,
      'name': '',
      'notes': '',
    };

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealScreen(
          meal: meal,
          prefillItems: prefill,
        ),
      ),
    );

    // If the user saved with an empty name and no items the stub should be
    // cleaned up. DatabaseHelper.insertMeal creates a row regardless, so we
    // attempt a best-effort delete when the result is still empty.
    try {
      final savedItems = await DatabaseHelper.instance.getMealItems(newMealId);
      final meals = await DatabaseHelper.instance.getMeals();
      final created = meals.cast<Map<String, dynamic>?>().firstWhere(
            (m) => m?['id'] == newMealId,
            orElse: () => null,
          );
      if (created != null &&
          (created['name'] as String).isEmpty &&
          savedItems.isEmpty) {
        await DatabaseHelper.instance.deleteMeal(newMealId);
      }
    } catch (_) {
      // cleanup is best-effort
    }
  }

  Future<void> _addFoodToMeal(String mealType) async {
    final vm = viewModel;
    final routeResult = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => AddFoodScreen(
          initialDate: vm.selectedDate, // <--- Pass-through
          initialMealType: mealType, // <--- Pass-through
        ),
      ),
    );

    if (!mounted) return;

    final addFoodResult = AddFoodNavigationResult.fromRouteResult(routeResult);
    if (addFoodResult.shouldRefresh) {
      return;
    }

    final selectedFoodItem = addFoodResult.selectedFoodItem;
    if (selectedFoodItem == null) return;

    // FIX: Pass the date to the helper menu.
    final result = await _showQuantityMenu(
      selectedFoodItem,
      mealType,
      initialDate: vm.selectedDate, // <--- Add parameter (see point C)
    );

    if (result == null || !mounted) return;

    // ... (rest of the logic stays the same, uses result.timestamp) ...
    final int quantity = result.quantity;
    final DateTime timestamp = result.timestamp;
    final String resultMealType = result.mealType;
    final bool isLiquid = result.isLiquid;
    final double? caffeinePer100 = result.caffeinePer100ml;

    final newFoodEntry = FoodEntry(
      barcode: selectedFoodItem.barcode,
      timestamp: timestamp,
      quantityInGrams: quantity,
      mealType: resultMealType,
    );
    final newFoodEntryId = await vm.insertFoodEntry(
      newFoodEntry,
    );

    if (!mounted) return;

    if (isLiquid) {
      final newFluidEntry = FluidEntry(
        timestamp: timestamp,
        quantityInMl: quantity,
        name: selectedFoodItem.name,
        kcal: (selectedFoodItem.calories / 100 * quantity).round(),
        sugarPer100ml: result.sugarPer100ml,
        carbsPer100ml: result.sugarPer100ml,
        caffeinePer100ml: result.caffeinePer100ml,
        linkedFoodEntryId: newFoodEntryId,
      );
      await vm.insertFluidEntry(newFluidEntry);
    }

    if (isLiquid && caffeinePer100 != null && caffeinePer100 > 0) {
      final totalCaffeine = (caffeinePer100 / 100.0) * quantity;
      await vm.logCaffeineDose(
        totalCaffeine,
        timestamp,
        foodEntryId: newFoodEntryId,
      );
    }
  }

  // Add these two new methods to the class.
  // In lib/screens/diary_screen.dart

  Future<
      ({
        int quantity,
        DateTime timestamp,
        String mealType,
        bool isLiquid,
        double? sugarPer100ml,
        double? caffeinePer100ml,
      })?> _showQuantityMenu(
    FoodItem item,
    String mealType, {
    DateTime? initialDate, // <--- New parameter
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();

    return showGlassBottomMenu(
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
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuantityDialogContent(
              key: dialogStateKey,
              item: item,
              initialMealType: mealType,
              initialTimestamp:
                  (initialDate ?? viewModel.selectedDate).withCurrentTime,
            ),
            // ... (rest of the method: buttons, etc. stays the same) ...
            const SizedBox(height: DesignConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(null);
                    },
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final state = dialogStateKey.currentState;
                      if (state != null) {
                        final quantity = int.tryParse(state.quantityText);
                        // ... parsing ...
                        final sugar = double.tryParse(
                          state.sugarText.replaceAll(',', '.'),
                        );
                        final caffeine = double.tryParse(
                          state.caffeineText.replaceAll(',', '.'),
                        );

                        if (quantity != null && quantity > 0) {
                          close();
                          Navigator.of(ctx).pop((
                            quantity: quantity,
                            timestamp: state.selectedDateTime,
                            mealType: state.selectedMealType,
                            isLiquid: state.isLiquid,
                            sugarPer100ml: sugar,
                            caffeinePer100ml: caffeine,
                          ));
                        }
                      }
                    },
                    child: Text(l10n.add_button),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> pickDate() async {
    final viewModel = context.read<DiaryViewModel>();
    final picked = await showAdaptiveDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      viewModel.pickDate(picked);
    }
  }

  void navigateDay(bool forward) {
    context.read<DiaryViewModel>().navigateDay(forward);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.select<DiaryViewModel, bool>((vm) => vm.isLoading);
    final stepsEnabled =
        context.select<DiaryViewModel, bool>((vm) => vm.stepsTrackingEnabled);
    final sleepEnabled =
        context.select<DiaryViewModel, bool>((vm) => vm.sleepTrackingEnabled);
    final pulseEnabled =
        context.select<DiaryViewModel, bool>((vm) => vm.pulseTrackingEnabled);
    final hasWorkoutSummary =
        context.select<DiaryViewModel, bool>((vm) => vm.workoutSummary != null);
    final l10n = AppLocalizations.of(context)!;
    final double appBarHeight =
        MediaQuery.paddingOf(context).top; // + kToolbarHeight;

    // 2. Get your base padding from your design constants
    const EdgeInsets basePadding = DesignConstants
        .cardPadding; // This is EdgeInsets.all(DesignConstants.spacingL)

    // 3. Create the final combined padding
    final EdgeInsets finalPadding = basePadding.copyWith(
      // Take the original top value (16.0) and add the app bar height
      top: basePadding.top + appBarHeight,
    );

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => syncHealthData(forceStepsRefresh: true),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: finalPadding.copyWith(bottom: 0),
                  sliver: SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Selector<
                              DiaryViewModel,
                              ({
                                DailyNutrition? dailyNutrition,
                                DateTime selectedDate,
                                bool showSugarInOverview
                              })>(
                            selector: (context, vm) => (
                              dailyNutrition: vm.dailyNutrition,
                              selectedDate: vm.selectedDate,
                              showSugarInOverview: vm.showSugarInOverview,
                            ),
                            builder: (context, data, child) {
                              final dailyNutrition = data.dailyNutrition;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (dailyNutrition != null &&
                                      data.selectedDate
                                          .isSameDate(DateTime.now()))
                                    RecommendationBanner(
                                      currentCalories:
                                          dailyNutrition.targetCalories,
                                    ),
                                  AppSectionHeader(
                                      title: l10n.today_overview_text),
                                  if (dailyNutrition != null)
                                    RepaintBoundary(
                                      key: _macroSummaryKey,
                                      child: NutritionSummaryWidget(
                                        nutritionData: dailyNutrition,
                                        l10n: l10n,
                                        isExpandedView: false,
                                        showSugarInOverview:
                                            data.showSugarInOverview,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: DesignConstants.spacingXS),
                          Selector<
                              DiaryViewModel,
                              ({
                                List<TrackedSupplement> trackedSupplements,
                                DateTime selectedDate
                              })>(
                            selector: (context, vm) => (
                              trackedSupplements: vm.trackedSupplements,
                              selectedDate: vm.selectedDate,
                            ),
                            builder: (context, data, child) {
                              return SupplementSummaryWidget(
                                trackedSupplements: data.trackedSupplements,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SupplementHubScreen(),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (stepsEnabled) const StepsSummaryCard(),
                          if (sleepEnabled) const SleepSummaryCard(),
                          if (pulseEnabled) const PulseSummaryCard(),
                          // New section: insert workout summary here.
                          if (hasWorkoutSummary)
                            Selector<DiaryViewModel, Map<String, dynamic>?>(
                              selector: (context, vm) => vm.workoutSummary,
                              builder: (context, workoutSummary, child) {
                                if (workoutSummary == null) {
                                  return const SizedBox.shrink();
                                }
                                return TodaysWorkoutSummaryCard(
                                  duration:
                                      workoutSummary['duration'] as Duration,
                                  volume: workoutSummary['volume'] as double,
                                  sets: workoutSummary['sets'] as int,
                                  workoutCount: workoutSummary['count'] as int,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const WorkoutHistoryScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: finalPadding.left),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: DesignConstants.spacingXL),
                        AppSectionHeader(title: l10n.protocol_today_capslock),
                        _buildTodaysLog(l10n),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: finalPadding.left,
                    right: finalPadding.right,
                    bottom: finalPadding.bottom,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: DesignConstants.spacingXL),
                          AppSectionHeader(
                              title: l10n.measurementWeightCapslock),
                          const WeightChartCard(),
                          const BottomContentSpacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  // Section headers now use the centralized AppSectionHeader widget.

  // lib/screens/diary_screen.dart
  // In lib/screens/diary_screen.dart

  Future<void> _showAddFluidMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final key = GlobalKey<FluidDialogContentState>();

    await showGlassBottomMenu(
      context: context,
      title: l10n.add_liquid_title,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FluidDialogContent(
              key: key,
              initialTimestamp: viewModel.selectedDate.withCurrentTime,
            ),
            const SizedBox(height: DesignConstants.spacingM),
            // ... (rest of the method stays the same: buttons row, etc.)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: close,
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final vm = viewModel;
                      final state = key.currentState;
                      if (state == null) return;
                      final diaryDate = vm.selectedDate;
                      final quantity = int.tryParse(state.quantityText);
                      if (quantity == null || quantity <= 0) return;

                      final name = state.nameText;
                      final sugarPer100ml = double.tryParse(
                        state.sugarText.replaceAll(',', '.'),
                      );
                      final caffeinePer100ml = double.tryParse(
                        state.caffeineText.replaceAll(',', '.'),
                      );
                      final kcal = (sugarPer100ml != null)
                          ? ((sugarPer100ml / 100) * quantity * 4).round()
                          : null;

                      final newEntry = FluidEntry(
                        timestamp: state
                            .selectedDateTime, // This is now initialized correctly.
                        quantityInMl: quantity,
                        name: name,
                        kcal: kcal,
                        sugarPer100ml: sugarPer100ml,
                        carbsPer100ml: sugarPer100ml,
                        caffeinePer100ml: caffeinePer100ml,
                      );

                      try {
                        final newId = await DatabaseHelper.instance
                            .insertFluidEntry(newEntry);

                        if (!mounted) return;

                        if (caffeinePer100ml != null && caffeinePer100ml > 0) {
                          final totalCaffeine =
                              (caffeinePer100ml / 100.0) * quantity;
                          await vm.logCaffeineDose(
                            totalCaffeine,
                            state.selectedDateTime,
                            fluidEntryId: newId,
                          );
                        }
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.error)),
                        );
                        return;
                      }

                      close();
                      if (!mounted) return;
                      vm.loadDataForDate(diaryDate, queueIfInFlight: true);
                    },
                    child: Text(l10n.add_button),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodaysLog(AppLocalizations l10n) {
    const mealOrder = [
      "fluids", // In first position
      "mealtypeBreakfast",
      "mealtypeLunch",
      "mealtypeDinner",
      "mealtypeSnack",
    ];

    return Column(
      children: [
        _FluidsCard(
          onAddFluid: _showAddFluidMenu,
          onEditFluid: _editFluidEntry,
          onDeleteFluid: _deleteFluidEntry,
        ),
        ...mealOrder.where((k) => k != "fluids").map((mealKey) {
          return _MealCard(
            key: ValueKey(mealKey),
            title: _getLocalizedMealName(l10n, mealKey),
            mealKey: mealKey,
            onAddFood: () => _addFoodToMeal(mealKey),
            onEditFood: _editFoodEntry,
            onDeleteFood: _deleteFoodEntry,
            onSaveAsTemplate: _saveAsMealTemplate,
          );
        }),
      ],
    );
  }

  String _getLocalizedMealName(AppLocalizations l10n, String key) {
    switch (key) {
      case "mealtypeBreakfast":
        return l10n.mealtypeBreakfast;
      case "mealtypeLunch":
        return l10n.mealtypeLunch;
      case "mealtypeDinner":
        return l10n.mealtypeDinner;
      case "mealtypeSnack":
        return l10n.mealtypeSnack;
      default:
        return key;
    }
  }
}

class _MealMacros {
  double calories = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;
}

class DiaryAppBar extends StatefulWidget {
  final GlobalKey<DiaryScreenState> diaryKey;
  const DiaryAppBar({super.key, required this.diaryKey});

  @override
  State<DiaryAppBar> createState() => _DiaryAppBarState();
}

class _DiaryAppBarState extends State<DiaryAppBar> {
  ValueNotifier<DateTime>? _notifier;

  @override
  void initState() {
    super.initState();
    _checkNotifier();
  }

  void _checkNotifier() {
    final notifier = widget.diaryKey.currentState?.selectedDateNotifier;
    if (notifier != null) {
      setState(() => _notifier = notifier);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkNotifier();
      });
    }
  }

  String _getAppBarTitle(
    BuildContext context,
    AppLocalizations l10n,
    DateTime selectedDate,
  ) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBeforeYesterday = today.subtract(const Duration(days: 2));

    if (selectedDate.isSameDate(today)) {
      return l10n.today;
    } else if (selectedDate.isSameDate(yesterday)) {
      return l10n.yesterday;
    } else if (selectedDate.isSameDate(dayBeforeYesterday)) {
      return l10n.dayBeforeYesterday;
    } else {
      return DateFormat.yMMMMd(
        Localizations.localeOf(context).toString(),
      ).format(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900);

    if (_notifier == null) {
      return Padding(
        padding: const EdgeInsets.only(left: DesignConstants.spacingXS),
        child: _DiaryDateNavigator(
          l10n.today,
          titleStyle: titleStyle,
          onPreviousDay: () => widget.diaryKey.currentState?.navigateDay(false),
          onPickDate: () => widget.diaryKey.currentState?.pickDate(),
          onNextDay: () => widget.diaryKey.currentState?.navigateDay(true),
        ),
      );
    }

    return ValueListenableBuilder<DateTime>(
      valueListenable: _notifier!,
      builder: (context, selectedDate, child) {
        final title = _getAppBarTitle(context, l10n, selectedDate);
        return Padding(
          padding: const EdgeInsets.only(left: DesignConstants.spacingXS),
          child: _DiaryDateNavigator(
            title,
            titleStyle: titleStyle,
            onPreviousDay: () =>
                widget.diaryKey.currentState?.navigateDay(false),
            onPickDate: () => widget.diaryKey.currentState?.pickDate(),
            onNextDay: () => widget.diaryKey.currentState?.navigateDay(true),
          ),
        );
      },
    );
  }
}

class _DiaryDateNavigator extends StatelessWidget {
  final String title;
  final TextStyle? titleStyle;
  final VoidCallback onPreviousDay;
  final VoidCallback onPickDate;
  final VoidCallback onNextDay;

  const _DiaryDateNavigator(
    this.title, {
    required this.titleStyle,
    required this.onPreviousDay,
    required this.onPickDate,
    required this.onNextDay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _compactIconButton(
          icon: LucideIcons.chevron_left,
          onPressed: onPreviousDay,
        ),
        Flexible(
          child: InkWell(
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
            onTap: onPickDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingXS,
                  vertical: DesignConstants.spacingS),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
          ),
        ),
        _compactIconButton(
          icon: LucideIcons.chevron_right,
          onPressed: onNextDay,
        ),
      ],
    );
  }

  Widget _compactIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 48),
      onPressed: onPressed,
    );
  }
}

class _MealCard extends StatefulWidget {
  final String title;
  final String mealKey;
  final VoidCallback onAddFood;
  final Future<void> Function(TrackedFoodItem) onEditFood;
  final Future<void> Function(int) onDeleteFood;
  final Future<void> Function(List<TrackedFoodItem>, AppLocalizations)
      onSaveAsTemplate;

  const _MealCard({
    super.key,
    required this.title,
    required this.mealKey,
    required this.onAddFood,
    required this.onEditFood,
    required this.onDeleteFood,
    required this.onSaveAsTemplate,
  });

  @override
  State<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<_MealCard> {
  bool _isOpen = false;

  bool _listEquals(List<TrackedFoodItem> a, List<TrackedFoodItem> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].entry.id != b[i].entry.id ||
          a[i].entry.quantityInGrams != b[i].entry.quantityInGrams ||
          a[i].entry.timestamp != b[i].entry.timestamp ||
          a[i].item.barcode != b[i].item.barcode ||
          a[i].item.calories != b[i].item.calories) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Selector<DiaryViewModel, List<TrackedFoodItem>>(
      selector: (context, vm) => vm.entriesByMeal[widget.mealKey] ?? const [],
      shouldRebuild: (prev, next) => !_listEquals(prev, next),
      builder: (context, items, child) {
        final mealMacros = _MealMacros();
        for (var item in items) {
          final factor = item.entry.quantityInGrams / 100.0;
          mealMacros.calories += (item.item.calories * factor).toDouble();
          mealMacros.protein += (item.item.protein * factor).toDouble();
          mealMacros.carbs += (item.item.carbs * factor).toDouble();
          mealMacros.fat += (item.item.fat * factor).toDouble();
        }

        final solidItems = items.where((item) {
          final fi = item.item;
          return fi.isLiquid != true && !fi.isFluid;
        }).toList();

        return RepaintBoundary(
          child: AppCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => setState(() {
                    _isOpen = !_isOpen;
                  }),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(widget.title,
                              style: theme.textTheme.titleMedium)),
                      Icon(_isOpen
                          ? LucideIcons.chevron_up
                          : LucideIcons.chevron_down),
                      const SizedBox(width: DesignConstants.spacingXS),
                      IconButton(
                        icon: const Icon(LucideIcons.circle_plus),
                        color: theme.colorScheme.primary,
                        onPressed: widget.onAddFood,
                        tooltip: l10n.addFoodOption,
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: DesignConstants.spacingXS),
                  MacroBadgeRow(
                    kcal: mealMacros.calories.round(),
                    protein: mealMacros.protein,
                    carbs: mealMacros.carbs,
                    fat: mealMacros.fat,
                    useBadges:
                        context.read<ThemeService>().useColorfulMacroBadges,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                AnimatedCrossFade(
                  crossFadeState: _isOpen
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: DesignConstants.expandCollapseDuration,
                  firstChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (items.isNotEmpty) const Divider(height: 16),
                      ...items.map(
                        (item) => FoodEntryTile(
                          trackedItem: item,
                          onEdit: widget.onEditFood,
                          onDelete: widget.onDeleteFood,
                        ),
                      ),
                      if (solidItems.isNotEmpty) ...[
                        const SizedBox(height: DesignConstants.spacingXS),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: DesignConstants.spacingXS,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: theme.colorScheme.primary,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () =>
                              widget.onSaveAsTemplate(solidItems, l10n),
                          child: Text(l10n.saveMealTemplateShortcut),
                        ),
                      ],
                    ],
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FluidsCard extends StatefulWidget {
  final VoidCallback onAddFluid;
  final Future<void> Function(FluidEntry) onEditFluid;
  final Future<void> Function(int) onDeleteFluid;

  const _FluidsCard({
    required this.onAddFluid,
    required this.onEditFluid,
    required this.onDeleteFluid,
  });

  @override
  State<_FluidsCard> createState() => _FluidsCardState();
}

class _FluidsCardState extends State<_FluidsCard> {
  bool _isOpen = false;

  bool _fluidListEquals(List<FluidEntry> a, List<FluidEntry> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].quantityInMl != b[i].quantityInMl ||
          a[i].timestamp != b[i].timestamp ||
          a[i].name != b[i].name ||
          a[i].kcal != b[i].kcal ||
          a[i].sugarPer100ml != b[i].sugarPer100ml ||
          a[i].caffeinePer100ml != b[i].caffeinePer100ml) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Selector<DiaryViewModel, List<FluidEntry>>(
      selector: (context, vm) => vm.fluidEntries,
      shouldRebuild: (prev, next) => !_fluidListEquals(prev, next),
      builder: (context, fluids, child) {
        return RepaintBoundary(
          child: AppCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => setState(() {
                    _isOpen = !_isOpen;
                  }),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(l10n.waterHeader,
                              style: theme.textTheme.titleMedium)),
                      Icon(_isOpen
                          ? LucideIcons.chevron_up
                          : LucideIcons.chevron_down),
                      const SizedBox(width: DesignConstants.spacingXS),
                      IconButton(
                        icon: const Icon(LucideIcons.circle_plus),
                        color: theme.colorScheme.primary,
                        onPressed: widget.onAddFluid,
                        tooltip: l10n.addLiquidOption,
                      ),
                    ],
                  ),
                ),
                if (fluids.isNotEmpty) ...[
                  const SizedBox(height: DesignConstants.spacingXS),
                  Builder(
                    builder: (ctx) {
                      int totalMl = 0;
                      int totalKcal = 0;
                      double totalSugar = 0;
                      double totalCaffeine = 0;
                      for (var entry in fluids) {
                        totalMl += entry.quantityInMl;
                        if (entry.kcal != null) totalKcal += entry.kcal!;
                        if (entry.sugarPer100ml != null) {
                          totalSugar +=
                              (entry.sugarPer100ml! / 100) * entry.quantityInMl;
                        }
                        if (entry.caffeinePer100ml != null) {
                          totalCaffeine += (entry.caffeinePer100ml! / 100) *
                              entry.quantityInMl;
                        }
                      }
                      return MacroBadgeRow(
                        kcal: totalKcal.round(),
                        sugar: totalSugar,
                        caffeine: totalCaffeine,
                        waterMl: totalMl,
                        useBadges:
                            ctx.read<ThemeService>().useColorfulMacroBadges,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
                AnimatedCrossFade(
                  crossFadeState: _isOpen
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: DesignConstants.expandCollapseDuration,
                  firstChild: Column(
                    children: [
                      if (fluids.isNotEmpty) const Divider(height: 16),
                      ...fluids.map(
                        (entry) => FluidEntryTile(
                          entry: entry,
                          onEdit: widget.onEditFluid,
                          onDelete: widget.onDeleteFluid,
                        ),
                      ),
                    ],
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
