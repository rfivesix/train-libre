# Mahlzeitenerfassung — Architektur- und UX-Plan

**Branch:** `feat/depth-scale-hint`
**Status:** Planung
**Verhältnis zu [DEPTH_SCAN_PLAN.md](DEPTH_SCAN_PLAN.md):** Dieses Dokument beschreibt die Struktur *um* den Scan herum — Aufnahme, Speicherung, Darstellung. Der Tiefen-Plan beschreibt, was *im* Scan passiert. Beide greifen an genau einer Stelle ineinander: der gemeinsamen Kamera (§3).

---

## 1. Befund: was heute strukturell fehlt

Der aktuelle Ablauf funktioniert, aber drei Dinge sind nicht abgebildet — und zwar nicht als fehlende Bildschirme, sondern als fehlende Begriffe im Datenmodell.

### 1.1 Es gibt keine „Mahlzeit" als geloggtes Ereignis

`NutritionLogs` (`lib/data/drift_database.dart:267`) ist eine flache Tabelle einzelner Einträge mit `mealType` als Textspalte. Ein KI-Scan mit sechs Zutaten erzeugt **sechs unabhängige Zeilen**, die nur die Zeichenkette `'Lunch'` gemeinsam haben.

Damit existiert nirgends die Information:
- dass diese sechs Zeilen aus *einer* Aufnahme stammen
- welches Foto dazugehörte
- dass „Rührei mit Toast" der Name dieser Mahlzeit war
- dass man den Scan wiederholen oder ergänzen könnte

`Meals` und `MealItems` (`drift_database.dart:366`) lösen das nicht — das sind **Vorlagen** zum Wiederverwenden („Build a template from scratch" in `meals_screen.dart:321`), keine protokollierten Ereignisse. Die Namensgleichheit ist irreführend und sollte im Zuge dieser Arbeit auseinandergezogen werden.

**Das ist die Wurzel aller drei Beschwerden.** Das Foto kann nicht wieder angezeigt werden, weil es kein Objekt gibt, an dem es hängen könnte.

### 1.2 Die Aufnahmewege sind künstlich getrennt

- KI-Foto → `AiMealCaptureScreen`, nutzt `image_picker`
- Barcode → `ScannerScreen`, nutzt `qr_code_scanner_plus` mit eigener Platform-View
- Suche/Katalog/Favoriten/Vorlagen → `AddFoodScreen` mit vier Tabs

Aus Nutzersicht sind das drei Kameras für eine Handlung: „ich will festhalten, was ich esse". Der Nutzer muss vorher wissen, ob vor ihm ein Barcode oder ein Teller ist, und den passenden Knopf treffen. Das ist eine Entscheidung, die die App selbst treffen kann.

*(Nebenbefund: Der Kommentar in `scanner_screen.dart:21` nennt `flutter_zxing`, tatsächlich importiert wird `qr_code_scanner_plus`. Stale, sollte korrigiert werden.)*

### 1.3 Kein Spracheingang

Es gibt keine Sprach-Abhängigkeit im Projekt. Dabei ist die aufwendige Hälfte bereits vorhanden: `AiService.analyzeText` (`lib/services/ai_service.dart:579`) verarbeitet Textbeschreibungen vollständig, und `analyzeImages` nimmt über `textHint` bereits einen Zusatztext entgegen. Es fehlt ausschließlich der Weg von gesprochenem zu geschriebenem Wort.

---

## 2. Leitgedanken

Bevor es konkret wird, die Prinzipien, an denen sich die Entscheidungen unten messen lassen:

1. **Additiv, nicht ersetzend.** Jede Änderung muss so gebaut sein, dass bestehende Daten und bestehende Gewohnheiten unverändert weiterfunktionieren. Ein Nutzer, der nie ein Foto macht, darf von dieser Arbeit nichts merken.
2. **Ein Ort für eine Handlung.** „Erfassen, was ich esse" ist eine Handlung, kein Menü.
3. **Die Datenstruktur bildet ab, was passiert ist.** Wenn sechs Zutaten aus einem Foto stammen, muss die Datenbank das wissen. Alles andere sind Folgeprobleme.
4. **Kein Speicherwachstum ohne Obergrenze.** Fotos sind die erste Sache in dieser App, die unbegrenzt wachsen kann. Das braucht von Anfang an eine Regel.

---

## 3. Die gemeinsame Kamera

### 3.1 Der entscheidende technische Punkt

**Auf iOS kann eine einzige `AVCaptureSession` gleichzeitig Barcodes erkennen, Fotos aufnehmen und Tiefendaten liefern.** `AVCaptureMetadataOutput` mit `metadataObjectTypes = [.ean13, .ean8, .upce, .code128, ...]` läuft parallel zu `AVCapturePhotoOutput` mit `isDepthDataDeliveryEnabled` auf derselben Session, ohne zusätzliche Bibliothek und ohne nennenswerte Kosten.

Das heißt: **Der Zusammenschluss von Barcode- und KI-Kamera ist auf iOS praktisch geschenkt, wenn er zusammen mit der Tiefenaufnahme aus dem Depth-Plan gebaut wird** — es ist ein zusätzlicher Output auf einer Session, die ohnehin entsteht. Getrennt gebaut wäre es eine zweite Kamerainfrastruktur.

Das ist der Grund, warum dieser Plan jetzt geschrieben wird und nicht nach der Tiefenarbeit.

### 3.2 Kein Moduswechsel — passive Barcode-Erkennung

Die naheliegende Lösung wären Tabs („Foto | Barcode | Sprache"). Der bessere Entwurf kommt ohne aus:

Die Kamera **schaut permanent nach Barcodes**, während der Nutzer sein Bild einrichtet. Findet sie einen, erscheint unten ein Chip: „Barcode erkannt · Barilla Penne". Antippen übernimmt das Produkt. Ignorieren kostet nichts.

- Der Auslöser macht immer ein KI-Foto.
- Das Mikrofon-Symbol startet Diktat, wahlweise *statt* oder *zusätzlich zu* einem Foto.
- Der Nutzer muss nie vorher wissen, was vor ihm liegt.

Damit verschwindet die Frage „warum ist das getrennt?" nicht durch Zusammenlegen zweier Modi, sondern dadurch, dass es keine Modi mehr gibt.

### 3.3 Plattformen

| | iOS mit LiDAR | iOS ohne LiDAR | Android |
|---|---|---|---|
| Session | `AVCaptureSession`, nativ | `AVCaptureSession`, nativ | `camera` Plugin |
| Barcode | `AVCaptureMetadataOutput` | dito | Dekodierung auf Preview-Frames |
| Tiefe | ja | nein | nein |
| Foto | `AVCapturePhotoOutput` | dito | `camera` |

Dart-seitig eine Schnittstelle, drei Implementierungen:

```dart
abstract class UnifiedCaptureController {
  Stream<BarcodeHit> get barcodes;
  Future<CaptureResult> takePhoto();   // Foto + optional Tiefe
  CaptureCapabilities get capabilities;
}
```

Für Android braucht es eine Barcode-Dekodierung auf Kameraframes. Empfehlung: eine FLOSS-Variante (ZXing-basiert) statt ML Kit — kein Google-Play-Services-Zwang, passend zur Ausrichtung der App. Das ist der einzige Punkt, an dem eine neue Abhängigkeit dazukommt.

**Fallback:** `ScannerScreen` und der `image_picker`-Weg bleiben zunächst bestehen und werden verwendet, wenn die vereinheitlichte Kamera nicht startet. Erst wenn die neue Kamera auf beiden Plattformen stabil läuft, werden sie entfernt.

### 3.4 Galerie

Der Import aus der Galerie muss erhalten bleiben (nicht jedes Essen wird live fotografiert). Er landet im selben Ablauf, nur ohne Tiefendaten und ohne Barcode-Erkennung.

---

## 4. Spracheingabe

Der kleinste der drei Punkte, mit der besten Wirkung pro Aufwand.

### 4.1 Zwei Einsatzarten

**A — Diktat statt Foto.** „Ich hatte zwei Scheiben Vollkornbrot mit Frischkäse und einen Apfel." → Text → `AiService.analyzeText`. Der Pfad existiert vollständig.

**B — Diktat zusätzlich zum Foto.** Genau das, was ein Foto nicht zeigen kann: „Das war in Olivenöl gebraten, etwa zwei Esslöffel." → geht als `textHint` in `analyzeImages`.

**B ist der wertvollere Fall** und wird meist übersehen. Zubereitungsart und unsichtbare Zutaten sind eine der größten Fehlerquellen bei reiner Bildschätzung — und der Nutzer weiß sie. Es ist derselbe Hebel wie die LiDAR-Messung, nur für eine andere Unbekannte.

### 4.2 Technik und Datenschutz

Systemdiktat über die jeweilige Plattform-API (iOS `SFSpeechRecognizer`, Android `SpeechRecognizer`), angesprochen über ein Flutter-Paket.

**Wichtig für eine Privacy-first-App:** `SFSpeechRecognizer` schickt Audio standardmäßig an Apple-Server. `requiresOnDeviceRecognition = true` muss gesetzt werden, wo das Gerät es unterstützt. Wo On-Device-Erkennung nicht verfügbar ist, muss der Nutzer das **vor** der ersten Nutzung erfahren — einmalig, klar, nicht als Fußnote. Wer ablehnt, tippt weiter.

Diese Einschränkung gehört auch in die Datenschutzerklärung, wenn das Feature ausgeliefert wird.

### 4.3 Bedienung

Halten zum Sprechen, loslassen zum Beenden — kein Start/Stopp-Modus, in dem man vergessen kann, dass das Mikrofon läuft. Der erkannte Text erscheint sofort editierbar, bevor er an die KI geht. Diktat ist fehleranfällig; ein Tippfehler in „150 g" wird sonst zu einer falschen Mahlzeit.

---

## 5. Die Mahlzeit als Objekt — der Kern

Das ist die Änderung, aus der alles andere folgt.

### 5.1 Neue Tabelle

```dart
/// Ein protokolliertes Ess-Ereignis. Klammert die Einträge, die zusammen
/// erfasst wurden, und trägt das Foto sowie die Herkunft.
///
/// Nicht zu verwechseln mit [Meals] — das sind wiederverwendbare Vorlagen.
class MealEntries extends Table with HybridId, MetaColumns {
  TextColumn get userId => text().nullable()();

  DateTimeColumn get consumedAt => dateTime()();
  TextColumn get mealType => text()();          // Breakfast | Lunch | Dinner | Snack

  /// Anzeigename, z.B. „Rührei mit Toast". Von der KI oder vom Nutzer.
  TextColumn get title => text().nullable()();

  /// aiPhoto | aiVoice | aiText | barcode | manual | template
  TextColumn get source => text()();

  /// Relativ zum App-Support-Verzeichnis, nie absolut (§6.3).
  TextColumn get photoPath => text().nullable()();
  TextColumn get photoThumbPath => text().nullable()();

  /// Roher Diktattext, falls vorhanden — damit ein erneuter Scan
  /// denselben Zusatzkontext bekommt.
  TextColumn get voiceTranscript => text().nullable()();

  /// JSON: Provider, Modell, Maßstab-Fakten, Regionen (§7 im Depth-Plan).
  /// Bewusst schemalos — dieser Teil wird sich noch bewegen.
  TextColumn get captureMeta => text().nullable()();
}
```

### 5.2 Die eine Spalte, die alles verbindet

```dart
// NutritionLogs bekommt:
TextColumn get mealEntryId => text().nullable()
    .references(MealEntries, #id, onDelete: KeyAction.setNull)();
```

**`nullable` ist hier die wichtigste Entscheidung des ganzen Dokuments.**

- Jede bestehende Zeile bleibt gültig, unverändert, ungruppiert.
- Es wird **keine** Migration bestehender Daten in künstliche Gruppen vorgenommen. Eine erfundene Mahlzeit „Frühstück 14.03." aus drei zufällig zusammenliegenden Einträgen wäre eine Behauptung über Vergangenes, die wir nicht belegen können.
- `onDelete: setNull` statt `cascade`: Löscht der Nutzer eine Mahlzeit, sollen ihm nicht ungefragt die Einzeleinträge verschwinden. Löschen der Gruppe und Löschen der Einträge sind zwei verschiedene Absichten, und die Oberfläche muss danach fragen.

Schema-Version geht von 24 auf 25.

### 5.3 Wie das Tagebuch das darstellt

`DiaryScreen` gruppiert weiterhin nach `mealType`. Innerhalb einer Mahlzeitengruppe wird zusätzlich nach `mealEntryId` gebündelt:

```
Mittagessen                                        640 kcal
┌──────────────────────────────────────────────┐
│ [Foto]  Rührei mit Toast              420 kcal│   ← MealEntry, aufklappbar
│         3 Zutaten · 12:40                     │
└──────────────────────────────────────────────┘
  Apfel                                    95 kcal    ← Einzeleintrag, wie heute
  Kaffee mit Milch                        125 kcal
```

Einträge ohne `mealEntryId` sehen exakt aus wie heute. Für einen Bestandsnutzer, der nie ein Foto macht, ändert sich nichts — das ist die Prüfbedingung für diesen Entwurf.

### 5.4 Der Mahlzeiten-Detailscreen

Neu: `MealEntryScreen`. Erreichbar durch Antippen der Karte im Tagebuch.

- Foto oben, mit den Callout-Flächen aus dem Depth-Plan (§9 dort), sofern vorhanden
- darunter die Zutatenliste mit Mengen, einzeln editierbar
- Summen
- Aktionen:
  - **Zutat hinzufügen** → in den bestehenden Auswahlablauf, Ergebnis landet in dieser Gruppe
  - **Erneut analysieren** → schickt dasselbe Foto (und denselben Diktattext) noch einmal an die KI; das Ergebnis wird als Vorschlag *neben* dem bestehenden gezeigt, nicht stillschweigend übernommen
  - **Als Vorlage speichern** → schlägt die Brücke zu den bestehenden `Meals`
  - **Mahlzeitentyp ändern**, **Zeit ändern**
  - **Löschen** → mit der Rückfrage aus §5.2

`AiMealReviewScreen` und `MealEntryScreen` zeigen dasselbe: eine Mahlzeit mit Foto und Zutaten. Der Unterschied ist nur, ob sie schon gespeichert ist. Sie sollten sich eine gemeinsame Widget-Ebene teilen, statt zwei Mal zu existieren.

---

## 6. Fotospeicherung

### 6.1 Ehrliche Rechnung

Die Annahme „sehr wenig Speicher" hält der Nachrechnung nicht ganz stand:

| Format | 1024 px lange Kante | 320 px Vorschau |
|---|---|---|
| JPEG q70 | ~110 KB | ~18 KB |
| WebP q75 | ~70 KB | ~12 KB |
| HEIC | ~55 KB | ~10 KB |

Bei realistisch drei fotografierten Mahlzeiten pro Tag sind das rund 1.100 Fotos im Jahr:

- WebP: **~77 MB pro Jahr**
- HEIC: **~60 MB pro Jahr**

Das ist nicht dramatisch, aber es ist auch nicht nichts — und es wächst monoton. Nach drei Jahren steht eine Viertelgigabyte im App-Container, für Fotos, die der Nutzer fast nie wieder ansieht.

### 6.2 Aufbewahrungsregel

Vorschlag als Standard, in den Einstellungen änderbar:

- Vollbild **180 Tage**, danach automatisch auf die Vorschau reduziert
- Vorschau bleibt dauerhaft — 12 KB pro Mahlzeit ist vernachlässigbar, und die Karte im Tagebuch bleibt bebildert
- Optionen: „Fotos nie löschen" / „nie speichern" / „nach 30/90/180/365 Tagen reduzieren"

Nach einem Jahr mit dieser Regel: ~550 Vollbilder (38 MB) + ~1.100 Vorschauen (13 MB) ≈ **51 MB**, stabil statt wachsend.

Ein Hinweis auf den belegten Speicher gehört in die Einstellungen, mit einer Möglichkeit, alle Fotos zu löschen, ohne die Mahlzeiten zu verlieren.

### 6.3 Format und Ort

**Kodierung nativ zum Aufnahmezeitpunkt**, in derselben Plugin-Schicht wie die Tiefenaufnahme. Grund: Flutter hat keinen mitgelieferten WebP- oder HEIC-Encoder, und eine Bildbibliothek nur dafür ins Projekt zu holen, wäre unverhältnismäßig — die Plattformen können es beide von sich aus (iOS: HEIC über `AVCapturePhotoOutput`; Android: `Bitmap.compress(WEBP_LOSSY)`).

Ablage unter Application Support, **nicht** unter Documents — Documents wird auf iOS in iCloud gesichert, und ein automatisches Backup von 80 MB Essensfotos will niemand.

`photoPath` speichert **relative** Pfade. Der Container-Pfad ändert sich auf iOS bei jedem Update; absolute Pfade in der Datenbank sind ein garantierter Fehler.

### 6.4 Backup und Export

`TrainLibreBackup` (`lib/features/app/domain/models/train_libre_backup.dart`) ist ein JSON-Modell — Fotos passen dort nicht hinein. Zwei gangbare Wege:

1. **Fotos vom Backup ausschließen**, Mahlzeiten bleiben mit allen Nährwerten erhalten, nur das Bild fehlt nach der Wiederherstellung. Einfach, ehrlich, muss dem Nutzer beim Backup gesagt werden.
2. **Backup als Archiv** (das `archive`-Paket ist bereits Abhängigkeit): JSON plus `photos/`-Ordner in einer Datei.

Empfehlung: **Weg 1 zuerst**, Weg 2 als eigener Vorgang danach. Backup-Format zu ändern ist ein Eingriff mit eigener Risikoklasse und gehört nicht in denselben Schritt wie ein neues Feature.

---

## 7. Mahlzeitentypen und Getränke

Hier lautet meine Empfehlung ausdrücklich: **in diesem Durchgang nicht anfassen.**

### 7.1 Was der Befund ist

Vier feste Typen (`meal_editor_screen.dart:11`), plus Flüssigkeiten in einer eigenen Tabelle `FluidLogs` (`drift_database.dart:317`), die über `linkedNutritionLogId` optional auf einen Nährwerteintrag zeigt. „Water & Drinks" ist damit tatsächlich ein Zwitter: teils eigene Tabelle, teils Querverweis.

### 7.2 Warum trotzdem nicht jetzt

- Die Mahlzeitentypen hängen an mehr, als es aussieht: HealthKit-Export, Home-Widgets, Statistik-Aggregation, Backup-Format, bestehende Nutzerdaten.
- Die drei Beschwerden aus §1 werden von den Mahlzeitentypen **nicht** verursacht. Sie werden von der fehlenden Gruppierung verursacht. Die Gruppierung löst sie vollständig, ohne einen einzigen Typ anzufassen.
- Zwei strukturelle Umbauten gleichzeitig machen jeden Fehler doppelt schwer zuzuordnen.

### 7.3 Was der neue Entwurf dafür offenhält

`MealEntries.mealType` ist eine Textspalte ohne Enum-Zwang in der Datenbank. Frei definierbare Mahlzeitentypen später einzuführen ist damit eine Änderung an der Oberfläche und an einer Nachschlagetabelle — nicht an der Struktur. Ebenso kann eine `MealEntry` später Flüssigkeiten aufnehmen, indem `FluidLogs` dieselbe `mealEntryId` bekommt. Beides ist vorbereitet, ohne es jetzt zu tun.

Als eigenständiger, späterer Schritt festgehalten — nicht vergessen, nur nicht jetzt.

---

## 8. Auswirkungen auf die bestehende Oberfläche

| Bildschirm | Änderung |
|---|---|
| `AddFoodScreen` | Der KI-Knopf und der Barcode-Knopf werden **ein** Knopf: „Scannen". Die vier Tabs bleiben unverändert. |
| `ScannerScreen` | bleibt vorerst als Fallback, wird nach Stabilisierung der neuen Kamera entfernt |
| `AiMealCaptureScreen` | wird zur vereinheitlichten Kamera; `image_picker` bleibt als Galerie-Weg |
| `AiMealReviewScreen` | teilt seine Widget-Ebene mit dem neuen `MealEntryScreen` |
| `DiaryScreen` | gruppiert zusätzlich nach `mealEntryId`; ohne Gruppen unverändert |
| `MealScreen` / `MealsScreen` | unverändert (Vorlagen), bekommen nur den Eingang „aus Mahlzeit erstellen" |
| `FoodDetailScreen` | zeigt zusätzlich, zu welcher Mahlzeit ein Eintrag gehört, sofern zutreffend |

---

## 9. Phasenplan

Bewusst so geschnitten, dass jede Phase für sich auslieferbar ist.

| Phase | Inhalt | Auslieferbar als |
|---|---|---|
| **N1** | `MealEntries` + `mealEntryId` (nullable), Schema 24→25, Repository-Ebene, keine UI | nichts sichtbar, Fundament steht |
| **N2** | KI-Scan schreibt eine `MealEntry`; `DiaryScreen` gruppiert; `MealEntryScreen` (lesend) | „deine KI-Mahlzeiten hängen jetzt zusammen" |
| **N3** | Fotospeicherung inkl. Aufbewahrungsregel und Einstellungen | „du siehst dein Foto wieder" |
| **N4** | `MealEntryScreen` schreibend: Zutat hinzufügen, erneut analysieren, als Vorlage speichern | die eigentliche Verbesserung |
| **N5** | Spracheingabe (Diktat allein + Diktat als Zusatz zum Foto) | kleines, eigenständiges Feature |
| **N6** | Vereinheitlichte Kamera mit passiver Barcode-Erkennung | zusammen mit **P0** aus dem Depth-Plan |
| **N7** | Altpfade entfernen, `AddFoodScreen` auf einen Scan-Knopf reduzieren | Aufräumen |
| *später* | Mahlzeitentypen und Getränke (§7) | eigener Plan |

**N1–N4 sind unabhängig vom Depth-Plan** und können sofort beginnen. **N6 sollte mit P0 zusammen gebaut werden** — die native Kamerasession entsteht dort ohnehin, und zwei Mal ist sie teurer als ein Mal.

Empfohlene Reihenfolge über beide Dokumente hinweg:
```
N1 → N2 → N3 → N4 → (P0+N6) → P1 → P2 → P3 → P4 [Go/No-Go] → N5 → P5…
```
Begründung: Die Struktur zuerst, weil sie den größten spürbaren Gewinn bringt und nichts riskiert. Die Kamera dann einmal für beide Zwecke. Die Tiefenmessung danach, mit ihrem eigenen Abbruchkriterium.

---

## 10. Risiken

| Risiko | Auswirkung | Umgang |
|---|---|---|
| Gruppierung verwirrt Bestandsnutzer | Beschwerden über „veränderte" Ansicht | Einträge ohne Gruppe sehen identisch aus; keine Rückwirkung auf Altdaten |
| Fotospeicher wächst unbemerkt | App belegt hunderte MB | Aufbewahrungsregel ab N3, sichtbarer Speicherstand in den Einstellungen |
| Absolute Pfade in der DB | Fotos nach App-Update weg | ausschließlich relative Pfade (§6.3), Testfall dafür |
| Backup enthält keine Fotos | Enttäuschung nach Wiederherstellung | vorher sagen, nicht hinterher (§6.4) |
| Diktat sendet Audio an Apple/Google | Widerspruch zum Privacy-Versprechen | On-Device erzwingen wo möglich, sonst einmalig und deutlich aufklären (§4.2) |
| Vereinheitlichte Kamera bricht den Barcode-Weg | Kernfunktion kaputt | `ScannerScreen` bleibt bis zur Stabilisierung als Fallback |
| Passive Barcode-Erkennung stört beim Fotografieren | ständige Chips im Bild | nur bei stabilem Treffer über mehrere Frames, ein Chip, verschwindet von selbst |
| Zwei Umbauten gleichzeitig | Fehler nicht zuzuordnen | Mahlzeitentypen/Getränke ausdrücklich verschoben (§7) |

---

## 11. Offene Punkte

- **Benennung.** `Meals` (Vorlagen) und `MealEntries` (Ereignisse) nebeneinander ist verwirrend. Sauberer wäre, `Meals` in `MealTemplates` umzubenennen — das berührt aber Backup und Sync und ist eine eigene Entscheidung.
- **Mehrere Fotos pro Mahlzeit?** Das Datenmodell hat aktuell ein Foto pro `MealEntry`. Eine eigene `MealPhotos`-Tabelle wäre allgemeiner, aber ohne belegten Bedarf verfrüht. Vorschlag: ein Foto, bis jemand mehr braucht.
- **Nachträglich gruppieren.** Soll der Nutzer bestehende Einzeleinträge zu einer Mahlzeit zusammenfassen können? Nützlich, aber eigene UI-Arbeit. Nach N4 entscheiden.
- **Telemetrie.** Welche Quelle (`source`) wie oft genutzt wird, wäre die wertvollste Kennzahl für alle weiteren Entscheidungen an diesem Ablauf. Muss gegen `TELEMETRY.md` geprüft und im Rahmen der bestehenden Zustimmung erhoben werden.
- **Android-Barcode-Bibliothek.** Konkrete Auswahl steht aus; Kriterium ist FLOSS und keine Play-Services-Abhängigkeit.
