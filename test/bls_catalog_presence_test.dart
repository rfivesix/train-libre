import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('installed BLS foods remain ready when the alias index needs repair',
      () async {
    sqflite.databaseFactory = databaseFactoryFfi;
    final support = await Directory.systemTemp.createTemp('bls-presence-');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => support.path);
    final sidecarPath =
        p.join(support.path, 'bls_food_catalog', 'train_libre_bls_foods.db');
    await Directory(p.dirname(sidecarPath)).create(recursive: true);
    final sidecar = await sqflite.openDatabase(sidecarPath);
    await sidecar.execute('CREATE TABLE products (barcode TEXT)');
    await sidecar.execute('CREATE TABLE food_nutrients (barcode TEXT)');
    await sidecar.execute("INSERT INTO products VALUES ('bls:B101000')");
    await sidecar.execute("INSERT INTO food_nutrients VALUES ('bls:B101000')");
    await sidecar.close();

    final db = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(db);
    BasisDataManager.instance.invalidateCatalogPresenceCache();
    SharedPreferences.setMockInitialValues({
      'installed_bls_food_version': '4.0.1',
    });
    try {
      await db.into(db.foodCategories).insert(const FoodCategoriesCompanion(
            key: Value('bread'),
          ));
      await db.into(db.products).insert(const ProductsCompanion(
            barcode: Value('bls:B101000'),
            name: Value('Bread'),
            calories: Value(100),
            protein: Value(1),
            carbs: Value(2),
            fat: Value(3),
            category: Value('bread'),
            source: Value('base'),
          ));

      expect(await BasisDataManager.instance.isBlsFoodCatalogInitialized(),
          isTrue);
    } finally {
      BasisDataManager.instance.invalidateCatalogPresenceCache();
      await db.close();
      await support.delete(recursive: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });
}
