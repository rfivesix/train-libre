import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class CsvExportCard extends StatelessWidget {
  const CsvExportCard({
    super.key,
    required this.isCsvExportRunning,
    required this.onExcelExportPressed,
    required this.onNutritionExportPressed,
    required this.onMeasurementsExportPressed,
    required this.onWorkoutsExportPressed,
  });

  final bool isCsvExportRunning;
  final VoidCallback? onExcelExportPressed;
  final VoidCallback? onNutritionExportPressed;
  final VoidCallback? onMeasurementsExportPressed;
  final VoidCallback? onWorkoutsExportPressed;

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
              l10n.csvExportTitle,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.csvExportDescription,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignConstants.spacingS),
            _buildExportTile(
              icon: LucideIcons.table,
              title: l10n.excelExportButton,
              onTap: isCsvExportRunning ? null : onExcelExportPressed,
            ),
            const Divider(),
            _buildExportTile(
              icon: LucideIcons.utensils,
              title: l10n.nutritionDiary,
              onTap: isCsvExportRunning ? null : onNutritionExportPressed,
            ),
            _buildExportTile(
              icon: LucideIcons.scale,
              title: l10n.drawerMeasurements,
              onTap: isCsvExportRunning ? null : onMeasurementsExportPressed,
            ),
            _buildExportTile(
              icon: LucideIcons.dumbbell,
              title: l10n.workoutHistoryTitle,
              onTap: isCsvExportRunning ? null : onWorkoutsExportPressed,
            ),
            if (isCsvExportRunning)
              const Padding(
                padding: EdgeInsets.only(top: DesignConstants.spacingL),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTile({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(LucideIcons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
