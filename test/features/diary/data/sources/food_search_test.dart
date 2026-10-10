import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/data/food_search_index.dart';
import 'package:train_libre/features/diary/data/sources/product_local_data_source.dart';
import 'package:train_libre/features/diary/domain/food_name_matching.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';
import 'package:train_libre/services/ai_meal_validation.dart';

FoodItem food(
  String id,
  String name, {
  FoodItemSource source = FoodItemSource.base,
  String en = '',
  String fr = '',
  String it = '',
  String ja = '',
  String brand = '',
  String category = 'test',
}) =>
    FoodItem(
        barcode: id,
        name: name,
        nameEn: en,
        nameFr: fr,
        nameIt: it,
        nameJa: ja,
        brand: brand,
        source: source,
        category: category,
        calories: 100,
        protein: 10,
        carbs: 10,
        fat: 2);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late db.AppDatabase database;
  late ProductLocalDataSource source;
  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(database);
    source = ProductLocalDataSource.forTesting(database);
  });
  tearDown(() => DatabaseHelper.closeAndResetDriftDb());

  Future<void> seed(List<FoodItem> foods) async {
    for (final item in foods) {
      await source.insertProduct(item);
    }
  }

  Future<void> alias(String barcode, String name, {bool approved = false}) =>
      database.customStatement(
          'INSERT OR REPLACE INTO bls_food_alias_index '
          '(barcode, language_code, alias, normalized_alias, kind, method, match_scope, review_status) '
          "VALUES (?, 'de', ?, ?, 'synonym', 'curated', ?, ?)",
          [
            barcode,
            name,
            FoodNameMatching.compact(name),
            approved ? 'identity' : 'broader',
            approved ? 'approved' : 'pending'
          ]);
  Future<List<String>> manual(String query) async =>
      (await source.searchProductsForUser(query))
          .map((food) => food.barcode)
          .toList();
  Future<List<String>> ai(String query, {bool off = false}) async =>
      (await source.fuzzyMatchForAi(query, includeOff: off))
          .map((food) => food.barcode)
          .toList();

  test('SQL and Dart normalization agree for supported scripts and spellings',
      () async {
    for (final text in [
      'ÄPFEL',
      'Straẞe',
      'CRÈME fraîche',
      'E\u0301clair',
      'HA\u0308HNCHEN-Brust',
      '玄米・ご飯',
      'Brot_(dunkel)',
      'l’huile'
    ]) {
      final row = await database.customSelect(
        'SELECT ${FoodSearchIndex.normalizeSql('?')} AS normalized',
        variables: [drift.Variable(text)],
      ).getSingle();
      expect(row.read<String>('normalized'), FoodNameMatching.normalize(text),
          reason: text);
    }
  });

  test('whole words anywhere outrank prefixes, without arbitrary -er stems',
      () async {
    await seed([
      food('wheat', 'Weizen Bier'),
      food('pils', 'Pilsner Bier'),
      food('compound', 'Bierschinken'),
      food('pear', 'Birne'),
      food('honey', 'Bienenhonig'),
      food('butter', 'Butter'),
      food('salad', 'Buttersalat'),
      food('exact', 'Bier', source: FoodItemSource.off),
    ]);
    expect(await manual('Bier'), ['wheat', 'pils', 'compound', 'exact']);
    expect(await ai('Bier'), ['wheat', 'pils', 'compound']);
    expect(await manual('Butter'), ['butter', 'salad']);
    expect(await manual('utter'), isEmpty);
    expect(await manual('Bier Birne'), isEmpty);
    expect(await ai('Bier Birne'), isEmpty);
  });

  test('all words, reordered names, punctuation and compounds use both paths',
      () async {
    await seed([
      food('a', 'Weizen-Bier alkoholfrei'),
      food('b', 'Weizenbrot'),
      food('c', 'Hähnchenbrust'),
      food('d', 'Crème fraîche')
    ]);
    for (final query in ['Bier Weizen', 'weizen, bier', 'WEIZEN---BIER']) {
      expect(await manual(query), ['a']);
      expect(await ai(query), ['a']);
    }
    for (final query in [
      'Hähnchen Brust',
      'haehnchenbrust',
      'HA\u0308HNCHEN BRUST'
    ]) {
      expect(await manual(query), ['c']);
      expect(await ai(query), ['c']);
    }
    expect(await manual('creme fraiche'), ['d']);
    expect(await ai('CRÈME FRAÎCHE'), ['d']);
    expect(await manual('Weizen Bier Zucker'), isEmpty);
  });

  test(
      'translations and brands are searchable, but languages cannot mix tokens',
      () async {
    await seed([
      food('rice', 'Reis gekocht',
          en: 'Cooked rice', fr: 'Riz cuit', it: 'Riso cotto', ja: 'ご飯'),
      food('off', 'Joghurt',
          en: 'Greek yogurt', source: FoodItemSource.off, brand: 'Acme')
    ]);
    for (final query in ['cooked rice', 'RIZ CUIT', 'riso cotto', 'ご飯']) {
      expect(await manual(query), ['rice']);
      expect(await ai(query), ['rice']);
    }
    expect(await manual('Reis cooked'), isEmpty);
    for (final query in ['acme yogurt', 'yogurt acme']) {
      expect(await manual(query), ['off']);
      expect(await ai(query, off: true), ['off']);
    }
    expect(await ai('yogurt'), isEmpty);
  });

  test('catalog aliases work at word boundaries and carry review evidence',
      () async {
    await seed([
      food('pasta', 'Teigwaren gekocht'),
      food('egg', 'Hühnerei'),
      food('bread', 'Brot')
    ]);
    await alias('pasta', 'Nudeln');
    await alias('egg', 'Eier', approved: true);
    await alias('bread', 'Dunkles Bauern Brot', approved: true);
    expect(await manual('Nudeln'), ['pasta']);
    expect(await ai('Nudeln'), ['pasta']);
    expect(await manual('Eier'), ['egg']);
    expect(await ai('Eier'), ['egg']);
    expect(await manual('Bauern Brot'), ['bread']);
    expect(await ai('Bauern Brot'), ['bread']);
    expect(await manual('auern'), isEmpty);
    final pasta = (await source.fuzzyMatchForAi('Nudeln')).single;
    expect(pasta.name, 'Teigwaren gekocht');
    expect(pasta.catalogMatchReviewStatus, 'pending');
  });

  test('rank before limit: translations and aliases beat hundreds of prefixes',
      () async {
    await database.transaction(() async {
      for (var i = 0; i < 90; i++) {
        await source.insertProduct(food('weak$i', 'Reiswaffel $i'));
        await source
            .insertProduct(food('off$i', 'Rice', source: FoodItemSource.off));
      }
      await source
          .insertProduct(food('translation', 'Langkornreis natur', en: 'Rice'));
      await source.insertProduct(food('alias', 'Oryza sativa'));
      await alias('alias', 'Reis', approved: true);
    });
    expect((await manual('Reis')).first, 'alias');
    expect((await ai('Reis')).first, 'alias');
    expect((await manual('Rice')).first, 'translation');
    expect(await ai('Rice'), ['translation']);
    final withOff = await ai('Rice', off: true);
    expect(withOff, contains('translation'));
    expect(withOff.where((id) => id.startsWith('off')), hasLength(15));
    expect(await manual('Reis'), hasLength(50));
  });

  test(
      'alias deduplication cannot consume candidate slots; strongest alias wins',
      () async {
    await seed([food('one', 'Teigwaren'), food('two', 'Getreidegericht')]);
    for (var i = 0; i < 40; i++) {
      await alias('one', 'Nudeln Variante $i');
    }
    await alias('two', 'Nudeln', approved: true);
    final hits = await source.searchProductsForUser('Nudeln');
    expect(hits.map((item) => item.barcode), ['two', 'one']);
    expect(hits.first.catalogMatchScope, 'identity');
    expect((await ai('Nudeln')).first, 'two');
  });

  test('source and category filters apply to names and aliases before limits',
      () async {
    await seed([
      food('base', 'Reis'),
      food('user', 'Reis', source: FoodItemSource.user),
      food('off', 'Reis', source: FoodItemSource.off),
      food('retired', 'Reis')
    ]);
    await alias('retired', 'Nudeln', approved: true);
    await database.customStatement(
        "UPDATE products SET source = 'legacy' WHERE barcode = 'retired'");
    expect(await manual('Reis'), ['base', 'user', 'off']);
    expect(await ai('Reis'), ['base', 'user']);
    expect(await manual('Nudeln'), isEmpty);
    expect(
        (await source.searchProducts('Reis', offOnly: true))
            .map((f) => f.barcode),
        ['off']);
    expect(
        (await source.getBaseFoods(search: 'Reis', categoryKey: 'test'))
            .map((f) => f.barcode),
        ['base']);
    expect(await source.getBaseFoods(search: 'Reis', categoryKey: 'missing'),
        isEmpty);
    await database.customStatement(
        "UPDATE products SET source = 'off_retained' WHERE barcode = 'off'");
    expect(await manual('Reis'), ['base', 'user']);
  });

  test('SQL/FTS operators, blanks and missing terms never widen a search',
      () async {
    await seed(
        [food('rice', 'Reis'), food('or', 'OR'), food('apple', 'Apfel')]);
    for (final query in ['', '  ', '%_*"()', 'xyzzy', 'Reis OR Apfel']) {
      expect(await manual(query), isEmpty, reason: query);
      expect(await ai(query), isEmpty, reason: query);
    }
    expect(await manual('OR'), ['or']);
    expect(await manual('"Reis"%'), ['rice']);
  });

  test(
      'index follows updates, overrides, replace, ignore, soft and hard deletion',
      () async {
    await seed([food('a', 'Apfel')]);
    expect(await source.hasSearchableProducts(), isTrue);
    await source.updateProduct(food('a', 'Birne'));
    expect(await manual('Apfel'), isEmpty);
    expect(await ai('Birne'), ['a']);
    await database.customStatement(
        "UPDATE products SET name = 'Katalogname' WHERE barcode = 'a'");
    expect(await manual('Birne'), ['a']); // visible override is indexed
    expect(await manual('Katalogname'), isEmpty);
    await database.delete(database.userFoodOverrides).go();
    expect(await manual('Katalogname'), ['a']);
    await database.customStatement(
        "INSERT OR IGNORE INTO products (id, barcode, name, calories, protein, carbs, fat, source) "
        "SELECT id, barcode, 'Ignored', calories, protein, carbs, fat, source FROM products WHERE barcode = 'a'");
    expect(await manual('Katalogname'), ['a']);
    await source.insertProduct(food('a', 'Banane'));
    expect(await manual('Katalogname'), isEmpty);
    expect(await manual('Banane'), ['a']);
    await alias('a', 'Bananas', approved: true);
    await alias('a', 'Bananas', approved: false);
    expect(
        (await source.searchProducts('Bananas'))
            .single
            .catalogMatchReviewStatus,
        'pending');
    await database.customStatement(
        "UPDATE bls_food_alias_index SET alias = 'Bananen' WHERE barcode = 'a'");
    expect(await manual('Bananas'), isEmpty);
    expect(await manual('Bananen'), ['a']);
    await database.customStatement('DELETE FROM bls_food_alias_index');
    expect(await manual('Bananen'), isEmpty);
    await database.customStatement('UPDATE products SET deleted_at = 1');
    expect(await manual('Banane'), isEmpty);
    expect(await source.hasSearchableProducts(), isFalse);
    await database.delete(database.products).go();
    final count = await database
        .customSelect('SELECT COUNT(*) AS n FROM ${FoodSearchIndex.products}')
        .getSingle();
    expect(count.read<int>('n'), 0);
  });

  test('AI validates aliases conservatively and forwards canonical repair IDs',
      () async {
    await seed([food('pasta', 'Teigwaren gekocht'), food('egg', 'Hühnerei')]);
    await alias('pasta', 'Nudeln');
    await alias('egg', 'Eier', approved: true);
    Future<AiValidationResult> validate(String name) =>
        AiMealValidationEngine().validateMealCandidate(
            candidate: AiMealCandidate(items: [
              AiMealCandidateItem(name: name, grams: 100, confidence: 0.9),
            ]),
            mode: AiValidationMode.capture);
    final pending = (await validate('Nudeln')).items.single;
    expect(pending.match.bestMatch, isNull);
    expect(pending.repairFoods.single.barcode, 'pasta');
    final prompt = pending.getRepairCandidates().single.toPromptLine();
    expect(prompt, contains('[id:pasta]'));
    expect(prompt, contains('review:pending'));
    expect(prompt, contains('Teigwaren gekocht'));
    final approved = (await validate('Eier')).items.single;
    expect(approved.match.bestMatch?.barcode, 'egg');
    expect(approved.match.quality, AiMatchQuality.exact);
    final missing = (await validate('NichtsPassendes')).items.single;
    expect(missing.match.bestMatch, isNull);
    expect(missing.repairFoods, isEmpty);
  });

  test('AI expands to OFF only with packaging evidence or explicit fallback',
      () async {
    await seed([
      food('off', 'Greek yogurt', source: FoodItemSource.off, brand: 'Acme')
    ]);
    Future<AiValidatedMealItem> validate(AiMealCandidateItem item) async =>
        (await AiMealValidationEngine().validateMealCandidate(
          candidate: AiMealCandidate(items: [item]),
          mode: AiValidationMode.capture,
        ))
            .items
            .single;
    const generic = AiMealCandidateItem(name: 'Greek yogurt', grams: 100);
    expect((await validate(generic)).match.bestMatch, isNull);
    final fallback = await validate(generic.copyWith(allowOffFallback: true));
    expect(fallback.match.bestMatch?.barcode, 'off');
    expect(fallback.candidate.isPackagedProduct, isFalse);
    final packaged = await validate(const AiMealCandidateItem(
        name: 'Yogurt',
        grams: 100,
        catalogSearchTerm: 'Acme Greek yogurt',
        packagedProductEvidence: 'Acme printed on the pot'));
    expect(packaged.match.bestMatch?.barcode, 'off');
    expect(packaged.match.quality, AiMatchQuality.exact);
  });

  test('history orders equally relevant foods without displacing exact names',
      () async {
    await seed([
      food('exact', 'Brot'),
      food('short', 'Brot hell'),
      food('used', 'Brot dunkel frisch')
    ]);
    await database
        .into(database.nutritionLogs)
        .insert(db.NutritionLogsCompanion(
          legacyBarcode: const drift.Value('used'),
          consumedAt: drift.Value(DateTime.now()),
          amount: const drift.Value(100),
        ));
    expect(await manual('Brot'), ['exact', 'used', 'short']);
  });

  test('later AI search terms retain stronger alias evidence for the same food',
      () async {
    await seed([food('a', 'Teigwaren gekocht')]);
    await alias('a', 'Nudeln', approved: true);
    final results =
        await source.fuzzyMatchForAi('Teigwaren', searchTerms: ['Nudeln']);
    expect(results.single.catalogMatchAlias, 'Nudeln');
  });

  test(
      'large catalog uses FTS and preserves exact hits beyond a crowded prefix',
      () async {
    final watch = Stopwatch()..start();
    await database.customStatement('''WITH RECURSIVE n(i) AS (
      VALUES(1) UNION ALL SELECT i+1 FROM n WHERE i < 100000
    ) INSERT INTO products (id, barcode, name, calories, protein, carbs, fat, source)
      SELECT 'id'||i, 'code'||i, CASE WHEN i <= 12000 THEN 'Reiswaffel '||i ELSE 'Katalogprodukt '||i END, 100, 10, 10, 2, 'off' FROM n''');
    await seed([food('best', 'Reis', source: FoodItemSource.off)]);
    final importMs = watch.elapsedMilliseconds;
    watch.reset();
    expect((await manual('Reis')).first, 'best');
    final searchMs = watch.elapsedMilliseconds;
    final plan = await database.customSelect(
        'EXPLAIN QUERY PLAN SELECT rowid FROM ${FoodSearchIndex.products} WHERE ${FoodSearchIndex.products} MATCH ?',
        variables: [const drift.Variable('name : "reis"*')]).get();
    expect(plan.map((row) => row.data.toString()).join(),
        contains('VIRTUAL TABLE INDEX'));
    // Diagnostic only: wall-clock thresholds would make this machine-dependent.
    // ignore: avoid_print
    print(
        'Food search benchmark: 100001 rows; import $importMs ms; query $searchMs ms');
  });

  test('an existing catalog is indexed once on reopen without data loss',
      () async {
    await DatabaseHelper.closeAndResetDriftDb();
    final dir = await Directory.systemTemp.createTemp('food-search-migration');
    final file = File('${dir.path}/catalog.sqlite');
    var disk = db.AppDatabase(NativeDatabase(file));
    try {
      await ProductLocalDataSource.forTesting(disk)
          .insertProduct(food('old', 'Weizen Bier'));
      // Simulate a database from before the derived index existed.
      final objects = await disk
          .customSelect(
              "SELECT type, name FROM sqlite_master WHERE type IN ('trigger', 'view') AND (name LIKE 'food_search_%' OR name LIKE 'food_alias_%')")
          .get();
      for (final row in objects) {
        await disk.customStatement(
            'DROP ${row.read<String>('type')} ${row.read<String>('name')}');
      }
      await disk.customStatement('DROP TABLE ${FoodSearchIndex.products}');
      await disk.customStatement('DROP TABLE ${FoodSearchIndex.aliases}');
      await disk.close();
      disk = db.AppDatabase(NativeDatabase(file));
      expect(
          (await ProductLocalDataSource.forTesting(disk).searchProducts('Bier'))
              .single
              .barcode,
          'old');
      await disk.close();
      disk = db.AppDatabase(NativeDatabase(file));
      expect(
          (await ProductLocalDataSource.forTesting(disk).searchProducts('Bier'))
              .single
              .barcode,
          'old');
    } finally {
      await disk.close();
      await dir.delete(recursive: true);
    }
  });

  test(
      'more than 50 competing OFF hits do not displace matching BLS base foods',
      () async {
    await database.transaction(() async {
      // 1 BLS base food: "Orange roh"
      await source.insertProduct(food('bls_orange', 'Orange roh'));
      // 1 user food: "Eigene Orange"
      await source.insertProduct(
          food('user_orange', 'Eigene Orange', source: FoodItemSource.user));
      // 70 competing OFF foods named "Orange Saft 0" .. "Orange Saft 69"
      for (var i = 0; i < 70; i++) {
        await source.insertProduct(food('off_orange_$i', 'Orange Saft $i',
            source: FoodItemSource.off));
      }
    });

    final results = await source.searchProductsForUser('Orange');
    // Base food must be first, user food second, OFF foods follow
    expect(results.first.barcode, 'bls_orange');
    expect(results.first.source, FoodItemSource.base);
    expect(results[1].barcode, 'user_orange');
    expect(results[1].source, FoodItemSource.user);

    // Verify BLS food was NOT displaced by the 70 OFF foods:
    expect(results.any((f) => f.barcode == 'bls_orange'), isTrue);
    expect(results.any((f) => f.barcode == 'user_orange'), isTrue);

    // OFF section contains at most the source limit (50)
    final offResults =
        results.where((f) => f.source == FoodItemSource.off).toList();
    expect(offResults.length, 50);

    // Total results = 1 base + 1 user + 50 off = 52
    expect(results.length, 52);
  });

  test(
      'realistic BLS catalog basis: Orange roh, Pilsner Bier and other staples lead their sections',
      () async {
    await database.transaction(() async {
      // Realistic BLS foods
      await source.insertProduct(food('bls:F503000', 'Orange roh',
          category: 'obst'));
      await source.insertProduct(food('bls:B101000', 'Pilsner Bier',
          category: 'bier_wein'));
      await source.insertProduct(food('bls:B101001', 'Bier alkoholfrei',
          category: 'bier_wein'));
      await source.insertProduct(food('bls:F100000', 'Apfel roh',
          category: 'obst'));
      await source.insertProduct(food('bls:M100000', 'Milch 3,5% Fett',
          category: 'milch'));
      await source.insertProduct(food('bls:G100000', 'Reis poliert gekocht',
          category: 'getreide'));

      // Competing branded OFF products (including 60 orange products to test crowding)
      for (var i = 0; i < 60; i++) {
        await source.insertProduct(food('off_orange_$i', 'Hohes C Orange $i',
            brand: 'Hohes C', source: FoodItemSource.off));
      }
      for (var i = 0; i < 60; i++) {
        await source.insertProduct(food('off_beer_$i', 'Krombacher Bier $i',
            brand: 'Krombacher', source: FoodItemSource.off));
      }
      await source.insertProduct(food('off_rice', 'Uncle Bens Reis',
          brand: 'Uncle Bens', source: FoodItemSource.off));
      await source.insertProduct(food('off_milk', 'Bärenmarke Frische Milch',
          brand: 'Bärenmarke', source: FoodItemSource.off));
    });

    // 1. Query "Orange": "Orange roh" is returned in base section ahead of OFF drinks
    final orangeResults = await source.searchProductsForUser('Orange');
    expect(orangeResults.first.barcode, 'bls:F503000');
    expect(orangeResults.first.name, 'Orange roh');
    expect(orangeResults.first.source, FoodItemSource.base);
    expect(orangeResults.any((f) => f.source == FoodItemSource.off), isTrue);

    // 2. Query "Bier": "Pilsner Bier" is returned in base section ahead of OFF beers
    final beerResults = await source.searchProductsForUser('Bier');
    final baseBeers = beerResults
        .where((f) => f.source == FoodItemSource.base)
        .map((f) => f.barcode)
        .toList();
    expect(baseBeers, contains('bls:B101000'));
    expect(baseBeers, contains('bls:B101001'));
    expect(beerResults.first.source, FoodItemSource.base);
    final offBeers =
        beerResults.where((f) => f.source == FoodItemSource.off).toList();
    expect(offBeers, isNotEmpty);

    // 3. Query "Reis": "Reis poliert gekocht" is returned in base section
    final riceResults = await source.searchProductsForUser('Reis');
    expect(riceResults.first.barcode, 'bls:G100000');
    expect(riceResults.first.name, 'Reis poliert gekocht');
    expect(riceResults.last.barcode, 'off_rice');

    // 4. Query "Milch": "Vollmilch 3,5% Fett" is returned in base section
    final milkResults = await source.searchProductsForUser('Milch');
    expect(milkResults.first.barcode, 'bls:M100000');
    expect(milkResults.last.barcode, 'off_milk');

    // 5. Irrelevant BLS foods do not appear
    expect(orangeResults.any((f) => f.barcode == 'bls:B101000'), isFalse);
    expect(beerResults.any((f) => f.barcode == 'bls:F503000'), isFalse);
  });

  test(
      'AI selection prefers BLS candidates for generic foods while respecting packaged product evidence',
      () async {
    await database.transaction(() async {
      await source.insertProduct(food('bls_orange', 'Orange roh',
          category: 'obst'));
      await source.insertProduct(food('off_hohes_c', 'Orange Saft',
          brand: 'Hohes C', source: FoodItemSource.off));
    });

    final engine = AiMealValidationEngine();

    // Generic food "Orange" -> selects BLS "Orange roh"
    final genericResult = await engine.validateMealCandidate(
      candidate: const AiMealCandidate(items: [
        AiMealCandidateItem(name: 'Orange', grams: 150, confidence: 0.9),
      ]),
      mode: AiValidationMode.capture,
    );
    expect(genericResult.items.single.match.bestMatch?.barcode, 'bls_orange');

    // Packaged food with packaging evidence -> selects OFF product
    final packagedResult = await engine.validateMealCandidate(
      candidate: const AiMealCandidate(items: [
        AiMealCandidateItem(
          name: 'Orange',
          grams: 200,
          confidence: 0.9,
          catalogSearchTerm: 'Hohes C Orange Saft',
          packagedProductEvidence: 'Hohes C Flasche',
        ),
      ]),
      mode: AiValidationMode.capture,
    );
    expect(packagedResult.items.single.match.bestMatch?.barcode, 'off_hohes_c');
  });
}
