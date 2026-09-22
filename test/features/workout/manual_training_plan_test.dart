import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/workout/data/manual_training_plan_repository.dart';
import 'package:train_libre/features/workout/domain/models/manual_training_plan.dart';

void main() {
  late AppDatabase database;
  late ManualTrainingPlanRepository repository;
  const workout = TrainingPlanDay(routineSnapshot: {
    'id': 1,
    'name': 'A',
    'exercises': [],
  });
  const rest = TrainingPlanDay();

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ManualTrainingPlanRepository(database: database);
  });

  tearDown(() async => database.close());

  test('weekly slots stay on weekdays after a missed day', () async {
    final id = await repository.createPlan(
      name: 'Week',
      kind: TrainingPlanKind.week,
      days: List.filled(7, workout),
    );
    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final days = await repository.calendar(id, today, tomorrow);
    expect(days, hasLength(2));
    expect(days.first.slotIndex, today.weekday - 1);
    expect(days.last.slotIndex, tomorrow.weekday - 1);
    expect(days.last.status, PlannedDayStatus.planned);
  });

  test('calendar does not project plan days before the first activation',
      () async {
    final id = await repository.createPlan(
      name: 'Week',
      kind: TrainingPlanKind.week,
      days: List.filled(7, workout),
    );
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    final days = await repository.calendar(id, yesterday, today);

    expect(days, hasLength(1));
    expect(DateUtils.isSameDay(days.single.date, today), isTrue);
  });

  test('sequence holds a missed workout until explicit skip', () async {
    final id = await repository.createPlan(
      name: 'Sequence',
      kind: TrainingPlanKind.sequence,
      days: [workout, rest],
    );
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final activation =
        await database.select(database.trainingPlanActivations).getSingle();
    await (database.update(database.trainingPlanActivations)
          ..where((row) => row.id.equals(activation.id)))
        .write(TrainingPlanActivationsCompanion(
            startedOn: drift.Value(yesterday)));
    final plan = (await repository.activePlan())!;
    var days = await repository.calendar(id, yesterday, today);
    expect(days.map((day) => day.slotIndex), [0, 0]);
    await repository.skip(plan, days.first);
    days = await repository.calendar(id, yesterday, today);
    expect(days.first.status, PlannedDayStatus.skipped);
    expect(days.last.slotIndex, 1);
    expect(days.last.status, PlannedDayStatus.rest);
  });

  test('edits append revisions without changing earlier calendar days',
      () async {
    final today = DateTime.now();
    final id = await repository.createPlan(
      name: 'Week',
      kind: TrainingPlanKind.week,
      days: List.filled(7, workout),
    );
    await repository.revisePlan(
      planId: id,
      name: 'Week edited',
      kind: TrainingPlanKind.week,
      days: [rest, workout, workout, workout, workout, workout, workout],
      nextCycle: true,
    );
    expect(await repository.revisions(id), hasLength(2));
    final days = await repository.calendar(id, today, today);
    expect(days.single.day.isRest, false);
  });

  test('only the linked workout resolves a plan occurrence', () async {
    const prescribed = TrainingPlanDay(routineSnapshot: {
      'name': 'Push',
      'exercises': [
        {
          'exercise': {
            'id': 1,
            'uuid': 'exercise-1',
            'source': 'user',
            'texts': {
              'en': {'name': 'Press', 'description': ''}
            },
            'category_name': '',
            'primaryMuscles': <String>[],
            'secondaryMuscles': <String>[],
          },
          'setTemplates': [
            {
              'id': 1,
              'set_type': 'normal',
              'target_reps': '8-12',
            }
          ],
        }
      ],
    });
    final id = await repository.createPlan(
      name: 'Linked',
      kind: TrainingPlanKind.sequence,
      days: const [prescribed],
    );
    final plan = (await repository.activePlan())!;
    final today = DateTime.now();

    await database.into(database.workoutLogs).insert(
          WorkoutLogsCompanion.insert(
            startTime: today,
            status: const drift.Value('completed'),
          ),
        );
    expect(
      (await repository.calendar(id, today, today)).single.status,
      PlannedDayStatus.planned,
    );

    final day = (await repository.calendar(id, today, today)).single;
    final started = await repository.start(plan, day);
    for (var index = 0; index < 2; index++) {
      await database.into(database.setLogs).insert(
            SetLogsCompanion.insert(
              workoutLogId: started.log.id,
              exerciseNameSnapshot: const drift.Value('Press'),
              isCompleted: const drift.Value(true),
              exerciseBlock: const drift.Value(0),
              logOrder: drift.Value(index),
            ),
          );
    }
    await (database.update(database.workoutLogs)
          ..where((row) => row.id.equals(started.log.id)))
        .write(const WorkoutLogsCompanion(status: drift.Value('completed')));
    await repository.reconcileWorkout(started.log.localId);

    expect(
      (await repository.calendar(id, today, today)).single.status,
      PlannedDayStatus.completed,
    );
  });
}
