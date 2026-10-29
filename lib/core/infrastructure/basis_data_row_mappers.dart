import 'package:drift/drift.dart' as drift;

import '../../config/app_data_sources.dart';
import '../../data/drift_database.dart' as db;
import '../../services/base_food_language_service.dart';
import 'caffeine_catalog_resolver.dart';

/// Type alias for food category companion to match category mapping terminology.
typedef CategoriesCompanion = db.FoodCategoriesCompanion;

/// Holds raw primitives for one exercise row (isolate-safe), or mapped Drift companions.
class ExerciseBundle {
  final Map<String, dynamic> exerciseFields;
  final List<Map<String, dynamic>> translationFields;
  final db.ExercisesCompanion? exercise;
  final db.ExerciseTranslationsCompanion? translation;

  const ExerciseBundle({
    this.exerciseFields = const {},
    this.translationFields = const [],
    this.exercise,
    this.translation,
  });
}

/// Static mappers and parsers for transforming raw catalog asset rows into Drift companions.
class BasisDataRowMappers {
  static int parseInt(dynamic value) => (value as num?)?.toInt() ?? 0;
  static double parseDouble(dynamic value) =>
      (value as num?)?.toDouble() ?? 0.0;
  static String parseString(dynamic value) => value?.toString() ?? '';

  static String? nullableString(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Nullable sibling of [parseDouble].
  ///
  /// `exercise_muscles.contribution` is deliberately shipped unset, and the
  /// existing helper would turn that into a real 0.0 — a weight of zero rather
  /// than an absent weight.
  static double? parseNullableDouble(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().trim());
  }

  static bool parseBool(Object? raw) {
    if (raw == null) return false;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final text = raw.toString().trim().toLowerCase();
    return text == '1' || text == 'true';
  }

  /// Reads an optional text column out of a mapped asset row.
  ///
  /// Returns `Absent` when the asset has no such column at all, and a real
  /// null when the asset carries the column but leaves it empty. Collapsing
  /// the two would let a v1 asset wipe classification a v2 import had already
  /// written — the catalog falls back to the bundled asset on every remote
  /// failure, so that is a normal Tuesday, not a corner case.
  static drift.Value<String?> optionalText(
    Map<String, dynamic> fields,
    String column,
  ) {
    if (!fields.containsKey(column)) return const drift.Value.absent();
    final raw = fields[column];
    if (raw == null) return const drift.Value(null);
    final text = raw.toString().trim();
    return drift.Value(text.isEmpty ? null : text);
  }

  static drift.Value<bool> optionalBool(
    Map<String, dynamic> fields,
    String column,
  ) {
    if (!fields.containsKey(column)) return const drift.Value.absent();
    final raw = fields[column];
    if (raw == null) return const drift.Value(false);
    if (raw is bool) return drift.Value(raw);
    if (raw is num) return drift.Value(raw != 0);
    final text = raw.toString().trim().toLowerCase();
    return drift.Value(text == '1' || text == 'true');
  }

  /// Catalog schema v2 columns on `exercises`, copied straight through.
  ///
  /// `image_path` is deliberately absent: it exists in both the asset and the
  /// Drift table, has never been read by this importer, and the catalog ships
  /// it empty. Adding it here would only make a dead contract look alive.
  static const List<String> v2ExerciseColumns = [
    'status',
    'merged_into',
    'modality',
    'mechanic',
    'force_vector',
    'movement_pattern',
    'laterality',
    'difficulty',
    'tracking_type',
    'load_mode',
    'supports_added_weight',
    'primary_equipment',
    'body_region',
  ];

  static db.ProductsCompanion mapProductRow(
    Map<String, dynamic> row, {
    required String sourceLabel,
    String? preferredLanguage,
  }) {
    var barcode = parseString(row['barcode']);
    String id;
    if (row['id'] != null) {
      id = parseString(row['id']);
    } else if (barcode.isNotEmpty) {
      id = 'manual_$barcode';
    } else {
      id = 'manual_${parseString(row['name']).replaceAll(RegExp(r'\s+'), '')}';
    }

    if (barcode.isEmpty) {
      barcode = id;
    }

    // Always persist both language variants when available.
    final rawNameDe = row['name_de']?.toString();
    final rawNameEn = row['name_en']?.toString();
    final rawNameFr = row['name_fr']?.toString();
    final rawNameIt = row['name_it']?.toString();
    final rawNameJa = row['name_ja']?.toString();
    final rawNameEs = row['name_es']?.toString();
    final rawNameNl = row['name_nl']?.toString();
    final rawName = row['name']?.toString() ?? '';

    // Select the display name (for the legacy `name` column) based on preference.
    String displayName;
    if (preferredLanguage == 'en') {
      displayName = parseString(rawNameEn ?? rawNameDe ?? rawName);
    } else if (preferredLanguage == 'fr') {
      displayName = parseString(rawNameFr ?? rawNameEn ?? rawNameDe ?? rawName);
    } else if (preferredLanguage == 'it') {
      displayName = parseString(rawNameIt ?? rawNameEn ?? rawNameDe ?? rawName);
    } else if (preferredLanguage == 'ja') {
      displayName = parseString(rawNameJa ?? rawNameEn ?? rawNameDe ?? rawName);
    } else if (preferredLanguage == 'es') {
      displayName = parseString(rawNameEs ?? rawNameEn ?? rawNameDe ?? rawName);
    } else if (preferredLanguage == 'nl') {
      displayName = parseString(rawNameNl ?? rawNameEn ?? rawNameDe ?? rawName);
    } else {
      displayName = parseString(rawNameDe ?? rawNameEn ?? rawName);
    }

    // ── is_fluid three-tier heuristic ────────────────────────────────────────
    //
    // Tier 1 – Allowlist: category tag contains a known beverage substring
    //          → candidate is_fluid = true.
    // Tier 2 – Blocklist: category tag exactly matches a non-beverage tag
    //          → veto is_fluid = false (overrides Tier 1).
    // Tier 3 – Volume-unit fallback: only when NO category data is available;
    //          product_quantity_unit in {ml, l, cl} → is_fluid = true.
    //
    // This mirrors the resolve_is_fluid() function in create_off_food_db.py.
    // Keep both in sync when adding new tags.
    // ─────────────────────────────────────────────────────────────────────────

    bool isFluidVal = false;

    // Read category tag blob — may come from the OFF API as a tag list string.
    final rawCategory =
        row['category'] ?? row['categories'] ?? row['categories_tags'];
    final categoryStr =
        rawCategory != null ? rawCategory.toString().toLowerCase() : '';

    // Split the flat string into individual tags, stripping blanks.
    final cats = categoryStr
        .split(RegExp(r'[,\s]+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (cats.isNotEmpty) {
      // ── Tier 1: allowlist (substring match) ──────────────────────────────
      const beverageAllowlistSubstrings = [
        'en:beverages',
        'en:beverages-and-beverages-preparations',
        'en:non-alcoholic-beverages',
        'en:hot-beverages',
        'en:cold-beverages',
        'en:plant-based-beverages',
        'en:carbonated-beverages',
        'en:waters',
        'en:mineral-waters',
        'en:sparkling-waters',
        'en:still-waters',
        'en:spring-waters',
        'en:flavoured-waters',
        'en:vitamin-waters',
        'en:coconut-waters',
        'en:fruit-juices',
        'en:vegetable-juices',
        'en:juices',
        'en:soft-drinks',
        'en:sodas',
        'en:colas',
        'en:lemonades',
        'en:energy-drinks',
        'en:sports-drinks',
        'en:electrolyte-drinks',
        'en:isotonic-drinks',
        'en:teas',
        'en:herbal-teas',
        'en:iced-teas',
        'en:coffees',
        'en:instant-coffees',
        'en:coffee-beverages',
        'en:alcoholic-beverages',
        'en:beers',
        'en:wines',
        'en:spirits',
        'en:liqueurs',
        'en:ciders',
        'en:champagnes',
        'en:proseccos',
        'en:plant-based-milks',
        'en:oat-milks',
        'en:soy-milks',
        'en:rice-milks',
        'en:almond-milks',
        'en:coconut-milks',
        'en:drinkable-yogurts',
        'en:flavoured-milks',
        'en:milks',
        'en:smoothies',
        'en:fruit-smoothies',
        'en:vegetable-smoothies',
        'en:baby-drinks',
        'en:drinking-waters',
        'en:kombucha',
        'en:kefir-drinks',
        'en:drinks',
      ];

      // ── Tier 2: blocklist (exact tag match) ──────────────────────────────
      const nonBeverageBlocklistTags = {
        'en:condiments',
        'en:sauces',
        'en:hot-sauces',
        'en:soy-sauces',
        'en:tomato-sauces',
        'en:barbecue-sauces',
        'en:pasta-sauces',
        'en:curry-sauces',
        'en:vegan-sauces',
        'en:vegetarian-sauces',
        'en:dessert-sauces',
        'en:burger-sauces',
        'en:sweet-and-sour-sauces',
        'en:bechamel-sauces',
        'en:worcestershire-sauces',
        'en:teriyaki-sauces',
        'en:nuoc-mam-sauce',
        'en:fish-sauces',
        'en:chili-sauces',
        'en:pepper-sauces',
        'en:cooking-sauces',
        'en:salad-dressings',
        'en:vinaigrettes',
        'en:mayonnaises',
        'en:light-mayonnaises',
        'en:egg-free-mayonnaises',
        'en:aiolis',
        'en:dips',
        'en:ketchup',
        'en:tomato-ketchup',
        'en:mustards',
        'en:vinegars',
        'en:balsamic-vinegars',
        'en:cider-vinegars',
        'en:rice-vinegars',
        'en:wine-vinegars',
        'en:sherry-vinegars',
        'en:glazes-with-vinegar',
        'en:soups',
        'en:canned-soups',
        'en:reheatable-soups',
        'en:fish-soups',
        'en:broths',
        'en:liquid-broths',
        'en:cream-of-vegetable-soups',
        'en:desserts',
        'en:dairy-desserts',
        'en:frozen-desserts',
        'en:ice-creams-and-sorbets',
        'en:ice-creams',
        'en:ice-cream-tubs',
        'en:ice-cream-bars',
        'en:ice-cream-cones',
        'en:ice-cream-sandwiches',
        'en:ice-cream-in-a-box',
        'en:sorbets',
        'en:ice-pops',
        'en:frozen-yogurts',
        'en:creams',
        'en:uht-creams',
        'en:whipped-creams',
        'en:unfermented-creams',
        'en:compound-dairy-creams',
        'en:cooking-creams',
        'en:spreads',
        'en:sweet-spreads',
        'en:plant-based-spreads',
        'en:nut-butters',
        'en:peanut-butters',
        'en:fats',
        'en:cooking-fats',
        'en:oils',
        'en:olive-oils',
        'en:simple-syrups',
        'en:maple-syrups',
        'en:agave-syrups',
        'en:toppings-ingredients',
        'en:snacks',
        'en:salty-snacks',
        'en:sweet-snacks',
        'en:frozen-foods',
        'en:groceries',
        'en:meals',
        'en:canned-meals',
        'en:canned-foods',
        'en:dried-meals',
        'en:dried-products',
        'en:dried-products-to-be-rehydrated',
        'en:dietary-supplements',
        'en:food-additives',
        'en:sweeteners',
        'en:sugar-substitutes',
        'en:tabletop-sweeteners',
        'en:artificial-sugar-substitutes',
        'en:flavors',
        'en:cooking-helpers',
        'en:non-food-products',
        'en:perfumes',
        'en:oil-perfumes',
        'en:bodybuilding-supplements',
      };

      final isCandidate = cats.any(
        (cat) => beverageAllowlistSubstrings.any((sub) => cat.contains(sub)),
      );
      final isBlocked =
          cats.any((cat) => nonBeverageBlocklistTags.contains(cat));

      if (isBlocked) {
        isFluidVal = false;
      } else if (isCandidate) {
        isFluidVal = true;
      }
      // else: category data present but no signal → conservative false
    } else {
      // Tier 3: no category data — fall back to volume unit
      final nutritionPer = (row['nutrition_data_prepared_per'] ??
              row['nutrition_data_per'] ??
              row['nutrition_baseline'] ??
              row['nutrition_baseline_key'])
          ?.toString()
          .toLowerCase()
          .trim();
      final unit =
          row['product_quantity_unit']?.toString().toLowerCase().trim() ?? '';
      if (nutritionPer != null && nutritionPer.contains('100ml')) {
        isFluidVal = true;
      } else if (unit == 'ml' || unit == 'l' || unit == 'cl') {
        isFluidVal = true;
      }
    }

    return db.ProductsCompanion(
      id: drift.Value(id),
      barcode: drift.Value(barcode),
      name: drift.Value(displayName),
      nameDe: drift.Value(rawNameDe),
      nameEn: drift.Value(rawNameEn),
      nameFr: drift.Value(rawNameFr),
      nameIt: drift.Value(rawNameIt),
      nameJa: drift.Value(rawNameJa),
      nameEs: drift.Value(rawNameEs),
      nameNl: drift.Value(rawNameNl),
      categoryEs: drift.Value(row['category_es']?.toString()),
      categoryNl: drift.Value(row['category_nl']?.toString()),
      brand: drift.Value(parseString(row['brand'])),
      calories: drift.Value(parseInt(row['calories'])),
      protein: drift.Value(parseDouble(row['protein'])),
      carbs: drift.Value(parseDouble(row['carbs'])),
      fat: drift.Value(parseDouble(row['fat'])),
      sugar: drift.Value(parseDouble(row['sugar'])),
      fiber: drift.Value(parseDouble(row['fiber'])),
      salt: drift.Value(parseDouble(row['salt'])),
      caffeine: drift.Value(parseNullableDouble(row['caffeine_mg_per_100ml'] ??
              row['caffeine'] ??
              row['caffeine_mg_per_100g']) ??
          CaffeineCatalogResolver.lookupCaffeine(
              barcode, rawNameDe ?? displayName)),
      caffeineMgPer100g: drift.Value(parseNullableDouble(
              row['caffeine_mg_per_100g'] ??
                  row['caffeine_mg_per_100ml'] ??
                  row['caffeine']) ??
          CaffeineCatalogResolver.lookupCaffeine(
              barcode, rawNameDe ?? displayName)),
      ingredientsText: drift.Value(
          sourceLabel == 'base' ? null : row['ingredients_text']?.toString()),
      ingredientsAnalysisTags:
          drift.Value(row['ingredients_analysis_tags']?.toString()),
      additivesTags: drift.Value(row['additives_tags']?.toString()),
      productQuantity: drift.Value(parseDouble(row['product_quantity'])),
      productQuantityUnit:
          drift.Value(row['product_quantity_unit']?.toString()),
      isFluid: drift.Value(isFluidVal),
      source: drift.Value(sourceLabel),
      isLiquid: drift.Value(parseInt(row['is_liquid']) == 1),
      category: drift.Value(row['category']?.toString()),
    );
  }

  static db.FoodCategoriesCompanion mapCategoryRow(Map<String, dynamic> row) {
    return db.FoodCategoriesCompanion(
      key: drift.Value(parseString(row['key'])),
      nameDe: drift.Value(row['name_de'] as String?),
      nameEn: drift.Value(row['name_en'] as String?),
      nameFr: drift.Value(row['name_fr'] as String?),
      nameIt: drift.Value(row['name_it'] as String?),
      nameJa: drift.Value(row['name_ja'] as String?),
      nameEs: drift.Value(row['name_es'] as String?),
      nameNl: drift.Value(row['name_nl'] as String?),
      emoji: drift.Value(row['emoji'] as String?),
    );
  }

  /// Maps a flat exercise asset row to an [ExerciseBundle] containing
  /// the structural exercise fields and derived translation rows.
  ///
  /// Handles both legacy flat format (name_de, name_en columns) and
  /// future relational format (exercise_translations sub-rows).
  static ExerciseBundle mapExerciseBundle(Map<String, dynamic> row) {
    final id = parseString(row['id']);

    final exerciseFields = <String, dynamic>{
      'id': id,
      // v1 compatibility columns. Still the only muscle source until the app
      // reads exercise_muscles, so they keep being written even on a v2 asset.
      'category_name': parseString(row['category_name']),
      'muscles_primary': parseString(row['muscles_primary']),
      'muscles_secondary': parseString(row['muscles_secondary']),
      // v2 classification. Absent on a v1 asset — `containsKey` rather than a
      // default, so "the asset has no opinion" stays distinguishable from "the
      // asset says null".
      for (final column in v2ExerciseColumns)
        if (row.containsKey(column)) column: row[column],
    };

    // Build translation rows. Support both flat (legacy) and
    // future relational format from the updated Python pipeline.
    final translations = <Map<String, dynamic>>[];

    void addTranslation(String langCode, dynamic name, dynamic description) {
      final n = parseString(name);
      if (n.isEmpty) return;
      translations.add({
        'exercise_id': id,
        'language_code': langCode,
        'name': n,
        'description': description?.toString(),
      });
    }

    // Flat-column format (current wger asset DB).
    // FIX: The fallback order for 'de' is intentionally de→en so that
    // exercises with only an English name still get a valid DE translation row
    // (the searchExercises COALESCE prefers t_de). Equally, 'en' falls back
    // to 'de' so that exercises with only a German name remain searchable in
    // English-locale environments.
    if (row.containsKey('name_de') || row.containsKey('name_en')) {
      addTranslation(
          'de', row['name_de'] ?? row['name_en'], row['description_de']);
      addTranslation('en', row['name_en'] ?? row['name_de'],
          row['description_en'] ?? row['description_de']);
      addTranslation('fr', row['name_fr'] ?? row['name_en'] ?? row['name_de'],
          row['description_fr']);
      addTranslation('it', row['name_it'] ?? row['name_en'] ?? row['name_de'],
          row['description_it']);
      addTranslation('ja', row['name_ja'] ?? row['name_en'] ?? row['name_de'],
          row['description_ja']);
    }

    return ExerciseBundle(
      exerciseFields: exerciseFields,
      translationFields: translations,
    );
  }

  /// Resolve the language code for base food import without a BuildContext.
  static String resolveBaseFoodLangCode({
    BaseFoodLanguage? choice,
    OffCatalogCountry? offCountry,
    String? preferredLanguage,
    List<String>? availableLanguages,
    String defaultLanguage = 'de',
  }) {
    if (choice != null && offCountry != null) {
      if (choice == BaseFoodLanguage.en) return 'en';
      if (choice == BaseFoodLanguage.de) return 'de';
      if (choice == BaseFoodLanguage.fr) return 'fr';
      if (choice == BaseFoodLanguage.it) return 'it';
      if (choice == BaseFoodLanguage.ja) return 'ja';
      if (choice == BaseFoodLanguage.es) return 'es';
      if (choice == BaseFoodLanguage.nl) return 'nl';
      // Auto: derive from the food DB region.
      return switch (offCountry) {
        OffCatalogCountry.us ||
        OffCatalogCountry.uk ||
        OffCatalogCountry.au =>
          'en',
        OffCatalogCountry.de ||
        OffCatalogCountry.ch ||
        OffCatalogCountry.at =>
          'de',
        OffCatalogCountry.fr => 'fr',
        OffCatalogCountry.it => 'it',
        OffCatalogCountry.jp => 'ja',
        OffCatalogCountry.nl => 'nl',
        OffCatalogCountry.es => 'es',
      };
    }
    if (preferredLanguage != null) {
      if (availableLanguages != null &&
          availableLanguages.contains(preferredLanguage)) {
        return preferredLanguage;
      }
      return defaultLanguage;
    }
    return defaultLanguage;
  }
}
