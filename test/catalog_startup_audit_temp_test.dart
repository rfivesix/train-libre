import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late AppDatabase db;
  late Directory temp;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    sqflite.databaseFactory = databaseFactoryFfi;
    temp = await Directory.systemTemp.createTemp('catalog-startup-audit-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => temp.path);
    PackageInfo.setMockInitialValues(appName: 'Train Libre', packageName: 'test',
      version: '1.3.0-alpha.1', buildNumber: '1003000', buildSignature: '');
    db = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(db);
    BasisDataManager.instance.invalidateCatalogPresenceCache();
    await db.into(db.products).insert(const ProductsCompanion(
      barcode: Value('base-1'), name: Value('Base'), calories: Value(100),
      protein: Value(1), carbs: Value(2), fat: Value(3), source: Value('base')));
    await db.into(db.foodCategories).insert(const FoodCategoriesCompanion(
      key: Value('fruit'), nameDe: Value('Obst')));
    SharedPreferences.setMockInitialValues({
      'last_db_sync_app_version': '1002001',
      'installed_food_enrichment_v1': true,
      'installed_food_version': '999999999999',
      'installed_cats_version': '999999999999',
    });
  });
  tearDown(() async {
    await db.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await temp.delete(recursive: true);
  });
  test('startup installs the real bundled v2 catalog without a remote update', () async {
    await BasisDataManager.instance.checkForBasisDataUpdate(skipOffDatabase: true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('installed_training_version'), '202609041121');
    expect(prefs.getBool('is_exercise_catalog_initialized'), true);
    final rows = await db.select(db.exercises).get();
    expect(rows.length, 909);
    expect(rows.where((r) => r.trackingType != null).length, greaterThan(800));
  });
  test('app upgrade currently leaves a healthy v1 catalog unchanged', () async {
    await BasisDataManager.instance.importExerciseCatalogFromFileForTesting(
      '/tmp/train-libre-catalog-v1-audit.db');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_exercise_catalog_initialized', true);
    await prefs.setString('installed_training_version', '202608010000');
    final before = await db.select(db.exercises).get();
    expect(before, isNotEmpty);
    expect(before.every((r) => r.trackingType == null), true);
    await BasisDataManager.instance.checkForBasisDataUpdate(skipOffDatabase: true);
    final after = await db.select(db.exercises).get();
    expect(prefs.getString('last_db_sync_app_version'), '1003000');
    expect(prefs.getString('installed_training_version'), '202608010000');
    expect(after.length, before.length);
    expect(after.every((r) => r.trackingType == null), true);
  });
}
