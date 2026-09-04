import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/config/app_data_sources.dart';
import 'package:train_libre/services/exercise_catalog_refresh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  const config = ExerciseCatalogRemoteSourceConfig(
    enabled: true,
    sourceId: 'wger_catalog',
    channel: 'stable',
    baseUrl: 'https://example.com/catalog/',
    manifestPath: 'catalog_manifest.json',
    defaultDbPath: 'catalog.db',
    defaultBuildReportPath: 'build_report.json',
    localCacheDirectoryName: 'cache',
    localCacheDbFileName: 'catalog.db',
    localManifestFileName: 'manifest.json',
    manifestTimeoutSeconds: 1,
    downloadTimeoutSeconds: 1,
    minCheckIntervalHours: 12,
    minimumExerciseRows: 1,
  );
  late Directory temp;
  late SharedPreferences prefs;
  late List<String> requests;
  final now = DateTime(2026, 9, 5, 12);

  setUp(() async {
    sqflite.databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    temp = await Directory.systemTemp.createTemp('catalog-selection-');
    requests = [];
  });
  tearDown(() async => temp.delete(recursive: true));

  Future<File> catalog(String version, String name, {int minSchema = 1}) async {
    final file = File('${temp.path}/$name');
    await file.parent.create(recursive: true);
    await File('test/fixtures/exercise_catalog/v2_min.db').copy(file.path);
    final db = await databaseFactoryFfi.openDatabase(file.path);
    await db.rawQuery('PRAGMA journal_mode = DELETE');
    await db.update('metadata', {'value': version},
        where: 'key = ?', whereArgs: ['version']);
    await db.update('metadata', {'value': '$minSchema'},
        where: 'key = ?', whereArgs: ['min_app_schema_version']);
    await db.close();
    return file;
  }

  Future<void> cache(String version, {int minSchema = 1}) async {
    await catalog(version, 'cache/catalog.db', minSchema: minSchema);
    await prefs.setString('exercise_catalog_cached_version', version);
  }

  Future<ExerciseCatalogRefreshService> service(String version,
      {bool offline = false, bool corrupt = false}) async {
    final remote = await catalog(version, 'remote.db');
    final bytes = await remote.readAsBytes();
    return ExerciseCatalogRefreshService.forTesting(
      config: config,
      nowProvider: () => now,
      supportDirectoryProvider: () async => temp,
      tempDirectoryProvider: () async => temp,
      prefsProvider: () async => prefs,
      httpClient: MockClient((request) async {
        requests.add(request.url.path);
        if (offline) return http.Response('offline', 503);
        if (request.url.path.endsWith('catalog_manifest.json')) {
          return http.Response(
              jsonEncode({
                'source_id': 'wger_catalog',
                'channel': 'stable',
                'version': version,
                'schema_version': 2,
                'min_app_schema_version': 1,
                'db_url': 'https://example.com/catalog/catalog.db',
                'db_sha256': sha256.convert(bytes).toString(),
              }),
              200);
        }
        return http.Response.bytes(corrupt ? [1, 2, 3] : bytes, 200);
      }),
    );
  }

  for (final force in [false, true]) {
    test('checks the latest release before using an older cache (force=$force)',
        () async {
      await cache('202609020000');
      if (force) {
        await prefs.setInt(
            'exercise_catalog_last_checked_at', now.millisecondsSinceEpoch);
      }
      final refresh = await service('202609040000');
      final result = await refresh.prepareUpdateCandidate(
          installedVersion: '202609010000', force: force);
      expect(result?.version, '202609040000');
      expect(result?.fromCache, false);
      expect(
          requests, ['/catalog/catalog_manifest.json', '/catalog/catalog.db']);
    });
  }

  test('reuses the cache after confirming the remote has the same version',
      () async {
    await cache('202609040000');
    final refresh = await service('202609040000');
    final result = await refresh.prepareUpdateCandidate(
        installedVersion: '202609010000', force: true);
    expect(result?.fromCache, true);
    expect(result?.version, '202609040000');
    expect(requests, ['/catalog/catalog_manifest.json']);
  });

  test('keeps a newer cache when the remote release was rolled back', () async {
    await cache('202609050000');
    final refresh = await service('202609040000');
    final result = await refresh.prepareUpdateCandidate(
        installedVersion: '202609010000', force: true);
    expect(result?.version, '202609050000');
    expect(requests, ['/catalog/catalog_manifest.json']);
  });

  for (final installed in ['202609040000', '202609050000']) {
    test('forced refresh never downloads equal or older data ($installed)',
        () async {
      await cache('202609020000');
      final refresh = await service('202609040000');
      final result = await refresh.prepareUpdateCandidate(
          installedVersion: installed, force: true);
      expect(result, isNull);
      expect(requests, ['/catalog/catalog_manifest.json']);
    });
  }

  test('offline refresh falls back to a validated cache newer than installed',
      () async {
    await cache('202609020000');
    final refresh = await service('202609040000', offline: true);
    final result = await refresh.prepareUpdateCandidate(
        installedVersion: '202609010000', force: true);
    expect(result?.version, '202609020000');
    expect(result?.fromCache, true);
    expect(requests, ['/catalog/catalog_manifest.json']);
  });

  test('corrupt download preserves and uses the valid newer cache', () async {
    await cache('202609020000');
    final refresh = await service('202609040000', corrupt: true);
    final result = await refresh.prepareUpdateCandidate(
        installedVersion: '202609010000', force: true);
    expect(result?.version, '202609020000');
    expect(prefs.getString('exercise_catalog_cached_version'), '202609020000');
    expect(prefs.getString('exercise_catalog_last_error'),
        contains('checksum mismatch'));
    expect(File(result!.localDbPath).existsSync(), true);
  });

  test('incompatible cache cannot be used as the offline fallback', () async {
    await cache('202609020000', minSchema: 99);
    final refresh = await service('202609040000', offline: true);
    expect(
        await refresh.prepareUpdateCandidate(
            installedVersion: '202609010000', force: true),
        isNull);
  });

  test('within the check interval a newer cache is usable without network',
      () async {
    await cache('202609020000');
    await prefs.setInt(
        'exercise_catalog_last_checked_at', now.millisecondsSinceEpoch);
    final refresh = await service('202609040000');
    final result =
        await refresh.prepareUpdateCandidate(installedVersion: '202609010000');
    expect(result?.version, '202609020000');
    expect(requests, isEmpty);
  });
  for (final inline in [false, true]) {
    test(
        'offline cache requires relational or legacy inline text (inline=$inline)',
        () async {
      await cache('202609020000');
      final db = await databaseFactoryFfi
          .openDatabase('${temp.path}/cache/catalog.db');
      await db.execute('DROP TABLE exercise_translations');
      if (inline) {
        for (final column in [
          'name_de',
          'name_en',
          'description_de',
          'description_en'
        ]) {
          await db.execute('ALTER TABLE exercises ADD COLUMN $column TEXT');
        }
        await db.execute("UPDATE exercises SET name_en = 'Legacy exercise'");
      }
      await db.close();
      final refresh = await service('202609040000', offline: true);
      final result = await refresh.prepareUpdateCandidate(
          installedVersion: '202609010000', force: true);
      if (inline) {
        expect(result?.version, '202609020000');
      } else {
        expect(result, isNull);
      }
    });
  }

  test('the shipped OpenExerciseDB file passes remote cache validation',
      () async {
    final target = File('${temp.path}/cache/catalog.db');
    await target.parent.create(recursive: true);
    await File(AppDataSources.trainingAssetDbPath).copy(target.path);
    final manifest = jsonDecode(
        File(AppDataSources.trainingAssetManifestPath).readAsStringSync());
    await prefs.setString(
        'exercise_catalog_cached_version', manifest['version'] as String);
    final refresh = await service('202609040000', offline: true);
    final result = await refresh.prepareUpdateCandidate(
        installedVersion: '0', force: true);
    expect(result?.version, manifest['version']);
    expect(result?.fromCache, true);
  });
}
