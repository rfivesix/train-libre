import 'package:flutter/material.dart';
import '../../../../widgets/common/app_link_row.dart';
import '../../../../generated/app_localizations.dart';

class MigrationCard extends StatelessWidget {
  const MigrationCard({
    super.key,
    required this.isMigrationRunning,
    required this.onImportPressed,
  });

  final bool isMigrationRunning;
  final VoidCallback? onImportPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppLinkRow(
      title: l10n.workoutImportTitle,
      subtitle: l10n.workoutImportDescription,
      onTap: isMigrationRunning ? () {} : (onImportPressed ?? () {}),
    );
  }
}
