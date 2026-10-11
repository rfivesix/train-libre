import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';

class WorkoutImportSlide extends StatelessWidget {
  final VoidCallback onImport;

  const WorkoutImportSlide({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const Key('onboarding_workout_import_page'),
      padding: const EdgeInsets.all(DesignConstants.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DesignConstants.spacingXL),
          Text(
            l10n.onboardingWorkoutImportTitle,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Text(
            l10n.onboardingWorkoutImportDescription,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),
          SummaryCard(
            key: const Key('onboarding_import_workouts_button'),
            onTap: onImport,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                LucideIcons.download,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                l10n.onboardingWorkoutImportButton,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                LucideIcons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Text(
            l10n.onboardingWorkoutImportPrivacy,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
