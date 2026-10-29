import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/data/drift_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('schema 46 adds Spanish and Dutch catalog columns', () async {
    final directory =
        await Directory.systemTemp.createTemp('schema_v46_catalog_test_');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final file = File(p.join(directory.path, 'v46.sqlite'));

    var database = AppDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1').get();
    await database.customStatement('PRAGMA foreign_keys = OFF');
    await database.customStatement('ALTER TABLE products DROP COLUMN name_es');
    await database
        .customStatement('ALTER TABLE products DROP COLUMN category_es');
    await database.customStatement('ALTER TABLE products DROP COLUMN name_nl');
    await database
        .customStatement('ALTER TABLE products DROP COLUMN category_nl');
    await database
        .customStatement('ALTER TABLE food_categories DROP COLUMN name_es');
    await database
        .customStatement('ALTER TABLE food_categories DROP COLUMN name_nl');
    await database.customStatement('PRAGMA user_version = 46');
    await database.close();

    database = AppDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1').get();
    final productColumns =
        await database.customSelect('PRAGMA table_info(products)').get();
    final categoryColumns =
        await database.customSelect('PRAGMA table_info(food_categories)').get();

    expect(database.schemaVersion, 47);
    expect(
      productColumns.map((row) => row.read<String>('name')),
      containsAll(['name_es', 'category_es', 'name_nl', 'category_nl']),
    );
    expect(
      categoryColumns.map((row) => row.read<String>('name')),
      containsAll(['name_es', 'name_nl']),
    );
    await database.close();
  });
}
