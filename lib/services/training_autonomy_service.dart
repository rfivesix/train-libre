import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import '../data/database_helper.dart';
import '../data/drift_database.dart' as db;
import '../features/workout/domain/models/prescription_enums.dart';

/// Centralizes the user's training autonomy level preference.
///
/// Backed by SQLite `AppSettings.trainingAutonomyLevel`, with SharedPreferences
/// fallback and synchronization.
/// The default is [AutonomyLevel.off], ensuring strict opt-in.
class TrainingAutonomyService extends ChangeNotifier {
  static const String _trainingAutonomyKey = 'training_autonomy_level';

  final db.AppDatabase? _db;
  Future<void>? _pendingLoad;
  AutonomyLevel _level = AutonomyLevel.off;

  TrainingAutonomyService([this._db]) {
    _pendingLoad = _loadLevel();
  }

  AutonomyLevel get level => _level;

  bool get isSuggestEnabled => _level == AutonomyLevel.suggest;

  Future<void> initialize() async {
    await (_pendingLoad ?? _loadLevel());
  }

  Future<void> reload() async {
    _pendingLoad = _loadLevel();
    await _pendingLoad;
  }

  Future<void> _loadLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final prefVal = prefs.getString(_trainingAutonomyKey);

    final dbInst = _db ?? DatabaseHelper.driftDb;
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
          final loadedFromDb = _parse(settingsRow.trainingAutonomyLevel);
          _updateLevel(loadedFromDb);
          return;
        }
      } catch (_) {
        // Fall back to SharedPreferences if DB not yet initialized or table unready
      }
    }

    final loaded = _parse(prefVal);
    _updateLevel(loaded);
  }

  void _updateLevel(AutonomyLevel newLevel) {
    if (_level == newLevel) return;
    _level = newLevel;
    notifyListeners();
  }

  Future<void> setLevel(AutonomyLevel value) async {
    // Await any in-flight load before overriding
    if (_pendingLoad != null) {
      await _pendingLoad;
    }

    final bool isChanged = value != _level;
    _level = value;

    // Keep SharedPreferences in sync for fast reads / fallback
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trainingAutonomyKey, value.name);

    // Save to AppSettings in Drift
    final dbInst = _db ?? DatabaseHelper.driftDb;
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
            trainingAutonomyLevel: drift.Value(value.name),
          ));
        }
      } catch (_) {}
    }

    if (isChanged) {
      notifyListeners();
    }
  }

  static AutonomyLevel _parse(String? value) {
    if (value == null) return AutonomyLevel.off;
    return AutonomyLevel.values.firstWhere(
      (lvl) => lvl.name == value.toLowerCase().trim(),
      orElse: () => AutonomyLevel.off,
    );
  }
}
