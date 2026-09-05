# Diary-Gewichtskarte — Implementierungsbericht

Stand: 5. September 2026, Branch `develop`.

Die Gewichtseingabe sitzt im normalen Diary direkt nach den Supplements und vor den Schritten (`lib/features/diary/presentation/diary_screen.dart:1045`). Die Startansicht und der überlagerte leere Tag zeigen die Karte separat oberhalb ihres bisherigen Inhalts, damit die Eingabe dort erreichbar bleibt (Zeilen 932 und 1153). Die alte `WeightChartCard` wurde entfernt.

## Entscheidungen und Belege

| Punkt | Umsetzung und Beobachtung |
| --- | --- |
| Diagramm | Kein Umzug nötig: `measurements_screen.dart:423` verwendet bereits `MeasurementChartWidget` mit `_activeDateRange`, Repository und gewählter Messart. Die neue Navigation wählt `weight` vor (`weight_card.dart:306`). |
| Erstansicht | Einspaltige Variante 1b des Entwurfs: Erklärung und voller Button „Gewicht eintragen“. Tagesansicht: Variante 1d ohne optionales Delta, mit „heute“ und Chevron. Keine Zielzeile. `weight_card.dart:175` ff. |
| Gestaltung | Vorhandene `GlassActionableCard` und `AppCardContainer`, 16 px Innenabstand, Theme-Farben und Lucide-Chevron. Die vorhandene `AppCardContainer` delegiert an `SummaryCard`; diese hat solide neutrale Flächen und 19-px-Squircle-Radien. Diese bestehenden Projektoberflächen bleiben erhalten, statt die HTML-Glasverläufe und 20-px-Radien als eigenes Kartendesign einzuführen. |
| Einheiten | Der Entwurf startet ohne Historie neutral. Hier ist die Basis einheitlich 75 kg (165,3 lbs nach Umrechnung), statt des unabhängig gesetzten HTML-Beispiels 165,0 lb. Die App-Einheitenbeschriftung bleibt `lbs` gemäß `UnitService`. Vorbelegung und Speicherung runden in der sichtbaren Einheit auf eine Nachkommastelle; danach erfolgt die Rückrechnung nach kg (`weight_card.dart:80`, `:106`). |
| Mehrfach am Tag | Separate Zeitpunkte bleiben als einzelne Wiegungen erhalten. `_latestWeightPerDay` sortiert nach Zeitpunkt und überschreibt den Tageswert (`body_nutrition_analytics_engine.dart:209`). Korrekturen in derselben SQLite-Sekunde ersetzen nur Gewichtseinträge dieses Zeitpunkts, atomar in einer Transaktion. Dadurch gibt es keinen mehrdeutigen Gleichstand (`profile_local_data_source.dart:323`). |
| Diary-Datum | Die Karte folgt dem gewählten Tag. Frühere Tage zeigen nur damals bekannte Gewichte, und eine Eingabe wird dem gewählten Datum mit aktueller Uhrzeit zugeordnet. Statt „heute“ steht dort das Datum. An zukünftigen Tagen ist die Karte ausgeblendet (`weight_card.dart:54`, `:106`, `:141`). |
| Animation | 300 ms, ease-out cubic; Lineal ab Phase 0,18, Auslöser bis 0,4, Aktionen ab 0,5. Loslassen schreibt nichts. Haptik über `HapticFeedback.selectionClick` beim Überschreiten ganzer kg bzw. 5 lbs (`weight_card.dart:28`, `:175`; `weight_ruler.dart:41`). |
| Lineal | 7 px Teilstrichabstand, 0,1 kg bzw. 0,2 lbs je Strich; Eingabeauflösung auch in lbs 0,1. Hauptstriche je 1 kg bzw. 5 lbs. Screenreader können um 0,1 erhöhen/senken. Grenzen und neutraler Hinweis entsprechen dem HTML-Entwurf. |
| Enge Breiten | Bei unzureichendem Platz wandern die Aktionen unter den Wert; bei großer Schrift können die beiden Aktionen ebenfalls umbrechen. Volle Beschriftungen bleiben erhalten (`weight_card.dart:314`). |
| Fehlerfälle | Laden bietet einen erneuten Versuch; bei Schreibfehlern bleiben Entwurf und Aktionen erhalten. Speichern ist während eines laufenden Schreibvorgangs gesperrt (`weight_card.dart:106`, `:147`). |
| Lokalisierung | Zehn neue Texte in jeder der fünf ARB-Dateien, einschließlich pluralisierter Altersanzeige. Klassen mit `flutter gen-l10n` generiert, nicht von Hand bearbeitet. Commit `8e96c364`. |

Die HTML-Dateien wurden als Designreferenzen gelesen; `support.js` ist deren Rendering-Laufzeit und wurde nicht in die App übernommen.

## Prüfung

- `dart format` nur auf den sechs geänderten/neuen Dart-Quelldateien außerhalb generierter Dateien angewendet.
- `flutter analyze`: **No issues found!**, 16,9 s. Vollständige Ausgabe: `build/verification/diary-weight-card/flutter-analyze.log`.
- `flutter test`: **1.431 bestanden, 7 übersprungen, 0 fehlgeschlagen**, 66 s. Vollständige Ausgabe: `build/verification/diary-weight-card/flutter-test.log`. Die sieben bestehenden Skip-Fälle betreffen die optionalen vollständigen Katalogartefakte (`exercise_catalog_v2_contract_test.dart`, `exercise_catalog_import_test.dart`); es wurde kein Skip hinzugefügt.
- 26 neue Tests: 23 Widget-Fälle und 3 Datenzugriffstests mit `NativeDatabase.memory()`. Belege: `test/features/diary/weight_card_test.dart:169` ff. und `weight_data_source_test.dart`. Sie prüfen die drei Zustände, Navigation auf Gewichtshistorie, echte Drag-Eingabe und Speicherung in kg bei beiden Anzeigesystemen, Loslassen/Abbrechen, Einheitwechsel während der Eingabe, historische Daten, reaktive Updates, 300-ms-Animation, Wertebereich, Schreibfehler, Screenreader-Aktion sowie fünf Sprachen in beiden Helligkeiten bei 320 Punkten und 150 % Schriftgröße.
- Visuelle Kontrolle anhand separat gerenderter Flutter-Widget-Bilder mit geladenen Inter- und Lucide-Schriften: Erstansicht, heutiger Wert, offene kg/lbs-Eingabe und deutsche Pfundansicht bei schmaler Breite. Bilder liegen in `build/verification/diary-weight-card/weight-*.png`. Das Test-Theme bildet Farben/Schriften der App nach, ist aber kein Screenshot des laufenden Diary-Screens. Die Bilder stammen aus dem 24-Test-Lauf vor Ergänzung der zwei zusätzlichen Animations-/Reaktivitätstests; die vollständige Suite enthält alle 26.
- Reproduzierbare Widget-Bilder: `flutter test test/features/diary/weight_card_test.dart test/features/diary/weight_data_source_test.dart --dart-define=WEIGHT_QA=true` (Ausgabe `/tmp/weight-*.png`).
- `git diff --check`: ohne Befund.

## Geräte-Build und verbleibender manueller Test

`flutter build ios --release` wurde erfolgreich abgeschlossen und mit dem konfigurierten Development Team signiert: **`build/ios/iphoneos/Runner.app` (54,7 MB)**, Xcode-Bauzeit **99,1 Sekunden**. Ausgabe: `build/verification/diary-weight-card/ios-build.log`. Der Build meldete einen nicht blockierenden Hinweis zur noch fehlenden Swift-Package-Manager-Unterstützung von `icloud_storage`.

`codesign --verify --deep --strict build/ios/iphoneos/Runner.app` war mit Zugriff auf den macOS-Zertifikatsspeicher ebenfalls erfolgreich (Exit 0; `build/verification/diary-weight-card/codesign.log`).

**Bereit für deinen manuellen Gerätetest.**

`flutter devices` fand kein erreichbares physisches iPhone; die drahtlosen Geräte meldeten Code -27. Deshalb wurde kein Diary-Durchlauf auf einem echten Gerät ausgeführt. Wie beauftragt wurde keine Simulator-Runde durchgeführt. Haptik und der vollständige Diary-Ablauf bleiben Teil deines manuellen Gerätetests. Beleg: `build/verification/diary-weight-card/devices.log`.

Die Prüfprotokolle und Bilder liegen im ignorierten Build-Verzeichnis und sind lokale Nachweise, keine eingecheckten Binärdateien.

## Commits

- `efa8ee7f` — Add reactive weight access and kilogram-only persistence (2 Dateien, 100 hinzugefügte Zeilen).
- `8e96c364` — Localize diary weight entry in all five languages (11 Dateien, 340 hinzugefügt, 5 entfernt).
- `6e571818` — Add an accessible weight ruler with major-tick haptics (1 Datei, 166 hinzugefügt).
- `e580e906` — Add the animated diary weight card with kilogram persistence tests (2 Dateien, 812 hinzugefügt).
- Abschließender Commit: Diary-Platzierung, Entfernen der redundanten Diagrammkarte, Changelog und dieser Bericht.

Die Angaben lassen sich mit `git show --stat <commit>` und `git log -5 --oneline` nachvollziehen.
