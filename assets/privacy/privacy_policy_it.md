# Informativa sulla privacy per l'applicazione mobile «Train Libre» e il sito web

**Versione 1.6**  
**Aggiornato al: 27 luglio 2026**

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
* **Nessun SDK di tracciamento o analisi (Telemetria anonima opzionale):** Train Libre rinuncia a reti pubblicitarie, tracciamento commerciale e profilazione comportamentale. Un'integrazione di statistiche d'uso puramente anonima (PostHog EU) è disattivata di default e non raccoglie alcuna informazione personale identificabile (PII) né contenuti personali di allenamento o alimentazione.
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

### C. Telemetria anonima opzionale
Train Libre include un'integrazione opzionale per metriche d'uso orientata alla privacy, gestita tramite PostHog EU (https://eu.i.posthog.com).

1. **Opt-In strettamente predefinito:** La telemetria è disattivata di default. Nessun dato o richiesta di rete viene trasmesso a meno che non si attivi esplicitamente l'opzione "Condividi statistiche d'uso anonime" nelle Impostazioni sotto Supporto e Info.
2. **Zero dati personali identificabili (Zero PII):** La telemetria non raccoglie alcun identificatore personale, nome, indirizzo e-mail, indirizzo IP, peso corporeo, ripetizioni o nomi di alimenti. Gli indirizzi IP vengono scartati immediatamente al momento dell'acquisizione.
3. **Intervalli aggregati approssimativi:** Le metriche degli eventi vengono raggruppate esclusivamente in intervalli approssimativi non identificabili (ad es. versione dell'app, piattaforma SO, intervalli di durata dell'allenamento come 15-30 min, numero di esercizi come 4-7, latenza richieste IA e stato migrazione database).
4. **Revoca immediata:** Puoi revocare il consenso e disattivare la telemetria in qualsiasi momento nelle Impostazioni, interrompendo immediatamente ogni trasmissione.
5. **Base giuridica:** Il trattamento dei dati di telemetria si basa esclusivamente sul tuo consenso esplicito ai sensi dell'Articolo 6(1)(a) del GDPR.
6. **Responsabile del trattamento:** PostHog, Inc. (2261 Market St., #4008, San Francisco, CA 94114, USA) agisce in qualità di responsabile del trattamento ai sensi dell'Articolo 28 del GDPR. È stato stipulato un accordo sul trattamento dei dati (DPA).
7. **Luogo di conservazione, durata e garanzie sui trasferimenti:** I dati di telemetria sono conservati esclusivamente su infrastrutture nell'UE (AWS eu-central-1, Francoforte, Germania) per un massimo di 12 mesi, trascorsi i quali vengono cancellati automaticamente. Sebbene l'archiviazione principale rimanga nell'UE, eventuali accessi di supporto tecnico da parte di PostHog, Inc. avvengono sotto le garanzie del EU-US Data Privacy Framework (DPF).

---

## 7. Diritti dell'interessato (GDPR)

* **Accesso e portabilità (Art. 15 & 20 del GDPR):** Esportazione JSON completa del database.
* **Rettifica (Art. 16 del GDPR):** Modifica diretta nell'applicazione.
* **Cancellazione (Art. 17 del GDPR):** Eliminazione manuale dei singoli log.
* **Cancellazione totale (AppData Reset):** Ripristino allo stato di fabbrica cancellando dati locali, impostazioni e chiavi API.
* **Diritti sui dati di telemetria:** Se hai acconsentito alla telemetria anonima, puoi esercitare i tuoi diritti (accesso, cancellazione, opposizione) relativi ai dati di telemetria trattati contattando il titolare del trattamento all'indirizzo feedback@schotte.me. Su richiesta, tutti i tuoi eventi di telemetria verranno cancellati dai server di PostHog.
* **Reclamo (Art. 77 del GDPR):** Diritto di proporre reclamo al Garante per la protezione dei dati personali o autorità competente.
