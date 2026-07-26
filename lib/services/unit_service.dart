import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UnitSystem { metric, imperial }

enum UnitDimension { weight, height, liquid, distance }

/// Centralizes the user's preferred unit system and conversions.
class UnitService extends ChangeNotifier {
  static const String _unitSystemKey = 'unit_system';

  UnitSystem _unitSystem = UnitSystem.metric;

  UnitService() {
    _loadUnitSystem();
  }

  UnitSystem get unitSystem => _unitSystem;

  bool get isMetric => _unitSystem == UnitSystem.metric;

  bool get isImperial => _unitSystem == UnitSystem.imperial;

  Future<void> reload() async {
    await _loadUnitSystem();
  }

  Future<void> _loadUnitSystem() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString(_unitSystemKey);
    final loadedSystem = storedValue == null
        ? _defaultUnitSystemForLocale()
        : storedValue == UnitSystem.imperial.name
            ? UnitSystem.imperial
            : UnitSystem.metric;

    if (storedValue == null) {
      await prefs.setString(_unitSystemKey, loadedSystem.name);
    }

    if (_unitSystem == loadedSystem) return;
    _unitSystem = loadedSystem;
    notifyListeners();
  }

  UnitSystem _defaultUnitSystemForLocale() {
    final countryCode =
        PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
    return switch (countryCode) {
      'LR' || 'MM' || 'US' => UnitSystem.imperial,
      _ => UnitSystem.metric,
    };
  }

  Future<void> setUnitSystem(UnitSystem value) async {
    final bool isChanged = value != _unitSystem;
    _unitSystem = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitSystemKey, value.name);
    if (isChanged) {
      notifyListeners();
    }
  }

  Future<void> toggleUnitSystem() {
    return setUnitSystem(isMetric ? UnitSystem.imperial : UnitSystem.metric);
  }

  double convertDisplayValue(double metricValue, UnitDimension dimension) {
    return switch (dimension) {
      UnitDimension.weight => isMetric ? metricValue : kgToLbs(metricValue),
      UnitDimension.height => isMetric ? metricValue : cmToInches(metricValue),
      UnitDimension.liquid =>
        isMetric ? metricValue : mlToFluidOunces(metricValue),
      UnitDimension.distance => isMetric ? metricValue : kmToMi(metricValue),
    };
  }

  double convertToMetric(double displayValue, UnitDimension dimension) {
    return switch (dimension) {
      UnitDimension.weight => isMetric ? displayValue : lbsToKg(displayValue),
      UnitDimension.height =>
        isMetric ? displayValue : inchesToCm(displayValue),
      UnitDimension.liquid =>
        isMetric ? displayValue : fluidOuncesToMl(displayValue),
      UnitDimension.distance => isMetric ? displayValue : miToKm(displayValue),
    };
  }

  String formatDisplayWeight(double metricValue, {int fractionDigits = 1}) {
    final val = convertDisplayValue(metricValue, UnitDimension.weight);
    if (val == val.truncateToDouble()) {
      return val.toInt().toString();
    }
    final str = val.toStringAsFixed(fractionDigits);
    if (str.endsWith('.0') || str.endsWith('.00')) {
      return str.split('.')[0];
    }
    return str;
  }

  String suffixFor(UnitDimension dimension) {
    return switch (dimension) {
      UnitDimension.weight => isMetric ? 'kg' : 'lbs',
      UnitDimension.height => isMetric ? 'cm' : 'in',
      UnitDimension.liquid => isMetric ? 'ml' : 'fl oz',
      UnitDimension.distance => isMetric ? 'km' : 'mi',
    };
  }

  String metricSuffixFor(UnitDimension dimension) {
    return switch (dimension) {
      UnitDimension.weight => 'kg',
      UnitDimension.height => 'cm',
      UnitDimension.liquid => 'ml',
      UnitDimension.distance => 'km',
    };
  }

  static double kgToLbs(double value) => value * 2.20462;

  static double lbsToKg(double value) => value / 2.20462;

  static double cmToInches(double value) => value * 0.393701;

  static double inchesToCm(double value) => value / 0.393701;

  static double mlToFluidOunces(double value) => value * 0.033814;

  static double fluidOuncesToMl(double value) => value / 0.033814;

  static double kmToMi(double value) => value * 0.621371;

  static double miToKm(double value) => value / 0.621371;
}
