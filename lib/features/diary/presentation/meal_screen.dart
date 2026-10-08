import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../data/database_helper.dart';
import '../data/sources/product_local_data_source.dart';
import '../../../generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../services/theme_service.dart';
import '../../../services/base_food_language_service.dart';
import '../domain/models/food_entry.dart';
import '../domain/models/food_item.dart';
import '../domain/models/meal_entry.dart';
import '../../supplements/domain/models/supplement.dart';
import '../../supplements/domain/models/supplement_log.dart';
import '../../../services/haptic_feedback_service.dart';
import 'food_detail_screen.dart';
import 'general_food_selection_screen.dart';
import '../../../widgets/common/common.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/global_app_bar.dart';

import '../../../widgets/common/macro_badge_row.dart';
import '../../../widgets/common/swipe_action_background.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:uuid/uuid.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../sharing/share_service.dart';
import 'widgets/confirm_log_meal_bottom_sheet.dart';

/// A comprehensive screen for viewing and editing a meal and its ingredients.
///
/// Displays nutritional totals for the meal and allows users to add, remove,
/// or adjust quantities of individual ingredients. Meals can be added directly
/// to the daily diary from this screen.
class MealScreen extends StatefulWidget {
  /// The meal data as a map containing 'id', 'name', and 'notes'.
  final Map<String, dynamic> meal; // expected: {id, name, notes}
  /// Whether to open the screen in edit mode initially.
  final bool startInEdit;

  /// Optional pre-filled food items from a diary section (e.g. Breakfast).
  /// Each entry must contain 'barcode' (String) and 'quantity_in_grams' (int).
  /// When provided the screen opens in edit mode with these rows populated and
  /// the name/notes fields left blank so the user can author their own title.
  final List<Map<String, dynamic>>? prefillItems;

  const MealScreen({
    super.key,
    required this.meal,
    this.startInEdit = false,
    this.prefillItems,
  });

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _servingsCtrl;
  late TextEditingController _cookedWeightCtrl;
  late int? _previewServingCount;
  late int? _previewCookedWeight;
  late String _previewWeightBasis;
  bool _editMode = false;
  bool _saving = false;

  List<Map<String, dynamic>> _items = [];
  bool _loadingItems = true;

  // Totals (recomputed from `_items` whenever data changes).
  int _totalKcal = 0;
  double _totalC = 0, _totalF = 0, _totalP = 0;

  double get _previewScale {
    final savedServings = _positiveIntOrNull(_servingsCtrl.text);
    if (_previewServingCount != null) {
      return _previewServingCount! / (savedServings ?? 1);
    }
    final savedCookedWeight = _positiveIntOrNull(_cookedWeightCtrl.text);
    if (savedCookedWeight != null &&
        savedCookedWeight > 0 &&
        _previewCookedWeight != null) {
      return _previewCookedWeight! / savedCookedWeight;
    }
    return 1;
  }

  @override
  void initState() {
    super.initState();
    // Open in edit mode whenever prefill data is provided or startInEdit is set.
    _editMode = widget.startInEdit || widget.prefillItems != null;
    // Leave name/notes blank when launched via the diary shortcut so the user
    // must consciously choose a template title.
    _nameCtrl = TextEditingController(
      text: widget.prefillItems != null
          ? ''
          : (widget.meal['name'] as String? ?? ''),
    );
    _notesCtrl = TextEditingController(
      text: widget.prefillItems != null
          ? ''
          : (widget.meal['notes'] as String? ?? ''),
    );
    _servingsCtrl = TextEditingController(
      text: widget.meal['serving_count']?.toString() ?? '',
    );
    _cookedWeightCtrl = TextEditingController(
      text: widget.meal['cooked_weight_in_grams']?.toString() ?? '',
    );
    _previewServingCount = _positiveIntOrNull(_servingsCtrl.text);
    _previewCookedWeight = _positiveIntOrNull(_cookedWeightCtrl.text);
    _previewWeightBasis = _previewCookedWeight == null ? 'raw' : 'cooked';
    _loadItems();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _servingsCtrl.dispose();
    _cookedWeightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);

    if (widget.prefillItems != null) {
      // Launched via the diary shortcut — use supplied items directly and skip
      // the DB fetch (the meal row has just been created and has no items yet).
      _items = List<Map<String, dynamic>>.from(widget.prefillItems!);
    } else {
      final id = widget.meal['id'] as int;
      final rows = await DatabaseHelper.instance.getMealItems(id);
      _items = List<Map<String, dynamic>>.from(rows);
    }

    await _recomputeTotals(); // Initial totals.
    if (mounted) setState(() => _loadingItems = false);
  }

  /// Recomputes aggregate kcal / carbs / fat / protein totals.
  Future<void> _recomputeTotals() async {
    int kcal = 0;
    double c = 0, f = 0, p = 0;

    for (final it in _items) {
      final bc = it['barcode'] as String;
      final qty = (it['quantity_in_grams'] as num?)?.toDouble() ?? 0.0;
      final fi = await ProductLocalDataSource.instance.getProductByBarcode(bc);
      if (fi == null) continue;

      final factor = qty / 100.0;
      final itemKcal = (fi.calories.toDouble()) * factor;
      final itemC = (fi.carbs) * factor;
      final itemF = (fi.fat) * factor;
      final itemP = (fi.protein) * factor;

      kcal += itemKcal.round();
      c += itemC;
      f += itemF;
      p += itemP;
    }

    _totalKcal = kcal;
    _totalC = c;
    _totalF = f;
    _totalP = p;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final canSave =
        _nameCtrl.text.trim().isNotEmpty && _items.isNotEmpty && !_saving;
    final displayScale = _editMode ? 1.0 : _previewScale;

    // Compute top padding for content shown beneath GlobalAppBar.
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    // Floating action button configuration by mode.
    Widget? fab;
    if (_editMode) {
      fab = GlassFab(
        label: l10n.mealAddIngredient,
        onPressed: _addIngredientFlow,
      );
    } else {
      if (_items.isNotEmpty) {
        fab = GlassFab(
          label: l10n.mealsAddToDiary,
          onPressed: _addMealToDiaryFlow,
        );
      } else {
        fab = null;
      }
    }

    return Scaffold(
      // Extend body behind app bar to support the glass effect.
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: GlobalAppBar(
        // Use GlobalAppBar for consistent app-wide behavior.
        title: _editMode
            ? l10n.mealsEdit
            : (_nameCtrl.text.isNotEmpty
                ? _nameCtrl.text
                : l10n.mealsViewTitle),
        actions: [
          if (_editMode)
            TextButton(
              onPressed: canSave ? _save : null,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.save,
                      style: TextStyle(
                        color: canSave
                            ? theme.colorScheme.primary
                            : theme.disabledColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            )
          else ...[
            IconButton(
              tooltip: l10n.mealsEdit,
              onPressed: () => setState(() => _editMode = true),
              icon: const Icon(LucideIcons.pencil),
            ),
            IconButton(
              tooltip: l10n.share,
              onPressed: () => const ShareService().showRecipeShareSheet(
                context: context,
                meal: widget.meal,
              ),
              icon: Icon(DesignConstants.adaptiveShareIcon),
            ),
          ],
        ],
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          _loadingItems
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  // Apply top padding so list content clears the app bar.
                  padding: EdgeInsets.fromLTRB(16, 12 + topPadding, 16, 96),
                  children: [
                    // Name and notes section.
                    _editMode
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _nameCtrl,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: l10n.mealNameLabel,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _servingsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l10n.mealServingCountLabel,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 12, top: 6, bottom: 12),
                                child: Text(l10n.mealServingCountHint,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                              ),
                              TextField(
                                controller: _cookedWeightCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l10n.mealCookedWeightLabel,
                                  suffixText: l10n.unit_grams,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 12, top: 6, bottom: 12),
                                child: Text(l10n.mealCookedWeightHint,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant),
                                    maxLines: 2),
                              ),
                              TextField(
                                controller: _notesCtrl,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: l10n.mealNotesLabel,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSettingsRow(
                                title: _previewServingCount != null
                                    ? l10n.mealServingsSummary(
                                        '$_previewServingCount')
                                    : l10n.mealServingCountLabel,
                                subtitle: [
                                  if (_previewServingCount case final servings?
                                      when servings > 0)
                                    '${(_totalKcal * displayScale).round()} ${l10n.unit_kcal} ${l10n.mealTotalNutrientsLabel}',
                                  if (_previewWeightBasis == 'cooked' &&
                                      _previewCookedWeight != null &&
                                      _previewCookedWeight! > 0)
                                    l10n.mealCookedWeightSummary(
                                        '$_previewCookedWeight'),
                                  if (_previewWeightBasis == 'raw')
                                    '${(_items.fold<int>(0, (sum, item) => sum + ((item['quantity_in_grams'] as num?)?.round() ?? 0)) * displayScale).round()} ${l10n.unit_grams} ${l10n.mealWeightBasisRaw}',
                                ].join(' · '),
                                onTap: _editServingDetails,
                                trailing: const Icon(LucideIcons.chevron_right),
                              ),
                              if (_notesCtrl.text.isNotEmpty)
                                AppSettingsRow(
                                    title: l10n.mealNotesLabel,
                                    subtitle: _notesCtrl.text),
                            ],
                          ),

                    const SizedBox(height: 18),

                    // === Nutrients (total sum) ===
                    AppSectionHeader(
                      title: !_editMode && displayScale != 1
                          ? l10n.mealTotalNutrientsLabel
                          : l10n.nutritionSectionLabel,
                    ),
                    AppCardContainer(
                      child: Skeletonizer(
                        enabled: _editMode && _items.isEmpty,
                        child: MacroBadgeRow(
                          kcal: (_editMode && _items.isEmpty)
                              ? 0
                              : (_items.isEmpty
                                  ? null
                                  : (_totalKcal * displayScale).round()),
                          protein: (_editMode && _items.isEmpty)
                              ? 0.0
                              : (_items.isEmpty
                                  ? null
                                  : _totalP * displayScale),
                          carbs: (_editMode && _items.isEmpty)
                              ? 0.0
                              : (_items.isEmpty
                                  ? null
                                  : _totalC * displayScale),
                          fat: (_editMode && _items.isEmpty)
                              ? 0.0
                              : (_items.isEmpty
                                  ? null
                                  : _totalF * displayScale),
                          useBadges: Provider.of<ThemeService>(context)
                              .useColorfulMacroBadges,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // === Ingredients ===
                    AppSectionHeader(title: l10n.ingredientsCapsLock),

                    if (_items.isEmpty)
                      if (_editMode)
                        SizedBox(
                          height: 480,
                          child: ColdStartEmptyState(
                            icon: LucideIcons.apple,
                            title: l10n.mealIngredientsTitle,
                            subtitle: l10n.emptyCategory,
                            showArrow: false,
                            customEndXOffset: 110.0,
                            customTargetYOffset:
                                110.0 + MediaQuery.paddingOf(context).bottom,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            l10n.emptyCategory,
                            textAlign: TextAlign.center,
                          ),
                        )
                    else
                      Column(
                        children: List.generate(_items.length, (i) {
                          final originalItem = _items[i];
                          final it = !_editMode && displayScale != 1
                              ? {
                                  ...originalItem,
                                  'quantity_in_grams':
                                      ((originalItem['quantity_in_grams']
                                                      as num)
                                                  .toDouble() *
                                              displayScale)
                                          .round(),
                                }
                              : originalItem;
                          return _IngredientCard(
                            key: ValueKey('ing_$i'),
                            item: it,
                            editMode: _editMode,
                            showPerIngredientMacros: !_editMode,
                            onQtyChanged: (val) async {
                              _items[i]['quantity_in_grams'] = val;
                              await _recomputeTotals();
                              if (mounted) setState(() {});
                            },
                            onDelete: () async {
                              final ok = await showDeleteConfirmation(
                                context,
                                title: l10n.deleteConfirmTitle,
                                content: l10n.deleteConfirmContent,
                              );

                              if (ok) {
                                setState(() => _items.removeAt(i));
                                await _recomputeTotals();
                                if (mounted) setState(() {});
                              }
                            },
                          );
                        }),
                      ),
                  ],
                ),
          if (fab != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: DesignConstants.bottomVignetteHeight,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: DesignConstants.bottomVignetteGradient(
                      Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _items.isEmpty) return;

    setState(() => _saving = true);
    try {
      final mealId = widget.meal['id'] as int;
      await DatabaseHelper.instance.updateMeal(
        mealId,
        name: name,
        notes: _notesCtrl.text.trim(),
        servingCount: _positiveIntOrNull(_servingsCtrl.text),
        cookedWeightInGrams: _positiveIntOrNull(_cookedWeightCtrl.text),
      );
      await DatabaseHelper.instance.clearMealItems(mealId);
      for (final it in _items) {
        final grams = (it['quantity_in_grams'] as num?)?.toInt() ?? 0;
        await DatabaseHelper.instance.addMealItem(
          mealId: mealId,
          barcode: it['barcode'] as String,
          amount: grams.toDouble(),
        );
      }
      if (mounted) {
        setState(() {
          _previewServingCount = _positiveIntOrNull(_servingsCtrl.text);
          _previewCookedWeight = _positiveIntOrNull(_cookedWeightCtrl.text);
          _editMode = false;
        });
        HapticFeedbackService.instance.confirmationFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mealSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int? _positiveIntOrNull(String value) {
    final parsed = int.tryParse(value.trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  Future<void> _editServingDetails() async {
    final originalServings = _positiveIntOrNull(_servingsCtrl.text);
    final originalCookedWeight = _positiveIntOrNull(_cookedWeightCtrl.text);
    final originalRawWeight = _items.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity_in_grams'] as num?)?.round() ?? 0),
    );
    final result = await showGlassBottomMenu<_RecipePreviewValues>(
      context: context,
      contentBuilder: (sheetContext, close) => _RecipePreviewEditor(
        initialServings: _previewServingCount ?? originalServings ?? 1,
        initialCookedWeight: _previewCookedWeight,
        originalServings: originalServings,
        originalCookedWeight: originalCookedWeight,
        originalRawWeight: originalRawWeight,
        initialWeightBasis: _previewWeightBasis,
        totalCalories: _totalKcal,
        onClose: close,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _previewServingCount = result.servings;
        _previewCookedWeight = result.cookedWeight;
        _previewWeightBasis = result.weightBasis;
      });
    }
  }
  // In lib/screens/meal_screen.dart

  Future<void> _addIngredientFlow() async {
    final l10n = AppLocalizations.of(context)!;
    final qtyCtrl = TextEditingController(text: '100');

    // 1. Navigate to general food selection screen (AddFoodScreen) in selectionMode
    final pickedProduct = await Navigator.of(context).push<FoodItem?>(
      MaterialPageRoute(
        builder: (_) => const GeneralFoodSelectionScreen(),
      ),
    );

    if (pickedProduct == null) return;

    final String barcode = pickedProduct.barcode;
    int quantity = -1;

    // Ask for amount
    final displayName =
        pickedProduct.name.isNotEmpty ? pickedProduct.name : barcode;
    if (!mounted) return;

    final qtyResult = await showGlassBottomMenu<int?>(
      context: context,
      title: displayName,
      contentBuilder: (qtyCtx, closeQty) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.mealIngredientAmountLabel),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                suffixText: '${l10n.unit_grams}/${l10n.unit_milliliters}',
              ),
              onSubmitted: (val) {
                final q = int.tryParse(val);
                Navigator.of(qtyCtx).pop(q);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    onPressed: () {
                      Navigator.of(qtyCtx).pop(null);
                    },
                    label: l10n.cancel,
                    tooltip: l10n.cancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.primary(
                    onPressed: () {
                      final val = int.tryParse(qtyCtrl.text);
                      Navigator.of(qtyCtx).pop(val);
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

    if (qtyResult != null && qtyResult > 0) {
      quantity = qtyResult;
    } else {
      return; // Canceled at amount step
    }

    // Add to list
    if (quantity > 0) {
      setState(() {
        _items.add({'barcode': barcode, 'quantity_in_grams': quantity});
      });
      await _recomputeTotals();
      if (mounted) setState(() {});
    }
  }

  /// Logs the current meal as individual FoodEntries in the diary.
  Future<void> _addMealToDiaryFlow() async {
    final l10n = AppLocalizations.of(context)!;
    final products = <String, FoodItem>{};
    for (final item in _items) {
      final barcode = item['barcode'] as String;
      final product =
          await ProductLocalDataSource.instance.getProductByBarcode(barcode);
      if (product != null) products[barcode] = product;
    }
    if (!mounted) return;

    final storedServings = _positiveIntOrNull(_servingsCtrl.text);
    final storedCookedWeight = _positiveIntOrNull(_cookedWeightCtrl.text);
    final portionScale = storedServings != null && storedServings > 0
        ? (_previewServingCount ?? storedServings) / storedServings
        : _previewServingCount != null
            ? _previewServingCount!.toDouble()
            : storedCookedWeight != null && storedCookedWeight > 0
                ? (_previewCookedWeight ?? storedCookedWeight) /
                    storedCookedWeight
                : 1.0;
    final loggingItems = _items.map((item) {
      final copy = Map<String, dynamic>.from(item);
      final grams = (item['quantity_in_grams'] as num?)?.toDouble() ?? 0;
      copy['quantity_in_grams'] = (grams * portionScale).round();
      return copy;
    }).toList();

    await showGlassBottomMenu<bool>(
      context: context,
      contentBuilder: (sheetContext, close) => ConfirmLogMealBottomSheet(
        mealName: _nameCtrl.text,
        rawItems: loggingItems,
        products: products,
        recipeCookedWeightInGrams: _previewCookedWeight,
        initialWeightBasis: _previewWeightBasis,
        recipeServingCount: _previewServingCount,
        initialDate: DateTime.now(),
        initialMealType: 'mealtypeBreakfast',
        onSave: (date, mealType, quantities) async {
          final foodEntries = loggingItems.map((item) {
            final barcode = item['barcode'] as String;
            final qty = quantities[item['id']?.toString() ?? barcode] ??
                (item['quantity_in_grams'] as int);
            return FoodEntry(
              barcode: barcode,
              timestamp: date,
              quantityInGrams: qty,
              mealType: mealType,
            );
          }).toList();
          final entryIds =
              await DatabaseHelper.instance.insertMealEntryWithFoodEntries(
            MealEntry(
              id: const Uuid().v4(),
              title: _nameCtrl.text,
              consumedAt: date,
              mealType: mealType,
              source: 'template',
            ),
            foodEntries,
            telemetrySource: FoodLogSource.meal,
          );
          for (var i = 0; i < foodEntries.length; i++) {
            final entry = foodEntries[i];
            final entryId = entryIds[i];
            final qty = entry.quantityInGrams;
            final product = products[entry.barcode];
            final caffeinePer100ml = product?.caffeineMgPer100ml;
            if (product?.isLiquid == true &&
                caffeinePer100ml != null &&
                caffeinePer100ml > 0) {
              await _logCaffeineDose(
                caffeinePer100ml * (qty / 100.0),
                date,
                foodEntryId: entryId,
              );
            }
          }
          if (!mounted) return;
          HapticFeedbackService.instance.confirmationFeedback();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.mealAddedToDiarySuccess)),
          );
        },
      ),
    );
  }

  Future<void> _logCaffeineDose(
    double doseMg,
    DateTime timestamp, {
    int? foodEntryId,
  }) async {
    if (doseMg <= 0) return;

    final supplements = await DatabaseHelper.instance.getAllSupplements();
    final caffeine = supplements.firstWhere(
      (s) => s.isCaffeine,
      orElse: () => Supplement(
        name: 'Caffeine',
        defaultDose: 100,
        unit: 'mg',
        dailyLimit: 400,
        code: 'caffeine',
        isBuiltin: true,
      ),
    );

    final caffeineId = caffeine.id ??
        (await DatabaseHelper.instance.insertSupplement(caffeine));

    await DatabaseHelper.instance.insertSupplementLog(
      SupplementLog(
        supplementId: caffeineId,
        dose: doseMg,
        unit: 'mg',
        timestamp: timestamp,
        sourceFoodEntryId: foodEntryId,
      ),
    );
  }
}

class _RecipePreviewValues {
  final int? servings;
  final int? cookedWeight;
  final String weightBasis;

  const _RecipePreviewValues(
      {required this.servings,
      required this.cookedWeight,
      required this.weightBasis});
}

class _RecipePreviewEditor extends StatefulWidget {
  final int? initialServings;
  final int? initialCookedWeight;
  final int? originalServings;
  final int? originalCookedWeight;
  final int originalRawWeight;
  final String initialWeightBasis;
  final int totalCalories;
  final VoidCallback onClose;

  const _RecipePreviewEditor({
    required this.initialServings,
    required this.initialCookedWeight,
    required this.originalServings,
    required this.originalCookedWeight,
    required this.originalRawWeight,
    required this.initialWeightBasis,
    required this.totalCalories,
    required this.onClose,
  });

  @override
  State<_RecipePreviewEditor> createState() => _RecipePreviewEditorState();
}

class _RecipePreviewEditorState extends State<_RecipePreviewEditor> {
  late final TextEditingController _servingsCtrl;
  late final TextEditingController _weightCtrl;
  late int? _servings;
  late int? _cookedWeight;
  late String _weightBasis;

  @override
  void initState() {
    super.initState();
    _servings = widget.initialServings;
    _cookedWeight = widget.initialCookedWeight;
    _weightBasis = widget.initialWeightBasis;
    _servingsCtrl = TextEditingController(text: _servings?.toString() ?? '');
    _weightCtrl = TextEditingController(text: _initialWeight.toString());
  }

  @override
  void dispose() {
    _servingsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  int? _positiveInt(String value) {
    final parsed = int.tryParse(value.trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  double get _scale {
    final baseServings = widget.originalServings ?? 1;
    if (_servings != null && baseServings > 0) return _servings! / baseServings;
    final baseWeight = _baselineWeight;
    final amount = _positiveInt(_weightCtrl.text);
    return amount != null && baseWeight > 0 ? amount / baseWeight : 1;
  }

  int get _baselineWeight => _weightBasis == 'cooked'
      ? (widget.originalCookedWeight ?? widget.originalRawWeight)
      : widget.originalRawWeight;

  int get _initialWeight {
    if (_weightBasis == 'cooked' && widget.initialCookedWeight != null) {
      return widget.initialCookedWeight!;
    }
    final servings = widget.initialServings ?? widget.originalServings ?? 1;
    return (_baselineWeight * servings / (widget.originalServings ?? 1))
        .round();
  }

  void _updateFromServings(int? servings) {
    setState(() {
      _servings = servings;
      if (servings != null) {
        final scale = servings / (widget.originalServings ?? 1);
        final weight = (_baselineWeight * scale).round();
        _weightCtrl.text = '$weight';
        if (_weightBasis == 'cooked') {
          _cookedWeight = weight;
        } else if (widget.originalCookedWeight != null) {
          _cookedWeight = (widget.originalCookedWeight! * scale).round();
        } else {
          _cookedWeight = null;
        }
      } else {
        _weightCtrl.clear();
      }
    });
  }

  void _updateFromWeight(int? weight) {
    setState(() {
      if (weight == null) {
        _servings = null;
        _cookedWeight = null;
        return;
      }
      final baseWeight = _baselineWeight;
      final baseServings = widget.originalServings ?? 1;
      _servings = baseWeight > 0
          ? (baseServings * weight / baseWeight).round().clamp(1, 1 << 31)
          : baseServings;
      final scale = _servings! / baseServings;
      if (_weightBasis == 'cooked') {
        _cookedWeight = weight;
      } else if (widget.originalCookedWeight != null) {
        _cookedWeight = (widget.originalCookedWeight! * scale).round();
      } else {
        _cookedWeight = null;
      }
      _servingsCtrl.text = _servings?.toString() ?? '';
    });
  }

  InputDecoration _decoration(String label, {String? suffix}) =>
      InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _servingsCtrl,
          keyboardType: TextInputType.number,
          decoration: _decoration(l10n.mealServingCountLabel),
          onChanged: (value) => _updateFromServings(_positiveInt(value)),
        ),
        const SizedBox(height: DesignConstants.spacingM),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: _decoration(
                  _weightBasis == 'raw'
                      ? l10n.mealTotalAmountLabel
                      : l10n.mealCookedWeightLabel,
                  suffix: l10n.unit_grams,
                ),
                onChanged: (value) => _updateFromWeight(_positiveInt(value)),
              ),
            ),
            const SizedBox(width: DesignConstants.spacingS),
            Expanded(
              flex: 2,
              child: PlatformAdaptiveDropdownFormField<String>(
                initialValue: _weightBasis,
                decoration: _decoration(l10n.mealWeightBasisLabel),
                items: [
                  DropdownMenuItem(
                      value: 'raw', child: Text(l10n.mealWeightBasisRaw)),
                  DropdownMenuItem(
                      value: 'cooked', child: Text(l10n.mealWeightBasisCooked)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _weightBasis = value;
                    final scale = (_servings ?? widget.originalServings ?? 1) /
                        (widget.originalServings ?? 1);
                    final amount = (_baselineWeight * scale).round();
                    _weightCtrl.text = '$amount';
                    if (_weightBasis == 'cooked') {
                      _cookedWeight = amount;
                    } else if (widget.originalCookedWeight != null) {
                      _cookedWeight =
                          (widget.originalCookedWeight! * scale).round();
                    } else {
                      _cookedWeight = null;
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Text(
          '${(widget.totalCalories * _scale).round()} ${l10n.unit_kcal} ${l10n.mealTotalNutrientsLabel}',
        ),
        const SizedBox(height: DesignConstants.spacingL),
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                onPressed: widget.onClose,
                label: l10n.cancel,
                tooltip: l10n.cancel,
              ),
            ),
            const SizedBox(width: DesignConstants.spacingS),
            Expanded(
              child: AppButton.primary(
                onPressed: () => Navigator.of(context).pop(
                  _RecipePreviewValues(
                    servings: _servings,
                    cookedWeight: _cookedWeight,
                    weightBasis: _weightBasis,
                  ),
                ),
                label: l10n.doneButtonLabel,
                tooltip: l10n.doneButtonLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Single ingredient as SummaryCard.
/// - View mode: name (tappable) + small kcal on the right + C/F/P below.
/// - Edit mode: amount field on the right; swipe left = delete.
class _IngredientCard extends StatelessWidget {
  final Map<String, dynamic> item; // { barcode, quantity_in_grams }
  final bool editMode;
  final bool showPerIngredientMacros;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onDelete;

  const _IngredientCard({
    super.key,
    required this.item,
    required this.editMode,
    required this.showPerIngredientMacros,
    required this.onQtyChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bc = item['barcode'] as String;
    final qty = (item['quantity_in_grams'] as num?)?.toDouble() ?? 0.0;
    final themeService = Provider.of<ThemeService>(context);

    Widget buildCard(FoodItem? fi) {
      final name = fi != null
          ? (() {
              final baseFoodLang = BaseFoodLanguageService.resolveLanguageCode(
                choice: themeService.baseFoodLanguage,
                context: context,
              );
              return fi.source == FoodItemSource.base
                  ? fi.getLocalizedName(context, languageCode: baseFoodLang)
                  : fi.getLocalizedName(context);
            })()
          : bc;
      final unit =
          (fi?.isLiquid == true) ? l10n.unit_milliliters : l10n.unit_grams;

      // per-ingredient macros & kcal
      int kcal = 0;
      double c = 0, f = 0, p = 0;
      if (fi != null) {
        final factor = qty / 100.0;
        kcal = ((fi.calories) * factor).round();
        c = (fi.carbs) * factor;
        f = (fi.fat) * factor;
        p = (fi.protein) * factor;
      }

      final titleWidget = InkWell(
        onTap: () {
          if (fi != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FoodDetailScreen(foodItem: fi)),
            );
          }
        },
        child: Text(
          name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      final trailingView = Text(
        fi == null ? '–' : '$kcal ${l10n.unit_kcal}',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      );

      final trailingEdit = SizedBox(
        width: 96,
        child: TextFormField(
          initialValue: '${qty.toInt()}',
          textAlign: TextAlign.right,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: InputDecoration(
            isDense: true,
            suffixText: unit,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (v) {
            final parsed = int.tryParse(v.trim());
            if (parsed != null && parsed >= 0) onQtyChanged(parsed);
          },
        ),
      );

      return AppCardContainer(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: titleWidget,
          subtitle: (fi != null)
              ? Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: themeService.useColorfulMacroBadges
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!editMode)
                              Text(
                                '${qty.toInt()}$unit',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            if (!editMode) const SizedBox(height: 4),
                            MacroBadgeRow(
                              kcal: editMode ? kcal : null,
                              protein: p,
                              carbs: c,
                              fat: f,
                              useBadges: true,
                            ),
                          ],
                        )
                      : AppMetadataRow(
                          items: [
                            if (editMode) '$kcal ${l10n.unit_kcal}',
                            if (!editMode) '${qty.toInt()}$unit',
                            '${p.toStringAsFixed(1)}g P',
                            '${c.toStringAsFixed(1)}g C',
                            '${f.toStringAsFixed(1)}g F',
                          ],
                        ),
                )
              : null,
          trailing: editMode ? trailingEdit : trailingView,
        ),
      );
    }

    final card = FutureBuilder<FoodItem?>(
      future: ProductLocalDataSource.instance.getProductByBarcode(bc),
      builder: (_, snap) => buildCard(snap.data),
    );

    if (!editMode) return card;

    // Edit mode: swipe left = delete
    return Dismissible(
      key: ValueKey('ing_${item['barcode']}_${item['quantity_in_grams']}'),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: const SwipeActionBackground(
        color: DesignConstants.brandRedColor,
        icon: LucideIcons.trash,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
        return false;
      },
      child: card,
    );
  }
}
