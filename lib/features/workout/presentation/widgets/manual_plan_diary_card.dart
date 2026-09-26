import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/card_morph_route.dart';
import '../../../../widgets/common/morph_source.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../data/manual_training_plan_repository.dart';
import '../../domain/models/manual_training_plan.dart';
import '../manual_plan_screen.dart';
import '../manual_plan_text.dart';
import 'manual_plan_ui.dart';

class ManualPlanDiaryCard extends StatefulWidget {
  const ManualPlanDiaryCard({
    super.key,
    required this.date,
    this.fallback,
  });

  final DateTime date;
  final Widget? fallback;

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
        if (result == null) {
          if (snapshot.connectionState == ConnectionState.done) {
            return widget.fallback ?? const SizedBox.shrink();
          }
          return const SizedBox.shrink();
        }
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
        final l10n = AppLocalizations.of(context)!;
        Widget buildCard({VoidCallback? onTap, VoidCallback? onStart}) =>
            SummaryCard(
              padding: EdgeInsets.zero,
              margin: const EdgeInsets.symmetric(
                vertical: DesignConstants.spacingXS,
              ),
              child: Semantics(
                button: true,
                container: true,
                label: '${day.day.routineName ?? text.get('rest')}, $subtitle',
                child: InkWell(
                  onTap: onTap,
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusL),
                  child: Padding(
                    // Keep every edge identical, like the Weight card.
                    padding: const EdgeInsets.all(DesignConstants.spacingM),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
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
                              const SizedBox(
                                height: DesignConstants.spacingXS,
                              ),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: DesignConstants.spacingM),
                        canStart
                            ? FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: DesignConstants.spacingM,
                                  ),
                                  textStyle:
                                      theme.textTheme.labelLarge?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      DesignConstants.borderRadiusM,
                                    ),
                                  ),
                                ),
                                onPressed: onStart,
                                child: Text(l10n.startButton),
                              )
                            : Icon(
                                LucideIcons.chevron_right,
                                color: theme.colorScheme.onSurface,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            );

        return MorphSourceScope(
          builder: (context, setHidden) => Builder(
            builder: (cardContext) => buildCard(
              onTap: () async {
                await Navigator.of(context).push(
                  CardMorphRoute(
                    sourceContext: cardContext,
                    sourceBuilder: (_) => buildCard(
                      onStart: canStart ? () {} : null,
                    ),
                    onSourceVisibilityChanged: setHidden,
                    builder: (_) => const ManualPlanScreen(),
                  ),
                );
                if (mounted) setState(() => _refresh++);
              },
              onStart: canStart
                  ? () async {
                      await startManualPlanDay(
                        context,
                        plan,
                        day,
                        sourceRect: CardMorphRoute.measureRect(cardContext),
                        sourceBuilder: (_) => buildCard(onStart: () {}),
                        onSourceVisibilityChanged: setHidden,
                      );
                      if (mounted) setState(() => _refresh++);
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }
}
