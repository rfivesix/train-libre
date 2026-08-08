import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/theme_service.dart';
import '../../../../services/base_food_language_service.dart';
import '../../domain/models/tracked_food_item.dart';
import '../../domain/models/food_item.dart';
import '../food_detail_screen.dart';
import '../diary_view_model.dart';
import '../../../../widgets/common/glass_actionable_card.dart';

class FoodEntryTile extends StatelessWidget {
  final TrackedFoodItem trackedItem;
  final Function(TrackedFoodItem) onEdit;
  final Function(int) onDelete;

  const FoodEntryTile({
    super.key,
    required this.trackedItem,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final themeService = Provider.of<ThemeService>(context);
    final baseFoodLang = BaseFoodLanguageService.resolveLanguageCode(
      choice: themeService.baseFoodLanguage,
      context: context,
    );

    return GlassActionableCard(
      dismissibleKey: Key('food_hub_entry_${trackedItem.entry.id}'),
      onEdit: () => onEdit(trackedItem),
      onDelete: () => onDelete(trackedItem.entry.id!),
      onTap: () {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (context) => FoodDetailScreen(trackedItem: trackedItem),
          ),
        )
            .then((_) {
          if (!context.mounted) return;
          context
              .read<DiaryViewModel>()
              .loadDataForDate(context.read<DiaryViewModel>().selectedDate);
        });
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          trackedItem.item.source == FoodItemSource.base
              ? trackedItem.item.getLocalizedName(
                  context,
                  languageCode: baseFoodLang,
                )
              : trackedItem.item.getLocalizedName(context),
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          '${trackedItem.entry.quantityInGrams}${l10n.unit_grams}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        trailing: Text(
          '${trackedItem.calculatedCalories} ${l10n.unit_kcal}',
          style: theme.textTheme.labelLarge,
        ),
      ),
    );
  }
}
