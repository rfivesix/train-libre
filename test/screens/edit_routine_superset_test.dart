import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/presentation/edit_routine_screen.dart';
import 'package:train_libre/features/workout/presentation/widgets/edit_routine_exercise_card.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/experience_level_service.dart';
import 'package:train_libre/services/theme_service.dart';
import 'package:train_libre/services/unit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late WorkoutLocalDataSource source;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = db.AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(database);
    source = WorkoutLocalDataSource.forTesting(database);
    for (var index = 0; index < 3; index++) {
      final id = 'exercise-$index';
      await database.into(database.exercises).insert(
            db.ExercisesCompanion.insert(
              id: Value(id),
              isCustom: const Value(true),
              source: const Value('user'),
              categoryName: const Value('Strength'),
            ),
          );
      await database.into(database.exerciseTranslations).insert(
            db.ExerciseTranslationsCompanion.insert(
              exerciseId: id,
              languageCode: 'en',
              name: 'Exercise ${index + 1}',
            ),
          );
    }
  });

  tearDown(() => database.close());

  Widget wrap(Widget child) => MultiProvider(
        providers: [
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

  testWidgets('connect buttons build a pair and then a triset', (tester) async {
    final routine = await source.createRoutine('Supersets');
    for (var exerciseId = 1; exerciseId <= 3; exerciseId++) {
      await source.addExerciseToRoutine(routine.id!, exerciseId);
    }
    final loaded = await source.getRoutineById(routine.id!);

    await tester.binding.setSurfaceSize(const Size(800, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrap(EditRoutineScreen(routine: loaded)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('superset_connector_0')));
    await tester.pumpAndSettle();
    var cards = tester.widgetList<EditRoutineExerciseCard>(
      find.byType(EditRoutineExerciseCard),
    );
    expect(cards.map((card) => card.supersetLabel), ['A1', 'A2', null]);
    expect(cards.map((card) => card.showPauseAction), [false, true, true]);
    expect(cards.map((card) => card.canDrag), [true, false, true]);

    await tester.tap(find.byKey(const ValueKey('superset_connector_1')));
    await tester.pumpAndSettle();
    cards = tester.widgetList<EditRoutineExerciseCard>(
      find.byType(EditRoutineExerciseCard),
    );
    expect(cards.map((card) => card.supersetLabel), ['A1', 'A2', 'A3']);
    expect(cards.map((card) => card.showPauseAction), [false, false, true]);

    final persisted = await source.getRoutineById(routine.id!);
    expect(persisted!.exercises.map((exercise) => exercise.supersetGroup),
        [1, 1, 1]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
