@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/features/exercise_catalog/domain/body_slug_mapper.dart';

/// Every `body_slugs` value the catalog ships must resolve to a real slug.
///
/// This is the test that caught three shoulders quietly not lighting up.
/// `BodyPartSlug.fromString` lowercases and turns `_` into `-`, which does
/// nothing for camelCase: `frontDeltoids` arrives as `frontdeltoids` and
/// matches none of the `front-deltoids` / `front-delts` / `shoulders` cases it
/// knows. The result is null, the highlight is skipped, and nothing reports an
/// error — a shoulder that does not light up is not something a user files a
/// bug about.
///
/// It asserts on `BodySlugMapper.fromCatalogSlug`, the app's own entry point,
/// rather than on the widget's parser: the app has to render correctly
/// whatever the fork's pin currently is. The second test keeps the fork honest
/// anyway, by naming the slugs that only work because of the app-side shim.
///
/// Runs against the fixture, so the next time the vocabulary grows a slug the
/// app cannot read, CI says so.
const String kFixturePath = 'test/fixtures/exercise_catalog/v2_min.db';

void main() {
  sqfliteFfiInit();

  late Database db;

  setUpAll(() async {
    db = await databaseFactoryFfi.openDatabase(
      File(kFixturePath).absolute.path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
  });

  tearDownAll(() async => db.close());

  Future<Map<String, List<String>>> slugsByMuscle() async {
    final rows = await db.query('muscles', columns: ['id', 'body_slugs']);
    final result = <String, List<String>>{};
    for (final row in rows) {
      final raw = row['body_slugs']?.toString() ?? '';
      if (raw.trim().isEmpty) continue;
      final decoded = jsonDecode(raw);
      if (decoded is! List) continue;
      final slugs = decoded
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (slugs.isNotEmpty) result[row['id'].toString()] = slugs;
    }
    return result;
  }

  test('every body_slugs value resolves to a BodyPartSlug', () async {
    final byMuscle = await slugsByMuscle();
    expect(byMuscle, isNotEmpty);

    final unresolved = <String, String>{};
    for (final entry in byMuscle.entries) {
      for (final slug in entry.value) {
        if (BodySlugMapper.fromCatalogSlug(slug) == null) {
          unresolved[slug] = entry.key;
        }
      }
    }

    expect(
      unresolved,
      isEmpty,
      reason: 'these slugs silently render nothing: $unresolved',
    );
  });

  test('which slugs only the app-side shim rescues', () async {
    // Not a failure: it records what the fork still cannot parse on its own.
    // The fix is committed in the fork; until that commit is pushed and the
    // pin moves, this list is what fromCatalogSlug is carrying.
    final byMuscle = await slugsByMuscle();
    final shimmed = <String>{};
    for (final slugs in byMuscle.values) {
      for (final slug in slugs) {
        if (BodyPartSlug.fromString(slug) == null &&
            BodySlugMapper.fromCatalogSlug(slug) != null) {
          shimmed.add(slug);
        }
      }
    }
    if (shimmed.isNotEmpty) {
      printOnFailure('rescued by BodySlugMapper.fromCatalogSlug: $shimmed');
    }
    // Whatever the fork can or cannot parse, nothing may be lost.
    expect(
      byMuscle.values
          .expand((slugs) => slugs)
          .where((slug) => BodySlugMapper.fromCatalogSlug(slug) == null),
      isEmpty,
    );
  });

  test('every muscle group has at least one paintable slug', () async {
    // Individual muscles may legitimately have none — diaphragm and hip
    // flexors have no surface. A whole group with none would mean an entire
    // region of the body never lights up.
    final rows = await db.query(
      'muscles',
      columns: ['id', 'body_slugs'],
      where: "level = 'group'",
    );
    expect(rows, isNotEmpty);

    final empty = <String>[];
    for (final row in rows) {
      final raw = row['body_slugs']?.toString() ?? '';
      if (raw.trim().isEmpty || raw.trim() == '[]') {
        empty.add(row['id'].toString());
      }
    }
    expect(empty, isEmpty);
  });

  test('the slugs the app resolves are the ones the fork can paint', () async {
    // fromString returning a value is necessary but not sufficient: the enum
    // carries `abductors`, for which no view has any path data. Muscles that
    // name it also name `gluteal`, so nothing is lost — but if that ever
    // stopped being true, the highlight would vanish with no error.
    final byMuscle = await slugsByMuscle();
    const withoutGeometry = {BodyPartSlug.abductors};

    final onlyUnpaintable = <String>[];
    for (final entry in byMuscle.entries) {
      final resolved = entry.value
          .map(BodySlugMapper.fromCatalogSlug)
          .whereType<BodyPartSlug>()
          .toSet();
      if (resolved.isNotEmpty && resolved.difference(withoutGeometry).isEmpty) {
        onlyUnpaintable.add(entry.key);
      }
    }

    expect(onlyUnpaintable, isEmpty,
        reason: 'these muscles resolve only to slugs with no path data: '
            '$onlyUnpaintable');
  });
}
