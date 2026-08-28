# Entwicklungsplan bis 1.2.0 Release

Stand: 2026-08-28, Basis `develop` @ `877ed0a6` (1.2.0-beta.3).
Grundlage: Testrunde auf iPhone 16 Pro.

Reihenfolge = Release-Reihenfolge. P0 blockt den Release, P1 sollte rein, P2 ist
Politur, die notfalls in 1.2.1 kann.

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

## P0 — Release-Blocker

### 1. Datenverlust im Live-Workout beim App-Kill

**Symptom:** App während laufendem Workout schließen → Pausen einzelner Übungen
teils weg, Sätze und eingestellte Werte (kg, RIR, Reps) zurückgesetzt,
Reihenfolge vertauscht, teils Sätze gelöscht.

Das ist der schlimmste Punkt der Liste: stiller Verlust von Nutzereingaben in
genau dem Feature, das die App ausmacht. Nichts anderes darf davor gefixt werden.

**Verdacht:** Der Live-Workout-State wird nicht (vollständig) synchron beim
Backgrounding persistiert. `live_workout_view_model.dart` hält
`didChangeAppLifecycleState` (Zeile 319) und einen `_appLifecycleState` — zu
prüfen ist, ob dort tatsächlich geschrieben wird und ob der Schreibvorgang bei
`paused` noch durchläuft, bevor iOS den Prozess einfriert. Das Muster der
Symptome (Reihenfolge vertauscht, einzelne Sätze fehlen) deutet auf zwei
getrennte Ursachen hin, die man auseinanderhalten muss:

- **Persistenz-Lücke:** Feldwerte (kg/RIR/Reps) und Pausen leben im
  Widget-/Controller-State und werden erst bei „Satz abschließen" geschrieben.
  Alles Eingetippte, aber nicht Bestätigte, ist beim Kill weg.
- **Rekonstruktions-Lücke:** Beim Wiederherstellen wird die Übungsliste ohne
  stabile Sortierung neu geladen (fehlendes `ORDER BY` auf der Positionsspalte),
  weshalb die Reihenfolge „zufällig" wirkt. `_onReorderItem`
  ([live_workout_screen.dart:467](../../lib/features/workout/presentation/live_workout_screen.dart))
  schreibt vermutlich nur in-memory.

**Vorgehen:**

1. Reproduzieren mit `SIGKILL` statt sauberem Schließen — Xcode „Stop" auf dem
   Gerät entspricht dem am ehesten. Vorher/Nachher-Zustand als JSON dumpen.
2. Die Datenbank-Tabellen des laufenden Workouts inspizieren (siehe Memo
   „Inspect the simulator container" — erst messen, dann Theorie).
3. Schreibpfad umstellen: jede Eingabe (kg, RIR, Reps, Pause, Reihenfolge)
   debounced (~300 ms) in die DB, plus ein synchroner Flush in
   `AppLifecycleState.paused`/`inactive`.
4. Beim Laden explizit nach Position sortieren.
5. Regressionstest: State schreiben → ViewModel wegwerfen → neu laden →
   identischer State. Der Test muss die Reihenfolge und die nicht bestätigten
   Feldwerte mit abdecken.

**Aufwand:** groß (1–2 Tage). Vermutlich der einzige Punkt, der echte
Architekturänderung braucht.

---

### 2. Stalls von 1–2 s bei Kaltstart und beim Resume

**Symptom:** iPhone 16 Pro, frischer Start oder Resume nach ~2 min im
Hintergrund: 1–2 s eingefrorene UI.

**Konkreter Verdacht Resume:**
[main_screen.dart:203](../../lib/features/app/presentation/main_screen.dart)
ruft in `AppLifecycleState.resumed` synchron `_syncHomeWidgetsNow()` auf, das
über `HomeWidgetSyncService.refresh()` die Statistiken neu berechnet. Der
2-Minuten-Schwellwert des Nutzers passt verdächtig gut zu einem Cache, der
inzwischen abgelaufen ist (`HomeWidgetSyncService.statisticsMaxAge`) — solange
der Cache warm ist, fällt nichts auf; danach läuft die volle Berechnung auf dem
Main Isolate.

**Vorgehen:**

1. Nicht nach Gefühl gehen. Der Mac reproduziert den Jank nicht (siehe Memo
   „Profiling UI jank"); mit dem bereits vorhandenen `jank_recorder.dart` und der
   Telemetrie aus `76a93099` auf dem Gerät messen, Raster- und Build-Zeit
   getrennt.
2. Resume-Pfad: `_syncHomeWidgetsNow()` aus dem kritischen Pfad nehmen —
   entweder einen Frame verzögert (`postFrameCallback` + kurzer Delay) oder die
   Statistikberechnung in einen Isolate (`compute`).
3. Kaltstart getrennt betrachten: messen, was zwischen `runApp` und erstem
   nutzbaren Frame passiert (DB-Öffnung inkl. `reconcileSchema`,
   Katalog-Laden, Provider-Initialisierung). Alles, was nicht für den ersten
   Frame gebraucht wird, hinter den ersten Frame verschieben.
4. Gegenprüfen, ob die Glass-Backdrops beitragen — pro `AppButton` entsteht ein
   eigener `BackdropFilterLayer` (siehe Memo), und der erste Frame nach Resume
   baut sie alle neu auf.

**Aufwand:** mittel bis groß, stark abhängig vom Messergebnis. Erst messen,
dann schätzen.

---

## P1 — sollte in 1.2.0

### 3. Datum/Uhrzeit bei KI-Mahlzeiten nicht änderbar

**Symptom:** Für per KI erfasste Mahlzeiten gibt es keinen Ort, an dem sich
Datum und Uhrzeit ändern lassen.

**Befund:** Kein Bug im engeren Sinn, sondern eine fehlende Funktion.
`ai_meal_review_screen.dart` setzt `_selectedTimestamp` einmal in `initState`
(Zeile 212) auf `initialDate ?? DateTime.now()` und schreibt ihn beim Speichern
(Zeilen 653, 669) — der Wert wird **nirgends** verändert. In Zeile 876 wird er
nur formatiert angezeigt. Und im gesamten `lib/features/diary` existiert kein
einziger `showTimePicker`/`showDatePicker`/`CupertinoDatePicker`. Auch
`meal_entry_screen.dart` zeigt `consumedAt` nur an (Zeile 382).

**Vorgehen:**

1. Einen gemeinsamen Picker-Sheet bauen (Datum + Uhrzeit, plattform-adaptiv wie
   `platform_adaptive_dropdown.dart`) unter `lib/widgets/common/`.
2. Im Review-Screen die vorhandene Zeitanzeige (Zeile 876) antippbar machen und
   `_selectedTimestamp` setzen.
3. Nachträgliche Korrektur im `meal_entry_screen` ebenso — das ist der Ort, an
   dem der Nutzer sie sucht, wenn die Mahlzeit schon gespeichert ist.
4. Beim Speichern nach Zeitänderung prüfen, dass die Mahlzeit im richtigen
   Tages-Log landet (Tageswechsel!) und die Statistik neu berechnet wird.

**Aufwand:** klein bis mittel (halber Tag). Klar abgegrenzt, geringes Risiko —
guter Kandidat, um zwischen den beiden P0-Brocken Fortschritt zu machen.

---

### 4. OpenAI-Modellliste zeigt nur 5.4

**Symptom:** Es werden nur `gpt-5.4`-Varianten angeboten, keine aktuellen
Modelle. Soll live abgefragt werden, nicht fest eingestellt.

**Befund:** Die Live-Abfrage **existiert bereits** —
`getModelOptions` ([ai_service.dart:396](../../lib/services/ai_service.dart))
fragt `_loadDynamicModelIds` und benutzt die hartkodierte Liste nur als
Notfall-Fallback. Wenn also nur die 5.4er erscheinen, greift genau dieser
Fallback (`emergencyFallbackModels`, ai_service.dart:117–124 — dort stehen
exakt die 5.4-Varianten). Drei mögliche Ursachen, in dieser Reihenfolge zu
prüfen:

1. **Die Abfrage schlägt fehl und niemand merkt es.** `_loadOpenAiModels`
   ([ai_network.dart:289](../../lib/services/ai/ai_network.dart)) fängt
   *jeden* Fehler mit `catch (_) { return null; }` ab. Falscher Key, Timeout,
   401 — alles führt stillschweigend zum Fallback. **Das ist zuerst zu
   instrumentieren:** Fehler loggen und in der UI unterscheidbar machen
   (`AiModelOption.isFallback` existiert bereits und wird auf dem Fallback-Pfad
   gesetzt, aber offenbar nicht sichtbar dargestellt).
2. **Der Filter ist zu eng.** Zeile 301 filtert auf
   `id.startsWith('gpt-')`. Alles, was nicht so heißt — die `o`-Reihe und
   künftige Namensschemata — fällt raus, obwohl `_openAiTokenParams`
   (ai_network.dart:21) die `o`-Reihe explizit unterstützt. Dazu 14 weitere
   `contains`-Ausschlüsse, die bei neuen Namen zu Kollateralschaden führen.
3. **Das Ranking drückt Neues nach unten.** `_providerModelScore`
   (ai_service.dart:487–493) vergibt fixe Boni auf die 5.4-IDs und
   `getModelOptions` kappt hart auf `take(10)` (Zeile 406). Ein neueres Modell
   ohne Eintrag in den `rankingHints` bekommt nur den generischen
   `_numericFreshnessScore` und kann aus den Top 10 fallen.

**Vorgehen:** Erst (1) klären — solange nicht feststeht, ob die Abfrage
überhaupt durchkommt, ist jede Änderung an Filter und Ranking Raten. Dann den
Filter von Deny-List auf „alles außer eindeutig ungeeigneten Modalitäten"
umstellen, die hartkodierten ID-Boni entfernen (sie sind per Definition am Tag
des nächsten OpenAI-Release veraltet) und das Cap anheben oder ganz streichen.

**Aufwand:** klein bis mittel, sobald die Diagnose steht.

---

## P2 — Politur

### 5. Card-Morph („Card-Warping") ausbauen

Vier getrennte Teilaufgaben. Der Kern ist schon ein globales Widget:
[card_morph_route.dart](../../lib/widgets/common/card_morph_route.dart).

**5a — Rückweg blendet nicht ein (der eigentliche Bug).**
Die Quell-Karte wird während des Flugs über `onSourceVisibilityChanged`
ausgeblendet und erst bei `AnimationStatus.dismissed` wieder eingeblendet, also
am allerletzten Frame und schlagartig auf 100 %. Dazu wird die Kopie der
Quell-Karte im Transition-Stack nur gezeichnet, solange `t < 0.45`, und zwar
ohne Opacity-Rampe — sie erscheint beim Unterschreiten der Schwelle abrupt mit
voller Deckkraft. Genau das beschreibt der Testbefund.
**Fix:** die Quell-Kopie über ein Überlappungsband (z. B. `t` 0.55→0.25)
weich einblenden statt hart bei 0.45 einzuschalten, und die echte Karte
darunter schon vor `dismissed` wiederherstellen, damit die Übergabe
überlappt statt springt.

**5b — Fehlende Stellen.** Aktuell verwendet in `exercise_catalog`,
`add_food`, `diary`, `workout_hub`, `routines`, `statistics_hub` (24
Aufrufstellen). Nachzurüsten:
- Diary → Steps-Widget
- Nutrition Hub komplett —
  [nutrition_hub_screen.dart](../../lib/features/diary/presentation/nutrition_hub_screen.dart)
  navigiert an drei Stellen (Zeilen 138, 273, 288) mit einer Standardroute.

**5c — Bewusst *ohne* Morph:** Settings und die App-Link-Row. Beim Nachrüsten
nicht versehentlich mitnehmen; ein kurzer Kommentar an diesen Aufrufstellen
verhindert, dass es später „vergessen" nachgeholt wird.

**5d — Konsistenz.** Wenn 5b erledigt ist, einmal alle `Navigator.push`-Stellen
durchgehen und entscheiden: Morph oder bewusst nicht. Der Zwischenzustand
„manchmal ja, manchmal nein" ist das, was sich unfertig anfühlt.

**Aufwand:** 5a klein (gezielte Änderung an einer Datei), 5b mittel,
5d Fleißarbeit.

---

### 6. Drag & Drop im Live-Workout

**Symptom:** Das gezogene Element ist teils unsichtbar und klebt nicht genau am
Finger.

**Befund:** Der `proxyDecorator`
([live_workout_screen.dart:853](../../lib/features/workout/presentation/live_workout_screen.dart))
ignoriert den übergebenen `child` und **baut die Karte komplett neu auf** —
`WorkoutCard`, `ListTile`, eigenes Layout. Damit hat das Drag-Proxy
zwangsläufig andere Maße als die Zeile, aus der gezogen wird; genau daher der
Positionsversatz. Die „Unsichtbarkeit" passt zu `Material(elevation: 0.0,
color: Colors.transparent)` über einer Glass-Karte: im Overlay fehlt der
Hintergrund, den die Karte im Listenkontext hatte.

**Fix:** `proxyDecorator` soll den `child` dekorieren, nicht ersetzen — also
`child` in ein `Material` mit Elevation und passender Hintergrundfarbe
(undurchsichtig, nicht `transparent`) wickeln und über `anim` skalieren. Die
Neuaufbau-Variante ersatzlos streichen.

**Aufwand:** klein. Gutes Verhältnis von Wirkung zu Aufwand.

---

### 7. Fehlende Animation im Legal Screen

**Symptom:** Das Ausklappen der Überschriften springt.

**Befund:**
[legal_screen.dart:238](../../lib/features/app/presentation/legal_screen.dart)
macht `setState(() => _isExpanded = !_isExpanded)` und Zeile 267 rendert den
Inhalt hinter einem nackten `if (_isExpanded)`. Keine Animation vorhanden.

**Fix:** `AnimatedSize` + `AnimatedCrossFade` (oder `AnimatedSwitcher`) um den
Inhalt, Chevron über `AnimatedRotation`. Dauer und Kurve aus
`DesignConstants` nehmen, damit es zum Rest passt.

**Aufwand:** sehr klein (unter einer Stunde).

---

## Vorgeschlagene Reihenfolge

| # | Thema | Prio | Aufwand |
|---|---|---|---|
| 1 | Workout-Datenverlust | P0 | groß |
| 2 | Stalls (erst messen) | P0 | mittel–groß |
| 7 | Legal-Screen-Animation | P2 | sehr klein |
| 6 | Drag & Drop Proxy | P2 | klein |
| 5a | Card-Morph Rück-Fade | P2 | klein |
| 3 | Datum/Uhrzeit KI-Mahlzeit | P1 | klein–mittel |
| 4 | OpenAI-Modellliste | P1 | klein–mittel |
| 5b/5d | Card-Morph nachrüsten | P2 | mittel |

Die drei kleinen Punkte (7, 6, 5a) sind bewusst nach vorne gezogen: sie sind
einzeln in Stunden erledigt und liefern sichtbaren Fortschritt, während 1 und 2
in Messphasen hängen. 5b/5d bleibt am Ende, weil es der einzige Punkt ist, der
notfalls sauber in 1.2.1 rutschen kann.

**Vor jedem Release-Build:** `flutter analyze`, `flutter test`, und die
Drift-Schemaversion gegenprüfen (siehe Memo „Drift schema version drift" — eine
erhöhte Version allein reicht nicht, `reconcileSchema` muss den Pfad abdecken).
