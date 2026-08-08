import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../widgets/common/app_button.dart';

class DataBackupCard extends StatelessWidget {
  const DataBackupCard({
    super.key,
    required this.isFullBackupRunning,
    required this.onExportPressed,
    required this.onImportPressed,
    required this.onExportEncryptedPressed,
  });

  final bool isFullBackupRunning;
  final VoidCallback? onExportPressed;
  final VoidCallback? onImportPressed;
  final VoidCallback? onExportEncryptedPressed;

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
            l10n.dataManagementBackupTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.dataManagementBackupDescription,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: DesignConstants.spacingL),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: isFullBackupRunning ? null : onExportPressed,
                  label: l10n.data_export_button,
                  tooltip: l10n.data_export_button,
                  icon: LucideIcons.file_up,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.primary(
                  onPressed: isFullBackupRunning ? null : onImportPressed,
                  label: l10n.data_import_button,
                  tooltip: l10n.data_import_button,
                  icon: LucideIcons.circle_arrow_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              onPressed: isFullBackupRunning ? null : onExportEncryptedPressed,
              label: l10n.exportEncrypted,
              tooltip: l10n.exportEncrypted,
              icon: LucideIcons.lock,
            ),
          ),
          if (isFullBackupRunning)
            const Padding(
              padding: EdgeInsets.only(top: DesignConstants.spacingL),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
