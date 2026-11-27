import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/domain/classification/exercise_log_mask.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/features/workout/domain/repositories/workout_repository.dart';
import 'package:train_libre/features/workout/presentation/live_workout_view_model.dart';
import 'package:train_libre/features/workout/presentation/widgets/live_workout_set_row.dart';
import 'package:train_libre/features/workout/presentation/widgets/workout_log_set_row.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/experience_level_service.dart';
import 'package:train_libre/services/unit_service.dart';

class _UnusedWorkoutRepository implements IWorkoutRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// What each exercise actually renders.
///
/// C3 derived the mask correctly in the model and wired it into nothing: the
/// getters existed, no screen read them, and a plank kept a repetitions column
/// while a pull-up kept an empty weight field. A data-layer test cannot see
/// that. This one can.
Exercise _exercise({String? trackingType, String? loadMode}) => Exercise(
  texts: const {'en': ExerciseText(name: 'Test')},
  categoryName: 'Abs',
  primaryMuscles: const [],
  secondaryMuscles: const [],
  trackingType: trackingType,
  loadMode: loadMode,
);

SetLog _setLog() => SetLog(
  id: 1,
  workoutLogId: 1,
  exerciseName: 'Test',
  setType: 'normal',
  weightKg: 40,
  reps: 8,
  durationSeconds: 45,
  distanceKm: 2.5,
  isCompleted: true,
  logOrder: 0,
);

Future<void> _pumpRow(WidgetTester tester, ExerciseLogMask mask) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<UnitService>(create: (_) => UnitService()),
          // Defaults to pro, which is what these expectations describe: the
          // RIR column present wherever the mask allows it.
          ChangeNotifierProvider<ExperienceLevelService>(
            create: (_) => ExperienceLevelService(),
          ),
        ],
        child: Scaffold(
          body: WorkoutLogSetRow(
            setLog: _setLog(),
            workingSetIndex: 1,
            exerciseName: 'Test',
            isEditMode: false,
            mask: mask,
            weightController: TextEditingController(),
            repsController: TextEditingController(),
            rirController: TextEditingController(),
            onDelete: () {},
            onSetTypeTap: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty live RPE stays empty even with a routine target', (
    tester,
  ) async {
    final manager = LiveWorkoutViewModel.forTesting(
      workoutDb: _UnusedWorkoutRepository(),
    );
    addTearDown(manager.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: manager),
            ChangeNotifierProvider.value(value: manager.unitService),
            ChangeNotifierProvider(create: (_) => ExperienceLevelService()),
          ],
          child: Scaffold(
            body: SizedBox(
              width: 320,
              child: LiveWorkoutSetRow(
                setIndex: 0,
                rowIndex: 0,
                templateId: 2,
                setLog: _setLog().copyWith(isCompleted: false),
                lastPerfSets: const [],
                currentSetTypes: const ['normal'],
                template: SetTemplate(id: 2, setType: 'normal', targetRpe: 8.5),
                manager: manager,
                mask: ExerciseLogMask.weightAndReps,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('8.5'), findsNothing);
    expect(find.byIcon(LucideIcons.gauge), findsOneWidget);
  });
  testWidgets('live set outlines track editability in both themes', (
    tester,
  ) async {
    final manager = LiveWorkoutViewModel.forTesting(
      workoutDb: _UnusedWorkoutRepository(),
    );
    addTearDown(manager.dispose);

    Future<void> pumpRow(Brightness brightness, bool isCompleted) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: manager),
              ChangeNotifierProvider.value(value: manager.unitService),
              ChangeNotifierProvider(create: (_) => ExperienceLevelService()),
            ],
            child: Scaffold(
              body: SizedBox(
                width: 320,
                child: LiveWorkoutSetRow(
                  setIndex: 2,
                  rowIndex: 1,
                  templateId: 2,
                  setLog: _setLog().copyWith(isCompleted: isCompleted),
                  lastPerfSets: const [],
                  currentSetTypes: const ['normal', 'normal'],
                  template: SetTemplate(id: 2, setType: 'normal'),
                  manager: manager,
                  mask: ExerciseLogMask.weightAndReps,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final fields = find.byType(TextField);
    for (final brightness in Brightness.values) {
      await pumpRow(brightness, false);
      expect(fields, findsNWidgets(2));
      expect(find.byIcon(LucideIcons.gauge), findsOneWidget);
      for (var index = 0; index < 2; index++) {
        final field = tester.widget<TextField>(fields.at(index));
        expect(field.decoration!.enabledBorder, isA<OutlineInputBorder>());
        expect(field.decoration!.focusedBorder, isA<OutlineInputBorder>());
        if (index > 0) {
          expect(
            tester.getRect(fields.at(index)).left,
            greaterThan(tester.getRect(fields.at(index - 1)).right),
          );
        }
      }
      await tester.tap(fields.first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .focusNode
            .hasFocus,
        isTrue,
      );

      await pumpRow(brightness, true);
      for (final field in tester.widgetList<TextField>(fields)) {
        expect(field.enabled, isFalse);
        expect(field.decoration!.disabledBorder, InputBorder.none);
        expect(field.decoration!.focusedBorder, InputBorder.none);
      }
    }
  });

  testWidgets('live duration control has an outline while editable', (
    tester,
  ) async {
    final manager = LiveWorkoutViewModel.forTesting(
      workoutDb: _UnusedWorkoutRepository(),
    );
    addTearDown(manager.dispose);
    final mask = ExerciseLogMask.forExercise(
      _exercise(trackingType: 'distance_time'),
    );

    for (final brightness in Brightness.values) {
      for (final completed in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: manager),
                ChangeNotifierProvider.value(value: manager.unitService),
                ChangeNotifierProvider(create: (_) => ExperienceLevelService()),
              ],
              child: Scaffold(
                body: SizedBox(
                  width: 320,
                  child: LiveWorkoutSetRow(
                    setIndex: 2,
                    rowIndex: 1,
                    templateId: 2,
                    setLog: _setLog().copyWith(isCompleted: completed),
                    lastPerfSets: const [],
                    currentSetTypes: const ['normal', 'normal'],
                    template: SetTemplate(id: 2, setType: 'normal'),
                    manager: manager,
                    mask: mask,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final durationBox = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('00:45'),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = durationBox.decoration! as BoxDecoration;
        expect(decoration.border != null, !completed);
        expect(tester.takeException(), isNull);
      }
    }
  });

  group('ExerciseLogMask derivation', () {
    test('weight_reps shows weight and reps', () {
      final mask = ExerciseLogMask.forExercise(
        _exercise(trackingType: 'weight_reps'),
      );
      expect(mask.primary, LogField.weight);
      expect(mask.secondary, LogField.reps);
    });

    test('bodyweight_reps shows an added-weight column, not a weight one', () {
      final mask = ExerciseLogMask.forExercise(
        _exercise(trackingType: 'bodyweight_reps'),
      );
      expect(mask.primary, LogField.addedWeight);
      expect(mask.secondary, LogField.reps);
      expect(
        mask.showsPrimary,
        isTrue,
        reason: 'the column stays, so a belt can be entered',
      );
    });

    test('time shows a duration and nothing else', () {
      final mask = ExerciseLogMask.forExercise(_exercise(trackingType: 'time'));
      expect(mask.primary, LogField.none);
      expect(mask.secondary, LogField.duration);
      expect(mask.showsPrimary, isFalse);
    });

    test('time_weight keeps a weight column alongside the duration', () {
      final mask = ExerciseLogMask.forExercise(
        _exercise(trackingType: 'time_weight'),
      );
      expect(mask.primary, LogField.weight);
      expect(mask.secondary, LogField.duration);
    });

    test('distance_only shows a distance and no second column', () {
      final mask = ExerciseLogMask.forExercise(
        _exercise(trackingType: 'distance_only'),
      );
      expect(mask.primary, LogField.distance);
      expect(mask.secondary, LogField.none);
    });

    test('an assistance machine labels its column as assistance', () {
      final mask = ExerciseLogMask.forExercise(
        _exercise(trackingType: 'weight_reps', loadMode: 'assisted'),
      );
      expect(
        mask.primary,
        LogField.assistance,
        reason: 'the number is a reduction, and the column has to say so',
      );
    });

    test('an unclassified exercise falls back to weight and reps', () {
      expect(
        ExerciseLogMask.forExercise(_exercise()),
        ExerciseLogMask.weightAndReps,
      );
      expect(ExerciseLogMask.forExercise(null), ExerciseLogMask.weightAndReps);
    });

    test('load-and-rep progression eligibility follows the logged metrics', () {
      for (final trackingType in [
        'time',
        'time_weight',
        'distance_time',
        'distance_only',
      ]) {
        expect(
          ExerciseLogMask.forExercise(_exercise(trackingType: trackingType))
              .supportsLoadRepProgression,
          isFalse,
          reason: '$trackingType needs a metric-specific progression model',
        );
      }

      for (final mode in ['external', 'assisted', 'bodyweight']) {
        expect(
          ExerciseLogMask.forExercise(
            _exercise(trackingType: 'bodyweight_reps', loadMode: mode),
          ).supportsLoadRepProgression,
          isTrue,
          reason: '$mode still logs a stable load axis and repetitions',
        );
      }

      expect(
        ExerciseLogMask.forExercise(
          _exercise(trackingType: 'weight_reps', loadMode: 'variable'),
        ).supportsLoadRepProgression,
        isFalse,
      );
      expect(
        ExerciseLogMask.forExercise(_exercise()).supportsLoadRepProgression,
        isTrue,
        reason: 'legacy non-cardio exercises retain their old fallback',
      );
    });
  });

  group('what the set row renders', () {
    testWidgets('a time exercise has no repetitions column', (tester) async {
      await _pumpRow(
        tester,
        ExerciseLogMask.forExercise(_exercise(trackingType: 'time')),
      );

      // 45 seconds, not 8 reps.
      expect(find.text('00:45'), findsOneWidget);
      expect(
        find.text('8'),
        findsNothing,
        reason: 'a plank was showing a repetitions column',
      );
      // And no weight either.
      expect(find.text('40 kg'), findsNothing);
    });

    testWidgets('a weight_reps exercise shows both numbers', (tester) async {
      await _pumpRow(
        tester,
        ExerciseLogMask.forExercise(_exercise(trackingType: 'weight_reps')),
      );

      expect(find.text('8'), findsOneWidget);
      expect(find.text('00:45'), findsNothing);
    });

    testWidgets('a bodyweight exercise keeps its repetitions column', (
      tester,
    ) async {
      await _pumpRow(
        tester,
        ExerciseLogMask.forExercise(_exercise(trackingType: 'bodyweight_reps')),
      );

      expect(find.text('8'), findsOneWidget);
      expect(find.text('00:45'), findsNothing);
    });

    testWidgets('a distance_time exercise shows distance and duration', (
      tester,
    ) async {
      await _pumpRow(
        tester,
        ExerciseLogMask.forExercise(_exercise(trackingType: 'distance_time')),
      );

      expect(find.text('2.5'), findsOneWidget);
      expect(find.text('00:45'), findsOneWidget);
      expect(find.text('8'), findsNothing);
    });

    testWidgets('a distance_only exercise has no second column', (
      tester,
    ) async {
      await _pumpRow(
        tester,
        ExerciseLogMask.forExercise(_exercise(trackingType: 'distance_only')),
      );

      expect(find.text('2.5'), findsOneWidget);
      expect(find.text('00:45'), findsNothing);
      expect(find.text('8'), findsNothing);
    });
  });
}
