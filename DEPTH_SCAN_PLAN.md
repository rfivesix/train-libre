# Depth Scale Hint — Implementierungsplan

**Branch:** `feat/depth-scale-hint` (von `develop`, ohne den `lidar-experiment`-Stand)
**Status:** Planung, noch keine Implementierung
**Ziel:** Mengenschätzung der KI-Mahlzeitenerkennung verbessern, indem LiDAR-Tiefendaten als *Kontext* an die KI gegeben werden — ohne lokale Segmentierung, Volumenberechnung oder Clustering.

---

## 1. Warum ein Neuanfang

Der Branch `lidar-experiment` (ca. 37.000 Zeilen, 27 Commits) hat versucht, aus Tiefendaten **lokal** die Bestandteile einer Mahlzeit zu erkennen: Ebenendetektion, Rim-Finder, geometrische Auto-Segmentierung, Clustering, Volumenschätzung pro Region.

Das funktioniert in der Praxis nicht, und zwar nicht wegen fehlender Parameterabstimmung, sondern strukturell: Geometrie sieht Höhenunterschiede, keine Zutaten. Reis und Hähnchen nebeneinander auf gleicher Höhe sind ein Cluster; ein Reishaufen mit Delle sind zwei. Semantische Segmentierung aus reiner Geometrie ist ein ungelöstes Problem.

Der Branch bleibt als Referenz erhalten und wird **nicht gelöscht**. Wir bauen aber auf dem sauberen `develop`-Stand neu auf.

### Was sich als Erkenntnis mitnehmen lässt

- Die veröffentlichte Forschung, die dieses Problem am nächsten löst ("Reasoning-Driven Food Energy Estimation via Multimodal LLMs"), rechnet Geometrie **lokal zu wenigen Zahlen** herunter und setzt diese als **Text ins Prompt** — sie schickt keine Punktwolken an das Modell.
- Der Nutrition5k-Baseline von Google erreicht unter Laborbedingungen (feste Rig, Aufnahme von oben) 18,8 % Fehler bei der Gesamtmasse. **~15–25 % Fehler ist ein gutes Ergebnis**, nicht ein schlechtes. Reine Bildschätzung liegt typischerweise bei 40–50 %.
- Der größte Einzelfehler bei reiner Bildschätzung ist der **fehlende absolute Maßstab**. Faktor 1,5 im angenommenen Tellerdurchmesser ist Faktor ~3 im Volumen. Genau diese Unbekannte kann LiDAR ohne jede Segmentierung beseitigen.

---

## 2. Nicht-Ziele (explizit)

Diese Dinge werden **nicht** gebaut. Sie sind der Grund, warum das Experiment gescheitert ist, und sie sind bewusst ausgeschlossen:

- ❌ Keine lokale Segmentierung / Maskenerzeugung (weder geometrisch noch per CoreML/Vision)
- ❌ Keine Ebenen-/Tellererkennung (RANSAC, Rim-Finder, Support-Klassifikation)
- ❌ Kein Clustering von Punkten zu Zutaten
- ❌ Keine lokale Volumenberechnung pro Zutat
- ❌ Kein eigenes Modell, kein Training, keine CoreML-Gewichte im Bundle
- ❌ Keine Punktwolke im Prompt (funktioniert nachweislich nicht, kostet massiv Tokens)
- ❌ Keine neuen Netzwerk-/Cloud-Abhängigkeiten außerhalb des bestehenden BYOK-Providers

**Erlaubt und beabsichtigt:** Lesen des Tiefenpuffers, elementare Arithmetik darauf (Median, Min/Max, Kamera-Intrinsics), und Rendern eines Bildes.

---

## 3. Kernidee in einem Satz

> Neben dem normalen Foto bekommt die KI **(a)** zwei bis vier gemessene Zahlen zum Maßstab der Szene als Text und **(b)** optional ein zweites Bild, in dem die Tiefe farbcodiert dargestellt ist. Alles andere bleibt exakt wie bisher.

---

## 4. Bestandsaufnahme: der aktuelle Ablauf auf `develop`

```
AiMealCaptureScreen              lib/features/diary/presentation/ai_meal_capture_screen.dart
  └─ image_picker (Foto/Galerie)        → List<File>
  └─ PhotoPreProcessor                  util/photo_pre_processor.dart
  └─ AiService.analyzeImages()          lib/services/ai_service.dart:554
       └─ _AiPrompts.buildSystemPrompt  lib/services/ai/ai_prompts.dart:5
       └─ _callSelectedProviderRaw      lib/services/ai_service.dart:701  (base64 pro Bild)
  └─ AiRepairOrchestrator               lib/services/ai_meal_validation.dart:233
       └─ AiService.repairMealCaptureCandidate  lib/services/ai_service.dart:652
AiMealReviewScreen               lib/features/diary/presentation/ai_meal_review_screen.dart
```

### 4.1 Vorgefundene Altlast

`AiSuggestedItem` (`lib/services/ai/ai_models.dart:51`) und `AiMealCandidateItem`
(`lib/services/ai/validation/validation_models.dart:58`) tragen bereits die Felder
`volumeCm3`, `depthConfidence` und `spatialBoundingBox`. Diese sind **nirgends im
Projekt gelesen oder geschrieben** — weder in `lib/` noch in `test/`. Sie stammen aus
einem früheren Ansatz und werden mitserialisiert, ohne je einen Wert zu tragen.

Entscheidung: Diese drei Felder werden im Zuge von P7 **entfernt** und durch das
saubere 2D-`boundingBox` ersetzt (§9.1). `volumeCm3` und `depthConfidence` gehören zu
genau der lokalen Volumenberechnung, die dieser Plan als Nicht-Ziel führt — sie
stehenzulassen würde suggerieren, dass dieser Weg noch offen ist.

**Wichtige Konsequenz:** Die Aufnahme läuft heute über `image_picker`. Es gibt **keine eigene Kamerasession** — und damit keinen Zugriff auf Tiefendaten. Der native Aufnahmeteil ist deshalb der einzige wirklich neue Baustein.

---

## 5. Zielarchitektur

```
┌─ iOS nativ ──────────────────────────────────────────────┐
│ ios/Runner/DepthScan/                                    │
│   DepthScanCapability.swift   Gerätefähigkeit prüfen     │
│   DepthScanController.swift   AVCaptureSession + Depth   │
│   DepthScanPlugin.swift       MethodChannel              │
│                                                          │
│   liefert: JPEG-Pfad + Float32-Tiefenpuffer + Intrinsics │
└──────────────────────────────────────────────────────────┘
                          │ MethodChannel
┌─ lib/features/depth_scan/ ───────────────────────────────┐
│ domain/models/                                           │
│   depth_capture.dart        Rohdaten + Intrinsics        │
│   depth_scale_facts.dart    die Zahlen fürs Prompt       │
│ data/                                                    │
│   depth_scale_calculator.dart   Median, Intrinsics-Mathe │
│   depth_map_renderer.dart       Bänderbild → PNG         │
│ platform/                                                │
│   depth_scan_channel.dart       iOS-Implementierung      │
│   unsupported_depth_scan.dart   Android + Non-Pro        │
│ presentation/                                            │
│   depth_scan_camera_screen.dart Aufnahme-UI              │
└──────────────────────────────────────────────────────────┘
                          │
┌─ bestehender Pfad, minimal erweitert ────────────────────┐
│ AiService.analyzeImages(..., DepthScaleFacts? depth)     │
│ _AiPrompts.buildSystemPrompt(..., depthHint)             │
│ AiMealCandidateItem + boundingBox                        │
└──────────────────────────────────────────────────────────┘
```

Die Trennung ist bewusst: `lib/features/depth_scan/` weiß nichts über Ernährung, `lib/services/ai/` weiß nichts über Kameras. Verbunden werden sie nur im Capture-Screen.

---

## 6. Baustein 1 — Native Tiefenaufnahme (iOS)

### 6.1 Warum AVFoundation und nicht ARKit

Der alte Branch nutzte `ARSession` mit `smoothedSceneDepth` (256×192, World Tracking im Hintergrund). Für eine **Standbildaufnahme** ist das der falsche Hebel:

| | ARKit `sceneDepth` | AVFoundation `builtInLiDARDepthCamera` |
|---|---|---|
| Auflösung | fix 256×192 | bis 320×240, an das Foto gekoppelt |
| Foto + Tiefe synchron | manuell zu koppeln | `AVCapturePhotoOutput` liefert beides in einem Callback |
| Overhead | World Tracking, Motion | nur Kamera |
| Ausrichtung Foto↔Tiefe | selbst zu rektifizieren | von `AVDepthData` garantiert |

Empfehlung: **`AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back)`** mit `AVCapturePhotoOutput`, `isDepthDataDeliveryEnabled = true`. Im Delegate liefert `AVCapturePhoto.depthData` die Tiefe zum exakt selben Auslösezeitpunkt.

### 6.2 Was über den Channel geht

```
Methode: depth_scan/capture
Rückgabe: {
  "imagePath":   String,        // JPEG, unverändert, für die KI und die UI
  "depth": {
    "width":     Int,           // z.B. 320
    "height":    Int,           // z.B. 240
    "values":    Uint8List,     // Float32 little-endian, width*height*4 Bytes
    "accuracy":  String,        // "absolute" | "relative"
    "filtered":  Bool
  },
  "intrinsics": { "fx": Double, "fy": Double, "cx": Double, "cy": Double,
                  "refWidth": Int, "refHeight": Int }
}
```

Bei 320×240 sind das **300 KB** über den Channel. Das ist unkritisch und einmalig pro Aufnahme.

**Bewusste Entscheidung:** Die Einfärbung passiert **nicht** nativ, sondern in Dart. Gründe: testbar mit `flutter test`, iterierbar ohne Xcode-Rebuild, und konform zur Projektkonvention (Logik in `lib/features/`, nicht in `ios/Runner/`).

`AVDepthData.depthDataType` muss auf `kCVPixelFormatType_DepthFloat32` konvertiert werden (`converting(toDepthDataType:)`), und `depthDataAccuracy` muss geprüft werden — bei `.relative` sind die Werte **nicht metrisch** und die Aufnahme muss als „ohne Maßstab" behandelt werden.

### 6.3 Fähigkeitsprüfung

```
Methode: depth_scan/capability
Rückgabe: { "supported": Bool, "reason": String? }
```

Unterstützt: iPhone 12 Pro/Pro Max und neuer (Pro-Modelle), iPad Pro ab 2020. Alles andere → `supported: false`, und der gesamte Feature-Zweig bleibt inaktiv.

---

## 7. Baustein 2 — Die Maßstab-Fakten

Das ist der inhaltliche Kern und der Teil mit dem besten Aufwand-Nutzen-Verhältnis.

### 7.1 Berechnung

```dart
class DepthScaleFacts {
  final double subjectDistanceCm;   // Median der Tiefe im mittleren Bilddrittel
  final double frameWidthCm;        // sichtbare Breite auf dieser Distanz
  final double frameHeightCm;
  final double nearCm;              // 5. Perzentil
  final double farCm;               // 95. Perzentil
  final double validSampleRatio;    // Anteil gültiger Tiefenwerte (0..1)
}
```

Die einzige nicht-triviale Zeile ist die Projektion durch die Intrinsics:

```dart
final frameWidthCm  = (imageWidthPx  * z) / fx * 100;
final frameHeightCm = (imageHeightPx * z) / fy * 100;
```

Perzentile statt Min/Max, damit einzelne Ausreißer (Reflexionen, Löcher im Puffer) die Skala nicht sprengen. Alles zusammen: eine Datei, ~80 Zeilen, vollständig unit-testbar mit synthetischen Puffern.

### 7.2 Qualitätsgate

Die Fakten werden **verworfen** (und das Feature verhält sich wie auf einem Nicht-Pro-Gerät), wenn:

- `depthDataAccuracy == .relative`
- `validSampleRatio < 0.5`
- `subjectDistanceCm` außerhalb 15–120 cm (LiDAR ist außerhalb unzuverlässig, und näher/ferner ist kein plausibles Essensfoto)

Lieber kein Maßstab als ein falscher — ein falscher Maßstab verschlechtert das Ergebnis gegenüber heute aktiv.

### 7.3 Prompt-Erweiterung

Neuer optionaler Block in `_AiPrompts.buildSystemPrompt`. Entwurf:

```
LIDAR SCALE MEASUREMENT (measured, not estimated — trust these numbers over
your visual impression):
- Distance from camera to the food: 38 cm
- The visible frame covers 29 cm x 39 cm at that distance
- Nearest surface 31 cm, farthest 57 cm

Use this to calibrate the absolute size of everything in the image. Do NOT
rely on assumed plate or cutlery sizes when this measurement is present —
derive plate diameter and portion dimensions from the frame size above.
```

Der Block entfällt **vollständig**, wenn keine Messung vorliegt. Kein „no depth data available" — ein leerer Hinweis ist schlechter als gar keiner.

### 7.4 Wo er auch hin muss

Der Repair-Pass (`buildRepairPrompt`, `ai_prompts.dart:84`) bekommt denselben Block. Sonst korrigiert die Reparatur die durch die Messung gewonnene Genauigkeit wieder weg, weil sie nur gegen den geratenen kcal-Anker optimiert.

---

## 8. Baustein 3 — Das Tiefenbild (Experiment)

Zweites Bild an denselben Request. **Unerprobt** — deshalb strikt getrennt von Baustein 2 zu bewerten.

### 8.1 Rendering-Entscheidungen

| Entscheidung | Wahl | Begründung |
|---|---|---|
| Farbrampe | monoton, hell = nah (Viridis-artig oder Graustufen) | Rot/Grün ist nicht monoton — das Modell hat keinen Begriff davon, ob Grün „mehr" ist als Rot |
| Kontinuierlich vs. Stufen | **8 diskrete Bänder** | LLMs interpolieren Farbnuancen schlecht, lesen aber diskrete Bänder gut |
| Bezugsgröße | Median-Tiefe des Frames abziehen | rohe Kameradistanz erzeugt bei schrägem Tisch einen Verlauf übers ganze Bild, der die Höhenunterschiede des Essens überdeckt |
| Skalierung | über das 5.–95.-Perzentil des Frames | feste 0–5 m würden das Essen in zwei Farbtöne quetschen |
| Legende | ins Bild gerendert **und** im Prompt als Text | Modelle lesen Achsenbeschriftungen unzuverlässig, Prompt-Text exakt |
| Auflösung | auf Fotoseitenverhältnis skaliert, max. 512 px lange Kante | größer bringt nichts und kostet Tokens |
| Ungültige Pixel | neutrales Grau + Legendeneintrag „keine Messung" | sonst erfindet das Modell dort Struktur |

Die Median-Subtraktion ist eine einzelne Zeile Arithmetik, kein Plane-Fitting: `relative = value - median`. Sie ist der Unterschied zwischen einem Bild, das die Tischneigung zeigt, und einem, das das Essen zeigt.

### 8.2 Prompt-Ergänzung

```
The SECOND image is not a photo. It is a depth map of the SAME scene,
rendered in 8 discrete bands relative to the table surface:
  Band 1 (darkest)  = at or below table level
  Band 2            = 0-1 cm above
  ...
  Band 8 (brightest) = 7 cm or more above the table
Grey pixels = no measurement available.
Use it to judge how high each food component is piled — this is information
the photo alone cannot show.
```

Die konkreten Bandgrenzen werden zur Laufzeit eingesetzt, nicht fest verdrahtet.

### 8.3 Kosten

Ein zweites Bild verdoppelt grob die Bild-Tokens pro Request. Bei BYOK zahlt das der Nutzer. Deshalb: **hinter einem Schalter** in den KI-Einstellungen, Standard erst nach Messung festlegen (siehe §11).

---

## 9. Baustein 4 — Bounding Boxes und Visualisierung

Damit die Callouts im Bild möglich werden, **ohne** lokale Segmentierung.

### 9.1 Schema-Erweiterung

`AiMealCandidateItem` (`lib/services/ai/validation/validation_models.dart:58`) und `AiSuggestedItem` (`lib/services/ai/ai_models.dart:51`) bekommen ein optionales Feld:

```dart
/// Normalized [x, y, w, h] in image space (0..1), origin top-left.
/// Null when the model did not localize the item.
final List<double>? boundingBox;
```

Prompt-Regel, additiv zu den bestehenden CRITICAL RULES:

```
12. LOCALIZATION: For each item that is visibly identifiable in the image,
    add "boundingBox": [x, y, width, height] with values from 0.0 to 1.0
    relative to the image, origin at top-left. Omit the field or use null
    for items you cannot localize (e.g. oil, salt, hidden ingredients).
```

### 9.2 Validierung der Boxen

Modell-Boxen sind unzuverlässig. Vor der Anzeige lokal prüfen:

- innerhalb 0..1, positive Breite/Höhe
- Fläche zwischen 0,2 % und 60 % des Bildes
- Überlappung zweier Boxen > 80 % → beide verwerfen (Modell hat dieselbe Region doppelt vergeben)

Fällt eine Box durch, wird das Item **ohne** Callout gelistet. Es gibt nie einen Fehlerzustand, der das Loggen blockiert.

---

## 10. End-User-Flow

Der UI-Umbau des Scan-Erlebnisses kommt als eigener Schritt **nach** diesem Plan. Was hier festgehalten wird, ist das Zielbild, damit die Datenstruktur es trägt.

### 10.1 Aufnahme

1. Nutzer öffnet die KI-Mahlzeitenerfassung.
2. Auf einem LiDAR-Gerät startet die eigene Kameraansicht statt `image_picker`. Kleines, unaufdringliches Badge: „LiDAR aktiv". Auf allen anderen Geräten bleibt der heutige `image_picker`-Weg unverändert — kein sichtbarer Unterschied, keine Erklärung nötig.
3. Ein Hinweis, wenn die Distanz außerhalb 15–120 cm liegt: „Etwas näher herangehen." Das ist der einzige Fall, in dem der Nutzer aktiv etwas tun muss.
4. Auslösen. Foto und Tiefe werden gemeinsam erfasst.

### 10.2 Analyse

5. Übergang in eine Verarbeitungsansicht. Hier gehört die Visualisierung hin, die im alten Branch bereits gut aussah: das Foto, über das sich die Tiefendarstellung legt und wieder zurückzieht. Das ist ehrliche Darstellung — es zeigt genau das, was tatsächlich passiert (die Tiefe wird mitgeschickt), statt eine Analyse zu inszenieren, die nicht stattfindet.
6. Der Request geht raus: Foto + Maßstab-Text (+ optional Tiefenbild).

### 10.3 Review

7. `AiMealReviewScreen` zeigt oben das Foto. Über dem Foto liegen die Callouts: pro erkanntem Item ein Label an der Position seiner Bounding Box — „Reis · 180 g · 234 kcal".
8. Tippen auf ein Callout scrollt zur passenden Zeile in der Liste darunter und hebt sie hervor; tippen auf eine Zeile hebt das Callout hervor. Zwei Richtungen, damit die Verbindung Bild↔Liste selbsterklärend ist.
9. Items ohne Box erscheinen nur in der Liste, ohne besondere Kennzeichnung.
10. Korrigiert der Nutzer eine Menge, bleibt das Callout stehen und aktualisiert seinen Wert.

### 10.4 Was der Nutzer nie sieht

Punktwolken, Volumenangaben, Konfidenzen der Messung, „LiDAR-Genauigkeit"-Anzeigen. Die Messung ist ein internes Hilfsmittel, kein Feature mit eigener Oberfläche. Alles, was suggeriert, hier werde exakt gemessen, ist eine Lüge — die Zahl bleibt eine KI-Schätzung, nur eine besser informierte.

---

## 11. Wie wir wissen, ob es hilft

Ohne Messung ist dieser ganze Plan Glaube. Deshalb vor Baustein 3 und 4:

### 11.1 Referenzsatz

20–30 Mahlzeiten, real fotografiert, jede Komponente vorher mit der Küchenwaage gewogen. Gemischt: Teller, Schüssel, Glas, Einzelobjekt in der Hand, sowohl flach als auch gehäuft. Als JSON-Fixture im Repo (`test/fixtures/depth_benchmark/`), Fotos + Tiefenpuffer + Sollwerte.

### 11.2 Vergleich

Ein Skript (`script/depth_benchmark.dart`) fährt jede Aufnahme in drei Varianten durch denselben Provider:

| Variante | Eingabe |
|---|---|
| A (Baseline) | nur Foto — der heutige Stand |
| B | Foto + Maßstab-Text |
| C | Foto + Maßstab-Text + Tiefenbild |

Metrik: mittlerer absoluter prozentualer Fehler der **Gesamtmasse** und der **Gesamt-kcal** pro Mahlzeit. Zusätzlich der Anteil der Mahlzeiten mit > 50 % Fehler (die sind es, die Nutzer verlieren).

### 11.3 Entscheidungsregeln

- B verbessert nicht messbar gegenüber A → das ganze Vorhaben ist erledigt, wir wissen es nach ein paar Tagen statt nach Monaten.
- C verbessert nicht messbar gegenüber B → Tiefenbild fliegt raus, Maßstab-Text bleibt. Spart Tokens und Komplexität.
- C hilft → als Standard aktivieren, mit Abschaltmöglichkeit für Nutzer mit knappem Token-Budget.

Der Referenzsatz sollte **vor** der Prompt-Optimierung stehen, sonst optimieren wir auf Eindrücke.

---

## 12. Phasenplan

| Phase | Inhalt | Ergebnis |
|---|---|---|
| **P0** | `DepthScanCapability` + `DepthScanController` + Channel, Debug-Screen der Rohwerte anzeigt | Tiefe kommt in Dart an, verifizierbar |
| **P1** | `DepthScaleCalculator` + Unit-Tests + Qualitätsgate | Maßstab-Fakten aus echten Aufnahmen |
| **P2** | Referenzsatz aufnehmen und wiegen | Messbarkeit hergestellt |
| **P3** | Prompt-Block in `buildSystemPrompt` + `buildRepairPrompt`, `analyzeImages` erweitert | Variante B lauffähig |
| **P4** | Benchmark A vs. B | **Go/No-Go für alles Weitere** |
| **P5** | `DepthMapRenderer` + zweites Bild + Prompt-Block | Variante C lauffähig |
| **P6** | Benchmark B vs. C | Entscheidung über das Tiefenbild |
| **P7** | Bounding Boxes im Schema + Validierung | Daten für die Visualisierung |
| **P8** | Callout-Overlay im Review-Screen | sichtbares Feature |
| **P9** | UI-/UX-Überarbeitung des gesamten Scan-Flows | *eigener Plan, hier nicht enthalten* |

P0–P4 sind der eigentliche Kern und in sich ausliefer­bar: Wenn danach Schluss wäre, hätte die App eine messbar bessere Mengenschätzung auf Pro-Geräten und sonst keinerlei Änderung.

---

## 13. Risiken

| Risiko | Auswirkung | Umgang |
|---|---|---|
| Maßstab bringt messbar nichts | Vorhaben hinfällig | P4 als frühes Go/No-Go, vor jeder UI-Arbeit |
| LiDAR liefert bei Glas/Flüssigkeit unbrauchbare Werte | falscher Maßstab, schlechter als heute | Qualitätsgate §7.2, im Zweifel verwerfen |
| Modell ignoriert den Maßstab-Block | keine Wirkung trotz korrekter Daten | Formulierung „measured, not estimated — trust these over your visual impression"; im Benchmark direkt sichtbar |
| Bounding Boxes systematisch versetzt | Callouts an falscher Stelle, wirkt kaputt | Validierung §9.2, im Zweifel kein Callout |
| Zweites Bild verdoppelt Kosten ohne Nutzen | Nutzerärger bei BYOK | P6 entscheidet datenbasiert, Schalter in den Einstellungen |
| Nur Pro-Geräte | Feature-Fragmentierung | bewusst unsichtbar gehalten (§10.1) — kein Nicht-Pro-Nutzer erfährt, dass ihm etwas fehlt |
| Eigene Kamerasession bringt neue Fehlerquellen (Berechtigungen, Lifecycle) | Aufnahme schlägt fehl | `image_picker`-Pfad bleibt als Fallback bestehen und wird bei jedem Fehler genommen |

---

## 14. Datenschutz

Unverändert zum heutigen Stand: Das Foto geht an den vom Nutzer selbst konfigurierten BYOK-Provider. Neu hinzu kommen einige Zentimeter-Angaben und optional ein abstraktes Tiefenbild — beides enthält weniger personenbezogene Information als das Foto, das ohnehin schon übertragen wird. Der rohe Tiefenpuffer verlässt das Gerät nie. Ohne konfigurierten KI-Provider passiert wie bisher gar nichts.

Kein neuer Netzwerkendpunkt, keine neue Abhängigkeit, keine Cloud-Komponente.

---

## 15. Offene Punkte

- Bandgrenzen des Tiefenbildes: feste Zentimeterstufen oder adaptiv über die Frame-Perzentile? Adaptiv ist besser lesbar, feste Stufen sind über Aufnahmen hinweg vergleichbar. Entscheidung nach den ersten echten Bildern.
- Soll die Aufnahme mehrere Fotos mit Tiefe erlauben (heute erlaubt `pickMultiImage` mehrere Bilder)? Vorschlag: zunächst nur die erste Aufnahme trägt Tiefe, weitere Bilder wie bisher.
- Telemetrie: ob eine Messung vorlag, sollte im bestehenden `trackAiMealScanRequested` als Flag mitlaufen, damit sich die Wirkung auch im Feld beobachten lässt. Muss gegen `TELEMETRY.md` geprüft werden.
