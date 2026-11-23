import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/domain/classification/exercise_log_mask.dart';
import 'package:train_libre/features/workout/domain/models/routine_exercise.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/features/workout/presentation/widgets/edit_routine_exercise_card.dart';
import 'package:train_libre/features/workout/presentation/widgets/reorderable_set_list.dart';
import 'package:train_libre/features/workout/presentation/widgets/workout_exercise_log_card.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';
import 'package:train_libre/services/experience_level_service.dart';
import 'package:train_libre/services/unit_service.dart';

Future<void> _longPressAndDrag(
  WidgetTester tester,
  Finder target,
  Offset delta,
) async {
  final center = tester.getCenter(target);
  final gesture = await tester.startGesture(center);
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
  const steps = 10;
  final step = Offset(delta.dx / steps, delta.dy / steps);
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(step);
    await tester.pump(const Duration(milliseconds: 50));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

Exercise _sampleExercise() => Exercise(
  id: 1,
  texts: const {'de': ExerciseText(name: 'Bankdrücken', description: '')},
  categoryName: 'Strength',
  primaryMuscles: const ['chest'],
  secondaryMuscles: const [],
);

Widget _testApp({
  required ExperienceLevelService experienceLevelService,
  required UnitService unitService,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ExperienceLevelService>.value(
        value: experienceLevelService,
      ),
      ChangeNotifierProvider<UnitService>.value(value: unitService),
    ],
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: appLocalizationDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExperienceLevelService experienceLevelService;
  late UnitService unitService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    experienceLevelService = ExperienceLevelService();
    unitService = UnitService();
  });

  tearDown(() {
    experienceLevelService.dispose();
    unitService.dispose();
  });

  testWidgets('ReorderableSetList moves sets both down and up via drag', (
    tester,
  ) async {
    var items = ['Satz A', 'Satz B', 'Satz C'];

    await tester.pumpWidget(
      _testApp(
        experienceLevelService: experienceLevelService,
        unitService: unitService,
        child: StatefulBuilder(
          builder: (context, setState) => ReorderableSetList(
            itemCount: items.length,
            enabled: true,
            onReorderSet: (oldIndex, newIndex) {
              setState(() {
                final copy = List<String>.of(items);
                final moved = copy.removeAt(oldIndex);
                copy.insert(newIndex, moved);
                items = copy;
              });
            },
            itemBuilder: (context, index) => SizedBox(
              key: ValueKey(items[index]),
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(items[index]),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Drag first set down past third set.
    await _longPressAndDrag(
      tester,
      find.text('Satz A'),
      const Offset(0, 110),
    );
    expect(items, ['Satz B', 'Satz C', 'Satz A']);

    // Drag last set back up to top.
    await _longPressAndDrag(
      tester,
      find.text('Satz A'),
      const Offset(0, -110),
    );
    expect(items, ['Satz A', 'Satz B', 'Satz C']);
  });

  testWidgets('EditRoutineExerciseCard reorders sets on drag in edit mode', (
    tester,
  ) async {
    var re = RoutineExercise(
      id: 10,
      exercise: _sampleExercise(),
      setTemplates: [
        SetTemplate(id: 101, setType: 'normal', targetWeight: 60),
        SetTemplate(id: 102, setType: 'normal', targetWeight: 80),
        SetTemplate(id: 103, setType: 'normal', targetWeight: 100),
      ],
    );
    final weightControllers = <int, TextEditingController>{
      101: TextEditingController(text: '60'),
      102: TextEditingController(text: '80'),
      103: TextEditingController(text: '100'),
    };
    final repsControllers = <int, TextEditingController>{
      101: TextEditingController(text: '10'),
      102: TextEditingController(text: '8'),
      103: TextEditingController(text: '6'),
    };
    final rirControllers = <int, TextEditingController>{
      101: TextEditingController(),
      102: TextEditingController(),
      103: TextEditingController(),
    };
    addTearDown(() {
      for (final c in weightControllers.values) {
        c.dispose();
      }
      for (final c in repsControllers.values) {
        c.dispose();
      }
      for (final c in rirControllers.values) {
        c.dispose();
      }
    });

    await tester.pumpWidget(
      _testApp(
        experienceLevelService: experienceLevelService,
        unitService: unitService,
        child: StatefulBuilder(
          builder: (context, setState) => EditRoutineExerciseCard(
            routineExercise: re,
            index: 0,
            isCardio: false,
            isEditMode: true,
            repsControllers: repsControllers,
            weightControllers: weightControllers,
            rirControllers: rirControllers,
            onEditNotes: () {},
            onEditPauseTime: () {},
            onDeleteExercise: () {},
            onAddSet: () {},
            onShowSetTypePicker: (_) {},
            onRemoveSet: (_, _) {},
            onReorderSet: (oldIndex, newIndex) {
              setState(() {
                final updated = List<SetTemplate>.of(re.setTemplates);
                final moved = updated.removeAt(oldIndex);
                updated.insert(newIndex, moved);
                re = re.copyWith(setTemplates: updated);
              });
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _longPressAndDrag(tester, find.text('1'), const Offset(0, 120));
    expect([for (final t in re.setTemplates) t.id], [102, 103, 101]);
  });

  testWidgets('WorkoutExerciseLogCard reorders sets on drag in edit mode', (
    tester,
  ) async {
    final sets = <SetLog>[
      SetLog(
        id: 201,
        workoutLogId: 1,
        exerciseName: 'Bankdrücken',
        setType: 'normal',
        weightKg: 60,
        reps: 10,
      ),
      SetLog(
        id: 202,
        workoutLogId: 1,
        exerciseName: 'Bankdrücken',
        setType: 'normal',
        weightKg: 80,
        reps: 8,
      ),
      SetLog(
        id: 203,
        workoutLogId: 1,
        exerciseName: 'Bankdrücken',
        setType: 'normal',
        weightKg: 100,
        reps: 6,
      ),
    ];
    final weightControllers = <int, TextEditingController>{
      201: TextEditingController(text: '60'),
      202: TextEditingController(text: '80'),
      203: TextEditingController(text: '100'),
    };
    final repsControllers = <int, TextEditingController>{
      201: TextEditingController(text: '10'),
      202: TextEditingController(text: '8'),
      203: TextEditingController(text: '6'),
    };
    final rirControllers = <int, TextEditingController>{
      201: TextEditingController(),
      202: TextEditingController(),
      203: TextEditingController(),
    };
    addTearDown(() {
      for (final c in weightControllers.values) {
        c.dispose();
      }
      for (final c in repsControllers.values) {
        c.dispose();
      }
      for (final c in rirControllers.values) {
        c.dispose();
      }
    });

    await tester.pumpWidget(
      _testApp(
        experienceLevelService: experienceLevelService,
        unitService: unitService,
        child: StatefulBuilder(
          builder: (context, setState) => WorkoutExerciseLogCard(
            exerciseName: 'Bankdrücken',
            exercise: _sampleExercise(),
            sets: sets,
            isEditMode: true,
            isCardio: false,
            mask: ExerciseLogMask.forExercise(_sampleExercise()),
            weightControllers: weightControllers,
            repsControllers: repsControllers,
            rirControllers: rirControllers,
            exerciseNote: null,
            onEditNotes: (_) {},
            onDeleteExercise: (_) {},
            onAddSet: () {},
            onDeleteSet: (_) {},
            onReorderSet: (oldIndex, newIndex) {
              setState(() {
                final moved = sets.removeAt(oldIndex);
                sets.insert(newIndex, moved);
              });
            },
            index: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Drag set 3 up to position 1.
    await _longPressAndDrag(tester, find.text('3'), const Offset(0, -120));
    expect([for (final s in sets) s.id], [203, 201, 202]);
  });
}
