// lib/features/exercise_catalog/domain/repositories/exercise_catalog_repository.dart
import '../../../workout/domain/models/set_log.dart';
import '../models/exercise.dart';

/// Abstract contract for Exercise Catalog data persistence and operations.
abstract class IExerciseCatalogRepository {
  /// [languageCode] picks which of the catalog's languages the results are
  /// named in. Callers inside the widget tree pass the UI locale; the default
  /// exists for the ones that only need a name to key by.
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
  });

  /// Equipment that is the load-bearing implement of at least one live
  /// exercise, named in [languageCode].
  Future<List<({String id, String name})>> getPrimaryEquipment(
      String languageCode);

  /// The usage tags in use: warmup, accessory, main_lift, and so on.
  Future<List<String>> getUsageTags();

  /// The values each classification axis actually takes on live exercises,
  /// each in its own vocabulary order rather than alphabetically.
  Future<
      ({
        List<String> difficulties,
        List<String> mechanics,
        List<String> lateralities,
      })> getClassificationAxes();
  Future<Exercise?> getExerciseByName(String name);
  Future<Exercise?> getExerciseByUuid(String exerciseUuid);
  Future<Exercise> insertExercise(Exercise exercise);
  Future<void> updateCustomExercise(Exercise exercise);
  Future<bool> deleteCustomExercise(int localId);
  Future<List<Exercise>> getCustomExercises();
  Future<void> importCustomExercises(List<Exercise> exercises);
  Future<void> applyExerciseNameMapping(Map<String, String> mapping);
  Future<String?> getExerciseUuidByLocalId(int id);
  Future<Map<String, SetLog?>> getExercisePRs(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
    bool isCardio = false,
  });
  Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
    bool isCardio = false,
  });
  Future<List<String>> getAllCategories();
  Future<List<String>> getAllMuscleGroups();
}
