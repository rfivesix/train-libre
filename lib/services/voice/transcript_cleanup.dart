// lib/services/voice/transcript_cleanup.dart

/// Tidies a raw dictation transcript into something worth reading back.
///
/// Deliberately local and rule-based rather than a second AI round trip. The
/// transcript is already on its way to the meal analysis, which returns proper
/// structured items — spending another request, another wait and another upload
/// on prettifying text that is about to be replaced buys nothing. What it does
/// buy is the moment where the user sees their own words come back clean, and
/// that has to be instant to be worth anything.
class TranscriptCleanup {
  /// Hesitation sounds and particles that never carry meaning in a meal
  /// description. Kept deliberately short: "like" and "actually" are on nobody's
  /// list here because they can be part of a real sentence, and silently
  /// deleting a real word is far worse than leaving a filler in.
  static const Set<String> fillers = {
    // German
    'äh', 'ähm', 'ähh', 'öh', 'öhm', 'ähem', 'hä',
    'halt', 'quasi', 'sozusagen', 'irgendwie',
    // English
    'uh', 'uhh', 'um', 'umm', 'uhm', 'erm', 'hmm', 'hm',
  };

  /// Multi-word fillers, matched before the single-word pass.
  static const List<String> fillerPhrases = [
    'you know',
    'i mean',
    'sort of',
    'kind of',
  ];

  /// Spoken unit names normalised to their symbols, so "500 Gramm" reads the
  /// same as a typed "500 g".
  static const Map<String, String> unitAliases = {
    'gramm': 'g',
    'gramms': 'g',
    'grams': 'g',
    'gram': 'g',
    'kilogramm': 'kg',
    'kilogramms': 'kg',
    'kilograms': 'kg',
    'kilogram': 'kg',
    'kilo': 'kg',
    'milliliter': 'ml',
    'millilitern': 'ml',
    'millilitre': 'ml',
    'millilitres': 'ml',
    'milliliters': 'ml',
    'liter': 'l',
    'litern': 'l',
    'litre': 'l',
    'litres': 'l',
    'liters': 'l',
  };

  /// Returns [raw] with fillers dropped, stutters collapsed, units normalised
  /// and the first letter capitalised. Returns an empty string for input that
  /// was only noise.
  static String clean(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return '';

    for (final phrase in fillerPhrases) {
      text = text.replaceAll(
        RegExp('\\b${RegExp.escape(phrase)}\\b[,]?', caseSensitive: false),
        ' ',
      );
    }

    final tokens = text.split(RegExp(r'\s+'));
    final kept = <String>[];

    for (final token in tokens) {
      if (token.isEmpty) continue;

      // Compare without punctuation so "ähm," is recognised too, but keep the
      // original token when it survives.
      final bare = token
          .toLowerCase()
          .replaceAll(RegExp(r'''^[^\wäöüß]+|[^\wäöüß]+$'''), '');
      if (bare.isEmpty) continue;
      if (fillers.contains(bare)) continue;

      final unit = unitAliases[bare];
      if (unit != null) {
        kept.add(unit);
        continue;
      }

      // "das das Brot" — dictation repeats a word when the speaker restarts.
      if (kept.isNotEmpty) {
        final previous = kept.last
            .toLowerCase()
            .replaceAll(RegExp(r'''^[^\wäöüß]+|[^\wäöüß]+$'''), '');
        if (previous == bare) continue;
      }

      kept.add(token);
    }

    var result = kept.join(' ');
    // Punctuation left stranded by a removed word.
    result = result.replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1');
    result = result.replaceAll(RegExp(r'([,;:])\1+'), r'$1');
    result = result.replaceAll(RegExp(r'^[\s,;:.]+'), '');
    result = result.trim();

    if (result.isEmpty) return '';
    return result[0].toUpperCase() + result.substring(1);
  }
}
