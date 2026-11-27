import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Loads the canonical Markdown sources bundled for both the app and website.
/// Only task-relevant pages enter the model context.
class AssistantDocumentationReader {
  AssistantDocumentationReader({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<String> forQuestion(String question) async {
    final text = question.toLowerCase();
    final paths = <String>{
      'documentation/features/ai_assistant_data_access.md',
      'documentation/features/ai_assistant_meal_logging.md',
    };
    if (RegExp(r'\b(routine|routines|routinen|übungen|workout routine)\b')
        .hasMatch(text)) {
      paths.addAll(const [
        'documentation/user_guide/ai_workout_routines.md',
        'documentation/user_guide/workout_routines.md',
        'documentation/user_guide/supersets_and_editing.md',
        'documentation/features/workout_progression_engine.md',
        'documentation/developer/architecture.md',
        'documentation/developer/data_flow_and_state.md',
      ]);
    }
    if (RegExp(r'\b(plan|plans|trainingsplan|trainingspläne|wochenplan|sequenz)\b')
        .hasMatch(text)) {
      paths.addAll(const [
        'documentation/user_guide/training_plans.md',
        'documentation/features/manual_workout_plans.md',
        'documentation/developer/architecture.md',
        'documentation/developer/data_flow_and_state.md',
      ]);
    }
    if (RegExp(
      r'\b(recipe|recipes|rezept|rezepte|meal|mahlzeit|food|essen|lebensmittel|makro|kalorien|protein|nährwert|mikronährstoff|vitamin|mineral|zucker|ballaststoff|koffein|wasser|trinken|eintrag|eintragen|log|track)\b',
    ).hasMatch(text)) {
      paths.addAll(const [
        'documentation/user_guide/ai_chat_food_logging.md',
        'documentation/user_guide/saved_meals.md',
        'documentation/user_guide/logging_food.md',
        'documentation/features/ai_assistant_meal_logging.md',
        'documentation/features/ai_assistant_data_access.md',
        'documentation/features/meal_capture_pipeline.md',
        'documentation/features/macro_analytics.md',
        'documentation/developer/food_search.md',
      ]);
    }
    if (RegExp(
      r'\b(schlaf|sleep|tiefschlaf|rem|wach|einschlaf|aufwach|nap|nickerchen|schlafscore|regelmäßigkeit)\b',
    ).hasMatch(text)) {
      paths.addAll(const [
        'documentation/features/sleep_scoring_engine.md',
        'documentation/user_guide/health_data.md',
      ]);
    }
    if (RegExp(
      r'\b(puls|pulse|herzfrequenz|heart rate|ruhepuls|resting|hrv|sdnn|schritte|steps|apple health|healthkit|health connect|sync)\b',
    ).hasMatch(text)) {
      paths.addAll(const [
        'documentation/user_guide/health_data.md',
        'documentation/features/health_sync_export.md',
      ]);
    }
    if (RegExp(
      r'\b(regeneration|recovery|erholt|erholung|readiness|muskelkater|ermüdung|fatigue|fit|übertraining)\b',
    ).hasMatch(text)) {
      paths.addAll(const [
        'documentation/features/muscle_recovery_model.md',
        'documentation/features/sleep_scoring_engine.md',
      ]);
    }
    if (RegExp(
      r'\b(tdee|verbrauch|erhaltungskalorien|ziel|ziele|goal|goals|abnehmen|zunehmen|cut|bulk|diät|empfehlung|recommendation|check-in|kalorienziel)\b',
    ).hasMatch(text)) {
      paths.addAll(const [
        'documentation/features/bayesian_tdee_estimator.md',
        'documentation/features/adaptive_nutrition_goals.md',
        'documentation/user_guide/weight_goals.md',
        'documentation/user_guide/daily_targets.md',
      ]);
    }
    if (RegExp(
      r'\b(statistik|statistics|pr|prs|bestleistung|rekord|streak|konsistenz|consistency|volumen|volume|trend|korrelation|gewicht|weight|messung|measurement)\b',
    ).hasMatch(text)) {
      paths.addAll(const [
        'documentation/user_guide/training_statistics.md',
        'documentation/user_guide/body_nutrition_statistics.md',
        'documentation/user_guide/measurements.md',
      ]);
    }
    if (RegExp(
      r'\b(supplement|supplemente|supplements|kreatin|creatine|magnesium|vitamin d|omega)\b',
    ).hasMatch(text)) {
      paths.add('documentation/user_guide/logging_supplements.md');
    }
    final sections = <String>[];
    for (final path in paths) {
      try {
        sections.add('## Source: $path\n${await _bundle.loadString(path)}');
      } on FlutterError {
        // An unavailable documentation asset should not block chat.
      }
    }
    return sections.join('\n\n');
  }
}
