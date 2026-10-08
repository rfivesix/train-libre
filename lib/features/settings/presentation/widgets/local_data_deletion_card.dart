import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../widgets/common/app_button.dart';

class LocalDataDeletionCard extends StatelessWidget {
  const LocalDataDeletionCard({
    super.key,
    required this.isLocalResetRunning,
    required this.onDeletePressed,
  });

  final bool isLocalResetRunning;
  final VoidCallback? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            l10n.localDataDeletionCardTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            l10n.localDataDeletionCardDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: SizedBox(
            width: double.infinity,
            child: AppButton.danger(
              key: const Key('delete_all_local_app_data_button'),
              onPressed: isLocalResetRunning ? null : onDeletePressed,
              label: l10n.deleteAllLocalAppData,
              tooltip: l10n.deleteAllLocalAppData,
              icon: LucideIcons.trash,
              isLoading: isLocalResetRunning,
            ),
          ),
        ),
        if (isLocalResetRunning)
          const Padding(
            padding: EdgeInsets.only(top: DesignConstants.spacingL),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
