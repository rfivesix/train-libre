import 'package:flutter/material.dart';
import '../../../../widgets/common/app_link_row.dart';

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
    return AppLinkRow(
      title: "External Workout Import",
      subtitle: "Import your training history from a CSV or Excel export file.",
      onTap: isMigrationRunning ? () {} : (onImportPressed ?? () {}),
    );
  }
}
