import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../data/manual_training_plan_repository.dart';
import '../../domain/models/manual_training_plan.dart';
import '../manual_plan_screen.dart';
import '../manual_plan_text.dart';

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
        return SummaryCard(
            child: Row(children: [
          const Icon(LucideIcons.calendar_days),
          const SizedBox(width: DesignConstants.spacingM),
          Expanded(
              child: InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManualPlanScreen()));
              if (mounted) setState(() => _refresh++);
            },
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan.name, style: Theme.of(context).textTheme.titleSmall),
              Text(day.day.routineName ?? text.get('rest'),
                  style: Theme.of(context).textTheme.titleMedium),
              if (!day.day.isRest)
                Text(text.get(day.status.name),
                    style: Theme.of(context).textTheme.bodySmall),
            ]),
          )),
          if (today && day.status == PlannedDayStatus.planned)
            AppButton.primary(
              label: text.get('start'),
              size: AppButtonSize.small,
              onPressed: () async {
                await startManualPlanDay(context, plan, day);
                if (mounted) setState(() => _refresh++);
              },
            ),
        ]));
      },
    );
  }
}
