// lib/features/diary/presentation/meal_entry_screen.dart

import '../data/meal_photo_store.dart';
import '../domain/models/meal_capture_meta.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/database_helper.dart';

import '../../../generated/app_localizations.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../util/date_util.dart';
import '../../../util/design_constants.dart';
import '../domain/meal_reschedule.dart';
import '../domain/models/food_entry.dart';
import '../domain/models/food_item.dart';
import '../domain/models/meal_entry.dart';
import '../domain/models/tracked_food_item.dart';
import '../domain/repositories/diary_repository.dart';
import '../../../services/ai_meal_validation.dart';
import '../../../services/haptic_feedback_service.dart';
import 'dialogs/delete_meal_entry_bottom_sheet.dart';
import 'widgets/meal_photo_widget.dart';
import 'widgets/meal_review_comparison_card.dart';
import 'general_food_selection_screen.dart';
import 'food_detail_screen.dart';
import 'util/meal_moment_format.dart';

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
  final List<int> _deletedItemIds = [];
  bool _isSaving = false;
  bool _canPop = false;
  IDiaryRepository? _repo;

  @override
  void initState() {
    super.initState();
    _mealEntry = widget.mealEntry;
    _items = List.from(widget.initialItems);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo ??= context.read<IDiaryRepository>();
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

  void _updateQuantity(TrackedFoodItem item, int delta) {
    final index = _items.indexOf(item);
    if (index < 0) return;
    setState(() {
      final current = _items[index];
      final newQuantity =
          (current.entry.quantityInGrams + delta).clamp(5, 5000);
      _items[index] = TrackedFoodItem(
        item: current.item,
        entry: current.entry.copyWith(quantityInGrams: newQuantity),
      );
    });
  }

  Future<void> _showDirectQuantityDialog(TrackedFoodItem item) async {
    final index = _items.indexOf(item);
    if (index < 0) return;
    final current = _items[index];
    final controller =
        TextEditingController(text: '${current.entry.quantityInGrams}');
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
                labelText: l10n.mealDetailAmountInGrams,
                suffixText: 'g',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusM),
                ),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),
            AppButton.primary(
              onPressed: () {
                final val = int.tryParse(controller.text);
                Navigator.of(ctx).pop(val);
              },
              label: l10n.mealDetailApply,
              tooltip: l10n.mealDetailApply,
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
      final currentIdx = _items.indexOf(current);
      if (currentIdx >= 0) {
        setState(() {
          _items[currentIdx] = TrackedFoodItem(
            item: current.item,
            entry: current.entry.copyWith(quantityInGrams: result),
          );
        });
      }
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

  /// Removes an ingredient from the meal and schedules it for DB deletion on save.
  void _deleteItem(TrackedFoodItem item) {
    setState(() {
      _items.remove(item);
      if (item.entry.id != null) {
        _deletedItemIds.add(item.entry.id!);
      }
    });
  }

  /// Swaps the food behind a row while keeping its amount.
  Future<void> _replaceIngredient(TrackedFoodItem item) async {
    final index = _items.indexOf(item);
    if (index < 0) return;
    final replacement = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute(builder: (_) => const GeneralFoodSelectionScreen()),
    );
    if (replacement == null || !mounted) return;

    final currentIdx = _items.indexOf(item);
    if (currentIdx >= 0) {
      final existing = _items[currentIdx];
      setState(() {
        _items[currentIdx] = TrackedFoodItem(
          item: replacement,
          entry: existing.entry.copyWith(barcode: replacement.barcode),
        );
      });
    }
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

  /// Writes all pending edits (deletions, updates, insertions) before exiting.
  Future<void> _persistChanges() async {
    if (_isSaving) return;
    _isSaving = true;

    final repo = _repo ?? (mounted ? context.read<IDiaryRepository>() : null);
    if (repo == null) {
      _isSaving = false;
      return;
    }

    try {
      // 1. Delete removed items
      for (final id in _deletedItemIds) {
        await repo.deleteFoodEntry(id);
      }
      _deletedItemIds.clear();

      // 2. Update meal entry header
      await repo.updateMealEntry(_mealEntry);

      // 3. Save item changes (update existing or insert new)
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.entry.id != null) {
          await repo.updateFoodEntry(item.entry);
        } else {
          final newId = await repo.insertFoodEntry(
            item.entry.copyWith(mealEntryId: _mealEntry.id),
          );
          _items[i] = TrackedFoodItem(
            item: item.item,
            entry: item.entry.copyWith(id: newId, mealEntryId: _mealEntry.id),
          );
        }
      }
    } catch (e) {
      debugPrint('Error persisting meal entry changes: $e');
    } finally {
      _isSaving = false;
    }
  }

  Future<void> _handlePop([Object? result]) async {
    await _persistChanges();
    if (mounted) {
      setState(() => _canPop = true);
      Navigator.of(context).pop(result ?? true);
    }
  }

  Future<void> _saveAsTemplate() async {
    final l10n = AppLocalizations.of(context)!;
    final title = (_mealEntry.title != null && _mealEntry.title!.trim().isNotEmpty)
        ? _mealEntry.title!.trim()
        : _getLocalizedMealName(context, _mealEntry.mealType);

    final mealId = await DatabaseHelper.instance.insertMeal(
      name: title,
      notes: '',
    );
    for (final item in _items) {
      await DatabaseHelper.instance.addMealItem(
        mealId: mealId,
        barcode: item.item.barcode,
        amount: item.entry.quantityInGrams.toDouble(),
      );
    }
    if (mounted) {
      HapticFeedbackService.instance.confirmationFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mealDetailSavedAsTemplate)),
      );
    }
  }

  Future<void> _showRenameMealDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _mealEntry.title ?? '');

    final result = await showGlassBottomMenu<String?>(
      context: context,
      title: l10n.mealNameLabel,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.mealNameLabel,
                hintText: l10n.mealEditorHintExample,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusM),
                ),
              ),
              onSubmitted: (val) {
                close();
                Navigator.of(ctx).pop(val);
              },
            ),
            const SizedBox(height: DesignConstants.spacingM),
            AppButton.primary(
              onPressed: () {
                close();
                Navigator.of(ctx).pop(controller.text);
              },
              label: l10n.save,
              tooltip: l10n.save,
            ),
            const SizedBox(height: DesignConstants.spacingS),
            AppButton.secondary(
              onPressed: () {
                close();
                Navigator.of(ctx).pop(null);
              },
              label: l10n.cancel,
              tooltip: l10n.cancel,
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      final trimmed = result.trim();
      setState(() {
        _mealEntry = _mealEntry.copyWith(title: trimmed.isEmpty ? null : trimmed);
      });
    }
  }

  /// Retroactively corrects when this meal happened.
  ///
  /// Unlike every other edit on this screen, this one is written immediately
  /// instead of waiting for [_persistChanges] on pop. A date change can move
  /// the meal off the day the user is looking at, and the diary behind this
  /// screen is a live stream — deferring the write would leave the meal showing
  /// on the old day until the user backed out, which reads as the change having
  /// been ignored.
  ///
  /// [IDiaryRepository.moveMealEntryTo] is used rather than a plain
  /// [IDiaryRepository.updateMealEntry] because it keys off the meal id in the
  /// database: it also catches linked rows this screen never loaded, which
  /// [_persistChanges] alone could not.
  Future<void> _pickDateTime() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final picked = await showAdaptiveDateTimePicker(
      context: context,
      initialDateTime: _mealEntry.consumedAt,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    if (picked == _mealEntry.consumedAt) return;

    final movedToAnotherDay = !picked.isSameDate(_mealEntry.consumedAt);

    final repo = context.read<IDiaryRepository>();
    await repo.moveMealEntryTo(_mealEntry.id, picked);
    if (!mounted) return;

    // Mirror the same shift onto the objects this screen holds, so the pending
    // save on pop rewrites the moved timestamps rather than dragging the items
    // back to the old day.
    final rescheduled = rescheduleMeal(
      entry: _mealEntry,
      items: _items,
      newConsumedAt: picked,
    );
    setState(() {
      _mealEntry = rescheduled.entry;
      _items = rescheduled.items;
    });

    HapticFeedbackService.instance.confirmationFeedback();

    // Only worth saying when the meal left the day it was on — otherwise the
    // subtitle already shows the new time and a toast is just noise.
    if (movedToAnotherDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.mealMovedToDate(
              DateFormat('EEEE, d MMMM', locale).format(picked),
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showOverflowMenu() {
    final l10n = AppLocalizations.of(context)!;
    showGlassBottomMenu<void>(
      context: context,
      title: _mealEntry.title ?? l10n.mealFallbackTitle,
      actions: [
        GlassMenuAction(
          icon: LucideIcons.pencil,
          label: l10n.mealNameLabel,
          onTap: () {
            _showRenameMealDialog();
          },
        ),
        GlassMenuAction(
          icon: LucideIcons.bookmark,
          label: l10n.mealDetailSaveAsTemplate,
          onTap: () async {
            await _saveAsTemplate();
          },
        ),
        GlassMenuAction(
          icon: LucideIcons.clock,
          label: l10n.mealDetailChangeMealType,
          onTap: () {
            _showChangeMealTypeDialog();
          },
        ),
        // Also reachable by tapping the subtitle; kept here too because this
        // menu is where the screen's other "change something about this meal"
        // actions already live.
        GlassMenuAction(
          icon: LucideIcons.calendar,
          label: l10n.mealDetailChangeDateTime,
          onTap: () {
            unawaited(_pickDateTime());
          },
        ),
        GlassMenuAction(
          icon: LucideIcons.trash_2,
          label: l10n.delete,
          onTap: () async {
            final choice = await DeleteMealEntryBottomSheet.show(
              context,
              mealTitle: _mealEntry.title ?? l10n.mealFallbackTitle,
              itemCount: _items.length,
              totalKcal: _totalKcal,
            );

            if (choice != null && mounted) {
              final repo = _repo ?? context.read<IDiaryRepository>();
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
      title: l10n.mealDetailSelectMealType,
      actions: types.map((entry) {
        return GlassMenuAction(
          icon: LucideIcons.utensils,
          label: entry.$2,
          onTap: () {
            if (!mounted) return;
            setState(() {
              _mealEntry = _mealEntry.copyWith(mealType: entry.$1);
              for (int i = 0; i < _items.length; i++) {
                _items[i] = TrackedFoodItem(
                  item: _items[i].item,
                  entry: _items[i].entry.copyWith(mealType: entry.$1),
                );
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final titleColor = isDark ? Colors.white : const Color(0xFF12120F);
    final subtitleColor =
        isDark ? const Color(0xFF8A8A82) : const Color(0xFF6A6A62);

    final captureMeta = MealCaptureMeta.tryParse(_mealEntry.captureMeta);
    final photoFiles = <File>[];
    for (final path in [
      _mealEntry.photoPath,
      ...?captureMeta?.extraPhotoPaths,
    ]) {
      // The preview is the fallback, because a backup carries only those: a
      // meal restored onto a new device has its thumbnail and nothing else,
      // and a soft picture beats an empty frame.
      final file = MealPhotoStore.instance.resolveSync(path);
      if (file != null && file.existsSync()) {
        photoFiles.add(file);
        continue;
      }
      final thumb = MealPhotoStore.instance
          .resolveSync(MealPhotoStore.thumbPathFor(path));
      if (thumb != null && thumb.existsSync()) photoFiles.add(thumb);
    }
    final hasPhoto = photoFiles.isNotEmpty;
    final timeStr = formatMealMoment(
      _mealEntry.consumedAt,
      locale: Localizations.localeOf(context).toString(),
    );
    final localizedMealType =
        _getLocalizedMealName(context, _mealEntry.mealType);

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handlePop(result);
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: GlobalAppBar(
          automaticallyImplyLeading: false,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(LucideIcons.arrow_left),
                  onPressed: () => _handlePop(true),
                )
              : null,
          title: _mealEntry.title ?? localizedMealType,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.ellipsis, size: 20),
              tooltip: l10n.mealDetailOptions,
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
                  if (hasPhoto)
                    MealPhotoWidget(
                      photoFiles: photoFiles,
                      height: 280,
                      roundedTop: false,
                      fadeBottom: true,
                    )
                  else
                    const SizedBox(height: DesignConstants.spacingS),
                  Transform.translate(
                    offset: Offset(0, hasPhoto ? -32 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The meal's name is already in the app bar; repeating it
                        // here just pushed the numbers down a line. Energy leads,
                        // macros sit right-aligned beside it.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Where the user looks for the meal's time is
                              // where they expect to be able to fix it, so the
                              // subtitle itself is the control.
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  key: const ValueKey(
                                      'meal_entry_timestamp_button'),
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: _pickDateTime,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '$localizedMealType · $timeStr',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: subtitleColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          LucideIcons.pencil,
                                          size: 12,
                                          color: subtitleColor,
                                          semanticLabel:
                                              l10n.mealDetailChangeDateTime,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '$_totalKcal kcal',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 24,
                                      color: titleColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  _buildMacroPill(
                                      'P',
                                      '${_totalProtein.round()}g',
                                      const Color(0xFFFF453A)),
                                  const SizedBox(width: 8),
                                  _buildMacroPill(
                                      'C',
                                      '${_totalCarbs.round()}g',
                                      const Color(0xFF30D158)),
                                  const SizedBox(width: 8),
                                  _buildMacroPill('F', '${_totalFat.round()}g',
                                      const Color(0xFFBF5AF2)),
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
                              // Same card the review screen uses, so a saved meal
                              // and a meal being reviewed are one screen with two
                              // states rather than two things that look alike.
                              ..._items.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final tracked = entry.value;
                                final factor =
                                    tracked.entry.quantityInGrams / 100.0;

                                return MealReviewComparisonCard(
                                  dismissibleKey: ValueKey(
                                      'meal_item_${tracked.entry.id ?? tracked.item.barcode}_$idx'),
                                  name: tracked.item.name,
                                  estimatedGrams: tracked.entry.quantityInGrams,
                                  // A saved entry carries no open uncertainty; the
                                  // card hides the chip above 0.7 anyway.
                                  confidence: 1.0,
                                  matchedFood: tracked.item,
                                  issues: const [],
                                  nutrition: AiNutritionTotals(
                                    kcal: tracked.item.calories * factor,
                                    protein: tracked.item.protein * factor,
                                    carbs: tracked.item.carbs * factor,
                                    fat: tracked.item.fat * factor,
                                  ),
                                  onDismissed: () => _deleteItem(tracked),
                                  onTap: () => _openItemDetail(tracked),
                                  onReplace: () => _replaceIngredient(tracked),
                                  onEditQuantity: () =>
                                      _showDirectQuantityDialog(tracked),
                                  onQuickAdjustQuantity: (delta) =>
                                      _updateQuantity(tracked, delta),
                                );
                              }),

                              const SizedBox(height: 8),

                              // Add Ingredient Button
                              AppButton.secondary(
                                onPressed: _addNewIngredient,
                                label: l10n.mealDetailAddIngredient,
                                tooltip: l10n.mealDetailAddIngredient,
                                icon: LucideIcons.plus,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
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
}
