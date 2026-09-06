import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/config/app_data_sources.dart';
import 'package:train_libre/services/exercise_catalog_refresh_service.dart';

/// The shipped configuration, held against the manifest actually published.
///
/// [ExerciseCatalogRefreshService.parseManifest] rejects silently: a mismatched
/// `source_id`, a missing `db_sha256`, a schema floor above what this build
/// declares — all of them return null, and the app simply never updates. That
/// failure looks exactly like "no new release yet", which is why pointing the
/// config at a new repository is worth a test rather than a read-through.
///
/// The fixture is a byte copy of
/// <https://github.com/rfivesix/OpenExerciseDB/releases/download/catalog-stable/catalog_manifest.json>.
/// It goes stale when the data repo publishes a new build; refresh it by
/// downloading that file again. What it pins is the contract between the two
/// repositories, not the contents of any one release.
void main() {
  final fixture = File(
    'test/fixtures/catalog/openexercisedb_catalog_manifest.json',
  );

  Map<String, dynamic> published() =>
      jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;

  group('the published catalog manifest', () {
    test('is accepted by the configuration this build ships', () {
      final manifest = ExerciseCatalogRefreshService.parseManifest(
        published(),
        AppDataSources.exerciseCatalog,
      );

      expect(
        manifest,
        isNotNull,
        reason: 'a rejected manifest is indistinguishable from no release',
      );
      expect(manifest!.schemaVersion, 2);
      expect(manifest.minAppSchemaVersion,
          lessThanOrEqualTo(AppDataSources.supportedCatalogSchemaVersion));
    });

    test('resolves to the release assets, not to the old repository', () {
      final manifest = ExerciseCatalogRefreshService.parseManifest(
        published(),
        AppDataSources.exerciseCatalog,
      )!;

      expect(manifest.dbUri.toString(), contains('OpenExerciseDB'));
      expect(manifest.dbUri.toString(), endsWith('openexercisedb.db'));
      expect(manifest.dbUri.scheme, 'https');
    });

    test('the configured base URL and manifest path address that file', () {
      // What the app requests before it has ever seen a manifest. Nothing
      // downstream can repair a wrong URL here: the first fetch 404s and the
      // catalog stays at whatever shipped in the asset.
      final config = AppDataSources.exerciseCatalog;
      expect(
        Uri.parse(config.baseUrl).resolve(config.manifestPath).toString(),
        'https://github.com/rfivesix/OpenExerciseDB/releases/download/'
        'catalog-stable/catalog_manifest.json',
      );
    });

    test('declares the source id parseManifest insists on', () {
      // The manifest still says `wger_catalog` even though the repository no
      // longer does. Whichever side changes that string first has to change
      // the other in the same release.
      expect(published()['source_id'], AppDataSources.exerciseCatalog.sourceId);
      expect(published()['channel'], AppDataSources.exerciseCatalog.channel);
    });
  });
}
