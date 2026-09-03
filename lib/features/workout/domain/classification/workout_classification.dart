// lib/features/workout/domain/classification/workout_classification.dart
import 'dart:convert';

/// Domain utilities for classifying sets and exercises.
class WorkoutClassification {
  static String normalizeAnalyticsToken(String? value) {
    if (value == null) return '';
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[/\\]+'), ' ')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool looksLikeCardioToken(String? value) {
    final normalized = normalizeAnalyticsToken(value);
    if (normalized.isEmpty) return false;

    const exactCardioTokens = {
      'cardio',
      'run',
      'running',
      'jog',
      'jogging',
      'walk',
      'walking',
      'hike',
      'hiking',
      'bike',
      'biking',
      'cycling',
      'cycle',
      'swim',
      'swimming',
      'rower',
      'rowing',
      'elliptical',
      'treadmill',
      'stairmaster',
      'stepper',
    };

    if (exactCardioTokens.contains(normalized)) return true;

    return normalized.contains('cardio') ||
        normalized.contains('treadmill') ||
        normalized.contains('elliptical') ||
        normalized.contains('stationary bike') ||
        normalized.contains('exercise bike') ||
        normalized.contains('indoor cycling') ||
        normalized.contains('stair master') ||
        normalized.contains('stair climber');
  }

  /// Modalities whose sets are work on the annotated muscle.
  ///
  /// `strength` needs no argument. `plyometric` is in because a box jump is
  /// concentric work on the quads — the user expects leg fatigue and gets it —
  /// and because those 21 exercises already count today: the name heuristic
  /// never caught them, so dropping them would be a fresh regression in
  /// existing statistics rather than a fix.
  ///
  /// Out, and why each:
  ///
  /// * `stretch` and `mobility` — 122 of 868 active exercises. SCHEMA §5 puts
  ///   `role: primary` on the muscle being *stretched*, not the one
  ///   contracting. Adding that to the same sum is not imprecise, it is
  ///   backwards. It barely showed before because most of these had no muscle
  ///   annotation at all; in v2 every one of them does.
  /// * `cardio` — replaces a name heuristic with a data field. Strictly
  ///   better: looksLikeCardioToken catches "Treadmill" and misses "Assault
  ///   Bike Sprints".
  /// * `balance` — three rows, where the primary muscle is the stabiliser.
  ///   The amount is noise; the rule is what matters: what counts is what puts
  ///   a target muscle under load.
  static const Set<String> muscleLoadBearingModalities = {
    'strength',
    'plyometric',
  };

  /// Whether a logged set counts towards volume and recovery.
  ///
  /// [modality] decides when the catalog has an opinion. It is null for rows
  /// written before schema v2 and for every user-created exercise, and those
  /// fall back to the old category/name heuristic — which is why that heuristic
  /// stays rather than being replaced.
  ///
  /// Note what this does *not* look at: whether a weight was entered. A
  /// bodyweight exercise is still work.
  static bool countsTowardsMuscleLoad({
    required String? modality,
    required String? setType,
    required String? categoryName,
    required String? exerciseNameSnapshot,
    required int reps,
  }) {
    if (reps <= 0) return false;
    if (looksLikeCardioToken(setType)) return false;

    final normalizedModality = normalizeAnalyticsToken(modality);
    if (normalizedModality.isNotEmpty) {
      return muscleLoadBearingModalities.contains(normalizedModality);
    }

    if (looksLikeCardioToken(categoryName)) return false;
    if (looksLikeCardioToken(exerciseNameSnapshot)) return false;
    return true;
  }

  static bool isRecoveryStrengthWorkSet({
    required String? modality,
    required String? setType,
    required String? categoryName,
    required String? nameDe,
    required String? nameEn,
    required String? exerciseNameSnapshot,
    required int reps,
  }) {
    if (reps <= 0) return false;

    if (looksLikeCardioToken(setType)) return false;

    final normalizedModality = normalizeAnalyticsToken(modality);
    if (normalizedModality.isNotEmpty) {
      return muscleLoadBearingModalities.contains(normalizedModality);
    }

    if (looksLikeCardioToken(categoryName)) return false;
    if (looksLikeCardioToken(nameDe) ||
        looksLikeCardioToken(nameEn) ||
        looksLikeCardioToken(exerciseNameSnapshot)) {
      return false;
    }

    return true;
  }

  static List<String> parseMuscleList(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    // Fallback for legacy CSV-style muscle lists.
    if (jsonStr.contains(',')) {
      return jsonStr.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }
}
