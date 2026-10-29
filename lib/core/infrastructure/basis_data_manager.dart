import 'dart:async';
import 'dart:convert';
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
import '../../services/bls_food_catalog_refresh_service.dart';
import '../../services/telemetry/telemetry_service.dart';
import 'caffeine_catalog_resolver.dart';
import 'basis_data_row_mappers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../generated/app_localizations.dart';
import '../../features/diary/domain/use_cases/retain_historical_off_products_use_case.dart';
import '../../features/exercise_catalog/domain/exercise_alias_migration.dart';
import '../../features/app/presentation/widgets/glass_bottom_menu.dart'; // Added
import '../../features/app/presentation/app_initializer_screen.dart'; // Added
import '../../util/design_constants.dart'; // Added
import 'package:flutter_lucide/flutter_lucide.dart'; // Added
import '../../widgets/common/app_button.dart';

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

List<dynamic> _parseBatchInIsolate(_BatchImportPayload payload) {
  switch (payload.type) {
    case BatchImportType.exercises:
      return payload.rows.map(BasisDataRowMappers.mapExerciseBundle).toList();
    case BatchImportType.categories:
      return payload.rows.map(BasisDataRowMappers.mapCategoryRow).toList();
    case BatchImportType.productsBase:
      return payload.rows
          .map((r) => BasisDataRowMappers.mapProductRow(r,
              sourceLabel: 'base',
              preferredLanguage: payload.preferredLanguage))
          .toList();
    case BatchImportType.productsOff:
      return payload.rows
          .map((r) => BasisDataRowMappers.mapProductRow(r, sourceLabel: 'off'))
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

  // Memoized "the rows are really there" results. Only a positive result is
  // cached: once a catalog is confirmed present it cannot disappear without a
  // restore or a wipe, both of which restart the app or call
  // [invalidateCatalogPresenceCache].
  bool _exerciseRowsVerified = false;
  bool _offRowsVerified = false;
  bool _blsRowsVerified = false;

  /// Drops the memoized presence results, e.g. after a restore replaced the
  /// database underneath us.
  void invalidateCatalogPresenceCache() {
    _exerciseRowsVerified = false;
    _offRowsVerified = false;
    _blsRowsVerified = false;
  }

  Future<bool> isExerciseCatalogInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('is_exercise_catalog_initialized') ?? false)) {
      return false;
    }
    // The preference alone is not proof: a restored backup carries the flag
    // from the source device, where the catalog *was* installed. Confirm the
    // rows exist here before claiming the catalog is ready.
    if (_exerciseRowsVerified) return true;
    try {
      final mainDb = await DatabaseHelper.instance.database;
      final row = await mainDb
          .customSelect('SELECT 1 FROM exercises LIMIT 1')
          .getSingleOrNull();
      _exerciseRowsVerified = row != null;
      return _exerciseRowsVerified;
    } catch (e) {
      debugPrint('[ExerciseCatalog] Presence check failed: $e');
      return false;
    }
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
    if (version == null || version == '0' || version == '') return false;
    // Same reasoning as above — verify the OFF rows actually landed on this
    // device instead of trusting a version string that may have been restored.
    if (_offRowsVerified) return true;
    try {
      final mainDb = await DatabaseHelper.instance.database;
      final row = await mainDb.customSelect(
        'SELECT 1 FROM products WHERE source = ? LIMIT 1',
        variables: [drift.Variable.withString('off')],
      ).getSingleOrNull();
      _offRowsVerified = row != null;
      return _offRowsVerified;
    } catch (e) {
      debugPrint('[OffCatalog] Presence check failed: $e');
      return false;
    }
  }

  Future<bool> isBlsFoodCatalogInitialized() async {
    final service = BlsFoodCatalogRefreshService.instance;
    if (_blsRowsVerified) {
      final path = await service.installedDatabasePath();
      if (File(path).existsSync()) return true;
      _blsRowsVerified = false;
    }
    final installed = await service.isInstalled();
    if (!installed) return false;
    try {
      final mainDb = await DatabaseHelper.instance.database;
      final row = await mainDb.customSelect('''
        SELECT 1
        FROM products p
        INNER JOIN food_categories c ON c.key = p.category
        WHERE p.source = 'base' AND p.barcode LIKE 'bls:%'
        LIMIT 1
      ''').getSingleOrNull();
      _blsRowsVerified = row != null;
      return _blsRowsVerified;
    } catch (error) {
      debugPrint('[BLS catalog] App database check failed: $error');
      return false;
    }
  }

  /// The search index can be rebuilt from the installed sidecar. A stale index
  /// must not make the food catalog appear missing or trigger another download.
  Future<bool> _isBlsAliasIndexCurrent() async {
    final path =
        await BlsFoodCatalogRefreshService.instance.installedDatabasePath();
    if (!await File(path).exists()) return false;
    try {
      final catalogDb = await sqflite.openDatabase(path, readOnly: true);
      try {
        final aliasTable = await catalogDb.rawQuery(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'food_aliases'",
        );
        // The app-side index has a composite primary key and can collapse
        // duplicate source rows. Compare against the same distinct key count,
        // otherwise a catalog containing duplicates is rebuilt every launch.
        final catalogCount = aliasTable.isEmpty
            ? 0
            : sqflite.Sqflite.firstIntValue(await catalogDb.rawQuery('''
                SELECT COUNT(*) FROM (
                  SELECT barcode, language_code, alias
                  FROM food_aliases
                  GROUP BY barcode, language_code, alias
                )
              ''')) ?? 0;
        final versionRows = await catalogDb.query('metadata',
            columns: ['value'], where: 'key = ?', whereArgs: ['version']);
        final catalogVersion =
            versionRows.isEmpty ? null : versionRows.first['value']?.toString();
        final mainDb = await DatabaseHelper.instance.database;
        final localCount = (await mainDb
                .customSelect(
                  'SELECT COUNT(*) AS count FROM bls_food_alias_index',
                )
                .getSingle())
            .read<int>('count');
        final state = await mainDb
            .customSelect(
              'SELECT catalog_version, alias_count '
              'FROM bls_food_alias_index_state WHERE id = 1',
            )
            .getSingleOrNull();
        return catalogVersion != null &&
            state != null &&
            localCount == catalogCount &&
            state.read<String>('catalog_version') == catalogVersion &&
            state.read<int>('alias_count') == catalogCount;
      } finally {
        await catalogDb.close();
      }
    } catch (error) {
      debugPrint('[BLS catalog] Alias index check failed: $error');
      return false;
    }
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
    final blsInitialized = await isBlsFoodCatalogInitialized();

    bool wgerUpdateAvailable = false;
    bool offUpdateAvailable = false;
    double? wgerSize;
    double? offSize;
    bool blsUpdateAvailable = false;
    double? blsSize;

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

    try {
      final blsManifest =
          await BlsFoodCatalogRefreshService.instance.fetchManifestDirect();
      final blsInstalled =
          await BlsFoodCatalogRefreshService.instance.installedVersion() ?? '0';
      blsUpdateAvailable = !blsInitialized ||
          BlsFoodCatalogRefreshService.isRemoteVersionNewer(
            remoteVersion: blsManifest.version,
            installedVersion: blsInstalled,
          );
      await prefs.setString(
          'bls_food_catalog_last_remote_version', blsManifest.version);
      blsSize = blsManifest.downloadSizeBytes / (1024 * 1024);
    } catch (e) {
      debugPrint('Error getting BLS manifest: $e');
      blsUpdateAvailable = !blsInitialized;
    }

    final isMissingEither =
        !wgerInitialized || !offInitialized || !blsInitialized;
    final isUpdateAvailable =
        wgerUpdateAvailable || offUpdateAvailable || blsUpdateAvailable;

    if (!isMissingEither && !isUpdateAvailable) {
      return;
    }

    final snoozeUntilIso = prefs.getString('db_update_snoozed_until');
    if (snoozeUntilIso != null) {
      final snoozeUntil = DateTime.tryParse(snoozeUntilIso);
      if (snoozeUntil != null && DateTime.now().isBefore(snoozeUntil)) {
        return;
      }
      await prefs.remove('db_update_snoozed_until');
    }

    if (!isMissingEither) {
      final lastPromptedWger =
          prefs.getString('last_prompted_wger_version') ?? '';
      final lastPromptedOff =
          prefs.getString('last_prompted_off_version') ?? '';
      final lastPromptedBls =
          prefs.getString('last_prompted_bls_version') ?? '';
      final currentWgerRemote =
          prefs.getString('exercise_catalog_last_remote_version') ?? '';
      final currentOffRemote = prefs.getString(
              'off_catalog_last_remote_version_${OffCatalogCountryService.readActiveCountryFromPrefs(prefs).code}') ??
          '';
      final currentBlsRemote =
          prefs.getString('bls_food_catalog_last_remote_version') ?? '';

      bool wgerMatch = !wgerUpdateAvailable ||
          (lastPromptedWger == currentWgerRemote &&
              currentWgerRemote.isNotEmpty);
      bool offMatch = !offUpdateAvailable ||
          (lastPromptedOff == currentOffRemote && currentOffRemote.isNotEmpty);
      bool blsMatch = !blsUpdateAvailable ||
          (lastPromptedBls == currentBlsRemote && currentBlsRemote.isNotEmpty);
      if (wgerMatch && offMatch && blsMatch) {
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
    if (blsUpdateAvailable) {
      await prefs.setString(
        'last_prompted_bls_version',
        prefs.getString('bls_food_catalog_last_remote_version') ?? '',
      );
    }

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final shouldDownload = await showGlassBottomMenu<bool>(
      context: context,
      title:
          isMissingEither ? l10n.offDownloadTitle : l10n.updateAvailableTitle,
      isDismissible: true,
      enableDrag: true,
      contentBuilder: (ctx, close) {
        final wgerStatus = wgerInitialized
            ? (wgerUpdateAvailable
                ? l10n.updateAvailableTitle
                : l10n.statusReady)
            : l10n.statusRequired;
        final offStatus = offInitialized
            ? (offUpdateAvailable
                ? l10n.updateAvailableTitle
                : l10n.statusReady)
            : l10n.statusRequired;
        final blsStatus = blsInitialized
            ? (blsUpdateAvailable
                ? l10n.updateAvailableTitle
                : l10n.statusReady)
            : l10n.statusRequired;

        final wgerSizeText =
            wgerSize != null ? '${wgerSize.toStringAsFixed(1)} MB' : '1.4 MB';
        final offSizeText =
            offSize != null ? '${offSize.toStringAsFixed(1)} MB' : '41.2 MB';
        final blsSizeText =
            blsSize != null ? '${blsSize.toStringAsFixed(1)} MB' : '25.6 MB';

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isMissingEither
                  ? l10n.offDownloadBody
                  : l10n.updatesAvailableBody,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Row(
              children: [
                const Icon(LucideIcons.dumbbell, size: 24),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: Text(l10n.exerciseCatalogWger,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  "$wgerStatus ($wgerSizeText)",
                  style: TextStyle(
                    color: wgerStatus == l10n.statusReady
                        ? Colors.green
                        : Colors.orange,
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
                Expanded(
                  child: Text(l10n.nutritionCatalogBls,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  '$blsStatus ($blsSizeText)',
                  style: TextStyle(
                    color: blsStatus == l10n.statusReady
                        ? Colors.green
                        : Colors.orange,
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
                Expanded(
                  child: Text(l10n.nutritionCatalogOff,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  "$offStatus ($offSizeText)",
                  style: TextStyle(
                    color: offStatus == l10n.statusReady
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    onPressed: () async {
                      await prefs.setString(
                        'db_update_snoozed_until',
                        DateTime.now()
                            .add(const Duration(days: 30))
                            .toIso8601String(),
                      );
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop(false);
                      }
                    },
                    label: l10n.offDownloadCancel,
                    tooltip: l10n.offDownloadCancel,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.primary(
                    onPressed: () async {
                      await prefs.remove('db_update_snoozed_until');
                      // Return true to signal the caller to launch the download
                      // screen. Do NOT push here — the sheet must fully close
                      // before the next route is pushed, otherwise the outer
                      // await showGlassBottomMenu resolves before the push,
                      // causing a navigation race condition.
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop(true);
                      }
                    },
                    label: isMissingEither
                        ? l10n.offDownloadConfirm
                        : "Update Now",
                    tooltip: isMissingEither
                        ? l10n.offDownloadConfirm
                        : "Update Now",
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

  /// Installs a newer bundled catalog offline, then optionally checks remote.
  /// [force] bypasses the remote check interval, never the downgrade guard.
  Future<void> importExerciseCatalog({
    bool force = false,
    bool checkRemote = false,
    ProgressCallback? onProgress,
    RemoteCatalogProgressCallback? onRemoteProgress,
    RemoteCatalogSkipRequested? isRemoteSkipRequested,
    ExerciseCatalogRefreshService? catalogRefreshService,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final mainDb = await DatabaseHelper.instance.database;
    Future<bool> hasCatalog() async {
      final exercises = await mainDb
          .customSelect('SELECT 1 FROM exercises LIMIT 1')
          .getSingleOrNull();
      final translations = await mainDb
          .customSelect('SELECT 1 FROM exercise_translations LIMIT 1')
          .getSingleOrNull();
      return exercises != null && translations != null;
    }

    final healthy = await hasCatalog();
    if (!healthy) {
      // A restore can carry a version preference without the actual rows.
      await prefs.remove(_keyVersionTraining);
      await prefs.setBool('is_exercise_catalog_initialized', false);
      _exerciseRowsVerified = false;
    }

    Future<void> importSource([String? path]) => _updateDatabaseFromSource(
          assetPath: AppDataSources.trainingAssetDbPath,
          sourceFilePath: path,
          prefKey: _keyVersionTraining,
          prefs: prefs,
          tableName: 'exercises',
          driftTableName: null,
          legacyAssetPath: AppDataSources.legacyTrainingAssetDbPath,
          importType: BatchImportType.exercises,
          preferredLanguage: null,
          taskLabel: 'Übungen',
          onProgress: onProgress,
          forceImport: false,
          enableOffReplacementRetention: false,
        );

    // The small manifest avoids copying/opening the bundled SQLite file on
    // every launch. The importer still checks the database's own version.
    var checkBundle = true;
    if (healthy) {
      try {
        final manifest = jsonDecode(await rootBundle.loadString(
          AppDataSources.trainingAssetManifestPath,
        )) as Map<String, dynamic>;
        final version = manifest['version']?.toString().trim() ?? '';
        if (version.isNotEmpty) {
          checkBundle = ExerciseCatalogRefreshService.isRemoteVersionNewer(
            remoteVersion: version,
            installedVersion: prefs.getString(_keyVersionTraining) ?? '0',
          );
        }
      } catch (e) {
        debugPrint('[ExerciseCatalog] Bundle manifest unavailable: $e');
      }
    }
    if (checkBundle) await importSource();

    if (force || checkRemote) {
      try {
        // Read AFTER the bundled import: remote and cached data must be newer
        // than both the previously installed catalog and the bundled one.
        final candidate = await (catalogRefreshService ??
                ExerciseCatalogRefreshService.instance)
            .prepareUpdateCandidate(
          installedVersion: prefs.getString(_keyVersionTraining) ?? '0',
          force: force,
          onProgress: onRemoteProgress,
          isSkipRequested: isRemoteSkipRequested,
        );
        if (candidate != null) await importSource(candidate.localDbPath);
      } catch (e) {
        debugPrint('[ExerciseCatalog] Remote update failed (non-fatal): $e');
      }
    }

    _exerciseRowsVerified = await hasCatalog();
    await prefs.setBool(
        'is_exercise_catalog_initialized', _exerciseRowsVerified);
  }

  /// Checks for updates to the basis data and performs an import if necessary.
  ///
  /// [force] checks remote catalogs immediately. It does not reimport an
  /// unchanged catalog; exercise catalogs never downgrade.
  /// The [onProgress] callback reports the ongoing task, details, and percentage.
  Future<void> checkForBasisDataUpdate({
    bool force = false,
    bool skipOffDatabase = false,
    ProgressCallback? onProgress, // New: callback
    RemoteCatalogProgressCallback? onRemoteProgress,
    RemoteCatalogSkipRequested? isRemoteSkipRequested,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final mainDb = await DatabaseHelper.instance.database;
    // Check remote catalogs on startup. Each refresh service applies its own
    // check interval, and imports only a newer catalog or repairs missing data.
    await importExerciseCatalog(
      force: force,
      checkRemote: true,
      onProgress: onProgress,
      onRemoteProgress: onRemoteProgress,
      isRemoteSkipRequested: isRemoteSkipRequested,
    );

    final blsWasInstalled = await isBlsFoodCatalogInitialized();
    // A missing catalog is not fetched in the background before the user has
    // accepted the first download prompt. Once installed, update checks run
    // automatically at the service's interval. `force` is used by onboarding
    // and the manual database refresh action after user intent.
    if (force || blsWasInstalled) {
      try {
        await refreshBlsFoodCatalog(
          forceCheck: force,
          onProgress: onProgress,
          onRemoteProgress: onRemoteProgress,
        );
      } catch (e) {
        debugPrint('[BLS catalog] Remote update failed safely: $e');
        // Keep a missing catalog marked as missing so the user is prompted
        // again on the next launch, even if preferences were restored.
      }
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

    // Drop an OFF version claim that no rows on this device back up, so the
    // "download required" prompt is offered instead of the app silently
    // reporting an up-to-date catalog it does not have.
    final storedOffVersion = prefs.getString(activeOffVersionKey);
    if (storedOffVersion != null &&
        storedOffVersion.isNotEmpty &&
        storedOffVersion != '0') {
      final hasOffData = await _hasInitializedData(
        mainDb: mainDb,
        prefKey: activeOffVersionKey,
      );
      if (!hasOffData) {
        debugPrint(
          '[OffCatalog] ⚠️  Installed version "$storedOffVersion" claimed for '
          '${activeOffCountry.upperCode} but no OFF products on this device → '
          'clearing the claim so a download can be offered.',
        );
        await prefs.remove(activeOffVersionKey);
        _offRowsVerified = false;
      }
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentAppVersion = packageInfo.version;
    final currentAppBuild = packageInfo.buildNumber;
    final lastDbSyncAppVersion = prefs.getString('last_db_sync_app_version');
    final bool isEnriched = prefs.getBool(_keyVersionFoodEnrichment) ?? false;
    final bool forceEnrichment = !isEnriched;

    // Same restore hazard as the exercise catalog: `last_db_sync_app_version`
    // may have been carried over from another device, which would make the
    // build-bound gate below skip the bundled imports even though nothing is
    // on disk here. Verify the rows before trusting the gate, and clear the
    // installed-version keys so the importer does not skip a second time.
    final bool hasBaseFoodData = await isBlsFoodCatalogInitialized();
    final bool hasCategoryData =
        await _hasInitializedData(mainDb: mainDb, prefKey: _keyVersionCats);
    final bool bundledDataMissing = !hasBaseFoodData || !hasCategoryData;

    String? remoteOffDbPath;
    if (!skipOffDatabase) {
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
    }

    if (bundledDataMissing && !force) {
      if (!hasBaseFoodData) {
        debugPrint(
          '[BasisData] ⚠️  Base products missing on this device → re-seeding.',
        );
        await prefs.remove(_keyVersionFood);
      }
      if (!hasCategoryData) {
        debugPrint(
          '[BasisData] ⚠️  Food categories missing on this device → re-seeding.',
        );
        await prefs.remove(_keyVersionCats);
      }
    }

    final bool shouldSync = force ||
        currentAppBuild != lastDbSyncAppVersion ||
        forceEnrichment ||
        bundledDataMissing ||
        remoteOffDbPath != null;

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

    // The old bundled base-food database is no longer the source of truth.
    // BLS products and categories are installed together from its verified
    // sidecar database; existing historical product rows stay addressable.
    if (hasBaseFoodData) {
      onProgress?.call('Basis-Produkte', 'BLS-Katalog ist aktuell.', 1.0);
      onProgress?.call('Kategorien', 'BLS-Kategorien sind aktuell.', 1.0);
    } else {
      onProgress?.call(
          'Basis-Produkte', 'BLS-Katalog wartet auf den Download.', 1.0);
      onProgress?.call(
          'Kategorien', 'BLS-Kategorien warten auf den Download.', 1.0);
    }

    if (skipOffDatabase) {
      await prefs.setString('last_db_sync_app_version', currentAppBuild);
      onProgress?.call(
        'Produktdatenbank (${activeOffCountry.upperCode})',
        'OFF-Katalog übersprungen.',
        1.0,
      );
      return;
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
      forceImportOverride: forceEnrichment,
    );

    await prefs.setString('last_db_sync_app_version', currentAppBuild);
  }

  /// Exposes a public method that bypasses remote check intervals for a manual
  /// refresh. Catalog contents are still imported only when newer or missing.
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

  /// Checks and installs only the BLS base-food catalog, leaving the OFF and
  /// exercise catalogs untouched. Used by the dedicated Data screen action.
  Future<bool> refreshBlsFoodCatalog({
    bool forceCheck = true,
    ProgressCallback? onProgress,
    RemoteCatalogProgressCallback? onRemoteProgress,
  }) async {
    final service = BlsFoodCatalogRefreshService.instance;
    var repairedLocal = false;
    final blsRowsPresent = await isBlsFoodCatalogInitialized();
    final aliasIndexCurrent = await _isBlsAliasIndexCurrent();
    if (!blsRowsPresent || !aliasIndexCurrent) {
      final localPath = await service.installedDatabasePath();
      if (File(localPath).existsSync()) {
        if (blsRowsPresent) {
          await _rebuildBlsAliasIndex(localPath);
          repairedLocal = true;
        } else {
          final localDb = await sqflite.openDatabase(localPath, readOnly: true);
          String? sourceVersion;
          try {
            final metadata = await localDb.query('metadata',
                columns: ['value'], where: 'key = ?', whereArgs: ['version']);
            sourceVersion =
                metadata.isEmpty ? null : metadata.first['value']?.toString();
          } finally {
            await localDb.close();
          }
          if (sourceVersion != null && sourceVersion.startsWith('bls-')) {
            await _importBlsFoodCatalog(
              localPath,
              await service.installedVersion() ??
                  sourceVersion.substring('bls-'.length),
              onProgress: onProgress,
            );
            repairedLocal = true;
          }
        }
      }
    }
    final BlsFoodCatalogUpdateCandidate? candidate;
    try {
      candidate = await service.prepareUpdateCandidate(
        installedVersion: await service.installedVersion() ?? '0',
        force: forceCheck,
        onProgress: (task, detail, progress) {
          onProgress?.call(task, detail, progress);
          onRemoteProgress?.call(task, detail, progress, canSkip: false);
        },
      );
    } catch (_) {
      if (repairedLocal) return true;
      rethrow;
    }
    if (candidate == null) {
      if (!await isBlsFoodCatalogInitialized() && await service.isInstalled()) {
        final path = await service.installedDatabasePath();
        final version = await service.installedVersion();
        if (version != null) {
          await _importBlsFoodCatalog(
            path,
            version,
            onProgress: onProgress,
          );
          return true;
        }
      }
      onProgress?.call(
        'BLS-Katalog aktuell',
        'Kein neuerer Lebensmittelkatalog verfügbar.',
        1.0,
      );
      return repairedLocal;
    }
    _blsRowsVerified = false;
    try {
      await _importBlsFoodCatalog(
        candidate.localDbPath,
        candidate.version,
        onProgress: onProgress,
      );
    } catch (_) {
      if (!_blsRowsVerified) await service.restorePreviousDatabase();
      rethrow;
    }
    return true;
  }

  Future<void> _importBlsFoodCatalog(
    String sourcePath,
    String catalogVersion, {
    ProgressCallback? onProgress,
  }) async {
    final sourceDb = await sqflite.openDatabase(sourcePath, readOnly: true);
    final mainDb = await DatabaseHelper.instance.database;
    final prefs = await SharedPreferences.getInstance();
    final languageChoice =
        await BaseFoodLanguageService.readChoice(prefs: prefs);
    final activeCountry =
        OffCatalogCountryService.readActiveCountryFromPrefs(prefs);
    final language = BasisDataRowMappers.resolveBaseFoodLangCode(
      choice: languageChoice,
      offCountry: activeCountry,
    );
    try {
      final count = sqflite.Sqflite.firstIntValue(
            await sourceDb.rawQuery('SELECT COUNT(*) FROM products'),
          ) ??
          0;
      final facts = sqflite.Sqflite.firstIntValue(
            await sourceDb.rawQuery('SELECT COUNT(*) FROM food_nutrients'),
          ) ??
          0;
      if (count <= 0 || facts <= 0) {
        throw StateError(
            'BLS catalog is incomplete ($count foods, $facts nutrient facts).');
      }

      onProgress?.call(
          'Basis-Produkte', 'Importiere BLS-Lebensmittel...', 0.03);
      // Keep historical product rows and their foreign-key references. They
      // remain available to old diary entries and saved meals, but disappear
      // from current catalog search once their replacements are installed.
      final aliasTable = await sourceDb.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'food_aliases'",
      );
      final aliases = aliasTable.isEmpty
          ? <Map<String, Object?>>[]
          : await sourceDb.query('food_aliases');
      final metadataRows = await sourceDb.query('metadata');
      final metadata = {
        for (final row in metadataRows)
          row['key']?.toString() ?? '': row['value']?.toString() ?? '',
      };
      final sourceVersion = metadata['version'];
      if (sourceVersion == null || !sourceVersion.startsWith('bls-')) {
        throw StateError('BLS catalog has invalid version metadata.');
      }
      final sourceSchema = int.tryParse(metadata['schema_version'] ?? '');
      if (sourceSchema == null ||
          sourceSchema > AppDataSources.supportedCatalogSchemaVersion ||
          (sourceSchema >= 2 &&
              (aliasTable.isEmpty ||
                  int.tryParse(metadata['curated_alias_count'] ?? '') !=
                      aliases.length))) {
        throw StateError('BLS alias data does not match catalog metadata.');
      }
      final productTranslationFields = <String, Map<String, String>>{};
      final categoryTranslationValues = <String, Map<String, Set<String>>>{};
      final translationTable = sourceSchema >= 3
          ? await sourceDb.rawQuery(
              "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'food_translations'",
            )
          : <Map<String, Object?>>[];
      if (sourceSchema >= 3) {
        if (translationTable.isEmpty) {
          throw StateError(
              'BLS schema 3 catalog has no food_translations table.');
        }
        final translations = await sourceDb.rawQuery('''
          SELECT t.barcode, t.language_code, t.name, t.category_name, p.category
          FROM food_translations t
          INNER JOIN products p ON p.barcode = t.barcode
          ORDER BY t.barcode, t.language_code
        ''');
        if (translations.length != count * 2) {
          throw StateError(
            'BLS schema 3 has ${translations.length} localized food rows; expected ${count * 2}.',
          );
        }
        for (final row in translations) {
          final barcode = row['barcode']?.toString() ?? '';
          final languageCode = row['language_code']?.toString() ?? '';
          final name = row['name']?.toString().trim() ?? '';
          final categoryKey = row['category']?.toString() ?? '';
          final categoryName = row['category_name']?.toString().trim() ?? '';
          if (barcode.isEmpty ||
              categoryKey.isEmpty ||
              name.isEmpty ||
              categoryName.isEmpty ||
              (languageCode != 'es' && languageCode != 'nl')) {
            throw StateError(
                'BLS schema 3 contains an invalid food translation.');
          }
          final nameField = 'name_$languageCode';
          final existingProductFields = productTranslationFields.putIfAbsent(
            barcode,
            () => <String, String>{},
          );
          if (existingProductFields.containsKey(nameField)) {
            throw StateError(
                'BLS schema 3 has duplicate translations for $barcode/$languageCode.');
          }
          existingProductFields[nameField] = name;
          categoryTranslationValues
              .putIfAbsent(categoryKey, () => <String, Set<String>>{})
              .putIfAbsent('name_$languageCode', () => <String>{})
              .add(categoryName);
        }
        if (productTranslationFields.length != count ||
            productTranslationFields.values.any(
              (fields) =>
                  !fields.containsKey('name_es') ||
                  !fields.containsKey('name_nl'),
            )) {
          throw StateError(
              'BLS schema 3 does not translate every product in both locales.');
        }
      }
      final categoryTranslationFields = <String, Map<String, String>>{};
      for (final entry in categoryTranslationValues.entries) {
        final spanish = entry.value['name_es'];
        final dutch = entry.value['name_nl'];
        if (spanish == null ||
            dutch == null ||
            spanish.length != 1 ||
            dutch.length != 1) {
          throw StateError(
              'BLS schema 3 has inconsistent translated labels for category ${entry.key}.');
        }
        categoryTranslationFields[entry.key] = {
          'name_es': spanish.single,
          'name_nl': dutch.single,
        };
      }
      await mainDb.transaction(() async {
        await mainDb.customStatement(
          "UPDATE products SET source = 'legacy' WHERE source = 'base'",
        );
        await _performBatchImport(
          sourceDb,
          'products',
          BatchImportType.productsBase,
          language,
          onProgress,
          'Basis-Produkte',
          collectProductBarcodes: false,
          localizedFieldsByKey: productTranslationFields,
          localizedFieldsKey: 'barcode',
          withinCatalogTransaction: true,
        );
        await _performBatchImport(
          sourceDb,
          'categories',
          BatchImportType.categories,
          null,
          onProgress,
          'Kategorien',
          collectProductBarcodes: false,
          localizedFieldsByKey: categoryTranslationFields,
          localizedFieldsKey: 'key',
          withinCatalogTransaction: true,
        );
        await _replaceBlsAliasIndex(
          mainDb: mainDb,
          aliases: aliases,
          catalogVersion: sourceVersion,
        );
        await mainDb.customStatement('''
        DELETE FROM food_categories
        WHERE key NOT IN (
          SELECT DISTINCT category FROM products
          WHERE source = 'base' AND category IS NOT NULL
        )
      ''');
        // Backfill caffeine for base products from legacy mappings & known catalog values
        final legacyMappingTable = await sourceDb.rawQuery(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'legacy_food_mappings'",
        );
        if (legacyMappingTable.isNotEmpty) {
          final mappedRows = await sourceDb.rawQuery(
            "SELECT legacy_product_id, target_barcode FROM legacy_food_mappings WHERE status = 'mapped' AND target_barcode IS NOT NULL",
          );
          for (final row in mappedRows) {
            final targetBarcode = row['target_barcode']?.toString();
            final legacyId = row['legacy_product_id']?.toString();
            if (targetBarcode != null && legacyId != null) {
              await mainDb.customStatement('''
                UPDATE products
                SET caffeine = (
                  SELECT caffeine_mg_per_100g FROM products
                  WHERE barcode = ? AND caffeine_mg_per_100g IS NOT NULL
                  LIMIT 1
                ),
                caffeine_mg_per_100g = (
                  SELECT caffeine_mg_per_100g FROM products
                  WHERE barcode = ? AND caffeine_mg_per_100g IS NOT NULL
                  LIMIT 1
                )
                WHERE barcode = ? AND (caffeine IS NULL OR caffeine = 0)
              ''', [
                legacyId,
                legacyId,
                targetBarcode,
              ]);
            }
          }
        }
        for (final entry
            in CaffeineCatalogResolver.knownBlsCaffeineMap.entries) {
          await mainDb.customStatement('''
            UPDATE products
            SET caffeine = ?, caffeine_mg_per_100g = ?
            WHERE barcode = ? AND (caffeine IS NULL OR caffeine = 0)
          ''', [
            entry.value,
            entry.value,
            entry.key,
          ]);
        }
      });
      _blsRowsVerified = true;
      await BlsFoodCatalogRefreshService.instance.markInstalled(catalogVersion);
      await prefs.setString(_keyVersionFood, catalogVersion);
      await prefs.setString(_keyVersionCats, catalogVersion);
      await prefs.setBool(_keyVersionFoodEnrichment, true);
      onProgress?.call('Kategorien', 'BLS-Kategorien bereit.', 1.0);
    } catch (error) {
      // The local catalog and alias index roll back together.
      rethrow;
    } finally {
      await sourceDb.close();
    }
  }

  /// Rebuilds only the replaceable BLS alias index. This avoids re-importing
  /// thousands of food rows when the sidecar catalog itself is already current.
  Future<void> _rebuildBlsAliasIndex(String sourcePath) async {
    final sourceDb = await sqflite.openDatabase(sourcePath, readOnly: true);
    final mainDb = await DatabaseHelper.instance.database;
    try {
      final aliasTable = await sourceDb.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'food_aliases'",
      );
      final aliases = aliasTable.isEmpty
          ? <Map<String, Object?>>[]
          : await sourceDb.query('food_aliases');
      final metadataRows = await sourceDb.query('metadata');
      final metadata = {
        for (final row in metadataRows)
          row['key']?.toString() ?? '': row['value']?.toString() ?? '',
      };
      final sourceVersion = metadata['version'];
      if (sourceVersion == null || !sourceVersion.startsWith('bls-')) {
        throw StateError('BLS catalog has invalid version metadata.');
      }
      final sourceSchema = int.tryParse(metadata['schema_version'] ?? '');
      if (sourceSchema == null ||
          sourceSchema > AppDataSources.supportedCatalogSchemaVersion ||
          (sourceSchema >= 2 &&
              (aliasTable.isEmpty ||
                  int.tryParse(metadata['curated_alias_count'] ?? '') !=
                      aliases.length))) {
        throw StateError('BLS alias data does not match catalog metadata.');
      }
      await mainDb.transaction(() => _replaceBlsAliasIndex(
            mainDb: mainDb,
            aliases: aliases,
            catalogVersion: sourceVersion,
          ));
    } finally {
      await sourceDb.close();
    }
  }

  Future<void> _replaceBlsAliasIndex({
    required AppDatabase mainDb,
    required List<Map<String, Object?>> aliases,
    required String catalogVersion,
  }) async {
    await mainDb.customStatement('DELETE FROM bls_food_alias_index');
    for (final alias in aliases) {
      await mainDb.customStatement(
        'INSERT OR REPLACE INTO bls_food_alias_index '
        '(barcode, language_code, alias, normalized_alias, kind, method, match_scope, review_status) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          for (final value in [
            alias['barcode'],
            alias['language_code'],
            alias['alias'],
            alias['normalized_alias'],
            alias['kind'],
            alias['method'],
            alias['match_scope'],
            alias['review_status'],
          ])
            value?.toString() ?? '',
        ],
      );
    }
    await mainDb.customStatement(
      'INSERT OR REPLACE INTO bls_food_alias_index_state '
      '(id, catalog_version, alias_count) VALUES (1, ?, '
      '(SELECT COUNT(*) FROM bls_food_alias_index))',
      [catalogVersion],
    );
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

        if (prefKey
            .startsWith(OffCatalogCountryService.installedVersionKeyPrefix)) {
          if (installedVersion == '0') {
            unawaited(TelemetryService.instance.trackFeatureUsed(
              featureKey: FeatureKey.offCatalogInstalled,
            ));
          } else {
            unawaited(TelemetryService.instance.trackFeatureUsed(
              featureKey: FeatureKey.offCatalogUpdated,
            ));
          }
        }

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
    Map<String, Map<String, String>> localizedFieldsByKey = const {},
    String localizedFieldsKey = 'barcode',
    bool withinCatalogTransaction = false,
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
    if (!withinCatalogTransaction) {
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
    }

    // Configure performance PRAGMAs before transaction
    if (!withinCatalogTransaction) {
      try {
        await mainDb.customStatement('PRAGMA synchronous = OFF;');
        await mainDb.customStatement('PRAGMA journal_mode = MEMORY;');
        await mainDb.customStatement('PRAGMA foreign_keys = OFF;');
      } catch (e) {
        debugPrint(
            '[ExerciseCatalog] Warning: could not set performance PRAGMAs: $e');
      }
    }

    int processed = 0;
    int totalExercisesInserted = 0;
    int totalTranslationsInserted = 0;
    int batchNumber = 0;

    try {
      Future<void> importRows() async {
        while (true) {
          final rows = await assetDb.query(
            tableName,
            limit: batchSize,
            offset: offset,
          );
          if (rows.isEmpty) break;
          batchNumber++;

          final rowsForMapping = localizedFieldsByKey.isEmpty
              ? rows
              : rows.map((row) {
                  final key = row[localizedFieldsKey]?.toString();
                  final localizedFields =
                      key == null ? null : localizedFieldsByKey[key];
                  return localizedFields == null
                      ? row
                      : <String, dynamic>{...row, ...localizedFields};
                }).toList(growable: false);

          final mappedCompanions = await compute(
            _parseBatchInIsolate,
            _BatchImportPayload(
              rows: rowsForMapping,
              type: importType,
              preferredLanguage: preferredLanguage,
            ),
          );

          // Exercise bundles need two passes: first insert exercises, then translations.
          final exerciseBundles = <ExerciseBundle>[];
          final otherCompanions = <dynamic>[];
          // ⚡ Bolt Optimization: Single-pass iteration to partition companions
          // Replaces two O(N) `.where` passes, avoiding redundant array allocations.
          for (final companion in mappedCompanions) {
            if (companion is ExerciseBundle) {
              exerciseBundles.add(companion);
            } else {
              otherCompanions.add(companion);
            }
          }

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
                  final exerciseId =
                      BasisDataRowMappers.parseString(fields['id']);
                  if (exerciseId.isEmpty) {
                    debugPrint(
                        '[ExerciseCatalog]   [$taskLabel] ⚠️  Skipping exercise with empty id');
                    return;
                  }
                  final exerciseCompanion = ExercisesCompanion(
                    id: drift.Value(exerciseId),
                    categoryName: drift.Value(BasisDataRowMappers.parseString(
                        fields['category_name'])),
                    musclesPrimary: drift.Value(BasisDataRowMappers.parseString(
                        fields['muscles_primary'])),
                    musclesSecondary: drift.Value(
                        BasisDataRowMappers.parseString(
                            fields['muscles_secondary'])),
                    isCustom: const drift.Value(false),
                    createdBy: const drift.Value('system'),
                    source: const drift.Value('wger'),
                    // Absent() rather than Value(null) where the asset does not
                    // carry the column: on a v1 asset this must leave whatever
                    // a previous v2 import wrote alone instead of erasing it.
                    status: BasisDataRowMappers.optionalText(fields, 'status'),
                    mergedInto:
                        BasisDataRowMappers.optionalText(fields, 'merged_into'),
                    modality:
                        BasisDataRowMappers.optionalText(fields, 'modality'),
                    mechanic:
                        BasisDataRowMappers.optionalText(fields, 'mechanic'),
                    forceVector: BasisDataRowMappers.optionalText(
                        fields, 'force_vector'),
                    movementPattern: BasisDataRowMappers.optionalText(
                        fields, 'movement_pattern'),
                    laterality:
                        BasisDataRowMappers.optionalText(fields, 'laterality'),
                    difficulty:
                        BasisDataRowMappers.optionalText(fields, 'difficulty'),
                    trackingType: BasisDataRowMappers.optionalText(
                        fields, 'tracking_type'),
                    loadMode:
                        BasisDataRowMappers.optionalText(fields, 'load_mode'),
                    supportsAddedWeight: BasisDataRowMappers.optionalBool(
                        fields, 'supports_added_weight'),
                    primaryEquipment: BasisDataRowMappers.optionalText(
                        fields, 'primary_equipment'),
                    bodyRegion:
                        BasisDataRowMappers.optionalText(fields, 'body_region'),
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
                      exerciseId: drift.Value(
                          BasisDataRowMappers.parseString(t['exercise_id'])),
                      languageCode: drift.Value(
                          BasisDataRowMappers.parseString(t['language_code'])),
                      name: drift.Value(
                          BasisDataRowMappers.parseString(t['name'])),
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
            final double baseMax =
                importType == BatchImportType.exercises ? 0.70 : 0.95;
            final double progress =
                ((processed / totalCount) * baseMax).clamp(0.0, baseMax);
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
                    final exerciseId =
                        BasisDataRowMappers.parseString(t['exercise_id']);
                    final langCode =
                        BasisDataRowMappers.parseString(t['language_code']);
                    final name = BasisDataRowMappers.parseString(t['name']);
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

              trOffset += trRows.length;
              if (onProgress != null && trTotal > 0) {
                final double trProgress =
                    (0.70 + (0.30 * (trOffset / trTotal))).clamp(0.70, 1.0);
                onProgress(
                  "Update $taskLabel",
                  "$trOffset / $trTotal Übersetzungen",
                  trProgress,
                );
              }
              await Future.delayed(const Duration(milliseconds: 1));
            }

            totalTranslationsInserted += relationalTrInserted;
            debugPrint(
              '[ExerciseCatalog]   [$taskLabel] Relational translation pass complete: '
              '$relationalTrInserted / $trTotal rows written',
            );
          }

          await _importCatalogSideTables(
            assetDb: assetDb,
            mainDb: mainDb,
            taskLabel: taskLabel,
          );

          // Order matters: the exercises are upserted above, the register is
          // imported by the pass right before this, and only then does user
          // data get pointed at the survivors. The whole register is replayed
          // every import, which is what covers a device that skipped a
          // release — the pass is idempotent by construction.
          await const ExerciseAliasMigration().run(mainDb);
        }
      }

      if (withinCatalogTransaction) {
        await importRows();
      } else {
        await mainDb.transaction(importRows);
      }

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
      if (!withinCatalogTransaction) {
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
    }

    return importedProductBarcodes;
  }

  /// Copies the catalog's v2 side tables into the app database.
  ///
  /// Two different policies, on purpose:
  ///
  /// * The vocabularies (`muscles`, `equipment`, `languages` and their
  ///   translations) are *replaced*. They are closed sets owned by the data
  ///   repo with no user data hanging off them, so an upsert-only import would
  ///   leave a retired muscle in the app forever.
  /// * `exercises` and everything keyed by an exercise id stay upsert-only.
  ///   Exercise ids are a contract with the user's workout logs; nothing keyed
  ///   by one is ever deleted here.
  ///
  /// A missing source table is not an error. A v1 asset has none of these, and
  /// the app has to keep running on one — the bundled asset is what every
  /// remote failure falls back to.
  Future<void> _importCatalogSideTables({
    required sqflite.Database assetDb,
    required AppDatabase mainDb,
    required String taskLabel,
  }) async {
    final available = (await assetDb.query(
      'sqlite_master',
      columns: ['name'],
      where: "type = 'table'",
    ))
        .map((row) => row['name']?.toString())
        .whereType<String>()
        .toSet();

    Future<void> copy({
      required String source,
      required bool replace,
      required Future<int> Function(List<Map<String, Object?>> rows) write,
    }) async {
      if (!available.contains(source)) {
        debugPrint(
          '[ExerciseCatalog]   [$taskLabel] $source: not in this asset, skipped',
        );
        return;
      }
      var offset = 0;
      var written = 0;
      var firstBatch = true;
      while (true) {
        final rows = await assetDb.query(source, limit: 5000, offset: offset);
        if (rows.isEmpty) break;
        if (firstBatch && replace) {
          // Only once the source has proved it has rows. Clearing a vocabulary
          // and then finding the asset empty would leave the app with neither.
          await _clearCatalogVocabularyTable(mainDb, source);
          firstBatch = false;
        }
        written += await write(rows);
        offset += rows.length;
        await Future.delayed(const Duration(milliseconds: 1));
      }
      debugPrint('[ExerciseCatalog]   [$taskLabel] $source: $written rows');
    }

    await copy(
      source: 'muscles',
      replace: true,
      write: (rows) async {
        var n = 0;
        await mainDb.batch((batch) {
          for (final row in rows) {
            final id = BasisDataRowMappers.parseString(row['id']);
            final groupId = BasisDataRowMappers.parseString(row['group_id']);
            if (id.isEmpty || groupId.isEmpty) continue;
            batch.insert(
              mainDb.muscles,
              MusclesCompanion.insert(
                id: id,
                parentId: drift.Value(
                    BasisDataRowMappers.nullableString(row['parent_id'])),
                level: BasisDataRowMappers.parseString(row['level']),
                groupId: groupId,
                legacyGroup: drift.Value(
                    BasisDataRowMappers.nullableString(row['legacy_group'])),
                bodySlugs: drift.Value(
                    BasisDataRowMappers.nullableString(row['body_slugs'])),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
            n++;
          }
        });
        return n;
      },
    );

    await copy(
      source: 'muscle_translations',
      replace: true,
      write: (rows) async {
        var n = 0;
        await mainDb.batch((batch) {
          for (final row in rows) {
            final muscleId = BasisDataRowMappers.parseString(row['muscle_id']);
            final lang = BasisDataRowMappers.parseString(row['language_code']);
            final name = BasisDataRowMappers.parseString(row['name']);
            if (muscleId.isEmpty || lang.isEmpty || name.isEmpty) continue;
            batch.insert(
              mainDb.muscleTranslations,
              MuscleTranslationsCompanion.insert(
                muscleId: muscleId,
                languageCode: lang,
                name: name,
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
            n++;
          }
        });
        return n;
      },
    );

    await copy(
      source: 'equipment',
      replace: true,
      write: (rows) async {
        var n = 0;
        await mainDb.batch((batch) {
          for (final row in rows) {
            final id = BasisDataRowMappers.parseString(row['id']);
            if (id.isEmpty) continue;
            batch.insert(
              mainDb.equipment,
              EquipmentCompanion.insert(
                id: id,
                kind: BasisDataRowMappers.parseString(row['kind']),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
            n++;
          }
        });
        return n;
      },
    );

    await copy(
      source: 'equipment_translations',
      replace: true,
      write: (rows) async {
        var n = 0;
        await mainDb.batch((batch) {
          for (final row in rows) {
            final equipmentId =
                BasisDataRowMappers.parseString(row['equipment_id']);
            final lang = BasisDataRowMappers.parseString(row['language_code']);
            final name = BasisDataRowMappers.parseString(row['name']);
            if (equipmentId.isEmpty || lang.isEmpty || name.isEmpty) continue;
            batch.insert(
              mainDb.equipmentTranslations,
              EquipmentTranslationsCompanion.insert(
                equipmentId: equipmentId,
                languageCode: lang,
                name: name,
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
            n++;
          }
        });
        return n;
      },
    );

    await copy(
      source: 'languages',
      replace: true,
      write: (rows) async {
        var n = 0;
        await mainDb.batch((batch) {
          for (final row in rows) {
            final code = BasisDataRowMappers.parseString(row['code']);
            if (code.isEmpty) continue;
            batch.insert(
              mainDb.catalogLanguages,
              CatalogLanguagesCompanion.insert(
                code: code,
                tier: BasisDataRowMappers.parseString(row['tier']),
                completeness: drift.Value(
                    BasisDataRowMappers.parseNullableDouble(
                            row['completeness']) ??
                        0),
                // The data repo decides which languages are fit to show. The
                // app reads that decision rather than re-deriving one from
                // `completeness`, which would rebuild exactly the coupling
                // that moving the vocabulary into the data removes.
                displayable: drift.Value(
                    BasisDataRowMappers.parseBool(row['displayable'])),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
            n++;
          }
        });
        return n;
      },
    );

    await copy(
      source: 'exercise_muscles',
      replace: false,
      write: (rows) async {
        var n = 0;
        await mainDb.batch((batch) {
          for (final row in rows) {
            final exerciseId =
                BasisDataRowMappers.parseString(row['exercise_id']);
            final muscleId = BasisDataRowMappers.parseString(row['muscle_id']);
            if (exerciseId.isEmpty || muscleId.isEmpty) continue;
            batch.insert(
              mainDb.exerciseMuscles,
              ExerciseMusclesCompanion.insert(
                exerciseId: exerciseId,
                muscleId: muscleId,
                role: BasisDataRowMappers.parseString(row['role']),
                contribution: drift.Value(
                    BasisDataRowMappers.parseNullableDouble(
                        row['contribution'])),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
            n++;
          }
        });
        return n;
      },
    );

    await copy(
      source: 'exercise_equipment',
      replace: false,
      write: (rows) async {
        var n = 0;
        await mainDb.batch((batch) {
          for (final row in rows) {
            final exerciseId =
                BasisDataRowMappers.parseString(row['exercise_id']);
            final equipmentId =
                BasisDataRowMappers.parseString(row['equipment_id']);
            if (exerciseId.isEmpty || equipmentId.isEmpty) continue;
            batch.insert(
              mainDb.exerciseEquipment,
              ExerciseEquipmentCompanion.insert(
                exerciseId: exerciseId,
                equipmentId: equipmentId,
                kind: BasisDataRowMappers.parseString(row['kind']),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
            n++;
          }
        });
        return n;
      },
    );

    await copy(
      source: 'exercise_tags',
      replace: false,
      write: (rows) async {
        var n = 0;
        await mainDb.batch((batch) {
          for (final row in rows) {
            final exerciseId =
                BasisDataRowMappers.parseString(row['exercise_id']);
            final tag = BasisDataRowMappers.parseString(row['tag']);
            if (exerciseId.isEmpty || tag.isEmpty) continue;
            batch.insert(
              mainDb.exerciseTags,
              ExerciseTagsCompanion.insert(exerciseId: exerciseId, tag: tag),
              mode: drift.InsertMode.insertOrReplace,
            );
            n++;
          }
        });
        return n;
      },
    );

    await copy(
      source: 'exercise_aliases',
      replace: false,
      write: (rows) async {
        var n = 0;
        await mainDb.batch((batch) {
          for (final row in rows) {
            final oldId = BasisDataRowMappers.parseString(row['old_id']);
            final newId = BasisDataRowMappers.parseString(row['new_id']);
            if (oldId.isEmpty || newId.isEmpty || oldId == newId) continue;
            batch.insert(
              mainDb.exerciseAliases,
              ExerciseAliasesCompanion.insert(
                oldId: oldId,
                newId: newId,
                reason: drift.Value(
                    BasisDataRowMappers.nullableString(row['reason'])),
                sinceVersion: drift.Value(
                    BasisDataRowMappers.nullableString(row['since_version'])),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
            n++;
          }
        });
        return n;
      },
    );
  }

  Future<void> _clearCatalogVocabularyTable(
    AppDatabase mainDb,
    String source,
  ) async {
    switch (source) {
      case 'muscles':
        await mainDb.delete(mainDb.muscles).go();
      case 'muscle_translations':
        await mainDb.delete(mainDb.muscleTranslations).go();
      case 'equipment':
        await mainDb.delete(mainDb.equipment).go();
      case 'equipment_translations':
        await mainDb.delete(mainDb.equipmentTranslations).go();
      case 'languages':
        await mainDb.delete(mainDb.catalogLanguages).go();
    }
  }

  /// Applies OFF replacement semantics with historical retention:
  /// - Keep imported barcodes active (`source='off'` via import mapping)
  /// - Demote historically protected, no-longer-imported rows to `off_retained`
  /// - Delete no-longer-imported rows that are not historically referenced
  /// Runs the real exercise-catalog import against an arbitrary source file.
  ///
  /// Exists so the contract test can drive the actual import path — the same
  /// batching, mapping and side-table passes the app runs — rather than a
  /// reimplementation of it that would agree with itself by construction.
  ///
  /// Expects [DatabaseHelper.setDriftDb] to have been pointed at a test
  /// database, and a real sqflite factory to be installed.
  @visibleForTesting
  Future<void> importExerciseCatalogFromFileForTesting(
      String sourcePath) async {
    final assetDb = await sqflite.openDatabase(sourcePath, readOnly: true);
    try {
      await _performBatchImport(
        assetDb,
        'exercises',
        BatchImportType.exercises,
        null,
        null,
        'Übungen',
        collectProductBarcodes: false,
      );
    } finally {
      await assetDb.close();
    }
  }

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
  ProductsCompanion mapProductRowForTesting(Map<String, dynamic> row,
      {required String sourceLabel, String? preferredLanguage}) {
    return BasisDataRowMappers.mapProductRow(row,
        sourceLabel: sourceLabel, preferredLanguage: preferredLanguage);
  }
}
