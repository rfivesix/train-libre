import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:drift/native.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/drift_database.dart' show AppDatabase;
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/data/workout_repository.dart';
import 'package:train_libre/features/workout/domain/models/routine_exercise.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/features/workout/presentation/widgets/live_workout_summary_bar.dart';
import 'package:train_libre/features/workout/presentation/live_workout_view_model.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';
import 'package:train_libre/services/profile_service.dart';
import 'package:train_libre/services/unit_service.dart';

void main() {
  testWidgets(
    'empty workout aligns the metrics and retains the progress row inset',
    (tester) async {
      SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
      final database = AppDatabase(NativeDatabase.memory());
      final units = UnitService();
      final manager = LiveWorkoutViewModel.forTesting(
        workoutDb: WorkoutRepository(
          localDataSource: WorkoutLocalDataSource(database),
        ),
        unitService: units,
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UnitService>.value(value: units),
            ChangeNotifierProvider<ProfileService>.value(
              value: ProfileService(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: appLocalizationDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: LiveWorkoutSummaryBar(workout: manager)),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('0'), findsOneWidget);
      expect(find.text('0 / 0'), findsNothing);
      final barBounds = tester.getRect(find.byType(LinearProgressIndicator));
      final volumeBounds = tester.getRect(find.text('0 kg'));
      final summaryBounds = tester.getRect(find.byType(LiveWorkoutSummaryBar));
      expect(barBounds.left, summaryBounds.left + 16);
      expect(volumeBounds.right, summaryBounds.right - 16);
      expect(tester.getRect(find.text('00:00')).left, barBounds.left);
      expect(
        tester
            .getRect(find.byKey(const ValueKey('session-muscle-badge')))
            .right,
        volumeBounds.right,
      );
      expect(barBounds.bottom, lessThanOrEqualTo(tester.getRect(find.text('00:00')).top));
      expect(
        volumeBounds.bottom,
        lessThanOrEqualTo(
          tester
              .getRect(find.byKey(const ValueKey('session-muscle-badge')))
              .top,
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      manager.dispose();
      units.dispose();
      await database.close();
    },
  );

  test(
    'coverage counts completed and planned sets once per targeted muscle',
    () {
      RoutineExercise exercise(
        List<String> primary,
        List<String> secondary,
        List<int> ids,
      ) => RoutineExercise(
        exercise: Exercise.single(
          languageCode: 'en',
          name: 'Exercise',
          categoryName: 'Strength',
          primaryMuscles: primary,
          secondaryMuscles: secondary,
        ),
        setTemplates: [
          for (final id in ids) SetTemplate(id: id, setType: 'normal'),
        ],
      );
      SetLog log(bool completed) => SetLog(
        workoutLogId: 1,
        exerciseName: 'Exercise',
        setType: 'normal',
        isCompleted: completed,
      );
      final coverage = SessionMuscleCoverage.fromWorkout(
        [
          exercise(['chest'], ['chest', 'triceps'], [1, 2]),
          exercise(['triceps'], [], [3]),
        ],
        {1: log(true), 2: log(false), 3: log(false)},
      );
      expect(coverage.counts['chest']!.completed, 1);
      expect(coverage.counts['chest']!.total, 2);
      expect(coverage.counts['triceps']!.completed, 1);
      expect(coverage.counts['triceps']!.total, 3);
    },
  );

  test('empty workout has no muscle coverage', () {
    expect(SessionMuscleCoverage.fromWorkout([], {}).counts, isEmpty);
  });

  test('cardio sets do not contribute to muscle coverage', () {
    final rowing = RoutineExercise(
      exercise: Exercise.single(
        languageCode: 'en',
        name: 'Indoor rowing machine',
        categoryName: 'Strength',
        trackingType: 'distance_time',
        primaryMuscles: ['glutes', 'calves'],
        secondaryMuscles: ['back'],
      ),
      setTemplates: [SetTemplate(id: 1, setType: 'normal')],
    );
    final log = SetLog(
      workoutLogId: 1,
      exerciseName: 'Indoor rowing machine',
      setType: 'normal',
      isCompleted: true,
    );
    expect(
      SessionMuscleCoverage.fromWorkout([rowing], {1: log}).counts,
      isEmpty,
    );
  });
}
