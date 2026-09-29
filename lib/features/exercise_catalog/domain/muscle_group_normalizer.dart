/// Returns one display value for each muscle group, ignoring case and
/// whitespace differences found across catalog sources.
List<String> deduplicateMuscleGroups(Iterable<String> muscles) {
  final byNormalizedName = <String, String>{};
  for (final muscle in muscles) {
    final trimmed = muscle.trim();
    if (trimmed.isEmpty) continue;
    byNormalizedName.putIfAbsent(trimmed.toLowerCase(), () => trimmed);
  }
  return byNormalizedName.values.toList();
}
