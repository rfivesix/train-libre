import '../../statistics/domain/recovery_domain_service.dart';

/// Returns one display value for each muscle group, ignoring case and
/// whitespace differences found across catalog sources.
List<String> deduplicateMuscleGroups(Iterable<String> muscles) {
  final byNormalizedName = <String, String>{};
  for (final muscle in muscles) {
    final trimmed = muscle.trim();
    if (trimmed.isEmpty) continue;
    byNormalizedName.putIfAbsent(
      RecoveryDomainService.normalizeMuscleName(trimmed),
      () => trimmed,
    );
  }
  return byNormalizedName.values.toList();
}

/// The stable group key shown to beginners and advanced users.
///
/// Catalog rows can be as specific as `lats` or `upper back`, while the
/// simplified experience deliberately presents both as one `back` choice.
/// Unknown names retain their normalized value so no user-created muscle is
/// silently lost.
String coarseMuscleGroupKey(String muscle) {
  final normalized = RecoveryDomainService.normalizeMuscleName(muscle);
  if (normalized.isEmpty) return '';
  // Fine-grained catalog heads do not all appear in the recovery alias map,
  // but their parent is unambiguous for the simplified selector.
  if (normalized.startsWith('biceps ')) return 'biceps';
  if (normalized.startsWith('triceps ')) return 'triceps';
  return RecoveryDomainService.majorMuscleGroupFor(normalized) ?? normalized;
}

/// Folds precise muscle names into the one selection each simplified label
/// represents. The returned values are canonical group keys, ready for both
/// localization and persistence.
List<String> coarsenMuscleGroups(Iterable<String> muscles) {
  final seen = <String>{};
  final groups = <String>[];
  for (final muscle in muscles) {
    final group = coarseMuscleGroupKey(muscle);
    if (group.isNotEmpty && seen.add(group)) groups.add(group);
  }
  return groups;
}

/// Keeps one source value for every visible label.
///
/// Even in pro mode legacy catalog aliases can render identically (`lats` and
/// `back` both become "Back"). Rendering one chip per source value would make
/// a person select the same visible muscle several times.
List<String> deduplicateMuscleGroupsByLabel(
  Iterable<String> muscles,
  String Function(String muscle) labelFor,
) {
  final seen = <String>{};
  final result = <String>[];
  for (final muscle in muscles) {
    final label = labelFor(muscle).trim();
    if (label.isEmpty) continue;
    if (seen.add(label.toLowerCase())) result.add(muscle);
  }
  return result;
}

/// Human-readable, precise label for the pro selector.
///
/// The broad localization helper intentionally maps `lats` to "Back" for
/// novice-facing screens. That loses the information a pro explicitly asked
/// to select, so this path preserves the catalog's actual muscle name.
String preciseMuscleLabel(String muscle) {
  final normalized = RecoveryDomainService.normalizeMuscleName(muscle);
  if (normalized.isEmpty) return '';
  return normalized
      .split(' ')
      .map(
        (word) => word.length <= 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
