---
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


---
# Privacy Policy for the App "Train Libre"

**Version:** 1.8  
**As of:** October 8, 2026  

This privacy policy informs you in accordance with Articles 13 and 14 of the General Data Protection Regulation (GDPR) about the processing of personal data and health-related data in the mobile application "Train Libre". 

Train Libre is designed as a local-first application; optional features can transmit data or create copies outside your device. We do not operate any central database or application servers to store your profiles, workouts, or nutrition logs.

---

## 1. Controller

The controller for data processing within the meaning of Article 4(7) of the GDPR is the developer and service provider:

Richard Georg Schotte  
Bundesallee 114  
12161 Berlin  
Germany  

Email: feedback@schotte.me  
Phone: (+49) 1520 6915571  

Since the controller is an individual developer and the statutory requirements for the mandatory appointment of a data protection officer pursuant to Article 37 of the GDPR and Section 38 of the German Federal Data Protection Act (BDSG) are not met, no separate data protection officer has been appointed. All data protection-related inquiries can be directed directly to the email address provided above.

---

## 2. Core Philosophy

Train Libre is based on the principles of "privacy by design" and "privacy by default" (Article 25 of the GDPR) as well as the principle of data minimization (Article 5(1)(c) of the GDPR).

* **No User Accounts:** No registration or creation of a user account is required to use the app. No email addresses, passwords, or login credentials are stored on external servers.
* **Local-First Architecture:** Profile settings, activities, nutrition data, vital signs, and measurements are primarily stored in a local database on your device. Optional features can transmit or copy data as described below.
* **No Central Backend Server:** We do not operate any cloud databases or application servers to store or process your training and nutrition data. Optional services and backups can receive or store copies.
* **No Advertising:** Train Libre does not use advertising networks or behaviour-based advertising. Optional usage statistics are disabled by default. When enabled, events may include technical identifiers and measurements such as counts or indicators derived from nutrition and weight-related features; these can be personal or health-related even without your name. See section 6 C.

---

## 3. Locally Processed Data

By using the app, your mobile device's operating system processes data in a local SQLite database (Drift/sqflite). This storage is necessary for the operation of the app and to fulfill its core functions.

### A. Categories of Processed Data

The local database includes the following data categories:

1. **Profile Settings and Goals:** Username, date of birth, body height, gender, profile picture file path, and individually defined daily goals (target calories, target protein, target carbohydrates, target fat, target water, target steps).
2. **Training and Activity Logs (Workouts):** Training plans (routines), exercise templates, historical workout logs (start and end times, notes, exercise sets with rep and weight values, RPE and RIR values, rest times, cardiovascular activities including distance, duration, and calories burned).
3. **Nutrition and Fluid Logs (Nutrition & Fluids):** Consumed food items (timestamp, amount in grams/milliliters, meal type), water and beverage logs (amount, nutrient content, caffeine content).
4. **Food and Product Catalog (User-Products):** Products individually created by the user, including barcode, product name, brand, and macro/micronutrient information per 100g/ml (calories, protein, carbohydrates, fat, sugar, dietary fiber, salt, caffeine, list of ingredients, and additives).
5. **Supplements:** Set up supplements (name, default dose, unit, daily goal, and daily limit) as well as historical supplement log entries with intake timestamp and amount.
6. **Body Dimensions and Measurements (Measurements):** Historical measurement values for body weight and various body circumferences (e.g., chest, waist) including date and unit.
7. **Heart Rate Data Aggregates:** Local hourly aggregations of heart rate (minimum, maximum, and average beats per minute, as well as sample count).
8. **Sleep Data Analyses:** Processed sleep data including sleep phases (deep sleep, REM, light sleep, waking phases), sleep efficiency, resting heart rate, sleep interruptions, sleep regularity, as well as historical raw data imports from system interfaces.
9. **Local Step Segments:** Step counts imported from system interfaces with precise start and end times as well as data source identifiers for local duplicate cleaning.

### B. Legal Basis for Processing

Core app storage is generally local to your device, while optional services can transmit or store copies as described in this policy. The legal basis depends on the purpose and context of each processing activity. Insofar as the app is considered within the scope of the GDPR, the following legal bases may apply:

* **General Data and Settings (Article 6(1)(b) of the GDPR):** The processing of general profile settings, training plans, and app preferences is carried out to fulfill the user relationship (provision of app functionalities).
* **Health Data (Article 9(2)(a) of the GDPR in conjunction with Article 6(1)(a) of the GDPR):** Some processing of health-related data may rely on your explicit consent. Entering a record or enabling an import is not, by itself, consent to every later purpose, such as transmission in an AI request. Where processing relies on consent, you may withdraw it for the future by contacting feedback@schotte.me or using the relevant platform permission controls. Deleting records or resetting the app does not automatically withdraw consent and does not undo processing that has already taken place.

---

## 4. Third-Party Integrations / BYOK

To provide advanced features, the app has interfaces to external services. These functions are optional and require your active participation.

### A. Artificial Intelligence: Chat, Meal Recognition and Drafts

Train Libre offers optional AI chat and meal recognition. The assistant can answer questions and prepare drafts such as meals, routines, training plans and recipes. Meal recognition can estimate portions and nutrition directly, or match suggested foods against a local catalog. Estimates and suggestions can be wrong and require your judgment.

**Your submitted content.** When you send a chat message, the text you type or dictate and the images you attach are sent to the model selected for the request. This happens before the separate request to read stored app records. Your message or image can itself contain personal or health information. The request can include system instructions, relevant documentation, the model identifier, limited earlier conversation context and images from the conversation. Follow-up context can include an earlier user question, categories and dates previously requested, or the name of a pending draft. An earlier data-backed answer is withheld until fresh overlapping access is approved and the provider matches. Not every request contains stored records, and entering a message is different from granting access to those records.

Dictation uses the device's speech-recognition service, which may use a network service depending on the device and settings. In meal dictation, an optional AI transcript-cleanup feature can send the transcript for processing before the meal is submitted; it can be disabled. Meal analysis sends the submitted description or photos, together with instructions and context needed for the analysis, to the model used for that feature.

**Access to existing app records.** The assistant can request categories including workouts, diary and nutrition, steps, sleep, recovery, measurements, goals, profile and daily targets, supplements, recipes, exercise catalog, routines and training plans. A request identifies categories and a period or current snapshot. Fresh reads of those records are gated by approval of the request; the app may request further categories separately. The assistant can query an approved local snapshot and send query results and related tool exchanges to the model. Approval does not mean that every record in a category is necessarily sent. The request card describes categories and period; it is not a complete preview of each value sent.

Automatic approval of data requests is off by default. If you enable it in the assistant, later requests, including additional categories, can be approved without a separate decision each time. Turn it off in the assistant to return to individual requests. Turning it off does not recall data already sent or necessarily stop work already in progress. Earlier conversation context, draft metadata, responses, retries and tool exchanges can still contain information from prior interactions.

**Recipient and configuration.** AI settings show the configured provider and model, and the assistant can display model information. The data-access card does not itself identify the recipient. Approval is not bound to a specific recipient: for text chat, the app can fall back to another configured provider when the selected one is unavailable or lacks credentials, and it resolves the provider again after approval. Changing configuration can therefore result in a different recipient. Image-bearing chat uses a separate selected-provider check instead of that implicit credential fallback. Requests may also retry with another model at the same provider.

Supported configurations include Apple Foundation Models on compatible devices, OpenAI, Google Gemini, Anthropic, Mistral, xAI, DeepSeek, Ollama and custom OpenAI-compatible endpoints. Apple Foundation Models are intended for on-device processing. Ollama normally connects to a local service; a custom endpoint may be local or remote and may forward data elsewhere. A local or self-hosted server is controlled by its operator, not verified by Train Libre. Network protection depends on the endpoint; a local HTTP connection is possible. API keys and AI configuration are stored using platform secure-storage facilities; credentials are used to authenticate with the configured service.

Train Libre cannot verify an external provider's or server operator's retention, human review, training, onward transfers or deletion practices. Review the applicable API terms and account settings before sending sensitive information. Provider and hosting locations, international transfers and safeguards depend on the service and configuration; do not assume a particular transfer mechanism applies. Train Libre does not operate a central service to receive these AI requests: the app communicates with the selected service or endpoint, or invokes the on-device model.

**History and deletion.** Chat messages, responses, errors, provider and model identifiers, access records and attachment references are stored locally; attachments can also be stored as files. Deleting a conversation attempts to remove its attachments. Local reset removes many records and provider keys, but does not establish that every attachment, cache or configuration item has been removed. Backups, exports, health-platform copies and information already sent to a provider are separate. Deleting local history does not request deletion from an AI provider. Contact the provider or server operator about its copies.

### B. Offline Catalog Updates (Open Food Facts & Exercise Catalog)

To scan food barcodes offline and look up exercises, Train Libre uses local product and exercise catalogs. These catalogs are downloaded directly to your device as precompiled SQLite database files.

* **How it Works:** The app checks at regular intervals whether updates are available for the food catalog (based on Open Food Facts) or the exercise catalog (based on wger/GitHub). The check and subsequent download of the compressed catalog databases are performed via an encrypted HTTPS connection directly to the servers of the hosting service provider (e.g., GitHub Pages / GitHub Inc. or Open Food Facts).
* **BLS catalog:** The BLS 4.0 base-food catalog from the Max Rubner-Institut is also downloaded from GitHub; it contains ingredients and nutrient values and is stored locally.
* **Data Minimization:** When downloading catalog updates, technical connection data (in particular your IP address, date/time of access, and the app's User-Agent) are transmitted to the host as a system requirement. No user-generated data, scanned barcodes, or personal profile characteristics are sent to the catalog hosts at any time.
* **Local Barcode Mapping:** The matching of a scanned barcode or the search for food and exercises takes place 100 percent offline on your device. Unlike conventional nutrition apps, scanning a product does not send a request with the barcode to a cloud server.

---

## 5. Health Data Interfaces

Train Libre can interact with Apple HealthKit or Google Health Connect when you enable the relevant features and grant the platform permissions. You can change these permissions in system settings. Imported data is stored and analyzed in the app, and may also be included in backups or in an AI request under the access rules in section 4. Changing system permissions does not automatically delete previously imported or exported records. App-data access approval for the assistant is separate from health-platform permission.

### A. Data Import (Reading)

If you grant permission to the app, Train Libre reads data from Apple HealthKit or Google Health Connect to display and process it locally within the app:
* **Body Measurements:** Import of weight, body-fat percentage, and waist circumference (from smart scales or external tracking apps) for accurate tracking trends and adaptive TDEE calibration.
* **Step Counts:** Import of recorded step count segments for offline evaluation.
* **Sleep Data:** Import of sleep intervals and sleep phases.
* **Heart Rate:** Import of heart rate samples to calculate local hourly aggregations.

Imported data may also be included in backups or shared through optional AI features as described above.

### B. Data Export (Writing & Idempotency)

At your request, Train Libre can export data manually recorded in the app to the system health databases (Apple HealthKit / Google Health Connect):
* **Body Dimensions:** Export of weight measurements.
* **Nutrition and Hydration:** Export of consumed nutritional values, calories, and water amounts.
* **Workouts:** Export of completed training sessions.

* **Local Idempotency Protection:** To prevent duplicate data from being written to your system health database during repeated synchronizations, Train Libre features a local logging system. In the `health_export_records` table of the local SQLite database, a unique ID, the target platform (Apple Health or Health Connect), the data domain, and a unique idempotency key are stored together with the export timestamp for every successful write operation. This comparison takes place purely locally on your device and serves to ensure data consistency.

---

## 6. Data Security & Backups

Device security is important to protecting your local data and credentials.

### A. Local Data Isolation

The operating system (iOS/Android) isolates Train Libre's app data using sandbox mechanisms. Other installed applications do not have access to the local SQLite database or the API keys stored in the secured app settings without your consent.

### B. Manual and Automatic Backups

You can create and share backups or exports, and can enable automatic backups to a selected location. Depending on the option, backups can include database records, settings, AI history and media. Password-encrypted export is available; protect passwords and unencrypted copies. The selected location or operating system may store a copy in a cloud service. Optional iCloud sync can upload a database snapshot and media after it is enabled in the app. Review the settings and practices of the storage provider. Resetting the app does not remove separately stored backups, exports, health-platform data or provider copies. Temporary files and failed cleanup may leave additional copies; do not assume every copy is erased immediately.

### C. Optional Pseudonymised Usage Statistics

Usage statistics are disabled by default. When enabled, the app uses the PostHog EU ingestion endpoint for pseudonymous events. Events can include technical identifiers, app and device context, screen and feature use, exact workout counts and duration, food-entry counts, AI request status, and indicators derived from nutrition or weight-related features. These events can be personal or health-related even without your name. The app configures IP and geographic-processing controls, but network and server handling depend on the service configuration.

You can turn off future telemetry in Settings. The deletion control resets local identifiers and counters and attempts a deletion request; it does not confirm server-side deletion, and historical identifiers or backups may not be covered. Contact feedback@schotte.me for help. A diagnostic report can also be shared by methods you choose; direct PostHog submission requires telemetry to be enabled. Review the report and its destination before sharing. Details of retention, processor arrangements, locations and international-transfer safeguards require confirmation with the service operator and applicable agreements.

---

## 7. Data Subject Rights

Depending on applicable law, you may have rights of access, rectification, erasure, portability, restriction or objection, and the right to withdraw consent where processing is based on consent. Withdrawal does not undo processing that has already occurred. You may also complain to a competent supervisory authority. Contact feedback@schotte.me with a request.

You can edit or delete many records in the app and export data. The local reset removes many app records, settings and provider keys, but does not guarantee removal of every attachment, cache or configuration item. It does not remove copies in backups, exports, Apple Health, Health Connect or external AI services. Manage those copies separately and contact the provider where appropriate. The telemetry deletion action attempts a request; it does not confirm remote deletion.
