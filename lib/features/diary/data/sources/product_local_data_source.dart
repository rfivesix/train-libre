// lib/data/product_database_helper.dart

import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import '../../../../data/database_helper.dart';
import '../../../../data/drift_database.dart' as db;
import '../../../../config/app_data_sources.dart';
import '../../domain/models/food_item.dart';
import '../../../../services/catalog_file_migration.dart';
import '../../../../util/perf_debug_timer.dart';
import '../../domain/use_cases/evaluate_food_source_use_case.dart';

/// Helper class for managing food product data in the Drift database.
///
/// Provides methods for searching products, managing favorites, and retrieving
/// base foods from the katalog.
class ProductLocalDataSource {
  final db.AppDatabase _dbInstance;

  ProductLocalDataSource(this._dbInstance);

  static ProductLocalDataSource get instance =>
      DatabaseHelper.instance.productLocalDataSource;

  db.AppDatabase get dbInstance => _dbInstance;

  ProductLocalDataSource.forTesting(this._dbInstance);

  // Access to the central Drift instance
  Future<db.AppDatabase> get database async {
    return _dbInstance;
  }

  // --- MAPPING HELPERS ---

  List<String>? _parseJsonList(String? json) {
    if (json == null || json.isEmpty) return null;
    if (json.startsWith('[') && json.endsWith(']')) {
      return json
          .substring(1, json.length - 1)
          .split(',')
          .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ""))
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [json];
  }

  db.ProductsCompanion _mapModelToCompanion(FoodItem item) {
    return db.ProductsCompanion(
      id: item.id != null ? Value(item.id!) : const Value.absent(),
      barcode: Value(item.barcode),
      name: Value(item.name),
      nameDe: Value(item.nameDe),
      nameEn: Value(item.nameEn),
      nameFr: Value(item.nameFr),
      nameIt: Value(item.nameIt),
      nameJa: Value(item.nameJa),
      brand: Value(item.brand),
      calories: Value(item.calories),
      protein: Value(item.protein),
      carbs: Value(item.carbs),
      fat: Value(item.fat),
      sugar: Value(item.sugar),
      fiber: Value(item.fiber),
      salt: Value(item.salt),
      caffeine: Value(item.caffeineMgPer100ml),
      caffeineMgPer100g: Value(item.caffeineMgPer100g),
      ingredientsText: Value(item.ingredientsText),
      ingredientsAnalysisTags: Value(_listToJson(item.ingredientsAnalysisTags)),
      additivesTags: Value(_listToJson(item.additivesTags)),
      productQuantity: Value(item.productQuantity),
      productQuantityUnit: Value(item.productQuantityUnit),
      isFluid: Value(item.isFluid),
      isLiquid: Value(item.isLiquid ?? false),
      source: Value(_sourceToString(item.source)),
      category: Value(item.category),
    );
  }

  String? _listToJson(List<String>? list) {
    if (list == null) return null;
    return '[${list.map((e) => '"$e"').join(',')}]';
  }

  String _sourceToString(FoodItemSource source) {
    switch (source) {
      case FoodItemSource.base:
        return 'base';
      case FoodItemSource.off:
        return 'off';
      case FoodItemSource.user:
        return 'user';
    }
  }

  FoodItem _mapRowAndOverrideToFoodItem(
      db.Product row, db.UserFoodOverride? overrideRow) {
    FoodItemSource source;
    switch (row.source) {
      case 'base':
        source = FoodItemSource.base;
        break;
      case 'off':
      case 'off_retained':
        source = FoodItemSource.off;
        break;
      default:
        source = FoodItemSource.user;
    }

    return FoodItem(
      id: row.id,
      barcode: row.barcode,
      name: overrideRow?.name ?? row.name,
      nameDe: overrideRow?.name ?? row.nameDe ?? row.name,
      nameEn: overrideRow?.name ?? row.nameEn ?? row.name,
      nameFr: overrideRow?.name ?? row.nameFr ?? row.name,
      nameIt: overrideRow?.name ?? row.nameIt ?? row.name,
      nameJa: overrideRow?.name ?? row.nameJa ?? row.name,
      brand: overrideRow?.brand ?? row.brand ?? '',
      calories: overrideRow?.calories ?? row.calories,
      protein: overrideRow?.protein ?? row.protein,
      carbs: overrideRow?.carbs ?? row.carbs,
      fat: overrideRow?.fat ?? row.fat,
      source: source,
      category: overrideRow?.category ?? row.category,
      sugar: overrideRow?.sugar ?? row.sugar,
      fiber: overrideRow?.fiber ?? row.fiber,
      salt: overrideRow?.salt ?? row.salt,
      sodium: (overrideRow?.salt ?? row.salt) != null
          ? (overrideRow?.salt ?? row.salt)! / 2.5
          : null,
      kj: ((overrideRow?.calories ?? row.calories) * 4.184),
      calcium: null,
      isLiquid: overrideRow?.isLiquid ?? row.isLiquid,
      isFluid: overrideRow?.isFluid ?? row.isFluid,
      caffeineMgPer100ml: overrideRow?.caffeine ?? row.caffeine,
      caffeineMgPer100g:
          overrideRow?.caffeineMgPer100g ?? row.caffeineMgPer100g,
      ingredientsText: overrideRow?.ingredientsText ?? row.ingredientsText,
      ingredientsAnalysisTags: _parseJsonList(
          overrideRow?.ingredientsAnalysisTags ?? row.ingredientsAnalysisTags),
      additivesTags:
          _parseJsonList(overrideRow?.additivesTags ?? row.additivesTags),
      productQuantity: overrideRow?.productQuantity ?? row.productQuantity,
      productQuantityUnit:
          overrideRow?.productQuantityUnit ?? row.productQuantityUnit,
    );
  }

  FoodItem _mapArchiveRowToFoodItem(db.OffProductsArchiveData row) {
    FoodItemSource source;
    switch (row.source) {
      case 'base':
        source = FoodItemSource.base;
        break;
      case 'off':
        source = FoodItemSource.off;
        break;
      default:
        source = FoodItemSource.user;
    }

    return FoodItem(
      id: row.id,
      barcode: row.barcode,
      name: row.productName,
      nameDe: row.productName,
      nameEn: row.productName,
      nameFr: row.productName,
      nameIt: row.productName,
      nameJa: row.productName,
      brand: row.brand ?? '',
      calories: row.calories,
      protein: row.protein,
      carbs: row.carbs,
      fat: row.fat,
      source: source,
      category: row.category,
      sugar: row.sugar,
      fiber: row.fiber,
      salt: row.salt,
      sodium: row.salt != null ? row.salt! / 2.5 : null,
      kj: row.calories * 4.184,
      calcium: null,
      isLiquid: row.isLiquid,
      isFluid: row.isFluid,
      caffeineMgPer100ml: row.caffeine,
      caffeineMgPer100g: row.caffeineMgPer100g,
      ingredientsText: null,
      ingredientsAnalysisTags: const [],
      additivesTags: const [],
      productQuantity: row.productQuantity,
      productQuantityUnit: row.productQuantityUnit,
    );
  }

  Future<List<FoodItem>> _enrichProductsWithOverrides(
      List<db.Product> rows) async {
    if (rows.isEmpty) return [];
    final dbInstance = await database;
    final barcodes = rows.map((r) => r.barcode).toList();

    final overrides = await (dbInstance.select(dbInstance.userFoodOverrides)
          ..where((tbl) => tbl.barcode.isIn(barcodes)))
        .get();

    final overrideMap = {for (final o in overrides) o.barcode: o};

    return rows.map((row) {
      final o = overrideMap[row.barcode];
      return _mapRowAndOverrideToFoodItem(row, o);
    }).toList();
  }

  // --- PUBLIC API ---

  /// Inserts a new product into the database or replaces an existing one with the same barcode.
  Future<void> insertProduct(FoodItem item) async {
    final dbInstance = await database;
    await dbInstance
        .into(dbInstance.products)
        .insert(_mapModelToCompanion(item), mode: InsertMode.insertOrReplace);
  }

  /// Updates an existing product's information in the database.
  Future<void> updateProduct(FoodItem item) async {
    final dbInstance = await database;
    await (dbInstance.update(dbInstance.products)
          ..where((tbl) => tbl.barcode.equals(item.barcode)))
        .write(_mapModelToCompanion(item));

    final existingOverride =
        await (dbInstance.select(dbInstance.userFoodOverrides)
              ..where((tbl) => tbl.barcode.equals(item.barcode)))
            .getSingleOrNull();

    final overrideCompanion = db.UserFoodOverridesCompanion(
      localId: existingOverride != null
          ? Value(existingOverride.localId)
          : const Value.absent(),
      id: existingOverride != null
          ? Value(existingOverride.id)
          : const Value.absent(),
      barcode: Value(item.barcode),
      name: Value(item.name),
      brand: Value(item.brand),
      calories: Value(item.calories),
      protein: Value(item.protein),
      carbs: Value(item.carbs),
      fat: Value(item.fat),
      sugar: Value(item.sugar),
      fiber: Value(item.fiber),
      salt: Value(item.salt),
      caffeine: Value(item.caffeineMgPer100ml),
      caffeineMgPer100g: Value(item.caffeineMgPer100g),
      ingredientsText: Value(item.ingredientsText),
      ingredientsAnalysisTags: Value(_listToJson(item.ingredientsAnalysisTags)),
      additivesTags: Value(_listToJson(item.additivesTags)),
      productQuantity: Value(item.productQuantity),
      productQuantityUnit: Value(item.productQuantityUnit),
      isFluid: Value(item.isFluid),
      isLiquid: Value(item.isLiquid ?? false),
      category: Value(item.category),
    );

    await dbInstance
        .into(dbInstance.userFoodOverrides)
        .insertOnConflictUpdate(overrideCompanion);
  }

  /// Retrieves a list of [FoodItem]s matching the provided [barcodes].
  Future<List<FoodItem>> getProductsByBarcodes(List<String> barcodes) async {
    if (barcodes.isEmpty) return [];
    final stopwatch = Stopwatch()..start();
    final dbInstance = await database;

    final rows = await (dbInstance.select(
      dbInstance.products,
    )..where((tbl) => tbl.barcode.isIn(barcodes)))
        .get();

    final result = await _enrichProductsWithOverrides(rows);
    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getProductsByBarcodes',
      elapsed: stopwatch.elapsed,
      fields: {'barcodes': barcodes.length, 'rows': rows.length},
    );
    return result;
  }

  /// Retrieves a map of [localId] to [FoodItem]s matching the provided [archiveLocalIds].
  Future<Map<int, FoodItem>> getProductsByArchiveIds(
      List<int> archiveLocalIds) async {
    if (archiveLocalIds.isEmpty) return {};
    final stopwatch = Stopwatch()..start();
    final dbInstance = await database;

    final rows = await (dbInstance.select(dbInstance.offProductsArchive)
          ..where((tbl) => tbl.localId.isIn(archiveLocalIds)))
        .get();

    final barcodesSet = <String>{};
    for (final r in rows) {
      if (r.barcode.isNotEmpty) barcodesSet.add(r.barcode);
    }

    final products = barcodesSet.isEmpty
        ? <db.Product>[]
        : await (dbInstance.select(dbInstance.products)
              ..where((tbl) => tbl.barcode.isIn(barcodesSet)))
            .get();

    final productMap = {for (final p in products) p.barcode: p};

    final result = <int, FoodItem>{};
    for (final row in rows) {
      var item = _mapArchiveRowToFoodItem(row);
      final prod = productMap[item.barcode];
      if (prod != null) {
        item = item.copyWithNames(
          nameDe: prod.nameDe ?? item.nameDe,
          nameEn: prod.nameEn ?? item.nameEn,
          nameFr: prod.nameFr ?? item.nameFr,
          nameIt: prod.nameIt ?? item.nameIt,
          nameJa: prod.nameJa ?? item.nameJa,
        );
      }
      result[row.localId] = item;
    }

    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getProductsByArchiveIds',
      elapsed: stopwatch.elapsed,
      fields: {'ids': archiveLocalIds.length, 'rows': rows.length},
    );
    return result;
  }

  /// Retrieves recently used products based on the user's consumption history.
  Future<List<FoodItem>> getRecentProducts() async {
    final dbInstance = await database;

    final maxDate = dbInstance.nutritionLogs.consumedAt.max();
    final query = dbInstance.selectOnly(dbInstance.nutritionLogs)
      ..addColumns([dbInstance.nutritionLogs.legacyBarcode, maxDate])
      ..groupBy([dbInstance.nutritionLogs.legacyBarcode])
      ..orderBy([
        OrderingTerm(expression: maxDate, mode: OrderingMode.desc),
      ])
      ..limit(100);

    final result = await query.get();

    final recentBarcodes = result
        .map((row) => row.read(dbInstance.nutritionLogs.legacyBarcode))
        .where((bc) => bc != null)
        .cast<String>()
        .toList();

    final products = await getProductsByBarcodes(recentBarcodes);

    // Sort products to match the exact descending order of recentBarcodes
    final barcodeToIndex = {
      for (var i = 0; i < recentBarcodes.length; i++) recentBarcodes[i]: i
    };
    products.sort((a, b) {
      final indexA = barcodeToIndex[a.barcode] ?? 9999;
      final indexB = barcodeToIndex[b.barcode] ?? 9999;
      return indexA.compareTo(indexB);
    });

    return products;
  }

  /// Retrieves all food categories from the database.
  Future<List<Map<String, dynamic>>> getBaseCategories() async {
    final db = await database;
    final rows = await (db.select(
      db.foodCategories,
    )..orderBy([(t) => OrderingTerm(expression: t.key)]))
        .get();

    return rows.map((row) {
      return {
        'key': row.key,
        'name_de': row.nameDe,
        'name_en': row.nameEn,
        'name_fr': row.nameFr,
        'name_it': row.nameIt,
        'name_ja': row.nameJa,
        'emoji': row.emoji,
      };
    }).toList();
  }

  /// Retrieves base foods from the katalog, optionally filtered by [categoryKey] or [search] term.
  Future<List<FoodItem>> getBaseFoods({
    String? categoryKey,
    int limit = 100,
    String? search,
  }) async {
    final db = await database;

    var query = db.select(db.products)
      ..where((t) => t.source.equals('base'))
      ..limit(limit);

    if (categoryKey != null) {
      query = query..where((t) => t.category.equals(categoryKey));
    }

    if (search != null && search.isNotEmpty) {
      final term = search.trim();
      query = query
        ..where(
          (t) =>
              t.name.like('%$term%') |
              t.nameDe.like('%$term%') |
              t.nameEn.like('%$term%') |
              t.nameFr.like('%$term%') |
              t.nameIt.like('%$term%') |
              t.nameJa.like('%$term%') |
              t.brand.like('%$term%'),
        );

      query = query
        ..orderBy([
          (t) => OrderingTerm(
                expression: CaseWhenExpression<int>(
                  cases: [
                    CaseWhen(
                        t.name.equals(term) |
                            t.nameDe.equals(term) |
                            t.nameEn.equals(term) |
                            t.nameFr.equals(term) |
                            t.nameIt.equals(term) |
                            t.nameJa.equals(term),
                        then: const Constant(0)),
                    CaseWhen(
                        t.name.like('$term%') |
                            t.nameDe.like('$term%') |
                            t.nameEn.like('$term%') |
                            t.nameFr.like('$term%') |
                            t.nameIt.like('$term%') |
                            t.nameJa.like('$term%'),
                        then: const Constant(1)),
                  ],
                  orElse: const Constant(2),
                ),
                mode: OrderingMode.asc,
              ),
          (t) =>
              OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
          (t) =>
              OrderingTerm(expression: t.name.length, mode: OrderingMode.asc),
        ]);
    } else {
      query = query
        ..orderBy([
          (t) =>
              OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
          (t) =>
              OrderingTerm(expression: t.name.length, mode: OrderingMode.asc),
        ]);
    }

    final rows = await query.get();
    return _enrichProductsWithOverrides(rows);
  }

  List<String> _tokenizeAndClean(String input) {
    final sanitized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9äöüß ]', unicode: true), ' ');
    return sanitized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  /// Performs a global search across user-created, base, and Open Food Facts products.
  Future<List<FoodItem>> searchProducts(String keyword) async {
    final tokens = _tokenizeAndClean(keyword);
    if (tokens.isEmpty) return [];

    final dbInstance = await database;
    const int limit = 50;

    final variables = <Variable>[];

    // Calculate frequency score in SQL using CTEs to avoid O(NxM) correlated subqueries
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final String historyScoreExpr =
        'COALESCE(rbl.score, 0) + COALESCE(ril.score, 0) AS history_priority_score';
    // Must be the first variables because they match the FIRST two `?` in the CTEs!
    variables.add(Variable.withDateTime(thirtyDaysAgo));
    variables.add(Variable.withDateTime(thirtyDaysAgo));

    // Für die Relevanz-Gewichtung im ORDER BY übergeben wir den rohen Suchbegriff
    final rawSearchLower = keyword.trim().toLowerCase();
    variables.add(Variable.withString(rawSearchLower)); // Für exakten Match (Name)
    variables.add(
        Variable.withString(rawSearchLower)); // Für exakten Match (Marke + Name)
    variables.add(
        Variable.withString(rawSearchLower)); // Für exakten Match (Name + Marke)
    variables.add(
        Variable.withString('$rawSearchLower%')); // Für Wortanfang-Match (Name)
    variables.add(Variable.withString(
        '$rawSearchLower%')); // Für Wortanfang-Match (Marke + Name)
    variables.add(Variable.withString(
        '$rawSearchLower%')); // Für Wortanfang-Match (Name + Marke)

    final whereClauses = <String>["p.source IN ('user', 'base', 'off')"];
    for (final token in tokens) {
      // WICHTIGER KNIEFALL FÜR DEN DEUTSCHEN PLURAL:
      // Wenn das Token auf "er" endet (z.B. "eier"), erlauben wir auch den Match auf den Stamm ("ei")
      if (token.endsWith('er') && token.length > 3) {
        final stem = token.substring(0, token.length - 2);
        whereClauses.add(
          '((p.name LIKE ? OR (p.brand IS NOT NULL AND p.brand LIKE ?)) OR '
          '(p.name LIKE ? OR (p.brand IS NOT NULL AND p.brand LIKE ?)))',
        );
        variables.add(Variable.withString('%$token%'));
        variables.add(Variable.withString('%$token%'));
        variables.add(Variable.withString('%$stem%'));
        variables.add(Variable.withString('%$stem%'));
      } else {
        whereClauses.add(
          '(p.name LIKE ? OR (p.brand IS NOT NULL AND p.brand LIKE ?))',
        );
        variables.add(Variable.withString('%$token%'));
        variables.add(Variable.withString('%$token%'));
      }
    }

    final whereSection = whereClauses.join(' AND ');

    final query = '''
      WITH RecentBarcodeLogs AS (
          SELECT legacy_barcode AS barcode, COUNT(*) * 10 AS score
          FROM nutrition_logs
          WHERE consumed_at >= ? AND legacy_barcode IS NOT NULL AND legacy_barcode != ''
          GROUP BY legacy_barcode
      ),
      RecentIdLogs AS (
          SELECT product_id AS id, COUNT(*) * 10 AS score
          FROM nutrition_logs
          WHERE consumed_at >= ? AND product_id IS NOT NULL AND product_id != ''
          GROUP BY product_id
      )
      SELECT p.*,
             $historyScoreExpr,
             (CASE WHEN p.source = 'base' THEN 1 ELSE 0 END) AS is_base_food,
             -- Text-Relevanz-Scores berechnen (Name oder Marke + Name Kombinationen):
             (CASE 
               WHEN LOWER(p.name) = ? 
                 OR LOWER(COALESCE(p.brand, '') || ' ' || p.name) = ? 
                 OR LOWER(p.name || ' ' || COALESCE(p.brand, '')) = ? 
               THEN 1 ELSE 0 
              END) AS is_exact_match,
             (CASE 
               WHEN LOWER(p.name) LIKE ? 
                 OR LOWER(COALESCE(p.brand, '') || ' ' || p.name) LIKE ? 
                 OR LOWER(p.name || ' ' || COALESCE(p.brand, '')) LIKE ? 
               THEN 1 ELSE 0 
              END) AS is_prefix_match
      FROM products p
      LEFT JOIN RecentBarcodeLogs rbl ON rbl.barcode = p.barcode
      LEFT JOIN RecentIdLogs ril ON ril.id = p.id
      WHERE $whereSection
      -- DIE NEUE PRIORISIERUNG:
      -- 1. Exakte Namens- oder Marken-Treffer müssen IMMER ganz nach oben (z.B. wenn ein Produkt exakt "Eier" oder "Rewe Bio Magerquark" heißt)
      -- 2. Wortanfang-Treffer (z.B. "Eiercreme" bei Suche nach "Eier") kommen als nächstes
      -- 3. Erst danach greift die Unterscheidung zwischen Grundnahrungsmittel und OpenFoodFacts
      -- 4. Innerhalb der Blöcke entscheidet deine Historie
      ORDER BY 
        is_exact_match DESC, 
        history_priority_score DESC, 
        is_prefix_match DESC, 
        is_base_food DESC, 
        LENGTH(p.name) ASC,
        p.name ASC
      LIMIT $limit
    ''';

    final rows = await dbInstance.customSelect(
      query,
      variables: variables,
      readsFrom: {dbInstance.products, dbInstance.nutritionLogs},
    ).get();

    final dbProducts =
        rows.map((row) => dbInstance.products.map(row.data)).toList();
    return _enrichProductsWithOverrides(dbProducts);
  }

  /// Retrieves a single product by its [barcode].
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    final db = await database;
    final row = await (db.select(db.products)
          ..where((t) => t.barcode.equals(barcode))
          ..limit(1))
        .getSingleOrNull();

    if (row == null) return null;
    final enriched = await _enrichProductsWithOverrides([row]);
    return enriched.first;
  }

  /// Retrieves all products marked as favorites by the user.
  Future<List<FoodItem>> getFavoriteProducts() async {
    final db = await database;
    final query = db.select(db.products).join([
      innerJoin(
        db.favorites,
        db.favorites.barcode.equalsExp(db.products.barcode),
      ),
    ]);

    final result = await query.get();
    final products = result.map((row) => row.readTable(db.products)).toList();
    return _enrichProductsWithOverrides(products);
  }

  /// Fuzzy-matches an AI-detected food name against the products table,
  /// with optional [catalogSearchTerm] for multi-lingual catalog lookups.
  Future<List<FoodItem>> fuzzyMatchForAi(
    String aiName, {
    String? catalogSearchTerm,
  }) async {
    final candidates = await searchProducts(aiName);
    if (catalogSearchTerm != null &&
        catalogSearchTerm.trim().isNotEmpty &&
        catalogSearchTerm.trim().toLowerCase() !=
            aiName.trim().toLowerCase()) {
      final catalogCandidates = await searchProducts(catalogSearchTerm.trim());
      for (final extra in catalogCandidates) {
        if (!candidates
            .any((c) => c.barcode == extra.barcode && c.id == extra.id)) {
          candidates.add(extra);
        }
      }
    }

    if (candidates.isEmpty) return [];

    const int returnLimit = 5;
    return const EvaluateFoodSourceUseCase().execute(
      candidates: candidates,
      searchTerm: aiName,
      limit: returnLimit,
    );
  }

  /// Returns up to [limit] fuzzy-match candidates for an AI-identified food name,
  /// enriched with macro density profiles for injection into repair prompts.
  ///
  /// Unlike [fuzzyMatchForAi] which returns the single best match for initial
  /// validation, this method returns a broader set of plausible alternatives
  /// sorted by a composite score of text similarity + macro plausibility.
  Future<List<FoodItem>> fuzzyMatchCandidatesForRepair(
    String aiName, {
    String? stateHint,
    int limit = 5,
  }) async {
    final candidates = await searchProducts(aiName);
    if (candidates.isEmpty) return [];

    // Re-rank items incorporating stateHint
    candidates.sort((a, b) {
      final aName = a.getLocalizedName(null).toLowerCase();
      final bName = b.getLocalizedName(null).toLowerCase();

      // State hint scoring/boosting
      double stateBoost(String name) {
        if (stateHint != null) {
          final hint = stateHint.toLowerCase();
          if (hint == 'cooked') {
            if (name.contains('gekocht') ||
                name.contains('zubereitet') ||
                name.contains('gebraten') ||
                name.contains('gebacken')) {
              return -2.0; // Lower is better in sort (ascending)
            }
            if (name.contains('roh')) {
              return 2.0; // raw is penalized when we expect cooked
            }
          } else if (hint == 'raw') {
            if (name.contains('roh')) {
              return -2.0;
            }
            if (name.contains('gekocht') ||
                name.contains('zubereitet') ||
                name.contains('gebraten')) {
              return 2.0;
            }
          }
        }
        return 0.0;
      }

      final scoreA = stateBoost(aName);
      final scoreB = stateBoost(bName);
      if (scoreA != scoreB) return scoreA.compareTo(scoreB);

      // Fallback to text matching
      final searchLower = aiName.trim().toLowerCase();
      int textScore(FoodItem item) {
        final name = item.getLocalizedName(null).toLowerCase();
        final brand = item.brand.toLowerCase();
        final fullName1 = brand.isEmpty ? name : '$brand $name';
        final fullName2 = brand.isEmpty ? name : '$name $brand';

        if (name == searchLower ||
            fullName1 == searchLower ||
            fullName2 == searchLower) {
          return 0;
        }
        if (name.startsWith(searchLower) ||
            fullName1.startsWith(searchLower) ||
            fullName2.startsWith(searchLower)) {
          return 1;
        }
        return 2;
      }

      final sa = textScore(a);
      final sb = textScore(b);
      if (sa != sb) return sa.compareTo(sb);

      int srcPri(FoodItemSource s) {
        switch (s) {
          case FoodItemSource.base:
            return 0;
          case FoodItemSource.user:
            return 1;
          case FoodItemSource.off:
            return 2;
        }
      }

      final spa = srcPri(a.source);
      final spb = srcPri(b.source);
      if (spa != spb) return spa.compareTo(spb);

      return aName.length.compareTo(bName.length);
    });

    return candidates.take(limit).toList();
  }

  // === Legacy / Compatibility ===
  Future<dynamic> get offDatabase async => null;

  Future<String> getBaseDbPath() async {
    final supportDir = await getApplicationSupportDirectory();
    return CatalogFileMigration.resolveCanonicalPath(
      directoryPath: supportDir.path,
      canonicalFileName: AppDataSources.baseFoodsDbFileName,
      legacyFileName: AppDataSources.legacyBaseFoodsDbFileName,
    );
  }

  /// Retrieves all custom/user-created food items from the database.
  Future<List<FoodItem>> getCustomFoods() async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(dbInstance.products)
          ..where((tbl) => tbl.source.equals('user')))
        .get();
    return _enrichProductsWithOverrides(rows);
  }

  /// Deletes a user-created food item, handling referencing keys safely.
  Future<void> deleteProduct(String id, String barcode) async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      // 1. Nullify references in NutritionLogs to avoid foreign-key violations
      await (dbInstance.update(dbInstance.nutritionLogs)
            ..where((tbl) => tbl.productId.equals(id)))
          .write(const db.NutritionLogsCompanion(productId: Value(null)));

      // 2. Delete references in MealItems
      await (dbInstance.delete(dbInstance.mealItems)
            ..where((tbl) => tbl.productId.equals(id)))
          .go();

      // 3. Remove from Favorites
      await (dbInstance.delete(dbInstance.favorites)
            ..where((tbl) => tbl.barcode.equals(barcode)))
          .go();

      // 4. Remove overrides if any
      await (dbInstance.delete(dbInstance.userFoodOverrides)
            ..where((tbl) => tbl.barcode.equals(barcode)))
          .go();

      // 5. Delete the product itself
      await (dbInstance.delete(dbInstance.products)
            ..where((tbl) => tbl.id.equals(id)))
          .go();
    });
  }

  Future<bool> isFavorite(String barcode) async {
    final dbInstance = await database;
    final count = await (dbInstance.select(
      dbInstance.favorites,
    )..where((t) => t.barcode.equals(barcode)))
        .get();
    return count.isNotEmpty;
  }

  Future<List<String>> getFavoriteBarcodes() async {
    final dbInstance = await database;
    final rows = await dbInstance.select(dbInstance.favorites).get();
    return rows.map((r) => r.barcode).toList();
  }

  Future<void> addFavorite(String barcode) async {
    final dbInstance = await database;
    await dbInstance.into(dbInstance.favorites).insert(
          db.FavoritesCompanion(barcode: Value(barcode)),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> removeFavorite(String barcode) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.favorites,
    )..where((t) => t.barcode.equals(barcode)))
        .go();
  }
}
