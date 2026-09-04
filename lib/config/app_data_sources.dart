/// Central configuration for bundled and remote data sources.
///
/// Keep URLs, asset paths, and naming conventions here so feature logic
/// does not hardcode environment-specific locations.
class AppDataSources {
  const AppDataSources._();

  // Bundled assets
  static const String trainingAssetManifestPath =
      'assets/db/catalog_manifest.json';
  static const String trainingDbFileName = 'train_libre_training.db';
  static const String legacyTrainingDbFileName = 'hypertrack_training.db';
  static const String trainingAssetDbPath = 'assets/db/$trainingDbFileName';
  static const String legacyTrainingAssetDbPath =
      'assets/db/$legacyTrainingDbFileName';
  static const String baseFoodsDbFileName = 'train_libre_base_foods.db';
  static const String legacyBaseFoodsDbFileName = 'hypertrack_base_foods.db';
  static const String baseFoodsAssetDbPath = 'assets/db/$baseFoodsDbFileName';
  static const String legacyBaseFoodsAssetDbPath =
      'assets/db/$legacyBaseFoodsDbFileName';
  static const String offFoodsAssetDbPath = 'assets/db/train_libre_prep_de.db';
  static const String legacyOffFoodsAssetDbPath =
      'assets/db/hypertrack_prep_de.db';
  static const String foodCategoriesAssetDbPath =
      'assets/db/$baseFoodsDbFileName';
  static const String legacyFoodCategoriesAssetDbPath =
      'assets/db/$legacyBaseFoodsDbFileName';

  /// The catalog schema version this build of the app can consume.
  ///
  /// The data repo declares two numbers per release: `schema_version` (what
  /// the artefact *is*) and `min_app_schema_version` (the oldest consumer that
  /// can still read it). A release is rejected when its floor is higher than
  /// this number — so a v2 catalog that keeps the v1 compatibility columns
  /// filled, and therefore declares `min_app_schema_version: 1`, is still
  /// accepted here.
  ///
  /// Raise this only together with an importer that understands the new
  /// schema, and only once that release is broadly installed. A device that
  /// raises it early accepts a catalog it then fails to read.
  static const int supportedCatalogSchemaVersion = 1;

  // Remote training-catalog source: the OpenExerciseDB stable channel.
  //
  // The catalog used to be built inside this repository from the wger API and
  // published on its own release tag. It now lives in its own repository, with
  // its own schema, licence and release cadence — see the About screen and the
  // README for the attribution that move obliges.
  //
  // `sourceId` deliberately keeps the old value: `parseManifest` rejects any
  // manifest whose `source_id` does not match this string, and the published
  // manifest still declares `wger_catalog`. Renaming it here without renaming
  // it there would reject every release rather than accept a new one.
  static const exerciseCatalog = ExerciseCatalogRemoteSourceConfig(
    enabled: true,
    sourceId: 'wger_catalog',
    channel: 'stable',
    baseUrl:
        'https://github.com/rfivesix/OpenExerciseDB/releases/download/catalog-stable/',
    manifestPath: 'catalog_manifest.json',
    defaultDbPath: 'openexercisedb.db',
    // The new release publishes one database under one name. These paths are
    // only fallbacks for a manifest that omits `db_file`/`db_url`; there is no
    // second, older asset name to fall back to.
    legacyDefaultDbPath: null,
    defaultBuildReportPath: 'build_report.json',
    localCacheDirectoryName: 'catalog_refresh',
    localCacheDbFileName: 'train_libre_training_remote.db',
    legacyLocalCacheDbFileName: 'hypertrack_training_remote.db',
    localManifestFileName: 'wger_catalog_manifest_cached.json',
    manifestTimeoutSeconds: 6,
    downloadTimeoutSeconds: 30,
    minCheckIntervalHours: 12,
    minimumExerciseRows: 50,
    supportedSchemaVersion: supportedCatalogSchemaVersion,
  );

  static const OffCatalogCountry defaultOffCatalogCountry =
      OffCatalogCountry.de;

  static const List<OffCatalogCountry> supportedOffCatalogCountries = [
    OffCatalogCountry.de,
    OffCatalogCountry.ch,
    OffCatalogCountry.us,
    OffCatalogCountry.uk,
    OffCatalogCountry.fr,
    OffCatalogCountry.it,
    OffCatalogCountry.jp,
    OffCatalogCountry.at,
  ];

  /// OFF release-channel/manifest expectations per supported country.
  static const Map<OffCatalogCountry, OffCatalogRemoteSourceConfig>
      offCatalogs = {
    OffCatalogCountry.de: OffCatalogRemoteSourceConfig(
      enabled: true,
      sourceId: 'off_food_catalog',
      countryCode: 'de',
      channel: 'stable',
      releaseTag: 'off-foods-de-stable',
      baseUrl:
          'https://github.com/rfivesix/train-libre/releases/download/off-foods-de-stable/',
      manifestPath: 'off_catalog_manifest_de.json',
      defaultDbPath: 'train_libre_off_de.db',
      legacyDefaultDbPath: 'hypertrack_off_de.db',
      defaultBuildReportPath: 'off_build_report_de.json',
      // This asset path is intentionally allowed to be absent in release
      // builds. Startup will use a remote OFF DB when available; otherwise the
      // smaller bundled base-foods catalog remains usable.
      bundledAssetDbPath: 'assets/db/train_libre_prep_de.db',
      legacyBundledAssetDbPath: 'assets/db/hypertrack_prep_de.db',
      minimumProductRows: 5000,
      manifestTimeoutSeconds: 6,
      downloadTimeoutSeconds: 45,
      minCheckIntervalHours: 12,
      localCacheDirectoryName: 'off_catalog_refresh',
      localCacheDbFileName: 'train_libre_off_de_remote.db',
      legacyLocalCacheDbFileName: 'hypertrack_off_de_remote.db',
      localManifestFileName: 'off_catalog_manifest_de_cached.json',
    ),
    OffCatalogCountry.ch: OffCatalogRemoteSourceConfig(
      enabled: true,
      sourceId: 'off_food_catalog',
      countryCode: 'ch',
      channel: 'stable',
      releaseTag: 'off-foods-ch-stable',
      baseUrl:
          'https://github.com/rfivesix/train-libre/releases/download/off-foods-ch-stable/',
      manifestPath: 'off_catalog_manifest_ch.json',
      defaultDbPath: 'train_libre_off_ch.db',
      legacyDefaultDbPath: null,
      defaultBuildReportPath: 'off_build_report_ch.json',
      bundledAssetDbPath: 'assets/db/train_libre_prep_ch.db',
      legacyBundledAssetDbPath: null,
      minimumProductRows: 5000,
      manifestTimeoutSeconds: 6,
      downloadTimeoutSeconds: 45,
      minCheckIntervalHours: 12,
      localCacheDirectoryName: 'off_catalog_refresh',
      localCacheDbFileName: 'train_libre_off_ch_remote.db',
      legacyLocalCacheDbFileName: null,
      localManifestFileName: 'off_catalog_manifest_ch_cached.json',
    ),
    OffCatalogCountry.us: OffCatalogRemoteSourceConfig(
      enabled: true,
      sourceId: 'off_food_catalog',
      countryCode: 'us',
      channel: 'stable',
      releaseTag: 'off-foods-us-stable',
      baseUrl:
          'https://github.com/rfivesix/train-libre/releases/download/off-foods-us-stable/',
      manifestPath: 'off_catalog_manifest_us.json',
      defaultDbPath: 'train_libre_off_us.db',
      legacyDefaultDbPath: 'hypertrack_off_us.db',
      defaultBuildReportPath: 'off_build_report_us.json',
      bundledAssetDbPath: 'assets/db/train_libre_prep_us.db',
      legacyBundledAssetDbPath: 'assets/db/hypertrack_prep_us.db',
      minimumProductRows: 5000,
      manifestTimeoutSeconds: 6,
      downloadTimeoutSeconds: 45,
      minCheckIntervalHours: 12,
      localCacheDirectoryName: 'off_catalog_refresh',
      localCacheDbFileName: 'train_libre_off_us_remote.db',
      legacyLocalCacheDbFileName: 'hypertrack_off_us_remote.db',
      localManifestFileName: 'off_catalog_manifest_us_cached.json',
    ),
    OffCatalogCountry.uk: OffCatalogRemoteSourceConfig(
      enabled: true,
      sourceId: 'off_food_catalog',
      countryCode: 'uk',
      channel: 'stable',
      releaseTag: 'off-foods-uk-stable',
      baseUrl:
          'https://github.com/rfivesix/train-libre/releases/download/off-foods-uk-stable/',
      manifestPath: 'off_catalog_manifest_uk.json',
      defaultDbPath: 'train_libre_off_uk.db',
      legacyDefaultDbPath: 'hypertrack_off_uk.db',
      defaultBuildReportPath: 'off_build_report_uk.json',
      bundledAssetDbPath: 'assets/db/train_libre_prep_uk.db',
      legacyBundledAssetDbPath: 'assets/db/hypertrack_prep_uk.db',
      minimumProductRows: 5000,
      manifestTimeoutSeconds: 6,
      downloadTimeoutSeconds: 45,
      minCheckIntervalHours: 12,
      localCacheDirectoryName: 'off_catalog_refresh',
      localCacheDbFileName: 'train_libre_off_uk_remote.db',
      legacyLocalCacheDbFileName: 'hypertrack_off_uk_remote.db',
      localManifestFileName: 'off_catalog_manifest_uk_cached.json',
    ),
    OffCatalogCountry.fr: OffCatalogRemoteSourceConfig(
      enabled: true,
      sourceId: 'off_food_catalog',
      countryCode: 'fr',
      channel: 'stable',
      releaseTag: 'off-foods-fr-stable',
      baseUrl:
          'https://github.com/rfivesix/train-libre/releases/download/off-foods-fr-stable/',
      manifestPath: 'off_catalog_manifest_fr.json',
      defaultDbPath: 'train_libre_off_fr.db',
      legacyDefaultDbPath: null,
      defaultBuildReportPath: 'off_build_report_fr.json',
      bundledAssetDbPath: 'assets/db/train_libre_prep_fr.db',
      legacyBundledAssetDbPath: null,
      minimumProductRows: 5000,
      manifestTimeoutSeconds: 6,
      downloadTimeoutSeconds: 45,
      minCheckIntervalHours: 12,
      localCacheDirectoryName: 'off_catalog_refresh',
      localCacheDbFileName: 'train_libre_off_fr_remote.db',
      legacyLocalCacheDbFileName: null,
      localManifestFileName: 'off_catalog_manifest_fr_cached.json',
    ),
    OffCatalogCountry.it: OffCatalogRemoteSourceConfig(
      enabled: true,
      sourceId: 'off_food_catalog',
      countryCode: 'it',
      channel: 'stable',
      releaseTag: 'off-foods-it-stable',
      baseUrl:
          'https://github.com/rfivesix/train-libre/releases/download/off-foods-it-stable/',
      manifestPath: 'off_catalog_manifest_it.json',
      defaultDbPath: 'train_libre_off_it.db',
      legacyDefaultDbPath: null,
      defaultBuildReportPath: 'off_build_report_it.json',
      bundledAssetDbPath: 'assets/db/train_libre_prep_it.db',
      legacyBundledAssetDbPath: null,
      minimumProductRows: 5000,
      manifestTimeoutSeconds: 6,
      downloadTimeoutSeconds: 45,
      minCheckIntervalHours: 12,
      localCacheDirectoryName: 'off_catalog_refresh',
      localCacheDbFileName: 'train_libre_off_it_remote.db',
      legacyLocalCacheDbFileName: null,
      localManifestFileName: 'off_catalog_manifest_it_cached.json',
    ),
    OffCatalogCountry.jp: OffCatalogRemoteSourceConfig(
      enabled: true,
      sourceId: 'off_food_catalog',
      countryCode: 'jp',
      channel: 'stable',
      releaseTag: 'off-foods-jp-stable',
      baseUrl:
          'https://github.com/rfivesix/train-libre/releases/download/off-foods-jp-stable/',
      manifestPath: 'off_catalog_manifest_jp.json',
      defaultDbPath: 'train_libre_off_jp.db',
      legacyDefaultDbPath: null,
      defaultBuildReportPath: 'off_build_report_jp.json',
      bundledAssetDbPath: 'assets/db/train_libre_prep_jp.db',
      legacyBundledAssetDbPath: null,
      minimumProductRows: 5000,
      manifestTimeoutSeconds: 6,
      downloadTimeoutSeconds: 45,
      minCheckIntervalHours: 12,
      localCacheDirectoryName: 'off_catalog_refresh',
      localCacheDbFileName: 'train_libre_off_jp_remote.db',
      legacyLocalCacheDbFileName: null,
      localManifestFileName: 'off_catalog_manifest_jp_cached.json',
    ),
    OffCatalogCountry.at: OffCatalogRemoteSourceConfig(
      enabled: true,
      sourceId: 'off_food_catalog',
      countryCode: 'at',
      channel: 'stable',
      releaseTag: 'off-foods-at-stable',
      baseUrl:
          'https://github.com/rfivesix/train-libre/releases/download/off-foods-at-stable/',
      manifestPath: 'off_catalog_manifest_at.json',
      defaultDbPath: 'train_libre_off_at.db',
      legacyDefaultDbPath: null,
      defaultBuildReportPath: 'off_build_report_at.json',
      bundledAssetDbPath: 'assets/db/train_libre_prep_at.db',
      legacyBundledAssetDbPath: null,
      minimumProductRows: 5000,
      manifestTimeoutSeconds: 6,
      downloadTimeoutSeconds: 45,
      minCheckIntervalHours: 12,
      localCacheDirectoryName: 'off_catalog_refresh',
      localCacheDbFileName: 'train_libre_off_at_remote.db',
      legacyLocalCacheDbFileName: null,
      localManifestFileName: 'off_catalog_manifest_at_cached.json',
    ),
  };

  static OffCatalogRemoteSourceConfig offCatalogForCountry(
    OffCatalogCountry country,
  ) {
    return offCatalogs[country]!;
  }

  static String offFoodsAssetDbPathForCountry(OffCatalogCountry country) {
    return offCatalogForCountry(country).bundledAssetDbPath;
  }
}

class ExerciseCatalogRemoteSourceConfig {
  final bool enabled;
  final String sourceId;
  final String channel;
  final String baseUrl;
  final String manifestPath;
  final String defaultDbPath;
  final String? legacyDefaultDbPath;
  final String defaultBuildReportPath;
  final String localCacheDirectoryName;
  final String localCacheDbFileName;
  final String? legacyLocalCacheDbFileName;
  final String localManifestFileName;
  final int manifestTimeoutSeconds;
  final int downloadTimeoutSeconds;
  final int minCheckIntervalHours;
  final int minimumExerciseRows;

  /// Highest catalog schema version this app can read. See
  /// [AppDataSources.supportedCatalogSchemaVersion].
  final int supportedSchemaVersion;

  const ExerciseCatalogRemoteSourceConfig({
    required this.enabled,
    required this.sourceId,
    required this.channel,
    required this.baseUrl,
    required this.manifestPath,
    required this.defaultDbPath,
    this.legacyDefaultDbPath,
    required this.defaultBuildReportPath,
    required this.localCacheDirectoryName,
    required this.localCacheDbFileName,
    this.legacyLocalCacheDbFileName,
    required this.localManifestFileName,
    required this.manifestTimeoutSeconds,
    required this.downloadTimeoutSeconds,
    required this.minCheckIntervalHours,
    required this.minimumExerciseRows,
    this.supportedSchemaVersion = 1,
  });

  Duration get manifestTimeout => Duration(seconds: manifestTimeoutSeconds);
  Duration get downloadTimeout => Duration(seconds: downloadTimeoutSeconds);
  Duration get minCheckInterval => Duration(hours: minCheckIntervalHours);
}

enum OffCatalogCountry {
  de,
  ch,
  us,
  uk,
  fr,
  it,
  jp,
  at,
}

extension OffCatalogCountryX on OffCatalogCountry {
  String get code => switch (this) {
        OffCatalogCountry.de => 'de',
        OffCatalogCountry.ch => 'ch',
        OffCatalogCountry.us => 'us',
        OffCatalogCountry.uk => 'uk',
        OffCatalogCountry.fr => 'fr',
        OffCatalogCountry.it => 'it',
        OffCatalogCountry.jp => 'jp',
        OffCatalogCountry.at => 'at',
      };

  String get upperCode => code.toUpperCase();
}

class OffCatalogCountryCodec {
  const OffCatalogCountryCodec._();

  static OffCatalogCountry parseOrDefault(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    for (final country in AppDataSources.supportedOffCatalogCountries) {
      if (country.code == normalized) {
        return country;
      }
    }
    return AppDataSources.defaultOffCatalogCountry;
  }
}

class OffCatalogRemoteSourceConfig {
  final bool enabled;
  final String sourceId;
  final String countryCode;
  final String channel;
  final String releaseTag;
  final String baseUrl;
  final String manifestPath;
  final String defaultDbPath;
  final String? legacyDefaultDbPath;
  final String defaultBuildReportPath;
  final String bundledAssetDbPath;
  final String? legacyBundledAssetDbPath;
  final int minimumProductRows;
  final int manifestTimeoutSeconds;
  final int downloadTimeoutSeconds;
  final int minCheckIntervalHours;
  final String localCacheDirectoryName;
  final String localCacheDbFileName;
  final String? legacyLocalCacheDbFileName;
  final String localManifestFileName;

  const OffCatalogRemoteSourceConfig({
    required this.enabled,
    required this.sourceId,
    required this.countryCode,
    required this.channel,
    required this.releaseTag,
    required this.baseUrl,
    required this.manifestPath,
    required this.defaultDbPath,
    this.legacyDefaultDbPath,
    required this.defaultBuildReportPath,
    required this.bundledAssetDbPath,
    this.legacyBundledAssetDbPath,
    required this.minimumProductRows,
    required this.manifestTimeoutSeconds,
    required this.downloadTimeoutSeconds,
    required this.minCheckIntervalHours,
    required this.localCacheDirectoryName,
    required this.localCacheDbFileName,
    this.legacyLocalCacheDbFileName,
    required this.localManifestFileName,
  });

  Duration get manifestTimeout => Duration(seconds: manifestTimeoutSeconds);
  Duration get downloadTimeout => Duration(seconds: downloadTimeoutSeconds);
  Duration get minCheckInterval => Duration(hours: minCheckIntervalHours);
}
