import 'package:flutter/material.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../../util/design_constants.dart';
import 'goal_flow_state.dart';

class GoalMotivationStep extends StatelessWidget {
  final GoalFlowState state;
  final EdgeInsetsGeometry padding;

  const GoalMotivationStep({
    super.key,
    required this.state,
    this.padding = const EdgeInsets.symmetric(
      horizontal: DesignConstants.spacingL,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.goalStep6Question,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.goalStep6Description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),

        // Prompts
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            l10n.goalReasonSuggestionHealth,
            l10n.goalReasonSuggestionFitness,
            l10n.goalReasonSuggestionEnergy,
            l10n.goalReasonSuggestionHabits,
          ].map((suggestion) {
            final isSelected = state.reasonController.text.trim() == suggestion;
            return ActionChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              label: Text(
                suggestion,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              side: isSelected
                  ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                  : BorderSide(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.15),
                    ),
              backgroundColor: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : null,
              onPressed: () {
                state.setReason(suggestion);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: DesignConstants.spacingM),

        // Multi-line Reason TextField with focus node
        InkWell(
          onTap: () => state.reasonFocusNode.requestFocus(),
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
          child: TextField(
            key: const ValueKey('reason_text_field'),
            focusNode: state.reasonFocusNode,
            controller: state.reasonController,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.goalReasonPlaceholder,
              filled: true,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusM),
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingM),
        Text(
          l10n.goalReasonPrivacyNotice,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    ),);
  }
}
