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

class BlsFoodCatalogManifest {
  const BlsFoodCatalogManifest({
    required this.version,
    required this.catalogVersion,
    required this.schemaVersion,
    required this.minAppSchemaVersion,
    required this.dbUri,
    required this.dbSha256,
    required this.downloadSha256,
    required this.dbSizeBytes,
    required this.downloadSizeBytes,
    required this.expectedFoodCount,
    required this.foodNutrientFactCount,
  });

  final String version;
  final String catalogVersion;
  final int schemaVersion;
  final int minAppSchemaVersion;
  final Uri dbUri;
  final String dbSha256;
  final String downloadSha256;
  final int dbSizeBytes;
  final int downloadSizeBytes;
  final int expectedFoodCount;
  final int foodNutrientFactCount;

  factory BlsFoodCatalogManifest.parse(Map<String, dynamic> json, Uri baseUri) {
    if (json['source_id'] != 'bls_food_catalog' ||
        json['channel'] != 'stable' ||
        json['catalog_id'] != 'bls' ||
        json['db_compression'] != 'gzip') {
      throw const FormatException('Unsupported BLS catalog manifest.');
    }
    final file = json['db_file']?.toString() ?? '';
    final version = json['version']?.toString() ?? '';
    final catalogVersion = json['catalog_version']?.toString() ?? '';
    final dbHash = json['db_sha256']?.toString() ?? '';
    final downloadHash = json['download_sha256']?.toString() ?? '';
    final license = json['license'];
    final source = json['source'];
    if (file != 'train_libre_base_foods.db.gz' ||
        version.isEmpty ||
        catalogVersion.isEmpty ||
        license is! Map<String, dynamic> ||
        license['id'] != 'CC-BY-4.0' ||
        source is! Map<String, dynamic> ||
        source['publisher'] != 'Max Rubner-Institut' ||
        source['doi'] != '10.25826/Data20251217-134202-0' ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(dbHash) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(downloadHash)) {
      throw const FormatException('Invalid BLS catalog manifest fields.');
    }
    int number(String key) {
      final value = json[key];
      if (value is! num || !value.isFinite || value < 0) {
        throw FormatException('Invalid BLS manifest value: $key');
      }
      return value.toInt();
    }

    final schema = number('schema_version');
    final minimum = number('min_app_schema_version');
    if (schema > AppDataSources.supportedCatalogSchemaVersion ||
        minimum > AppDataSources.supportedCatalogSchemaVersion) {
      throw const FormatException('BLS catalog requires a newer app version.');
    }
    return BlsFoodCatalogManifest(
      version: version,
      catalogVersion: catalogVersion,
      schemaVersion: schema,
      minAppSchemaVersion: minimum,
      dbUri: baseUri.resolve(file),
      dbSha256: dbHash,
      downloadSha256: downloadHash,
      dbSizeBytes: number('db_size_bytes'),
      downloadSizeBytes: number('download_size_bytes'),
      expectedFoodCount: number('expected_food_count'),
      foodNutrientFactCount: number('food_nutrient_fact_count'),
    );
  }
}

class BlsFoodCatalogUpdateCandidate {
  const BlsFoodCatalogUpdateCandidate({
    required this.version,
    required this.localDbPath,
    required this.fromCache,
  });

  final String version;
  final String localDbPath;
  final bool fromCache;
}

typedef BlsCatalogProgress = void Function(
    String task, String detail, double progress);

/// Downloads, verifies and atomically installs the complete BLS catalog.
/// Nutrient facts and their provenance remain in this read-only sidecar DB.
class BlsFoodCatalogRefreshService {
  BlsFoodCatalogRefreshService._({http.Client? client})
      : _client = client ?? http.Client();

  static final BlsFoodCatalogRefreshService instance =
      BlsFoodCatalogRefreshService._();

  final http.Client _client;

  static const _baseUri = AppDataSources.blsFoodCatalogReleaseBaseUrl;
  static const _manifestFile = 'catalog_manifest.json';
  static const _versionKey = 'installed_bls_food_version';
  static const _checkedAtKey = 'bls_food_catalog_last_checked_at';
  static const _remoteVersionKey = 'bls_food_catalog_last_remote_version';
  static const _lastErrorKey = 'bls_food_catalog_last_error';
  static const _minimumCheckInterval = Duration(hours: 12);
  static const _databaseFileName = 'train_libre_bls_foods.db';

  static bool isRemoteVersionNewer({
    required String remoteVersion,
    required String installedVersion,
  }) {
    final remote = _versionParts(remoteVersion);
    final installed = _versionParts(installedVersion);
    if (remote == null || installed == null) {
      return remoteVersion.compareTo(installedVersion) > 0;
    }
    final length =
        remote.length > installed.length ? remote.length : installed.length;
    for (var index = 0; index < length; index++) {
      final left = index < remote.length ? remote[index] : 0;
      final right = index < installed.length ? installed[index] : 0;
      if (left != right) return left > right;
    }
    return false;
  }

  static List<int>? _versionParts(String version) {
    final parts = version.split('.');
    if (parts.isEmpty || parts.any((part) => int.tryParse(part) == null)) {
      return null;
    }
    return parts.map(int.parse).toList(growable: false);
  }

  static String? installedVersionKey({SharedPreferences? prefs}) {
    return prefs?.getString(_versionKey);
  }

  Future<String> installedDatabasePath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'bls_food_catalog', _databaseFileName);
  }

  Future<bool> isInstalled() async {
    final prefs = await SharedPreferences.getInstance();
    final path = await installedDatabasePath();
    final file = File(path);
    if (!file.existsSync() || prefs.getString(_versionKey) == null) {
      return false;
    }
    try {
      final db = await sqflite.openDatabase(path, readOnly: true);
      try {
        final fact = await db.rawQuery(
          'SELECT 1 FROM food_nutrients LIMIT 1',
        );
        final foods = sqflite.Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM products'),
            ) ??
            0;
        return fact.isNotEmpty && foods > 0;
      } finally {
        await db.close();
      }
    } catch (error) {
      debugPrint('[BLS catalog] Installed database check failed: $error');
      return false;
    }
  }

  Future<BlsFoodCatalogManifest> fetchManifestDirect() async {
    final uri = Uri.parse(_baseUri).resolve(_manifestFile);
    final response = await _client.get(uri, headers: const {
      'Accept': 'application/json'
    }).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw HttpException(
          'BLS manifest request returned ${response.statusCode}.');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return BlsFoodCatalogManifest.parse(json, Uri.parse(_baseUri));
  }

  Future<BlsFoodCatalogUpdateCandidate?> prepareUpdateCandidate({
    required String installedVersion,
    bool force = false,
    BlsCatalogProgress? onProgress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final installedPath = await installedDatabasePath();
    if (!force) {
      final checked = prefs.getInt(_checkedAtKey);
      final installed = await isInstalled();
      if (installed &&
          checked != null &&
          DateTime.now()
                  .difference(DateTime.fromMillisecondsSinceEpoch(checked)) <
              _minimumCheckInterval) {
        return null;
      }
    }
    onProgress?.call(
        'BLS-Manifest wird geladen...', 'Prüfe Lebensmittelkatalog', 0.01);
    try {
      final manifest = await fetchManifestDirect();
      await prefs.setString(_remoteVersionKey, manifest.version);
      await prefs.setInt(_checkedAtKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.remove(_lastErrorKey);
      if (installedVersion.isNotEmpty &&
          !isRemoteVersionNewer(
            remoteVersion: manifest.version,
            installedVersion: installedVersion,
          ) &&
          await isInstalled()) {
        return null;
      }
      final dir = Directory(p.dirname(installedPath));
      await dir.create(recursive: true);
      final workDir = await Directory.systemTemp.createTemp('trainlibre-bls-');
      final compressed = File(p.join(workDir.path, 'catalog.db.gz'));
      final staged = File(p.join(workDir.path, 'catalog.db'));
      try {
        onProgress?.call('BLS-Katalog wird heruntergeladen...', '0 MB', 0.03);
        final request = http.Request('GET', manifest.dbUri);
        final response =
            await _client.send(request).timeout(const Duration(minutes: 4));
        if (response.statusCode != 200) {
          throw HttpException(
              'BLS catalog download returned ${response.statusCode}.');
        }
        final output = compressed.openWrite();
        final digestSink = _DigestSink();
        final hashingSink = sha256.startChunkedConversion(digestSink);
        var downloadedBytes = 0;
        var lastProgressMb = -1;
        try {
          await for (final chunk
              in response.stream.timeout(const Duration(seconds: 30))) {
            downloadedBytes += chunk.length;
            hashingSink.add(chunk);
            output.add(chunk);
            final progressMb = downloadedBytes ~/ (1024 * 1024);
            if (progressMb != lastProgressMb) {
              lastProgressMb = progressMb;
              final fraction = downloadedBytes / manifest.downloadSizeBytes;
              onProgress?.call(
                'BLS-Katalog wird heruntergeladen...',
                '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                (0.03 + fraction * 0.40).clamp(0.03, 0.43),
              );
            }
          }
          await output.flush();
        } finally {
          await output.close();
          hashingSink.close();
        }
        if (downloadedBytes != manifest.downloadSizeBytes ||
            digestSink.value.toString() != manifest.downloadSha256) {
          throw const FormatException(
              'BLS download size or checksum mismatch.');
        }
        onProgress?.call(
            'BLS-Katalog wird entpackt...', 'Datenbank wird geprüft', 0.48);
        await compressed
            .openRead()
            .transform(gzip.decoder)
            .pipe(staged.openWrite());
        if (await staged.length() != manifest.dbSizeBytes ||
            await _sha256File(staged) != manifest.dbSha256) {
          throw const FormatException(
              'BLS database size or checksum mismatch.');
        }
        await _validateDatabase(staged.path, manifest);
        final siblingStage = File('$installedPath.staging');
        if (await siblingStage.exists()) await siblingStage.delete();
        await staged.copy(siblingStage.path);
        final installedFile = File(installedPath);
        final previousFile = File('$installedPath.previous');
        if (await previousFile.exists()) await previousFile.delete();
        final hadPrevious = await installedFile.exists();
        if (hadPrevious) await installedFile.rename(previousFile.path);
        try {
          await siblingStage.rename(installedPath);
          if (await previousFile.exists()) await previousFile.delete();
        } catch (_) {
          if (hadPrevious && await previousFile.exists()) {
            await previousFile.rename(installedPath);
          }
          rethrow;
        }
        onProgress?.call(
            'BLS-Katalog bereit', 'Version ${manifest.version}', 1.0);
        return BlsFoodCatalogUpdateCandidate(
          version: manifest.version,
          localDbPath: installedPath,
          fromCache: false,
        );
      } finally {
        if (await workDir.exists()) await workDir.delete(recursive: true);
      }
    } catch (error) {
      await prefs.setString(_lastErrorKey, error.toString());
      debugPrint('[BLS catalog] Update failed: $error');
      rethrow;
    }
  }

  Future<void> markInstalled(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_versionKey, version);
  }

  Future<String?> installedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_versionKey);
  }

  Future<void> _validateDatabase(
      String path, BlsFoodCatalogManifest manifest) async {
    final db = await sqflite.openDatabase(path, readOnly: true);
    try {
      final foods = sqflite.Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM products'),
      );
      final facts = sqflite.Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM food_nutrients'),
      );
      final sideTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final names = sideTables.map((row) => row['name']).toSet();
      const required = {
        'products',
        'categories',
        'metadata',
        'nutrient_components',
        'food_nutrients',
        'data_origins',
        'source_references',
        'legacy_food_mappings',
      };
      if (foods != manifest.expectedFoodCount ||
          facts != manifest.foodNutrientFactCount ||
          !names.containsAll(required)) {
        throw const FormatException(
            'BLS database structure or row counts are invalid.');
      }
      final metadataRows = await db.query('metadata');
      final metadata = {
        for (final row in metadataRows)
          row['key']?.toString() ?? '': row['value']?.toString() ?? '',
      };
      if (metadata['version'] != 'bls-${manifest.catalogVersion}' ||
          metadata['source_license'] != 'CC-BY-4.0' ||
          metadata['source_doi'] != '10.25826/Data20251217-134202-0' ||
          metadata['schema_version'] != manifest.schemaVersion.toString()) {
        throw const FormatException(
            'BLS database metadata does not match its manifest.');
      }
      final foreignKeys = await db.rawQuery('PRAGMA foreign_key_check');
      if (foreignKeys.isNotEmpty) {
        throw const FormatException('BLS database has invalid foreign keys.');
      }
    } finally {
      await db.close();
    }
  }

  Future<String> _sha256File(File file) async {
    final digestSink = _DigestSink();
    final inputSink = sha256.startChunkedConversion(digestSink);
    await file.openRead().forEach(inputSink.add);
    inputSink.close();
    return digestSink.value.toString();
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? _digest;

  Digest get value => _digest ?? (throw StateError('Digest is not available.'));

  @override
  void add(Digest data) => _digest = data;

  @override
  void close() {}
}

class BlsNutrientFact {
  const BlsNutrientFact({
    required this.code,
    required this.name,
    required this.unit,
    required this.group,
    required this.value,
    required this.valueText,
    required this.origin,
    required this.reference,
  });

  final String code;
  final String name;
  final String unit;
  final String group;
  final double? value;
  final String? origin;
  final String? reference;
  final String? valueText;
}

class BlsNutrientRepository {
  const BlsNutrientRepository();

  Future<List<BlsNutrientFact>> getFacts(
      String barcode, String languageCode) async {
    if (!barcode.startsWith('bls:')) return const [];
    final path =
        await BlsFoodCatalogRefreshService.instance.installedDatabasePath();
    if (!await File(path).exists()) return const [];
    final db = await sqflite.openDatabase(path, readOnly: true);
    try {
      final english = languageCode == 'en' ||
          languageCode == 'fr' ||
          languageCode == 'it' ||
          languageCode == 'ja';
      final nameColumn = english ? 'name_en' : 'name_de';
      final groupColumn = english ? 'group_en' : 'group_de';
      final rows = await db.rawQuery('''
        SELECT n.component_code, c.$nameColumn AS component_name,
               c.unit, c.$groupColumn AS component_group,
               n.value_numeric, n.value_text, o.label AS origin,
               r.citation AS reference
        FROM food_nutrients n
        JOIN nutrient_components c ON c.component_code = n.component_code
        LEFT JOIN data_origins o ON o.origin_id = n.origin_id
        LEFT JOIN source_references r ON r.reference_id = n.reference_id
        WHERE n.barcode = ?
        ORDER BY c.group_de, c.component_code
      ''', [barcode]);
      return rows
          .map((row) => BlsNutrientFact(
                code: row['component_code']?.toString() ?? '',
                name: row['component_name']?.toString() ??
                    row['component_code']?.toString() ??
                    '',
                unit: row['unit']?.toString() ?? '',
                group: row['component_group']?.toString() ?? '',
                value: (row['value_numeric'] as num?)?.toDouble(),
                valueText: row['value_text']?.toString(),
                origin: row['origin']?.toString(),
                reference: row['reference']?.toString(),
              ))
          .toList(growable: false);
    } finally {
      await db.close();
    }
  }
}
