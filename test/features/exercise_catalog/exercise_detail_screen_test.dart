import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' show AppDatabase;
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/exercise_catalog/domain/repositories/exercise_catalog_repository.dart';
import 'package:train_libre/features/exercise_catalog/presentation/exercise_detail_screen.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/workout_log.dart';
import 'package:train_libre/features/workout/domain/repositories/workout_repository.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/widgets/common/global_app_bar.dart';
import 'package:train_libre/widgets/common/value_summary_card.dart';

class _FakeExerciseCatalogRepository implements IExerciseCatalogRepository {
  @override
  Future<Map<String, SetLog?>> getExercisePRs(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
    bool isCardio = false,
  }) async => {
    'Est. 1RM': SetLog(
      workoutLogId: 1,
      exerciseName: exerciseName,
      setType: 'Normal',
      weightKg: 100.0,
      reps: 5,
    ),
    '1 RM': null,
  };

  @override
  Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
    bool isCardio = false,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWorkoutRepository implements IWorkoutRepository {
  @override
  Stream<List<WorkoutLog>> watchFullWorkoutLogs() =>
      Stream<List<WorkoutLog>>.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  sqflite.databaseFactory = databaseFactoryFfi;

  for (final brightness in [Brightness.dark, Brightness.light]) {
    testWidgets(
      'ExerciseDetailScreen hosts TabBar inside GlobalAppBar and uses monochrome PR text (${brightness.name})',
      (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final db = AppDatabase(NativeDatabase.memory());
        DatabaseHelper.setDriftDb(db);
        addTearDown(() async {
          await DatabaseHelper.closeAndResetDriftDb();
        });

        final unitService = UnitService();
        final exercise = Exercise.single(
          languageCode: 'de',
          name: 'Brustpresse',
          categoryName: 'Chest',
          primaryMuscles: const ['Chest'],
          secondaryMuscles: const [],
          trackingType: 'weight_reps',
        );

        final theme = ThemeData(
          brightness: brightness,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFDDFF00),
            brightness: brightness,
          ),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<IWorkoutRepository>.value(
                value: _FakeWorkoutRepository(),
              ),
              ChangeNotifierProvider<UnitService>.value(value: unitService),
            ],
            child: MaterialApp(
              theme: theme,
              localizationsDelegates: appLocalizationDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('de'),
              home: ExerciseDetailScreen(
                exercise: exercise,
                repository: _FakeExerciseCatalogRepository(),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // TabBar and ProgressiveBlur live inside GlobalAppBar so scrolled tab
        // content fades beneath the full app bar header.
        expect(
          find.descendant(
            of: find.byType(GlobalAppBar),
            matching: find.byType(TabBar),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(GlobalAppBar),
            matching: find.byType(ProgressiveBlur),
          ),
          findsOneWidget,
        );

        final prCards = tester
            .widgetList<ValueSummaryCard>(find.byType(ValueSummaryCard))
            .toList();
        expect(prCards.length, 2);

        final populatedPr = prCards.firstWhere((card) => card.value != '-');
        final emptyPr = prCards.firstWhere((card) => card.value == '-');
        expect(
          populatedPr.valueColor,
          brightness == Brightness.light ? Colors.black : Colors.white,
        );
        expect(populatedPr.valueColor, isNot(theme.colorScheme.primary));
        expect(emptyPr.valueColor, theme.colorScheme.onSurfaceVariant);

        await tester.pumpWidget(const SizedBox.shrink());
        unitService.dispose();
      },
    );
  }
}
