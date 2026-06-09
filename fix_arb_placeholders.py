import json
import os
import re

# Mapping of non-English placeholder names to English placeholder names
PLACEHOLDER_MAP = {
    # Italian
    'unita': 'unit',
    'differenza': 'difference',
    'numero': 'number',
    'marca': 'brand',
    'calorie': 'calories',
    'grammi': 'grams',
    'ora': 'time',
    'millilitri': 'milliliters',
    'secondi': 'seconds',
    'errore': 'error',
    'percorso': 'path',
    'punteggio': 'score',
    'codice': 'code',
    'ore': 'hours',
    'muscolo': 'muscle',
    'livello': 'level',
    'da': 'from',
    'peso': 'weight',
    'ripetizioni': 'reps',
    'precedente': 'previous',
    'recente': 'recent',
    'data': 'date',
    'muscoli': 'muscles',
    'valore': 'value',
    'percentuale': 'percent',
    'tasso': 'rate',
    'obiettivo': 'goal',
    'inferiore': 'lower',
    'superiore': 'upper',
    'proteine': 'protein',
    'grasso': 'fat',
    'carboidrati': 'carbs',
    # French
    'unite': 'unit',
    'marque': 'brand',
    'heure': 'time',
    'millilitres': 'milliliters',
    'erreur': 'error',
    'chemin': 'path',
    'frais': 'fresh',
    'pret': 'ready',
    'recuperation': 'recovering',
    'heures': 'hours',
    'niveau': 'level',
    'poids': 'weight',
    'precedent': 'previous',
    'recent': 'recent',
    'valeur': 'value',
    'inferieure': 'lower',
    'superieure': 'upper',
    'proteine': 'protein',
    'graisse': 'fat',
    'glucides': 'carbs',
    'grammes': 'grams',
    'secondes': 'seconds',
    'repetitions': 'reps',
    # Japanese
    'Days': 'calorieDays',
}

def fix_placeholders_in_string(text, en_placeholders):
    # Find all placeholders in the text. Placeholder names must start with a letter.
    found = re.findall(r'\{([a-zA-Z][a-zA-Z0-9_]*)', text)
    new_text = text
    for f in found:
        if f in PLACEHOLDER_MAP:
            # We use a more careful replacement to avoid partial matches if names are short
            # but usually they are inside braces so {name} is safe to replace.
            new_text = new_text.replace('{' + f, '{' + PLACEHOLDER_MAP[f])
        elif f not in en_placeholders:
            # If it's not in EN and not in our map, maybe it's another one we missed.
            pass
    return new_text

def fix_arb_files(directory):
    en_file = os.path.join(directory, 'app_en.arb')
    with open(en_file, 'r', encoding='utf-8') as f:
        en_data = json.load(f)

    en_placeholders = {}
    for key, value in en_data.items():
        if not key.startswith('@') and isinstance(value, str):
            en_placeholders[key] = set(re.findall(r'\{([a-zA-Z][a-zA-Z0-9_]*)', value))

    files = [f for f in os.listdir(directory) if f.endswith('.arb') and f != 'app_en.arb']
    
    for filename in files:
        filepath = os.path.join(directory, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        modified = False
        new_data = {}
        
        for key, value in data.items():
            if key.startswith('@'):
                # Handle metadata
                main_key = key[1:]
                if main_key in en_placeholders:
                    if 'placeholders' in value:
                        new_placeholders = {}
                        for p_key, p_val in value['placeholders'].items():
                            if p_key in PLACEHOLDER_MAP:
                                new_placeholders[PLACEHOLDER_MAP[p_key]] = p_val
                                modified = True
                            elif not re.match(r'^[a-zA-Z]', p_key):
                                # Remove numeric placeholders if they leaked into metadata
                                modified = True
                                continue
                            else:
                                new_placeholders[p_key] = p_val
                        
                        # Also check if any EN placeholders are missing in metadata
                        en_set = en_placeholders[main_key]
                        for en_p in en_set:
                            if en_p not in new_placeholders:
                                if key in en_data and 'placeholders' in en_data[key] and en_p in en_data[key]['placeholders']:
                                    new_placeholders[en_p] = en_data[key]['placeholders'][en_p]
                                    modified = True
                                else:
                                    new_placeholders[en_p] = {}
                                    modified = True
                        
                        value['placeholders'] = new_placeholders
                new_data[key] = value
            elif isinstance(value, str):
                if key in en_placeholders:
                    new_val = fix_placeholders_in_string(value, en_placeholders[key])
                    
                    # Fix special cases like aiValidationPartialSaveItemsMessage
                    if key in ['aiValidationPartialSaveItemsMessage', 'aiValidationPartialSaveIngredientsMessage']:
                        # Remove extra braces if present
                        while new_val.endswith('}}}'):
                            new_val = new_val[:-1]
                            modified = True
                    
                    if new_val != value:
                        modified = True
                    new_data[key] = new_val
                else:
                    new_data[key] = value
            else:
                new_data[key] = value

        if modified:
            print(f"Fixing {filename}")
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(new_data, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
    fix_arb_files('lib/l10n')
