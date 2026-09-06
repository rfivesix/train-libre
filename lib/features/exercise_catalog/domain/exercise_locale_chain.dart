import 'package:flutter/foundation.dart';

import '../../../data/drift_database.dart';
import 'models/exercise_text.dart';

/// Decides which languages the catalog may be read in, and in what order.
///
/// The catalog ships 22 languages and marks which of them it stands behind, in
/// `catalog_languages.displayable`. The app reads that flag rather than
/// re-deriving a judgement of its own from `completeness` — the point of
/// moving the vocabulary into the data was to stop the app holding opinions
/// about data quality, and a completeness threshold in Dart would put one
/// straight back.
///
/// A language the registry does not mention is included. That covers a v1
/// catalog (no registry at all) and, more importantly, a language the user
/// typed their own exercises in.
class ExerciseLocaleChain {
  const ExerciseLocaleChain._();

  static Map<String, bool>? _cache;

  /// Drops the cached registry. Call after a catalog import.
  static void invalidate() => _cache = null;

  static Future<List<String>> resolve(
    AppDatabase db,
    String languageCode,
  ) async {
    final registry = await _registry(db);
    final requested = languageCode.trim().toLowerCase();
    // Absent from the registry means "no opinion", which is not the same as
    // "not displayable" — see the class comment.
    final include = registry[requested] ?? true;
    if (!include) {
      debugPrint(
        '[ExerciseCatalog] $requested is not displayable per the catalog; '
        'falling back to the English chain.',
      );
    }
    return exerciseLocaleChain(requested, include: include);
  }

  static Future<Map<String, bool>> _registry(AppDatabase db) async {
    final cached = _cache;
    if (cached != null) return cached;

    try {
      final rows = await db.select(db.catalogLanguages).get();
      final map = {
        for (final row in rows) row.code.trim().toLowerCase(): row.displayable,
      };
      _cache = map;
      return map;
    } catch (e) {
      // A device that has not imported a v2 catalog yet has no such table
      // until reconcileSchema runs. Falling back to "no opinion" keeps the
      // app on exactly its pre-v2 behaviour.
      debugPrint('[ExerciseCatalog] language registry unavailable: $e');
      _cache = const {};
      return const {};
    }
  }
}
