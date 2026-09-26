import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/haptic_feedback_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../domain/models/manual_training_plan.dart';
import '../../domain/models/routine_exercise.dart';
import '../manual_plan_text.dart';

int plannedExerciseCount(TrainingPlanDay day) =>
    day.routine?.exercises.length ?? 0;

int plannedSetCount(TrainingPlanDay day) =>
    day.routine?.exercises.fold<int>(
      0,
      (total, exercise) => total + exercise.setTemplates.length,
    ) ??
    0;

String plannedDayMetadata(BuildContext context, TrainingPlanDay day) {
  if (day.isRest) return '';
  final text = ManualPlanText(context);
  final l10n = AppLocalizations.of(context)!;
  return '${plannedExerciseCount(day)} ${text.get('exercises')}'
      '${DesignConstants.metadataSeparator}${l10n.setCount(plannedSetCount(day))}';
}

/// Permanent card displaying the authored template of a plan directly beneath
/// the plan header, with an explicit edit action in its header.
class PlanOverviewCard extends StatelessWidget {
  const PlanOverviewCard({
    super.key,
    required this.plan,
    this.activeSlotIndex,
    required this.onEdit,
  });

  final ManualTrainingPlan plan;
  final int? activeSlotIndex;
  final ValueChanged<BuildContext> onEdit;

  @override
  Widget build(BuildContext context) {
    final text = ManualPlanText(context);
    final theme = Theme.of(context);

    return SummaryCard(
      key: const Key('manual_plan_overview_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                text.get('planOverview'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Builder(
                builder: (editButtonContext) => IconButton(
                  key: const Key('manual_plan_overview_edit_button'),
                  tooltip: text.get('edit'),
                  icon: const Icon(LucideIcons.pencil, size: 20),
                  onPressed: () => onEdit(editButtonContext),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingM),
          PlanScheduleOverviewGrid(
            plan: plan,
            activeSlotIndex: activeSlotIndex,
          ),
        ],
      ),
    );
  }
}

/// Shows the authored structure of a plan independently from the dates and
/// completion states projected in the calendar below it. It deliberately uses
/// the app-wide two-column value grid, rather than introducing another card
/// hierarchy above the calendar.
class PlanScheduleOverviewGrid extends StatelessWidget {
  const PlanScheduleOverviewGrid({
    super.key,
    required this.plan,
    this.activeSlotIndex,
  });

  final ManualTrainingPlan plan;
  final int? activeSlotIndex;

  @override
  Widget build(BuildContext context) {
    final text = ManualPlanText(context);
    final locale = Localizations.localeOf(context).toString();
    final tiles = [
      for (var index = 0; index < plan.days.length; index++)
        _PlanScheduleOverviewTile(
          label: _labelFor(index, locale, text),
          day: plan.days[index],
          isActive: plan.active && activeSlotIndex == index,
        ),
    ];

    final rows = <Widget>[];
    for (var index = 0; index < tiles.length; index += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[index]),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                child: index + 1 < tiles.length
                    ? tiles[index + 1]
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      );
      if (index + 2 < tiles.length) {
        rows.add(const SizedBox(height: DesignConstants.spacingS));
      }
    }

    return Semantics(
      container: true,
      label: text.get('planOverview'),
      child: Column(
        key: const Key('plan_schedule_overview_grid'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }

  String _labelFor(int index, String locale, ManualPlanText text) {
    if (plan.kind == TrainingPlanKind.sequence) {
      return '${text.get('day')} ${index + 1}';
    }
    // 21 September 2026 is a Monday; this lets Intl localize the weekday
    // without tying the overview to a particular calendar week.
    return DateFormat.E(locale).format(DateTime(2026, 9, 21 + index));
  }
}

class _PlanScheduleOverviewTile extends StatelessWidget {
  const _PlanScheduleOverviewTile({
    required this.label,
    required this.day,
    required this.isActive,
  });

  final String label;
  final TrainingPlanDay day;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final text = ManualPlanText(context);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Semantics(
      label: '$label, ${day.routineName ?? text.get('rest')}'
          '${isActive ? ', ${text.get('nextUp')}' : ''}',
      child: ValueSummaryCard(
        label: label,
        value: day.routineName ?? text.get('rest'),
        useSecondarySurface: true,
        valueColor: isActive
            ? accent
            : (day.isRest
                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                : null),
        backgroundColor: isActive ? accent.withValues(alpha: 0.14) : null,
      ),
    );
  }
}

class PlanStatusIndicator extends StatelessWidget {
  const PlanStatusIndicator({
    super.key,
    required this.status,
    this.compact = false,
  });

  final PlannedDayStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (status) {
      PlannedDayStatus.completed => (
          LucideIcons.circle_check,
          theme.colorScheme.primary
        ),
      PlannedDayStatus.partial => (
          LucideIcons.circle_dot,
          theme.colorScheme.tertiary
        ),
      PlannedDayStatus.skipped => (
          LucideIcons.skip_forward,
          theme.colorScheme.onSurfaceVariant
        ),
      PlannedDayStatus.rest => (
          LucideIcons.minus,
          theme.colorScheme.onSurfaceVariant
        ),
      PlannedDayStatus.ongoing => (
          LucideIcons.timer,
          theme.colorScheme.primary
        ),
      PlannedDayStatus.planned => (
          LucideIcons.circle,
          theme.colorScheme.onSurfaceVariant
        ),
    };
    final label = ManualPlanText(context).get(status.name);
    if (compact) {
      return Tooltip(
        message: label,
        child: Icon(icon, size: 16, color: color),
      );
    }
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The plan's date entry point intentionally mirrors the Diary's calendar
/// control, while opening the plan-specific week picker.
class PlanCalendarPickerButton extends StatelessWidget {
  const PlanCalendarPickerButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.brightness == Brightness.dark
        ? DesignConstants.summaryCardDarkMode
        : Colors.white;
    return Tooltip(
      message: AppLocalizations.of(context)!.selectDateTitle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
          child: InkWell(
            onTap: () {
              HapticFeedbackService.instance.selectionFeedback();
              onPressed();
            },
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            child: SizedBox(
              width: 44,
              height: 48,
              child: Icon(
                LucideIcons.calendar_days,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlanWeekStrip extends StatelessWidget {
  const PlanWeekStrip({
    super.key,
    required this.dates,
    required this.days,
    required this.selectedDate,
    required this.onSelected,
    this.nextDate,
  });

  final List<DateTime> dates;
  final Map<DateTime, PlannedCalendarDay> days;
  final DateTime? selectedDate;
  final DateTime? nextDate;
  final ValueChanged<DateTime> onSelected;

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return SizedBox(
      height: 68,
      child: Row(
        children: [
          for (final date in dates)
            Expanded(
              child: _PlanDayCell(
                date: date,
                day: days[_day(date)],
                weekday: DateFormat.E(locale).format(date),
                selected: selectedDate != null &&
                    DateUtils.isSameDay(date, selectedDate),
                today: DateUtils.isSameDay(date, DateTime.now()),
                next: nextDate != null && DateUtils.isSameDay(date, nextDate),
                onTap: days[_day(date)] == null
                    ? null
                    : () {
                        HapticFeedbackService.instance.selectionFeedback();
                        onSelected(date);
                      },
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanDayCell extends StatelessWidget {
  const _PlanDayCell({
    required this.date,
    required this.day,
    required this.weekday,
    required this.selected,
    required this.today,
    required this.next,
    required this.onTap,
  });

  final DateTime date;
  final PlannedCalendarDay? day;
  final String weekday;
  final bool selected;
  final bool today;
  final bool next;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final disabled = day == null;
    final foreground = selected
        ? colorScheme.onPrimary
        : disabled
            ? theme.disabledColor
            : colorScheme.onSurface;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '${DateFormat.EEEE(locale).format(date)}, '
          '${DateFormat.yMMMd(locale).format(date)}'
          '${day == null ? '' : ', ${ManualPlanText(context).get(day!.status.name)}'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          selected ? colorScheme.primary : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(DesignConstants.borderRadiusM),
                      border: today && !selected
                          ? Border.all(color: colorScheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekday.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          DateFormat.d(locale).format(date),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  _PlanDayMarker(
                    day: day,
                    selected: selected,
                    next: next,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanDayMarker extends StatelessWidget {
  const _PlanDayMarker({
    required this.day,
    required this.selected,
    required this.next,
  });

  final PlannedCalendarDay? day;
  final bool selected;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (day == null) return const SizedBox(height: 5);
    final color = selected
        ? colors.primary
        : switch (day!.status) {
            PlannedDayStatus.completed => colors.primary,
            PlannedDayStatus.partial => colors.tertiary,
            PlannedDayStatus.ongoing => colors.primary,
            PlannedDayStatus.skipped => colors.onSurfaceVariant,
            PlannedDayStatus.rest => colors.onSurfaceVariant,
            PlannedDayStatus.planned => next
                ? colors.primary
                : colors.onSurfaceVariant.withValues(alpha: 0.45),
          };
    if (day!.status == PlannedDayStatus.rest) {
      return Container(
        width: 10,
        height: 2,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class PlanDayDetailCard extends StatelessWidget {
  const PlanDayDetailCard({
    super.key,
    required this.plan,
    required this.day,
    this.onStart,
    this.onSkip,
    this.onViewWorkout,
  });

  final ManualTrainingPlan plan;
  final PlannedCalendarDay day;
  final VoidCallback? onStart;
  final VoidCallback? onSkip;
  final VoidCallback? onViewWorkout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = ManualPlanText(context);
    final metadata = plannedDayMetadata(context, day.day);
    final sequenceLabel = plan.kind == TrainingPlanKind.sequence
        ? '${text.get('day')} ${day.slotIndex + 1} ${DesignConstants.metadataSeparator}${plan.days.length} ${text.get('days')}'
        : null;

    return SummaryCard(
      margin: const EdgeInsets.only(top: DesignConstants.spacingM),
      padding: const EdgeInsets.all(DesignConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (sequenceLabel != null)
                Expanded(
                  child: Text(
                    sequenceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                const Spacer(),
              PlanStatusIndicator(status: day.status),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            day.day.routineName ?? text.get('rest'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          if (metadata.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              metadata,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
          if (!day.day.isRest &&
              day.day.routine?.exercises.isNotEmpty == true) ...[
            const SizedBox(height: DesignConstants.spacingM),
            for (final exercise in day.day.routine!.exercises)
              _PlanExerciseRow(exercise: exercise),
          ],
          if (onStart != null) ...[
            const SizedBox(height: DesignConstants.spacingL),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: text.get('start'),
                onPressed: onStart,
              ),
            ),
            if (onSkip != null)
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: onSkip,
                  child: Text(text.get('skip')),
                ),
              ),
          ],
          if (onStart == null && onViewWorkout != null) ...[
            const SizedBox(height: DesignConstants.spacingL),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: text.get('viewWorkout'),
                onPressed: onViewWorkout,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanExerciseRow extends StatelessWidget {
  const _PlanExerciseRow({required this.exercise});

  final RoutineExercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              exercise.exercise.localizedNameFor(locale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: DesignConstants.spacingM),
          Text(
            l10n.setCount(exercise.setTemplates.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutPlanHeroCard extends StatelessWidget {
  const WorkoutPlanHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.status,
    this.onTap,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final PlannedDayStatus? status;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel =
        status == null ? null : ManualPlanText(context).get(status!.name);
    final semanticStatus = statusLabel == null ||
            subtitle.toLowerCase().contains(statusLabel.toLowerCase())
        ? ''
        : ', $statusLabel';
    return SummaryCard(
      margin: const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: onTap != null,
            label: '$eyebrow, $title, $subtitle$semanticStatus',
            excludeSemantics: true,
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusL),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(
                  compact ? DesignConstants.spacingM : DesignConstants.spacingL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            eyebrow.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                        if (status != null)
                          PlanStatusIndicator(status: status!, compact: compact)
                        else
                          Icon(
                            LucideIcons.chevron_right,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                    SizedBox(height: compact ? 5 : DesignConstants.spacingS),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: (compact
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.headlineSmall)
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: compact ? null : -0.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.66),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? DesignConstants.spacingM : DesignConstants.spacingL,
                0,
                compact ? DesignConstants.spacingM : DesignConstants.spacingL,
                compact ? DesignConstants.spacingM : DesignConstants.spacingL,
              ),
              child: compact
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: AppButton.primary(
                        label: actionLabel!,
                        onPressed: onAction,
                        size: AppButtonSize.small,
                      ),
                    )
                  : AppButton.primary(
                      label: actionLabel!,
                      onPressed: onAction,
                    ),
            ),
        ],
      ),
    );
  }
}
