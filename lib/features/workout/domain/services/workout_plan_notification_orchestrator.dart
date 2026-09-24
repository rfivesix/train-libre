import 'package:shared_preferences/shared_preferences.dart';

import '../../data/manual_training_plan_repository.dart';
import '../models/manual_training_plan.dart';
import '../workout_plan_notification_scheduler.dart';
import '../../../../services/local_notification_service.dart';

typedef WorkoutPlanPreferencesLoader = Future<SharedPreferences> Function();

/// Keeps the finite set of local plan reminders in sync with the active plan.
///
/// Reminders are intentionally opt-in and are only created for upcoming,
/// unresolved workout days. Past sessions never generate catch-up prompts.
class WorkoutPlanNotificationOrchestrator {
  WorkoutPlanNotificationOrchestrator({
    ManualTrainingPlanRepository? repository,
    WorkoutPlanNotificationScheduler? scheduler,
    WorkoutPlanPreferencesLoader? preferencesLoader,
    DateTime Function()? clock,
  })  : _repository = repository ?? ManualTrainingPlanRepository(),
        _scheduler = scheduler ?? LocalNotificationService.instance,
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _clock = clock ?? DateTime.now;

  static const enabledPreference = 'notify_workout_plan';
  static const hourPreference = 'notify_workout_plan_hour';
  static const minutePreference = 'notify_workout_plan_minute';
  static const defaultHour = 18;
  static const defaultMinute = 0;
  static const horizonDays = 28;

  final ManualTrainingPlanRepository _repository;
  final WorkoutPlanNotificationScheduler _scheduler;
  final WorkoutPlanPreferencesLoader _preferencesLoader;
  final DateTime Function() _clock;

  Future<void> synchronize() async {
    final preferences = await _preferencesLoader();
    if (!(preferences.getBool(enabledPreference) ?? false)) {
      await _scheduler.cancelWorkoutPlanReminders();
      return;
    }

    final plan = await _repository.activePlan();
    if (plan == null) {
      await _scheduler.cancelWorkoutPlanReminders();
      return;
    }

    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final through = DateTime(today.year, today.month, today.day + horizonDays);
    final hour =
        (preferences.getInt(hourPreference) ?? defaultHour).clamp(0, 23);
    final minute =
        (preferences.getInt(minutePreference) ?? defaultMinute).clamp(0, 59);
    final days = await _repository.calendar(plan.id, today, through);
    final reminders = <WorkoutPlanReminder>[];

    for (final day in days) {
      if (day.day.isRest || day.status != PlannedDayStatus.planned) continue;
      final scheduledAt = DateTime(
        day.date.year,
        day.date.month,
        day.date.day,
        hour,
        minute,
      );
      if (!scheduledAt.isAfter(now)) continue;
      reminders.add(WorkoutPlanReminder(
        planId: plan.id,
        planName: plan.name,
        routineName: day.day.routineName ?? plan.name,
        scheduledAt: scheduledAt,
      ));
    }

    await _scheduler.replaceWorkoutPlanReminders(reminders);
  }
}
