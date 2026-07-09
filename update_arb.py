import json
import glob
import os

locales = {
    'en': {
        "muscleChest": "Chest",
        "muscleBack": "Back",
        "muscleShoulders": "Shoulders",
        "muscleBiceps": "Biceps",
        "muscleTriceps": "Triceps",
        "muscleQuads": "Quadriceps",
        "muscleHamstrings": "Hamstrings",
        "muscleGlutes": "Glutes",
        "muscleCalves": "Calves",
        "muscleLowerBack": "Lower Back",
        "muscleAbs": "Abs",
        "muscleAdductors": "Adductors",
        "muscleForearms": "Forearms",
        "muscleTraps": "Traps",
        "muscleObliques": "Obliques"
    },
    'de': {
        "muscleChest": "Brust",
        "muscleBack": "Rücken",
        "muscleShoulders": "Schultern",
        "muscleBiceps": "Bizeps",
        "muscleTriceps": "Trizeps",
        "muscleQuads": "Quadrizeps",
        "muscleHamstrings": "Oberschenkelrückseite",
        "muscleGlutes": "Gesäß",
        "muscleCalves": "Waden",
        "muscleLowerBack": "Unterer Rücken",
        "muscleAbs": "Bauchmuskeln",
        "muscleAdductors": "Adduktoren",
        "muscleForearms": "Unterarme",
        "muscleTraps": "Nacken",
        "muscleObliques": "Seitliche Bauchmuskeln"
    },
    'fr': {
        "muscleChest": "Pectoraux",
        "muscleBack": "Dos",
        "muscleShoulders": "Épaules",
        "muscleBiceps": "Biceps",
        "muscleTriceps": "Triceps",
        "muscleQuads": "Quadriceps",
        "muscleHamstrings": "Ischio-jambiers",
        "muscleGlutes": "Fessiers",
        "muscleCalves": "Mollets",
        "muscleLowerBack": "Bas du dos",
        "muscleAbs": "Abdos",
        "muscleAdductors": "Adducteurs",
        "muscleForearms": "Avant-bras",
        "muscleTraps": "Trapèzes",
        "muscleObliques": "Obliques"
    },
    'it': {
        "muscleChest": "Pettorali",
        "muscleBack": "Schiena",
        "muscleShoulders": "Spalle",
        "muscleBiceps": "Bicipiti",
        "muscleTriceps": "Tricipiti",
        "muscleQuads": "Quadricipiti",
        "muscleHamstrings": "Femorali",
        "muscleGlutes": "Glutei",
        "muscleCalves": "Polpacci",
        "muscleLowerBack": "Bassa schiena",
        "muscleAbs": "Addominali",
        "muscleAdductors": "Adduttori",
        "muscleForearms": "Avambracci",
        "muscleTraps": "Trapezi",
        "muscleObliques": "Obliqui"
    },
    'ja': {
        "muscleChest": "胸",
        "muscleBack": "背中",
        "muscleShoulders": "肩",
        "muscleBiceps": "上腕二頭筋",
        "muscleTriceps": "上腕三頭筋",
        "muscleQuads": "大腿四頭筋",
        "muscleHamstrings": "ハムストリングス",
        "muscleGlutes": "臀部",
        "muscleCalves": "ふくらはぎ",
        "muscleLowerBack": "腰",
        "muscleAbs": "腹筋",
        "muscleAdductors": "内転筋",
        "muscleForearms": "前腕",
        "muscleTraps": "僧帽筋",
        "muscleObliques": "腹斜筋"
    }
}

for arb_file in glob.glob("lib/l10n/app_*.arb"):
    lang = os.path.basename(arb_file).replace("app_", "").replace(".arb", "")
    with open(arb_file, "r") as f:
        data = json.load(f)
    
    if lang in locales:
        data.update(locales[lang])
    else:
        # fallback to English
        data.update(locales['en'])
        
    with open(arb_file, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
