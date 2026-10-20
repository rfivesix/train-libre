import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/exercise_catalog/domain/repositories/exercise_catalog_repository.dart';
import 'package:train_libre/features/exercise_catalog/presentation/exercise_mapping_screen.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/generated/app_localizations.dart';

class FakeExerciseCatalogRepository implements IExerciseCatalogRepository {
  @override
  Future<List<Exercise>> searchExercises({
    String query = '',
    List<String> categories = const [],
    List<String> forceLevels = const [],
    String sortOrder = 'alphabetical',
    List<String> equipmentIds = const [],
    List<String> usageTags = const [],
    List<String> difficulties = const [],
    List<String> mechanics = const [],
    List<String> lateralities = const [],
    String languageCode = 'en',
    bool onlyPerformed = false,
  }) async => [];

  @override
  Future<List<({String id, String name})>> getPrimaryEquipment(
          String languageCode) async =>
      [];

  @override
  Future<List<String>> getUsageTags() async => [];

  @override
  Future<
      ({
        List<String> difficulties,
        List<String> mechanics,
        List<String> lateralities,
      })> getClassificationAxes() async => (
        difficulties: <String>[],
        mechanics: <String>[],
        lateralities: <String>[],
      );

  @override
  Future<Exercise?> getExerciseByName(String name) async => null;

  @override
  Future<Exercise?> getExerciseByUuid(String exerciseUuid) async => null;

  @override
  Future<Exercise> insertExercise(Exercise exercise) async => exercise;

  @override
  Future<void> updateCustomExercise(Exercise exercise) async {}

  @override
  Future<bool> deleteCustomExercise(int localId) async => true;

  @override
  Future<List<Exercise>> getCustomExercises() async => [];

  @override
  Future<void> importCustomExercises(List<Exercise> exercises) async {}

  @override
  Future<void> applyExerciseNameMapping(Map<String, String> mapping) async {}

  @override
  Future<String?> getExerciseUuidByLocalId(int id) async => null;

  @override
  Future<Map<String, SetLog?>> getExercisePRs(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
    bool isCardio = false,
  }) async =>
      {};

  @override
  Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
    bool isCardio = false,
  }) async =>
      [];

  @override
  Future<List<String>> getAllCategories() async => [];

  @override
  Future<List<String>> getAllMuscleGroups() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ExerciseMappingScreen renders scrollbar and content properly positioned',
      (tester) async {
    final repo = FakeExerciseCatalogRepository();
    final names = List.generate(20, (i) => 'Unknown Exercise $i');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(393, 852),
            padding: EdgeInsets.only(top: 59, bottom: 34),
          ),
          child: ExerciseMappingScreen(
            unknownNames: names,
            repository: repo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoScrollbar), findsOneWidget);
    expect(find.text('Unknown Exercise 0'), findsOneWidget);

    final scrollbarRect = tester.getRect(find.byType(CupertinoScrollbar));
    // Scrollbar starts at top of screen (0.0) and stretches to above bottomNavigationBar
    expect(scrollbarRect.top, 0.0);

    // First exercise item starts below the app bar (topPadding = 59 + 56 = 115)
    final item0Rect = tester.getRect(find.text('Unknown Exercise 0'));
    expect(item0Rect.top, greaterThan(115.0));

    // Scroll down and ensure items scroll behind app bar
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // After scrolling, items have moved up
    expect(find.text('Unknown Exercise 0'), findsNothing);
    expect(find.text('Unknown Exercise 5'), findsOneWidget);
  });
}
