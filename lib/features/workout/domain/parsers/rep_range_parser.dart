/// Represents a parsed rep range with minimum and maximum repetitions.
typedef RepRange = ({int min, int max});

/// Parses a target reps string into a [RepRange].
///
/// Supported formats:
/// - Range with hyphen: "8-12" -> (min: 8, max: 12)
/// - Range with en-dash: "8–12" -> (min: 8, max: 12)
/// - Surrounding/inner whitespace: " 8 - 12 " or " 8 – 12 " -> (min: 8, max: 12)
/// - Single value: "8" -> (min: 8, max: 8)
///
/// Returns `null` on invalid or empty formats (e.g. "", "8-12-16", "8-", "-12", "abc", null).
RepRange? parseRepRange(String? input) {
  if (input == null) return null;
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  // Single integer check: e.g. "8"
  final singleInt = int.tryParse(trimmed);
  if (singleInt != null && singleInt > 0) {
    return (min: singleInt, max: singleInt);
  }

  // Check for hyphen or en-dash (\u2013)
  final parts = trimmed.split(RegExp(r'[-–]'));
  if (parts.length != 2) {
    return null;
  }

  final minStr = parts[0].trim();
  final maxStr = parts[1].trim();

  final minVal = int.tryParse(minStr);
  final maxVal = int.tryParse(maxStr);

  if (minVal == null || maxVal == null) {
    return null;
  }

  if (minVal <= 0 || maxVal <= 0 || minVal > maxVal) {
    return null;
  }

  return (min: minVal, max: maxVal);
}
