enum AssistantDataCategory {
  workouts,
  diary,
  nutrition,
  steps,
  sleep,
  recovery,
  measurements,
  goals,
  routines,
  trainingPlans;

  bool get isCurrentSnapshot =>
      this == goals || this == routines || this == trainingPlans;

  String localizedLabel(String locale) {
    final isDe = locale.toLowerCase().startsWith('de');
    return switch (this) {
      AssistantDataCategory.workouts =>
        isDe ? 'Trainingseinheiten' : 'workouts',
      AssistantDataCategory.diary => isDe ? 'Tagebuch' : 'diary',
      AssistantDataCategory.nutrition => isDe ? 'Ernährung' : 'nutrition',
      AssistantDataCategory.steps => isDe ? 'Schritte' : 'steps',
      AssistantDataCategory.sleep => isDe ? 'Schlaf' : 'sleep',
      AssistantDataCategory.recovery => isDe ? 'Regeneration' : 'recovery',
      AssistantDataCategory.measurements =>
        isDe ? 'Körpermessungen' : 'measurements',
      AssistantDataCategory.goals => isDe ? 'Ziele' : 'goals',
      AssistantDataCategory.routines => isDe ? 'Routinen' : 'routines',
      AssistantDataCategory.trainingPlans =>
        isDe ? 'Trainingspläne' : 'training plans',
    };
  }

  static String localizeName(String rawName, String locale) {
    for (final category in values) {
      if (category.name == rawName) return category.localizedLabel(locale);
    }
    return rawName;
  }
}

String localizeAssistantScopeLabel(String rawLabel, String locale) {
  final isDe = locale.toLowerCase().startsWith('de');
  if (!isDe) return rawLabel;
  final trimmed = rawLabel.trim();
  final lower = trimmed.toLowerCase();
  final inferredDays =
      RegExp(r'^last (\d+) days \(inferred\)$').firstMatch(lower);
  if (inferredDays != null) {
    return 'Letzte ${inferredDays.group(1)} Tage (automatisch gewählt)';
  }
  final lastDays = RegExp(r'^last (\d+) days$').firstMatch(lower);
  if (lastDays != null) {
    return 'Letzte ${lastDays.group(1)} Tage';
  }
  return switch (lower) {
    'current' => 'Aktueller Stand',
    'today' => 'Heute',
    'today (inferred)' => 'Heute (automatisch gewählt)',
    'yesterday' => 'Gestern',
    'last week' => 'Letzte Woche',
    'this week' => 'Diese Woche',
    'last month' => 'Letzter Monat',
    'this month' => 'Dieser Monat',
    'explicit date' => 'Gewähltes Datum',
    'explicit range' => 'Gewählter Zeitraum',
    'since explicit date' => 'Seit gewähltem Datum',
    'inferred period' => 'Automatisch gewählter Zeitraum',
    'date range' => 'Zeitraum',
    'last monday' => 'Letzter Montag',
    'last tuesday' => 'Letzter Dienstag',
    'last wednesday' => 'Letzter Mittwoch',
    'last thursday' => 'Letzter Donnerstag',
    'last friday' => 'Letzter Freitag',
    'last saturday' => 'Letzter Samstag',
    'last sunday' => 'Letzter Sonntag',
    _ => trimmed,
  };
}

String synthesizeAssistantConversationTitle({
  required String prompt,
  String? modelTitle,
  AssistantDataRequest? request,
  required String locale,
}) {
  final cleanedModelTitle = modelTitle
      ?.trim()
      .replaceAll(RegExp(r'^["„“‚‘]+|["“”‘’]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (cleanedModelTitle != null && cleanedModelTitle.isNotEmpty) {
    return cleanedModelTitle.length > 52
        ? '${cleanedModelTitle.substring(0, 52)}…'
        : cleanedModelTitle;
  }
  final isDe = locale.toLowerCase().startsWith('de');
  if (request != null && request.categories.isNotEmpty) {
    final categoryLabels = request.categories
        .take(2)
        .map((c) => _titleCaseCategory(c.localizedLabel(locale)))
        .join(isDe ? ' & ' : ' & ');
    final scope = request.scope;
    if (scope != null) {
      final scopeLabel = localizeAssistantScopeLabel(scope.label, locale)
          .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
          .trim();
      if (scopeLabel.isNotEmpty &&
          !const {
            'Gewähltes Datum',
            'Gewählter Zeitraum',
            'Automatisch gewählter Zeitraum',
            'explicit date',
            'explicit range',
            'inferred period',
            'model period',
          }.contains(scopeLabel)) {
        return '$categoryLabels · $scopeLabel';
      }
      return '$categoryLabels · ${AssistantDateScope._date(scope.start)}';
    }
    return categoryLabels;
  }
  var text = prompt.trim().replaceAll(RegExp(r'\s+'), ' ');
  text = text.replaceFirst(
    RegExp(
      r'^(kannst du mir sagen|kannst du mir zeigen|zeig mir|zeige mir|wie sieht es mit|wie war mein[e]?|was ist mit|can you tell me|can you show me|show me my|show my|how was my|how am i doing with)\s+',
      caseSensitive: false,
    ),
    '',
  );
  text = text.replaceAll(RegExp(r'[?!.]+$'), '').trim();
  if (text.isEmpty) text = prompt.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isNotEmpty) {
    text = '${text[0].toUpperCase()}${text.substring(1)}';
  }
  return text.length > 48 ? '${text.substring(0, 48)}…' : text;
}

String _titleCaseCategory(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

class AssistantDateScope {
  const AssistantDateScope(this.start, this.end, this.label);
  final DateTime start;
  final DateTime end;
  final String label;

  Map<String, dynamic> toJson() => {
        'start': _date(start),
        'end': _date(end),
        'label': label,
        'timezone': start.timeZoneName,
        'startOffsetMinutes': start.timeZoneOffset.inMinutes,
        'endOffsetMinutes': end.timeZoneOffset.inMinutes,
      };

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class AssistantDataRequest {
  const AssistantDataRequest({required this.categories, required this.scope});
  final Set<AssistantDataCategory> categories;
  final AssistantDateScope? scope;

  void validate() {
    if (categories.isEmpty) throw ArgumentError('No data category');
    if (categories.any((category) => !category.isCurrentSnapshot) &&
        scope == null) {
      throw ArgumentError('Date scope required');
    }
    if (scope != null) {
      final days =
          DateTime.utc(scope!.end.year, scope!.end.month, scope!.end.day)
              .difference(DateTime.utc(
                  scope!.start.year, scope!.start.month, scope!.start.day))
              .inDays;
      if (days < 0 || days > 366) {
        throw ArgumentError('Date range must span at most 367 days');
      }
    }
  }
}

/// Resolves local civil dates and relative date expressions. Intent and data
/// categories are proposed by the configured model and validated separately.
class AssistantDateResolver {
  const AssistantDateResolver();

  AssistantDateScope? resolveDate(
    String text, {
    required DateTime now,
    required String locale,
  }) {
    text = text.toLowerCase();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? parseCivil(String value) {
      final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(value);
      final local =
          RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(value);
      final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value);
      if (iso == null && local == null && slash == null) return null;
      final year =
          int.parse((iso ?? local ?? slash)!.group(iso != null ? 1 : 3)!);
      var month = int.parse((iso ?? local ?? slash)!.group(2)!);
      var day = int.parse((iso ?? local ?? slash)!.group(iso != null ? 3 : 1)!);
      if (slash != null) {
        final first = int.parse(slash.group(1)!);
        final second = int.parse(slash.group(2)!);
        final us = locale.toLowerCase().startsWith('en-us');
        final dayFirstLocale =
            RegExp(r'^(de|en-gb|fr|it)').hasMatch(locale.toLowerCase());
        if (!us && !dayFirstLocale && first <= 12 && second <= 12) {
          return null;
        }
        final monthFirst = us || (!dayFirstLocale && second > 12);
        day = monthFirst ? second : first;
        month = monthFirst ? first : second;
      }
      final date = DateTime(year, month, day);
      return date.year == year && date.month == month && date.day == day
          ? date
          : null;
    }

    final dates = RegExp(
            r'\b\d{4}-\d{1,2}-\d{1,2}\b|\b\d{1,2}\.\d{1,2}\.\d{4}\b|\b\d{1,2}/\d{1,2}/\d{4}\b')
        .allMatches(text)
        .map((m) => parseCivil(m.group(0)!))
        .toList();
    if (dates.contains(null) || dates.length > 2) return null;
    if (dates.length == 2) {
      return AssistantDateScope(dates[0]!, dates[1]!, 'explicit range');
    }
    if (dates.length == 1) {
      if (RegExp(r'\b(from|since|ab|seit)\b').hasMatch(text)) {
        return AssistantDateScope(dates[0]!, today, 'since explicit date');
      }
      return AssistantDateScope(dates[0]!, dates[0]!, 'explicit date');
    }
    const namedMonths = <String, int>{
      'january': 1,
      'jan': 1,
      'januar': 1,
      'february': 2,
      'feb': 2,
      'februar': 2,
      'march': 3,
      'mar': 3,
      'märz': 3,
      'maerz': 3,
      'april': 4,
      'apr': 4,
      'may': 5,
      'mai': 5,
      'june': 6,
      'jun': 6,
      'juni': 6,
      'july': 7,
      'jul': 7,
      'juli': 7,
      'august': 8,
      'aug': 8,
      'september': 9,
      'sep': 9,
      'october': 10,
      'oct': 10,
      'oktober': 10,
      'okt': 10,
      'november': 11,
      'nov': 11,
      'december': 12,
      'dec': 12,
      'dezember': 12,
      'dez': 12,
    };
    final monthWord = namedMonths.keys.join('|');
    final monthFirst =
        RegExp('\\b($monthWord)\\s+(\\d{1,2})(?:,?\\s+(\\d{4}))?\\b');
    final dayFirst =
        RegExp('\\b(\\d{1,2})\\.?\\s+($monthWord)(?:\\s+(\\d{4}))?\\b');
    final named = <DateTime>[];
    for (final match in monthFirst.allMatches(text)) {
      final month = namedMonths[match.group(1)]!;
      final day = int.parse(match.group(2)!);
      final explicitYear = match.group(3);
      var year = explicitYear == null ? today.year : int.parse(explicitYear);
      var date = DateTime(year, month, day);
      if (explicitYear == null && date.isAfter(today)) {
        year--;
        date = DateTime(year, month, day);
      }
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      named.add(date);
    }
    for (final match in dayFirst.allMatches(text)) {
      final day = int.parse(match.group(1)!);
      final month = namedMonths[match.group(2)]!;
      final explicitYear = match.group(3);
      var year = explicitYear == null ? today.year : int.parse(explicitYear);
      var date = DateTime(year, month, day);
      if (explicitYear == null && date.isAfter(today)) {
        year--;
        date = DateTime(year, month, day);
      }
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      named.add(date);
    }
    if (named.length == 1) {
      if (RegExp(r'\b(from|since|ab|seit)\b').hasMatch(text)) {
        return AssistantDateScope(named.single, today, 'since explicit date');
      }
      return AssistantDateScope(named.single, named.single, 'explicit date');
    }
    if (named.length == 2) {
      return AssistantDateScope(named.first, named.last, 'explicit range');
    }
    if (named.length > 2) return null;

    // Month-only requests such as "since June", "June until now", and
    // "Juni bis jetzt" are common follow-ups. Treat a month paired with an
    // until-now phrase as a range from its first day through today. A bare
    // month means that calendar month (through today for the current month).
    final monthOnly = RegExp(
      '\\b($monthWord)(?:\\s+(\\d{4}))?\\b',
    ).firstMatch(text);
    if (monthOnly != null) {
      final month = namedMonths[monthOnly.group(1)]!;
      final yearText = monthOnly.group(2);
      var year = yearText == null ? today.year : int.parse(yearText);
      if (yearText == null && month > today.month) year--;
      final start = DateTime(year, month, 1);
      final untilNow = RegExp(
        r'\b(from|since|ab|seit|bis jetzt|bis heute|bis nun|until now|through today|to date|so far)\b',
      ).hasMatch(text);
      if (untilNow) {
        return AssistantDateScope(start, today, 'since ${monthOnly.group(1)}');
      }
      final monthEnd = DateTime(year, month + 1, 0);
      return AssistantDateScope(
        start,
        monthEnd.isAfter(today) ? today : monthEnd,
        monthOnly.group(1)!,
      );
    }
    if (RegExp(r'\b(today|heute)\b').hasMatch(text)) {
      return AssistantDateScope(today, today, 'today');
    }
    if (RegExp(r'\b(yesterday|gestern)\b').hasMatch(text)) {
      final day = DateTime(today.year, today.month, today.day - 1);
      return AssistantDateScope(day, day, 'yesterday');
    }
    const weekdays = <String, int>{
      'monday': 1,
      'montag': 1,
      'tuesday': 2,
      'dienstag': 2,
      'wednesday': 3,
      'mittwoch': 3,
      'thursday': 4,
      'donnerstag': 4,
      'friday': 5,
      'freitag': 5,
      'saturday': 6,
      'samstag': 6,
      'sunday': 7,
      'sonntag': 7,
    };
    final weekday = RegExp(
      r'\b(last|letzten|letzte|vergangenen)\s+(monday|montag|tuesday|dienstag|wednesday|mittwoch|thursday|donnerstag|friday|freitag|saturday|samstag|sunday|sonntag)\b',
    ).firstMatch(text);
    if (weekday != null) {
      var delta = (today.weekday - weekdays[weekday.group(2)]!) % 7;
      if (delta == 0) delta = 7;
      final day = DateTime(today.year, today.month, today.day - delta);
      return AssistantDateScope(day, day, weekday.group(0)!);
    }
    if (RegExp(r'\b(last week|letzte woche|vergangene woche)\b')
        .hasMatch(text)) {
      final start =
          DateTime(today.year, today.month, today.day - today.weekday - 6);
      return AssistantDateScope(
          start, DateTime(start.year, start.month, start.day + 6), 'last week');
    }
    if (RegExp(r'\b(this week|diese woche)\b').hasMatch(text)) {
      final start =
          DateTime(today.year, today.month, today.day - today.weekday + 1);
      return AssistantDateScope(start, today, 'this week');
    }
    if (RegExp(r'\b(last month|letzten monat|letzter monat)\b')
        .hasMatch(text)) {
      final start = DateTime(today.year, today.month - 1, 1);
      final end = DateTime(today.year, today.month, 0);
      return AssistantDateScope(start, end, 'last month');
    }
    if (RegExp(r'\b(this month|diesen monat|dieser monat)\b').hasMatch(text)) {
      return AssistantDateScope(
          DateTime(today.year, today.month, 1), today, 'this month');
    }
    final lastDays =
        RegExp(r'\b(?:last|letzte[nr]?)\s+(\d{1,3})\s+(?:days|tage[n]?)\b')
            .firstMatch(text);
    if (lastDays != null) {
      final days = int.parse(lastDays.group(1)!);
      if (days < 1 || days > 366) return null;
      return AssistantDateScope(
          DateTime(today.year, today.month, today.day - days + 1),
          today,
          'last $days days');
    }
    return null;
  }
}
