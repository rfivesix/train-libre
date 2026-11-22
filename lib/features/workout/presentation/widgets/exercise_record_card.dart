import 'package:material_ui/material_ui.dart';

import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import 'exercise_record_data.dart';

/// Displays all personal records achieved for a single exercise in a workout
/// summary or detail screen, with an amber outline and aligned metric rows.
class ExerciseRecordCard extends StatelessWidget {
  final String exerciseName;
  final List<ExerciseRecordData> records;
  final UnitService unitService;

  const ExerciseRecordCard({
    super.key,
    required this.exerciseName,
    required this.records,
    required this.unitService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return SummaryCard(
      borderColor: Colors.amber.withValues(alpha: isDark ? 0.35 : 0.25),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingM,
        vertical: DesignConstants.spacingS + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exerciseName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXS),
          for (var i = 0; i < records.length; i++) ...[
            if (i > 0) const SizedBox(height: 3),
            _RecordRow(
              record: records[i],
              unitService: unitService,
              mutedColor: mutedColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final ExerciseRecordData record;
  final UnitService unitService;
  final Color mutedColor;

  const _RecordRow({
    required this.record,
    required this.unitService,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueText = record.formatValue(unitService);
    final diffText = record.formatDiff(unitService);

    return Row(
      children: [
        Expanded(
          child: Text(
            record.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: DesignConstants.spacingS),
        Text(
          valueText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (diffText != null) ...[
          const SizedBox(width: DesignConstants.spacingS),
          Text(
            diffText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: mutedColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}
