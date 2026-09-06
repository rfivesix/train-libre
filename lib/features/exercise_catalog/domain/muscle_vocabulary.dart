import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../data/drift_database.dart';

/// One node of the catalog's muscle hierarchy: group -> muscle -> head.
@immutable
class MuscleNode {
  final String id;
  final String? parentId;

  /// group | muscle | head.
  final String level;

  /// The group this node resolves to. Statistics and recovery compute here.
  final String groupId;

  /// The group the pre-v2 app would have used. Deliberately differs for
  /// `serratus_anterior` (chest anatomically, back to this app) and
  /// `hip_flexors` (abs anatomically, glutes to this app).
  final String? legacyGroup;

  /// Body-highlighter slugs. May be empty — `diaphragm` and `hip_flexors`
  /// genuinely have no surface to paint.
  final List<String> bodySlugs;

  const MuscleNode({
    required this.id,
    required this.parentId,
    required this.level,
    required this.groupId,
    required this.legacyGroup,
    required this.bodySlugs,
  });

  /// What this app's statistics should file the muscle under.
  String get analyticsGroup => legacyGroup ?? groupId;
}

/// The muscle vocabulary, as shipped by the catalog.
///
/// This is the table that ends a coupling: while the anatomy lived in Dart —
/// seventy alias entries in `recovery_domain_service.dart`, a slug map in
/// `body_slug_mapper.dart` — every vocabulary change in the data repo was an
/// app release. Now it is a data release.
///
/// The hard-coded maps stay behind it as a fallback, because they still have
/// to answer for user-created exercises and for rows written before v2, which
/// carry legacy muscle names and no ids at all.
@immutable
class MuscleVocabulary {
  final Map<String, MuscleNode> byId;

  /// muscle id -> language code -> name.
  final Map<String, Map<String, String>> namesById;

  const MuscleVocabulary({required this.byId, required this.namesById});

  static const MuscleVocabulary empty =
      MuscleVocabulary(byId: {}, namesById: {});

  bool get isEmpty => byId.isEmpty;

  MuscleNode? node(String muscleId) => byId[muscleId.trim()];

  /// The raw group key for [muscleId], before this app decides which of its
  /// own buckets that belongs to.
  String? rawGroupFor(String muscleId) => node(muscleId)?.analyticsGroup;

  List<String> slugsFor(String muscleId) =>
      node(muscleId)?.bodySlugs ?? const [];

  /// The muscle's name in [languageCode], falling back to English.
  String? nameFor(String muscleId, String languageCode) {
    final names = namesById[muscleId.trim()];
    if (names == null) return null;
    for (final code in [languageCode.trim().toLowerCase(), 'en']) {
      final name = names[code];
      if (name != null && name.trim().isNotEmpty) return name;
    }
    return names.values.where((n) => n.trim().isNotEmpty).firstOrNull;
  }

  static Future<MuscleVocabulary> load(AppDatabase db) async {
    try {
      final rows = await db.select(db.muscles).get();
      if (rows.isEmpty) return empty;

      final byId = <String, MuscleNode>{
        for (final row in rows)
          row.id: MuscleNode(
            id: row.id,
            parentId: row.parentId,
            level: row.level,
            groupId: row.groupId,
            legacyGroup: row.legacyGroup,
            bodySlugs: _decodeSlugs(row.bodySlugs),
          ),
      };

      final namesById = <String, Map<String, String>>{};
      for (final row in await db.select(db.muscleTranslations).get()) {
        namesById.putIfAbsent(row.muscleId, () => <String, String>{})[
            row.languageCode.trim().toLowerCase()] = row.name;
      }

      return MuscleVocabulary(byId: byId, namesById: namesById);
    } catch (e) {
      // A device that has not imported a v2 catalog has no such table until
      // reconcileSchema runs. An empty vocabulary means "fall back to the
      // hard-coded maps", which is exactly the pre-v2 behaviour.
      debugPrint('[ExerciseCatalog] muscle vocabulary unavailable: $e');
      return empty;
    }
  }

  static List<String> _decodeSlugs(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {
      // Not JSON. The column is written by the build, so this should not
      // happen; treating it as "no slugs" beats throwing during a repaint.
    }
    return const [];
  }
}
