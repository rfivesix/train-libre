import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/data/drift_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('migration from v47 adds HRV table without removing pulse data', () async {
    final directory = await Directory.systemTemp.createTemp('schema_v48_hrv_');
    addTearDown(() async => directory.delete(recursive: true));
    final file = File(p.join(directory.path, 'db.sqlite'));
    var database = AppDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1').get();
    await database.customStatement('DROP TABLE pulse_hrv_samples');
    await database.customStatement(
      "INSERT INTO pulse_aggregate_metadata (key, value, updated_at_ms) VALUES ('test', 'kept', 1)",
    );
    await database.customStatement('PRAGMA user_version = 47');
    await database.close();
    database = AppDatabase(NativeDatabase(file));
    final columns = await database
        .customSelect('PRAGMA table_info(pulse_hrv_samples)')
        .get();
    expect(
      columns.map((row) => row.read<String>('name')),
      containsAll(['native_id', 'source_id', 'start_ms', 'end_ms', 'sdnn_ms']),
    );
    expect(
      (await database
              .customSelect(
                "SELECT value FROM pulse_aggregate_metadata WHERE key = 'test'",
              )
              .getSingle())
          .read<String>('value'),
      'kept',
    );
    expect(database.schemaVersion, 48);
    await database.close();
  });
}
