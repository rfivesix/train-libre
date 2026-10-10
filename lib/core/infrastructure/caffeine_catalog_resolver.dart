// lib/core/infrastructure/caffeine_catalog_resolver.dart

/// Provides caffeine content resolution for food and beverage catalog entries.
///
/// Official nutritional tables such as the German BLS (Bundeslebensmittelschlüssel)
/// 4.0 do not include a caffeine component in their standard analytical
/// workbook, leaving raw catalog rows with null caffeine values.
///
/// This resolver provides:
/// 1. Direct barcode-based mappings for standard catalog beverages.
/// 2. Natural language heuristics (German & English) for beverage variants.
/// 3. Safe fallback logic to ensure caffeine is detected when logging drinks.
class CaffeineCatalogResolver {
  const CaffeineCatalogResolver._();

  /// Known caffeine values in mg per 100 ml (or 100 g) for canonical catalog beverages.
  static const Map<String, double> knownBlsCaffeineMap = {
    // Cola beverages
    'bls:N330000': 10.0, // Colagetränk koffeinhaltig
    'bls:N331000': 10.0, // Colagetränk koffeinhaltig, mit Süßungsmitteln
    'bls:N390100': 6.5, // Cola-Misch-Getränk Orange (Spezi)
    'bls:N340000': 0.0, // Colagetränk koffeinfrei
    'bls:N352000': 0.0, // Colagetränk koffeinfrei, mit Süßungsmitteln

    // Coffee beverages & preparations
    'bls:N410100': 40.0, // Kaffee (Getränk)
    'bls:N410200': 35.0, // Kaffee (Getränk) mit Milch 3,5 % Fett
    'bls:N410300': 35.0, // Kaffee (Getränk) mit Milch 3,5 % Fett und Zucker
    'bls:N410400': 35.0, // Kaffee (Getränk) mit Kondensmilch 7,5 % Fett
    'bls:N410500': 35.0, // Kaffee (Getränk) mit Kondensmilch 7,5 % Fett und Zucker
    'bls:N410600': 40.0, // Kaffee (Getränk) mit Zucker
    'bls:N410800': 35.0, // Kaffee (Getränk) mit Alkohol
    'bls:N411100': 212.0, // Espresso
    'bls:N416000': 10.0, // Kaffee (Getränk) koffeinreduziert
    'bls:N420100': 35.0, // Kaffee (Getränk) aus Instantpulver
    'bls:N420900': 3000.0, // Instantkaffeepulver (trocken)
    'bls:N491000': 20.0, // Kaffee (Getränk) halb und halb, mit Milch 3,5 % Fett
    'bls:N4A0000': 35.0, // Kaffee (Getränk) mit Haferdrink, ungesüßt
    'bls:N4A1000': 35.0, // Kaffee (Getränk) mit Mandeldrink, ungesüßt
    'bls:N4A2000': 35.0, // Kaffee (Getränk) mit Sojadrink, ungesüßt
    'bls:Y997043': 30.0, // Eiskaffee
    'bls:S220200': 10.0, // Kaffeeeis

    // Decaffeinated coffee
    'bls:N414100': 0.0, // Kaffee entkoffeiniert, mit Milch 3,5 % Fett
    'bls:N414200': 0.0, // Kaffee entkoffeiniert, mit Kondensmilch 7,5 % Fett
    'bls:N415000': 0.0, // Kaffee entkoffeiniert
    'bls:N440100': 0.0, // Kaffee entkoffeiniert, aus Instantpulver
    'bls:N440900': 0.0, // Instantkaffeepulver entkoffeiniert

    // Coffee substitutes (grain / chicory - no caffeine)
    'bls:N500100': 0.0,
    'bls:N500200': 0.0,
    'bls:N500300': 0.0,
    'bls:N500400': 0.0,
    'bls:N500500': 0.0,
    'bls:N500600': 0.0,
    'bls:N500900': 0.0,
    'bls:N540100': 0.0,
    'bls:N540900': 0.0,
    'bls:N5A0000': 0.0,
    'bls:N5A1000': 0.0,
    'bls:N5A2000': 0.0,

    // Teas
    'bls:N610100': 15.0, // Grüntee (Getränk)
    'bls:N611000': 35.0, // Mate-Tee (Getränk)
    'bls:N630000': 20.0, // Schwarztee (Getränk)
    'bls:N630200': 18.0, // Schwarztee mit Milch 3,5 % Fett
    'bls:N630300': 18.0, // Schwarztee mit Milch 3,5 % Fett und Zucker
    'bls:N630400': 18.0, // Schwarztee mit Sahne 30 % Fett
    'bls:N630500': 18.0, // Schwarztee mit Sahne 30 % Fett und Zucker
    'bls:N630600': 20.0, // Schwarztee mit Zucker
    'bls:N630700': 20.0, // Schwarztee mit Zitronensaft und Zucker
    'bls:N670100': 0.0, // Schwarztee entkoffeiniert
    'bls:N019000': 5.0, // Eistee mit Zitronen-/Pfirsichgeschmack

    // Herbal & Fruit infusions (caffeine-free)
    'bls:N601000': 0.0, // Roibusch-/Rooibos-Tee
    'bls:N710000': 0.0, // Früchtetee
    'bls:N710600': 0.0,
    'bls:N720100': 0.0, // Kräutertee
    'bls:N720200': 0.0,
    'bls:N720300': 0.0,
    'bls:N720400': 0.0,
    'bls:N720500': 0.0,
    'bls:N720600': 0.0,
    'bls:N721000': 0.0, // Pfefferminztee

    // Legacy base food mappings fallback
    'base_food_cola': 10.0,
    'base_food_sugar_free_cola': 10.0,
    'base_food_energy_drink': 32.0,
    'base_food_sugar_free_energy_drink': 32.0,
    'base_food_coffee_black': 40.0,
    'base_food_black_coffee_unsweetened': 40.0,
    'base_food_espresso_unsweetened': 212.0,
    'base_food_americano_unsweetened': 30.0,
    'base_food_cold_brew_coffee_unsweetened': 50.0,
    'base_food_instant_black_coffee_unsweetened': 35.0,
    'base_food_turkish_coffee_unsweetened': 60.0,
    'base_food_ristretto_unsweetened': 250.0,
    'base_food_moka_pot_coffee_unsweetened': 100.0,
    'base_food_french_press_coffee_unsweetened': 45.0,
    'base_food_tea_black': 20.0,
    'base_food_black_tea_unsweetened': 20.0,
    'base_food_earl_grey_tea_unsweetened': 22.0,
    'base_food_green_tea_unsweetened': 15.0,
    'base_food_jasmine_green_tea_unsweetened': 15.0,
    'base_food_oolong_tea_unsweetened': 25.0,
    'base_food_white_tea_unsweetened': 10.0,
    'base_food_pu_erh_tea_unsweetened': 30.0,
    'base_food_yerba_mate_tea_unsweetened': 35.0,
    'base_food_decaffeinated_black_coffee_unsweetened': 0.0,
  };

  /// Resolves caffeine in mg per 100 ml (or 100 g).
  ///
  /// Checks the explicit catalog barcode first, then falls back to normalized
  /// product name matching.
  static double? lookupCaffeine(String? barcode, [String? name]) {
    if (barcode != null && barcode.isNotEmpty) {
      final direct = knownBlsCaffeineMap[barcode];
      if (direct != null) return direct;
    }

    if (name == null || name.isEmpty) return null;
    final lower = name.toLowerCase();

    // 1. Explicitly decaffeinated foods
    if (lower.contains('entkoffeiniert') ||
        lower.contains('koffeinfrei') ||
        lower.contains('decaffeinated') ||
        lower.contains('decaf') ||
        lower.contains('senza caffeina') ||
        lower.contains('décaféiné')) {
      return 0.0;
    }

    // 2. Grain / herbal coffee substitutes
    if (lower.contains('kaffeeersatz') ||
        lower.contains('zichorienkaffee') ||
        lower.contains('malzkaffee') ||
        lower.contains('getreidekaffee') ||
        lower.contains('chicory coffee')) {
      return 0.0;
    }

    // 3. Caffeine explicitly stated in name
    if (lower.contains('koffeinhaltig') || lower.contains('caffeinated')) {
      if (lower.contains('cola')) return 10.0;
      return 15.0;
    }

    // 4. Energy drinks
    if (lower.contains('energy drink') ||
        lower.contains('energy-drink') ||
        lower.contains('energydrink') ||
        lower.contains('monster energy') ||
        lower.contains('red bull')) {
      return 32.0;
    }

    // 5. Espresso / concentrated coffees
    if (lower.contains('espresso')) return 212.0;
    if (lower.contains('ristretto')) return 250.0;
    if (lower.contains('mokka') || lower.contains('moka')) return 100.0;
    if (lower.contains('cold brew') || lower.contains('cold-brew')) return 50.0;
    if (lower.contains('instantkaffeepulver')) return 3000.0;

    // 6. Regular coffee
    if (lower.contains('kaffee') ||
        lower.contains('coffee') ||
        lower.contains('caffè') ||
        lower.contains('café')) {
      if (lower.contains('koffeinreduziert') ||
          lower.contains('caffeine-reduced')) {
        return 10.0;
      }
      if (lower.contains('eiskaffee')) return 30.0;
      if (lower.contains('instant')) return 35.0;
      return 40.0;
    }

    // 7. Teas & Mate
    if (lower.contains('mate-tee') ||
        lower.contains('mate tee') ||
        lower.contains('yerba mate') ||
        lower.contains('mate-getränk') ||
        lower.contains('club mate')) {
      return 35.0;
    }
    if (lower.contains('pu-erh') || lower.contains('puerh')) return 30.0;
    if (lower.contains('oolong')) return 25.0;
    if (lower.contains('schwarztee') ||
        lower.contains('schwarzer tee') ||
        lower.contains('black tea') ||
        lower.contains('earl grey')) {
      return 20.0;
    }
    if (lower.contains('grüntee') ||
        lower.contains('grüner tee') ||
        lower.contains('green tea') ||
        lower.contains('matcha')) {
      return 15.0;
    }
    if (lower.contains('weißtee') ||
        lower.contains('weißer tee') ||
        lower.contains('white tea')) {
      return 10.0;
    }
    if (lower.contains('eistee') ||
        lower.contains('iced tea') ||
        lower.contains('ice tea')) {
      return 5.0;
    }

    // 8. Colas
    if (lower.contains('cola') || lower.contains('coke')) {
      if (lower.contains('misch') || lower.contains('spezi')) return 6.5;
      return 10.0;
    }

    return null;
  }

  /// Determines whether an item is likely caffeinated (> 0 mg).
  static bool isLikelyCaffeinated(String? barcode, [String? name]) {
    final value = lookupCaffeine(barcode, name);
    return value != null && value > 0;
  }
}
