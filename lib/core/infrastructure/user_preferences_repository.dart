import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesRepository {
  static final UserPreferencesRepository instance =
      UserPreferencesRepository._init();
  UserPreferencesRepository._init();

  final StreamController<String> _extraNutrientController =
      StreamController<String>.broadcast();

  Stream<String> watchOverviewExtraNutrient() =>
      _extraNutrientController.stream;

  Future<int?> getTargetSugar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('targetSugar');
  }

  Future<int?> getTargetFiber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('targetFiber');
  }

  Future<int?> getTargetSalt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('targetSalt');
  }

  Future<int?> getTargetCaffeine() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('targetCaffeine');
  }

  static const String overviewExtraNutrientPrefKey = 'overviewExtraNutrient';

  Future<bool> getShowSugarInDiaryOverview() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('showSugarInDiaryOverview') ?? false;
  }

  Future<String> getOverviewExtraNutrient() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(overviewExtraNutrientPrefKey);
    if (saved != null) return saved;

    final legacySugar = prefs.getBool('showSugarInDiaryOverview');
    if (legacySugar == true) {
      return 'sugar';
    }
    return 'fiber';
  }

  Future<void> setOverviewExtraNutrient(String nutrient) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(overviewExtraNutrientPrefKey, nutrient);
    _extraNutrientController.add(nutrient);
  }
}
