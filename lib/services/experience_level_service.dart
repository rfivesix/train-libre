import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
/// Lives in the developer lab for now; the real entry point (an onboarding
/// question, a visible setting) follows in a later update. The default is
/// [ExperienceLevel.pro], so an app that never touches this behaves exactly as
/// it did before the level existed.
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
    final loaded = _parse(prefs.getString(_experienceLevelKey));
    if (_level == loaded) return;
    _level = loaded;
    notifyListeners();
  }

  Future<void> setLevel(ExperienceLevel value) async {
    final bool isChanged = value != _level;
    _level = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_experienceLevelKey, value.name);
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
