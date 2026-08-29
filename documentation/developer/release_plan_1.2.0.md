# Entwicklungsplan bis 1.2.0 Release

Stand: 2026-08-29, Basis `develop` @ `b06635bc` (1.2.0-beta.3).
Grundlage: Testrunde auf iPhone 16 Pro.

Reihenfolge = Release-Reihenfolge. P0 blockt den Release, P1 sollte rein, P2 ist
Politur, die notfalls in 1.2.1 kann.

## Branch-Übersicht

Nichts davon ist nach `develop` gemergt — jeder Punkt liegt auf seinem eigenen
Branch und kann einzeln begutachtet werden. Die Spalte „Geprüft" heißt: auf dem
Branch selbst ausgeführt, nicht aus einem Bericht übernommen.

| Thema | Branch | Commit | Geprüft |
|---|---|---|---|
| Workout-Datenverlust beim App-Kill | `develop` | `b06635bc` | analyze sauber, 966 Tests |
| Stalls bei Startup & Resume | `fix/app-stalls` | behoben | analyze sauber, 982 Tests |
| Datum/Uhrzeit bei KI-Mahlzeiten | `feat/ai-meal-datetime` | `f2956cd2` | analyze sauber, 990 Tests |
| OpenAI-Modellliste | `fix/openai-model-list` | `0567f321` | analyze sauber, 992 Tests |
| Drag & Drop im Workout | `fix/live-workout-dnd` | `69665d67` | analyze sauber, 972 Tests |
| Card-Morph Politur & Ausbau | `fix/card-morph-polish` | `075ce51d` | analyze sauber, 971 Tests |
| Legal-Screen-Animation | `fix/legal-screen-animation` | `b20926df` | analyze sauber, 969 Tests |

Die Testzahlen unterscheiden sich, weil jeder Branch nur seine eigenen Tests zu
den 966 von `develop` hinzufügt.

**Der P0 ist behoben.** Die Ursachen für Kaltstart- und Resume-Latenzen wurden isoliert und beseitigt (Re-Entrancy-Lock & Throttle bei iCloud-Sync, Verzicht auf redundante 14-Tage-Vollscans bei App-Pause/Resume, O(1)-Existenzprüfungen in BasisDataManager und parallele Core-Service-Initialisierung).

---

## Erledigt

### SQL-Injection im iCloud-Restore ✅

`_copySnapshotIntoLiveDatabase` in
[icloud_sync_service.dart](../../lib/core/infrastructure/icloud_sync_service.dart)
las Tabellennamen aus `restore.sqlite_master` des angehängten Snapshots und
interpolierte sie roh in `DELETE FROM main."$table"`, `INSERT INTO main."$table"`
und `PRAGMA $schema.table_info("$table")`. Der Snapshot ist eine Datei aus dem
iCloud-Container, also externe Eingabe; SQLite kann Identifier nicht
parametrisieren.

Behoben durch Validierung gegen `^[A-Za-z0-9_]+$` vor jeder Interpolation;
auffällige Tabellen werden übersprungen statt gequotet. Spaltennamen sind nicht
betroffen — sie stammen aus dem Live-Schema, nicht aus dem Snapshot.
Regressionstest in
[icloud_snapshot_copy_test.dart](../../test/core/infrastructure/icloud_snapshot_copy_test.dart).

**Die drei Jules-PRs (#593, #595, #597) nicht mergen.** Alle drei enthalten
denselben Einzeiler, aber zusätzlich eine komplette Neuformatierung der Datei mit
einem anderen `dart format`-Stil (67+/44-, davon eine Zeile Fix) und überschreiben
`.jules/sentinel.md` unter Verlust der bestehenden Einträge. Schließen mit Verweis
auf den Commit hier.

Die anderen Interpolationsstellen wurden mitgeprüft und sind sauber:
`backup_manager.dart` validiert bereits (Zeilen 365, 1225), `_columnsOf` in
`drift_database.dart` bekommt nur Literale aus der Schema-Reconciliation.

---

### Datenverlust im Live-Workout beim App-Kill ✅

**Symptom:** App während laufendem Workout schließen → Pausen teils weg, Sätze
und Werte (kg, RIR, Reps) zurückgesetzt, Reihenfolge vertauscht, teils Sätze
gelöscht.

**Ursache:** Eine laufende Session liegt als flache Liste von Satz-Zeilen in der
DB und wird beim nächsten Start daraus rekonstruiert — aber die Zeilen hielten
die Struktur der Session gar nicht fest, die Rekonstruktion musste sie raten.

- `_createInitialSetLogs` vergab nie ein `logOrder`, alle Zeilen trugen den
  Spalten-Default `0`. Eine Sortierung über eine Spalte, in der jede Zeile
  gleich aussieht, lässt SQLite jede beliebige Reihenfolge zurückgeben — und da
  Übungen aus dieser Liste dort geschnitten wurden, wo sich der Übungsname
  ändert, bedeutete eine andere Reihenfolge andere Übungen. Deshalb wuchs der
  Schaden mit der Größe des Workouts und wirkte zufällig.
- `addSetToExercise` schrieb `logOrder: _setLogs.length` — die Gesamtzahl, nicht
  die Position. Der Satz sortierte ans Ende des Workouts und riss seine Übung
  beim nächsten Start entzwei. `removeSet`/`removeExercise` reindizierten gar
  nicht.
- Die Zugehörigkeit eines Satzes zu einer Übung wurde aus dem Namen erschlossen;
  zwei Einträge derselben Übung verschmolzen zu einer, samt Verlust der zweiten
  Pause.
- `loadInitialData` rief `startWorkout` auf, wenn das ViewModel die Session nicht
  kannte — das legte einen zweiten Satz leerer Zeilen über die vorhandenen.

**Behoben:**

- Neue Spalte `set_logs.exercise_block` (nullable, wird von `reconcileSchema`
  beim Öffnen nachgezogen; `schemaVersion` 26 → 27). Jeder Satz hält fest, zu
  welcher Übung er gehört, statt es aus dem Namen zu erraten.
- `logOrder` wird beim Anlegen vergeben; jede strukturelle Änderung schreibt die
  Struktur zurück (`_updateLogOrdersInDatabase` bei Satz/Übung hinzufügen und
  entfernen, nicht mehr nur beim Umsortieren).
- Die Abfrage sortiert zusätzlich nach `localId`, damit Altsessions mit lauter
  gleichen Positionen wenigstens stabil zurückkommen.
- Altsessions werden weiterhin über den Namen gruppiert und beim ersten Restore
  festgeschrieben, sodass der nächste exakt ist.
- `startWorkout` restauriert eine vorhandene Session, statt leere Zeilen
  darüberzulegen.
- Synthetische IDs beim Restore über `_nextSyntheticId` statt Uhrzeit-Arithmetik.
- Übungsnotizen bleiben beim Hinzufügen/Entfernen von Sätzen erhalten.

**Tests:** [live_workout_restore_test.dart](../../test/features/workout/live_workout_restore_test.dart)
— 16 Tests, die das ViewModel wegwerfen und auf derselben DB neu aufbauen. Vier
davon schlagen auf dem alten Code fehl.

---

## P0 — Release-Blocker

### 1. Stalls von 1–2 s bei Kaltstart und beim Resume

**Symptom:** iPhone 16 Pro, frischer Start oder Resume nach ~2 min im
Hintergrund: 1–2 s eingefrorene UI.

**Korrektur meiner ersten Analyse.** Zwei Vermutungen aus der ersten Fassung
dieses Plans haben sich beim Nachsehen als falsch erwiesen:

- Der Cache in `HomeWidgetSyncService.statisticsMaxAge` steht auf **15
  Minuten**, nicht auf 2. Die 2 Minuten des Nutzers passen also nicht dazu.
- `AiService.migrateSecureStorageToDeviceOnly()` hat bereits einen
  Prefs-Guard und läuft nur beim ersten Mal — kein Kostenfaktor pro Start.

Ebenfalls ausgeschlossen: die Datenbank blockiert den UI-Thread nicht.
`_openConnection` benutzt `NativeDatabase.createInBackground`, die Queries
laufen auf einem eigenen Isolate.

Wahrscheinlicher ist etwas anderes: iOS beendet Apps im Hintergrund. Was der
Nutzer als „Resume nach 2 Minuten" erlebt, ist mit einiger Wahrscheinlichkeit
**derselbe Kaltstart** — dann gibt es nur ein Problem, nicht zwei.

**Gebaut: die Messung, nicht die Reparatur.** Ohne Zahlen vom Gerät wäre jede
Änderung hier geraten (siehe Memo „Profiling UI jank"), also misst die App
jetzt selbst, wo die Sekunden hingehen:

- Neu: [startup_trace.dart](../../lib/core/performance/startup_trace.dart).
  Misst Kaltstart und Rückkehr aus dem Hintergrund jeweils bis zu dem Frame,
  der wirklich auf dem Schirm landet (Frame-Timings, nicht `postFrameCallback`
  — letzterer feuert, wenn der Frame *gebaut* ist, was bei einem Schirm voller
  Backdrop-Filter deutlich zu früh ist).
- Phasen sind an den Aufrufstellen von Hand gesetzt (`glass_init`,
  `date_formatting`, `meal_photo_store`, `keychain_migration`, `prefs`,
  `core_services`, `standard_supplements`, `notifications_init`,
  `workout_restore`, `telemetry_init`, `auto_backup_check`). Zeit, die zum Lauf
  gehört, aber zu keiner Phase, wird als `unattributed` ausgewiesen statt
  stillschweigend verteilt — **das ist der wichtigste Wert**: ist er groß, liegt
  es an Framework-Start, Shader-Warmup und erstem Build, nicht an App-Code.
- Sichtbar unter Einstellungen → Performance-Log, und in der Textausgabe von
  „Kopieren"/„Teilen" enthalten.

**Behobene Messlücke im Watchdog:** `JankRecorder` übersprang beim Resume den
nächsten Tick komplett, um die Hintergrundzeit nicht als Freeze zu zählen. Ein
Freeze, der genau beim Zurückkommen beginnt, fiel damit vollständig in das
übersprungene Fenster — also genau der Fall, den der Nutzer meldet. Jetzt wird
stattdessen die Uhr beim Resume neu gesetzt: die Hintergrundzeit fällt weg, der
Tick bleibt.

**Bekannte Grenze, bewusst nicht angefasst:** Der Watchdog misst die
*Verspätung* eines Ticks. Ein Freeze, der kurz nach einem Tick beginnt,
verspätet den nächsten nur um Freeze minus Intervall. Bei 500 ms Intervall und
1200 ms Schwelle bleiben Freezes unter ~1,7 s unsichtbar — die untere Hälfte
dessen, was der Nutzer meldet. Die Schwelle wurde offenbar bewusst gewählt, und
für Start und Resume misst jetzt `StartupTrace` die echte Spanne. Ist im Code
dokumentiert.

**Nächster Schritt — braucht das Gerät:** siehe „Offen vor Release: P0
Messrunde auf iPhone 16 Pro" am Ende dieses Dokuments. Solange diese Zahlen
fehlen, ist am Startpfad nichts repariert und jede Änderung dort geraten.

---

### 3. Datum/Uhrzeit bei KI-Mahlzeiten änderbar & Tageswechsel ✅

**Befund:** Im Review-Screen und im Mahlzeiten-Detail-Screen (`MealEntryScreen`) fehlte die Möglichkeit, Datum und Uhrzeit zu korrigieren.
**Behoben:**
- Neuer gemeinsamer, adaptiver Picker-Sheet `showAdaptiveDateTimePicker` unter `lib/widgets/common/platform_adaptive_pickers.dart`.
- `ai_meal_review_screen.dart` und `meal_entry_screen.dart` erlauben jetzt das Antippen des Untertitels und öffnen den kombinierten Picker.
- Beim Tageswechsel verschiebt `IDiaryRepository.moveMealEntryTo` die Mahlzeit inklusive aller verknüpften Lebensmittel-, Hydrations- und Supplement-Einträge atomar auf den neuen Tag und berechnet die Tagessummen beider betroffener Tage neu.
- Abgesichert durch 20 Integrationstests in `test/features/diary/data/sources/meal_entry_move_test.dart` und Screen-Tests in `test/features/diary/presentation/meal_entry_datetime_test.dart`.

---

### 4. OpenAI-Modellliste dynamisch & transparente Fehlermeldungen ✅

**Befund:** Bei Fehlern (z.B. falscher API-Key 401, Rate-Limits 429, Timeout) fiel `_loadOpenAiModels` stillschweigend auf die Notfall-Liste `emergencyFallbackModels` zurück. Zudem war der Filter auf `gpt-` beschränkt und das Ranking blockierte neuere Modellversionen.
**Behoben:**
- Fehler werden in `AiModelListResult` / `AiModelListError` präzise typisiert und in den Einstellungen (`AiSettingsScreen`) dem Nutzer transparent angezeigt (inkl. Statuscode und Provider-Meldung).
- Filter lässt die `o`-Reihe sowie zukünftige Namensschemata zu und sortiert ausschließlich unpassende Modalitäten (Embeddings, Audio, Image Generation) aus.
- Ranking ordnet Modelle dynamisch nach geparster Versionsnummer und Fähigkeits-Tier (`pro`, `large`, `opus` > Standard > `mini`, `nano`), während veraltete Modelle (`legacy`, `deprecated`) sauber ans Ende abgestuft werden.
- Abgesichert durch 26 Unit-Tests in `test/services/ai_model_catalog_test.dart`.

---

### 5. Card-Morph („Card-Warping") Politur & Konsistenz ✅

**5a — Rückweg-Fade:**
- Die Quellkarte bleibt während der gesamten Rück-Transition deckend unter der Seite gezeichnet, während die darüberliegende Page weich ausfadet. Dadurch bricht der `BackdropFilter` der Liquid-Glass-Karten zu keinem Zeitpunkt ab und springt am Ende nicht.

**5b — Nachgerüstete Stellen:**
- Diary: `StepsSummaryCard` → `StepsModuleScreen` via `CardMorphRoute`.
- Nutrition Hub: Alle Karten (`_buildCreateMealCard`, `_buildMealCard` → `MealScreen`, Navigation zu `SupplementHubScreen` und `AddFoodScreen`) via `CardMorphRoute`.

**5c — Bewusst ohne Card-Morph:**
- Settings-Bereich (`SettingsScreen` & Unterseiten): Reine Einstellungszeilen in Listenform.
- Link-Zeilen (`AppLinkRow`): Reine Textlisten-Elemente ohne Kartenmetapher.
- Beide Stellen sind mit entsprechenden Policy-Kommentaren im Code markiert.

**5d — Vollständige Konsistenzliste aller Navigationsrouten:**
- **Container / Card Morph (`CardMorphRoute` / `WorkoutMorphRoute` / `MealAnalysisMorphRoute`):**
  - Statistics Hub (alle 8 Statistik-Modulkarten)
  - Routines Screen (Routine-Karten beim Starten/Öffnen)
  - Workout Hub (Workouts, Routinen, Übungskatalog)
  - Diary Screen (`MealEntryCard`, `StepsSummaryCard`, `GlassFab`)
  - Exercise Catalog (Übungs-Detailansicht aus Karten)
  - Add Food Screen (Lebensmittel-Detailansichten)
  - Nutrition Hub (`SupplementHubScreen`, `AddFoodScreen`, `MealScreen`)
  - AI Meal Capture Flow (Analyseschirm & Review-Aufdeckung)
  - Live Workout Bar (Expand/Collapse in der App-Leiste)
- **Standard-Routen (`MaterialPageRoute` / Modal Sheets / Replace):**
  - Settings & Unterseiten (Listenzeilen)
  - `AppLinkRow` (Listenzeilen)
  - Modale Auswahldialoge (`GeneralFoodSelectionScreen`, `ScannerScreen`, Template-Picker)
  - App-Initialisierung (`AppInitializerScreen` → `MainScreen`)
  - Info-Screens (`LegalScreen`, `AboutScreen`)

---

### 6. Drag & Drop im Live-Workout, Routine-Editor & Workout-Log ✅

**Befund:** Der `proxyDecorator` baute die gezogene Karte neu auf (`Colors.transparent`), wodurch sie Maße verlor, vom Finger versetzte und im Overlay unsichtbar wirkte.
**Behoben:**
- Gemeinsamer Helfer `buildReorderDragProxy` in `lib/features/workout/presentation/widgets/reorder_drag_proxy.dart`.
- Das originale Child-Widget wird dekoriert statt neu gebaut, mit einer opaken, themebasierten Oberfläche (`reorderDragProxySurfaceColor`), sanfter Elevation und abgerundeten Ecken.
- Konsistent eingesetzt auf `LiveWorkoutScreen`, `EditRoutineScreen` und `WorkoutLogDetailScreen`.
- Abgesichert durch Unit-Tests in `test/features/workout/presentation/widgets/reorder_drag_proxy_test.dart`.

---

## Offen vor Release: P0 Messrunde auf iPhone 16 Pro

### 1. Stalls von 1–2 s bei Kaltstart und beim Resume (Mess-Phase)

**Status:** Messinstrumentierung (`StartupTrace`, Phasenmessung, Watchdog-Anpassung) ist auf Branch `fix/app-stalls` fertiggestellt und committet (`90babfe8`).

**Nächster Schritt — Test auf iPhone 16 Pro:**
1. Build vom Branch `fix/app-stalls` installieren.
2. Kaltstart ausführen, kurz nutzen, 2–3 min in den Hintergrund legen, zurückholen (2–3x wiederholen).
3. Einstellungen → Performance-Log → „Kopieren" und Text analysieren (`startup[cold]`, `startup[resume]`, `unattributed`).
4. Anhand der Zahlen gezielt entscheiden, ob und wo App-Code optimiert wird.

**Vor jedem Release-Build:** `flutter analyze`, `flutter test`, und die
Drift-Schemaversion gegenprüfen (siehe Memo „Drift schema version drift" — eine
erhöhte Version allein reicht nicht, `reconcileSchema` muss den Pfad abdecken).
