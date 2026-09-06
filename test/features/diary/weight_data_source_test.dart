import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/profile/data/sources/profile_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late ProfileLocalDataSource source;
  final day = DateTime(2026, 9, 5);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    source = ProfileLocalDataSource(database);
  });
  tearDown(() => database.close());

  test(
      'keeps multiple daily weights; latest wins; same-second correction is unique',
      () async {
    await source.saveWeightKg(85, date: day.add(const Duration(hours: 7)));
    await source.saveWeightKg(84.2, date: day.add(const Duration(hours: 8)));
    await source.saveWeightKg(84.3,
        date: day.add(const Duration(hours: 8, milliseconds: 500)));
    final rows = await database.select(database.measurements).get();
    expect(rows, hasLength(2));
    expect(
        rows.every((row) => row.type == 'weight' && row.unit == 'kg'), isTrue);
    expect(
        (await source.watchLatestWeightBefore(DateTime(2026, 9, 6)).first)!
            .value,
        84.3);
    expect(await source.watchLatestWeightBefore(day).first, isNull);
  });

  test('watch observes saves and deletion, excluding non-weight measurements',
      () async {
    await database
        .into(database.measurements)
        .insert(MeasurementsCompanion.insert(
          type: 'waist',
          value: 90,
          unit: 'cm',
          date: day,
        ));
    final stream = source.watchLatestWeightBefore(DateTime(2026, 9, 6));
    expect(await stream.first, isNull);
    final changed = stream.firstWhere((row) => row != null);
    await source.saveWeightKg(81.7, date: day);
    expect((await changed)!.value, 81.7);
    final deleted = stream.firstWhere((row) => row == null);
    await database.delete(database.measurements).go();
    expect(await deleted, isNull);
  });

  test('rejects invalid storage values', () async {
    for (final value in [0.0, -1.0, double.nan, double.infinity]) {
      await expectLater(
          source.saveWeightKg(value, date: day), throwsArgumentError);
    }
    expect(await database.select(database.measurements).get(), isEmpty);
  });
}
