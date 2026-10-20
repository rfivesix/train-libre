import 'package:drift/drift.dart';

import '../features/diary/domain/food_name_matching.dart';

/// Derived, versioned indexes. Triggers cover catalog imports, edits, overrides,
/// replacement inserts and deletions; no full-catalog scan runs per search.
abstract final class FoodSearchIndex {
  static const products = 'food_search_v1';
  static const aliases = 'food_alias_search_v1';
  static const names = [
    'name',
    'name_de',
    'name_en',
    'name_fr',
    'name_it',
    'name_ja'
  ];

  static String literal(String value) => "'${value.replaceAll("'", "''")}'";

  static String normalizeSql(String expression) {
    var sql = "COALESCE($expression, '')";
    for (final fold in FoodNameMatching.folds.entries) {
      sql =
          'REPLACE($sql, ${literal(fold.key.toUpperCase())}, ${literal(fold.value)})';
    }
    sql = "LOWER(REPLACE($sql, 'ẞ', 'ss'))";
    for (final fold in FoodNameMatching.folds.entries) {
      sql = 'REPLACE($sql, ${literal(fold.key)}, ${literal(fold.value)})';
    }
    for (final separator in [
      '-',
      ',',
      '.',
      '(',
      ')',
      '/',
      '\\',
      ':',
      ';',
      "'",
      '’',
      '–',
      '—',
      '_',
      '+',
      '&',
      '%',
      '!',
      '?',
      '"',
      '\n',
      '\r',
      '\t',
      '\u00a0',
      '・',
      '、',
      '。',
      '（',
      '）',
      '[',
      ']',
      '{',
      '}',
      '=',
      '*'
    ]) {
      sql = 'REPLACE($sql, ${literal(separator)}, \' \')';
    }
    for (var i = 0; i < 5; i++) {
      sql = "REPLACE($sql, '  ', ' ')";
    }
    return 'TRIM($sql)';
  }

  static Future<void> ensure(GeneratedDatabase db) async {
    final existing = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('$products', '$aliases')",
        )
        .get();
    final tables = existing.map((row) => row.read<String>('name')).toSet();
    if (tables.contains(products) && tables.contains(aliases)) return;
    await db.transaction(() async {
      if (!tables.contains(products)) {
        await db.customStatement('CREATE VIRTUAL TABLE $products USING fts5('
            '${names.join(', ')}, brand, compact, tokenize="unicode61 remove_diacritics 2", prefix="2 3 4")');
        // The view keeps import, override and initial-build normalization equal.
        await db.customStatement('CREATE VIEW food_search_content_v1 AS SELECT '
            'p.local_id AS rowid, '
            '${names.map((name) {
          final raw = 'COALESCE(o.name, p.$name)';
          final previous = names.take(names.indexOf(name));
          final normalized = normalizeSql(raw);
          // OFF imports often repeat the same name in every language.
          return previous.isEmpty
              ? '$normalized AS $name'
              : "CASE WHEN $raw IS NULL OR $raw IN (${previous.map((n) => 'COALESCE(o.name, p.$n)').join(', ')}) THEN '' ELSE $normalized END AS $name";
        }).join(', ')}, '
            '${normalizeSql('COALESCE(o.brand, p.brand)')} AS brand, p.source '
            "FROM products p LEFT JOIN user_food_overrides o ON o.barcode = p.barcode WHERE p.source IN ('base', 'user', 'off') AND p.deleted_at IS NULL");
        String insert(String condition) =>
            'INSERT INTO $products(rowid, ${names.join(', ')}, brand, compact) '
            'SELECT rowid, ${names.join(', ')}, brand, '
            "CASE WHEN source = 'base' THEN ${names.map((name) => "REPLACE($name, ' ', '')").join(" || ' ' || ")} ELSE '' END "
            'FROM food_search_content_v1 WHERE $condition;';
        await db.customStatement(insert('1'));
        await db.customStatement(
            'CREATE TRIGGER food_search_insert_v1 AFTER INSERT ON products BEGIN '
            '${insert('rowid = new.local_id')} END');
        await db.customStatement(
            'CREATE TRIGGER food_search_update_v1 AFTER UPDATE OF ${names.join(', ')}, brand, source, barcode, deleted_at ON products BEGIN '
            'DELETE FROM $products WHERE rowid = old.local_id; ${insert('rowid = new.local_id')} END');
        await db.customStatement(
            'CREATE TRIGGER food_search_delete_v1 AFTER DELETE ON products BEGIN '
            'DELETE FROM $products WHERE rowid = old.local_id; END');
        for (final event in ['INSERT', 'UPDATE', 'DELETE']) {
          final barcode = event == 'DELETE' ? 'old.barcode' : 'new.barcode';
          final condition =
              'rowid IN (SELECT local_id FROM products WHERE barcode = $barcode'
              '${event == 'UPDATE' ? ' OR barcode = old.barcode' : ''})';
          await db.customStatement(
              'CREATE TRIGGER food_search_override_${event.toLowerCase()}_v1 AFTER $event ON user_food_overrides BEGIN '
              'DELETE FROM $products WHERE $condition; ${insert(condition)} END');
        }
      }
      if (!tables.contains(aliases)) {
        await db.customStatement('CREATE VIRTUAL TABLE $aliases USING fts5('
            'name, compact, tokenize="unicode61 remove_diacritics 2", prefix="2 3 4")');
        String insert(String condition) =>
            'INSERT INTO $aliases(rowid, name, compact) '
            'SELECT rowid, ${normalizeSql('alias')}, REPLACE(${normalizeSql('alias')}, \' \', \'\') '
            'FROM bls_food_alias_index WHERE $condition;';
        await db.customStatement(insert('1'));
        await db.customStatement(
            'CREATE TRIGGER food_alias_insert_v1 AFTER INSERT ON bls_food_alias_index BEGIN '
            '${insert('rowid = new.rowid')} END');
        await db.customStatement(
            'CREATE TRIGGER food_alias_update_v1 AFTER UPDATE ON bls_food_alias_index BEGIN '
            'DELETE FROM $aliases WHERE rowid = old.rowid; ${insert('rowid = new.rowid')} END');
        await db.customStatement(
            'CREATE TRIGGER food_alias_delete_v1 AFTER DELETE ON bls_food_alias_index BEGIN '
            'DELETE FROM $aliases WHERE rowid = old.rowid; END');
      }
    });
  }
}
