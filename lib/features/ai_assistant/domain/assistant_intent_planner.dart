import 'dart:convert';

import 'assistant_data_request.dart';

enum AssistantIntentKind { chat, data, clarify }

class AssistantIntent {
  const AssistantIntent.chat(this.message, {this.title})
      : kind = AssistantIntentKind.chat,
        request = null;
  const AssistantIntent.clarify(this.message, {this.title})
      : kind = AssistantIntentKind.clarify,
        request = null;
  const AssistantIntent.data(this.request, {this.title})
      : kind = AssistantIntentKind.data,
        message = null;

  final AssistantIntentKind kind;
  final String? message;
  final AssistantDataRequest? request;
  final String? title;
}

/// Builds the pre-approval model request and validates its untrusted result.
/// No app records are part of this prompt or accepted from the model.
class AssistantIntentPlanner {
  const AssistantIntentPlanner({
    AssistantDateResolver dateResolver = const AssistantDateResolver(),
  }) : _dateResolver = dateResolver;

  final AssistantDateResolver _dateResolver;

  String prompt({
    required String message,
    required List<Map<String, String>> context,
    required DateTime now,
    required String locale,
  }) =>
      '''You are deciding how to respond to a Train Libre user. No Train Libre records have been provided. Never claim to have seen their records.
Return exactly one JSON object, without Markdown or explanation:
{"kind":"chat","title":"short 2-5 word topic title","answer":"your conversational answer"} when no app records are needed;
{"kind":"clarify","title":"short 2-5 word topic title","question":"one short, specific question"} only when two plausible interpretations materially change the answer;
{"kind":"data","title":"short 2-5 word topic title","categories":["workouts"],"dateExpression":"last week","scope":{"start":"YYYY-MM-DD","end":"YYYY-MM-DD","label":"last week"}} when app records are needed.
Write "title", "answer", "question", and scope "label" in the language of the user's message (defaulting to locale $locale, e.g. German when locale starts with "de"). "title" must be a concise, contextual 2-5 word summary of the conversation topic, never a raw copy of a long sentence.
Allowed categories: workouts, diary, nutrition, steps, sleep, recovery, measurements, goals, routines, trainingPlans. Choose the smallest useful set. Nutrition means daily totals; diary means individual entries. Goals, routines, and trainingPlans are current snapshots. Recovery is a current estimate. For questions about muscle-building progress, use workouts and measurements; add nutrition for protein/calorie context when useful. Do not imply that body weight alone measures muscle mass. For dated data, infer a narrow period if none was stated: today for diary/nutrition, last 7 days for steps/sleep, last 14 days for workouts, last 30 days for measurements. Resolve month-only ranges such as "since June", "June until now", or "Juni bis jetzt" from the first day of that month through today. For "latest", use a recent bounded period. Include the inferred period in scope. When current snapshots (goals, routines, trainingPlans) are requested together with historical data, include both: the date scope applies to historical categories and snapshots return their current state. Use prior user messages for follow-ups, but request fresh access each time. Do not ask users to name an internal category or use a date format. If they ask generally how they are doing, request a narrow recent view of relevant data. Do not put any purported app records in the answer.
Current local date and time: ${now.toIso8601String()}. Timezone: ${now.timeZoneName}, UTC offset ${now.timeZoneOffset.inMinutes} minutes. Locale: $locale.
Prior conversation context (user messages and assistant replies that did not use app records): ${jsonEncode(context)}
Current user message: ${jsonEncode(message)}''';

  AssistantIntent parse(String raw,
      {required DateTime now, required String locale}) {
    final isDe = locale.toLowerCase().startsWith('de');
    try {
      var text = raw.trim();
      if (text.startsWith('```')) {
        text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
        text = text.replaceFirst(RegExp(r'\s*```$'), '');
      }
      final value = jsonDecode(text);
      if (value is! Map<String, dynamic>) throw const FormatException();
      final title = _shortText(value['title'], 60);
      switch (value['kind']) {
        case 'chat':
          final answer = _shortText(value['answer'], 4000);
          if (answer == null) throw const FormatException();
          return AssistantIntent.chat(answer, title: title);
        case 'clarify':
          final question = _shortText(value['question'], 500);
          if (question == null) throw const FormatException();
          return AssistantIntent.clarify(question, title: title);
        case 'data':
          return AssistantIntent.data(
            _parseRequest(value, now, locale),
            title: title,
          );
        default:
          throw const FormatException();
      }
    } on FormatException {
      return AssistantIntent.clarify(
        isDe
            ? 'Könntest du kurz anders formulieren, was du wissen möchtest?'
            : 'Could you rephrase what you would like to know?',
      );
    } on ArgumentError {
      return AssistantIntent.clarify(
        isDe
            ? 'Könntest du den Zeitraum eingrenzen oder genauer beschreiben, welche Einträge du meinst?'
            : 'Could you narrow the period or describe the records you mean?',
      );
    } on TypeError {
      return AssistantIntent.clarify(
        isDe
            ? 'Könntest du kurz anders formulieren, was du wissen möchtest?'
            : 'Could you rephrase what you would like to know?',
      );
    }
  }

  AssistantDataRequest _parseRequest(
      Map<String, dynamic> value, DateTime now, String locale) {
    final proposed = value['categories'];
    if (proposed is! List || proposed.isEmpty) throw const FormatException();
    final categories = <AssistantDataCategory>{};
    for (final category in proposed) {
      if (category is! String) throw const FormatException();
      final match =
          AssistantDataCategory.values.where((item) => item.name == category);
      if (match.length != 1) throw const FormatException();
      categories.add(match.single);
    }

    AssistantDateScope? scope;
    final expression = value['dateExpression'];
    if (expression != null) {
      if (expression is! String || expression.length > 100) {
        throw const FormatException();
      }
      scope = _dateResolver.resolveDate(expression, now: now, locale: locale);
    }
    if (scope == null && value['scope'] != null) {
      final proposedScope = value['scope'];
      if (proposedScope is! Map<String, dynamic>) throw const FormatException();
      final start = _civilDate(proposedScope['start']);
      final end = _civilDate(proposedScope['end']);
      final label = _shortText(proposedScope['label'], 80) ?? 'inferred period';
      if (start == null || end == null) throw const FormatException();
      scope = AssistantDateScope(start, end, label);
    }
    if (expression != null &&
        scope == null &&
        value['scope'] == null &&
        !RegExp(r'^(current|now|latest|recent)$', caseSensitive: false)
            .hasMatch(expression.trim())) {
      throw const FormatException();
    }
    scope ??= _defaultScope(categories, now);

    if (categories.contains(AssistantDataCategory.recovery) &&
        scope != null &&
        !_sameDay(scope.end, now)) {
      throw ArgumentError('Historical recovery is unavailable');
    }
    final request = AssistantDataRequest(categories: categories, scope: scope);
    request.validate();
    return request;
  }

  AssistantDateScope? _defaultScope(
      Set<AssistantDataCategory> categories, DateTime now) {
    if (categories.every((category) => category.isCurrentSnapshot)) return null;
    final today = DateTime(now.year, now.month, now.day);
    final days = categories.contains(AssistantDataCategory.diary) ||
            categories.contains(AssistantDataCategory.nutrition)
        ? 1
        : categories.contains(AssistantDataCategory.measurements)
            ? 30
            : categories.contains(AssistantDataCategory.workouts) ||
                    categories.contains(AssistantDataCategory.recovery)
                ? 14
                : 7;
    return AssistantDateScope(
        DateTime(today.year, today.month, today.day - days + 1),
        today,
        days == 1 ? 'today (inferred)' : 'last $days days (inferred)');
  }

  DateTime? _civilDate(Object? raw) {
    if (raw is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String? _shortText(Object? value, int maxLength) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty || text.length > maxLength ? null : text;
  }
}
