import re

filepath = 'test/workout_database_helper_query_test.dart'

with open(filepath, 'r') as f:
    lines = f.readlines()

result = []
inside_companion = False
companion_id = None
name_de = ""
name_en = ""
desc_de = ""
desc_en = ""
is_insert_returning = False
insert_var_name = ""

def extract_string(line):
    # Extracts the string between the first quote and the last quote on the line
    start = line.find("'")
    end = line.rfind("'")
    if start != -1 and end != -1 and start != end:
        return line[start:end+1]
    return ""

i = 0
while i < len(lines):
    line = lines[i]
    stripped = line.strip()
    
    if 'db.ExercisesCompanion(' in stripped:
        inside_companion = True
        companion_id = None
        name_de = ""
        name_en = ""
        desc_de = ""
        desc_en = ""
        
        # Look back to see if it's an insertReturning and what the variable name is
        # e.g., `final row = await database.into(database.exercises).insertReturning(`
        if i > 0 and 'insertReturning' in lines[i-1]:
            is_insert_returning = True
            m = re.search(r'(final|var)\s+(\w+)\s*=', lines[i-1])
            if m:
                insert_var_name = m.group(2)
            else:
                insert_var_name = "row" # fallback
        else:
            is_insert_returning = False
            insert_var_name = ""
            
        result.append(line)
        i += 1
        continue
        
    if inside_companion:
        # check if end of companion
        if stripped == '),' or stripped == ')' or (line.count(')') > line.count('(') and 'drift.Value' not in stripped):
            inside_companion = False
            result.append(line)
            # Now append the translations if we had an ID
            if (companion_id or is_insert_returning) and (name_de or name_en):
                indent = " " * (len(line) - len(line.lstrip()))
                target_id = companion_id if companion_id else f"{insert_var_name}.id"
                
                # If we don't have an ID but it was just a regular insert, we can't easily insert translations.
                # Fortunately, all tests either use insertReturning or specify an ID.
                
                if name_de:
                    result.append(f"{indent}await database.into(database.exerciseTranslations).insertOnConflictUpdate(\n")
                    result.append(f"{indent}  db.ExerciseTranslationsCompanion.insert(\n")
                    result.append(f"{indent}    exerciseId: {target_id},\n")
                    result.append(f"{indent}    languageCode: 'de',\n")
                    result.append(f"{indent}    name: {name_de},\n")
                    if desc_de: result.append(f"{indent}    description: const drift.Value({desc_de}),\n")
                    result.append(f"{indent}  ),\n")
                    result.append(f"{indent});\n")
                if name_en:
                    result.append(f"{indent}await database.into(database.exerciseTranslations).insertOnConflictUpdate(\n")
                    result.append(f"{indent}  db.ExerciseTranslationsCompanion.insert(\n")
                    result.append(f"{indent}    exerciseId: {target_id},\n")
                    result.append(f"{indent}    languageCode: 'en',\n")
                    result.append(f"{indent}    name: {name_en},\n")
                    if desc_en: result.append(f"{indent}    description: const drift.Value({desc_en}),\n")
                    result.append(f"{indent}  ),\n")
                    result.append(f"{indent});\n")
            i += 1
            continue

        if 'id:' in stripped and 'drift.Value' in stripped:
            val = extract_string(stripped)
            if val: companion_id = val
            result.append(line)
            i += 1
            continue
            
        if 'nameDe:' in stripped:
            val = extract_string(stripped)
            if val: name_de = val
            i += 1
            continue
        if 'nameEn:' in stripped:
            val = extract_string(stripped)
            if val: name_en = val
            i += 1
            continue
        if 'descriptionDe:' in stripped:
            val = extract_string(stripped)
            if val: desc_de = val
            i += 1
            continue
        if 'descriptionEn:' in stripped:
            val = extract_string(stripped)
            if val: desc_en = val
            i += 1
            continue
            
    result.append(line)
    i += 1

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

print("Done!")
