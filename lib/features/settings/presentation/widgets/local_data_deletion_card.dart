import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
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

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.localDataDeletionCardTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.localDataDeletionCardDescription,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            SizedBox(
              width: double.infinity,
              child: AppButton.danger(
                onPressed: isLocalResetRunning ? null : onDeletePressed,
                label: l10n.deleteAllLocalAppData,
                tooltip: l10n.deleteAllLocalAppData,
                icon: LucideIcons.trash_2,
                isLoading: isLocalResetRunning,
              ),
            ),
            if (isLocalResetRunning)
              const Padding(
                padding: EdgeInsets.only(top: DesignConstants.spacingL),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
