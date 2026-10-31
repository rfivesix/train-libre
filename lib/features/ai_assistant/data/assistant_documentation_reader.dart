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
    if (RegExp(r'\b(plan|plans|trainingsplan|trainingspläne|wochenplan)\b')
        .hasMatch(text)) {
      paths.addAll(const [
        'documentation/user_guide/training_plans.md',
        'documentation/features/manual_workout_plans.md',
        'documentation/developer/architecture.md',
        'documentation/developer/data_flow_and_state.md',
      ]);
    }
    if (RegExp(
      r'\b(recipe|recipes|rezept|rezepte|meal|mahlzeit|food|essen|lebensmittel|makro|kalorien|protein|nährwert|eintrag|eintragen|log|track)\b',
    ).hasMatch(text)) {
      paths.addAll(const [
        'documentation/user_guide/ai_chat_food_logging.md',
        'documentation/user_guide/saved_meals.md',
        'documentation/user_guide/logging_food.md',
        'documentation/features/ai_assistant_meal_logging.md',
        'documentation/features/ai_assistant_data_access.md',
        'documentation/features/meal_capture_pipeline.md',
        'documentation/developer/food_search.md',
      ]);
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
