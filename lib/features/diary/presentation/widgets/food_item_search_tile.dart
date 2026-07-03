import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/base_food_language_service.dart';
import '../../../../services/theme_service.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../domain/models/food_item.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class FoodItemSearchTile extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  const FoodItemSearchTile({
    super.key,
    required this.item,
    required this.onAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final themeService = Provider.of<ThemeService>(context);
    final baseFoodLang = BaseFoodLanguageService.resolveLanguageCode(
      choice: themeService.baseFoodLanguage,
      context: context,
    );

    IconData sourceIcon;
    switch (item.source) {
      case FoodItemSource.base:
        sourceIcon = LucideIcons.star;
        break;
      case FoodItemSource.off:
      case FoodItemSource.user:
        sourceIcon = LucideIcons.archive;
        break;
    }

    return SummaryCard(
      child: ListTile(
        leading: Icon(sourceIcon, color: colorScheme.primary),
        title: Row(
          children: [
            Expanded(
              child: Text(
                () {
                  final name = item.source == FoodItemSource.base
                      ? item.getLocalizedName(context,
                          languageCode: baseFoodLang)
                      : item.getLocalizedName(context);
                  return name.isNotEmpty ? name : l10n.unknown;
                }(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (item.isCustom) ...[
              const SizedBox(width: DesignConstants.spacingS),
              _buildSourceBadge(context),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              l10n
                  .foodItemSubtitle('', item.calories)
                  .replaceFirst(RegExp(r'^.*?-\s*'), ''),
            ),
            if (item.brand.isNotEmpty &&
                item.brand != 'Keine Marke' &&
                item.brand != l10n.noBrand) ...[
              const Text(' • '),
              Expanded(
                child: Text(
                  item.brand,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            LucideIcons.circle_plus,
            color: colorScheme.primary,
            size: 28,
          ),
          onPressed: onAdd,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSourceBadge(BuildContext context) {
    final theme = Theme.of(context);
    const color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignConstants.spacingS, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        AppLocalizations.of(context)!.customLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
