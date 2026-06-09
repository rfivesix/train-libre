import json
import os
import re

def get_real_placeholders(en_data, key):
    metadata_key = '@' + key
    if metadata_key in en_data and 'placeholders' in en_data[metadata_key]:
        return set(en_data[metadata_key]['placeholders'].keys())
    # Fallback to simple regex if no metadata, but try to avoid plural branches
    text = en_data.get(key, '')
    if not isinstance(text, str): return set()
    # This regex is still imperfect but better than nothing
    return set(re.findall(r'\{([a-zA-Z][a-zA-Z0-9_]*)', text)) - {'plural', 'select', 'gender'}

def check_arb_files(directory):
    en_file = os.path.join(directory, 'app_en.arb')
    with open(en_file, 'r', encoding='utf-8') as f:
        en_data = json.load(f)

    files = [f for f in os.listdir(directory) if f.endswith('.arb') and f != 'app_en.arb']
    
    mismatches = []

    for filename in files:
        filepath = os.path.join(directory, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        for key, value in data.items():
            if not key.startswith('@') and isinstance(value, str):
                en_placeholders = get_real_placeholders(en_data, key)
                if not en_placeholders: continue
                
                # For the 'other' file, we also need to be careful about plural branches
                # Let's just see which placeholders from the EN list (or their likely translations) are present.
                found = re.findall(r'\{([a-zA-Z][a-zA-Z0-9_]*)', value)
                found = set(found) - {'plural', 'select', 'gender'}
                
                # If 'matchedCount' is expected but missing, that's a mismatch we want to see.
                # If there are placeholders NOT in EN and NOT something we'd ignore, it's a mismatch.
                
                # A better way: if 'matchedCount' is in EN but NOT in FOUND, and no other suspicious ones are there.
                if found != en_placeholders:
                    mismatches.append({
                        'file': filename,
                        'key': key,
                        'en': list(en_placeholders),
                        'other': list(found),
                        'other_text': value
                    })
    
    return mismatches

if __name__ == '__main__':
    mismatches = check_arb_files('lib/l10n')
    for m in mismatches:
        print(f"File: {m['file']}, Key: {m['key']}")
        print(f"  EN: {m['en']}")
        print(f"  {m['file'].split('_')[1].split('.')[0].upper()}: {m['other']}")
        # print(f"  Text: {m['other_text']}")
        print("-" * 20)
