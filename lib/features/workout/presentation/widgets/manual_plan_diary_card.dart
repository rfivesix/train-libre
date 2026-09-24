import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../data/manual_training_plan_repository.dart';
import '../../domain/models/manual_training_plan.dart';
import '../manual_plan_screen.dart';
import '../manual_plan_text.dart';
import 'manual_plan_ui.dart';

class ManualPlanDiaryCard extends StatefulWidget {
  const ManualPlanDiaryCard({super.key, required this.date});
  final DateTime date;

  @override
  State<ManualPlanDiaryCard> createState() => _ManualPlanDiaryCardState();
}

class _ManualPlanDiaryCardState extends State<ManualPlanDiaryCard> {
  final _repository = ManualTrainingPlanRepository();
  int _refresh = 0;

  Future<(ManualTrainingPlan, PlannedCalendarDay)?> _load() async {
    final plan = await _repository.activePlan();
    if (plan == null) return null;
    final days = await _repository.calendar(plan.id, widget.date, widget.date);
    if (days.isEmpty) return null;
    return (plan, days.first);
  }

  @override
  Widget build(BuildContext context) {
    final text = ManualPlanText(context);
    return FutureBuilder<(ManualTrainingPlan, PlannedCalendarDay)?>(
      key: ValueKey((widget.date, _refresh)),
      future: _load(),
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result == null) return const SizedBox.shrink();
        final plan = result.$1;
        final day = result.$2;
        final today = DateUtils.isSameDay(widget.date, DateTime.now());
        final metadata = plannedDayMetadata(context, day.day);
        final subtitle = day.day.isRest
            ? text.get('restDescription')
            : metadata.isEmpty
                ? text.get(day.status.name)
                : '$metadata · ${text.get(day.status.name)}';
        final canStart =
            today && !day.day.isRest && day.status == PlannedDayStatus.planned;
        final theme = Theme.of(context);
        return SummaryCard(
          padding: EdgeInsets.zero,
          margin:
              const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
          child: ListTile(
            onTap: () async {
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManualPlanScreen()));
              if (mounted) setState(() => _refresh++);
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingM,
              vertical: DesignConstants.screenPaddingVertical,
            ),
            title: Text(
              day.day.routineName ?? text.get('rest'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: canStart
                ? AppButton.primary(
                    label: text.get('start'),
                    icon: LucideIcons.play,
                    size: AppButtonSize.small,
                    onPressed: () async {
                      await startManualPlanDay(context, plan, day);
                      if (mounted) setState(() => _refresh++);
                    },
                  )
                : Icon(
                    LucideIcons.chevron_right,
                    color: theme.colorScheme.onSurface,
                  ),
          ),
        );
      },
    );
  }
}
