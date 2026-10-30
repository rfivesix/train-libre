**Version:** 1.8  
**Stand:** 8. Oktober 2026  

Diese Datenschutzerklärung informiert Sie gemäß Art. 13 und 14 der Datenschutz-Grundverordnung (DSGVO) über die Verarbeitung personenbezogener Daten und gesundheitsbezogener Daten in der mobilen Applikation „Train Libre“. 

Da Train Libre als Local-First-Applikation konzipiert ist, verbleibt die vollständige Kontrolle über Ihre Daten zu jedem Zeitpunkt direkt bei Ihnen. Wir betreiben keine zentralen Datenbank- oder Anwendungsserver zur Speicherung Ihrer Profile, Workouts oder Ernährungsprotokolle.

---

## 1. Verantwortlicher

Verantwortlich für die Datenverarbeitung im Sinne des Art. 4 Nr. 7 DSGVO ist der Entwickler und Diensteanbieter:

Richard Georg Schotte  
Bundesallee 114  
12161 Berlin  
Deutschland  

E-Mail: feedback@schotte.me  
Telefon: (+49) 1520 6915571  

Da es sich bei dem Verantwortlichen um einen Einzelentwickler handelt und die gesetzlichen Voraussetzungen zur verpflichtenden Bestellung eines Datenschutzbeauftragten gemäß Art. 37 DSGVO bzw. § 38 BDSG nicht vorliegen, ist kein gesonderter Datenschutzbeauftragter bestellt. Sämtliche datenschutzbezogene Anfragen können direkt an die oben genannte E-Mail-Adresse gerichtet werden.

---

## 2. Grundphilosophie

Train Libre beruht auf dem Prinzip des „Privacy by Design“ und des „Privacy by Default“ (Art. 25 DSGVO) sowie auf dem Grundsatz der Datensparsamkeit (Art. 5 Abs. 1 lit. c DSGVO). 

* **Keine Benutzerkonten:** Für die Nutzung der App ist keine Registrierung und kein Erstellen eines Benutzerkontos erforderlich. Es werden keine E-Mail-Adressen, Passwörter oder Anmeldedaten auf externen Servern gespeichert.
* **Local-First-Architektur:** Profil-, Trainings-, Ernährungs-, Gesundheits- und Messdaten werden grundsätzlich lokal auf Ihrem Gerät gespeichert. Optionale Funktionen können Daten wie nachfolgend beschrieben übertragen oder Kopien außerhalb des Geräts erstellen.
* **Kein zentraler Backend-Server:** Wir betreiben keine zentrale Cloud-Datenbank zur Speicherung Ihrer Trainings- und Ernährungsprotokolle. Optionale Dienste und Backups können jedoch Datenkopien erhalten oder speichern.
* **Keine Werbung:** Train Libre verwendet keine Werbenetzwerke und keine verhaltensbasierte Werbung. Optionale Nutzungsstatistiken sind standardmäßig deaktiviert. Aktivierte Ereignisse können technische Kennungen und Kennzahlen aus Ernährungs- oder Gewichtsbereichen enthalten und auch ohne Namen personenbezogen oder gesundheitsbezogen sein. Einzelheiten stehen unter Ziffer 6 C.

---

## 3. Lokal verarbeitete Daten

Durch die Nutzung der App verarbeitet das Betriebssystem Ihres Mobilgeräts Daten in einer lokalen SQLite-Datenbank (Drift/sqflite). Die Speicherung dient dem Betrieb der App und der Erfüllung der Kernfunktionen.

### A. Kategorien verarbeiteter Daten

Die lokale Datenbank umfasst folgende Datenkategorien:

1. **Profileinstellungen und Ziele:** Benutzername, Geburtsdatum, Körpergröße, Geschlecht, Profilbild-Dateipfad sowie individuell festgelegte Tagesziele (Ziel-Kalorien, Ziel-Proteine, Ziel-Kohlenhydrate, Ziel-Fett, Ziel-Wasser, Ziel-Schritte).
2. **Trainings- und Aktivitätsprotokolle (Workouts):** Trainingspläne (Routinen), Übungsvorlagen, historische Workout-Protokolle (Start- und Endzeit, Notizen, Übungssätze mit rep- und Gewicht-Werten, RPE- und RIR-Werten, Pausenzeiten, kardiovaskuläre Aktivitäten inklusive Distanz, Dauer und verbrannten Kalorien).
3. **Ernährungs- und Flüssigkeitsprotokolle (Nutrition & Fluids):** Konsumierte Lebensmittel (Zeitpunkt, Menge in Gramm/Millilitern, Mahlzeitentyp), Wasser- und Getränkeprotokolle (Menge, Nährstoffgehalt, Koffeingehalt).
4. **Lebensmittel- und Produktkatalog (User-Products):** Individuell vom Benutzer angelegte Produkte mit Barcode, Produktname, Marke und Makro-/Mikronährwertangaben pro 100g/ml (Kalorien, Eiweiß, Kohlenhydrate, Fett, Zucker, Ballaststoffe, Salz, Koffein, Zutatenliste und Zusatzstoffe).
5. **Supplemente (Nahrungsergänzungsmittel):** Eingerichtete Supplemente (Name, Standarddosis, Einheit, Tagesziel und Tageslimit) sowie historische Supplement-Logeinträge mit Einnahme-Zeitpunkt und Menge.
6. **Körpermaße und Messungen (Measurements):** Historische Messwerte für das Körpergewicht und verschiedene Körperumfänge (z. B. Brust, Taille) inklusive Datum und Einheit.
7. **Pulsdaten-Aggregate:** Lokale stündliche Aggregationen der Herzfrequenz (minimale, maximale und durchschnittliche Schläge pro Minute sowie Stichprobenanzahl).
8. **Schlafdaten-Analysen:** Aufbereitete Schlafdaten inklusive Schlafphasen (Tiefschlaf, REM, Leichtschlaf, Wachphasen), Schlaf-Effizienz, Ruheherzfrequenz, Schlafunterbrechungen, Schlaf-Regularität sowie historische Rohdaten-Importe aus den System-Schnittstellen.
9. **Lokale Schrittsegmente:** Aus den System-Schnittstellen importierte Schrittzahlen mit genauen Start- und Endzeitpunkten sowie Kennungen der Datenquelle zur lokalen Bereinigung von Dubletten.

### B. Rechtsgrundlagen der Verarbeitung

Die Rechtsgrundlage hängt von der jeweiligen Funktion und dem Verarbeitungszweck ab. Für bestimmte Verarbeitungen stützt sich Train Libre auf Ihre Einwilligung; sie kann für die Zukunft widerrufen werden. Das Löschen einzelner Einträge oder das Zurücksetzen der App ist nicht automatisch ein Widerruf und macht bereits erfolgte Verarbeitung nicht rückgängig. Details zu optionalen Übermittlungen stehen in den jeweiligen Abschnitten dieser Erklärung. Die konkrete rechtliche Bewertung sollte anhand der tatsächlichen Konfiguration geprüft werden.

---

## 4. Drittanbieter-Integrationen / BYOK

Optionale Funktionen können Daten an externe Dienste oder einen von Ihnen konfigurierten Endpunkt übertragen. Die Datenverarbeitung des jeweiligen Dienstes richtet sich nach dessen geltenden Bedingungen und Einstellungen.

### A. KI: Chat, Mahlzeitenerkennung und Entwürfe

Train Libre bietet optionale KI-Funktionen für Chat, Mahlzeitenerkennung und Entwürfe wie Routinen, Trainingspläne und Rezepte. Schätzungen und Vorschläge können unvollständig oder falsch sein.

**Ihre Nachricht.** Wenn Sie eine Chatnachricht absenden, werden der von Ihnen eingegebene oder diktierte Text und angehängte Bilder an das Modell bzw. den Anbieter gesendet, der für diese Anfrage verwendet wird. Dies geschieht vor einer separaten Anfrage zum Lesen gespeicherter App-Daten. Die Nachricht oder ein Bild kann selbst personenbezogene oder Gesundheitsdaten enthalten. Die Anfrage kann begrenzten Gesprächskontext, Anweisungen, Modellangaben und frühere Inhalte enthalten. Nicht jede Anfrage enthält gespeicherte App-Daten; das Absenden einer Nachricht ist von der Freigabe solcher Daten zu unterscheiden. Diktierfunktionen können je nach Gerät und Einstellungen einen Spracherkennungsdienst verwenden. Die optionale Bereinigung von Mahlzeiten-Transkripten kann Text vor dem Absenden zur Verarbeitung übertragen.

**Gespeicherte App-Daten.** Der Assistent kann etwa Workouts, Ernährungstagebuch, Schritte, Schlaf, Erholung, Messwerte, Ziele, Profil, Supplemente, Rezepte, Übungen, Routinen und Trainingspläne anfragen. Frische Lesezugriffe sind grundsätzlich durch eine Freigabeanfrage geschützt. Auto-Freigabe ist standardmäßig aus; wenn sie aktiviert ist, können spätere Anfragen ohne erneute Entscheidung freigegeben werden. Eine Anfrage nennt Kategorien und Zeitraum, zeigt aber nicht zwingend jeden übermittelten Einzelwert. Ergebnisse lokaler Abfragen und zugehörige Werkzeugaufrufe können an das Modell gesendet werden. Das Ausschalten der Auto-Freigabe ruft bereits übermittelte Daten nicht zurück und stoppt nicht zwingend laufende Vorgänge.

**Empfänger.** Die Freigabe ist nicht an einen bestimmten Anbieter gebunden. Bei Textchat kann die App bei fehlender Verfügbarkeit oder Zugangsdaten auf einen anderen konfigurierten Anbieter ausweichen und den Anbieter nach der Freigabe erneut bestimmen. Dadurch kann ein anderer Empfänger verwendet werden. Die Datenfreigabekarte selbst nennt den Empfänger nicht. Unterstützt werden unter anderem Apple Foundation Models auf kompatiblen Geräten, OpenAI, Google, Anthropic, Mistral, xAI, DeepSeek, Ollama und eigene OpenAI-kompatible Endpunkte. Eigene Endpunkte können lokal oder remote betrieben werden und Daten weiterleiten. Train Libre kann Speicherung, menschliche Prüfung, Training, Weitergabe, Löschung und Verarbeitungsorte externer Anbieter nicht verifizieren. Prüfen Sie die Bedingungen des jeweiligen API-Angebots oder Serverbetreibers.

**Verlauf und Löschung.** Nachrichten, Antworten, Fehler, Anbieter- und Modellangaben, Freigabeinformationen sowie Verweise auf Anhänge können lokal gespeichert sein; Anhänge können als Dateien vorliegen. Das Löschen eines Chats versucht, Anhänge zu entfernen. Das Zurücksetzen löscht viele App-Daten und Anbieterschlüssel, garantiert aber nicht die Entfernung jeder Datei, jedes Caches oder jeder Konfiguration. Backups, Exporte, Health-Plattformen und bereits an Anbieter übermittelte Daten sind davon getrennt. Das Löschen des lokalen Verlaufs fordert keine Löschung beim KI-Anbieter an.

### B. Offline-Katalog-Updates (Open Food Facts & Exercise Catalog)

Um Lebensmittel-Barcodes offline scannen und Übungen nachschlagen zu können, nutzt Train Libre lokale Produkt- und Übungskataloge. Diese Kataloge werden als vorkompilierte SQLite-Datenbankdateien direkt auf Ihr Gerät heruntergeladen.

* **Funktionsweise:** Die App prüft in regelmäßigen Abständen, ob Aktualisierungen für den Lebensmittelkatalog (basierend auf Open Food Facts) oder den Übungskatalog (basierend auf wger/GitHub) vorliegen. Die Prüfung und der anschließende Download der komprimierten Katalogdatenbanken erfolgen über eine verschlüsselte HTTPS-Verbindung direkt zu den Servern des Hosting-Dienstleisters (z. B. GitHub Pages / GitHub Inc. bzw. Open Food Facts).
* **BLS-Katalog:** Zusätzlich wird der Basis-Lebensmittelkatalog BLS 4.0 des Max Rubner-Instituts über GitHub geladen; er enthält Zutaten und Nährstoffwerte und wird lokal gespeichert.
* **Datenminimierung:** Beim Herunterladen der Katalog-Updates werden systembedingt technische Verbindungsdaten (insbesondere Ihre IP-Adresse, Datum/Uhrzeit des Zugriffs und der User-Agent der App) an den Hoster übertragen. Es werden zu keinem Zeitpunkt nutzergenerierte Daten, gescannte Barcodes oder persönliche Profileigenschaften an die Katalog-Hoster gesendet.
* **Lokale Barcode-Zuordnung:** Der Abgleich eines gescannten Barcodes oder die Suche nach Lebensmitteln und Übungen findet zu 100 Prozent offline auf Ihrem Gerät statt. Im Gegensatz zu herkömmlichen Ernährungs-Apps wird beim Scannen eines Produkts keine Anfrage mit dem Barcode an einen Cloud-Server gesendet.

---

## 5. Gesundheitsdaten-Schnittstellen

Train Libre kann Apple HealthKit oder Google Health Connect nutzen, wenn Sie die Funktionen aktivieren und die Plattformberechtigungen erteilen. Sie können diese Berechtigungen in den Systemeinstellungen ändern. Importierte Daten werden in der App gespeichert und ausgewertet und können in Backups oder – nach den Freigaberegeln in Abschnitt 4 – in KI-Anfragen einfließen. Das Ändern der Plattformberechtigung löscht zuvor importierte oder exportierte Daten nicht automatisch. Die Freigabe für KI-Datenzugriffe ist unabhängig von der Health-Plattformberechtigung.

## 6. Datensicherheit & Backups

Da sämtliche Daten lokal auf Ihrem Endgerät liegen, ist die Sicherheit des Geräts maßgeblich für den Schutz Ihrer Daten. 

### A. Lokale Datenisolation

Das Betriebssystem (iOS/Android) isoliert die App-Daten von Train Libre durch Sandbox-Mechanismen. Andere installierte Applikationen haben ohne Ihre Zustimmung keinen Zugriff auf die lokale SQLite-Datenbank oder die in den gesicherten App-Einstellungen hinterlegten API-Schlüssel.

### B. Manuelle und automatische Backups

Sie können Sicherungen oder Exporte erstellen und automatische Sicherungen an einem ausgewählten Speicherort aktivieren. Je nach Funktion können Datenbankeinträge, Einstellungen, KI-Verlauf und Medien enthalten sein. Ein passwortgeschützter Export ist verfügbar; schützen Sie Passwörter und unverschlüsselte Kopien. Der ausgewählte Speicherort oder das Betriebssystem kann Kopien in einem Cloud-Dienst speichern. Die optionale iCloud-Synchronisierung kann nach ihrer Aktivierung einen Datenbank-Snapshot und Medien hochladen. Prüfen Sie die Einstellungen und Datenschutzpraktiken des Speicheranbieters. Das Zurücksetzen der App löscht separat gespeicherte Backups, Exporte, Health-Plattform-Daten oder Anbieterkopien nicht. Temporäre Dateien und fehlgeschlagene Bereinigungen können weitere Kopien hinterlassen; eine sofortige vollständige Löschung kann nicht zugesichert werden.

### C. Optionale Nutzungsstatistik

Nutzungsstatistiken sind standardmäßig deaktiviert. Bei Aktivierung verwendet die App den PostHog-EU-Eingang für pseudonyme Ereignisse. Diese können technische Kennungen, App- und Gerätekontext, Bildschirm- und Funktionsnutzung, genaue Trainingszähler und -dauer, Ernährungseintragszähler, den Status von KI-Anfragen sowie Kennzahlen aus Ernährungs- oder Gewichtsbereichen enthalten. Auch ohne Namen können solche Ereignisse personenbezogen oder gesundheitsbezogen sein. Die App konfiguriert IP- und Standortverarbeitungsoptionen; die tatsächliche Netzwerk- und Serververarbeitung hängt auch von der Dienstkonfiguration ab.

Sie können künftige Telemetrie in den Einstellungen ausschalten. Die Löschfunktion setzt lokale Kennungen und Zähler zurück und versucht, eine Löschanfrage zu senden; sie bestätigt keine serverseitige Löschung und erfasst möglicherweise nicht frühere Kennungen oder Sicherungskopien. Kontaktieren Sie feedback@schotte.me, wenn Sie Hilfe benötigen. Diagnoseberichte können außerdem über von Ihnen gewählte Wege geteilt werden; eine direkte Übermittlung an PostHog setzt aktivierte Telemetrie voraus. Prüfen Sie Inhalt und Empfänger vor dem Teilen. Angaben zu Aufbewahrung, Auftragsverarbeitung, Speicherorten und Drittlandtransfers müssen anhand der aktuellen Dienstkonfiguration und Vereinbarungen bestätigt werden.

## 7. Betroffenenrechte

Je nach anwendbarem Recht können Sie Rechte auf Auskunft, Berichtigung, Löschung, Datenübertragbarkeit, Einschränkung oder Widerspruch sowie den Widerruf einer Einwilligung haben. Ein Widerruf macht bereits erfolgte Verarbeitung nicht rückgängig. Sie können sich außerdem bei einer zuständigen Aufsichtsbehörde beschweren. Wenden Sie sich mit einem Anliegen an feedback@schotte.me.

Viele Datensätze können Sie in der App bearbeiten oder löschen und Daten exportieren. Das lokale Zurücksetzen entfernt viele App-Daten, Einstellungen und Anbieterschlüssel, garantiert aber nicht die Entfernung jedes Anhangs, Caches oder jeder Konfiguration. Es löscht keine Kopien in Backups, Exporten, Apple Health, Health Connect oder externen KI-Diensten. Verwalten Sie diese Kopien gesondert und wenden Sie sich gegebenenfalls an den jeweiligen Anbieter. Die Telemetrie-Löschfunktion versucht eine Anfrage, bestätigt aber keine entfernte Löschung.
