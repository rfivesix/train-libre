# Informativa sulla privacy per l'applicazione mobile «Train Libre» e il sito web

**Versione 1.8**  
**Aggiornato al: 8 ottobre 2026**

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
* **Architettura Local-First:** I dati di profilo, allenamento, nutrizione, salute e misurazione sono archiviati principalmente sul dispositivo. Le funzioni opzionali possono trasmettere dati o creare copie esterne, come descritto di seguito.
* **Nessun server centrale:** Non gestiamo un database cloud centrale per archiviare i registri di allenamento e nutrizione. Servizi opzionali e backup possono tuttavia ricevere o conservare copie.
* **Nessuna pubblicità:** Train Libre non usa reti pubblicitarie né pubblicità comportamentale. Le statistiche opzionali sono disattivate per impostazione predefinita. Quando attive, gli eventi possono includere identificativi tecnici e indicatori derivati da funzioni legate a nutrizione o peso; anche senza nome possono essere dati personali o relativi alla salute. Vedi il punto 6 C.
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

La base giuridica dipende dalla funzione e dalla finalità del trattamento. Alcuni trattamenti si basano sul consenso, che può essere revocato per il futuro. Eliminare singoli record o ripristinare l’app non equivale automaticamente alla revoca e non annulla i trattamenti già effettuati. Le trasmissioni opzionali sono descritte nelle sezioni pertinenti. La valutazione giuridica specifica va verificata in base alla configurazione effettiva.

---

## 4. Integrazioni di terze parti / BYOK

Per fornire funzionalità avanzate, l'app dispone di interfacce verso servizi esterni. Queste funzioni sono opzionali.

### A. Intelligenza artificiale: chat, riconoscimento dei pasti e bozze

Train Libre offre funzioni IA opzionali per chat, riconoscimento dei pasti e preparazione di bozze, come pasti, routine, piani di allenamento e ricette. Stime e suggerimenti possono essere incompleti o errati.

**Contenuti inviati dall’utente.** Quando invii un messaggio, il testo digitato o dettato e le immagini allegate vengono trasmessi al modello usato per quella richiesta, prima di un’eventuale richiesta separata di accesso ai dati salvati nell’app. Il messaggio o l’immagine possono già contenere dati personali o relativi alla salute. La richiesta può includere un contesto limitato delle conversazioni precedenti, istruzioni, l’identificativo del modello e contenuti precedenti. Non tutte le richieste includono dati salvati nell’app: inviare un messaggio è diverso dall’autorizzare l’accesso a tali dati. La dettatura può usare un servizio di riconoscimento vocale in base al dispositivo e alle impostazioni. La pulizia facoltativa della trascrizione di un pasto può trasmettere il testo prima dell’invio del pasto.

**Dati già salvati nell’app.** L’assistente può richiedere categorie come allenamenti, diario alimentare, passi, sonno, recupero, misurazioni, obiettivi, profilo, integratori, ricette, esercizi, routine e piani. I nuovi accessi sono soggetti a una richiesta di approvazione. L’approvazione automatica è disattivata per impostazione predefinita; se attivata, richieste successive possono essere approvate senza una nuova decisione. La scheda indica categorie e periodo, ma non mostra necessariamente ogni valore trasmesso. Risultati di query locali e relativi scambi con gli strumenti possono essere inviati al modello. Disattivare l’approvazione automatica non richiama dati già inviati e non interrompe necessariamente operazioni in corso.

**Destinatario.** L’approvazione non è legata a uno specifico fornitore. Nella chat testuale l’app può passare a un altro fornitore configurato se quello selezionato non è disponibile o non dispone delle credenziali, e risolve nuovamente il fornitore dopo l’approvazione. Potrebbe quindi essere usato un destinatario diverso; la scheda di approvazione non mostra da sola il destinatario. Le configurazioni supportate includono Apple Foundation Models, OpenAI, Google, Anthropic, Mistral, xAI, DeepSeek, Ollama e endpoint personalizzati compatibili con OpenAI. Un endpoint personalizzato può essere locale o remoto e inoltrare i dati altrove. Train Libre non può verificare le pratiche esterne di conservazione, revisione umana, addestramento, trasferimento o cancellazione. Controlla i termini API o quelli dell’operatore interessato.

**Cronologia e cancellazione.** Messaggi, risposte, errori, identificativi di fornitore e modello, registrazioni delle approvazioni e riferimenti agli allegati possono essere salvati localmente; gli allegati possono essere file separati. Eliminare una conversazione tenta di rimuovere i relativi allegati. Il ripristino elimina molti dati e chiavi, ma non garantisce la rimozione di ogni file, cache o impostazione. Backup, esportazioni, piattaforme sanitarie e dati già inviati a un fornitore sono separati. Eliminare la cronologia locale non richiede la cancellazione al fornitore IA.

### B. Aggiornamento dei cataloghi offline
* **Funzionamento:** L'app controlla periodicamente la presenza di aggiornamenti dei cataloghi tramite HTTPS verso i server di hosting.
* **Catalogo BLS:** Il catalogo alimentare BLS 4.0 del Max Rubner-Institut viene scaricato da GitHub e conservato localmente.
* **Minimizzazione:** Vengono trasmessi solo i dati tecnici di connessione (IP, timestamp, user-agent) necessari per il download.
* **Ricerca offline:** La ricerca di prodotti e la scansione dei codici a barre avvengono al 100% offline.

---

## 5. Interfacce con i dati sanitari

Train Libre può usare Apple HealthKit o Google Health Connect se attivi le funzioni pertinenti e concedi i permessi della piattaforma. Puoi modificare tali permessi nelle impostazioni di sistema. I dati importati vengono archiviati e analizzati nell’app e possono essere inclusi nei backup o in una richiesta IA secondo le regole di approvazione della sezione 4. Modificare i permessi di sistema non elimina automaticamente dati già importati o esportati. L’approvazione per l’accesso dell’assistente ai dati dell’app è distinta dal permesso della piattaforma Health.

## 6. Sicurezza dei dati, backup e telemetria

La sicurezza del dispositivo è importante per proteggere i dati locali e le credenziali.

### A. Isolamento dei dati
Il sistema operativo isola l'applicazione in una sandbox, impedendo ad altre app installate di accedere al database SQLite o alle chiavi API.

### B. Backup manuali e automatici

Puoi creare e condividere backup o esportazioni e attivare backup automatici in una posizione selezionata. A seconda dell’opzione, possono includere record del database, impostazioni, cronologia IA e file multimediali. È disponibile l’esportazione protetta da password; proteggi le password e le copie non cifrate. La posizione selezionata o il sistema operativo può archiviare una copia in un servizio cloud. Dopo l’attivazione, la sincronizzazione iCloud opzionale può caricare uno snapshot del database e file multimediali. Verifica impostazioni e pratiche del fornitore di archiviazione. Il ripristino dell’app non elimina backup, esportazioni, dati delle piattaforme sanitarie o copie presso fornitori salvate separatamente. File temporanei o una pulizia non riuscita possono lasciare altre copie; non è garantita la cancellazione immediata e completa.

### C. Statistiche d’uso facoltative

Le statistiche d’uso sono disattivate per impostazione predefinita. Quando sono attive, l’app usa l’endpoint di raccolta PostHog EU per eventi pseudonimi. Gli eventi possono includere identificativi tecnici, contesto dell’app e del dispositivo, uso di schermate e funzioni, conteggi esatti e durata degli allenamenti, conteggi degli inserimenti alimentari, stato delle richieste IA e indicatori derivati da funzioni relative a nutrizione o peso. Anche senza nome, questi eventi possono essere dati personali o relativi alla salute. L’app configura opzioni relative a IP e geolocalizzazione, ma il trattamento di rete e server dipende anche dalla configurazione del servizio.

Puoi disattivare la telemetria futura nelle Impostazioni. Il comando di cancellazione reimposta identificativi e contatori locali e tenta di inviare una richiesta di cancellazione; non conferma la cancellazione lato server e potrebbe non includere identificativi storici o backup. Per assistenza contatta feedback@schotte.me. Puoi inoltre condividere rapporti diagnostici con i metodi che scegli; l’invio diretto a PostHog richiede che la telemetria sia attiva. Controlla contenuto e destinatario prima della condivisione. Conservazione, accordi con responsabili, ubicazioni e trasferimenti internazionali devono essere confermati in base alla configurazione e agli accordi attuali del servizio.

## 7. Diritti dell’interessato (GDPR)

A seconda della legge applicabile, puoi avere diritti di accesso, rettifica, cancellazione, portabilità, limitazione o opposizione, nonché il diritto di revocare il consenso quando il trattamento si basa su di esso. La revoca non annulla i trattamenti già avvenuti. Puoi inoltre presentare un reclamo all’autorità di controllo competente. Per le richieste, contatta feedback@schotte.me.

Puoi modificare o cancellare molti dati nell’app ed esportarli. Il ripristino locale elimina molti dati dell’app, impostazioni e chiavi dei fornitori, ma non garantisce la rimozione di ogni allegato, cache o configurazione. Non elimina copie in backup, esportazioni, Apple Health, Health Connect o servizi IA esterni. Gestisci tali copie separatamente e contatta il fornitore se necessario. Il comando di cancellazione della telemetria tenta una richiesta, ma non conferma la cancellazione remota.
