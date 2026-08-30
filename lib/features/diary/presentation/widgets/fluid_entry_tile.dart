import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/fluid_entry.dart';
import '../../../../widgets/common/glass_actionable_card.dart';
import 'diary_food_row.dart';

class FluidEntryTile extends StatelessWidget {
  final FluidEntry entry;
  final Function(FluidEntry) onEdit;
  final Function(int) onDelete;

  const FluidEntryTile({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final mutedColor = theme.textTheme.bodySmall?.color;

    final totalSugar = (entry.sugarPer100ml != null && entry.sugarPer100ml! > 0)
        ? (entry.sugarPer100ml! / 100.0 * entry.quantityInMl)
        : 0.0;
    final totalCaffeine =
        (entry.caffeinePer100ml != null && entry.caffeinePer100ml! > 0)
            ? (entry.caffeinePer100ml! / 100.0 * entry.quantityInMl)
            : 0.0;

    final extraColumns = <Widget>[];

    if (totalSugar > 0) {
      final sugarStr = totalSugar.truncateToDouble() == totalSugar
          ? totalSugar.toStringAsFixed(0)
          : totalSugar.toStringAsFixed(1);
      extraColumns.add(
        Text(
          'S $sugarStr${l10n.unit_grams}',
          textAlign: TextAlign.right,
          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
          maxLines: 1,
        ),
      );
    }

    if (totalCaffeine > 0) {
      final caffeineStr = totalCaffeine.truncateToDouble() == totalCaffeine
          ? totalCaffeine.toStringAsFixed(0)
          : totalCaffeine.toStringAsFixed(1);
      extraColumns.add(
        Text(
          '$caffeineStr${l10n.unit_milligrams}',
          textAlign: TextAlign.right,
          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
          maxLines: 1,
        ),
      );
    }

    return GlassActionableCard(
      dismissibleKey: Key('fluid_entry_${entry.id}'),
      onEdit: () => onEdit(entry),
      onDelete: () => onDelete(entry.id!),
      onTap: () => onEdit(entry),
      child: DiaryFoodRow(
        name: entry.name,
        amountLabel: '${entry.quantityInMl}${l10n.unit_milliliters}',
        energyLabel: '${entry.kcal ?? 0} ${l10n.unit_kcal}',
        extraColumns: extraColumns.isNotEmpty ? extraColumns : null,
      ),
    );
  }
}

