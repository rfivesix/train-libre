import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as drift;

import '../../../data/database_helper.dart';
import '../models/export_models.dart';

class PreparedHealthExportIdentity {
  const PreparedHealthExportIdentity({
    required this.externalId,
    required this.revision,
    required this.payloadFingerprint,
  });

  final String externalId;
  final int revision;
  final String payloadFingerprint;
}

/// Persists the native identity and last committed payload for each exported
/// source record. Preparing an export never advances the committed revision;
/// that happens only after the native write succeeds. A process death between
/// those steps therefore retries the same native id/revision safely.
class HealthExportIdentityStore {
  HealthExportIdentityStore({DatabaseHelper? databaseHelper})
      : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<PreparedHealthExportIdentity?> prepare({
    required HealthExportPlatform platform,
    required HealthExportDomain domain,
    required String sourceKey,
    required String payloadFingerprint,
  }) async {
    final db = await _dbHelper.database;
    return db.transaction(() async {
      var row = await _load(
        platform: platform,
        domain: domain,
        sourceKey: sourceKey,
      );
      if (row == null) {
        final legacy = await db.customSelect(
          '''SELECT 1 FROM health_export_records
             WHERE platform = ? AND domain = ? AND idempotency_key = ?
             LIMIT 1''',
          variables: [
            drift.Variable.withString(platform.name),
            drift.Variable.withString(domain.name),
            drift.Variable.withString(sourceKey),
          ],
        ).getSingleOrNull();
        // Builds before schema 38 already wrote sourceKey as the native client
        // ID at revision 0. Preserve that identity and continue at revision 1
        // so edited historical records replace rather than duplicate it.
        final externalId = legacy == null
            ? _externalId(platform, domain, sourceKey)
            : sourceKey;
        final initialRevision = legacy == null ? -1 : 0;
        await db.customStatement(
          '''INSERT OR IGNORE INTO health_export_identities
             (platform, domain, source_key, external_id, revision,
              payload_fingerprint, is_legacy, exported_at)
             VALUES (?, ?, ?, ?, ?, NULL, 0, NULL)''',
          [
            platform.name,
            domain.name,
            sourceKey,
            externalId,
            initialRevision,
          ],
        );
        row = await _load(
          platform: platform,
          domain: domain,
          sourceKey: sourceKey,
        );
      }
      if (row == null || row.read<int>('is_legacy') == 1) return null;

      final committedFingerprint =
          row.readNullable<String>('payload_fingerprint');
      if (committedFingerprint == payloadFingerprint) return null;
      final committedRevision = row.read<int>('revision');
      return PreparedHealthExportIdentity(
        externalId: row.read<String>('external_id'),
        revision: committedRevision + 1,
        payloadFingerprint: payloadFingerprint,
      );
    });
  }

  Future<void> commit({
    required HealthExportPlatform platform,
    required HealthExportDomain domain,
    required String sourceKey,
    required PreparedHealthExportIdentity identity,
  }) async {
    final db = await _dbHelper.database;
    await db.customStatement(
      '''UPDATE health_export_identities
         SET revision = ?, payload_fingerprint = ?, exported_at = ?
         WHERE platform = ? AND domain = ? AND source_key = ?
           AND is_legacy = 0 AND revision < ?''',
      [
        identity.revision,
        identity.payloadFingerprint,
        DateTime.now().toUtc().millisecondsSinceEpoch,
        platform.name,
        domain.name,
        sourceKey,
        identity.revision,
      ],
    );
  }

  Future<drift.QueryRow?> _load({
    required HealthExportPlatform platform,
    required HealthExportDomain domain,
    required String sourceKey,
  }) async {
    final db = await _dbHelper.database;
    return db.customSelect(
      '''SELECT external_id, revision, payload_fingerprint, is_legacy
         FROM health_export_identities
         WHERE platform = ? AND domain = ? AND source_key = ?''',
      variables: [
        drift.Variable.withString(platform.name),
        drift.Variable.withString(domain.name),
        drift.Variable.withString(sourceKey),
      ],
    ).getSingleOrNull();
  }

  String _externalId(
    HealthExportPlatform platform,
    HealthExportDomain domain,
    String sourceKey,
  ) {
    final digest = sha256
        .convert(
          utf8.encode('trainlibre:${platform.name}:${domain.name}:$sourceKey'),
        )
        .bytes
        .take(16)
        .toList(growable: false);
    // RFC 4122 version/variant bits make the stable identifier acceptable as
    // HKMetadataKeyExternalUUID while remaining a valid Health Connect client ID.
    final bytes = [...digest];
    bytes[6] = (bytes[6] & 0x0f) | 0x50;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
