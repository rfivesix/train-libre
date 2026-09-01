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
      version: '1.2.1',
      releasedOn: '2026-09-01',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'Improved macronutrient recommendations',
          body: 'The adaptive nutrition calculation now distributes fats and carbohydrates in a more balanced way based on your body weight and goal.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.bug,
          title: 'Bug fixes',
          body: 'Fixed minor issues with caffeine logging in the diary and resolved visual glitches during card transitions and animations.',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.2.0',
      releasedOn: '2026-08-30',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'Log a meal from a photo',
          body: 'Point the camera at your plate and the AI turns it into individual foods with amounts, calories and macros - all correctable before you save. Packaged products are recognised by barcode in the very same view, iPhones with LiDAR measure the portion instead of guessing it, and the microphone button lets you add what a photo cannot show.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'A clearer diary',
          body: 'A scanned meal stays one entry with its photo and unfolds into its ingredients. Entries are sorted by calories, largest first.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'More from your training',
          body: 'Keep up to 4 photos per workout, and the bar above the tab bar always shows whether you are working or resting and which exercise comes next. Tapping it grows the workout out of the bar.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.cloud,
          title: 'Your photos in the iCloud backup',
          body: 'The automatic backup now carries the photos of your meals and workouts. Restoring no longer needs a restart and keeps the previous backup as a spare copy.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.sparkles,
          title: 'Smoother to use',
          body: 'Cards grow into full screen instead of switching abruptly, numbers count themselves up, and removed exercises fold away gently instead of popping out.',
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
          body: 'The widget family has arrived on Android - your last workout with its muscle map, muscle recovery, your steps of the last 7 days, body measurements, today\'s nutrition and quick actions. Add them from your launcher\'s widget picker; nutrition, measurements and quick actions can be reconfigured at any time.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'Your running workout in the notification shade',
          body: 'A workout in progress now sits in your notifications with its rest countdown, and on Android 16 it becomes a Live Update with a chip in the status bar. Tick off a set, add or drop 15 seconds and skip the rest right there, without opening the app.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Quick Settings tiles',
          body: 'All seven quick actions - barcode scanner, AI meal capture, start workout, add water, log a supplement, add a measurement and add food - are now available as tiles in your Quick Settings panel.',
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
          body: 'Follow your running workout straight from the Lock Screen and the Dynamic Island - current exercise, set, weight and rest countdown, without unlocking your phone. Skip or extend the rest timer right there.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Home & Lock Screen Widgets',
          body: 'New widgets for your last workout, muscle recovery, 7-day steps, body measurements and today\'s nutrition. Add them to the Home Screen or the Lock Screen and see your numbers at a glance.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Siri, Shortcuts & Action Button',
          body: 'Barcode scanner, AI meal capture, start workout, add water, log a supplement, add a measurement and add food are now available as Shortcuts, Control Center buttons and Action Button mappings.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Faster catalog updates',
          body: 'The database update screen no longer stalls near the end - the slow step behind it now takes milliseconds instead of about 20 seconds.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Straight to your next set',
          body: 'Opening a running workout now scrolls directly to the exercise with the next open set.',
        ),
      ],
    ),
  ],
  'de': <WhatsNewRelease>[
    WhatsNewRelease(
      version: '1.2.1',
      releasedOn: '2026-09-01',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'Verbesserte Makronährstoff-Empfehlungen',
          body: 'Die adaptive Berechnung verteilt Fett und Kohlenhydrate jetzt noch ausgewogener basierend auf deinem Körpergewicht und Ziel.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.bug,
          title: 'Fehlerbehebungen',
          body: 'Kleinere Fehler bei der Erfassung von Koffein im Tagebuch sowie Darstellungsfehler bei Animationen und Kartenübergängen behoben.',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.2.0',
      releasedOn: '2026-08-30',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'Mahlzeiten per Foto erfassen',
          body: 'Richte die Kamera auf deinen Teller, und die KI macht daraus einzelne Lebensmittel mit Menge, Kalorien und Makros - vor dem Speichern alles korrigierbar. Verpackte Produkte erkennt dieselbe Ansicht am Barcode, iPhones mit LiDAR messen die Portion statt zu schätzen, und per Mikrofontaste ergänzt du, was das Foto nicht zeigt.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'Übersichtlicheres Tagebuch',
          body: 'Eine erfasste Mahlzeit bleibt ein Eintrag mit Foto und lässt sich zu ihren Zutaten aufklappen. Einträge sind nach Kalorien sortiert, die größten zuerst.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Mehr von deinem Training',
          body: 'Halte Workouts mit bis zu 4 Fotos fest, und die Leiste über der Navigation zeigt jederzeit, ob du trainierst oder pausierst und welche Übung als Nächstes ansteht. Ein Tipp lässt das Workout aus der Leiste herauswachsen.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.cloud,
          title: 'Deine Fotos im iCloud-Backup',
          body: 'Das automatische Backup nimmt jetzt auch die Fotos deiner Mahlzeiten und Workouts mit. Das Wiederherstellen braucht außerdem keinen Neustart mehr und behält das vorherige Backup als Reservekopie.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.sparkles,
          title: 'Flüssigere Bedienung',
          body: 'Karten wachsen zum Vollbild heran statt hart umzuschalten, Zahlen zählen sich hoch, und entfernte Übungen klappen sanft zusammen, statt wegzuspringen.',
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
          body: 'Die Widget-Familie gibt es jetzt auch auf Android - dein letztes Workout mit Muskelkarte, die Muskelregeneration, deine Schritte der letzten 7 Tage, Körpermaße, die heutige Ernährung und Schnellaktionen. Du fügst sie über die Widget-Auswahl deines Launchers hinzu; Ernährung, Körpermaße und Schnellaktionen kannst du jederzeit neu einstellen.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'Laufendes Workout in der Benachrichtigung',
          body: 'Dein Workout liegt jetzt mit Pausen-Countdown in den Benachrichtigungen, auf Android 16 wird daraus ein Live Update mit Chip in der Statusleiste. Satz abhaken, 15 Sekunden drauflegen oder abziehen und Pause überspringen geht direkt dort, ohne die App zu öffnen.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Kacheln in den Schnelleinstellungen',
          body: 'Alle sieben Schnellaktionen - Barcode-Scanner, KI-Mahlzeitenerfassung, Workout starten, Wasser hinzufügen, Supplement eintragen, Körpermaß erfassen und Lebensmittel hinzufügen - gibt es jetzt als Kacheln in deinen Schnelleinstellungen.',
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
          body: 'Verfolge dein laufendes Workout direkt auf dem Sperrbildschirm und in der Dynamic Island - aktuelle Übung, Satz, Gewicht und Pausen-Countdown, ohne das Handy zu entsperren. Pause verlängern oder überspringen geht gleich dort.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Widgets für Home- und Sperrbildschirm',
          body: 'Neue Widgets für dein letztes Workout, die Muskelregeneration, deine Schritte der letzten 7 Tage, Körpermaße und die heutige Ernährung. Einfach auf den Home- oder Sperrbildschirm legen und alle Werte auf einen Blick sehen.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Siri, Kurzbefehle & Action Button',
          body: 'Barcode-Scanner, KI-Mahlzeitenerfassung, Workout starten, Wasser hinzufügen, Supplement eintragen, Körpermaß erfassen und Lebensmittel hinzufügen gibt es jetzt als Kurzbefehle, Kontrollzentrum-Buttons und für den Action Button.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Schnellere Katalog-Updates',
          body: 'Der Ladebildschirm beim Datenbank-Update bleibt nicht mehr kurz vor Schluss hängen - der langsame Schritt dahinter dauert jetzt Millisekunden statt rund 20 Sekunden.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Direkt zum nächsten Satz',
          body: 'Wenn du ein laufendes Workout öffnest, springt die App jetzt direkt zur Übung mit dem nächsten offenen Satz.',
        ),
      ],
    ),
  ],
  'fr': <WhatsNewRelease>[
    WhatsNewRelease(
      version: '1.2.1',
      releasedOn: '2026-09-01',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'Recommandations de macronutriments améliorées',
          body: 'le calcul adaptatif répartit désormais les lipides et les glucides de manière plus équilibrée selon ton poids corporel et ton objectif.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.bug,
          title: 'Corrections d\'erreurs',
          body: 'correction de légers soucis liés au suivi de la caféine dans le journal et amélioration des transitions et animations de cartes.',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.2.0',
      releasedOn: '2026-08-30',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'Enregistrer un repas à partir d\'une photo',
          body: 'vise ton assiette et l\'IA en fait des aliments distincts, avec quantités, calories et macros - tout reste corrigeable avant l\'enregistrement. Les produits emballés sont reconnus par leur code-barres dans la même vue, les iPhone équipés du LiDAR mesurent la portion au lieu de la deviner, et le bouton micro permet d\'ajouter ce qu\'une photo ne montre pas.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'Un journal plus lisible',
          body: 'un repas scanné reste une seule entrée avec sa photo et se déplie sur ses ingrédients. Les entrées sont triées par calories, les plus élevées d\'abord.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Plus de tes entraînements',
          body: 'garde jusqu\'à 4 photos par séance, et la barre au-dessus de la navigation indique en permanence si tu travailles ou récupères et quel exercice arrive ensuite. Un appui fait grandir l\'entraînement depuis la barre.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.cloud,
          title: 'Tes photos dans la sauvegarde iCloud',
          body: 'la sauvegarde automatique emporte désormais les photos de tes repas et de tes entraînements. La restauration ne demande plus de redémarrage et conserve la sauvegarde précédente comme copie de secours.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.sparkles,
          title: 'Une utilisation plus fluide',
          body: 'les cartes s\'agrandissent en plein écran au lieu de basculer d\'un coup, les chiffres défilent jusqu\'à leur valeur, et les exercices supprimés se replient en douceur au lieu de disparaître brusquement.',
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
          body: 'la famille de widgets arrive sur Android - ta dernière séance avec sa carte musculaire, la récupération musculaire, tes pas des 7 derniers jours, tes mensurations, la nutrition du jour et les actions rapides. Ajoute-les depuis le sélecteur de widgets de ton lanceur ; nutrition, mensurations et actions rapides se reconfigurent à tout moment.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'Ta séance en cours dans les notifications',
          body: 'une séance en cours s\'affiche désormais dans tes notifications avec le compte à rebours de repos, et sur Android 16 elle devient une Live Update avec une pastille dans la barre d\'état. Valider une série, ajouter ou retirer 15 secondes et passer le repos se font sur place, sans ouvrir l\'app.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Tuiles des réglages rapides',
          body: 'les sept actions rapides - scanner de code-barres, capture de repas par IA, démarrer une séance, ajouter de l\'eau, enregistrer un complément, ajouter une mensuration et ajouter un aliment - sont maintenant disponibles comme tuiles dans tes réglages rapides.',
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
          body: 'suis ta séance en cours directement depuis l\'écran verrouillé et la Dynamic Island - exercice actuel, série, charge et compte à rebours de repos, sans déverrouiller ton téléphone. Tu peux prolonger ou passer le repos sur place.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Widgets pour l\'écran d\'accueil et l\'écran verrouillé',
          body: 'de nouveaux widgets pour ta dernière séance, la récupération musculaire, tes pas des 7 derniers jours, tes mensurations et la nutrition du jour. Ajoute-les et vois tout d\'un coup d\'œil.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Siri, Raccourcis et bouton Action',
          body: 'scanner de code-barres, capture de repas par IA, démarrer une séance, ajouter de l\'eau, enregistrer un complément, ajouter une mensuration et ajouter un aliment sont désormais disponibles comme raccourcis, boutons du centre de contrôle et pour le bouton Action.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Mises à jour de catalogue plus rapides',
          body: 'l\'écran de mise à jour de la base de données ne bloque plus juste avant la fin - l\'étape lente derrière prend maintenant quelques millisecondes au lieu d\'environ 20 secondes.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Directement à ta prochaine série',
          body: 'à l\'ouverture d\'une séance en cours, l\'app défile directement jusqu\'à l\'exercice contenant la prochaine série ouverte.',
        ),
      ],
    ),
  ],
  'it': <WhatsNewRelease>[
    WhatsNewRelease(
      version: '1.2.1',
      releasedOn: '2026-09-01',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'Raccomandazioni dei macronutrienti migliorate',
          body: 'il calcolo adattivo distribuisce ora grassi e carboidrati in modo più bilanciato in base al peso corporeo e all\'obiettivo.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.bug,
          title: 'Correzione di bug',
          body: 'risolti piccoli problemi con la registrazione della caffeina nel diario e migliorate le transizioni e le animazioni delle schede.',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.2.0',
      releasedOn: '2026-08-30',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: 'Registra un pasto da una foto',
          body: 'inquadra il piatto e l\'IA lo trasforma in singoli alimenti con quantità, calorie e macro, tutto correggibile prima di salvare. I prodotti confezionati vengono riconosciuti dal codice a barre nella stessa schermata, gli iPhone con LiDAR misurano la porzione invece di stimarla e il pulsante del microfono ti fa aggiungere ciò che una foto non mostra.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'Un diario più chiaro',
          body: 'un pasto scansionato resta una sola voce con la sua foto e si espande sui suoi ingredienti. Le voci sono ordinate per calorie, dalle più alte.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Di più dai tuoi allenamenti',
          body: 'conserva fino a 4 foto per sessione e la barra sopra la navigazione mostra sempre se stai lavorando o recuperando e quale esercizio viene dopo. Un tocco fa crescere l\'allenamento dalla barra.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.cloud,
          title: 'Le tue foto nel backup iCloud',
          body: 'il backup automatico porta con sé anche le foto dei tuoi pasti e dei tuoi allenamenti. Il ripristino non richiede più un riavvio e conserva il backup precedente come copia di riserva.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.sparkles,
          title: 'Uso più fluido',
          body: 'le schede si aprono a schermo intero invece di cambiare di scatto, i numeri si contano da soli e gli esercizi rimossi si richiudono con delicatezza invece di sparire di colpo.',
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
          body: 'la famiglia di widget arriva su Android - il tuo ultimo allenamento con la mappa muscolare, il recupero muscolare, i passi degli ultimi 7 giorni, le misure corporee, la nutrizione di oggi e le azioni rapide. Aggiungili dal selettore di widget del tuo launcher; nutrizione, misure e azioni rapide si possono riconfigurare in qualsiasi momento.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: 'L\'allenamento in corso nelle notifiche',
          body: 'un allenamento in corso compare ora nelle notifiche con il conto alla rovescia del recupero e, su Android 16, diventa una Live Update con un indicatore nella barra di stato. Completare una serie, aggiungere o togliere 15 secondi e saltare il recupero si fanno da lì, senza aprire l\'app.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Riquadri delle impostazioni rapide',
          body: 'tutte e sette le azioni rapide - scanner di codici a barre, riconoscimento pasti con IA, avvia allenamento, aggiungi acqua, registra un integratore, aggiungi una misura e aggiungi un alimento - sono ora disponibili come riquadri nelle tue impostazioni rapide.',
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
          body: 'segui l\'allenamento in corso direttamente dalla schermata di blocco e dalla Dynamic Island - esercizio attuale, serie, peso e conto alla rovescia del recupero, senza sbloccare il telefono. Puoi prolungare o saltare il recupero da lì.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'Widget per schermata Home e di blocco',
          body: 'nuovi widget per l\'ultimo allenamento, il recupero muscolare, i passi degli ultimi 7 giorni, le misure corporee e la nutrizione di oggi. Aggiungili e vedi tutto a colpo d\'occhio.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Siri, Comandi rapidi e tasto Azione',
          body: 'scanner di codici a barre, riconoscimento pasti con IA, avvia allenamento, aggiungi acqua, registra un integratore, aggiungi una misura e aggiungi un alimento sono ora disponibili come comandi rapidi, pulsanti del Centro di Controllo e per il tasto Azione.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'Aggiornamenti del catalogo più veloci',
          body: 'la schermata di aggiornamento del database non si blocca più poco prima della fine - il passaggio lento dietro le quinte ora richiede millisecondi invece di circa 20 secondi.',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'Subito alla prossima serie',
          body: 'aprendo un allenamento in corso l\'app scorre direttamente all\'esercizio con la prossima serie da completare.',
        ),
      ],
    ),
  ],
  'ja': <WhatsNewRelease>[
    WhatsNewRelease(
      version: '1.2.1',
      releasedOn: '2026-09-01',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: 'PFCバランスの推奨値を改善',
          body: '体重と目標に基づき、脂質と炭水化物の適応計算をよりバランスの良い配分に改善しました。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.bug,
          title: 'バグ修正',
          body: '日記でのカフェイン記録に関する軽微な不具合の修正と、カードの切り替えアニメーションの表示を改善しました。',
        ),
      ],
    ),
    WhatsNewRelease(
      version: '1.2.0',
      releasedOn: '2026-08-30',
      entries: <WhatsNewEntry>[
        WhatsNewEntry(
          icon: LucideIcons.camera,
          title: '写真から食事を記録',
          body: 'カメラをお皿に向けるだけで、AIが個々の食品として量・カロリー・PFCに分解します。保存前にすべて修正でき、市販の包装食品は同じ画面のままバーコードで認識、LiDAR搭載のiPhoneでは分量を推測せずに計測し、マイクボタンで写真に写らない情報を補足できます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.utensils,
          title: '見やすくなった記録',
          body: 'スキャンした食事は写真付きの1つの項目としてまとまり、展開すると材料が表示されます。項目はカロリーの多い順に並びます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.dumbbell,
          title: 'トレーニングをもっと記録',
          body: 'ワークアウトに最大4枚の写真を残せます。ナビゲーションの上のバーには、トレーニング中か休憩中か、次の種目は何かが常に表示され、タップするとワークアウトがバーから広がって開きます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.cloud,
          title: 'iCloudバックアップに写真も保存',
          body: '自動バックアップが食事やワークアウトの写真も一緒に保存します。復元は再起動が不要になり、直前のバックアップは予備として残ります。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.sparkles,
          title: 'より滑らかな操作感',
          body: 'カードが切り替わるのではなく全画面へと広がり、数値はカウントアップし、削除した種目は急に消えず静かに折りたたまれます。',
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
          body: 'ウィジェットがAndroidにも登場しました。直近のワークアウト（筋肉マップ付き）、筋肉の回復状況、過去7日間の歩数、身体計測、今日の栄養、クイックアクションの6種類です。ランチャーのウィジェット一覧から追加でき、栄養・身体計測・クイックアクションは後からいつでも設定を変更できます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.activity,
          title: '進行中のワークアウトを通知に表示',
          body: 'ワークアウト中は休憩のカウントダウンが通知に表示され、Android 16ではステータスバーにチップが出るライブアップデートになります。セットの完了、休憩の15秒延長・短縮、スキップは、アプリを開かずにその場で行えます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.zap,
          title: 'クイック設定のタイル',
          body: 'バーコードスキャナー、AI食事記録、ワークアウト開始、水分の追加、サプリの記録、身体計測の追加、食品の追加という7つのクイックアクションが、クイック設定のタイルとして使えるようになりました。',
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
          body: '進行中のワークアウトをロック画面とダイナミックアイランドから確認できます。現在の種目、セット、重量、休憩のカウントダウンを、ロックを解除せずに表示。休憩の延長やスキップもその場で行えます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.layout_grid,
          title: 'ホーム画面・ロック画面ウィジェット',
          body: '直近のワークアウト、筋肉の回復状況、過去7日間の歩数、身体計測、今日の栄養のウィジェットを追加しました。ホーム画面やロック画面に置けば、数値をひと目で確認できます。',
        ),
        WhatsNewEntry(
          icon: LucideIcons.mic,
          title: 'Siri・ショートカット・アクションボタン',
          body: 'バーコードスキャナー、AI食事記録、ワークアウト開始、水分の追加、サプリの記録、身体計測の追加、食品の追加が、ショートカット、コントロールセンターのボタン、アクションボタンから使えるようになりました。',
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
const String kWhatsNewGeneratedForVersion = '1.2.1';
