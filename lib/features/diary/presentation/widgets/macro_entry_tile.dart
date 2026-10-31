import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/glass_actionable_card.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../../../widgets/common/global_app_bar.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/models/macro_entry.dart';
import 'diary_food_row.dart';

class MacroEntryTile extends StatelessWidget {
  const MacroEntryTile({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final MacroEntry entry;
  final Future<void> Function(MacroEntry) onEdit;
  final Future<void> Function(String) onDelete;

  String _format(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unit = entry.amountUnit ?? (entry.isFluid ? 'ml' : 'g');
    final amount = entry.amount == null ? '' : '${_format(entry.amount!)}$unit';
    return GlassActionableCard(
      dismissibleKey: Key('macro_entry_${entry.id}'),
      onEdit: () => onEdit(entry),
      onDelete: () => onDelete(entry.id),
      onTap: () => _showDetails(context),
      child: DiaryFoodRow(
        name: entry.name?.trim().isNotEmpty == true
            ? entry.name!.trim()
            : l10n.macroEntryDefaultName,
        amountLabel: amount,
        energyLabel: '${entry.totalCalories.round()} ${l10n.unit_kcal}',
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            MacroEntryDetailScreen(entry: entry, onEdit: onEdit, l10n: l10n),
      ),
    );
  }
}

class MacroEntryDetailScreen extends StatelessWidget {
  const MacroEntryDetailScreen({
    required this.entry,
    required this.onEdit,
    required this.l10n,
    super.key,
  });

  final MacroEntry entry;
  final Future<void> Function(MacroEntry) onEdit;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final title = entry.name?.trim().isNotEmpty == true
        ? entry.name!.trim()
        : l10n.macroEntryDefaultName;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: title,
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(LucideIcons.pencil),
            onPressed: () async {
              await onEdit(entry);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            DesignConstants.cardPaddingInternal,
            MediaQuery.paddingOf(context).top +
                kToolbarHeight +
                DesignConstants.cardPaddingInternal,
            DesignConstants.cardPaddingInternal,
            DesignConstants.cardPaddingInternal,
          ),
          child: _MacroEntryDetails(
            entry: entry,
            initialPer100: false,
            l10n: l10n,
          ),
        ),
      ),
    );
  }
}

class _MacroEntryDetails extends StatefulWidget {
  const _MacroEntryDetails({
    required this.entry,
    required this.initialPer100,
    required this.l10n,
  });

  final MacroEntry entry;
  final bool initialPer100;
  final AppLocalizations l10n;

  @override
  State<_MacroEntryDetails> createState() => _MacroEntryDetailsState();
}

class _MacroEntryDetailsState extends State<_MacroEntryDetails> {
  late bool _per100 = widget.initialPer100;

  String _format(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final l10n = widget.l10n;
    final hasPortion = entry.amount != null && entry.amount! > 0;
    final factor = !hasPortion || _per100 ? 1.0 : entry.amount! / 100;
    double core(double value) => value * factor;
    double? extra(double? value) => value == null ? null : value * factor;
    final unit = entry.amountUnit ?? (entry.isFluid ? 'ml' : 'g');
    final colors = Theme.of(context).extension<MacroColors>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = isDark
        ? LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.black.withValues(alpha: 0.15), Colors.transparent],
            stops: const [0, 1],
          )
        : null;
    final shadows = isDark
        ? const [
            Shadow(
              color: Color.fromRGBO(0, 0, 0, 0.35),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ]
        : null;

    Widget metricGrid(List<_MacroMetric> metrics) {
      if (metrics.isEmpty) return const SizedBox.shrink();
      final cards = metrics
          .map(
            (metric) => ValueSummaryCard(
              label: metric.label,
              value:
                  '${metric.decimals == 0 ? metric.value.round() : _format(metric.value)} ${metric.unit}',
              valueColor: isDark ? Colors.white : const Color(0xFF1C1C1E),
              labelColor: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : const Color(0xFF1C1C1E).withValues(alpha: 0.85),
              backgroundColor: metric.color,
              backgroundOverlayGradient: overlay,
              textShadows: shadows,
              showShadow: true,
            ),
          )
          .toList(growable: false);
      final rows = <Widget>[];
      for (var i = 0; i < cards.length; i += 2) {
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[i]),
                const SizedBox(width: DesignConstants.spacingS),
                Expanded(
                  child: i + 1 < cards.length ? cards[i + 1] : const SizedBox(),
                ),
              ],
            ),
          ),
        );
        if (i + 2 < cards.length) {
          rows.add(const SizedBox(height: DesignConstants.spacingS));
        }
      }
      return Column(children: rows);
    }

    final coreMetrics = [
      _MacroMetric(
        l10n.calories,
        core(entry.calories),
        'kcal',
        colors?.calories ?? Colors.orange,
        decimals: 0,
      ),
      _MacroMetric(
        l10n.protein,
        core(entry.protein),
        'g',
        colors?.protein ?? Colors.red,
      ),
      _MacroMetric(
        l10n.carbs,
        core(entry.carbs),
        'g',
        colors?.carbs ?? Colors.green,
      ),
      _MacroMetric(
        l10n.fat,
        core(entry.fat),
        'g',
        colors?.fat ?? Colors.purple,
      ),
    ];
    final extraMetrics = <_MacroMetric>[
      if (entry.sugar != null)
        _MacroMetric(
          l10n.macroEntrySugar,
          extra(entry.sugar)!,
          'g',
          colors?.sugar ?? Colors.pink,
        ),
      if (entry.fiber != null)
        _MacroMetric(
          l10n.macroEntryFiber,
          extra(entry.fiber)!,
          'g',
          colors?.fiber ?? Colors.brown,
        ),
      if (entry.salt != null)
        _MacroMetric(
          l10n.macroEntrySalt,
          extra(entry.salt)!,
          'g',
          colors?.salt ?? Colors.blueGrey,
        ),
    ];
    final portionTitle = !hasPortion
        ? l10n.macroEntryDetailTitle
        : entry.isFluid || unit == 'ml'
        ? '${l10n.macroEntryDetailTitle} (${_format(entry.amount!)} $unit)'
        : l10n.nutritionPerPortion(entry.amount!.round());

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                portionTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (hasPortion) ...[
              const SizedBox(width: DesignConstants.spacingM),
              _MacroPortionToggle(
                per100: _per100,
                onChanged: (value) => setState(() => _per100 = value),
                portionLabel: l10n.foodDetailSegmentPortion,
                per100Label: l10n.foodDetailSegment100g,
              ),
            ],
          ],
        ),
        const SizedBox(height: DesignConstants.spacingS),
        metricGrid(coreMetrics),
        if (extraMetrics.isNotEmpty) ...[
          const SizedBox(height: DesignConstants.spacingS),
          metricGrid(extraMetrics),
        ],
        if (entry.caffeine != null) ...[
          const SizedBox(height: DesignConstants.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: DesignConstants.spacingS,
              horizontal: DesignConstants.spacingM,
            ),
            child: Row(
              children: [
                Expanded(child: Text(l10n.macroEntryCaffeine)),
                Text('${_format(extra(entry.caffeine)!)} mg'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MacroMetric {
  const _MacroMetric(
    this.label,
    this.value,
    this.unit,
    this.color, {
    this.decimals = 1,
  });

  final String label;
  final double value;
  final String unit;
  final Color color;
  final int decimals;
}

class _MacroPortionToggle extends StatelessWidget {
  const _MacroPortionToggle({
    required this.per100,
    required this.onChanged,
    required this.portionLabel,
    required this.per100Label,
  });

  final bool per100;
  final ValueChanged<bool> onChanged;
  final String portionLabel;
  final String per100Label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: per100,
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.46 : 0.74,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.onSurface.withValues(alpha: isDark ? 0.14 : 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MacroPortionChip(
              label: portionLabel,
              selected: !per100,
              onTap: () => onChanged(false),
            ),
            const SizedBox(width: 2),
            _MacroPortionChip(
              label: per100Label,
              selected: per100,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroPortionChip extends StatelessWidget {
  const _MacroPortionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minWidth: 58, minHeight: 30),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: isDark ? 0.34 : 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: selected
              ? Border.all(
                  color: colors.primary.withValues(alpha: isDark ? 0.34 : 0.18),
                )
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? colors.primary
                      : colors.onSurfaceVariant.withValues(alpha: 0.88),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
