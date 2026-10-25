import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/common.dart';
import '../../domain/macro_entry_calculator.dart';
import '../../domain/models/macro_entry.dart';

/// Compact editor for a manually entered macro-only diary item.
class MacroEntryForm extends StatefulWidget {
  const MacroEntryForm({
    super.key,
    required this.initialMealType,
    this.initialDate,
    this.initialEntry,
  });

  final String initialMealType;
  final DateTime? initialDate;
  final MacroEntry? initialEntry;

  @override
  State<MacroEntryForm> createState() => MacroEntryFormState();
}

class MacroEntryFormState extends State<MacroEntryForm> {
  static const _coreNutrients = MacroEntryCalculator.nutrients;

  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _calculatedPreviewController;
  late final Map<String, TextEditingController> _coreControllers;
  late final Map<String, TextEditingController> _extraControllers;
  String? _manualOverrideNutrient;
  late DateTime _timestamp;
  bool _isFluid = false;
  bool _showExtras = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _timestamp = entry?.timestamp ?? widget.initialDate ?? DateTime.now();
    _isFluid = entry?.isFluid ?? false;
    _nameController = TextEditingController(text: entry?.name ?? '');
    _amountController = TextEditingController(
      text: entry?.amount == null ? '' : _format(entry!.amount!),
    );
    _calculatedPreviewController = TextEditingController();
    _coreControllers = {
      'calories': TextEditingController(
        text: _initialCoreText(entry, 'calories'),
      ),
      'protein': TextEditingController(
        text: _initialCoreText(entry, 'protein'),
      ),
      'carbs': TextEditingController(text: _initialCoreText(entry, 'carbs')),
      'fat': TextEditingController(text: _initialCoreText(entry, 'fat')),
    };
    _extraControllers = {
      'sugar': TextEditingController(text: _formatNullable(entry?.sugar)),
      'fiber': TextEditingController(text: _formatNullable(entry?.fiber)),
      'salt': TextEditingController(text: _formatNullable(entry?.salt)),
      'caffeine': TextEditingController(text: _formatNullable(entry?.caffeine)),
    };
    _showExtras = entry?.sugar != null ||
        entry?.fiber != null ||
        entry?.salt != null ||
        entry?.caffeine != null;
  }

  String _initialCoreText(MacroEntry? entry, String nutrient) {
    if (entry == null) return '';
    return _format(switch (nutrient) {
      'calories' => entry.calories,
      'protein' => entry.protein,
      'carbs' => entry.carbs,
      'fat' => entry.fat,
      _ => 0,
    });
  }

  String _format(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  String _formatNullable(double? value) => value == null ? '' : _format(value);

  double? _parse(TextEditingController controller) {
    final text = controller.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  String? get _autoDerivedNutrient {
    if (_manualOverrideNutrient != null) return null;
    final missing = _coreNutrients
        .where((nutrient) => _coreControllers[nutrient]!.text.trim().isEmpty)
        .toList(growable: false);
    return missing.length == 1 ? missing.single : null;
  }

  Map<String, double?> get _coreValues => {
        for (final nutrient in _coreNutrients)
          nutrient: nutrient == _autoDerivedNutrient
              ? null
              : _parse(_coreControllers[nutrient]!),
      };

  MacroEntryCalculation? get calculation {
    final values = _coreValues;
    final present = values.values.whereType<double>().toList(growable: false);
    if (present.length == 4 &&
        present.every((value) => value.isFinite && value >= 0)) {
      return MacroEntryCalculation(
        calories: values['calories']!,
        protein: values['protein']!,
        carbs: values['carbs']!,
        fat: values['fat']!,
        calculatedNutrient:
            widget.initialEntry?.calculatedNutrient ?? 'calories',
      );
    }
    return MacroEntryCalculator.calculate(values);
  }

  bool get canSave {
    final amountText = _amountController.text.trim();
    final amount = amountText.isEmpty
        ? null
        : double.tryParse(amountText.replaceAll(',', '.'));
    final extrasValid = _extraControllers.values.every((controller) {
      final text = controller.text.trim();
      if (text.isEmpty) return true;
      final value = _parse(controller);
      return value != null && value.isFinite && value >= 0;
    });
    return calculation != null &&
        extrasValid &&
        (amountText.isEmpty || (amount != null && amount > 0)) &&
        (!_isFluid || (amount != null && amount > 0));
  }

  MacroEntry? createEntry() {
    final result = calculation;
    if (result == null || !canSave) return null;
    final amountText = _amountController.text.trim();
    final amount = amountText.isEmpty
        ? null
        : double.parse(amountText.replaceAll(',', '.'));
    double? extra(String key) => _parse(_extraControllers[key]!);
    return MacroEntry(
      id: widget.initialEntry?.id ?? const Uuid().v4(),
      timestamp: _timestamp,
      mealType: widget.initialEntry?.mealType ?? widget.initialMealType,
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      amount: amount,
      amountUnit: amount == null ? null : (_isFluid ? 'ml' : 'g'),
      isFluid: _isFluid,
      calories: result.calories,
      protein: result.protein,
      carbs: result.carbs,
      fat: result.fat,
      sugar: extra('sugar'),
      fiber: extra('fiber'),
      salt: extra('salt'),
      caffeine: extra('caffeine'),
      calculatedNutrient: result.calculatedNutrient,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _calculatedPreviewController.dispose();
    for (final controller in _coreControllers.values) {
      controller.dispose();
    }
    for (final controller in _extraControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showAdaptiveDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: Localizations.localeOf(context),
    );
    if (picked == null) return;
    setState(() => _timestamp = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _timestamp.hour,
          _timestamp.minute,
        ));
  }

  Future<void> _selectTime() async {
    final picked = await showAdaptiveTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (picked == null) return;
    setState(() => _timestamp = DateTime(
          _timestamp.year,
          _timestamp.month,
          _timestamp.day,
          picked.hour,
          picked.minute,
        ));
  }

  String _nutrientLabel(AppLocalizations l10n, String nutrient) =>
      switch (nutrient) {
        'calories' => l10n.calories,
        'protein' => l10n.protein,
        'carbs' => l10n.carbs,
        'fat' => l10n.fat,
        _ => nutrient,
      };

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final calc = calculation;
    final values = <String, double?>{
      'calories': calc?.calories,
      'protein': calc?.protein,
      'carbs': calc?.carbs,
      'fat': calc?.fat,
    };
    final autoDerivedNutrient = _autoDerivedNutrient;
    final calculatedValue =
        autoDerivedNutrient == null ? null : values[autoDerivedNutrient];
    final calculatedText =
        calculatedValue == null || _manualOverrideNutrient != null
            ? ''
            : _format(calculatedValue);
    if (_calculatedPreviewController.text != calculatedText) {
      _calculatedPreviewController.text = calculatedText;
    }

    Widget coreField(String nutrient) {
      return _numberField(
        label: _nutrientLabel(l10n, nutrient),
        controller:
            nutrient == autoDerivedNutrient && _manualOverrideNutrient == null
                ? _calculatedPreviewController
                : _coreControllers[nutrient]!,
        suffix: nutrient == 'calories' ? 'kcal' : 'g',
        onChanged: (value) => setState(() {
          if (_manualOverrideNutrient == null &&
              nutrient == autoDerivedNutrient) {
            _manualOverrideNutrient = nutrient;
            _coreControllers[nutrient]!.text = value;
          } else if (_manualOverrideNutrient == nutrient &&
              value.trim().isEmpty) {
            _manualOverrideNutrient = null;
          }
        }),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: l10n.macroEntryName),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        _numberField(
          label: l10n.macroEntryAmount,
          controller: _amountController,
          suffix: _isFluid ? 'ml' : 'g',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: DesignConstants.spacingXS),
        Text(
          _amountController.text.trim().isEmpty
              ? l10n.macroEntryAmountTotalHint
              : (_isFluid
                  ? l10n.macroEntryAmountPer100MlHint
                  : l10n.macroEntryAmountPer100GramHint),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Row(
          children: [
            Expanded(child: coreField('calories')),
            const SizedBox(width: DesignConstants.spacingS),
            Expanded(child: coreField('protein')),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Row(
          children: [
            Expanded(child: coreField('carbs')),
            const SizedBox(width: DesignConstants.spacingS),
            Expanded(child: coreField('fat')),
          ],
        ),
        if (calc == null && _coreValues.values.whereType<double>().length == 3)
          Padding(
            padding: const EdgeInsets.only(top: DesignConstants.spacingXS),
            child: Text(
              l10n.macroEntryInvalidValues,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (calc == null && _coreValues.values.whereType<double>().length < 3)
          Padding(
            padding: const EdgeInsets.only(top: DesignConstants.spacingXS),
            child: Text(
              l10n.macroEntryFillThreeValues,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        const SizedBox(height: DesignConstants.spacingS),
        PlatformAdaptiveSwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.add_to_water_intake),
          value: _isFluid,
          onChanged: (value) => setState(() => _isFluid = value),
        ),
        if (_isFluid && _amountController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignConstants.spacingS),
            child: Text(
              l10n.macroEntryFluidAmountRequired,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _showExtras = !_showExtras),
            icon: Icon(_showExtras ? LucideIcons.chevron_up : LucideIcons.plus),
            label: Text(l10n.macroEntryExtraNutrients),
          ),
        ),
        if (_showExtras) ...[
          Row(
            children: [
              Expanded(
                child: _numberField(
                  label: l10n.macroEntrySugar,
                  controller: _extraControllers['sugar']!,
                  suffix: 'g',
                ),
              ),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                child: _numberField(
                  label: l10n.macroEntryFiber,
                  controller: _extraControllers['fiber']!,
                  suffix: 'g',
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  label: l10n.macroEntrySalt,
                  controller: _extraControllers['salt']!,
                  suffix: 'g',
                ),
              ),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                child: _numberField(
                  label: l10n.macroEntryCaffeine,
                  controller: _extraControllers['caffeine']!,
                  suffix: l10n.unit_milligrams,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: DesignConstants.spacingXS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(LucideIcons.calendar, size: 18),
              label: Text(DateFormat.yMd(locale).format(_timestamp)),
              onPressed: _selectDate,
            ),
            TextButton.icon(
              icon: const Icon(LucideIcons.clock, size: 18),
              label: Text(DateFormat.Hm(locale).format(_timestamp)),
              onPressed: _selectTime,
            ),
          ],
        ),
      ],
    );
  }
}
