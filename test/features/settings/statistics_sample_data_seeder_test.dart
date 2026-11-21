import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/settings/presentation/developer_lab/statistics_sample_data_seeder.dart';

void main() {
  test('StatisticsSampleDataSeeder seeds and clears sample data cleanly', () async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    final helper = DatabaseHelper.forTesting(db);

    await StatisticsSampleDataSeeder.seedAll(dbHelper: helper);

    final goals = await db.select(db.dailyGoalsHistory).get();
    final macros = await db.select(db.macroEntries).get();
    final measurements = await db.select(db.measurements).get();
    final fluids = await db.select(db.fluidLogs).get();
    final workouts = await db.select(db.workoutLogs).get();
    final sets = await db.select(db.setLogs).get();
    final steps = await db.select(db.healthStepSegments).get();
    final sleepAnalyses = await db
        .customSelect('SELECT COUNT(*) AS c FROM sleep_nightly_analyses')
        .getSingle();
    final pulse = await db
        .customSelect('SELECT COUNT(*) AS c FROM pulse_hourly_aggregates')
        .getSingle();

    expect(goals.length, 2);
    expect(macros.length, greaterThan(100));
    expect(measurements.length, greaterThan(30));
    expect(fluids.length, greaterThan(60));
    expect(workouts.length, 16);
    expect(sets.length, greaterThan(100));
    expect(steps.length, greaterThan(300));
    expect(sleepAnalyses.read<int>('c'), 14);
    expect(pulse.read<int>('c'), greaterThan(100));

    await StatisticsSampleDataSeeder.clearSampleData(dbHelper: helper);

    expect(await db.select(db.dailyGoalsHistory).get(), isEmpty);
    expect(await db.select(db.macroEntries).get(), isEmpty);
    expect(await db.select(db.measurements).get(), isEmpty);
    expect(await db.select(db.fluidLogs).get(), isEmpty);
    expect(await db.select(db.workoutLogs).get(), isEmpty);
    expect(await db.select(db.setLogs).get(), isEmpty);
    expect(await db.select(db.healthStepSegments).get(), isEmpty);

    await db.close();
  });
}
