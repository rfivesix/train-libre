import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/fluid_entry.dart';
import '../../../../widgets/common/glass_actionable_card.dart';

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
    final totalSugar = (entry.sugarPer100ml != null)
        ? (entry.sugarPer100ml! / 100 * entry.quantityInMl).toStringAsFixed(1)
        : '0';
    final totalCaffeine = (entry.caffeinePer100ml != null)
        ? (entry.caffeinePer100ml! / 100 * entry.quantityInMl).toStringAsFixed(
            1,
          )
        : '0';

    return GlassActionableCard(
      dismissibleKey: Key('fluid_entry_${entry.id}'),
      onEdit: () => onEdit(entry),
      onDelete: () => onDelete(entry.id!),
      onTap: () => onEdit(entry),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(entry.name, style: theme.textTheme.titleMedium),
        subtitle: Text(
          '${entry.quantityInMl}${l10n.unit_milliliters} • ${l10n.sugar}: $totalSugar${l10n.unit_grams} • ${l10n.supplement_caffeine}: $totalCaffeine${l10n.unit_milligrams}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        trailing: Text(
          '${entry.kcal ?? 0} ${l10n.unit_kcal}',
          style: theme.textTheme.labelLarge,
        ),
      ),
    );
  }
}
