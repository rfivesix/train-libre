class WorkoutPlanReminder {
  const WorkoutPlanReminder({
    required this.planId,
    required this.planName,
    required this.routineName,
    required this.scheduledAt,
  });

  final String planId;
  final String planName;
  final String routineName;
  final DateTime scheduledAt;
}

abstract interface class WorkoutPlanNotificationScheduler {
  Future<void> replaceWorkoutPlanReminders(
    List<WorkoutPlanReminder> reminders,
  );

  Future<void> cancelWorkoutPlanReminders();
}
