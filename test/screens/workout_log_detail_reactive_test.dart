import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:train_libre/features/workout/domain/repositories/workout_repository.dart';
import 'package:train_libre/features/workout/data/workout_repository.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/presentation/workout_log_detail_screen.dart';
import 'package:train_libre/features/workout/presentation/widgets/workout_exercise_log_card.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:train_libre/services/experience_level_service.dart';
import 'package:train_libre/services/theme_service.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child, IWorkoutRepository repo) {
  return MultiProvider(
    providers: [
      Provider<IWorkoutRepository>.value(value: repo),
      ChangeNotifierProvider(create: (_) => ThemeService()),
      ChangeNotifierProvider(create: (_) => UnitService()),
      ChangeNotifierProvider(create: (_) => ExperienceLevelService()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late IWorkoutRepository repo;
  late String logUuid;
  late int logId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
    database = db.AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(database);

    // Insert a dummy workout directly into the DB so _loadDetails succeeds
    final row = await database
        .into(database.workoutLogs)
        .insertReturning(db.WorkoutLogsCompanion.insert(
          startTime: DateTime.now(),
          status: const drift.Value('completed'),
          routineNameSnapshot: const drift.Value('Test Routine'),
        ));
    logId = row.localId;
    logUuid = row.id;

    repo = WorkoutRepository(localDataSource: WorkoutLocalDataSource(database));
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('reactive propagation in read-only mode', (tester) async {
    await tester.pumpWidget(_wrap(WorkoutLogDetailScreen(logId: logId), repo));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsNothing);

    // Push new sets via real drift database
    await database.into(database.setLogs).insert(db.SetLogsCompanion.insert(
          workoutLogId: logUuid,
          exerciseNameSnapshot: const drift.Value('Bench Press'),
          setType: const drift.Value('normal'),
          weight: const drift.Value(100),
          reps: const drift.Value(10),
          restTimeSeconds: const drift.Value(60),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(0),
        ));

    // Wait for drift watch stream to propagate
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsWidgets);
    expect(find.textContaining('100'), findsWidgets); // Weight

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('edit-mode guard prevents overwrite during active typing',
      (tester) async {
    // Start with 1 set
    final setRow = await database
        .into(database.setLogs)
        .insertReturning(db.SetLogsCompanion.insert(
          workoutLogId: logUuid,
          exerciseNameSnapshot: const drift.Value('Bench Press'),
          setType: const drift.Value('normal'),
          weight: const drift.Value(100),
          reps: const drift.Value(10),
          restTimeSeconds: const drift.Value(60),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(0),
        ));

    // Use a tall viewport so ReorderableListView.builder renders all items eagerly
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(WorkoutLogDetailScreen(logId: logId), repo));
    await tester.pumpAndSettle();

    // Tap edit button to enter edit mode
    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();

    // The weight input field is keyed by set localId
    final weightFieldFinder =
        find.byKey(ValueKey('weight_input_${setRow.localId}'));

    // Verify the field is in the tree and shows the initial weight
    expect(weightFieldFinder, findsOneWidget);
    expect(find.textContaining('100'), findsWidgets);

    // Type a new weight
    await tester.enterText(weightFieldFinder, '105');
    await tester.pumpAndSettle();

    // Push new sets via DB (simulating a background sync or other device edit)
    await database.update(database.setLogs).replace(
        setRow.copyWith(weight: const drift.Value(110)) // Changed weight!
        );

    // Pump to process stream
    await tester.pumpAndSettle();

    // The text field should STILL have 105, because edit mode guarded the state
    expect(find.text('105'), findsWidgets);

    // Save to exit edit mode
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    final updatedSetInDb = await (database.select(database.setLogs)
          ..where((tbl) => tbl.localId.equals(setRow.localId)))
        .getSingle();
    expect(updatedSetInDb.weight, 105.0);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('same exercise in two blocks renders two independent cards',
      (tester) async {
    for (final block in [0, 2]) {
      await database.into(database.setLogs).insert(
            db.SetLogsCompanion.insert(
              workoutLogId: logUuid,
              exerciseNameSnapshot: const drift.Value('Bench Press'),
              setType: const drift.Value('normal'),
              weight: drift.Value(100 + block.toDouble()),
              reps: const drift.Value(10),
              isCompleted: const drift.Value(true),
              logOrder: drift.Value(block),
              exerciseBlock: drift.Value(block),
              supersetGroup: const drift.Value(5),
            ),
          );
    }

    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(WorkoutLogDetailScreen(logId: logId), repo));
    await tester.pumpAndSettle();

    final cards = tester.widgetList<WorkoutExerciseLogCard>(
      find.byType(WorkoutExerciseLogCard),
    );
    expect(cards.length, 2);
    expect(cards.map((card) => card.sets.single.exerciseBlock), [0, 2]);
    expect(cards.map((card) => card.supersetLabel), ['A1', 'A2']);
    expect(cards.map((card) => card.supersetColor), everyElement(isNotNull));

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('legacy rows without blocks still render one name-based card',
      (tester) async {
    for (var index = 0; index < 2; index++) {
      await database.into(database.setLogs).insert(
            db.SetLogsCompanion.insert(
              workoutLogId: logUuid,
              exerciseNameSnapshot: const drift.Value('Bench Press'),
              setType: const drift.Value('normal'),
              weight: drift.Value(100 + index.toDouble()),
              reps: const drift.Value(10),
              isCompleted: const drift.Value(true),
              logOrder: drift.Value(index),
            ),
          );
    }

    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(WorkoutLogDetailScreen(logId: logId), repo));
    await tester.pumpAndSettle();

    final cards = tester.widgetList<WorkoutExerciseLogCard>(
      find.byType(WorkoutExerciseLogCard),
    );
    expect(cards.length, 1);
    expect(cards.single.sets.length, 2);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('deleting a duplicate exercise removes only its block',
      (tester) async {
    for (final block in [0, 2]) {
      await database.into(database.setLogs).insert(
            db.SetLogsCompanion.insert(
              workoutLogId: logUuid,
              exerciseNameSnapshot: const drift.Value('Bench Press'),
              setType: const drift.Value('normal'),
              weight: drift.Value(100 + block.toDouble()),
              reps: const drift.Value(10),
              isCompleted: const drift.Value(true),
              logOrder: drift.Value(block),
              exerciseBlock: drift.Value(block),
            ),
          );
    }

    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(WorkoutLogDetailScreen(logId: logId), repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.pencil).first);
    await tester.pumpAndSettle();

    final firstCard = find.byType(WorkoutExerciseLogCard).first;
    final removeButton = find
        .descendant(
          of: firstCard,
          matching: find.byIcon(LucideIcons.trash),
        )
        .first;
    await tester.tap(removeButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    final remaining = await (database.select(database.setLogs)
          ..where((table) => table.workoutLogId.equals(logUuid)))
        .get();
    expect(remaining.map((set) => set.exerciseBlock), [2]);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('history edit mode persists a new superset connection',
      (tester) async {
    for (final entry in [(0, 'Bench Press'), (1, 'Squat')]) {
      await database.into(database.setLogs).insert(
            db.SetLogsCompanion.insert(
              workoutLogId: logUuid,
              exerciseNameSnapshot: drift.Value(entry.$2),
              setType: const drift.Value('normal'),
              weight: const drift.Value(100),
              reps: const drift.Value(10),
              isCompleted: const drift.Value(true),
              logOrder: drift.Value(entry.$1),
              exerciseBlock: drift.Value(entry.$1),
            ),
          );
    }

    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(WorkoutLogDetailScreen(logId: logId), repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.pencil).first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('history_superset_connector_0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    final saved = await (database.select(database.setLogs)
          ..where((table) => table.workoutLogId.equals(logUuid))
          ..orderBy([(table) => drift.OrderingTerm.asc(table.logOrder)]))
        .get();
    expect(saved.map((set) => set.supersetGroup).toSet().length, 1);
    expect(saved.first.supersetGroup, isNotNull);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('history split keeps both sides of a larger superset',
      (tester) async {
    for (final block in [0, 1, 2, 3]) {
      await database.into(database.setLogs).insert(
            db.SetLogsCompanion.insert(
              workoutLogId: logUuid,
              exerciseNameSnapshot: drift.Value('Exercise $block'),
              setType: const drift.Value('normal'),
              weight: const drift.Value(100),
              reps: const drift.Value(10),
              isCompleted: const drift.Value(true),
              logOrder: drift.Value(block),
              exerciseBlock: drift.Value(block),
              supersetGroup: const drift.Value(9),
            ),
          );
    }

    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(WorkoutLogDetailScreen(logId: logId), repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.pencil).first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('history_superset_connector_1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    final saved = await (database.select(database.setLogs)
          ..where((table) => table.workoutLogId.equals(logUuid))
          ..orderBy([(table) => drift.OrderingTerm.asc(table.logOrder)]))
        .get();
    expect(saved.map((set) => set.supersetGroup), [9, 9, 10, 10]);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });
}
