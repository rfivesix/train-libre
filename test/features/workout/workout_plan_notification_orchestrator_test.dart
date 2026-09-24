import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/workout/data/manual_training_plan_repository.dart';
import 'package:train_libre/features/workout/domain/models/manual_training_plan.dart';
import 'package:train_libre/features/workout/domain/services/workout_plan_notification_orchestrator.dart';
import 'package:train_libre/features/workout/domain/workout_plan_notification_scheduler.dart';

class _RecordingScheduler implements WorkoutPlanNotificationScheduler {
  List<WorkoutPlanReminder> reminders = [];
  int cancelCount = 0;

  @override
  Future<void> cancelWorkoutPlanReminders() async {
    cancelCount++;
    reminders = [];
  }

  @override
  Future<void> replaceWorkoutPlanReminders(
      List<WorkoutPlanReminder> reminders) async {
    this.reminders = List.of(reminders);
  }
}

void main() {
  late AppDatabase database;
  late ManualTrainingPlanRepository repository;
  late _RecordingScheduler scheduler;

  const workout = TrainingPlanDay(routineSnapshot: {
    'id': 1,
    'name': 'Full Body',
    'exercises': [],
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase(NativeDatabase.memory());
    repository = ManualTrainingPlanRepository(database: database);
    scheduler = _RecordingScheduler();
  });

  tearDown(() => database.close());

  test('reminders are opt-in and disabled state clears pending requests',
      () async {
    await repository.createPlan(
      name: 'Plan',
      kind: TrainingPlanKind.week,
      days: List.filled(7, workout),
    );
    await WorkoutPlanNotificationOrchestrator(
      repository: repository,
      scheduler: scheduler,
    ).synchronize();

    expect(scheduler.cancelCount, 1);
    expect(scheduler.reminders, isEmpty);
  });

  test('enabled reminders use the chosen time and never schedule the past',
      () async {
    final now = DateTime.now();
    final todayAtTen = DateTime(now.year, now.month, now.day, 10);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        WorkoutPlanNotificationOrchestrator.enabledPreference, true);
    await prefs.setInt(WorkoutPlanNotificationOrchestrator.hourPreference, 18);
    await prefs.setInt(
        WorkoutPlanNotificationOrchestrator.minutePreference, 15);
    await repository.createPlan(
      name: 'Plan',
      kind: TrainingPlanKind.week,
      days: List.filled(7, workout),
    );

    await WorkoutPlanNotificationOrchestrator(
      repository: repository,
      scheduler: scheduler,
      clock: () => todayAtTen,
    ).synchronize();

    expect(scheduler.reminders, isNotEmpty);
    expect(scheduler.reminders.first.scheduledAt.hour, 18);
    expect(scheduler.reminders.first.scheduledAt.minute, 15);
    expect(
      scheduler.reminders
          .every((reminder) => reminder.scheduledAt.isAfter(todayAtTen)),
      isTrue,
    );
  });
}
