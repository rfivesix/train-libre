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
Register configuration objects for Japan (`jp`), France (`fr`), and Italy (`it`) in the country map to support parquet-to-SQLite filtering, correctly prioritizing respective local language tags (`ja`, `fr`, `it`) during extraction.

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
    "ch": {
        "preferred_languages": ("de", "fr", "it", "en"),
        "country_tags": ("en:switzerland", "en:ch", "en:suisse", "en:schweiz"),
    },
    # --- ADDED TARGET COUNTRIES ---
    "fr": {
        "preferred_languages": ("fr", "en"),
        "country_tags": ("en:france", "en:fr"),
    },
    "it": {
        "preferred_languages": ("it", "en"),
        "country_tags": ("en:italy", "en:it"),
    },
    "jp": {
        "preferred_languages": ("ja", "en"),
        "country_tags": ("en:japan", "en:jp"),
    }
}
```

### Base Food Database Pipeline (User-Generated)

The base food SQLite database `train_libre_base_foods.db` is manually compiled and managed. Rather than using relational translation tables, it uses a flat-column schema to store translations for target languages.

**Required Base Food Updates & Verified Schema**:
The physical schema in `train_libre_base_foods.db` contains flat column names matching the newly integrated French, Italian, and Japanese locales:

#### `categories` table schema
```sql
CREATE TABLE categories (
  key      TEXT PRIMARY KEY,
  name_de  TEXT NOT NULL,
  name_en  TEXT NOT NULL,
  emoji    TEXT,
  name_fr  TEXT,
  name_it  TEXT,
  name_ja  TEXT
);
```

#### `products` table schema
```sql
CREATE TABLE products (
  barcode                      TEXT PRIMARY KEY,
  name                         TEXT NOT NULL,
  name_de                      TEXT NOT NULL,
  name_en                      TEXT NOT NULL,
  category                     TEXT NOT NULL REFERENCES categories(key),
  category_de                  TEXT NOT NULL,
  category_en                  TEXT NOT NULL,
  calories                     INTEGER,
  protein                      REAL,
  carbs                        REAL,
  fat                          REAL,
  kj_100g                      INTEGER,
  fiber                        REAL,
  sugar                        REAL,
  salt                         REAL,
  sodium_100g                  REAL,
  calcium_100g                 REAL,
  caffeine_mg_per_100g         REAL,
  ingredients_analysis_tags    TEXT,
  additives_tags               TEXT,
  product_quantity             REAL,
  product_quantity_unit        TEXT,
  is_fluid                     INTEGER,
  name_fr                      TEXT,
  category_fr                  TEXT,
  name_it                      TEXT,
  category_it                  TEXT,
  name_ja                      TEXT,
  category_ja                  TEXT
);
```

During database v23 migration, `BasisDataManager._performBatchImport` reads these exact columns from `train_libre_base_foods.db` and copies them directly into the app's localized Drift database schemas.

---

## 4. Legal & Compliance Localization (Web & App Stores)

To deploy Train Libre updates in the French, Italian, and Japanese App Stores and Google Play Stores, all legally required user-facing compliance documentation must be translated and served directly on the official website.

### Dynamic Client-Side i18n Architecture

Unlike static sites that generate separate HTML files for each language version, the Train Libre website uses a single-page localized template system driven by client-side Javascript.

1. **Static Templates**: All compliance pages (`docs/privacy.html`, `docs/terms.html`, `docs/impressum.html`, and `docs/privacy-policy/index.html`) write structural nodes once, embedding descriptive `data-i18n` translation keys on all translatable elements.
2. **Translation Registry**: A central dictionary (`TRANSLATIONS` inside [script.js](../../docs/script.js)) stores translation strings nested under each locale key (`en`, `de`, `fr`, `it`, `ja`).
3. **Dropdown Menu Navigation**: Each compliance page hosts a language selection dropdown. To support new locales, dropdown items must be appended to the menu list:
   ```html
   <!-- Example: French language selector added to all docs/*.html pages -->
   <button class="dropdown-item" data-lang="fr">
     <span>Français</span>
     <svg class="check-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
       <polyline points="20 6 9 17 4 12"></polyline>
     </svg>
   </button>
   ```
4. **Active State & Screenshot Mapping**: Upon selecting a language, `script.js` updates translation elements, caches the choice in `localStorage`, and maps localized screenshot directory paths (`assets/screenshots/iOS/fr-FR/`, etc.) dynamically.

### Privacy-Hardened & Offline-First Philosophies

Train Libre enforces sandboxed local storage. The translated Privacy Policy and ToS documents must unmissably convey to international users that:
1. **Local Sandbox**: All calorie logs, consumed food entries, workout notes, routine templates, and physiological measurements are stored exclusively inside the local, sandboxed SQLite database on the device.
2. **No Cloud Synchronization**: There is no mandatory cloud backend. Data is never uploaded to Train Libre servers or third-party cloud aggregators unless explicitly exported manually by the user via file backup.
3. **Hardware Isolation**: The architecture relies completely on local execution, aligning perfectly with security-hardened OS setups (like GrapheneOS) that isolate process network scopes.

---

## 5. The "Infinite Localization" Master Checklist
*How to add a new language (e.g., Spanish `es`) in under 15 minutes.*

### Step 1: Add App UI String Translations
1. Create `lib/l10n/app_es.arb`. Copy the JSON structure from `lib/l10n/app_en.arb` and replace values with Spanish translations.
2. Ensure the first key is the locale code: `"@@locale": "es"`.

### Step 2: Register Language in App Settings
1. Open [base_food_language_service.dart](../../lib/services/base_food_language_service.dart). Add `es` to `BaseFoodLanguage` enum.
2. Open [ai_matching_language_service.dart](../../lib/services/ai_matching_language_service.dart). Add `es` to `AiMatchingLanguage` enum.
3. Open [settings_screen.dart](../../lib/features/settings/presentation/settings_screen.dart).
   - In `_baseFoodLanguageLabel` function, add a mapper case returning your newly added ARB string label:
     `BaseFoodLanguage.es => l10n.settingsBaseFoodLanguageSpanish,`
4. Register the new UI label key in both `app_en.arb` and the new `app_es.arb` (e.g. `"settingsBaseFoodLanguageSpanish": "Spanish (Español)"`).

### Step 3: Map Data Pipelines
- **For wger (exercises)**:
  1. Open [create_wger_exercise_db.py](../../script/create_wger_exercise_db.py).
  2. Locate the `LANGUAGE_ID_MAP`. Look up wger's API language ID for Spanish (which is `3`) and add it to the map:
     `3: "es"`
- **For Open Food Facts (food)**:
  1. Open [create_off_food_db.py](../../script/create_off_food_db.py).
  2. Add `es` to the `COUNTRY_CONFIG` map under country key `es` (Spain) or `mx` (Mexico) containing preferred languages list and country tags:
     ```python
     "es": {
         "preferred_languages": ("es", "en"),
         "country_tags": ("en:spain", "en:es"),
     }
     ```
- **For Base Foods (user-generated)**:
  1. Update the flat columns (`name_es`, `category_es`) directly in the `products` and `categories` tables of `train_libre_base_foods.db`.

### Step 4: Localize Web Compliance Pages (script.js & HTML)
1. Open [script.js](../../docs/script.js).
2. Append `es: { ... }` block containing all translated keys for ToS, Privacy Policy, and landing strings.
3. Open all compliance templates in `docs/` (`index.html`, `privacy.html`, `terms.html`, etc.) and append the Spanish `<button class="dropdown-item" data-lang="es">` item inside the `.dropdown-menu` container.
4. Add the Spanish code to the `langFolder` mapping in `script.js` (e.g. `es: "es-ES"`).

### Step 5: Recompile and Run
1. Run local translation compilation:
   ```bash
   flutter gen-l10n
   ```
2. Build and run app:
   ```bash
   flutter run
   ```
   The UI setting, the database queries, and the import scripts will now fully support Spanish.
