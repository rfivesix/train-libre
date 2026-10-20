import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/services/bls_food_catalog_refresh_service.dart';

void main() {
  const baseUri =
      'https://github.com/rfivesix/train-libre-bls-catalog/releases/download/bls-foods-stable/';
  final manifest = <String, dynamic>{
    'source_id': 'bls_food_catalog',
    'channel': 'stable',
    'version': '4.0.0',
    'catalog_id': 'bls',
    'catalog_version': '4.0',
    'license': {'id': 'CC-BY-4.0'},
    'source': {
      'publisher': 'Max Rubner-Institut',
      'doi': '10.25826/Data20251217-134202-0',
    },
    'schema_version': 1,
    'min_app_schema_version': 1,
    'db_file': 'train_libre_base_foods.db.gz',
    'db_compression': 'gzip',
    'db_sha256': 'a' * 64,
    'download_sha256': 'b' * 64,
    'db_size_bytes': 86274048,
    'download_size_bytes': 26794921,
    'expected_food_count': 7140,
    'food_nutrient_fact_count': 985320,
  };

  group('BLS catalog release contract', () {
    test('parses the published stable gzip catalog manifest', () {
      final parsed = BlsFoodCatalogManifest.parse(
        manifest,
        Uri.parse(baseUri),
      );

      expect(parsed.version, '4.0.0');
      expect(parsed.schemaVersion, 1);
      expect(parsed.minAppSchemaVersion, 1);
      expect(parsed.dbUri.toString(), '${baseUri}train_libre_base_foods.db.gz');
      expect(parsed.expectedFoodCount, 7140);
      expect(parsed.foodNutrientFactCount, 985320);
    });

    test('rejects a manifest from a different source or compression format',
        () {
      final wrongSource = {...manifest, 'source_id': 'other'};
      expect(
        () => BlsFoodCatalogManifest.parse(wrongSource, Uri.parse(baseUri)),
        throwsFormatException,
      );

      final wrongCompression = {...manifest, 'db_compression': 'zip'};
      expect(
        () => BlsFoodCatalogManifest.parse(
          wrongCompression,
          Uri.parse(baseUri),
        ),
        throwsFormatException,
      );
    });

    test('rejects catalog schemas newer than this app supports', () {
      final newerSchema = {...manifest, 'schema_version': 99};
      expect(
        () => BlsFoodCatalogManifest.parse(newerSchema, Uri.parse(baseUri)),
        throwsFormatException,
      );
    });
  });

  group('BLS catalog versions', () {
    test('compares numeric version segments', () {
      expect(
        BlsFoodCatalogRefreshService.isRemoteVersionNewer(
          remoteVersion: '4.0.10',
          installedVersion: '4.0.9',
        ),
        isTrue,
      );
      expect(
        BlsFoodCatalogRefreshService.isRemoteVersionNewer(
          remoteVersion: '4.0.0',
          installedVersion: '4.0',
        ),
        isFalse,
      );
    });
  });
}
