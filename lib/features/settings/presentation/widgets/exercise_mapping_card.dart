import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../widgets/common/app_link_row.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class ExerciseMappingCard extends StatelessWidget {
  const ExerciseMappingCard({super.key, required this.onMapPressed});

  final VoidCallback? onMapPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: DesignConstants.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mapExercisesTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(l10n.mapExercisesDescription, style: theme.textTheme.bodyMedium),
          const SizedBox(height: DesignConstants.spacingL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.folder_check),
              label: Text(l10n.mapExercisesButton),
              onPressed: onMapPressed,
            ),
          ),
        ],
      ),
    );
  }
}
