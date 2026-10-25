/// Calculates the one missing core nutrient from any three supplied values.
class MacroEntryCalculation {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String calculatedNutrient;

  const MacroEntryCalculation({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calculatedNutrient,
  });
}

class MacroEntryCalculator {
  static const nutrients = ['calories', 'protein', 'carbs', 'fat'];

  static MacroEntryCalculation? calculate(Map<String, double?> values) {
    final present = nutrients.where((key) => values[key] != null).toList();
    if (present.length != 3) return null;
    if (present.any((key) => !values[key]!.isFinite || values[key]! < 0)) {
      return null;
    }

    final missing = nutrients.firstWhere(
      (key) => !values.containsKey(key) || values[key] == null,
    );
    final p = values['protein'];
    final c = values['carbs'];
    final f = values['fat'];
    final kcal = values['calories'];
    double derived;

    if (missing == 'calories') {
      derived = p! * 4 + c! * 4 + f! * 9;
    } else {
      final knownEnergy = (p ?? 0) * 4 + (c ?? 0) * 4 + (f ?? 0) * 9;
      final factor = missing == 'fat' ? 9.0 : 4.0;
      derived = (kcal! - knownEnergy) / factor;
      if (!derived.isFinite || derived < 0) return null;
    }

    return MacroEntryCalculation(
      calories: missing == 'calories' ? derived : kcal!,
      protein: missing == 'protein' ? derived : p!,
      carbs: missing == 'carbs' ? derived : c!,
      fat: missing == 'fat' ? derived : f!,
      calculatedNutrient: missing,
    );
  }
}
