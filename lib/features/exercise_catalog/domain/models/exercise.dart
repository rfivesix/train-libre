// lib/models/exercise.dart
import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:flutter/widgets.dart';

import 'exercise_text.dart';

export 'exercise_text.dart';

/// Represents a physical exercise in the system.
///
/// Contains information about the exercise name, description, category,
/// and the muscles targeted (primary and secondary).
class Exercise {
  /// Unique identifier for the exercise.
  ///
  /// Can be null if the exercise is newly created and not yet saved to the database.
  final int? id; // Optional for newly created records

  /// The global UUID identifier for database references.
  final String? uuid;

  /// The source tag ('user', 'wger', etc.)
  final String source;

  /// The UUID of the original system exercise replaced by this user exercise override.
  final String? replacesExerciseId;

  /// Name and description per language code.
  ///
  /// Replaces the old `nameDe`/`nameEn`/`descriptionDe`/`descriptionEn`
  /// quartet. The catalog ships 22 languages and the registry lives in the
  /// data repo, so a new language has to be a row here rather than a field —
  /// otherwise every language is an app release.
  ///
  /// Usually holds only the languages a query asked for, not all 22.
  final Map<String, ExerciseText> texts;

  /// The category of the exercise (e.g., "Strength", "Cardio").
  final String categoryName;

  /// An optional path to an image representing the exercise.
  final String? imagePath;

  /// A list of primary muscles targeted by this exercise.
  final List<String> primaryMuscles;

  /// A list of secondary muscles targeted by this exercise.
  final List<String> secondaryMuscles;

  /// Catalog muscle ids, when the exercise has them.
  ///
  /// The precise annotation, as opposed to the fifteen legacy names above.
  /// Empty for user-created exercises and for rows written before schema v2,
  /// and empty on list rows — only the paths that load one exercise fill
  /// these, because that is the only place the precision is rendered.
  final List<String> primaryMuscleIds;
  final List<String> secondaryMuscleIds;

  /// Shape of the log mask: weight_reps, bodyweight_reps, time, time_weight,
  /// distance_time, distance_only. Null before schema v2 and for user-created
  /// exercises, where [categoryName] still decides.
  final String? trackingType;

  /// What the logged number means: external, bodyweight, assisted, variable.
  ///
  /// `assisted` is the one that matters: on an assistance machine the number
  /// is a *reduction* of resistance, so more kilos is easier. Read as load, an
  /// e1RM curve runs exactly backwards and nothing looks wrong.
  final String? loadMode;

  /// Whether a belt or a dumbbell between the feet is a real option here.
  final bool supportsAddedWeight;

  /// Whether this exercise is categorized as Cardio.
  ///
  /// Kept as a name because a lot of call sites ask this question, but it is
  /// now answered by [trackingType] where the catalog has one: `category_name`
  /// conflates body region with training type, which is why a rowing machine
  /// and a rowing barbell movement were the same word.
  bool get isCardio {
    switch (trackingType) {
      case 'distance_time':
      case 'distance_only':
        return true;
      case 'weight_reps':
      case 'bodyweight_reps':
      case 'time_weight':
        return false;
      case 'time':
        // A plank and a treadmill both log a duration. Only the category can
        // still tell them apart, and for `time` it is not misleading.
        return categoryName.trim().toLowerCase() == 'cardio';
    }
    return categoryName.trim().toLowerCase() == 'cardio';
  }

  /// Whether the log mask offers a weight field.
  ///
  /// `bodyweight_reps` gets one only when the exercise supports added weight —
  /// a weighted pull-up is a real thing, a weighted push-up mostly is not.
  bool get logsWeight {
    switch (trackingType) {
      case 'weight_reps':
      case 'time_weight':
        return true;
      case 'bodyweight_reps':
        return supportsAddedWeight;
      case 'time':
      case 'distance_time':
      case 'distance_only':
        return false;
    }
    return !isCardio;
  }

  bool get logsReps {
    switch (trackingType) {
      case 'weight_reps':
      case 'bodyweight_reps':
        return true;
      case 'time':
      case 'time_weight':
      case 'distance_time':
      case 'distance_only':
        return false;
    }
    return !isCardio;
  }

  bool get logsDuration {
    switch (trackingType) {
      case 'time':
      case 'time_weight':
      case 'distance_time':
        return true;
      case 'weight_reps':
      case 'bodyweight_reps':
      case 'distance_only':
        return false;
    }
    return isCardio;
  }

  bool get logsDistance {
    switch (trackingType) {
      case 'distance_time':
      case 'distance_only':
        return true;
      case 'weight_reps':
      case 'bodyweight_reps':
      case 'time':
      case 'time_weight':
        return false;
    }
    return isCardio;
  }

  /// Whether a bigger logged number means a harder set.
  ///
  /// False on an assistance machine, where it means the opposite. Progression
  /// and e1RM must not be computed from a number whose direction they have
  /// backwards; refusing to compute is the honest answer, and a wrong curve
  /// nobody can see is the alternative.
  bool get weightMeansResistance => loadMode != 'assisted';

  /// Creates a new [Exercise] instance.
  const Exercise({
    this.id,
    this.uuid,
    this.source = 'user',
    this.replacesExerciseId,
    required this.texts,
    required this.categoryName,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.primaryMuscleIds = const [],
    this.secondaryMuscleIds = const [],
    this.trackingType,
    this.loadMode,
    this.supportsAddedWeight = false,
    this.imagePath,
  });

  /// An exercise whose text exists in exactly one language.
  ///
  /// What the create-exercise screen produces, and what most tests want.
  Exercise.single({
    this.id,
    this.uuid,
    this.source = 'user',
    this.replacesExerciseId,
    required String languageCode,
    required String name,
    String description = '',
    required this.categoryName,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.primaryMuscleIds = const [],
    this.secondaryMuscleIds = const [],
    this.trackingType,
    this.loadMode,
    this.supportsAddedWeight = false,
    this.imagePath,
  }) : texts = {
          languageCode: ExerciseText(name: name, description: description),
        };

  // ---------- Parsing helpers ----------
  static List<String> _parseMuscleList(dynamic raw) {
    if (raw == null) return const [];
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];

    // JSON array?
    if (s.startsWith('[')) {
      try {
        final data = jsonDecode(s);
        if (data is List) {
          return data
              .map((e) => (e ?? '').toString().trim())
              .where((e) => e.isNotEmpty)
              .cast<String>()
              .toList(growable: false);
        }
      } catch (_) {
        // Falls back to CSV
      }
    }

    // CSV (GROUP_CONCAT)
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  /// Creates an [Exercise] instance from a Map, typically from a database row.
  ///
  /// Reads texts from a `texts` entry (`{lang: {name, description}}`) and
  /// still understands the old flat `name_de`/`name_en` shape, which is what
  /// backups written before this change contain.
  factory Exercise.fromMap(Map<String, Object?> m) {
    final primRaw = m['primaryMuscles_json_de'] ??
        m['primaryMuscles_json_en'] ??
        m['primaryMuscles'];
    final secRaw = m['secondaryMuscles_json_de'] ??
        m['secondaryMuscles_json_en'] ??
        m['secondaryMuscles'];

    return Exercise(
      id: (m['id'] is num) ? (m['id'] as num).toInt() : m['id'] as int?,
      uuid: m['uuid'] as String?,
      source: (m['source'] ?? 'user') as String,
      replacesExerciseId: m['replaces_exercise_id'] as String?,
      texts: _parseTexts(m),
      categoryName: (m['category_name'] ?? '') as String,
      imagePath: m['image_path'] as String?,
      primaryMuscles: _parseMuscleList(primRaw),
      secondaryMuscles: _parseMuscleList(secRaw),
    );
  }

  static Map<String, ExerciseText> _parseTexts(Map<String, Object?> m) {
    final raw = m['texts'];
    if (raw is Map) {
      return {
        for (final entry in raw.entries)
          if (entry.value is Map)
            entry.key.toString(): ExerciseText(
              name: ((entry.value as Map)['name'] ?? '').toString(),
              description:
                  ((entry.value as Map)['description'] ?? '').toString(),
            ),
      };
    }

    // Legacy flat shape, kept because older backups carry it.
    final texts = <String, ExerciseText>{};
    void add(String lang, Object? name, Object? description) {
      final text = (name ?? '').toString().trim();
      if (text.isEmpty) return;
      texts[lang] = ExerciseText(
        name: text,
        description: (description ?? '').toString(),
      );
    }

    add('de', m['name_de'], m['description_de']);
    add('en', m['name_en'], m['description_en']);
    return texts;
  }

  // ---------- Model -> DB (for inserts/updates) ----------
  //
  // Note: We serialize muscles as CSV because the insert path
  // in workout_database_helper currently expects CSV.
  /// Converts the [Exercise] instance to a Map for database storage.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      'source': source,
      if (replacesExerciseId != null)
        'replaces_exercise_id': replacesExerciseId,
      'texts': {
        for (final entry in texts.entries)
          entry.key: {
            'name': entry.value.name,
            'description': entry.value.description,
          },
      },
      'category_name': categoryName,
      'image_path': imagePath,
      'primaryMuscles': jsonEncode(primaryMuscles),
      'secondaryMuscles': jsonEncode(secondaryMuscles),
    };
  }

  // ---------- convenient ----------
  /// Creates a copy of this [Exercise] with the given fields replaced by the new values.
  Exercise copyWith({
    int? id,
    String? uuid,
    String? source,
    String? replacesExerciseId,
    Map<String, ExerciseText>? texts,
    String? categoryName,
    String? imagePath,
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
    List<String>? primaryMuscleIds,
    List<String>? secondaryMuscleIds,
    String? trackingType,
    String? loadMode,
    bool? supportsAddedWeight,
  }) {
    return Exercise(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      source: source ?? this.source,
      replacesExerciseId: replacesExerciseId ?? this.replacesExerciseId,
      texts: texts ?? this.texts,
      categoryName: categoryName ?? this.categoryName,
      imagePath: imagePath ?? this.imagePath,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      primaryMuscleIds: primaryMuscleIds ?? this.primaryMuscleIds,
      secondaryMuscleIds: secondaryMuscleIds ?? this.secondaryMuscleIds,
      trackingType: trackingType ?? this.trackingType,
      loadMode: loadMode ?? this.loadMode,
      supportsAddedWeight: supportsAddedWeight ?? this.supportsAddedWeight,
    );
  }

  /// Replaces the text of one language, leaving the others alone.
  Exercise withText(String languageCode, ExerciseText text) => copyWith(
        texts: {...texts, languageCode: text},
      );

  /// Spawns a custom copy of a system exercise.
  factory Exercise.duplicateAsCustom(Exercise original, {String? newUuid}) {
    return Exercise(
      id: null,
      uuid: newUuid,
      source: 'user',
      replacesExerciseId: original.uuid,
      texts: Map<String, ExerciseText>.from(original.texts),
      categoryName: original.categoryName,
      imagePath: original.imagePath,
      primaryMuscles: List.from(original.primaryMuscles),
      secondaryMuscles: List.from(original.secondaryMuscles),
      primaryMuscleIds: List.from(original.primaryMuscleIds),
      secondaryMuscleIds: List.from(original.secondaryMuscleIds),
      trackingType: original.trackingType,
      loadMode: original.loadMode,
      supportsAddedWeight: original.supportsAddedWeight,
    );
  }

  // ---------- Reading the texts ----------

  /// The name in [languageCode], falling back down the chain.
  ///
  /// The chain is: what was asked for, then English, then German, then
  /// whatever is there. The last step matters more than it looks: a user's own
  /// exercise may exist only in a language nothing else in this app uses, and
  /// showing an empty string would be worse than showing it in Polish.
  String localizedNameFor(String languageCode) {
    for (final code in exerciseLocaleChain(languageCode)) {
      final text = texts[code];
      if (text != null && text.name.trim().isNotEmpty) return text.name;
    }
    for (final text in texts.values) {
      if (text.name.trim().isNotEmpty) return text.name;
    }
    return '';
  }

  String localizedDescriptionFor(String languageCode) {
    for (final code in exerciseLocaleChain(languageCode)) {
      final text = texts[code];
      if (text != null && text.description.trim().isNotEmpty) {
        return text.description;
      }
    }
    for (final text in texts.values) {
      if (text.description.trim().isNotEmpty) return text.description;
    }
    return '';
  }

  /// Returns the name of the exercise localized to the user's language.
  String getLocalizedName(BuildContext context) =>
      localizedNameFor(Localizations.localeOf(context).languageCode);

  /// Returns the description of the exercise localized to the user's language.
  String getLocalizedDescription(BuildContext context) =>
      localizedDescriptionFor(Localizations.localeOf(context).languageCode);

  /// A stable name to key by, independent of who is looking.
  ///
  /// Not a display name. Live sessions keep per-exercise notes and last
  /// performances in maps keyed by name, and match against
  /// `set_logs.exercise_name_snapshot`; those keys must not change when the
  /// user switches the app language, or a running workout loses its notes.
  ///
  /// English where the exercise has it, which is what the code that used
  /// `nameEn` for this was relying on without saying so.
  String get canonicalName => localizedNameFor('en');

  /// The name in a second language, when it differs from [primary].
  ///
  /// The detail screen shows this under the title. Returns null when there is
  /// nothing useful to add.
  String? secondaryNameFor(String languageCode, String primary) {
    for (final code in exerciseLocaleChain(languageCode)) {
      final text = texts[code];
      if (text == null) continue;
      final name = text.name.trim();
      if (name.isNotEmpty && name != primary) return name;
    }
    return null;
  }

  /// Every name this exercise goes by, for matching and lookup.
  Iterable<String> get allNames => texts.values
      .map((t) => t.name.trim())
      .where((name) => name.isNotEmpty)
      .toSet();
}
