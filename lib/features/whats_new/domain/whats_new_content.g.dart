// GENERATED FILE - DO NOT EDIT BY HAND.
//
// Source:    metadata/whats_new/<locale>.md
// Generator: script/build_whats_new.py
//
// Add a new release by editing the Markdown files, then run:
//   python3 script/build_whats_new.py --write --sync-store

import 'package:flutter_lucide/flutter_lucide.dart';

import 'whats_new_release.dart';

/// User-facing release notes per app language code.
///
/// Languages without their own translation fall back to [kWhatsNewFallbackLanguage].
const Map<String, List<WhatsNewRelease>> kWhatsNewContent = {
  'en': <WhatsNewRelease>[
    WhatsNewRelease(
      version: '1.2.0-beta.1',
      releasedOn: '2026-08-27',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'Photos for your workouts',
          body:
              'Capture your workout sessions with up to 4 photos. Take pictures directly with your camera or select them from your library – right in the workout summary or later in your workout history. All photos and previews are safely included in backups.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Your running workout, always one tap away',
          body:
              'The bar above the tab bar now shows at a glance whether you are working or resting, how long is left and which exercise your next open set belongs to. Tapping it grows the workout out of the bar instead of pushing in a new screen, and the chevron in its header shrinks it back down.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'Log a meal from a photo',
          body:
              'Point the camera at your plate and the AI turns it into individual foods with amounts, calories and macros. Take up to four photos of the same meal, correct or swap anything before saving - and packaged products are recognised by their barcode in the very same view, without switching modes.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.smartphone,
          title: 'Portion sizes measured, not guessed',
          body:
              'On iPhone models with LiDAR the camera measures how far away your plate is and how large the visible area really is, and passes that to the AI. You can turn the measurement off in the AI settings.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Just say what\'s in it',
          body:
              'Hold the microphone button and describe your meal - on its own or in addition to the photo. Cooking method, oil and hidden ingredients are exactly what a photo cannot show. Recognition runs on your device wherever possible, and you can edit the text before anything is sent.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'A clearer diary',
          body:
              'A scanned meal stays one entry with its photo and can be unfolded into its ingredients. Entries are sorted by calories, largest first, and amounts and calories now line up in the same columns on every row.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.cloud,
          title: 'Your photos in the iCloud backup',
          body:
              'The automatic backup now carries the photos of your meals and workouts, so a restored iPhone shows your entries the way you logged them. Restoring is also safer: it no longer needs a restart, and the previous backup is kept as a spare copy.',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.1.1',
      releasedOn: '2026-08-12',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Home screen widgets on Android',
          body:
              'The widget family has arrived on Android - your last workout with its muscle map, muscle recovery, your steps of the last 7 days, body measurements, today\'s nutrition and quick actions. Add them from your launcher\'s widget picker; nutrition, measurements and quick actions can be reconfigured at any time.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'Your running workout in the notification shade',
          body:
              'A workout in progress now sits in your notifications with its rest countdown, and on Android 16 it becomes a Live Update with a chip in the status bar. Tick off a set, add or drop 15 seconds and skip the rest right there, without opening the app.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Quick Settings tiles',
          body:
              'All seven quick actions - barcode scanner, AI meal capture, start workout, add water, log a supplement, add a measurement and add food - are now available as tiles in your Quick Settings panel.',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.1.0',
      releasedOn: '2026-08-12',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'Live Activity & Dynamic Island',
          body:
              'Follow your running workout straight from the Lock Screen and the Dynamic Island - current exercise, set, weight and rest countdown, without unlocking your phone. Skip or extend the rest timer right there.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Home & Lock Screen Widgets',
          body:
              'New widgets for your last workout, muscle recovery, 7-day steps, body measurements and today\'s nutrition. Add them to the Home Screen or the Lock Screen and see your numbers at a glance.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Siri, Shortcuts & Action Button',
          body:
              'Barcode scanner, AI meal capture, start workout, add water, log a supplement, add a measurement and add food are now available as Shortcuts, Control Center buttons and Action Button mappings.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Faster catalog updates',
          body:
              'The database update screen no longer stalls near the end - the slow step behind it now takes milliseconds instead of about 20 seconds.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Straight to your next set',
          body:
              'Opening a running workout now scrolls directly to the exercise with the next open set.',
        ),
      ],
    ),
  ],
  'de': <WhatsNewRelease>[
    WhatsNewRelease(
      version: '1.2.0-beta.1',
      releasedOn: '2026-08-27',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'Fotos für deine Workouts',
          body:
              'Halte deine Trainingseinheiten mit bis zu 4 Fotos fest. Nimm Fotos direkt mit der Kamera auf oder wähle sie aus deiner Mediathek – sowohl direkt nach dem Training in der Zusammenfassung als auch nachträglich im Trainingsverlauf. Alle Fotos und Vorschauen werden auch im Backup gesichert.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Dein laufendes Workout immer im Blick',
          body:
              'Die Leiste über der Navigation zeigt auf einen Blick, ob du trainierst oder pausierst, wie lange noch, und zu welcher Übung dein nächster offener Satz gehört. Ein Tipp lässt das Workout aus der Leiste herauswachsen, statt einen neuen Bildschirm hereinzuschieben - der Pfeil im Kopfbereich schrumpft es wieder dorthin zurück.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'Mahlzeiten per Foto erfassen',
          body:
              'Richte die Kamera auf deinen Teller und die KI macht daraus einzelne Lebensmittel mit Menge, Kalorien und Makros. Bis zu vier Fotos pro Mahlzeit, alles vor dem Speichern korrigierbar oder austauschbar - und verpackte Produkte erkennt dieselbe Ansicht direkt am Barcode, ohne den Modus zu wechseln.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.smartphone,
          title: 'Portionen gemessen statt geschätzt',
          body:
              'Auf iPhones mit LiDAR misst die Kamera, wie weit dein Teller entfernt ist und wie groß der sichtbare Ausschnitt tatsächlich ist, und gibt das an die KI weiter. In den KI-Einstellungen kannst du die Messung abschalten.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Einfach sagen, was drin ist',
          body:
              'Halte die Mikrofontaste gedrückt und beschreibe deine Mahlzeit - allein oder zusätzlich zum Foto. Zubereitung, Öl und versteckte Zutaten sind genau das, was ein Foto nicht zeigen kann. Die Erkennung läuft wenn möglich auf deinem Gerät, und du kannst den Text vor dem Senden noch korrigieren.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'Übersichtlicheres Tagebuch',
          body:
              'Eine erfasste Mahlzeit bleibt ein Eintrag mit Foto und lässt sich zu ihren Zutaten aufklappen. Einträge sind nach Kalorien sortiert, die größten zuerst, und Menge und Kalorien stehen in jeder Zeile in denselben Spalten.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.cloud,
          title: 'Deine Fotos im iCloud-Backup',
          body:
              'Das automatische Backup nimmt jetzt auch die Fotos deiner Mahlzeiten und Workouts mit, damit ein wiederhergestelltes iPhone deine Einträge so zeigt, wie du sie erfasst hast. Das Wiederherstellen ist außerdem sicherer: Es braucht keinen Neustart mehr, und das vorherige Backup bleibt als Reservekopie erhalten.',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.1.1',
      releasedOn: '2026-08-12',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Homescreen-Widgets für Android',
          body:
              'Die Widget-Familie gibt es jetzt auch auf Android - dein letztes Workout mit Muskelkarte, die Muskelregeneration, deine Schritte der letzten 7 Tage, Körpermaße, die heutige Ernährung und Schnellaktionen. Du fügst sie über die Widget-Auswahl deines Launchers hinzu; Ernährung, Körpermaße und Schnellaktionen kannst du jederzeit neu einstellen.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'Laufendes Workout in der Benachrichtigung',
          body:
              'Dein Workout liegt jetzt mit Pausen-Countdown in den Benachrichtigungen, auf Android 16 wird daraus ein Live Update mit Chip in der Statusleiste. Satz abhaken, 15 Sekunden drauflegen oder abziehen und Pause überspringen geht direkt dort, ohne die App zu öffnen.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Kacheln in den Schnelleinstellungen',
          body:
              'Alle sieben Schnellaktionen - Barcode-Scanner, KI-Mahlzeitenerfassung, Workout starten, Wasser hinzufügen, Supplement eintragen, Körpermaß erfassen und Lebensmittel hinzufügen - gibt es jetzt als Kacheln in deinen Schnelleinstellungen.',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.1.0',
      releasedOn: '2026-08-12',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'Live-Aktivität & Dynamic Island',
          body:
              'Verfolge dein laufendes Workout direkt auf dem Sperrbildschirm und in der Dynamic Island - aktuelle Übung, Satz, Gewicht und Pausen-Countdown, ohne das Handy zu entsperren. Pause verlängern oder überspringen geht gleich dort.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Widgets für Home- und Sperrbildschirm',
          body:
              'Neue Widgets für dein letztes Workout, die Muskelregeneration, deine Schritte der letzten 7 Tage, Körpermaße und die heutige Ernährung. Einfach auf den Home- oder Sperrbildschirm legen und alle Werte auf einen Blick sehen.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Siri, Kurzbefehle & Action Button',
          body:
              'Barcode-Scanner, KI-Mahlzeitenerfassung, Workout starten, Wasser hinzufügen, Supplement eintragen, Körpermaß erfassen und Lebensmittel hinzufügen gibt es jetzt als Kurzbefehle, Kontrollzentrum-Buttons und für den Action Button.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Schnellere Katalog-Updates',
          body:
              'Der Ladebildschirm beim Datenbank-Update bleibt nicht mehr kurz vor Schluss hängen - der langsame Schritt dahinter dauert jetzt Millisekunden statt rund 20 Sekunden.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Direkt zum nächsten Satz',
          body:
              'Wenn du ein laufendes Workout öffnest, springt die App jetzt direkt zur Übung mit dem nächsten offenen Satz.',
        ),
      ],
    ),
  ],
  'fr': <WhatsNewRelease>[
    WhatsNewRelease(
      version: '1.2.0-beta.1',
      releasedOn: '2026-08-27',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'Photos pour vos entraînements',
          body:
              'Capturez vos séances d\'entraînement avec jusqu\'à 4 photos. Prenez des photos directement avec votre appareil ou choisissez-les dans votre bibliothèque, dans le récapitulatif ou dans l\'historique d\'entraînement.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Ton entraînement en cours toujours à portée',
          body:
              'la barre au-dessus de la navigation indique d\'un coup d\'œil si tu travailles ou si tu récupères, combien de temps il reste et à quel exercice appartient ta prochaine série. Un appui fait grandir l\'entraînement depuis la barre au lieu d\'ouvrir un nouvel écran, et le chevron de l\'en-tête le fait redescendre.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'Enregistrer un repas à partir d\'une photo',
          body:
              'vise ton assiette et l\'IA en fait des aliments distincts, avec quantités, calories et macros. Jusqu\'à quatre photos par repas, tout reste corrigeable ou remplaçable avant l\'enregistrement - et les produits emballés sont reconnus par leur code-barres dans la même vue, sans changer de mode.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.smartphone,
          title: 'Des portions mesurées, pas devinées',
          body:
              'sur les iPhone équipés du LiDAR, la caméra mesure la distance de l\'assiette et la taille réelle de la zone visible, puis transmet ces valeurs à l\'IA. La mesure se désactive dans les réglages IA.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Dis simplement ce qu\'il y a dedans',
          body:
              'maintiens le bouton micro et décris ton repas - seul ou en complément de la photo. Mode de cuisson, huile et ingrédients cachés sont justement ce qu\'une photo ne montre pas. La reconnaissance se fait sur ton appareil quand c\'est possible, et tu peux corriger le texte avant l\'envoi.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'Un journal plus lisible',
          body:
              'un repas scanné reste une seule entrée avec sa photo et se déplie sur ses ingrédients. Les entrées sont triées par calories, les plus élevées d\'abord, et quantités et calories s\'alignent dans les mêmes colonnes sur chaque ligne.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.cloud,
          title: 'Tes photos dans la sauvegarde iCloud',
          body:
              'la sauvegarde automatique emporte désormais les photos de tes repas et de tes entraînements, pour qu\'un iPhone restauré affiche tes entrées telles que tu les as enregistrées. La restauration est aussi plus sûre : elle ne demande plus de redémarrage, et la sauvegarde précédente est conservée comme copie de secours.',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.1.1',
      releasedOn: '2026-08-12',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Widgets d\'écran d\'accueil sur Android',
          body:
              'la famille de widgets arrive sur Android - ta dernière séance avec sa carte musculaire, la récupération musculaire, tes pas des 7 derniers jours, tes mensurations, la nutrition du jour et les actions rapides. Ajoute-les depuis le sélecteur de widgets de ton lanceur ; nutrition, mensurations et actions rapides se reconfigurent à tout moment.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'Ta séance en cours dans les notifications',
          body:
              'une séance en cours s\'affiche désormais dans tes notifications avec le compte à rebours de repos, et sur Android 16 elle devient une Live Update avec une pastille dans la barre d\'état. Valider une série, ajouter ou retirer 15 secondes et passer le repos se font sur place, sans ouvrir l\'app.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Tuiles des réglages rapides',
          body:
              'les sept actions rapides - scanner de code-barres, capture de repas par IA, démarrer une séance, ajouter de l\'eau, enregistrer un complément, ajouter une mensuration et ajouter un aliment - sont maintenant disponibles comme tuiles dans tes réglages rapides.',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.1.0',
      releasedOn: '2026-08-12',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'Activité en direct et Dynamic Island',
          body:
              'suis ta séance en cours directement depuis l\'écran verrouillé et la Dynamic Island - exercice actuel, série, charge et compte à rebours de repos, sans déverrouiller ton téléphone. Tu peux prolonger ou passer le repos sur place.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Widgets pour l\'écran d\'accueil et l\'écran verrouillé',
          body:
              'de nouveaux widgets pour ta dernière séance, la récupération musculaire, tes pas des 7 derniers jours, tes mensurations et la nutrition du jour. Ajoute-les et vois tout d\'un coup d\'œil.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Siri, Raccourcis et bouton Action',
          body:
              'scanner de code-barres, capture de repas par IA, démarrer une séance, ajouter de l\'eau, enregistrer un complément, ajouter une mensuration et ajouter un aliment sont désormais disponibles comme raccourcis, boutons du centre de contrôle et pour le bouton Action.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Mises à jour de catalogue plus rapides',
          body:
              'l\'écran de mise à jour de la base de données ne bloque plus juste avant la fin - l\'étape lente derrière prend maintenant quelques millisecondes au lieu d\'environ 20 secondes.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Directement à ta prochaine série',
          body:
              'à l\'ouverture d\'une séance en cours, l\'app défile directement jusqu\'à l\'exercice contenant la prochaine série ouverte.',
        ),
      ],
    ),
  ],
  'it': <WhatsNewRelease>[
    WhatsNewRelease(
      version: '1.2.0-beta.1',
      releasedOn: '2026-08-27',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'Foto per i tuoi allenamenti',
          body:
              'Immortala le tue sessioni di allenamento con un massimo di 4 foto. Scatta direttamente con la fotocamera o scegli dalla libreria, nel riepilogo dell\'allenamento o nella cronologia.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'L\'allenamento in corso sempre a portata',
          body:
              'la barra sopra la navigazione mostra a colpo d\'occhio se stai lavorando o recuperando, quanto manca e a quale esercizio appartiene la prossima serie aperta. Un tocco fa crescere l\'allenamento dalla barra invece di aprire una nuova schermata, e il chevron nell\'intestazione lo fa tornare giù.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'Registra un pasto da una foto',
          body:
              'inquadra il piatto e l\'IA lo trasforma in singoli alimenti con quantità, calorie e macro. Fino a quattro foto per pasto, tutto correggibile o sostituibile prima di salvare - e i prodotti confezionati vengono riconosciuti dal codice a barre nella stessa schermata, senza cambiare modalità.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.smartphone,
          title: 'Porzioni misurate, non stimate',
          body:
              'sugli iPhone con LiDAR la fotocamera misura quanto è distante il piatto e quanto è grande davvero l\'area inquadrata, e passa questi dati all\'IA. La misurazione si può disattivare nelle impostazioni IA.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Di\' semplicemente cosa c\'è dentro',
          body:
              'tieni premuto il pulsante del microfono e descrivi il pasto - da solo o insieme alla foto. Cottura, olio e ingredienti nascosti sono proprio ciò che una foto non può mostrare. Il riconoscimento avviene sul dispositivo quando è possibile e puoi correggere il testo prima di inviarlo.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'Un diario più chiaro',
          body:
              'un pasto scansionato resta una sola voce con la sua foto e si può espandere sui suoi ingredienti. Le voci sono ordinate per calorie, dalle più alte, e quantità e calorie sono allineate nelle stesse colonne su ogni riga.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.cloud,
          title: 'Le tue foto nel backup iCloud',
          body:
              'il backup automatico porta con sé anche le foto dei tuoi pasti e dei tuoi allenamenti, così un iPhone ripristinato mostra le tue voci come le hai registrate. Il ripristino è anche più sicuro: non richiede più un riavvio e il backup precedente viene conservato come copia di riserva.',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.1.1',
      releasedOn: '2026-08-12',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Widget per la schermata Home su Android',
          body:
              'la famiglia di widget arriva su Android - il tuo ultimo allenamento con la mappa muscolare, il recupero muscolare, i passi degli ultimi 7 giorni, le misure corporee, la nutrizione di oggi e le azioni rapide. Aggiungili dal selettore di widget del tuo launcher; nutrizione, misure e azioni rapide si possono riconfigurare in qualsiasi momento.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'L\'allenamento in corso nelle notifiche',
          body:
              'un allenamento in corso compare ora nelle notifiche con il conto alla rovescia del recupero e, su Android 16, diventa una Live Update con un indicatore nella barra di stato. Completare una serie, aggiungere o togliere 15 secondi e saltare il recupero si fanno da lì, senza aprire l\'app.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Riquadri delle impostazioni rapide',
          body:
              'tutte e sette le azioni rapide - scanner di codici a barre, riconoscimento pasti con IA, avvia allenamento, aggiungi acqua, registra un integratore, aggiungi una misura e aggiungi un alimento - sono ora disponibili come riquadri nelle tue impostazioni rapide.',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.1.0',
      releasedOn: '2026-08-12',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'Attività in tempo reale e Dynamic Island',
          body:
              'segui l\'allenamento in corso direttamente dalla schermata di blocco e dalla Dynamic Island - esercizio attuale, serie, peso e conto alla rovescia del recupero, senza sbloccare il telefono. Puoi prolungare o saltare il recupero da lì.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Widget per schermata Home e di blocco',
          body:
              'nuovi widget per l\'ultimo allenamento, il recupero muscolare, i passi degli ultimi 7 giorni, le misure corporee e la nutrizione di oggi. Aggiungili e vedi tutto a colpo d\'occhio.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Siri, Comandi rapidi e tasto Azione',
          body:
              'scanner di codici a barre, riconoscimento pasti con IA, avvia allenamento, aggiungi acqua, registra un integratore, aggiungi una misura e aggiungi un alimento sono ora disponibili come comandi rapidi, pulsanti del Centro di Controllo e per il tasto Azione.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Aggiornamenti del catalogo più veloci',
          body:
              'la schermata di aggiornamento del database non si blocca più poco prima della fine - il passaggio lento dietro le quinte ora richiede millisecondi invece di circa 20 secondi.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Subito alla prossima serie',
          body:
              'aprendo un allenamento in corso l\'app scorre direttamente all\'esercizio con la prossima serie da completare.',
        ),
      ],
    ),
  ],
  'ja': <WhatsNewRelease>[
    WhatsNewRelease(
      version: '1.2.0-beta.1',
      releasedOn: '2026-08-27',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'ワークアウトの写真記録',
          body:
              'トレーニングに最大4枚の写真を添付できるようになりました。カメラでの直接撮影やライブラリからの選択に対応し、サマリー画面や履歴詳細からいつでも追加・確認できます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: '進行中のワークアウトをいつでも手元に',
          body:
              'ナビゲーションの上のバーに、トレーニング中か休憩中か、残り時間、次の未完了セットがどの種目のものかがひと目で分かるようになりました。タップするとワークアウトがバーから広がって開き、ヘッダーのシェブロンでバーに縮んで戻ります。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: '写真から食事を記録',
          body:
              'カメラをお皿に向けるだけで、AIが個々の食品として量・カロリー・PFCに分解します。1回の食事につき最大4枚まで撮影でき、保存前に修正や差し替えが可能です。市販の包装食品は同じ画面のままバーコードで認識されるので、モードを切り替える必要はありません。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.smartphone,
          title: '分量は推測ではなく計測',
          body:
              'LiDAR搭載のiPhoneでは、お皿までの距離と実際に写っている範囲の大きさをカメラが計測し、その値をAIに渡します。計測はAI設定でオフにできます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: '中身を話すだけ',
          body:
              'マイクボタンを長押しして食事の内容を話してください。写真の代わりにも、写真に添えても使えます。調理法や油、隠れた材料は、写真では分からない情報です。認識は可能な限り端末内で行われ、送信前にテキストを編集できます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: '見やすくなった記録',
          body:
              'スキャンした食事は写真付きの1つの項目としてまとまり、展開すると材料が表示されます。項目はカロリーの多い順に並び、量とカロリーはどの行でも同じ位置に揃います。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.cloud,
          title: 'iCloudバックアップに写真も保存',
          body:
              '自動バックアップが食事やワークアウトの写真も一緒に保存するようになり、復元したiPhoneでも記録したときのまま表示されます。復元自体も安全になりました。再起動が不要になり、直前のバックアップは予備として残ります。',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.1.1',
      releasedOn: '2026-08-12',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Androidのホーム画面ウィジェット',
          body:
              'ウィジェットがAndroidにも登場しました。直近のワークアウト（筋肉マップ付き）、筋肉の回復状況、過去7日間の歩数、身体計測、今日の栄養、クイックアクションの6種類です。ランチャーのウィジェット一覧から追加でき、栄養・身体計測・クイックアクションは後からいつでも設定を変更できます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: '進行中のワークアウトを通知に表示',
          body:
              'ワークアウト中は休憩のカウントダウンが通知に表示され、Android 16ではステータスバーにチップが出るライブアップデートになります。セットの完了、休憩の15秒延長・短縮、スキップは、アプリを開かずにその場で行えます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'クイック設定のタイル',
          body:
              'バーコードスキャナー、AI食事記録、ワークアウト開始、水分の追加、サプリの記録、身体計測の追加、食品の追加という7つのクイックアクションが、クイック設定のタイルとして使えるようになりました。',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.1.0',
      releasedOn: '2026-08-12',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'ライブアクティビティとダイナミックアイランド',
          body:
              '進行中のワークアウトをロック画面とダイナミックアイランドから確認できます。現在の種目、セット、重量、休憩のカウントダウンを、ロックを解除せずに表示。休憩の延長やスキップもその場で行えます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'ホーム画面・ロック画面ウィジェット',
          body:
              '直近のワークアウト、筋肉の回復状況、過去7日間の歩数、身体計測、今日の栄養のウィジェットを追加しました。ホーム画面やロック画面に置けば、数値をひと目で確認できます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Siri・ショートカット・アクションボタン',
          body:
              'バーコードスキャナー、AI食事記録、ワークアウト開始、水分の追加、サプリの記録、身体計測の追加、食品の追加が、ショートカット、コントロールセンターのボタン、アクションボタンから使えるようになりました。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'カタログ更新が高速化',
          body: 'データベース更新画面が終了直前で止まらなくなりました。裏側の遅い処理が約20秒からミリ秒単位に短縮されています。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: '次のセットへすぐ移動',
          body: '進行中のワークアウトを開くと、次の未完了セットがある種目まで自動でスクロールします。',
        ),
      ],
    ),
  ],
};

/// Language used when the device language has no notes of its own.
const String kWhatsNewFallbackLanguage = 'en';

/// The version this catalog was generated for, taken from pubspec.yaml.
const String kWhatsNewGeneratedForVersion = '1.2.0-beta.1';
