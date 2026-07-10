import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/theme_service.dart';
import '../../../../services/base_food_language_service.dart';
import '../../../../widgets/common/swipe_action_background.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../domain/models/tracked_food_item.dart';
import '../../domain/models/food_item.dart';
import '../food_detail_screen.dart';
import '../diary_view_model.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

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

    return Dismissible(
      key: Key('food_hub_entry_${trackedItem.entry.id}'),
      background: const SwipeActionBackground(
        color: Colors.blueAccent,
        icon: LucideIcons.pencil,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: LucideIcons.trash_2,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit(trackedItem);
          return false;
        } else {
          return await showDeleteConfirmation(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete(trackedItem.entry.id!);
        }
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
      ),
    );
  }
}
