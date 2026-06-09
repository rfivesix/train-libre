# Offline-First Relational Localization Architecture

This document defines the architecture and integration strategy for supporting multi-language settings in Train Libre. It provides the implementation blueprint for supporting Japanese (`ja`), French (`fr`), and Italian (`it`), and serves as a step-by-step guide to adding any future locale in under 15 minutes.

---

## 1. Architectural Audit: Discovery & Normalization

The legacy system utilized hardcoded columns (e.g., `name_de`, `name_en`, `description_de`, `description_en`) directly in primary entities:
- **`exercises`**: `nameDe`, `nameEn`, `descriptionDe`, `descriptionEn`
- **`products`**: `name`, `nameDe`, `nameEn`
- **`food_categories`**: `nameDe`, `nameEn`
- **`user_food_overrides`**: `nameDe`, `nameEn`

This approach is **not scalable**; adding support for new languages requires modifying table schemas, running database migrations, and updating entity objects. 

### Relational Schema Transformation (Modular 1:N)

To make the system infinitely scalable, all language-specific fields are factored out into dedicated 1:N translation tables. The main entities now store only non-localizable structural data, referencing translation tables keyed by language code.

```mermaid
erDiagram
    EXERCISES {
        text id PK
        text category_name
        text muscles_primary
        text muscles_secondary
        text image_path
        boolean is_custom
        text source
        integer usage_count
    }
    EXERCISE_TRANSLATIONS {
        integer local_id PK
        text id UNIQUE
        text exercise_id FK
        text language_code
        text name
        text description
    }
    PRODUCTS {
        text id PK
        text barcode UNIQUE
        text brand
        integer calories
        real protein
        real carbs
        real fat
        real sugar
        real fiber
        real salt
        real caffeine
        boolean is_fluid
        boolean is_liquid
        text source
        integer usage_count
    }
    PRODUCT_TRANSLATIONS {
        integer local_id PK
        text id UNIQUE
        text product_id FK
        text language_code
        text name
    }
    EXERCISES ||--o{ EXERCISE_TRANSLATIONS : "has"
    PRODUCTS ||--o{ PRODUCT_TRANSLATIONS : "has"
```

### Drift Tables Mapping

```dart
// lib/data/drift_database.dart

// Normalized Exercises Table (No localization columns)
class Exercises extends Table with HybridId, MetaColumns {
  TextColumn get createdBy => text().nullable()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get musclesPrimary => text().nullable()();
  TextColumn get musclesSecondary => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().withDefault(const Constant('user'))();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  TextColumn get replacesExerciseId =>
      text().nullable().references(Exercises, #id)();
}

// 1:N Translation Table for Exercises
class ExerciseTranslations extends Table with HybridId, MetaColumns {
  TextColumn get exerciseId =>
      text().references(Exercises, #id, onDelete: KeyAction.cascade)();
  TextColumn get languageCode => text()(); // 'en', 'de', 'ja', 'fr', 'it'
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {exerciseId, languageCode}
      ];
}

// Normalized Products Table
class Products extends Table with HybridId, MetaColumns {
  TextColumn get barcode => text().unique()();
  TextColumn get brand => text().nullable()();
  IntColumn get calories => integer()();
  RealColumn get protein => real()();
  RealColumn get carbs => real()();
  RealColumn get fat => real()();
  RealColumn get sugar => real().nullable()();
  RealColumn get fiber => real().nullable()();
  RealColumn get salt => real().nullable()();
  RealColumn get caffeine => real().nullable()();
  RealColumn get caffeineMgPer100g => real().named('caffeine_mg_per_100g').nullable()();
  TextColumn get ingredientsText => text().nullable()();
  TextColumn get ingredientsAnalysisTags => text().nullable()();
  TextColumn get additivesTags => text().nullable()();
  RealColumn get productQuantity => real().nullable()();
  TextColumn get productQuantityUnit => text().nullable()();
  BoolColumn get isFluid => boolean().withDefault(const Constant(false))();
  BoolColumn get isLiquid => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().withDefault(const Constant('user'))();
  TextColumn get category => text().nullable()();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
}

// 1:N Translation Table for Products
class ProductTranslations extends Table with HybridId, MetaColumns {
  TextColumn get productId =>
      text().references(Products, #id, onDelete: KeyAction.cascade)();
  TextColumn get languageCode => text()(); // 'en', 'de', 'ja', 'fr', 'it'
  TextColumn get name => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {productId, languageCode}
      ];
}
```

### Drift Database Migration (Version 22 to 23)

The migration logic in `AppDatabase` performs the table creations, copies legacy column values to the normalized tables, and safely drops obsolete columns using standard SQLite schema-altering syntax.

```dart
// lib/data/drift_database.dart

@override
int get schemaVersion => 23;

// In MigrationStrategy:
if (from < 23) {
  // 1. Create translation tables
  await m.createTable(exerciseTranslations);
  await m.createTable(productTranslations);
  await m.createTable(foodCategoryTranslations);
  await m.createTable(userFoodOverrideTranslations);

  // 2. Backfill exercise translations
  await customStatement('''
    INSERT INTO exercise_translations (id, created_at, updated_at, exercise_id, language_code, name, description)
    SELECT lower(hex(randomblob(16))), strftime('%s','now')*1000, strftime('%s','now')*1000, id, 'de', name_de, description_de
    FROM exercises WHERE name_de IS NOT NULL AND name_de != '';
  ''');
  await customStatement('''
    INSERT INTO exercise_translations (id, created_at, updated_at, exercise_id, language_code, name, description)
    SELECT lower(hex(randomblob(16))), strftime('%s','now')*1000, strftime('%s','now')*1000, id, 'en', name_en, description_en
    FROM exercises WHERE name_en IS NOT NULL AND name_en != '';
  ''');

  // 3. Backfill product translations
  await customStatement('''
    INSERT INTO product_translations (id, created_at, updated_at, product_id, language_code, name)
    SELECT lower(hex(randomblob(16))), strftime('%s','now')*1000, strftime('%s','now')*1000, id, 'de', name_de
    FROM products WHERE name_de IS NOT NULL AND name_de != '';
  ''');
  await customStatement('''
    INSERT INTO product_translations (id, created_at, updated_at, product_id, language_code, name)
    SELECT lower(hex(randomblob(16))), strftime('%s','now')*1000, strftime('%s','now')*1000, id, 'en', name_en
    FROM products WHERE name_en IS NOT NULL AND name_en != '';
  ''');

  // 4. Clean up legacy tables (Recreate or Drop Columns)
  // SQLite 3.35.0+ supports ALTER TABLE DROP COLUMN
  await customStatement('ALTER TABLE exercises DROP COLUMN name_de;');
  await customStatement('ALTER TABLE exercises DROP COLUMN name_en;');
  await customStatement('ALTER TABLE exercises DROP COLUMN description_de;');
  await customStatement('ALTER TABLE exercises DROP COLUMN description_en;');

  await customStatement('ALTER TABLE products DROP COLUMN name_de;');
  await customStatement('ALTER TABLE products DROP COLUMN name_en;');
}
```

---

## 2. Multi-Module Localization Blueprint

### Database Layer (Drift Queries with Fallback)

To fetch translated values, queries join the main table on the translation table using the target locale (e.g., Japanese `ja`). In case a specific language record is missing, the query must fall back:
1. Target Locale (e.g., `ja`)
2. Default Fallback Locale (`en`)
3. Primary fallback (`de`)
4. Any available localized name in the translations table

#### Drift Query Implementation (Exercises)

```dart
// lib/features/workout/data/sources/parts/exercises_queries.dart

Future<List<Exercise>> searchExercises({
  required String query,
  required String languageCode, // User's active database language setting
  List<String> selectedCategories = const [],
}) async {
  final dbInstance = await database;
  final tokens = _tokenizeAndClean(query);

  // We write a robust SQLite query using COALESCE to resolve the translations
  final sql = '''
    SELECT e.*,
           COALESCE(t_target.name, t_en.name, t_de.name, t_any.name) AS display_name,
           COALESCE(t_target.description, t_en.description, t_de.description, t_any.description) AS display_description
    FROM exercises e
    
    -- 1. Left join target locale translation
    LEFT JOIN exercise_translations t_target 
      ON e.id = t_target.exercise_id AND t_target.language_code = ?
      
    -- 2. Left join 'en' fallback translation
    LEFT JOIN exercise_translations t_en 
      ON e.id = t_en.exercise_id AND t_en.language_code = 'en'
      
    -- 3. Left join 'de' fallback translation
    LEFT JOIN exercise_translations t_de 
      ON e.id = t_de.exercise_id AND t_de.language_code = 'de'

    -- 4. Left join first available translation as ultimate safety
    LEFT JOIN (
      SELECT exercise_id, name, description, MIN(language_code) 
      FROM exercise_translations 
      GROUP BY exercise_id
    ) t_any ON e.id = t_any.exercise_id

    WHERE (
      t_target.name LIKE ? OR t_en.name LIKE ? OR t_de.name LIKE ?
    )
    LIMIT 50;
  ''';

  final variables = [
    drift.Variable.withString(languageCode),
    drift.Variable.withString('%$query%'),
    drift.Variable.withString('%$query%'),
    drift.Variable.withString('%$query%'),
  ];

  final rows = await dbInstance.customSelect(
    sql,
    variables: variables,
    readsFrom: {dbInstance.exercises, dbInstance.exerciseTranslations},
  ).get();

  return rows.map((row) {
    final rawExercise = dbInstance.exercises.map(row.data);
    final displayName = row.read<String>('display_name');
    final displayDescription = row.read<String>('display_description');

    return Exercise(
      id: rawExercise.localId,
      uuid: rawExercise.id,
      source: rawExercise.source,
      replacesExerciseId: rawExercise.replacesExerciseId,
      nameDe: rawExercise.source == 'user' ? displayName : '', 
      nameEn: displayName, // Unified display name
      descriptionDe: '',
      descriptionEn: displayDescription ?? '',
      categoryName: rawExercise.categoryName ?? 'Other',
      imagePath: rawExercise.imagePath,
      primaryMuscles: _parseMuscleList(rawExercise.musclesPrimary),
      secondaryMuscles: _parseMuscleList(rawExercise.musclesSecondary),
    );
  }).toList();
}
```

### UI Text Layer (`.arb`)

The application leverages standard `flutter_localizations` configured via `l10n.yaml`. To register Japanese, French, and Italian:

1. **Add ARB Files**:
   - `lib/l10n/app_ja.arb`
   - `lib/l10n/app_fr.arb`
   - `lib/l10n/app_it.arb`

   Each file contains JSON matching the keys of `lib/l10n/app_en.arb`.
   
   Example (`app_ja.arb`):
   ```json
   {
     "@@locale": "ja",
     "appTitle": "トレイン・リブレ",
     "settingsBaseFoodLanguageTitle": "食品データベースの言語",
     "settingsBaseFoodLanguageEnglish": "英語 (English)",
     "settingsBaseFoodLanguageGerman": "ドイツ語 (Deutsch)",
     "settingsBaseFoodLanguageJapanese": "日本語 (Japanese)",
     "settingsBaseFoodLanguageFrench": "フランス語 (French)",
     "settingsBaseFoodLanguageItalian": "イタリア語 (Italian)"
   }
   ```

2. **Run Generator**:
   ```bash
   flutter gen-l10n
   ```
   This compiles classes in `lib/generated/app_localizations.dart` and automatically populates `AppLocalizations.supportedLocales` with `Locale('ja')`, `Locale('fr')`, and `Locale('it')`. No routing configuration updates are required since `lib/main.dart` binds directly to `AppLocalizations.supportedLocales`.

3. **Expand Locale Picker**:
   Update `lib/services/base_food_language_service.dart` and `lib/services/ai_matching_language_service.dart` enums to register the new languages:
   ```dart
   enum BaseFoodLanguage { auto, en, de, ja, fr, it }
   ```

---

## 3. Data Processing Pipelines

### wger Catalog Fetch Pipeline

The python script `script/create_wger_exercise_db.py` queries the wger API and generates the SQLite database `train_libre_training.db` deployed as a release asset. 

**Required Updates for Multi-Language Relational Model**:
1. **API Language Fetching**: Map standard wger language IDs (`1: de`, `2: en`, `3: ja`, `4: fr`, `5: it`, etc.).
2. **Normalized DB Output**: Alter tables created in SQLite output.

```python
# script/create_wger_exercise_db.py

# Map wger API language IDs to ISO 639-1 language codes
LANGUAGE_ID_MAP = {
    1: "de",
    2: "en",
    # Add newly fetched wger translation language IDs
    4: "fr",
    5: "it",
    8: "ja"
}

def process_and_create_db(db_out="train_libre_training.db", ...):
    # Setup connection
    conn = sqlite3.connect(db_out)
    cursor = conn.cursor()

    # Create Normalized Table and translations
    cursor.execute("""
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        category_name TEXT,
        muscles_primary TEXT,
        muscles_secondary TEXT,
        image_path TEXT,
        is_custom INTEGER DEFAULT 0,
        created_by TEXT DEFAULT 'system',
        source TEXT DEFAULT 'base'
      )""")
      
    cursor.execute("""
      CREATE TABLE exercise_translations (
        id TEXT PRIMARY KEY,
        exercise_id TEXT,
        language_code TEXT,
        name TEXT,
        description TEXT,
        FOREIGN KEY(exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )""")

    # Populate Exercise records
    for item in exercises_info_data:
        ex_id = str(item["id"])
        # Insert structural exercise properties...
        cursor.execute("INSERT INTO exercises (...) VALUES (...)", (...))
        
        # Populate translations dynamically
        for translation in item.get("translations", []):
            wger_lang_id = translation.get("language")
            lang_code = LANGUAGE_ID_MAP.get(wger_lang_id)
            if not lang_code:
                continue # Skip unsupported languages
            
            t_id = f"{ex_id}_{lang_code}"
            name = translation.get("name", "").strip()
            desc = clean_html(translation.get("description"))
            
            if name:
                cursor.execute("""
                    INSERT OR REPLACE INTO exercise_translations (id, exercise_id, language_code, name, description)
                    VALUES (?, ?, ?, ?, ?)
                """, (t_id, ex_id, lang_code, name, desc))
```

### Open Food Facts Parquet Pipeline

The python script `script/create_off_food_db.py` filters Open Food Facts parquet exports to compile country-specific SQLite databases.

**Required Updates**:
Register configuration objects for `jp` (Japan), `fr` (France), and `it` (Italy) in the country map to specify preferred language scans.

```python
# script/create_off_food_db.py

COUNTRY_CONFIG: Dict[str, Dict[str, Any]] = {
    "de": {
        "preferred_languages": ("de", "en"),
        "country_tags": ("en:germany",),
    },
    "us": {
        "preferred_languages": ("en",),
        "country_tags": ("en:united-states", "en:united-states-of-america", "en:usa"),
    },
    "uk": {
        "preferred_languages": ("en",),
        "country_tags": ("en:united-kingdom", "en:uk", "en:great-britain"),
    },
    # --- ADDED LOCALES ---
    "jp": {
        "preferred_languages": ("ja", "en"),
        "country_tags": ("en:japan", "en:jp"),
    },
    "fr": {
        "preferred_languages": ("fr", "en"),
        "country_tags": ("en:france", "en:fr"),
    },
    "it": {
        "preferred_languages": ("it", "en"),
        "country_tags": ("en:italy", "en:it"),
    }
}
```

### Base Food Database Pipeline (User-Generated)

The base food SQLite database `train_libre_base_foods.db` is manually compiled and managed. Currently, it only stores name strings for German and English. 

**Required Base Food Updates**:
1. **Source Translations**: During the compilation of the base food database, translations for Japanese (`ja`), French (`fr`), and Italian (`it`) must be inserted into the base food SQLite database's translation schema.
2. **Translation Schema**: The user-generated database schema must reflect the normalized table layout. It must contain the `product_translations` relational table populated with `product_id`, `language_code` (`de`, `en`, `ja`, `fr`, `it`), and the translated `name`.
3. **Import Logic Adaptation**:
   In `BasisDataManager._performBatchImport`, when parsing `BatchImportType.productsBase`, the mapping logic must load associated rows from the base database's `product_translations` table and insert them into the app database's `product_translations` table:
   ```dart
   // When copying base products, we insert structural rows into `products`
   // and all associated localized rows into `product_translations`
   ```

---

## 4. The "Infinite Localization" Master Checklist
*How to add a new language (e.g., Spanish `es`) in under 15 minutes.*

### Step 1: Add App UI String Translations
1. Create `lib/l10n/app_es.arb`. Copy the JSON structure from `lib/l10n/app_en.arb` and replace values with Spanish translations.
2. Ensure the first key is the locale code: `"@@locale": "es"`.

### Step 2: Register Language in App Settings
1. Open [base_food_language_service.dart](file:///Users/richardgeorgschotte/Projekte/train-libre/lib/services/base_food_language_service.dart). Add `es` to `BaseFoodLanguage` enum.
2. Open [ai_matching_language_service.dart](file:///Users/richardgeorgschotte/Projekte/train-libre/lib/services/ai_matching_language_service.dart). Add `es` to `AiMatchingLanguage` enum.
3. Open [settings_screen.dart](file:///Users/richardgeorgschotte/Projekte/train-libre/lib/features/settings/presentation/settings_screen.dart).
   - In `_baseFoodLanguageLabel` function, add a mapper case returning your newly added ARB string label:
     `BaseFoodLanguage.es => l10n.settingsBaseFoodLanguageSpanish,`
4. Register the new UI label key in both `app_en.arb` and the new `app_es.arb` (e.g. `"settingsBaseFoodLanguageSpanish": "Spanish (Español)"`).

### Step 3: Map Data Pipelines
- **For wger (exercises)**:
  1. Open [create_wger_exercise_db.py](file:///Users/richardgeorgschotte/Projekte/train-libre/script/create_wger_exercise_db.py).
  2. Locate the `LANGUAGE_ID_MAP`. Look up wger's API language ID for Spanish (which is `3`) and add it to the map:
     `3: "es"`
- **For Open Food Facts (food)**:
  1. Open [create_off_food_db.py](file:///Users/richardgeorgschotte/Projekte/train-libre/script/create_off_food_db.py).
  2. Add `es` to the `COUNTRY_CONFIG` map under country key `es` (Spain) or `mx` (Mexico) containing preferred languages list and country tags:
     ```python
     "es": {
         "preferred_languages": ("es", "en"),
         "country_tags": ("en:spain", "en:es"),
     }
     ```
- **For Base Foods (user-generated)**:
  1. When compiling/updating `train_libre_base_foods.db`, add Spanish translations to the `product_translations` table using the locale code `es`.

### Step 4: Recompile and Run
1. Run local translation compilation:
   ```bash
   flutter gen-l10n
   ```
2. Build and run app:
   ```bash
   flutter run
   ```
   The UI setting, the database queries, and the import scripts will now fully support Spanish.
