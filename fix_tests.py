import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    result = []
    inside_companion = False
    companion_id = None
    name_de = ""
    name_en = ""
    desc_de = ""
    desc_en = ""

    for line in lines:
        stripped = line.strip()
        
        if 'db.ExercisesCompanion(' in stripped:
            inside_companion = True
            companion_id = None
            name_de = ""
            name_en = ""
            desc_de = ""
            desc_en = ""
            result.append(line)
            continue
            
        if inside_companion:
            # check if end of companion
            if line.count(')') > line.count('(') and not 'drift.Value' in stripped and not ')' in stripped and not stripped.endswith(')'):
                # actually it usually ends with `),`
                pass
            if stripped == '),' or stripped == ')':
                inside_companion = False
                result.append(line)
                # Now append the translations if we had an ID
                if companion_id and (name_de or name_en):
                    indent = " " * (len(line) - len(line.lstrip()))
                    if name_de:
                        result.append(f"{indent}await database.into(database.exerciseTranslations).insertOnConflictUpdate(\n")
                        result.append(f"{indent}  db.ExerciseTranslationsCompanion(\n")
                        result.append(f"{indent}    exerciseId: {companion_id},\n")
                        result.append(f"{indent}    languageCode: const drift.Value('de'),\n")
                        result.append(f"{indent}    name: {name_de},\n")
                        if desc_de: result.append(f"{indent}    description: {desc_de},\n")
                        result.append(f"{indent}  ),\n")
                        result.append(f"{indent});\n")
                    if name_en:
                        result.append(f"{indent}await database.into(database.exerciseTranslations).insertOnConflictUpdate(\n")
                        result.append(f"{indent}  db.ExerciseTranslationsCompanion(\n")
                        result.append(f"{indent}    exerciseId: {companion_id},\n")
                        result.append(f"{indent}    languageCode: const drift.Value('en'),\n")
                        result.append(f"{indent}    name: {name_en},\n")
                        if desc_en: result.append(f"{indent}    description: {desc_en},\n")
                        result.append(f"{indent}  ),\n")
                        result.append(f"{indent});\n")
                continue

            if 'id:' in stripped and 'drift.Value' in stripped:
                m = re.search(r'id:\s*(const drift\.Value\([^)]+\))', stripped)
                if m: companion_id = m.group(1)
                
            if 'nameDe:' in stripped:
                m = re.search(r'nameDe:\s*(const drift\.Value\([^)]+\))', stripped)
                if m: name_de = m.group(1)
                continue
            if 'nameEn:' in stripped:
                m = re.search(r'nameEn:\s*(const drift\.Value\([^)]+\))', stripped)
                if m: name_en = m.group(1)
                continue
            if 'descriptionDe:' in stripped:
                m = re.search(r'descriptionDe:\s*(const drift\.Value\([^)]+\))', stripped)
                if m: desc_de = m.group(1)
                continue
            if 'descriptionEn:' in stripped:
                m = re.search(r'descriptionEn:\s*(const drift\.Value\([^)]+\))', stripped)
                if m: desc_en = m.group(1)
                continue
                
        result.append(line)

    # Post process to fix `nameDe` getters on Rows outside of companions
    final_content = "".join(result)
    final_content = re.sub(r"'name_de':\s*\w+Row\.nameDe", "'name_de': ''", final_content)
    final_content = re.sub(r"'name_en':\s*\w+Row\.nameEn", "'name_en': ''", final_content)
    final_content = re.sub(r"systemRow\.nameDe", "''", final_content)
    final_content = re.sub(r"systemRow\.nameEn", "''", final_content)
    final_content = re.sub(r"userRow\.nameDe", "''", final_content)
    final_content = re.sub(r"userRow\.nameEn", "''", final_content)

    with open(filepath, 'w') as f:
        f.write(final_content)

process_file('test/workout_session_manager_test.dart')
process_file('test/workout_database_helper_query_test.dart')
print("Done!")
