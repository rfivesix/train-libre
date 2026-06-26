// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get selectDateTitle => 'Seleziona data';

  @override
  String get selectTimeTitle => 'Seleziona ora';

  @override
  String get appTitle => 'Train Libre';

  @override
  String get bannerText => 'Raccomandazione/Allenamento attuale';

  @override
  String get calories => 'Calorie';

  @override
  String get water => 'Acqua';

  @override
  String get protein => 'Proteine';

  @override
  String get carbs => 'Carboidrati';

  @override
  String get fat => 'Grassi';

  @override
  String get steps => 'Passi';

  @override
  String get daily => 'Quotidiano';

  @override
  String get today => 'Oggi';

  @override
  String get workoutSection => 'Sezione allenamento - non ancora implementata';

  @override
  String get addMenuTitle => 'Cosa vuoi aggiungere?';

  @override
  String get addFoodOption => 'aggiungere cibo';

  @override
  String get addLiquidOption => 'aggiungere liquido';

  @override
  String get searchHintText => 'Ricerca...';

  @override
  String get mealtypeBreakfast => 'Colazione';

  @override
  String get mealtypeLunch => 'Pranzo';

  @override
  String get mealtypeDinner => 'Cena';

  @override
  String get mealtypeSnack => 'Spuntino';

  @override
  String get waterHeader => 'Acqua e bevande';

  @override
  String get openFoodFactsSource => 'Dati da Open Food Facts';

  @override
  String get tabRecent => 'Recente';

  @override
  String get tabSearch => 'Ricerca';

  @override
  String get tabFavorites => 'Preferiti';

  @override
  String get fabCreateOwnFood => 'Cibo personalizzato';

  @override
  String get recentEmptyState =>
      'I tuoi prodotti alimentari usati di recente\napparirà qui.';

  @override
  String get favoritesEmptyState =>
      'Non hai ancora nessun preferito.\nContrassegna un alimento con l\'icona del cuore per vederlo qui.';

  @override
  String get searchInitialHint => 'Inserisci un termine di ricerca.';

  @override
  String get searchNoResults => 'Nessun risultato trovato';

  @override
  String get createFoodScreenTitle => 'Crea cibo personalizzato';

  @override
  String get formFieldName => 'Nome del cibo';

  @override
  String get formFieldBrand => 'Marchio (facoltativo)';

  @override
  String get formSectionMainNutrients => 'Principali nutrienti (per 100 g)';

  @override
  String get formFieldCalories => 'Calorie (kcal)';

  @override
  String get formFieldProtein => 'Proteine ​​(g)';

  @override
  String get formFieldCarbs => 'Carboidrati (g)';

  @override
  String get formFieldFat => 'Grassi (g)';

  @override
  String get formSectionOptionalNutrients =>
      'Nutrienti aggiuntivi (facoltativi, per 100 g)';

  @override
  String get formFieldSugar => 'Di cui zuccheri (g)';

  @override
  String get formFieldFiber => 'Fibra (g)';

  @override
  String get formFieldKj => 'Kilojoule (kJ)';

  @override
  String get formFieldSalt => 'Sale (g)';

  @override
  String get formFieldSodium => 'Sodio (mg)';

  @override
  String get formFieldCalcium => 'Calcio (mg)';

  @override
  String get buttonSave => 'Salva';

  @override
  String get validatorPleaseEnterName => 'Inserisci un nome.';

  @override
  String get validatorPleaseEnterNumber => 'Inserisci un numero valido.';

  @override
  String snackbarSaveSuccess(String foodName) {
    return '$foodName è stato salvato correttamente.';
  }

  @override
  String get foodDetailSegmentPortion => 'Porzione';

  @override
  String get foodDetailSegment100g => '100 g';

  @override
  String get sugar => 'Zucchero';

  @override
  String get fiber => 'Fibra';

  @override
  String get salt => 'Sale';

  @override
  String get caffeine => 'Caffeina';

  @override
  String get explorerScreenTitle => 'Esploratore del cibo';

  @override
  String get nutritionScreenTitle => 'Analisi nutrizionale';

  @override
  String get entriesForDateRangeLabel => 'Voci per';

  @override
  String get noEntriesForPeriod => 'Nessuna voce per questo periodo ancora.';

  @override
  String get waterEntryTitle => 'Acqua';

  @override
  String get profileScreenTitle => 'Profilo';

  @override
  String get profileDailyGoals => 'Obiettivi giornalieri';

  @override
  String get profileDailyGoalsCL => 'OBIETTIVI GIORNALIERI';

  @override
  String get snackbarGoalsSaved => 'Gol salvati con successo!';

  @override
  String get measurementsScreenTitle => 'Misure';

  @override
  String get measurementsEmptyState =>
      'Nessuna misurazione ancora registrata.\nInizia con il pulsante \"+\".';

  @override
  String get addMeasurementDialogTitle => 'Aggiungi nuova misurazione';

  @override
  String get formFieldMeasurementType => 'Tipo di misurazione';

  @override
  String formFieldMeasurementValue(Object unit) {
    return 'Valore ($unit)';
  }

  @override
  String get validatorPleaseEnterValue => 'Inserisci un valore';

  @override
  String get measurementWeight => 'Peso corporeo';

  @override
  String get measurementFatPercent => 'Grasso corporeo';

  @override
  String get measurementNeck => 'Collo';

  @override
  String get measurementShoulder => 'Spalla';

  @override
  String get measurementChest => 'Petto';

  @override
  String get measurementLeftBicep => 'Bicipite sinistro';

  @override
  String get measurementRightBicep => 'Bicipite destro';

  @override
  String get measurementLeftForearm => 'Avambraccio sinistro';

  @override
  String get measurementRightForearm => 'Avambraccio destro';

  @override
  String get measurementAbdomen => 'Addome';

  @override
  String get measurementWaist => 'Vita';

  @override
  String get measurementHips => 'Fianchi';

  @override
  String get measurementLeftThigh => 'Coscia sinistra';

  @override
  String get measurementRightThigh => 'Coscia destra';

  @override
  String get measurementLeftCalf => 'Vitello sinistro';

  @override
  String get measurementRightCalf => 'Vitello destro';

  @override
  String get drawerMenuTitle => 'Menù Treno Libero';

  @override
  String get drawerDashboard => 'Pannello di controllo';

  @override
  String get drawerFoodExplorer => 'Esploratore del cibo';

  @override
  String get drawerDataManagement => 'Backup dei dati';

  @override
  String get drawerMeasurements => 'Misure';

  @override
  String get dataManagementTitle => 'Backup dei dati';

  @override
  String get exportCardTitle => 'Esporta dati';

  @override
  String get exportCardDescription =>
      'Salva tutte le voci del diario, i preferiti e gli alimenti personalizzati in un unico file di backup.';

  @override
  String get exportCardButton => 'Crea backup';

  @override
  String get importCardTitle => 'Importa dati';

  @override
  String get importCardDescription =>
      'Ripristina i tuoi dati da un file di backup creato in precedenza. ATTENZIONE: tutti i dati attualmente memorizzati nell\'app verranno sovrascritti!';

  @override
  String get importCardButton => 'Ripristina backup';

  @override
  String get recommendationDefault => 'Tieni traccia del tuo primo pasto!';

  @override
  String recommendationOverTarget(Object count, Object difference) {
    return 'Ultimi $count giorni: +$difference kcal rispetto al target';
  }

  @override
  String recommendationUnderTarget(Object count, Object difference) {
    return 'Ultimi $count giorni: $difference kcal sotto il target';
  }

  @override
  String recommendationOnTarget(Object count) {
    return 'Ultimi $count giorni: obiettivo raggiunto ✅';
  }

  @override
  String get recommendationFirstEntry =>
      'Ottimo, il tuo primo ingresso è stato registrato!';

  @override
  String get dialogConfirmTitle => 'Conferma richiesta';

  @override
  String get dialogConfirmImportContent =>
      'Vuoi davvero ripristinare i dati da questo backup?\n\nATTENZIONE: tutte le voci correnti, i preferiti e gli alimenti personalizzati verranno eliminati e sostituiti in modo permanente.';

  @override
  String get dialogButtonCancel => 'Cancellare';

  @override
  String get dialogButtonOverwrite => 'Sì, sovrascrivi tutto';

  @override
  String get snackbarNoFileSelected => 'Nessun file selezionato.';

  @override
  String get snackbarImportSuccessTitle => 'Importazione riuscita!';

  @override
  String get snackbarImportSuccessContent =>
      'I tuoi dati sono stati ripristinati. Si consiglia di riavviare l\'app per una corretta visualizzazione.';

  @override
  String get snackbarButtonOK => 'OK';

  @override
  String get snackbarImportError => 'Errore durante l\'importazione dei dati.';

  @override
  String get snackbarExportSuccess =>
      'Il file di backup è stato passato al sistema. Scegli una posizione in cui salvare.';

  @override
  String get snackbarExportFailed => 'Esportazione annullata o non riuscita.';

  @override
  String get profileUserHeight => 'Altezza (cm)';

  @override
  String get workoutRoutinesTitle => 'Routine';

  @override
  String get workoutHistoryTitle => 'Cronologia degli allenamenti';

  @override
  String get workoutHistoryButton => 'Storia';

  @override
  String get emptyRoutinesTitle => 'Nessuna routine trovata';

  @override
  String get emptyRoutinesSubtitle =>
      'Crea la tua prima routine o inizia un allenamento vuoto.';

  @override
  String get createFirstRoutineButton => 'Crea la prima routine';

  @override
  String get startEmptyWorkoutButton => 'Allenamento gratuito';

  @override
  String get editRoutineSubtitle =>
      'Tocca per modificare o avviare l\'allenamento.';

  @override
  String get startButton => 'Inizio';

  @override
  String get addRoutineButton => 'Nuova routine';

  @override
  String get freeWorkoutTitle => 'Allenamento gratuito';

  @override
  String get finishWorkoutButton => 'Fine';

  @override
  String get addSetButton => 'Aggiungi insieme';

  @override
  String get addExerciseToWorkoutButton =>
      'Aggiungi esercizio all\'allenamento';

  @override
  String get lastTimeLabel => 'L\'ultima volta';

  @override
  String get setLabel => 'Impostato';

  @override
  String get kgLabel => 'Peso (kg)';

  @override
  String get repsLabel => 'Rappresentanti';

  @override
  String get cardioDistanceLabel => 'Distanza (km)';

  @override
  String get cardioTimeLabel => 'Tempo';

  @override
  String get cardioIntensityLabel => 'Intensi.';

  @override
  String get cardioIntensityShortLabel => 'interno';

  @override
  String get restTimerLabel => 'Riposo';

  @override
  String get skipButton => 'Saltare';

  @override
  String get appInitStarting => 'Avvio dell\'app...';

  @override
  String get appInitInitializing => 'Inizializzazione...';

  @override
  String get appInitFinalizing => 'Finalizzazione';

  @override
  String get appInitCheckingBackups => 'Controllo dei backup...';

  @override
  String get appInitSkipDownload => 'Salta il download';

  @override
  String get appInitSkippingRemoteDownload => 'Salto download remoto...';

  @override
  String get emptyHistory => 'Nessun allenamento ancora completato.';

  @override
  String get workoutDetailsTitle => 'Dettagli allenamento';

  @override
  String get workoutHeartRateSectionTitle => 'Frequenza cardiaca';

  @override
  String get workoutHeartRateAverageLabel => 'Media';

  @override
  String get workoutHeartRateMaxLabel => 'Massimo';

  @override
  String get workoutHeartRateMinLabel => 'minimo';

  @override
  String get workoutHeartRateQualityReady => 'Buona copertura';

  @override
  String get workoutHeartRateQualityLimited => 'Dati limitati';

  @override
  String get workoutHeartRateQualityInsufficient => 'Molto scarso';

  @override
  String get workoutHeartRateQualityNoData => 'Nessun dato';

  @override
  String get workoutHeartRateNoDataGeneral =>
      'Nessun campione di frequenza cardiaca trovato per questa finestra di allenamento.';

  @override
  String get workoutHeartRateNoDataPermission =>
      'Per visualizzare la frequenza cardiaca dell\'allenamento è necessaria l\'autorizzazione relativa alla frequenza cardiaca.';

  @override
  String get workoutHeartRateNoDataUnavailable =>
      'I dati sulla frequenza cardiaca non sono attualmente disponibili su questo dispositivo.';

  @override
  String get workoutHeartRateNoDataWorkoutNotFinished =>
      'Il riepilogo della frequenza cardiaca viene visualizzato al termine dell\'allenamento.';

  @override
  String get workoutHeartRateNoDataInvalidWindow =>
      'La finestra temporale dell\'allenamento non è valida, quindi la FC non può essere analizzata.';

  @override
  String get workoutHeartRateNoDataQueryFailed =>
      'Impossibile leggere i dati sulla frequenza cardiaca per questo allenamento.';

  @override
  String get workoutHeartRateLimitedChartHint =>
      'Campioni coerenti non sufficienti per un grafico affidabile.';

  @override
  String workoutHeartRateSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count campioni',
      one: '1 campione',
      zero: 'Nessun campione',
    );
    return '$_temp0';
  }

  @override
  String get workoutNotFound => 'Allenamento non trovato.';

  @override
  String get totalVolumeLabel => 'Volume totale';

  @override
  String get notesLabel => 'Note';

  @override
  String get workoutImportTitle => 'Importazione di allenamenti esterni';

  @override
  String get workoutImportDescription =>
      'Importa la cronologia dei tuoi allenamenti da un file di esportazione CSV o Excel.';

  @override
  String get workoutImportButton => 'Importa dati di allenamento';

  @override
  String workoutImportSuccess(Object count) {
    return '$count allenamenti importati con successo!';
  }

  @override
  String get workoutImportFailed =>
      'Importazione non riuscita. Si prega di controllare il file.';

  @override
  String get importUnitSelectionTitle => 'Unità di importazione';

  @override
  String get importUnitSelectionDescription =>
      'In quale unità vengono forniti i dati nel file?';

  @override
  String get unitMetricLabel => 'Metrico (kg)';

  @override
  String get unitImperialLabel => 'Imperiale (libbre)';

  @override
  String get excelExportButton => 'Esportazione in Excel (.xlsx)';

  @override
  String get exportWorkoutHistory => 'Cronologia degli allenamenti';

  @override
  String get exportNutritionDiary => 'Diario nutrizionale';

  @override
  String get exportMeasurements => 'Misure';

  @override
  String get startWorkout => 'Inizia l\'allenamento';

  @override
  String get addMeasurement => 'Aggiungi misurazione';

  @override
  String get filterToday => 'Oggi';

  @override
  String get filter7Days => '7 giorni';

  @override
  String get filter30Days => '30 giorni';

  @override
  String get filterAll => 'Tutto';

  @override
  String get showLess => 'Mostra meno';

  @override
  String get showMoreDetails => 'Mostra più dettagli';

  @override
  String get deleteConfirmTitle => 'Conferma l\'eliminazione';

  @override
  String get deleteConfirmContent => 'Vuoi davvero eliminare questa voce?';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get save => 'Salva';

  @override
  String get unsavedChangesTitle => 'Modifiche non salvate';

  @override
  String get unsavedChangesContent =>
      'Sono presenti modifiche non salvate. Vuoi salvarli prima di partire?';

  @override
  String get share => 'Condividere';

  @override
  String get shareWorkout => 'Condividi allenamento';

  @override
  String get shareRoutine => 'Condividi la routine';

  @override
  String get shareAsImage => 'Condividi come immagine';

  @override
  String get shareAsText => 'Condividi come testo';

  @override
  String get sharedFromTrainLibre => 'Condiviso da Train Libre';

  @override
  String get sharedWithTrainLibre => 'Condiviso con Train Libre';

  @override
  String get shareImageSummary => 'Riepilogo';

  @override
  String get shareImageExercises => 'Esercizi';

  @override
  String get shareImageMuscleFocus => 'Concentrazione muscolare';

  @override
  String get shareImageMinimal => 'Minimo';

  @override
  String get volume => 'Volume';

  @override
  String moreExercises(int count) {
    return '+ $count altri esercizi';
  }

  @override
  String shareSetNumber(int number) {
    return 'Imposta $number';
  }

  @override
  String get repsShort => 'ripetizioni';

  @override
  String get shareFailed => 'Condivisione non riuscita';

  @override
  String get workoutShareTitle => 'Allenamento';

  @override
  String get routineShareTitle => 'Routine';

  @override
  String get setTypeWarmup => 'Riscaldamento';

  @override
  String get setTypeWork => 'Set di lavoro';

  @override
  String get setTypeFailure => 'Fallimento';

  @override
  String get setTypeDropset => 'Dropset';

  @override
  String get setTypeSuperset => 'Superinsieme';

  @override
  String get setTypeOther => 'Altro';

  @override
  String get setTypeWarmupSuffix => 'Riscaldamento';

  @override
  String get setTypeFailureSuffix => 'Fallimento';

  @override
  String get setTypeDropsetSuffix => 'Dropset';

  @override
  String get setTypeSupersetSuffix => 'Superinsieme';

  @override
  String get setTypeOtherSuffix => 'Altro';

  @override
  String warmupSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serie di riscaldamento',
      one: '1 set di riscaldamento',
    );
    return '$_temp0';
  }

  @override
  String workSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count set di lavoro',
      one: '1 set da lavoro',
    );
    return '$_temp0';
  }

  @override
  String failureSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count set di errori',
      one: '1 set di errori',
    );
    return '$_temp0';
  }

  @override
  String dropsetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dropset',
      one: '1 set di gocce',
    );
    return '$_temp0';
  }

  @override
  String supersetSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count superset',
      one: '1 superserie',
    );
    return '$_temp0';
  }

  @override
  String otherSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count altri set',
      one: '1 altro set',
    );
    return '$_temp0';
  }

  @override
  String warmupCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count riscaldamento',
      one: '1 riscaldamento',
    );
    return '$_temp0';
  }

  @override
  String workCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lavoro',
      one: '1 opera',
    );
    return '$_temp0';
  }

  @override
  String failureCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errore',
      one: '1 fallimento',
    );
    return '$_temp0';
  }

  @override
  String dropsetCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dropset',
      one: '1 set di gocce',
    );
    return '$_temp0';
  }

  @override
  String supersetCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count superset',
      one: '1 superserie',
    );
    return '$_temp0';
  }

  @override
  String otherCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count altro',
      one: '1 altro',
    );
    return '$_temp0';
  }

  @override
  String get shareExercisesLabel => 'esercizi';

  @override
  String get shareSetsLabel => 'insiemi';

  @override
  String get shareSetLabel => 'impostato';

  @override
  String get tabBaseFoods => 'Alimenti base';

  @override
  String get baseFoodsEmptyState =>
      'Questa sezione sarà presto riempita con un elenco curato di alimenti base come frutta, verdura e altro ancora.';

  @override
  String get noBrand => 'Nessun marchio';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String backupFileSubject(String timestamp) {
    return 'Backup dell\'app Train Libre - $timestamp';
  }

  @override
  String foodItemSubtitle(String brand, int calories) {
    return '$brand - $calories kcal / 100 g';
  }

  @override
  String foodListSubtitle(int grams, String time) {
    return '${grams}g - $time';
  }

  @override
  String foodListTrailingKcal(int calories) {
    return '$calories kcal';
  }

  @override
  String waterListTrailingMl(int milliliters) {
    return '$milliliters ml';
  }

  @override
  String get exerciseCatalogTitle => 'Catalogo degli esercizi';

  @override
  String get filterByMuscle => 'Filtra per gruppo muscolare';

  @override
  String get noExercisesFound => 'Nessun esercizio trovato.';

  @override
  String get noDescriptionAvailable => 'Nessuna descrizione disponibile.';

  @override
  String get filterByCategory => 'Filtra per categoria';

  @override
  String get edit => 'Modificare';

  @override
  String get repsLabelShort => 'ripetizioni';

  @override
  String get titleNewRoutine => 'Nuova routine';

  @override
  String get titleEditRoutine => 'Modifica routine';

  @override
  String get validatorPleaseEnterRoutineName =>
      'Inserisci un nome per la routine.';

  @override
  String get snackbarRoutineCreated =>
      'Routine creata. Ora aggiungi alcuni esercizi.';

  @override
  String get snackbarRoutineSaved => 'Routine salvata.';

  @override
  String get saveAsRoutineButton => 'Salva come routine';

  @override
  String get saveAsRoutineTitle => 'Salva come routine';

  @override
  String get saveAsRoutinePrompt => 'Inserisci un nome per la nuova routine:';

  @override
  String get saveAsRoutineSuccess => 'Routine creata!';

  @override
  String get snackbarRoutineSavedAction => 'Visualizzazione';

  @override
  String get formFieldRoutineName => 'Nome della routine';

  @override
  String get emptyStateAddFirstExercise => 'Aggiungi il tuo primo esercizio.';

  @override
  String setCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imposta',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String get fabAddExercise => 'Aggiungi esercizio';

  @override
  String get kgLabelShort => 'kg';

  @override
  String get drawerExerciseCatalog => 'Catalogo degli esercizi';

  @override
  String get lastWorkoutTitle => 'Ultimo allenamento';

  @override
  String get repeatButton => 'Ripetere';

  @override
  String get weightHistoryTitle => 'Cronologia del peso';

  @override
  String get hideSummary => 'Nascondi riepilogo';

  @override
  String get showSummary => 'Mostra riepilogo';

  @override
  String get exerciseDataAttribution => 'Dati dell\'esercizio da wger';

  @override
  String get duplicate => 'Duplicato';

  @override
  String deleteRoutineConfirmContent(String routineName) {
    return 'Vuoi eliminare definitivamente la routine \"$routineName\"?';
  }

  @override
  String get editPauseTimeTitle => 'Modifica la durata della pausa';

  @override
  String get pauseInSeconds => 'Pausa in pochi secondi';

  @override
  String get editPauseTime => 'Modifica pausa';

  @override
  String pauseDuration(int seconds) {
    return '$seconds seconda pausa';
  }

  @override
  String maxPauseDuration(int seconds) {
    return 'Pausa fino a $seconds s';
  }

  @override
  String get deleteWorkoutConfirmContent =>
      'Sei sicuro di voler eliminare definitivamente questo registro degli allenamenti?';

  @override
  String get removeExercise => 'Rimuovi esercizio';

  @override
  String get deleteExerciseConfirmTitle => 'Rimuovere l\'esercizio?';

  @override
  String deleteExerciseConfirmContent(String exerciseName) {
    return 'Sei sicuro di voler rimuovere \"$exerciseName\" da questa routine?';
  }

  @override
  String get doneButtonLabel => 'Fatto';

  @override
  String get setRestTimeButton => 'Imposta il tempo di riposo';

  @override
  String get deleteExerciseButton => 'Elimina esercizio';

  @override
  String get restOverLabel => 'La pausa è finita';

  @override
  String get workoutRunningLabel => 'L’allenamento è attivo…';

  @override
  String get continueButton => 'Continuare';

  @override
  String get discardButton => 'Scartare';

  @override
  String get workoutStatsTitle => 'Formazione (7 giorni)';

  @override
  String get workoutsLabel => 'Allenamenti';

  @override
  String get durationLabel => 'Durata';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get setsLabel => 'Imposta';

  @override
  String get muscleSplitLabel => 'Divisione muscolare';

  @override
  String get snackbar_could_not_open_open_link =>
      'Impossibile aprire il collegamento';

  @override
  String get chart_no_data_for_period =>
      'Nessun dato grafico per questo periodo';

  @override
  String get amount_in_milliliters => 'Quantità in millilitri';

  @override
  String get amount_in_grams => 'Quantità in grammi';

  @override
  String get meal_label => 'Pasto';

  @override
  String get add_to_water_intake => 'Aggiungere all\'assunzione di acqua';

  @override
  String get create_exercise_screen_title => 'Crea esercizio personalizzato';

  @override
  String get exercise_name_label => 'Nome dell\'esercizio';

  @override
  String get category_label => 'Categoria';

  @override
  String get description_optional_label => 'Descrizione (facoltativa)';

  @override
  String get primary_muscles_label => 'Muscoli primari';

  @override
  String get primary_muscles_hint => 'per esempio. Petto, Tricipiti';

  @override
  String get secondary_muscles_label => 'Muscoli secondari (facoltativo)';

  @override
  String get secondary_muscles_hint => 'per esempio. Spalle';

  @override
  String get fluidNameLabel => 'Nome';

  @override
  String get sugarPer100mlLabel => 'Zucchero (g/100ml)';

  @override
  String get set_type_normal => 'Normale';

  @override
  String get set_type_warmup => 'Riscaldamento';

  @override
  String get set_type_failure => 'Fallimento';

  @override
  String get set_type_dropset => 'Dropset';

  @override
  String get set_reps_hint => '8-12';

  @override
  String get data_export_button => 'Esportare';

  @override
  String get data_import_button => 'Importare';

  @override
  String get snackbar_button_ok => 'OK';

  @override
  String get measurement_session_detail_view =>
      'Visualizzazione dettagliata della sessione di misurazione';

  @override
  String get unit_grams => 'G';

  @override
  String get unit_kcal => 'kcal';

  @override
  String get delete_profile_picture_button => 'Elimina l\'immagine del profilo';

  @override
  String get attribution_title => 'Attribuzione';

  @override
  String get add_liquid_title => 'Aggiungi fluido';

  @override
  String get add_button => 'Aggiungere';

  @override
  String get discard_button => 'Scartare';

  @override
  String get continue_workout_button => 'Continuare';

  @override
  String get soon_available_snackbar =>
      'Questa schermata sarà presto disponibile';

  @override
  String get start_button => 'Inizio';

  @override
  String get today_overview_text => 'OGGI IN FOCUS';

  @override
  String get quick_add_text => 'AGGIUNTA VELOCE';

  @override
  String get scann_barcode_capslock => 'Scansiona il codice a barre';

  @override
  String get protocol_today_capslock => 'IL PROTOCOLLO DI OGGI';

  @override
  String get my_plans_capslock => 'I MIEI PIANI';

  @override
  String get overview_capslock => 'PANORAMICA';

  @override
  String get manage_all_plans => 'Gestisci tutti i piani';

  @override
  String get workoutSectionStart => 'Inizio';

  @override
  String get workoutSectionMyPlans => 'I miei piani';

  @override
  String get workoutSectionHistoryLibrary => 'Storia e biblioteca';

  @override
  String get workoutAllRoutines => 'Tutte le routine';

  @override
  String get workoutEntryWorkouts => 'Allenamenti';

  @override
  String get free_training => 'formazione gratuita';

  @override
  String get my_consistency => 'LA MIA COERENZA';

  @override
  String get calendar_currently_not_available =>
      'La visualizzazione del calendario sarà presto disponibile.';

  @override
  String get in_depth_analysis => 'ANALISI APPROFONDITA';

  @override
  String get body_measurements => 'Misure del corpo';

  @override
  String get measurements_description =>
      'Analizzare il peso, la percentuale di grasso corporeo e la circonferenza.';

  @override
  String get nutrition_description => 'Valuta macro, calorie e tendenze.';

  @override
  String get training_analysis => 'Analisi della formazione';

  @override
  String get training_analysis_description =>
      'Tieni traccia del volume, della forza e della progressione.';

  @override
  String get load_dots => 'caricamento...';

  @override
  String get profile_capslock => 'PROFILO';

  @override
  String get settings_capslock => 'IMPOSTAZIONI';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsUpdateFoodDatabase => 'Aggiorna i database';

  @override
  String get settingsUpdateFoodDatabaseSubtitle =>
      'Verifica manualmente gli aggiornamenti dei database di alimenti ed esercizi.';

  @override
  String get settingsUpdateFoodDatabaseSuccess =>
      'Database aggiornati con successo.';

  @override
  String settingsUpdateFoodDatabaseError(String error) {
    return 'Errore durante l\'aggiornamento dei database: $error';
  }

  @override
  String get settingsGuidedTourSectionTitle => 'Visita guidata';

  @override
  String get settingsRestartAppTourTitle => 'Riavvia il tour dell\'app';

  @override
  String get settingsRestartAppTourSubtitle =>
      'Esegui nuovamente la breve procedura dettagliata in-app.';

  @override
  String get my_goals => 'I miei obiettivi';

  @override
  String get my_goals_description => 'Regola calorie, macronutrienti e acqua.';

  @override
  String get backup_and_import => 'Backup e importazione dei dati';

  @override
  String get backup_and_import_description =>
      'Crea backup, ripristina e importa dati.';

  @override
  String get feedbackReportSettingsSectionTitle => 'Supporto';

  @override
  String get feedbackReportSettingsEntryTitle => 'Invia feedback';

  @override
  String get feedbackReportSettingsEntrySubtitle =>
      'Crea un report diagnostico locale e scegli come condividerlo.';

  @override
  String get about_and_legal_capslock => 'INFORMAZIONI E LEGALE';

  @override
  String get feedbackReportScreenTitle => 'Rapporto di feedback';

  @override
  String get feedbackReportPrivacyTitle => 'La privacy prima di tutto';

  @override
  String get feedbackReportPrivacyBody =>
      'Questo report viene generato localmente sul tuo dispositivo. Niente viene inviato automaticamente. Solo ciò che vedi nell\'anteprima viene incluso quando scegli di copiare, salvare, condividere o inviare tramite email. L\'e-mail apre una bozza a feedback@schotte.me in modo che tu possa rivedere, modificare o annullare prima dell\'invio.';

  @override
  String get feedbackReportOptionalNoteTitle => 'Nota facoltativa';

  @override
  String get feedbackReportOptionalNoteLabel => 'La tua nota (facoltativo)';

  @override
  String get feedbackReportOptionalNoteHint =>
      'Descrivi cosa è successo, il comportamento previsto e i passaggi da riprodurre.';

  @override
  String get feedbackReportIncludeSectionTitle => 'Includi nel rapporto';

  @override
  String get feedbackReportIncludeAdaptiveNutrition =>
      'Diagnostica nutrizionale adattiva';

  @override
  String get feedbackReportIncludeBackupRestore =>
      'Backup/ripristino diagnostica';

  @override
  String get feedbackReportIncludeUserNote => 'Nota per l\'utente';

  @override
  String get feedbackReportGeneratePreview => 'Genera anteprima';

  @override
  String get feedbackReportPreviewTitle => 'Anteprima';

  @override
  String get feedbackReportActionCopy => 'Copia';

  @override
  String get feedbackReportActionSave => 'Salva';

  @override
  String get feedbackReportActionShare => 'Condividere';

  @override
  String get feedbackReportActionEmail => 'E-mail';

  @override
  String get feedbackReportCopied => 'Rapporto copiato negli appunti.';

  @override
  String get feedbackReportSavedToTemporaryFile =>
      'Salvato in un file di rapporto temporaneo.';

  @override
  String get feedbackReportShareCompleted => 'Foglio di condivisione aperto.';

  @override
  String get feedbackReportShareCanceled => 'Condivisione annullata.';

  @override
  String get feedbackReportEmailOpenFailed =>
      'Impossibile aprire l\'app di posta elettronica.';

  @override
  String get feedbackReportEmailSubject =>
      'Rapporto di feedback di Train Libre';

  @override
  String get feedbackReportReportTitle => 'Rapporto di feedback di Train Libre';

  @override
  String get feedbackReportReportGeneratedAt => 'Generato';

  @override
  String get feedbackReportReportAppVersion => 'Versione dell\'app';

  @override
  String get feedbackReportReportBuildNumber => 'Numero di costruzione';

  @override
  String get feedbackReportReportPlatform => 'Piattaforma';

  @override
  String get feedbackReportReportOsVersion => 'Versione del sistema operativo';

  @override
  String get feedbackReportUnavailable => 'non disponibile';

  @override
  String get feedbackReportSectionUserNote => 'Nota per l\'utente';

  @override
  String get feedbackReportSectionAdaptiveNutrition =>
      'Diagnostica nutrizionale adattiva';

  @override
  String get feedbackReportSectionBackupRestore =>
      'Backup/ripristino diagnostica';

  @override
  String get attribution_and_license => 'Attribuzione e licenze';

  @override
  String get data_from_off_and_wger =>
      'Dati provenienti da Open Food Facts e wger.';

  @override
  String get app_version => 'Versione dell\'app';

  @override
  String get all_measurements => 'TUTTE LE MISURE';

  @override
  String get all_measurements_no_cap => 'Tutte le misurazioni';

  @override
  String get date_and_time_of_measurement => 'Data e ora della misurazione';

  @override
  String get onbWelcomeTitle => 'Benvenuti su Train Libre';

  @override
  String get onbWelcomeBody =>
      'Iniziamo definendo obiettivi personali per guidare l’allenamento e l’alimentazione.';

  @override
  String get onbTrackTitle => 'Tieni traccia di tutto';

  @override
  String get onbTrackBody =>
      'Registra nutrizione, allenamenti e misurazioni, tutto in un unico posto.';

  @override
  String get onbPrivacyTitle => 'Prima offline e privacy';

  @override
  String get onbPrivacyBody =>
      'I tuoi dati rimangono sul dispositivo. Nessun account cloud, nessuna sincronizzazione in background.';

  @override
  String get onbFinishTitle => 'Tutto pronto';

  @override
  String get onbFinishBody =>
      'Sei pronto per esplorare l\'app. Puoi modificare le impostazioni in qualsiasi momento.';

  @override
  String get onbFinishCta => 'Andiamo!';

  @override
  String get onbShowTutorialAgain => 'Mostra di nuovo l\'onboarding';

  @override
  String get appTourOfferTitle => 'Vuoi fare un breve tour dell\'app?';

  @override
  String get appTourOfferBody =>
      'Ottieni una breve panoramica delle principali aree dell\'app. Puoi saltare ora e riavviare più tardi in Impostazioni.';

  @override
  String get appTourOfferStart => 'Inizia il giro';

  @override
  String get appTourOfferSkip => 'Forse più tardi';

  @override
  String get appTourSkip => 'Saltare';

  @override
  String get appTourNext => 'Prossimo';

  @override
  String get appTourDone => 'Fatto';

  @override
  String get appTourStepNavigationTitle => 'Navigazione principale';

  @override
  String get appTourStepNavigationBody =>
      'Utilizza le schede in basso per spostarti tra Diario, Allenamento, Statistiche e Nutrizione.';

  @override
  String get appTourStepQuickActionsTitle => 'Azioni rapide';

  @override
  String get appTourStepQuickActionsBody =>
      'Tocca il pulsante più per aggiungere rapidamente cibo, liquidi, misurazioni, allenamenti e altro ancora.';

  @override
  String get appTourStepDiaryTitle => 'Diario';

  @override
  String get appTourStepDiaryBody =>
      'Il diario è la tua panoramica quotidiana. Tieni traccia dei pasti, dell\'idratazione, degli integratori e della tua giornata a colpo d\'occhio.';

  @override
  String get appTourStepWorkoutTitle => 'Allenamento';

  @override
  String get appTourStepWorkoutBody =>
      'Allenamento è il luogo in cui inizi le sessioni, gestisci le routine e rivedi la cronologia degli allenamenti.';

  @override
  String get appTourStepNutritionTitle => 'Nutrizione';

  @override
  String get appTourStepNutritionBody =>
      'La nutrizione ti aiuta a pianificare i pasti, rivedere gli obiettivi e accedere a strumenti come i modelli di pasto.';

  @override
  String get appTourStepStatisticsTitle => 'Statistiche';

  @override
  String get appTourStepStatisticsBody =>
      'Le statistiche mostrano tendenze e progressi in modo che tu possa capire come cambiano i tuoi dati nel tempo.';

  @override
  String get onbSetGoalsCta => 'Stabilisci obiettivi';

  @override
  String get onbHeaderTitle => 'Esercitazione';

  @override
  String get onbHeaderSkip => 'Saltare';

  @override
  String get onbBack => 'Indietro';

  @override
  String get onbNext => 'Prossimo';

  @override
  String get onbGuideTitle => 'Come funziona questo tutorial';

  @override
  String get onbGuideBody =>
      'Scorri tra le diapositive o utilizza Successivo. Tocca i pulsanti su ciascuna diapositiva per provare le funzionalità. Puoi terminare in qualsiasi momento con Salta.';

  @override
  String get onbCtaOpenNutrition => 'Nutrizione aperta';

  @override
  String get onbCtaLearnMore => 'Saperne di più';

  @override
  String get onbBadgeDone => 'Fatto';

  @override
  String get onbTipSetGoals => 'Suggerimento: modifica prima gli obiettivi';

  @override
  String get onbTipAddEntry => 'Suggerimento: aggiungi una voce oggi';

  @override
  String get onbTipLocalControl => 'Puoi controllare tutti i dati localmente';

  @override
  String get onbTrackHowBody =>
      'Come registrare la nutrizione:\n• Aprire la scheda Cibo.\n• Tocca il pulsante +.\n• Cerca prodotti o scansiona un codice a barre.\n• Modificare porzione e tempo.\n• Salva sul tuo diario.';

  @override
  String get onbMeasureTitle => 'Tieni traccia delle misurazioni';

  @override
  String get onbMeasureBody =>
      'Come aggiungere misure:\n• Aprire la scheda Statistiche.\n• Tocca il pulsante +.\n• Scegli un parametro (ad esempio peso, vita, grasso corporeo).\n• Immettere valore e ora.\n• Salva nella tua cronologia.';

  @override
  String get onbTipMeasureToday =>
      'Suggerimento: aggiungi il peso di oggi per iniziare il grafico';

  @override
  String get onbTrainTitle => 'Allenati con routine';

  @override
  String get onbTrainBody =>
      'Crea una routine e inizia un allenamento:\n• Apri la scheda Treno.\n• Tocca Crea routine per aggiungere esercizi e serie.\n• Salvare la routine.\n• Tocca Avvia per iniziare oppure utilizza “Inizia allenamento a vuoto”.';

  @override
  String get onbTipStartWorkout =>
      'Suggerimento: avvia un allenamento vuoto per registrare una sessione veloce';

  @override
  String get unitsSection => 'unità';

  @override
  String get weightUnit => 'Unità di peso';

  @override
  String get lengthUnit => 'unità di lunghezza';

  @override
  String get comingSoon => 'Prossimamente';

  @override
  String get noFavorites => 'Nessun preferito';

  @override
  String get nothingTrackedYet => 'Niente ancora tracciato';

  @override
  String snackbarBarcodeNotFound(String barcode) {
    return 'Nessun prodotto trovato per il codice a barre \"$barcode\".';
  }

  @override
  String get categoryHint => 'per esempio. Petto, schiena, gambe...';

  @override
  String get validatorPleaseEnterCategory => 'Inserisci una categoria.';

  @override
  String get dialogEnterPasswordImport =>
      'Inserisci la password per importare il backup';

  @override
  String get dataManagementBackupTitle => 'Backup dei dati di Train Libre';

  @override
  String get dataManagementBackupDescription =>
      'Esegui il backup o ripristina tutti i dati dell\'app. Ideale per cambiare dispositivo.';

  @override
  String get exportEncrypted => 'Esporta crittografato';

  @override
  String get dialogPasswordForExport =>
      'Password per l\'esportazione crittografata';

  @override
  String get snackbarEncryptedBackupShared => 'Backup crittografato condiviso.';

  @override
  String get exportFailed => 'Esportazione non riuscita.';

  @override
  String get csvExportTitle => 'Esportazione dati (CSV)';

  @override
  String get csvExportDescription =>
      'Esporta parti dei tuoi dati come file CSV per l\'analisi in altri programmi.';

  @override
  String get snackbarSharingNutrition => 'Condivido il diario nutrizionale...';

  @override
  String get snackbarExportFailedNoEntries =>
      'Esportazione non riuscita. Potrebbero non esserci ancora voci.';

  @override
  String get snackbarSharingMeasurements => 'Condivisione delle misurazioni...';

  @override
  String get snackbarSharingWorkouts =>
      'Condivisione della cronologia degli allenamenti...';

  @override
  String get mapExercisesTitle => 'Esercizi sulla mappa';

  @override
  String get mapExercisesDescription =>
      'Mappa i nomi sconosciuti dai log agli esercizi wger.';

  @override
  String get mapExercisesButton => 'Inizia la mappatura';

  @override
  String get autoBackupTitle => 'Backup automatici';

  @override
  String get autoBackupDescription =>
      'Salva periodicamente un backup nella cartella. Cartella corrente:';

  @override
  String get autoBackupDefaultFolder =>
      'Documenti/backup dell\'app (impostazione predefinita)';

  @override
  String get autoBackupChooseFolder => 'Scegli Cartella';

  @override
  String get autoBackupCopyPath => 'Copia percorso';

  @override
  String get autoBackupRunNow =>
      'Controlla ed esegui il backup automatico adesso';

  @override
  String get autoBackupRequestAccessSubtitle =>
      'Per eseguire il backup automatico dei tuoi dati, Train Libre necessita dell\'accesso a una cartella di tua scelta. I tuoi backup verranno archiviati lì.';

  @override
  String get snackbarAutoBackupSuccess => 'Backup automatico completato.';

  @override
  String get snackbarAutoBackupFailed =>
      'Il backup automatico non è riuscito o è stato annullato.';

  @override
  String get localDataDeletionCardTitle => 'Dati dell\'app locale';

  @override
  String get localDataDeletionCardDescription =>
      'Elimina definitivamente i dati di proprietà dell\'utente memorizzati su questo dispositivo e ripristina Train Libre a un nuovo stato locale.';

  @override
  String get deleteAllLocalAppData => 'Elimina tutti i dati dell\'app locale';

  @override
  String get localDataDeletionConfirmTitle =>
      'Eliminare tutti i dati dell\'app locale?';

  @override
  String get localDataDeletionConfirmBody =>
      'Questa operazione elimina definitivamente allenamenti, registri nutrizionali, misurazioni, integratori, impostazioni/stato, dati analitici memorizzati nella cache e dati delle app locali memorizzati localmente.\n\nCiò non elimina i dati già esportati su Apple Health o Health Connect.\n\nCiò non elimina i dati del provider esterno o le origini del catalogo pubblico remoto. Le risorse dell\'app in bundle e i cataloghi predefiniti richiesti vengono mantenuti o ricreati in modo che l\'app possa essere avviata dopo il ripristino.';

  @override
  String get localDataDeletionTypeDeleteLabel =>
      'Digita CANCELLA per confermare';

  @override
  String get localDataDeletionSuccessTitle => 'Dati locali cancellati';

  @override
  String get localDataDeletionSuccessBody =>
      'Train Libre tornerà al suo stato di configurazione iniziale.';

  @override
  String get localDataDeletionFailed =>
      'Impossibile eliminare i dati locali. Per favore riprova.';

  @override
  String get noUnknownExercisesFound => 'Nessun esercizio sconosciuto trovato';

  @override
  String snackbarAutoBackupFolderSet(String path) {
    return 'Impostazione cartelle per il backup automatico:\n$path';
  }

  @override
  String get snackbarPathCopied => 'Percorso copiato';

  @override
  String get passwordLabel => 'Password';

  @override
  String get descriptionLabel => 'Descrizione';

  @override
  String get involvedMuscles => 'Muscoli coinvolti';

  @override
  String get primaryLabel => 'Primario:';

  @override
  String get secondaryLabel => 'Secondario:';

  @override
  String get noMusclesSpecified => 'Nessun muscolo specificato.';

  @override
  String get frontLabel => 'Fronte';

  @override
  String get backLabel => 'Indietro';

  @override
  String get noSelection => 'Nessuna selezione';

  @override
  String get selectButton => 'Selezionare';

  @override
  String get applyingChanges => 'Applicazione delle modifiche...';

  @override
  String get applyMapping => 'Applica la mappatura';

  @override
  String get mappingSuggestions => 'Suggerimenti';

  @override
  String get mappingSuggestionsEmpty =>
      'Nessun esercizio corrispondente trovato';

  @override
  String get personalData => 'Dati personali';

  @override
  String get personalDataCL => 'DATI PERSONALI';

  @override
  String get macroDistribution => 'Distribuzione dei macronutrienti';

  @override
  String get dialogFinishWorkoutBody =>
      'Sei sicuro di voler finire questo allenamento?';

  @override
  String get attributionText =>
      'Questa app utilizza dati provenienti da fonti esterne:\n\n● Dati e immagini degli esercizi da wger (wger.de), concesso in licenza con CC-BY-SA 4.0.\n\n● Database alimentare di Open Food Facts (openfoodfacts.org), disponibile sotto la licenza Open Database License (ODbL).';

  @override
  String get errorRoutineNotFound => 'Routine non trovata';

  @override
  String get workoutHistoryEmptyTitle => 'La tua cronologia è vuota';

  @override
  String get workoutSummaryTitle => 'Allenamento completato';

  @override
  String get workoutSummaryExerciseOverview => 'Panoramica degli esercizi';

  @override
  String get nutritionDiary => 'Diario';

  @override
  String get detailedNutrientGoals => 'Nutrienti dettagliati';

  @override
  String get detailedNutrientGoalsCL => 'NUTRIENTI DETTAGLIATI';

  @override
  String get supplementTrackerTitle => 'Monitoraggio degli integratori';

  @override
  String get supplementTrackerDescription =>
      'Tieni traccia di obiettivi, limiti e assunzione.';

  @override
  String get createSupplementTitle => 'Crea supplemento';

  @override
  String get supplementNameLabel => 'Nome del supplemento';

  @override
  String get defaultDoseLabel => 'Dose predefinita';

  @override
  String get unitLabel => 'Unità';

  @override
  String get dailyGoalLabel => 'Obiettivo giornaliero (facoltativo)';

  @override
  String get dailyLimitLabel => 'Limite giornaliero (facoltativo)';

  @override
  String get dailyProgressTitle => 'Progresso quotidiano';

  @override
  String get todaysLogTitle => 'Il diario di oggi';

  @override
  String get logIntakeTitle => 'Registra l\'assunzione';

  @override
  String get emptySupplementGoals =>
      'Imposta obiettivi o limiti per gli integratori per vedere i tuoi progressi qui.';

  @override
  String get emptySupplementLogs =>
      'Ancora nessuna assunzione registrata per oggi.';

  @override
  String get doseLabel => 'Dose';

  @override
  String get settingsDescription => 'Tema, unità, dati e altro ancora';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Leggero';

  @override
  String get themeDark => 'Buio';

  @override
  String get caffeinePrompt => 'Caffeina (facoltativa)';

  @override
  String get caffeineUnit => 'mg per 100 ml';

  @override
  String get profile => 'Profilo';

  @override
  String get measurementWeightCapslock => 'PESO CORPOREO';

  @override
  String get diary => 'Diario';

  @override
  String get analysis => 'Analisi';

  @override
  String get yesterday => 'Ieri';

  @override
  String get dayBeforeYesterday => 'Due giorni fa';

  @override
  String get statistics => 'Statistiche';

  @override
  String get workout => 'Allenamento';

  @override
  String get addFoodTitle => 'aggiungere cibo';

  @override
  String get nutritionExplorerTitle => 'Esploratore della nutrizione';

  @override
  String get myMeals => 'I miei pasti';

  @override
  String get myMealsCL => 'I MIEI PASTI';

  @override
  String get nutritionSectionTodayInFocus => 'Oggi al centro dell\'attenzione';

  @override
  String get nutritionSectionMyMeals => 'I miei pasti';

  @override
  String get nutritionSectionToolsAndLibrary => 'Strumenti e libreria';

  @override
  String get supplement_caffeine => 'Caffeina';

  @override
  String get supplement_creatine_monohydrate => 'Creatina monoidrato';

  @override
  String get manageSupplementsTitle => 'Gestire gli integratori';

  @override
  String get deleted => 'cancellato';

  @override
  String get operationNotAllowed => 'Questa operazione non è consentita';

  @override
  String get emptySupplements => 'Nessun supplemento disponibile';

  @override
  String get undo => 'Disfare';

  @override
  String get deleteSupplementConfirm =>
      'Sei sicuro di voler eliminare questo supplemento? Tutti i dati storici andranno persi.\n\nSuggerimento: puoi semplicemente annullarne la traccia modificando il supplemento.';

  @override
  String get fieldRequired => 'Necessario';

  @override
  String get unitNotSupported => 'Unità non supportata.';

  @override
  String get caffeineUnitLocked => 'Per la caffeina l\'unità è fissa: mg.';

  @override
  String get caffeineMustBeMg => 'La caffeina deve essere registrata in mg.';

  @override
  String get tabCatalogSearch => 'Catalogare';

  @override
  String get tabMeals => 'Pasti';

  @override
  String get emptyCategory => 'Nessuna voce';

  @override
  String get searchSectionBase => 'Alimenti base';

  @override
  String get searchSectionOther => 'Altri risultati';

  @override
  String get mealsComingSoonTitle => 'Pasti (disponibili a breve)';

  @override
  String get mealsComingSoonBody =>
      'Presto sarai in grado di creare i tuoi pasti da più cibi.';

  @override
  String get mealsEmptyTitle => 'Nessun modello di pasto salvato';

  @override
  String get mealsEmptyBody =>
      'Crea pasti per registrare rapidamente più alimenti contemporaneamente.';

  @override
  String get mealsEmptyBodyWithShortcut =>
      'Nel diario, utilizza l\'opzione \"Salva come pasto\" sotto la colazione o la cena per salvare le combinazioni alimentari comuni come modello rapido.';

  @override
  String get mealsCreateManually => 'Crea pasto manualmente';

  @override
  String get saveMealTemplateShortcut => 'Salva come pasto';

  @override
  String get mealsCreate => 'Crea pasto';

  @override
  String get mealsEdit => 'Modifica pasto';

  @override
  String get mealsDelete => 'Elimina pasto';

  @override
  String get mealsAddToDiary => 'Aggiungi cibo';

  @override
  String get mealNameLabel => 'Nome del pasto';

  @override
  String get mealNotesLabel => 'Note';

  @override
  String get mealIngredientsTitle => 'Ingredienti';

  @override
  String get mealAddIngredient => 'Aggiungi ingrediente';

  @override
  String get mealIngredientAmountLabel => 'Quantità';

  @override
  String get mealDeleteConfirmTitle => 'Elimina pasto';

  @override
  String mealDeleteConfirmBody(Object name) {
    return 'Sei sicuro di voler eliminare il pasto \'$name\'? Verranno rimossi anche tutti i suoi ingredienti.';
  }

  @override
  String mealAddedToDiary(Object name) {
    return 'Il pasto \'$name\' è stato aggiunto al tuo diario.';
  }

  @override
  String get mealSaved => 'Pasto salvato.';

  @override
  String get mealDeleted => 'Pasto eliminato.';

  @override
  String get confirm => 'Confermare';

  @override
  String get addMealToDiaryTitle => 'Aggiungi al diario';

  @override
  String get mealTypeLabel => 'Pasto';

  @override
  String get amountLabel => 'Quantità';

  @override
  String get mealAddedToDiarySuccess => 'Pasto aggiunto al diario';

  @override
  String get error => 'Errore';

  @override
  String get mealsViewTitle => 'pastiViewTitle';

  @override
  String get noNotes => 'Nessuna nota';

  @override
  String get ingredientsCapsLock => 'INGREDIENTI';

  @override
  String get nutritionSectionLabel => 'FATTI NUTRIZIONALI';

  @override
  String get nutritionCalculatedForCurrentAmounts => 'per le quantità attuali';

  @override
  String get startCapsLock => 'INIZIO';

  @override
  String get nutritionHubSubtitle =>
      'Scopri approfondimenti, monitora i pasti e pianifica la tua alimentazione qui presto.';

  @override
  String get nutritionHubTitle => 'Nutrizione';

  @override
  String get nutrition => 'Nutrizione';

  @override
  String get changeSetTypTitle => 'Cambia tipo di set';

  @override
  String get settingsVisualStyleTitle => 'Stile visivo';

  @override
  String get settingsVisualStyleStandard => 'Vetro smerigliato';

  @override
  String get settingsVisualStyleLiquid => 'Vetro liquido (fluido)';

  @override
  String get settingsVisualStyleLiquidDesc =>
      'Elementi dell\'interfaccia utente arrotondati e mobili';

  @override
  String get settingsMaterialColorsTitle => 'Colori dei materiali';

  @override
  String get settingsMaterialColorsSubtitle =>
      'Utilizza i colori dinamici di sistema (Material You) invece dell\'accento del marchio Train Libre';

  @override
  String get settingsFoodDbSectionTitle => 'Banca dati alimentare';

  @override
  String get settingsFoodDbRegionTitle => 'Regione del database';

  @override
  String get settingsFoodDbRegionSubtitle =>
      'Seleziona la regione del catalogo prodotti Open Food Facts utilizzata.';

  @override
  String get settingsFoodDbRegionCurrent => 'Regione attuale';

  @override
  String get settingsFoodDbRegionDialogTitle =>
      'Scegli la regione del database';

  @override
  String get settingsFoodDbRegionDialogSubtitle =>
      'Questo cambia la sorgente del catalogo Open Food Facts per la ricerca.';

  @override
  String get settingsFoodDbRegionSearchPlaceholder => 'Cerca regione...';

  @override
  String get settingsFoodDbRegionNoResults => 'Nessuna regione trovata';

  @override
  String get settingsFoodDbRegionIssueHint =>
      'Se il tuo Paese non è ancora nell\'elenco, non esitare ad aprire un problema su GitHub e richiedere supporto.';

  @override
  String get settingsFoodDbRegionGermany => 'Germania (DE)';

  @override
  String get settingsFoodDbRegionSwitzerland => 'Svizzera (CH)';

  @override
  String get settingsFoodDbRegionUnitedStates => 'Stati Uniti (US)';

  @override
  String get settingsFoodDbRegionFrance => 'Francia (FR)';

  @override
  String get settingsFoodDbRegionItaly => 'Italia (IT)';

  @override
  String get settingsFoodDbRegionJapan => 'Giappone (JP)';

  @override
  String get settingsFoodDbRegionAustria => 'Austria (AT)';

  @override
  String get settingsColorfulMacroBadgesTitle => 'Distintivi macro colorati';

  @override
  String get settingsColorfulMacroBadgesSubtitle =>
      'Utilizza anche il design del badge con codice colore della verifica AI nel diario.';

  @override
  String get settingsFoodDbRegionUnitedKingdom => 'Regno Unito (UK)';

  @override
  String settingsFoodDbRegionChanged(String region) {
    return 'Regione del database impostata su $region. Le modifiche verranno applicate al prossimo ciclo di importazione.';
  }

  @override
  String get searchBaseFoodHint => 'Cerca alimenti di base';

  @override
  String get searchNoHits => 'Nessun successo.';

  @override
  String get onbSubtitleWelcome =>
      'Il tuo strumento centrale per fitness, nutrizione e progresso.';

  @override
  String get onbBodyWelcome =>
      'Ti aiutiamo a definire e monitorare i tuoi obiettivi. Registra in modo efficiente allenamenti, alimentazione, integratori e misurazioni del corpo.';

  @override
  String get onbBodyNutritionVisual =>
      'Registra i pasti con pochi clic. Tieni d\'occhio calorie, macronutrienti e acqua per monitorare facilmente il tuo obiettivo.';

  @override
  String get onbBodyMeasurementsVisual =>
      'Visualizza i tuoi progressi. La tabella del peso e della circonferenza rende visibile il tuo successo e ti mantiene motivato.';

  @override
  String get onbBodyWorkoutVisual =>
      'Crea routine e inizia il tuo allenamento in pochi secondi. Set di tronchi, pesi e pause per la massima progressione.';

  @override
  String get onbTitleAppLayout => 'Navigazione e aggiunta rapida';

  @override
  String get onbBodyAppLayout =>
      'La barra inferiore consente il passaggio rapido da un\'area all\'altra. Utilizza il pulsante grande [+] per registrare tutto all\'istante.';

  @override
  String get dataHubTitle => 'Hub dati';

  @override
  String get resumeButton => 'Riprendere';

  @override
  String get onboardingWelcomeTitle => 'Benvenuti su Train Libre';

  @override
  String get onboardingWelcomeSubtitle =>
      'Impostiamo il tuo profilo per ottenere i migliori risultati.';

  @override
  String get onboardingMissionTitle => 'La Nostra Missione';

  @override
  String get onboardingMissionBody =>
      'Train Libre è per i bodybuilder naturali dedicati che richiedono progressi basati sulla scienza e sui dati.';

  @override
  String get onboardingFeatureWorkoutTitle => 'Tracker allenamenti';

  @override
  String get onboardingFeatureWorkoutBody =>
      'Registra le serie (RIR/RPE) e segui il recupero muscolare.';

  @override
  String get onboardingFeatureTdeeTitle => 'TDEE adattivo';

  @override
  String get onboardingFeatureTdeeBody =>
      'Un filtro di Kalman integrato calcola il tuo reale consumo calorico.';

  @override
  String get onboardingFeatureNutritionTitle => 'Nutrizione e acqua';

  @override
  String get onboardingFeatureNutritionBody =>
      'Traccia macro, acqua e usa il riconoscimento immagini IA opzionale.';

  @override
  String get onboardingFeaturePrivacyTitle => '100% privato e locale';

  @override
  String get onboardingFeaturePrivacyBody =>
      'Nessun account, nessun cloud obbligatorio. I tuoi dati appartengono a te.';

  @override
  String get onboardingSettingsHint =>
      'Tutte le impostazioni possono essere modificate in seguito in qualsiasi momento nelle Impostazioni.';

  @override
  String get adaptiveRatePerWeekLabel => 'Tasso target settimanale';

  @override
  String get onboardingNameTitle => 'Come ti chiami?';

  @override
  String get onboardingNameLabel => 'Il tuo nome';

  @override
  String get onboardingNameError => 'Per favore inserisci il tuo nome';

  @override
  String get onboardingDobTitle => 'Quando sei nato?';

  @override
  String get onboardingDobLabel => 'Data di nascita';

  @override
  String get onboardingDobError => 'Seleziona la tua data di nascita';

  @override
  String get onboardingWeightTitle => 'Peso attuale';

  @override
  String get onboardingWeightLabel => 'Peso';

  @override
  String get onboardingWeightError => 'Inserisci un peso valido';

  @override
  String get onboardingGoalsTitle => 'I tuoi obiettivi nutrizionali';

  @override
  String get onboardingGoalsSubtitle =>
      'Puoi modificarli in seguito nelle impostazioni.';

  @override
  String get onboardingGoalCalories => 'Calorie giornaliere (kcal)';

  @override
  String get onboardingGoalProtein => 'Proteine ​​(g)';

  @override
  String get onboardingGoalCarbs => 'Carboidrati (g)';

  @override
  String get onboardingGoalFat => 'Grassi (g)';

  @override
  String get onboardingGoalWater => 'Acqua';

  @override
  String get onboardingNext => 'Prossimo';

  @override
  String get onboardingBack => 'Indietro';

  @override
  String get onboardingFinish => 'Inizia il monitoraggio';

  @override
  String get onboardingAiHealthTitle => 'IA e salute';

  @override
  String get onboardingAiHealthSubtitle =>
      'Configurazione facoltativa: configura il riconoscimento pasti tramite IA con BYOK (Bring Your Own Key) e scegli quali dati sanitari Train Libre può leggere.';

  @override
  String get onboardingOpenSettings => 'Apri';

  @override
  String get onboardingUnitSystemTitle => 'Scegli il tuo sistema di unità';

  @override
  String get onboardingUnitSystemSubtitle =>
      'Puoi modificarlo in seguito in Impostazioni.';

  @override
  String get onboardingUnitMetric => 'Metrico';

  @override
  String get onboardingUnitMetricSubtitle => 'chilogrammi, centimetri, ml';

  @override
  String get onboardingUnitImperial => 'Imperiale';

  @override
  String get onboardingUnitImperialSubtitle => 'libbre, pollici, fl oz';

  @override
  String get onboardingHeightLabel => 'Altezza';

  @override
  String get onboardingGenderLabel => 'Genere';

  @override
  String get onboardingBioDataInfo =>
      'La tua età e il sesso biologico determinano le finestre di recupero di base del modello di recupero muscolare e alimentano gli algoritmi della tua Sleep Health Engine.';

  @override
  String get onboardingMeasurementsTitle => 'Misure e baseline';

  @override
  String get onboardingMeasurementsSubtitle =>
      'Imposta la tua baseline attuale per la raccomandazione adattiva.';

  @override
  String get onboardingMeasurementsDisclaimer =>
      'Puoi inserire e registrare peso, grasso corporeo e altre misure in qualsiasi momento nella dashboard.';

  @override
  String onboardingWaterNeedLabel(String unit) {
    return 'Fabbisogno d\'acqua ($unit)';
  }

  @override
  String get genderMale => 'Maschio';

  @override
  String get genderFemale => 'Femmina';

  @override
  String get genderDiverse => 'Diverso';

  @override
  String get vegan => 'Vegano';

  @override
  String get vegetarian => 'Vegetariano';

  @override
  String get ingredients => 'Ingredienti';

  @override
  String get aiSettingsTitle => 'Riconoscimento pasti tramite IA';

  @override
  String get aiSettingsDescription =>
      'Configura il rilevamento dei pasti assistito da IA.';

  @override
  String get aiProviderSection => 'Fornitore di intelligenza artificiale';

  @override
  String get aiProviderLabel => 'Fornitore';

  @override
  String get aiApiKeySection => 'Chiave API';

  @override
  String get aiApiKeyLabel => 'Chiave API';

  @override
  String get aiApiKeyHint => 'Incolla qui la tua chiave API';

  @override
  String get aiSaveKey => 'Salva chiave';

  @override
  String get aiTestConnection => 'Test';

  @override
  String get aiTestSuccess => 'Connessione riuscita!';

  @override
  String get aiKeySaved => 'Chiave API salvata in modo sicuro.';

  @override
  String get aiPrivacySection => 'Privacy AI';

  @override
  String get aiPrivacyDisclosure =>
      'Immagini, testo e prompt generati vengono inviati al provider AI selezionato solo quando utilizzi un\'azione AI. La conservazione e l\'elaborazione del fornitore seguono i termini di tale fornitore. La tua chiave API è archiviata crittografata solo su questo dispositivo.';

  @override
  String get aiMealCapture => 'Pasto AI';

  @override
  String get aiCaptureTitle => 'Cattura pasto AI';

  @override
  String get aiCaptureTabPhoto => 'Foto';

  @override
  String get aiCaptureTabText => 'Testo';

  @override
  String get aiCapturePhotoHint =>
      'Scatta o seleziona fino a 4 foto del tuo pasto.';

  @override
  String get aiCaptureTextHint =>
      'Descrivi il tuo pasto (es. \"Pollo alla griglia con riso e insalata\")...';

  @override
  String get aiAnalyzeButton => 'Analizzare';

  @override
  String get aiAnalyzing => 'Analizzando il tuo pasto...';

  @override
  String get aiReviewTitle => 'Suggerimenti per la revisione';

  @override
  String aiReviewFoundItems(int count) {
    return 'L\'intelligenza artificiale ha trovato $count elementi';
  }

  @override
  String get aiReviewNoMatch => 'Nessuna corrispondenza: tocca per cercare';

  @override
  String get aiReviewConfidence => 'Fiducia';

  @override
  String get aiReviewAddItem => 'Aggiungi l\'articolo manualmente';

  @override
  String get aiReviewReplaceItem => 'Sostituisci l\'articolo';

  @override
  String get aiReviewSaveToDiary => 'Salva nel diario';

  @override
  String get aiReviewFeedbackHint =>
      'Descrivi cosa ha sbagliato l\'intelligenza artificiale...';

  @override
  String get aiReviewRetryButton => 'Riprova con feedback';

  @override
  String get aiReviewFeedbackSection => 'Correzione';

  @override
  String get aiErrorNoKey =>
      'Nessuna chiave API configurata. Impostane uno in Impostazioni → Acquisizione pasto AI.';

  @override
  String get aiErrorNetwork =>
      'Errore di rete. Controlla la connessione e riprova.';

  @override
  String get aiErrorAuth =>
      'Autenticazione non riuscita. Controlla la tua chiave API.';

  @override
  String get aiErrorParse =>
      'Impossibile comprendere la risposta dell\'IA. Per favore riprova.';

  @override
  String get aiErrorRateLimit =>
      'Troppe richieste. Per favore aspetta un momento.';

  @override
  String get aiEnableTitle => 'Abilita funzionalità AI';

  @override
  String get aiEnableSubtitle =>
      'Consente l\'uso dell\'intelligenza artificiale per il riconoscimento dei pasti. Disabilitando questa opzione si nascondono tutti i pulsanti AI nell\'app.';

  @override
  String get aiCustomInstructionsTitle =>
      'Istruzioni globali sull\'intelligenza artificiale';

  @override
  String get aiCustomInstructionsSubtitle =>
      'Fornisci all\'IA regole fisse (ad esempio allergie, cibi vietati come \"niente ciotole\" o intolleranze) da seguire ad ogni cattura.';

  @override
  String get aiValidationNoMatchedItemsSaveYet =>
      'Nessun elemento corrispondente può ancora essere salvato.';

  @override
  String get aiValidationNoMatchedIngredientsSaveYet =>
      'Nessun ingrediente abbinato può ancora essere salvato.';

  @override
  String get aiValidationSomeItemsNeedReviewTitle =>
      'Alcuni articoli necessitano di revisione';

  @override
  String get aiValidationSomeIngredientsNeedReviewTitle =>
      'Alcuni ingredienti necessitano di revisione';

  @override
  String get aiValidationSaveMatchedItemsButton =>
      'Salva gli elementi abbinati';

  @override
  String get aiValidationSaveMatchedIngredientsButton =>
      'Salva gli ingredienti abbinati';

  @override
  String get aiValidationValidationPassedTitle => 'Convalida superata';

  @override
  String get aiValidationReviewSuggestedTitle => 'Recensione suggerita';

  @override
  String get aiValidationMacroFitValidatedTitle =>
      'Adattamento macro convalidato';

  @override
  String get aiValidationNeedsReviewTitle => 'Necessita di revisione';

  @override
  String get aiValidationRepairLimitReachedReview =>
      'Limite di riparazione automatica raggiunto. Si prega di rivedere prima di salvare.';

  @override
  String get aiValidationRecentMealContextIncluded =>
      'È stato incluso il contesto del pasto recente.';

  @override
  String get aiValidationGeneratedWithoutRecentMealHistory =>
      'Generato senza cronologia recente dei pasti.';

  @override
  String get aiValidationApiKeyRequiredTitle => 'Chiave API obbligatoria';

  @override
  String aiValidationScoreLabel(int score) {
    return 'Punteggio $score/100';
  }

  @override
  String aiValidationDeltaSummary(
      int kcalDelta, int proteinDelta, int carbsDelta, int fatDelta) {
    return 'Delta: $kcalDelta kcal · ${proteinDelta}g Proteine ​​· ${carbsDelta}g Carboidrati · ${fatDelta}g Grassi';
  }

  @override
  String aiValidationPartialSaveItemsMessage(
      int unmatchedCount, int matchedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unmatchedCount,
      locale: localeName,
      other:
          'Gli elementi $unmatchedCount non hanno una corrispondenza nel database locale e non verranno salvati.',
      one:
          '1 elemento non ha una corrispondenza nel database locale e non verra salvato.',
    );
    return '$_temp0';
  }

  @override
  String aiValidationPartialSaveIngredientsMessage(
      int unmatchedCount, int matchedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unmatchedCount,
      locale: localeName,
      other:
          'Gli ingredienti $unmatchedCount non hanno una corrispondenza nel database locale e non verranno salvati.',
      one:
          '1 ingrediente non ha una corrispondenza nel database locale e non verra salvato.',
    );
    return '$_temp0';
  }

  @override
  String get aiValidationEmptyItemName =>
      'Un articolo non ha un nome alimentare.';

  @override
  String aiValidationDuplicateItemMerged(String name) {
    return 'Le voci \"$name\" duplicate sono state unite prima della convalida.';
  }

  @override
  String get aiValidationInvalidQuantity =>
      'La quantità deve essere maggiore di 0 g.';

  @override
  String get aiValidationTinyQuantity =>
      'La quantità è molto piccola; rivedere la quantità in grammi.';

  @override
  String get aiValidationExtremeQuantity =>
      'La quantità è incredibilmente alta per un pasto.';

  @override
  String get aiValidationLargeQuantity =>
      'La quantità è insolitamente grande; rivedere la quantità in grammi.';

  @override
  String get aiValidationLowAiConfidence =>
      'La fiducia dell\'IA è bassa per questo elemento.';

  @override
  String get aiValidationUnmatchedItem =>
      'Non è stata trovata alcuna corrispondenza nel database locale.';

  @override
  String get aiValidationWeakDbMatch =>
      'La corrispondenza del database locale è debole.';

  @override
  String get aiValidationPartialDbMatch =>
      'La corrispondenza del database locale è parziale.';

  @override
  String get aiValidationAmbiguousDbMatch =>
      'Diverse corrispondenze di database locali sembrano altrettanto plausibili.';

  @override
  String get aiValidationStateMismatch =>
      'Lo stato dell\'elemento AI potrebbe non corrispondere alla voce del database.';

  @override
  String get aiValidationZeroNutritionMatch =>
      'La voce del database corrispondente non contiene dati nutrizionali utilizzabili.';

  @override
  String get aiValidationImplausibleFoodDensity =>
      'Il cibo abbinato ha kcal insolitamente elevate per 100 g.';

  @override
  String get aiValidationMacroEnergyMismatch =>
      'I macronutrienti alimentari abbinati non si allineano bene con le kcal.';

  @override
  String get aiValidationImplausibleItemNutrition =>
      'La nutrizione per questa quantità è insolitamente alta.';

  @override
  String get aiValidationEmptyMeal => 'L\'IA non ha restituito alcun pasto.';

  @override
  String get aiValidationAllItemsUnmatched =>
      'Nessun articolo può essere abbinato al database alimentare locale.';

  @override
  String aiValidationPartialUnmatchedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Gli elementi $count non possono essere salvati finché non vengono abbinati.',
      one: '1 elemento non puo essere salvato finche non viene abbinato.',
    );
    return '$_temp0';
  }

  @override
  String get aiValidationZeroTotalKcal =>
      'Gli articoli abbinati producono 0 kcal.';

  @override
  String get aiValidationCaptureTotalKcalExtreme =>
      'Le kcal totali sono incredibilmente alte per un pasto catturato.';

  @override
  String get aiValidationCaptureTotalKcalHigh =>
      'Le kcal totali sono insolitamente alte; rivedere porzioni.';

  @override
  String get aiValidationMacroTotalExtreme =>
      'I macro totali sono incredibilmente alti.';

  @override
  String get aiValidationMacroTotalHigh =>
      'I macro totali sono insolitamente alti; rivedere porzioni.';

  @override
  String aiValidationTargetKcalMismatch(int delta) {
    return 'Le calorie mancano l\'obiettivo di $delta kcal.';
  }

  @override
  String aiValidationTargetProteinMismatch(int delta) {
    return 'Le proteine ​​mancano il bersaglio di ${delta}g.';
  }

  @override
  String aiValidationTargetCarbsMismatch(int delta) {
    return 'I carboidrati mancano l\'obiettivo di ${delta}g.';
  }

  @override
  String aiValidationTargetFatMismatch(int delta) {
    return 'Fat manca il bersaglio di ${delta}g.';
  }

  @override
  String aiValidationUnknownIssue(String code) {
    return 'Problema di convalida: $code';
  }

  @override
  String get currentlyTracking => 'Attualmente';

  @override
  String get currentlyTrackingDesc =>
      'Mostra nell\'hub di monitoraggio giornaliero';

  @override
  String get filter3Months => '3 mesi';

  @override
  String get filter6Months => '6 mesi';

  @override
  String get sectionConsistency => 'Coerenza e frequenza';

  @override
  String get metricsWorkoutsWeek => 'Allenamenti (settimana)';

  @override
  String get metricsCurrentStreak => 'Serie attuale';

  @override
  String get metricsActiveWeeks => 'settimane attive';

  @override
  String get placeholderCalendarHeatmap =>
      'Visualizzazione della mappa termica del calendario';

  @override
  String get consistencyTrackerTitle => 'Monitoraggio della coerenza';

  @override
  String get consistencyTrackerComingSoon =>
      'Monitoraggio della coerenza e delle abitudini (disponibile a breve)';

  @override
  String get sectionMuscleVolume => 'Gruppi muscolari e volume';

  @override
  String get metricsTopTrained => 'I più preparati';

  @override
  String get metricsMostNeglected => 'I più trascurati';

  @override
  String get placeholderMuscleHeatmap => 'Mappa termica muscolare visiva';

  @override
  String get muscleAnalyticsTitle => 'Analisi dei gruppi muscolari';

  @override
  String get muscleAnalyticsComingSoon =>
      'Volume muscolare e mappe di calore (disponibile a breve)';

  @override
  String get sectionPerformance => 'Prestazioni e PR';

  @override
  String get metricsRecentPrs => 'PR recenti';

  @override
  String get metricsVolumeLifted => 'Volume sollevato';

  @override
  String get metricsMostImproved => 'Molto migliorato';

  @override
  String get exerciseAnalyticsTitle => 'Analisi degli esercizi';

  @override
  String get exerciseAnalyticsSubtitle => 'Cerca e analizza esercizi specifici';

  @override
  String get prDashboardTitle => 'Cruscotto PR';

  @override
  String get prDashboardComingSoon =>
      'Record e progressi (disponibile a breve)';

  @override
  String get exerciseAnalyticsComingSoon =>
      'Ricerca degli esercizi e tendenze specifiche (disponibile a breve)';

  @override
  String get sectionRecovery => 'Recupero';

  @override
  String get metricsMuscleReadiness => 'Prontezza muscolare';

  @override
  String get recoveryTrackerTitle => 'Monitoraggio del recupero';

  @override
  String get recoveryTrackerComingSoon =>
      'Prontezza muscolare e affaticamento (disponibile a breve)';

  @override
  String get recoveryOverallMostlyRecovered => 'Per lo più recuperato';

  @override
  String get recoveryOverallMixed => 'Stato di recupero misto';

  @override
  String get recoveryOverallSeveralRecovering =>
      'Diversi gruppi muscolari ancora in recupero';

  @override
  String get recoveryOverallInsufficientData =>
      'Dati insufficienti per informazioni dettagliate sul recupero';

  @override
  String recoveryHubCountsSummary(int recovering, int ready, int fresh) {
    return 'In recupero: $recovering Pronto: $ready Fresco: $fresh';
  }

  @override
  String get recoveryHubNoDataSummary =>
      'Continua a registrare gli allenamenti per sbloccare informazioni dettagliate sul recupero.';

  @override
  String get recoveryByMuscleTitle => 'Recupero muscolare';

  @override
  String get recoveryStateRecovering => 'Recupero';

  @override
  String get recoveryStateReady => 'Pronto';

  @override
  String get recoveryStateFresh => 'Fresco';

  @override
  String get recoveryStateUnknown => 'Sconosciuto';

  @override
  String recoveryLastLoadedHours(int hours) {
    return 'Ultimo caricamento significativo: $hours h fa';
  }

  @override
  String get recoveryFatigueContextHigh =>
      'Contesto di affaticamento: affaticamento elevato della sessione';

  @override
  String get recoveryFatigueContextBaseline =>
      'Contesto della fatica: fatica della sessione di base';

  @override
  String recoveryExplanationWithHighFatigue(String muscle, int hours) {
    return '$muscle: ultimo carico significativo $hours h fa, con affaticamento elevato durante la sessione.';
  }

  @override
  String recoveryExplanationBasic(String muscle, int hours) {
    return '$muscle: l\'ultimo carico significativo $hours h fa.';
  }

  @override
  String get recoveryHeuristicDisclaimer =>
      'Si tratta di un\'euristica conservativa basata sul recente caricamento significativo e sullo sforzo della sessione. Non è una misurazione del recupero medico.';

  @override
  String get recoveryReadinessLabel => 'Prontezza';

  @override
  String recoveryRecentLoad(String sets) {
    return 'Ultimo caricamento: $sets set equivalenti';
  }

  @override
  String recoveryLastLoadPressure(String level) {
    return 'Ultima pressione di carico: $level';
  }

  @override
  String get recoveryPressureLow => 'Basso';

  @override
  String get recoveryPressureModerate => 'moderare';

  @override
  String get recoveryPressureHigh => 'alto';

  @override
  String get recoveryPressureVeryHigh => 'molto alto';

  @override
  String recoveryCurrentWindow(int recoveringUpper, int readyUpper) {
    return 'Finestra corrente: recupero fino alle $recoveringUpper h circa, pronto fino alle $readyUpper h circa.';
  }

  @override
  String recoveryWindowHeuristic(int from, int to) {
    return 'Finestra attuale: recupero fino alle $from h circa, pronto fino alle $to h circa.';
  }

  @override
  String get recoveryRadarHeuristicCaption =>
      'Panoramica radar della prontezza attuale per muscolo. I badge di stato rimangono il segnale principale.';

  @override
  String get recoveryNoDataBody =>
      'Non è stato ancora registrato un carico di allenamento significativo sufficiente per stimare il recupero muscolare.';

  @override
  String get sectionBodyNutrition => 'Corpo e nutrizione';

  @override
  String get statisticsSectionTraining => 'Formazione';

  @override
  String get statisticsSectionBody => 'Corpo';

  @override
  String get statisticsEnableStepTrackingHint =>
      'Abilita il monitoraggio dei passi nelle Impostazioni';

  @override
  String get statisticsNoStepDataYet => 'Nessun dato sui passi ancora';

  @override
  String get statisticsTotalSteps => 'Passi totali';

  @override
  String get statisticsLast7Days => 'Ultimi 7 giorni';

  @override
  String get statisticsLast30Days => 'Ultimi 30 giorni';

  @override
  String get statisticsLast3Months => 'Ultimi 3 mesi';

  @override
  String get statisticsLast6Months => 'Ultimi 6 mesi';

  @override
  String get metricsCurrentWeight => 'Peso attuale';

  @override
  String get metricsAvgCalories => 'Media Calorie';

  @override
  String get placeholderWeightTrend =>
      'Grafico della linea di tendenza del peso';

  @override
  String get exerciseAnalyticsPrsLabel => 'DOCUMENTI PERSONALI';

  @override
  String get exerciseAnalyticsTrendsLabel => 'TENDENZE';

  @override
  String get exerciseAnalyticsNoData =>
      'Nessun dato di tracciamento per questo esercizio.';

  @override
  String get exerciseAnalyticsNotEnoughData => 'Dati insufficienti';

  @override
  String get exerciseAnalyticsChartWeight => 'Peso nel tempo (kg)';

  @override
  String get exerciseAnalyticsChartVolume => 'Volume nel tempo (kg)';

  @override
  String get exerciseAnalyticsChartSets => 'Imposta nel tempo';

  @override
  String get exerciseMetricMaxWeight => 'Peso massimo';

  @override
  String get exerciseMetricVolume => 'Volume';

  @override
  String get exerciseMetricEst1RM => '1RM Stimato';

  @override
  String get prBannerBestMaxWeight => 'Miglior peso massimo';

  @override
  String get prBannerBestVolumeSet => 'Miglior set di volumi';

  @override
  String get prBannerBest1RM => 'Miglior 1 ripetizione max';

  @override
  String get newPersonalRecordLabel => 'Nuovo record personale';

  @override
  String get prBadgeTooltip => 'Nuovo record personale!';

  @override
  String get workoutSummaryNewRecordsTitle => 'Nuovi record';

  @override
  String get allTimeRecordsLabel => 'Record di tutti i tempi';

  @override
  String get recentActivityLabel => 'Attività recente';

  @override
  String get prsByRepRangeLabel => 'Miglior set per intervallo di ripetizioni';

  @override
  String get volumeAnalyticsTitle => 'Analisi del volume';

  @override
  String get weeklyTonnageLabel => 'Tonnellaggio settimanale';

  @override
  String get volumeByMuscleLabel => 'Per gruppo muscolare';

  @override
  String get topExercisesLabel => 'I migliori esercizi';

  @override
  String get thisWeekLabel => 'Questa settimana';

  @override
  String get avgPerWeekLabel => 'Media/settimana';

  @override
  String get streakLabel => 'Strisciante';

  @override
  String get trainingCalendarLabel => 'Calendario della formazione';

  @override
  String get workoutsPerWeekLabel => 'Allenamenti a settimana';

  @override
  String get totalWorkoutsLabel => 'Totale';

  @override
  String get weeksLabel => 'Settimane';

  @override
  String get tonnageKgLabel => 'Tonnellaggio (kg)';

  @override
  String get noWorkoutDataLabel =>
      'Nessun dato di allenamento ancora. Inizia la registrazione per vedere le statistiche.';

  @override
  String get analyticsSectionVolumeMuscles => 'Gruppi di volume e muscoli';

  @override
  String get analyticsSectionPerformanceRecords => 'Prestazioni e record';

  @override
  String get analyticsTopVolume => 'I più preparati';

  @override
  String get analyticsLowestVolume => 'Volume più basso';

  @override
  String get analyticsRecentRecords => 'Record recenti';

  @override
  String analyticsPerfWithReps(String weight, int reps) {
    return '$weight kg x $reps';
  }

  @override
  String get analyticsKgThisWeek => 'kg (questa settimana)';

  @override
  String get analyticsRecoverySummary => '3 in convalescenza, 8 pronti';

  @override
  String get analyticsViewDetails => 'Visualizza i dettagli';

  @override
  String get analyticsRepRangeSuffix => 'ripetizioni';

  @override
  String get analyticsNoRecordYet => 'Nessun record ancora';

  @override
  String get analyticsNotableImprovements => 'Miglioramenti notevoli';

  @override
  String get analyticsNoPrTrendInWindow =>
      'Non esiste ancora una chiara tendenza delle PR in questa finestra.';

  @override
  String analyticsE1rmProgress(String previous, String recent) {
    return 'e1RM $previous -> $recent kg';
  }

  @override
  String get analyticsUnitKg => 'kg';

  @override
  String get analyticsUnitSets => 'insiemi';

  @override
  String get analyticsViewLabel => 'Visualizzazione';

  @override
  String get analyticsViewWeek => 'Settimana';

  @override
  String get analyticsViewMonth => 'Mese';

  @override
  String get analyticsViewByExercise => 'Per esercizio';

  @override
  String get analyticsViewByMuscle => 'Per gruppo muscolare';

  @override
  String get analyticsMetricLabel => 'Metrico';

  @override
  String get analyticsMovedWeightKg => 'Peso spostato (kg)';

  @override
  String get analyticsWorkSets => 'Set di lavoro';

  @override
  String get analyticsVolumeContextWithSets =>
      'Peso spostato = peso x ripetizioni. Passa ai set di lavoro per il carico basato sul conteggio.';

  @override
  String get analyticsVolumeContextTonnageOnly =>
      'Questa visualizzazione utilizza il peso spostato (peso x ripetizioni).';

  @override
  String get analyticsKpisHeader => 'KPI';

  @override
  String get analyticsTrainingDaysPerWeek => 'Giorni/settimana di allenamento';

  @override
  String get analyticsLast4Weeks => 'ultime 4 settimane';

  @override
  String get analyticsRhythm => 'Ritmo';

  @override
  String get analyticsVsPrior4Weeks => 'rispetto alle 4 settimane precedenti';

  @override
  String get analyticsRollingConsistency => 'Consistenza del rotolamento';

  @override
  String get analyticsWeeksAtLeast2Workouts =>
      'settimane con almeno 2 sessioni';

  @override
  String get analyticsCalendarExplainer =>
      'L\'intensità del colore riflette le sessioni giornaliere, rendendola una vera mappa di coerenza.';

  @override
  String get analyticsSelectDayPrompt =>
      'Seleziona un giorno per controllare il conteggio delle sessioni.';

  @override
  String analyticsSelectedDayWorkouts(String date, int count) {
    return '$date: $count sessioni';
  }

  @override
  String get analyticsTotalSessions => 'Sessioni totali';

  @override
  String get analyticsPlaceholderWeightValue => '82,5';

  @override
  String get analyticsPlaceholderWeightTrend => 'chilogrammo (-0,5)';

  @override
  String get analyticsPlaceholderCaloriesValue => '2.450';

  @override
  String get analyticsPlaceholderCaloriesUnit => 'kcal/giorno';

  @override
  String get analyticsMuscleWeeklySets => 'Set settimanali';

  @override
  String get analyticsMuscleTopFrequency => 'Frequenza massima';

  @override
  String get analyticsPerWeekAbbrev => 'sett';

  @override
  String get analyticsKeepTrackingUnlockInsights =>
      'Continua a monitorare per sbloccare approfondimenti.';

  @override
  String get analyticsGuidanceNoClearWeakPoint =>
      'Guida: nessun chiaro punto debole in questo periodo.';

  @override
  String analyticsGuidanceLowerEmphasis(String muscles) {
    return 'Guida: ridurre l\'enfasi recente sui $muscles.';
  }

  @override
  String get analyticsPeriodLabel => 'Periodo';

  @override
  String get analyticsEquivalentSetsExplainer =>
      'I set hard equivalenti utilizzano la ponderazione primaria x1.0 e secondaria x0.3. La frequenza conta solo i giorni che raggiungono >= 1,0 set equivalenti.';

  @override
  String get analyticsWeeklySetsByMuscle => 'Set settimanali di Muscle';

  @override
  String get analyticsFrequencyByMuscle => 'Frequenza per muscolo';

  @override
  String get analyticsRecentDistributionHeatmap =>
      'Mappa termica della distribuzione recente';

  @override
  String get analyticsRadarOverviewTitle => 'Panoramica del radar';

  @override
  String get analyticsRadarVolumeCaption =>
      'Mostra la distribuzione relativa del volume tra i muscoli per un rapido riepilogo a colpo d\'occhio.';

  @override
  String get analyticsGuidanceTitle => 'Guida';

  @override
  String get analyticsGuidanceDirectionalDisclaimer =>
      'Questa è una guida direzionale basata sulla recente distribuzione del set, non una diagnosi assoluta.';

  @override
  String get analyticsGuidanceSoftenedDisclaimer =>
      'Gli approfondimenti vengono intenzionalmente attenuati finché non sono disponibili dati sufficienti.';

  @override
  String analyticsWeekTotalEquivalentSets(String value) {
    return 'Totale settimana: $value set equivalenti';
  }

  @override
  String get analyticsFrequencyRuleFooter =>
      'La frequenza conta solo i giorni in cui il muscolo ha raggiunto >= 1,0 serie equivalenti.';

  @override
  String liveWorkoutE1rmCurrentSet(String value) {
    return 'e1RM $value kg';
  }

  @override
  String liveWorkoutE1rmBestSession(String value) {
    return 'Miglior e1RM di questa sessione: $value kg';
  }

  @override
  String liveWorkoutE1rmVsLastSession(String delta) {
    return 'rispetto all\'ultima sessione: $delta kg';
  }

  @override
  String get bodyNutritionCorrelationTitle =>
      'Tendenze corporee e nutrizionali';

  @override
  String get metricsWeightChange => 'Variazione di peso';

  @override
  String get analyticsKcalPerDay => 'kcal/giorno';

  @override
  String get analyticsDaysWithWeightData => 'giorni con peso';

  @override
  String get analyticsDayUnitLabel => 'giorni';

  @override
  String get analyticsPerDayLabel => 'al giorno';

  @override
  String get analyticsEffectiveRangeLabel => 'Portata effettiva';

  @override
  String get analyticsAxisXLabel => 'X';

  @override
  String get analyticsAxisYLabel => 'Y';

  @override
  String get analyticsHighConfidenceLabel =>
      'Modello con confidenza più elevata';

  @override
  String get analyticsLowConfidenceLabel => 'Modello di fiducia inferiore';

  @override
  String get analyticsObservedPatternLabel => 'Modello osservato';

  @override
  String get analyticsBodyNutritionTrendContext => 'Peso e calorie nel tempo';

  @override
  String get analyticsBodyNutritionTrendContextHint =>
      'Il grafico ridimensiona ciascuna serie per adattarla allo stesso spazio; i suggerimenti mostrano i valori grezzi di kg e kcal.';

  @override
  String get analyticsBodyNutritionNormalizedHint =>
      'Il grafico ridimensiona peso e calorie per adattarli allo stesso spazio; i suggerimenti mostrano i valori grezzi di kg e kcal.';

  @override
  String get analyticsBodyNutritionTotalWeightLabel => 'Peso totale (kg)';

  @override
  String get analyticsBodyNutritionTotalCaloriesLabel =>
      'Calorie totali (kcal)';

  @override
  String get analyticsWeightTrendLabel => 'Peso (kg)';

  @override
  String get analyticsCaloriesTrendLabel => 'Calorie (kcal)';

  @override
  String get analyticsInterpretationTitle => 'Interpretazione';

  @override
  String get analyticsBodyNutritionConfidenceHighHint =>
      'La copertura dei dati in questo intervallo è sufficientemente forte per una lettura del modello più affidabile.';

  @override
  String get analyticsBodyNutritionConfidenceModerateHint =>
      'La copertura dei dati è moderata. Le tendenze rappresentano un contesto utile, ma continua a registrarle per una maggiore sicurezza.';

  @override
  String get analyticsBodyNutritionConfidenceLowHint =>
      'La copertura dei dati in questo intervallo è ancora limitata, quindi consideralo come un contesto iniziale.';

  @override
  String get analyticsBodyNutritionLowConfidenceNudge =>
      'Continua a registrare regolarmente peso e calorie per aumentare la sicurezza.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceHigh =>
      'Fiducia nell\'interpretazione: più alta. Usalo come contesto di tendenza, non come dichiarazione di causa diretta.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceLow =>
      'Fiducia nell\'interpretazione: inferiore. Usalo come segnale di pattern iniziale e continua a monitorarlo.';

  @override
  String get analyticsCorrelationDisclaimer =>
      'Questa visualizzazione fornisce il contesto della tendenza. Ciò non dimostra che i cambiamenti calorici abbiano causato direttamente cambiamenti di peso.';

  @override
  String get analyticsInsightStableWeightCaloriesUp =>
      'L’andamento del peso è stabile mentre le calorie medie sono in aumento.';

  @override
  String get analyticsInsightWeightUpCaloriesUp =>
      'Il peso tende ad aumentare insieme ad un apporto calorico medio più elevato.';

  @override
  String get analyticsInsightCaloriesDownWeightStable =>
      'La recente riduzione delle calorie non ha ancora cambiato nettamente l’andamento del peso.';

  @override
  String get analyticsInsightWeightDownCaloriesDown =>
      'Il peso tende al ribasso insieme ad un apporto calorico medio inferiore.';

  @override
  String get analyticsInsightMixedPattern =>
      'Gli andamenti del peso e delle calorie sono contrastanti senza ancora una relazione chiara.';

  @override
  String get analyticsInsightNotEnoughData =>
      'Dati coerenti non ancora sufficienti per una lettura significativa della tendenza.';

  @override
  String get analyticsModerateConfidenceLabel => 'Modello di fiducia moderata';

  @override
  String get analyticsInsufficientConfidenceLabel =>
      'Confidenza dei dati insufficiente';

  @override
  String get analyticsTrendRising => 'In aumento';

  @override
  String get analyticsTrendFalling => 'Cadente';

  @override
  String get analyticsTrendStable => 'Stabile';

  @override
  String get analyticsTrendUnclear => 'Non chiaro';

  @override
  String get analyticsRelationshipAlignedCut =>
      'Il basso apporto e la diminuzione del peso corporeo sono allineati.';

  @override
  String get analyticsRelationshipAlignedBulk =>
      'Un apporto maggiore e l’aumento del peso corporeo sono allineati.';

  @override
  String get analyticsRelationshipStableMaintenance =>
      'Il peso e l\'assunzione sembrano sostanzialmente stabili.';

  @override
  String get analyticsRelationshipMixed =>
      'I segnali sono mescolati o ritardati.';

  @override
  String get analyticsRelationshipInsufficient =>
      'La sovrapposizione coerente non è ancora sufficiente per classificare il modello.';

  @override
  String analyticsBasedOnDataCoverage(int weightDays, int calorieDays) {
    return 'Basato su $weightDays pesate e $calorieDays giorni di calorie';
  }

  @override
  String get restTimerNotificationTitle => 'Resto finito';

  @override
  String get restTimerNotificationBody =>
      'Il timer della pausa è scaduto. Pronti per il prossimo set.';

  @override
  String get onboardingContinueSetup => 'Imposta profilo';

  @override
  String get onboardingRestoreFromBackup => 'Ripristina dal backup';

  @override
  String get onboardingRestoreImporting => 'Importazione backup...';

  @override
  String get onboardingRestoreSuccess => 'Backup ripristinato con successo!';

  @override
  String get onboardingRestoreFailed =>
      'Importazione non riuscita. Controlla il file e riprova.';

  @override
  String get finishWorkoutTitleLabel => 'Titolo dell\'allenamento';

  @override
  String get finishWorkoutNotesLabel => 'Note (facoltativo)';

  @override
  String get finishWorkoutNotesHint => 'Com\'è andato l\'allenamento?';

  @override
  String get sleepSectionTitle => 'Sonno';

  @override
  String get sleepSectionSubtitleDayEntry =>
      'Panoramica giornaliera e approfondimenti dettagliati';

  @override
  String get sleepSectionSubtitleAllEntry =>
      'Da questa voce sono disponibili le visualizzazioni del giorno, della settimana e del mese del sonno';

  @override
  String get sleepScopeDay => 'Giorno';

  @override
  String get sleepScopeWeek => 'Settimana';

  @override
  String get sleepScopeMonth => 'Mese';

  @override
  String get sleepWeekSummaryTitle => 'Riepilogo della settimana';

  @override
  String get sleepMonthSummaryTitle => 'Riepilogo del mese';

  @override
  String get sleepSleepWindowTitle => 'Finestra per dormire';

  @override
  String get sleepDailyScoreTitle => 'Punteggio giornaliero';

  @override
  String get sleepMonthDailyScoreStatesTitle =>
      'Stati del punteggio giornaliero';

  @override
  String sleepMeanScoreLabel(String value) {
    return 'Punteggio medio: $value';
  }

  @override
  String get sleepHubScoreLabel => 'Punteggio del sonno';

  @override
  String get sleepHubAverageLabel => 'Media';

  @override
  String get sleepHubBedtimeLabel => 'Ora di andare a dormire';

  @override
  String get sleepHubInterruptionsLabel => 'Interruzioni';

  @override
  String sleepHubInterruptionsSummary(int count, String duration) {
    return '$count risvegli, $duration totale';
  }

  @override
  String sleepWeekdayAvgDurationLabel(String value) {
    return 'Durata media del giorno feriale: $value';
  }

  @override
  String sleepWeekendAvgDurationLabel(String value) {
    return 'Durata media del fine settimana: $value';
  }

  @override
  String get sleepWeekNoScoredNights =>
      'Non sono ancora disponibili notti di sonno conteggiate in questa settimana.';

  @override
  String get sleepMonthNoScoredNights =>
      'Non sono ancora disponibili notti di sonno conteggiate questo mese.';

  @override
  String get sleepSettingsSectionTitle => 'Sonno';

  @override
  String get sleepEnableTrackingTitle => 'Abilita il monitoraggio del sonno';

  @override
  String get sleepEnableTrackingSubtitle =>
      'Leggi il sonno e la frequenza cardiaca notturna da Health Connect / HealthKit';

  @override
  String get sleepHealthConnectionStatusTitle =>
      'Stato della connessione sanitaria';

  @override
  String get sleepRequestAccessTitle => 'Richiedi l\'accesso';

  @override
  String get sleepRequestAccessSubtitle =>
      'Richiedere o richiedere nuovamente le autorizzazioni relative al sonno/frequenza cardiaca';

  @override
  String get sleepImportNowTitle => 'Importa ora i dati del sonno';

  @override
  String get sleepImportNowSubtitle =>
      'Importa tutti i dati sul sonno disponibili (tutto il tempo)';

  @override
  String get sleepRawImportsTitle =>
      'Visualizza le importazioni del sonno non elaborato';

  @override
  String get sleepRawImportsSubtitle =>
      'Mostra i payload recenti di Health Connect';

  @override
  String get sleepDataStatusTitle => 'Stato dei dati';

  @override
  String get sleepDataStatusSubtitle =>
      'Autorizzazioni concesse. Se non viene ancora visualizzato lo stato di sospensione, esegui un\'importazione manuale di seguito.';

  @override
  String get sleepNoPermissionTitle => 'Nessun permesso';

  @override
  String get sleepNoPermissionSubtitle =>
      'Per importare i dati del sonno sono necessarie le autorizzazioni relative al sonno e alla frequenza cardiaca.';

  @override
  String get sleepFeatureUnavailableTitle => 'Funzionalità non disponibile';

  @override
  String get sleepFeatureUnavailableSubtitle =>
      'L\'importazione del sonno non è disponibile su questo dispositivo oppure Health Connect non è installato.';

  @override
  String get sleepNoRawImportsFound =>
      'Nessuna importazione di sonno grezzo ancora trovata.';

  @override
  String get sleepRawImportsSheetTitle =>
      'Importazioni del sonno non elaborato (più recenti)';

  @override
  String sleepImportFinishedSessions(int count) {
    return 'Importazione del sonno terminata ($count sessioni).';
  }

  @override
  String get sleepImportUnavailableCheckPermissions =>
      'Importazione del sonno non disponibile. Controlla i permessi.';

  @override
  String get sleepStatusChecking =>
      'Verifica dello stato delle autorizzazioni…';

  @override
  String get sleepStatusReady => 'Pronto';

  @override
  String get sleepStatusDenied => 'Negato';

  @override
  String get sleepStatusPartial => 'Accesso parziale';

  @override
  String get sleepStatusUnavailable => 'Non disponibile su questo dispositivo';

  @override
  String get sleepStatusNotInstalled => 'Connessione Salute non installata';

  @override
  String get sleepStatusTechnicalError => 'Errore tecnico';

  @override
  String get sleepConnectHealthDataTitle => 'Connetti i dati sanitari';

  @override
  String get sleepConnectHealthDataMessage =>
      'Connetti HealthKit o Health Connect per importare i registri del sonno.';

  @override
  String get sleepPermissionDeniedTitle => 'Autorizzazione negata';

  @override
  String get sleepPermissionDeniedMessage =>
      'Le autorizzazioni per il sonno sono negate. Apri le impostazioni per concedere l\'accesso.';

  @override
  String get sleepSourceUnavailableTitle => 'Fonte non disponibile';

  @override
  String get sleepSourceUnavailableMessage =>
      'L\'origine dati del sonno non è disponibile o non è installata su questo dispositivo.';

  @override
  String get sleepEmptyDayNoData =>
      'Nessun dato sul sonno disponibile per questo giorno.';

  @override
  String get sleepEmptyDayConnectMessage =>
      'Connect Health Connect/HealthKit in Impostazioni e importa i dati recenti sul sonno.';

  @override
  String get sleepOpenSettingsButton => 'Apri le impostazioni';

  @override
  String get sleepImportNowButton => 'Importa ora';

  @override
  String get sleepImportFinishedRefreshing =>
      'Importazione del sonno terminata. Rinfrescante...';

  @override
  String get sleepImportUnavailableSettingsHint =>
      'Importazione del sonno non disponibile. Controlla le autorizzazioni in Impostazioni.';

  @override
  String get sleepTimelineTitle => 'Cronologia';

  @override
  String get sleepTimelineUnavailable =>
      'Nessuna cronologia del palco disponibile per questa notte.';

  @override
  String get sleepSessionTypeCore => 'Sonno fondamentale';

  @override
  String get sleepSessionTypeNap => 'Pisolino';

  @override
  String get sleepIntervalsDrawerTitle => 'Intervalli di sonno';

  @override
  String get sleepStageDeepLabel => 'Profondo';

  @override
  String get sleepStageLightLabel => 'Leggero';

  @override
  String get sleepStageRemLabel => 'REM';

  @override
  String get sleepStageAwakeLabel => 'Sveglio';

  @override
  String get sleepScoreCardTitle => 'Qualità del sonno';

  @override
  String get sleepScoreUnavailableForNight =>
      'Punteggio non disponibile per questa notte.';

  @override
  String sleepScoreCompletenessLabel(String value) {
    return 'Completezza del punteggio: $value';
  }

  @override
  String get sleepQualityGood => 'Bene';

  @override
  String get sleepQualityAverage => 'Media';

  @override
  String get sleepQualityPoor => 'Povero';

  @override
  String get sleepQualityUnavailable => 'Non disponibile';

  @override
  String get sleepQualitySubtitleGood =>
      'La ripresa è apparsa forte durante la notte.';

  @override
  String get sleepQualitySubtitleAverage =>
      'Il sonno era ok con margini di miglioramento.';

  @override
  String get sleepQualitySubtitlePoor =>
      'I segnali di ripresa stasera sono stati deboli.';

  @override
  String get sleepQualitySubtitleUnavailable =>
      'Dati insufficienti per segnare questa notte.';

  @override
  String get sleepQualityRegularityNotContributing =>
      'La regolarità non ha contribuito (<5 giorni validi).';

  @override
  String get sleepQualityRegularityPreliminary =>
      'La regolarità è preliminare (5-6 giorni validi).';

  @override
  String sleepQualityRegularityStable(int days) {
    return 'La regolarità è stabile ($days giorni).';
  }

  @override
  String sleepRegularityNightView(int count) {
    return '$count-vista notturna';
  }

  @override
  String get sleepMetricUnavailable => 'Non disponibile';

  @override
  String get sleepMetricDurationTitle => 'Durata';

  @override
  String get sleepMetricHeartRateTitle => 'Frequenza cardiaca';

  @override
  String get sleepMetricRegularityTitle => 'Regolarità';

  @override
  String get sleepMetricDepthTitle => 'Profondità';

  @override
  String get sleepMetricInterruptionsTitle => 'Interruzioni';

  @override
  String get sleepMetricDepthLowConfidence => 'Bassa fiducia';

  @override
  String get sleepMetricDepthStagesAvailable => 'Stage disponibili';

  @override
  String get sleepDurationUnavailable =>
      'I dati sulla durata non sono disponibili.';

  @override
  String get sleepDurationStatusWithinTarget => 'All\'interno dell\'obiettivo';

  @override
  String get sleepDurationStatusBelowTarget => 'Sotto l\'obiettivo';

  @override
  String get sleepDurationSubtitle =>
      'La durata totale del tuo sonno per questa notte.';

  @override
  String get sleepDurationBenchmarkHint =>
      'Gli adulti spesso ottengono risultati migliori con circa 7-9 ore. Questo benchmark ti aiuta a vedere dove si trova la tua notte in quell\'intervallo.';

  @override
  String get sleepDepthUnavailable =>
      'I dati sulla profondità non sono disponibili.';

  @override
  String get sleepDepthConfidenceTooLow =>
      'La confidenza dello stage è troppo bassa per un\'analisi approfondita affidabile.';

  @override
  String get sleepDepthBreakdownUnavailable =>
      'La ripartizione della durata della fase non è disponibile per questa notte.';

  @override
  String get sleepDepthRatingRestorative => 'Restaurativo';

  @override
  String get sleepDepthRatingLightLeaning => 'Leggero';

  @override
  String sleepDepthStageConfidenceLabel(String value) {
    return 'Confidenza della fase: $value';
  }

  @override
  String get sleepDepthSubtitle =>
      'Distribuzione delle fasi basata su segmenti della timeline derivati.';

  @override
  String get sleepInterruptionsUnavailable =>
      'I dati sulle interruzioni non sono disponibili.';

  @override
  String get sleepInterruptionsStatusNoneDetected => 'Nessuno rilevato';

  @override
  String get sleepInterruptionsStatusDetected => 'Rilevato';

  @override
  String get sleepInterruptionsSubtitle =>
      'Interruzioni della scia qualificanti durante la notte.';

  @override
  String get sleepInterruptionsTotalWakeDuration => 'Durata totale della scia';

  @override
  String get sleepInterruptionsFootnote =>
      'Questa visualizzazione include solo le interruzioni qualificanti provenienti dagli output dell\'analisi derivati.';

  @override
  String get sleepRegularityUnavailable =>
      'I dati sulla regolarità non sono disponibili.';

  @override
  String sleepRegularityNightRange(int count) {
    return '$count-intervallo di notti';
  }

  @override
  String get sleepRegularityStatusSufficientTrend =>
      'Dati di tendenza sufficienti';

  @override
  String get sleepRegularityStatusLimitedTrend => 'Dati di tendenza limitati';

  @override
  String get sleepRegularitySubtitle =>
      'Finestre dell\'ora di andare a dormire e di svegliarsi per le notti recenti.';

  @override
  String get sleepRegularityAverageBedtime =>
      'Orario medio di andare a dormire';

  @override
  String get sleepRegularityAverageWake => 'Sveglia media';

  @override
  String get sleepHeartRateUnavailable =>
      'I dati sulla frequenza cardiaca del sonno non sono disponibili.';

  @override
  String get sleepHeartRateStatusNoSampleSeries =>
      'Nessuna serie di campioni per questa notte';

  @override
  String get sleepHeartRateStatusBaselineNotEstablished =>
      'Linea di base non stabilita';

  @override
  String get sleepHeartRateStatusComparisonUnavailable =>
      'Confronto di riferimento non disponibile';

  @override
  String get sleepHeartRateStatusBelowBaseline =>
      'Al di sotto della linea di base';

  @override
  String get sleepHeartRateStatusAboveBaseline => 'Sopra la linea di base';

  @override
  String get sleepHeartRateNoSamplesText =>
      'Per questa notte non sono disponibili campioni di frequenza cardiaca del sonno persistente.';

  @override
  String get sleepHeartRateBaselineNotEstablishedText =>
      'Linea di base non ancora stabilita. Questo è neutrale e previsto nella fase iniziale.';

  @override
  String get sleepHeartRateComparisonUnavailableText =>
      'Il confronto di riferimento non è attualmente disponibile per questa notte.';

  @override
  String sleepHeartRateDeltaText(String direction, String delta, String unit) {
    return 'La tua frequenza cardiaca del sonno è pari al valore basale $direction di $delta $unit.';
  }

  @override
  String get sleepHeartRateDirectionBelow => 'sotto';

  @override
  String get sleepHeartRateDirectionAbove => 'Sopra';

  @override
  String get sleepHeartRateComparedBaselineSubtitle =>
      'Rispetto al valore di riferimento del sonno stabilito.';

  @override
  String get sleepHeartRateNoBaselineSubtitle =>
      'La linea di base non è ancora stata stabilita. Questo è neutro.';

  @override
  String get sleepHeartRateSamplesUnavailable =>
      'Nessun campione di frequenza cardiaca è stato memorizzato per questa notte. Il grafico delle tendenze non è disponibile.';

  @override
  String sleepHeartRateDashedLineHint(String value, String unit) {
    return 'La linea tratteggiata mostra la linea di base ($value $unit).';
  }

  @override
  String get sleepBpmUnit => 'bpm';

  @override
  String get sleepRawImportImportedAt => 'Importato a';

  @override
  String get sleepRawImportStatus => 'Stato';

  @override
  String get sleepRawImportSource => 'Fonte';

  @override
  String get sleepRawImportApp => 'App';

  @override
  String get sleepRawImportConfidence => 'Fiducia';

  @override
  String get sleepRawImportPayload => 'Carico utile';

  @override
  String get adaptiveBodyweightTargetSectionTitle =>
      'Obiettivo di peso corporeo adattivo';

  @override
  String get adaptiveRecommendationSettingsSectionTitle =>
      'Impostazioni dei consigli';

  @override
  String get adaptiveGoalDirectionLabel => 'Direzione dell\'obiettivo';

  @override
  String get adaptiveGoalLose => 'Perdere peso';

  @override
  String get adaptiveGoalMaintain => 'Mantenere il peso';

  @override
  String get adaptiveGoalGain => 'Aumentare di peso';

  @override
  String adaptiveRatePerWeek(String value) {
    return '$value kg/settimana';
  }

  @override
  String get adaptivePriorActivityLabel => 'Attività quotidiana di base';

  @override
  String get adaptivePriorActivityLow => 'Bassa attività';

  @override
  String get adaptivePriorActivityModerate => 'Attività moderata';

  @override
  String get adaptivePriorActivityHigh => 'Alta attività';

  @override
  String get adaptivePriorActivityVeryHigh => 'Attività molto elevata';

  @override
  String get adaptivePriorActivityHelpIntro =>
      'Solo attività quotidiana di base (separata dall\'attività cardio extra):';

  @override
  String get adaptivePriorActivityHelpLowLine =>
      'Basso: per lo più seduto, studente/alunno o routine in ufficio.';

  @override
  String get adaptivePriorActivityHelpModerateLine =>
      'Moderato: misto seduto, camminato e in piedi.';

  @override
  String get adaptivePriorActivityHelpHighLine =>
      'Alto: stare molto in piedi/camminare o fare un lavoro fisicamente attivo.';

  @override
  String get adaptivePriorActivityHelpVeryHighLine =>
      'Molto alto: routine/lavoro molto intenso con attività quotidiana costantemente elevata.';

  @override
  String get adaptiveExtraCardioLabel =>
      'Cardio/resistenza extra fuori dall\'app';

  @override
  String get adaptiveExtraCardioOption0 => '0 ore/settimana';

  @override
  String get adaptiveExtraCardioOption1 => '1 ora/settimana';

  @override
  String get adaptiveExtraCardioOption2 => '2 ore/settimana';

  @override
  String get adaptiveExtraCardioOption3 => '3 ore/settimana';

  @override
  String get adaptiveExtraCardioOption5 => '5 ore/settimana';

  @override
  String get adaptiveExtraCardioOption7Plus => '7+ ore/settimana';

  @override
  String get adaptiveExtraCardioHelp =>
      'Includere sessioni di jogging, corsa, ciclismo, nuoto o altre sessioni di resistenza non registrate come allenamenti Train Libre.';

  @override
  String get onboardingAdaptiveGoalTitle =>
      'Raccomandazione nutrizionale adattiva';

  @override
  String get onboardingAdaptiveGoalSubtitle =>
      'Imposta la direzione e la tariffa settimanale. Creiamo una raccomandazione iniziale conservativa e la adattiamo con i tuoi log.';

  @override
  String get adaptiveRecommendationGenerating => 'Generazione...';

  @override
  String get adaptiveRecommendationRefresh => 'Aggiorna la raccomandazione';

  @override
  String get onboardingAdaptiveSummaryEmpty =>
      'Imposta gli input dell\'obiettivo e tocca Aggiorna per visualizzare in anteprima il tuo consiglio iniziale.';

  @override
  String get onboardingAdaptiveSummaryTitle =>
      'Anteprima della raccomandazione';

  @override
  String onboardingAdaptiveSummaryCalories(int value) {
    return 'Calorie: $value kcal';
  }

  @override
  String onboardingAdaptiveSummaryProtein(int value) {
    return 'Proteine: $value g';
  }

  @override
  String onboardingAdaptiveSummaryCarbs(int value) {
    return 'Carboidrati: $value g';
  }

  @override
  String onboardingAdaptiveSummaryFat(int value) {
    return 'Grassi: $value g';
  }

  @override
  String onboardingAdaptiveSummaryConfidence(String value) {
    return 'Base dati: $value';
  }

  @override
  String get onboardingAdaptiveSummaryApply =>
      'Applicare agli obiettivi giornalieri';

  @override
  String get onboardingAdaptiveSummaryApplied =>
      'Applicato agli obiettivi giornalieri';

  @override
  String get onboardingBodyFatPageTitle => '% di grasso corporeo';

  @override
  String get onboardingBodyFatPageSubtitle =>
      'Passaggio facoltativo: inserisci una stima approssimativa se la conosci.';

  @override
  String get onboardingBodyFatOptionalLabel =>
      '% di grasso corporeo (facoltativo)';

  @override
  String get onboardingBodyFatOptionalHelper =>
      'Facoltativo: inseriscilo solo se conosci approssimativamente il tuo valore. Lasciarlo vuoto va bene. Aiuta a personalizzare la raccomandazione iniziale.';

  @override
  String get onboardingBodyFatHelpAction => 'Come posso stimarlo?';

  @override
  String get bodyFatGuidanceTitle =>
      'Guida alla percentuale di grasso corporeo';

  @override
  String get bodyFatGuidanceIntro =>
      'La percentuale di grasso corporeo può essere stimata solo approssimativamente dall’apparenza. Questo è solo un orientamento, non una diagnosi precisa.';

  @override
  String get bodyFatGuidanceDisclaimer =>
      'L\'aspetto può variare notevolmente allo stesso livello di grasso corporeo a causa della massa muscolare, della distribuzione del grasso, della genetica, della ritenzione idrica, della postura e dell\'illuminazione.';

  @override
  String get bodyFatGuidanceSexLabel => 'Sesso di riferimento';

  @override
  String bodyFatGuidancePercent(int percent) {
    return '$percent%';
  }

  @override
  String get bodyFatGuidanceMale10 => 'Definizione molto snella e chiara.';

  @override
  String get bodyFatGuidanceMale15 => 'Atletico, visibilmente definito.';

  @override
  String get bodyFatGuidanceMale20 => 'Sportivo, leggermente più morbido.';

  @override
  String get bodyFatGuidanceMale25 =>
      'Meno definizione, più morbidezza in vita e ventre.';

  @override
  String get bodyFatGuidanceMale30 => 'Chiaramente più morbido, più rotondo.';

  @override
  String get bodyFatGuidanceMale35 =>
      'Molto morbido, quasi nessuna definizione visibile.';

  @override
  String get bodyFatGuidanceMale40 =>
      'Aspetto fortemente più rotondo, nessuna definizione visibile.';

  @override
  String get bodyFatGuidanceFemale15 => 'Molto magro, molto definito.';

  @override
  String get bodyFatGuidanceFemale20 => 'Magro e atletico.';

  @override
  String get bodyFatGuidanceFemale25 => 'Vestibilità, leggermente morbida.';

  @override
  String get bodyFatGuidanceFemale30 =>
      'Gamma media da atletico a normale morbida e dall\'aspetto sano.';

  @override
  String get bodyFatGuidanceFemale35 => 'Notevolmente più morbido.';

  @override
  String get bodyFatGuidanceFemale40 =>
      'Aspetto generale chiaramente più morbido e rotondo.';

  @override
  String get adaptiveRecommendationCardTitle => 'Raccomandazione adattiva';

  @override
  String get adaptiveRecommendationEmptyBody =>
      'Tieni traccia del peso e dell\'alimentazione per circa una settimana per sbloccare il tuo primo consiglio settimanale.';

  @override
  String adaptiveRecommendationGoalLine(String goal, String rate) {
    return 'Obiettivo: $goal ($rate)';
  }

  @override
  String adaptiveRecommendationMaintenanceLine(int value) {
    return 'Stima di mantenimento: $value kcal';
  }

  @override
  String adaptiveRecommendationMaintenanceRangeLine(int lower, int upper) {
    return 'Intervallo probabile: $lower-$upper kcal';
  }

  @override
  String get adaptiveRecommendationUncertaintyHintNarrow =>
      'Il tuo probabile intervallo di manutenzione è abbastanza ristretto. Piccoli spostamenti giornalieri sono normali.';

  @override
  String get adaptiveRecommendationUncertaintyHintModerate =>
      'Il tuo probabile intervallo di mantenimento è moderato in questo momento. Qualche movimento di settimana in settimana è normale.';

  @override
  String get adaptiveRecommendationUncertaintyHintWide =>
      'Il tuo probabile intervallo di manutenzione è ancora ampio. Questo è normale mentre raccogliamo dati più costanti.';

  @override
  String get adaptiveRecommendationStabilizingHint =>
      'Ci stiamo ancora adattando alla tua fase recente, quindi questa stima può variare più del solito.';

  @override
  String adaptiveRecommendationCaloriesValue(int value) {
    return '$value kcal';
  }

  @override
  String adaptiveRecommendationProteinValue(int value) {
    return '$value g';
  }

  @override
  String adaptiveRecommendationCarbsValue(int value) {
    return '$value g';
  }

  @override
  String adaptiveRecommendationFatValue(int value) {
    return '$value g';
  }

  @override
  String adaptiveRecommendationConfidenceLine(String value) {
    return 'Base dati: $value';
  }

  @override
  String adaptiveRecommendationDataBasisLine(
      int windowDays, int weightLogs, int intakeDays) {
    return 'Base dati: $windowDays giorni, $weightLogs registri del peso, $intakeDays giorni di assunzione';
  }

  @override
  String adaptiveRecommendationActiveCaloriesLine(int value) {
    return 'Calorie attive attuali: $value kcal';
  }

  @override
  String adaptiveRecommendationCalculatedAtLine(String value) {
    return 'Calcolato a: $value';
  }

  @override
  String adaptiveRecommendationNextDueLine(String value) {
    return 'Prossimo consiglio adattivo in scadenza: $value';
  }

  @override
  String adaptiveRecommendationNextDueShort(String value) {
    return 'Successivo $value';
  }

  @override
  String get adaptiveRecommendationDueNowLine =>
      'Questa settimana è prevista una nuova raccomandazione adattiva.';

  @override
  String get adaptiveRecommendationDueNowShort =>
      'In scadenza questa settimana';

  @override
  String get adaptiveRecommendationMaintenanceLabel => 'Manutenzione stimata';

  @override
  String get adaptiveRecommendationMaintenanceSourceLabel =>
      'Profilo precedenti + registri recenti';

  @override
  String get adaptiveRecommendationMaintenanceUnit => 'kcal/giorno';

  @override
  String get adaptiveRecommendationMacroTargetsLabel => 'Obiettivi consigliati';

  @override
  String get adaptiveRecommendationTargetCaloriesLabel => 'Obiettivo kcal';

  @override
  String get adaptiveRecommendationDataQualityLabel => 'Qualità dei dati';

  @override
  String get adaptiveRecommendationRecalculateNowAction => 'Ricalcola ora';

  @override
  String get adaptiveRecommendationRecalculating => 'Ricalcolo in corso...';

  @override
  String get adaptiveRecommendationApplying => 'Applicazione...';

  @override
  String get adaptiveRecommendationApplyAction =>
      'Applicare il consiglio agli obiettivi attivi';

  @override
  String get adaptiveRecommendationWarningCalorieFloor =>
      'Raccomandazione vincolata da un livello minimo di sicurezza calorica. Esamina i dati del profilo e i registri recenti prima di candidarti.';

  @override
  String get adaptiveRecommendationWarningUnresolvedFood =>
      'Non è stato possibile risolvere completamente alcune voci nutrizionali per le calorie. Controlla i registri recenti prima di applicare.';

  @override
  String get adaptiveRecommendationWarningLargeAdjustment =>
      'Rilevata grande regolazione. Si prega di verificare la completezza della registrazione recente prima di presentare domanda.';

  @override
  String get adaptiveRecommendationWarningMacroConstrained =>
      'La macrosuddivisione è stata vincolata dal budget calorico. Controlla se la tua tariffa target è troppo aggressiva.';

  @override
  String get adaptiveRecommendationWarningConservative =>
      'Revisione suggerita: la raccomandazione è stata modificata in modo conservativo a causa della variabilità dei dati.';

  @override
  String get adaptiveRecommendationDataBasisHintDefault =>
      'Costruito a partire dai registri recenti e dalla loro completezza.';

  @override
  String get adaptiveRecommendationDataBasisHintPriorOnly =>
      'Basato solo sul profilo/dati precedenti. Aggiungi i registri recenti del peso e dell\'assunzione per un adeguamento adattivo.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseWeight =>
      'I registri recenti del peso sono scarsi, quindi la qualità dei trend è limitata.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseIntake =>
      'I registri di assunzione recenti sono scarsi, quindi le deduzioni sulla manutenzione sono limitate.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseWeightAndIntake =>
      'I registri recenti del peso e dell\'assunzione sono scarsi, quindi questa raccomandazione è più conservativa.';

  @override
  String get adaptiveConfidenceNotEnoughData => 'Solo profilo/precedente';

  @override
  String get adaptiveConfidenceLow => 'Registri recenti limitati';

  @override
  String get adaptiveConfidenceMedium => 'Registri recenti utilizzabili';

  @override
  String get adaptiveConfidenceHigh => 'Registri recenti forti';

  @override
  String get adaptiveRecommendationRecalculatedSnack =>
      'Raccomandazione ricalcolata.';

  @override
  String get adaptiveRecommendationAppliedToGoalsSnack =>
      'Raccomandazione applicata agli obiettivi attivi.';

  @override
  String get adaptiveRecommendationNotAvailableSnack =>
      'Nessuna raccomandazione disponibile per l\'applicazione.';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsAppearanceSubtitle =>
      'Modifica il tema, lo stile visivo e l\'aspetto tattile';

  @override
  String get settingsShowSugarInDiaryOverviewTitle =>
      'Mostra lo zucchero nella panoramica del diario';

  @override
  String get settingsShowSugarInDiaryOverviewSubtitle =>
      'Mostra lo zucchero nella sezione panoramica giornaliera in alto';

  @override
  String get settingsSectionHealthTracking => 'Salute e monitoraggio';

  @override
  String get settingsStepsSubtitle =>
      'Monitoraggio, policy di origine e fornitori';

  @override
  String get settingsSleepSubtitle =>
      'Importazione, autorizzazioni e stato di sospensione';

  @override
  String get settingsPulseSubtitle =>
      'Attiva l\'analisi del polso e l\'accesso alla frequenza cardiaca';

  @override
  String get settingsHealthExportSubtitle =>
      'Gestisci l\'esportazione di Apple Health e Health Connect';

  @override
  String get settingsSectionNutritionAndData => 'Nutrizione e dati';

  @override
  String get settingsSectionSupportAbout => 'Supporto/Informazioni';

  @override
  String get settingsHapticFeedbackTitle => 'Feedback tattile';

  @override
  String get settingsHapticFeedbackSubtitle =>
      'Vibrazioni leggere per conferme e attesa dell\'IA';

  @override
  String get stepsSettingsEnableTrackingTitle =>
      'Abilita il monitoraggio dei passaggi';

  @override
  String get stepsSettingsEnableTrackingSubtitle =>
      'Leggi i dati sui passi da Apple Health/Health Connect';

  @override
  String get stepsSettingsSourcePolicyTitle => 'Politica delle fonti';

  @override
  String get stepsSettingsSourcePolicyAutoDominant =>
      'Auto (sorgente dominante)';

  @override
  String get stepsSettingsSourcePolicyAutoDominantSubtitle =>
      'Consigliato: utilizzare una fonte al giorno per evitare sovrapposizioni di inflazione.';

  @override
  String get stepsSettingsSourcePolicyMaxPerHour => 'Unisci (massimo all\'ora)';

  @override
  String get stepsSettingsSourcePolicyMaxPerHourSubtitle =>
      'Combina le fonti prendendo il periodo orario più alto.';

  @override
  String get stepsSettingsProviderFilterTitle => 'Filtro fornitore';

  @override
  String get pulseTitle => 'Impulso';

  @override
  String get pulseChartTitle => 'Pulsare nel tempo';

  @override
  String get pulseRangeLabel => 'Allineare';

  @override
  String get pulseAverageLabel => 'Media';

  @override
  String get pulseRestingLabel => 'Riposare';

  @override
  String get pulseInsufficientData =>
      'Troppi pochi campioni di impulsi per un grafico affidabile.';

  @override
  String get pulseMethodNote =>
      'Il polso medio è ponderato nel tempo. Il polso a riposo è una stima conservativa del 20% più basso dei campioni nel periodo selezionato.';

  @override
  String pulseSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count campioni',
      one: '1 campione',
      zero: 'Nessun campione',
    );
    return '$_temp0';
  }

  @override
  String get pulseQualityReady => 'Buona copertura';

  @override
  String get pulseQualityLimited => 'Dati limitati';

  @override
  String get pulseQualityInsufficient => 'Molto scarso';

  @override
  String get pulseQualityNoData => 'Nessun dato';

  @override
  String get pulseNoDataDisabled =>
      'L\'analisi del polso è disabilitata nelle Impostazioni.';

  @override
  String get pulseNoDataPermissionDenied =>
      'Per mostrare l\'analisi del polso è necessaria l\'autorizzazione relativa alla frequenza cardiaca.';

  @override
  String get pulseNoDataUnavailable =>
      'I dati sulle pulsazioni non sono al momento disponibili su questo dispositivo.';

  @override
  String get pulseNoDataQueryFailed =>
      'Impossibile leggere i dati sulle pulsazioni.';

  @override
  String get pulseNoDataDefault =>
      'Nessun campione di polso è stato trovato per questo periodo.';

  @override
  String get pulseSettingsEnableTitle => 'Abilita l\'analisi del polso';

  @override
  String get pulseSettingsEnableSubtitle =>
      'Legge i dati sulla frequenza cardiaca per la visualizzazione del polso solo quando la attivi.';

  @override
  String get pulseSettingsPermissionTitle =>
      'Consenti l\'accesso alla frequenza cardiaca';

  @override
  String get pulseSettingsPermissionSubtitle =>
      'Apre Apple Health o Health Connect in modo che Train Libre possa leggere campioni di pulsazioni.';

  @override
  String get pulseSettingsAnalysisSubtitle =>
      'Mostra l\'intervallo, la media ponderata nel tempo e una stima conservativa del polso a riposo. Non una diagnosi medica.';

  @override
  String get pulseSettingsPermissionGranted =>
      'L\'accesso alla frequenza cardiaca è pronto.';

  @override
  String get pulseSettingsPermissionFailed =>
      'L\'accesso alla frequenza cardiaca non è stato concesso.';

  @override
  String get pulseOptInChip => 'Accettazione';

  @override
  String get statisticsPulseDescription =>
      'Intervallo, media ponderata nel tempo e polso a riposo per periodi selezionati.';

  @override
  String get statisticsPulseOpenCaption => 'Apre l\'analisi del polso';

  @override
  String get healthExportTitle => 'Esportazione della salute';

  @override
  String get healthExportAppleHealthTitle => 'Esportazione di Apple Salute';

  @override
  String get healthExportHealthConnectTitle => 'Esportazione di Health Connect';

  @override
  String get healthExportDomainNutritionHydration => 'Nutrizione e idratazione';

  @override
  String get healthExportDomainWorkouts => 'Allenamenti';

  @override
  String get healthExportStateIdle => 'Oziare';

  @override
  String get healthExportStateExporting => 'Esportazione';

  @override
  String get healthExportStateSuccess => 'Successo';

  @override
  String get healthExportStateFailed => 'Fallito';

  @override
  String get healthExportStateDisabled => 'Disabilitato';

  @override
  String get healthExportResultComplete => 'Esportazione completata';

  @override
  String get healthExportResultFailed => 'Esportazione non riuscita';

  @override
  String get healthExportAppleHealthSubtitle =>
      'Esportazione di sola andata da Train Libre ad Apple Health';

  @override
  String get healthExportHealthConnectSubtitle =>
      'Esportazione unidirezionale da Train Libre a Health Connect';

  @override
  String get healthExportAppleHealthStatusTitle =>
      'Stato dell\'esportazione di Apple Health';

  @override
  String get healthExportHealthConnectStatusTitle =>
      'Stato dell\'esportazione di Health Connect';

  @override
  String get settingsBaseFoodLanguageTitle => 'Lingua di visualizzazione cibo';

  @override
  String get settingsBaseFoodLanguageSubtitle =>
      'Scegli la lingua per i nomi degli alimenti di base.';

  @override
  String get settingsBaseFoodLanguageFollowApp =>
      'Segui la lingua dell\'applicazione';

  @override
  String get settingsBaseFoodLanguageEnglish => 'Inglese';

  @override
  String get settingsBaseFoodLanguageGerman => 'Tedesco';

  @override
  String get settingsBaseFoodLanguageFrench => 'Francese';

  @override
  String get settingsBaseFoodLanguageItalian => 'Italiano';

  @override
  String get settingsBaseFoodLanguageJapanese => 'Giapponese';

  @override
  String get aiModelLabel => 'Modello';

  @override
  String get autoBackupStoragePickerUnavailable =>
      'Selettore di archiviazione non disponibile. Riavviare/reinstallare completamente l\'app dopo l\'aggiornamento.';

  @override
  String autoBackupFolderPickerFailed(Object error) {
    return 'Selezione cartella non riuscita: $error';
  }

  @override
  String get healthExportPermissionDenied => 'Autorizzazione negata';

  @override
  String get healthExportAdapterUnavailable => 'Adattatore non disponibile';

  @override
  String get healthExportPlatformUnavailable => 'Piattaforma non disponibile';

  @override
  String get healthExportPlatformNotInstalled => 'Piattaforma non installata';

  @override
  String get healthExportExportDisabled => 'Esportazione disabilitata';

  @override
  String get onboardingMacrosStepTitle => 'Macronutrienti';

  @override
  String get onboardingMacrosStepSubtitle =>
      'Come è composta la tua alimentazione?';

  @override
  String get statisticsProviderAppleHealth => 'Salute delle mele';

  @override
  String get statisticsProviderHealthConnect => 'Connessione sanitaria';

  @override
  String get statisticsProviderWithings => 'Withings';

  @override
  String get statisticsProviderGarmin => 'Garmin';

  @override
  String get statisticsProviderFitbit => 'Fitbit';

  @override
  String get statisticsProviderLocal => 'Locale';

  @override
  String get unit_milliliters => 'ml';

  @override
  String get unit_kilograms => 'kg';

  @override
  String get mealEditorHintExample => 'per esempio. Ciotola di pollo';

  @override
  String get mealEditorNoIngredientsYet => 'Nessuno ancora, in arrivo';

  @override
  String get foodDetailSavedBaseDb => 'Salvato (DB base)';

  @override
  String foodDetailExportError(Object error) {
    return 'Errore di esportazione: $error';
  }

  @override
  String get stepsModulePrevious => 'Precedente';

  @override
  String get stepsModuleNext => 'Prossimo';

  @override
  String get stepsModuleTotalSteps => 'Passi totali';

  @override
  String get stepsModuleThisWeek => 'Questa settimana';

  @override
  String get stepsModuleThisMonth => 'Questo mese';

  @override
  String stepsModuleUpdated(String time) {
    return '$time aggiornato';
  }

  @override
  String get stepsModuleScopeSwitcherSemantics =>
      'Cambia l\'ambito del passaggio';

  @override
  String get stepsModuleDay => 'Giorno';

  @override
  String get stepsModuleWeek => 'Settimana';

  @override
  String get stepsModuleMonth => 'Mese';

  @override
  String get stepsModuleHourlyTimeline => 'Cronologia oraria';

  @override
  String get stepsModuleTotal => 'Totale';

  @override
  String get stepsModuleActiveHours => 'Orari attivi';

  @override
  String get stepsModulePeakHour => 'Ora di punta';

  @override
  String get stepsModuleAvgPerDay => 'Media/Giorno';

  @override
  String get stepsModuleGoalHit => 'Obiettivo colpito';

  @override
  String get stepsModuleGoalDays => 'Giorni di goal';

  @override
  String get diarySyncingSteps => 'Sincronizzazione dei passaggi...';

  @override
  String get diaryLoadingSleep => 'Caricamento sonno...';

  @override
  String get unit_milligrams => 'mg';

  @override
  String get scannerPermissionRequired =>
      'Per eseguire la scansione dei codici a barre è necessario l\'accesso alla fotocamera.';

  @override
  String get scannerPermissionPermanentlyDenied =>
      'L\'accesso alla telecamera è permanentemente negato. Abilitalo nelle impostazioni per scansionare i codici a barre.';

  @override
  String get scannerOpenSettings => 'Apri Impostazioni';

  @override
  String get scannerGrantPermission => 'Continua';

  @override
  String get scannerAlignInstruction =>
      'Allinea il codice a barre orizzontalmente all\'interno della linea laser rossa';

  @override
  String get about_train_libre => 'A proposito di Train Libre';

  @override
  String get legal_notice => 'Note legali';

  @override
  String get privacy_policy => 'Informativa sulla privacy';

  @override
  String get terms_of_service => 'Termini di servizio';

  @override
  String get view_in_browser => 'Visualizza nel browser';

  @override
  String get legal_document_version => 'Versione documento';

  @override
  String get legal_document_last_updated => 'Ultimo aggiornamento';

  @override
  String get used_libraries => 'Biblioteche usate';

  @override
  String get licensing_info => 'Informazioni sulla licenza';

  @override
  String get project_website => 'Sito web del progetto';

  @override
  String get github_repository => 'Repository GitHub';

  @override
  String get health_permission_dialog_title => 'Dati sanitari e privacy';

  @override
  String get health_permission_dialog_body =>
      'Train Libre deve leggere i dati dei tuoi passi per mostrare le statistiche giornaliere/settimanali. I tuoi dati rimangono localmente sul tuo dispositivo; non esiste un server esterno.';

  @override
  String get health_permission_continue => 'Continuare';

  @override
  String get health_permission_not_now => 'Non adesso';

  @override
  String get welcome_privacy_title => 'Benvenuto e privacy';

  @override
  String get welcome_privacy_body =>
      'Utilizzando Train Libre, accetti il ​​trattamento dei tuoi dati come descritto nella nostra Informativa sulla privacy e nelle Note legali.';

  @override
  String get i_agree_to_privacy_policy =>
      'Ho letto e acconsento al trattamento dei miei dati sanitari come descritto nella Privacy Policy.';

  @override
  String get acceptTermsPrompt => 'Accetto i Termini di servizio';

  @override
  String get viewTermsInline => 'Termini di servizio';

  @override
  String get accept_and_get_started => 'Accetta e inizia';

  @override
  String get about_section => 'Di';

  @override
  String get legal_section => 'Informazioni legali e privacy';

  @override
  String get aiSettingsInstructionTitle =>
      'Come funziona il riconoscimento dei pasti tramite intelligenza artificiale';

  @override
  String get aiSettingsInstructionBody =>
      'Questa funzionalità utilizza l\'intelligenza artificiale per analizzare le immagini degli alimenti e fornire stime sui nutrienti. Le tue immagini vengono inviate solo al fornitore AI selezionato quando utilizzi la funzione. Si basa su un\'architettura Bring-Your-Own-Key (BYOK), mantenendo i tuoi dati localmente sul tuo dispositivo fino all\'analisi.';

  @override
  String get aiSettingsSetupGuideTitle => 'Guida all\'installazione';

  @override
  String get aiSettingsSetupGuideBody =>
      'Per utilizzare questa funzionalità, è necessaria una chiave API di un fornitore di intelligenza artificiale. Google Gemini viene utilizzato come esempio principale perché attualmente offre un livello gratuito per sviluppatori e utenti.';

  @override
  String get aiSettingsGetApiKeyButton =>
      'Visualizza la guida all\'installazione';

  @override
  String get legal_document_version_value => '1.2';

  @override
  String get legal_document_last_updated_value => '20 maggio 2026';

  @override
  String get muscleChest => 'Petto';

  @override
  String get muscleBack => 'Indietro';

  @override
  String get muscleShoulders => 'Spalle';

  @override
  String get muscleBiceps => 'Bicipite';

  @override
  String get muscleTriceps => 'Tricipiti';

  @override
  String get muscleQuads => 'Quad';

  @override
  String get muscleHamstrings => 'Tendini del ginocchio';

  @override
  String get muscleGlutes => 'Glutei';

  @override
  String get muscleCalves => 'Vitelli';

  @override
  String get muscleLowerBack => 'Parte bassa della schiena';

  @override
  String get muscleAbs => 'Ass';

  @override
  String get muscleAdductors => 'Adduttori';

  @override
  String get muscleForearms => 'Avambracci';

  @override
  String get sleepDetailAnalysisHeader => 'Analisi dettagliata';

  @override
  String get sleepMetricDurationLabel => 'Durata del sonno';

  @override
  String get sleepMetricContinuityLabel => 'Continuità (WASO/SE)';

  @override
  String get sleepMetricDepthLabel => 'Profondità della fase del sonno';

  @override
  String get sleepMetricTimingLabel => 'Tempi circadiani';

  @override
  String get sleepMetricRegularityLabel => 'Regolarità';

  @override
  String get sleepBannerTstBottleneck =>
      'Penalità della durata del sonno attiva: il volume totale del sonno era inferiore all\'ottimale rigenerativo di 6,5 ore, il che limita il rilascio dell\'ormone anabolico.';

  @override
  String get sleepBannerRemBottleneck =>
      'Penalità per carenza di sonno REM: il tuo sonno REM è stato inferiore a 60 minuti. Ciò compromette il recupero neuronale e la freschezza mentale.';

  @override
  String get sleepBannerN3Bottleneck =>
      'Penalità per carenza di sonno profondo: mancanza critica di sonno profondo N3 (<70 min). La riparazione fisica del tessuto muscolare non è ottimale.';

  @override
  String get sleepBannerTimingBottleneck =>
      'Penalità di spostamento di fase circadiana: il tuo sonno intermedio è avvenuto dopo le 05:30. Dormire contro l’orologio interno riduce la qualità del sonno e la sensibilità all’insulina.';

  @override
  String get sleepBannerDefaultPenalty =>
      'Freno protettivo clinico attivo: il volume del sonno non era ottimale (<6 ore) o i tempi circadiani (inizio del sonno) erano notevolmente spostati. Il punteggio totale è stato limitato.';

  @override
  String get infoTdeeTitle => 'Stima adattiva delle calorie e del TDEE';

  @override
  String get infoTdeeExplanation =>
      'Stima la tua spesa energetica giornaliera totale (TDEE) in base al tuo profilo, ai pasti registrati e alle variazioni di peso corporeo.';

  @override
  String get infoTdeeKeyPoints =>
      '• Appiana le fluttuazioni giornaliere del peso utilizzando un modello di trend ricorsivo.\n• Utilizza un approccio di ispirazione bayesiana per adattare in modo conservativo gli obiettivi settimanali.\n• Avvisa se la coerenza della registrazione è troppo scarsa per aggiornamenti ad alta affidabilità.';

  @override
  String get infoTdeeTechnicalTitle =>
      'Filtraggio ricorsivo bayesiano e livellamento metabolico';

  @override
  String get infoTdeeTechnicalExplanation =>
      'Piuttosto che fare affidamento su formule statiche, Train Libre modella il tuo metabolismo come uno \"stato nascosto\" dinamico stimato ricorsivamente. Il mantenimento giornaliero osservato viene calcolato aggiustando l\'assunzione rispetto ai cambiamenti della massa corporea. Un coefficiente di rumore del processo viene aggiunto nei giorni non registrati per aumentare l’incertezza della stima, che smorza gli aggiornamenti e previene la distorsione dovuta alla ritenzione idrica a breve termine.';

  @override
  String get infoRecoveryTitle => 'Stima del recupero muscolare';

  @override
  String get infoRecoveryExplanation =>
      'Stima le curve di preparazione e recupero specifiche del muscolo in base al volume di allenamento, all\'intensità e alla prossimità al cedimento.';

  @override
  String get infoRecoveryKeyPoints =>
      '• Tiene conto dello stress muscolare sovrapposto (ad esempio, la distensione su panca conta per petto, tricipiti e spalle).\n• Ridimensiona la velocità di recupero in base a RIR/RPE ed estende la finestra per i set portati al fallimento.\n• Calibra le finestre di recupero di base in base alle dimensioni del gruppo muscolare e alle proprietà metaboliche.';

  @override
  String get infoRecoveryTechnicalTitle =>
      'Modello di fatica dell\'insieme equivalente e di decadimento a pezzi';

  @override
  String get infoRecoveryTechnicalExplanation =>
      'Calcola la prontezza dinamica tramite curve di decadimento non lineari. Il monitoraggio del volume distribuisce automaticamente il carico tra i gruppi muscolari primari e secondari. La velocità di recupero scala in base alla prossimità al fallimento (RIR) e applica una rigorosa estensione temporale per i set portati al fallimento assoluto.';

  @override
  String get infoScientificReferencesButton =>
      'Visualizza riferimenti scientifici e fonti';

  @override
  String get infoScientificDisclaimer =>
      'Questa funzionalità si basa su letteratura consolidata di scienze dello sport e modellazione metabolica. L\'elenco completo delle fonti peer-reviewed è disponibile sul nostro sito web.';

  @override
  String get infoAiMealTitle => 'Hub di acquisizione pasti AI';

  @override
  String get infoAiMealExplanation =>
      'Converte le foto dei pasti o le descrizioni testuali in voci di diario strutturato e le confronta con il database dei prodotti privato.';

  @override
  String get infoAiMealKeyPoints =>
      '• Traduce descrizioni imprecise (ad esempio, \"una fetta di pane\") in stime di peso metrico.\n• Confronta i suggerimenti dell\'intelligenza artificiale offline con il database dei prodotti locali sul tuo dispositivo.\n• Calcola la nutrizione localmente invece di delegare i calcoli a server esterni.';

  @override
  String get infoAiMealTechnicalTitle =>
      'Ibrida BYOK AI e abbinamento Jaro-Winkler';

  @override
  String get infoAiMealTechnicalExplanation =>
      'Utilizza un modello di privacy Bring-Your-Own-Key (BYOK). L\'intelligenza artificiale funziona strettamente come un livello di suggerimento. La corrispondenza viene eseguita offline utilizzando un filtro Jaro-Winkler tokenizzato rispetto al database SQLite locale. Al fornitore di intelligenza artificiale è severamente vietato eseguire calcoli nutrizionali tramite istruzioni di sistema.';

  @override
  String get infoSleepTitle => 'Qualità del sonno (SHS v3.5)';

  @override
  String get infoSleepExplanation =>
      'Calcola un indice del sonno completo in base a quantità, continuità, profondità, tempistica e regolarità quotidiana.';

  @override
  String get infoSleepKeyPoints =>
      '• Aggrega cinque dimensioni cliniche utilizzando una somma ponderata.\n• Ridimensiona automaticamente i requisiti se il tuo dispositivo indossabile non fornisce fasi specifiche o dati sull\'efficienza.\n• Ti protegge tramite moltiplicatori soft-cap che limitano il punteggio totale se un dominio critico (come REM o sonno profondo) è compromesso.';

  @override
  String get infoSleepTechnicalTitle =>
      'Baseline ponderata e soft-cap continui';

  @override
  String get infoSleepTechnicalExplanation =>
      'Aggrega cinque domini primari utilizzando una somma lineare ponderata: Durata (30%), Continuità (20%), Architettura (25%), Tempistica (15%) e Regolarità (10%). Per evitare medie fuorvianti quando un dominio clinico è compromesso, il punteggio finale viene degradato se vengono rilevati colli di bottiglia significativi nelle fasi del sonno o nei tempi circadiani.';

  @override
  String get tdeeRecalculationNotificationTitle => 'TDEE ricalcolato';

  @override
  String tdeeRecalculationNotificationBody(
      int calories, int protein, int carbs, int fat) {
    return 'Nuovi obiettivi giornalieri: $calories kcal | ${protein}g Proteine ​​| ${carbs}g Carboidrati | ${fat}g Grasso';
  }

  @override
  String recommendationBannerText(String delta) {
    return 'Nuovi target disponibili ($delta kcal).';
  }

  @override
  String get recommendationBannerApply => 'Fare domanda a';

  @override
  String get cancelingAndRollingBack => 'Annullamento, rollback sicuro...';

  @override
  String get sleepSyncTitle => 'Sincronizzazione della cronologia del sonno...';

  @override
  String get backupExportTitle => 'Esportazione del backup...';

  @override
  String get backupImportTitle => 'Importazione del backup...';

  @override
  String progressImportingNight(int index, int total) {
    return 'Importazione della notte $index/$total...';
  }

  @override
  String progressExportingTable(String table) {
    return 'Esportazione di $table...';
  }

  @override
  String progressImportingTable(String table) {
    return 'Ripristino di $table...';
  }

  @override
  String get shareDailyLogTitle => 'Registro giornaliero';

  @override
  String get shareSleepStartTime => 'Ora di inizio';

  @override
  String get shareSleepEndTime => 'Ora di fine';

  @override
  String get shareSleepDeep => 'Sonno profondo';

  @override
  String get shareSleepLight => 'Sonno leggero';

  @override
  String get shareSleepRem => 'Sonno REM';

  @override
  String get shareSleepAwake => 'Veglia/Interruzioni';

  @override
  String get shareTotalWater => 'Acqua/fluidi totali';

  @override
  String get shareNutritionSummary => 'Riepilogo nutrizione';

  @override
  String get shareSleepEfficiency => 'Efficienza';

  @override
  String get shareSleepRestingHeartRate => 'Frequenza cardiaca a riposo';

  @override
  String get shareAsTextOrCopy => 'Condividi / copia come testo';

  @override
  String get editExercise => 'Modifica esercizio';

  @override
  String exerciseCopyCreated(String exerciseName) {
    return 'Copia di \'$exerciseName\' creata.';
  }

  @override
  String get copySystemExerciseTitle => 'Copia esercizio di sistema';

  @override
  String get copySystemExerciseBody =>
      'Questo esercizio è fornito dal sistema e non può essere modificato direttamente. Vuoi crearne una copia personalizzata per modificarlo?';

  @override
  String get createCopyAndEdit => 'Crea copia e modifica';

  @override
  String get profileEdit => 'Modifica profilo';

  @override
  String get selectBirthday => 'Seleziona la data di nascita';

  @override
  String get exerciseNoteTitle => 'Nota esercizio';

  @override
  String get exerciseNoteHint => 'Inserisci note o suggerimenti...';

  @override
  String get deleteNoteTooltip => 'Elimina nota';

  @override
  String get emptyStateAddFirstExerciseSubtitle =>
      'Aggiungi un esercizio per iniziare a registrare.';

  @override
  String get syncRoutineTitle => 'Aggiorna routine?';

  @override
  String get syncRoutineSubtitle =>
      'Rilevate modifiche alla struttura o all\'ordine.';

  @override
  String syncRoutineBody(String routineName) {
    return 'Vuoi aggiornare la routine \'$routineName\' con i dati dell\'allenamento corrente (esercizi, ordine, serie)?';
  }

  @override
  String get discard => 'Scarta';

  @override
  String get updateNow => 'Aggiorna ora';

  @override
  String get syncRoutineSuccess => 'Routine aggiornata con successo!';

  @override
  String syncRoutineError(String error) {
    return 'Errore durante l\'aggiornamento della routine: $error';
  }

  @override
  String createRoutineError(String error) {
    return 'Errore durante la creazione della routine: $error';
  }

  @override
  String nutritionPerQuantity(String quantity) {
    return 'Valori nutrizionali per ${quantity}g';
  }

  @override
  String get settingsLocalModelName => 'Nome modello locale';

  @override
  String get settingsCustomBaseUrl => 'URL di base personalizzato';

  @override
  String get settingsCustomModelName => 'Nome modello personalizzato';

  @override
  String get settingsAiFoodNameLanguage => 'Lingua nomi alimenti IA';

  @override
  String get settingsRequestTimeout => 'Timeout richiesta';

  @override
  String settingsSeconds(int seconds) {
    return '$seconds secondi';
  }

  @override
  String get semanticsApplyRecommendation => 'Applica raccomandazione';

  @override
  String get semanticsDismissBanner => 'Chiudi banner';

  @override
  String get importedWorkout => 'Allenamento importato';

  @override
  String get unknownExercise => 'Esercizio sconosciuto';

  @override
  String get devExportBaseDb => 'Esporta database di base';

  @override
  String get initCheckingExercises => 'Verifica degli esercizi...';

  @override
  String get initLoadingRemoteManifest => 'Caricamento del manifesto remoto...';

  @override
  String get initExercisesUpToDate => 'Esercizi aggiornati';

  @override
  String get initNoDownloadRequired => 'Nessun download remoto richiesto.';

  @override
  String get initLoadingExercises => 'Caricamento degli esercizi...';

  @override
  String initDownloadingRemoteCatalog(String version) {
    return 'Download del catalogo degli esercizi remoto $version...';
  }

  @override
  String get initPreparingImport =>
      'Preparazione del download per l\'importazione...';

  @override
  String get initExercisesReady => 'Esercizi pronti';

  @override
  String initImportingRemoteCatalog(String version) {
    return 'Importazione del catalogo degli esercizi remoto $version...';
  }

  @override
  String initCheckingProductDatabase(String country) {
    return 'Verifica del database dei prodotti ($country)...';
  }

  @override
  String get initProductDatabaseUpToDate => 'Database prodotti aggiornato';

  @override
  String get initLoadingProductDatabase =>
      'Caricamento del database dei prodotti...';

  @override
  String initDownloadingProductBundle(String version) {
    return 'Download del pacchetto di prodotti remoto $version...';
  }

  @override
  String get initProductDatabaseReady => 'Database prodotti pronto';

  @override
  String initImportingProductBundle(String version) {
    return 'Importazione del pacchetto di prodotti remoto $version...';
  }

  @override
  String get initNoOffBundle =>
      'Nessun pacchetto OFF/remoto disponibile. I dati OFF locali esistenti rimangono invariati.';

  @override
  String initEntriesProgress(String processed, String totalCount) {
    return '$processed / $totalCount voci';
  }

  @override
  String initUpdateTask(String task) {
    return 'Aggiorna $task';
  }

  @override
  String initCheckingTask(String task) {
    return 'Verifica di $task...';
  }

  @override
  String initTaskUpToDate(String task) {
    return '$task aggiornato';
  }

  @override
  String get initInitializing => 'Inizializzazione...';

  @override
  String get initPreparation => 'Preparazione...';

  @override
  String get initReady => 'Pronto';

  @override
  String yearsOld(int age) {
    return '$age anni';
  }

  @override
  String get customFoodsTitle => 'Alimenti personalizzati';

  @override
  String get deleteFoodConfirmTitle => 'Elimina alimento';

  @override
  String get deleteFoodConfirmBody =>
      'Sei sicuro di voler eliminare questo alimento personalizzato? I registri storici non saranno influenzati.';

  @override
  String get foodItemDeleted => 'Alimento eliminato';

  @override
  String get copySystemFoodTitle => 'Copia alimento di sistema';

  @override
  String get copySystemFoodBody =>
      'Gli alimenti di sistema non possono essere modificati direttamente. Vuoi creare una copia personalizzata e modificarla?';

  @override
  String foodCopyCreated(String name) {
    return 'Copia creata: $name';
  }

  @override
  String get nutritionPer100g => 'Valori nutrizionali per 100g';

  @override
  String nutritionPerPortion(int grams) {
    return 'Valori nutrizionali per porzione (${grams}g)';
  }

  @override
  String get workoutConflictTitle => 'Allenamento in corso';

  @override
  String get workoutConflictContent =>
      'Hai già una sessione di allenamento attiva. Vuoi riprenderla o eliminarla per iniziarne una nuova?';

  @override
  String get resumeWorkoutButton => 'Riprendi allenamento';

  @override
  String get discardAndStartButton => 'Elimina e inizia nuovo';

  @override
  String get profileTapToSetUp => 'Tocca per configurare';

  @override
  String get customLabel => 'Personalizzato';

  @override
  String get noData => 'Nessun dato';

  @override
  String get languageAuto => 'Automatico';

  @override
  String aiValidationCostEstimation(num tokenCount) {
    return 'Costo: ~$tokenCount token';
  }

  @override
  String showAllWithCount(num count) {
    return 'Mostra tutti ($count)';
  }

  @override
  String repsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rip.',
      one: '1 rip.',
    );
    return '$_temp0';
  }

  @override
  String get offDownloadTitle => 'Scarica i cataloghi dei database';

  @override
  String get offDownloadBody =>
      'Per accedere alla ricerca completa dei prodotti offline, alla scansione dei codici a barre e alle funzioni IA, inizializza i cataloghi locali. Scaricherai le ultime versioni del database da GitHub.';

  @override
  String get offDownloadConfirm => 'Scarica ora';

  @override
  String get offDownloadCancel => 'Non ora';

  @override
  String get offDownloadCTA => 'Scarica il database';

  @override
  String get offPlaceholderText =>
      'Le funzioni nutrizionali richiedono il catalogo del database locale.';

  @override
  String get backupImportLockedTitle => 'Catalogo database richiesto';

  @override
  String get backupImportLockedBody =>
      'Prima di importare un backup, sia il catalogo degli esercizi che quello nutrizionale devono essere completamente scaricati e inizializzati per evitare incongruenze nei dati. Si prega di scaricare prima i database richiesti.';

  @override
  String get wgerPlaceholderText =>
      'Il catalogo degli esercizi richiede il caricamento del database locale.';

  @override
  String get onboardingRegionTitle => 'Seleziona regione';

  @override
  String get onboardingRegionExplanation =>
      'Seleziona il paese in cui acquisti la spesa. Ciò garantisce il download del database Open Food Facts corretto per i tuoi prodotti locali.';

  @override
  String get onboardingRegionSettingsHint =>
      'Puoi modificarlo in qualsiasi momento in Impostazioni → Nutrizione → Regione del database.';
}
