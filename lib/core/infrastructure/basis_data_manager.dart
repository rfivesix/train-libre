// lib/data/basis_data_manager.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import '../../data/database_helper.dart';
import '../../data/drift_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:drift/drift.dart' as drift;

import '../../config/app_data_sources.dart';
import '../../services/base_food_language_service.dart';
import '../../services/exercise_catalog_refresh_service.dart';
import '../../services/off_catalog_country_service.dart';
import '../../services/off_catalog_refresh_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../features/diary/domain/use_cases/retain_historical_off_products_use_case.dart';

// Type definition for the callback
typedef ProgressCallback = void Function(
    String task, String detail, double progress);
typedef RemoteCatalogProgressCallback = void Function(
  String task,
  String detail,
  double progress, {
  required bool canSkip,
});
typedef RemoteCatalogSkipRequested = bool Function();

/// Manager responsible for initializing and updating the application's base data.
///
/// Handles importing exercises, food products, and categories from asset databases
/// into the main application database.
enum BatchImportType { exercises, productsBase, categories, productsOff }

class _BatchImportPayload {
  final List<Map<String, dynamic>> rows;
  final BatchImportType type;
  final String? preferredLanguage;

  const _BatchImportPayload({
    required this.rows,
    required this.type,
    this.preferredLanguage,
  });
}

/// Holds raw primitives for one exercise row (isolate-safe).
class _ExerciseBundle {
  final Map<String, dynamic> exerciseFields;
  final List<Map<String, dynamic>> translationFields;

  const _ExerciseBundle({
    required this.exerciseFields,
    required this.translationFields,
  });
}

List<dynamic> _parseBatchInIsolate(_BatchImportPayload payload) {
  switch (payload.type) {
    case BatchImportType.exercises:
      return payload.rows.map(BasisDataManager._mapExerciseBundle).toList();
    case BatchImportType.categories:
      return payload.rows.map(BasisDataManager._mapCategoryRow).toList();
    case BatchImportType.productsBase:
      return payload.rows
          .map((r) => BasisDataManager._mapProductRow(r,
              sourceLabel: 'base',
              preferredLanguage: payload.preferredLanguage))
          .toList();
    case BatchImportType.productsOff:
      return payload.rows
          .map((r) => BasisDataManager._mapProductRow(r, sourceLabel: 'off'))
          .toList();
  }
}

class BasisDataManager {
  /// Singleton instance of [BasisDataManager].
  static final BasisDataManager instance = BasisDataManager._init();
  BasisDataManager._init();

  static const String _keyVersionTraining = 'installed_training_version';
  static const String _keyVersionFood = 'installed_food_version';
  static const String _keyVersionCats = 'installed_cats_version';

  /// Version key for the metadata enrichment (Caffeine, Ingredients, etc.)
  static const String _keyVersionFoodEnrichment =
      'installed_food_enrichment_v1';
  static const String _fallbackInstalledVersion = '000000000001';

  static int _parseInt(dynamic value) => (value as num?)?.toInt() ?? 0;
  static double _parseDouble(dynamic value) =>
      (value as num?)?.toDouble() ?? 0.0;
  static String _parseString(dynamic value) => value?.toString() ?? '';

  /// Public method to trigger the exercise catalog check and update process.
  Future<void> importExerciseCatalog({
    bool force = false,
    ProgressCallback? onProgress,
    RemoteCatalogProgressCallback? onRemoteProgress,
    RemoteCatalogSkipRequested? isRemoteSkipRequested,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (force) {
      await prefs.remove(_keyVersionTraining);
    }

    String? remoteTrainingDbPath;
    final installedTrainingVersion =
        prefs.getString(_keyVersionTraining) ?? '0';
    try {
      onProgress?.call(
        "Prüfe Übungen...",
        "Suche nach Remote-Katalog-Updates...",
        0.0,
      );
      final remoteCandidate =
          await ExerciseCatalogRefreshService.instance.prepareUpdateCandidate(
        installedVersion: installedTrainingVersion,
        force: force,
        onProgress: onRemoteProgress,
        isSkipRequested: isRemoteSkipRequested,
      );
      if (remoteCandidate != null) {
        remoteTrainingDbPath = remoteCandidate.localDbPath;
        debugPrint('[ExerciseCatalog] Remote update available: v${remoteCandidate.version}');
        onProgress?.call(
          "Update Übungen",
          "Remote-Katalog ${remoteCandidate.version} gefunden.",
          0.02,
        );
      }
    } catch (e) {
      debugPrint('[ExerciseCatalog] Remote check failed (non-fatal): $e');
    }

    await _updateDatabaseFromSource(
      assetPath: AppDataSources.trainingAssetDbPath,
      sourceFilePath: remoteTrainingDbPath,
      prefKey: _keyVersionTraining,
      prefs: prefs,
      tableName: 'exercises',
      driftTableName: null,
      legacyAssetPath: AppDataSources.legacyTrainingAssetDbPath,
      importType: BatchImportType.exercises,
      preferredLanguage: null,
      taskLabel: 'Übungen',
      onProgress: onProgress,
      forceImport: force,
      enableOffReplacementRetention: false,
    );
  }

  /// Checks for updates to the basis data and performs an import if necessary.
  ///
  /// The [force] parameter triggers a re-import regardless of version mismatch.
  /// The [onProgress] callback reports the ongoing task, details, and percentage.
  Future<void> checkForBasisDataUpdate({
    bool force = false,
    ProgressCallback? onProgress, // New: callback
    RemoteCatalogProgressCallback? onRemoteProgress,
    RemoteCatalogSkipRequested? isRemoteSkipRequested,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (force) {
      await prefs.remove(_keyVersionFood);
      await _clearOffVersionPreferences(prefs);
      await prefs.remove(_keyVersionCats);
    }

    // --- FIX 1 & 2: Always run the exercise catalog check, independent of the
    // food/category sync gate. This decouples exercise versioning (uses its own
    // _keyVersionTraining pref key) from the food enrichment guard.
    //
    // Additionally, if the exercises table is empty but SharedPreferences still
    // holds a version (e.g. after an iOS sandbox reset that wiped SQLite while
    // NSUserDefaults survived), we force a re-seed to recover the catalog.
    final mainDb = await DatabaseHelper.instance.database;

    final exerciseCountRow = await mainDb
        .customSelect('SELECT COUNT(*) AS c FROM exercises')
        .getSingleOrNull();
    final exerciseCountDb = exerciseCountRow?.read<int>('c') ?? 0;
    final translationCountRow = await mainDb
        .customSelect('SELECT COUNT(*) AS c FROM exercise_translations')
        .getSingleOrNull();
    final translationCountDb = translationCountRow?.read<int>('c') ?? 0;

    final exercisesEmpty = exerciseCountDb == 0;
    // Treat severely under-translated catalogs as corrupt: a real wger import
    // gives at least 1 translation per exercise. Fewer means Phase 2 failed.
    final translationsHealthy =
        exerciseCountDb == 0 || (translationCountDb >= exerciseCountDb);

    if (exercisesEmpty || !translationsHealthy) {
      await prefs.remove(_keyVersionTraining);
      if (exercisesEmpty) {
        debugPrint(
          '[ExerciseCatalog] ⚠️  exercises table empty → forcing re-seed '
          '(sandbox reset: NSUserDefaults survived SQLite wipe).',
        );
      } else {
        debugPrint(
          '[ExerciseCatalog] ⚠️  Under-translated: $translationCountDb translations '
          'for $exerciseCountDb exercises → forcing re-seed.',
        );
      }
    }

    await importExerciseCatalog(
      force: force,
      onProgress: onProgress,
      onRemoteProgress: onRemoteProgress,
      isRemoteSkipRequested: isRemoteSkipRequested,
    );

    // Post-import sanity check – only log if something looks wrong.
    final postExRow = await mainDb
        .customSelect('SELECT COUNT(*) AS c FROM exercises')
        .getSingleOrNull();
    final postExCount = postExRow?.read<int>('c') ?? 0;
    final postTrRow = await mainDb
        .customSelect('SELECT COUNT(*) AS c FROM exercise_translations')
        .getSingleOrNull();
    final postTrCount = postTrRow?.read<int>('c') ?? 0;
    if (postExCount == 0) {
      debugPrint('[ExerciseCatalog] ❌ exercises still EMPTY after import!');
    } else if (postTrCount < postExCount) {
      debugPrint('[ExerciseCatalog] ❌ translations ($postTrCount) still below exercises ($postExCount) after import!');
    } else {
      debugPrint('[ExerciseCatalog] ✅ $postExCount exercises / $postTrCount translations ready.');
    }

    final activeOffSource = OffCatalogCountryService.activeSourceFromPrefs(
      prefs,
    );
    final activeOffCountry = OffCatalogCountryCodec.parseOrDefault(
      activeOffSource.countryCode,
    );
    await _migrateLegacyOffVersionPreference(
      prefs: prefs,
      country: activeOffCountry,
    );
    final activeOffVersionKey =
        OffCatalogCountryService.installedVersionKeyForCountry(
      activeOffCountry,
    );

    final packageInfo = await PackageInfo.fromPlatform();
    final currentAppVersion = packageInfo.version;
    final currentAppBuild = packageInfo.buildNumber;
    final lastDbSyncAppVersion = prefs.getString('last_db_sync_app_version');
    final bool isEnriched = prefs.getBool(_keyVersionFoodEnrichment) ?? false;
    final bool forceEnrichment = !isEnriched;

    final bool shouldSync =
        force || currentAppBuild != lastDbSyncAppVersion || forceEnrichment;

    if (!shouldSync) {
      onProgress?.call(
        'Basis-Produkte',
        'Basis-Produkte sind aktuell.',
        1.0,
      );
      onProgress?.call(
        'Kategorien',
        'Kategorien sind aktuell.',
        1.0,
      );
      onProgress?.call(
        'Produktdatenbank (${activeOffCountry.upperCode})',
        'OFF-Datenbank ist aktuell (Version: $currentAppVersion).',
        1.0,
      );
      return;
    }

    // Helper function to keep the code readable.
    Future<void> process(
      String label,
      String asset,
      String key,
      String table,
      BatchImportType importType, {
      String? sourceFilePath,
      String? legacyAssetPath,
      String? driftTable,
      String? preferredLanguage,
      bool enableOffReplacementRetention = false,
      bool? forceImportOverride,
    }) async {
      await _updateDatabaseFromSource(
        assetPath: asset,
        sourceFilePath: sourceFilePath,
        prefKey: key,
        prefs: prefs,
        tableName: table,
        driftTableName: driftTable,
        legacyAssetPath: legacyAssetPath,
        importType: importType,
        preferredLanguage: preferredLanguage,
        taskLabel: label,
        onProgress: onProgress,
        forceImport: forceImportOverride ?? force,
        enableOffReplacementRetention: enableOffReplacementRetention,
      );
    }

    // 2a. Base Foods
    // Read the preferred display language once before import.
    final baseFoodLang = await BaseFoodLanguageService.readChoice(prefs: prefs);
    final baseFoodLangCode = _resolveBaseFoodLangCode(
      choice: baseFoodLang,
      offCountry: activeOffCountry,
    );
    await process(
      'Basis-Produkte',
      AppDataSources.baseFoodsAssetDbPath,
      _keyVersionFood,
      'products',
      BatchImportType.productsBase,
      preferredLanguage: baseFoodLangCode,
      legacyAssetPath: AppDataSources.legacyBaseFoodsAssetDbPath,
      forceImportOverride: force || forceEnrichment,
    );

    // 2b. Categories
    await process(
      'Kategorien',
      AppDataSources.foodCategoriesAssetDbPath,
      _keyVersionCats,
      'categories',
      BatchImportType.categories,
      driftTable: 'food_categories',
      legacyAssetPath: AppDataSources.legacyFoodCategoriesAssetDbPath,
    );

    String? remoteOffDbPath;
    final installedOffVersion = prefs.getString(activeOffVersionKey) ?? '0';
    try {
      onProgress?.call(
        'Prüfe Produktdatenbank (${activeOffCountry.upperCode})...',
        'Suche nach Remote-OFF-Katalog-Updates...',
        0.0,
      );
      final remoteOffCandidate =
          await OffCatalogRefreshService.instance.prepareUpdateCandidate(
        installedVersion: installedOffVersion,
        force: force,
        onProgress: onRemoteProgress,
        isSkipRequested: isRemoteSkipRequested,
      );
      if (remoteOffCandidate != null) {
        remoteOffDbPath = remoteOffCandidate.localDbPath;
        onProgress?.call(
          'Update Produktdatenbank (${activeOffCountry.upperCode})',
          'Remote-OFF-Katalog ${remoteOffCandidate.version} gefunden.',
          0.02,
        );
      }
    } catch (e) {
      debugPrint('Remote OFF catalog check skipped safely: $e');
    }

    final hasBundledOffAsset =
        await OffCatalogCountryService.bundledAssetAvailableForCountry(
      activeOffCountry,
    );

    if (remoteOffDbPath == null && !hasBundledOffAsset) {
      onProgress?.call(
        'Produktdatenbank (${activeOffCountry.upperCode})',
        'Kein OFF-Bundle/Remote verfügbar. Vorhandene lokale OFF-Daten bleiben unverändert.',
        1.0,
      );
      await prefs.setString('last_db_sync_app_version', currentAppBuild);
      return;
    }

    // 3. OFF database (the large file)
    await process(
      'Produktdatenbank (${activeOffCountry.upperCode})',
      activeOffSource.bundledAssetDbPath,
      activeOffVersionKey,
      'products',
      BatchImportType.productsOff,
      sourceFilePath: remoteOffDbPath,
      legacyAssetPath: activeOffSource.legacyBundledAssetDbPath,
      enableOffReplacementRetention: true,
      forceImportOverride: force || forceEnrichment,
    );

    await prefs.setString('last_db_sync_app_version', currentAppBuild);
  }

  /// Exposes a public method that bypasses the version check for manual triggers.
  Future<void> forceSyncDatabase({
    ProgressCallback? onProgress,
    RemoteCatalogProgressCallback? onRemoteProgress,
    RemoteCatalogSkipRequested? isRemoteSkipRequested,
  }) async {
    await checkForBasisDataUpdate(
      force: true,
      onProgress: onProgress,
      onRemoteProgress: onRemoteProgress,
      isRemoteSkipRequested: isRemoteSkipRequested,
    );
  }

  Future<void> _clearOffVersionPreferences(SharedPreferences prefs) async {
    await prefs.remove(OffCatalogCountryService.legacyInstalledVersionKey);
    final offVersionKeys = prefs
        .getKeys()
        .where(
          (key) => key.startsWith(
            OffCatalogCountryService.installedVersionKeyPrefix,
          ),
        )
        .toList(growable: false);
    for (final key in offVersionKeys) {
      await prefs.remove(key);
    }
  }

  Future<void> _migrateLegacyOffVersionPreference({
    required SharedPreferences prefs,
    required OffCatalogCountry country,
  }) async {
    // Keep existing DE installations stable when upgrading from a single OFF
    // version key to country-scoped OFF version keys.
    if (country != OffCatalogCountry.de) return;
    final targetKey = OffCatalogCountryService.installedVersionKeyForCountry(
      country,
    );
    if (prefs.containsKey(targetKey)) return;
    final legacyValue = prefs
        .getString(OffCatalogCountryService.legacyInstalledVersionKey)
        ?.trim();
    if (legacyValue == null || legacyValue.isEmpty) return;
    await prefs.setString(targetKey, legacyValue);
  }

  Future<void> _updateDatabaseFromSource({
    required String assetPath,
    String? sourceFilePath,
    String? legacyAssetPath,
    required String prefKey,
    required SharedPreferences prefs,
    required String tableName,
    String? driftTableName,
    required BatchImportType importType,
    String? preferredLanguage,
    required String taskLabel,
    ProgressCallback? onProgress,
    required bool forceImport,
    required bool enableOffReplacementRetention,
  }) async {
    File? tempFile;
    sqflite.Database? assetDb;

    try {
      // Initiale Meldung (0%)
      onProgress?.call("Prüfe $taskLabel...", "Initialisiere...", 0.0);

      // ── Source selection ───────────────────────────────────────────────────
      if (sourceFilePath != null &&
          sourceFilePath.isNotEmpty &&
          await File(sourceFilePath).exists()) {
        debugPrint('[ExerciseCatalog]   [$taskLabel] Opening REMOTE source: $sourceFilePath');
        try {
          assetDb = await sqflite.openDatabase(sourceFilePath, readOnly: true);
        } catch (e) {
          debugPrint(
            '[ExerciseCatalog]   [$taskLabel] Remote source open FAILED – falling back to bundled asset: $e',
          );
        }
      } else {
        debugPrint('[ExerciseCatalog]   [$taskLabel] No remote source → will use bundled asset: $assetPath');
      }

      if (assetDb == null) {
        final tempDir = await getTemporaryDirectory();
        final tempPath = p.join(tempDir.path, p.basename(assetPath));

        try {
          ByteData byteData;
          try {
            byteData = await rootBundle.load(assetPath);
            debugPrint('[ExerciseCatalog]   [$taskLabel] Bundled asset loaded: $assetPath (${byteData.lengthInBytes} bytes)');
            // Guard: a 0-byte asset is an empty placeholder — opening it as a
            // SQLite DB produces a valid empty database with no tables, which
            // causes the importer to silently skip without importing anything.
            if (byteData.lengthInBytes == 0) {
              debugPrint('[ExerciseCatalog] ❌ [$taskLabel] Bundled asset is 0 bytes – import aborted. '
                  'Drop a real SQLite file at $assetPath.');
              return;
            }
          } catch (_) {
            if (legacyAssetPath == null) rethrow;
            debugPrint('[ExerciseCatalog]   [$taskLabel] Primary asset missing → trying legacy: $legacyAssetPath');
            byteData = await rootBundle.load(legacyAssetPath);
            debugPrint('[ExerciseCatalog]   [$taskLabel] Legacy asset loaded: $legacyAssetPath (${byteData.lengthInBytes} bytes)');
            if (byteData.lengthInBytes == 0) {
              debugPrint('[ExerciseCatalog] ❌ [$taskLabel] Legacy asset is also 0 bytes – import aborted.');
              return;
            }
          }
          tempFile = File(tempPath);
          await tempFile.writeAsBytes(
            byteData.buffer.asUint8List(
              byteData.offsetInBytes,
              byteData.lengthInBytes,
            ),
          );
        } catch (e) {
          debugPrint(
            '[ExerciseCatalog] ❌ [$taskLabel] Asset load FAILED – import aborted: $assetPath ($e)',
          );
          return;
        }

        assetDb = await sqflite.openDatabase(tempPath, readOnly: true);
      }

      // ── Table discovery ───────────────────────────────────────────────────
      var checkTable = tableName;
      if (tableName == 'exercises') {
        final tables = await assetDb.query(
          'sqlite_master',
          columns: ['name'],
          where: "type = ? AND name = ?",
          whereArgs: ['table', 'exercises'],
        );
        if (tables.isEmpty) {
          checkTable = 'exercise';
          debugPrint('[ExerciseCatalog] [$taskLabel] Using fallback table name "exercise"');
        }
      } else {
        final tables = await assetDb.query(
          'sqlite_master',
          columns: ['name'],
          where: "type = ? AND name = ?",
          whereArgs: ['table', tableName],
        );
        if (tables.isEmpty) {
          debugPrint('[ExerciseCatalog] ❌ [$taskLabel] Source table "$tableName" not found in asset DB – aborting.');
          return;
        }
      }

      // ── Version check ──────────────────────────────────────────────────────
      String assetVersion = '0';
      try {
        final metaRows = await assetDb.query(
          'metadata',
          where: 'key = ?',
          whereArgs: ['version'],
        );
        if (metaRows.isNotEmpty) {
          assetVersion = _normalizeVersion(metaRows.first['value']);
        }
      } catch (_) {
      debugPrint('[ExerciseCatalog]   [$taskLabel] No metadata table in asset DB – assetVersion = "0"');
      }

      final String installedVersion = prefs.getString(prefKey) ?? '0';
      final mainDb = await DatabaseHelper.instance.database;
      final hasExistingData = await _hasInitializedData(
        mainDb: mainDb,
        prefKey: prefKey,
      );

      final shouldImport = shouldImportAsset(
        forceImport: forceImport,
        assetVersion: assetVersion,
        installedVersion: installedVersion,
        hasExistingDataForVersionlessAsset: hasExistingData,
      );

      if (importType == BatchImportType.exercises) {
        debugPrint(
          '[ExerciseCatalog] [$taskLabel] '
          'asset=$assetVersion installed=$installedVersion '
          'existing=$hasExistingData force=$forceImport → import=$shouldImport',
        );
      }

      if (shouldImport) {
        onProgress?.call("Update $taskLabel", "Vorbereitung...", 0.05);

        final importedBarcodes = await _performBatchImport(
          assetDb,
          checkTable,
          importType,
          preferredLanguage,
          onProgress,
          taskLabel,
          collectProductBarcodes: enableOffReplacementRetention,
        );

        if (enableOffReplacementRetention) {
          await retainHistoricallyNeededOffProducts(
            importedOffBarcodes: importedBarcodes,
            onProgress: onProgress,
          );
        }

        final storedVersion = storedVersionAfterImport(assetVersion: assetVersion);
        await prefs.setString(prefKey, storedVersion);

        // If we just successfully imported base foods, mark the enrichment version as well.
        if (prefKey == _keyVersionFood) {
          await prefs.setBool(_keyVersionFoodEnrichment, true);
        }
      } else {
        // If current, briefly show 100% so it does not hang.
        if (installedVersion == '0' &&
            assetVersion == '0' &&
            hasExistingData &&
            !forceImport) {
          await prefs.setString(prefKey, _fallbackInstalledVersion);
        }
        onProgress?.call("$taskLabel aktuell", "Bereit", 1.0);
      }
    } finally {
      await assetDb?.close();
      if (tempFile != null && await tempFile.exists()) await tempFile.delete();
    }
  }

  static bool shouldImportAsset({
    required bool forceImport,
    required String assetVersion,
    required String installedVersion,
    required bool hasExistingDataForVersionlessAsset,
  }) {
    if (forceImport) return true;
    if (assetVersion.compareTo(installedVersion) > 0) return true;
    if (installedVersion != '0') return false;

    // Guard: if the asset provides no version but data already exists,
    // do not import again on every startup.
    if (assetVersion == '0' && hasExistingDataForVersionlessAsset) {
      return false;
    }
    return true;
  }

  static String storedVersionAfterImport({required String assetVersion}) {
    return assetVersion == '0' ? _fallbackInstalledVersion : assetVersion;
  }

  String _normalizeVersion(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? '0' : normalized;
  }

  Future<bool> _hasInitializedData({
    required AppDatabase mainDb,
    required String prefKey,
  }) async {
    switch (prefKey) {
      case _keyVersionTraining:
        final row = await mainDb
            .customSelect('SELECT 1 FROM exercises LIMIT 1')
            .getSingleOrNull();
        return row != null;
      case _keyVersionFood:
        final row = await mainDb.customSelect(
          'SELECT 1 FROM products WHERE source = ? LIMIT 1',
          variables: [drift.Variable.withString('base')],
        ).getSingleOrNull();
        return row != null;
      case OffCatalogCountryService.legacyInstalledVersionKey:
        final row = await mainDb.customSelect(
          'SELECT 1 FROM products WHERE source = ? LIMIT 1',
          variables: [drift.Variable.withString('off')],
        ).getSingleOrNull();
        return row != null;
      case _keyVersionCats:
        final row = await mainDb
            .customSelect('SELECT 1 FROM food_categories LIMIT 1')
            .getSingleOrNull();
        return row != null;
      default:
        if (prefKey.startsWith(
          OffCatalogCountryService.installedVersionKeyPrefix,
        )) {
          final row = await mainDb.customSelect(
            'SELECT 1 FROM products WHERE source = ? LIMIT 1',
            variables: [drift.Variable.withString('off')],
          ).getSingleOrNull();
          return row != null;
        }
        return false;
    }
  }

  Future<Set<String>> _performBatchImport(
    sqflite.Database assetDb,
    String tableName,
    BatchImportType importType,
    String? preferredLanguage,
    ProgressCallback? onProgress,
    String taskLabel, {
    required bool collectProductBarcodes,
  }) async {
    final mainDb = await DatabaseHelper.instance.database;
    const int batchSize = 2000;
    int offset = 0;
    final importedProductBarcodes = <String>{};

    // 1. Determine total count for progress bar
    int totalCount = 0;
    try {
      final countResult = await assetDb.query(
        tableName,
        columns: ['COUNT(*) as c'],
      );
      totalCount = sqflite.Sqflite.firstIntValue(countResult) ?? 0;
    } catch (_) {
      totalCount = 0;
    }

    if (totalCount == 0) {
      debugPrint('[ExerciseCatalog] ❌ [$taskLabel] Source table has 0 rows – import skipped entirely!');
      return importedProductBarcodes;
    }

    int processed = 0;
    int totalExercisesInserted = 0;
    int totalTranslationsInserted = 0;
    int batchNumber = 0;

    while (true) {
      final rows = await assetDb.query(
        tableName,
        limit: batchSize,
        offset: offset,
      );
      if (rows.isEmpty) break;
      batchNumber++;

      final mappedCompanions = await compute(
        _parseBatchInIsolate,
        _BatchImportPayload(
          rows: rows,
          type: importType,
          preferredLanguage: preferredLanguage,
        ),
      );

      // Exercise bundles need two passes: first insert exercises, then translations.
      final exerciseBundles =
          mappedCompanions.whereType<_ExerciseBundle>().toList();
      final otherCompanions =
          mappedCompanions.where((c) => c is! _ExerciseBundle).toList();

      debugPrint(
        '[ExerciseCatalog]   [$taskLabel] Batch #$batchNumber: '
        '${rows.length} source rows → '
        '${exerciseBundles.length} exercise bundles, '
        '${otherCompanions.length} other companions',
      );
      await mainDb.batch((batch) {
        for (final companion in otherCompanions) {
          try {
            if (companion is ProductsCompanion) {
              if (collectProductBarcodes &&
                  companion.barcode.present &&
                  companion.barcode.value.trim().isNotEmpty) {
                importedProductBarcodes.add(companion.barcode.value.trim());
              }
              batch.insert(
                mainDb.products,
                companion,
                mode: drift.InsertMode.insertOrReplace,
              );
            } else if (companion is FoodCategoriesCompanion) {
              batch.insert(
                mainDb.foodCategories,
                companion,
                mode: drift.InsertMode.insertOrReplace,
              );
            }
          } catch (e) {
            debugPrint('[ExerciseCatalog]   [$taskLabel] Skipping malformed non-exercise row: $e');
          }
        }
      });

      if (exerciseBundles.isNotEmpty) {
        // Wrap the two-phase exercise + translation insert in a single atomic
        // transaction. An iOS background process kill between Phase 1 and
        // Phase 2 would otherwise leave exercises with no translations.
        int batchExCount = 0;
        int batchTrCount = 0;

        try {
          await mainDb.transaction(() async {
            // Phase 1: Upsert base exercise rows.
            await mainDb.batch((batch) {
              for (final bundle in exerciseBundles) {
                try {
                  final fields = bundle.exerciseFields;
                  final exerciseId = _parseString(fields['id']);
                  if (exerciseId.isEmpty) {
                    debugPrint('[ExerciseCatalog]   [$taskLabel] ⚠️  Skipping exercise with empty id');
                    return;
                  }
                  final exerciseCompanion = ExercisesCompanion(
                    id: drift.Value(exerciseId),
                    categoryName:
                        drift.Value(_parseString(fields['category_name'])),
                    musclesPrimary:
                        drift.Value(_parseString(fields['muscles_primary'])),
                    musclesSecondary:
                        drift.Value(_parseString(fields['muscles_secondary'])),
                    isCustom: const drift.Value(false),
                    createdBy: const drift.Value('system'),
                    source: const drift.Value('wger'),
                  );
                  batch.insert(
                    mainDb.exercises,
                    exerciseCompanion,
                    onConflict: drift.DoUpdate(
                      (_) => exerciseCompanion,
                      target: [mainDb.exercises.id],
                    ),
                  );
                  batchExCount++;
                } catch (e) {
                  debugPrint('[ExerciseCatalog]   [$taskLabel] ⚠️  Skipping malformed exercise: $e');
                }
              }
            });

            // Phase 2: Upsert translations — FK-safe within the same transaction.
            await mainDb.batch((batch) {
              for (final bundle in exerciseBundles) {
                for (final t in bundle.translationFields) {
                  try {
                    final companion = ExerciseTranslationsCompanion(
                      exerciseId: drift.Value(_parseString(t['exercise_id'])),
                      languageCode: drift.Value(_parseString(t['language_code'])),
                      name: drift.Value(_parseString(t['name'])),
                      description: drift.Value(t['description'] as String?),
                    );
                    batch.insert(
                      mainDb.exerciseTranslations,
                      companion,
                      onConflict: drift.DoUpdate(
                        (_) => companion,
                        target: [
                          mainDb.exerciseTranslations.exerciseId,
                          mainDb.exerciseTranslations.languageCode,
                        ],
                      ),
                    );
                    batchTrCount++;
                  } catch (e) {
                    debugPrint(
                        '[ExerciseCatalog]   [$taskLabel] ⚠️  Skipping malformed translation: $e');
                  }
                }
              }
            });
          });

          totalExercisesInserted += batchExCount;
          totalTranslationsInserted += batchTrCount;
        } catch (e) {
          debugPrint(
            '[ExerciseCatalog] ❌ [$taskLabel] Batch #$batchNumber TRANSACTION FAILED – rolled back: $e',
          );
        }
      }

      processed += rows.length;
      offset += batchSize;

      // Progress melden
      if (onProgress != null) {
        final double progress = (processed / totalCount).clamp(0.0, 1.0);
        onProgress(
          "Update $taskLabel",
          "$processed / $totalCount Einträge",
          progress,
        );
      }

      // Let the UI thread breathe
      await Future.delayed(const Duration(milliseconds: 1));
    }

    // ── Relational translation pass ─────────────────────────────────────────
    // The current asset DB schema stores translations in a separate
    // `exercise_translations` table, not as flat columns (name_de/name_en)
    // on the exercise row. _mapExerciseBundle only handles flat columns, so
    // translations were never written in the loop above.
    // This pass reads the source DB's exercise_translations table directly.
    if (importType == BatchImportType.exercises) {
      final trTables = await assetDb.query(
        'sqlite_master',
        columns: ['name'],
        where: "type = 'table' AND name = 'exercise_translations'",
      );
      if (trTables.isNotEmpty) {
        int trTotal = 0;
        try {
          final countResult = await assetDb.query(
            'exercise_translations',
            columns: ['COUNT(*) as c'],
          );
          trTotal = sqflite.Sqflite.firstIntValue(countResult) ?? 0;
        } catch (_) {}

        debugPrint(
          '[ExerciseCatalog]   [$taskLabel] Relational translation pass: '
          '$trTotal rows in source exercise_translations table',
        );

        int trOffset = 0;
        int trBatch = 0;
        int relationalTrInserted = 0;

        while (true) {
          final trRows = await assetDb.query(
            'exercise_translations',
            limit: batchSize,
            offset: trOffset,
          );
          if (trRows.isEmpty) break;
          trBatch++;

          try {
            await mainDb.batch((batch) {
              for (final t in trRows) {
                try {
                  final exerciseId = _parseString(t['exercise_id']);
                  final langCode = _parseString(t['language_code']);
                  final name = _parseString(t['name']);
                  if (exerciseId.isEmpty || langCode.isEmpty || name.isEmpty) {
                    continue;
                  }
                  final companion = ExerciseTranslationsCompanion(
                    exerciseId: drift.Value(exerciseId),
                    languageCode: drift.Value(langCode),
                    name: drift.Value(name),
                    description: drift.Value(t['description'] as String?),
                  );
                  batch.insert(
                    mainDb.exerciseTranslations,
                    companion,
                    onConflict: drift.DoUpdate(
                      (_) => companion,
                      target: [
                        mainDb.exerciseTranslations.exerciseId,
                        mainDb.exerciseTranslations.languageCode,
                      ],
                    ),
                  );
                  relationalTrInserted++;
                } catch (e) {
                  debugPrint(
                    '[ExerciseCatalog]   [$taskLabel] ⚠️  Skipping malformed relational translation: $e',
                  );
                }
              }
            });
          } catch (e) {
            debugPrint(
              '[ExerciseCatalog] ❌ [$taskLabel] Relational translation batch #$trBatch FAILED: $e',
            );
          }

          trOffset += batchSize;
          await Future.delayed(const Duration(milliseconds: 1));
        }

        totalTranslationsInserted += relationalTrInserted;
        debugPrint(
          '[ExerciseCatalog]   [$taskLabel] Relational translation pass complete: '
          '$relationalTrInserted / $trTotal rows written',
        );
      } else {
        debugPrint(
          '[ExerciseCatalog]   [$taskLabel] No exercise_translations table in source DB '
          '– relying on flat-column translations only ($totalTranslationsInserted written)',
        );
      }

      debugPrint(
        '[ExerciseCatalog]   [$taskLabel] ── Batch import complete ──────────────────',
      );
      debugPrint(
        '[ExerciseCatalog]   [$taskLabel]   Source rows processed  : $processed / $totalCount',
      );
      debugPrint(
        '[ExerciseCatalog]   [$taskLabel]   Exercises inserted/updated: $totalExercisesInserted',
      );
      debugPrint(
        '[ExerciseCatalog]   [$taskLabel]   Translations inserted/updated: $totalTranslationsInserted',
      );
      if (totalExercisesInserted == 0) {
        debugPrint('[ExerciseCatalog] ❌ [$taskLabel] ZERO exercises written – check source DB and mapping!');
      } else if (totalTranslationsInserted == 0) {
        debugPrint('[ExerciseCatalog] ❌ [$taskLabel] ZERO translations written – exercises will be invisible!');
      }
    }

    return importedProductBarcodes;
  }

  /// Applies OFF replacement semantics with historical retention:
  /// - Keep imported barcodes active (`source='off'` via import mapping)
  /// - Demote historically protected, no-longer-imported rows to `off_retained`
  /// - Delete no-longer-imported rows that are not historically referenced
  @visibleForTesting
  Future<void> retainHistoricallyNeededOffProducts({
    required Set<String> importedOffBarcodes,
    ProgressCallback? onProgress,
    AppDatabase? testingDatabase,
  }) async {
    final db = testingDatabase ?? await DatabaseHelper.instance.database;
    await const RetainHistoricalOffProductsUseCase().execute(
      database: db,
      importedOffBarcodes: importedOffBarcodes,
      onProgress: onProgress != null
          ? (msg, detail, progress) => onProgress(msg, detail, progress)
          : null,
    );
  }

  @visibleForTesting
  dynamic mapProductRowForTesting(Map<String, dynamic> row,
      {required String sourceLabel, String? preferredLanguage}) {
    return _mapProductRow(row,
        sourceLabel: sourceLabel, preferredLanguage: preferredLanguage);
  }

  // --- Mapping functions (unchanged) ---

  static dynamic _mapProductRow(
    Map<String, dynamic> row, {
    required String sourceLabel,
    String? preferredLanguage,
  }) {
    var barcode = _parseString(row['barcode']);
    String id;
    if (row['id'] != null) {
      id = _parseString(row['id']);
    } else if (barcode.isNotEmpty) {
      id = 'manual_$barcode';
    } else {
      id = 'manual_${_parseString(row['name']).replaceAll(RegExp(r'\s+'), '')}';
    }

    if (barcode.isEmpty) {
      barcode = id;
    }

    // Always persist both language variants when available.
    final rawNameDe = row['name_de']?.toString();
    final rawNameEn = row['name_en']?.toString();
    final rawNameFr = row['name_fr']?.toString();
    final rawNameIt = row['name_it']?.toString();
    final rawNameJa = row['name_ja']?.toString();
    final rawName = row['name']?.toString() ?? '';

    // Select the display name (for the legacy `name` column) based on preference.
    String displayName;
    if (preferredLanguage == 'en') {
      displayName = _parseString(rawNameEn ?? rawNameDe ?? rawName);
    } else if (preferredLanguage == 'fr') {
      displayName =
          _parseString(rawNameFr ?? rawNameEn ?? rawNameDe ?? rawName);
    } else if (preferredLanguage == 'it') {
      displayName =
          _parseString(rawNameIt ?? rawNameEn ?? rawNameDe ?? rawName);
    } else if (preferredLanguage == 'ja') {
      displayName =
          _parseString(rawNameJa ?? rawNameEn ?? rawNameDe ?? rawName);
    } else {
      displayName = _parseString(rawNameDe ?? rawNameEn ?? rawName);
    }

    bool isFluidVal = false;
    final isFluidRaw = row['is_fluid'];
    if (isFluidRaw != null) {
      isFluidVal = _parseInt(isFluidRaw) == 1;
    }

    final nutritionPer = (row['nutrition_data_prepared_per'] ??
            row['nutrition_data_per'] ??
            row['nutrition_baseline'] ??
            row['nutrition_baseline_key'])
        ?.toString()
        .toLowerCase()
        .trim();
    if (nutritionPer != null) {
      if (nutritionPer.contains('100g')) {
        isFluidVal = false;
      } else if (nutritionPer.contains('100ml')) {
        isFluidVal = true;
      }
    }

    final rawCategory =
        row['category'] ?? row['categories'] ?? row['categories_tags'];
    if (rawCategory != null) {
      final categoryStr = rawCategory.toString().toLowerCase();
      if (categoryStr.contains('en:beverages') ||
          categoryStr.contains('en:drinks') ||
          categoryStr.contains('en:waters')) {
        isFluidVal = true;
      }
    }

    return ProductsCompanion(
      id: drift.Value(id),
      barcode: drift.Value(barcode),
      name: drift.Value(displayName),
      nameDe: drift.Value(rawNameDe),
      nameEn: drift.Value(rawNameEn),
      nameFr: drift.Value(rawNameFr),
      nameIt: drift.Value(rawNameIt),
      nameJa: drift.Value(rawNameJa),
      brand: drift.Value(_parseString(row['brand'])),
      calories: drift.Value(_parseInt(row['calories'])),
      protein: drift.Value(_parseDouble(row['protein'])),
      carbs: drift.Value(_parseDouble(row['carbs'])),
      fat: drift.Value(_parseDouble(row['fat'])),
      sugar: drift.Value(_parseDouble(row['sugar'])),
      fiber: drift.Value(_parseDouble(row['fiber'])),
      salt: drift.Value(_parseDouble(row['salt'])),
      caffeine: drift.Value(
          _parseDouble(row['caffeine_mg_per_100ml'] ?? row['caffeine'])),
      caffeineMgPer100g: drift.Value(_parseDouble(row['caffeine_mg_per_100g'])),
      ingredientsText: drift.Value(
          sourceLabel == 'base' ? null : row['ingredients_text']?.toString()),
      ingredientsAnalysisTags:
          drift.Value(row['ingredients_analysis_tags']?.toString()),
      additivesTags: drift.Value(row['additives_tags']?.toString()),
      productQuantity: drift.Value(_parseDouble(row['product_quantity'])),
      productQuantityUnit:
          drift.Value(row['product_quantity_unit']?.toString()),
      isFluid: drift.Value(isFluidVal),
      source: drift.Value(sourceLabel),
      isLiquid: drift.Value(_parseInt(row['is_liquid']) == 1),
      category: drift.Value(row['category']?.toString()),
    );
  }

  /// Resolve the language code for base food import without a BuildContext.
  static String _resolveBaseFoodLangCode({
    required BaseFoodLanguage choice,
    required OffCatalogCountry offCountry,
  }) {
    if (choice == BaseFoodLanguage.en) return 'en';
    if (choice == BaseFoodLanguage.de) return 'de';
    if (choice == BaseFoodLanguage.fr) return 'fr';
    if (choice == BaseFoodLanguage.it) return 'it';
    if (choice == BaseFoodLanguage.ja) return 'ja';
    // Auto: derive from the food DB region.
    return switch (offCountry) {
      OffCatalogCountry.us || OffCatalogCountry.uk => 'en',
      OffCatalogCountry.de || OffCatalogCountry.ch || OffCatalogCountry.at => 'de',
      OffCatalogCountry.fr => 'fr',
      OffCatalogCountry.it => 'it',
      OffCatalogCountry.jp => 'ja',
    };
  }

  static dynamic _mapCategoryRow(Map<String, dynamic> row) {
    return FoodCategoriesCompanion(
      key: drift.Value(_parseString(row['key'])),
      nameDe: drift.Value(row['name_de'] as String?),
      nameEn: drift.Value(row['name_en'] as String?),
      nameFr: drift.Value(row['name_fr'] as String?),
      nameIt: drift.Value(row['name_it'] as String?),
      nameJa: drift.Value(row['name_ja'] as String?),
      emoji: drift.Value(row['emoji'] as String?),
    );
  }

  /// Maps a flat exercise asset row to an [_ExerciseBundle] containing
  /// the structural exercise fields and derived translation rows.
  ///
  /// Handles both legacy flat format (name_de, name_en columns) and
  /// future relational format (exercise_translations sub-rows).
  static _ExerciseBundle _mapExerciseBundle(Map<String, dynamic> row) {
    final id = _parseString(row['id']);

    final exerciseFields = <String, dynamic>{
      'id': id,
      'category_name': _parseString(row['category_name']),
      'muscles_primary': _parseString(row['muscles_primary']),
      'muscles_secondary': _parseString(row['muscles_secondary']),
    };

    // Build translation rows. Support both flat (legacy) and
    // future relational format from the updated Python pipeline.
    final translations = <Map<String, dynamic>>[];

    void addTranslation(String langCode, dynamic name, dynamic description) {
      final n = _parseString(name);
      if (n.isEmpty) return;
      translations.add({
        'exercise_id': id,
        'language_code': langCode,
        'name': n,
        'description': description?.toString(),
      });
    }

    // Flat-column format (current wger asset DB).
    // FIX: The fallback order for 'de' is intentionally de→en so that
    // exercises with only an English name still get a valid DE translation row
    // (the searchExercises COALESCE prefers t_de). Equally, 'en' falls back
    // to 'de' so that exercises with only a German name remain searchable in
    // English-locale environments.
    if (row.containsKey('name_de') || row.containsKey('name_en')) {
      addTranslation(
          'de', row['name_de'] ?? row['name_en'], row['description_de']);
      addTranslation(
          'en', row['name_en'] ?? row['name_de'], row['description_en'] ?? row['description_de']);
      addTranslation('fr', row['name_fr'] ?? row['name_en'] ?? row['name_de'], row['description_fr']);
      addTranslation('it', row['name_it'] ?? row['name_en'] ?? row['name_de'], row['description_it']);
      addTranslation('ja', row['name_ja'] ?? row['name_en'] ?? row['name_de'], row['description_ja']);
    }

    return _ExerciseBundle(
      exerciseFields: exerciseFields,
      translationFields: translations,
    );
  }
}
