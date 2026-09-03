import '../../../../generated/app_localizations.dart';
import 'package:flutter/material.dart';
// lib/features/exercise_catalog/domain/body_slug_mapper.dart

import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';
import '../../statistics/domain/recovery_domain_service.dart';
import 'muscle_vocabulary.dart';

/// Maps raw muscle name strings (as stored in the wger exercise database)
/// to one or more [BodyPartSlug] values suitable for the [BodyHighlighter]
/// widget.
///
/// Resolution order:
///   1. Direct [BodyPartSlug.fromString] lookup (handles most single-muscle
///      names like "biceps", "quads", "hamstrings", "chest", "triceps", …).
///   2. Canonical major-group lookup via [RecoveryDomainService.majorMuscleGroupFor],
///      which normalises aliases like "traps", "lats", "pecs" first.
///   3. Manual canonical-group → slug(s) mapping for aggregate groups
///      (e.g. "back" → trapezius + upperBack, "shoulders" → front + rear delts).
///
/// For the "shoulders" canonical group the split is anatomically correct:
///   * [BodyPartSlug.frontDeltoids] — appears on the **front** view only.
///   * [BodyPartSlug.backDeltoids] — appears on the **back** view only.
/// Callers that render a single view should filter by [BodySide].
class BodySlugMapper {
  const BodySlugMapper._();

  /// Resolved slugs for each canonical major-group key.
  ///
  /// "shoulders" deliberately returns both front and back deltoid slugs so
  /// each view highlights the anatomically correct region.
  static const Map<String, List<BodyPartSlug>> _canonicalToSlugs = {
    'chest': [BodyPartSlug.chest],
    'back': [BodyPartSlug.trapezius, BodyPartSlug.upperBack],
    'shoulders': [BodyPartSlug.frontDeltoids, BodyPartSlug.backDeltoids],
    'biceps': [
      BodyPartSlug.biceps,
      BodyPartSlug.biceps_long,
      BodyPartSlug.biceps_short,
    ],
    'triceps': [BodyPartSlug.triceps],
    'quads': [BodyPartSlug.quadriceps],
    'hamstrings': [BodyPartSlug.hamstrings],
    'glutes': [BodyPartSlug.gluteal],
    'calves': [BodyPartSlug.calves],
    'lower back': [BodyPartSlug.lowerBack],
    'abs': [BodyPartSlug.abs, BodyPartSlug.obliques],
    'adductors': [BodyPartSlug.adductors],
    'forearms': [BodyPartSlug.forearms],
  };

  /// Which side of the body each slug is visible on.
  ///
  /// Used by [forSide] to filter slugs to only those relevant for a given
  /// [BodySide] when rendering a single view.
  ///
  /// Slugs NOT listed here are shown on BOTH views (front and back).
  static const Map<BodyPartSlug, BodySide> _slugSide = {
    // Front-only slugs
    BodyPartSlug.chest: BodySide.front,
    BodyPartSlug.abs: BodySide.front,
    BodyPartSlug.obliques: BodySide.front,
    BodyPartSlug.frontDeltoids: BodySide.front,
    BodyPartSlug.biceps: BodySide.front,
    BodyPartSlug.biceps_long: BodySide.front,
    BodyPartSlug.biceps_short: BodySide.front,
    BodyPartSlug.quadriceps: BodySide.front,
    BodyPartSlug.abductors: BodySide.front,
    BodyPartSlug.tibialisAnterior: BodySide.front,
    // Back-only slugs
    BodyPartSlug.upperBack: BodySide.back,
    BodyPartSlug.lowerBack: BodySide.back,
    BodyPartSlug.backDeltoids: BodySide.back,
    BodyPartSlug.gluteal: BodySide.back,
    BodyPartSlug.hamstrings: BodySide.back,
    // Visible on both sides — no entry means shown on both
    // BodyPartSlug.trapezius → both (front collar and back neck area)
    // BodyPartSlug.calves → both (gastrocnemius has a rear silhouette entry)
    // BodyPartSlug.forearms → both (SVG has paths on front + back views)
    // BodyPartSlug.triceps → both (lateral head silhouette visible from front)
    // BodyPartSlug.adductors → both (deep inner-thigh visible on front and back)
  };

  /// Resolves a `body_slugs` value from the catalog.
  ///
  /// The catalog writes camelCase (`frontDeltoids`, `tibialisAnterior`);
  /// [BodyPartSlug.fromString] lowercases and rewrites `_` to `-`, which does
  /// nothing for camelCase because there is no separator to rewrite. Three
  /// slugs therefore resolved to null and silently painted nothing — and a
  /// shoulder that does not light up is not something a user reports.
  ///
  /// The fork has been fixed to accept these spellings directly. This stays
  /// because the app must not depend on a pin bump to render correctly, and
  /// because knowing how *its own data* spells things is the app's job, not
  /// the widget's. It costs one regex on a cold path.
  static BodyPartSlug? fromCatalogSlug(String slug) {
    final direct = BodyPartSlug.fromString(slug);
    if (direct != null) return direct;

    final separated = slug
        .trim()
        .replaceAllMapped(
            RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]}-${m[2]}')
        .toLowerCase();
    return BodyPartSlug.fromString(separated);
  }

  /// Slugs for a catalog muscle id, straight from the shipped vocabulary.
  ///
  /// This is the path that makes a vocabulary change a data release: the
  /// answer to "where is the latissimus dorsi" now comes from the catalog
  /// rather than from [_canonicalToSlugs] below.
  static List<BodyPartSlug> fromMuscleId(
    String muscleId,
    MuscleVocabulary vocabulary,
  ) {
    final slugs = vocabulary.slugsFor(muscleId);
    if (slugs.isNotEmpty) {
      final resolved = slugs
          .map(fromCatalogSlug)
          .whereType<BodyPartSlug>()
          .toList(growable: false);
      if (resolved.isNotEmpty) return resolved;
    }

    // The muscle has no surface of its own (diaphragm, hip flexors). Painting
    // its group is more honest than painting nothing.
    final group = vocabulary.rawGroupFor(muscleId);
    return group == null ? const [] : fromRawName(group);
  }

  /// Merges primary and secondary muscle **ids** into highlight data.
  ///
  /// Same precedence rule as [mergedHighlights]: a slug claimed by a primary
  /// muscle is not dimmed by a secondary one.
  static List<BodyPartHighlightData> mergedHighlightsFromIds({
    required List<String> primaryMuscleIds,
    required List<String> secondaryMuscleIds,
    required MuscleVocabulary vocabulary,
    int primaryIntensity = 5,
    int secondaryIntensity = 2,
  }) {
    final seen = <BodyPartSlug>{};
    final result = <BodyPartHighlightData>[];

    void add(List<String> ids, int intensity) {
      for (final id in ids) {
        for (final slug in fromMuscleId(id, vocabulary)) {
          if (seen.add(slug)) {
            result.add(BodyPartHighlightData(slug: slug, intensity: intensity));
          }
        }
      }
    }

    add(primaryMuscleIds, primaryIntensity);
    add(secondaryMuscleIds, secondaryIntensity);
    return result;
  }

  /// Maps a single raw muscle name (e.g. `"chest"`, `"front delts"`,
  /// `"latissimus"`) to the corresponding [BodyPartSlug] values.
  ///
  /// Returns an empty list when no mapping can be determined.
  static List<BodyPartSlug> fromRawName(String rawName) {
    final cleaned =
        rawName.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');

    // Explicit manual mappings for specific muscle queries to bridge cleanly to visual slugs
    if (cleaned == 'traps' ||
        cleaned == 'trapezius' ||
        cleaned == 'neck' ||
        cleaned == 'lower neck') {
      return [BodyPartSlug.trapezius];
    }
    if (cleaned == 'lower back' ||
        cleaned == 'erector spinae' ||
        cleaned == 'erectors' ||
        cleaned == 'spinal erectors') {
      return [BodyPartSlug.lowerBack];
    }
    if (cleaned == 'adductor' ||
        cleaned == 'adductors' ||
        cleaned == 'hip adductor' ||
        cleaned == 'hip adductors') {
      return [BodyPartSlug.adductors];
    }
    if (cleaned == 'forearm' || cleaned == 'forearms') {
      return [BodyPartSlug.forearms];
    }
    if (cleaned.contains('biceps') || cleaned == 'brachialis') {
      return [
        BodyPartSlug.biceps,
        BodyPartSlug.biceps_long,
        BodyPartSlug.biceps_short,
      ];
    }
    // Wger muscles that fall back to their Latin name (no name_en set)
    if (cleaned == 'soleus') {
      return [BodyPartSlug.calves];
    }
    if (cleaned == 'obliquus externus abdominis') {
      return [BodyPartSlug.obliques];
    }
    if (cleaned == 'serratus anterior') {
      return [BodyPartSlug.upperBack];
    }

    // 1. Resolve via canonical group, then map group → slug list
    // This handles aggregate groups like "Shoulders" -> [frontDeltoids, backDeltoids]
    final canonical = RecoveryDomainService.majorMuscleGroupFor(rawName);
    if (canonical != null) {
      return _canonicalToSlugs[canonical] ?? const [];
    }

    // 2. Try direct fromString (normalises underscores → dashes, trims, lowercases)
    final direct = BodyPartSlug.fromString(rawName);
    if (direct != null) return [direct];

    return const [];
  }

  /// Converts a full list of raw muscle names to [BodyPartHighlightData]
  /// entries.
  ///
  /// Duplicate slugs are deduplicated — the first occurrence wins (earlier
  /// muscles in the list take precedence, so primary muscles beat secondary
  /// ones when this helper is called separately for each list).
  ///
  /// [intensity] is applied to every resulting slug (1–5).
  static List<BodyPartHighlightData> toHighlightData(
    List<String> muscleNames, {
    required int intensity,
  }) {
    final seen = <BodyPartSlug>{};
    final result = <BodyPartHighlightData>[];

    for (final name in muscleNames) {
      for (final slug in fromRawName(name)) {
        if (seen.add(slug)) {
          result.add(BodyPartHighlightData(slug: slug, intensity: intensity));
        }
      }
    }

    return result;
  }

  /// Merges primary and secondary muscle highlight lists, ensuring primary
  /// muscles always win when the same slug appears in both lists.
  ///
  /// Primary muscles → [primaryIntensity] (default 5).
  /// Secondary muscles → [secondaryIntensity] (default 2).
  static List<BodyPartHighlightData> mergedHighlights({
    required List<String> primaryMuscles,
    required List<String> secondaryMuscles,
    int primaryIntensity = 5,
    int secondaryIntensity = 2,
  }) {
    final seen = <BodyPartSlug>{};
    final result = <BodyPartHighlightData>[];

    // Primary muscles first — they own the slug
    for (final name in primaryMuscles) {
      for (final slug in fromRawName(name)) {
        if (seen.add(slug)) {
          result.add(
            BodyPartHighlightData(slug: slug, intensity: primaryIntensity),
          );
        }
      }
    }

    // Secondary muscles — only add slugs not already claimed
    for (final name in secondaryMuscles) {
      for (final slug in fromRawName(name)) {
        if (seen.add(slug)) {
          result.add(
            BodyPartHighlightData(slug: slug, intensity: secondaryIntensity),
          );
        }
      }
    }

    return result;
  }

  /// Returns only those highlights that are visible on [side].
  ///
  /// Use this when rendering a single [BodySide] view so that e.g.
  /// [BodyPartSlug.frontDeltoids] is not passed to a back-view widget
  /// (where it would render on an invisible region).
  static List<BodyPartHighlightData> forSide(
    List<BodyPartHighlightData> highlights,
    BodySide side,
  ) {
    return highlights.where((h) {
      final slugSide = _slugSide[h.slug];
      // If slug has no side mapping, show it on both views
      return slugSide == null || slugSide == side;
    }).toList(growable: false);
  }

  /// A muscle's display name.
  ///
  /// Prefers the catalog's own `muscle_translations`, which is what lets a new
  /// muscle arrive with its name in 22 languages without an app release. The
  /// hard-coded switch below stays for legacy names and group keys, which the
  /// vocabulary does not contain.
  static String localize(
    BuildContext context,
    String rawName, {
    MuscleVocabulary? vocabulary,
  }) {
    final l10n = AppLocalizations.of(context)!;

    if (vocabulary != null && !vocabulary.isEmpty) {
      final fromCatalog = vocabulary.nameFor(
        rawName,
        Localizations.localeOf(context).languageCode,
      );
      if (fromCatalog != null && fromCatalog.trim().isNotEmpty) {
        return fromCatalog;
      }
    }

    final cleaned =
        rawName.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');

    final canonical =
        RecoveryDomainService.majorMuscleGroupFor(cleaned) ?? cleaned;

    switch (canonical) {
      case 'chest':
        return l10n.muscleChest;
      case 'back':
        return l10n.muscleBack;
      case 'shoulders':
        return l10n.muscleShoulders;
      case 'biceps':
        return l10n.muscleBiceps;
      case 'triceps':
        return l10n.muscleTriceps;
      case 'quads':
        return l10n.muscleQuads;
      case 'hamstrings':
        return l10n.muscleHamstrings;
      case 'legs':
        return l10n.muscleLegs;
      case 'arms':
        return l10n.muscleArms;
      case 'calves':
        return l10n.muscleCalves;
      case 'lower back':
        return l10n.muscleLowerBack;
      case 'abs':
        return l10n.muscleAbs;
      case 'adductors':
        return l10n.muscleAdductors;
      case 'forearms':
        return l10n.muscleForearms;
      case 'traps':
      case 'trapezius':
      case 'neck':
        return l10n.muscleTraps;
      case 'obliques':
        return l10n.muscleObliques;
      default:
        if (rawName.isEmpty) return '';
        return rawName[0].toUpperCase() + rawName.substring(1).toLowerCase();
    }
  }
}
