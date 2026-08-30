// lib/features/diary/presentation/util/meal_moment_format.dart

import 'package:intl/intl.dart';

import '../../../../util/date_util.dart';

/// Formats when a meal happened, for the subtitle line the review screen and
/// the saved-meal screen both show.
///
/// The date is only spelled out when the meal is not on [today]. Once a meal
/// can be moved to another day, a bare "12:30" stops being enough — the user
/// has no way to tell a lunch moved to last Tuesday from one logged an hour
/// ago — but printing the date on every one of today's meals is noise.
String formatMealMoment(DateTime moment, {DateTime? today, String? locale}) {
  final reference = today ?? DateTime.now();
  final timeStr = DateFormat('HH:mm').format(moment);
  if (moment.isSameDate(reference)) return timeStr;
  return '${DateFormat('E, d MMM', locale).format(moment)} · $timeStr';
}
