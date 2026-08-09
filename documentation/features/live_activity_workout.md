# Live Activity: Workout (iOS)

Status: implementiert, Xcode-Target eingerichtet, Gerätetest offen
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

**S2 und S3 teilen sich ein Layout.** Das ist die zentrale Lehre aus der Umsetzung: eine Live
Activity kann ohne Push nur *Text innerhalb von System-Zeitviews* selbst aktualisieren, niemals
ihre Struktur. Zwei getrennte Layouts brauchen zwingend einen Re-Render, und dessen Zeitpunkt
bestimmt iOS — beobachtet wurden ein bis zwei Minuten Verzug. Deshalb:

- Die Karte sieht in S2 und S3 identisch aus. Der Timer läuft mit `Text(_, style: .timer)` bis
  zum Pausenende runter und **danach weiter hoch**; das Häkchen ist durchgehend verfügbar.
- Dart lässt die Phase auf `resting` und behält `restEndsAt` auch nach Ablauf. Nur so kann die
  Swift-Seite überhaupt zwischen „läuft" und „überzogen" unterscheiden.
- Sekundengenau reagiert allein `LARestProgress`: zwei `ProgressView(timerInterval:)`, vom System
  animiert. Die obere Leiste ist exakt bei 0:00 voll, die untere läuft danach rot durch.
- Die rote **Farbe** der Zahl hängt weiterhin an einem Re-Render und kommt verspätet. Das ist
  hinnehmbar, weil sie nur bestätigt, was die Ziffern und die Leisten schon zeigen.

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

**S2 und S3** ergänzen darunter zwei Fortschritts-Haarlinien und `−15s · 2:20 · +15s · Skip`.
Die Kennzahlenzeile wird **nicht** ausgegraut und das Häkchen bleibt sichtbar — sonst müsste beim
Ablauf das Layout wechseln, und genau das geht nicht rechtzeitig (§2). Überzogen wird die Zahl
`#FF6B78`, aufgehellt aus `brandRedColor`; diese Umfärbung kommt verspätet.

Fehlen Gewicht oder Wiederholungen, steht dort `–` statt einer geratenen Zahl, und das Häkchen ist
grau und kein Button — der Tap fällt auf die `widgetURL` durch und öffnet die App.

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

Ein Kreis, genau **ein** Element: die laufende Zeit während der Pause, sonst der kürzestmögliche
Satz (`115×9`, ohne Einheiten) und andernfalls das App-Icon. Laufen zwei Live Activities, bekommen
**beide** ihren Minimal-Kreis — dann ist das hier die einzige Stelle, an der der Satz überhaupt
sichtbar ist, weshalb die Zahlen dort Vorrang vor dem Logo haben.

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
| `ios/LiveActivity/WorkoutActivityAttributes.swift` | Geteiltes Modell, **beide** Targets |
| `ios/LiveActivity/WorkoutLiveActivityBridge.swift` | MethodChannel, nur Runner |
| `ios/LiveActivity/RestSoundScheduler.swift` | Nativer Pausenton, **beide** Targets |
| `ios/TrainLibreLiveActivity/WorkoutLiveActivityWidget.swift` | WidgetBundle, alle vier Flächen |
| `ios/TrainLibreLiveActivity/WorkoutLiveActivityViews.swift` | Lockscreen + Expanded + Compact |
| `ios/TrainLibreLiveActivity/WorkoutLiveActivityIntents.swift` | App Intents, Kommando-Warteschlange |
| `ios/TrainLibreLiveActivity/WorkoutLiveActivityTheme.swift` | Design-Tokens |
| `lib/features/workout/domain/live_activity/` | Modell, Strings, Builder |
| `lib/features/workout/data/live_activity/` | MethodChannel-Service |
| `test/features/workout/live_activity_content_test.dart` | Zustände, Badges, Cardio |

---

## 7. Xcode-Einrichtung (erledigt, hier zur Nachvollziehbarkeit)

Das Extension-Target `TrainLibreLiveActivity` steht. Beim Anlegen zu beachten war:

1. **Apple Developer Portal:** App Group `group.com.rfivesix.trainlibre` anlegen und dem App-ID
   `com.rfivesix.trainlibre` sowie dem neuen Extension-Bundle
   `com.rfivesix.trainlibre.LiveActivity` zuweisen.
2. **Xcode → File → New → Target → Widget Extension**, Name `TrainLibreLiveActivity`,
   „Include Live Activity" an, „Include Configuration Intent" aus.
   Die von Xcode erzeugten Platzhalterdateien löschen.
3. Die Dateien aus `ios/TrainLibreLiveActivity/` zum neuen Target hinzufügen, inklusive
   `Assets.xcassets`. Xcodes generierte `Info.plist` durch die vorhandene ersetzen.
4. `ios/LiveActivity/WorkoutActivityAttributes.swift` und `RestSoundScheduler.swift`
   **beiden** Targets zuweisen
   (Target Membership: Runner **und** TrainLibreLiveActivity).
   `WorkoutLiveActivityBridge.swift` nur dem Runner.
5. Signing & Capabilities → App Groups für beide Targets aktivieren, jeweils
   `group.com.rfivesix.trainlibre`. Die Entitlement-Dateien liegen bereits vor.
6. Deployment Target der Extension auf iOS 16.2.
7. Fastlane: das neue Provisioning-Profil in die Match-/Signing-Konfiguration aufnehmen.

`NSSupportsLiveActivities` in `ios/Runner/Info.plist` und die App Group in beiden Entitlements
sind bereits gesetzt.

---

## 7a. Pausenton neben der Live Activity (umgesetzt)

### Das Problem

Der Pausentimer meldet sich heute über zwei Wege, die sich mit der Live Activity überschneiden:

| Situation | heute | Ton? | Banner? |
|---|---|---|---|
| App im Vordergrund | Haptik + Sound + `showRestTimerDoneNotification(foreground: true)` | ja | ja, überflüssig |
| App suspendiert | vorab geplante `scheduleRestTimerDoneNotification` | ja | ja, doppelt zur Live Activity |

Der **Ton ist der eigentliche Zweck** — mit Kopfhörern im Ohr ist er das Einzige, was ankommt.
Das Banner ist der redundante Teil.

### Die harte Randbedingung

Ist die App suspendiert, läuft der Dart-`Timer.periodic` nicht. Der Ton kann dann **ausschließlich**
aus der vorab geplanten lokalen Notification kommen. Eine Notification ohne Banner
(`interruptionLevel: .passive`) spielt keinen Ton — beides zusammen geht nicht. Das Banner im
Hintergrund ist also der Preis für den Ton und bleibt.

### Vorgeschlagene Umsetzung

**Schritt 1 — Vordergrund entdoppeln — erledigt**
`_startRestTimer` ruft im Ablauf-Callback `showRestTimerDoneNotification(foreground: true)` auf.
Läuft eine Live Activity, ist das Banner überflüssig: die Karte zeigt den Zustand bereits.
Haptik und Sound bleiben, die Notification entfällt. Bedingung ist `_liveActivityRunning`, das im
View Model schon existiert.

**Schritt 2 — den Desync beheben — erledigt**
`AdjustRestIntent` und `SkipRestIntent` verschieben das Pausenende in der App Group, während die
App suspendiert ist. Die **geplante Notification bleibt dabei auf der alten Uhrzeit stehen** —
nach `+15s` aus der Island piept es 15 Sekunden zu früh, nach `Skip` piept es überhaupt noch.
Das ist ein echter Fehler, kein Schönheitsproblem.

Lösung: die Pausenton-Notification nativ planen statt über `flutter_local_notifications`, damit
sowohl die App als auch die App Intents sie umplanen können.

- Neue Swift-Seite in `WorkoutLiveActivityBridge`: `scheduleRestSound(at:)` / `cancelRestSound()`
  über `UNUserNotificationCenter` mit fester Identifier-Konstante.
- `AdjustRestIntent` und `SkipRestIntent` rufen dieselben Funktionen direkt auf.
- Dart ruft sie über den bestehenden MethodChannel statt `LocalNotificationService`, **solange
  eine Live Activity läuft**. Ohne Live Activity bleibt alles beim Alten — der bestehende Pfad
  ist auf Android ohnehin der einzige.

**Schritt 3 — offen, optional, iOS 17+**
`Activity.update(_:alertConfiguration:)` löst Ton und Haptik auf iPhone *und* Apple Watch aus und
hebt die Live Activity kurz hervor. Das ist der von Apple dafür vorgesehene Weg, greift aber nur,
wenn die App im Moment des Ablaufs läuft — also als Zusatz im Vordergrund, nicht als Ersatz für
Schritt 2.

### Entschieden

- Die `haptics_enabled`-Einstellung wird auf dem nativen Pfad **nicht** ausgewertet; der Ton
  kommt immer. Die Einstellung greift weiterhin auf dem bestehenden Flutter-Pfad.
- Die native Planung ist **iOS-spezifisch**. Läuft keine Live Activity — und auf Android immer —
  bleibt alles bei `LocalNotificationService`. Der Umschalter ist
  `LiveWorkoutViewModel._usesNativeRestSound`.

---

## 8. Offene Fragen

1. **Pausentimer bei Cardio** — laufen S2/S3 dort überhaupt, oder ist Cardio immer S1?
2. **Kürzel für Superset und Other** — `S` und `O` sind gesetzt, aber `SetTypeChip` kennt sie
   noch nicht. Sobald die App sie definiert, hier nachziehen.
3. **Geplante Cardio-Werte** — `SetTemplate` hat keine Ziel-Dauer und keine Ziel-Distanz. Bis das
   existiert, kann ein frischer Cardio-Satz nicht aus der Live Activity abgehakt werden.

---

## 9. Testmatrix

- [x] Fünf Zustände, Badge-Logik, Cardio-Varianten und `canCompleteSet` (Unit-Tests)
- [ ] Fortschrittsbalken: füllt sich exakt bis 0:00, danach läuft die rote Leiste — der einzige
      sekundengenaue Indikator, weil das System ihn selbst animiert
- [ ] Häkchen grau und nicht drückbar, wenn Gewicht oder Wdh fehlen; Tap öffnet die App
- [ ] Deep Link stapelt den Live-Workout-Screen nicht mehr
- [ ] `+15s` / `Skip` aus der Island verschieben den Pausenton mit (App suspendiert)
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
