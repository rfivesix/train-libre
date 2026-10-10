// lib/data/product_database_helper.dart

import 'dart:convert';
import 'dart:async';
import 'dart:collection';

import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import '../../../../data/database_helper.dart';
import '../../../../data/drift_database.dart' as db;
import '../../../../data/food_search_index.dart';
import '../../../../config/app_data_sources.dart';
import '../../domain/models/food_item.dart';
import '../../domain/food_name_matching.dart';
import '../../../../services/catalog_file_migration.dart';
import '../../../../util/perf_debug_timer.dart';
import '../../domain/use_cases/evaluate_food_source_use_case.dart';

/// One scan shares recent-use weights and in-flight catalog searches across
/// all ingredients and repair rounds. Both values stay on-device.
class AiCatalogSearchSession {
  final ProductLocalDataSource _source;
  late final Future<({String barcodes, String ids})> scores =
      _source._loadRecentAiScores();
  final Map<String, Future<List<FoodItem>>> _terms = {};
  final Queue<Completer<void>> _waiting = Queue<Completer<void>>();
  int _active = 0;

  AiCatalogSearchSession(this._source);

  Future<List<FoodItem>> search(String term, {bool includeOff = false}) async {
    Future<List<FoodItem>> sourceSearch(bool offOnly) => _terms.putIfAbsent(
          '${offOnly ? 'off' : 'base'}:${FoodNameMatching.normalize(term)}',
          () => _runBounded(term, offOnly: offOnly),
        );
    final results = await Future.wait([
      sourceSearch(false),
      if (includeOff) sourceSearch(true),
    ]);
    return results.expand((foods) => foods).toList(growable: false);
  }

  Future<List<FoodItem>> _runBounded(String term,
      {required bool offOnly}) async {
    if (_active >= 4) {
      final ready = Completer<void>();
      _waiting.add(ready);
      await ready.future;
    } else {
      _active++;
    }
    try {
      return await _source.searchProducts(
        term,
        aiSession: this,
        includeOff: offOnly,
        offOnly: offOnly,
      );
    } finally {
      if (_waiting.isNotEmpty) {
        _waiting.removeFirst().complete();
      } else {
        _active--;
      }
    }
  }
}

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

  AiCatalogSearchSession createAiSearchSession() =>
      AiCatalogSearchSession(this);

  FoodItem _withCatalogMatchEvidence(FoodItem food, String alias,
          String language, String scope, String status) =>
      FoodItem(
        id: food.id,
        barcode: food.barcode,
        name: food.name,
        nameDe: food.nameDe,
        nameEn: food.nameEn,
        nameFr: food.nameFr,
        nameIt: food.nameIt,
        nameJa: food.nameJa,
        brand: food.brand,
        calories: food.calories,
        protein: food.protein,
        carbs: food.carbs,
        fat: food.fat,
        source: food.source,
        category: food.category,
        kj: food.kj,
        fiber: food.fiber,
        sugar: food.sugar,
        salt: food.salt,
        sodium: food.sodium,
        calcium: food.calcium,
        isLiquid: food.isLiquid,
        isFluid: food.isFluid,
        caffeineMgPer100ml: food.caffeineMgPer100ml,
        caffeineMgPer100g: food.caffeineMgPer100g,
        ingredientsText: food.ingredientsText,
        ingredientsAnalysisTags: food.ingredientsAnalysisTags,
        additivesTags: food.additivesTags,
        productQuantity: food.productQuantity,
        productQuantityUnit: food.productQuantityUnit,
        catalogMatchAlias: alias,
        catalogMatchLanguage: language,
        catalogMatchScope: scope,
        catalogMatchReviewStatus: status,
      );

  Future<({String barcodes, String ids})> _loadRecentAiScores() async {
    final dbInstance = await database;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    Future<Map<String, int>> scores(String field) async {
      final rows = await dbInstance.customSelect(
        'SELECT $field AS key, COUNT(*) * 10 AS score FROM nutrition_logs '
        'WHERE consumed_at >= ? AND $field IS NOT NULL AND $field != \'\' '
        'GROUP BY $field',
        variables: [Variable.withDateTime(cutoff)],
        readsFrom: {dbInstance.nutritionLogs},
      ).get();
      return {
        for (final row in rows) row.read<String>('key'): row.read<int>('score'),
      };
    }

    final results = await Future.wait([
      scores('legacy_barcode'),
      scores('product_id'),
    ]);
    return (barcodes: jsonEncode(results[0]), ids: jsonEncode(results[1]));
  }

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
      case 'legacy':
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

    if (search != null && search.trim().isNotEmpty) {
      return _searchCatalog(search,
          baseOnly: true, categoryKey: categoryKey, limit: limit);
    }
    query = query
      ..orderBy([
        (t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.name.length),
        (t) => OrderingTerm(expression: t.name),
      ]);

    final rows = await query.get();
    return _enrichProductsWithOverrides(rows);
  }

  Future<bool> hasSearchableProducts() async {
    final result = await _dbInstance.customSelect(
      "SELECT 1 FROM products WHERE source IN ('base', 'user', 'off') "
      'AND deleted_at IS NULL LIMIT 1',
      readsFrom: {_dbInstance.products},
    ).get();
    return result.isNotEmpty;
  }

  /// Manual search presents base, user and OFF sections, each with its own
  /// relevance-ranked allowance. Other sources cannot consume BLS slots.
  Future<List<FoodItem>> searchProductsForUser(String keyword) =>
      searchProducts(keyword);

  Future<List<FoodItem>> searchProducts(String keyword,
          {AiCatalogSearchSession? aiSession,
          bool includeOff = true,
          bool offOnly = false}) =>
      _searchCatalog(keyword,
          aiSession: aiSession, includeOff: includeOff, offOnly: offOnly,
          groupBySource: aiSession == null);

  Future<List<FoodItem>> _searchCatalog(
    String keyword, {
    AiCatalogSearchSession? aiSession,
    bool includeOff = true,
    bool offOnly = false,
    bool baseOnly = false,
    bool groupBySource = false,
    String? categoryKey,
    int limit = 50,
  }) async {
    final tokens = FoodNameMatching.tokens(keyword);
    if (tokens.isEmpty || limit <= 0) return [];
    final normalized = FoodNameMatching.normalize(keyword);
    final compact = FoodNameMatching.compact(keyword);
    // Tokens contain letters/numbers only. Always quote FTS terms so input
    // such as OR, quotes, %, _ and punctuation cannot change query syntax.
    final tokenQuery = tokens.map((token) => '"$token"*').join(' AND ');
    final nameQuery = FoodSearchIndex.names
        .map((name) => '{$name brand} : ($tokenQuery)')
        .join(' OR ');
    final variables = <Variable>[];
    String bind(String value) {
      variables.add(Variable.withString(value));
      return '?';
    }

    String rankName(
      String expression, {
      List<String> otherExactNames = const [],
      String? compactName,
    }) {
      final exact = [expression, ...otherExactNames]
          .map((name) => '$name = ${bind(normalized)}')
          .join(' OR ');
      final compactExact =
          compactName == null ? '' : ' OR $compactName = ${bind(compact)}';
      final words = tokens
          .map((token) =>
              "(' ' || $expression || ' ') LIKE ${bind('% $token %')}")
          .join(' AND ');
      final prefixes = tokens
          .map((token) => "(' ' || $expression) LIKE ${bind('% $token%')}")
          .join(' AND ');
      final compactPrefix = compactName == null
          ? ''
          : "WHEN $compactName LIKE ${bind('$compact%')} THEN 3";
      return '(CASE WHEN $exact$compactExact THEN 0 '
          'WHEN $words THEN 1 WHEN $prefixes THEN 2 $compactPrefix ELSE 4 END)';
    }

    final dbInstance = await database;
    final sourceFilter = baseOnly
        ? "p.source = 'base'"
        : offOnly
            ? "p.source = 'off'"
            : includeOff
                ? "p.source IN ('base', 'user', 'off')"
                : "p.source IN ('base', 'user')";
    final categoryFilter = categoryKey == null
        ? ''
        : ' AND p.category = ${FoodSearchIndex.literal(categoryKey)}';
    final ranks = [
      for (final name in FoodSearchIndex.names)
        rankName("TRIM(f.$name || ' ' || f.brand)",
            otherExactNames: ['f.$name', "TRIM(f.brand || ' ' || f.$name)"],
            compactName:
                "CASE WHEN p.source = 'base' THEN REPLACE(f.$name, ' ', '') ELSE '' END"),
    ];
    final canonicalSql =
        'SELECT p.local_id, MIN(${ranks.join(', ')}) AS relevance, '
        'NULL AS alias_id FROM ${FoodSearchIndex.products} f '
        'JOIN products p ON p.local_id = f.rowid '
        'WHERE ${FoodSearchIndex.products} MATCH ${bind('($nameQuery) OR compact : "$compact"*')} '
        'AND $sourceFilter$categoryFilter AND p.deleted_at IS NULL';
    var aliasesSql = '';
    if (!offOnly) {
      final aliasRank =
          rankName('f.name', compactName: "REPLACE(f.name, ' ', '')");
      aliasesSql = ' UNION ALL SELECT p.local_id, $aliasRank + '
          "CASE WHEN a.match_scope = 'identity' AND a.review_status = 'approved' THEN 0 ELSE 1 END, "
          'a.rowid FROM ${FoodSearchIndex.aliases} f '
          'JOIN bls_food_alias_index a ON a.rowid = f.rowid '
          "JOIN products p ON p.barcode = a.barcode AND p.source = 'base' "
          'WHERE ${FoodSearchIndex.aliases} MATCH ${bind('name : ($tokenQuery) OR compact : "$compact"*')}'
          '$categoryFilter AND p.deleted_at IS NULL';
    }
    final recentScores = aiSession == null
        ? await _loadRecentAiScores()
        : await aiSession.scores;
    final barcodeScores = bind(recentScores.barcodes);
    final idScores = bind(recentScores.ids);
    // Deduplicate and rank every indexed hit before the PER-SOURCE limit.
    // This applies to AI's base/user pass too: many custom exact names must
    // not crowd out a relevant BLS variant before final AI validation.
    final rows = await dbInstance
        .customSelect(
          '''
      WITH hits AS ($canonicalSql$aliasesSql),
      ranked AS (
        SELECT *, ROW_NUMBER() OVER (
          PARTITION BY local_id ORDER BY relevance, alias_id NULLS LAST
        ) AS position FROM hits WHERE relevance < 4
      ),
      recent_barcodes AS (SELECT key, value FROM json_each($barcodeScores)),
      recent_ids AS (SELECT key, value FROM json_each($idScores))
      , candidates AS (
        SELECT p.*, r.relevance,
               CASE p.source WHEN 'base' THEN 0 WHEN 'user' THEN 1 ELSE 2 END AS source_priority,
               (COALESCE(rb.value, 0) + COALESCE(ri.value, 0)) AS history_priority,
               a.alias AS match_alias, a.language_code AS match_language,
               a.match_scope AS match_scope, a.review_status AS match_review_status
        FROM ranked r JOIN products p ON p.local_id = r.local_id
        LEFT JOIN bls_food_alias_index a ON a.rowid = r.alias_id
        LEFT JOIN recent_barcodes rb ON rb.key = p.barcode
        LEFT JOIN recent_ids ri ON ri.key = p.id
        WHERE r.position = 1
      ), source_ranked AS (
        SELECT *, ROW_NUMBER() OVER (
          PARTITION BY source
          ORDER BY relevance, history_priority DESC, LENGTH(name), name, barcode
        ) AS source_position
        FROM candidates
      )
      SELECT * FROM source_ranked WHERE source_position <= $limit
      ORDER BY ${groupBySource ? 'source_priority, relevance' : 'relevance, source_priority'},
               history_priority DESC, LENGTH(name), name, barcode
    ''',
          variables: variables,
          readsFrom: {
            dbInstance.products,
            dbInstance.userFoodOverrides,
            dbInstance.nutritionLogs
          },
        )
        .get();
    final foods = await _enrichProductsWithOverrides(
        rows.map((row) => dbInstance.products.map(row.data)).toList());
    return [
      for (var i = 0; i < foods.length; i++)
        if (rows[i].readNullable<String>('match_alias') case final alias?)
          _withCatalogMatchEvidence(
              foods[i],
              alias,
              rows[i].read<String>('match_language'),
              rows[i].read<String>('match_scope'),
              rows[i].read<String>('match_review_status'))
        else
          foods[i],
    ];
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

  /// Retrieves and ranks bounded per-source AI candidates using the same
  /// names, translations and aliases as manual search. OFF requires opt-in.
  Future<List<FoodItem>> fuzzyMatchForAi(
    String aiName, {
    String? catalogSearchTerm,
    Iterable<String> searchTerms = const [],
    AiCatalogSearchSession? aiSession,
    bool includeOff = false,
  }) async {
    final session = aiSession ?? createAiSearchSession();
    final terms = <String>{
      aiName.trim(),
      if (catalogSearchTerm != null) catalogSearchTerm.trim(),
      ...searchTerms.map((term) => term.trim()),
    }..removeWhere((term) => term.isEmpty);
    final resultSets = await Future.wait(
      terms.take(6).map((term) => session.search(term, includeOff: includeOff)),
    );
    final byBarcode = <String, FoodItem>{};
    int rank(FoodItem food) => terms
        .map((term) => FoodNameMatching.rank(term, food))
        .reduce((a, b) => a < b ? a : b);
    for (final results in resultSets) {
      for (final food in results) {
        final previous = byBarcode[food.barcode];
        // A later synonym may carry stronger, reviewed alias evidence.
        if (previous == null || rank(food) < rank(previous)) {
          byBarcode[food.barcode] = food;
        }
      }
    }
    final candidates = byBarcode.values.toList();

    if (candidates.isEmpty) return [];

    const int returnLimit = 15;
    return const EvaluateFoodSourceUseCase().execute(
      candidates: candidates,
      searchTerm: aiName,
      searchTerms: terms,
      limit: returnLimit,
      preserveSourceCandidates: true,
    );
  }

  /// Returns up to [limit] fuzzy-match candidates for an AI-identified food name,
  /// enriched with macro density profiles for injection into repair prompts.
  ///
  /// Applies preparation-state preference to the shared catalog shortlist.
  Future<List<FoodItem>> fuzzyMatchCandidatesForRepair(
    String aiName, {
    String? stateHint,
    int limit = 5,
  }) async {
    final candidates = await fuzzyMatchForAi(aiName);
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

      final sa = FoodNameMatching.rank(aiName, a);
      final sb = FoodNameMatching.rank(aiName, b);
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
