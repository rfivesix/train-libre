import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/data/drift_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('schema 37 adds the persistent health export identity registry',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('schema_v38_health_export_');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final file = File(p.join(directory.path, 'v37.sqlite'));

    var database = AppDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1').get();
    await database.customStatement('DROP TABLE health_export_identities');
    await database.customStatement('PRAGMA user_version = 37');
    await database.close();

    database = AppDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1').get();
    final columns = await database
        .customSelect('PRAGMA table_info(health_export_identities)')
        .get();
    final names = columns.map((row) => row.read<String>('name')).toSet();

    expect(database.schemaVersion, 38);
    expect(
      names,
      containsAll(<String>{
        'platform',
        'domain',
        'source_key',
        'external_id',
        'revision',
        'payload_fingerprint',
        'is_legacy',
        'exported_at',
      }),
    );
    await database.close();
  });
}
