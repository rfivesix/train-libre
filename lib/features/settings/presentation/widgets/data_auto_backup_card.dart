import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../widgets/common/app_button.dart';

class DataAutoBackupCard extends StatelessWidget {
  const DataAutoBackupCard({
    super.key,
    required this.autoBackupDir,
    required this.lastAutoBackupFilePath,
    required this.lastAutoBackupDirUsed,
    required this.lastAutoBackupUsedFallback,
    required this.onPickDirectory,
    required this.onCopyPath,
    required this.onRunNow,
  });

  final String? autoBackupDir;
  final String? lastAutoBackupFilePath;
  final String? lastAutoBackupDirUsed;
  final bool lastAutoBackupUsedFallback;
  final VoidCallback? onPickDirectory;
  final VoidCallback? onCopyPath;
  final VoidCallback? onRunNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(DesignConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.autoBackupTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(l10n.autoBackupDescription, style: theme.textTheme.bodyMedium),
          const SizedBox(height: DesignConstants.spacingS),
          SelectableText(
            autoBackupDir ?? l10n.autoBackupDefaultFolder,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: onPickDirectory,
                  label: l10n.autoBackupChooseFolder,
                  tooltip: l10n.autoBackupChooseFolder,
                  icon: LucideIcons.folder_open,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.secondary(
                  onPressed: (autoBackupDir == null || autoBackupDir!.isEmpty)
                      ? null
                      : onCopyPath,
                  label: l10n.autoBackupCopyPath,
                  tooltip: l10n.autoBackupCopyPath,
                  icon: LucideIcons.copy,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingM),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              onPressed: onRunNow,
              label: l10n.autoBackupRunNow,
              tooltip: l10n.autoBackupRunNow,
              icon: LucideIcons.cloud_upload,
            ),
          ),
          if (lastAutoBackupUsedFallback &&
              lastAutoBackupDirUsed != null &&
              lastAutoBackupDirUsed!.isNotEmpty) ...[
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              'Fallback folder used:\n$lastAutoBackupDirUsed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (lastAutoBackupFilePath != null &&
              lastAutoBackupFilePath!.isNotEmpty) ...[
            const SizedBox(height: DesignConstants.spacingS),
            SelectableText(
              lastAutoBackupFilePath!,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
