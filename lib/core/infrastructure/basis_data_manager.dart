// lib/data/basis_data_manager.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import '../../data/database_helper.dart';
import '../../data/drift_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:drift/drift.dart' as drift;
import 'package:http/http.dart' as http; // Added

import '../../config/app_data_sources.dart';
import '../../services/base_food_language_service.dart';
import '../../services/exercise_catalog_refresh_service.dart';
import '../../services/off_catalog_country_service.dart';
import '../../services/off_catalog_refresh_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../generated/app_localizations.dart';
import '../../features/diary/domain/use_cases/retain_historical_off_products_use_case.dart';
import '../../features/app/presentation/widgets/glass_bottom_menu.dart'; // Added
import '../../features/app/presentation/app_initializer_screen.dart'; // Added
import '../../util/design_constants.dart'; // Added
import 'package:flutter_lucide/flutter_lucide.dart'; // Added

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

class CatalogSizes {
  final double? offSizeMb;
  final double? wgerSizeMb;

  const CatalogSizes({this.offSizeMb, this.wgerSizeMb});
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

  Future<bool> isExerciseCatalogInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_exercise_catalog_initialized') ?? false;
  }

  Future<bool> isOffDatabaseInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    final activeOffSource =
        OffCatalogCountryService.activeSourceFromPrefs(prefs);
    final activeOffCountry =
        OffCatalogCountryCodec.parseOrDefault(activeOffSource.countryCode);
    final activeOffVersionKey =
        OffCatalogCountryService.installedVersionKeyForCountry(
            activeOffCountry);
    final version = prefs.getString(activeOffVersionKey);
    return version != null && version != '0' && version != '';
  }

  Future<int?> getRemoteFileSize(Uri uri) async {
    try {
      final client = http.Client();
      final response =
          await client.head(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final contentLength = response.headers['content-length'];
        if (contentLength != null) {
          return int.tryParse(contentLength);
        }
      }
      final response2 = await client.get(uri,
          headers: {'Range': 'bytes=0-0'}).timeout(const Duration(seconds: 4));
      if (response2.statusCode == 206) {
        final contentRange = response2.headers['content-range'];
        if (contentRange != null) {
          final parts = contentRange.split('/');
          if (parts.length == 2) {
            return int.tryParse(parts[1].trim());
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to get remote file size: $e');
    }
    return null;
  }

  Future<void> promptOffDatabaseDownloadIfFirstTime(
      BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final wgerInitialized = await isExerciseCatalogInitialized();
    final offInitialized = await isOffDatabaseInitialized();

    bool wgerUpdateAvailable = false;
    bool offUpdateAvailable = false;
    double? wgerSize;
    double? offSize;

    try {
      final wgerManifest =
          await ExerciseCatalogRefreshService.instance.fetchManifestDirect();
      if (wgerManifest != null) {
        final wgerInstalled = prefs.getString(_keyVersionTraining) ?? '0';
        wgerUpdateAvailable =
            ExerciseCatalogRefreshService.isRemoteVersionNewer(
          remoteVersion: wgerManifest.version,
          installedVersion: wgerInstalled,
        );
        await prefs.setString(
            'exercise_catalog_last_remote_version', wgerManifest.version);
        final wgerBytes = await getRemoteFileSize(wgerManifest.dbUri);
        if (wgerBytes != null) {
          wgerSize = wgerBytes / (1024 * 1024);
        }
      }
    } catch (e) {
      debugPrint('Error getting wger manifest: $e');
    }

    try {
      final offManifest =
          await OffCatalogRefreshService.instance.fetchManifestDirect();
      if (offManifest != null) {
        final activeOffSource =
            OffCatalogCountryService.activeSourceFromPrefs(prefs);
        final activeOffCountry =
            OffCatalogCountryCodec.parseOrDefault(activeOffSource.countryCode);
        final activeOffVersionKey =
            OffCatalogCountryService.installedVersionKeyForCountry(
                activeOffCountry);
        final offInstalled = prefs.getString(activeOffVersionKey) ?? '0';
        offUpdateAvailable = OffCatalogRefreshService.isRemoteVersionNewer(
          remoteVersion: offManifest.version,
          installedVersion: offInstalled,
        );
        await prefs.setString(
            'off_catalog_last_remote_version_${activeOffCountry.code}',
            offManifest.version);
        final offBytes = await getRemoteFileSize(offManifest.dbUri);
        if (offBytes != null) {
          offSize = offBytes / (1024 * 1024);
        }
      }
    } catch (e) {
      debugPrint('Error getting OFF manifest: $e');
    }

    final isMissingEither = !wgerInitialized || !offInitialized;
    final isUpdateAvailable = wgerUpdateAvailable || offUpdateAvailable;

    if (!isMissingEither && !isUpdateAvailable) {
      return;
    }

    if (!isMissingEither) {
      final lastPromptedWger =
          prefs.getString('last_prompted_wger_version') ?? '';
      final lastPromptedOff =
          prefs.getString('last_prompted_off_version') ?? '';
      final currentWgerRemote =
          prefs.getString('exercise_catalog_last_remote_version') ?? '';
      final currentOffRemote = prefs.getString(
              'off_catalog_last_remote_version_${OffCatalogCountryService.readActiveCountryFromPrefs(prefs).code}') ??
          '';

      bool wgerMatch = !wgerUpdateAvailable ||
          (lastPromptedWger == currentWgerRemote &&
              currentWgerRemote.isNotEmpty);
      bool offMatch = !offUpdateAvailable ||
          (lastPromptedOff == currentOffRemote && currentOffRemote.isNotEmpty);
      if (wgerMatch && offMatch) {
        return;
      }
    }

    if (wgerUpdateAvailable) {
      await prefs.setString('last_prompted_wger_version',
          prefs.getString('exercise_catalog_last_remote_version') ?? '');
    }
    if (offUpdateAvailable) {
      await prefs.setString(
          'last_prompted_off_version',
          prefs.getString(
                  'off_catalog_last_remote_version_${OffCatalogCountryService.readActiveCountryFromPrefs(prefs).code}') ??
              '');
    }

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final shouldDownload = await showGlassBottomMenu<bool>(
      context: context,
      title: isMissingEither ? l10n.offDownloadTitle : "Update Available",
      isDismissible: true,
      enableDrag: true,
      contentBuilder: (ctx, close) {
        final wgerStatus = wgerInitialized
            ? (wgerUpdateAvailable ? "Update Available" : "Ready")
            : "Required";
        final offStatus = offInitialized
            ? (offUpdateAvailable ? "Update Available" : "Ready")
            : "Required";

        final wgerSizeText =
            wgerSize != null ? '${wgerSize.toStringAsFixed(1)} MB' : '1.4 MB';
        final offSizeText =
            offSize != null ? '${offSize.toStringAsFixed(1)} MB' : '41.2 MB';

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isMissingEither
                  ? l10n.offDownloadBody
                  : "New updates are available for your local catalogs. Would you like to update now?",
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Row(
              children: [
                const Icon(LucideIcons.dumbbell, size: 24),
                const SizedBox(width: DesignConstants.spacingM),
                const Expanded(
                  child: Text("Exercise Catalog (wger)",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  "$wgerStatus ($wgerSizeText)",
                  style: TextStyle(
                    color: wgerStatus == "Ready" ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Row(
              children: [
                const Icon(LucideIcons.database, size: 24),
                const SizedBox(width: DesignConstants.spacingM),
                const Expanded(
                  child: Text("Nutrition Catalog (OFF)",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  "$offStatus ($offSizeText)",
                  style: TextStyle(
                    color: offStatus == "Ready" ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(false);
                    },
                    child: Text(l10n.offDownloadCancel),
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      // Return true to signal the caller to launch the download
                      // screen. Do NOT push here — the sheet must fully close
                      // before the next route is pushed, otherwise the outer
                      // await showGlassBottomMenu resolves before the push,
                      // causing a navigation race condition.
                      Navigator.of(ctx).pop(true);
                    },
                    child: Text(isMissingEither
                        ? l10n.offDownloadConfirm
                        : "Update Now"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    // The sheet is now fully closed. Only push the download screen if the
    // user confirmed — this must happen after the sheet resolves so we don't
    // race with any outer await on this method.
    if (shouldDownload == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AppInitializerScreen(
            forceUpdate: true,
            isModal: true,
          ),
        ),
      );
    }
  }

  /// Public method to trigger the exercise catalog check and update process.
  Future<void> importExerciseCatalog({
    bool force = false,
    bool checkRemote = false,
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
    if (force || checkRemote) {
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
          debugPrint(
              '[ExerciseCatalog] Remote update available: v${remoteCandidate.version}');
          onProgress?.call(
            "Update Übungen",
            "Remote-Katalog ${remoteCandidate.version} gefunden.",
            0.02,
          );
        }
      } catch (e) {
        debugPrint('[ExerciseCatalog] Remote check failed (non-fatal): $e');
      }
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
    bool skipOffDatabase = false,
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

    final isExerciseInitialized =
        prefs.getBool('is_exercise_catalog_initialized') ?? false;
    final mainDb = await DatabaseHelper.instance.database;

    if (!isExerciseInitialized || force) {
      final exerciseCountRow = await mainDb
          .customSelect('SELECT COUNT(*) AS c FROM exercises')
          .getSingleOrNull();
      final exerciseCountDb = exerciseCountRow?.read<int>('c') ?? 0;
      final translationCountRow = await mainDb
          .customSelect('SELECT COUNT(*) AS c FROM exercise_translations')
          .getSingleOrNull();
      final translationCountDb = translationCountRow?.read<int>('c') ?? 0;

      final exercisesEmpty = exerciseCountDb == 0;
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
        checkRemote: force,
        onProgress: force ? onProgress : null,
        onRemoteProgress: force ? onRemoteProgress : null,
        isRemoteSkipRequested: force ? isRemoteSkipRequested : null,
      );
      await prefs.setBool('is_exercise_catalog_initialized', true);
    }

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
      debugPrint(
          '[ExerciseCatalog] ❌ translations ($postTrCount) still below exercises ($postExCount) after import!');
    } else {
      debugPrint(
          '[ExerciseCatalog] ✅ $postExCount exercises / $postTrCount translations ready.');
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

    if (skipOffDatabase) {
      await prefs.setString('last_db_sync_app_version', currentAppBuild);
      onProgress?.call(
        'Produktdatenbank (${activeOffCountry.upperCode})',
        'OFF-Katalog übersprungen.',
        1.0,
      );
      return;
    }

    String? remoteOffDbPath;
    final installedOffVersion = prefs.getString(activeOffVersionKey) ?? '0';
    if (force) {
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
        debugPrint(
            '[ExerciseCatalog]   [$taskLabel] Opening REMOTE source: $sourceFilePath');
        try {
          assetDb = await sqflite.openDatabase(sourceFilePath, readOnly: true);
        } catch (e) {
          debugPrint(
            '[ExerciseCatalog]   [$taskLabel] Remote source open FAILED – falling back to bundled asset: $e',
          );
        }
      } else {
        debugPrint(
            '[ExerciseCatalog]   [$taskLabel] No remote source → will use bundled asset: $assetPath');
      }

      if (assetDb == null) {
        final tempDir = await getTemporaryDirectory();
        final tempPath = p.join(tempDir.path, p.basename(assetPath));

        try {
          ByteData byteData;
          try {
            byteData = await rootBundle.load(assetPath);
            debugPrint(
                '[ExerciseCatalog]   [$taskLabel] Bundled asset loaded: $assetPath (${byteData.lengthInBytes} bytes)');
            // Guard: a 0-byte asset is an empty placeholder — opening it as a
            // SQLite DB produces a valid empty database with no tables, which
            // causes the importer to silently skip without importing anything.
            if (byteData.lengthInBytes == 0) {
              debugPrint(
                  '[ExerciseCatalog] ❌ [$taskLabel] Bundled asset is 0 bytes – import aborted. '
                  'Drop a real SQLite file at $assetPath.');
              return;
            }
          } catch (_) {
            if (legacyAssetPath == null) rethrow;
            debugPrint(
                '[ExerciseCatalog]   [$taskLabel] Primary asset missing → trying legacy: $legacyAssetPath');
            byteData = await rootBundle.load(legacyAssetPath);
            debugPrint(
                '[ExerciseCatalog]   [$taskLabel] Legacy asset loaded: $legacyAssetPath (${byteData.lengthInBytes} bytes)');
            if (byteData.lengthInBytes == 0) {
              debugPrint(
                  '[ExerciseCatalog] ❌ [$taskLabel] Legacy asset is also 0 bytes – import aborted.');
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
          debugPrint(
              '[ExerciseCatalog] [$taskLabel] Using fallback table name "exercise"');
        }
      } else {
        final tables = await assetDb.query(
          'sqlite_master',
          columns: ['name'],
          where: "type = ? AND name = ?",
          whereArgs: ['table', tableName],
        );
        if (tables.isEmpty) {
          debugPrint(
              '[ExerciseCatalog] ❌ [$taskLabel] Source table "$tableName" not found in asset DB – aborting.');
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
        debugPrint(
            '[ExerciseCatalog]   [$taskLabel] No metadata table in asset DB – assetVersion = "0"');
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

        final storedVersion =
            storedVersionAfterImport(assetVersion: assetVersion);
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
    const int batchSize = 5000;
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
      debugPrint(
          '[ExerciseCatalog] ❌ [$taskLabel] Source table has 0 rows – import skipped entirely!');
      return importedProductBarcodes;
    }

    // Query original PRAGMAs
    String originalJournalMode = 'WAL';
    int originalSynchronous = 1; // NORMAL
    int originalForeignKeys = 1; // ON
    try {
      final journalModeRow =
          await mainDb.customSelect('PRAGMA journal_mode;').getSingle();
      originalJournalMode = journalModeRow.read<String>('journal_mode');
      final syncRow =
          await mainDb.customSelect('PRAGMA synchronous;').getSingle();
      originalSynchronous = syncRow.read<int>('synchronous');
      final fkRow =
          await mainDb.customSelect('PRAGMA foreign_keys;').getSingle();
      originalForeignKeys = fkRow.read<int>('foreign_keys');
    } catch (e) {
      debugPrint(
          '[ExerciseCatalog] Warning: could not query original PRAGMAs: $e');
    }

    // Configure performance PRAGMAs before transaction
    try {
      await mainDb.customStatement('PRAGMA synchronous = OFF;');
      await mainDb.customStatement('PRAGMA journal_mode = MEMORY;');
      await mainDb.customStatement('PRAGMA foreign_keys = OFF;');
    } catch (e) {
      debugPrint(
          '[ExerciseCatalog] Warning: could not set performance PRAGMAs: $e');
    }

    int processed = 0;
    int totalExercisesInserted = 0;
    int totalTranslationsInserted = 0;
    int batchNumber = 0;

    try {
      await mainDb.transaction(() async {
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
                debugPrint(
                    '[ExerciseCatalog]   [$taskLabel] Skipping malformed non-exercise row: $e');
              }
            }
          });

          if (exerciseBundles.isNotEmpty) {
            int batchExCount = 0;
            int batchTrCount = 0;

            // Phase 1: Upsert base exercise rows.
            await mainDb.batch((batch) {
              for (final bundle in exerciseBundles) {
                try {
                  final fields = bundle.exerciseFields;
                  final exerciseId = _parseString(fields['id']);
                  if (exerciseId.isEmpty) {
                    debugPrint(
                        '[ExerciseCatalog]   [$taskLabel] ⚠️  Skipping exercise with empty id');
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
                  debugPrint(
                      '[ExerciseCatalog]   [$taskLabel] ⚠️  Skipping malformed exercise: $e');
                }
              }
            });

            // Phase 2: Upsert translations.
            await mainDb.batch((batch) {
              for (final bundle in exerciseBundles) {
                for (final t in bundle.translationFields) {
                  try {
                    final companion = ExerciseTranslationsCompanion(
                      exerciseId: drift.Value(_parseString(t['exercise_id'])),
                      languageCode:
                          drift.Value(_parseString(t['language_code'])),
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

            totalExercisesInserted += batchExCount;
            totalTranslationsInserted += batchTrCount;
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
            // ignore: unused_local_variable
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

              await mainDb.batch((batch) {
                for (final t in trRows) {
                  try {
                    final exerciseId = _parseString(t['exercise_id']);
                    final langCode = _parseString(t['language_code']);
                    final name = _parseString(t['name']);
                    if (exerciseId.isEmpty ||
                        langCode.isEmpty ||
                        name.isEmpty) {
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

              trOffset += batchSize;
              await Future.delayed(const Duration(milliseconds: 1));
            }

            totalTranslationsInserted += relationalTrInserted;
            debugPrint(
              '[ExerciseCatalog]   [$taskLabel] Relational translation pass complete: '
              '$relationalTrInserted / $trTotal rows written',
            );
          }
        }
      });

      if (importType == BatchImportType.exercises) {
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
          debugPrint(
              '[ExerciseCatalog] ❌ [$taskLabel] ZERO exercises written – check source DB and mapping!');
        } else if (totalTranslationsInserted == 0) {
          debugPrint(
              '[ExerciseCatalog] ❌ [$taskLabel] ZERO translations written – exercises will be invisible!');
        }
      }
    } finally {
      // Restore original PRAGMAs
      debugPrint(
          '[ExerciseCatalog] [$taskLabel] Restoring original SQLite PRAGMAs: journal_mode=$originalJournalMode, synchronous=$originalSynchronous, foreign_keys=$originalForeignKeys');
      try {
        await mainDb
            .customStatement('PRAGMA synchronous = $originalSynchronous;');
        await mainDb
            .customStatement('PRAGMA journal_mode = $originalJournalMode;');
        await mainDb
            .customStatement('PRAGMA foreign_keys = $originalForeignKeys;');
      } catch (e) {
        debugPrint('[ExerciseCatalog] Error restoring PRAGMAs: $e');
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

    // ── is_fluid three-tier heuristic ────────────────────────────────────────
    //
    // Tier 1 – Allowlist: category tag contains a known beverage substring
    //          → candidate is_fluid = true.
    // Tier 2 – Blocklist: category tag exactly matches a non-beverage tag
    //          → veto is_fluid = false (overrides Tier 1).
    // Tier 3 – Volume-unit fallback: only when NO category data is available;
    //          product_quantity_unit in {ml, l, cl} → is_fluid = true.
    //
    // This mirrors the resolve_is_fluid() function in create_off_food_db.py.
    // Keep both in sync when adding new tags.
    // ─────────────────────────────────────────────────────────────────────────

    bool isFluidVal = false;

    // Read category tag blob — may come from the OFF API as a tag list string.
    final rawCategory =
        row['category'] ?? row['categories'] ?? row['categories_tags'];
    final categoryStr =
        rawCategory != null ? rawCategory.toString().toLowerCase() : '';

    // Split the flat string into individual tags, stripping blanks.
    final cats = categoryStr
        .split(RegExp(r'[,\s]+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (cats.isNotEmpty) {
      // ── Tier 1: allowlist (substring match) ──────────────────────────────
      const beverageAllowlistSubstrings = [
        'en:beverages',
        'en:beverages-and-beverages-preparations',
        'en:non-alcoholic-beverages',
        'en:hot-beverages',
        'en:cold-beverages',
        'en:plant-based-beverages',
        'en:carbonated-beverages',
        'en:waters',
        'en:mineral-waters',
        'en:sparkling-waters',
        'en:still-waters',
        'en:spring-waters',
        'en:flavoured-waters',
        'en:vitamin-waters',
        'en:coconut-waters',
        'en:fruit-juices',
        'en:vegetable-juices',
        'en:juices',
        'en:soft-drinks',
        'en:sodas',
        'en:colas',
        'en:lemonades',
        'en:energy-drinks',
        'en:sports-drinks',
        'en:electrolyte-drinks',
        'en:isotonic-drinks',
        'en:teas',
        'en:herbal-teas',
        'en:iced-teas',
        'en:coffees',
        'en:instant-coffees',
        'en:coffee-beverages',
        'en:alcoholic-beverages',
        'en:beers',
        'en:wines',
        'en:spirits',
        'en:liqueurs',
        'en:ciders',
        'en:champagnes',
        'en:proseccos',
        'en:plant-based-milks',
        'en:oat-milks',
        'en:soy-milks',
        'en:rice-milks',
        'en:almond-milks',
        'en:coconut-milks',
        'en:drinkable-yogurts',
        'en:flavoured-milks',
        'en:milks',
        'en:smoothies',
        'en:fruit-smoothies',
        'en:vegetable-smoothies',
        'en:baby-drinks',
        'en:drinking-waters',
        'en:kombucha',
        'en:kefir-drinks',
        'en:drinks',
      ];

      // ── Tier 2: blocklist (exact tag match) ──────────────────────────────
      const nonBeverageBlocklistTags = {
        'en:condiments',
        'en:sauces',
        'en:hot-sauces',
        'en:soy-sauces',
        'en:tomato-sauces',
        'en:barbecue-sauces',
        'en:pasta-sauces',
        'en:curry-sauces',
        'en:vegan-sauces',
        'en:vegetarian-sauces',
        'en:dessert-sauces',
        'en:burger-sauces',
        'en:sweet-and-sour-sauces',
        'en:bechamel-sauces',
        'en:worcestershire-sauces',
        'en:teriyaki-sauces',
        'en:nuoc-mam-sauce',
        'en:fish-sauces',
        'en:chili-sauces',
        'en:pepper-sauces',
        'en:cooking-sauces',
        'en:salad-dressings',
        'en:vinaigrettes',
        'en:mayonnaises',
        'en:light-mayonnaises',
        'en:egg-free-mayonnaises',
        'en:aiolis',
        'en:dips',
        'en:ketchup',
        'en:tomato-ketchup',
        'en:mustards',
        'en:vinegars',
        'en:balsamic-vinegars',
        'en:cider-vinegars',
        'en:rice-vinegars',
        'en:wine-vinegars',
        'en:sherry-vinegars',
        'en:glazes-with-vinegar',
        'en:soups',
        'en:canned-soups',
        'en:reheatable-soups',
        'en:fish-soups',
        'en:broths',
        'en:liquid-broths',
        'en:cream-of-vegetable-soups',
        'en:desserts',
        'en:dairy-desserts',
        'en:frozen-desserts',
        'en:ice-creams-and-sorbets',
        'en:ice-creams',
        'en:ice-cream-tubs',
        'en:ice-cream-bars',
        'en:ice-cream-cones',
        'en:ice-cream-sandwiches',
        'en:ice-cream-in-a-box',
        'en:sorbets',
        'en:ice-pops',
        'en:frozen-yogurts',
        'en:creams',
        'en:uht-creams',
        'en:whipped-creams',
        'en:unfermented-creams',
        'en:compound-dairy-creams',
        'en:cooking-creams',
        'en:spreads',
        'en:sweet-spreads',
        'en:plant-based-spreads',
        'en:nut-butters',
        'en:peanut-butters',
        'en:fats',
        'en:cooking-fats',
        'en:oils',
        'en:olive-oils',
        'en:simple-syrups',
        'en:maple-syrups',
        'en:agave-syrups',
        'en:toppings-ingredients',
        'en:snacks',
        'en:salty-snacks',
        'en:sweet-snacks',
        'en:frozen-foods',
        'en:groceries',
        'en:meals',
        'en:canned-meals',
        'en:canned-foods',
        'en:dried-meals',
        'en:dried-products',
        'en:dried-products-to-be-rehydrated',
        'en:dietary-supplements',
        'en:food-additives',
        'en:sweeteners',
        'en:sugar-substitutes',
        'en:tabletop-sweeteners',
        'en:artificial-sugar-substitutes',
        'en:flavors',
        'en:cooking-helpers',
        'en:non-food-products',
        'en:perfumes',
        'en:oil-perfumes',
        'en:bodybuilding-supplements',
      };

      final isCandidate = cats.any(
        (cat) => beverageAllowlistSubstrings.any((sub) => cat.contains(sub)),
      );
      final isBlocked =
          cats.any((cat) => nonBeverageBlocklistTags.contains(cat));

      if (isBlocked) {
        isFluidVal = false;
      } else if (isCandidate) {
        isFluidVal = true;
      }
      // else: category data present but no signal → conservative false
    } else {
      // Tier 3: no category data — fall back to volume unit
      final nutritionPer = (row['nutrition_data_prepared_per'] ??
              row['nutrition_data_per'] ??
              row['nutrition_baseline'] ??
              row['nutrition_baseline_key'])
          ?.toString()
          .toLowerCase()
          .trim();
      final unit =
          row['product_quantity_unit']?.toString().toLowerCase().trim() ?? '';
      if (nutritionPer != null && nutritionPer.contains('100ml')) {
        isFluidVal = true;
      } else if (unit == 'ml' || unit == 'l' || unit == 'cl') {
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
      OffCatalogCountry.de ||
      OffCatalogCountry.ch ||
      OffCatalogCountry.at =>
        'de',
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
      addTranslation('en', row['name_en'] ?? row['name_de'],
          row['description_en'] ?? row['description_de']);
      addTranslation('fr', row['name_fr'] ?? row['name_en'] ?? row['name_de'],
          row['description_fr']);
      addTranslation('it', row['name_it'] ?? row['name_en'] ?? row['name_de'],
          row['description_it']);
      addTranslation('ja', row['name_ja'] ?? row['name_en'] ?? row['name_de'],
          row['description_ja']);
    }

    return _ExerciseBundle(
      exerciseFields: exerciseFields,
      translationFields: translations,
    );
  }
}
