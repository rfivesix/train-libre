import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../generated/app_localizations.dart';
import '../../util/design_constants.dart';
import '../../core/infrastructure/basis_data_manager.dart';

class DatabasePlaceholderWidget extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final VoidCallback? onDownloadPressed;

  const DatabasePlaceholderWidget({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    this.onDownloadPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignConstants.spacingXL),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.all(DesignConstants.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                icon,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: DesignConstants.spacingL),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignConstants.spacingM),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignConstants.spacingXL),
              FilledButton.icon(
                onPressed: onDownloadPressed ?? () async {
                  await BasisDataManager.instance.promptOffDatabaseDownloadIfFirstTime(context);
                },
                icon: const Icon(LucideIcons.download),
                label: Text(l10n.offDownloadCTA),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
