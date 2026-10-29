// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get selectDateTitle => 'Datum selecteren';

  @override
  String get selectTimeTitle => 'Tijd selecteren';

  @override
  String get selectDateTimeTitle => 'Datum en tijd selecteren';

  @override
  String get mealDetailChangeDateTime => 'Datum en tijd wijzigen';

  @override
  String mealMovedToDate(String date) {
    return 'Maaltijd verplaatst naar $date';
  }

  @override
  String get removeTimer => 'Timer verwijderen';

  @override
  String get connectSuperset => 'Als superset koppelen';

  @override
  String get disconnectSuperset => 'Superset ontbinden';

  @override
  String get connectSupersetShort => 'Superset';

  @override
  String get disconnectSupersetShort => 'Ontkoppelen';

  @override
  String get noTimerLabel => 'Geen timer';

  @override
  String get appTitle => 'Train Libre';

  @override
  String get bannerText => 'Aanbeveling / Huidige training';

  @override
  String get calories => 'Calorieën';

  @override
  String get water => 'Water';

  @override
  String get protein => 'Eiwitten';

  @override
  String get carbs => 'Koolhydraten';

  @override
  String get fat => 'Vetten';

  @override
  String get steps => 'Stappen';

  @override
  String get daily => 'Dagelijks';

  @override
  String get nowLabel => 'Nu';

  @override
  String get today => 'Vandaag';

  @override
  String get workoutSection => 'Trainingssectie – nog niet beschikbaar';

  @override
  String get addMenuTitle => 'Wat wil je toevoegen?';

  @override
  String get addFoodOption => 'Voedsel toevoegen';

  @override
  String get addLiquidOption => 'Drank toevoegen';

  @override
  String get searchHintText => 'Zoeken...';

  @override
  String get mealtypeBreakfast => 'Ontbijt';

  @override
  String get mealtypeLunch => 'Lunch';

  @override
  String get mealtypeDinner => 'Diner';

  @override
  String get mealtypeSnack => 'Tussendoortje';

  @override
  String get waterHeader => 'Water en dranken';

  @override
  String get openFoodFactsSource => 'Gegevens van Open Food Facts';

  @override
  String get tabRecent => 'Recent';

  @override
  String get tabSearch => 'Zoeken';

  @override
  String get tabFavorites => 'Favorieten';

  @override
  String get fabCreateOwnFood => 'Eigen voedingsmiddel';

  @override
  String get recentEmptyState =>
      'Voedingsmiddelen die je onlangs hebt gebruikt, verschijnen hier.';

  @override
  String get favoritesEmptyState =>
      'Je hebt nog geen favorieten.\nTik op het hartje bij een voedingsmiddel om het hier te zien.';

  @override
  String get searchInitialHint => 'Voer een zoekterm in.';

  @override
  String get searchNoResults => 'Geen resultaten gevonden.';

  @override
  String get createFoodScreenTitle => 'Eigen voedingsmiddel maken';

  @override
  String get formFieldName => 'Naam van het voedingsmiddel';

  @override
  String get formFieldBrand => 'Merk (optioneel)';

  @override
  String get formSectionMainNutrients =>
      'Belangrijkste voedingsstoffen (per 100 g)';

  @override
  String get formFieldCalories => 'Calorieën (kcal)';

  @override
  String get formFieldProtein => 'Eiwitten (g)';

  @override
  String get formFieldCarbs => 'Koolhydraten (g)';

  @override
  String get formFieldFat => 'Vetten (g)';

  @override
  String get formSectionOptionalNutrients =>
      'Extra voedingsstoffen (optioneel, per 100 g)';

  @override
  String get formFieldSugar => 'Waarvan suikers (g)';

  @override
  String get formFieldFiber => 'Vezels (g)';

  @override
  String get formFieldKj => 'Kilojoules (kJ)';

  @override
  String get formFieldSalt => 'Zout (g)';

  @override
  String get formFieldSodium => 'Natrium (mg)';

  @override
  String get formFieldCalcium => 'Calcium (mg)';

  @override
  String get buttonSave => 'Opslaan';

  @override
  String get validatorPleaseEnterName => 'Voer een naam in.';

  @override
  String get validatorPleaseEnterNumber => 'Voer een geldig getal in.';

  @override
  String snackbarSaveSuccess(String foodName) {
    return '$foodName is opgeslagen.';
  }

  @override
  String get foodDetailSegmentPortion => 'Portie';

  @override
  String get foodDetailSegment100g => '100 g';

  @override
  String get foodDetailEnergyGroup => 'Energie';

  @override
  String get foodDetailMacronutrientsGroup => 'Macronutriënten';

  @override
  String get foodDetailOtherNutrientsGroup => 'Overige voedingsstoffen';

  @override
  String get sugar => 'Suiker';

  @override
  String get fiber => 'Vezels';

  @override
  String get salt => 'Zout';

  @override
  String get caffeine => 'Cafeïne';

  @override
  String get nutritionScreenTitle => 'Voedingsanalyse';

  @override
  String get entriesForDateRangeLabel => 'Items voor';

  @override
  String get noEntriesForPeriod => 'Er zijn nog geen items voor deze periode.';

  @override
  String get waterEntryTitle => 'Water';

  @override
  String get profileScreenTitle => 'Profiel';

  @override
  String get profileDailyGoals => 'Dagelijkse doelen';

  @override
  String get profileDailyGoalsCL => 'DAGELIJKSE DOELEN';

  @override
  String get snackbarGoalsSaved => 'Doelen opgeslagen.';

  @override
  String get measurementsScreenTitle => 'Metingen';

  @override
  String get measurementsEmptyState =>
      'Er zijn nog geen metingen vastgelegd.\nGebruik de knop \'+\' om te beginnen.';

  @override
  String get addMeasurementDialogTitle => 'Meting toevoegen';

  @override
  String get formFieldMeasurementType => 'Soort meting';

  @override
  String formFieldMeasurementValue(Object unit) {
    return 'Waarde ($unit)';
  }

  @override
  String get validatorPleaseEnterValue => 'Voer een waarde in.';

  @override
  String get measurementWeight => 'Lichaamsgewicht';

  @override
  String get measurementFatPercent => 'Lichaamsvet';

  @override
  String get measurementNeck => 'Nek';

  @override
  String get measurementShoulder => 'Schouders';

  @override
  String get measurementChest => 'Borst';

  @override
  String get measurementLeftBicep => 'Linker bovenarm';

  @override
  String get measurementRightBicep => 'Rechter bovenarm';

  @override
  String get measurementLeftForearm => 'Linker onderarm';

  @override
  String get measurementRightForearm => 'Rechter onderarm';

  @override
  String get measurementAbdomen => 'Buik';

  @override
  String get measurementWaist => 'Taille';

  @override
  String get measurementHips => 'Heupen';

  @override
  String get measurementLeftThigh => 'Linkerbovenbeen';

  @override
  String get measurementRightThigh => 'Rechterbovenbeen';

  @override
  String get measurementLeftCalf => 'Linkerkuit';

  @override
  String get measurementRightCalf => 'Rechterkuit';

  @override
  String get drawerMenuTitle => 'Train Libre-menu';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerDataManagement => 'Back-up';

  @override
  String get drawerMeasurements => 'Metingen';

  @override
  String get dataManagementTitle => 'Back-up';

  @override
  String get exportCardTitle => 'Gegevens exporteren';

  @override
  String get exportCardDescription =>
      'Slaat al je dagboekitems, favorieten en eigen voedingsmiddelen op in één back-upbestand.';

  @override
  String get exportCardButton => 'Back-up maken';

  @override
  String get importCardTitle => 'Gegevens importeren';

  @override
  String get importCardDescription =>
      'Herstelt je gegevens vanuit een eerder gemaakt back-upbestand. WAARSCHUWING: alle gegevens die nu in de app staan, worden overschreven!';

  @override
  String get importCardButton => 'Back-up terugzetten';

  @override
  String get recommendationDefault => 'Registreer je eerste maaltijd!';

  @override
  String recommendationOverTarget(Object count, Object difference) {
    return 'Afgelopen $count dagen: +$difference kcal boven je doel';
  }

  @override
  String recommendationUnderTarget(Object count, Object difference) {
    return 'Afgelopen $count dagen: $difference kcal onder je doel';
  }

  @override
  String recommendationOnTarget(Object count) {
    return 'Afgelopen $count dagen: doel behaald ✅';
  }

  @override
  String get recommendationFirstEntry =>
      'Goed bezig, je eerste item is geregistreerd!';

  @override
  String get dialogConfirmTitle => 'Bevestiging vereist';

  @override
  String get dialogConfirmImportContent =>
      'Wil je de gegevens uit deze back-up echt terugzetten?\n\nWAARSCHUWING: al je huidige items, favorieten en eigen voedingsmiddelen worden permanent verwijderd en vervangen.';

  @override
  String get dialogButtonCancel => 'Annuleren';

  @override
  String get dialogButtonOverwrite => 'Ja, alles overschrijven';

  @override
  String get snackbarNoFileSelected => 'Geen bestand geselecteerd.';

  @override
  String get snackbarImportSuccessTitle => 'Importeren geslaagd';

  @override
  String get snackbarImportSuccessContent =>
      'Je gegevens zijn hersteld. Start de app opnieuw op om alles correct weer te geven.';

  @override
  String get snackbarButtonOK => 'OK';

  @override
  String get snackbarImportError => 'Fout bij het importeren van gegevens.';

  @override
  String get snackbarExportSuccess =>
      'Het back-upbestand is aan het systeem doorgegeven. Kies waar je het wilt opslaan.';

  @override
  String get snackbarExportFailed => 'Exporteren is geannuleerd of mislukt.';

  @override
  String get profileUserHeight => 'Lengte (cm)';

  @override
  String get workoutRoutinesTitle => 'Trainingsschema’s';

  @override
  String get workoutHistoryTitle => 'Trainingsgeschiedenis';

  @override
  String get workoutHistoryButton => 'Geschiedenis';

  @override
  String get emptyRoutinesTitle => 'Geen schema’s gevonden';

  @override
  String get emptyRoutinesSubtitle =>
      'Maak je eerste schema of begin een vrije training.';

  @override
  String get createFirstRoutineButton => 'Eerste schema maken';

  @override
  String get startEmptyWorkoutButton => 'Vrije training';

  @override
  String get editRoutineSubtitle =>
      'Tik om te bewerken of de training te starten.';

  @override
  String get startButton => 'Starten';

  @override
  String get addRoutineButton => 'Nieuw schema';

  @override
  String get freeWorkoutTitle => 'Vrije training';

  @override
  String get finishWorkoutButton => 'Voltooien';

  @override
  String get addSetButton => 'Set toevoegen';

  @override
  String get addExerciseToWorkoutButton => 'Oefening aan training toevoegen';

  @override
  String get lastTimeLabel => 'Vorige keer';

  @override
  String get setLabel => 'Set';

  @override
  String kgLabel(String unit) {
    return 'Gewicht ($unit)';
  }

  @override
  String get repsLabel => 'Herhalingen';

  @override
  String cardioDistanceLabel(String unit) {
    return 'Afstand ($unit)';
  }

  @override
  String get cardioTimeLabel => 'Tijd';

  @override
  String get cardioIntensityLabel => 'Intensiteit';

  @override
  String get cardioIntensityShortLabel => 'Intens.';

  @override
  String get restTimerLabel => 'Rust';

  @override
  String get pauseTimerLabel => 'Rusttimer';

  @override
  String get timerOffLabel => 'Uit';

  @override
  String get skipButton => 'Overslaan';

  @override
  String get appInitStarting => 'App starten…';

  @override
  String get appInitFailed =>
      'Train Libre kon niet starten. Je opgeslagen gegevens zijn niet gewist. Probeer het opnieuw.';

  @override
  String get appInitInitializing => 'Initialiseren…';

  @override
  String get appInitFinalizing => 'Afronden';

  @override
  String get appInitCheckingBackups => 'Back-ups controleren…';

  @override
  String get appInitSkipDownload => 'Download overslaan';

  @override
  String get appInitSkippingRemoteDownload => 'Externe download overslaan…';

  @override
  String get emptyHistory => 'Je hebt nog geen trainingen afgerond.';

  @override
  String get workoutDetailsTitle => 'Trainingsdetails';

  @override
  String get workoutHeartRateSectionTitle => 'Hartslag';

  @override
  String get workoutHeartRateAverageLabel => 'Gem.';

  @override
  String get workoutHeartRateMaxLabel => 'Max.';

  @override
  String get workoutHeartRateMinLabel => 'Min.';

  @override
  String get workoutHeartRateQualityReady => 'Goede dekking';

  @override
  String get workoutHeartRateQualityLimited => 'Beperkte gegevens';

  @override
  String get workoutHeartRateQualityInsufficient => 'Weinig gegevens';

  @override
  String get workoutHeartRateQualityNoData => 'Geen gegevens';

  @override
  String get workoutHeartRateNoDataGeneral =>
      'Er zijn geen hartslagmetingen gevonden voor deze training.';

  @override
  String get workoutHeartRateNoDataPermission =>
      'Je hebt toestemming nodig om de hartslag van deze training te bekijken.';

  @override
  String get workoutHeartRateNoDataUnavailable =>
      'Hartslaggegevens zijn momenteel niet beschikbaar op dit apparaat.';

  @override
  String get workoutHeartRateNoDataWorkoutNotFinished =>
      'Het hartslagoverzicht is beschikbaar nadat je de training hebt afgerond.';

  @override
  String get workoutHeartRateNoDataInvalidWindow =>
      'De trainingsperiode is ongeldig. De hartslag kan daarom niet worden geanalyseerd.';

  @override
  String get workoutHeartRateNoDataQueryFailed =>
      'De hartslaggegevens van deze training konden niet worden gelezen.';

  @override
  String get workoutHeartRateLimitedChartHint =>
      'Er zijn niet genoeg consistente metingen voor een betrouwbare grafiek.';

  @override
  String workoutHeartRateSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count metingen',
      one: '1 meting',
      zero: 'Geen metingen',
    );
    return '$_temp0';
  }

  @override
  String get workoutNotFound => 'Training niet gevonden.';

  @override
  String get totalVolumeLabel => 'Totaal volume';

  @override
  String get notesLabel => 'Notities';

  @override
  String get workoutImportTitle => 'Trainingen importeren';

  @override
  String get workoutImportDescription =>
      'Importeer je trainingsgeschiedenis uit een CSV- of Excel-exportbestand.';

  @override
  String workoutImportPreviewSummary(int workouts, int sets, int duplicates) {
    return '$workouts trainingen en $sets sets zijn klaar om te importeren. $duplicates bestaande trainingen worden overgeslagen.';
  }

  @override
  String get workoutImportHevyInstructions =>
      'Hevy-export herkend. Exporteer via Profiel > Instellingen > Gegevens exporteren en importeren > Gegevens exporteren > Trainingen exporteren.';

  @override
  String get workoutImportStrongInstructions =>
      'Strong-export herkend. Kies in Instellingen voor Strong-gegevens exporteren op iOS of Gegevens exporteren op Android.';

  @override
  String get workoutImportGenericInstructions =>
      'CSV- of Excel-bestand herkend. Controleer de gewichtseenheid voordat je importeert.';

  @override
  String workoutImportPreviewInvalidRows(int count) {
    return '$count rijen met ontbrekende of ongeldige datums worden overgeslagen.';
  }

  @override
  String get onboardingWorkoutImportHint =>
      'Houd je je trainingen al ergens anders bij? Importeer je geschiedenis in de volgende stap of later via Instellingen > Gegevens en back-up.';

  @override
  String get onboardingWorkoutImportTitle =>
      'Je trainingsgeschiedenis meenemen?';

  @override
  String get onboardingWorkoutImportDescription =>
      'Importeer je geschiedenis uit Hevy, Strong of een CSV-bestand. Je kunt eerst een voorbeeld bekijken.';

  @override
  String get onboardingWorkoutImportButton => 'Exportbestand kiezen';

  @override
  String get onboardingWorkoutImportLater => 'Doe ik later';

  @override
  String get onboardingWorkoutImportPrivacy =>
      'Je export wordt op dit apparaat verwerkt. Als anonieme statistieken zijn ingeschakeld, registreren we alleen of je een import start, overslaat of afrondt, nooit de trainingsgegevens.';

  @override
  String get workoutImportButton => 'Trainingsgegevens importeren';

  @override
  String workoutImportSuccess(Object count) {
    return '$count trainingen geïmporteerd.';
  }

  @override
  String get workoutImportFailed =>
      'Importeren mislukt. Controleer het bestand.';

  @override
  String get importUnitSelectionTitle => 'Importeenheid';

  @override
  String get importUnitSelectionDescription =>
      'In welke eenheid staan de gegevens in het bestand?';

  @override
  String get unitMetricLabel => 'Metrisch (kg)';

  @override
  String get unitImperialLabel => 'Imperiaal (lb)';

  @override
  String get excelExportButton => 'Alle gegevens exporteren (.xlsx)';

  @override
  String get exportWorkoutHistory => 'Trainingsgeschiedenis';

  @override
  String get exportNutritionDiary => 'Voedingsdagboek';

  @override
  String get exportMeasurements => 'Metingen';

  @override
  String get startWorkout => 'Training starten';

  @override
  String get addMeasurement => 'Meting toevoegen';

  @override
  String get filterToday => 'Vandaag';

  @override
  String get filter7Days => '7 dagen';

  @override
  String get filter30Days => '30 dagen';

  @override
  String get filter30DaysShort => '30 d';

  @override
  String get filter90DaysShort => '90 d';

  @override
  String get filter180DaysShort => '180 d';

  @override
  String get filter1DayShort => '1 d';

  @override
  String get filter7DaysShort => '7 d';

  @override
  String get filter1MonthShort => '1 mnd';

  @override
  String get filter3MonthsShort => '3 mnd';

  @override
  String get filter6MonthsShort => '6 mnd';

  @override
  String get filter1YearShort => '1 jr';

  @override
  String get filterMax => 'MAX.';

  @override
  String get filterAll => 'Alles';

  @override
  String get showLess => 'Minder tonen';

  @override
  String get showMoreDetails => 'Meer details tonen';

  @override
  String get deleteConfirmTitle => 'Verwijderen bevestigen';

  @override
  String get deleteConfirmContent => 'Wil je dit item echt verwijderen?';

  @override
  String get cancel => 'Annuleren';

  @override
  String get delete => 'Verwijderen';

  @override
  String get save => 'Opslaan';

  @override
  String get unsavedChangesTitle => 'Niet-opgeslagen wijzigingen';

  @override
  String get unsavedChangesContent =>
      'Je hebt wijzigingen niet opgeslagen. Wil je ze opslaan voordat je weggaat?';

  @override
  String get share => 'Delen';

  @override
  String get shareWorkout => 'Training delen';

  @override
  String get shareRoutine => 'Trainingsschema delen';

  @override
  String get shareAsImage => 'Als afbeelding delen';

  @override
  String get shareAsText => 'Als tekst delen';

  @override
  String get shareWebLink => 'Weblink delen';

  @override
  String get shareFormattedText => 'Als opgemaakte tekst delen';

  @override
  String get sharePortableJson => 'Als JSON / gegevens exporteren';

  @override
  String get shareCopyJson => 'JSON kopiëren';

  @override
  String get shareJsonCopied => 'JSON naar klembord gekopieerd';

  @override
  String get shareJsonFile => 'JSON-bestand delen';

  @override
  String get shareImportFile => 'Gedeeld JSON-bestand importeren';

  @override
  String get shareImportSectionTitle => 'Gedeelde inhoud importeren';

  @override
  String get shareImportSectionDescription =>
      'Importeer trainingsschema’s, trainingsplannen, recepten of trainingen uit een JSON-bestand, of plak JSON-tekst, zoals een AI-antwoord. Bekijk de inhoud voordat je importeert.';

  @override
  String get shareImportPasteButton => 'JSON-tekst plakken';

  @override
  String get shareImportPasteTitle => 'JSON-tekst importeren';

  @override
  String get shareImportPasteDescription =>
      'Plak hier de volledige Train Libre JSON-inhoud. Je kunt deze bekijken voordat je opslaat.';

  @override
  String get shareImportPasteHint => 'Plak JSON hier';

  @override
  String get shareImportReplaceWarning =>
      'De geopende inhoud wordt volledig vervangen. Afgeronde trainingen en oudere versies van trainingsplannen blijven behouden.';

  @override
  String get shareImportAddWarning =>
      'Deze inhoud wordt als nieuw item geïmporteerd. Bestaande trainingsschema’s, trainingsplannen, recepten en trainingen blijven ongewijzigd.';

  @override
  String get shareImportPreview => 'Gedeeld item importeren';

  @override
  String get shareImportConfirm => 'Importeren naar Train Libre';

  @override
  String get shareImportSuccess => 'Importeren geslaagd';

  @override
  String get shareImportInvalid =>
      'Dit gedeelde item kon niet worden geïmporteerd.';

  @override
  String get shareImportRetry => 'Opnieuw proberen';

  @override
  String get sharePlanWeekly => 'Weekplan';

  @override
  String get sharePlanSequence => 'Trainingsreeks';

  @override
  String get shareRestDay => 'Rustdag';

  @override
  String get shareDay => 'Dag';

  @override
  String get shareDays => 'dagen';

  @override
  String get sharePortions => 'Porties';

  @override
  String get shareIngredients => 'Ingrediënten';

  @override
  String get shareRestSeconds => 'Rust (seconden)';

  @override
  String get shareTargetMuscles => 'Doelspieren';

  @override
  String get shareTotal => 'Totaal';

  @override
  String get sharedFromTrainLibre => 'Gedeeld via Train Libre';

  @override
  String get sharedWithTrainLibre => 'Gedeeld met Train Libre';

  @override
  String get shareImageSummary => 'Overzicht';

  @override
  String get shareImageExercises => 'Oefeningen';

  @override
  String get shareImageMuscleFocus => 'Spiergroepen';

  @override
  String get shareImageMinimal => 'Minimaal';

  @override
  String get volume => 'Volume';

  @override
  String moreExercises(int count) {
    return '+ $count oefeningen meer';
  }

  @override
  String shareSetNumber(int number) {
    return 'Set $number';
  }

  @override
  String get repsShort => 'herh.';

  @override
  String get shareFailed => 'Delen mislukt';

  @override
  String get workoutShareTitle => 'Training';

  @override
  String get routineShareTitle => 'Trainingsschema';

  @override
  String get setTypeWarmup => 'Warming-up';

  @override
  String get setTypeWork => 'Werksets';

  @override
  String get setTypeFailure => 'Tot spierfalen';

  @override
  String get setTypeDropset => 'Dropset';

  @override
  String get setTypeSuperset => 'Superset';

  @override
  String get setTypeOther => 'Overig';

  @override
  String get setTypeWarmupSuffix => 'Warming-up';

  @override
  String get setTypeFailureSuffix => 'Tot falen';

  @override
  String get setTypeDropsetSuffix => 'Dropset';

  @override
  String get setTypeSupersetSuffix => 'Superset';

  @override
  String get setTypeOtherSuffix => 'Overig';

  @override
  String warmupSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opwarmsets',
      one: '1 opwarmset',
    );
    return '$_temp0';
  }

  @override
  String workSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count werksets',
      one: '1 werkset',
    );
    return '$_temp0';
  }

  @override
  String failureSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets tot spierfalen',
      one: '1 set tot spierfalen',
    );
    return '$_temp0';
  }

  @override
  String dropsetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dropsets',
      one: '1 dropset',
    );
    return '$_temp0';
  }

  @override
  String supersetSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count supersets',
      one: '1 superset',
    );
    return '$_temp0';
  }

  @override
  String otherSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overige sets',
      one: '1 overige set',
    );
    return '$_temp0';
  }

  @override
  String warmupCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opwarmsets',
      one: '1 opwarmset',
    );
    return '$_temp0';
  }

  @override
  String workCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count werksets',
      one: '1 werkset',
    );
    return '$_temp0';
  }

  @override
  String failureCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets tot spierfalen',
      one: '1 set tot spierfalen',
    );
    return '$_temp0';
  }

  @override
  String dropsetCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dropsets',
      one: '1 dropset',
    );
    return '$_temp0';
  }

  @override
  String supersetCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count supersets',
      one: '1 superset',
    );
    return '$_temp0';
  }

  @override
  String otherCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count andere sets',
      one: '1 andere set',
    );
    return '$_temp0';
  }

  @override
  String get shareExercisesLabel => 'oefeningen';

  @override
  String get shareSetsLabel => 'sets';

  @override
  String get shareSetLabel => 'set';

  @override
  String get tabBaseFoods => 'Basisvoedingsmiddelen';

  @override
  String get baseFoodsEmptyState =>
      'In dit onderdeel vind je binnenkort een samengestelde lijst met basisvoedingsmiddelen, zoals fruit, groenten en meer.';

  @override
  String get noBrand => 'Geen merk';

  @override
  String get unknown => 'Onbekend';

  @override
  String backupFileSubject(String timestamp) {
    return 'Train Libre-appback-up - $timestamp';
  }

  @override
  String foodItemSubtitle(String brand, int calories) {
    return '$brand - $calories kcal / 100 g';
  }

  @override
  String foodListSubtitle(int grams, String time) {
    return '$grams g - $time';
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
  String get exerciseCatalogTitle => 'Oefeningencatalogus';

  @override
  String get filterByMuscle => 'Filteren op spiergroep';

  @override
  String get noExercisesFound => 'Geen oefeningen gevonden.';

  @override
  String get noDescriptionAvailable => 'Geen beschrijving beschikbaar.';

  @override
  String get filterByCategory => 'Filteren op categorie';

  @override
  String get edit => 'Bewerken';

  @override
  String get repsLabelShort => 'herh.';

  @override
  String get titleNewRoutine => 'Nieuw trainingsschema';

  @override
  String get titleEditRoutine => 'Trainingsschema bewerken';

  @override
  String get editRoutine => 'Trainingsschema bewerken';

  @override
  String get validatorPleaseEnterRoutineName =>
      'Voer een naam in voor het trainingsschema.';

  @override
  String get snackbarRoutineCreated =>
      'Trainingsschema aangemaakt. Voeg nu oefeningen toe.';

  @override
  String get snackbarRoutineSaved => 'Trainingsschema opgeslagen.';

  @override
  String get saveAsRoutineButton => 'Opslaan als trainingsschema';

  @override
  String get saveAsRoutineTitle => 'Opslaan als trainingsschema';

  @override
  String get saveAsRoutinePrompt =>
      'Voer een naam in voor het nieuwe trainingsschema:';

  @override
  String get saveAsRoutineSuccess => 'Trainingsschema aangemaakt!';

  @override
  String get snackbarRoutineSavedAction => 'Bekijken';

  @override
  String get formFieldRoutineName => 'Naam van het trainingsschema';

  @override
  String get emptyStateAddFirstExercise => 'Voeg je eerste oefening toe.';

  @override
  String setCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String get fabAddExercise => 'Oefening toevoegen';

  @override
  String get drawerExerciseCatalog => 'Oefeningencatalogus';

  @override
  String get lastWorkoutTitle => 'Vorige training';

  @override
  String get repeatButton => 'Herhalen';

  @override
  String get weightHistoryTitle => 'Gewichtsgeschiedenis';

  @override
  String get hideSummary => 'Samenvatting verbergen';

  @override
  String get showSummary => 'Samenvatting tonen';

  @override
  String get exerciseDataAttribution => 'Oefengegevens van OpenExerciseDB';

  @override
  String get exerciseDataLicense => 'Licentie voor oefengegevens';

  @override
  String get exerciseDataUpstream => 'Deels afgeleid van wger';

  @override
  String get duplicate => 'Dupliceren';

  @override
  String deleteRoutineConfirmContent(String routineName) {
    return 'Weet je zeker dat je het trainingsschema ‘$routineName’ definitief wilt verwijderen?';
  }

  @override
  String get editPauseTimeTitle => 'Rustduur aanpassen';

  @override
  String get pauseInSeconds => 'Rust in seconden';

  @override
  String get editPauseTime => 'Rust aanpassen';

  @override
  String pauseDuration(int seconds) {
    return '$seconds seconden rust';
  }

  @override
  String maxPauseDuration(int seconds) {
    return 'Rust tot $seconds s';
  }

  @override
  String get deleteWorkoutConfirmContent =>
      'Weet je zeker dat je dit trainingslog definitief wilt verwijderen?';

  @override
  String get removeExercise => 'Oefening verwijderen';

  @override
  String get deleteExerciseConfirmTitle => 'Oefening verwijderen?';

  @override
  String deleteExerciseConfirmContent(String exerciseName) {
    return 'Weet je zeker dat je ‘$exerciseName’ uit dit trainingsschema wilt verwijderen?';
  }

  @override
  String get doneButtonLabel => 'Gereed';

  @override
  String get setRestTimeButton => 'Rusttijd instellen';

  @override
  String get deleteExerciseButton => 'Oefening verwijderen';

  @override
  String get deleteCustomExerciseTitle => 'Aangepaste oefening verwijderen';

  @override
  String deleteCustomExerciseBody(String name) {
    return '‘$name’ wordt definitief verwijderd. Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get deleteCustomExerciseWithLogsWarning =>
      'Deze oefening komt voor in je trainingsgeschiedenis. Je logs blijven bewaard, maar de koppeling met de oefening wordt verwijderd.';

  @override
  String get deleteCustomExerciseWithRoutinesWarning =>
      'Deze oefening wordt gebruikt in een of meer trainingsschema’s. De oefening wordt daaruit verwijderd.';

  @override
  String get deleteCustomExerciseSuccess => 'Oefening verwijderd.';

  @override
  String get restOverLabel => 'Rust is voorbij';

  @override
  String get workoutRunningLabel => 'Training is actief…';

  @override
  String get continueButton => 'Doorgaan';

  @override
  String get discardButton => 'Weggooien';

  @override
  String get workoutStatsTitle => 'Training (7 dagen)';

  @override
  String get workoutsLabel => 'Trainingen';

  @override
  String get durationLabel => 'Duur';

  @override
  String get clearDuration => 'Duur wissen';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get setsLabel => 'Sets';

  @override
  String get muscleSplitLabel => 'Spierverdeling';

  @override
  String get snackbar_could_not_open_open_link =>
      'Link kan niet worden geopend';

  @override
  String get chart_no_data_for_period =>
      'Geen grafiekgegevens voor deze periode';

  @override
  String get amount_in_milliliters => 'Hoeveelheid';

  @override
  String get amount_in_grams => 'Hoeveelheid in gram';

  @override
  String get meal_label => 'Maaltijd';

  @override
  String get add_to_water_intake => 'Toevoegen aan waterinname';

  @override
  String get create_exercise_screen_title => 'Aangepaste oefening maken';

  @override
  String get exercise_name_label => 'Naam van de oefening';

  @override
  String get category_label => 'Categorie';

  @override
  String get description_optional_label => 'Beschrijving (optioneel)';

  @override
  String get primary_muscles_label => 'Primaire spieren';

  @override
  String get primary_muscles_hint => 'bijv. borst, triceps';

  @override
  String get secondary_muscles_label => 'Secundaire spieren (optioneel)';

  @override
  String get secondary_muscles_hint => 'bijv. schouders';

  @override
  String get fluidNameLabel => 'Naam';

  @override
  String get sugarPer100mlLabel => 'Suiker (g / 100 ml)';

  @override
  String get set_type_normal => 'Normaal';

  @override
  String get set_type_warmup => 'Opwarmset';

  @override
  String get set_type_failure => 'Tot spierfalen';

  @override
  String get set_type_dropset => 'Dropset';

  @override
  String get set_type_info => 'Info en uitleg';

  @override
  String get set_type_normal_help =>
      'Een gewone werkset. Na het opwarmen is de eerste set meestal je focusset met het zwaarste gewicht; deze telt mee voor je progressie.';

  @override
  String get set_type_warmup_help =>
      'Warm op door het gewicht geleidelijk te verhogen. Deze set telt niet mee voor je progressie.';

  @override
  String get set_type_failure_help =>
      'Een werkset tot je geen herhalingen meer met goede techniek kunt uitvoeren. Deze telt mee voor je progressie.';

  @override
  String get set_type_dropset_help =>
      'Verlaag het gewicht direct na een werkset en ga door. Deze set telt niet mee voor je progressie.';

  @override
  String get set_reps_hint => '8-12';

  @override
  String get data_export_button => 'Exporteren';

  @override
  String get data_import_button => 'Importeren';

  @override
  String get snackbar_button_ok => 'OK';

  @override
  String get measurement_session_detail_view => 'Details van de meetsessie';

  @override
  String get unit_grams => 'g';

  @override
  String get unit_kcal => 'kcal';

  @override
  String get delete_profile_picture_button => 'Profielfoto verwijderen';

  @override
  String get attribution_title => 'Bronvermelding';

  @override
  String get add_liquid_title => 'Drank toevoegen';

  @override
  String get add_button => 'Toevoegen';

  @override
  String get discard_button => 'Weggooien';

  @override
  String get continue_workout_button => 'Training voortzetten';

  @override
  String get minimizeWorkoutButton => 'Minimaliseren';

  @override
  String get soon_available_snackbar => 'Dit scherm is binnenkort beschikbaar';

  @override
  String get start_button => 'Starten';

  @override
  String get today_overview_text => 'IN HET KORT';

  @override
  String get quick_add_text => 'SNEL TOEVOEGEN';

  @override
  String get scann_barcode_capslock => 'Barcode scannen';

  @override
  String get protocol_today_capslock => 'DAGBOEK';

  @override
  String get my_plans_capslock => 'MIJN PLANNEN';

  @override
  String get overview_capslock => 'OVERZICHT';

  @override
  String get manage_all_plans => 'Alle plannen beheren';

  @override
  String get workoutSectionStart => 'Starten';

  @override
  String get workoutSectionMyPlans => 'Mijn plannen';

  @override
  String get emptyStateWorkoutRoutinesCallout =>
      'Maak je eerste trainingsschema om je trainingen in de sportschool gestructureerd bij te houden.';

  @override
  String get workoutSectionHistoryLibrary => 'Geschiedenis en bibliotheek';

  @override
  String get workoutAllRoutines => 'Alle trainingsschema’s';

  @override
  String get workoutEntryWorkouts => 'Trainingen';

  @override
  String get free_training => 'vrije training';

  @override
  String get my_consistency => 'MIJN CONSISTENTIE';

  @override
  String get calendar_currently_not_available =>
      'De kalenderweergave is binnenkort beschikbaar.';

  @override
  String get datePickerCalendar => 'Kalenderweergave';

  @override
  String get datePickerWheel => 'Wielweergave';

  @override
  String get in_depth_analysis => 'DIEPGAANDE ANALYSE';

  @override
  String get body_measurements => 'Lichaamsmetingen';

  @override
  String get measurements_description =>
      'Bekijk je gewicht, lichaamsvetpercentage en omtrekmetingen.';

  @override
  String get nutrition_description => 'Bekijk macro’s, calorieën en trends.';

  @override
  String get training_analysis => 'Trainingsanalyse';

  @override
  String get training_analysis_description =>
      'Houd volume, kracht en progressie bij.';

  @override
  String get load_dots => 'laden…';

  @override
  String get profile_capslock => 'PROFIEL';

  @override
  String get settings_capslock => 'INSTELLINGEN';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsUpdateFoodDatabase => 'Databases bijwerken';

  @override
  String get settingsUpdateFoodDatabaseSubtitle =>
      'Controleer handmatig op updates voor de voedingsmiddelen- en oefeningendatabases.';

  @override
  String get settingsUpdateFoodDatabaseSuccess =>
      'De databases zijn bijgewerkt.';

  @override
  String settingsUpdateFoodDatabaseError(String error) {
    return 'Fout bij het bijwerken van de databases: $error';
  }

  @override
  String get settingsGuidedTourSectionTitle => 'Rondleiding';

  @override
  String get settingsRestartAppTourTitle => 'Rondleiding opnieuw starten';

  @override
  String get settingsRestartAppTourSubtitle =>
      'Doorloop de korte rondleiding in de app opnieuw.';

  @override
  String get my_goals => 'Mijn doelen';

  @override
  String get my_goals_description =>
      'Pas je calorieën, macro’s en waterinname aan.';

  @override
  String get backup_and_import => 'Back-up en gegevens importeren';

  @override
  String get backup_and_import_description =>
      'Maak back-ups, zet gegevens terug en importeer ze.';

  @override
  String get feedbackReportSettingsSectionTitle => 'Ondersteuning';

  @override
  String get feedbackReportSettingsEntryTitle => 'Feedback sturen';

  @override
  String get feedbackReportSettingsEntrySubtitle =>
      'Maak een lokaal diagnoserapport en kies hoe je het wilt delen.';

  @override
  String get about_and_legal_capslock => 'OVER EN JURIDISCH';

  @override
  String get feedbackReportScreenTitle => 'Feedbackrapport';

  @override
  String get feedbackReportPrivacyTitle => 'Privacy voorop';

  @override
  String get feedbackReportPrivacyBody =>
      'Dit rapport wordt lokaal op je apparaat gemaakt. Er wordt niets automatisch verzonden. Alleen wat je in het voorbeeld ziet, wordt opgenomen als je het kopieert, opslaat, deelt of per e-mail verstuurt. Je e-mailapp opent een concept aan feedback@schotte.me dat je kunt bekijken, aanpassen of annuleren voordat je het verstuurt.';

  @override
  String get feedbackReportOptionalNoteTitle => 'Optionele notitie';

  @override
  String get feedbackReportOptionalNoteLabel => 'Je notitie (optioneel)';

  @override
  String get feedbackReportOptionalNoteHint =>
      'Beschrijf wat er gebeurde, wat je verwachtte en hoe je het probleem kunt reproduceren.';

  @override
  String get feedbackReportIncludeSectionTitle => 'Opnemen in rapport';

  @override
  String get feedbackReportIncludeAdaptiveNutrition =>
      'Diagnostiek van adaptieve voeding';

  @override
  String get feedbackReportIncludeBackupRestore =>
      'Diagnostiek van back-up en herstel';

  @override
  String get feedbackReportIncludePerformance =>
      'Prestatielogboek (frametijden)';

  @override
  String get settingsPerformanceLogTitle => 'Prestatielogboek';

  @override
  String get settingsPerformanceLogSubtitle =>
      'Toont op welke schermen frames wegvallen';

  @override
  String get performanceLogIntro =>
      'Registreert de vernieuwingsfrequentie en weggevallen frames op dit apparaat. Het logboek loopt op de achtergrond en verlaat het apparaat alleen wanneer je het deelt.';

  @override
  String get performanceLogDeviceLabel => 'Apparaat';

  @override
  String get performanceLogDisplayLabel => 'Scherm';

  @override
  String get performanceLogFramesLabel => 'Frames';

  @override
  String get performanceLogJankLabel => 'Weggevallen frames';

  @override
  String get performanceLogStallsLabel => 'Blokkeringen';

  @override
  String get performanceLogCopyButton => 'Kopiëren';

  @override
  String get performanceLogShareButton => 'Delen';

  @override
  String get performanceLogCopiedSnack => 'Prestatielogboek gekopieerd.';

  @override
  String get performanceLogScreensSection => 'Schermen';

  @override
  String get performanceLogEmpty => 'Er zijn nog geen frames geregistreerd.';

  @override
  String get performanceLogStallsSection =>
      'Blokkeringen (UI-thread geblokkeerd)';

  @override
  String get performanceLogStartupSection => 'Opstarten en hervatten';

  @override
  String get performanceLogStartupEmpty => 'Opstarten is nog niet gemeten.';

  @override
  String get performanceLogStartupCold => 'Koude start';

  @override
  String get performanceLogStartupResume => 'Hervatten';

  @override
  String get performanceLogStartupUnattributed =>
      'Framework en eerste weergave';

  @override
  String get performanceLogSevereLabel => 'ernstig';

  @override
  String get performanceLogPauseTitle => 'Registratie pauzeren';

  @override
  String get performanceLogResetTitle => 'Metingen wissen';

  @override
  String get performanceLogResetDialogBody =>
      'Alle geregistreerde framestatistieken en blokkeringen worden verwijderd. Daarna begint de registratie opnieuw.';

  @override
  String get performanceLogResetConfirm => 'Wissen';

  @override
  String get performanceLogResetDoneSnack => 'Metingen gewist.';

  @override
  String get feedbackReportIncludeUserNote => 'Notitie van gebruiker';

  @override
  String get feedbackReportGeneratePreview => 'Voorbeeld maken';

  @override
  String get feedbackReportPreviewTitle => 'Voorbeeld';

  @override
  String get feedbackReportActionCopy => 'Kopiëren';

  @override
  String get feedbackReportActionSave => 'Opslaan';

  @override
  String get feedbackReportActionShare => 'Delen';

  @override
  String get feedbackReportActionEmail => 'E-mail';

  @override
  String get feedbackReportCopied => 'Rapport gekopieerd naar klembord.';

  @override
  String get feedbackReportSavedToTemporaryFile =>
      'Opgeslagen in een tijdelijk rapportbestand.';

  @override
  String get feedbackReportShareCompleted => 'Deelvenster geopend.';

  @override
  String get feedbackReportShareCanceled => 'Delen geannuleerd.';

  @override
  String get feedbackReportEmailOpenFailed =>
      'E-mailapp kon niet worden geopend.';

  @override
  String get feedbackReportEmailSubject => 'Train Libre-feedbackrapport';

  @override
  String get feedbackReportReportTitle => 'Train Libre-feedbackrapport';

  @override
  String get feedbackReportReportGeneratedAt => 'Gemaakt';

  @override
  String get feedbackReportReportAppVersion => 'Appversie';

  @override
  String get feedbackReportReportBuildNumber => 'Buildnummer';

  @override
  String get feedbackReportReportPlatform => 'Platform';

  @override
  String get feedbackReportReportOsVersion => 'OS-versie';

  @override
  String get feedbackReportUnavailable => 'niet beschikbaar';

  @override
  String get feedbackReportSectionUserNote => 'Notitie van gebruiker';

  @override
  String get feedbackReportSectionAdaptiveNutrition =>
      'Diagnostiek van adaptieve voeding';

  @override
  String get feedbackReportSectionBackupRestore =>
      'Diagnostiek van back-up en herstel';

  @override
  String get attribution_and_license => 'Bronvermelding en licenties';

  @override
  String get data_from_off_and_wger => 'Gegevens van Open Food Facts en wger.';

  @override
  String get app_version => 'Appversie';

  @override
  String get all_measurements => 'ALLE METINGEN';

  @override
  String get all_measurements_no_cap => 'Alle metingen';

  @override
  String get date_and_time_of_measurement => 'Datum en tijd van meting';

  @override
  String get onbWelcomeTitle => 'Welkom bij Train Libre';

  @override
  String get onbWelcomeBody =>
      'Stel eerst persoonlijke doelen in als leidraad voor je training en voeding.';

  @override
  String get onbTrackTitle => 'Houd alles bij';

  @override
  String get onbTrackBody =>
      'Houd je voeding, trainingen en metingen op één plek bij.';

  @override
  String get onbPrivacyTitle => 'Offline en privacyvriendelijk';

  @override
  String get onbPrivacyBody =>
      'Je gegevens blijven op je apparaat. Geen cloudaccounts of synchronisatie op de achtergrond.';

  @override
  String get onbFinishTitle => 'Klaar';

  @override
  String get onbFinishBody =>
      'Je kunt de app nu verkennen. Je kunt de instellingen altijd aanpassen.';

  @override
  String get onbFinishCta => 'Aan de slag!';

  @override
  String get onbShowTutorialAgain => 'Introductie opnieuw bekijken';

  @override
  String get appTourOfferTitle => 'Een korte rondleiding door de app?';

  @override
  String get appTourOfferBody =>
      'Bekijk een korte uitleg van de belangrijkste onderdelen van de app. Je kunt de rondleiding overslaan en later opnieuw starten via Instellingen.';

  @override
  String get appTourOfferStart => 'Rondleiding starten';

  @override
  String get appTourOfferSkip => 'Misschien later';

  @override
  String get appTourSkip => 'Overslaan';

  @override
  String get appTourNext => 'Volgende';

  @override
  String get appTourDone => 'Gereed';

  @override
  String get appTourStepNavigationTitle => 'Hoofdnavigatie';

  @override
  String get appTourStepNavigationBody =>
      'Gebruik de tabbladen onderaan om naar Dagboek, Training, Statistieken en Voeding te gaan.';

  @override
  String get appTourStepQuickActionsTitle => 'Snelle acties';

  @override
  String get appTourStepQuickActionsBody =>
      'Tik op de plusknop om snel voedingsmiddelen, drinken, metingen, trainingen en meer toe te voegen.';

  @override
  String get appTourStepDiaryTitle => 'Dagboek';

  @override
  String get appTourStepDiaryBody =>
      'In het Dagboek zie je je dag in één overzicht. Houd maaltijden, drinken en supplementen bij.';

  @override
  String get appTourStepWorkoutTitle => 'Training';

  @override
  String get appTourStepWorkoutBody =>
      'Bij Training start je sessies, beheer je trainingsschema’s en bekijk je je trainingsgeschiedenis.';

  @override
  String get appTourStepNutritionTitle => 'Voeding';

  @override
  String get appTourStepNutritionBody =>
      'Bij Voeding plan je maaltijden, bekijk je doelen en gebruik je hulpmiddelen zoals maaltijdtemplates.';

  @override
  String get appTourStepStatisticsTitle => 'Statistieken';

  @override
  String get appTourStepStatisticsBody =>
      'Statistieken tonen trends en voortgang, zodat je ziet hoe je gegevens in de loop van de tijd veranderen.';

  @override
  String get appTourRestartTitle => 'Rondleiding bekijken';

  @override
  String get appTourRestartSubtitle =>
      'Bekijk de introductie en belangrijkste functies opnieuw';

  @override
  String get onbSetGoalsCta => 'Doelen instellen';

  @override
  String get onbHeaderTitle => 'Tutorial';

  @override
  String get onbHeaderSkip => 'Overslaan';

  @override
  String get onbBack => 'Terug';

  @override
  String get onbNext => 'Volgende';

  @override
  String get onbGuideTitle => 'Zo werkt deze tutorial';

  @override
  String get onbGuideBody =>
      'Veeg tussen de schermen of tik op Volgende. Probeer functies uit met de knoppen op elk scherm. Je kunt op elk moment stoppen met Overslaan.';

  @override
  String get onbCtaOpenNutrition => 'Voeding openen';

  @override
  String get onbCtaLearnMore => 'Meer informatie';

  @override
  String get onbBadgeDone => 'Gereed';

  @override
  String get onbTipSetGoals => 'Tip: pas eerst je doelen aan';

  @override
  String get onbTipAddEntry => 'Tip: voeg vandaag een item toe';

  @override
  String get onbTipLocalControl => 'Je beheert al je gegevens lokaal';

  @override
  String get onbTrackHowBody =>
      'Voeding registreren:\n• Open het tabblad Voeding.\n• Tik op de knop +.\n• Zoek producten of scan een barcode.\n• Pas de portie en tijd aan.\n• Sla de registratie op in je dagboek.';

  @override
  String get onbMeasureTitle => 'Metingen bijhouden';

  @override
  String get onbMeasureBody =>
      'Metingen toevoegen:\n• Open het tabblad Statistieken.\n• Tik op de knop +.\n• Kies een meting (bijvoorbeeld gewicht, taille of lichaamsvet).\n• Voer de waarde en tijd in.\n• Sla de meting op in je geschiedenis.';

  @override
  String get onbTipMeasureToday =>
      'Tip: voeg je gewicht van vandaag toe om je grafiek te starten';

  @override
  String get onbTrainTitle => 'Train met schema’s';

  @override
  String get onbTrainBody =>
      'Maak een trainingsschema en start een training:\n• Open het tabblad Training.\n• Tik op Trainingsschema maken om oefeningen en sets toe te voegen.\n• Sla het schema op.\n• Tik op Starten of kies ‘Vrije training starten’.';

  @override
  String get onbTipStartWorkout =>
      'Tip: start een vrije training om snel een sessie te registreren';

  @override
  String get unitsSection => 'Eenheden';

  @override
  String get weightUnit => 'Gewichtseenheden';

  @override
  String get lengthUnit => 'Lengte-eenheid';

  @override
  String get comingSoon => 'Binnenkort beschikbaar';

  @override
  String get noFavorites => 'Geen favorieten';

  @override
  String get nothingTrackedYet => 'Er is nog niets bijgehouden';

  @override
  String snackbarBarcodeNotFound(String barcode) {
    return 'Geen product gevonden voor barcode “$barcode”.';
  }

  @override
  String get categoryHint => 'bijv. borst, rug, benen…';

  @override
  String get validatorPleaseEnterCategory => 'Voer een categorie in.';

  @override
  String get dialogEnterPasswordImport =>
      'Voer het wachtwoord in om de back-up te importeren';

  @override
  String get dataManagementBackupTitle => 'Train Libre-gegevensback-up';

  @override
  String get dataManagementBackupDescription =>
      'Maak een back-up van je Train Libre-gegevens en voorbeeldafbeeldingen of herstel ze. Originele foto’s blijven op dit apparaat.';

  @override
  String get exportEncrypted => 'Versleuteld exporteren';

  @override
  String get dialogPasswordForExport => 'Wachtwoord voor versleutelde export';

  @override
  String get snackbarEncryptedBackupShared => 'Versleutelde back-up gedeeld.';

  @override
  String get exportFailed => 'Exporteren mislukt.';

  @override
  String get csvExportTitle => 'Gegevens exporteren';

  @override
  String get csvExportDescription =>
      'Exporteer geselecteerde gegevens als CSV-bestanden of alle persoonlijke tabelgegevens in één Excel-werkmap. Gebruik een back-up om gegevens terug te zetten.';

  @override
  String get snackbarSharingNutrition => 'Voedingsdagboek delen…';

  @override
  String get snackbarExportFailedNoEntries =>
      'Exporteren mislukt. Er zijn mogelijk nog geen gegevens.';

  @override
  String get snackbarSharingMeasurements => 'Metingen delen…';

  @override
  String get snackbarSharingWorkouts => 'Trainingsgeschiedenis delen…';

  @override
  String get mapExercisesTitle => 'Oefeningen koppelen';

  @override
  String get mapExercisesDescription =>
      'Koppel onbekende namen uit je logs aan oefeningen van wger.';

  @override
  String get mapExercisesButton => 'Koppelen starten';

  @override
  String get autoBackupTitle => 'Automatische back-ups';

  @override
  String get autoBackupDescription =>
      'Maakt regelmatig een back-up in deze map. Huidige map:';

  @override
  String get autoBackupDefaultFolder => 'App-documenten/Back-ups (standaard)';

  @override
  String get autoBackupChooseFolder => 'Map kiezen';

  @override
  String get autoBackupCopyPath => 'Pad kopiëren';

  @override
  String get autoBackupRunNow => 'Automatische back-up controleren en starten';

  @override
  String get icloudAutoBackupTitle => 'Automatische iCloud-back-up';

  @override
  String get icloudAutoBackupDescription =>
      'Synchroniseert je database automatisch met iCloud Drive wanneer de app naar de achtergrond gaat. Je kunt je gegevens herstellen op een nieuw apparaat of na een herinstallatie.';

  @override
  String get icloudBackupNow => 'Nu een back-up maken in iCloud';

  @override
  String get icloudBackupUploading => 'Uploaden…';

  @override
  String get icloudBackupSuccess => 'Back-up geüpload.';

  @override
  String get icloudBackupFailed =>
      'Back-up mislukt. Controleer je iCloud-verbinding.';

  @override
  String get autoBackupRequestAccessSubtitle =>
      'Voor automatische back-ups heeft Train Libre toegang nodig tot een map die je kiest. Je back-ups worden daar opgeslagen.';

  @override
  String get snackbarAutoBackupSuccess => 'Automatische back-up voltooid.';

  @override
  String get snackbarAutoBackupFailed =>
      'Automatische back-up mislukt of geannuleerd.';

  @override
  String get localDataDeletionCardTitle => 'Lokale appgegevens';

  @override
  String get localDataDeletionCardDescription =>
      'Verwijder definitief je gegevens op dit apparaat en zet Train Libre terug naar een lege lokale staat.';

  @override
  String get deleteAllLocalAppData => 'Alle lokale appgegevens verwijderen';

  @override
  String get localDataDeletionConfirmTitle =>
      'Alle lokale gegevens verwijderen?';

  @override
  String get localDataDeletionConfirmBody =>
      'Hiermee verwijder je definitief lokaal opgeslagen trainingen, voedingslogs, metingen, supplementen, instellingen en status, gecachte analyses en andere lokale appgegevens.\n\nGegevens die al naar Apple Health of Health Connect zijn geëxporteerd, worden niet verwijderd.\n\nGegevens van externe aanbieders en openbare catalogi op afstand worden ook niet verwijderd. Gebundelde appbestanden en vereiste standaardcatalogi blijven behouden of worden opnieuw aangemaakt, zodat de app na het resetten kan starten.';

  @override
  String get localDataDeletionTypeDeleteLabel => 'Typ DELETE om te bevestigen';

  @override
  String get localDataDeletionSuccessTitle => 'Lokale gegevens verwijderd';

  @override
  String get localDataDeletionSuccessBody =>
      'Train Libre keert terug naar de eerste configuratie.';

  @override
  String get localDataDeletionFailed =>
      'Lokale gegevens konden niet worden verwijderd. Probeer het opnieuw.';

  @override
  String get noUnknownExercisesFound => 'Geen onbekende oefeningen gevonden';

  @override
  String snackbarAutoBackupFolderSet(String path) {
    return 'Map voor automatische back-ups ingesteld:\n$path';
  }

  @override
  String get snackbarPathCopied => 'Pad gekopieerd';

  @override
  String get passwordLabel => 'Wachtwoord';

  @override
  String get descriptionLabel => 'Beschrijving';

  @override
  String get involvedMuscles => 'Betrokken spieren';

  @override
  String get primaryLabel => 'Primair:';

  @override
  String get secondaryLabel => 'Secundair:';

  @override
  String get noMusclesSpecified => 'Geen spieren opgegeven.';

  @override
  String get frontLabel => 'Voorkant';

  @override
  String get backLabel => 'Achterkant';

  @override
  String get noSelection => 'Geen selectie';

  @override
  String get selectButton => 'Selecteren';

  @override
  String get applyingChanges => 'Wijzigingen toepassen…';

  @override
  String get applyMapping => 'Koppeling toepassen';

  @override
  String get mappingSuggestions => 'Suggesties';

  @override
  String get mappingSuggestionsEmpty =>
      'Geen overeenkomende oefeningen gevonden';

  @override
  String get personalData => 'Persoonlijke gegevens';

  @override
  String get personalDataCL => 'PERSOONLIJKE GEGEVENS';

  @override
  String get macroDistribution => 'Verdeling van macronutriënten';

  @override
  String get dialogFinishWorkoutBody =>
      'Weet je zeker dat je deze training wilt afronden?';

  @override
  String get attributionText =>
      'Deze app gebruikt gegevens uit externe bronnen:\n\n● Oefengegevens van OpenExerciseDB (github.com/rfivesix/OpenExerciseDB), onder licentie CC BY-SA 4.0 en deels afgeleid van het project wger (wger.de).\n\n● Voedingsmiddelendatabase van Open Food Facts (openfoodfacts.org), beschikbaar onder de Open Database License (ODbL).\n\n● Voedingsstoffengegevens voor basisvoedingsmiddelen uit de Bundeslebensmittelschlüssel (BLS) 4.0, uitgegeven door het Max Rubner-Institut, DOI 10.25826/Data20251217-134202-0, onder licentie CC BY 4.0. Train Libre voegt vertalingen, zoekaliassen en categorieën toe.';

  @override
  String get errorRoutineNotFound => 'Trainingsschema niet gevonden';

  @override
  String get workoutHistoryEmptyTitle => 'Je geschiedenis is leeg';

  @override
  String get workoutSummaryTitle => 'Training afgerond';

  @override
  String get workoutSummaryExerciseOverview => 'Oefeningenoverzicht';

  @override
  String get nutritionDiary => 'Dagboek';

  @override
  String get detailedNutrientGoals => 'Gedetailleerde voedingsstoffen';

  @override
  String get detailedNutrientGoalsCL => 'GEDETAILLEERDE VOEDINGSSTOFFEN';

  @override
  String get supplementTrackerTitle => 'Supplementen bijhouden';

  @override
  String get supplementTrackerDescription =>
      'Houd doelen, limieten en inname bij.';

  @override
  String get createSupplementTitle => 'Supplement aanmaken';

  @override
  String get supplementNameLabel => 'Naam van supplement';

  @override
  String get defaultDoseLabel => 'Standaarddosering';

  @override
  String get unitLabel => 'Eenheid';

  @override
  String get dailyGoalLabel => 'Dagelijks doel (optioneel)';

  @override
  String get dailyLimitLabel => 'Dagelijkse limiet (optioneel)';

  @override
  String get dailyProgressTitle => 'Dagelijkse voortgang';

  @override
  String get todaysLogTitle => 'Logboek van vandaag';

  @override
  String get logIntakeTitle => 'Inname registreren';

  @override
  String get emptySupplementGoals =>
      'Stel doelen of limieten in voor supplementen om je voortgang hier te zien.';

  @override
  String get emptySupplementLogs =>
      'Je hebt vandaag nog geen inname geregistreerd.';

  @override
  String get doseLabel => 'Dosering';

  @override
  String get settingsDescription => 'Thema, eenheden, gegevens en meer';

  @override
  String get settingsAppearance => 'Weergave';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Donker';

  @override
  String get caffeinePrompt => 'Cafeïne (optioneel)';

  @override
  String get caffeineUnit => 'mg per 100 ml';

  @override
  String get profile => 'Profiel';

  @override
  String get measurementWeightCapslock => 'LICHAAMSGEWICHT';

  @override
  String get diary => 'Dagboek';

  @override
  String get analysis => 'Analyse';

  @override
  String get yesterday => 'Gisteren';

  @override
  String get dayBeforeYesterday => 'Eergisteren';

  @override
  String get statistics => 'Statistieken';

  @override
  String get workout => 'Training';

  @override
  String get addFoodTitle => 'voedingsmiddel toevoegen';

  @override
  String get nutritionExplorerTitle => 'Voedingsverkenner';

  @override
  String get myMeals => 'Mijn recepten';

  @override
  String get myMealsCL => 'MIJN RECEPTEN';

  @override
  String get nutritionSectionTodayInFocus => 'Vandaag in beeld';

  @override
  String get nutritionSectionMyMeals => 'Mijn recepten';

  @override
  String get emptyStateNutritionRecipesCallout =>
      'Maak je eerste recept om je gebruikelijke maaltijden snel te registreren.';

  @override
  String get nutritionSectionToolsAndLibrary => 'Hulpmiddelen en bibliotheek';

  @override
  String get supplement_caffeine => 'Cafeïne';

  @override
  String get supplement_creatine_monohydrate => 'Creatinemonohydraat';

  @override
  String get manageSupplementsTitle => 'Supplementen beheren';

  @override
  String get deleted => 'verwijderd';

  @override
  String get operationNotAllowed => 'Deze handeling is niet toegestaan';

  @override
  String get emptySupplements => 'Geen supplementen beschikbaar';

  @override
  String get undo => 'Ongedaan maken';

  @override
  String get deleteSupplementConfirm =>
      'Weet je zeker dat je dit supplement wilt verwijderen? Alle historische gegevens gaan verloren.\n\nTip: je kunt het ook niet meer bijhouden door het supplement te bewerken.';

  @override
  String get editSupplementLogTitle => 'Registratie bewerken';

  @override
  String get deleteSupplementLogConfirm =>
      'Weet je zeker dat je deze registratie wilt verwijderen?';

  @override
  String get fieldRequired => 'Verplicht';

  @override
  String get unitNotSupported => 'Eenheid niet ondersteund.';

  @override
  String get caffeineUnitLocked => 'Voor cafeïne staat de eenheid vast: mg.';

  @override
  String get caffeineMustBeMg => 'Cafeïne moet in mg worden geregistreerd.';

  @override
  String get tabCatalogSearch => 'Catalogus';

  @override
  String get tabMeals => 'Recepten';

  @override
  String get emptyCategory => 'Geen gegevens';

  @override
  String get searchSectionBase => 'Basisvoedingsmiddelen';

  @override
  String get searchSectionOther => 'Overige resultaten';

  @override
  String get mealsComingSoonTitle => 'Recepten (binnenkort)';

  @override
  String get mealsComingSoonBody =>
      'Binnenkort kun je zelf recepten maken met meerdere voedingsmiddelen.';

  @override
  String get mealsEmptyTitle => 'Geen recepten opgeslagen';

  @override
  String get mealsEmptyBody =>
      'Maak recepten om meerdere voedingsmiddelen tegelijk te registreren.';

  @override
  String get mealsEmptyBodyWithShortcut =>
      'Gebruik in het dagboek de optie ‘Opslaan als recept’ onder je ontbijt of avondeten om combinaties van voedingsmiddelen als snel sjabloon op te slaan.';

  @override
  String get mealsCreateManually => 'Recept handmatig maken';

  @override
  String get saveMealTemplateShortcut => 'Opslaan als recept';

  @override
  String get mealsCreate => 'Recept maken';

  @override
  String get mealsEdit => 'Recept bewerken';

  @override
  String get mealsDelete => 'Recept verwijderen';

  @override
  String get mealsAddToDiary => 'Voedingsmiddel toevoegen';

  @override
  String get mealNameLabel => 'Naam van recept';

  @override
  String get mealNotesLabel => 'Notities';

  @override
  String get mealIngredientsTitle => 'Ingrediënten';

  @override
  String get mealAddIngredient => 'Ingrediënt toevoegen';

  @override
  String get mealIngredientAmountLabel => 'Hoeveelheid';

  @override
  String get mealTotalAmountLabel => 'Totale hoeveelheid van recept';

  @override
  String get mealWeightBasisLabel => 'Toestand';

  @override
  String get mealWeightBasisRaw => 'Rauw';

  @override
  String get mealWeightBasisCooked => 'Bereid';

  @override
  String get mealPreviewBasisLabel => 'Voorbeeld aanpassen op basis van';

  @override
  String get mealTotalNutrientsLabel => 'totaal';

  @override
  String mealTotalAmountHint(int grams) {
    return 'Heel recept: $grams g. De hoeveelheden van de ingrediënten worden evenredig aangepast.';
  }

  @override
  String get mealServingCountLabel => 'Porties in recept';

  @override
  String get mealServingCountHint =>
      'Het aantal porties van het volledige recept.';

  @override
  String get mealCookedWeightLabel => 'Eindgewicht na bereiding';

  @override
  String get mealCookedWeightHint =>
      'Optioneel: weeg het bereide recept om porties in gram nauwkeurig te berekenen.';

  @override
  String mealServingsSummary(String count) {
    return '$count porties';
  }

  @override
  String mealCookedWeightSummary(String weight) {
    return '$weight g bereid';
  }

  @override
  String get mealPortionAmountLabel => 'Gegeten porties';

  @override
  String get mealDecreasePortion => '0,5 portie minder';

  @override
  String get mealIncreasePortion => '0,5 portie meer';

  @override
  String mealPortionAmountHint(int count) {
    return 'Opgeslagen recept: $count porties';
  }

  @override
  String get mealDuplicate => 'Recept dupliceren';

  @override
  String get mealCopySuffix => '(kopie)';

  @override
  String get mealDeleteConfirmTitle => 'Recept verwijderen';

  @override
  String mealDeleteConfirmBody(Object name) {
    return 'Weet je zeker dat je het recept ‘$name’ wilt verwijderen? Alle ingrediënten worden ook verwijderd.';
  }

  @override
  String mealAddedToDiary(Object name) {
    return 'Recept ‘$name’ is aan je dagboek toegevoegd.';
  }

  @override
  String get mealSaved => 'Recept opgeslagen.';

  @override
  String get mealDeleted => 'Recept verwijderd.';

  @override
  String get confirm => 'Bevestigen';

  @override
  String get addMealToDiaryTitle => 'Toevoegen aan dagboek';

  @override
  String get mealTypeLabel => 'Recept';

  @override
  String get amountLabel => 'Hoeveelheid';

  @override
  String get mealAddedToDiarySuccess => 'Recept aan dagboek toegevoegd';

  @override
  String get error => 'Fout';

  @override
  String get mealsViewTitle => 'Recepten';

  @override
  String get noNotes => 'Geen notities';

  @override
  String get ingredientsCapsLock => 'INGREDIËNTEN';

  @override
  String get nutritionSectionLabel => 'VOEDINGSWAARDEN';

  @override
  String get nutritionCalculatedForCurrentAmounts =>
      'voor de huidige hoeveelheden';

  @override
  String get startCapsLock => 'START';

  @override
  String get nutritionHubSubtitle =>
      'Ontdek hier binnenkort inzichten, houd maaltijden bij en plan je voeding.';

  @override
  String get nutritionHubTitle => 'Voeding';

  @override
  String get nutrition => 'Voeding';

  @override
  String get changeSetTypTitle => 'Settype wijzigen';

  @override
  String get settingsVisualStyleTitle => 'Visuele stijl';

  @override
  String get settingsVisualStyleStandard => 'Matglas';

  @override
  String get settingsVisualStyleLiquid => 'Liquid Glass (vloeiend)';

  @override
  String get settingsVisualStyleLiquidDesc =>
      'Afgeronde, zwevende interface-elementen';

  @override
  String get settingsMaterialColorsTitle => 'Material-kleuren';

  @override
  String get settingsMaterialColorsSubtitle =>
      'Gebruik dynamische systeemkleuren (Material You) in plaats van de Train Libre-merkkleur';

  @override
  String get settingsAppColorTitle => 'Appkleur';

  @override
  String get settingsAppColorSubtitle =>
      'Kies een accentkleur die zich aanpast aan de lichte en donkere modus.';

  @override
  String get appColorPresetTrainLibre => 'Train Libre';

  @override
  String get appColorPresetMonochrome => 'Zwart-wit';

  @override
  String get appColorPresetBlue => 'Blauw';

  @override
  String get appColorPresetTeal => 'Turkoois';

  @override
  String get appColorPresetPurple => 'Paars';

  @override
  String get appColorPresetOrange => 'Oranje';

  @override
  String get appColorPresetRose => 'Roze';

  @override
  String get appColorPresetCustom => 'Aangepast';

  @override
  String get appColorPresetSystem => 'Systeemkleuren';

  @override
  String get appColorCustomDialogTitle => 'Kies een kleur';

  @override
  String get appColorHexLabel => 'Hexkleur';

  @override
  String get appColorHexInvalid => 'Voer een hexkleur van 6 cijfers in.';

  @override
  String get appColorHexOutOfRange =>
      'Kies een kleur met een helderheid van 40–82%.';

  @override
  String get appColorHueLabel => 'Tint';

  @override
  String get appColorSaturationLabel => 'Verzadiging';

  @override
  String get appColorBrightnessLabel => 'Helderheid';

  @override
  String get appColorCancel => 'Annuleren';

  @override
  String get appColorApply => 'Toepassen';

  @override
  String get settingsFoodDbSectionTitle => 'Voedingsmiddelendatabase';

  @override
  String get settingsFoodDbRegionTitle => 'Regio voedingsmiddelendatabase';

  @override
  String get settingsFoodDbRegionSubtitle =>
      'Kies welke regio van de Open Food Facts-productcatalogus wordt gebruikt om voedingsmiddelen te zoeken.';

  @override
  String get settingsFoodDbRegionCurrent => 'Huidige regio';

  @override
  String get settingsFoodDbRegionDialogTitle =>
      'Regio voedingsmiddelendatabase kiezen';

  @override
  String get settingsFoodDbRegionDialogSubtitle =>
      'Hiermee wijzig je de Open Food Facts-catalogus die wordt gebruikt om producten te zoeken.';

  @override
  String get settingsFoodDbRegionSearchPlaceholder => 'Regio zoeken…';

  @override
  String get settingsFoodDbRegionNoResults => 'Geen regio gevonden';

  @override
  String get settingsFoodDbRegionIssueHint =>
      'Staat je land er nog niet bij? Open gerust een issue op GitHub om ondersteuning aan te vragen.';

  @override
  String get settingsFoodDbRegionGermany => 'Duitsland (DE)';

  @override
  String get settingsFoodDbRegionSwitzerland => 'Zwitserland (CH)';

  @override
  String get settingsFoodDbRegionUnitedStates => 'Verenigde Staten (US)';

  @override
  String get settingsFoodDbRegionFrance => 'Frankrijk (FR)';

  @override
  String get settingsFoodDbRegionItaly => 'Italië (IT)';

  @override
  String get settingsFoodDbRegionJapan => 'Japan (JP)';

  @override
  String get settingsFoodDbRegionAustria => 'Oostenrijk (AT)';

  @override
  String get settingsFoodDbRegionNetherlands => 'Nederland (NL)';

  @override
  String get settingsFoodDbRegionSpain => 'Spanje (ES)';

  @override
  String get settingsFoodDbRegionAustralia => 'Australië (AU)';

  @override
  String get settingsColorfulMacroBadgesTitle => 'Kleurrijke macrobadges';

  @override
  String get settingsColorfulMacroBadgesSubtitle =>
      'Gebruikt ook in het dagboek de gekleurde badges van de AI-controle.';

  @override
  String get settingsFoodDbRegionUnitedKingdom => 'Verenigd Koninkrijk (UK)';

  @override
  String settingsFoodDbRegionChanged(String region) {
    return 'Regio voedingsmiddelendatabase ingesteld op $region. De wijziging geldt na de volgende catalogusvernieuwing of import.';
  }

  @override
  String get searchBaseFoodHint => 'Basisvoedingsmiddelen zoeken';

  @override
  String get searchNoHits => 'Geen resultaten.';

  @override
  String get onbSubtitleWelcome =>
      'De centrale plek voor je training, voeding en voortgang.';

  @override
  String get onbBodyWelcome =>
      'Stel doelen in en houd ze bij. Registreer eenvoudig trainingen, voeding, supplementen en lichaamsmetingen.';

  @override
  String get onbBodyNutritionVisual =>
      'Registreer maaltijden in een paar tikken. Houd calorieën, macro’s en water bij om je doel eenvoudig te volgen.';

  @override
  String get onbBodyMeasurementsVisual =>
      'Bekijk je voortgang. De grafiek met gewicht en omtrekmetingen maakt je vooruitgang zichtbaar en houdt je gemotiveerd.';

  @override
  String get onbBodyWorkoutVisual =>
      'Maak trainingsschema’s en begin binnen enkele seconden met trainen. Registreer sets, gewichten en rusttijden om maximaal vooruitgang te boeken.';

  @override
  String get onbTitleAppLayout => 'Navigatie en snel toevoegen';

  @override
  String get onbBodyAppLayout =>
      'Met de balk onderaan wissel je snel tussen onderdelen. Tik op de grote [+]-knop om direct iets te registreren.';

  @override
  String get dataHubTitle => 'Gegevenscentrum';

  @override
  String get resumeButton => 'Hervatten';

  @override
  String get onboardingWelcomeTitle => 'Welkom bij Train Libre';

  @override
  String get onboardingWelcomeSubtitle =>
      'Stel je profiel in voor de beste resultaten.';

  @override
  String get onboardingMissionTitle => 'Onze missie';

  @override
  String get onboardingMissionBody =>
      'Train Libre is er voor toegewijde natural bodybuilders die vooruitgang willen boeken op basis van wetenschap en gegevens.';

  @override
  String get onboardingFeatureWorkoutTitle => 'Training bijhouden';

  @override
  String get onboardingFeatureWorkoutBody =>
      'Registreer sets (RIR/RPE) en houd het herstel van je spieren bij.';

  @override
  String get onboardingFeatureTdeeTitle => 'Adaptief energieverbruik';

  @override
  String get onboardingFeatureTdeeBody =>
      'Een geïntegreerd Kalman-filter berekent je werkelijke calorieverbruik.';

  @override
  String get onboardingFeatureNutritionTitle => 'Voeding en water';

  @override
  String get onboardingFeatureNutritionBody =>
      'Houd macro’s en water bij en gebruik optioneel AI-beeldherkenning.';

  @override
  String get onboardingFeaturePrivacyTitle => '100% privé en lokaal';

  @override
  String get onboardingFeaturePrivacyBody =>
      'Geen accounts en geen verplichte cloud. Je gegevens zijn van jou.';

  @override
  String get onboardingSettingsHint =>
      'Je kunt alle instellingen later op elk moment wijzigen.';

  @override
  String get adaptiveRatePerWeekLabel => 'Wekelijks doeltempo';

  @override
  String get customTargetRateOption => 'Aangepast';

  @override
  String get customTargetRateDialogTitle => 'Aangepast doeltempo instellen';

  @override
  String get onboardingNameTitle => 'Hoe heet je?';

  @override
  String get onboardingNameLabel => 'Je naam';

  @override
  String get onboardingProfilePhotoSubtitle =>
      'Voeg eventueel een profielfoto toe om je profiel meteen persoonlijk te maken.';

  @override
  String get onboardingProfilePhotoAdd => 'Profielfoto toevoegen';

  @override
  String get onboardingNameError => 'Voer je naam in';

  @override
  String get onboardingDobTitle => 'Wanneer ben je geboren?';

  @override
  String get onboardingAgeTitle => 'Hoe oud ben je?';

  @override
  String get onboardingDobLabel => 'Geboortedatum';

  @override
  String get onboardingDobPlaceholder => 'Selecteer je geboortedatum';

  @override
  String get onboardingDobError => 'Selecteer je geboortedatum';

  @override
  String get onboardingDobUnderageError =>
      'Je moet minstens 16 jaar oud zijn om Train Libre te gebruiken.';

  @override
  String get onboardingWeightTitle => 'Huidig gewicht';

  @override
  String get onboardingWeightLabel => 'Gewicht';

  @override
  String get onboardingWeightError => 'Voer een geldig gewicht in';

  @override
  String get onboardingGoalsTitle => 'Je voedingsdoelen';

  @override
  String get onboardingGoalsSubtitle =>
      'Je kunt ze later wijzigen in Instellingen.';

  @override
  String get onboardingGoalCalories => 'Calorieën per dag (kcal)';

  @override
  String get onboardingGoalProtein => 'Eiwitten (g)';

  @override
  String get onboardingGoalCarbs => 'Koolhydraten (g)';

  @override
  String get onboardingGoalFat => 'Vetten (g)';

  @override
  String get onboardingGoalWater => 'Water';

  @override
  String get onboardingExperienceLevelTitle =>
      'Hoeveel trainingservaring heb je?';

  @override
  String get onboardingExperienceLevelSubtitle =>
      'We stemmen de terminologie en opties van de trainingsinterface af op jouw kennis.';

  @override
  String get onboardingNext => 'Volgende';

  @override
  String get onboardingBack => 'Terug';

  @override
  String get onboardingFinish => 'Begin met bijhouden';

  @override
  String get onboardingAiHealthTitle => 'AI en gezondheid';

  @override
  String get onboardingAiHealthSubtitle =>
      'Optionele instelling: configureer AI-maaltijdregistratie met BYOK (bring your own key) en kies welke gezondheidsgegevens Train Libre mag lezen.';

  @override
  String get onboardingOpenSettings => 'Openen';

  @override
  String get onboardingUnitSystemTitle => 'Kies je eenhedensysteem';

  @override
  String get onboardingUnitSystemSubtitle =>
      'Je kunt dit later wijzigen in Instellingen.';

  @override
  String get onboardingUnitMetric => 'Metrisch';

  @override
  String get onboardingUnitMetricSubtitle => 'kg, cm, ml';

  @override
  String get onboardingUnitImperial => 'Imperiaal';

  @override
  String get onboardingUnitImperialSubtitle => 'lb, inch, fl oz';

  @override
  String get onboardingHeightLabel => 'Lengte';

  @override
  String get onboardingHeightTitle => 'Hoe lang ben je?';

  @override
  String get onboardingHeightSubtitle =>
      'Sleep de liniaal omhoog of omlaag om je lengte in te stellen.';

  @override
  String get onboardingGenderLabel => 'Geslacht';

  @override
  String get onboardingBioDataInfo =>
      'Je leeftijd en biologische sekse bepalen de standaardhersteltijden van het spierherstelmodel en worden gebruikt in de algoritmen van de Slaapgezondheidsmodule.';

  @override
  String get onboardingFieldCannotBeEmpty => 'Dit veld mag niet leeg zijn.';

  @override
  String get onboardingPhysiologicalRangeWarning =>
      'Let op: deze waarde valt buiten het verwachte fysiologische bereik. Onze sportwetenschappelijke analyses en heuristische modellen zijn niet afgestemd op extreme waarden. Is dit bewust? Tik dan nogmaals op ‘Volgende’ om door te gaan.';

  @override
  String get onboardingMeasurementsTitle => 'Metingen en uitgangswaarden';

  @override
  String get onboardingMeasurementsSubtitle =>
      'Vul je huidige waarden in voor de adaptieve aanbeveling.';

  @override
  String get onboardingMeasurementsDisclaimer =>
      'Je kunt je gewicht, lichaamsvet en andere metingen op elk moment invoeren en bijhouden via het dashboard.';

  @override
  String get onboardingActivityTitle => 'Hoe actief ben je op dit moment?';

  @override
  String get onboardingActivitySubtitle =>
      'Je dagelijkse activiteit en huidige cardiotraining helpen je basisenergieverbruik te schatten. Toekomstige trainingsplannen tellen hierbij niet mee.';

  @override
  String get onboardingGoalDecisionTitle =>
      'Wil je een persoonlijk voedingsdoel instellen?';

  @override
  String get onboardingGoalDecisionSubtitle =>
      'Kies een richting, streefgewicht en tempo. Je kunt dit ook overslaan en je huidige gewicht behouden.';

  @override
  String get onboardingGoalDecisionSetupNow => 'Nu instellen';

  @override
  String get onboardingGoalDecisionSetupLater => 'Later instellen';

  @override
  String onboardingWaterNeedLabel(String unit) {
    return 'Waterbehoefte ($unit)';
  }

  @override
  String get genderMale => 'Man';

  @override
  String get genderFemale => 'Vrouw';

  @override
  String get genderDiverse => 'Divers';

  @override
  String get vegan => 'Veganistisch';

  @override
  String get vegetarian => 'Vegetarisch';

  @override
  String get ingredients => 'Ingrediënten';

  @override
  String get aiSettingsTitle => 'AI-functies';

  @override
  String get aiSettingsDescription =>
      'Stel AI-functies in, zoals chat en maaltijdherkenning.';

  @override
  String get aiProviderSection => 'AI-aanbieder';

  @override
  String get aiProviderLabel => 'Aanbieder';

  @override
  String get aiApiKeySection => 'API-sleutel';

  @override
  String get aiApiKeyLabel => 'API-sleutel';

  @override
  String get aiApiKeyHint => 'Plak hier je API-sleutel';

  @override
  String get aiSaveKey => 'Sleutel opslaan';

  @override
  String get aiTestConnection => 'Testen';

  @override
  String get aiTestSuccess => 'Verbinding geslaagd!';

  @override
  String get aiKeySaved =>
      'De API-sleutel is veilig opgeslagen op dit apparaat.';

  @override
  String get aiPrivacySection => 'Privacy';

  @override
  String get aiPrivacyDisclosure =>
      'Afbeeldingen, tekst en gegenereerde prompts worden alleen naar de gekozen AI-aanbieder gestuurd wanneer je een AI-functie gebruikt. De aanbieder verwerkt en bewaart gegevens volgens de eigen voorwaarden. Je API-sleutel wordt alleen versleuteld op dit apparaat opgeslagen.';

  @override
  String get aiMealCapture => 'AI-maaltijd';

  @override
  String get aiChatAction => 'AI-chat';

  @override
  String get aiCaptureTitle => 'Maaltijd vastleggen met AI';

  @override
  String get aiCaptureTabPhoto => 'Foto';

  @override
  String get aiCaptureTabText => 'Tekst';

  @override
  String get aiCapturePhotoHint =>
      'Maak of selecteer maximaal 4 foto’s van je maaltijd.';

  @override
  String get aiCaptureTextHint =>
      'Beschrijf je maaltijd (bijvoorbeeld: “Gegrilde kip met rijst en salade”)…';

  @override
  String get aiAnalyzeButton => 'Analyseren';

  @override
  String get aiAnalyzing => 'Je maaltijd wordt geanalyseerd…';

  @override
  String get aiReviewTitle => 'Suggesties controleren';

  @override
  String aiReviewFoundItems(int count) {
    return 'AI heeft $count voedingsmiddelen gevonden';
  }

  @override
  String get aiReviewNoMatch => 'Geen overeenkomst: tik om te zoeken';

  @override
  String get aiValidationCandidateSelectionRequired =>
      'Controleer en bewerk de ingrediënten voordat je opslaat.';

  @override
  String aiReviewUncertain(int percent) {
    return 'Onzeker ($percent%)';
  }

  @override
  String get aiReviewConfidence => 'Betrouwbaarheid';

  @override
  String get aiReviewAddItem => 'Voedingsmiddel handmatig toevoegen';

  @override
  String get aiReviewReplaceItem => 'Voedingsmiddel vervangen';

  @override
  String get aiReviewSaveToDiary => 'Opslaan in dagboek';

  @override
  String aiReviewTokensUsed(int count) {
    return 'AI-gebruik: $count tokens';
  }

  @override
  String get aiReviewTokensPending => 'AI-gebruik: wordt bijgewerkt…';

  @override
  String get aiReviewTokensUnknown => 'AI-gebruik: niet beschikbaar';

  @override
  String get aiReviewPreliminaryNutrition =>
      'Voorlopige voedingswaarden: controle loopt nog.';

  @override
  String get aiReviewScanFailed =>
      'De scan kon niet worden voltooid. Ga terug en probeer het opnieuw.';

  @override
  String get aiReviewScanTimedOut =>
      'Het AI-verzoek duurde te lang. De scan is gestopt. Ga terug en probeer het opnieuw.';

  @override
  String get aiReviewFeedbackHint =>
      'Beschrijf wat de AI verkeerd heeft gedaan…';

  @override
  String get aiReviewRetryButton => 'Opnieuw proberen met feedback';

  @override
  String get aiReviewFeedbackSection => 'Correctie';

  @override
  String get aiErrorNoKey =>
      'Er is geen API-sleutel ingesteld. Voeg er een toe via Instellingen → AI-functies.';

  @override
  String get aiErrorNetwork =>
      'Netwerkfout. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get aiErrorAuth => 'Verificatie mislukt. Controleer je API-sleutel.';

  @override
  String get aiErrorParse =>
      'Het AI-antwoord kon niet worden verwerkt. Probeer het opnieuw.';

  @override
  String get aiErrorRateLimit =>
      'Je hebt te veel verzoeken gedaan. Wacht even.';

  @override
  String get aiEnableTitle => 'AI-functies inschakelen';

  @override
  String get aiEnableSubtitle =>
      'Schakelt AI-functies zoals chat en maaltijdherkenning in. Als je dit uitschakelt, verdwijnen alle ingangen naar AI-functies.';

  @override
  String get aiNutritionEngineLabel => 'Methode voor voedingsschattingen';

  @override
  String get aiNutritionEngineSubtitle =>
      'Directe schattingen maken voedingswaarden zonder overeenkomsten in de database te zoeken. In de catalogusmodus krijg je suggesties uit de lokale voedingsmiddelencatalogus.';

  @override
  String get aiNutritionEngineEstimate => 'Directe AI-schatting';

  @override
  String get aiNutritionEngineCatalog => 'Lokale voedingsmiddelencatalogus';

  @override
  String get aiDirectEstimateLabel => 'AI-schatting';

  @override
  String get aiFloatingAssistantTitle => 'Zwevende AI-assistent tonen';

  @override
  String get aiFloatingAssistantSubtitle =>
      'Toont de AI-wolk boven de app. Als je de wolk verbergt, blijft de AI-chat beschikbaar via het menu Toevoegen.';

  @override
  String get aiStatusAndFeaturesSectionTitle => 'Status en functies';

  @override
  String get aiProviderSectionTitle => 'AI-model en aanbieder';

  @override
  String get aiAdvancedOptionsTitle => 'Geavanceerde opties';

  @override
  String get aiCustomInstructionsTitle => 'Algemene AI-instructies';

  @override
  String get aiCustomInstructionsSubtitle =>
      'Geef de AI vaste regels mee (bijvoorbeeld allergieën, voedingsmiddelen die je niet wilt zoals ‘geen bowls’, of intoleranties). Deze gelden bij elke vastlegging.';

  @override
  String get aiValidationNoMatchedItemsSaveYet =>
      'Er kunnen nog geen overeenkomende voedingsmiddelen worden opgeslagen.';

  @override
  String get aiValidationNoMatchedIngredientsSaveYet =>
      'Er kunnen nog geen overeenkomende ingrediënten worden opgeslagen.';

  @override
  String get aiValidationSomeItemsNeedReviewTitle =>
      'Sommige voedingsmiddelen moeten worden gecontroleerd';

  @override
  String get aiValidationSomeIngredientsNeedReviewTitle =>
      'Sommige ingrediënten moeten worden gecontroleerd';

  @override
  String get aiValidationSaveMatchedItemsButton =>
      'Overeenkomende voedingsmiddelen opslaan';

  @override
  String get aiValidationSaveMatchedIngredientsButton =>
      'Overeenkomende ingrediënten opslaan';

  @override
  String get aiValidationValidationPassedTitle => 'Controle geslaagd';

  @override
  String get aiValidationReviewSuggestedTitle => 'Controle aanbevolen';

  @override
  String get aiValidationMacroFitValidatedTitle => 'Macro’s gecontroleerd';

  @override
  String get aiValidationNeedsReviewTitle => 'Controle nodig';

  @override
  String get aiValidationRepairLimitReachedReview =>
      'De limiet voor automatische correcties is bereikt. Controleer dit voordat je opslaat.';

  @override
  String get aiValidationRecentMealContextIncluded =>
      'Recente maaltijdcontext is meegenomen.';

  @override
  String get aiValidationGeneratedWithoutRecentMealHistory =>
      'Gegenereerd zonder recente maaltijdgeschiedenis.';

  @override
  String get aiValidationApiKeyRequiredTitle => 'API-sleutel vereist';

  @override
  String aiValidationScoreLabel(int score) {
    return 'Score: $score/100';
  }

  @override
  String aiValidationDeltaSummary(
      int kcalDelta, int proteinDelta, int carbsDelta, int fatDelta) {
    return 'Verschil: $kcalDelta kcal · $proteinDelta g eiwit · $carbsDelta g koolhydraten · $fatDelta g vet';
  }

  @override
  String aiValidationPartialSaveItemsMessage(
      int unmatchedCount, int matchedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unmatchedCount,
      locale: localeName,
      other:
          '$unmatchedCount voedingsmiddelen komen niet overeen met de lokale database en worden niet opgeslagen.',
      one:
          '1 voedingsmiddel komt niet overeen met de lokale database en wordt niet opgeslagen.',
    );
    return '$_temp0 Alleen de overeenkomende voedingsmiddelen ($matchedCount) opslaan?';
  }

  @override
  String aiValidationPartialSaveIngredientsMessage(
      int unmatchedCount, int matchedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unmatchedCount,
      locale: localeName,
      other:
          '$unmatchedCount ingrediënten komen niet overeen met de lokale database en worden niet opgeslagen.',
      one:
          '1 ingrediënt komt niet overeen met de lokale database en wordt niet opgeslagen.',
    );
    return '$_temp0 Alleen de overeenkomende ingrediënten ($matchedCount) opslaan?';
  }

  @override
  String get aiValidationEmptyItemName => 'Een voedingsmiddel heeft geen naam.';

  @override
  String aiValidationDuplicateItemMerged(String name) {
    return 'Dubbele vermeldingen van “$name” zijn vóór de controle samengevoegd.';
  }

  @override
  String get aiValidationInvalidQuantity =>
      'De hoeveelheid moet groter zijn dan 0 g.';

  @override
  String get aiValidationTinyQuantity =>
      'De hoeveelheid is erg klein. Controleer het aantal gram.';

  @override
  String get aiValidationExtremeQuantity =>
      'De hoeveelheid lijkt onwaarschijnlijk groot voor één maaltijdproduct.';

  @override
  String get aiValidationLargeQuantity =>
      'De hoeveelheid is ongewoon groot. Controleer het aantal gram.';

  @override
  String get aiValidationLowAiConfidence =>
      'De AI is onzeker over dit voedingsmiddel.';

  @override
  String get aiValidationUnmatchedItem =>
      'Geen overeenkomst gevonden in de lokale database.';

  @override
  String get aiValidationWeakDbMatch =>
      'De overeenkomst met de lokale database is twijfelachtig.';

  @override
  String get aiValidationPartialDbMatch =>
      'De overeenkomst met de lokale database is gedeeltelijk.';

  @override
  String get aiValidationAmbiguousDbMatch =>
      'Meerdere overeenkomsten in de lokale database zijn even aannemelijk.';

  @override
  String get aiValidationStateMismatch =>
      'De toestand van het door AI voorgestelde voedingsmiddel komt mogelijk niet overeen met de databasevermelding.';

  @override
  String get aiValidationZeroNutritionMatch =>
      'De overeenkomende databasevermelding bevat geen bruikbare voedingswaarden.';

  @override
  String get aiValidationImplausibleFoodDensity =>
      'Het overeenkomende voedingsmiddel heeft een ongewoon hoge kcal-waarde per 100 g.';

  @override
  String get aiValidationMacroEnergyMismatch =>
      'De macro’s van het overeenkomende voedingsmiddel passen niet goed bij de kcal-waarde.';

  @override
  String get aiValidationImplausibleItemNutrition =>
      'De voedingswaarden voor deze hoeveelheid zijn ongewoon hoog.';

  @override
  String get aiValidationEmptyMeal =>
      'AI heeft geen voedingsmiddelen voor de maaltijd teruggegeven.';

  @override
  String get aiValidationAllItemsUnmatched =>
      'Geen van de voedingsmiddelen komt overeen met de lokale database.';

  @override
  String aiValidationPartialUnmatchedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count voedingsmiddelen kunnen pas worden opgeslagen nadat ze zijn gekoppeld.',
      one: '1 voedingsmiddel kan pas worden opgeslagen nadat het is gekoppeld.',
    );
    return '$_temp0';
  }

  @override
  String get aiValidationZeroTotalKcal =>
      'De overeenkomende voedingsmiddelen bevatten samen 0 kcal.';

  @override
  String get aiValidationCaptureTotalKcalExtreme =>
      'Het totale aantal kcal lijkt onwaarschijnlijk hoog voor één maaltijd.';

  @override
  String get aiValidationCaptureTotalKcalHigh =>
      'Het totale aantal kcal is ongewoon hoog. Controleer de porties.';

  @override
  String get aiValidationMacroTotalExtreme =>
      'Het totaal aan macro’s lijkt onwaarschijnlijk hoog.';

  @override
  String get aiValidationMacroTotalHigh =>
      'Het totaal aan macro’s is ongewoon hoog. Controleer de porties.';

  @override
  String aiValidationTargetKcalMismatch(int delta) {
    return 'De calorieën wijken $delta kcal af van het doel.';
  }

  @override
  String aiValidationTargetProteinMismatch(int delta) {
    return 'De eiwitten wijken $delta g af van het doel.';
  }

  @override
  String aiValidationTargetCarbsMismatch(int delta) {
    return 'De koolhydraten wijken $delta g af van het doel.';
  }

  @override
  String aiValidationTargetFatMismatch(int delta) {
    return 'De vetten wijken $delta g af van het doel.';
  }

  @override
  String aiValidationUnknownIssue(String code) {
    return 'Controleprobleem: $code';
  }

  @override
  String get currentlyTracking => 'Momenteel';

  @override
  String get currentlyTrackingDesc => 'Tonen in het dagelijkse overzicht';

  @override
  String get filter3Months => '3 maanden';

  @override
  String get filter6Months => '6 maanden';

  @override
  String get sectionConsistency => 'Consistentie en frequentie';

  @override
  String get metricsWorkoutsWeek => 'Trainingen (week)';

  @override
  String get metricsCurrentStreak => 'Huidige reeks';

  @override
  String get metricsActiveWeeks => 'actieve weken';

  @override
  String get placeholderCalendarHeatmap => 'Kalender met trainingsactiviteit';

  @override
  String get consistencyTrackerTitle => 'Trainingsritme';

  @override
  String get consistencyTrackerComingSoon =>
      'Consistentie- en gewoontetracker (binnenkort beschikbaar)';

  @override
  String get sectionMuscleVolume => 'Spiergroepen en volume';

  @override
  String get metricsTopTrained => 'Meest getrainde spieren';

  @override
  String get metricsMostNeglected => 'Minst getrainde spieren';

  @override
  String get placeholderMuscleHeatmap => 'Heatmap van spiergroepen';

  @override
  String get muscleAnalyticsTitle => 'Analyse van spiergroepen';

  @override
  String get muscleAnalyticsComingSoon =>
      'Spiergroeivolume en heatmaps (binnenkort beschikbaar)';

  @override
  String get sectionPerformance => 'Prestaties en persoonlijke records';

  @override
  String get metricsRecentPrs => 'Recente persoonlijke records';

  @override
  String get metricsVolumeLifted => 'Volume';

  @override
  String get metricsMostImproved => 'Meest vooruitgegaan';

  @override
  String get exerciseAnalyticsTitle => 'Oefeningsanalyse';

  @override
  String get exerciseAnalyticsSubtitle =>
      'Zoek specifieke oefeningen en analyseer ze';

  @override
  String get prDashboardTitle => 'Overzicht persoonlijke records';

  @override
  String get prDashboardComingSoon =>
      'Records en voortgang (binnenkort beschikbaar)';

  @override
  String get exerciseAnalyticsComingSoon =>
      'Oefeningen zoeken en specifieke trends bekijken (binnenkort beschikbaar)';

  @override
  String get sectionRecovery => 'Herstel';

  @override
  String get metricsMuscleReadiness => 'Herstelstatus van spieren';

  @override
  String get recoveryTrackerTitle => 'Herstel bijhouden';

  @override
  String get recoveryTrackerComingSoon =>
      'Spierherstel en vermoeidheid (binnenkort)';

  @override
  String get recoveryOverallMostlyRecovered => 'Overwegend hersteld';

  @override
  String get recoveryOverallMixed => 'Gemengde herstelstatus';

  @override
  String get recoveryOverallSeveralRecovering =>
      'Meerdere spiergroepen herstellen nog';

  @override
  String get recoveryOverallInsufficientData =>
      'Nog onvoldoende gegevens voor inzicht in herstel';

  @override
  String recoveryHubCountsSummary(int recovering, int ready, int fresh) {
    return 'Herstellend: $recovering  Klaar: $ready  Fris: $fresh';
  }

  @override
  String get recoveryHubNoDataSummary =>
      'Blijf trainingen registreren om inzicht in je herstel te krijgen.';

  @override
  String get recoveryByMuscleTitle => 'Herstel per spiergroep';

  @override
  String get recoveryStateRecovering => 'Herstellend';

  @override
  String get recoveryStateReady => 'Klaar';

  @override
  String get recoveryStateFresh => 'Fris';

  @override
  String get recoveryStateUnknown => 'Onbekend';

  @override
  String recoveryReadyInHours(int hours) {
    return 'Naar verwachting over ongeveer $hours uur klaar';
  }

  @override
  String recoveryFreshInHours(int hours) {
    return 'Naar verwachting over ongeveer $hours uur volledig hersteld';
  }

  @override
  String get recoveryStillRecovering => 'Herstelt nog';

  @override
  String get recoveryReadyForNormalTraining =>
      'Klaar voor een normale training';

  @override
  String get recoveryFreshForFullTraining =>
      'Fris · klaar voor een volledige training';

  @override
  String get recoveryDetailLastSession => 'Laatste training';

  @override
  String get recoveryNoRecentLoad =>
      'Geen significante belasting geregistreerd';

  @override
  String get recoveryDetailEquivalentSets => 'equivalente sets';

  @override
  String get recoveryDataConfidence => 'Betrouwbaarheid van gegevens';

  @override
  String get recoveryDetailEligibleSets => 'meegetelde sets';

  @override
  String get recoveryDetailResidualLoad => 'resterende belasting';

  @override
  String get recoveryDetailDirectLoad => 'directe belasting';

  @override
  String get recoveryDetailIndirectLoad => 'indirecte belasting';

  @override
  String get recoveryDetailAverageRir => 'gemiddelde RIR';

  @override
  String get recoveryDetailAverageRpe => 'gemiddelde RPE';

  @override
  String get recoveryMovementPatterns => 'Bewegingspatronen';

  @override
  String get recoveryDetailForecast => 'Verwachting';

  @override
  String get recoveryDetailRirData => 'RIR-gegevens';

  @override
  String recoveryCompactHours(int hours) {
    return '≈ $hours h';
  }

  @override
  String recoverySessionLoadAndAge(String load, int hours) {
    return '$load belastingseenheden · $hours uur geleden';
  }

  @override
  String recoveryLastSessionDetails(String load, int hours) {
    return 'Laatste training: $load belastingseenheden · $hours uur geleden';
  }

  @override
  String recoveryRirCoverage(int covered, int total) {
    return 'RIR geregistreerd voor $covered van $total sets';
  }

  @override
  String recoveryLastLoadedHours(int hours) {
    return 'Laatste significante belasting: $hours uur geleden';
  }

  @override
  String get recoveryFatigueContextHigh =>
      'Vermoeidheid: hoge vermoeidheid tijdens de training';

  @override
  String get recoveryFatigueContextBaseline =>
      'Vermoeidheid: gebruikelijke vermoeidheid tijdens de training';

  @override
  String recoveryExplanationWithHighFatigue(String muscle, int hours) {
    return '$muscle: voor het laatst significant belast $hours uur geleden, met hoge trainingsvermoeidheid.';
  }

  @override
  String recoveryExplanationBasic(String muscle, int hours) {
    return '$muscle: voor het laatst significant belast $hours uur geleden.';
  }

  @override
  String get recoveryHeuristicDisclaimer =>
      'Dit is een voorzichtige schatting op basis van recente significante belasting en trainingsinspanning. Het is geen medische meting van herstel.';

  @override
  String get recoveryReadinessLabel => 'Trainingsgereedheid';

  @override
  String recoveryRecentLoad(String sets) {
    return 'Laatste belasting: $sets equivalente sets';
  }

  @override
  String recoveryLastLoadPressure(String level) {
    return 'Belasting van de laatste training: $level';
  }

  @override
  String get recoveryPressureLow => 'laag';

  @override
  String get recoveryPressureModerate => 'gemiddeld';

  @override
  String get recoveryPressureHigh => 'hoog';

  @override
  String get recoveryPressureVeryHigh => 'zeer hoog';

  @override
  String recoveryCurrentWindow(int recoveringUpper, int readyUpper) {
    return 'Huidige periode: herstellend tot ongeveer $recoveringUpper uur, klaar tot ongeveer $readyUpper uur.';
  }

  @override
  String recoveryWindowHeuristic(int from, int to) {
    return 'Huidige periode: herstellend tot ongeveer $from uur, klaar tot ongeveer $to uur.';
  }

  @override
  String get recoveryRadarHeuristicCaption =>
      'Radardiagram van de huidige trainingsgereedheid per spiergroep. De statuslabels zijn leidend.';

  @override
  String get recoveryNoDataBody =>
      'Er is nog niet genoeg significante trainingsbelasting geregistreerd om spierherstel te schatten.';

  @override
  String get sectionBodyNutrition => 'Lichaam en voeding';

  @override
  String get statisticsSectionTraining => 'Training';

  @override
  String get statisticsSectionBody => 'Lichaam';

  @override
  String get statisticsEditCardsTitle => 'Statistieken bewerken';

  @override
  String get statisticsPinnedTitle => 'Vastgezet';

  @override
  String get statisticsAddCardsTitle => 'Meer statistieken';

  @override
  String get statisticsMicronutrientsTitle => 'Micronutriënten';

  @override
  String get statisticsMicronutrientsCoverage =>
      'Alleen BLS-voedingsmiddelen in het dagboek';

  @override
  String get statisticsMicronutrientsPreviewSubtitle =>
      'Vitaminen, mineralen en andere voedingsstoffen';

  @override
  String get statisticsMicronutrientsNoData =>
      'Nog geen BLS-voedingsmiddelen geregistreerd';

  @override
  String get statisticsAveragePerLoggedDay =>
      'Gemiddelde per geregistreerde dag';

  @override
  String get statisticsMicronutrientsLoggedDays => 'geregistreerde dagen';

  @override
  String statisticsMicronutrientsNutrientCoverage(int count) {
    return 'Waarde geregistreerd op $count dagen';
  }

  @override
  String get diaryMicronutrientsAction =>
      'Micronutriënten van deze dag bekijken';

  @override
  String get statisticsWaterDailyAverage => 'Dagelijks gemiddelde';

  @override
  String get statisticsWaterNoData => 'Nog geen dranken geregistreerd';

  @override
  String statisticsWaterGoalProgress(int percent) {
    return '$percent% van het dagelijkse doel';
  }

  @override
  String get statisticsActivityCategory => 'Activiteit';

  @override
  String get statisticsPinnedEmptyHint =>
      'Voeg hieronder statistieken toe om ze hier te tonen.';

  @override
  String get statisticsAllDataTitle => 'Alle gegevens';

  @override
  String get statisticsAllDataAction => 'Alle gegevens weergeven';

  @override
  String get statisticsRemoveCard => 'Statistiek verwijderen';

  @override
  String get statisticsEnableStepTrackingHint =>
      'Schakel stappentelling in via Instellingen';

  @override
  String get statisticsNoStepDataYet => 'Nog geen stapgegevens';

  @override
  String get statisticsTotalSteps => 'Totaal aantal stappen';

  @override
  String get statisticsLast7Days => 'Afgelopen 7 dagen';

  @override
  String get statisticsLast30Days => 'Afgelopen 30 dagen';

  @override
  String get statisticsLast3Months => 'Afgelopen 3 maanden';

  @override
  String get statisticsLast6Months => 'Afgelopen 6 maanden';

  @override
  String get metricsCurrentWeight => 'Huidig gewicht';

  @override
  String get metricsAvgCalories => 'Gemiddeld aantal calorieën';

  @override
  String get placeholderWeightTrend => 'Lijngrafiek gewichtstrend';

  @override
  String get exerciseAnalyticsPrsLabel => 'PERSOONLIJKE RECORDS';

  @override
  String get exerciseAnalyticsTrendsLabel => 'TRENDS';

  @override
  String get exerciseAnalyticsNoData =>
      'Geen trainingsgegevens voor deze oefening.';

  @override
  String get exerciseAnalyticsNotEnoughData => 'Onvoldoende gegevens';

  @override
  String get exerciseAnalyticsChartWeight => 'Gewicht door de tijd (kg)';

  @override
  String get exerciseAnalyticsChartVolume => 'Volume door de tijd (kg)';

  @override
  String get exerciseAnalyticsChartSets => 'Sets door de tijd';

  @override
  String get exerciseMetricMaxWeight => 'Maximaal gewicht';

  @override
  String get exerciseMetricVolume => 'Volume';

  @override
  String get exerciseMetricEst1RM => 'Geschatte 1RM';

  @override
  String get exerciseMetricDistance => 'Afstand';

  @override
  String get exerciseMetricDuration => 'Duur';

  @override
  String get exerciseMetricPace => 'Tempo';

  @override
  String get prBannerBestMaxWeight => 'Beste maximale gewicht';

  @override
  String get prBannerBestVolumeSet => 'Set met het hoogste volume';

  @override
  String get prBannerBest1RM => 'Beste 1RM';

  @override
  String get newPersonalRecordLabel => 'Nieuw persoonlijk record';

  @override
  String get prBadgeTooltip => 'Nieuw persoonlijk record!';

  @override
  String get workoutSummaryNewRecordsTitle => 'Nieuwe records';

  @override
  String get allTimeRecordsLabel => 'Records aller tijden';

  @override
  String get recentActivityLabel => 'Recente activiteit';

  @override
  String get prsByRepRangeLabel => 'Beste set per herhalingsbereik';

  @override
  String get volumeAnalyticsTitle => 'Volumeanalyse';

  @override
  String get weeklyTonnageLabel => 'Wekelijkse tonnage';

  @override
  String get volumeByMuscleLabel => 'Per spiergroep';

  @override
  String get topExercisesLabel => 'Topoefeningen';

  @override
  String get thisWeekLabel => 'Deze week';

  @override
  String get avgPerWeekLabel => 'Gemiddeld per week';

  @override
  String get streakLabel => 'Reeks';

  @override
  String get trainingCalendarLabel => 'Trainingskalender';

  @override
  String get workoutsPerWeekLabel => 'Trainingen per week';

  @override
  String get totalWorkoutsLabel => 'Totaal';

  @override
  String get weeksLabel => 'Weken';

  @override
  String get tonnageKgLabel => 'Tonnage (kg)';

  @override
  String get noWorkoutDataLabel =>
      'Nog geen trainingsgegevens. Registreer trainingen om je statistieken te bekijken.';

  @override
  String get analyticsSectionVolumeMuscles => 'Volume en spiergroepen';

  @override
  String get analyticsSectionPerformanceRecords => 'Prestaties en records';

  @override
  String get analyticsTopVolume => 'Meest getraind';

  @override
  String get analyticsLowestVolume => 'Laagste volume';

  @override
  String get analyticsRecentRecords => 'Recente records';

  @override
  String get analyticsNewBestPerformances => 'Nieuwe persoonlijke records';

  @override
  String get analyticsTop => 'Top';

  @override
  String analyticsLastWeeks(int weeks) {
    return 'Afgelopen $weeks weken';
  }

  @override
  String get analyticsMuscleGroups => 'Spiergroepen';

  @override
  String get analyticsStrongestBreakthrough => 'Grootste vooruitgang';

  @override
  String get analyticsRecordOverview => 'Recordoverzicht';

  @override
  String get analyticsRecentlySet => 'Recent ingesteld';

  @override
  String get analyticsByRepetitionRange => 'Op herhalingsbereik';

  @override
  String analyticsPerfWithReps(String weight, int reps, Object unit) {
    return '$weight $unit × $reps';
  }

  @override
  String get analyticsKgThisWeek => 'kg (deze week)';

  @override
  String get analyticsRecoverySummary => '3 herstellen, 8 zijn klaar';

  @override
  String get analyticsViewDetails => 'Details bekijken';

  @override
  String get analyticsRepRangeSuffix => ' herhalingen';

  @override
  String get analyticsNoRecordYet => 'Nog geen record';

  @override
  String get analyticsNoRecordsInPeriod =>
      'Geen persoonlijke records in deze periode';

  @override
  String get analyticsNotableImprovements => 'Opvallende verbeteringen';

  @override
  String get analyticsNoPrTrendInWindow =>
      'Er is nog geen duidelijke recordtrend in deze periode.';

  @override
  String analyticsE1rmProgress(String previous, String recent, Object unit) {
    return 'Geschatte 1RM $previous → $recent $unit';
  }

  @override
  String get analyticsUnitKg => 'kg';

  @override
  String get analyticsUnitSets => 'sets';

  @override
  String get analyticsViewLabel => 'Weergave';

  @override
  String get analyticsViewChart => 'Grafiek';

  @override
  String get analyticsViewOverview => 'Overzicht';

  @override
  String get analyticsVolumeWeeklyAverage => 'Wekelijks gemiddelde';

  @override
  String get analyticsVolumeTotal => 'Totaal';

  @override
  String get analyticsSwitchToChart => 'Grafiek tonen';

  @override
  String get analyticsSwitchToOverview => 'Overzicht tonen';

  @override
  String get analyticsViewWeek => 'Week';

  @override
  String get analyticsViewMonth => 'Maand';

  @override
  String get analyticsViewByExercise => 'Per oefening';

  @override
  String get analyticsViewByMuscle => 'Per spiergroep';

  @override
  String get analyticsMetricLabel => 'Maatstaf';

  @override
  String get analyticsMovedWeightKg => 'Verplaatst gewicht (kg)';

  @override
  String get analyticsWorkSets => 'Werksets';

  @override
  String get analyticsVolumeContextWithSets =>
      'Verplaatst gewicht = gewicht × herhalingen. Schakel over naar werksets om de belasting op basis van het aantal sets te zien.';

  @override
  String get analyticsVolumeContextTonnageOnly =>
      'Deze weergave gebruikt verplaatst gewicht (gewicht × herhalingen).';

  @override
  String get analyticsKpisHeader => 'Kerncijfers';

  @override
  String get analyticsTrainingDaysPerWeek => 'Trainingsdagen per week';

  @override
  String get analyticsLast4Weeks => 'afgelopen 4 weken';

  @override
  String get analyticsRhythm => 'Ritme';

  @override
  String get analyticsVsPrior4Weeks => 'vergeleken met de vorige 4 weken';

  @override
  String get analyticsRollingConsistency => 'Consistentie over tijd';

  @override
  String get analyticsWeeksAtLeast2Workouts => 'weken met minstens 2 sessies';

  @override
  String get analyticsInTimeframe => 'Binnen de periode';

  @override
  String get analyticsVsPriorPeriod => 'vergeleken met de vorige periode';

  @override
  String get analyticsCalendarExplainer =>
      'De kleur geeft het aantal sessies per dag aan.';

  @override
  String get analyticsSelectDayPrompt =>
      'Selecteer een dag om het aantal sessies te bekijken.';

  @override
  String analyticsSelectedDayWorkouts(String date, int count) {
    return '$date: $count sessies';
  }

  @override
  String get analyticsTotalSessions => 'Totaal aantal sessies';

  @override
  String get analyticsPlaceholderWeightValue => '82,5';

  @override
  String get analyticsPlaceholderWeightTrend => 'kg (-0,5)';

  @override
  String get analyticsPlaceholderCaloriesValue => '2.450';

  @override
  String get analyticsPlaceholderCaloriesUnit => 'kcal/dag';

  @override
  String get analyticsMuscleWeeklySets => 'Sets per week';

  @override
  String get analyticsMuscleTopFrequency => 'Hoogste frequentie';

  @override
  String get analyticsPerWeekAbbrev => 'wk';

  @override
  String get analyticsKeepTrackingUnlockInsights =>
      'Blijf trainingen registreren om inzichten te krijgen.';

  @override
  String get analyticsGuidanceNoClearWeakPoint =>
      'Advies: in deze periode is geen duidelijk zwak punt te zien.';

  @override
  String analyticsGuidanceLowerEmphasis(String muscles) {
    return 'Advies: de laatste tijd lag er minder nadruk op $muscles.';
  }

  @override
  String get analyticsPeriodLabel => 'Periode';

  @override
  String get analyticsCoverageMuscles => 'Spieren';

  @override
  String get analyticsCoverageMovementPatterns => 'Bewegingspatronen';

  @override
  String get analyticsWorkingSetsByMuscle => 'Werksets per spiergroep';

  @override
  String get analyticsWorkingSetsByPattern => 'Werksets per bewegingspatroon';

  @override
  String get analyticsPrimaryMuscleCoverageCaption =>
      'Toont alleen voltooide normale sets en sets tot spierfalen voor primaire spiergroepen.';

  @override
  String get analyticsMovementPatternCoverageCaption =>
      'Toont voltooide normale sets en sets tot spierfalen per bewegingspatroon.';

  @override
  String get analyticsUnclassified => 'Niet ingedeeld';

  @override
  String get analyticsPatternOther => 'Overig';

  @override
  String analyticsAverageWorkingSetsPerWeek(String value) {
    return 'Gemiddeld $value werksets per week';
  }

  @override
  String get analyticsFrequencyWorkingSetFooter =>
      'De frequentie telt trainingsdagen waarop je minstens één werkset voor die spiergroep deed.';

  @override
  String analyticsAverageFrequencyPerWeek(String value) {
    return 'Gemiddelde frequentie: $value / wk';
  }

  @override
  String analyticsTotalWorkingSets(String value) {
    return '$value werksets';
  }

  @override
  String get analyticsEquivalentSetsExplainer =>
      'Equivalente zware sets wegen primaire spiergroepen mee als ×1,0 en secundaire als ×0,3. De frequentie telt alleen dagen waarop je minstens 1,0 equivalente set haalt.';

  @override
  String get analyticsWeeklySetsByMuscle =>
      'Gemiddeld aantal sets per spiergroep per week';

  @override
  String get analyticsFrequencyByMuscle => 'Frequentie per spiergroep';

  @override
  String get analyticsRecentDistributionHeatmap =>
      'Heatmap van de recente verdeling';

  @override
  String get analyticsRadarOverviewTitle => 'Radardiagram';

  @override
  String get analyticsRadarVolumeCaption =>
      'Geeft in één oogopslag de relatieve volumeverdeling over spiergroepen weer.';

  @override
  String get analyticsGuidanceTitle => 'Advies';

  @override
  String get analyticsGuidanceDirectionalDisclaimer =>
      'Dit is richtinggevend advies op basis van de recente verdeling van je sets, geen absolute diagnose.';

  @override
  String get analyticsGuidanceSoftenedDisclaimer =>
      'Inzichten worden voorzichtig geformuleerd totdat er genoeg gegevens zijn.';

  @override
  String analyticsWeekTotalEquivalentSets(String value) {
    return 'Gemiddeld $value equivalente sets per week';
  }

  @override
  String get analyticsFrequencyRuleFooter =>
      'De frequentie telt alleen dagen waarop een spiergroep minstens 1,0 equivalente sets haalt.';

  @override
  String liveWorkoutE1rmCurrentSet(String value, Object unit) {
    return 'Geschatte 1RM $value $unit';
  }

  @override
  String liveWorkoutE1rmBestSession(String value, Object unit) {
    return 'Beste geschatte 1RM deze sessie: $value $unit';
  }

  @override
  String liveWorkoutE1rmVsLastSession(String delta, Object unit) {
    return 'vergeleken met de vorige sessie: $delta $unit';
  }

  @override
  String get bodyNutritionCorrelationTitle => 'Trends in gewicht en voeding';

  @override
  String get metricsWeightChange => 'Gewichtsverandering';

  @override
  String get analyticsKcalPerDay => 'kcal/dag';

  @override
  String get analyticsDaysWithWeightData => 'dagen met gewichtsgegevens';

  @override
  String get analyticsDayUnitLabel => 'dagen';

  @override
  String get analyticsPerDayLabel => 'per dag';

  @override
  String get analyticsEffectiveRangeLabel => 'Effectief bereik';

  @override
  String get analyticsAxisXLabel => 'X';

  @override
  String get analyticsAxisYLabel => 'Y';

  @override
  String get analyticsHighConfidenceLabel => 'Patroon met hoge betrouwbaarheid';

  @override
  String get analyticsLowConfidenceLabel =>
      'Patroon met lagere betrouwbaarheid';

  @override
  String get analyticsObservedPatternLabel => 'Waargenomen patroon';

  @override
  String get analyticsBodyNutritionTrendContext =>
      'Gewicht en calorieën over tijd';

  @override
  String analyticsBodyNutritionTrendContextHint(Object unit) {
    return 'De grafiek schaalt elke reeks zodat ze in dezelfde ruimte passen; tooltips tonen de oorspronkelijke waarden in $unit en kcal.';
  }

  @override
  String analyticsBodyNutritionNormalizedHint(Object unit) {
    return 'De grafiek schaalt gewicht en calorieën zodat ze in dezelfde ruimte passen; tooltips tonen de oorspronkelijke waarden in $unit en kcal.';
  }

  @override
  String analyticsBodyNutritionTotalWeightLabel(Object unit) {
    return 'Totaal gewicht ($unit)';
  }

  @override
  String get analyticsBodyNutritionTotalCaloriesLabel =>
      'Totaal calorieën (kcal)';

  @override
  String analyticsWeightTrendLabel(String unit) {
    return 'Gewicht ($unit)';
  }

  @override
  String get analyticsCaloriesTrendLabel => 'Calorieën (kcal)';

  @override
  String get analyticsInterpretationTitle => 'Interpretatie';

  @override
  String get analyticsBodyNutritionConfidenceHighHint =>
      'Er zijn genoeg gegevens in deze periode om een patroon betrouwbaarder te herkennen.';

  @override
  String get analyticsBodyNutritionConfidenceModerateHint =>
      'Er zijn redelijk wat gegevens. Trends geven nuttige context, maar blijf registreren voor meer zekerheid.';

  @override
  String get analyticsBodyNutritionConfidenceLowHint =>
      'Er zijn nog weinig gegevens in deze periode. Zie dit daarom als een eerste aanwijzing.';

  @override
  String get analyticsBodyNutritionLowConfidenceNudge =>
      'Registreer je gewicht en calorieën regelmatig om de betrouwbaarheid te vergroten.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceHigh =>
      'Betrouwbaarheid van de interpretatie: hoog. Gebruik dit als context bij trends, niet als bewijs voor een direct oorzakelijk verband.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceLow =>
      'Betrouwbaarheid van de interpretatie: lager. Zie dit als een eerste patroon en blijf gegevens registreren.';

  @override
  String get analyticsCorrelationDisclaimer =>
      'Deze weergave geeft context bij trends. Ze bewijst niet dat veranderingen in calorieën rechtstreeks veranderingen in gewicht veroorzaken.';

  @override
  String get analyticsInsightStableWeightCaloriesUp =>
      'Je gewicht blijft stabiel terwijl je gemiddelde calorie-inname stijgt.';

  @override
  String get analyticsInsightWeightUpCaloriesUp =>
      'Je gewicht stijgt samen met een hogere gemiddelde calorie-inname.';

  @override
  String get analyticsInsightCaloriesDownWeightStable =>
      'De recente verlaging van calorieën heeft de gewichtstrend nog niet duidelijk veranderd.';

  @override
  String get analyticsInsightWeightDownCaloriesDown =>
      'Je gewicht daalt samen met een lagere gemiddelde calorie-inname.';

  @override
  String get analyticsInsightMixedPattern =>
      'De trends in gewicht en calorieën lopen uiteen; een duidelijk verband is nog niet zichtbaar.';

  @override
  String get analyticsInsightNotEnoughData =>
      'Er zijn nog niet genoeg consistente gegevens om een betekenisvolle trend te bepalen.';

  @override
  String get analyticsModerateConfidenceLabel =>
      'Patroon met redelijke betrouwbaarheid';

  @override
  String get analyticsInsufficientConfidenceLabel =>
      'Onvoldoende gegevens voor een betrouwbare conclusie';

  @override
  String get analyticsTrendRising => 'Stijgend';

  @override
  String get analyticsTrendFalling => 'Dalend';

  @override
  String get analyticsTrendStable => 'Stabiel';

  @override
  String get analyticsTrendUnclear => 'Onduidelijk';

  @override
  String get analyticsRelationshipAlignedCut =>
      'Een lagere inname en dalend lichaamsgewicht lopen gelijk.';

  @override
  String get analyticsRelationshipAlignedBulk =>
      'Een hogere inname en stijgend lichaamsgewicht lopen gelijk.';

  @override
  String get analyticsRelationshipStableMaintenance =>
      'Gewicht en inname lijken over het algemeen stabiel.';

  @override
  String get analyticsRelationshipMixed =>
      'De signalen lopen uiteen of komen vertraagd door.';

  @override
  String get analyticsRelationshipInsufficient =>
      'Er is nog onvoldoende consistente overlap om het patroon te classificeren.';

  @override
  String analyticsBasedOnDataCoverage(int weightDays, int calorieDays) {
    return 'Gebaseerd op $weightDays dagen met een weging en $calorieDays dagen met caloriegegevens';
  }

  @override
  String get restTimerNotificationTitle => 'Rust voorbij';

  @override
  String get restTimerNotificationBody =>
      'De rusttimer is afgelopen. Je kunt aan de volgende set beginnen.';

  @override
  String get onboardingContinueSetup => 'Profiel instellen';

  @override
  String get onboardingRestoreFromBackup => 'Herstellen vanuit back-up';

  @override
  String get onboardingRestoreImporting => 'Back-up importeren…';

  @override
  String get onboardingRestoreSuccess => 'Back-up succesvol hersteld!';

  @override
  String get onboardingRestoreFailed =>
      'Importeren mislukt. Controleer het bestand en probeer het opnieuw.';

  @override
  String get onboardingRestoreFromICloud => 'Herstellen vanuit iCloud';

  @override
  String get onboardingRestoreICloudSuccess =>
      'iCloud-back-up succesvol hersteld!';

  @override
  String get onboardingRestoreICloudFailed =>
      'Herstellen vanuit iCloud mislukt. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get finishWorkoutTitleLabel => 'Trainingstitel';

  @override
  String get finishWorkoutNotesLabel => 'Notities (optioneel)';

  @override
  String get finishWorkoutNotesHint => 'Hoe ging de training?';

  @override
  String get sleepSectionTitle => 'Slaap';

  @override
  String get sleepSectionSubtitleDayEntry =>
      'Dagoverzicht met doorklikken naar details';

  @override
  String get sleepSectionSubtitleAllEntry =>
      'Vanuit dit onderdeel kun je slaap per dag, week en maand bekijken';

  @override
  String get sleepScopeDay => 'Dag';

  @override
  String get sleepScopeWeek => 'Week';

  @override
  String get sleepScopeMonth => 'Maand';

  @override
  String get sleepWeekSummaryTitle => 'Weekoverzicht';

  @override
  String get sleepMonthSummaryTitle => 'Maandoverzicht';

  @override
  String get sleepSleepWindowTitle => 'Slaapvenster';

  @override
  String get sleepDailyScoreTitle => 'Dagscore';

  @override
  String get sleepMonthDailyScoreStatesTitle => 'Dagscore per nacht';

  @override
  String sleepMeanScoreLabel(String value) {
    return 'Gemiddelde score: $value';
  }

  @override
  String get sleepHubScoreLabel => 'Slaapscore';

  @override
  String get sleepHubAverageLabel => 'Gemiddelde';

  @override
  String get sleepHubBedtimeLabel => 'Bedtijd';

  @override
  String get sleepHubInterruptionsLabel => 'Onderbrekingen';

  @override
  String sleepHubInterruptionsSummary(int count, String duration) {
    return '$count keer wakker, in totaal $duration';
  }

  @override
  String sleepWeekdayAvgDurationLabel(String value) {
    return 'Gemiddelde duur op werkdagen: $value';
  }

  @override
  String sleepWeekendAvgDurationLabel(String value) {
    return 'Gemiddelde duur in het weekend: $value';
  }

  @override
  String get sleepWeekNoScoredNights =>
      'Deze week zijn er nog geen gescoorde nachten beschikbaar.';

  @override
  String get sleepMonthNoScoredNights =>
      'Deze maand zijn er nog geen gescoorde nachten beschikbaar.';

  @override
  String get sleepSettingsSectionTitle => 'Slaap';

  @override
  String get sleepEnableTrackingTitle => 'Slaap bijhouden inschakelen';

  @override
  String get sleepEnableTrackingSubtitle =>
      'Slaap en nachtelijke hartslag uitlezen via Health Connect / HealthKit';

  @override
  String get sleepHealthConnectionStatusTitle =>
      'Verbindingsstatus gezondheidsgegevens';

  @override
  String get sleepRequestAccessTitle => 'Toegang aanvragen';

  @override
  String get sleepRequestAccessSubtitle =>
      'Toestemming voor slaap en hartslag aanvragen of opnieuw aanvragen';

  @override
  String get sleepImportNowTitle => 'Slaapgegevens nu importeren';

  @override
  String get sleepImportNowSubtitle =>
      'Alle beschikbare slaapgegevens importeren';

  @override
  String get sleepRawImportsTitle => 'Ruwe slaapimports bekijken';

  @override
  String get sleepRawImportsSubtitle =>
      'Recente gegevens van Health Connect tonen';

  @override
  String get sleepDataStatusTitle => 'Gegevensstatus';

  @override
  String get sleepDataStatusSubtitle =>
      'Toestemming verleend. Als er nog geen slaapgegevens verschijnen, start hieronder een handmatige import.';

  @override
  String get sleepDataStatusSubtitleIos =>
      'Verbinding actief. Ontbreken er gegevens (0 sessies geïmporteerd), controleer dan handmatig de leesrechten in de Apple Gezondheid-app.';

  @override
  String get sleepNoPermissionSubtitle =>
      'Toestemming voor slaap en hartslag is nodig om slaapgegevens te importeren.';

  @override
  String get sleepFeatureUnavailableTitle => 'Functie niet beschikbaar';

  @override
  String get sleepFeatureUnavailableSubtitle =>
      'Slaap importeren is niet beschikbaar op dit apparaat of Health Connect is niet geïnstalleerd.';

  @override
  String get sleepNoRawImportsFound => 'Nog geen ruwe slaapimports gevonden.';

  @override
  String get sleepRawImportsSheetTitle => 'Ruwe slaapimports (meest recent)';

  @override
  String sleepImportFinishedSessions(int count) {
    return 'Slaapimport voltooid ($count sessies).';
  }

  @override
  String get sleepImportUnavailableCheckPermissions =>
      'Slaap importeren niet beschikbaar. Controleer de toestemmingen.';

  @override
  String get sleepStatusChecking => 'Toestemmingsstatus controleren…';

  @override
  String get sleepStatusReady => 'Gereed';

  @override
  String get sleepStatusDenied => 'Geweigerd';

  @override
  String get sleepStatusPartial => 'Gedeeltelijke toegang';

  @override
  String get sleepStatusUnavailable => 'Niet beschikbaar op dit apparaat';

  @override
  String get sleepStatusNotInstalled => 'Health Connect is niet geïnstalleerd';

  @override
  String get sleepStatusTechnicalError => 'Technische fout';

  @override
  String get sleepConnectHealthDataTitle => 'Gezondheidsgegevens koppelen';

  @override
  String get sleepConnectHealthDataMessage =>
      'Koppel HealthKit of Health Connect om slaapgegevens te importeren.';

  @override
  String get sleepPermissionDeniedTitle => 'Toestemming geweigerd';

  @override
  String get sleepPermissionDeniedMessage =>
      'Slaaptoestemming is geweigerd. Open de instellingen om toegang te verlenen.';

  @override
  String get sleepSourceUnavailableTitle => 'Bron niet beschikbaar';

  @override
  String get sleepSourceUnavailableMessage =>
      'De slaapgegevensbron is niet beschikbaar of niet geïnstalleerd op dit apparaat.';

  @override
  String get sleepEmptyDayNoData =>
      'Geen slaapgegevens beschikbaar voor deze dag.';

  @override
  String get sleepEmptyDayConnectMessage =>
      'Koppel Health Connect / HealthKit via Instellingen en importeer recente slaapgegevens.';

  @override
  String get sleepOpenSettingsButton => 'Instellingen openen';

  @override
  String get sleepImportNowButton => 'Nu importeren';

  @override
  String get sleepImportFinishedRefreshing =>
      'Slaapimport voltooid. Vernieuwen…';

  @override
  String get sleepImportUnavailableSettingsHint =>
      'Slaap importeren niet beschikbaar. Controleer de toestemmingen via Instellingen.';

  @override
  String get sleepTimelineTitle => 'Tijdlijn';

  @override
  String get sleepTimelineUnavailable =>
      'Voor deze nacht is geen tijdlijn met slaapfasen beschikbaar.';

  @override
  String get sleepSessionTypeCore => 'Kernslaap';

  @override
  String get sleepSessionTypeNap => 'Dutje';

  @override
  String get sleepIntervalsDrawerTitle => 'Slaapintervallen';

  @override
  String get sleepStageDeepLabel => 'Diep';

  @override
  String get sleepStageLightLabel => 'Licht';

  @override
  String get sleepStageRemLabel => 'REM';

  @override
  String get sleepStageAwakeLabel => 'Wakker';

  @override
  String get sleepScoreCardTitle => 'Slaapkwaliteit';

  @override
  String get sleepScoreUnavailableForNight =>
      'Voor deze nacht is geen score beschikbaar.';

  @override
  String sleepScoreCompletenessLabel(String value) {
    return 'Scorevolledigheid: $value';
  }

  @override
  String get sleepQualityGood => 'Goed';

  @override
  String get sleepQualityAverage => 'Gemiddeld';

  @override
  String get sleepQualityPoor => 'Slecht';

  @override
  String get sleepQualityUnavailable => 'Niet beschikbaar';

  @override
  String get sleepQualitySubtitleGood =>
      'De herstelsignalen gedurende de nacht waren gunstig.';

  @override
  String get sleepQualitySubtitleAverage =>
      'Je slaap was redelijk, maar er is ruimte voor verbetering.';

  @override
  String get sleepQualitySubtitlePoor =>
      'De herstelsignalen waren vannacht zwak.';

  @override
  String get sleepQualitySubtitleUnavailable =>
      'Er zijn onvoldoende gegevens om deze nacht een score te geven.';

  @override
  String get sleepQualityRegularityNotContributing =>
      'Regelmaat telt niet mee (minder dan 5 geldige dagen).';

  @override
  String get sleepQualityRegularityPreliminary =>
      'De regelmaat is voorlopig (5–6 geldige dagen).';

  @override
  String sleepQualityRegularityStable(int days) {
    return 'De regelmaat is stabiel ($days dagen).';
  }

  @override
  String sleepRegularityNightView(int count) {
    return 'Weergave van $count nachten';
  }

  @override
  String get sleepMetricUnavailable => 'Niet beschikbaar';

  @override
  String get sleepMetricDurationTitle => 'Duur';

  @override
  String get sleepMetricHeartRateTitle => 'Hartslag';

  @override
  String get sleepMetricRegularityTitle => 'Regelmaat';

  @override
  String get sleepMetricDepthTitle => 'Diepte';

  @override
  String get sleepMetricInterruptionsTitle => 'Onderbrekingen';

  @override
  String get sleepMetricDepthLowConfidence => 'Lage betrouwbaarheid';

  @override
  String get sleepMetricDepthStagesAvailable => 'Slaapfasen beschikbaar';

  @override
  String get sleepDurationUnavailable => 'Duurgegevens zijn niet beschikbaar.';

  @override
  String get sleepDurationStatusWithinTarget => 'Binnen het doel';

  @override
  String get sleepDurationStatusBelowTarget => 'Onder het doel';

  @override
  String get sleepDurationSubtitle => 'Je totale slaapduur voor deze nacht.';

  @override
  String get sleepDurationBenchmarkHint =>
      'Veel volwassenen functioneren het best met ongeveer 7–9 uur slaap. Deze richtlijn helpt je zien waar je nacht binnen dat bereik valt.';

  @override
  String get sleepDepthUnavailable =>
      'Gegevens over slaapdiepte zijn niet beschikbaar.';

  @override
  String get sleepDepthConfidenceTooLow =>
      'De betrouwbaarheid van de slaapfasen is te laag voor een betrouwbare uitsplitsing van slaapdiepte.';

  @override
  String get sleepDepthBreakdownUnavailable =>
      'Voor deze nacht is geen uitsplitsing van de duur per slaapfase beschikbaar.';

  @override
  String get sleepDepthRatingRestorative => 'Herstellend';

  @override
  String get sleepDepthRatingLightLeaning => 'Overwegend lichte slaap';

  @override
  String sleepDepthStageConfidenceLabel(String value) {
    return 'Betrouwbaarheid slaapfasen: $value';
  }

  @override
  String get sleepDepthSubtitle =>
      'Verdeling van de slaapfasen op basis van afgeleide tijdlijnsegmenten.';

  @override
  String get sleepInterruptionsUnavailable =>
      'Gegevens over onderbrekingen zijn niet beschikbaar.';

  @override
  String get sleepInterruptionsStatusNoneDetected => 'Geen gedetecteerd';

  @override
  String get sleepInterruptionsStatusDetected => 'Gedetecteerd';

  @override
  String get sleepInterruptionsSubtitle =>
      'Meetellende onderbrekingen waarbij je ’s nachts wakker was.';

  @override
  String get sleepInterruptionsTotalWakeDuration => 'Totale tijd wakker';

  @override
  String get sleepInterruptionsFootnote =>
      'Deze weergave bevat alleen onderbrekingen die meetellen volgens de afgeleide analyse.';

  @override
  String get sleepRegularityUnavailable =>
      'Gegevens over regelmaat zijn niet beschikbaar.';

  @override
  String sleepRegularityNightRange(int count) {
    return 'Bereik van $count nachten';
  }

  @override
  String get sleepRegularityStatusSufficientTrend =>
      'Voldoende gegevens voor een trend';

  @override
  String get sleepRegularityStatusLimitedTrend => 'Beperkte trendgegevens';

  @override
  String get sleepRegularitySubtitle =>
      'Bedtijd en wektijd van recente nachten.';

  @override
  String get sleepRegularityAverageBedtime => 'Gemiddelde bedtijd';

  @override
  String get sleepRegularityAverageWake => 'Gemiddelde wektijd';

  @override
  String get sleepHeartRateUnavailable =>
      'Hartslaggegevens tijdens de slaap zijn niet beschikbaar.';

  @override
  String get sleepHeartRateStatusNoSampleSeries =>
      'Geen reeks metingen voor deze nacht';

  @override
  String get sleepHeartRateStatusBaselineNotEstablished =>
      'Referentiewaarde nog niet vastgesteld';

  @override
  String get sleepHeartRateStatusComparisonUnavailable =>
      'Vergelijking met referentiewaarde niet beschikbaar';

  @override
  String get sleepHeartRateStatusBelowBaseline => 'Onder de referentiewaarde';

  @override
  String get sleepHeartRateStatusAboveBaseline => 'Boven de referentiewaarde';

  @override
  String get sleepHeartRateNoSamplesText =>
      'Er zijn voor deze nacht geen opgeslagen hartslagmetingen tijdens de slaap beschikbaar.';

  @override
  String get sleepHeartRateBaselineNotEstablishedText =>
      'De referentiewaarde is nog niet vastgesteld. Dat is normaal aan het begin.';

  @override
  String get sleepHeartRateComparisonUnavailableText =>
      'Vergelijking met de referentiewaarde is voor deze nacht momenteel niet beschikbaar.';

  @override
  String sleepHeartRateDeltaText(String direction, String delta, String unit) {
    return 'Je hartslag tijdens de slaap ligt $direction de referentiewaarde met $delta $unit.';
  }

  @override
  String get sleepHeartRateDirectionBelow => 'onder';

  @override
  String get sleepHeartRateDirectionAbove => 'boven';

  @override
  String get sleepHeartRateComparedBaselineSubtitle =>
      'Vergeleken met je vastgestelde slaapreferentie.';

  @override
  String get sleepHeartRateNoBaselineSubtitle =>
      'De referentiewaarde is nog niet vastgesteld. Dit is normaal.';

  @override
  String get sleepHeartRateSamplesUnavailable =>
      'Er zijn voor deze nacht geen hartslagmetingen opgeslagen. De trendlijn is niet beschikbaar.';

  @override
  String sleepHeartRateDashedLineHint(String value, String unit) {
    return 'De stippellijn toont je basiswaarde ($value $unit).';
  }

  @override
  String get sleepBpmUnit => 'bpm';

  @override
  String get sleepRawImportImportedAt => 'Geïmporteerd op';

  @override
  String get sleepRawImportStatus => 'Status';

  @override
  String get sleepRawImportSource => 'Bron';

  @override
  String get sleepRawImportApp => 'App';

  @override
  String get sleepRawImportConfidence => 'Betrouwbaarheid';

  @override
  String get sleepRawImportPayload => 'Gegevens';

  @override
  String get adaptiveBodyweightTargetSectionTitle =>
      'Adaptief lichaamsgewichtdoel';

  @override
  String get adaptiveRecommendationSettingsSectionTitle => 'Adviesinstellingen';

  @override
  String get adaptiveGoalDirectionLabel => 'Doelrichting';

  @override
  String get adaptiveGoalLose => 'Afvallen';

  @override
  String get adaptiveGoalMaintain => 'Gewicht behouden';

  @override
  String get adaptiveGoalGain => 'Aankomen';

  @override
  String adaptiveRatePerWeek(String value, Object unit) {
    return '$value $unit/week';
  }

  @override
  String get adaptivePriorActivityLabel =>
      'Gebruikelijke dagelijkse activiteit';

  @override
  String get adaptivePriorActivityLow => 'Weinig actief';

  @override
  String get adaptivePriorActivityModerate => 'Matig actief';

  @override
  String get adaptivePriorActivityHigh => 'Actief';

  @override
  String get adaptivePriorActivityVeryHigh => 'Zeer actief';

  @override
  String get adaptivePriorActivityHelpIntro =>
      'Alleen je gebruikelijke dagelijkse activiteit (exclusief extra cardio):';

  @override
  String get adaptivePriorActivityHelpLowLine =>
      'Laag: meestal zittend, zoals op school of op kantoor.';

  @override
  String get adaptivePriorActivityHelpModerateLine =>
      'Gemiddeld: afwisselend zitten, lopen en staan.';

  @override
  String get adaptivePriorActivityHelpHighLine =>
      'Hoog: veel staan of lopen, of een fysiek actieve baan.';

  @override
  String get adaptivePriorActivityHelpVeryHighLine =>
      'Zeer hoog: een zeer beweeglijke routine of baan met voortdurend veel dagelijkse activiteit.';

  @override
  String get adaptiveExtraCardioLabel =>
      'Extra cardio of duurtraining buiten de app';

  @override
  String get adaptiveExtraCardioOption0 => '0 u/week';

  @override
  String get adaptiveExtraCardioOption1 => '1 u/week';

  @override
  String get adaptiveExtraCardioOption2 => '2 u/week';

  @override
  String get adaptiveExtraCardioOption3 => '3 u/week';

  @override
  String get adaptiveExtraCardioOption5 => '5 u/week';

  @override
  String get adaptiveExtraCardioOption7Plus => '7+ u/week';

  @override
  String get adaptiveExtraCardioHelp =>
      'Tel joggen, hardlopen, fietsen, zwemmen en andere duurtrainingen mee die je niet als Train Libre-workout registreert.';

  @override
  String get onboardingAdaptiveGoalTitle => 'Adaptief voedingsadvies';

  @override
  String get onboardingAdaptiveGoalSubtitle =>
      'Kies je doel en tempo per week. We maken een voorzichtig startadvies en passen dit aan op basis van je registraties.';

  @override
  String get adaptiveRecommendationGenerating => 'Bezig met berekenen…';

  @override
  String get adaptiveRecommendationRefresh => 'Advies vernieuwen';

  @override
  String get onboardingAdaptiveSummaryEmpty =>
      'Stel je doel in en tik op Vernieuwen om je startadvies te bekijken.';

  @override
  String get onboardingAdaptiveSummaryTitle => 'Voorbeeld van je advies';

  @override
  String onboardingAdaptiveSummaryCalories(int value) {
    return 'Calorieën: $value kcal';
  }

  @override
  String onboardingAdaptiveSummaryProtein(int value) {
    return 'Eiwit: $value g';
  }

  @override
  String onboardingAdaptiveSummaryCarbs(int value) {
    return 'Koolhydraten: $value g';
  }

  @override
  String onboardingAdaptiveSummaryFat(int value) {
    return 'Vet: $value g';
  }

  @override
  String onboardingAdaptiveSummaryConfidence(String value) {
    return 'Gebaseerd op: $value';
  }

  @override
  String get onboardingAdaptiveSummaryApply => 'Toepassen op dagdoelen';

  @override
  String get onboardingAdaptiveSummaryApplied => 'Toegepast op dagdoelen';

  @override
  String get onboardingBodyFatPageTitle => 'Vetpercentage';

  @override
  String get onboardingBodyFatPageSubtitle =>
      'Optionele stap: vul een schatting in als je die weet.';

  @override
  String get onboardingBodyFatOptionalLabel => 'Vetpercentage (optioneel)';

  @override
  String get onboardingBodyFatOptionalHelper =>
      'Optioneel: vul dit alleen in als je je waarde ongeveer weet. Leeg laten is ook prima. Zo kunnen we je startadvies beter afstemmen.';

  @override
  String get onboardingBodyFatHelpAction => 'Hoe schat ik dit in?';

  @override
  String get bodyFatGuidanceTitle => 'Toelichting bij het vetpercentage';

  @override
  String get bodyFatGuidanceIntro =>
      'Je vetpercentage is op basis van je uiterlijk alleen globaal in te schatten. Dit is bedoeld als richtlijn, niet als nauwkeurige diagnose.';

  @override
  String get bodyFatGuidanceDisclaimer =>
      'Bij hetzelfde vetpercentage kan het uiterlijk sterk verschillen door spiermassa, vetverdeling, genetica, vocht vasthouden, houding en belichting.';

  @override
  String get bodyFatGuidanceSexLabel => 'Referentiegeslacht';

  @override
  String bodyFatGuidancePercent(int percent) {
    return '$percent%';
  }

  @override
  String get bodyFatGuidanceMale10 => 'Zeer slank, duidelijk gespierd.';

  @override
  String get bodyFatGuidanceMale15 => 'Atletisch en zichtbaar gespierd.';

  @override
  String get bodyFatGuidanceMale20 => 'Sportief, iets minder strak.';

  @override
  String get bodyFatGuidanceMale25 =>
      'Minder spierdefinitie, meer zachtheid rond taille en buik.';

  @override
  String get bodyFatGuidanceMale30 => 'Duidelijk zachter en ronder.';

  @override
  String get bodyFatGuidanceMale35 =>
      'Erg zacht, bijna geen zichtbare spierdefinitie.';

  @override
  String get bodyFatGuidanceMale40 =>
      'Veel ronder uiterlijk, zonder zichtbare spierdefinitie.';

  @override
  String get bodyFatGuidanceFemale15 => 'Zeer slank en gespierd.';

  @override
  String get bodyFatGuidanceFemale20 => 'Slank en atletisch.';

  @override
  String get bodyFatGuidanceFemale25 => 'Fit, met een lichte zachtheid.';

  @override
  String get bodyFatGuidanceFemale30 =>
      'Zacht en gezond ogend, van atletisch tot gemiddeld.';

  @override
  String get bodyFatGuidanceFemale35 => 'Merkbaar zachter.';

  @override
  String get bodyFatGuidanceFemale40 =>
      'Over het geheel duidelijk zachter en ronder.';

  @override
  String get adaptiveRecommendationCardTitle => 'Adaptief advies';

  @override
  String get adaptiveRecommendationEmptyBody =>
      'Registreer ongeveer een week je gewicht en voeding om je eerste weekadvies te krijgen.';

  @override
  String adaptiveRecommendationGoalLine(String goal, String rate) {
    return 'Doel: $goal ($rate)';
  }

  @override
  String adaptiveRecommendationMaintenanceLine(int value) {
    return 'Geschat onderhoud: $value kcal';
  }

  @override
  String adaptiveRecommendationMaintenanceRangeLine(int lower, int upper) {
    return 'Waarschijnlijk bereik: $lower-$upper kcal';
  }

  @override
  String get adaptiveRecommendationUncertaintyHintNarrow =>
      'Je waarschijnlijke onderhoudsbereik is vrij smal. Kleine schommelingen van dag tot dag zijn normaal.';

  @override
  String get adaptiveRecommendationUncertaintyHintModerate =>
      'Je waarschijnlijke onderhoudsbereik is nu gemiddeld. Schommelingen van week tot week zijn normaal.';

  @override
  String get adaptiveRecommendationUncertaintyHintWide =>
      'Je waarschijnlijke onderhoudsbereik is nog breed. Dat is normaal terwijl we meer consistente gegevens verzamelen.';

  @override
  String get adaptiveRecommendationStabilizingHint =>
      'We stemmen de berekening nog af op je recente fase. Daardoor kan deze schatting meer dan gebruikelijk veranderen.';

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
    return 'Gebaseerd op: $value';
  }

  @override
  String adaptiveRecommendationDataBasisLine(
      int windowDays, int weightLogs, int intakeDays) {
    return 'Gebaseerd op $windowDays dagen, $weightLogs gewichtsregistraties en $intakeDays voedingsdagen';
  }

  @override
  String adaptiveRecommendationActiveCaloriesLine(int value) {
    return 'Huidige actieve calorieën: $value kcal';
  }

  @override
  String adaptiveRecommendationCalculatedAtLine(String value) {
    return 'Berekend op: $value';
  }

  @override
  String adaptiveRecommendationNextDueLine(String value) {
    return 'Volgend adaptief advies: $value';
  }

  @override
  String adaptiveRecommendationNextDueShort(String value) {
    return 'Volgende: $value';
  }

  @override
  String get adaptiveRecommendationDueNowLine =>
      'Deze week is een nieuw adaptief advies aan de beurt.';

  @override
  String get adaptiveRecommendationDueNowShort => 'Deze week aan de beurt';

  @override
  String get adaptiveRecommendationMaintenanceLabel => 'Geschat onderhoud';

  @override
  String get adaptiveRecommendationWhyTitle => 'Waarom dit advies?';

  @override
  String get adaptiveRecommendationWhySubtitle =>
      'Onderhoudsschatting, gegevenskwaliteit en berekening';

  @override
  String get adaptiveRecommendationMaintenanceSourceLabel =>
      'Profielbasis + recente registraties';

  @override
  String get adaptiveRecommendationMaintenanceUnit => 'kcal/dag';

  @override
  String get adaptiveRecommendationMacroTargetsLabel => 'Aanbevolen doelen';

  @override
  String get adaptiveRecommendationAlreadyActive => 'Al actief';

  @override
  String adaptiveRecommendationTargetChange(String value) {
    return '$value ten opzichte van het huidige doel';
  }

  @override
  String get adaptiveRecommendationTargetCaloriesLabel => 'Caloriedoel';

  @override
  String get adaptiveRecommendationDataQualityLabel => 'Gegevenskwaliteit';

  @override
  String adaptiveRecommendationTrajectoryCorrectionLine(String value) {
    return 'Trendcorrectie: $value kcal/dag';
  }

  @override
  String get adaptiveRecommendationTrajectoryCorrectionExplanation =>
      'Een begrensde aanpassing brengt je recente gewichtsverandering geleidelijk dichter bij je doeltempo.';

  @override
  String get adaptiveRecommendationRecalculateNowAction =>
      'Nu opnieuw berekenen';

  @override
  String get adaptiveRecommendationRecalculating => 'Opnieuw berekenen…';

  @override
  String get adaptiveRecommendationApplying => 'Toepassen…';

  @override
  String get adaptiveRecommendationApplyAction => 'Advies toepassen';

  @override
  String get adaptiveRecommendationWarningCalorieFloor =>
      'Het advies is begrensd door een minimum aan calorieën voor de veiligheid. Controleer je profielgegevens en recente registraties voordat je het toepast.';

  @override
  String get adaptiveRecommendationWarningUnresolvedFood =>
      'Voor sommige voedingsregistraties konden de calorieën niet volledig worden bepaald. Controleer je recente registraties voordat je het advies toepast.';

  @override
  String get adaptiveRecommendationWarningLargeAdjustment =>
      'Er is een grote aanpassing vastgesteld. Controleer of je recente registraties volledig zijn voordat je deze toepast.';

  @override
  String get adaptiveRecommendationWarningMacroConstrained =>
      'De verdeling van macronutriënten is begrensd door het caloriebudget. Controleer of je doeltempo niet te ambitieus is.';

  @override
  String get adaptiveRecommendationWarningConservative =>
      'Controle aanbevolen: door wisselende gegevens is het advies voorzichtig aangepast.';

  @override
  String get adaptiveRecommendationDataBasisHintDefault =>
      'Gebaseerd op recente registraties en hoe volledig die zijn.';

  @override
  String get adaptiveRecommendationDataBasisHintPriorOnly =>
      'Alleen gebaseerd op profiel- en eerdere gegevens. Voeg recente gewichts- en voedingsregistraties toe voor een adaptieve aanpassing.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseWeight =>
      'Er zijn weinig recente gewichtsregistraties, waardoor de trend minder betrouwbaar is.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseIntake =>
      'Er zijn weinig recente voedingsregistraties, waardoor de onderhoudsschatting minder betrouwbaar is.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseWeightAndIntake =>
      'Er zijn weinig recente gewichts- en voedingsregistraties, daarom is dit advies voorzichtiger.';

  @override
  String get adaptiveConfidenceNotEnoughData =>
      'Alleen profiel- en eerdere gegevens';

  @override
  String get adaptiveConfidenceLow => 'Weinig recente registraties';

  @override
  String get adaptiveConfidenceMedium => 'Bruikbare recente registraties';

  @override
  String get adaptiveConfidenceHigh => 'Sterke recente registraties';

  @override
  String get adaptiveRecommendationRecalculatedSnack =>
      'Advies opnieuw berekend.';

  @override
  String get adaptiveRecommendationAppliedToGoalsSnack =>
      'Advies toegepast op actieve doelen.';

  @override
  String get adaptiveRecommendationNotAvailableSnack =>
      'Er is geen advies beschikbaar om toe te passen.';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsAppearanceSubtitle =>
      'Pas thema, vormgeving en haptische feedback aan';

  @override
  String get settingsShowSugarInDiaryOverviewTitle =>
      'Suiker tonen in het dagoverzicht';

  @override
  String get settingsShowSugarInDiaryOverviewSubtitle =>
      'Toont suiker in het bovenste deel van het dagoverzicht';

  @override
  String get settingsOverviewExtraNutrientTitle =>
      'Extra voedingsstof in het overzicht';

  @override
  String get settingsOverviewExtraNutrientSubtitle =>
      'Voeg een derde voedingsstoftegel toe aan het dagoverzicht';

  @override
  String get settingsSectionHealthTracking => 'Gezondheid en bijhouden';

  @override
  String get healthSettingsTitle => 'Gezondheid';

  @override
  String get onboardingHealthSettingsDescription =>
      'Beheer stappen, slaap, hartslag en Apple Health of Health Connect';

  @override
  String get healthSettingsStepActive => 'Stappentracking staat aan';

  @override
  String get healthSettingsStepAvailable => 'Stappengegevens zijn beschikbaar';

  @override
  String get healthSettingsStepUnavailable =>
      'Stappengegevens zijn niet beschikbaar';

  @override
  String get healthSettingsSyncSteps => 'Stappen nu synchroniseren';

  @override
  String get healthSettingsSyncExport => 'Nu exporteren';

  @override
  String healthSettingsStepsSyncResult(int count) {
    return '$count stapsegmenten bijgewerkt';
  }

  @override
  String healthSettingsSleepSyncResult(int count) {
    return '$count slaapsessies geïmporteerd';
  }

  @override
  String get settingsStepsSubtitle => 'Bijhouden, bronbeleid en providers';

  @override
  String get settingsSleepSubtitle => 'Import, machtigingen en slaapstatus';

  @override
  String get settingsPulseSubtitle =>
      'Optionele hartslaganalyse en toegang tot hartslaggegevens';

  @override
  String get settingsHealthExportSubtitle =>
      'Beheer export naar Apple Health en Health Connect';

  @override
  String get settingsSectionNutritionAndData => 'Voeding en gegevens';

  @override
  String get settingsSectionSupportAbout => 'Ondersteuning en over';

  @override
  String get settingsHapticFeedbackTitle => 'Haptische feedback';

  @override
  String get settingsHapticFeedbackSubtitle =>
      'Lichte trillingen bij bevestigingen en tijdens het wachten op AI';

  @override
  String get stepsSettingsEnableTrackingTitle => 'Stappentracking inschakelen';

  @override
  String get stepsSettingsEnableTrackingSubtitle =>
      'Stapgegevens lezen uit Apple Health of Health Connect';

  @override
  String get stepsSettingsSourcePolicyTitle => 'Bronbeleid';

  @override
  String get stepsSettingsSourcePolicyAutoDominant =>
      'Automatisch (voorkeursbron)';

  @override
  String get stepsSettingsSourcePolicyAutoDominantSubtitle =>
      'Aanbevolen: gebruik per dag één bron om dubbeltellingen te voorkomen.';

  @override
  String get stepsSettingsSourcePolicyMaxPerHour =>
      'Samenvoegen (maximum per uur)';

  @override
  String get stepsSettingsSourcePolicyMaxPerHourSubtitle =>
      'Combineer bronnen door per uur de hoogste waarde te gebruiken.';

  @override
  String get stepsSettingsProviderFilterTitle => 'Providerfilter';

  @override
  String get pulseTitle => 'Hartslag';

  @override
  String get pulseChartTitle => 'Hartslag in de tijd';

  @override
  String get pulseRangeLabel => 'Bereik';

  @override
  String get pulseAverageLabel => 'Gemiddelde';

  @override
  String get pulseRestingLabel => 'In rust';

  @override
  String get pulseInsufficientData =>
      'Er zijn te weinig hartslagmetingen voor een betrouwbare grafiek.';

  @override
  String get pulseMethodNote =>
      'De gemiddelde hartslag is tijdgewogen. De rusthartslag is een voorzichtige schatting op basis van de laagste 20% van de metingen in de geselecteerde periode.';

  @override
  String pulseSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count metingen',
      one: '1 meting',
      zero: 'Geen metingen',
    );
    return '$_temp0';
  }

  @override
  String get pulseQualityReady => 'Goede dekking';

  @override
  String get pulseQualityLimited => 'Beperkte gegevens';

  @override
  String get pulseQualityInsufficient => 'Zeer weinig gegevens';

  @override
  String get pulseQualityNoData => 'Geen gegevens';

  @override
  String get pulseNoDataDisabled =>
      'Hartslaganalyse is uitgeschakeld in Instellingen.';

  @override
  String get pulseNoDataPermissionDenied =>
      'Toegang tot hartslaggegevens is nodig om de hartslaganalyse te tonen.';

  @override
  String get pulseNoDataUnavailable =>
      'Hartslaggegevens zijn momenteel niet beschikbaar op dit apparaat.';

  @override
  String get pulseNoDataQueryFailed =>
      'Hartslaggegevens konden niet worden gelezen.';

  @override
  String get pulseNoDataDefault =>
      'Er zijn geen hartslagmetingen gevonden voor deze periode.';

  @override
  String get pulseSettingsEnableTitle => 'Hartslaganalyse inschakelen';

  @override
  String get pulseSettingsEnableSubtitle =>
      'Hartslaggegevens worden alleen gelezen voor het hartslagoverzicht als je dit inschakelt.';

  @override
  String get pulseSettingsPermissionTitle =>
      'Toegang tot hartslaggegevens toestaan';

  @override
  String get pulseSettingsPermissionSubtitle =>
      'Opent Apple Health of Health Connect zodat Train Libre hartslagmetingen kan lezen.';

  @override
  String get pulseSettingsAnalysisSubtitle =>
      'Toont het bereik, het tijdgewogen gemiddelde en een voorzichtige schatting van je rusthartslag. Dit is geen medische diagnose.';

  @override
  String get pulseSettingsPermissionGranted =>
      'Toegang tot hartslaggegevens is ingesteld.';

  @override
  String get pulseSettingsPermissionFailed =>
      'Toegang tot hartslaggegevens is niet verleend.';

  @override
  String get pulseOptInChip => 'Optioneel';

  @override
  String get statisticsPulseDescription =>
      'Bereik, tijdgewogen gemiddelde en rusthartslag voor geselecteerde perioden.';

  @override
  String get statisticsPulseOpenCaption => 'Opent de hartslaganalyse';

  @override
  String get healthExportTitle => 'Gezondheidsgegevens exporteren';

  @override
  String get healthExportAppleHealthTitle => 'Export naar Apple Health';

  @override
  String get healthExportHealthConnectTitle => 'Export naar Health Connect';

  @override
  String get healthExportDomainNutritionHydration => 'Voeding en hydratatie';

  @override
  String get healthNutritionImportTitle => 'Voeding importeren';

  @override
  String get healthNutritionImportSubtitle =>
      'Importeer dagtotalen uit Apple Health of Health Connect in je dagboek.';

  @override
  String get healthNutritionImportPolicy =>
      'Handmatige invoer blijft apart. Geïmporteerde dagen worden na lokale wijzigingen niet overschreven en na verwijdering niet opnieuw aangemaakt.';

  @override
  String get healthExportDomainWorkouts => 'Trainingen';

  @override
  String get healthExportStateIdle => 'Inactief';

  @override
  String get healthExportStateExporting => 'Bezig met exporteren';

  @override
  String get healthExportStateSuccess => 'Geslaagd';

  @override
  String get healthExportStateFailed => 'Mislukt';

  @override
  String get healthExportStatePermissionRequired => 'Toestemming vereist';

  @override
  String get healthExportStateDisabled => 'Uitgeschakeld';

  @override
  String get healthExportResultComplete => 'Export voltooid';

  @override
  String get healthExportResultFailed => 'Export mislukt';

  @override
  String get healthExportAppleHealthSubtitle =>
      'Eenrichtingsverkeer naar Apple Health. Train Libre leest alleen de eigen geëxporteerde gegevens, zodat wijzigingen deze veilig kunnen vervangen.';

  @override
  String get healthExportHealthConnectSubtitle =>
      'Eenrichtingsverkeer van Train Libre naar Health Connect';

  @override
  String get healthExportAppleHealthStatusTitle => 'Exportstatus Apple Health';

  @override
  String get healthExportHealthConnectStatusTitle =>
      'Exportstatus Health Connect';

  @override
  String get healthConnectWeightImportTitle =>
      'Lichaamsmetingen uit Health Connect importeren';

  @override
  String get healthConnectWeightImportSubtitle =>
      'Importeer gewicht en vetpercentage van weegschalen en andere apps. Gegevens van Train Libre worden genegeerd.';

  @override
  String get appleHealthWeightImportTitle =>
      'Lichaamsmetingen uit Apple Health importeren';

  @override
  String get appleHealthWeightImportSubtitle =>
      'Importeer gewicht, vetpercentage en tailleomtrek uit Apple Health. Gegevens van Train Libre worden genegeerd.';

  @override
  String get healthConnectWeightImportReady =>
      'Toegang tot de volledige geschiedenis ingeschakeld';

  @override
  String get healthConnectWeightImportLimited =>
      'Beperkt tot de beschikbare recente geschiedenis';

  @override
  String get healthConnectWeightImportUnavailable =>
      'Health Connect is niet beschikbaar';

  @override
  String get healthConnectWeightImportNow => 'Nu importeren';

  @override
  String healthConnectWeightImportResult(int imported, int updated) {
    return '$imported geïmporteerd, $updated bijgewerkt';
  }

  @override
  String get settingsBaseFoodLanguageTitle => 'Weergavetaal van basisproducten';

  @override
  String get settingsBaseFoodLanguageSubtitle =>
      'Kies de taal voor de namen van basisproducten.';

  @override
  String get settingsBaseFoodLanguageFollowApp => 'App-taal volgen';

  @override
  String get settingsBaseFoodLanguageEnglish => 'Engels';

  @override
  String get settingsBaseFoodLanguageGerman => 'Duits';

  @override
  String get settingsBaseFoodLanguageFrench => 'Frans';

  @override
  String get settingsBaseFoodLanguageItalian => 'Italiaans';

  @override
  String get settingsBaseFoodLanguageJapanese => 'Japans';

  @override
  String get settingsBaseFoodLanguageSpanish => 'Spaans';

  @override
  String get settingsBaseFoodLanguageDutch => 'Nederlands';

  @override
  String get aiModelLabel => 'Model';

  @override
  String get aiModelListFallbackTitle =>
      'De ingebouwde modellijst wordt getoond';

  @override
  String get aiModelListRetry => 'Modellen opnieuw laden';

  @override
  String get aiModelListErrorMissingKey =>
      'Sla je API-sleutel op om de actuele modellen van de provider te laden.';

  @override
  String get aiModelListErrorNetwork =>
      'De provider is niet bereikbaar. Controleer je internetverbinding.';

  @override
  String get aiModelListErrorTimeout =>
      'De provider heeft niet binnen de ingestelde tijd geantwoord.';

  @override
  String aiModelListErrorAuth(Object status) {
    return 'De provider heeft je API-sleutel geweigerd (HTTP $status). Controleer de sleutel en de machtigingen.';
  }

  @override
  String aiModelListErrorRateLimit(Object status) {
    return 'De provider beperkt het aantal verzoeken of je quotum is op (HTTP $status). Probeer het zo meteen opnieuw.';
  }

  @override
  String aiModelListErrorHttp(Object status) {
    return 'De provider antwoordde met HTTP $status.';
  }

  @override
  String get aiModelListErrorResponse =>
      'De modellijst van de provider kon niet worden gelezen.';

  @override
  String get autoBackupStoragePickerUnavailable =>
      'De opslaglocatiekiezer is niet beschikbaar. Start de app na de update volledig opnieuw op of installeer deze opnieuw.';

  @override
  String autoBackupFolderPickerFailed(Object error) {
    return 'De mapkiezer is mislukt: $error';
  }

  @override
  String get healthExportPermissionDenied => 'Toestemming geweigerd';

  @override
  String get healthExportAdapterUnavailable => 'Adapter niet beschikbaar';

  @override
  String get healthExportPlatformUnavailable => 'Platform niet beschikbaar';

  @override
  String get healthExportPlatformNotInstalled => 'Platform niet geïnstalleerd';

  @override
  String get healthExportExportDisabled => 'Export uitgeschakeld';

  @override
  String get onboardingMacrosStepTitle => 'Macronutriënten';

  @override
  String get onboardingMacrosStepSubtitle => 'Hoe is je voeding samengesteld?';

  @override
  String get statisticsProviderAppleHealth => 'Apple Health';

  @override
  String get statisticsProviderHealthConnect => 'Health Connect';

  @override
  String get statisticsProviderWithings => 'Withings';

  @override
  String get statisticsProviderGarmin => 'Garmin';

  @override
  String get statisticsProviderFitbit => 'Fitbit';

  @override
  String get statisticsProviderLocal => 'Lokaal';

  @override
  String get unit_milliliters => 'ml';

  @override
  String get unit_kilograms => 'kg';

  @override
  String get mealEditorHintExample => 'bijv. kipbowl';

  @override
  String get mealEditorNoIngredientsYet =>
      'Nog geen ingrediënten – volgt later';

  @override
  String get foodDetailSavedBaseDb => 'Opgeslagen (basisdatabase)';

  @override
  String foodDetailExportError(Object error) {
    return 'Exportfout: $error';
  }

  @override
  String get stepsModulePrevious => 'Vorige';

  @override
  String get stepsModuleNext => 'Volgende';

  @override
  String get stepsModuleTotalSteps => 'Totaal aantal stappen';

  @override
  String get stepsModuleThisWeek => 'Deze week';

  @override
  String get stepsModuleThisMonth => 'Deze maand';

  @override
  String stepsModuleUpdated(String time) {
    return 'Bijgewerkt: $time';
  }

  @override
  String get stepsModuleScopeSwitcherSemantics =>
      'Periode voor stappen wijzigen';

  @override
  String get stepsModuleDay => 'Dag';

  @override
  String get stepsModuleWeek => 'Week';

  @override
  String get stepsModuleMonth => 'Maand';

  @override
  String get stepsModuleHourlyTimeline => 'Tijdlijn per uur';

  @override
  String get stepsModuleTotal => 'Totaal';

  @override
  String get stepsModuleActiveHours => 'Actieve uren';

  @override
  String get stepsModulePeakHour => 'Piekuur';

  @override
  String get stepsModuleAvgPerDay => 'Gem. per dag';

  @override
  String get stepsModuleGoalHit => 'Doel behaald';

  @override
  String get stepsModuleGoalDays => 'Dagen met behaald doel';

  @override
  String get diarySyncingSteps => 'Stappen synchroniseren…';

  @override
  String get diaryLoadingSleep => 'Slaapgegevens laden…';

  @override
  String get unit_milligrams => 'mg';

  @override
  String get scannerPermissionRequired =>
      'Cameratoegang is nodig om barcodes te scannen.';

  @override
  String get scannerPermissionPermanentlyDenied =>
      'Cameratoegang is permanent geweigerd. Schakel deze in bij Instellingen om barcodes te scannen.';

  @override
  String get scannerOpenSettings => 'Instellingen openen';

  @override
  String get scannerGrantPermission => 'Doorgaan';

  @override
  String get scannerAlignInstruction =>
      'Houd de barcode horizontaal binnen de rode laserlijn';

  @override
  String get scannerToggleFlash => 'Zaklamp in- of uitschakelen';

  @override
  String get about_train_libre => 'Over Train Libre';

  @override
  String get legal_notice => 'Juridische informatie';

  @override
  String get privacy_policy => 'Privacybeleid';

  @override
  String get terms_of_service => 'Servicevoorwaarden';

  @override
  String get view_in_browser => 'In browser bekijken';

  @override
  String get legal_document_version => 'Versie';

  @override
  String get legal_document_last_updated => 'Laatst bijgewerkt';

  @override
  String get used_libraries => 'Gebruikte bibliotheken';

  @override
  String get licensing_info => 'Licentie-informatie';

  @override
  String get project_website => 'Projectwebsite';

  @override
  String get github_repository => 'GitHub-opslagplaats';

  @override
  String get health_permission_dialog_title => 'Gezondheidsgegevens en privacy';

  @override
  String get health_permission_dialog_body =>
      'Train Libre moet je stappengegevens lezen om dag- en weekstatistieken te tonen. Je gegevens blijven op je apparaat; er is geen externe server.';

  @override
  String get health_permission_continue => 'Doorgaan';

  @override
  String get health_permission_not_now => 'Niet nu';

  @override
  String get welcome_privacy_title => 'Welkom en privacy';

  @override
  String get welcome_privacy_body =>
      'Voor trainingsregistratie en trainingsinzichten verwerken we je fitness- en activiteitsgegevens zoals beschreven in ons Privacybeleid.';

  @override
  String get i_agree_to_privacy_policy =>
      'Ik geef uitdrukkelijk toestemming voor de verwerking van mijn fitness- en gezondheidsgegevens voor trainingsregistratie en trainingsinzichten. Ik kan deze toestemming op elk moment intrekken via Instellingen.';

  @override
  String get i_agree_to_optional_telemetry =>
      '(Optioneel) Ik wil geanonimiseerde gebruiksstatistieken delen om de stabiliteit en functies van de app te verbeteren (geen persoonlijke of gezondheidsgegevens).';

  @override
  String get welcome_back_updated_legal_title =>
      'Welkom terug en bijgewerkt beleid';

  @override
  String legal_update_body(String version) {
    return 'We hebben ons Privacybeleid en onze Servicevoorwaarden bijgewerkt (versie $version). Bevestig de bijgewerkte voorwaarden om Train Libre te blijven gebruiken. Al je bestaande gegevens blijven veilig op je apparaat opgeslagen.';
  }

  @override
  String i_agree_to_updated_privacy_policy(String version) {
    return 'Ik geef uitdrukkelijk toestemming voor het bijgewerkte privacybeleid (v$version) en de verwerking van mijn fitness- en gezondheidsgegevens.';
  }

  @override
  String get accept_and_continue => 'Accepteren en doorgaan';

  @override
  String get by_tapping_accept_continue =>
      'Door op ‘Accepteren en doorgaan’ te tikken, ga je akkoord met het bijgewerkte';

  @override
  String get acceptTermsPrompt => 'Ik ga akkoord met de servicevoorwaarden';

  @override
  String get viewTermsInline => 'Servicevoorwaarden';

  @override
  String get accept_and_get_started => 'Accepteren en starten';

  @override
  String get by_tapping_accept =>
      'Door op ‘Accepteren en starten’ te tikken, ga je akkoord met';

  @override
  String get and_acknowledge => 'en bevestig je dat je hebt gelezen';

  @override
  String get about_section => 'Over';

  @override
  String get legal_section => 'Juridisch';

  @override
  String get aiSettingsInstructionTitle => 'Zo werken AI-functies';

  @override
  String get aiSettingsInstructionBody =>
      'Train Libre biedt AI-functies zoals chat en maaltijdherkenning. Bij maaltijdherkenning analyseert AI afbeeldingen van eten en schat het de voedingswaarden. Afbeeldingen en tekst worden alleen naar de door jou gekozen AI-provider gestuurd wanneer je een AI-functie gebruikt. Met je eigen API-sleutel (BYOK) blijven je gegevens tot dat moment op je apparaat.';

  @override
  String get aiSettingsSetupGuideTitle => 'Installatiehandleiding';

  @override
  String get aiSettingsSetupGuideBody =>
      'Voor deze functie heb je een API-sleutel van een AI-provider nodig. Google Gemini dient als hoofdvoorbeeld, omdat het momenteel een gratis versie aanbiedt voor ontwikkelaars en gebruikers.';

  @override
  String get aiSettingsGetApiKeyButton => 'Installatiehandleiding bekijken';

  @override
  String get legal_document_version_value => '1.2';

  @override
  String get legal_document_last_updated_value => '20 mei 2026';

  @override
  String get muscleChest => 'Borst';

  @override
  String get muscleBack => 'Rug';

  @override
  String get muscleShoulders => 'Schouders';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleQuads => 'Quadriceps';

  @override
  String get muscleHamstrings => 'Hamstrings';

  @override
  String get muscleLegs => 'Benen';

  @override
  String get muscleArms => 'Armen';

  @override
  String get muscleGlutes => 'Bilspieren';

  @override
  String get muscleCalves => 'Kuiten';

  @override
  String get muscleLowerBack => 'Onderrug';

  @override
  String get muscleAbs => 'Buikspieren';

  @override
  String get muscleAdductors => 'Adductoren';

  @override
  String get muscleForearms => 'Onderarmen';

  @override
  String get sleepDetailAnalysisHeader => 'Gedetailleerde analyse';

  @override
  String get sleepMetricDurationLabel => 'Slaapduur';

  @override
  String get sleepMetricContinuityLabel => 'Continuïteit (WASO/SE)';

  @override
  String get sleepMetricDepthLabel => 'Diepte van slaapfasen';

  @override
  String get sleepMetricTimingLabel => 'Circadiaans ritme';

  @override
  String get sleepMetricRegularityLabel => 'Regelmaat';

  @override
  String get sleepBannerTstBottleneck =>
      'Straf voor slaapduur actief: je totale slaapduur bleef onder het herstellende optimum van 6,5 uur, waardoor de afgifte van anabole hormonen wordt beperkt.';

  @override
  String get sleepBannerRemBottleneck =>
      'Straf voor REM-slaaptekort: je had minder dan 60 minuten REM-slaap. Dit belemmert het neurologisch herstel en de mentale alertheid.';

  @override
  String get sleepBannerN3Bottleneck =>
      'Straf voor tekort aan diepe slaap: je had minder dan 70 minuten diepe N3-slaap. Het herstel van spierweefsel is daardoor mogelijk onvoldoende.';

  @override
  String get sleepBannerTimingBottleneck =>
      'Straf voor een verschoven circadiaans ritme: het midden van je slaap viel na 05.30 uur. Slapen tegen je interne klok in vermindert de slaapkwaliteit en insulinegevoeligheid.';

  @override
  String get sleepBannerDefaultPenalty =>
      'Beschermende klinische begrenzing actief: je slaapduur was onvoldoende (minder dan 6 uur) of je inslaaptijd was sterk verschoven. De totaalscore is begrensd.';

  @override
  String get infoTdeeTitle => 'Adaptieve calorie- en TDEE-schatting';

  @override
  String get infoTdeeExplanation =>
      'Schat je totale dagelijkse energieverbruik (TDEE) op basis van je profiel, geregistreerde maaltijden en gewichtsveranderingen.';

  @override
  String get infoTdeeKeyPoints =>
      '• Gebruikt je gewichts- en voedingsregistraties van de afgelopen 14 dagen om je onderhoud te schatten.\n• Rekent gewichtsschommelingen bij een fasewisseling mee als extra onzekerheid.\n• Gebruikt een aparte begrensde aanpassing wanneer je tempo langdurig afwijkt van je doel.';

  @override
  String get infoTdeeTechnicalTitle =>
      'Bayesiaanse recursieve filtering en metabole afvlakking';

  @override
  String get infoTdeeTechnicalExplanation =>
      'Train Libre schat het onderhoud als een dynamische verborgen toestand met een recursief Kalman-filter. De wekelijkse procesonzekerheid laat de schatting echte metabole veranderingen volgen, terwijl meetonzekerheid overreacties op vochtgewicht en onvolledige registraties beperkt. Een afzonderlijke begrensde trajectregeling kan het caloriedoel aanpassen na twee aanhoudende afwijkingen in tempo, zonder de onderhoudsschatting te wijzigen.';

  @override
  String get infoRecoveryTitle => 'Schatting van spierherstel';

  @override
  String get infoRecoveryExplanation =>
      'Schat de belastbaarheid en herstelcurves per spier op basis van trainingsvolume, intensiteit en hoe dicht je bij spierfalen traint.';

  @override
  String get infoRecoveryKeyPoints =>
      '• Houdt rekening met overlappende spierbelasting (bankdrukken belast bijvoorbeeld borst, triceps en schouders).\n• Stemt de herstelsnelheid af op RIR/RPE en verlengt de hersteltijd bij sets tot spierfalen.\n• Kalibreert de hersteltijd per spiergroep op basis van omvang en stofwisseling.';

  @override
  String get infoRecoveryTechnicalTitle =>
      'Vermoeidheid in equivalente sets en een stukgewijs vervalmodel';

  @override
  String get infoRecoveryTechnicalExplanation =>
      'Berekent de dynamische belastbaarheid met niet-lineaire vervalcurves. De volumetracking verdeelt de belasting automatisch over primaire en secundaire spiergroepen. De herstelsnelheid hangt af van de nabijheid tot spierfalen (RIR); sets tot volledig spierfalen leiden tot een aanzienlijk langere hersteltijd.';

  @override
  String get infoScientificReferencesButton =>
      'Wetenschappelijke bronnen bekijken';

  @override
  String get infoScientificDisclaimer =>
      'Deze functie is gebaseerd op gevestigde literatuur over sportwetenschap en metabole modellen. De volledige lijst met peer-reviewed bronnen staat op onze website.';

  @override
  String get infoAiMealTitle => 'AI-maaltijdregistratie';

  @override
  String get infoAiMealExplanation =>
      'Zet foto’s of tekstbeschrijvingen van maaltijden om in gestructureerde dagboekregistraties en vergelijkt ze met je persoonlijke productendatabase.';

  @override
  String get infoAiMealKeyPoints =>
      '• Zet onnauwkeurige beschrijvingen (zoals ‘een snee brood’) om in schattingen in grammen.\n• Vergelijkt AI-suggesties offline met de lokale productendatabase op je apparaat.\n• Berekent voedingswaarden lokaal en besteedt die berekening niet uit aan externe servers.';

  @override
  String get infoAiMealTechnicalTitle =>
      'Hybride BYOK-AI en Jaro-Winkler-overeenkomst';

  @override
  String get infoAiMealTechnicalExplanation =>
      'Gebruikt een privacymodel waarbij je je eigen sleutel meeneemt (BYOK). AI doet uitsluitend suggesties. Het vergelijken gebeurt offline met een getokeniseerd Jaro-Winkler-filter op de lokale SQLite-database. De systeeminstructies verbieden de AI-provider uitdrukkelijk om voedingswaarden te berekenen.';

  @override
  String get infoSleepTitle => 'Slaapkwaliteit (SHS v3.5)';

  @override
  String get infoSleepExplanation =>
      'Berekent een uitgebreide slaapindex op basis van hoeveelheid, continuïteit, diepte, timing en dagelijkse regelmaat.';

  @override
  String get infoSleepKeyPoints =>
      '• Combineert vijf klinische dimensies met een gewogen som.\n• Past de vereisten automatisch aan als je wearable geen slaapfasen of efficiëntiegegevens aanlevert.\n• Beschermt je met zachte begrenzingsfactoren die de totaalscore beperken wanneer een belangrijk domein, zoals REM- of diepe slaap, tekortschiet.';

  @override
  String get infoSleepTechnicalTitle =>
      'Gewogen basiswaarde en doorlopende zachte begrenzingen';

  @override
  String get infoSleepTechnicalExplanation =>
      'Combineert vijf hoofddomeinen met een gewogen lineaire som: duur (30%), continuïteit (20%), slaapstructuur (25%), timing (15%) en regelmaat (10%). Om misleidende gemiddelden te voorkomen wanneer een klinisch domein tekortschiet, wordt de eindscore verlaagd als er ernstige knelpunten in slaapfasen of circadiaanse timing worden vastgesteld.';

  @override
  String get tdeeRecalculationNotificationTitle => 'TDEE opnieuw berekend';

  @override
  String tdeeRecalculationNotificationBody(
      int calories, int protein, int carbs, int fat) {
    return 'Nieuwe dagdoelen: $calories kcal | $protein g eiwit | $carbs g koolhydraten | $fat g vet';
  }

  @override
  String recommendationBannerText(String delta) {
    return 'Nieuwe doelen beschikbaar ($delta kcal).';
  }

  @override
  String get recommendationBannerApply => 'Toepassen';

  @override
  String get cancelingAndRollingBack =>
      'Bezig met annuleren en veilig terugdraaien…';

  @override
  String get sleepSyncTitle => 'Slaapgeschiedenis synchroniseren…';

  @override
  String get backupExportTitle => 'Back-up exporteren…';

  @override
  String get backupImportTitle => 'Back-up importeren…';

  @override
  String progressImportingNight(int index, int total) {
    return 'Nacht $index/$total importeren…';
  }

  @override
  String progressExportingTable(String table) {
    return '$table exporteren…';
  }

  @override
  String progressImportingTable(String table) {
    return '$table herstellen…';
  }

  @override
  String get shareDailyLogTitle => 'Dagboekoverzicht';

  @override
  String get shareSleepStartTime => 'Starttijd';

  @override
  String get shareSleepEndTime => 'Eindtijd';

  @override
  String get shareSleepDeep => 'Diepe slaap';

  @override
  String get shareSleepLight => 'Lichte slaap';

  @override
  String get shareSleepRem => 'REM-slaap';

  @override
  String get shareSleepAwake => 'Wakker/onderbrekingen';

  @override
  String get shareTotalWater => 'Totaal water en vocht';

  @override
  String get shareNutritionSummary => 'Totaaloverzicht voeding';

  @override
  String get shareSleepEfficiency => 'Efficiëntie';

  @override
  String get shareSleepRestingHeartRate => 'Rusthartslag';

  @override
  String get shareAsTextOrCopy => 'Delen/kopiëren als tekst';

  @override
  String get editExercise => 'Oefening bewerken';

  @override
  String exerciseCopyCreated(String exerciseName) {
    return 'Kopie van ‘$exerciseName’ gemaakt.';
  }

  @override
  String get copySystemExerciseTitle => 'Systeem-oefening kopiëren';

  @override
  String get copySystemExerciseBody =>
      'Deze oefening wordt door de app geleverd en kan niet rechtstreeks worden bewerkt. Wil je een eigen kopie maken om te bewerken?';

  @override
  String get createCopyAndEdit => 'Kopie maken en bewerken';

  @override
  String get profileEdit => 'Profiel bewerken';

  @override
  String get selectBirthday => 'Geboortedatum selecteren';

  @override
  String get exerciseNoteTitle => 'Oefeningsnotitie';

  @override
  String get exerciseNoteHint => 'Voeg notities of aanwijzingen toe…';

  @override
  String get editExerciseNotes => 'Notitie toevoegen/bewerken';

  @override
  String get workoutNoteAddHint => 'Voeg hier een notitie toe…';

  @override
  String get noteTypeTitle => 'Type notitie';

  @override
  String get pinnedExerciseNoteTitle => 'Vaste oefeningsnotitie';

  @override
  String get pinnedExerciseNoteDescription =>
      'Wordt telkens ingevuld wanneer je deze oefening registreert.';

  @override
  String get pinnedRoutineNoteTitle => 'Vaste routinenotitie';

  @override
  String get pinnedRoutineNoteDescription =>
      'Wordt alleen voor deze oefening in deze routine ingevuld.';

  @override
  String get workoutExerciseNoteTitle => 'Trainingsnotitie bij oefening';

  @override
  String get workoutExerciseNoteDescription =>
      'Geldt alleen voor deze oefening in deze training.';

  @override
  String get deleteNoteTooltip => 'Notitie verwijderen';

  @override
  String get emptyStateAddFirstExerciseSubtitle =>
      'Voeg een oefening toe om te beginnen met registreren.';

  @override
  String get syncRoutineTitle => 'Routine bijwerken?';

  @override
  String get syncRoutineSubtitle =>
      'Wijzigingen in structuur of volgorde gevonden.';

  @override
  String syncRoutineBody(String routineName) {
    return 'Wil je de routine ‘$routineName’ bijwerken met de huidige trainingsgegevens (oefeningen, volgorde en sets)?';
  }

  @override
  String get discard => 'Verwerpen';

  @override
  String get updateNow => 'Nu bijwerken';

  @override
  String get syncRoutineSuccess => 'Routine bijgewerkt.';

  @override
  String syncRoutineError(String error) {
    return 'Fout bij het bijwerken van de routine: $error';
  }

  @override
  String createRoutineError(String error) {
    return 'Fout bij het maken van de routine: $error';
  }

  @override
  String nutritionPerQuantity(String quantity) {
    return 'Voedingswaarden per $quantity g';
  }

  @override
  String get settingsLocalModelName => 'Naam lokaal model';

  @override
  String get settingsCustomBaseUrl => 'Aangepaste basis-URL';

  @override
  String get settingsCustomModelName => 'Naam aangepast model';

  @override
  String get settingsAiFoodNameLanguage => 'Taal voor AI-voedingsnamen';

  @override
  String get settingsRequestTimeout => 'Time-out voor verzoeken';

  @override
  String settingsSeconds(int seconds) {
    return '$seconds seconden';
  }

  @override
  String get semanticsApplyRecommendation => 'Advies toepassen';

  @override
  String get semanticsDismissBanner => 'Melding sluiten';

  @override
  String get importedWorkout => 'Geïmporteerde training';

  @override
  String get unknownExercise => 'Onbekende oefening';

  @override
  String get devExportBaseDb => 'Basisdatabase exporteren';

  @override
  String get initCheckingExercises => 'Oefeningen controleren…';

  @override
  String get initLoadingRemoteManifest => 'Manifest op afstand laden…';

  @override
  String get initExercisesUpToDate => 'Oefeningen zijn bijgewerkt';

  @override
  String get initNoDownloadRequired => 'Downloaden op afstand is niet nodig.';

  @override
  String get initLoadingExercises => 'Oefeningen laden…';

  @override
  String initDownloadingRemoteCatalog(String version) {
    return 'Catalogus met oefeningen op afstand downloaden $version…';
  }

  @override
  String get initPreparingImport => 'Download voorbereiden voor import…';

  @override
  String get initExercisesReady => 'Oefeningen zijn klaar';

  @override
  String initImportingRemoteCatalog(String version) {
    return 'Catalogus met oefeningen op afstand importeren $version…';
  }

  @override
  String initCheckingProductDatabase(String country) {
    return 'Productendatabase controleren ($country)…';
  }

  @override
  String get initProductDatabaseUpToDate => 'Productendatabase is bijgewerkt';

  @override
  String get initLoadingProductDatabase => 'Productendatabase laden…';

  @override
  String initDownloadingProductBundle(String version) {
    return 'Productenpakket op afstand downloaden $version…';
  }

  @override
  String get initProductDatabaseReady => 'Productendatabase is klaar';

  @override
  String initImportingProductBundle(String version) {
    return 'Productenpakket $version importeren…';
  }

  @override
  String get initNoOffBundle =>
      'Geen Open Food Facts-pakket of externe bron beschikbaar. Bestaande lokale Open Food Facts-gegevens blijven ongewijzigd.';

  @override
  String initEntriesProgress(String processed, String totalCount) {
    return '$processed / $totalCount items';
  }

  @override
  String initUpdateTask(String task) {
    return '$task bijwerken';
  }

  @override
  String initCheckingTask(String task) {
    return '$task controleren…';
  }

  @override
  String initTaskUpToDate(String task) {
    return '$task is bijgewerkt';
  }

  @override
  String get initInitializing => 'Initialiseren…';

  @override
  String get initPreparation => 'Voorbereiden…';

  @override
  String get initReady => 'Gereed';

  @override
  String yearsOld(int age) {
    return '$age jaar';
  }

  @override
  String get customFoodsTitle => 'Eigen voedingsmiddelen';

  @override
  String get deleteFoodConfirmTitle => 'Voedingsmiddel verwijderen';

  @override
  String get deleteFoodConfirmBody =>
      'Weet je zeker dat je dit eigen voedingsmiddel wilt verwijderen? Eerdere registraties blijven behouden.';

  @override
  String get foodItemDeleted => 'Voedingsmiddel verwijderd';

  @override
  String get copySystemFoodTitle => 'Systeemvoedingsmiddel kopiëren';

  @override
  String get copySystemFoodBody =>
      'Systeemvoedingsmiddelen kun je niet rechtstreeks bewerken. Wil je een eigen kopie maken en bewerken?';

  @override
  String foodCopyCreated(String name) {
    return 'Kopie gemaakt: $name';
  }

  @override
  String get nutritionPer100g => 'Voedingswaarde per 100 g';

  @override
  String nutritionPerPortion(int grams) {
    return 'Voedingswaarde per portie ($grams g)';
  }

  @override
  String get workoutConflictTitle => 'Training bezig';

  @override
  String get workoutConflictContent =>
      'Je hebt al een actieve trainingssessie. Wil je deze hervatten of verwijderen om een nieuwe te starten?';

  @override
  String get resumeWorkoutButton => 'Training hervatten';

  @override
  String get discardAndStartButton => 'Verwijderen en nieuw starten';

  @override
  String get profileTapToSetUp => 'Tik om in te stellen';

  @override
  String get customLabel => 'Aangepast';

  @override
  String get noData => 'Geen gegevens';

  @override
  String get languageAuto => 'Automatisch';

  @override
  String aiValidationCostEstimation(num tokenCount) {
    return 'Kosten: ~$tokenCount tokens';
  }

  @override
  String showAllWithCount(num count) {
    return 'Alles tonen ($count)';
  }

  @override
  String repsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count herhalingen',
      one: '1 herhaling',
    );
    return '$_temp0';
  }

  @override
  String get offDownloadTitle => 'Databankcatalogi downloaden';

  @override
  String get offDownloadBody =>
      'Download de lokale catalogi om offline basisvoedingsmiddelen te gebruiken, verpakte producten te zoeken, barcodes te scannen, oefeningen op te zoeken en maaltijden met AI te koppelen. De BLS 4.0-ingrediëntencatalogus is ongeveer 25,6 MB; de catalogi voor voedingsmiddelen en oefeningen worden apart gedownload.';

  @override
  String get offDownloadConfirm => 'Nu downloaden';

  @override
  String get offDownloadCancel => 'Niet nu';

  @override
  String get offDownloadCTA => 'Databank downloaden';

  @override
  String get offPlaceholderText =>
      'Voor voedingsfuncties is de lokale databankcatalogus nodig.';

  @override
  String get backupImportLockedTitle => 'Databankcatalogus vereist';

  @override
  String get backupImportLockedBody =>
      'Download en initialiseer vóór het importeren van een back-up eerst de volledige catalogi voor oefeningen en voeding om gegevensinconsistentie te voorkomen. Download eerst de vereiste databanken.';

  @override
  String get wgerPlaceholderText =>
      'Voor functies in de oefeningencatalogus is de lokale databank nodig.';

  @override
  String get onboardingRegionTitle => 'Selecteer regio';

  @override
  String get onboardingRegionExplanation =>
      'Selecteer het land waar je boodschappen doet. Zo downloaden we de juiste Open Food Facts-databank voor producten uit jouw regio.';

  @override
  String get onboardingRegionSettingsHint =>
      'Je kunt dit later altijd wijzigen via Instellingen → Voeding → Databankregio.';

  @override
  String get clearSearch => 'Zoekopdracht wissen';

  @override
  String rollingDaysLabel(int days) {
    return 'Afgelopen $days dagen (voortschrijdend)';
  }

  @override
  String get muscleTraps => 'Trapezius';

  @override
  String get muscleObliques => 'Schuine buikspieren';

  @override
  String get icloudSyncErrorTitle => 'iCloud-synchronisatie mislukt';

  @override
  String get icloudSyncErrorHelp =>
      'Controleer of iCloud Drive is ingeschakeld via de iOS-systeeminstellingen: Instellingen -> [Je naam] -> iCloud -> iCloud Drive.';

  @override
  String get icloudSyncErrorCopyLog => 'Technisch foutenlogboek kopiëren';

  @override
  String get icloudSyncErrorClose => 'Sluiten';

  @override
  String get icloudSyncErrorCopied => 'Foutenlogboek gekopieerd naar klembord!';

  @override
  String icloudLastSynced(String date) {
    return 'Laatst gesynchroniseerd: $date';
  }

  @override
  String get icloudNeverSynced => 'Nooit gesynchroniseerd';

  @override
  String get emptyStateDiaryColdStartTitle => 'Welkom bij je dagboek!';

  @override
  String get emptyStateDiaryColdStartSubtitle =>
      'Houd hier je voeding en vochtinname bij.';

  @override
  String get emptyStateActiveGapOverlay =>
      'Geen gegevens beschikbaar voor deze periode';

  @override
  String get emptyStateDiaryColdStartCallToAction =>
      'Registreer hier je eerste invoer';

  @override
  String get statisticsColdStartTitle => 'Welkom bij je analyses!';

  @override
  String get statisticsColdStartSubtitle =>
      'Je voortgang verschijnt hier zodra je je eerste trainingen en maaltijden registreert of je stappen en slaap bijhoudt.';

  @override
  String get statisticsActiveGapTitle => 'Geen gegevens beschikbaar';

  @override
  String get reviewPromptTitle => 'Vind je Train Libre fijn?';

  @override
  String get reviewPromptSubtitle =>
      'Met je feedback kunnen we de app blijven verbeteren, zonder advertenties of trackers.';

  @override
  String get reviewPromptYes => 'Ja, ik vind het fijn';

  @override
  String get reviewPromptNo => 'Niet echt';

  @override
  String get reviewPromptLater => 'Herinner me later';

  @override
  String get updateAvailableTitle => 'Update beschikbaar';

  @override
  String get statusReady => 'Gereed';

  @override
  String get statusRequired => 'Vereist';

  @override
  String get updatesAvailableBody =>
      'Er zijn updates beschikbaar voor je lokale catalogi. Wil je deze nu bijwerken?';

  @override
  String get exerciseCatalogWger => 'Oefeningencatalogus (OpenExerciseDB)';

  @override
  String get nutritionCatalogOff => 'Voedingscatalogus (OFF)';

  @override
  String get workoutImportZeroNew =>
      '0 nieuwe trainingen geïmporteerd (ze bestonden allemaal al).';

  @override
  String get telemetryDeleteDialogTitle => 'Telemetriegegevens verwijderen?';

  @override
  String get telemetryDeleteDialogBody =>
      'Weet je zeker dat je eerdere telemetriegegevens wilt verwijderen?\n\nDit gebeurt er dan:\n• Alle apparaat-UUID’s, sessie-ID’s en lokale tellers op dit apparaat worden gereset.\n• Er wordt een verwijderverzoek (\$delete_person) naar de PostHog-servers in de EU gestuurd om je gegevens daar te wissen.\n• De telemetrie-SDK wordt volledig gereset.';

  @override
  String get telemetryDeleteConfirmButton => 'Gegevens nu verwijderen';

  @override
  String get telemetryConsentTitle => 'Help je Train Libre verbeteren?';

  @override
  String get telemetryConsentBody =>
      'Train Libre wordt zelfstandig ontwikkeld door één ontwikkelaar, zonder accounts en advertenties. Je kunt desgewenst gepseudonimiseerde gebruiksstatistieken delen. Zo zie ik welke functies worden gebruikt en wat er aan de app kan worden verbeterd.';

  @override
  String get telemetryConsentPointAnonymous =>
      'Gepseudonimiseerd: geen naam, e-mailadres, training, dagboek-, gewichts-, voedings- of gezondheidsgegevens. Alleen schermweergaven, functiegebruik en foutrapporten worden verzonden.';

  @override
  String get telemetryConsentPointNotSold =>
      'Niet voor advertenties: gegevens worden nooit verkocht of gebruikt voor marketing of reclame. Ze worden verwerkt op servers in de EU.';

  @override
  String get telemetryConsentPointRevocable =>
      'Vrijwillig: je kunt dit op elk moment uitschakelen in Instellingen. Daar kun je opgeslagen telemetriegegevens ook verwijderen.';

  @override
  String get telemetryConsentAccept => 'Ja, gebruiksgegevens delen';

  @override
  String get telemetryConsentDecline => 'Nee, bedankt';

  @override
  String get settingsTelemetryToggleTitle =>
      'Gepseudonimiseerde gebruiksstatistieken delen';

  @override
  String get settingsTelemetryToggleSubtitle =>
      'Helpt de app verbeteren. Gepseudonimiseerd, zonder persoonlijke of gezondheidsgegevens.';

  @override
  String get settingsTelemetryDeleteTitle => 'Telemetriegegevens verwijderen';

  @override
  String get settingsTelemetryDeleteSubtitle =>
      'Verwijdert alle lokaal opgeslagen ID’s en ID’s op de PostHog-server';

  @override
  String liveActivitySetPosition(int index, int total) {
    return 'Set $index van $total';
  }

  @override
  String get liveActivityOverdueLabel => 'over tijd met';

  @override
  String get liveActivityRirLabel => 'RIR';

  @override
  String get liveActivityRpeLabel => 'RPE';

  @override
  String get liveActivityAddExercise => 'Oefening toevoegen';

  @override
  String get liveActivityOpenApp => 'App openen';

  @override
  String get unit_pounds => 'lbs';

  @override
  String get unit_kilometers => 'km';

  @override
  String get unit_miles => 'mi';

  @override
  String get liveActivitySkipShort => 'Overslaan';

  @override
  String get whatsNewTitle => 'Nieuw in deze versie';

  @override
  String get whatsNewSubtitle => 'Dit is er veranderd sinds je laatste update.';

  @override
  String whatsNewVersionHeader(String version) {
    return 'Versie $version';
  }

  @override
  String get whatsNewCta => 'Aan de slag';

  @override
  String get whatsNewAboutRow => 'Nieuw';

  @override
  String get whatsNewAboutRowSubtitle =>
      'Belangrijke wijzigingen in deze en eerdere versies';

  @override
  String get mealAnalysisPreparing => 'Opname voorbereiden';

  @override
  String get mealAnalysisAnalyzing => 'Maaltijd analyseren';

  @override
  String get mealAnalysisMatching => 'Ingrediënten koppelen';

  @override
  String get mealAnalysisRepairing => 'Resultaat verfijnen';

  @override
  String get mealAnalysisFailed => 'Dat is niet gelukt';

  @override
  String get mealAnalysisProcessingTag => 'AI-BEELDVERWERKING';

  @override
  String get aiScannerTitle => 'AI-scanner';

  @override
  String get aiCaptureAnalyzing => 'Analyseren…';

  @override
  String aiCaptureAnalyzeMeal(int count) {
    return 'Maaltijd analyseren ($count)';
  }

  @override
  String get aiCaptureAnalyzeText => 'Tekst analyseren';

  @override
  String get aiCaptureDescribeHint =>
      'Beschrijf de maaltijd (bijv. 2 eieren met toast)…';

  @override
  String get aiCaptureBarcodeDetected => 'Barcode gedetecteerd';

  @override
  String get aiCaptureLogBarcode => 'Registreren';

  @override
  String aiCaptureBarcodeFallback(String code) {
    return 'Barcode $code';
  }

  @override
  String get aiCaptureMoveCloser => 'Houd de camera iets dichterbij';

  @override
  String get aiCaptureMoveAway => 'Houd de camera iets verder weg';

  @override
  String get aiCaptureOpenSettings => 'Instellingen openen';

  @override
  String get voiceDictationTitle => 'Maaltijd inspreken';

  @override
  String get voiceHoldToTalk => 'Houd ingedrukt om te spreken';

  @override
  String get voiceSpeakNow => 'Spreek nu — laat los om te voltooien';

  @override
  String get voiceExampleStandalone =>
      'bijv. ‘Een groentekebab met platbrood en knoflooksaus’';

  @override
  String get voiceExampleWithPhoto =>
      'Voeg toe wat de foto niet laat zien, bijvoorbeeld: ‘gebakken in twee eetlepels olijfolie’';

  @override
  String get voiceNetworkNotice =>
      'Dit apparaat kan spraak niet lokaal herkennen. De opname wordt naar de spraakherkenning van het systeem gestuurd om te worden uitgeschreven.';

  @override
  String get voiceTapToRecord => 'Tik om de opname te starten';

  @override
  String get voiceTapToFinish => 'Luisteren — tik om te voltooien';

  @override
  String get aiChatAddImage => 'Afbeelding toevoegen';

  @override
  String get aiChatTakePhoto => 'Foto maken';

  @override
  String get aiChatChoosePhoto => 'Kiezen uit bibliotheek';

  @override
  String get aiChatRemoveImage => 'Afbeelding verwijderen';

  @override
  String get aiChatCameraUnavailable =>
      'De camera is niet beschikbaar op dit apparaat.';

  @override
  String get aiChatCameraPermission =>
      'Geef toegang tot de camera om een foto te maken.';

  @override
  String get aiChatCapture => 'Foto maken';

  @override
  String get aiChatCameraOptions => 'Cameraopties';

  @override
  String get aiChatFlash => 'Flits';

  @override
  String get aiChatSwitchCamera => 'Camera wisselen';

  @override
  String get aiChatImageLimit => 'Je kunt maximaal 4 afbeeldingen toevoegen.';

  @override
  String get aiChatImageQuestion =>
      'Als deze afbeelding eten of drinken toont, schat dan de voedingswaarden en maak een dagboekinvoer die ik kan controleren. Beschrijf anders kort wat erop staat.';

  @override
  String get aiChatImageUnsupported =>
      'Het geselecteerde AI-model ondersteunt geen afbeeldingen. Je concept blijft in het invoerveld staan.';

  @override
  String get voiceStarting => 'Voorbereiden…';

  @override
  String get voiceTidyingUp => 'Je woorden ordenen…';

  @override
  String get voiceNothingHeard =>
      'Er is niets herkend. Probeer het opnieuw of typ het in.';

  @override
  String get voiceLanguage => 'Taal';

  @override
  String get voiceLanguageTitle => 'Taal voor dicteren';

  @override
  String get voiceLanguageSystem => 'Apparaattaal volgen';

  @override
  String get voiceLanguageHint =>
      'Kies de taal waarin je spreekt, niet de taal van de app.';

  @override
  String get voiceCleanedNotice => 'Stopwoorden verwijderd';

  @override
  String get voiceRetake => 'Opnieuw opnemen';

  @override
  String voiceTidiedIn(String seconds) {
    return 'Door AI opgeschoond in $seconds s';
  }

  @override
  String get aiDepthImageTitle => 'Ook de dieptekaart versturen';

  @override
  String get aiDepthImageSubtitle =>
      'Voegt als tweede afbeelding een reliëf in valse kleuren van de maaltijd toe, zodat het model naast de omtrek ook de hoogte kan inschatten. Kost één extra afbeelding per analyse.';

  @override
  String get aiVoiceTidyTitle => 'Dicteren opschonen met AI';

  @override
  String get aiVoiceTidySubtitle =>
      'Na het spreken wordt de transcriptie gecorrigeerd en in opsommingstekens verdeeld. Kost één verzoek en een paar seconden.';

  @override
  String get voicePermissionTitle => 'Microfoon en spraakherkenning';

  @override
  String get voicePermissionBody =>
      'Om een maaltijd in te spreken heeft Train Libre de microfoon nodig zolang je de knop ingedrukt houdt, en spraakherkenning om je woorden om te zetten naar tekst. Waar mogelijk gebeurt de herkenning op je apparaat. Er wordt niets opgenomen of bewaard.';

  @override
  String get voicePermissionContinue => 'Doorgaan';

  @override
  String get voiceApplyText => 'Deze tekst gebruiken';

  @override
  String get voiceTranscriptHint => 'Herkenningstekst — hier te bewerken';

  @override
  String get voiceUnavailablePermission =>
      'Dicteren vereist toegang tot de microfoon en spraakherkenning. Je kunt de tekst ook typen.';

  @override
  String get voiceUnavailableUnsupported =>
      'Dit apparaat ondersteunt geen spraakherkenning. Je kunt de tekst typen.';

  @override
  String get voiceUnavailableFailed =>
      'Spraakherkenning kon niet worden gestart. Je kunt de tekst typen.';

  @override
  String get mealFallbackTitle => 'Maaltijd';

  @override
  String mealIngredientCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingrediënten',
      one: '1 ingrediënt',
    );
    return '$_temp0';
  }

  @override
  String get mealDetailOptions => 'Opties';

  @override
  String get mealDetailViewMode => 'Weergave';

  @override
  String get mealDetailAddIngredient => 'Ingrediënt toevoegen';

  @override
  String get mealDetailSaveAsTemplate => 'Opslaan als sjabloon';

  @override
  String get mealDetailSavedAsTemplate => 'Opgeslagen als maaltijdsjabloon.';

  @override
  String get mealDetailChangeMealType => 'Maaltijdtype wijzigen';

  @override
  String get mealDetailSelectMealType => 'Maaltijdtype kiezen';

  @override
  String get mealDetailAmountInGrams => 'Hoeveelheid in gram';

  @override
  String get mealDetailApply => 'Toepassen';

  @override
  String get mealDeleteQuestion => 'Wat wil je met deze maaltijd doen?';

  @override
  String get mealDeleteUngroupTitle => 'Alleen de groepering verwijderen';

  @override
  String mealDeleteUngroupBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'De foto en groepering worden verwijderd. De $count invoeren blijven apart in je dagboek staan; je dagtotaal verandert niet.',
      one:
          'De foto en groepering worden verwijderd. De invoer blijft apart in je dagboek staan; je dagtotaal verandert niet.',
    );
    return '$_temp0';
  }

  @override
  String get mealDeleteAllTitle => 'Maaltijd en invoeren verwijderen';

  @override
  String mealDeleteAllBody(int count, int kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'De foto, groepering en alle $count invoeren verdwijnen uit je dagboek. Er wordt $kcal kcal van je dagtotaal afgehaald.',
      one:
          'De foto, groepering en invoer verdwijnen uit je dagboek. Er wordt $kcal kcal van je dagtotaal afgehaald.',
    );
    return '$_temp0';
  }

  @override
  String get reanalysisTitle => 'Nieuw resultaat';

  @override
  String get reanalysisSubtitle => 'Jij bepaalt wat bewaard blijft.';

  @override
  String get reanalysisPrevious => 'HUIDIG';

  @override
  String get reanalysisNew => 'NIEUW';

  @override
  String get reanalysisKeepPrevious => 'Huidige behouden';

  @override
  String get reanalysisApplyNew => 'Nieuwe gebruiken';

  @override
  String get reanalysisDiffHint =>
      'Gemarkeerd = wijkt af van wat is opgeslagen';

  @override
  String get aiReviewDiscardTitle => 'Deze maaltijd weggooien?';

  @override
  String get aiReviewDiscardBody =>
      'De analyse is niet opgeslagen en gaat verloren.';

  @override
  String get aiLidarScaleTitle => 'LiDAR-schaal meesturen';

  @override
  String get aiLidarScaleSubtitle =>
      'Meet de afstand en beeldgrootte in centimeters en stuurt die naar de AI. Schakel dit uit om te vergelijken of de schatting er echt beter van wordt.';

  @override
  String get mealPhotoStorageSection => 'Maaltijdfoto’s (opslag)';

  @override
  String get mealPhotoRetentionTitle => 'Bewaartermijn';

  @override
  String get mealPhotoRetentionBody =>
      'Foto’s worden automatisch verwijderd zodra de termijn is verstreken. De voedingsregistraties in je dagboek blijven staan.';

  @override
  String mealPhotoRetentionDays(int days) {
    return '$days dagen';
  }

  @override
  String get mealPhotoRetentionDefaultSuffix => '(standaard)';

  @override
  String get mealPhotoRetentionUnlimited => 'Onbeperkt';

  @override
  String get mealPhotoRetentionSaved => 'Bewaartermijn opgeslagen.';

  @override
  String get mealPhotoDeleteAll => 'Alle lokale foto’s verwijderen';

  @override
  String get mealPhotoDeleteAllTitle => 'Alle maaltijdfoto’s verwijderen?';

  @override
  String get mealPhotoDeleteAllBody =>
      'Alleen de afbeeldingsbestanden worden van het apparaat verwijderd. Je dagboekinvoer en calorieën blijven ongewijzigd.';

  @override
  String get mealPhotoDeleted => 'Foto’s verwijderd.';

  @override
  String get speechSectionTitle => 'Spraakinvoer en dicteren';

  @override
  String get speechOnDeviceActive => 'Spraakherkenning op het apparaat actief';

  @override
  String get speechOnDeviceBody =>
      'Ingesproken maaltijden (“2 eieren met toast en koffie”) worden rechtstreeks op je apparaat omgezet in tekst en blijven privé.';

  @override
  String get aiCaptureTourStepShutterTitle => 'Maak foto’s van je maaltijd';

  @override
  String get aiCaptureTourStepShutterDesc =>
      'Maak met de sluiter maximaal 4 foto’s van je maaltijd vanuit verschillende hoeken. Op ondersteunde apparaten legt LiDAR automatisch dieptegegevens vast voor nauwkeurigere portieschattingen.';

  @override
  String get aiCaptureTourStepBarcodeTitle => 'Barcodes automatisch herkennen';

  @override
  String get aiCaptureTourStepBarcodeDesc =>
      'Houd verpakte producten voor de camera; barcodes worden automatisch in realtime herkend. Met deze knop zet je de live scanner aan of uit.';

  @override
  String get aiCaptureTourBarcodeDemoProduct =>
      'Biologische havervlokken 500 g';

  @override
  String get aiCaptureTourBarcodeDemoHint =>
      'Zo ziet het scannen van een barcode eruit!';

  @override
  String get aiCaptureTourStepGalleryTitle => 'Kies uit je bibliotheek';

  @override
  String get aiCaptureTourStepGalleryDesc =>
      'Heb je al foto’s van je maaltijd gemaakt? Kies maximaal 4 afbeeldingen rechtstreeks uit je fotobibliotheek.';

  @override
  String get aiCaptureTourStepVoiceTitle => 'Dicteren met je stem';

  @override
  String get aiCaptureTourStepVoiceDesc =>
      'Tik op de microfoon om ingrediënten, merken of hoeveelheden in te spreken (bijv. “200 g kipfilet met rijst”). AI ordent en analyseert je spraak automatisch.';

  @override
  String get aiCaptureTourStepTextTitle => 'Tekst en notities';

  @override
  String get aiCaptureTourStepTextDesc =>
      'Voeg geschreven notities toe of beschrijf je maaltijd alleen met tekst als je geen foto wilt maken.';

  @override
  String get aiCaptureTourStepAnalyzeTitle => 'Slimme AI-analyse';

  @override
  String get aiCaptureTourStepAnalyzeDesc =>
      'Zodra een foto, spraaktranscript of tekst klaarstaat, tik je op Analyseren. De AI herkent voedingsmiddelen, schat porties en vergelijkt alles met je voedingsdoelen.';

  @override
  String get aiCaptureTourReplayTooltip =>
      'Uitleg over vastleggen opnieuw bekijken';

  @override
  String get workoutPhotoAdd => 'Foto toevoegen';

  @override
  String get workoutPhotoTake => 'Foto maken';

  @override
  String get workoutPhotoFromLibrary => 'Kiezen uit bibliotheek';

  @override
  String get workoutPhotoRemove => 'Foto verwijderen';

  @override
  String get workoutPhotoRemoveConfirm =>
      'Weet je zeker dat je deze foto wilt verwijderen?';

  @override
  String get workoutPhotoLimitReached => 'Maximum van 4 foto’s bereikt';

  @override
  String workoutPhotoPagination(int current, int total) {
    return '$current van $total';
  }

  @override
  String get catalogFilterTitle => 'Filteren';

  @override
  String get catalogFilterBodyRegion => 'Lichaamsregio';

  @override
  String get catalogFilterEquipment => 'Materiaal';

  @override
  String get catalogFilterUsage => 'Doel';

  @override
  String get catalogFilterReset => 'Wissen';

  @override
  String get catalogFilterCombineHint =>
      'Meerdere keuzes binnen één onderdeel verruimen de resultaten; keuzes in verschillende onderdelen beperken ze.';

  @override
  String get catalogFilterDifficulty => 'Moeilijkheid';

  @override
  String get catalogFilterMechanic => 'Mechaniek';

  @override
  String get catalogFilterLaterality => 'Zijden';

  @override
  String get catalogFilterAlreadyDone => 'Eerder uitgevoerd';

  @override
  String get catalogTrainedBadge => 'Getraind';

  @override
  String get catalogLastTrainedToday => 'Vandaag getraind';

  @override
  String get catalogLastTrainedYesterday => 'Gisteren getraind';

  @override
  String catalogLastTrainedDaysAgo(int days) {
    return '$days d geleden';
  }

  @override
  String catalogLastTrainedOn(String date) {
    return 'Getraind op $date';
  }

  @override
  String get noTrainedExercisesFound =>
      'Geen eerder uitgevoerde oefeningen gevonden.';

  @override
  String get exerciseDifficultyBeginner => 'Beginner';

  @override
  String get exerciseDifficultyIntermediate => 'Gemiddeld';

  @override
  String get exerciseDifficultyAdvanced => 'Gevorderd';

  @override
  String get exerciseMechanicCompound => 'Samengesteld';

  @override
  String get exerciseMechanicIsolation => 'Isolatie';

  @override
  String get exerciseLateralityBilateral => 'Beide zijden';

  @override
  String get exerciseLateralityUnilateral => 'Eén zijde';

  @override
  String get exerciseLateralityAlternating => 'Afwisselend';

  @override
  String get exerciseClassificationTitle => 'Classificatie';

  @override
  String get exerciseMovementPatternLabel => 'Bewegingspatroon';

  @override
  String get exerciseForceVectorLabel => 'Krachtrichting';

  @override
  String get exerciseMechanicLabel => 'Oefeningstype';

  @override
  String get exerciseLateralityLabel => 'Lateraal';

  @override
  String get exerciseDifficultyLabel => 'Moeilijkheid';

  @override
  String get exerciseClassificationNotSpecified => 'Niet opgegeven';

  @override
  String get exercisePatternOther => 'Overig';

  @override
  String get exerciseUsageWarmup => 'Warming-up';

  @override
  String get exerciseUsageActivation => 'Activatie';

  @override
  String get exerciseUsageMainLift => 'Hoofdoefening';

  @override
  String get exerciseUsageAccessory => 'Hulpoefening';

  @override
  String get exerciseUsageConditioning => 'Conditietraining';

  @override
  String get exerciseUsageFinisher => 'Afmaker';

  @override
  String get exerciseUsageCooldown => 'Cooling-down';

  @override
  String get exerciseUsagePrehab => 'Prehab';

  @override
  String get exerciseForcePush => 'Duwen';

  @override
  String get exerciseForcePull => 'Trekken';

  @override
  String get exerciseForceStatic => 'Statisch';

  @override
  String get exercisePatternHorizontalPush => 'Horizontaal duwen';

  @override
  String get exercisePatternHorizontalPull => 'Horizontaal trekken';

  @override
  String get exercisePatternVerticalPush => 'Verticaal duwen';

  @override
  String get exercisePatternVerticalPull => 'Verticaal trekken';

  @override
  String get exercisePatternSquat => 'Squat';

  @override
  String get exercisePatternHinge => 'Heupscharnier';

  @override
  String get exercisePatternLunge => 'Uitvalspas';

  @override
  String get exercisePatternGait => 'Gangpatroon';

  @override
  String get exercisePatternCarry => 'Dragen';

  @override
  String get exercisePatternRotation => 'Rotatie';

  @override
  String get exercisePatternAntiRotation => 'Anti-rotatie';

  @override
  String get exercisePatternAntiExtension => 'Anti-extensie';

  @override
  String get exercisePatternAntiFlexion => 'Anti-flexie';

  @override
  String get exercisePatternAntiLateralFlexion => 'Anti-zijwaartse flexie';

  @override
  String get exercisePatternSpinalFlexion => 'Wervelkolomflexie';

  @override
  String get exercisePatternSpinalExtension => 'Wervelkolomstrekking';

  @override
  String get exercisePatternElbowFlexion => 'Elleboogflexie';

  @override
  String get exercisePatternElbowExtension => 'Elleboogstrekking';

  @override
  String get exercisePatternShoulderFlexion => 'Schouderflexie';

  @override
  String get exercisePatternShoulderAbduction => 'Schouderabductie';

  @override
  String get exercisePatternScapularElevation => 'Schouderbladheffing';

  @override
  String get exercisePatternHipExtension => 'Heupextensie';

  @override
  String get exercisePatternHipAbduction => 'Heupabductie';

  @override
  String get exercisePatternHipAdduction => 'Heupadductie';

  @override
  String get exercisePatternKneeFlexion => 'Knieflexie';

  @override
  String get exercisePatternKneeExtension => 'Kniestrekking';

  @override
  String get exercisePatternPlantarFlexion => 'Plantairflexie';

  @override
  String get exercisePatternDorsiflexion => 'Dorsaalflexie';

  @override
  String get exercisePatternWristFlexion => 'Polsflexie';

  @override
  String get exercisePatternWristExtension => 'Polsstrekking';

  @override
  String get settingsDeveloperTitle => 'Ontwikkelaar';

  @override
  String get settingsDeveloperSubtitle => 'Diagnostiek en experimentele opties';

  @override
  String get developerLabExperienceSection => 'Ervaringsniveau';

  @override
  String get developerLabExperienceLabel => 'Ervaringsniveau';

  @override
  String get developerLabExperienceHint =>
      'Alleen voor tests; tijdens de eerste installatie wordt nog niet naar je niveau gevraagd.';

  @override
  String get experienceLevelBeginner => 'Beginner';

  @override
  String get experienceLevelAdvanced => 'Gevorderd';

  @override
  String get experienceLevelPro => 'Pro';

  @override
  String get experienceLevelBeginnerDescription =>
      'Geschikt als je net begint: gericht op de basis, met gewicht en herhalingen. Gebruikt eenvoudige dagelijkse spiernamen zoals “schouders”.';

  @override
  String get experienceLevelAdvancedDescription =>
      'Voor regelmatige sportschoolgangers: gedetailleerde anatomische spierindeling in de catalogus en trainingen (bijv. voorste, middelste en achterste deltaspier).';

  @override
  String get experienceLevelProDescription =>
      'Alleen aanbevolen voor ervaren krachtsporters die goed kunnen inschatten wanneer ze niet meer kunnen: voegt intensiteitsregistratie met RIR (herhalingen in reserve) en cardio-intensiteitszones toe.';

  @override
  String get diaryWeightLabel => 'Gewicht';

  @override
  String get diaryWeightPitch =>
      'Met een geschiedenis van gewichtsmetingen wordt je caloriedoel nauwkeuriger.';

  @override
  String get diaryWeightStaleNudge =>
      'Het is alweer even geleden. Regelmatige registraties houden je caloriedoel nauwkeurig.';

  @override
  String get diaryWeightLog => 'Registreren';

  @override
  String get diaryWeightLogLong => 'Gewicht registreren';

  @override
  String diaryWeightDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen geleden',
      one: '1 dag geleden',
    );
    return '$_temp0';
  }

  @override
  String get diaryWeightToday => 'vandaag';

  @override
  String get diaryWeightRange => 'Buiten het gebruikelijke bereik';

  @override
  String get diaryWeightLoadError => 'Gewicht kon niet worden geladen.';

  @override
  String get diaryWeightSaveError =>
      'Gewicht kon niet worden opgeslagen. Probeer het opnieuw.';

  @override
  String get diaryWeightRetry => 'Opnieuw proberen';

  @override
  String get settingsTrainingExperienceTitle => 'Trainingservaring';

  @override
  String get settingsTrainingExperienceSubtitle =>
      'Detailniveau van spierbenamingen en intensiteitskolommen';

  @override
  String get settingsTrainingProgressionTitle => 'Trainingsprogressie';

  @override
  String get settingsTrainingProgressionSubtitle =>
      'Gewichtssuggesties op basis van je geschiedenis';

  @override
  String get progressionPromptTitle => 'Progressie-engine inschakelen?';

  @override
  String get progressionPromptDescription =>
      'Train Libre heeft eerdere trainingsgegevens gevonden. De progressie-engine kan automatisch het ideale gewicht voor je volgende set voorstellen en je progressie stapsgewijs aanpassen.';

  @override
  String get progressionPromptFeatureSmartWeights =>
      'Automatische gewichtssuggesties op basis van je recente sets';

  @override
  String get progressionPromptFeatureStayInControl =>
      'Je houdt altijd de controle en kunt elke waarde op elk moment aanpassen';

  @override
  String get progressionPromptEnableAction => 'Suggesties inschakelen';

  @override
  String get progressionPromptDismissAction => 'Niet nu';

  @override
  String get trainingProgressionOff => 'Uit';

  @override
  String get trainingProgressionSuggest => 'Suggestie';

  @override
  String get progressionTogether => 'Sets gezamenlijk opbouwen';

  @override
  String get progressionIndividually => 'Sets afzonderlijk opbouwen';

  @override
  String get progressionPolicy => 'Setprogressie';

  @override
  String get progressionToggleEnabled => 'Automatische progressie aan';

  @override
  String get progressionToggleDisabled => 'Automatische progressie uit';

  @override
  String get workoutKeyboardInsertHyphen => 'Minteken invoegen';

  @override
  String get workoutKeyboardNextField => 'Naar het volgende veld';

  @override
  String get workoutKeyboardClose => 'Toetsenbord sluiten';

  @override
  String get progressionSetOutcome => 'Set registreren als';

  @override
  String get progressionDetails => 'Progressie en materiaal';

  @override
  String get progressionLargeStep =>
      'De volgende beschikbare belasting is een grote stap. Probeer die pas na bevestiging, of behoud de huidige belasting.';

  @override
  String get progressionBridge =>
      'Optioneel tijdelijk doel: twee herhalingen boven de bovengrens van je bereik. Je ingestelde bereik blijft ongewijzigd. Als je dit doel haalt, wordt de echte belastingstap weer aangeboden.';

  @override
  String get progressionUnavailable =>
      'Er is geen volgende stap beschikbaar. Behoud de belasting, corrigeer de beschikbare belastingen voor microloading of kies een nieuwe uitgangswaarde.';

  @override
  String get progressionOvershoot =>
      'Deze registratie ligt minstens drie herhalingen boven de bovengrens. Bevestig de invoer en kies daarna de volgende beschikbare stap of stel expliciet een nieuwe uitgangswaarde in.';

  @override
  String get progressionStall =>
      'In drie vergelijkbare sessies bleef deze positie onder het bereik. Je kunt de voorgestelde lagere belasting kiezen, het plan behouden of het bereik aanpassen. Er verandert niets automatisch.';

  @override
  String get progressionBoundary =>
      'Nieuwe meeteenheid en uitgangswaarde. Bevestig de overgang voor deze oefening; ondersteuning, lichaamsgewicht en extra gewicht zijn aparte meetwaarden.';

  @override
  String get progressionAccept => 'Doel bevestigen';

  @override
  String get progressionDecline => 'Huidige belasting behouden';

  @override
  String get progressionDismiss => 'Beoordeling sluiten';

  @override
  String get progressionRecalibrate => 'Nieuwe uitgangswaarde kiezen';

  @override
  String get progressionConfirmLog =>
      'Registratie bevestigen en volgende stap bekijken';

  @override
  String get progressionLoads =>
      'Beschikbare belastingen (scheiden met puntkomma’s)';

  @override
  String get progressionEquipment => 'Materiaal (optioneel)';

  @override
  String get progressionContext => 'Context of tijdelijke reden (optioneel)';

  @override
  String get progressionCompleted => 'Normaal voltooid';

  @override
  String get progressionAbandoned => 'Voortijdig beëindigd';

  @override
  String get progressionPain => 'Gestopt vanwege pijn';

  @override
  String get progressionEquipmentInterrupted =>
      'Materiaal of opstelling zat in de weg';

  @override
  String get progressionPainGuidance =>
      'Stop deze set. Overweeg een passende beoordeling voordat je verdergaat; er wordt geen belasting aanbevolen.';

  @override
  String get progressionUserLadder => 'Je beschikbare belastingen';

  @override
  String get progressionEquipmentLadder =>
      'Belastingsstappen van het materiaal';

  @override
  String get progressionFallback => 'Alternatieve materiaalstap';

  @override
  String get progressionHold =>
      'Behoud de belasting; het aantal herhalingen volgt het bereik en de geschiedenis van deze positie.';

  @override
  String get progressionOrdinary =>
      'Bovengrens bereikt: gebruik de volgende beschikbare belasting en begin opnieuw bij het minimumaantal herhalingen van het bereik.';

  @override
  String get progressionAnchor =>
      'Gekoppelde posities behouden het verschil in belasting van vandaag ten opzichte van de vorige sessie.';

  @override
  String get progressionNewPosition =>
      'Nieuwe positie: voorlopige uitgangswaarde op basis van de voltooide werkset van vandaag, geen bewijs uit eerdere progressie.';

  @override
  String get progressionWithheld =>
      'Geen vergelijkbare gegevens voor een suggestie.';

  @override
  String get progressionOffered => 'Aangeboden';

  @override
  String get progressionAccepted => 'Geaccepteerd';

  @override
  String get progressionRejected => 'Afgewezen';

  @override
  String get progressionInvalidLoads =>
      'Voer niet-negatieve belastingen in; geef minstens één beschikbare waarde op.';

  @override
  String get progressionBodyweight => 'Lichaamsgewicht';

  @override
  String get progressionWeighted => 'Lichaamsgewicht met extra gewicht';

  @override
  String get progressionAssisted => 'Ondersteund';

  @override
  String get createGoalTitle => 'Nieuw doel instellen';

  @override
  String get goalConfirmCreateButton => 'Doel activeren';

  @override
  String get goalStep1Question => 'Wat wil je bereiken?';

  @override
  String get goalStep1Description =>
      'Kies een richting of beschrijf je mijlpaal in je eigen woorden.';

  @override
  String goalStepProgress(int current, int total) {
    return 'Stap $current van $total';
  }

  @override
  String get goalStartingPointAndTargetTitle => 'Je startpunt en bestemming';

  @override
  String get goalStartingPointAndTargetDescription =>
      'Bevestig waar je begint en kies een doel dat past bij de richting die je op wilt.';

  @override
  String get goalTargetDirectionLoseError =>
      'Kies voor gewichtsverlies een doel onder je startgewicht.';

  @override
  String get goalTargetDirectionGainError =>
      'Kies voor gewichtstoename een doel boven je startgewicht.';

  @override
  String get goalDriverSettingDescription =>
      'Train Libre gebruikt dit doel om je dagelijkse calorie- en macrodoelen aan te passen.';

  @override
  String get goalPresetLoseWeight => 'Afvallen';

  @override
  String get goalPresetLoseWeightDescription =>
      'Verminder lichaamsvet en streefgewicht op een beheerste manier.';

  @override
  String get goalPresetGainWeight => 'Aankomen';

  @override
  String get goalPresetGainWeightDescription =>
      'Bouw geleidelijk spiermassa en lichaamsgewicht op.';

  @override
  String get goalPresetMaintainWeight => 'Gewicht behouden';

  @override
  String get goalPresetMaintainWeightDescription =>
      'Houd je lichaamsgewicht binnen een evenwichtige bandbreedte.';

  @override
  String get goalPresetRecomposition => 'Lichaamssamenstelling verbeteren';

  @override
  String get goalPresetRecompositionDescription =>
      'Verlies vet en bouw tegelijkertijd spieren op.';

  @override
  String get goalPresetCustom => 'Aangepast doel';

  @override
  String get goalPresetCustomDescription =>
      'Beschrijf een vrije mijlpaal in je eigen woorden.';

  @override
  String get goalCustomTitleLabel => 'Naam van je doel';

  @override
  String get goalCustomTitleHint =>
      'Bijvoorbeeld: zomerklaar worden of trainen voor een halve marathon';

  @override
  String get goalStep2Question => 'Hoe wil je je voortgang meten?';

  @override
  String get goalStep2Description =>
      'Kies de belangrijkste meetwaarde om je doel te volgen.';

  @override
  String get goalMetricWeightTitle => 'Lichaamsgewicht';

  @override
  String get goalMetricWeightSubtitle =>
      'Volg je gewicht in kg of lb met regelmatige metingen.';

  @override
  String get goalMetricBodyFatTitle => 'Vetpercentage';

  @override
  String get goalMetricBodyFatSubtitle =>
      'Volg je vetpercentage in de loop van de tijd.';

  @override
  String get goalMetricCircumferenceTitle => 'Lichaamsmeting / omtrek';

  @override
  String get goalMetricCircumferenceSubtitle =>
      'Volg je taille of andere lichaamsmetingen.';

  @override
  String get goalMetricDirectionalOnlyTitle => 'Alleen richting';

  @override
  String get goalMetricDirectionalOnlySubtitle =>
      'Volg het proces zonder vast streefgetal.';

  @override
  String get goalStep3Question => 'Tempo en parameters';

  @override
  String get goalStep3Description =>
      'Geef eventueel een streefwaarde en tempo per week op.';

  @override
  String get goalCustomDirectionPrompt =>
      'Moet dit doel je voedingsdoelen aansturen?';

  @override
  String get goalCustomDirectionNone => 'Alleen ter documentatie';

  @override
  String get goalTargetValueOptionalLabel => 'Streefwaarde (optioneel)';

  @override
  String get goalWeeklyRateLabel => 'Gepland tempo per week';

  @override
  String get goalStep4Question => 'Heb je een streefdatum?';

  @override
  String get goalStep4Description =>
      'Een streefdatum is helemaal optioneel. Train Libre zet je nooit onder druk.';

  @override
  String get goalNoDeadlineOption => 'Geen streefdatum';

  @override
  String get goalSelectDatePrompt => 'Datum selecteren';

  @override
  String get goalRemoveDeadlineChip => 'Streefdatum verwijderen';

  @override
  String get goalStep5Question => 'Startdatum en uitgangswaarde';

  @override
  String get goalStep5Description =>
      'Wanneer begint of begon dit doel? Train Libre zoekt automatisch naar de uitgangsmeting.';

  @override
  String get goalStartDateLabel => 'Startdatum';

  @override
  String get goalBaselineFoundTitle => 'Uitgangsmeting gevonden';

  @override
  String get goalBaselineNotFoundTitle => 'Geen uitgangsmeting gevonden';

  @override
  String get goalBaselineNotFoundDescription =>
      'Het doel blijft de status ‘Wacht op meting’ houden totdat je je eerste gewicht registreert.';

  @override
  String get goalStep6Question => 'Waarom is dit belangrijk voor je?';

  @override
  String get goalStep6Description =>
      'Je persoonlijke motivatie helpt je gefocust te blijven. Deze wordt alleen op je apparaat opgeslagen.';

  @override
  String get goalStepBaselineQuestion => 'Startdatum en uitgangsgewicht';

  @override
  String get goalStepBaselineDescription =>
      'Wanneer begint dit doel? Train Libre gebruikt je gewicht op die datum als uitgangswaarde.';

  @override
  String get goalStepTargetWeightQuestion => 'Wat is je streefgewicht?';

  @override
  String get goalStepTargetWeightDescription =>
      'Vul het gewenste streefgewicht in.';

  @override
  String get goalStepTrajectoryQuestion => 'Plan tempo en streefdatum';

  @override
  String get goalStepTrajectoryDescription =>
      'Kies een streefdatum of tempo per week; het andere wordt direct berekend.';

  @override
  String goalEnterBaselineWeightPrompt(String unit) {
    return 'Vul je startgewicht in ($unit)';
  }

  @override
  String goalTargetWeightLabel(String unit) {
    return 'Streefgewicht ($unit)';
  }

  @override
  String get goalWeightDifferenceLabel => 'Geplande verandering';

  @override
  String get goalPlanByDate => 'Plannen op streefdatum';

  @override
  String get goalPlanByRate => 'Plannen op tempo per week';

  @override
  String get goalEstimatedDailyDelta => 'Dagelijkse calorieaanpassing';

  @override
  String goalEstimatedDuration(int weeks) {
    return 'Duur: $weeks weken';
  }

  @override
  String get goalRateGentle => 'Rustig (0,25 kg/week)';

  @override
  String get goalRateModerate => 'Gemiddeld (0,50 kg/week)';

  @override
  String get goalRateAthletic => 'Sportief (0,75 kg/week)';

  @override
  String get goalRateAggressive => 'Intensief (1,00 kg/week)';

  @override
  String get goalRateCustom => 'Aangepast tempo (schuifregelaar)';

  @override
  String get goalDurationCustom => 'Aangepaste streefdatum...';

  @override
  String get goalPaceFeedbackSafe =>
      'Aanbevolen, duurzaam tempo (0,5%–1,0% van je lichaamsgewicht per week).';

  @override
  String get goalPaceFeedbackAggressive =>
      'Intensief tempo. Let goed op voldoende eiwitten en herstel.';

  @override
  String get goalPaceFeedbackGentle =>
      'Een heel rustig tempo dat je op lange termijn gemakkelijk volhoudt.';

  @override
  String get goalPaceFeedbackMaintain =>
      'Behoud je gewicht met een evenwichtige energie-inname.';

  @override
  String get goalReasonSuggestionHealth => 'Gezondheid en vitaliteit';

  @override
  String get goalReasonSuggestionFitness => 'Fitness en prestaties';

  @override
  String get goalReasonSuggestionShape => 'Comfortabel gewicht en uiterlijk';

  @override
  String get goalReasonSuggestionEvent => 'Sportwedstrijd of evenement';

  @override
  String get goalReasonSuggestionEnergy =>
      'Meer energie in het dagelijks leven';

  @override
  String get goalReasonSuggestionStrength => 'Kracht en spieropbouw';

  @override
  String get goalReasonSuggestionConfidence => 'Zelfvertrouwen en welzijn';

  @override
  String get goalReasonSuggestionLongevity =>
      'Een lang en gezond leven en preventie';

  @override
  String get goalReasonSuggestionHabits => 'Gezonde routine en discipline';

  @override
  String get goalReasonSuggestionClothing => 'Je goed voelen in je kleding';

  @override
  String get goalReasonPlaceholder =>
      'bijv. Ik wil me weer fitter en soepeler voelen…';

  @override
  String get goalReasonPrivacyNotice =>
      'Je notitie blijft volledig privé op je apparaat en wordt nooit gedeeld.';

  @override
  String get goalStep7Question => 'Controleren en activeren';

  @override
  String get goalStep7Description =>
      'Controleer je instellingen voordat je het doel activeert.';

  @override
  String get goalAreaLabel => 'Doelgebied';

  @override
  String get goalStartLabel => 'Startpunt';

  @override
  String get goalWaitingForMeasurementShort => 'Wachten op meting';

  @override
  String get goalTargetLabel => 'Doel';

  @override
  String get goalDirectionalOnly => 'Procesgericht';

  @override
  String get goalTargetDateLabel => 'Doeldatum';

  @override
  String get goalDriverSettingLabel => 'Stuurt voedingsdoelen';

  @override
  String get noActiveGoalTitle => 'Geen actief doel';

  @override
  String get noActiveGoalSubtitle =>
      'Train Libre werkt prima zonder vooraf ingestelde doelen.';

  @override
  String get noActiveGoalDescription =>
      'Je kunt altijd een doel voor je gewicht, vetpercentage of een eigen mijlpaal instellen om je voortgang en wekelijkse evaluaties te volgen.';

  @override
  String get createGoalButton => 'Doel instellen';

  @override
  String get goalWaitingForBaselineLabel => 'Wachten op meting';

  @override
  String get goalBaselineHeader => 'Start (basis)';

  @override
  String get goalCurrentHeader => 'Huidig';

  @override
  String get goalTargetHeader => 'Doel';

  @override
  String get goalProgressSectionTitle => 'Voortgang';

  @override
  String goalRemainingDistanceLabel(String distance) {
    return 'Nog $distance te gaan';
  }

  @override
  String get weekShort => 'week';

  @override
  String get goalNoTargetDateShort => 'Geen doeldatum';

  @override
  String get reviewStatusOnTrack => 'Op schema';

  @override
  String get reviewStatusSlower => 'Langzamer dan gepland';

  @override
  String get reviewStatusFaster => 'Sneller dan gepland';

  @override
  String get reviewStatusCalibrating => 'Kalibreren';

  @override
  String get reviewStatusBehind => 'Achter op schema';

  @override
  String get reviewStatusAhead => 'Voor op schema';

  @override
  String get reviewStatusTargetReached => 'Doel bereikt';

  @override
  String get reviewStatusTargetDateNeedsReview =>
      'Doeldatum moet worden herzien';

  @override
  String reviewOverallSummary(String overall, String momentum) {
    return 'Totaal: $overall. Afgelopen 7 dagen: $momentum.';
  }

  @override
  String get reviewMomentumMatchingPlan => 'volgens plan';

  @override
  String get reviewMomentumCatchingUp => 'bezig met inhalen';

  @override
  String get reviewMomentumFallingBehind => 'raakt verder achter';

  @override
  String get reviewMomentumMovingFaster => 'gaat sneller';

  @override
  String get reviewMomentumMovingSlower => 'gaat langzamer';

  @override
  String get reviewMomentumUnclear => 'nog onduidelijk';

  @override
  String reviewNextAnalysisScheduled(String date) {
    return 'Volgende adaptieve evaluatie op $date (min. 3 wegingen en 4 dagen met calorieënregistratie)';
  }

  @override
  String get weeklyReviewCardHeaderBadge => 'Wekelijkse evaluatie';

  @override
  String get weeklyReviewCardOverallLabel => 'Totale voortgang';

  @override
  String get weeklyReviewCardRecentLabel => 'Afgelopen 7 dagen';

  @override
  String get weeklyReviewPendingDefaultExplanation =>
      'Het adaptieve systeem vergelijkt de trend over 7 dagen met het gewenste verloop.';

  @override
  String get weeklyReviewNutritionSectionTitle => 'Voedingsadvies';

  @override
  String get weeklyReviewCaloriesTitle => 'Dagelijks caloriedoel';

  @override
  String get weeklyReviewCaloriesCurrent => 'Huidig';

  @override
  String get weeklyReviewCaloriesRecommended => 'Aanbevolen';

  @override
  String weeklyReviewCaloriesChange(String change) {
    return '$change kcal/dag';
  }

  @override
  String weeklyReviewCaloriesComparison(
      String current, String recommended, String change) {
    return '$current → $recommended kcal/dag ($change)';
  }

  @override
  String get weeklyReviewWeightProgressTitle => 'Voortgang gewichtdoel';

  @override
  String get weeklyReviewWeightPlannedLabel => 'Gepland tot nu toe';

  @override
  String get weeklyReviewWeightTrendLabel => 'Recente trend';

  @override
  String get weeklyReviewAdjustPlanTitle => 'Je plan aanpassen';

  @override
  String get weeklyReviewAdjustRate => 'Tempo per week aanpassen';

  @override
  String get weeklyReviewAdjustDate => 'Doeldatum wijzigen';

  @override
  String get weeklyReviewDetailsTitle => 'Voortgangsdetails';

  @override
  String get weeklyReviewDecisionTitle => 'Je volgende stap';

  @override
  String get weeklyReviewContinueLogging => 'Blijven registreren';

  @override
  String get weeklyReviewPreviewNoChanges =>
      'Proefweergave: er zijn geen wijzigingen opgeslagen.';

  @override
  String get reviewOpenDetailsButton => 'Evaluatie bekijken';

  @override
  String get applyRecommendationButton => 'Advies toepassen';

  @override
  String get weeklyReviewScreenTitle => 'Wekelijkse doelevaluatie';

  @override
  String get reviewSufficiencyGateTitle => 'Gegevens (afgelopen 7 dagen)';

  @override
  String get reviewWeighInsCountLabel => 'Wegingen';

  @override
  String get reviewLoggedDaysCountLabel => 'Dagen met voedingsregistratie';

  @override
  String get reviewTrajectoryComparisonTitle => 'Vergelijking van het verloop';

  @override
  String get reviewPlanVsRealityTitle => 'Plan en werkelijkheid';

  @override
  String get reviewExpectedByNowLabel => 'Verwacht tot nu toe';

  @override
  String get reviewSmoothedCurrentLabel => 'Huidige afgevlakte waarde';

  @override
  String get reviewTrajectoryGapLabel => 'Afwijking van het plan';

  @override
  String get reviewRequiredRateLabel => 'Benodigd tempo vanaf nu';

  @override
  String get reviewProjectedDateLabel => 'Verwachte doeldatum';

  @override
  String get reviewNutritionAdjustTargets =>
      'Je gewichtstrend wijkt af van het geplande tempo. Je registraties bevatten genoeg gegevens om een wijziging van je dagelijkse doelen aan te bevelen.';

  @override
  String get reviewNutritionKeepTargetsIntakeDiffers =>
      'Je huidige doelen passen nog steeds. Je geregistreerde inname wijkt ervan af; een planwijziging lost de grootste afwijking daarom niet op.';

  @override
  String get reviewNutritionKeepTargets =>
      'Deze week wordt geen wijziging van je dagelijkse doelen aanbevolen.';

  @override
  String get reviewNutritionTrajectoryChangeNeeded =>
      'Het tempo dat nodig is om de huidige datum te halen, is geen verstandige voedingsaanpassing. Wijzig je doel, tempo of datum.';

  @override
  String get reviewNutritionInsufficientData =>
      'Blijf je gegevens normaal registreren. Er zijn nog niet genoeg recente gegevens voor een betrouwbaar voedingsadvies.';

  @override
  String get reviewObservedRateLabel => 'Waargenomen trend';

  @override
  String get reviewTargetRateLabel => 'Gepland tempo';

  @override
  String get reviewEstimatedTDEELabel => 'Geschat onderhoud (TDEE)';

  @override
  String get reviewRecommendationTitle => 'Aanbevolen dagdoelen';

  @override
  String get reviewActionApplyRecommendation =>
      'Aanbevolen dagdoelen toepassen';

  @override
  String get weeklyReviewApplyTargetsAction => 'Doelen toepassen';

  @override
  String get weeklyReviewDateExtensionTitle => 'Doeldatum uitgesteld';

  @override
  String weeklyReviewDateExtensionContent(String rate, String date) {
    return 'Het tempo dat nodig is om je huidige doeldatum te halen, zou onveilig zijn voor je gezondheid. Je weektempo is begrensd op $rate en je doeldatum is aangepast naar $date om je gezondheid te beschermen.';
  }

  @override
  String get weeklyReviewRateTitle => 'Tempo per week';

  @override
  String get weeklyReviewDateTitle => 'Doeldatum';

  @override
  String get weeklyReviewRateNoChange => 'Ongewijzigd';

  @override
  String get weeklyReviewDateOnTrack => 'Op schema';

  @override
  String weeklyReviewDateDaysChange(String days) {
    return '$days dagen';
  }

  @override
  String get weeklyReviewPlanUpdatedSnack =>
      'Doelen en doelverloop bijgewerkt.';

  @override
  String get reviewActionAdjustTrajectory => 'Doel en verloop aanpassen';

  @override
  String get reviewActionKeepCurrent => 'Doel behouden en dagdoelen aanpassen';

  @override
  String get weeklyReviewKeepGoalAction => 'Doel behouden';

  @override
  String get reviewDismissedSnack =>
      'Evaluatie gesloten. Je huidige doelen blijven actief.';

  @override
  String get adjustGoalTitle => 'Doel aanpassen';

  @override
  String get adjustGoalDescription =>
      'Pas je streefgewicht, datum of weektempo aan. De overige waarden worden direct opnieuw berekend.';

  @override
  String get adjustGoalFixOptionKeepDate => 'Vaste datum';

  @override
  String get adjustGoalFixOptionKeepRate => 'Vast tempo';

  @override
  String get adjustGoalExtremeRateWarning =>
      'Let op: dit tempo wijkt sterk af van gebruikelijke fysiologische aanbevelingen.';

  @override
  String get adjustGoalApplyAsSuccessorButton => 'Als opvolgend doel toepassen';

  @override
  String get adjustGoalConfirmTitle => 'Plan bijwerken?';

  @override
  String get adjustGoalConfirmContent =>
      'Je voortgang en alle metingen blijven behouden. Het aangepaste verloop begint vandaag.';

  @override
  String get adjustGoalUpdatePlanButton => 'Plan bijwerken';

  @override
  String get adjustGoalAcceptRecommendationAndUpdatePlan =>
      'Advies accepteren en plan bijwerken';

  @override
  String get adjustGoalRecommendedTitle => 'Aanbevolen aanpassing';

  @override
  String adjustGoalRecommendedPlan(String date, String rate) {
    return 'Houd een realistisch tempo aan en verplaats de doeldatum naar $date ($rate).';
  }

  @override
  String adjustGoalRecommendedKeepDatePlan(String date, String rate) {
    return 'Behoud de doeldatum $date en pas het tempo aan naar $rate.';
  }

  @override
  String get adjustGoalSelectRecommendedPlan => 'Advies kiezen';

  @override
  String get adjustGoalConfirmButton => 'Toepassen';

  @override
  String get adjustGoalTargetWeightLabel => 'Streefgewicht';

  @override
  String get adjustGoalTargetDateLabel => 'Doeldatum';

  @override
  String get adjustGoalWeeklyRateLabel => 'Gepland tempo per week';

  @override
  String get goalDetailScreenTitle => 'Doeldetails';

  @override
  String get retireGoalDialogTitle => 'Doel archiveren?';

  @override
  String get retireGoalDialogContent =>
      'Het doel wordt gearchiveerd en stuurt je adaptieve voedingsdoelen niet meer aan. Je kunt het op elk moment opnieuw activeren.';

  @override
  String get retireGoalConfirmButton => 'Doel archiveren';

  @override
  String get goalRetiredSuccessSnack => 'Doel gearchiveerd.';

  @override
  String get resumeGoalDialogTitle => 'Doel opnieuw activeren?';

  @override
  String get resumeGoalDialogContent =>
      'Dit wordt weer je actieve doel en stuurt je adaptieve voedingsdoelen aan.';

  @override
  String get resumeGoalConfirmButton => 'Opnieuw activeren';

  @override
  String get goalResumedSuccessSnack => 'Doel opnieuw geactiveerd.';

  @override
  String get goalStatusActive => 'Actief';

  @override
  String get goalStatusRetired => 'Gearchiveerd';

  @override
  String get goalStatusSuperseded => 'Vervangen';

  @override
  String goalStartedOnLabel(String date) {
    return 'Gestart op $date';
  }

  @override
  String get goalDrivesNutritionBadge => 'Stuurt voeding aan';

  @override
  String get goalDocumentationOnlyBadge => 'Alleen ter registratie';

  @override
  String get goalWaitingForBaselineCalloutTitle => 'Basismeting vereist';

  @override
  String get goalWaitingForBaselineCalloutDescription =>
      'Er is geen meting op of vóór de startdatum. Registreer je eerste weging om de voortgang en het verloop te berekenen.';

  @override
  String get recordFirstMeasurementButton => 'Eerste meting registreren';

  @override
  String get goalWeightHistoryChartTitle => 'Gewichtstrend en doel';

  @override
  String get goalPersonalMotivationTitle => 'Je motivatie';

  @override
  String get retireGoalButton => 'Doel archiveren';

  @override
  String get resumeGoalButton => 'Doel opnieuw activeren';

  @override
  String get myGoalsOperativeTargetsBanner =>
      'Naar dagelijkse doelen (calorieën, macro’s en water)';

  @override
  String get myGoalsActiveGoalSectionHeader => 'Actief doel';

  @override
  String get myGoalsHistorySectionHeader => 'Doelgeschiedenis';

  @override
  String get goalsScreenToMyGoalsBannerTitle => 'Zoek je langetermijndoelen?';

  @override
  String get goalsScreenToMyGoalsBannerSubtitle =>
      'Beheer je gewichtstrajecten en wekelijkse evaluaties bij ‘Mijn doelen’.';

  @override
  String get dailyOperatingTargetsTitle => 'Dagdoelen';

  @override
  String get dailyOperatingTargetsSubtitle =>
      'Calorieën, macronutriënten en water';

  @override
  String get adjustDailyTargetsButton => 'Dagdoelen aanpassen';

  @override
  String get targetCaloriesLabel => 'Dagdoel';

  @override
  String get goalNotificationSettingsTitle =>
      'Meldingen voor doelen en evaluaties';

  @override
  String get goalNotificationWeeklyReviewTitle =>
      'Wekelijkse evaluatie beschikbaar';

  @override
  String get goalNotificationWeeklyReviewSubtitle =>
      'Je krijgt een melding zodra een evaluatie over 7 dagen beschikbaar is.';

  @override
  String get goalNotificationAdaptiveDueTitle => 'Adaptief advies beschikbaar';

  @override
  String get goalNotificationAdaptiveDueSubtitle =>
      'Meldt wanneer aanpassingen van je dagdoelen beschikbaar zijn.';

  @override
  String get goalNotificationTargetDateTitle =>
      'Herinnering voor de streefdatum';

  @override
  String get goalNotificationTargetDateSubtitle =>
      'Een vriendelijke herinnering wanneer de streefdatum nadert, zonder druk.';

  @override
  String get goalNotificationPrivacyNotice =>
      'Alle meldingen worden lokaal op je apparaat afgehandeld. Privégegevens over gewicht of calorieën verschijnen nooit op het vergrendelscherm.';

  @override
  String get goalMaintainCorridor => '± 1,0 kg (gewicht behouden)';

  @override
  String get goalNeedsFirstMeasurementPrompt =>
      'Registreer je eerste weging om je voortgang en trend te bekijken.';

  @override
  String goalRemainingDistanceText(String distance) {
    return 'Nog $distance';
  }

  @override
  String get goalMaintenanceStable => 'Stabiel binnen de doelmarge';

  @override
  String get goalMaintenanceDrifting => 'Lichte afwijking van de marge';

  @override
  String get goalJourneyInProgress => 'Je bent op weg naar je doel';

  @override
  String get goalJourneyTargetReached => 'Je hebt je doel bereikt';

  @override
  String get goalNotifyWeeklyReviewTitle => 'Wekelijkse evaluatie klaar';

  @override
  String get goalNotifyWeeklyReviewSubtitle =>
      'Meldt zodra de evaluatie van 7 dagen beschikbaar is.';

  @override
  String get goalNotifyRecommendationDueTitle =>
      'Nieuw adaptief advies beschikbaar';

  @override
  String get goalNotifyRecommendationDueSubtitle =>
      'Meldt wanneer aanpassingen van je dagdoelen beschikbaar zijn.';

  @override
  String get goalNotifyTargetDateTitle => 'Herinnering voor de streefdatum';

  @override
  String get goalNotifyTargetDateSubtitle =>
      'Een vriendelijke herinnering wanneer de streefdatum nadert, zonder druk.';

  @override
  String get goalNotifyPrivacyTitle => 'Privacy en lokale verwerking';

  @override
  String get goalNotifyPrivacyBody =>
      'Meldingen over doelen en evaluaties worden lokaal verwerkt en kunnen nuttige details over je doelen, gewicht of calorieën bevatten. Gebruik de instellingen van je besturingssysteem om voorbeelden op het vergrendelscherm en stille uren te beheren.';

  @override
  String get goalNotificationSettingsSubtitle =>
      'Lokale meldingen voor evaluaties en streefdatums';

  @override
  String get notificationSettingsTitle => 'Meldingen';

  @override
  String get notificationSettingsSubtitle =>
      'Herinneringen voor trainingen, doelen en evaluaties';

  @override
  String get notificationWorkoutSectionTitle => 'Trainingsplan';

  @override
  String get notificationGoalsSectionTitle => 'Doelen en evaluaties';

  @override
  String get workoutPlanNotifyTitle => 'Herinner me op trainingsdagen';

  @override
  String get workoutPlanNotifySubtitle =>
      'Alleen op geplande trainingsdagen. Geen inhaalherinneringen of verwijten.';

  @override
  String get workoutPlanNotifyTimeTitle => 'Tijdstip van herinnering';

  @override
  String get workoutPlanNotifyNoActivePlan =>
      'Herinneringen worden actief zodra er een trainingsplan actief is.';

  @override
  String get notificationPermissionDenied =>
      'Meldingen zijn uitgeschakeld in de systeeminstellingen.';

  @override
  String get notificationPrivacyTitle => 'Lokaal en onder jouw beheer';

  @override
  String get notificationPrivacyBody =>
      'Deze herinneringen worden lokaal ingepland. Beheer voorbeelden op het vergrendelscherm en stille uren via de instellingen van je besturingssysteem.';

  @override
  String get workoutPlanReminderTitle => 'Je training staat gepland';

  @override
  String workoutPlanReminderBody(String routineName, String planName) {
    return 'Hierna staat $routineName op het programma in $planName.';
  }

  @override
  String get weeklyGoalReviewNotificationTitle => 'Wekelijkse evaluatie klaar';

  @override
  String get weeklyGoalReviewNotificationBody =>
      'Je nieuwe evaluatie van 7 dagen staat klaar in de voedingshub.';

  @override
  String weeklyGoalReviewNotificationDetailedBody(
      String goalTitle, int calories) {
    return '$goalTitle: je bijgewerkte advies is $calories kcal per dag. Open de evaluatie voor de volledige toelichting.';
  }

  @override
  String get goalTargetDateReminderTitle => 'Streefdatum van je doel';

  @override
  String goalTargetDateReachedBody(String goalTitle) {
    return 'Vandaag is de streefdatum voor ‘$goalTitle’.';
  }

  @override
  String goalTargetDateApproachingBody(String goalTitle) {
    return 'De streefdatum voor ‘$goalTitle’ komt eraan.';
  }

  @override
  String get back => 'Terug';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nee';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get saving => 'Opslaan…';

  @override
  String get emptyStateMeasurements =>
      'Er zijn nog geen metingen geregistreerd.';

  @override
  String get goalTrackingModeTitle => 'Hoe wil je plannen?';

  @override
  String get goalTrackingModeDescription => 'Kies wat je voedingsdoel bepaalt.';

  @override
  String get goalTrackingModeOpen => 'Open doel';

  @override
  String get goalTrackingModeOpenDescription =>
      'Geen streefgewicht, datum of aangepast weektempo.';

  @override
  String get goalTrackingModeWeeklyRate => 'Tempo per week';

  @override
  String get goalTrackingModeWeeklyRateDescription =>
      'Stel in hoeveel je per week wilt afvallen of aankomen.';

  @override
  String get goalTrackingModeTargetWeight => 'Streefgewicht';

  @override
  String get goalTrackingModeTargetWeightDescription =>
      'Stel een streefgewicht in, eventueel met een datum.';

  @override
  String goalTrackingModeDefaultRateInfo(String rate) {
    return 'Het veilige standaardtempo van $rate wordt gebruikt en in het advies getoond.';
  }

  @override
  String get goalTrackingOpenReady =>
      'Je open doel is klaar. Het advies gebruikt het veilige standaardtempo voor deze richting.';

  @override
  String get goalTargetDateOptional => 'Streefdatum (optioneel)';

  @override
  String get goalReplaceActiveTitle => 'Actief voedingsdoel vervangen?';

  @override
  String get goalReplaceActiveBody =>
      'Je huidige voedingsdoel wordt afgerond en vervangen. Je dagdoelen veranderen pas wanneer je een advies toepast.';

  @override
  String get goalReplaceActiveConfirm => 'Doel vervangen';

  @override
  String goalCreateError(String error) {
    return 'Doel opslaan mislukt: $error';
  }

  @override
  String goalAdjustError(String error) {
    return 'Doel aanpassen mislukt: $error';
  }

  @override
  String get reviewKeepAndApplyTitle => 'Doel behouden en dagdoelen bijwerken?';

  @override
  String get reviewKeepAndApplyBody =>
      'Het doel blijft ongewijzigd. Het advies wordt opnieuw berekend en de nieuwe calorie- en voedingsstofdoelen worden meteen toegepast.';

  @override
  String reviewActionError(String error) {
    return 'Actie voor evaluatie mislukt: $error';
  }

  @override
  String get calculationBasisTitle => 'Berekeningsbasis';

  @override
  String get calculationBasisSubtitle =>
      'Dagelijkse activiteit en extra cardio';

  @override
  String get estimatedOneRepMaxInfoTitle =>
      'Schatting van je 1RM (Brzycki-formule)';

  @override
  String get estimatedOneRepMaxInfoExplanation =>
      'Schat je kracht op basis van een voltooide set om je voortgang te volgen.';

  @override
  String get estimatedOneRepMaxInfoPoints =>
      '1RM ≈ effectieve belasting × (36 / (37 − herhalingen)), voor 1–12 herhalingen.\nDit is een schatting op basis van een voltooide set, geen directe maximumtest.\nBij lichaamsgewicht- en ondersteunde oefeningen wordt de effectieve belasting gebruikt, inclusief lichaamsgewicht en ondersteuning.';

  @override
  String get estimatedOneRepMaxInfoDetailsTitle =>
      'Details van de Brzycki-formule';

  @override
  String get estimatedOneRepMaxInfoDetails =>
      'Train Libre schat het one-repetition maximum (1RM) op basis van de effectieve belasting van een set met de Brzycki-formule: 1RM = effectieve belasting × (36 / (37 − herhalingen)). Sets met meer dan 12 herhalingen worden niet gebruikt. Het blijft een schatting; individuele techniek en prestaties kunnen afwijken van de berekening.';

  @override
  String get setTimerStart => 'Timer starten';

  @override
  String get setTimerRunning => 'Timer loopt';

  @override
  String get setTimerStop => 'Timer stoppen';

  @override
  String get aiScanLogsTitle => 'AI-scanlogboeken voor maaltijden';

  @override
  String get aiScanLogsPrivacy =>
      'Alleen opgeslagen op dit apparaat. Geen maaltijdtekst, foto’s of sleutels. Maximaal 20 scans.';

  @override
  String get aiScanLogsEmpty =>
      'Er zijn nog geen AI-scans van maaltijden geregistreerd.';

  @override
  String aiScanLogsCount(int count) {
    return '$count scans';
  }

  @override
  String get aiScanLogsCopyAll => 'Alles kopiëren';

  @override
  String get aiScanLogsClear => 'Logboeken wissen';

  @override
  String get aiScanLogsCopy => 'Logboek kopiëren';

  @override
  String get aiScanLogsCopied => 'Logboek naar klembord gekopieerd';

  @override
  String get aiScanLogsPhotos => 'Foto’s';

  @override
  String get aiScanLogsFirstPass => 'Eerste validatie geslaagd';

  @override
  String get aiScanLogsValidations => 'Geselecteerde / totale validaties';

  @override
  String get aiScanLogsRepairs => 'Automatische reparaties';

  @override
  String get aiScanLogsHedge => 'Parallel verzoek';

  @override
  String get aiScanLogsTokens => 'Totaal aantal tokens (invoer / uitvoer)';

  @override
  String get aiScanLogsUnknown => 'Onbekend';

  @override
  String get aiScanLogsCalls => 'Verzoeken aan provider';

  @override
  String get aiScanLogsReview => 'Resultaat van beoordeling';

  @override
  String get aiScanLogsCorrections => 'AI-correcties door gebruiker';

  @override
  String get aiScanLogsTimeline => 'Tijdlijn';

  @override
  String get aiScanLogsInputText => 'Tekst';

  @override
  String get aiScanLogsInputPhoto => 'Foto';

  @override
  String get aiScanLogsInputMixed => 'Foto + tekst';

  @override
  String get aiScanLogsRunning => 'Bezig';

  @override
  String get aiScanLogsAccepted => 'Geaccepteerd';

  @override
  String get aiScanLogsNeedsRepair => 'Herstel nodig';

  @override
  String get aiScanLogsFailed => 'Mislukt';

  @override
  String get aiScanLogsCancelled => 'Geannuleerd';

  @override
  String get aiScanLogsSavedUnchanged => 'Ongewijzigd opgeslagen';

  @override
  String get aiScanLogsSavedEdited => 'Opgeslagen na bewerking';

  @override
  String get aiScanLogsSavedCorrected => 'Opgeslagen na AI-correctie';

  @override
  String get aiScanLogsDiscarded => 'Verworpen';

  @override
  String get aiScanLogsStageRequested => 'Scan gestart';

  @override
  String get aiScanLogsStagePrepared => 'Voorbereiding afgerond';

  @override
  String get aiScanLogsStagePrimary => 'Eerste AI-verzoek gestart';

  @override
  String get aiScanLogsStageHedge => 'Parallel AI-verzoek gestart';

  @override
  String get aiScanLogsStageProvider => 'AI-antwoord ontvangen';

  @override
  String get aiScanLogsStageValidation => 'Lokale validatie afgerond';

  @override
  String get aiScanLogsStageRepairStart => 'AI-herstel gestart';

  @override
  String get aiScanLogsStageRepairEnd => 'AI-herstelantwoord ontvangen';

  @override
  String get aiScanLogsStageReview => 'Beoordeling zichtbaar';

  @override
  String get aiScanLogsStagePreliminaryNutrition =>
      'Eerste voedingsschatting klaar';

  @override
  String get aiScanLogsStageReviewReady => 'Beoordeling klaar om op te slaan';

  @override
  String get aiScanLogsStageCorrectionStart => 'Gebruikerscorrectie gestart';

  @override
  String get aiScanLogsStageCorrectionEnd => 'Gebruikerscorrectie afgerond';

  @override
  String get aiScanLogsClearConfirm =>
      'Alle lokaal opgeslagen AI-scanlogboeken wissen?';

  @override
  String get aiScanLogsStageSelected => 'Kandidaat geselecteerd';

  @override
  String get aiScanLogsCandidatePrimary => 'Eerste verzoek';

  @override
  String get aiScanLogsCandidateHedge => 'Parallel verzoek';

  @override
  String get aiScanLogsScore => 'Score';

  @override
  String get aiScanLogsIssueSemantic => 'Cataloguskeuze';

  @override
  String get aiScanLogsIssueCatalog => 'Catalogusmatch';

  @override
  String get aiScanLogsIssueQuantity => 'Hoeveelheid';

  @override
  String get aiScanLogsIssueNutrition => 'Voedingsanker';

  @override
  String get aiScanLogsIssuePreparation => 'Bereidingstoestand';

  @override
  String get aiScanLogsIssueConfidence => 'Betrouwbaarheid';

  @override
  String get aiScanLogsIssueOther => 'Overige validatie';

  @override
  String get aiScanLogsStageUsage => 'Providergebruik gemeld';

  @override
  String get aiScanLogsCall => 'Verzoek';

  @override
  String get blsModificationsDetail =>
      'Toevoegingen van Train Libre: vertalingen, zoektermen en categorieën.';

  @override
  String get nutritionCatalogBls => 'Basisvoedingscatalogus (BLS)';

  @override
  String get blsCatalogManagementDescription =>
      'Download en werk de offline ingrediëntencatalogus BLS 4.0 bij (25,6 MB).';

  @override
  String get blsCatalogRefresh => 'Controleren op catalogusupdates';

  @override
  String get blsCatalogUpdated => 'BLS-catalogus bijgewerkt.';

  @override
  String get blsCatalogCurrent => 'De BLS-catalogus is up-to-date.';

  @override
  String get blsCatalogRefreshFailed =>
      'De BLS-catalogus kon niet worden bijgewerkt. Probeer het later opnieuw.';

  @override
  String get blsCompleteNutrientProfile =>
      'Volledig voedingsstoffenprofiel (BLS)';

  @override
  String blsNutrientCount(int count) {
    return '$count voedingswaarden per 100 g';
  }

  @override
  String get blsNutrientsUnavailable =>
      'Voedingsstofdetails zijn pas beschikbaar nadat de BLS-catalogus is geïnstalleerd.';

  @override
  String get blsNutrientDetails => 'Details';

  @override
  String get blsNutrientOrigin => 'Meting of berekening';

  @override
  String get blsNutrientReference => 'Referentie';

  @override
  String get blsFoodSourceLabel => 'Bron en licentie';

  @override
  String get blsFoodSource =>
      'Bundeslebensmittelschlüssel (BLS) 4.0 — Max Rubner-Institut';

  @override
  String get blsFoodLicense => 'BLS-gegevens: CC BY 4.0';

  @override
  String get blsFoodModifications =>
      'Vertalingen en categorieën van Train Libre';

  @override
  String get developerAiOverlayDemoTitle => 'AI-overlay';

  @override
  String get developerAiOverlayDemoSubtitle =>
      'Scrollbare UI-voorbeeldweergave met voorbeeldkaarten';

  @override
  String get aiOverlayDemoGlobalEnabledTitle =>
      'AI-assistent in de hele app tonen';

  @override
  String get aiOverlayDemoGlobalEnabledSubtitle =>
      'De zwevende AI-wolk op elk scherm tonen.';

  @override
  String get aiOverlayDemoScreenTitle => 'Demo van de AI-overlay';

  @override
  String get aiOverlayDemoIntroTitle => 'Voorbeeld van de assistent';

  @override
  String get aiOverlayDemoIntroBody =>
      'Blader door voorbeeldinhoud in de stijl van de app en probeer de voorbeeldweergave voor toegang.';

  @override
  String get aiOverlayDemoPreviewNote =>
      'Alleen voorbeeldgegevens. Er worden geen AI-verzoeken gedaan en er wordt geen echte trainings- of voedingsinformatie gebruikt.';

  @override
  String get aiOverlayDemoTodaySection => 'Jouw dag';

  @override
  String get aiOverlayDemoNutritionSection => 'Voeding';

  @override
  String get aiOverlayDemoActivitySection => 'Activiteit';

  @override
  String get aiOverlayDemoWorkoutTitle => 'Krachttraining';

  @override
  String get aiOverlayDemoWorkoutSubtitle => 'Bovenlichaam A · 2 uur geleden';

  @override
  String get aiOverlayDemoWorkoutMeta => '47 min · 6 oefeningen · 12 sets';

  @override
  String get aiOverlayDemoExerciseOne => 'Bankdrukken';

  @override
  String get aiOverlayDemoExerciseTwo => 'Zittende kabelroei';

  @override
  String get aiOverlayDemoStepsValue => '7.842 van 10.000 stappen';

  @override
  String get aiOverlayDemoWaterValue => '1,6 van 2,5 l';

  @override
  String get aiOverlayDemoAssistantSection => 'Actie met toestemming';

  @override
  String get aiOverlayNewChat => 'Nieuwe chat';

  @override
  String get aiOverlayChatHistory => 'Chatgeschiedenis';

  @override
  String get aiOverlayAutoApprove => 'Dataverzoeken automatisch goedkeuren';

  @override
  String get aiOverlayDemoAssistantMessage =>
      'Je hebt deze week drie keer getraind. Zal ik je trainingsbelasting vergelijken?';

  @override
  String get aiOverlayDemoRequestLabel => 'Benodigde gegevens';

  @override
  String get aiOverlayDemoScope => 'Work-outs van de afgelopen 7 dagen';

  @override
  String get aiOverlayDemoScopeDetails => 'Duur en volume van work-outs';

  @override
  String get aiOverlayDemoPurpose => 'Doel: trainingsbelasting vergelijken';

  @override
  String get aiOverlayDemoDeny => 'Weigeren';

  @override
  String get aiOverlayDemoAllowOnce => 'Eenmalig toestaan';

  @override
  String get aiOverlayDemoApprovedFeedback =>
      'De goedkeuring is in deze demo gesimuleerd.';

  @override
  String get aiOverlayDemoDeniedFeedback =>
      'Het verzoek is in deze demo geweigerd.';

  @override
  String get aiOverlayDemoCloudHint =>
      'Versleep de wolk horizontaal. De positie wordt opgeslagen.';

  @override
  String get aiOverlayDemoAssistantHint => 'AI-assistent openen';

  @override
  String get aiOverlayDemoColorSectionTitle => 'Zwart en wit';

  @override
  String get aiOverlayDemoColorWhite => 'Wit';

  @override
  String get aiOverlayDemoColorBlack => 'Zwart';

  @override
  String get aiOverlayDemoLivelinessTitle => 'Beweging van de wolk';

  @override
  String get aiOverlayDemoLivelinessDescription =>
      'Regelt de beweging van de uitgeklapte AI-wolk.';

  @override
  String get aiOverlayDemoSafeSpaceTitle =>
      'Punten van het veilige gebied tonen';

  @override
  String get aiOverlayDemoSafeSpaceSubtitle =>
      'De hoeken tonen waarmee je het gebied kunt vergroten of verkleinen';

  @override
  String get aiOverlayDemoFullscreenTitle => 'Direct op volledig scherm openen';

  @override
  String get aiOverlayDemoFullscreenSubtitle =>
      'De tussenweergave overslaan wanneer je de wolk opent';

  @override
  String get developerNutritionLabSubtitle =>
      'Bekijk de voedingslogica en adaptieve aanbevelingen';

  @override
  String get appleFoundationReadyTitle => 'Beschikbaar op dit apparaat';

  @override
  String get appleFoundationEnableTitle => 'In iOS-instellingen inschakelen';

  @override
  String get appleFoundationNoTransferSubtitle =>
      'Geen gegevensoverdracht en geen API-kosten.';

  @override
  String get telemetryDeleteSuccess =>
      'Telemetrie-ID\'s en -gegevens zijn lokaal en op de server verwijderd.';

  @override
  String aiAssistantAskModelHint(String model) {
    return 'Vraag $model';
  }

  @override
  String get aiStarterCheckNutritionTitle => 'Voeding van vandaag bekijken';

  @override
  String get aiStarterCheckNutritionPrompt =>
      'Hoe staan mijn voeding en macro\'s er vandaag voor? Toon mijn verbruikte calorieën, eiwitten, koolhydraten en vetten, vergelijk ze met mijn dagdoelen en geef aan wat ik nog over heb.';

  @override
  String get aiStarterCheckRecoveryTitle => 'Herstelstatus bekijken';

  @override
  String get aiStarterCheckRecoveryPrompt =>
      'Wat is mijn huidige herstelstatus? Welke spiergroepen zijn volledig hersteld en welke hebben nog rust nodig voor mijn volgende work-out?';

  @override
  String get aiStarterSuggestMealTitle =>
      'Maaltijd voorstellen voor resterende macro\'s';

  @override
  String get aiStarterSuggestMealPrompt =>
      'Bekijk mijn voedingsdagboek van vandaag en mijn resterende macro\'s. Welke maaltijden heb ik al geregistreerd en wat kan ik bij mijn volgende maaltijd eten om mijn resterende calorie- en voedingsdoelen zo goed mogelijk te halen?';

  @override
  String get aiAssistantThinking => 'Denkt na…';

  @override
  String get aiAssistantProcessingData => 'Goedgekeurde gegevens analyseren…';

  @override
  String get macroEntryButton => 'Macro\'s';

  @override
  String get macroEntryTitle => 'Macro\'s registreren';

  @override
  String get macroEntryName => 'Naam (optioneel)';

  @override
  String get macroEntryAmount => 'Hoeveelheid (optioneel)';

  @override
  String get macroEntryAmountTotalHint =>
      'Laat leeg om waarden voor het hele product in te voeren.';

  @override
  String get macroEntryAmountPer100GramHint =>
      'Als je een hoeveelheid invult, gelden de voedingswaarden per 100 g.';

  @override
  String get macroEntryAmountPer100MlHint =>
      'Als je een hoeveelheid invult, gelden de voedingswaarden per 100 ml.';

  @override
  String get macroEntryCalculate => 'Automatisch berekenen';

  @override
  String get macroEntryInvalidValues =>
      'Met deze waarden kan geen geldige hoeveelheid macro\'s worden berekend.';

  @override
  String get macroEntryLogAsFluid => 'Ook als drank registreren';

  @override
  String get macroEntryFluidAmountRequired =>
      'Voer een hoeveelheid in ml in om een drank te registreren.';

  @override
  String get macroEntryExtraNutrients => 'Meer voedingsstoffen toevoegen';

  @override
  String get macroEntrySugar => 'Suiker';

  @override
  String get macroEntryFiber => 'Vezels';

  @override
  String get macroEntrySalt => 'Zout';

  @override
  String get macroEntryCaffeine => 'Cafeïne';

  @override
  String get macroEntryPer100 => 'Per 100';

  @override
  String get macroEntryPortion => 'Portie';

  @override
  String get macroEntrySaved => 'Macro\'s geregistreerd.';

  @override
  String get macroEntryDefaultName => 'Macroregistratie';

  @override
  String get macroEntryDetailTitle => 'Voedingsstoffen';

  @override
  String get macroEntryFillThreeValues =>
      'Vul precies drie van de vier macrowaarden in.';

  @override
  String get macroEntryDeleteConfirm =>
      'Deze drank is gekoppeld aan een macroregistratie. Als je de drank verwijdert, wordt ook de macroregistratie verwijderd.';

  @override
  String get recoveryMixedReadyZoneTitle => 'Gemengd / klaar';

  @override
  String get feedbackReportDirectRequiresTelemetry =>
      'Voor rechtstreeks verzenden moet je anonieme gebruiksstatistieken inschakelen. Schakel dit in bij Instellingen of gebruik e-mail of delen.';

  @override
  String get feedbackReportDirectSent =>
      'Diagnoserapport rechtstreeks naar de ontwikkelaar verzonden. Bedankt!';

  @override
  String get feedbackReportDirectSend =>
      'Rechtstreeks naar de ontwikkelaar verzenden';

  @override
  String get aiAssistantUpdateIntroTitle => 'Maak kennis met de AI-chat';

  @override
  String get aiAssistantUpdateIntroBody =>
      'Stel vragen over je training en voeding. De assistent kan gegevens die je goedkeurt samenvatten en routines, trainingsschema’s of recepten als concept opstellen. Je kunt elk verzoek om gegevens en elke wijziging controleren voordat je die toepast. Stel een provider in bij AI-instellingen voor echte antwoorden.';

  @override
  String get aiAssistantUpdateIntroDemoLabel => 'Voorbeeldchat';

  @override
  String get aiAssistantUpdateIntroExampleQuestion =>
      'Wat kan de nieuwe AI-chat in Train Libre?';

  @override
  String get aiAssistantUpdateIntroExampleAnswer =>
      'De chat beantwoordt vragen over training en voeding en bekijkt relevante gegevens met jouw toestemming. De chat maakt concepten voor routines, trainingsschema’s en recepten. Je controleert en bevestigt maaltijden vóór het opslaan; zonder jouw toestemming wordt niets opgeslagen.';

  @override
  String get aiAssistantUpdateIntroAiEnabled => 'AI-functies inschakelen';

  @override
  String get aiAssistantUpdateIntroAiEnabledHint =>
      'Regelt de AI-chat en de overige AI-functies.';

  @override
  String get aiAssistantUpdateIntroLauncherEnabled => 'Zwevende AI-chat tonen';

  @override
  String get aiAssistantUpdateIntroLauncherEnabledHint =>
      'Toon of verberg de chatballon. Je kunt de chat ook openen via het menu Toevoegen.';

  @override
  String get aiAssistantIntroAboutRow => 'AI-chat bekijken';

  @override
  String get aiAssistantIntroAboutRowSubtitle =>
      'Bekijk de introductie van de nieuwe AI-chat wanneer je wilt opnieuw.';
}
