# Live Activity: Workout (iOS)

Status: implementiert (Swift + Dart), Xcode-Target-Einrichtung offen
Plattform: iOS 16.2+ · Dynamic Island: iPhone 14 Pro und neuer · interaktive Buttons: iOS 17+
Android: nicht Teil dieser Version

---

## 1. Ziel

Während eines laufenden Workouts sieht der Nutzer außerhalb der App, **was als Nächstes ansteht**
und **wie lange die Satzpause noch läuft** — ohne die App zu öffnen und ohne das Gerät zu
entsperren.

Leitsatz für jede Design-Entscheidung: *Ein Blick, keine Interpretation.*

### Out of Scope (v1)

- Android
- Bearbeiten von Gewicht/Wdh/Distanz direkt aus der Live Activity
- Push-Updates über APNs — widerspricht der Offline-first-Ausrichtung; alle Updates sind lokal

---

## 2. Zustände

| ID | Zustand | Bedingung |
|---|---|---|
| **S1** | Satz ausstehend | Kein Pausentimer aktiv, ein nächster Satz existiert |
| **S2** | Pause läuft | Pausentimer aktiv, `jetzt < pauseEndetUm` |
| **S3** | Pause überfällig | `jetzt >= pauseEndetUm`, Satz noch nicht getrackt |
| **S4** | Keine Sätze mehr | Alle geplanten Sätze aller Übungen sind getrackt |
| **S5** | Leer | Workout läuft, aber es gibt keine Übung |

**S3 wird nie von der App gepusht.** Der Übergang S2 → S3 passiert ohne Zutun der App und ändert
das Layout — zu diesem Zeitpunkt ist die App typischerweise suspendiert. Gelöst über
`staleDate = pauseEndetUm` beim Push und `context.isStale` in der View. Dart meldet nur
„rastet nicht mehr" (`setPending`), sobald das Pausenende in der Vergangenheit liegt.

---

## 3. Flächen

### 3.1 Lockscreen / Banner

```
[App-Icon] Push Day                                    17:06

Bankdrücken                                    Satz 3 von 5
W  72,5 kg  ×  8 Wdh  (RIR 2)                           [✓]
```

**Der Satztyp führt die Kennzahlenzeile an**, direkt vor dem Gewicht — nicht als eigene Spalte.
So beginnt der Übungsname an der linken Kante und behält die volle Breite, und der Typ steht bei
dem Wert, den er qualifiziert.

Zeichen **und** Farbe kommen 1:1 aus `SetTypeChip`: Warmup `W`/`#FF9800`, Failure `F`/`#E5253A`,
Dropset `D`/`#2196F3`, Superset `S` und Other `O` neutral `#8E8E93`. **Normale Sätze tragen die
Satznummer**, keinen Buchstaben — so ist das Badge immer sichtbar und trägt immer Information.

**S2** graut die gesamte Kennzahlenzeile inklusive Badge aus (der Satz ist noch nicht dran) und
zeigt darunter eine 3-pt-Haarlinie als Fortschritt plus `−15s · 2:20 · +15s · Skip`.

**S3** nimmt die Ausgrauung zurück, ersetzt die Buttonzeile durch das Häkchen und zeigt
`überfällig seit 0:47` in `#FF6B78` — aufgehellt aus `brandRedColor`, weil die Akzentfarbe in
allen anderen Zuständen „läuft nach Plan" bedeutet.

**S4** zeigt nur die Kopfzeile plus `Übung hinzufügen`, **S5** plus `App öffnen`.

### 3.2 Dynamic Island — Expanded

Inhaltsgleich, enger. Kürzungsreihenfolge: RIR → Satztyp → „von y" → Titel.

### 3.3 Compact

| Zustand | Leading | Trailing |
|---|---|---|
| S1 | Satztyp (Cardio: App-Icon) | `72,5 kg` / `× 8` |
| S2 | `2:20` runterzählend | `72,5 kg` / `× 8` |
| S3 | `0:47` hochzählend, `#FF6B78` | `72,5 kg` / `× 8` |
| S4 / S5 | App-Icon | `+` / — |

Der Satztyp verliert seinen Platz, sobald ein Timer läuft — der Timer ist dort wichtiger.

### 3.4 Minimal

Ein Kreis, genau **ein** Element: Ring mit Restzeit (S2), Überfällig-Zähler (S3), sonst App-Icon.
Gewicht und Wiederholungen passen hier nicht. Ob wir Compact oder Minimal bekommen, entscheidet
das System — beide Fälle müssen für sich funktionieren.

---

## 4. Cardio

Dieselben Zustände, dieselben Slots — nur andere Inhalte:

| Übungsart | Kennzahlenzeile | Trenner |
|---|---|---|
| Kraft | `72,5 kg × 8 Wdh (RIR 2)` | `×` |
| Cardio | `20:00 · 5,00 km (RPE 7)` | `·` |

Cardio sendet **kein Badge** — die Zeile beginnt an der linken Kante, Compact Leading zeigt das
App-Icon. „Intensität" ist das bestehende `SetLog.rpe`.

**Bekannte Lücke:** `SetTemplate` kennt nur `targetReps`, `targetWeight` und `targetRir` — es gibt
im Datenmodell **keine geplante Dauer und keine geplante Distanz**. Ein frischer Cardio-Satz kann
daher keine Zielwerte anzeigen; die Zeile füllt sich aus bereits eingetragenen Ist-Werten und
bleibt sonst leer. Sobald Templates Ziel-Dauer und -Distanz bekommen, ändert sich nur
`_cardioMetrics` in `build_workout_live_activity_content.dart`.

---

## 5. Architektur

### Datenfluss

```
LiveWorkoutViewModel
  └─ buildWorkoutLiveActivityContent()   ← rein, testbar, formatiert alles fertig
       └─ WorkoutLiveActivityService     ← MethodChannel, verwirft No-op-Pushes
            └─ WorkoutLiveActivityBridge (Swift)
                 └─ ActivityKit
```

Zwei Regeln, die das Ganze tragen:

1. **Alles vorformatiert aus Dart.** `72,5 kg`, `8 Wdh`, `RIR 2`, Satztyp-Farbe als `#RRGGBB`.
   Die Swift-Seite formatiert keine Zahl, keine Einheit und kein lokalisiertes Wort — DE/EN,
   kg/lbs, km/mi und Zahlenformate sind damit erledigt.
2. **Zeiten als `Date`, nie als Sekundenzahl.** SwiftUI zählt selbst hoch und runter; kein Feld
   im ContentState ändert sich sekündlich, deshalb kommt die Aktivität mit einem Push pro
   Satzwechsel aus.

### Buttons

App Intents laufen in einem anderen Prozess und haben keinen Zugriff auf die drift-Datenbank.
Deshalb zwei Klassen:

- **`−15s` / `+15s` / `Skip`** berühren nur Timer-Zustand. Sie aktualisieren die Aktivität direkt,
  spiegeln das Pausenende in die App Group und legen ein Kommando in die Warteschlange.
- **Das Häkchen** ist ein Datenbank-Schreibvorgang. Es legt ein Kommando ab und öffnet die App
  (`openAppWhenRun`), die es anwendet und den nächsten Satz neu bestimmt.

`applyPendingLiveActivityCommands()` arbeitet die Warteschlange beim Zurückkehren in den
Vordergrund ab. Danach ist die App wieder alleinige Quelle der Wahrheit.

---

## 6. Dateien

| Pfad | Rolle |
|---|---|
| `ios/Runner/LiveActivity/WorkoutActivityAttributes.swift` | Geteiltes Modell, **beide** Targets |
| `ios/Runner/LiveActivity/WorkoutLiveActivityBridge.swift` | MethodChannel, nur Runner |
| `ios/TrainLibreLiveActivity/WorkoutLiveActivityWidget.swift` | WidgetBundle, alle vier Flächen |
| `ios/TrainLibreLiveActivity/WorkoutLiveActivityViews.swift` | Lockscreen + Expanded + Compact |
| `ios/TrainLibreLiveActivity/WorkoutLiveActivityIntents.swift` | App Intents, Kommando-Warteschlange |
| `ios/TrainLibreLiveActivity/WorkoutLiveActivityTheme.swift` | Design-Tokens |
| `lib/features/workout/domain/live_activity/` | Modell, Strings, Builder |
| `lib/features/workout/data/live_activity/` | MethodChannel-Service |
| `test/features/workout/live_activity_content_test.dart` | Zustände, Badges, Cardio |

---

## 7. Xcode-Einrichtung (noch offen)

Der Quellcode ist vollständig; das Extension-Target existiert im `project.pbxproj` noch nicht.
Bewusst nicht per Hand gepatcht — die Datei trägt die Release-Pipeline, und Signing und App Group
brauchen ohnehin Schritte im Developer-Portal.

1. **Apple Developer Portal:** App Group `group.com.rfivesix.trainlibre` anlegen und dem App-ID
   `com.rfivesix.trainlibre` sowie dem neuen Extension-Bundle
   `com.rfivesix.trainlibre.LiveActivity` zuweisen.
2. **Xcode → File → New → Target → Widget Extension**, Name `TrainLibreLiveActivity`,
   „Include Live Activity" an, „Include Configuration Intent" aus.
   Die von Xcode erzeugten Platzhalterdateien löschen.
3. Die Dateien aus `ios/TrainLibreLiveActivity/` zum neuen Target hinzufügen, inklusive
   `Assets.xcassets`. Xcodes generierte `Info.plist` durch die vorhandene ersetzen.
4. `ios/Runner/LiveActivity/WorkoutActivityAttributes.swift` **beiden** Targets zuweisen
   (Target Membership: Runner **und** TrainLibreLiveActivity).
   `WorkoutLiveActivityBridge.swift` nur dem Runner.
5. Signing & Capabilities → App Groups für beide Targets aktivieren, jeweils
   `group.com.rfivesix.trainlibre`. Die Entitlement-Dateien liegen bereits vor.
6. Deployment Target der Extension auf iOS 16.2.
7. Fastlane: das neue Provisioning-Profil in die Match-/Signing-Konfiguration aufnehmen.

`NSSupportsLiveActivities` in `ios/Runner/Info.plist` und die App Group in beiden Entitlements
sind bereits gesetzt.

---

## 8. Offene Fragen

1. **Fortschrittsbalken** in S2 — im Design vorhanden und implementiert. Bestätigen oder streichen.
2. **Pausentimer bei Cardio** — laufen S2/S3 dort überhaupt, oder ist Cardio immer S1?
3. **Kürzel für Superset und Other** — `S` und `O` sind gesetzt, aber `SetTypeChip` kennt sie
   noch nicht. Sobald die App sie definiert, hier nachziehen.

---

## 9. Testmatrix

- [x] Fünf Zustände, Badge-Logik und Cardio-Varianten (Unit-Tests)
- [ ] Alle fünf Zustände × vier Flächen visuell auf dem Gerät
- [ ] Nicht-Pro-Gerät (keine Dynamic Island)
- [ ] Zweite Live Activity aktiv → Compact **und** Minimal
- [ ] **S2 → S3 mit suspendierter App** — der kritische Fall, hängt an `staleDate`/`isStale`
- [ ] App im Hintergrund / hart beendet / Gerät neu gestartet
- [ ] Buttons: `−15s`, `+15s`, `Skip` bei suspendierter App, danach Abgleich in der App
- [ ] Häkchen → App öffnet sich, Satz ist mit den geplanten Werten getrackt
- [ ] Workout länger als 8 Stunden
- [ ] Live Activities in den Systemeinstellungen deaktiviert
- [ ] Zwei Workouts hintereinander ohne App-Neustart; Workout abgebrochen statt beendet
- [ ] Lange Übungsnamen, vierstellige Gewichte, lbs statt kg
- [ ] Dark Mode, DE und EN
