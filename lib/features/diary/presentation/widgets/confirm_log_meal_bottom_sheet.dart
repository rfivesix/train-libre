import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../util/design_constants.dart';

import 'package:intl/intl.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/date_util.dart';
import '../../domain/models/food_item.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../widgets/common/common.dart';
import 'package:provider/provider.dart';
import '../../../../services/theme_service.dart';
import '../../../../services/base_food_language_service.dart';
import '../../../../widgets/common/app_button.dart';

class ConfirmLogMealBottomSheet extends StatefulWidget {
  final String mealName;
  final List<Map<String, dynamic>> rawItems;
  final Map<String, FoodItem> products;
  final int? recipeCookedWeightInGrams;
  final int? recipeServingCount;
  final String? initialWeightBasis;
  final DateTime initialDate;
  final String initialMealType;
  final Future<void> Function(
    DateTime date,
    String mealType,
    Map<String, int> quantities,
  ) onSave;

  const ConfirmLogMealBottomSheet({
    super.key,
    required this.mealName,
    required this.rawItems,
    required this.products,
    this.recipeCookedWeightInGrams,
    this.recipeServingCount,
    this.initialWeightBasis,
    required this.initialDate,
    required this.initialMealType,
    required this.onSave,
  });

  @override
  State<ConfirmLogMealBottomSheet> createState() =>
      _ConfirmLogMealBottomSheetState();
}

class _ConfirmLogMealBottomSheetState extends State<ConfirmLogMealBottomSheet> {
  late DateTime _selectedDate;
  late String _selectedMealType;
  late Map<String, TextEditingController> _qtyCtrls;
  late final TextEditingController _totalQtyCtrl;
  late final TextEditingController _portionQtyCtrl;
  late final int _rawRecipeTotalGrams;
  late String _selectedWeightBasis;
  int get _recipeTotalGrams => _selectedWeightBasis == 'cooked'
      ? (widget.recipeCookedWeightInGrams ?? _rawRecipeTotalGrams)
      : _rawRecipeTotalGrams;
  bool _syncingQuantities = false;
  bool _isSaving = false;

  String _quantityKey(Map<String, dynamic> item) =>
      item['id']?.toString() ?? item['barcode'] as String;

  final List<String> _internalTypes = const [
    'mealtypeBreakfast',
    'mealtypeLunch',
    'mealtypeDinner',
    'mealtypeSnack',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize date and meal type states
    _selectedDate = widget.initialDate.withCurrentTime;
    _selectedMealType = widget.initialMealType;
    if (!_internalTypes.contains(_selectedMealType)) {
      _selectedMealType = _internalTypes.first;
    }

    // Initialize text controllers for all ingredient quantities
    _qtyCtrls = {
      for (final it in widget.rawItems)
        _quantityKey(it): TextEditingController(
          text: '${it['quantity_in_grams']}',
        ),
    };
    _rawRecipeTotalGrams = widget.rawItems.fold<int>(
      0,
      (sum, it) => sum + ((it['quantity_in_grams'] as num?)?.round() ?? 0),
    );
    _selectedWeightBasis = widget.initialWeightBasis ??
        (widget.recipeCookedWeightInGrams == null ? 'raw' : 'cooked');
    _totalQtyCtrl = TextEditingController(text: '$_recipeTotalGrams')
      ..addListener(_scaleIngredientsFromTotal);
    _portionQtyCtrl = TextEditingController(
      text: widget.recipeServingCount?.toString() ?? '',
    )..addListener(_scaleFromPortionCount);
  }

  @override
  void dispose() {
    _totalQtyCtrl.dispose();
    _portionQtyCtrl.dispose();
    for (final ctrl in _qtyCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _scaleIngredientsFromTotal() {
    if (_syncingQuantities || _recipeTotalGrams <= 0) return;
    final requested = int.tryParse(_totalQtyCtrl.text.trim());
    if (requested == null || requested <= 0) return;
    _syncingQuantities = true;
    if (widget.recipeServingCount case final servings? when servings > 0) {
      final portions = requested * servings / _recipeTotalGrams;
      _portionQtyCtrl.text = _formatPortions(portions);
    }
    final scaledAmounts = <int>[];
    for (var i = 0; i < widget.rawItems.length; i++) {
      final item = widget.rawItems[i];
      final original = (item['quantity_in_grams'] as num).round();
      scaledAmounts.add((original * requested / _recipeTotalGrams).round());
    }
    if (_selectedWeightBasis == 'raw' && scaledAmounts.isNotEmpty) {
      final originalTotal = widget.rawItems.fold<int>(
        0,
        (sum, item) => sum + (item['quantity_in_grams'] as num).round(),
      );
      final roundedTotal =
          scaledAmounts.fold<int>(0, (sum, value) => sum + value);
      final largestIndex = widget.rawItems.indexOf(widget.rawItems.reduce(
        (largest, item) => (item['quantity_in_grams'] as num) >
                (largest['quantity_in_grams'] as num)
            ? item
            : largest,
      ));
      if (originalTotal == _recipeTotalGrams) {
        scaledAmounts[largestIndex] += requested - roundedTotal;
      }
    }
    for (var i = 0; i < widget.rawItems.length; i++) {
      _qtyCtrls[_quantityKey(widget.rawItems[i])]?.text = '${scaledAmounts[i]}';
    }
    _syncingQuantities = false;
  }

  String _formatPortions(double value) {
    final rounded = value.toStringAsFixed(1);
    return rounded.endsWith('.0')
        ? rounded.substring(0, rounded.length - 2)
        : rounded;
  }

  double? _currentPortions() => double.tryParse(
        _portionQtyCtrl.text.trim().replaceAll(',', '.'),
      );

  void _adjustPortions({required bool increase}) {
    final current = _currentPortions();
    double next;
    if (increase) {
      if (current == null || current < 0.5) {
        next = 0.5;
      } else {
        final halfSteps = current * 2;
        final isOnStep = (halfSteps - halfSteps.round()).abs() < 0.000001;
        next = isOnStep ? current + 0.5 : (halfSteps.ceil() / 2);
      }
    } else {
      if (current == null || current <= 0.5) {
        next = 0.5;
      } else {
        final halfSteps = current * 2;
        final isOnStep = (halfSteps - halfSteps.round()).abs() < 0.000001;
        next = isOnStep ? current - 0.5 : (halfSteps.floor() / 2);
        if (next < 0.5) next = 0.5;
      }
    }
    _portionQtyCtrl.text = _formatPortions(next);
  }

  void _changeWeightBasis(String? basis) {
    if (basis == null || basis == _selectedWeightBasis) return;
    final oldTotal = _recipeTotalGrams;
    final currentAmount = int.tryParse(_totalQtyCtrl.text.trim()) ?? oldTotal;
    setState(() => _selectedWeightBasis = basis);
    final newTotal = _recipeTotalGrams;
    if (oldTotal > 0 && newTotal > 0) {
      _totalQtyCtrl.text =
          (currentAmount * newTotal / oldTotal).round().toString();
    }
  }

  void _scaleFromPortionCount() {
    final servings = widget.recipeServingCount;
    if (_syncingQuantities || servings == null || servings <= 0) return;
    final requestedPortions = double.tryParse(
      _portionQtyCtrl.text.trim().replaceAll(',', '.'),
    );
    if (requestedPortions == null || requestedPortions <= 0) return;
    final requestedGrams = (requestedPortions * _recipeTotalGrams / servings)
        .round()
        .clamp(1, 1 << 31);
    _syncingQuantities = true;
    _totalQtyCtrl.text = '$requestedGrams';
    _syncingQuantities = false;
    _scaleIngredientsFromTotal();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final formattedDate = DateFormat.yMd(locale).format(_selectedDate);
    final formattedTime = DateFormat.Hm(locale).format(_selectedDate);

    final Map<String, String> mealTypeLabel = {
      'mealtypeBreakfast': l10n.mealtypeBreakfast,
      'mealtypeLunch': l10n.mealtypeLunch,
      'mealtypeDinner': l10n.mealtypeDinner,
      'mealtypeSnack': l10n.mealtypeSnack,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.mealName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: DesignConstants.spacingM),

        // Date & time selection
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(LucideIcons.calendar, size: 18),
              label: Text(formattedDate),
              onPressed: () async {
                final picked = await showAdaptiveDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      _selectedDate.hour,
                      _selectedDate.minute,
                    );
                  });
                }
              },
            ),
            TextButton.icon(
              icon: const Icon(LucideIcons.clock, size: 18),
              label: Text(formattedTime),
              onPressed: () async {
                final picked = await showAdaptiveTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_selectedDate),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      picked.hour,
                      picked.minute,
                    );
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingS),

        if (widget.recipeServingCount case final servings?
            when servings > 0) ...[
          TextFormField(
            controller: _portionQtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d?$')),
            ],
            decoration: InputDecoration(
              labelText: l10n.mealPortionAmountLabel,
              helperText: l10n.mealPortionAmountHint(servings),
              prefixIcon: IconButton(
                tooltip: l10n.mealDecreasePortion,
                onPressed: () => _adjustPortions(increase: false),
                icon: const Icon(LucideIcons.minus),
              ),
              suffixIcon: IconButton(
                tooltip: l10n.mealIncreasePortion,
                onPressed: () => _adjustPortions(increase: true),
                icon: const Icon(LucideIcons.plus),
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusM),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _totalQtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.mealTotalAmountLabel,
                  suffixText: l10n.unit_grams,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(DesignConstants.borderRadiusM),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
            if (widget.recipeCookedWeightInGrams != null) ...[
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                flex: 2,
                child: PlatformAdaptiveDropdownFormField<String>(
                  initialValue: _selectedWeightBasis,
                  decoration: InputDecoration(
                    labelText: l10n.mealWeightBasisLabel,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'raw', child: Text(l10n.mealWeightBasisRaw)),
                    DropdownMenuItem(
                        value: 'cooked',
                        child: Text(l10n.mealWeightBasisCooked)),
                  ],
                  onChanged: _changeWeightBasis,
                ),
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 6),
          child: Text(l10n.mealTotalAmountHint(_recipeTotalGrams),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: DesignConstants.spacingM),

        PlatformAdaptiveDropdownFormField<String>(
          initialValue: _selectedMealType,
          decoration: InputDecoration(
            labelText: l10n.mealTypeLabel,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
              borderSide: BorderSide.none,
            ),
            isDense: true,
          ),
          items: _internalTypes
              .map(
                (key) => DropdownMenuItem(
                  value: key,
                  child: Text(mealTypeLabel[key] ?? key),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _selectedMealType = v;
              });
            }
          },
        ),

        const SizedBox(height: DesignConstants.spacingM),

        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: widget.rawItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final it = widget.rawItems[i];
              final bc = it['barcode'] as String;
              final quantityKey = _quantityKey(it);
              final fi = widget.products[bc];
              final displayName = fi != null
                  ? (() {
                      final themeService = Provider.of<ThemeService>(context);
                      final baseFoodLang =
                          BaseFoodLanguageService.resolveLanguageCode(
                        choice: themeService.baseFoodLanguage,
                        context: context,
                      );
                      return fi.source == FoodItemSource.base
                          ? fi.getLocalizedName(context,
                              languageCode: baseFoodLang)
                          : fi.getLocalizedName(context);
                    })()
                  : bc;
              final unit = (fi?.isLiquid == true)
                  ? l10n.unit_milliliters
                  : l10n.unit_grams;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: Icon(LucideIcons.sandwich, size: 20),
                  ),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrls[quantityKey],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: displayName,
                        suffixText: unit,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesignConstants.borderRadiusM),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: DesignConstants.spacingM,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: DesignConstants.spacingXL),

        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                label: l10n.cancel,
                tooltip: l10n.cancel,
              ),
            ),
            const SizedBox(width: DesignConstants.spacingM),
            Expanded(
              child: AppButton.primary(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          // Build final quantities map to hand over
                          final Map<String, int> finalQuantities = {};
                          for (final it in widget.rawItems) {
                            final ctrl = _qtyCtrls[_quantityKey(it)]!;
                            final parsed = int.tryParse(ctrl.text.trim());
                            final qty = (parsed == null || parsed < 1)
                                ? (it['quantity_in_grams'] as int)
                                : parsed;
                            finalQuantities[_quantityKey(it)] = qty;
                          }

                          await widget.onSave(_selectedDate, _selectedMealType,
                              finalQuantities);
                          if (!mounted) return;
                          navigator.pop(true);
                        } catch (error) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('${l10n.error}: $error')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                label: l10n.save,
                tooltip: l10n.save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
