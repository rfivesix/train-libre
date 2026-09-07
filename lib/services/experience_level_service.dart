import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import '../data/database_helper.dart';
import '../data/drift_database.dart' as db;

/// How much of the training vocabulary the app puts in front of the user.
///
/// This is a *presentation* axis, not a data one: nothing here changes what is
/// logged, computed or stored — only which columns are offered and how finely
/// muscles are named. Not to be confused with an exercise's own difficulty
/// (`beginner | intermediate | advanced` on [Exercise]), which describes the
/// movement rather than the person doing it.
enum ExperienceLevel { beginner, advanced, pro }

/// Centralizes the user's experience level.
///
/// Backed by SQLite `AppSettings.experienceLevel`, with an automatic one-time
/// migration from SharedPreferences if existing.
/// The default is [ExperienceLevel.pro], so an app that never touches this
/// behaves exactly as it did before the level existed.
class ExperienceLevelService extends ChangeNotifier {
  static const String _experienceLevelKey = 'experience_level';

  ExperienceLevel _level = ExperienceLevel.pro;

  ExperienceLevelService() {
    _loadLevel();
  }

  ExperienceLevel get level => _level;

  /// Whether to offer the third set column at all — RIR on a lift, intensity
  /// on a cardio row. Both are the same column, so both go together.
  bool get showsIntensity => _level == ExperienceLevel.pro;

  /// Whether to name a muscle by its region ("shoulders") rather than by the
  /// individual head ("front deltoid"). The body map stays fine-grained either
  /// way — this is about words, not about the drawing.
  bool get usesCoarseMuscleNames => _level != ExperienceLevel.pro;

  Future<void> reload() async {
    await _loadLevel();
  }

  Future<void> _loadLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyPrefVal = prefs.getString(_experienceLevelKey);

    final dbInst = DatabaseHelper.driftDb;
    if (dbInst != null) {
      try {
        final settingsRows = await (dbInst.select(dbInst.appSettings)
              ..orderBy([
                (t) => drift.OrderingTerm(
                    expression: t.localId, mode: drift.OrderingMode.desc)
              ])
              ..limit(1))
            .get();

        if (settingsRows.isNotEmpty) {
          final settingsRow = settingsRows.first;
          // If SharedPreferences has a legacy value and DB still has default or null, migrate it.
          if (legacyPrefVal != null &&
              settingsRow.experienceLevel == 'pro' &&
              legacyPrefVal != 'pro') {
            await (dbInst.update(dbInst.appSettings)
                  ..where((t) => t.id.equals(settingsRow.id)))
                .write(db.AppSettingsCompanion(
              experienceLevel: drift.Value(legacyPrefVal),
            ));
            _updateLevel(_parse(legacyPrefVal));
            return;
          }

          final loadedFromDb = _parse(settingsRow.experienceLevel);
          _updateLevel(loadedFromDb);
          return;
        }
      } catch (_) {
        // Fall back to SharedPreferences if DB not yet initialized or table unready
      }
    }

    final loaded = _parse(legacyPrefVal);
    _updateLevel(loaded);
  }

  void _updateLevel(ExperienceLevel newLevel) {
    if (_level == newLevel) return;
    _level = newLevel;
    notifyListeners();
  }

  Future<void> setLevel(ExperienceLevel value) async {
    final bool isChanged = value != _level;
    _level = value;

    // Keep SharedPreferences in sync for backup / fallback
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_experienceLevelKey, value.name);

    // Save to AppSettings in Drift
    final dbInst = DatabaseHelper.driftDb;
    if (dbInst != null) {
      try {
        final settingsRows = await (dbInst.select(dbInst.appSettings)
              ..orderBy([
                (t) => drift.OrderingTerm(
                    expression: t.localId, mode: drift.OrderingMode.desc)
              ])
              ..limit(1))
            .get();

        if (settingsRows.isNotEmpty) {
          await (dbInst.update(dbInst.appSettings)
                ..where((t) => t.id.equals(settingsRows.first.id)))
              .write(db.AppSettingsCompanion(
            experienceLevel: drift.Value(value.name),
          ));
        }
      } catch (_) {}
    }

    if (isChanged) {
      notifyListeners();
    }
  }

  static ExperienceLevel _parse(String? value) {
    if (value == null) return ExperienceLevel.pro;
    return ExperienceLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => ExperienceLevel.pro,
    );
  }
}
