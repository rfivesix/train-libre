import re

filepath = 'test/workout_database_helper_query_test.dart'

with open(filepath, 'r') as f:
    content = f.read()

helper_func = """
  Future<db.Exercise> _insertTestExercise(db.ExercisesCompanion companion, {String? nameEn, String? nameDe, String? descEn, String? descDe, drift.InsertMode? mode, drift.UpsertClause<db.$ExercisesTable, db.Exercise>? onConflict}) async {
    final row = await database.into(database.exercises).insertReturning(
      companion,
      mode: mode,
      onConflict: onConflict,
    );
    if (nameDe != null) {
      await database.into(database.exerciseTranslations).insertOnConflictUpdate(
        db.ExerciseTranslationsCompanion.insert(
          exerciseId: row.id,
          languageCode: 'de',
          name: nameDe,
          description: descDe != null ? drift.Value(descDe) : const drift.Value.absent(),
        ),
      );
    }
    if (nameEn != null) {
      await database.into(database.exerciseTranslations).insertOnConflictUpdate(
        db.ExerciseTranslationsCompanion.insert(
          exerciseId: row.id,
          languageCode: 'en',
          name: nameEn,
          description: descEn != null ? drift.Value(descEn) : const drift.Value.absent(),
        ),
      );
    }
    return row;
  }
"""

content = content.replace("  late WorkoutLocalDataSource helper;", "  late WorkoutLocalDataSource helper;\n" + helper_func)

def replace_insert(match):
    full_match = match.group(0)
    name_de = re.search(r"nameDe:\s*const drift\.Value\('([^']+)'\)", full_match)
    name_en = re.search(r"nameEn:\s*const drift\.Value\('([^']+)'\)", full_match)
    desc_de = re.search(r"descriptionDe:\s*const drift\.Value\('([^']+)'\)", full_match)
    desc_en = re.search(r"descriptionEn:\s*const drift\.Value\('([^']+)'\)", full_match)
    
    modified = re.sub(r"nameDe:\s*const drift\.Value\('[^']+'\),\s*", "", full_match)
    modified = re.sub(r"nameEn:\s*const drift\.Value\('[^']+'\),\s*", "", modified)
    modified = re.sub(r"descriptionDe:\s*const drift\.Value\('[^']+'\),\s*", "", modified)
    modified = re.sub(r"descriptionEn:\s*const drift\.Value\('[^']+'\),\s*", "", modified)
    
    # Check if the block actually had names
    if not (name_de or name_en):
        return modified
    
    # Change `await database.into(database.exercises).insert` to `await _insertTestExercise`
    modified = re.sub(r"await database\.into\(database\.exercises\)\.insert(?:Returning)?\(", "await _insertTestExercise(", modified)
    
    kwargs = []
    if name_de: kwargs.append(f"nameDe: '{name_de.group(1)}'")
    if name_en: kwargs.append(f"nameEn: '{name_en.group(1)}'")
    if desc_de: kwargs.append(f"descDe: '{desc_de.group(1)}'")
    if desc_en: kwargs.append(f"descEn: '{desc_en.group(1)}'")
    
    # Replace the final `);` with `, kwargs);`
    # We must ensure we only replace the VERY LAST `);` of the insert call!
    modified = re.sub(r"\);\s*$", f", {', '.join(kwargs)});\n", modified)
    return modified

# Regex to match the entire insert block, assuming it ends with `);` on its own line or followed by newline
pattern = re.compile(r"await database\.into\(database\.exercises\)\.insert(?:Returning)?\(\s*db\.ExercisesCompanion\([^;]+?\);\n", re.DOTALL | re.MULTILINE)
content = pattern.sub(replace_insert, content)

pattern2 = re.compile(r"(?:final|var|const)\s+\w+\s*=\s*await database\.into\(database\.exercises\)\.insert(?:Returning)?\(\s*db\.ExercisesCompanion\([^;]+?\);\n", re.DOTALL | re.MULTILINE)
content = pattern2.sub(replace_insert, content)

content = content.replace("""      final refreshedCompanion = db.ExercisesCompanion(
        id: const drift.Value('catalog-1'),
        nameDe: const drift.Value('Bankdruecken Neu'),
        nameEn: const drift.Value('Bench Press New'),
        descriptionDe: const drift.Value('neu'),
        descriptionEn: const drift.Value('new'),
        categoryName: const drift.Value('Strength'),
        musclesPrimary: const drift.Value('["chest"]'),
        musclesSecondary: const drift.Value('["front_delts","triceps"]'),
        source: const drift.Value('base'),
        isCustom: const drift.Value(false),
      );

      await database.into(database.exercises).insert(
            refreshedCompanion,
            onConflict: drift.DoUpdate(
              (_) => refreshedCompanion,
              target: [database.exercises.id],
            ),
          );""", """      final refreshedCompanion = db.ExercisesCompanion(
        id: const drift.Value('catalog-1'),
        categoryName: const drift.Value('Strength'),
        musclesPrimary: const drift.Value('["chest"]'),
        musclesSecondary: const drift.Value('["front_delts","triceps"]'),
        source: const drift.Value('base'),
        isCustom: const drift.Value(false),
      );

      await _insertTestExercise(
            refreshedCompanion,
            nameDe: 'Bankdruecken Neu',
            nameEn: 'Bench Press New',
            descDe: 'neu',
            descEn: 'new',
            onConflict: drift.DoUpdate(
              (_) => refreshedCompanion,
              target: [database.exercises.id],
            ),
          );""")

content = content.replace("""      final refreshedCompanion = db.ExercisesCompanion(
        id: const drift.Value('user-1'),
        nameDe: const drift.Value('Bankdruecken Neu'),
        nameEn: const drift.Value('Bench Press New'),
        descriptionDe: const drift.Value('neu'),
        descriptionEn: const drift.Value('new'),
        categoryName: const drift.Value('Strength'),
        musclesPrimary: const drift.Value('["chest"]'),
        musclesSecondary: const drift.Value('["front_delts","triceps"]'),
        source: const drift.Value('user'),
        isCustom: const drift.Value(false),
      );

      await database.into(database.exercises).insert(
            refreshedCompanion,
            onConflict: drift.DoUpdate(
              (_) => refreshedCompanion,
              target: [database.exercises.id],
            ),
          );""", """      final refreshedCompanion = db.ExercisesCompanion(
        id: const drift.Value('user-1'),
        categoryName: const drift.Value('Strength'),
        musclesPrimary: const drift.Value('["chest"]'),
        musclesSecondary: const drift.Value('["front_delts","triceps"]'),
        source: const drift.Value('user'),
        isCustom: const drift.Value(false),
      );

      await _insertTestExercise(
            refreshedCompanion,
            nameDe: 'Bankdruecken Neu',
            nameEn: 'Bench Press New',
            descDe: 'neu',
            descEn: 'new',
            onConflict: drift.DoUpdate(
              (_) => refreshedCompanion,
              target: [database.exercises.id],
            ),
          );""")

# Post process to fix `nameDe` getters on Rows outside of companions
final_content = content
final_content = re.sub(r"'name_de':\s*\w+Row\.nameDe", "'name_de': ''", final_content)
final_content = re.sub(r"'name_en':\s*\w+Row\.nameEn", "'name_en': ''", final_content)
final_content = re.sub(r"systemRow\.nameDe", "''", final_content)
final_content = re.sub(r"systemRow\.nameEn", "''", final_content)
final_content = re.sub(r"userRow\.nameDe", "''", final_content)
final_content = re.sub(r"userRow\.nameEn", "''", final_content)

with open(filepath, 'w') as f:
    f.write(final_content)

print("Done!")
