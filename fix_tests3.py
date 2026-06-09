import re

filepath = 'test/workout_database_helper_query_test.dart'

with open(filepath, 'r') as f:
    content = f.read()

# Add the helper function
helper_func = """
  Future<db.Exercise> _insertTestExercise(db.ExercisesCompanion companion, {String? nameEn, String? nameDe, String? descEn, String? descDe, drift.InsertMode? mode, drift.DoUpdate? onConflict}) async {
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

# Insert the helper function after setUp(() async {
content = content.replace('  setUp(() async {', helper_func + '  setUp(() async {')

def replace_insert(match):
    full_match = match.group(0)
    # Extract names and descriptions
    name_de = re.search(r"nameDe:\s*const drift\.Value\('([^']+)'\)", full_match)
    name_en = re.search(r"nameEn:\s*const drift\.Value\('([^']+)'\)", full_match)
    desc_de = re.search(r"descriptionDe:\s*const drift\.Value\('([^']+)'\)", full_match)
    desc_en = re.search(r"descriptionEn:\s*const drift\.Value\('([^']+)'\)", full_match)
    
    # Remove them from the companion string
    modified = re.sub(r"nameDe:\s*const drift\.Value\('[^']+'\),\s*", "", full_match)
    modified = re.sub(r"nameEn:\s*const drift\.Value\('[^']+'\),\s*", "", modified)
    modified = re.sub(r"descriptionDe:\s*const drift\.Value\('[^']+'\),\s*", "", modified)
    modified = re.sub(r"descriptionEn:\s*const drift\.Value\('[^']+'\),\s*", "", modified)
    
    # Change `await database.into(database.exercises).insert` to `await _insertTestExercise`
    # and `insertReturning` as well.
    modified = re.sub(r"await database\.into\(database\.exercises\)\.insert(?:Returning)?\(", "await _insertTestExercise(", modified)
    
    # Add kwargs to the end of _insertTestExercise call. We need to find the end of the db.ExercisesCompanion call 
    # or the end of the `await _insertTestExercise(` call.
    # Actually, we can just insert the kwargs after `db.ExercisesCompanion(...)`
    
    kwargs = []
    if name_de: kwargs.append(f"nameDe: '{name_de.group(1)}'")
    if name_en: kwargs.append(f"nameEn: '{name_en.group(1)}'")
    if desc_de: kwargs.append(f"descDe: '{desc_de.group(1)}'")
    if desc_en: kwargs.append(f"descEn: '{desc_en.group(1)}'")
    
    if not kwargs:
        return modified # no names found
        
    # Find the closing parenthesis of db.ExercisesCompanion.
    # It's usually `),` or `)` before `mode:` or `onConflict:` or the final `);`
    # Let's replace the last `)` before the final `;` with `, ` + ', '.join(kwargs) + `)`
    # This is slightly tricky, we just append kwargs to the `_insertTestExercise` call.
    
    # Since `_insertTestExercise` takes `companion`, `mode`, `onConflict`, we can just replace the final `);` with `, kwargs);` 
    # BUT wait, the `full_match` includes the trailing `);`
    
    # Replace final `);` with `, ` + kwargs + `);`
    modified = re.sub(r"\);\s*$", f", {', '.join(kwargs)});\n", modified)
    return modified

# Regex to match the entire insert block
pattern = re.compile(r"await database\.into\(database\.exercises\)\.insert(?:Returning)?\(\s*db\.ExercisesCompanion\([^;]+?\);\n", re.DOTALL | re.MULTILINE)
content = pattern.sub(replace_insert, content)

# But wait, some are assigned to a variable: `final row = await database.into(database.exercises).insertReturning(`
# Let's use a broader pattern
pattern2 = re.compile(r"(?:final|var|const)\s+\w+\s*=\s*await database\.into\(database\.exercises\)\.insert(?:Returning)?\(\s*db\.ExercisesCompanion\([^;]+?\);\n", re.DOTALL | re.MULTILINE)
content = pattern2.sub(replace_insert, content)

# Also handle `final refreshedCompanion = db.ExercisesCompanion(...)` which is inserted later.
# In `workout_database_helper_query_test.dart`:
#       final refreshedCompanion = db.ExercisesCompanion(
#         id: const drift.Value('catalog-1'),
#         nameDe: const drift.Value('Bankdruecken Neu'),
#         ...
#       );
#       await database.into(database.exercises).insert( refreshedCompanion, ... );
# This is a specific case around line 308. We can fix this one manually in the python script.

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
