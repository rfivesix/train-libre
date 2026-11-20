import 'package:material_ui/material_ui.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final themeService = Provider.of<ThemeService>(context);
    final baseFoodLang = BaseFoodLanguageService.resolveLanguageCode(
      choice: themeService.baseFoodLanguage,
      context: context,
    );
    final name = item.source == FoodItemSource.base
        ? item.getLocalizedName(context, languageCode: baseFoodLang)
        : item.getLocalizedName(context);
    final calories = l10n
        .foodItemSubtitle('', item.calories)
        .replaceFirst(RegExp(r'^.*?-\s*'), '');
    final hasBrand =
        item.brand.isNotEmpty &&
        item.brand != 'Keine Marke' &&
        item.brand != l10n.noBrand;

    return SummaryCard(
      margin: const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.only(
          start: DesignConstants.cardPaddingInternal,
          end: DesignConstants.spacingS,
        ),
        minTileHeight: 64,
        minVerticalPadding: DesignConstants.spacingS,
        // Center both lines together within the compact tile.
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name.isNotEmpty ? name : l10n.unknown,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (item.isCustom) ...[
                  const SizedBox(width: DesignConstants.spacingS),
                  _buildSourceBadge(context),
                ],
              ],
            ),
            Text(
              hasBrand
                  ? '$calories${DesignConstants.metadataSeparator}${item.brand}'
                  : calories,
              style:
                  ListTileTheme.of(context).subtitleTextStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: l10n.add_button,
          icon: Icon(
            LucideIcons.plus,
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
        horizontal: DesignConstants.spacingS,
        vertical: 3,
      ),
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
