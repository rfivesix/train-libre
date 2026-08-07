# Informativa sulla privacy per l'applicazione mobile «Train Libre» e il sito web

**Versione 1.7**  
**Aggiornato al: 7 agosto 2026**

Questa informativa sulla privacy vi informa, ai sensi degli articoli 13 e 14 del Regolamento generale sulla protezione dei dati (GDPR), sul trattamento dei dati personali e dei dati relativi alla salute nell'applicazione mobile "Train Libre" e durante la visita a questo sito web.

Poiché Train Libre è progettato come un'applicazione locale ("Local-First"), il controllo totale dei dati rimane direttamente a voi in ogni momento. Non gestiamo alcun database centrale o server applicativi per memorizzare i vostri profili, allenamenti o registri alimentari.

---

## 1. Titolare del trattamento

Il titolare del trattamento dei dati ai sensi dell'Articolo 4(7) del GDPR è lo sviluppatore e fornitore di servizi:

**Richard Georg Schotte**  
Bundesallee 114  
12161 Berlin  
Germania  

Email: feedback@schotte.me  
Telefono: (+49) 1520 6915571  

Trattandosi di uno sviluppatore indipendente e non sussistendo l'obbligo di nomina di un responsabile della protezione dei dati ai sensi dell'Articolo 37 del GDPR e § 38 del BDSG tedesco, non è stato nominato alcun DPO. Qualsiasi richiesta relativa alla protezione dei dati può essere inviata direttamente all'indirizzo email sopra indicato.

---

## 2. Filosofia fondamentale

Train Libre si basa sui principi di "privacy by design" e "privacy by default" (Articolo 25 del GDPR) e sul principio di minimizzazione dei dati (Articolo 5(1)(c) del GDPR).

* **Nessun account utente:** Non è richiesta alcuna registrazione. Nessun indirizzo email, password o credenziale viene memorizzato su server remoti.
* **Architettura Local-First:** Tutti i dati di profilo, allenamenti, pasti, misurazioni e parametri vitali sono memorizzati esclusivamente in un database SQLite locale sul dispositivo.
* **Nessun server centrale:** Non gestiamo cloud per raccogliere o elaborare le tue informazioni giornaliere. I tuoi dati rimangono in tuo possesso fisico.
* **Nessun tracciamento commerciale (Statistiche d'uso pseudonimizzate opzionali):** Train Libre rinuncia a reti pubblicitarie, tracciamento commerciale e profilazione comportamentale. È disponibile una rilevazione d'uso puramente opzionale (PostHog EU), disattivata di default, che prima del vostro consenso non stabilisce alcuna connessione e non trasmette né i vostri nomi e contenuti né misure corporee o valori nutrizionali. Per i dettagli si veda il punto 6 C.
* **Hosting web & Cookie (Visita del sito):** Quando accedi a questo sito, il tuo browser si connette ai server del nostro provider di hosting (GitHub Pages / GitHub Inc., 88 Colin P. Kelly Jr St, San Francisco, CA 94107, USA) per motivi tecnici. Vengono registrati log tecnici standard (IP, user-agent, timestamp) per fornire la pagina, sulla base del nostro legittimo interesse (Art. 6(1)(f) GDPR). Questo sito non utilizza cookie o script di tracciamento.

---

## 3. Dati elaborati localmente

L'uso dell'applicazione comporta l'elaborazione dei dati nel database SQLite locale (tramite Drift/sqflite). Questa archiviazione è necessaria per il funzionamento dell'app.

### A. Categorie di dati elaborati
1. **Profilo e obiettivi:** Nome utente, data di nascita, altezza, genere e obiettivi giornalieri personalizzati (calorie, macro, acqua, passi).
2. **Attività e allenamenti:** Piani di allenamento (routine), schede, carichi, ripetizioni, tempi di recupero, attività cardiovascolari (distanza, durata, calorie).
3. **Nutrizione e idratazione:** Alimenti consumati, quantità, tipo di pasto e log dell'acqua.
4. **Catalogo alimenti:** Prodotti creati dall'utente con codice a barre, marca e valori nutrizionali per 100g.
5. **Integratori:** Integratori configurati e storico delle assunzioni giornaliere.
6. **Misurazioni corporee:** Storico del peso corporeo e delle varie circonferenze.
7. **Frequenza cardiaca:** Aggregazioni orarie calcolate localmente sul dispositivo.
8. **Analisi del sonno:** Fasi del sonno, efficienza e regolarità importate dalle interfacce di sistema.
9. **Passi giornalieri:** Passi importati dal sistema con rimozione locale dei duplicati.

### B. Base giuridica del trattamento
* **Dati generali (Art. 6(1)(b) del GDPR):** Elaborazione necessaria per l'esecuzione del rapporto d'uso (fornitura delle funzionalità dell'applicazione).
* **Dati sanitari (Art. 9(2)(a) del GDPR in combinato disposto con l'Art. 6(1)(a) del GDPR):** Inserendo i parametri fisici o consentendo l'importazione dei dati sanitari (sonno, battito), l'utente esprime il proprio consenso esplicito. È possibile revocare il consenso in qualsiasi momento eliminando le voci o reimpostando l'app.

---

## 4. Integrazioni di terze parti / BYOK

Per fornire funzionalità avanzate, l'app dispone di interfacce verso servizi esterni. Queste funzioni sono opzionali.

### A. Riconoscimento pasti tramite IA (BYOK)
L'app offre la possibilità di analizzare i pasti tramite foto o testo fornendo la propria chiave API (BYOK) di un fornitore supportato.

* **Fornitori supportati:** OpenAI, Google Gemini, Anthropic Claude, Mistral AI, xAI Grok, Ollama.
* **Archiviazione sicura:** La chiave API viene salvata cifrata con AES-256 tramite `flutter_secure_storage` nel portachiavi sicuro del dispositivo (iOS Keychain o Android Keystore) e non viene mai trasmessa a noi.
* **Trasmissione limitata:** L'immagine o il testo vengono inviati tramite connessione HTTPS protetta direttamente all'API del fornitore scelto, senza metadati personali.
* **Elaborazione analitica:** L'IA viene usata esclusivamente per identificare i componenti del pasto e stimare i grammi. Train Libre non genera piani nutrizionali o ricette tramite l'IA.
* **Protezione tramite prompt di sistema:** Il prompt indica all'IA di non calcolare i nutrienti. La corrispondenza degli alimenti avviene offline sul dispositivo per calcolare i macro tramite database locale.
* **Algoritmo locale:** I calcoli di calorie e macro rimangono 100% locali sul tuo dispositivo e non vengono usati per addestrare i modelli globali.
* **Responsabilità:** L'uso della chiave implica un rapporto diretto con il fornitore dell'IA. Si invita a consultare la loro informativa sulla privacy.

| Fornitore | Informativa sulla privacy |
| :--- | :--- |
| OpenAI | https://openai.com/policies/privacy-policy |
| Google Gemini | https://policies.google.com/privacy |
| Anthropic Claude | https://www.anthropic.com/privacy |
| Mistral AI | https://mistral.ai/privacy-policy |
| xAI Grok | https://x.ai/privacy-policy |
| Ollama | https://ollama.com/privacy |

### B. Aggiornamento dei cataloghi offline
* **Funzionamento:** L'app controlla periodicamente la presenza di aggiornamenti dei cataloghi tramite HTTPS verso i server di hosting.
* **Minimizzazione:** Vengono trasmessi solo i dati tecnici di connessione (IP, timestamp, user-agent) necessari per il download.
* **Ricerca offline:** La ricerca di prodotti e la scansione dei codici a barre avvengono al 100% offline.

---

## 5. Interfacce dati sanitari del sistema

Train Libre può interagire con i database sanitari di sistema (Apple HealthKit o Google Health Connect). L'interazione avviene offline e richiede il tuo consenso esplicito.

---

## 6. Sicurezza dei dati, backup e telemetria

Poiché tutti i dati risiedono sul dispositivo, la sicurezza fisica e logica dello stesso è fondamentale.

### A. Isolamento dei dati
Il sistema operativo isola l'applicazione in una sandbox, impedendo ad altre app installate di accedere al database SQLite o alle chiavi API.

### B. Backup manuali e automatici
1. **Esportazione file:** Backup JSON completo condivisibile tramite il menu di condivisione di sistema.
2. **Cifratura:** I backup possono essere crittografati localmente con password.
3. **Backup automatici:** Su Android tramite Storage Access Framework (SAF).
4. **Backup di sistema:** Inclusi nei backup cloud del sistema operativo (iCloud / Google Drive) se attivi.
5. **Backup iCloud (solo iOS):** Opzionale, gestito dall'ID Apple dell'utente.

### C. Statistiche d'uso pseudonimizzate opzionali

Train Libre offre una rilevazione d'uso puramente opzionale e rispettosa della privacy, finalizzata a migliorare la stabilità dell'app e l'utilizzo delle funzionalità, gestita tramite PostHog EU (https://eu.i.posthog.com). Nell'app la funzione è denominata «Condividi statistiche d'uso anonime». Poiché PostHog associa identificativi tecnici agli eventi trasmessi, si tratta giuridicamente di dati pseudonimizzati; per i dati tecnici di utilizzo non è possibile garantire un anonimato completo.

1. **Opt-in rigoroso per impostazione predefinita:** La telemetria è completamente disattivata per impostazione predefinita. Finché non prestate espressamente il consenso, la libreria di telemetria non viene nemmeno inizializzata. Non viene trasmesso alcun evento e non viene stabilita alcuna connessione di rete verso PostHog — nemmeno una richiesta tecnica di configurazione. Soltanto quando attivate «Condividi statistiche d'uso anonime» nelle Impostazioni, alla voce Supporto e Info, l'app contatta PostHog per la prima volta. Un identificativo casuale del dispositivo viene sì generato localmente già al primo avvio, affinché il conteggio dei dispositivi attivi funzioni a partire dal vostro consenso; tale generazione avviene esclusivamente sul vostro dispositivo e senza alcuna trasmissione.
2. **Ambito degli eventi rilevati:** Se avete prestato il consenso, vengono rilevate esclusivamente le seguenti categorie:

   - Avvii dell'app (per determinare il numero di dispositivi attivi)
   - Schermate aperte, identificate esclusivamente tramite identificativi tecnici tratti da un elenco fissato nel codice sorgente (ad esempio diary_tab, live_workout)
   - Funzioni attivate, parimenti tramite identificativi fissi (ad esempio routine_created, barcode_scanned)
   - Un contatore aggregato delle voci alimentari registrate (il numero nonché la modalità di inserimento, ad esempio ricerca, scansione del codice a barre o riconoscimento tramite IA)
   - Indicatori delle sessioni di allenamento concluse: numero di esercizi, serie e timer di recupero, durata in minuti nonché indicazioni sì/no sulle funzioni di allenamento utilizzate. Il tipo di sessione viene trasmesso esclusivamente come «routine» o «custom», mai come nome
   - Progressione nell'onboarding (numero del passaggio, denominazione del passaggio, tempo di permanenza)
   - Impostazioni modificate (identificativo dell'impostazione e nuovo valore)
   - Stato delle richieste IA per il riconoscimento dei pasti (fornitore selezionato, esito positivo o codice di errore, tempo di risposta in intervalli ampi quali «2-5s»)
   - Stato delle migrazioni del database (versione di partenza e di destinazione, esito)
   - Indicatori della stima calorica adattiva: numero di voci di peso e alimentazione considerate, ampiezza della finestra di osservazione, livello di confidenza e indicatori di qualità — ma nessun valore di peso, calorico o di obiettivo
   - Dati tecnici di contesto: versione dell'app, build, sistema operativo e relativa versione, piattaforma, fuso orario nonché un'indicazione sul fatto che l'app sia eseguita in un emulatore

   Contatori quali il numero di esercizi o di serie e la durata dell'allenamento vengono trasmessi come valori numerici esatti e non come intervalli. Tali valori vengono trasmessi senza nome, indirizzo e-mail o identificativo del dispositivo del produttore. L'identificazione di singoli utenti non è né intenzionale né tecnicamente prevista.

3. **Nessun contenuto e nessun valore sanitario:** Non vengono raccolti nomi, indirizzi e-mail, identificativi di account o identificativi del dispositivo del produttore, né alcun contenuto da voi inserito — in particolare nessun titolo di scheda di allenamento, nome di esercizio o di alimento, nome di ricetta, nota o testo libero. Parimenti non vengono trasmessi misure corporee, pesi, valori calorici o nutrizionali. Tutti gli eventi vengono inviati con $ip: 0.0.0.0; gli indirizzi IP non vengono memorizzati come dati dell'evento e la risoluzione della posizione basata sull'IP è espressamente disattivata mediante $geoip_disable.
4. **Paese e lingua:** Per analizzare la diffusione geografica dell'app vengono trasmessi il vostro paese, il vostro continente e la vostra impostazione di lingua (ad esempio «DE», «Europa», «de_DE»). Tali indicazioni vengono derivate sul vostro dispositivo dalle impostazioni di sistema e non dal vostro indirizzo IP. Non avviene alcuna risoluzione a livello di città, regione, codice postale o coordinate; essa è disattivata lato server.
5. **Rapporto diagnostico volontario:** Nella sezione Feedback potete inviare attivamente un rapporto diagnostico allo sviluppatore. Prima dell'invio il rapporto vi viene mostrato integralmente in un'anteprima e selezionate singolarmente le sezioni da includere. Se lo trasmettete via e-mail, tramite il menu di condivisione, gli appunti o l'esportazione su file, esso giunge direttamente allo sviluppatore sotto il vostro controllo e non tramite PostHog. Per l'invio diretto a PostHog offerto in aggiunta vale invariato il punto 3: la vostra nota in testo libero, il vostro peso corporeo nonché i vostri valori calorici e di macronutrienti non vengono trasmessi, bensì esclusivamente indicatori tecnici quali il numero di voci, i livelli di confidenza, gli indicatori di qualità e lo stato dei vostri backup. L'invio diretto presuppone un consenso attivo ai sensi del punto 1; se le statistiche d'uso sono disattivate, l'app ve lo segnala anziché comunicare un invio.
6. **Revoca e cancellazione:** Potete revocare il consenso in qualsiasi momento nelle Impostazioni, interrompendo immediatamente ogni trasmissione. Tramite il pulsante «Elimina dati di telemetria» nelle Impostazioni potete inoltre richiedere la cancellazione presso PostHog dei dati collegati al vostro identificativo di telemetria; contestualmente vengono reimpostati tutti gli identificativi memorizzati localmente. La cancellazione può essere soggetta a eccezioni di natura tecnica, ad esempio per le copie di backup. In alternativa è sufficiente una semplice e-mail a feedback@schotte.me.
7. **Base giuridica:** Il trattamento dei dati di telemetria avviene esclusivamente sulla base del vostro consenso esplicito ai sensi dell'art. 6, par. 1, lett. a) GDPR.
8. **Responsabile del trattamento:** PostHog, Inc. (2261 Market St., #4008, San Francisco, CA 94114, USA) opera quale responsabile del trattamento ai sensi dell'art. 28 GDPR. È stato stipulato un accordo sul trattamento dei dati (Data Processing Agreement, DPA).
9. **Luogo di conservazione, durata e trasferimenti verso paesi terzi:** Il progetto PostHog EU utilizzato impiega quale infrastruttura di hosting primaria server situati a Francoforte sul Meno, Germania (AWS eu-central-1). I dati di telemetria vengono cancellati automaticamente dopo un massimo di 12 mesi. A seconda dei processi di supporto, sicurezza e sub-responsabilità del trattamento, accessi o trattamenti possono avvenire anche al di fuori dell'UE. Per tali trasferimenti valgono le garanzie adeguate concordate nell'accordo sul trattamento dei dati, integrate dalla certificazione ai sensi dell'EU-US Data Privacy Framework (DPF).
10. **Trasparenza completa:** Il catalogo completo di tutti gli eventi e delle caratteristiche trasmesse per ciascuno di essi è consultabile pubblicamente nel repository del codice sorgente, nel file TELEMETRY.md. Le build F-Droid e offline vengono compilate senza la libreria di telemetria e non ne contengono il codice.

---

## 7. Diritti dell'interessato (GDPR)

* **Accesso e portabilità (Art. 15 & 20 del GDPR):** Esportazione JSON completa del database.
* **Rettifica (Art. 16 del GDPR):** Modifica diretta nell'applicazione.
* **Cancellazione (Art. 17 del GDPR):** Eliminazione manuale dei singoli log.
* **Cancellazione totale (AppData Reset):** Ripristino allo stato di fabbrica cancellando dati locali, impostazioni e chiavi API.
* **Diritti sui dati di telemetria:** Se hai acconsentito alla telemetria anonima, puoi esercitare i tuoi diritti (accesso, cancellazione, opposizione) relativi ai dati di telemetria trattati contattando il titolare del trattamento all'indirizzo feedback@schotte.me. Su richiesta, tutti i tuoi eventi di telemetria verranno cancellati dai server di PostHog.
* **Reclamo (Art. 77 del GDPR):** Diritto di proporre reclamo al Garante per la protezione dei dati personali o autorità competente.
