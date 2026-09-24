import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/haptic_feedback_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/summary_card.dart';
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
  });

  final ManualTrainingPlan plan;
  final PlannedCalendarDay day;
  final VoidCallback? onStart;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = ManualPlanText(context);
    final locale = Localizations.localeOf(context).toString();
    final metadata = plannedDayMetadata(context, day.day);
    final relativeLabel = DateUtils.isSameDay(day.date, DateTime.now())
        ? text.get('today')
        : DateFormat.EEEE(locale).format(day.date);
    final sequenceLabel = plan.kind == TrainingPlanKind.sequence
        ? '${text.get('day')} ${day.slotIndex + 1} ${DesignConstants.metadataSeparator}${plan.days.length} ${text.get('days')}'
        : DateFormat.yMMMd(locale).format(day.date);

    return SummaryCard(
      margin: const EdgeInsets.only(top: DesignConstants.spacingM),
      padding: const EdgeInsets.all(DesignConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$relativeLabel ${DesignConstants.metadataSeparator}$sequenceLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
          const SizedBox(height: DesignConstants.spacingM),
          Text(
            _description(text),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          if (!day.day.isRest &&
              day.day.routine?.exercises.isNotEmpty == true) ...[
            const SizedBox(height: DesignConstants.spacingL),
            Divider(color: theme.dividerColor.withValues(alpha: 0.45)),
            const SizedBox(height: DesignConstants.spacingS),
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
        ],
      ),
    );
  }

  String _description(ManualPlanText text) => day.day.isRest
      ? text.get('restDescription')
      : switch (day.status) {
          PlannedDayStatus.completed => text.get('completedDescription'),
          PlannedDayStatus.partial => text.get('partialDescription'),
          PlannedDayStatus.skipped => text.get('skippedDescription'),
          PlannedDayStatus.ongoing => text.get('todayDescription'),
          PlannedDayStatus.rest => text.get('restDescription'),
          PlannedDayStatus.planned => day.date.isAfter(DateTime.now())
              ? text.get('futureDescription')
              : DateUtils.isSameDay(day.date, DateTime.now())
                  ? text.get('todayDescription')
                  : text.get('pastOpenDescription'),
        };
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
                        icon: LucideIcons.play,
                        onPressed: onAction,
                        size: AppButtonSize.small,
                      ),
                    )
                  : AppButton.primary(
                      label: actionLabel!,
                      icon: LucideIcons.play,
                      onPressed: onAction,
                    ),
            ),
        ],
      ),
    );
  }
}
