// lib/features/diary/presentation/meal_entry_screen.dart

import '../data/meal_photo_store.dart';
import '../domain/models/meal_capture_meta.dart';

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import '../domain/models/macro_entry.dart';
import '../domain/models/tracked_food_item.dart';
import '../domain/repositories/diary_repository.dart';
import '../../../services/haptic_feedback_service.dart';
import 'dialogs/delete_meal_entry_bottom_sheet.dart';
import 'dialogs/macro_entry_form.dart';
import 'widgets/macro_entry_tile.dart';
import 'widgets/meal_photo_widget.dart';
import 'widgets/meal_ingredients_summary.dart';
import 'general_food_selection_screen.dart';
import 'food_detail_screen.dart';
import '../../../services/theme_service.dart';
import '../../../services/base_food_language_service.dart';

/// Full detail and editing screen for a logged meal entry (Screens D3 & D6b).
class MealEntryScreen extends StatefulWidget {
  final MealEntry mealEntry;
  final List<TrackedFoodItem> initialItems;
  final List<MacroEntry> initialMacroEntries;

  const MealEntryScreen({
    super.key,
    required this.mealEntry,
    required this.initialItems,
    this.initialMacroEntries = const [],
  });

  @override
  State<MealEntryScreen> createState() => _MealEntryScreenState();
}

class _PinnedMealSummaryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _PinnedMealSummaryDelegate(this.child);

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(covariant _PinnedMealSummaryDelegate oldDelegate) =>
      child != oldDelegate.child;
}

class _MealEntryScreenState extends State<MealEntryScreen> {
  late MealEntry _mealEntry;
  late List<TrackedFoodItem> _items;
  late List<MacroEntry> _macroEntries;
  final List<int> _deletedItemIds = [];
  final List<String> _deletedMacroEntryIds = [];
  bool _isSaving = false;
  bool _canPop = false;
  bool _isEditing = false;
  IDiaryRepository? _repo;
  final ValueNotifier<double> _mealPhotoScrollOffset = ValueNotifier<double>(0);
  final ScrollController _mealScrollController = ScrollController();
  double? _resolvedMealPhotoHeight;
  bool _initialSummaryPositionScheduled = false;
  bool _userHasScrolledMeal = false;

  void _scheduleInitialSummaryPosition() {
    if (_initialSummaryPositionScheduled ||
        _userHasScrolledMeal ||
        _resolvedMealPhotoHeight == null ||
        !_mealScrollController.hasClients) {
      return;
    }
    _initialSummaryPositionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialSummaryPositionScheduled = false;
      if (!mounted ||
          _userHasScrolledMeal ||
          !_mealScrollController.hasClients ||
          _resolvedMealPhotoHeight == null) {
        return;
      }
      final position = _mealScrollController.position;
      final target =
          (_resolvedMealPhotoHeight! +
                  DesignConstants.spacingL +
                  52 -
                  position.viewportDimension)
              .clamp(0.0, position.maxScrollExtent)
              .toDouble();
      if ((position.pixels - target).abs() > 1) {
        _mealScrollController.jumpTo(target);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _mealEntry = widget.mealEntry;
    _items = List.from(widget.initialItems);
    _macroEntries = List.from(widget.initialMacroEntries);
  }

  @override
  void dispose() {
    _mealScrollController.dispose();
    _mealPhotoScrollOffset.dispose();
    super.dispose();
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
    sum += _macroEntries.fold<int>(
      0,
      (total, entry) => total + entry.totalCalories.round(),
    );
    return sum;
  }

  double get _totalProtein {
    double sum = 0;
    for (final it in _items) {
      final factor = it.entry.quantityInGrams / 100.0;
      sum += it.item.protein * factor;
    }
    sum += _macroEntries.fold<double>(
      0,
      (total, entry) => total + entry.totalProtein,
    );
    return sum;
  }

  double get _totalCarbs {
    double sum = 0;
    for (final it in _items) {
      final factor = it.entry.quantityInGrams / 100.0;
      sum += it.item.carbs * factor;
    }
    sum += _macroEntries.fold<double>(
      0,
      (total, entry) => total + entry.totalCarbs,
    );
    return sum;
  }

  double get _totalFat {
    double sum = 0;
    for (final it in _items) {
      final factor = it.entry.quantityInGrams / 100.0;
      sum += it.item.fat * factor;
    }
    sum += _macroEntries.fold<double>(
      0,
      (total, entry) => total + entry.totalFat,
    );
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

  Future<void> _showDirectQuantityDialog(TrackedFoodItem item) async {
    final index = _items.indexOf(item);
    if (index < 0) return;
    final current = _items[index];
    final controller = TextEditingController(
      text: '${current.entry.quantityInGrams}',
    );
    final l10n = AppLocalizations.of(context)!;
    ThemeService? themeService;
    try {
      themeService = Provider.of<ThemeService>(context, listen: false);
    } catch (_) {}
    final baseFoodLang = BaseFoodLanguageService.resolveLanguageCode(
      choice: themeService?.baseFoodLanguage ?? BaseFoodLanguage.auto,
      context: context,
    );
    final foodName = current.item.source == FoodItemSource.base
        ? current.item.getLocalizedName(context, languageCode: baseFoodLang)
        : current.item.getLocalizedName(context);

    final result = await showGlassBottomMenu<int>(
      context: context,
      title: foodName,
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
                  borderRadius: BorderRadius.circular(
                    DesignConstants.borderRadiusM,
                  ),
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
        builder: (_) =>
            FoodDetailScreen(foodItem: tracked.item, trackedItem: tracked),
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

  Future<void> _editMacroEntry(MacroEntry entry) async {
    final formKey = GlobalKey<MacroEntryFormState>();
    final l10n = AppLocalizations.of(context)!;
    final updated = await showGlassBottomMenu<MacroEntry>(
      context: context,
      title: l10n.macroEntryTitle,
      contentBuilder: (sheetContext, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacroEntryForm(
            key: formKey,
            initialDate: _mealEntry.consumedAt,
            initialMealType: _mealEntry.mealType,
            initialEntry: entry,
            allowTimestampEditing: false,
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: close,
                  label: l10n.cancel,
                  tooltip: l10n.cancel,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.primary(
                  onPressed: () {
                    final value = formKey.currentState?.createEntry();
                    if (value == null) return;
                    Navigator.of(sheetContext).pop(
                      value.copyWith(
                        id: entry.id,
                        mealEntryId: _mealEntry.id,
                        timestamp: _mealEntry.consumedAt,
                        mealType: _mealEntry.mealType,
                      ),
                    );
                  },
                  label: l10n.save,
                  tooltip: l10n.save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (updated == null || !mounted) return;
    setState(() {
      final index = _macroEntries.indexWhere((item) => item.id == entry.id);
      if (index >= 0) _macroEntries[index] = updated;
    });
  }

  Future<void> _openMacroEntryDetail(MacroEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MacroEntryDetailScreen(
          entry: entry,
          onEdit: _editMacroEntry,
          l10n: l10n,
        ),
      ),
    );
  }

  Future<void> _addMacroEntry() async {
    final formKey = GlobalKey<MacroEntryFormState>();
    final l10n = AppLocalizations.of(context)!;
    final created = await showGlassBottomMenu<MacroEntry>(
      context: context,
      title: l10n.macroEntryTitle,
      contentBuilder: (sheetContext, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacroEntryForm(
            key: formKey,
            initialDate: _mealEntry.consumedAt,
            initialMealType: _mealEntry.mealType,
            allowTimestampEditing: false,
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: close,
                  label: l10n.cancel,
                  tooltip: l10n.cancel,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.primary(
                  onPressed: () {
                    final value = formKey.currentState?.createEntry();
                    if (value == null) return;
                    Navigator.of(sheetContext).pop(
                      value.copyWith(
                        mealEntryId: _mealEntry.id,
                        timestamp: _mealEntry.consumedAt,
                        mealType: _mealEntry.mealType,
                      ),
                    );
                  },
                  label: l10n.save,
                  tooltip: l10n.save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (created == null || !mounted) return;
    setState(() => _macroEntries.add(created));
  }

  Future<void> _deleteMacroEntry(MacroEntry entry) async {
    if (!mounted) return;
    setState(() {
      _macroEntries.removeWhere((item) => item.id == entry.id);
      _deletedMacroEntryIds.add(entry.id);
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
      MaterialPageRoute(builder: (_) => const GeneralFoodSelectionScreen()),
    );

    if (selectedFood != null && mounted) {
      setState(() {
        _items.add(
          TrackedFoodItem(
            item: selectedFood,
            entry: FoodEntry(
              barcode: selectedFood.barcode,
              timestamp: _mealEntry.consumedAt,
              quantityInGrams: 100,
              mealType: _mealEntry.mealType,
              mealEntryId: _mealEntry.id,
            ),
          ),
        );
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
      for (final id in _deletedMacroEntryIds) {
        await repo.deleteMacroEntry(id);
      }
      _deletedMacroEntryIds.clear();

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
      for (final entry in _macroEntries) {
        final linked = entry.copyWith(
          mealEntryId: _mealEntry.id,
          mealType: _mealEntry.mealType,
        );
        if (widget.initialMacroEntries.any((item) => item.id == entry.id)) {
          await repo.updateMacroEntry(linked);
        } else {
          await repo.insertMacroEntry(linked);
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
    final title =
        (_mealEntry.title != null && _mealEntry.title!.trim().isNotEmpty)
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mealDetailSavedAsTemplate)));
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
                  borderRadius: BorderRadius.circular(
                    DesignConstants.borderRadiusM,
                  ),
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
        _mealEntry = _mealEntry.copyWith(
          title: trimmed.isEmpty ? null : trimmed,
        );
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
    final timestampDelta = picked.difference(_mealEntry.consumedAt);
    setState(() {
      _mealEntry = rescheduled.entry;
      _items = rescheduled.items;
      _macroEntries = _macroEntries
          .map(
            (entry) =>
                entry.copyWith(timestamp: entry.timestamp.add(timestampDelta)),
          )
          .toList(growable: false);
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
        if (_macroEntries.isEmpty)
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
          icon: LucideIcons.trash,
          label: l10n.delete,
          onTap: () async {
            final choice = await DeleteMealEntryBottomSheet.show(
              context,
              mealTitle: _mealEntry.title ?? l10n.mealFallbackTitle,
              itemCount: _items.length + _macroEntries.length,
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
              for (var i = 0; i < _macroEntries.length; i++) {
                _macroEntries[i] = _macroEntries[i].copyWith(
                  mealType: entry.$1,
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
    ThemeService? themeService;
    try {
      themeService = Provider.of<ThemeService>(context, listen: false);
    } catch (_) {}
    final baseFoodLang = BaseFoodLanguageService.resolveLanguageCode(
      choice: themeService?.baseFoodLanguage ?? BaseFoodLanguage.auto,
      context: context,
    );
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final titleColor = isDark ? Colors.white : const Color(0xFF12120F);

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
      final thumb = MealPhotoStore.instance.resolveSync(
        MealPhotoStore.thumbPathFor(path),
      );
      if (thumb != null && thumb.existsSync()) photoFiles.add(thumb);
    }
    final hasPhoto = photoFiles.isNotEmpty;
    final localizedMealType = _getLocalizedMealName(
      context,
      _mealEntry.mealType,
    );
    final photoHeight = (MediaQuery.sizeOf(context).height * 0.58)
        .clamp(300.0, 560.0)
        .toDouble();
    final pinnedSummary = Material(
      color: bg,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$_totalKcal kcal',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: titleColor,
                ),
              ),
              const Spacer(),
              _buildMacroPill(
                'P',
                '${_totalProtein.round()}g',
                const Color(0xFFFF453A),
              ),
              const SizedBox(width: 8),
              _buildMacroPill(
                'C',
                '${_totalCarbs.round()}g',
                const Color(0xFF30D158),
              ),
              const SizedBox(width: 8),
              _buildMacroPill(
                'F',
                '${_totalFat.round()}g',
                const Color(0xFFBF5AF2),
              ),
            ],
          ),
        ),
      ),
    );
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
              icon: Icon(
                _isEditing ? LucideIcons.eye : LucideIcons.pencil,
                size: 20,
              ),
              tooltip: _isEditing ? l10n.mealDetailViewMode : l10n.edit,
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
            IconButton(
              icon: const Icon(LucideIcons.ellipsis, size: 20),
              tooltip: l10n.mealDetailOptions,
              onPressed: _showOverflowMenu,
            ),
          ],
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth == 0 &&
                notification.metrics.axis == Axis.vertical &&
                notification is UserScrollNotification &&
                notification.direction != ScrollDirection.idle) {
              _userHasScrolledMeal = true;
            }
            if (notification.depth == 0 &&
                notification.metrics.axis == Axis.vertical &&
                (notification is ScrollUpdateNotification ||
                    notification is ScrollMetricsNotification)) {
              _mealPhotoScrollOffset.value = notification.metrics.pixels
                  .clamp(0.0, double.infinity)
                  .toDouble();
              _scheduleInitialSummaryPosition();
            }
            return false;
          },
          child: CustomScrollView(
            controller: _mealScrollController,
            slivers: [
              if (hasPhoto)
                SliverToBoxAdapter(
                  child: MealPhotoWidget(
                    photoFiles: photoFiles,
                    height: photoHeight,
                    roundedTop: true,
                    roundedAll: true,
                    fadeBottom: true,
                    imageFit: BoxFit.contain,
                    scrollOffset: _mealPhotoScrollOffset,
                    matchSmallestPhotoAspectRatio: true,
                    onHeightChanged: (height) {
                      _resolvedMealPhotoHeight = height;
                      _scheduleInitialSummaryPosition();
                    },
                  ),
                )
              else
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignConstants.spacingS),
                ),
              if (hasPhoto)
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignConstants.spacingL),
                ),
              if (hasPhoto)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedMealSummaryDelegate(pinnedSummary),
                )
              else
                SliverToBoxAdapter(child: pinnedSummary),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Keep the same readable ingredient cards in both
                    // modes. Edit mode changes the actions and tap behavior,
                    // not the visual layout of the meal contents.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          MealIngredientsSummary(
                            ingredients: [
                              ..._items.map(
                                (item) => MealIngredientSummaryItem(
                                  key:
                                      'food-${item.entry.id ?? item.item.barcode}',
                                  name: item.item.source == FoodItemSource.base
                                      ? item.item.getLocalizedName(
                                          context,
                                          languageCode: baseFoodLang,
                                        )
                                      : item.item.getLocalizedName(context),
                                  grams: item.entry.quantityInGrams,
                                  kcal: item.calculatedCalories,
                                ),
                              ),
                              ..._macroEntries.map(
                                (entry) => MealIngredientSummaryItem(
                                  key: 'macro-${entry.id}',
                                  name: entry.name?.trim().isNotEmpty == true
                                      ? entry.name!.trim()
                                      : l10n.macroEntryDefaultName,
                                  grams: entry.amount?.round(),
                                  amountLabel: entry.amount == null
                                      ? null
                                      : '${entry.amount!.round()} ${entry.amountUnit ?? 'g'}',
                                  kcal: entry.totalCalories.round(),
                                ),
                              ),
                            ],
                            onEdit: () =>
                                setState(() => _isEditing = !_isEditing),
                            showEditButton: !_isEditing,
                            onIngredientTap: (index) {
                              if (index < _items.length) {
                                if (_isEditing) {
                                  _showDirectQuantityDialog(_items[index]);
                                } else {
                                  _openItemDetail(_items[index]);
                                }
                              } else {
                                final macro =
                                    _macroEntries[index - _items.length];
                                if (_isEditing) {
                                  _editMacroEntry(macro);
                                } else {
                                  _openMacroEntryDetail(macro);
                                }
                              }
                            },
                            onIngredientLongPress: _isEditing
                                ? (index) {
                                    if (index < _items.length) {
                                      _replaceIngredient(_items[index]);
                                    } else {
                                      _deleteMacroEntry(
                                        _macroEntries[index - _items.length],
                                      );
                                    }
                                  }
                                : null,
                            onIngredientDismissed: _isEditing
                                ? (index) {
                                    if (index < _items.length) {
                                      _deleteItem(_items[index]);
                                    } else {
                                      _deleteMacroEntry(
                                        _macroEntries[index - _items.length],
                                      );
                                    }
                                  }
                                : null,
                          ),
                          if (_isEditing) ...[
                            const SizedBox(height: DesignConstants.spacingS),
                            _buildEditActionButtons(
                              context,
                              l10n.mealDetailAddIngredient,
                              l10n.macroEntryTitle,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditActionButtons(
    BuildContext context,
    String addIngredientLabel,
    String addMacroLabel,
  ) {
    final theme = Theme.of(context);
    final style = (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.bold,
    );
    final direction = Directionality.of(context);
    double buttonWidth(String label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: direction,
        maxLines: 1,
      )..layout();
      // AppButton uses a 20px icon, 8px icon gap, and 16px side padding.
      return painter.width + 20 + 8 + 32;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = DesignConstants.spacingS;
        final fitsSideBySide =
            constraints.maxWidth >=
            buttonWidth(addIngredientLabel) + buttonWidth(addMacroLabel) + gap;
        final addIngredient = AppButton.secondary(
          onPressed: _addNewIngredient,
          label: addIngredientLabel,
          tooltip: addIngredientLabel,
          icon: LucideIcons.plus,
        );
        final addMacro = AppButton.secondary(
          onPressed: _addMacroEntry,
          label: addMacroLabel,
          tooltip: addMacroLabel,
          icon: LucideIcons.chart_pie,
        );
        if (fitsSideBySide) {
          return Row(
            children: [
              Expanded(child: addIngredient),
              SizedBox(width: gap),
              Expanded(child: addMacro),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            addIngredient,
            SizedBox(height: gap),
            addMacro,
          ],
        );
      },
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
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          color: color,
        ),
      ),
    );
  }
}
