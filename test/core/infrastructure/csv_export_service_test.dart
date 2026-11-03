import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/core/infrastructure/backup_manager.dart';
import 'package:train_libre/core/infrastructure/csv_export_service.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/diary/data/sources/diary_local_data_source.dart';
import 'package:train_libre/features/diary/data/sources/product_local_data_source.dart';
import 'package:train_libre/features/profile/data/sources/profile_local_data_source.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('CsvExportService', () {
    test('instance is accessible and provides expected API signatures', () {
      final service = CsvExportService.instance;
      expect(service, isNotNull);
      expect(service.exportNutritionAsCsv, isA<Future<bool> Function()>());
      expect(service.exportWorkoutsAsCsv, isA<Future<bool> Function()>());
      expect(service.exportMeasurementsAsCsv, isA<Future<bool> Function()>());
    });

    test('can be instantiated with custom or mocked data sources', () {
      final db = AppDatabase(NativeDatabase.memory());
      final helper = DatabaseHelper.forTesting(db);
      final service = CsvExportService(
        dbHelper: helper,
        diaryDb: DiaryLocalDataSource(db),
        productDb: ProductLocalDataSource(db),
        workoutDb: WorkoutLocalDataSource(db),
        profileDb: ProfileLocalDataSource(db),
      );
      expect(service, isNotNull);
      addTearDown(() => db.close());
    });

    test('returns false when no nutrition or workout records exist', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final helper = DatabaseHelper.forTesting(db);
      final service = CsvExportService(
        dbHelper: helper,
        diaryDb: DiaryLocalDataSource(db),
        productDb: ProductLocalDataSource(db),
        workoutDb: WorkoutLocalDataSource(db),
        profileDb: ProfileLocalDataSource(db),
      );

      final nutritionResult = await service.exportNutritionAsCsv();
      expect(nutritionResult, isFalse);

      final workoutsResult = await service.exportWorkoutsAsCsv();
      expect(workoutsResult, isFalse);

      await db.close();
    });

    test(
      'BackupManager delegates CSV exports with identical method signatures',
      () {
        final manager = BackupManager.instance;
        expect(manager.exportNutritionAsCsv, isA<Future<bool> Function()>());
        expect(manager.exportWorkoutsAsCsv, isA<Future<bool> Function()>());
        expect(manager.exportMeasurementsAsCsv, isA<Future<bool> Function()>());
      },
    );
  });
}
