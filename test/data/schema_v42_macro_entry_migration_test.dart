import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/data/drift_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('upgrades a v42 database where macro_entries does not exist', () async {
    final tempDir = await Directory.systemTemp.createTemp('schema_v42_test_');
    final file = File(p.join(tempDir.path, 'train-libre.sqlite'));
    final current = AppDatabase(NativeDatabase(file));
    await current.customSelect('SELECT 1').get();

    // Version 42 predates macro_entries. Recreate that relevant part of the
    // schema while leaving the unrelated tables at their current shape.
    await current.customStatement('PRAGMA foreign_keys = OFF');
    await current.customStatement('DROP TABLE macro_entries');
    await current.customStatement('PRAGMA user_version = 42');
    await current.close();

    final migrated = AppDatabase(NativeDatabase(file));
    try {
      await migrated.customSelect('SELECT 1').get();
      final columns = await migrated
          .customSelect('PRAGMA table_info(macro_entries)')
          .get();
      expect(
        columns.map((row) => row.read<String>('name')),
        contains('meal_entry_id'),
      );
      final version = await migrated.customSelect('PRAGMA user_version').get();
      expect(version.single.read<int>('user_version'), 47);
    } finally {
      await migrated.close();
      await tempDir.delete(recursive: true);
    }
  });
}
