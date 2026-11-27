import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/statistics/data/bls_micronutrient_analytics_data_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'BLS food on an incomplete day contributes no micronutrient entries',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      DatabaseHelper.setDriftDb(database);
      addTearDown(DatabaseHelper.closeAndResetDriftDb);
      final day = DateTime(2026, 4, 8);
      await database
          .into(database.nutritionLogs)
          .insert(
            NutritionLogsCompanion.insert(
              legacyBarcode: const drift.Value('bls:test-product'),
              consumedAt: DateTime(2026, 4, 8, 8),
              amount: 100,
            ),
          );
      await DatabaseHelper.instance.setIncompleteNutritionDay(day, true);

      final summary = await const BlsMicronutrientAnalyticsDataAdapter()
          .fetchSummary(
            range: DateTimeRange(start: day, end: day),
            languageCode: 'de',
          );

      expect(summary.nutrients, isEmpty);
      expect(summary.blsFoodEntries, 0);
      expect(summary.blsLoggedDays, 0);
    },
  );
}
