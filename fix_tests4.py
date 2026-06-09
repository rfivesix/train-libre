import re

filepath = 'test/workout_database_helper_query_test.dart'

with open(filepath, 'r') as f:
    content = f.read()

# Add the helper function inside main() or at the top of the file
# We will just insert it after `import 'package:train_libre/data/drift_database.dart' as db;`
helper_func = """

Future<db.Exercise> _insertTestExercise(db.AppDatabase database, db.ExercisesCompanion companion, {String? nameEn, String? nameDe, drift.InsertMode? mode, drift.UpsertClause<db.$ExercisesTable, db.Exercise>? onConflict}) async {
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
      ),
    );
  }
  if (nameEn != null) {
    await database.into(database.exerciseTranslations).insertOnConflictUpdate(
      db.ExerciseTranslationsCompanion.insert(
        exerciseId: row.id,
        languageCode: 'en',
        name: nameEn,
      ),
    );
  }
  return row;
}

"""

content = content.replace("import 'package:train_libre/data/drift_database.dart' as db;", "import 'package:train_libre/data/drift_database.dart' as db;\n" + helper_func)

def extract_val(pattern, string):
    m = re.search(pattern, string)
    if m:
        return m.group(1)
    return None

# We will iterate line by line to strip nameDe/nameEn etc from db.ExercisesCompanion
lines = content.split('\n')
result = []
inside_comp = False

for line in lines:
    stripped = line.strip()
    if 'db.ExercisesCompanion(' in stripped:
        inside_comp = True
        result.append(line)
        continue
    
    if inside_comp:
        if stripped == '),' or stripped == ')' or (line.count(')') > line.count('(') and 'drift.Value' not in stripped):
            inside_comp = False
            result.append(line)
            continue
            
        if 'nameDe:' in stripped or 'nameEn:' in stripped or 'descriptionDe:' in stripped or 'descriptionEn:' in stripped:
            continue
            
    result.append(line)

content = '\n'.join(result)

# Replace systemRow.nameDe -> ''
content = re.sub(r"'name_de':\s*\w+Row\.nameDe", "'name_de': ''", content)
content = re.sub(r"'name_en':\s*\w+Row\.nameEn", "'name_en': ''", content)
content = re.sub(r"systemRow\.nameDe", "''", content)
content = re.sub(r"systemRow\.nameEn", "''", content)
content = re.sub(r"userRow\.nameDe", "''", content)
content = re.sub(r"userRow\.nameEn", "''", content)

with open(filepath, 'w') as f:
    f.write(content)

print("Done!")
