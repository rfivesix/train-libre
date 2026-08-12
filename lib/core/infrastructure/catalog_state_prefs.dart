// lib/core/infrastructure/catalog_state_prefs.dart

/// Preference keys that describe which catalog databases (wger exercises, OFF
/// products, base foods, food categories) are physically installed on *this*
/// device.
///
/// These keys are device-local bookkeeping, not user data. A backup taken on
/// device A says nothing about what is on disk on device B, so restoring them
/// makes a fresh install believe the catalogs are already present — the
/// download prompt then never appears and the catalog screens stay empty.
///
/// Backups must therefore neither export nor restore these keys; the device's
/// own values win. The user's *choice* of OFF country
/// (`off_catalog_active_country`) is a real preference and is deliberately not
/// part of this list.
class CatalogStatePrefs {
  const CatalogStatePrefs._();

  /// Keys matched verbatim.
  static const Set<String> exactKeys = {
    // Installed catalog versions.
    'installed_training_version',
    'installed_food_version',
    'installed_cats_version',
    'installed_food_enrichment_v1',
    'is_exercise_catalog_initialized',
    'last_db_sync_app_version',
    // Remote-update bookkeeping (last seen / last prompted / snooze).
    'exercise_catalog_last_remote_version',
    'last_prompted_wger_version',
    'last_prompted_off_version',
    'db_update_snoozed_until',
  };

  /// Keys matched by prefix — the OFF catalog keys are country-scoped
  /// (`installed_off_version_de`, `off_catalog_last_remote_version_fr`, …).
  /// `installed_off_version` (no suffix) is the legacy key and is covered by
  /// the same prefix.
  static const List<String> keyPrefixes = [
    'installed_off_version',
    'off_catalog_last_remote_version_',
  ];

  static bool isCatalogStateKey(String key) {
    if (exactKeys.contains(key)) return true;
    for (final prefix in keyPrefixes) {
      if (key.startsWith(prefix)) return true;
    }
    return false;
  }
}
