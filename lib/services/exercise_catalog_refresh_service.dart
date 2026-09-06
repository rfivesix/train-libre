import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../config/app_data_sources.dart';
import 'catalog_file_migration.dart';

class ExerciseCatalogManifest {
  final String version;

  /// Structure version of the artefact this manifest describes.
  ///
  /// Independent of [version], which only tracks content. Absent on manifests
  /// written before the version contract existed; those are read as 1.
  final int schemaVersion;

  /// Oldest consumer that can still read this release.
  ///
  /// A release stays readable by older apps as long as it keeps the v1
  /// compatibility columns filled — that is what this number declares. When a
  /// manifest names a [schemaVersion] but no floor, the floor is taken to be
  /// that same schema version rather than 1: a release that forgot to declare
  /// its floor must not be assumed compatible.
  final int minAppSchemaVersion;

  final Uri dbUri;
  final Uri? buildReportUri;
  final String sourceId;
  final String channel;
  final DateTime? generatedAt;
  final int? expectedExerciseRows;
  final int? minimumExerciseRows;
  final String dbSha256;

  const ExerciseCatalogManifest({
    required this.version,
    required this.schemaVersion,
    required this.minAppSchemaVersion,
    required this.dbUri,
    required this.buildReportUri,
    required this.sourceId,
    required this.channel,
    required this.generatedAt,
    required this.expectedExerciseRows,
    required this.minimumExerciseRows,
    required this.dbSha256,
  });
}

class ExerciseCatalogUpdateCandidate {
  final String version;
  final String localDbPath;
  final Uri manifestUri;
  final Uri dbUri;
  final bool fromCache;

  const ExerciseCatalogUpdateCandidate({
    required this.version,
    required this.localDbPath,
    required this.manifestUri,
    required this.dbUri,
    required this.fromCache,
  });
}

class ExerciseCatalogRefreshSnapshot {
  final String installedVersion;
  final String? cachedVersion;
  final String? lastKnownRemoteVersion;
  final DateTime? lastCheckedAt;
  final String? lastError;

  const ExerciseCatalogRefreshSnapshot({
    required this.installedVersion,
    required this.cachedVersion,
    required this.lastKnownRemoteVersion,
    required this.lastCheckedAt,
    required this.lastError,
  });
}

typedef NowProvider = DateTime Function();
typedef SupportDirectoryProvider = Future<Directory> Function();
typedef TempDirectoryProvider = Future<Directory> Function();
typedef PrefsProvider = Future<SharedPreferences> Function();
typedef ExerciseCatalogRefreshProgress = void Function(
  String task,
  String detail,
  double progress, {
  required bool canSkip,
});
typedef ExerciseRemoteRefreshSkipRequested = bool Function();

/// Handles remote exercise-catalog update discovery, download, and validation.
///
/// The service keeps network/source details in central config and degrades
/// gracefully by returning `null` on any remote failure.
class ExerciseCatalogRefreshService {
  ExerciseCatalogRefreshService._({
    http.Client? httpClient,
    ExerciseCatalogRemoteSourceConfig? config,
    NowProvider? nowProvider,
    SupportDirectoryProvider? supportDirectoryProvider,
    TempDirectoryProvider? tempDirectoryProvider,
    PrefsProvider? prefsProvider,
  })  : _httpClient = httpClient ?? http.Client(),
        _config = config ?? AppDataSources.exerciseCatalog,
        _nowProvider = nowProvider ?? DateTime.now,
        _supportDirectoryProvider =
            supportDirectoryProvider ?? getApplicationSupportDirectory,
        _tempDirectoryProvider = tempDirectoryProvider ?? getTemporaryDirectory,
        _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  static final ExerciseCatalogRefreshService instance =
      ExerciseCatalogRefreshService._();

  @visibleForTesting
  factory ExerciseCatalogRefreshService.forTesting({
    http.Client? httpClient,
    ExerciseCatalogRemoteSourceConfig? config,
    NowProvider? nowProvider,
    SupportDirectoryProvider? supportDirectoryProvider,
    TempDirectoryProvider? tempDirectoryProvider,
    PrefsProvider? prefsProvider,
  }) {
    return ExerciseCatalogRefreshService._(
      httpClient: httpClient,
      config: config,
      nowProvider: nowProvider,
      supportDirectoryProvider: supportDirectoryProvider,
      tempDirectoryProvider: tempDirectoryProvider,
      prefsProvider: prefsProvider,
    );
  }

  final http.Client _httpClient;
  final ExerciseCatalogRemoteSourceConfig _config;
  final NowProvider _nowProvider;
  final SupportDirectoryProvider _supportDirectoryProvider;
  final TempDirectoryProvider _tempDirectoryProvider;
  final PrefsProvider _prefsProvider;

  static const String _keyLastRemoteVersion =
      'exercise_catalog_last_remote_version';
  static const String _keyLastCheckedAtMs = 'exercise_catalog_last_checked_at';
  static const String _keyCachedCatalogVersion =
      'exercise_catalog_cached_version';
  static const String _keyLastError = 'exercise_catalog_last_error';

  static const Set<String> _requiredTables = {'exercises', 'metadata'};
  static const Set<String> _requiredExerciseColumns = {
    'id',
    'category_name',
    'muscles_primary',
    'muscles_secondary',
  };

  Future<ExerciseCatalogManifest?> fetchManifestDirect() async {
    final manifestUri = _resolveUrlOrPath(
      _config.baseUrl,
      _config.manifestPath,
    );
    return _fetchManifest(manifestUri);
  }

  Future<ExerciseCatalogUpdateCandidate?> prepareUpdateCandidate({
    required String installedVersion,
    bool force = false,
    ExerciseCatalogRefreshProgress? onProgress,
    ExerciseRemoteRefreshSkipRequested? isSkipRequested,
  }) async {
    if (!_config.enabled) {
      return null;
    }

    final prefs = await _prefsProvider();
    final cachePath = await _cachedDbPath();
    final manifestUri = _resolveUrlOrPath(
      _config.baseUrl,
      _config.manifestPath,
    );

    // Keep a valid newer cache as an offline fallback. A due or forced check
    // must still fetch the manifest before deciding which version to import.
    ExerciseCatalogUpdateCandidate? cachedCandidate;
    final cachedVersion = prefs.getString(_keyCachedCatalogVersion);
    if (cachedVersion != null &&
        isRemoteVersionNewer(
          remoteVersion: cachedVersion,
          installedVersion: installedVersion,
        )) {
      final cachedValidation = await _validateCatalogDb(
        dbPath: cachePath,
        expectedVersion: cachedVersion,
        minimumRows: _config.minimumExerciseRows,
      );
      if (cachedValidation.isValid) {
        cachedCandidate = ExerciseCatalogUpdateCandidate(
          version: cachedVersion,
          localDbPath: cachePath,
          manifestUri: manifestUri,
          dbUri: Uri.file(cachePath),
          fromCache: true,
        );
      }
    }

    final now = _nowProvider();
    final lastCheckedMs = prefs.getInt(_keyLastCheckedAtMs);
    final hasLastError = prefs.getString(_keyLastError) != null;
    if (!force &&
        !hasLastError &&
        !shouldCheckRemoteNow(
          now: now,
          lastCheckedEpochMs: lastCheckedMs,
          minCheckInterval: _config.minCheckInterval,
        )) {
      return cachedCandidate;
    }
    await prefs.setInt(_keyLastCheckedAtMs, now.millisecondsSinceEpoch);

    try {
      if (isSkipRequested?.call() ?? false) {
        await prefs.setString(
          _keyLastError,
          'Remote exercise catalog update skipped by user.',
        );
        return cachedCandidate;
      }
      onProgress?.call(
        'Prüfe Übungen...',
        'Remote-Manifest wird geladen...',
        0.0,
        canSkip: true,
      );
      final manifest = await _fetchManifest(manifestUri);
      if (manifest == null) {
        await prefs.setString(
          _keyLastError,
          'Manifest fetch failed or invalid payload.',
        );
        return cachedCandidate;
      }

      await prefs.setString(_keyLastRemoteVersion, manifest.version);

      final shouldDownload = isRemoteVersionNewer(
        remoteVersion: manifest.version,
        installedVersion: installedVersion,
      );
      if (!shouldDownload) {
        await prefs.remove(_keyLastError);
        onProgress?.call(
          'Übungen aktuell',
          'Kein Remote-Download erforderlich.',
          1.0,
          canSkip: false,
        );
        return cachedCandidate;
      }

      if (cachedCandidate != null &&
          !isRemoteVersionNewer(
            remoteVersion: manifest.version,
            installedVersion: cachedCandidate.version,
          )) {
        await prefs.remove(_keyLastError);
        return cachedCandidate;
      }

      if (isSkipRequested?.call() ?? false) {
        await prefs.setString(
          _keyLastError,
          'Remote exercise catalog download skipped by user.',
        );
        return cachedCandidate;
      }

      final tempDir = await _tempDirectoryProvider();
      final tempDbPath = p.join(
        tempDir.path,
        'train_libre_training_remote_${now.millisecondsSinceEpoch}.db',
      );

      final effectiveDbUri = await _downloadWithLegacyFallback(
        manifest: manifest,
        destinationPath: tempDbPath,
        timeout: _config.downloadTimeout,
        onProgress: (progress) {
          onProgress?.call(
            'Lade Übungen...',
            'Remote-Übungskatalog ${manifest.version} wird heruntergeladen.',
            progress,
            canSkip: true,
          );
        },
        isSkipRequested: isSkipRequested,
      );
      if (effectiveDbUri == null) {
        await prefs.setString(
          _keyLastError,
          (isSkipRequested?.call() ?? false)
              ? 'Remote exercise catalog download skipped by user.'
              : 'Download failed for ${manifest.dbUri}',
        );
        return cachedCandidate;
      }

      onProgress?.call(
        'Prüfe Übungen...',
        'Download wird verifiziert...',
        0.92,
        canSkip: false,
      );
      final actualDbSha256 = await _computeFileSha256(tempDbPath);
      if (!_sha256Equals(actualDbSha256, manifest.dbSha256)) {
        await prefs.setString(
          _keyLastError,
          'Downloaded DB checksum mismatch. expected=${manifest.dbSha256} actual=$actualDbSha256',
        );
        await _deleteIfExists(tempDbPath);
        return cachedCandidate;
      }

      if (await _usesWalJournalMode(tempDbPath)) {
        onProgress?.call(
          'Prüfe Übungen...',
          'Download wird für den Import vorbereitet...',
          0.94,
          canSkip: false,
        );
        final beforeSize = await File(tempDbPath).length();
        await _normalizeSingleFileWalDatabase(tempDbPath);
        final afterSize = await File(tempDbPath).length();
        if (afterSize <= 0 || afterSize < beforeSize) {
          await prefs.setString(
            _keyLastError,
            'Downloaded catalog DB was modified unexpectedly during WAL normalization. before=$beforeSize after=$afterSize',
          );
          await _deleteIfExists(tempDbPath);
          return cachedCandidate;
        }
      }

      final validated = await _validateCatalogDb(
        dbPath: tempDbPath,
        expectedVersion: manifest.version,
        minimumRows:
            manifest.minimumExerciseRows ?? _config.minimumExerciseRows,
      );
      if (!validated.isValid) {
        await prefs.setString(
          _keyLastError,
          validated.error ?? 'Downloaded DB validation failed.',
        );
        await _deleteIfExists(tempDbPath);
        return cachedCandidate;
      }

      // From here on the old cache may be replaced; do not return its old
      // version/path pair if publishing the new cache fails.
      cachedCandidate = null;
      await File(cachePath).parent.create(recursive: true);
      await _deleteIfExists(cachePath);
      await File(tempDbPath).copy(cachePath);
      await _deleteIfExists(tempDbPath);

      await prefs.setString(_keyCachedCatalogVersion, manifest.version);
      await prefs.remove(_keyLastError);

      await _cacheManifestJson(
        manifestUri: manifestUri,
        manifest: manifest,
      );

      onProgress?.call(
        'Übungen bereit',
        'Remote-Übungskatalog ${manifest.version} wird importiert.',
        1.0,
        canSkip: false,
      );

      return ExerciseCatalogUpdateCandidate(
        version: manifest.version,
        localDbPath: cachePath,
        manifestUri: manifestUri,
        dbUri: effectiveDbUri,
        fromCache: false,
      );
    } catch (e) {
      await prefs.setString(_keyLastError, e.toString());
      debugPrint('Exercise catalog refresh skipped (safe fallback): $e');
      return cachedCandidate;
    }
  }

  Future<ExerciseCatalogRefreshSnapshot> readSnapshot({
    required String installedVersion,
  }) async {
    final prefs = await _prefsProvider();
    final lastCheckedMs = prefs.getInt(_keyLastCheckedAtMs);
    return ExerciseCatalogRefreshSnapshot(
      installedVersion: installedVersion,
      cachedVersion: prefs.getString(_keyCachedCatalogVersion),
      lastKnownRemoteVersion: prefs.getString(_keyLastRemoteVersion),
      lastCheckedAt: lastCheckedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastCheckedMs),
      lastError: prefs.getString(_keyLastError),
    );
  }

  Future<String> _cachedDbPath() async {
    final supportDir = await _supportDirectoryProvider();
    final cacheDir = Directory(
      p.join(supportDir.path, _config.localCacheDirectoryName),
    );
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return CatalogFileMigration.resolveCanonicalPath(
      directoryPath: cacheDir.path,
      canonicalFileName: _config.localCacheDbFileName,
      legacyFileName: _config.legacyLocalCacheDbFileName,
    );
  }

  Future<Uri?> _downloadWithLegacyFallback({
    required ExerciseCatalogManifest manifest,
    required String destinationPath,
    required Duration timeout,
    ValueChanged<double>? onProgress,
    ExerciseRemoteRefreshSkipRequested? isSkipRequested,
  }) async {
    if (await _downloadFile(
      manifest.dbUri,
      destinationPath,
      timeout: timeout,
      onProgress: onProgress,
      isSkipRequested: isSkipRequested,
    )) {
      return manifest.dbUri;
    }

    final legacyUri = legacyFallbackDbUri(
      failedUri: manifest.dbUri,
      config: _config,
    );
    if (legacyUri == null) {
      return null;
    }
    await _deleteIfExists(destinationPath);
    if (await _downloadFile(
      legacyUri,
      destinationPath,
      timeout: timeout,
      onProgress: onProgress,
      isSkipRequested: isSkipRequested,
    )) {
      return legacyUri;
    }
    return null;
  }

  @visibleForTesting
  static Uri? legacyFallbackDbUri({
    required Uri failedUri,
    required ExerciseCatalogRemoteSourceConfig config,
  }) {
    final legacyDbPath = config.legacyDefaultDbPath;
    if (legacyDbPath == null || legacyDbPath == config.defaultDbPath) {
      return null;
    }
    final legacyUri = _resolveUrlOrPath(config.baseUrl, legacyDbPath);
    if (legacyUri == failedUri || !_isSecureRemoteUri(legacyUri)) {
      return null;
    }
    return legacyUri;
  }

  Future<void> _cacheManifestJson({
    required Uri manifestUri,
    required ExerciseCatalogManifest manifest,
  }) async {
    final supportDir = await _supportDirectoryProvider();
    final cacheDir = Directory(
      p.join(supportDir.path, _config.localCacheDirectoryName),
    );
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final manifestFile = File(
      p.join(cacheDir.path, _config.localManifestFileName),
    );
    final map = {
      'source_id': manifest.sourceId,
      'channel': manifest.channel,
      'version': manifest.version,
      'schema_version': manifest.schemaVersion,
      'min_app_schema_version': manifest.minAppSchemaVersion,
      'generated_at': manifest.generatedAt?.toIso8601String(),
      'db_url': manifest.dbUri.toString(),
      'db_sha256': manifest.dbSha256,
      'build_report_url': manifest.buildReportUri?.toString(),
      'manifest_url': manifestUri.toString(),
      'expected_exercise_count': manifest.expectedExerciseRows,
      'minimum_exercise_rows': manifest.minimumExerciseRows,
      'cached_at': _nowProvider().toIso8601String(),
    };
    await manifestFile.writeAsString(
      jsonEncode(map),
      flush: true,
    );
  }

  Future<ExerciseCatalogManifest?> _fetchManifest(Uri manifestUri) async {
    final response = await _httpClient.get(manifestUri, headers: const {
      'Accept': 'application/json'
    }).timeout(_config.manifestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return parseManifest(decoded, _config);
  }

  static ExerciseCatalogManifest? parseManifest(
    Map<String, dynamic> json,
    ExerciseCatalogRemoteSourceConfig config,
  ) {
    final build = json['build'] is Map<String, dynamic>
        ? json['build'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final version = _firstNonBlankString([
      json['version'],
      json['db_version'],
      build['db_version'],
    ]);
    if (version == null) {
      return null;
    }

    final sourceId =
        _firstNonBlankString([json['source_id'], build['source_id']]) ??
            config.sourceId;
    final channel = _firstNonBlankString([json['channel'], build['channel']]) ??
        config.channel;
    if (sourceId != config.sourceId || channel != config.channel) {
      return null;
    }

    final dbSha256 = _firstNonBlankString([json['db_sha256']]);
    if (dbSha256 == null || !_isValidSha256(dbSha256)) {
      return null;
    }

    // Schema contract. `schema_version` says what the artefact is,
    // `min_app_schema_version` says which consumers may read it. Rejecting on
    // the floor rather than on the schema itself is what keeps the data repo's
    // compatibility-column promise worth anything: a v2 catalog that still
    // fills the v1 columns declares floor 1 and is deliberately accepted here.
    //
    // A manifest that names a schema but no floor is treated as requiring that
    // schema. Silently reading a missing floor as 1 would let exactly the
    // release this guard exists for slip through.
    final schemaVersion =
        _parseInt(json['schema_version']) ?? _parseInt(build['schema_version']);
    final minAppSchemaVersion = _parseInt(json['min_app_schema_version']) ??
        _parseInt(build['min_app_schema_version']) ??
        schemaVersion ??
        1;
    final effectiveSchemaVersion = schemaVersion ?? 1;
    if (effectiveSchemaVersion < 1 || minAppSchemaVersion < 1) {
      return null;
    }
    if (minAppSchemaVersion > config.supportedSchemaVersion) {
      debugPrint(
        '[ExerciseCatalog] Rejecting catalog release $version: it requires app '
        'schema $minAppSchemaVersion, this build supports '
        '${config.supportedSchemaVersion}.',
      );
      return null;
    }

    final expectedRows = _parseInt(json['expected_exercise_count']);
    final minimumRows = _parseInt(json['minimum_exercise_rows']) ??
        _parseInt(json['min_exercise_count']) ??
        _parseInt(json['min_rows']);
    if (minimumRows != null && minimumRows <= 0) {
      return null;
    }
    if (expectedRows != null && expectedRows <= 0) {
      return null;
    }
    if (expectedRows != null &&
        minimumRows != null &&
        expectedRows < minimumRows) {
      return null;
    }

    final usesFileKeys = _firstNonBlankString([
          json['db_file'],
          json['db_path'],
          json['database_path'],
          json['build_report_file'],
          json['build_report_path'],
          json['report_path'],
        ]) !=
        null;
    final effectiveBaseUrl = _firstNonBlankString([
          json['asset_base_url'],
          json['download_base_url'],
          json['base_url'],
        ]) ??
        config.baseUrl;
    if (usesFileKeys && effectiveBaseUrl.trim().isEmpty) {
      return null;
    }

    final dbUri = _resolveFromManifest(
      baseUrl: effectiveBaseUrl,
      urlValue: _firstNonBlankString([
        json['db_url'],
        json['database_url'],
      ]),
      pathValue: _firstNonBlankString([
        json['db_path'],
        json['database_path'],
        json['db_file'],
      ]),
      fallbackPath: config.defaultDbPath,
    );
    if (dbUri == null) {
      return null;
    }
    if (!_isSecureRemoteUri(dbUri)) {
      return null;
    }

    final buildReportUri = _resolveFromManifest(
      baseUrl: effectiveBaseUrl,
      urlValue: _firstNonBlankString([
        json['build_report_url'],
        json['report_url'],
      ]),
      pathValue: _firstNonBlankString([
        json['build_report_file'],
        json['build_report_path'],
        json['report_path'],
      ]),
      fallbackPath: config.defaultBuildReportPath,
    );
    if (buildReportUri != null && !_isSecureRemoteUri(buildReportUri)) {
      return null;
    }

    final generatedAtRaw =
        _firstNonBlankString([json['generated_at'], build['generated_at']]);
    final generatedAt =
        generatedAtRaw != null ? DateTime.tryParse(generatedAtRaw) : null;

    return ExerciseCatalogManifest(
      version: version,
      schemaVersion: effectiveSchemaVersion,
      minAppSchemaVersion: minAppSchemaVersion,
      dbUri: dbUri,
      buildReportUri: buildReportUri,
      sourceId: sourceId,
      channel: channel,
      generatedAt: generatedAt,
      expectedExerciseRows: expectedRows,
      minimumExerciseRows: minimumRows,
      dbSha256: dbSha256.toLowerCase(),
    );
  }

  static bool isRemoteVersionNewer({
    required String remoteVersion,
    required String installedVersion,
  }) {
    final normalizedRemote = remoteVersion.trim();
    final normalizedInstalled = installedVersion.trim();
    if (normalizedRemote.isEmpty) return false;
    if (normalizedInstalled.isEmpty) return true;
    return normalizedRemote.compareTo(normalizedInstalled) > 0;
  }

  static bool shouldCheckRemoteNow({
    required DateTime now,
    required int? lastCheckedEpochMs,
    required Duration minCheckInterval,
  }) {
    if (lastCheckedEpochMs == null) return true;
    final lastChecked = DateTime.fromMillisecondsSinceEpoch(lastCheckedEpochMs);
    return now.difference(lastChecked) >= minCheckInterval;
  }

  Future<bool> _downloadFile(
    Uri uri,
    String destinationPath, {
    required Duration timeout,
    ValueChanged<double>? onProgress,
    ExerciseRemoteRefreshSkipRequested? isSkipRequested,
  }) async {
    if (isSkipRequested?.call() ?? false) return false;
    final request = http.Request('GET', uri);
    final response = await _httpClient.send(request).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }
    final file = File(destinationPath);
    await file.parent.create(recursive: true);
    final sink = file.openWrite();
    var received = 0;
    final total = response.contentLength;
    try {
      await for (final chunk in response.stream.timeout(timeout)) {
        if (isSkipRequested?.call() ?? false) {
          return false;
        }
        received += chunk.length;
        sink.add(chunk);
        if (total != null && total > 0) {
          onProgress?.call((received / total).clamp(0.0, 0.9));
        } else {
          onProgress?.call(0.0);
        }
      }
    } finally {
      await sink.close();
    }
    if (isSkipRequested?.call() ?? false) return false;
    onProgress?.call(0.9);
    return true;
  }

  Future<_CatalogDbValidationResult> _validateCatalogDb({
    required String dbPath,
    required String expectedVersion,
    required int minimumRows,
  }) async {
    if (!await File(dbPath).exists()) {
      return const _CatalogDbValidationResult(
        isValid: false,
        error: 'Catalog DB file is missing.',
      );
    }

    sqflite.Database? db;
    try {
      db = await sqflite.openDatabase(dbPath, readOnly: true);
      final tableRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final tables = tableRows
          .map((row) => row['name']?.toString())
          .whereType<String>()
          .toSet();
      if (!_requiredTables.every(tables.contains)) {
        return const _CatalogDbValidationResult(
          isValid: false,
          error: 'Catalog DB missing required tables.',
        );
      }

      final pragmaRows = await db.rawQuery('PRAGMA table_info(exercises)');
      final columns = pragmaRows
          .map((row) => row['name']?.toString())
          .whereType<String>()
          .toSet();
      if (!_requiredExerciseColumns.every(columns.contains)) {
        return const _CatalogDbValidationResult(
          isValid: false,
          error: 'Catalog DB missing required exercise columns.',
        );
      }

      // Both formats are understood by the importer: older catalogs embed
      // German/English text, OpenExerciseDB uses exercise_translations.
      const inlineTextColumns = {
        'name_de',
        'name_en',
        'description_de',
        'description_en',
      };
      if (!inlineTextColumns.every(columns.contains)) {
        final translationColumns = tables.contains('exercise_translations')
            ? (await db.rawQuery('PRAGMA table_info(exercise_translations)'))
                .map((row) => row['name']?.toString())
                .toSet()
            : <String?>{};
        if (!{'exercise_id', 'language_code', 'name', 'description'}
            .every(translationColumns.contains)) {
          return const _CatalogDbValidationResult(
            isValid: false,
            error: 'Catalog DB missing required exercise translations.',
          );
        }
      }

      final versionRows = await db.query(
        'metadata',
        where: 'key = ?',
        whereArgs: ['version'],
      );
      final version = versionRows.isNotEmpty
          ? (versionRows.first['value']?.toString().trim() ?? '')
          : '';
      if (version.isEmpty) {
        return const _CatalogDbValidationResult(
          isValid: false,
          error: 'Catalog DB metadata.version is missing.',
        );
      }
      if (expectedVersion.isNotEmpty && version != expectedVersion) {
        return _CatalogDbValidationResult(
          isValid: false,
          error:
              'Catalog DB version mismatch. expected=$expectedVersion actual=$version',
        );
      }

      // Second reading of the same contract, this time off the artefact.
      // The cached-catalog path re-uses a downloaded DB without ever looking at
      // a manifest again, so a manifest-only guard would not cover it.
      final schemaRows = await db.query(
        'metadata',
        where: 'key IN (?, ?)',
        whereArgs: ['schema_version', 'min_app_schema_version'],
      );
      final schemaMeta = <String, String>{
        for (final row in schemaRows)
          row['key']?.toString() ?? '': row['value']?.toString().trim() ?? '',
      };
      final dbSchemaVersion = _parseInt(schemaMeta['schema_version']);
      final dbMinAppSchemaVersion =
          _parseInt(schemaMeta['min_app_schema_version']) ??
              dbSchemaVersion ??
              1;
      if (dbMinAppSchemaVersion > _config.supportedSchemaVersion) {
        return _CatalogDbValidationResult(
          isValid: false,
          error: 'Catalog DB requires app schema $dbMinAppSchemaVersion, '
              'this build supports ${_config.supportedSchemaVersion}.',
        );
      }

      final countRows =
          await db.rawQuery('SELECT COUNT(*) as c FROM exercises');
      final rowCount = sqflite.Sqflite.firstIntValue(countRows) ?? 0;
      if (rowCount < minimumRows) {
        return _CatalogDbValidationResult(
          isValid: false,
          error:
              'Catalog DB row count too low. count=$rowCount minimum=$minimumRows',
        );
      }

      return _CatalogDbValidationResult(
        isValid: true,
        version: version,
        rowCount: rowCount,
      );
    } catch (e) {
      return _CatalogDbValidationResult(
        isValid: false,
        error: 'Catalog DB validation failed: $e',
      );
    } finally {
      await db?.close();
    }
  }

  Future<void> _deleteIfExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> _computeFileSha256(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Future<bool> _usesWalJournalMode(String filePath) async {
    final file = File(filePath);
    final length = await file.length();
    if (length < 20) return false;

    final handle = await file.open();
    try {
      final header = await handle.read(20);
      if (header.length < 20) return false;
      final isSqlite =
          String.fromCharCodes(header.take(16)) == 'SQLite format 3\u0000';
      if (!isSqlite) return false;
      return header[18] == 2 || header[19] == 2;
    } finally {
      await handle.close();
    }
  }

  Future<void> _normalizeSingleFileWalDatabase(String filePath) async {
    final handle = await File(filePath).open(mode: FileMode.writeOnlyAppend);
    try {
      await handle.setPosition(18);
      await handle.writeFrom(const [1, 1]);
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  static bool _sha256Equals(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  static Uri _resolveUrlOrPath(String baseUrl, String value) {
    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }
    final base = Uri.parse(baseUrl);
    return base.resolve(value);
  }

  static Uri? _resolveFromManifest({
    required String baseUrl,
    required String? urlValue,
    required String? pathValue,
    required String fallbackPath,
  }) {
    final preferred = urlValue?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      final uri = Uri.tryParse(preferred);
      if (uri != null && uri.hasScheme) return uri;
      return _resolveUrlOrPath(baseUrl, preferred);
    }

    final path = (pathValue?.trim().isNotEmpty ?? false)
        ? pathValue!.trim()
        : fallbackPath;
    if (path.isEmpty) return null;
    return _resolveUrlOrPath(baseUrl, path);
  }

  static String? _firstNonBlankString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _isSecureRemoteUri(Uri uri) {
    return uri.hasScheme && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  static bool _isValidSha256(String value) {
    return RegExp(r'^[A-Fa-f0-9]{64}$').hasMatch(value.trim());
  }
}

class _CatalogDbValidationResult {
  final bool isValid;
  final String? version;
  final int? rowCount;
  final String? error;

  const _CatalogDbValidationResult({
    required this.isValid,
    this.version,
    this.rowCount,
    this.error,
  });
}
