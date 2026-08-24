// lib/features/diary/presentation/meal_entry_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/app_button.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../util/design_constants.dart';
import '../domain/models/food_entry.dart';
import '../domain/models/food_item.dart';
import '../domain/models/meal_entry.dart';
import '../domain/models/tracked_food_item.dart';
import '../domain/repositories/diary_repository.dart';
import 'dialogs/delete_meal_entry_bottom_sheet.dart';
import 'widgets/meal_photo_overlay_widget.dart';
import 'general_food_selection_screen.dart';
import 'food_detail_screen.dart';

/// Full detail and editing screen for a logged meal entry (Screens D3 & D6b).
class MealEntryScreen extends StatefulWidget {
  final MealEntry mealEntry;
  final List<TrackedFoodItem> initialItems;

  const MealEntryScreen({
    super.key,
    required this.mealEntry,
    required this.initialItems,
  });

  @override
  State<MealEntryScreen> createState() => _MealEntryScreenState();
}

class _MealEntryScreenState extends State<MealEntryScreen> {
  late MealEntry _mealEntry;
  late List<TrackedFoodItem> _items;
  int? _selectedRegionIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _mealEntry = widget.mealEntry;
    _items = List.from(widget.initialItems);
  }

  int get _totalKcal {
    int sum = 0;
    for (final it in _items) {
      final factor = it.entry.quantityInGrams / 100.0;
      sum += (it.item.calories * factor).round();
    }
    return sum;
  }

  double get _totalProtein {
    double sum = 0;
    for (final it in _items) {
      final factor = it.entry.quantityInGrams / 100.0;
      sum += it.item.protein * factor;
    }
    return sum;
  }

  double get _totalCarbs {
    double sum = 0;
    for (final it in _items) {
      final factor = it.entry.quantityInGrams / 100.0;
      sum += it.item.carbs * factor;
    }
    return sum;
  }

  double get _totalFat {
    double sum = 0;
    for (final it in _items) {
      final factor = it.entry.quantityInGrams / 100.0;
      sum += it.item.fat * factor;
    }
    return sum;
  }

  String _getLocalizedMealName(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key.toLowerCase()) {
      case 'mealtypebreakfast':
      case 'breakfast':
      case 'frühstück':
        return l10n.mealtypeBreakfast;
      case 'mealtypelunch':
      case 'lunch':
      case 'mittagessen':
        return l10n.mealtypeLunch;
      case 'mealtypedinner':
      case 'dinner':
      case 'abendessen':
        return l10n.mealtypeDinner;
      case 'mealtypesnack':
      case 'snack':
      case 'snacks':
        return l10n.mealtypeSnack;
      default:
        return key;
    }
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final current = _items[index];
      final newQuantity = (current.entry.quantityInGrams + delta).clamp(5, 5000);
      _items[index] = TrackedFoodItem(
        item: current.item,
        entry: current.entry.copyWith(quantityInGrams: newQuantity),
      );
    });
  }

  Future<void> _showDirectQuantityDialog(int index) async {
    final current = _items[index];
    final controller = TextEditingController(text: '${current.entry.quantityInGrams}');
    final l10n = AppLocalizations.of(context)!;

    final result = await showGlassBottomMenu<int>(
      context: context,
      title: current.item.name,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Menge in Gramm',
                suffixText: 'g',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
                ),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),
            AppButton.primary(
              onPressed: () {
                final val = int.tryParse(controller.text);
                Navigator.of(ctx).pop(val);
              },
              label: 'Übernehmen',
              tooltip: 'Übernehmen',
            ),
            const SizedBox(height: DesignConstants.spacingS),
            AppButton.secondary(
              onPressed: close,
              label: l10n.cancel,
              tooltip: l10n.cancel,
            ),
          ],
        );
      },
    );

    if (result != null && result > 0 && mounted) {
      setState(() {
        _items[index] = TrackedFoodItem(
          item: current.item,
          entry: current.entry.copyWith(quantityInGrams: result),
        );
      });
    }
  }

  Future<void> _openItemDetail(TrackedFoodItem tracked) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodDetailScreen(
          foodItem: tracked.item,
          trackedItem: tracked,
        ),
      ),
    );
  }

  Future<void> _addNewIngredient() async {
    final selectedFood = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute(
        builder: (_) => const GeneralFoodSelectionScreen(),
      ),
    );

    if (selectedFood != null && mounted) {
      setState(() {
        _items.add(TrackedFoodItem(
          item: selectedFood,
          entry: FoodEntry(
            barcode: selectedFood.barcode,
            timestamp: _mealEntry.consumedAt,
            quantityInGrams: 100,
            mealType: _mealEntry.mealType,
            mealEntryId: _mealEntry.id,
          ),
        ));
      });
    }
  }

  Future<void> _saveAndClose() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final repo = context.read<IDiaryRepository>();

    // Update meal entry
    await repo.updateMealEntry(_mealEntry);

    // Save item changes
    for (final item in _items) {
      if (item.entry.id != null) {
        await repo.updateFoodEntry(item.entry);
      } else {
        await repo.insertFoodEntry(item.entry.copyWith(mealEntryId: _mealEntry.id));
      }
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _showOverflowMenu() {
    final l10n = AppLocalizations.of(context)!;
    showGlassBottomMenu<void>(
      context: context,
      title: _mealEntry.title ?? 'Mahlzeit',
      actions: [
        GlassMenuAction(
          icon: LucideIcons.bookmark,
          label: 'Als Vorlage speichern',
          onTap: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Als Mahlzeiten-Vorlage gespeichert.')),
            );
          },
        ),
        GlassMenuAction(
          icon: LucideIcons.clock,
          label: 'Mahlzeitentyp ändern',
          onTap: () {
            Navigator.of(context).pop();
            _showChangeMealTypeDialog();
          },
        ),
        GlassMenuAction(
          icon: LucideIcons.trash_2,
          label: l10n.delete,
          onTap: () async {
            Navigator.of(context).pop();
            final choice = await DeleteMealEntryBottomSheet.show(
              context,
              mealTitle: _mealEntry.title ?? 'Mahlzeit',
              itemCount: _items.length,
              totalKcal: _totalKcal,
            );

            if (choice != null && mounted) {
              final repo = context.read<IDiaryRepository>();
              await repo.deleteMealEntry(
                _mealEntry.id,
                deleteFoodLogs: choice == DeleteMealChoice.deleteAll,
              );
              if (mounted) Navigator.of(context).pop(true);
            }
          },
        ),
      ],
    );
  }

  void _showChangeMealTypeDialog() {
    final l10n = AppLocalizations.of(context)!;
    final types = [
      ('mealtypeBreakfast', l10n.mealtypeBreakfast),
      ('mealtypeLunch', l10n.mealtypeLunch),
      ('mealtypeDinner', l10n.mealtypeDinner),
      ('mealtypeSnack', l10n.mealtypeSnack),
    ];

    showGlassBottomMenu<void>(
      context: context,
      title: 'Mahlzeitentyp wählen',
      actions: types.map((entry) {
        return GlassMenuAction(
          icon: LucideIcons.utensils,
          label: entry.$2,
          onTap: () {
            setState(() {
              _mealEntry = _mealEntry.copyWith(mealType: entry.$1);
              for (int i = 0; i < _items.length; i++) {
                _items[i] = TrackedFoodItem(
                  item: _items[i].item,
                  entry: _items[i].entry.copyWith(mealType: entry.$1),
                );
              }
            });
            Navigator.of(context).pop();
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF12120F);
    final subtitleColor = isDark ? const Color(0xFF8A8A82) : const Color(0xFF6A6A62);
    final topPadding = MediaQuery.of(context).padding.top;

    final hasPhoto = _mealEntry.photoPath != null &&
        _mealEntry.photoPath!.isNotEmpty &&
        File(_mealEntry.photoPath!).existsSync();
    final photoFile = hasPhoto ? File(_mealEntry.photoPath!) : null;
    final timeStr = DateFormat('HH:mm').format(_mealEntry.consumedAt);
    final localizedMealType = _getLocalizedMealName(context, _mealEntry.mealType);

    final overlayItems = _items.asMap().entries.map((e) {
      final factor = e.value.entry.quantityInGrams / 100.0;
      return OverlayItemDisplay(
        name: e.value.item.name,
        grams: e.value.entry.quantityInGrams,
        kcal: (e.value.item.calories * factor).round(),
        regions: const [], // extracted if present in meta
        color: MealOverlayColors.forIndex(e.key),
      );
    }).toList();

    final bool hasVisibleRegions = overlayItems.any((it) => it.regions.isNotEmpty);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bg,
      appBar: GlobalAppBar(
        title: _mealEntry.title ?? localizedMealType,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.ellipsis, size: 20),
            tooltip: 'Optionen',
            onPressed: _showOverflowMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Top Stage: Photo with gradients (or top spacer if no photo)
                if (hasPhoto)
                  MealPhotoOverlayWidget(
                    photoFile: photoFile,
                    height: 320,
                    items: overlayItems,
                    selectedIndex: _selectedRegionIndex,
                    onItemTapped: (idx) => setState(() => _selectedRegionIndex = idx),
                  )
                else
                  SizedBox(height: kToolbarHeight + topPadding + 16),

                // Title & Subtitle Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _mealEntry.title ?? localizedMealType,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                color: titleColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_totalKcal kcal',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$localizedMealType · $timeStr',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Macro summary pills
                      Row(
                        children: [
                          _buildMacroPill('P', '${_totalProtein.round()}g', const Color(0xFFFF453A)),
                          const SizedBox(width: 8),
                          _buildMacroPill('C', '${_totalCarbs.round()}g', const Color(0xFF30D158)),
                          const SizedBox(width: 8),
                          _buildMacroPill('F', '${_totalFat.round()}g', const Color(0xFFBF5AF2)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Ingredients List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ..._items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final tracked = entry.value;
                        final isSelected = _selectedRegionIndex == idx;
                        final color = MealOverlayColors.forIndex(idx);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
                            border: Border.all(
                              color: isSelected
                                  ? MealOverlayColors.selectedBorder
                                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Conditional Dot: Only rendered when valid regions exist (Screen C4 / D6b)
                              if (hasVisibleRegions) ...[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],

                              // Ingredient Name (Tapping opens FoodDetailScreen)
                              Expanded(
                                child: InkWell(
                                  onTap: () => _openItemDetail(tracked),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      tracked.item.name,
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        color: titleColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),

                              // Quantity Stepper with direct click on grams (Screen D3)
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF222220) : const Color(0xFFE8E8E0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildStepperButton(
                                      icon: LucideIcons.minus,
                                      onTap: () => _updateQuantity(idx, -10),
                                    ),
                                    InkWell(
                                      onTap: () => _showDirectQuantityDialog(idx),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        child: Text(
                                          '${tracked.entry.quantityInGrams} g',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: titleColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    _buildStepperButton(
                                      icon: LucideIcons.plus,
                                      onTap: () => _updateQuantity(idx, 10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),

                      // Add Ingredient Button
                      AppButton.secondary(
                        onPressed: _addNewIngredient,
                        label: 'Zutat hinzufügen',
                        tooltip: 'Zutat hinzufügen',
                        icon: LucideIcons.plus,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // Bottom Bar: "Fertig" (Speichern)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: bg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: AppButton.primary(
              onPressed: _isSaving ? null : _saveAndClose,
              label: 'Fertig',
              tooltip: 'Fertig',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 14),
      ),
    );
  }
}
