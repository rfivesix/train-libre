import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../../generated/app_localizations.dart';

/// Single item representing an initial starter prompt suggestion.
class StarterPromptItem {
  final IconData icon;
  final String title;
  final String prompt;

  const StarterPromptItem({
    required this.icon,
    required this.title,
    required this.prompt,
  });
}

/// Vertically stacked starter prompt suggestion rows shown directly above the composer
/// when the conversation is empty and no text has been entered yet.
class CloudOverlayPromptSuggestions extends StatelessWidget {
  final Color contrastColor;
  final ValueChanged<String> onSelectPrompt;

  const CloudOverlayPromptSuggestions({
    super.key,
    required this.contrastColor,
    required this.onSelectPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      StarterPromptItem(
        icon: LucideIcons.chart_pie,
        title: l10n.aiStarterCheckNutritionTitle,
        prompt: l10n.aiStarterCheckNutritionPrompt,
      ),
      StarterPromptItem(
        icon: LucideIcons.biceps_flexed,
        title: l10n.aiStarterCheckRecoveryTitle,
        prompt: l10n.aiStarterCheckRecoveryPrompt,
      ),
      StarterPromptItem(
        icon: LucideIcons.sparkles,
        title: l10n.aiStarterSuggestMealTitle,
        prompt: l10n.aiStarterSuggestMealPrompt,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            _SuggestionRow(
              item: item,
              contrastColor: contrastColor,
              onTap: () => onSelectPrompt(item.prompt),
            ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final StarterPromptItem item;
  final Color contrastColor;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.item,
    required this.contrastColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: contrastColor.withValues(alpha: 0.12),
        highlightColor: contrastColor.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 21,
                color: contrastColor.withValues(alpha: 0.88),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: contrastColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
