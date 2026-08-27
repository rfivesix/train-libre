// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get selectDateTitle => 'Choisir une date';

  @override
  String get selectTimeTitle => 'Choisir une heure';

  @override
  String get removeTimer => 'Supprimer le minuteur';

  @override
  String get noTimerLabel => 'Aucun minuteur';

  @override
  String get appTitle => 'Train Libre';

  @override
  String get bannerText => 'Recommandation / Entraînement actuel';

  @override
  String get calories => 'Calories';

  @override
  String get water => 'Eau';

  @override
  String get protein => 'Protéines';

  @override
  String get carbs => 'Glucides';

  @override
  String get fat => 'Lipides';

  @override
  String get steps => 'Pas';

  @override
  String get daily => 'Tous les jours';

  @override
  String get nowLabel => 'Now';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get workoutSection => 'Section entraînement - pas encore implémentée';

  @override
  String get addMenuTitle => 'Que veux-tu ajouter ?';

  @override
  String get addFoodOption => 'ajouter de la nourriture';

  @override
  String get addLiquidOption => 'ajouter du liquide';

  @override
  String get searchHintText => 'Recherche...';

  @override
  String get mealtypeBreakfast => 'Petit-déjeuner';

  @override
  String get mealtypeLunch => 'Déjeuner';

  @override
  String get mealtypeDinner => 'Dîner';

  @override
  String get mealtypeSnack => 'Collation';

  @override
  String get waterHeader => 'Eau et boissons';

  @override
  String get openFoodFactsSource => 'Données d’Open Food Facts';

  @override
  String get tabRecent => 'Récent';

  @override
  String get tabSearch => 'Recherche';

  @override
  String get tabFavorites => 'Favoris';

  @override
  String get fabCreateOwnFood => 'Nourriture personnalisée';

  @override
  String get recentEmptyState =>
      'Vos produits alimentaires récemment utilisés\napparaîtra ici.';

  @override
  String get favoritesEmptyState =>
      'Vous n\'avez pas encore de favoris.\nMarquez un aliment avec l\'icône en forme de cœur pour le voir ici.';

  @override
  String get searchInitialHint => 'Veuillez saisir un terme de recherche.';

  @override
  String get searchNoResults => 'Aucun résultat trouvé.';

  @override
  String get createFoodScreenTitle => 'Créer des aliments personnalisés';

  @override
  String get formFieldName => 'Nom de la nourriture';

  @override
  String get formFieldBrand => 'Marque (facultatif)';

  @override
  String get formSectionMainNutrients => 'Principaux nutriments (pour 100 g)';

  @override
  String get formFieldCalories => 'Calories (kcal)';

  @override
  String get formFieldProtein => 'Protéine (g)';

  @override
  String get formFieldCarbs => 'Glucides (g)';

  @override
  String get formFieldFat => 'Graisse (g)';

  @override
  String get formSectionOptionalNutrients =>
      'Nutriments supplémentaires (facultatif, par 100 g)';

  @override
  String get formFieldSugar => 'Dont sucres (g)';

  @override
  String get formFieldFiber => 'Fibres (g)';

  @override
  String get formFieldKj => 'Kilojoules (kJ)';

  @override
  String get formFieldSalt => 'Sel (g)';

  @override
  String get formFieldSodium => 'Sodium (mg)';

  @override
  String get formFieldCalcium => 'Calcium (mg)';

  @override
  String get buttonSave => 'Sauvegarder';

  @override
  String get validatorPleaseEnterName => 'Veuillez saisir un nom.';

  @override
  String get validatorPleaseEnterNumber => 'Veuillez entrer un numéro valide.';

  @override
  String snackbarSaveSuccess(String foodName) {
    return '$foodName a été enregistré avec succès.';
  }

  @override
  String get foodDetailSegmentPortion => 'Partie';

  @override
  String get foodDetailSegment100g => '100g';

  @override
  String get sugar => 'Sucre';

  @override
  String get fiber => 'Fibre';

  @override
  String get salt => 'Sel';

  @override
  String get caffeine => 'Caféine';

  @override
  String get explorerScreenTitle => 'Explorateur culinaire';

  @override
  String get nutritionScreenTitle => 'Analyse nutritionnelle';

  @override
  String get entriesForDateRangeLabel => 'Entrées pour';

  @override
  String get noEntriesForPeriod =>
      'Aucune entrée pour cette période pour l\'instant.';

  @override
  String get waterEntryTitle => 'Eau';

  @override
  String get profileScreenTitle => 'Profil';

  @override
  String get profileDailyGoals => 'Objectifs quotidiens';

  @override
  String get profileDailyGoalsCL => 'OBJECTIFS QUOTIDIENS';

  @override
  String get snackbarGoalsSaved => 'Objectifs enregistrés avec succès !';

  @override
  String get measurementsScreenTitle => 'Mesures';

  @override
  String get measurementsEmptyState =>
      'Aucune mesure enregistrée pour l\'instant.\nCommencez par le bouton « + ».';

  @override
  String get addMeasurementDialogTitle => 'Ajouter une nouvelle mesure';

  @override
  String get formFieldMeasurementType => 'Type de mesure';

  @override
  String formFieldMeasurementValue(Object unit) {
    return 'Valeur ($unit)';
  }

  @override
  String get validatorPleaseEnterValue => 'Veuillez saisir une valeur';

  @override
  String get measurementWeight => 'Poids corporel';

  @override
  String get measurementFatPercent => 'Graisse corporelle';

  @override
  String get measurementNeck => 'Cou';

  @override
  String get measurementShoulder => 'Épaule';

  @override
  String get measurementChest => 'Poitrine';

  @override
  String get measurementLeftBicep => 'Biceps gauche';

  @override
  String get measurementRightBicep => 'Biceps droit';

  @override
  String get measurementLeftForearm => 'Avant-bras gauche';

  @override
  String get measurementRightForearm => 'Avant-bras droit';

  @override
  String get measurementAbdomen => 'Abdomen';

  @override
  String get measurementWaist => 'Taille';

  @override
  String get measurementHips => 'Les hanches';

  @override
  String get measurementLeftThigh => 'Cuisse gauche';

  @override
  String get measurementRightThigh => 'Cuisse droite';

  @override
  String get measurementLeftCalf => 'Mollet gauche';

  @override
  String get measurementRightCalf => 'Veau droit';

  @override
  String get drawerMenuTitle => 'Menu Train Libre';

  @override
  String get drawerDashboard => 'Tableau de bord';

  @override
  String get drawerFoodExplorer => 'Explorateur culinaire';

  @override
  String get drawerDataManagement => 'Sauvegarde des données';

  @override
  String get drawerMeasurements => 'Mesures';

  @override
  String get dataManagementTitle => 'Sauvegarde des données';

  @override
  String get exportCardTitle => 'Exporter des données';

  @override
  String get exportCardDescription =>
      'Enregistre toutes vos entrées de journal, favoris et aliments personnalisés dans un seul fichier de sauvegarde.';

  @override
  String get exportCardButton => 'Créer une sauvegarde';

  @override
  String get importCardTitle => 'Importer des données';

  @override
  String get importCardDescription =>
      'Restaure vos données à partir d\'un fichier de sauvegarde précédemment créé. AVERTISSEMENT : toutes les données actuellement stockées dans l\'application seront écrasées !';

  @override
  String get importCardButton => 'Restaurer la sauvegarde';

  @override
  String get recommendationDefault => 'Suivez votre premier repas !';

  @override
  String recommendationOverTarget(Object count, Object difference) {
    return '$count derniers jours : +$difference kcal par rapport à l\'objectif';
  }

  @override
  String recommendationUnderTarget(Object count, Object difference) {
    return '$count derniers jours : $difference kcal en dessous de l\'objectif';
  }

  @override
  String recommendationOnTarget(Object count) {
    return '$count derniers jours : objectif atteint ✅';
  }

  @override
  String get recommendationFirstEntry =>
      'Super, votre première entrée est enregistrée !';

  @override
  String get dialogConfirmTitle => 'Confirmation requise';

  @override
  String get dialogConfirmImportContent =>
      'Voulez-vous vraiment restaurer les données de cette sauvegarde ?\n\nAVERTISSEMENT : toutes vos entrées, favoris et aliments personnalisés actuels seront définitivement supprimés et remplacés.';

  @override
  String get dialogButtonCancel => 'Annuler';

  @override
  String get dialogButtonOverwrite => 'Oui, tout écraser';

  @override
  String get snackbarNoFileSelected => 'Aucun fichier sélectionné.';

  @override
  String get snackbarImportSuccessTitle => 'Importation réussie !';

  @override
  String get snackbarImportSuccessContent =>
      'Vos données ont été restaurées. Il est recommandé de redémarrer l\'application pour un affichage correct.';

  @override
  String get snackbarButtonOK => 'D\'ACCORD';

  @override
  String get snackbarImportError =>
      'Erreur lors de l\'importation des données.';

  @override
  String get snackbarExportSuccess =>
      'Le fichier de sauvegarde a été transmis au système. Veuillez choisir un emplacement à enregistrer.';

  @override
  String get snackbarExportFailed =>
      'L\'exportation a été annulée ou a échoué.';

  @override
  String get profileUserHeight => 'Hauteur (cm)';

  @override
  String get workoutRoutinesTitle => 'Programmes';

  @override
  String get workoutHistoryTitle => 'Historique d\'entraînement';

  @override
  String get workoutHistoryButton => 'Histoire';

  @override
  String get emptyRoutinesTitle => 'Aucune routine trouvée';

  @override
  String get emptyRoutinesSubtitle =>
      'Créez votre première routine ou démarrez un entraînement vierge.';

  @override
  String get createFirstRoutineButton => 'Créer la première routine';

  @override
  String get startEmptyWorkoutButton => 'Entraînement gratuit';

  @override
  String get editRoutineSubtitle =>
      'Appuyez pour modifier ou démarrer l\'entraînement.';

  @override
  String get startButton => 'Commencer';

  @override
  String get addRoutineButton => 'Nouvelle routine';

  @override
  String get freeWorkoutTitle => 'Entraînement gratuit';

  @override
  String get finishWorkoutButton => 'Finition';

  @override
  String get addSetButton => 'Ajouter un ensemble';

  @override
  String get addExerciseToWorkoutButton =>
      'Ajouter de l\'exercice à l\'entraînement';

  @override
  String get lastTimeLabel => 'Dernière fois';

  @override
  String get setLabel => 'Ensemble';

  @override
  String kgLabel(String unit) {
    return 'Weight ($unit)';
  }

  @override
  String get repsLabel => 'Représentants';

  @override
  String cardioDistanceLabel(String unit) {
    return 'Distance ($unit)';
  }

  @override
  String get cardioTimeLabel => 'Temps';

  @override
  String get cardioIntensityLabel => 'Intenses.';

  @override
  String get cardioIntensityShortLabel => 'Int.';

  @override
  String get restTimerLabel => 'Repos';

  @override
  String get skipButton => 'Sauter';

  @override
  String get appInitStarting => 'Démarrage de l\'application...';

  @override
  String get appInitInitializing => 'Initialisation...';

  @override
  String get appInitFinalizing => 'Finalisation';

  @override
  String get appInitCheckingBackups => 'Vérification des sauvegardes...';

  @override
  String get appInitSkipDownload => 'Ignorer le téléchargement';

  @override
  String get appInitSkippingRemoteDownload =>
      'Ignorer le téléchargement à distance...';

  @override
  String get emptyHistory => 'Aucun entraînement terminé pour l\'instant.';

  @override
  String get workoutDetailsTitle => 'Détails de l\'entraînement';

  @override
  String get workoutHeartRateSectionTitle => 'Fréquence cardiaque';

  @override
  String get workoutHeartRateAverageLabel => 'Moy.';

  @override
  String get workoutHeartRateMaxLabel => 'Max.';

  @override
  String get workoutHeartRateMinLabel => 'Min.';

  @override
  String get workoutHeartRateQualityReady => 'Bonne couverture';

  @override
  String get workoutHeartRateQualityLimited => 'Données limitées';

  @override
  String get workoutHeartRateQualityInsufficient => 'Très clairsemé';

  @override
  String get workoutHeartRateQualityNoData => 'Aucune donnée';

  @override
  String get workoutHeartRateNoDataGeneral =>
      'Aucun échantillon de fréquence cardiaque n\'a été trouvé pour cette fenêtre d\'entraînement.';

  @override
  String get workoutHeartRateNoDataPermission =>
      'Une autorisation de fréquence cardiaque est requise pour afficher la fréquence cardiaque de l\'entraînement.';

  @override
  String get workoutHeartRateNoDataUnavailable =>
      'Les données de fréquence cardiaque ne sont actuellement pas disponibles sur cet appareil.';

  @override
  String get workoutHeartRateNoDataWorkoutNotFinished =>
      'Un résumé de la fréquence cardiaque apparaît après un entraînement terminé.';

  @override
  String get workoutHeartRateNoDataInvalidWindow =>
      'La fenêtre de temps d’entraînement n’est pas valide, la FC ne peut donc pas être analysée.';

  @override
  String get workoutHeartRateNoDataQueryFailed =>
      'Impossible de lire les données de fréquence cardiaque pour cet entraînement.';

  @override
  String get workoutHeartRateLimitedChartHint =>
      'Pas assez d’échantillons cohérents pour un graphique fiable.';

  @override
  String workoutHeartRateSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count échantillons',
      one: '1 echantillon',
      zero: 'Aucun echantillon',
    );
    return '$_temp0';
  }

  @override
  String get workoutNotFound => 'Entraînement introuvable.';

  @override
  String get totalVolumeLabel => 'Volume total';

  @override
  String get notesLabel => 'Remarques';

  @override
  String get workoutImportTitle => 'Importation d\'entraînement externe';

  @override
  String get workoutImportDescription =>
      'Importez votre historique de formation à partir d’un fichier d’export CSV ou Excel.';

  @override
  String get workoutImportButton => 'Importer des données d\'entraînement';

  @override
  String workoutImportSuccess(Object count) {
    return '$count entraînements ont été importés avec succès !';
  }

  @override
  String get workoutImportFailed =>
      'L\'importation a échoué. Veuillez vérifier le fichier.';

  @override
  String get importUnitSelectionTitle => 'Unité d\'importation';

  @override
  String get importUnitSelectionDescription =>
      'Dans quelle unité les données du fichier sont-elles fournies ?';

  @override
  String get unitMetricLabel => 'Métrique (kg)';

  @override
  String get unitImperialLabel => 'Impérial (lbs)';

  @override
  String get excelExportButton => 'Exportation Excel (.xlsx)';

  @override
  String get exportWorkoutHistory => 'Historique d\'entraînement';

  @override
  String get exportNutritionDiary => 'Journal nutritionnel';

  @override
  String get exportMeasurements => 'Mesures';

  @override
  String get startWorkout => 'Commencer l\'entraînement';

  @override
  String get addMeasurement => 'Ajouter une mesure';

  @override
  String get filterToday => 'Aujourd\'hui';

  @override
  String get filter7Days => '7 jours';

  @override
  String get filter30Days => '30 jours';

  @override
  String get filter30DaysShort => '30j';

  @override
  String get filter90DaysShort => '90j';

  @override
  String get filter180DaysShort => '180j';

  @override
  String get filter7DaysShort => '7j';

  @override
  String get filter1MonthShort => '1M';

  @override
  String get filter3MonthsShort => '3M';

  @override
  String get filter6MonthsShort => '6M';

  @override
  String get filter1YearShort => '1A';

  @override
  String get filterMax => 'MAX';

  @override
  String get filterAll => 'Tous';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get showMoreDetails => 'Afficher plus de détails';

  @override
  String get deleteConfirmTitle => 'Confirmer la suppression';

  @override
  String get deleteConfirmContent =>
      'Voulez-vous vraiment supprimer cette entrée ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get unsavedChangesTitle => 'Modifications non enregistrées';

  @override
  String get unsavedChangesContent =>
      'Vous avez des modifications non enregistrées. Voulez-vous les sauvegarder avant de partir ?';

  @override
  String get share => 'Partager';

  @override
  String get shareWorkout => 'Partager l\'entraînement';

  @override
  String get shareRoutine => 'Partager la routine';

  @override
  String get shareAsImage => 'Partager en tant qu\'image';

  @override
  String get shareAsText => 'Partager sous forme de texte';

  @override
  String get sharedFromTrainLibre => 'Partagé depuis Train Libre';

  @override
  String get sharedWithTrainLibre => 'Partagé avec Train Libre';

  @override
  String get shareImageSummary => 'Résumé';

  @override
  String get shareImageExercises => 'Exercices';

  @override
  String get shareImageMuscleFocus => 'Concentration musculaire';

  @override
  String get shareImageMinimal => 'Minimal';

  @override
  String get volume => 'Volume';

  @override
  String moreExercises(int count) {
    return '+ $count exercices supplémentaires';
  }

  @override
  String shareSetNumber(int number) {
    return 'Définir $number';
  }

  @override
  String get repsShort => 'représentants';

  @override
  String get shareFailed => 'Le partage a échoué';

  @override
  String get workoutShareTitle => 'Entraînement';

  @override
  String get routineShareTitle => 'Routine';

  @override
  String get setTypeWarmup => 'Réchauffer';

  @override
  String get setTypeWork => 'Ensembles de travail';

  @override
  String get setTypeFailure => 'Échec';

  @override
  String get setTypeDropset => 'Ensemble de gouttes';

  @override
  String get setTypeSuperset => 'Surensemble';

  @override
  String get setTypeOther => 'Autre';

  @override
  String get setTypeWarmupSuffix => 'Réchauffer';

  @override
  String get setTypeFailureSuffix => 'Échec';

  @override
  String get setTypeDropsetSuffix => 'Ensemble de gouttes';

  @override
  String get setTypeSupersetSuffix => 'Surensemble';

  @override
  String get setTypeOtherSuffix => 'Autre';

  @override
  String warmupSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ensembles d\'echauffement $count',
      one: '1 kit d\'echauffement',
    );
    return '$_temp0';
  }

  @override
  String workSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ensembles de travaux $count',
      one: '1 ensemble de travail',
    );
    return '$_temp0';
  }

  @override
  String failureSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ensembles de defaillances $count',
      one: '1 jeu de pannes',
    );
    return '$_temp0';
  }

  @override
  String dropsetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ensembles de gouttes $count',
      one: '1 dropset',
    );
    return '$_temp0';
  }

  @override
  String supersetSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Surensembles $count',
      one: '1 surensemble',
    );
    return '$_temp0';
  }

  @override
  String otherSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres ensembles',
      one: '1 autre ensemble',
    );
    return '$_temp0';
  }

  @override
  String warmupCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count échauffement',
      one: '1 echauffement',
    );
    return '$_temp0';
  }

  @override
  String workCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count travail',
      one: '1 uvre',
    );
    return '$_temp0';
  }

  @override
  String failureCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Echec $count',
      one: '1 echec',
    );
    return '$_temp0';
  }

  @override
  String dropsetCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ensembles de gouttes $count',
      one: '1 dropset',
    );
    return '$_temp0';
  }

  @override
  String supersetCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Surensembles $count',
      one: '1 surensemble',
    );
    return '$_temp0';
  }

  @override
  String otherCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autre',
      one: '1 autre',
    );
    return '$_temp0';
  }

  @override
  String get shareExercisesLabel => 'exercices';

  @override
  String get shareSetsLabel => 'ensembles';

  @override
  String get shareSetLabel => 'ensemble';

  @override
  String get tabBaseFoods => 'Aliments de base';

  @override
  String get baseFoodsEmptyState =>
      'Cette section sera bientôt remplie d\'une liste organisée d\'aliments de base comme des fruits, des légumes et plus encore.';

  @override
  String get noBrand => 'Aucune marque';

  @override
  String get unknown => 'Inconnu';

  @override
  String backupFileSubject(String timestamp) {
    return 'Sauvegarde de l\'application Train Libre - $timestamp';
  }

  @override
  String foodItemSubtitle(String brand, int calories) {
    return '$brand - $calories kcal / 100g';
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
  String get exerciseCatalogTitle => 'Catalogue d\'exercices';

  @override
  String get filterByMuscle => 'Filtrer par groupe musculaire';

  @override
  String get noExercisesFound => 'Aucun exercice trouvé.';

  @override
  String get noDescriptionAvailable => 'Aucune description disponible.';

  @override
  String get filterByCategory => 'Filtrer par catégorie';

  @override
  String get edit => 'Modifier';

  @override
  String get repsLabelShort => 'représentants';

  @override
  String get titleNewRoutine => 'Nouvelle routine';

  @override
  String get titleEditRoutine => 'Modifier la routine';

  @override
  String get editRoutine => 'Modifier la routine';

  @override
  String get validatorPleaseEnterRoutineName =>
      'Veuillez saisir un nom pour la routine.';

  @override
  String get snackbarRoutineCreated =>
      'Routine créée. Ajoutez maintenant quelques exercices.';

  @override
  String get snackbarRoutineSaved => 'Routine enregistrée.';

  @override
  String get saveAsRoutineButton => 'Enregistrer comme routine';

  @override
  String get saveAsRoutineTitle => 'Enregistrer comme routine';

  @override
  String get saveAsRoutinePrompt =>
      'Veuillez saisir un nom pour la nouvelle routine :';

  @override
  String get saveAsRoutineSuccess => 'Routine créée !';

  @override
  String get snackbarRoutineSavedAction => 'Voir';

  @override
  String get formFieldRoutineName => 'Nom de la routine';

  @override
  String get emptyStateAddFirstExercise => 'Ajoutez votre premier exercice.';

  @override
  String setCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ensembles $count',
      one: '1 ensemble',
    );
    return '$_temp0';
  }

  @override
  String get fabAddExercise => 'Ajouter un exercice';

  @override
  String get drawerExerciseCatalog => 'Catalogue d\'exercices';

  @override
  String get lastWorkoutTitle => 'Dernier entraînement';

  @override
  String get repeatButton => 'Répéter';

  @override
  String get weightHistoryTitle => 'Historique du poids';

  @override
  String get hideSummary => 'Masquer le résumé';

  @override
  String get showSummary => 'Afficher le résumé';

  @override
  String get exerciseDataAttribution => 'Données d\'exercice de wger';

  @override
  String get duplicate => 'Double';

  @override
  String deleteRoutineConfirmContent(String routineName) {
    return 'Êtes-vous sûr de vouloir supprimer définitivement la routine « $routineName » ?';
  }

  @override
  String get editPauseTimeTitle => 'Modifier la durée de la pause';

  @override
  String get pauseInSeconds => 'Pause en secondes';

  @override
  String get editPauseTime => 'Modifier la pause';

  @override
  String pauseDuration(int seconds) {
    return '$seconds seconde pause';
  }

  @override
  String maxPauseDuration(int seconds) {
    return 'Pause jusqu\'à $seconds s';
  }

  @override
  String get deleteWorkoutConfirmContent =>
      'Êtes-vous sûr de vouloir supprimer définitivement ce journal d\'entraînement ?';

  @override
  String get removeExercise => 'Supprimer l\'exercice';

  @override
  String get deleteExerciseConfirmTitle => 'Supprimer l\'exercice ?';

  @override
  String deleteExerciseConfirmContent(String exerciseName) {
    return 'Êtes-vous sûr de vouloir supprimer « $exerciseName » de cette routine ?';
  }

  @override
  String get doneButtonLabel => 'Fait';

  @override
  String get setRestTimeButton => 'Définir le temps de repos';

  @override
  String get deleteExerciseButton => 'Supprimer l\'exercice';

  @override
  String get deleteCustomExerciseTitle => 'Supprimer l\'exercice personnalisé';

  @override
  String deleteCustomExerciseBody(String name) {
    return '« $name » sera supprimé définitivement. Cette action est irréversible.';
  }

  @override
  String get deleteCustomExerciseWithLogsWarning =>
      'Cet exercice apparaît dans votre historique d\'entraînements. Vos entrées de journal seront conservées, mais le lien vers l\'exercice sera supprimé.';

  @override
  String get deleteCustomExerciseWithRoutinesWarning =>
      'Cet exercice est utilisé dans une ou plusieurs routines. Il sera supprimé de ces routines.';

  @override
  String get deleteCustomExerciseSuccess => 'Exercice supprimé.';

  @override
  String get restOverLabel => 'La pause est terminée';

  @override
  String get workoutRunningLabel => 'L’entraînement est actif…';

  @override
  String get continueButton => 'Continuer';

  @override
  String get discardButton => 'Jeter';

  @override
  String get workoutStatsTitle => 'Formation (7 jours)';

  @override
  String get workoutsLabel => 'Entraînements';

  @override
  String get durationLabel => 'Durée';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get setsLabel => 'Ensembles';

  @override
  String get muscleSplitLabel => 'Division musculaire';

  @override
  String get snackbar_could_not_open_open_link =>
      'Impossible d\'ouvrir le lien';

  @override
  String get chart_no_data_for_period =>
      'Aucune donnée graphique pour cette période';

  @override
  String get amount_in_milliliters => 'Quantité en millilitres';

  @override
  String get amount_in_grams => 'Quantité en grammes';

  @override
  String get meal_label => 'Repas';

  @override
  String get add_to_water_intake => 'Ajouter à la prise d\'eau';

  @override
  String get create_exercise_screen_title => 'Créer un exercice personnalisé';

  @override
  String get exercise_name_label => 'Nom de l\'exercice';

  @override
  String get category_label => 'Catégorie';

  @override
  String get description_optional_label => 'Description (facultatif)';

  @override
  String get primary_muscles_label => 'Muscles primaires';

  @override
  String get primary_muscles_hint => 'par ex. Poitrine, Triceps';

  @override
  String get secondary_muscles_label => 'Muscles secondaires (facultatif)';

  @override
  String get secondary_muscles_hint => 'par ex. Épaules';

  @override
  String get fluidNameLabel => 'Nom';

  @override
  String get sugarPer100mlLabel => 'Sucre (g/100ml)';

  @override
  String get set_type_normal => 'Normale';

  @override
  String get set_type_warmup => 'Réchauffer';

  @override
  String get set_type_failure => 'Échec';

  @override
  String get set_type_dropset => 'Ensemble de gouttes';

  @override
  String get set_reps_hint => '8-12';

  @override
  String get data_export_button => 'Exporter';

  @override
  String get data_import_button => 'Importer';

  @override
  String get snackbar_button_ok => 'D\'ACCORD';

  @override
  String get measurement_session_detail_view =>
      'Vue détaillée de la session de mesure';

  @override
  String get unit_grams => 'g';

  @override
  String get unit_kcal => 'kilocalories';

  @override
  String get delete_profile_picture_button => 'Supprimer la photo de profil';

  @override
  String get attribution_title => 'Attribution';

  @override
  String get add_liquid_title => 'Ajouter du liquide';

  @override
  String get add_button => 'Ajouter';

  @override
  String get discard_button => 'Jeter';

  @override
  String get continue_workout_button => 'Continuer';

  @override
  String get minimizeWorkoutButton => 'Réduire';

  @override
  String get soon_available_snackbar => 'Cet écran sera bientôt disponible';

  @override
  String get start_button => 'Commencer';

  @override
  String get today_overview_text => 'AUJOURD\'HUI À L\'AFFICHE';

  @override
  String get quick_add_text => 'AJOUT RAPIDE';

  @override
  String get scann_barcode_capslock => 'Scanner le code-barres';

  @override
  String get protocol_today_capslock => 'PROTOCOLE D\'AUJOURD\'HUI';

  @override
  String get my_plans_capslock => 'MES PROJETS';

  @override
  String get overview_capslock => 'APERÇU';

  @override
  String get manage_all_plans => 'Gérer tous les forfaits';

  @override
  String get workoutSectionStart => 'Commencer';

  @override
  String get workoutSectionMyPlans => 'Mes projets';

  @override
  String get emptyStateWorkoutRoutinesCallout =>
      'Créez votre première routine pour suivre vos entraînements en salle de manière structurée.';

  @override
  String get workoutSectionHistoryLibrary => 'Histoire et bibliothèque';

  @override
  String get workoutAllRoutines => 'Toutes les routines';

  @override
  String get workoutEntryWorkouts => 'Entraînements';

  @override
  String get free_training => 'formation gratuite';

  @override
  String get my_consistency => 'MA COHÉRENCE';

  @override
  String get calendar_currently_not_available =>
      'La vue du calendrier sera bientôt disponible.';

  @override
  String get in_depth_analysis => 'ANALYSE APPROFONDIE';

  @override
  String get body_measurements => 'Mesures du corps';

  @override
  String get measurements_description =>
      'Analysez le poids, le pourcentage de graisse corporelle et la circonférence.';

  @override
  String get nutrition_description =>
      'Évaluez les macros, les calories et les tendances.';

  @override
  String get training_analysis => 'Analyse de la formation';

  @override
  String get training_analysis_description =>
      'Suivez le volume, la force et la progression.';

  @override
  String get load_dots => 'chargement...';

  @override
  String get profile_capslock => 'PROFIL';

  @override
  String get settings_capslock => 'PARAMÈTRES';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsUpdateFoodDatabase => 'Mettre à jour les bases de données';

  @override
  String get settingsUpdateFoodDatabaseSubtitle =>
      'Vérifier manuellement les mises à jour des bases de données d\'aliments et d\'exercices.';

  @override
  String get settingsUpdateFoodDatabaseSuccess =>
      'Bases de données mises à jour avec succès.';

  @override
  String settingsUpdateFoodDatabaseError(String error) {
    return 'Erreur lors de la mise à jour des bases de données : $error';
  }

  @override
  String get settingsGuidedTourSectionTitle => 'Visite guidée';

  @override
  String get settingsRestartAppTourTitle =>
      'Redémarrer la visite guidée de l\'application';

  @override
  String get settingsRestartAppTourSubtitle =>
      'Exécutez à nouveau la courte procédure pas à pas dans l’application.';

  @override
  String get my_goals => 'Mes objectifs';

  @override
  String get my_goals_description =>
      'Ajustez les calories, les macros et l\'eau.';

  @override
  String get backup_and_import => 'Sauvegarde et importation de données';

  @override
  String get backup_and_import_description =>
      'Créez des sauvegardes, restaurez et importez des données.';

  @override
  String get feedbackReportSettingsSectionTitle => 'Soutien';

  @override
  String get feedbackReportSettingsEntryTitle => 'Envoyer des commentaires';

  @override
  String get feedbackReportSettingsEntrySubtitle =>
      'Créez un rapport de diagnostic local et choisissez comment le partager.';

  @override
  String get about_and_legal_capslock => 'À PROPOS ET LÉGAL';

  @override
  String get feedbackReportScreenTitle => 'Rapport de rétroaction';

  @override
  String get feedbackReportPrivacyTitle => 'La confidentialité avant tout';

  @override
  String get feedbackReportPrivacyBody =>
      'Ce rapport est généré localement sur votre appareil. Rien n\'est envoyé automatiquement. Seul ce que vous voyez dans l\'aperçu est inclus lorsque vous choisissez de copier, enregistrer, partager ou envoyer par courrier électronique. L\'e-mail ouvre un brouillon à feedback@schotte.me afin que vous puissiez le consulter, le modifier ou l\'annuler avant de l\'envoyer.';

  @override
  String get feedbackReportOptionalNoteTitle => 'Remarque facultative';

  @override
  String get feedbackReportOptionalNoteLabel => 'Votre note (facultatif)';

  @override
  String get feedbackReportOptionalNoteHint =>
      'Décrivez ce qui s\'est passé, le comportement attendu et les étapes à suivre pour reproduire.';

  @override
  String get feedbackReportIncludeSectionTitle => 'Inclure dans le rapport';

  @override
  String get feedbackReportIncludeAdaptiveNutrition =>
      'Diagnostic nutritionnel adaptatif';

  @override
  String get feedbackReportIncludeBackupRestore =>
      'Diagnostic de sauvegarde/restauration';

  @override
  String get feedbackReportIncludeUserNote => 'Remarque utilisateur';

  @override
  String get feedbackReportGeneratePreview => 'Générer un aperçu';

  @override
  String get feedbackReportPreviewTitle => 'Aperçu';

  @override
  String get feedbackReportActionCopy => 'Copie';

  @override
  String get feedbackReportActionSave => 'Sauvegarder';

  @override
  String get feedbackReportActionShare => 'Partager';

  @override
  String get feedbackReportActionEmail => 'E-mail';

  @override
  String get feedbackReportCopied => 'Rapport copié dans le presse-papiers.';

  @override
  String get feedbackReportSavedToTemporaryFile =>
      'Enregistré dans un fichier de rapport temporaire.';

  @override
  String get feedbackReportShareCompleted => 'Feuille de partage ouverte.';

  @override
  String get feedbackReportShareCanceled => 'Partage annulé.';

  @override
  String get feedbackReportEmailOpenFailed =>
      'Impossible d\'ouvrir l\'application de messagerie.';

  @override
  String get feedbackReportEmailSubject =>
      'Rapport de retour d\'information sur Train Libre';

  @override
  String get feedbackReportReportTitle =>
      'Rapport de rétroaction sur Train Libre';

  @override
  String get feedbackReportReportGeneratedAt => 'Généré';

  @override
  String get feedbackReportReportAppVersion => 'Version de l\'application';

  @override
  String get feedbackReportReportBuildNumber => 'Numéro de build';

  @override
  String get feedbackReportReportPlatform => 'Plate-forme';

  @override
  String get feedbackReportReportOsVersion =>
      'Version du système d\'exploitation';

  @override
  String get feedbackReportUnavailable => 'indisponible';

  @override
  String get feedbackReportSectionUserNote => 'Remarque utilisateur';

  @override
  String get feedbackReportSectionAdaptiveNutrition =>
      'Diagnostic nutritionnel adaptatif';

  @override
  String get feedbackReportSectionBackupRestore =>
      'Diagnostic de sauvegarde/restauration';

  @override
  String get attribution_and_license => 'Attribution et licences';

  @override
  String get data_from_off_and_wger => 'Données d’Open Food Facts et wger.';

  @override
  String get app_version => 'Version de l\'application';

  @override
  String get all_measurements => 'TOUTES LES MESURES';

  @override
  String get all_measurements_no_cap => 'Toutes les mesures';

  @override
  String get date_and_time_of_measurement => 'Date et heure de la mesure';

  @override
  String get onbWelcomeTitle => 'Bienvenue chez Train Libre';

  @override
  String get onbWelcomeBody =>
      'Commençons par fixer des objectifs personnels pour guider l’entraînement et la nutrition.';

  @override
  String get onbTrackTitle => 'Suivez tout';

  @override
  String get onbTrackBody =>
      'Enregistrez la nutrition, les entraînements et les mesures, le tout au même endroit.';

  @override
  String get onbPrivacyTitle => 'Hors ligne et confidentialité';

  @override
  String get onbPrivacyBody =>
      'Vos données restent sur l\'appareil. Pas de comptes cloud, pas de synchronisation en arrière-plan.';

  @override
  String get onbFinishTitle => 'Tout est prêt';

  @override
  String get onbFinishBody =>
      'Vous êtes prêt à explorer l\'application. Vous pouvez ajuster les paramètres à tout moment.';

  @override
  String get onbFinishCta => 'Allons-y!';

  @override
  String get onbShowTutorialAgain => 'Afficher à nouveau l\'intégration';

  @override
  String get appTourOfferTitle => 'Faire une visite rapide de l\'application ?';

  @override
  String get appTourOfferBody =>
      'Obtenez une brève présentation des principaux domaines de l’application. Vous pouvez ignorer maintenant et redémarrer plus tard dans Paramètres.';

  @override
  String get appTourOfferStart => 'Commencer la visite';

  @override
  String get appTourOfferSkip => 'Peut-être plus tard';

  @override
  String get appTourSkip => 'Sauter';

  @override
  String get appTourNext => 'Suivant';

  @override
  String get appTourDone => 'Fait';

  @override
  String get appTourStepNavigationTitle => 'Navigation principale';

  @override
  String get appTourStepNavigationBody =>
      'Utilisez les onglets du bas pour vous déplacer entre Journal, Entraînement, Statistiques et Nutrition.';

  @override
  String get appTourStepQuickActionsTitle => 'Actions rapides';

  @override
  String get appTourStepQuickActionsBody =>
      'Appuyez sur le bouton plus pour ajouter rapidement de la nourriture, des liquides, des mesures, des séances d\'entraînement et bien plus encore.';

  @override
  String get appTourStepDiaryTitle => 'Agenda';

  @override
  String get appTourStepDiaryBody =>
      'Le journal est votre aperçu quotidien. Suivez vos repas, votre hydratation, vos suppléments et votre journée en un coup d\'œil.';

  @override
  String get appTourStepWorkoutTitle => 'Entraînement';

  @override
  String get appTourStepWorkoutBody =>
      'L\'entraînement est l\'endroit où vous démarrez des séances, gérez des routines et consultez votre historique d\'entraînement.';

  @override
  String get appTourStepNutritionTitle => 'Nutrition';

  @override
  String get appTourStepNutritionBody =>
      'La nutrition vous aide à planifier vos repas, à revoir vos objectifs et à accéder à des outils tels que des modèles de repas.';

  @override
  String get appTourStepStatisticsTitle => 'Statistiques';

  @override
  String get appTourStepStatisticsBody =>
      'Les statistiques montrent les tendances et les progrès afin que vous puissiez comprendre comment vos données évoluent au fil du temps.';

  @override
  String get appTourRestartTitle => 'Voir la visite guidée';

  @override
  String get appTourRestartSubtitle =>
      'Revoir l\'introduction et les fonctionnalités clés';

  @override
  String get onbSetGoalsCta => 'Fixer des objectifs';

  @override
  String get onbHeaderTitle => 'Tutoriel';

  @override
  String get onbHeaderSkip => 'Sauter';

  @override
  String get onbBack => 'Dos';

  @override
  String get onbNext => 'Suivant';

  @override
  String get onbGuideTitle => 'Comment fonctionne ce tutoriel';

  @override
  String get onbGuideBody =>
      'Faites glisser votre doigt entre les diapositives ou utilisez Suivant. Appuyez sur les boutons de chaque diapositive pour essayer les fonctionnalités. Vous pouvez terminer à tout moment avec Skip.';

  @override
  String get onbCtaOpenNutrition => 'Alimentation ouverte';

  @override
  String get onbCtaLearnMore => 'Apprendre encore plus';

  @override
  String get onbBadgeDone => 'Fait';

  @override
  String get onbTipSetGoals => 'Astuce : ajustez d\'abord les cibles';

  @override
  String get onbTipAddEntry => 'Astuce : ajoutez une entrée aujourd\'hui';

  @override
  String get onbTipLocalControl =>
      'Vous contrôlez toutes les données localement';

  @override
  String get onbTrackHowBody =>
      'Comment enregistrer la nutrition :\n• Ouvrez l\'onglet Aliments.\n• Appuyez sur le bouton +.\n• Recherchez des produits ou scannez un code-barres.\n• Ajustez la portion et le temps.\n• Enregistrez dans votre agenda.';

  @override
  String get onbMeasureTitle => 'Suivre les mesures';

  @override
  String get onbMeasureBody =>
      'Comment ajouter des mesures :\n• Ouvrez l\'onglet Statistiques.\n• Appuyez sur le bouton +.\n• Choisissez une mesure (par exemple, poids, taille, graisse corporelle).\n• Entrez la valeur et l\'heure.\n• Enregistrez dans votre historique.';

  @override
  String get onbTipMeasureToday =>
      'Astuce : ajoutez le poids du jour pour commencer votre graphique';

  @override
  String get onbTrainTitle => 'Entraînez-vous avec des routines';

  @override
  String get onbTrainBody =>
      'Créez une routine et démarrez un entraînement :\n• Ouvrez l\'onglet Train.\n• Appuyez sur Créer une routine pour ajouter des exercices et des séries.\n• Sauvegardez la routine.\n• Appuyez sur Démarrer pour commencer ou utilisez « Démarrer un entraînement vide ».';

  @override
  String get onbTipStartWorkout =>
      'Astuce : démarrez un entraînement vide pour enregistrer une séance rapide';

  @override
  String get unitsSection => 'unités';

  @override
  String get weightUnit => 'Unités de poids';

  @override
  String get lengthUnit => 'unité de longueur';

  @override
  String get comingSoon => 'À venir';

  @override
  String get noFavorites => 'Aucun favori';

  @override
  String get nothingTrackedYet => 'Rien de suivi pour l\'instant';

  @override
  String snackbarBarcodeNotFound(String barcode) {
    return 'Aucun produit trouvé pour le code-barres \"$barcode\".';
  }

  @override
  String get categoryHint => 'par ex. Poitrine, Dos, Jambes...';

  @override
  String get validatorPleaseEnterCategory => 'Veuillez entrer une catégorie.';

  @override
  String get dialogEnterPasswordImport =>
      'Entrez le mot de passe pour importer la sauvegarde';

  @override
  String get dataManagementBackupTitle => 'Sauvegarde des données Train Libre';

  @override
  String get dataManagementBackupDescription =>
      'Sauvegardez ou restaurez toutes les données de votre application. Idéal pour changer d\'appareil.';

  @override
  String get exportEncrypted => 'Exporter crypté';

  @override
  String get dialogPasswordForExport =>
      'Mot de passe pour l\'exportation cryptée';

  @override
  String get snackbarEncryptedBackupShared => 'Sauvegarde cryptée partagée.';

  @override
  String get exportFailed => 'L\'exportation a échoué.';

  @override
  String get csvExportTitle => 'Exportation de données (CSV)';

  @override
  String get csvExportDescription =>
      'Exportez des parties de vos données sous forme de fichier CSV pour les analyser dans d\'autres programmes.';

  @override
  String get snackbarSharingNutrition => 'Partager le journal nutritionnel...';

  @override
  String get snackbarExportFailedNoEntries =>
      'L\'exportation a échoué. Il n\'y a peut-être pas encore d\'entrées.';

  @override
  String get snackbarSharingMeasurements => 'Partage des mesures...';

  @override
  String get snackbarSharingWorkouts =>
      'Partager l\'historique des entraînements...';

  @override
  String get mapExercisesTitle => 'Exercices de cartes';

  @override
  String get mapExercisesDescription =>
      'Mappez les noms inconnus des journaux vers les exercices wger.';

  @override
  String get mapExercisesButton => 'Commencer la cartographie';

  @override
  String get autoBackupTitle => 'Sauvegardes automatiques';

  @override
  String get autoBackupDescription =>
      'Enregistre périodiquement une sauvegarde dans le dossier. Dossier actuel :';

  @override
  String get autoBackupDefaultFolder =>
      'Documents d\'application/sauvegardes (par défaut)';

  @override
  String get autoBackupChooseFolder => 'Choisir un dossier';

  @override
  String get autoBackupCopyPath => 'Copier le chemin';

  @override
  String get autoBackupRunNow => 'Vérifier & exécuter la sauvegarde auto';

  @override
  String get icloudAutoBackupTitle => 'Sauvegarde Auto iCloud';

  @override
  String get icloudAutoBackupDescription =>
      'Synchronise automatiquement votre base de données sur iCloud Drive lorsque l\'application est en arrière-plan. Vos données peuvent être restaurées sur un nouvel appareil ou après une réinstallation.';

  @override
  String get icloudBackupNow => 'Sauvegarder sur iCloud maintenant';

  @override
  String get icloudBackupUploading => 'Téléchargement…';

  @override
  String get icloudBackupSuccess => 'Sauvegarde téléchargée avec succès.';

  @override
  String get icloudBackupFailed =>
      'Échec de la sauvegarde. Vérifiez votre connexion iCloud.';

  @override
  String get autoBackupRequestAccessSubtitle =>
      'Pour sauvegarder automatiquement vos données, Train Libre a besoin d\'accéder à un dossier que vous choisissez. Vos sauvegardes y seront stockées.';

  @override
  String get snackbarAutoBackupSuccess => 'Sauvegarde automatique terminée.';

  @override
  String get snackbarAutoBackupFailed =>
      'La sauvegarde automatique a échoué ou a été annulée.';

  @override
  String get localDataDeletionCardTitle => 'Données d\'application locale';

  @override
  String get localDataDeletionCardDescription =>
      'Supprimez définitivement les données appartenant à l\'utilisateur stockées sur cet appareil et réinitialisez Train Libre à un nouvel état local.';

  @override
  String get deleteAllLocalAppData =>
      'Supprimer toutes les données de l\'application locale';

  @override
  String get localDataDeletionConfirmTitle =>
      'Supprimer toutes les données de l\'application locale ?';

  @override
  String get localDataDeletionConfirmBody =>
      'Cela supprime définitivement les entraînements stockés localement, les journaux nutritionnels, les mesures, les suppléments, les paramètres/état, les analyses mises en cache et les données des applications locales.\n\nCela ne supprime pas les données déjà exportées vers Apple Health ou Health Connect.\n\nCela ne supprime pas les données des fournisseurs externes ni les sources de catalogue public distantes. Les ressources d\'application groupées et les catalogues par défaut requis sont conservés ou recréés afin que l\'application puisse se lancer après la réinitialisation.';

  @override
  String get localDataDeletionTypeDeleteLabel => 'Tapez SUPPR pour confirmer';

  @override
  String get localDataDeletionSuccessTitle => 'Données locales supprimées';

  @override
  String get localDataDeletionSuccessBody =>
      'Train Libre reviendra à son état de configuration initial.';

  @override
  String get localDataDeletionFailed =>
      'Les données locales n\'ont pas pu être supprimées. Veuillez réessayer.';

  @override
  String get noUnknownExercisesFound => 'Aucun exercice inconnu trouvé';

  @override
  String snackbarAutoBackupFolderSet(String path) {
    return 'Ensemble de dossiers de sauvegarde automatique :\n$path';
  }

  @override
  String get snackbarPathCopied => 'Chemin copié';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get involvedMuscles => 'Muscles impliqués';

  @override
  String get primaryLabel => 'Primaire:';

  @override
  String get secondaryLabel => 'Secondaire:';

  @override
  String get noMusclesSpecified => 'Aucun muscle spécifié.';

  @override
  String get frontLabel => 'Devant';

  @override
  String get backLabel => 'Dos';

  @override
  String get noSelection => 'Aucune sélection';

  @override
  String get selectButton => 'Sélectionner';

  @override
  String get applyingChanges => 'Application des modifications...';

  @override
  String get applyMapping => 'Appliquer le mappage';

  @override
  String get mappingSuggestions => 'Suggestions';

  @override
  String get mappingSuggestionsEmpty => 'Aucun exercice correspondant trouvé';

  @override
  String get personalData => 'Données personnelles';

  @override
  String get personalDataCL => 'DONNÉES PERSONNELLES';

  @override
  String get macroDistribution => 'Distribution des macronutriments';

  @override
  String get dialogFinishWorkoutBody =>
      'Êtes-vous sûr de vouloir terminer cet entraînement ?';

  @override
  String get attributionText =>
      'Cette application utilise des données provenant de sources externes :\n\n● Données d\'exercice et images de wger (wger.de), sous licence CC-BY-SA 4.0.\n\n● Base de données alimentaire d\'Open Food Facts (openfoodfacts.org), disponible sous licence Open Database (ODbL).';

  @override
  String get errorRoutineNotFound => 'Routine introuvable';

  @override
  String get workoutHistoryEmptyTitle => 'Votre historique est vide';

  @override
  String get workoutSummaryTitle => 'Entraînement terminé';

  @override
  String get workoutSummaryExerciseOverview => 'Aperçu de l\'exercice';

  @override
  String get nutritionDiary => 'Agenda';

  @override
  String get detailedNutrientGoals => 'Nutriments détaillés';

  @override
  String get detailedNutrientGoalsCL => 'NUTRIMENTS DÉTAILLÉS';

  @override
  String get supplementTrackerTitle => 'Suivi des suppléments';

  @override
  String get supplementTrackerDescription =>
      'Suivez les objectifs, les limites et les apports.';

  @override
  String get createSupplementTitle => 'Créer un supplément';

  @override
  String get supplementNameLabel => 'Nom du supplément';

  @override
  String get defaultDoseLabel => 'Dose par défaut';

  @override
  String get unitLabel => 'Unité';

  @override
  String get dailyGoalLabel => 'Objectif quotidien (facultatif)';

  @override
  String get dailyLimitLabel => 'Limite quotidienne (facultatif)';

  @override
  String get dailyProgressTitle => 'Progrès quotidien';

  @override
  String get todaysLogTitle => 'Journal du jour';

  @override
  String get logIntakeTitle => 'Entrée de journal';

  @override
  String get emptySupplementGoals =>
      'Fixez des objectifs ou des limites pour les suppléments pour voir vos progrès ici.';

  @override
  String get emptySupplementLogs =>
      'Aucune prise enregistrée pour aujourd\'hui pour l\'instant.';

  @override
  String get doseLabel => 'Dose';

  @override
  String get settingsDescription => 'Thème, unités, données et plus';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Lumière';

  @override
  String get themeDark => 'Sombre';

  @override
  String get caffeinePrompt => 'Caféine (facultatif)';

  @override
  String get caffeineUnit => 'mg pour 100 ml';

  @override
  String get profile => 'Profil';

  @override
  String get measurementWeightCapslock => 'POIDS CORPOREL';

  @override
  String get diary => 'Agenda';

  @override
  String get analysis => 'Analyse';

  @override
  String get yesterday => 'Hier';

  @override
  String get dayBeforeYesterday => 'Il y a deux jours';

  @override
  String get statistics => 'Statistiques';

  @override
  String get workout => 'Entraînement';

  @override
  String get addFoodTitle => 'ajouter de la nourriture';

  @override
  String get nutritionExplorerTitle => 'Explorateur de nutrition';

  @override
  String get myMeals => 'Mes recettes';

  @override
  String get myMealsCL => 'MES RECETTES';

  @override
  String get nutritionSectionTodayInFocus => 'Aujourd’hui à l’honneur';

  @override
  String get nutritionSectionMyMeals => 'Mes recettes';

  @override
  String get emptyStateNutritionRecipesCallout =>
      'Créez votre première recette pour enregistrer rapidement vos repas fréquents.';

  @override
  String get nutritionSectionToolsAndLibrary => 'Outils et bibliothèque';

  @override
  String get supplement_caffeine => 'Caféine';

  @override
  String get supplement_creatine_monohydrate => 'Créatine Monohydrate';

  @override
  String get manageSupplementsTitle => 'Gérer les suppléments';

  @override
  String get deleted => 'supprimé';

  @override
  String get operationNotAllowed => 'Cette opération n\'est pas autorisée';

  @override
  String get emptySupplements => 'Aucun supplément disponible';

  @override
  String get undo => 'Défaire';

  @override
  String get deleteSupplementConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce supplément ? Toutes les données historiques seront perdues.\n\nAstuce : Vous pouvez simplement supprimer le suivi en modifiant le supplément à la place.';

  @override
  String get editSupplementLogTitle => 'Modifier l\'entrée';

  @override
  String get deleteSupplementLogConfirm =>
      'Voulez-vous vraiment supprimer cette entrée ?';

  @override
  String get fieldRequired => 'Requis';

  @override
  String get unitNotSupported => 'Unité non prise en charge.';

  @override
  String get caffeineUnitLocked => 'Pour la caféine l’unité est fixe : mg.';

  @override
  String get caffeineMustBeMg => 'La caféine doit être enregistrée en mg.';

  @override
  String get tabCatalogSearch => 'Catalogue';

  @override
  String get tabMeals => 'Recettes';

  @override
  String get emptyCategory => 'Aucune entrée';

  @override
  String get searchSectionBase => 'Aliments de base';

  @override
  String get searchSectionOther => 'Autres résultats';

  @override
  String get mealsComingSoonTitle => 'Recettes (à venir)';

  @override
  String get mealsComingSoonBody =>
      'Bientôt, vous pourrez créer vos propres recettes à partir de plusieurs aliments.';

  @override
  String get mealsEmptyTitle => 'Aucun modèle de recette enregistré';

  @override
  String get mealsEmptyBody =>
      'Créez des recettes pour enregistrer rapidement plusieurs aliments à la fois.';

  @override
  String get mealsEmptyBodyWithShortcut =>
      'Dans le journal, utilisez l\'option « Enregistrer comme recette » sous votre petit-déjeuner ou votre dîner pour enregistrer les combinaisons alimentaires courantes comme modèle rapide.';

  @override
  String get mealsCreateManually => 'Créer une recette manuellement';

  @override
  String get saveMealTemplateShortcut => 'Enregistrer comme recette';

  @override
  String get mealsCreate => 'Créer une recette';

  @override
  String get mealsEdit => 'Modifier la recette';

  @override
  String get mealsDelete => 'Supprimer la recette';

  @override
  String get mealsAddToDiary => 'Ajouter de la nourriture';

  @override
  String get mealNameLabel => 'Nom de la recette';

  @override
  String get mealNotesLabel => 'Remarques';

  @override
  String get mealIngredientsTitle => 'Ingrédients';

  @override
  String get mealAddIngredient => 'Ajouter un ingrédient';

  @override
  String get mealIngredientAmountLabel => 'Montant';

  @override
  String get mealDeleteConfirmTitle => 'Supprimer la recette';

  @override
  String mealDeleteConfirmBody(Object name) {
    return 'Êtes-vous sûr de vouloir supprimer la recette « $name » ? Tous ses ingrédients seront également supprimés.';
  }

  @override
  String mealAddedToDiary(Object name) {
    return 'La recette \'$name\' a été ajoutée à votre agenda.';
  }

  @override
  String get mealSaved => 'Recette sauvée.';

  @override
  String get mealDeleted => 'Recette supprimée.';

  @override
  String get confirm => 'Confirmer';

  @override
  String get addMealToDiaryTitle => 'Ajouter au journal';

  @override
  String get mealTypeLabel => 'Recette';

  @override
  String get amountLabel => 'Montant';

  @override
  String get mealAddedToDiarySuccess => 'Recette ajoutée au journal';

  @override
  String get error => 'Erreur';

  @override
  String get mealsViewTitle => 'repasViewTitle';

  @override
  String get noNotes => 'Aucune note';

  @override
  String get ingredientsCapsLock => 'INGRÉDIENTS';

  @override
  String get nutritionSectionLabel => 'FAITS NUTRITIONNELS';

  @override
  String get nutritionCalculatedForCurrentAmounts =>
      'pour les quantités actuelles';

  @override
  String get startCapsLock => 'COMMENCER';

  @override
  String get nutritionHubSubtitle =>
      'Découvrez des informations, suivez vos repas et planifiez votre alimentation ici bientôt.';

  @override
  String get nutritionHubTitle => 'Nutrition';

  @override
  String get nutrition => 'Nutrition';

  @override
  String get changeSetTypTitle => 'Modifier le type d\'ensemble';

  @override
  String get settingsVisualStyleTitle => 'Style visuel';

  @override
  String get settingsVisualStyleStandard => 'Verre dépoli';

  @override
  String get settingsVisualStyleLiquid => 'Verre liquide (fluide)';

  @override
  String get settingsVisualStyleLiquidDesc =>
      'Éléments d\'interface utilisateur arrondis et flottants';

  @override
  String get settingsMaterialColorsTitle => 'Couleurs des matériaux';

  @override
  String get settingsMaterialColorsSubtitle =>
      'Utilisez les couleurs dynamiques du système (Material You) au lieu de l\'accent de la marque Train Libre';

  @override
  String get settingsFoodDbSectionTitle => 'Base de données alimentaire';

  @override
  String get settingsFoodDbRegionTitle => 'Région de la base de données';

  @override
  String get settingsFoodDbRegionSubtitle =>
      'Sélectionnez la région du catalogue de produits Open Food Facts utilisée.';

  @override
  String get settingsFoodDbRegionCurrent => 'Région actuelle';

  @override
  String get settingsFoodDbRegionDialogTitle =>
      'Choisir la région de la base de données';

  @override
  String get settingsFoodDbRegionDialogSubtitle =>
      'Cela modifie la source du catalogue Open Food Facts pour la recherche.';

  @override
  String get settingsFoodDbRegionSearchPlaceholder =>
      'Rechercher une région...';

  @override
  String get settingsFoodDbRegionNoResults => 'Aucune région trouvée';

  @override
  String get settingsFoodDbRegionIssueHint =>
      'Si votre pays ne figure pas encore dans la liste, n\'hésitez pas à ouvrir un ticket GitHub et à demander de l\'aide.';

  @override
  String get settingsFoodDbRegionGermany => 'Allemagne (DE)';

  @override
  String get settingsFoodDbRegionSwitzerland => 'Suisse (CH)';

  @override
  String get settingsFoodDbRegionUnitedStates => 'États-Unis (US)';

  @override
  String get settingsFoodDbRegionFrance => 'France (FR)';

  @override
  String get settingsFoodDbRegionItaly => 'Italie (IT)';

  @override
  String get settingsFoodDbRegionJapan => 'Japon (JP)';

  @override
  String get settingsFoodDbRegionAustria => 'Autriche (AT)';

  @override
  String get settingsColorfulMacroBadgesTitle => 'Insignes macro colorés';

  @override
  String get settingsColorfulMacroBadgesSubtitle =>
      'Utilise également la conception du badge à code couleur issue de la vérification par l\'IA dans le journal.';

  @override
  String get settingsFoodDbRegionUnitedKingdom => 'Royaume-Uni (UK)';

  @override
  String settingsFoodDbRegionChanged(String region) {
    return 'Région de la base de données définie sur $region. Les modifications s\'appliqueront lors du prochain cycle d\'importation.';
  }

  @override
  String get searchBaseFoodHint => 'Rechercher des aliments de base';

  @override
  String get searchNoHits => 'Aucun coup sûr.';

  @override
  String get onbSubtitleWelcome =>
      'Votre outil central pour la forme physique, la nutrition et le progrès.';

  @override
  String get onbBodyWelcome =>
      'Nous vous aidons à définir et suivre vos objectifs. Enregistrez efficacement vos entraînements, votre nutrition, vos suppléments et vos mensurations.';

  @override
  String get onbBodyNutritionVisual =>
      'Enregistrez vos repas en quelques clics. Gardez un œil sur les calories, les macros et l\'eau pour suivre sans effort votre objectif.';

  @override
  String get onbBodyMeasurementsVisual =>
      'Visualisez vos progrès. Le tableau des poids et des circonférences rend votre réussite visible et vous maintient motivé.';

  @override
  String get onbBodyWorkoutVisual =>
      'Créez des routines et démarrez votre entraînement en quelques secondes. Enregistrez les séries, les poids et les repos pour une progression maximale.';

  @override
  String get onbTitleAppLayout => 'Navigation et ajout rapide';

  @override
  String get onbBodyAppLayout =>
      'La barre inférieure permet de basculer rapidement entre les zones. Utilisez le gros bouton [+] pour tout enregistrer instantanément.';

  @override
  String get dataHubTitle => 'Centre de données';

  @override
  String get resumeButton => 'CV';

  @override
  String get onboardingWelcomeTitle => 'Bienvenue chez Train Libre';

  @override
  String get onboardingWelcomeSubtitle =>
      'Configurons votre profil pour obtenir les meilleurs résultats.';

  @override
  String get onboardingMissionTitle => 'Notre Mission';

  @override
  String get onboardingMissionBody =>
      'Train Libre est destiné aux bodybuilders naturels passionnés qui exigent des progrès basés sur la science et les données.';

  @override
  String get onboardingFeatureWorkoutTitle => 'Suivi des entraînements';

  @override
  String get onboardingFeatureWorkoutBody =>
      'Enregistrez vos séries (RIR/RPE) et suivez votre récupération musculaire.';

  @override
  String get onboardingFeatureTdeeTitle => 'TDEE adaptatif';

  @override
  String get onboardingFeatureTdeeBody =>
      'Un filtre de Kalman intégré calcule votre dépense calorique réelle.';

  @override
  String get onboardingFeatureNutritionTitle => 'Nutrition et eau';

  @override
  String get onboardingFeatureNutritionBody =>
      'Suivez les macros, l\'eau et utilisez la reconnaissance d\'images IA optionnelle.';

  @override
  String get onboardingFeaturePrivacyTitle => '100% privé et local';

  @override
  String get onboardingFeaturePrivacyBody =>
      'Aucun compte, aucun cloud obligatoire. Vos données vous appartiennent.';

  @override
  String get onboardingSettingsHint =>
      'Tous les réglages peuvent être modifiés plus tard à tout moment dans les paramètres.';

  @override
  String get adaptiveRatePerWeekLabel => 'Taux cible hebdomadaire';

  @override
  String get customTargetRateOption => 'Personnalisé';

  @override
  String get customTargetRateDialogTitle => 'Définir l\'objectif personnalisé';

  @override
  String get onboardingNameTitle => 'Quel est ton nom?';

  @override
  String get onboardingNameLabel => 'Votre nom';

  @override
  String get onboardingNameError => 'Veuillez entrer votre nom';

  @override
  String get onboardingDobTitle => 'Quand êtes-vous né?';

  @override
  String get onboardingDobLabel => 'Date de naissance';

  @override
  String get onboardingDobError =>
      'Veuillez sélectionner votre date de naissance';

  @override
  String get onboardingWeightTitle => 'Poids actuel';

  @override
  String get onboardingWeightLabel => 'Poids';

  @override
  String get onboardingWeightError => 'Veuillez entrer un poids valide';

  @override
  String get onboardingGoalsTitle => 'Vos objectifs nutritionnels';

  @override
  String get onboardingGoalsSubtitle =>
      'Vous pourrez les modifier ultérieurement dans les paramètres.';

  @override
  String get onboardingGoalCalories => 'Calories quotidiennes (kcal)';

  @override
  String get onboardingGoalProtein => 'Protéine (g)';

  @override
  String get onboardingGoalCarbs => 'Glucides (g)';

  @override
  String get onboardingGoalFat => 'Graisse (g)';

  @override
  String get onboardingGoalWater => 'Eau';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingBack => 'Dos';

  @override
  String get onboardingFinish => 'Commencer le suivi';

  @override
  String get onboardingAiHealthTitle => 'IA et santé';

  @override
  String get onboardingAiHealthSubtitle =>
      'Configuration facultative : configurez la reconnaissance des repas par IA avec BYOK (Bring Your Own Key) et choisissez les données de santé que Train Libre peut lire.';

  @override
  String get onboardingOpenSettings => 'Ouvrir';

  @override
  String get onboardingUnitSystemTitle => 'Choisissez votre système d\'unités';

  @override
  String get onboardingUnitSystemSubtitle =>
      'Vous pourrez modifier cela ultérieurement dans Paramètres.';

  @override
  String get onboardingUnitMetric => 'Métrique';

  @override
  String get onboardingUnitMetricSubtitle => 'kg, cm, ml';

  @override
  String get onboardingUnitImperial => 'Impérial';

  @override
  String get onboardingUnitImperialSubtitle => 'livres, po, fl oz';

  @override
  String get onboardingHeightLabel => 'Hauteur';

  @override
  String get onboardingGenderLabel => 'Genre';

  @override
  String get onboardingBioDataInfo =>
      'Votre âge et votre sexe biologique déterminent les fenêtres de récupération de base de votre modèle de récupération musculaire et alimentent les algorithmes de votre Sleep Health Engine.';

  @override
  String get onboardingFieldCannotBeEmpty => 'Ce champ ne peut pas être vide.';

  @override
  String get onboardingPhysiologicalRangeWarning =>
      'Attention : Cette valeur est en dehors de la plage physiologique attendue. Nos analyses en sciences du sport et nos moteurs heuristiques ne sont pas calibrés pour des mesures extrêmes. Si cette valeur est intentionnelle, cliquez à nouveau sur \'Suivant\' pour continuer malgré tout.';

  @override
  String get onboardingMeasurementsTitle => 'Mesures et référence';

  @override
  String get onboardingMeasurementsSubtitle =>
      'Définissez votre référence actuelle pour la recommandation adaptative.';

  @override
  String get onboardingMeasurementsDisclaimer =>
      'Vous pouvez saisir et journaliser votre poids, votre masse grasse et d\'autres mesures à tout moment dans le tableau de bord.';

  @override
  String onboardingWaterNeedLabel(String unit) {
    return 'Besoin en eau ($unit)';
  }

  @override
  String get genderMale => 'Mâle';

  @override
  String get genderFemale => 'Femelle';

  @override
  String get genderDiverse => 'Divers';

  @override
  String get vegan => 'Végétalien';

  @override
  String get vegetarian => 'Végétarien';

  @override
  String get ingredients => 'Ingrédients';

  @override
  String get aiSettingsTitle => 'Reconnaissance de repas par IA';

  @override
  String get aiSettingsDescription =>
      'Configurer la détection de repas assistée par IA.';

  @override
  String get aiProviderSection => 'Fournisseur d\'IA';

  @override
  String get aiProviderLabel => 'Fournisseur';

  @override
  String get aiApiKeySection => 'Clé API';

  @override
  String get aiApiKeyLabel => 'Clé API';

  @override
  String get aiApiKeyHint => 'Collez votre clé API ici';

  @override
  String get aiSaveKey => 'Enregistrer la clé';

  @override
  String get aiTestConnection => 'Test';

  @override
  String get aiTestSuccess => 'Connexion réussie !';

  @override
  String get aiKeySaved => 'Clé API enregistrée en toute sécurité.';

  @override
  String get aiPrivacySection => 'Confidentialité';

  @override
  String get aiPrivacyDisclosure =>
      'Les images, le texte et les invites générées sont envoyés au fournisseur d\'IA sélectionné uniquement lorsque vous utilisez une action d\'IA. La rétention et le traitement du fournisseur suivent les conditions de ce fournisseur. Votre clé API est stockée cryptée sur cet appareil uniquement.';

  @override
  String get aiMealCapture => 'Repas IA';

  @override
  String get aiCaptureTitle => 'Capture de repas IA';

  @override
  String get aiCaptureTabPhoto => 'Photo';

  @override
  String get aiCaptureTabText => 'Texte';

  @override
  String get aiCapturePhotoHint =>
      'Prenez ou sélectionnez jusqu\'à 4 photos de votre repas.';

  @override
  String get aiCaptureTextHint =>
      'Décrivez votre repas (par exemple \"Poulet grillé avec riz et salade\")...';

  @override
  String get aiAnalyzeButton => 'Analyser';

  @override
  String get aiAnalyzing => 'Analyser votre repas...';

  @override
  String get aiReviewTitle => 'Suggestions de révision';

  @override
  String aiReviewFoundItems(int count) {
    return 'L\'IA a trouvé $count éléments';
  }

  @override
  String get aiReviewNoMatch =>
      'Aucune correspondance – appuyez pour rechercher';

  @override
  String aiReviewUncertain(int percent) {
    return 'Incertain ($percent%)';
  }

  @override
  String get aiReviewConfidence => 'Confiance';

  @override
  String get aiReviewAddItem => 'Ajouter un article manuellement';

  @override
  String get aiReviewReplaceItem => 'Remplacer l\'élément';

  @override
  String get aiReviewSaveToDiary => 'Enregistrer dans le journal';

  @override
  String get aiReviewFeedbackHint => 'Décrivez ce que l\'IA s\'est trompé...';

  @override
  String get aiReviewRetryButton => 'Réessayez avec commentaires';

  @override
  String get aiReviewFeedbackSection => 'Correction';

  @override
  String get aiErrorNoKey =>
      'Aucune clé API configurée. Veuillez en définir un dans Paramètres → AI Meal Capture.';

  @override
  String get aiErrorNetwork =>
      'Erreur réseau. Veuillez vérifier votre connexion et réessayer.';

  @override
  String get aiErrorAuth =>
      'L\'authentification a échoué. Veuillez vérifier votre clé API.';

  @override
  String get aiErrorParse =>
      'Impossible de comprendre la réponse de l\'IA. Veuillez réessayer.';

  @override
  String get aiErrorRateLimit =>
      'Trop de demandes. Veuillez patienter un moment.';

  @override
  String get aiEnableTitle => 'Activer les fonctionnalités d\'IA';

  @override
  String get aiEnableSubtitle =>
      'Permet l\'utilisation de l\'IA pour la reconnaissance des repas. La désactivation de cette option masque tous les boutons AI de l\'application.';

  @override
  String get aiCustomInstructionsTitle => 'Instructions mondiales sur l\'IA';

  @override
  String get aiCustomInstructionsSubtitle =>
      'Donnez à l\'IA des règles fixes (par exemple, allergies, aliments interdits comme « pas de bols » ou intolérances) à suivre à chaque capture.';

  @override
  String get aiValidationNoMatchedItemsSaveYet =>
      'Aucun élément correspondant ne peut encore être enregistré.';

  @override
  String get aiValidationNoMatchedIngredientsSaveYet =>
      'Aucun ingrédient correspondant ne peut encore être enregistré.';

  @override
  String get aiValidationSomeItemsNeedReviewTitle =>
      'Certains éléments doivent être révisés';

  @override
  String get aiValidationSomeIngredientsNeedReviewTitle =>
      'Certains ingrédients doivent être révisés';

  @override
  String get aiValidationSaveMatchedItemsButton =>
      'Enregistrer les éléments correspondants';

  @override
  String get aiValidationSaveMatchedIngredientsButton =>
      'Enregistrez les ingrédients correspondants';

  @override
  String get aiValidationValidationPassedTitle => 'Validation réussie';

  @override
  String get aiValidationReviewSuggestedTitle => 'Avis suggéré';

  @override
  String get aiValidationMacroFitValidatedTitle => 'Ajustement macro validé';

  @override
  String get aiValidationNeedsReviewTitle => 'Besoin d\'un examen';

  @override
  String get aiValidationRepairLimitReachedReview =>
      'Limite de réparation automatique atteinte. Veuillez vérifier avant d\'enregistrer.';

  @override
  String get aiValidationRecentMealContextIncluded =>
      'Le contexte du repas récent a été inclus.';

  @override
  String get aiValidationGeneratedWithoutRecentMealHistory =>
      'Généré sans historique de repas récent.';

  @override
  String get aiValidationApiKeyRequiredTitle => 'Clé API requise';

  @override
  String aiValidationScoreLabel(int score) {
    return 'Note : $score/100';
  }

  @override
  String aiValidationDeltaSummary(
      int kcalDelta, int proteinDelta, int carbsDelta, int fatDelta) {
    return 'Delta : $kcalDelta kcal · ${proteinDelta}g Protéines · ${carbsDelta}g Glucides · ${fatDelta}g Lipides';
  }

  @override
  String aiValidationPartialSaveItemsMessage(
      int unmatchedCount, int matchedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unmatchedCount,
      locale: localeName,
      other:
          'Les elements $unmatchedCount n\'ont pas de correspondance dans la base de données locale et ne seront pas enregistrés.',
      one:
          '1 element n\'a pas de correspondance dans la base de donnees locale et ne sera pas enregistre.',
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
          'Les ingredients $unmatchedCount n\'ont pas de correspondance dans la base de données locale et ne seront pas enregistrés.',
      one:
          '1 ingredient n\'a pas de correspondance dans la base de donnees locale et ne sera pas enregistre.',
    );
    return '$_temp0';
  }

  @override
  String get aiValidationEmptyItemName =>
      'Un article n\'a pas de nom d\'aliment.';

  @override
  String aiValidationDuplicateItemMerged(String name) {
    return 'Les entrées « $name » en double ont été fusionnées avant la validation.';
  }

  @override
  String get aiValidationInvalidQuantity =>
      'La quantité doit être supérieure à 0g.';

  @override
  String get aiValidationTinyQuantity =>
      'La quantité est très petite ; vérifiez la quantité en grammes.';

  @override
  String get aiValidationExtremeQuantity =>
      'La quantité est invraisemblablement élevée pour un repas.';

  @override
  String get aiValidationLargeQuantity =>
      'La quantité est inhabituellement importante ; vérifiez la quantité en grammes.';

  @override
  String get aiValidationLowAiConfidence =>
      'La confiance de l’IA est faible pour cet élément.';

  @override
  String get aiValidationUnmatchedItem =>
      'Aucune correspondance avec la base de données locale n\'a été trouvée.';

  @override
  String get aiValidationWeakDbMatch =>
      'La correspondance avec la base de données locale est faible.';

  @override
  String get aiValidationPartialDbMatch =>
      'La correspondance avec la base de données locale est partielle.';

  @override
  String get aiValidationAmbiguousDbMatch =>
      'Plusieurs correspondances de bases de données locales semblent tout aussi plausibles.';

  @override
  String get aiValidationStateMismatch =>
      'L\'état de l\'élément AI peut ne pas correspondre à l\'entrée de la base de données.';

  @override
  String get aiValidationZeroNutritionMatch =>
      'L’entrée de base de données correspondante ne contient aucune donnée nutritionnelle utilisable.';

  @override
  String get aiValidationImplausibleFoodDensity =>
      'Les aliments assortis contiennent des calories inhabituellement élevées pour 100 g.';

  @override
  String get aiValidationMacroEnergyMismatch =>
      'Les macros alimentaires assorties ne correspondent pas bien aux kcal.';

  @override
  String get aiValidationImplausibleItemNutrition =>
      'La nutrition pour cette quantité est inhabituellement élevée.';

  @override
  String get aiValidationEmptyMeal => 'L’IA n’a renvoyé aucun repas.';

  @override
  String get aiValidationAllItemsUnmatched =>
      'Aucun article n\'a pu être associé à la base de données sur les aliments locaux.';

  @override
  String aiValidationPartialUnmatchedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Les elements $count ne peuvent pas être enregistrés tant qu\'ils n\'ont pas été mis en correspondance.',
      one:
          '1 element ne peut pas etre enregistre tant qu\'il n\'a pas ete associe.',
    );
    return '$_temp0';
  }

  @override
  String get aiValidationZeroTotalKcal =>
      'Les éléments correspondants produisent 0 kcal.';

  @override
  String get aiValidationCaptureTotalKcalExtreme =>
      'Le total de kcal est incroyablement élevé pour un repas capturé.';

  @override
  String get aiValidationCaptureTotalKcalHigh =>
      'Le kcal total est inhabituellement élevé ; passer en revue des parties.';

  @override
  String get aiValidationMacroTotalExtreme =>
      'Le total des macros est incroyablement élevé.';

  @override
  String get aiValidationMacroTotalHigh =>
      'Le total des macros est inhabituellement élevé ; passer en revue des parties.';

  @override
  String aiValidationTargetKcalMismatch(int delta) {
    return 'Les calories manquent l\'objectif de $delta kcal.';
  }

  @override
  String aiValidationTargetProteinMismatch(int delta) {
    return 'La protéine manque la cible de $delta g.';
  }

  @override
  String aiValidationTargetCarbsMismatch(int delta) {
    return 'Les glucides manquent la cible de $delta g.';
  }

  @override
  String aiValidationTargetFatMismatch(int delta) {
    return 'Fat manque la cible de ${delta}g.';
  }

  @override
  String aiValidationUnknownIssue(String code) {
    return 'Problème de validation : $code';
  }

  @override
  String get currentlyTracking => 'Actuellement';

  @override
  String get currentlyTrackingDesc => 'Afficher dans le hub de suivi quotidien';

  @override
  String get filter3Months => '3 mois';

  @override
  String get filter6Months => '6 mois';

  @override
  String get sectionConsistency => 'Cohérence et fréquence';

  @override
  String get metricsWorkoutsWeek => 'Entraînements (semaine)';

  @override
  String get metricsCurrentStreak => 'Série actuelle';

  @override
  String get metricsActiveWeeks => 'semaines d\'activité';

  @override
  String get placeholderCalendarHeatmap =>
      'Visuel de la carte thermique du calendrier';

  @override
  String get consistencyTrackerTitle => 'Suivi de cohérence';

  @override
  String get consistencyTrackerComingSoon =>
      'Suivi de la cohérence et des habitudes (à venir)';

  @override
  String get sectionMuscleVolume => 'Groupes musculaires et volume';

  @override
  String get metricsTopTrained => 'Les mieux formés';

  @override
  String get metricsMostNeglected => 'Les plus négligés';

  @override
  String get placeholderMuscleHeatmap =>
      'Visuel de la carte thermique musculaire';

  @override
  String get muscleAnalyticsTitle => 'Analyse des groupes musculaires';

  @override
  String get muscleAnalyticsComingSoon =>
      'Volume musculaire et cartes thermiques (à venir)';

  @override
  String get sectionPerformance => 'Performances et relations publiques';

  @override
  String get metricsRecentPrs => 'PR récents';

  @override
  String get metricsVolumeLifted => 'Volume augmenté';

  @override
  String get metricsMostImproved => 'Le plus amélioré';

  @override
  String get exerciseAnalyticsTitle => 'Analyse des exercices';

  @override
  String get exerciseAnalyticsSubtitle =>
      'Rechercher et analyser des exercices spécifiques';

  @override
  String get prDashboardTitle => 'Tableau de bord des relations publiques';

  @override
  String get prDashboardComingSoon => 'Records et progrès (à venir)';

  @override
  String get exerciseAnalyticsComingSoon =>
      'Recherche d\'exercices et tendances spécifiques (à venir)';

  @override
  String get sectionRecovery => 'Récupération';

  @override
  String get metricsMuscleReadiness => 'Préparation musculaire';

  @override
  String get recoveryTrackerTitle => 'Suivi de récupération';

  @override
  String get recoveryTrackerComingSoon =>
      'Préparation musculaire et fatigue (à venir)';

  @override
  String get recoveryOverallMostlyRecovered => 'En grande partie récupéré';

  @override
  String get recoveryOverallMixed => 'État de récupération mixte';

  @override
  String get recoveryOverallSeveralRecovering =>
      'Plusieurs groupes musculaires encore en convalescence';

  @override
  String get recoveryOverallInsufficientData =>
      'Pas encore assez de données pour obtenir des informations sur la récupération';

  @override
  String recoveryHubCountsSummary(int recovering, int ready, int fresh) {
    return 'Récupération : $recovering Prêt : $ready Frais : $fresh';
  }

  @override
  String get recoveryHubNoDataSummary =>
      'Continuez à enregistrer vos entraînements pour débloquer des informations sur la récupération.';

  @override
  String get recoveryByMuscleTitle => 'Récupération par Muscle';

  @override
  String get recoveryStateRecovering => 'Récupération';

  @override
  String get recoveryStateReady => 'Prêt';

  @override
  String get recoveryStateFresh => 'Frais';

  @override
  String get recoveryStateUnknown => 'Inconnu';

  @override
  String recoveryLastLoadedHours(int hours) {
    return 'Dernier chargement significatif : il y a $hours h';
  }

  @override
  String get recoveryFatigueContextHigh =>
      'Contexte de fatigue : fatigue de séance élevée';

  @override
  String get recoveryFatigueContextBaseline =>
      'Contexte de fatigue : fatigue de base de la séance';

  @override
  String recoveryExplanationWithHighFatigue(String muscle, int hours) {
    return '$muscle : dernière charge significative il y a $hours h, avec une fatigue de session élevée.';
  }

  @override
  String recoveryExplanationBasic(String muscle, int hours) {
    return '$muscle : dernière charge significative il y a $hours h.';
  }

  @override
  String get recoveryHeuristicDisclaimer =>
      'Il s’agit d’une heuristique conservatrice basée sur des efforts de chargement et de session importants récents. Il ne s’agit pas d’une mesure de récupération médicale.';

  @override
  String get recoveryReadinessLabel => 'Préparation';

  @override
  String recoveryRecentLoad(String sets) {
    return 'Dernier chargement : $sets ensembles équivalents';
  }

  @override
  String recoveryLastLoadPressure(String level) {
    return 'Dernière pression de charge : $level';
  }

  @override
  String get recoveryPressureLow => 'faible';

  @override
  String get recoveryPressureModerate => 'modéré';

  @override
  String get recoveryPressureHigh => 'haut';

  @override
  String get recoveryPressureVeryHigh => 'très élevé';

  @override
  String recoveryCurrentWindow(int recoveringUpper, int readyUpper) {
    return 'Fenêtre actuelle : récupération jusqu\'à environ $recoveringUpper h, prêt jusqu\'à environ $readyUpper h.';
  }

  @override
  String recoveryWindowHeuristic(int from, int to) {
    return 'Fenêtre actuelle : récupération jusqu\'à environ $from h, prêt jusqu\'à environ $to h.';
  }

  @override
  String get recoveryRadarHeuristicCaption =>
      'Aperçu radar de l\'état de préparation actuel par muscle. Les badges de statut restent le signal principal.';

  @override
  String get recoveryNoDataBody =>
      'Une charge d’entraînement suffisamment significative n’a pas encore été enregistrée pour estimer la récupération musculaire.';

  @override
  String get sectionBodyNutrition => 'Corps & Nutrition';

  @override
  String get statisticsSectionTraining => 'Entraînement';

  @override
  String get statisticsSectionBody => 'Corps';

  @override
  String get statisticsEnableStepTrackingHint =>
      'Activer le suivi des étapes dans les paramètres';

  @override
  String get statisticsNoStepDataYet => 'Aucune donnée de pas pour l\'instant';

  @override
  String get statisticsTotalSteps => 'Nombre total d\'étapes';

  @override
  String get statisticsLast7Days => '7 derniers jours';

  @override
  String get statisticsLast30Days => '30 derniers jours';

  @override
  String get statisticsLast3Months => '3 derniers mois';

  @override
  String get statisticsLast6Months => '6 derniers mois';

  @override
  String get metricsCurrentWeight => 'Poids actuel';

  @override
  String get metricsAvgCalories => 'Moy. Calories';

  @override
  String get placeholderWeightTrend =>
      'Graphique linéaire de tendance du poids';

  @override
  String get exerciseAnalyticsPrsLabel => 'DOSSIERS PERSONNELS';

  @override
  String get exerciseAnalyticsTrendsLabel => 'TENDANCES';

  @override
  String get exerciseAnalyticsNoData =>
      'Aucune donnée de suivi pour cet exercice.';

  @override
  String get exerciseAnalyticsNotEnoughData => 'Pas assez de données';

  @override
  String get exerciseAnalyticsChartWeight => 'Poids dans le temps (kg)';

  @override
  String get exerciseAnalyticsChartVolume => 'Volume dans le temps (kg)';

  @override
  String get exerciseAnalyticsChartSets => 'Se fixe au fil du temps';

  @override
  String get exerciseMetricMaxWeight => 'Poids maximum';

  @override
  String get exerciseMetricVolume => 'Volume';

  @override
  String get exerciseMetricEst1RM => 'HNE. 1RM';

  @override
  String get exerciseMetricDistance => 'Distance';

  @override
  String get exerciseMetricDuration => 'Durée';

  @override
  String get exerciseMetricPace => 'Allure';

  @override
  String get prBannerBestMaxWeight => 'Meilleur poids maximum';

  @override
  String get prBannerBestVolumeSet => 'Meilleur ensemble de volumes';

  @override
  String get prBannerBest1RM => 'Meilleur 1 répétition maximum';

  @override
  String get newPersonalRecordLabel => 'Nouveau record personnel';

  @override
  String get prBadgeTooltip => 'Nouveau record personnel !';

  @override
  String get workoutSummaryNewRecordsTitle => 'Nouveaux records';

  @override
  String get allTimeRecordsLabel => 'Records de tous les temps';

  @override
  String get recentActivityLabel => 'Activité récente';

  @override
  String get prsByRepRangeLabel => 'Meilleur ensemble par plage de répétitions';

  @override
  String get volumeAnalyticsTitle => 'Analyse des volumes';

  @override
  String get weeklyTonnageLabel => 'Tonnage hebdomadaire';

  @override
  String get volumeByMuscleLabel => 'Par groupe musculaire';

  @override
  String get topExercisesLabel => 'Meilleurs exercices';

  @override
  String get thisWeekLabel => 'Cette semaine';

  @override
  String get avgPerWeekLabel => 'Moyenne / Semaine';

  @override
  String get streakLabel => 'Traînée';

  @override
  String get trainingCalendarLabel => 'Calendrier de formation';

  @override
  String get workoutsPerWeekLabel => 'Entraînements par semaine';

  @override
  String get totalWorkoutsLabel => 'Nombre total d’entraînements';

  @override
  String get weeksLabel => 'Semaines';

  @override
  String get tonnageKgLabel => 'Tonnage (kg)';

  @override
  String get noWorkoutDataLabel =>
      'Aucune donnée d\'entraînement pour l\'instant. Commencez à vous connecter pour voir les statistiques.';

  @override
  String get analyticsSectionVolumeMuscles => 'Groupes de volume et de muscles';

  @override
  String get analyticsSectionPerformanceRecords => 'Performances et records';

  @override
  String get analyticsTopVolume => 'Les mieux formés';

  @override
  String get analyticsLowestVolume => 'Volume le plus bas';

  @override
  String get analyticsRecentRecords => 'Enregistrements récents';

  @override
  String analyticsPerfWithReps(String weight, int reps, Object unit) {
    return '$weight $unit x $reps';
  }

  @override
  String get analyticsKgThisWeek => 'kg (cette semaine)';

  @override
  String get analyticsRecoverySummary => '3 en récupération, 8 prêts';

  @override
  String get analyticsViewDetails => 'Afficher les détails';

  @override
  String get analyticsRepRangeSuffix => 'représentants';

  @override
  String get analyticsNoRecordYet => 'Pas encore d\'enregistrement';

  @override
  String get analyticsNotableImprovements => 'Améliorations notables';

  @override
  String get analyticsNoPrTrendInWindow =>
      'Il n’y a pas encore de tendance claire en matière de relations publiques dans cette fenêtre.';

  @override
  String analyticsE1rmProgress(String previous, String recent, Object unit) {
    return 'e1RM $previous -> $recent $unit';
  }

  @override
  String get analyticsUnitKg => 'kilos';

  @override
  String get analyticsUnitSets => 'ensembles';

  @override
  String get analyticsViewLabel => 'Voir';

  @override
  String get analyticsViewWeek => 'Semaine';

  @override
  String get analyticsViewMonth => 'Mois';

  @override
  String get analyticsViewByExercise => 'Par exercice';

  @override
  String get analyticsViewByMuscle => 'Par groupe musculaire';

  @override
  String get analyticsMetricLabel => 'Métrique';

  @override
  String get analyticsMovedWeightKg => 'Poids déplacé (kg)';

  @override
  String get analyticsWorkSets => 'Ensembles de travail';

  @override
  String get analyticsVolumeContextWithSets =>
      'Poids déplacé = poids x répétitions. Passez aux ensembles de travaux pour une charge basée sur le nombre.';

  @override
  String get analyticsVolumeContextTonnageOnly =>
      'Cette vue utilise le poids déplacé (poids x répétitions).';

  @override
  String get analyticsKpisHeader => 'KPI';

  @override
  String get analyticsTrainingDaysPerWeek => 'Jours de formation/semaine';

  @override
  String get analyticsLast4Weeks => 'les 4 dernières semaines';

  @override
  String get analyticsRhythm => 'Rythme';

  @override
  String get analyticsVsPrior4Weeks => 'vs les 4 semaines précédentes';

  @override
  String get analyticsRollingConsistency => 'Cohérence de roulement';

  @override
  String get analyticsWeeksAtLeast2Workouts =>
      'semaines avec au moins 2 séances';

  @override
  String get analyticsInTimeframe => 'Dans la période';

  @override
  String get analyticsVsPriorPeriod => 'vs période précédente';

  @override
  String get analyticsCalendarExplainer =>
      'L\'intensité des couleurs reflète les séances quotidiennes, ce qui en fait une véritable carte de cohérence.';

  @override
  String get analyticsSelectDayPrompt =>
      'Sélectionnez un jour pour inspecter le nombre de sessions.';

  @override
  String analyticsSelectedDayWorkouts(String date, int count) {
    return '$date : $count sessions';
  }

  @override
  String get analyticsTotalSessions => 'Nombre total de séances';

  @override
  String get analyticsPlaceholderWeightValue => '82,5';

  @override
  String get analyticsPlaceholderWeightTrend => 'kg (-0,5)';

  @override
  String get analyticsPlaceholderCaloriesValue => '2 450';

  @override
  String get analyticsPlaceholderCaloriesUnit => 'kcal/jour';

  @override
  String get analyticsMuscleWeeklySets => 'Ensembles hebdomadaires';

  @override
  String get analyticsMuscleTopFrequency => 'Fréquence la plus élevée';

  @override
  String get analyticsPerWeekAbbrev => 'semaine';

  @override
  String get analyticsKeepTrackingUnlockInsights =>
      'Continuez à suivre pour débloquer des informations.';

  @override
  String get analyticsGuidanceNoClearWeakPoint =>
      'Orientation : Pas de point faible évident sur cette période.';

  @override
  String analyticsGuidanceLowerEmphasis(String muscles) {
    return 'Conseils : Moins d\'accent récemment mis sur les $muscles.';
  }

  @override
  String get analyticsPeriodLabel => 'Période';

  @override
  String get analyticsEquivalentSetsExplainer =>
      'Les ensembles durs équivalents utilisent une pondération primaire x1,0 et secondaire x0,3. La fréquence ne compte que les jours atteignant >= 1,0 ensembles équivalents.';

  @override
  String get analyticsWeeklySetsByMuscle => 'Ø Séries hebdomadaires par muscle';

  @override
  String get analyticsFrequencyByMuscle => 'Fréquence par muscle';

  @override
  String get analyticsRecentDistributionHeatmap =>
      'Carte thermique de distribution récente';

  @override
  String get analyticsRadarOverviewTitle => 'Aperçu des radars';

  @override
  String get analyticsRadarVolumeCaption =>
      'Affiche la répartition relative du volume entre les muscles pour un résumé rapide en un coup d\'œil.';

  @override
  String get analyticsGuidanceTitle => 'Conseils';

  @override
  String get analyticsGuidanceDirectionalDisclaimer =>
      'Il s\'agit d\'un guidage directionnel basé sur votre distribution d\'ensemble récente, et non d\'un diagnostic absolu.';

  @override
  String get analyticsGuidanceSoftenedDisclaimer =>
      'Les informations sont intentionnellement adoucies jusqu\'à ce que suffisamment de données soient disponibles.';

  @override
  String analyticsWeekTotalEquivalentSets(String value) {
    return 'Ø $value séries équivalentes par semaine';
  }

  @override
  String get analyticsFrequencyRuleFooter =>
      'La fréquence ne compte que les jours où le muscle a atteint >= 1,0 séries équivalentes.';

  @override
  String liveWorkoutE1rmCurrentSet(String value, Object unit) {
    return 'e1RM $value $unit';
  }

  @override
  String liveWorkoutE1rmBestSession(String value, Object unit) {
    return 'Meilleur e1RM cette session : $value $unit';
  }

  @override
  String liveWorkoutE1rmVsLastSession(String delta, Object unit) {
    return 'vs dernière séance : $delta $unit';
  }

  @override
  String get bodyNutritionCorrelationTitle => 'Tendances corps et nutrition';

  @override
  String get metricsWeightChange => 'Changement de poids';

  @override
  String get analyticsKcalPerDay => 'kcal/jour';

  @override
  String get analyticsDaysWithWeightData => 'jours avec du poids';

  @override
  String get analyticsDayUnitLabel => 'jours';

  @override
  String get analyticsPerDayLabel => 'par jour';

  @override
  String get analyticsEffectiveRangeLabel => 'Portée efficace';

  @override
  String get analyticsAxisXLabel => 'X';

  @override
  String get analyticsAxisYLabel => 'Oui';

  @override
  String get analyticsHighConfidenceLabel => 'Modèle de confiance plus élevée';

  @override
  String get analyticsLowConfidenceLabel => 'Modèle de confiance inférieure';

  @override
  String get analyticsObservedPatternLabel => 'Modèle observé';

  @override
  String get analyticsBodyNutritionTrendContext =>
      'Poids et calories au fil du temps';

  @override
  String analyticsBodyNutritionTrendContextHint(Object unit) {
    return 'Le graphique met à l\'échelle chaque série pour s\'adapter au même espace ; les info-bulles affichent les valeurs brutes en $unit et en kcal.';
  }

  @override
  String analyticsBodyNutritionNormalizedHint(Object unit) {
    return 'Le graphique met à l\'échelle le poids et les calories pour s\'adapter au même espace ; les info-bulles affichent les valeurs brutes en $unit et en kcal.';
  }

  @override
  String analyticsBodyNutritionTotalWeightLabel(Object unit) {
    return 'Poids total ($unit)';
  }

  @override
  String get analyticsBodyNutritionTotalCaloriesLabel =>
      'Calories totales (kcal)';

  @override
  String analyticsWeightTrendLabel(String unit) {
    return 'Poids ($unit)';
  }

  @override
  String get analyticsCaloriesTrendLabel => 'Calories (kcal)';

  @override
  String get analyticsInterpretationTitle => 'Interprétation';

  @override
  String get analyticsBodyNutritionConfidenceHighHint =>
      'La couverture des données dans cette plage est suffisamment forte pour une lecture de modèle plus fiable.';

  @override
  String get analyticsBodyNutritionConfidenceModerateHint =>
      'La couverture des données est modérée. Les tendances constituent un contexte utile, mais continuez à les enregistrer pour renforcer votre confiance.';

  @override
  String get analyticsBodyNutritionConfidenceLowHint =>
      'La couverture des données dans cette plage est encore limitée, il faut donc considérer cela comme un contexte précoce.';

  @override
  String get analyticsBodyNutritionLowConfidenceNudge =>
      'Continuez à enregistrer régulièrement votre poids et vos calories pour améliorer votre confiance.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceHigh =>
      'Confiance dans l’interprétation : plus élevée. Utilisez-le comme contexte de tendance, et non comme énoncé de cause directe.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceLow =>
      'Confiance dans l’interprétation : inférieure. Utilisez-le comme signal de modèle précoce et continuez à suivre.';

  @override
  String get analyticsCorrelationDisclaimer =>
      'Cette vue fournit un contexte de tendance. Cela ne prouve pas que les changements de calories entraînent directement des changements de poids.';

  @override
  String get analyticsInsightStableWeightCaloriesUp =>
      'La tendance du poids est stable tandis que les calories moyennes augmentent.';

  @override
  String get analyticsInsightWeightUpCaloriesUp =>
      'Le poids tend à augmenter parallèlement à un apport calorique moyen plus élevé.';

  @override
  String get analyticsInsightCaloriesDownWeightStable =>
      'La réduction récente des calories n’a pas encore clairement modifié la tendance en matière de poids.';

  @override
  String get analyticsInsightWeightDownCaloriesDown =>
      'Le poids tend à diminuer parallèlement à une baisse de l’apport calorique moyen.';

  @override
  String get analyticsInsightMixedPattern =>
      'Les tendances en matière de poids et de calories sont mitigées sans encore de relation claire.';

  @override
  String get analyticsInsightNotEnoughData =>
      'Pas encore assez de données cohérentes pour une lecture de tendance significative.';

  @override
  String get analyticsModerateConfidenceLabel => 'Modèle de confiance modérée';

  @override
  String get analyticsInsufficientConfidenceLabel =>
      'Confiance insuffisante des données';

  @override
  String get analyticsTrendRising => 'Soulèvement';

  @override
  String get analyticsTrendFalling => 'Chute';

  @override
  String get analyticsTrendStable => 'Écurie';

  @override
  String get analyticsTrendUnclear => 'Peu clair';

  @override
  String get analyticsRelationshipAlignedCut =>
      'La baisse de la consommation et la baisse du poids corporel sont alignées.';

  @override
  String get analyticsRelationshipAlignedBulk =>
      'Une consommation plus élevée et une augmentation du poids corporel sont alignées.';

  @override
  String get analyticsRelationshipStableMaintenance =>
      'Le poids et la consommation semblent globalement stables.';

  @override
  String get analyticsRelationshipMixed =>
      'Les signaux sont mélangés ou retardés.';

  @override
  String get analyticsRelationshipInsufficient =>
      'Pas encore assez de chevauchement cohérent pour classer le motif.';

  @override
  String analyticsBasedOnDataCoverage(int weightDays, int calorieDays) {
    return 'Basé sur $weightDays pesées et $calorieDays jours caloriques';
  }

  @override
  String get restTimerNotificationTitle => 'Reste terminé';

  @override
  String get restTimerNotificationBody =>
      'Votre minuteur de pause est terminé. Prêt pour le prochain set.';

  @override
  String get onboardingContinueSetup => 'Configurer le profil';

  @override
  String get onboardingRestoreFromBackup =>
      'Restaurer à partir d\'une sauvegarde';

  @override
  String get onboardingRestoreImporting => 'Importation de la sauvegarde...';

  @override
  String get onboardingRestoreSuccess => 'Sauvegarde restaurée avec succès !';

  @override
  String get onboardingRestoreFailed =>
      'L\'importation a échoué. Veuillez vérifier le fichier et réessayer.';

  @override
  String get onboardingRestoreFromICloud => 'Restaurer depuis iCloud';

  @override
  String get onboardingRestoreICloudSuccess =>
      'La sauvegarde iCloud a été restaurée avec succès !';

  @override
  String get onboardingRestoreICloudFailed =>
      'La restauration iCloud a échoué. Vérifiez votre connexion et réessayez.';

  @override
  String get finishWorkoutTitleLabel => 'Titre de l\'entraînement';

  @override
  String get finishWorkoutNotesLabel => 'Remarques (facultatif)';

  @override
  String get finishWorkoutNotesHint => 'Comment s’est passé l’entraînement ?';

  @override
  String get sleepSectionTitle => 'Dormir';

  @override
  String get sleepSectionSubtitleDayEntry =>
      'Aperçu de la journée et détails détaillés';

  @override
  String get sleepSectionSubtitleAllEntry =>
      'Les vues du jour, de la semaine et du mois du sommeil sont disponibles à partir de cette entrée';

  @override
  String get sleepScopeDay => 'Jour';

  @override
  String get sleepScopeWeek => 'Semaine';

  @override
  String get sleepScopeMonth => 'Mois';

  @override
  String get sleepWeekSummaryTitle => 'Résumé de la semaine';

  @override
  String get sleepMonthSummaryTitle => 'Résumé du mois';

  @override
  String get sleepSleepWindowTitle => 'Fenêtre de veille';

  @override
  String get sleepDailyScoreTitle => 'Score quotidien';

  @override
  String get sleepMonthDailyScoreStatesTitle => 'États de score quotidiens';

  @override
  String sleepMeanScoreLabel(String value) {
    return 'Score moyen : $value';
  }

  @override
  String get sleepHubScoreLabel => 'Score de sommeil';

  @override
  String get sleepHubAverageLabel => 'Moyenne';

  @override
  String get sleepHubBedtimeLabel => 'Heure du coucher';

  @override
  String get sleepHubInterruptionsLabel => 'Interruptions';

  @override
  String sleepHubInterruptionsSummary(int count, String duration) {
    return '$count réveils, $duration au total';
  }

  @override
  String sleepWeekdayAvgDurationLabel(String value) {
    return 'Durée moyenne en semaine : $value';
  }

  @override
  String sleepWeekendAvgDurationLabel(String value) {
    return 'Durée moyenne du week-end : $value';
  }

  @override
  String get sleepWeekNoScoredNights =>
      'Aucune nuit de sommeil notée n\'est encore disponible cette semaine.';

  @override
  String get sleepMonthNoScoredNights =>
      'Aucune nuit de sommeil notée n\'est encore disponible ce mois-ci.';

  @override
  String get sleepSettingsSectionTitle => 'Dormir';

  @override
  String get sleepEnableTrackingTitle => 'Activer le suivi du sommeil';

  @override
  String get sleepEnableTrackingSubtitle =>
      'Lisez le sommeil et la fréquence cardiaque nocturne à partir de Health Connect / HealthKit';

  @override
  String get sleepHealthConnectionStatusTitle => 'État de la connexion santé';

  @override
  String get sleepRequestAccessTitle => 'Demander l\'accès';

  @override
  String get sleepRequestAccessSubtitle =>
      'Demander ou redemander des autorisations de sommeil/fréquence cardiaque';

  @override
  String get sleepImportNowTitle =>
      'Importez les données de sommeil maintenant';

  @override
  String get sleepImportNowSubtitle =>
      'Importer toutes les données de sommeil disponibles (à tout moment)';

  @override
  String get sleepRawImportsTitle =>
      'Afficher les importations brutes de sommeil';

  @override
  String get sleepRawImportsSubtitle =>
      'Afficher les charges utiles Health Connect récentes';

  @override
  String get sleepDataStatusTitle => 'Statut des données';

  @override
  String get sleepDataStatusSubtitle =>
      'Autorisations accordées. Si aucune veille n\'apparaît encore, exécutez une importation manuelle ci-dessous.';

  @override
  String get sleepDataStatusSubtitleIos =>
      'Connexion active. Si des données manquent (0 sessions importées), vérifiez manuellement les autorisations de lecture dans l\'application Apple Health.';

  @override
  String get sleepNoPermissionSubtitle =>
      'Des autorisations de sommeil et de fréquence cardiaque sont requises pour importer des données de sommeil.';

  @override
  String get sleepFeatureUnavailableTitle => 'Fonctionnalité indisponible';

  @override
  String get sleepFeatureUnavailableSubtitle =>
      'L’importation du sommeil n’est pas disponible sur cet appareil ou Health Connect n’est pas installé.';

  @override
  String get sleepNoRawImportsFound =>
      'Aucune importation de sommeil brut n\'a encore été trouvée.';

  @override
  String get sleepRawImportsSheetTitle =>
      'Importations de sommeil brut (dernières)';

  @override
  String sleepImportFinishedSessions(int count) {
    return 'Importation du sommeil terminée ($count sessions).';
  }

  @override
  String get sleepImportUnavailableCheckPermissions =>
      'L\'importation du sommeil n\'est pas disponible. Vérifiez les autorisations.';

  @override
  String get sleepStatusChecking =>
      'Vérification de l\'état des autorisations…';

  @override
  String get sleepStatusReady => 'Prêt';

  @override
  String get sleepStatusDenied => 'Refusé';

  @override
  String get sleepStatusPartial => 'Accès partiel';

  @override
  String get sleepStatusUnavailable => 'Indisponible sur cet appareil';

  @override
  String get sleepStatusNotInstalled => 'Health Connect n\'est pas installé';

  @override
  String get sleepStatusTechnicalError => 'Erreur technique';

  @override
  String get sleepConnectHealthDataTitle => 'Connecter les données de santé';

  @override
  String get sleepConnectHealthDataMessage =>
      'Connectez HealthKit ou Health Connect pour importer des enregistrements de sommeil.';

  @override
  String get sleepPermissionDeniedTitle => 'Autorisation refusée';

  @override
  String get sleepPermissionDeniedMessage =>
      'Les autorisations de veille sont refusées. Ouvrez les paramètres pour accorder l’accès.';

  @override
  String get sleepSourceUnavailableTitle => 'Source indisponible';

  @override
  String get sleepSourceUnavailableMessage =>
      'La source de données de veille n\'est pas disponible ou n\'est pas installée sur cet appareil.';

  @override
  String get sleepEmptyDayNoData =>
      'Aucune donnée sur le sommeil disponible pour cette journée.';

  @override
  String get sleepEmptyDayConnectMessage =>
      'Connectez Health Connect/HealthKit dans Paramètres et importez les données de sommeil récentes.';

  @override
  String get sleepOpenSettingsButton => 'Ouvrir les paramètres';

  @override
  String get sleepImportNowButton => 'Importer maintenant';

  @override
  String get sleepImportFinishedRefreshing =>
      'L\'importation du sommeil est terminée. Rafraîchissant...';

  @override
  String get sleepImportUnavailableSettingsHint =>
      'L\'importation du sommeil n\'est pas disponible. Vérifiez les autorisations dans Paramètres.';

  @override
  String get sleepTimelineTitle => 'Chronologie';

  @override
  String get sleepTimelineUnavailable =>
      'Aucun calendrier de scène disponible pour cette soirée.';

  @override
  String get sleepSessionTypeCore => 'Sommeil de base';

  @override
  String get sleepSessionTypeNap => 'Somme';

  @override
  String get sleepIntervalsDrawerTitle => 'Intervalles de sommeil';

  @override
  String get sleepStageDeepLabel => 'Profond';

  @override
  String get sleepStageLightLabel => 'Lumière';

  @override
  String get sleepStageRemLabel => 'REM';

  @override
  String get sleepStageAwakeLabel => 'Éveillé';

  @override
  String get sleepScoreCardTitle => 'Qualité du sommeil';

  @override
  String get sleepScoreUnavailableForNight =>
      'Score indisponible pour cette soirée.';

  @override
  String sleepScoreCompletenessLabel(String value) {
    return 'Complétude du score : $value';
  }

  @override
  String get sleepQualityGood => 'Bien';

  @override
  String get sleepQualityAverage => 'Moyenne';

  @override
  String get sleepQualityPoor => 'Pauvre';

  @override
  String get sleepQualityUnavailable => 'Indisponible';

  @override
  String get sleepQualitySubtitleGood =>
      'La reprise a semblé forte du jour au lendemain.';

  @override
  String get sleepQualitySubtitleAverage =>
      'Le sommeil était correct et pouvait être amélioré.';

  @override
  String get sleepQualitySubtitlePoor =>
      'Les signaux de reprise étaient faibles ce soir.';

  @override
  String get sleepQualitySubtitleUnavailable =>
      'Pas assez de données pour marquer ce soir.';

  @override
  String get sleepQualityRegularityNotContributing =>
      'La régularité n\'a pas contribué (<5 jours valables).';

  @override
  String get sleepQualityRegularityPreliminary =>
      'La régularité est préliminaire (5-6 jours valables).';

  @override
  String sleepQualityRegularityStable(int days) {
    return 'La régularité est stable ($days jours).';
  }

  @override
  String sleepRegularityNightView(int count) {
    return '$count-vue de nuit';
  }

  @override
  String get sleepMetricUnavailable => 'Indisponible';

  @override
  String get sleepMetricDurationTitle => 'Durée';

  @override
  String get sleepMetricHeartRateTitle => 'Fréquence cardiaque';

  @override
  String get sleepMetricRegularityTitle => 'Régularité';

  @override
  String get sleepMetricDepthTitle => 'Profondeur';

  @override
  String get sleepMetricInterruptionsTitle => 'Interruptions du sommeil';

  @override
  String get sleepMetricDepthLowConfidence => 'Faible confiance';

  @override
  String get sleepMetricDepthStagesAvailable => 'Étapes disponibles';

  @override
  String get sleepDurationUnavailable =>
      'Les données de durée ne sont pas disponibles.';

  @override
  String get sleepDurationStatusWithinTarget => 'Dans la cible';

  @override
  String get sleepDurationStatusBelowTarget => 'En dessous de l\'objectif';

  @override
  String get sleepDurationSubtitle =>
      'Votre durée totale de sommeil pour cette nuit.';

  @override
  String get sleepDurationBenchmarkHint =>
      'Les adultes réussissent souvent mieux avec environ 7 à 9 heures. Cette référence vous aide à voir où se situe votre nuit dans cette plage.';

  @override
  String get sleepDepthUnavailable =>
      'Les données de profondeur ne sont pas disponibles.';

  @override
  String get sleepDepthConfidenceTooLow =>
      'La confiance dans la scène est trop faible pour une analyse fiable de la profondeur.';

  @override
  String get sleepDepthBreakdownUnavailable =>
      'La répartition de la durée de l\'étape n\'est pas disponible pour cette nuit.';

  @override
  String get sleepDepthRatingRestorative => 'Réparateur';

  @override
  String get sleepDepthRatingLightLeaning => 'Tendance à la lumière';

  @override
  String sleepDepthStageConfidenceLabel(String value) {
    return 'Confiance de l\'étape : $value';
  }

  @override
  String get sleepDepthSubtitle =>
      'Distribution des étapes basée sur des segments de chronologie dérivés.';

  @override
  String get sleepInterruptionsUnavailable =>
      'Les données sur les interruptions ne sont pas disponibles.';

  @override
  String get sleepInterruptionsStatusNoneDetected => 'Aucun détecté';

  @override
  String get sleepInterruptionsStatusDetected => 'Détecté';

  @override
  String get sleepInterruptionsSubtitle =>
      'Interruptions de réveil qualificatives pendant la nuit.';

  @override
  String get sleepInterruptionsTotalWakeDuration => 'Durée totale de réveil';

  @override
  String get sleepInterruptionsFootnote =>
      'Cette vue inclut uniquement les interruptions qualifiées des sorties d’analyse dérivées.';

  @override
  String get sleepRegularityUnavailable =>
      'Les données de régularité ne sont pas disponibles.';

  @override
  String sleepRegularityNightRange(int count) {
    return 'Plage de $count nuit';
  }

  @override
  String get sleepRegularityStatusSufficientTrend =>
      'Données de tendance suffisantes';

  @override
  String get sleepRegularityStatusLimitedTrend =>
      'Données de tendance limitées';

  @override
  String get sleepRegularitySubtitle =>
      'Fenêtres d’heure de coucher et de réveil pour les nuits récentes.';

  @override
  String get sleepRegularityAverageBedtime => 'Heure moyenne du coucher';

  @override
  String get sleepRegularityAverageWake => 'Sillage moyen';

  @override
  String get sleepHeartRateUnavailable =>
      'Les données de fréquence cardiaque pendant le sommeil ne sont pas disponibles.';

  @override
  String get sleepHeartRateStatusNoSampleSeries =>
      'Aucune série d\'échantillons pour cette nuit';

  @override
  String get sleepHeartRateStatusBaselineNotEstablished =>
      'Base de référence non établie';

  @override
  String get sleepHeartRateStatusComparisonUnavailable =>
      'Comparaison de base indisponible';

  @override
  String get sleepHeartRateStatusBelowBaseline =>
      'En dessous de la ligne de base';

  @override
  String get sleepHeartRateStatusAboveBaseline =>
      'Au-dessus de la ligne de base';

  @override
  String get sleepHeartRateNoSamplesText =>
      'Aucun échantillon persistant de fréquence cardiaque pendant le sommeil n\'est disponible pour cette nuit.';

  @override
  String get sleepHeartRateBaselineNotEstablishedText =>
      'Base de référence pas encore établie. Ceci est neutre et attendu dès le début.';

  @override
  String get sleepHeartRateComparisonUnavailableText =>
      'La comparaison de base n\'est actuellement pas disponible pour cette nuit.';

  @override
  String sleepHeartRateDeltaText(String direction, String delta, String unit) {
    return 'Votre FC de sommeil est la référence de $direction par $delta $unit.';
  }

  @override
  String get sleepHeartRateDirectionBelow => 'ci-dessous';

  @override
  String get sleepHeartRateDirectionAbove => 'au-dessus de';

  @override
  String get sleepHeartRateComparedBaselineSubtitle =>
      'Par rapport à votre base de sommeil établie.';

  @override
  String get sleepHeartRateNoBaselineSubtitle =>
      'La ligne de base n’est pas encore établie. C\'est neutre.';

  @override
  String get sleepHeartRateSamplesUnavailable =>
      'Aucun échantillon de fréquence cardiaque n\'a été stocké pour cette nuit. Le graphique de tendance n\'est pas disponible.';

  @override
  String sleepHeartRateDashedLineHint(String value, String unit) {
    return 'La ligne pointillée montre la ligne de base ($value $unit).';
  }

  @override
  String get sleepBpmUnit => 'bpm';

  @override
  String get sleepRawImportImportedAt => 'Importé à';

  @override
  String get sleepRawImportStatus => 'Statut';

  @override
  String get sleepRawImportSource => 'Source d’importation';

  @override
  String get sleepRawImportApp => 'Application';

  @override
  String get sleepRawImportConfidence => 'Confiance';

  @override
  String get sleepRawImportPayload => 'Charge utile';

  @override
  String get adaptiveBodyweightTargetSectionTitle =>
      'Objectif de poids corporel adaptatif';

  @override
  String get adaptiveRecommendationSettingsSectionTitle =>
      'Paramètres de recommandation';

  @override
  String get adaptiveGoalDirectionLabel => 'Direction du but';

  @override
  String get adaptiveGoalLose => 'Perdre du poids';

  @override
  String get adaptiveGoalMaintain => 'Maintenir le poids';

  @override
  String get adaptiveGoalGain => 'Prendre du poids';

  @override
  String adaptiveRatePerWeek(String value, Object unit) {
    return '$value $unit/semaine';
  }

  @override
  String get adaptivePriorActivityLabel => 'Activité quotidienne de base';

  @override
  String get adaptivePriorActivityLow => 'Faible activité';

  @override
  String get adaptivePriorActivityModerate => 'Activité modérée';

  @override
  String get adaptivePriorActivityHigh => 'Haute activité';

  @override
  String get adaptivePriorActivityVeryHigh => 'Très forte activité';

  @override
  String get adaptivePriorActivityHelpIntro =>
      'Activité quotidienne de base uniquement (séparée du cardio supplémentaire) :';

  @override
  String get adaptivePriorActivityHelpLowLine =>
      'Faible : principalement assis, étudiant/élève ou routine de bureau.';

  @override
  String get adaptivePriorActivityHelpModerateLine =>
      'Modéré : mixte assis, marchant et debout.';

  @override
  String get adaptivePriorActivityHelpHighLine =>
      'Élevé : beaucoup de temps debout/marché ou un travail physiquement actif.';

  @override
  String get adaptivePriorActivityHelpVeryHighLine =>
      'Très élevé : routine/travail très exigeant en mouvements avec une activité quotidienne constamment élevée.';

  @override
  String get adaptiveExtraCardioLabel =>
      'Cardio/endurance supplémentaire en dehors de l\'application';

  @override
  String get adaptiveExtraCardioOption0 => '0 h/semaine';

  @override
  String get adaptiveExtraCardioOption1 => '1h/semaine';

  @override
  String get adaptiveExtraCardioOption2 => '2h/semaine';

  @override
  String get adaptiveExtraCardioOption3 => '3h/semaine';

  @override
  String get adaptiveExtraCardioOption5 => '5h/semaine';

  @override
  String get adaptiveExtraCardioOption7Plus => '7+ heures/semaine';

  @override
  String get adaptiveExtraCardioHelp =>
      'Incluez le jogging, la course à pied, le vélo, la natation ou d\'autres séances d\'endurance non enregistrées comme entraînements Train Libre.';

  @override
  String get onboardingAdaptiveGoalTitle =>
      'Recommandation nutritionnelle adaptative';

  @override
  String get onboardingAdaptiveGoalSubtitle =>
      'Définissez votre direction et votre tarif hebdomadaire. Nous créons une recommandation de départ conservatrice et l\'adaptons avec vos journaux.';

  @override
  String get adaptiveRecommendationGenerating => 'Générateur...';

  @override
  String get adaptiveRecommendationRefresh => 'Actualiser la recommandation';

  @override
  String get onboardingAdaptiveSummaryEmpty =>
      'Définissez vos objectifs et appuyez sur Actualiser pour prévisualiser votre recommandation de départ.';

  @override
  String get onboardingAdaptiveSummaryTitle => 'Aperçu de la recommandation';

  @override
  String onboardingAdaptiveSummaryCalories(int value) {
    return 'Calories : $value kcal';
  }

  @override
  String onboardingAdaptiveSummaryProtein(int value) {
    return 'Protéine : $value g';
  }

  @override
  String onboardingAdaptiveSummaryCarbs(int value) {
    return 'Glucides : $value g';
  }

  @override
  String onboardingAdaptiveSummaryFat(int value) {
    return 'Graisse : $value g';
  }

  @override
  String onboardingAdaptiveSummaryConfidence(String value) {
    return 'Base de données : $value';
  }

  @override
  String get onboardingAdaptiveSummaryApply =>
      'Appliquer aux objectifs quotidiens';

  @override
  String get onboardingAdaptiveSummaryApplied =>
      'Appliqué aux objectifs quotidiens';

  @override
  String get onboardingBodyFatPageTitle => '% de graisse corporelle';

  @override
  String get onboardingBodyFatPageSubtitle =>
      'Étape facultative : saisissez une estimation approximative si vous la connaissez.';

  @override
  String get onboardingBodyFatOptionalLabel =>
      '% de graisse corporelle (facultatif)';

  @override
  String get onboardingBodyFatOptionalHelper =>
      'Facultatif : ne saisissez cette valeur que si vous connaissez à peu près votre valeur. Le laisser vide, c\'est bien. Cela permet de personnaliser la recommandation initiale.';

  @override
  String get onboardingBodyFatHelpAction => 'Comment puis-je estimer cela ?';

  @override
  String get bodyFatGuidanceTitle => '% de graisse corporelle';

  @override
  String get bodyFatGuidanceIntro =>
      'Le pourcentage de graisse corporelle ne peut être estimé qu’approximativement à partir de l’apparence. Il s\'agit uniquement d\'une orientation, pas d\'un diagnostic précis.';

  @override
  String get bodyFatGuidanceDisclaimer =>
      'L\'apparence peut varier considérablement pour un même niveau de graisse corporelle en raison de la masse musculaire, de la répartition des graisses, de la génétique, de la rétention d\'eau, de la posture et de l\'éclairage.';

  @override
  String get bodyFatGuidanceSexLabel => 'Sexe de référence';

  @override
  String bodyFatGuidancePercent(int percent) {
    return '$percent%';
  }

  @override
  String get bodyFatGuidanceMale10 => 'Définition très simple et claire.';

  @override
  String get bodyFatGuidanceMale15 => 'Athlétique, visiblement défini.';

  @override
  String get bodyFatGuidanceMale20 => 'Sportif, légèrement plus doux.';

  @override
  String get bodyFatGuidanceMale25 =>
      'Moins de définition, plus de douceur à la taille et au ventre.';

  @override
  String get bodyFatGuidanceMale30 => 'Clairement plus doux, plus rond.';

  @override
  String get bodyFatGuidanceMale35 =>
      'Très doux, presque aucune définition visible.';

  @override
  String get bodyFatGuidanceMale40 =>
      'Aspect fortement plus rond, pas de définition visible.';

  @override
  String get bodyFatGuidanceFemale15 => 'Très maigre, très défini.';

  @override
  String get bodyFatGuidanceFemale20 => 'Mince et athlétique.';

  @override
  String get bodyFatGuidanceFemale25 => 'Ajusté, légèrement doux.';

  @override
  String get bodyFatGuidanceFemale30 =>
      'Gamme moyenne athlétique à normale, douce et d\'apparence saine.';

  @override
  String get bodyFatGuidanceFemale35 => 'Visiblement plus doux.';

  @override
  String get bodyFatGuidanceFemale40 =>
      'Aspect général nettement plus doux et plus rond.';

  @override
  String get adaptiveRecommendationCardTitle => 'Recommandation adaptative';

  @override
  String get adaptiveRecommendationEmptyBody =>
      'Suivez votre poids et votre nutrition pendant environ une semaine pour débloquer votre première recommandation hebdomadaire.';

  @override
  String adaptiveRecommendationGoalLine(String goal, String rate) {
    return 'Objectif : $goal ($rate)';
  }

  @override
  String adaptiveRecommendationMaintenanceLine(int value) {
    return 'Estimation d\'entretien : $value kcal';
  }

  @override
  String adaptiveRecommendationMaintenanceRangeLine(int lower, int upper) {
    return 'Fourchette probable : $lower - $upper kcal';
  }

  @override
  String get adaptiveRecommendationUncertaintyHintNarrow =>
      'Votre plage de maintenance probable est assez étroite. De petits quarts de travail quotidiens sont normaux.';

  @override
  String get adaptiveRecommendationUncertaintyHintModerate =>
      'Votre plage de maintenance probable est modérée en ce moment. Certains mouvements de semaine en semaine sont normaux.';

  @override
  String get adaptiveRecommendationUncertaintyHintWide =>
      'Votre marge de maintenance probable est encore large. C\'est normal pendant que nous collectons des données plus stables.';

  @override
  String get adaptiveRecommendationStabilizingHint =>
      'Nous sommes encore en train de nous adapter à votre phase récente, cette estimation peut donc bouger plus que d\'habitude.';

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
    return 'Base de données : $value';
  }

  @override
  String adaptiveRecommendationDataBasisLine(
      int windowDays, int weightLogs, int intakeDays) {
    return 'Base de données : $windowDays jours, $weightLogs journaux de poids, $intakeDays jours de prise';
  }

  @override
  String adaptiveRecommendationActiveCaloriesLine(int value) {
    return 'Calories actives actuelles : $value kcal';
  }

  @override
  String adaptiveRecommendationCalculatedAtLine(String value) {
    return 'Calculé à : $value';
  }

  @override
  String adaptiveRecommendationNextDueLine(String value) {
    return 'Prochaine recommandation adaptative attendue : $value';
  }

  @override
  String adaptiveRecommendationNextDueShort(String value) {
    return 'Suivant $value';
  }

  @override
  String get adaptiveRecommendationDueNowLine =>
      'Une nouvelle recommandation adaptative est attendue cette semaine.';

  @override
  String get adaptiveRecommendationDueNowShort => 'À rendre cette semaine';

  @override
  String get adaptiveRecommendationMaintenanceLabel => 'Entretien estimé';

  @override
  String get adaptiveRecommendationMaintenanceSourceLabel =>
      'Profils journaux antérieurs et récents';

  @override
  String get adaptiveRecommendationMaintenanceUnit => 'kcal/jour';

  @override
  String get adaptiveRecommendationMacroTargetsLabel => 'Cibles recommandées';

  @override
  String get adaptiveRecommendationTargetCaloriesLabel => 'Kcal cible';

  @override
  String get adaptiveRecommendationDataQualityLabel => 'Qualité des données';

  @override
  String get adaptiveRecommendationEnergyDensityLabel =>
      'Densité énergétique effective';

  @override
  String adaptiveRecommendationEnergyDensityValue(int value) {
    return '$value kcal/kg';
  }

  @override
  String get adaptiveRecommendationEnergyDensityExplanation =>
      'Valeur dynamique basée sur le poids et le ratio de perte d’eau';

  @override
  String get adaptiveRecommendationRecalculateNowAction =>
      'Recalculer maintenant';

  @override
  String get adaptiveRecommendationRecalculating => 'Recalculer...';

  @override
  String get adaptiveRecommendationApplying => 'Candidature...';

  @override
  String get adaptiveRecommendationApplyAction => 'Appliquer la recommandation';

  @override
  String get adaptiveRecommendationWarningCalorieFloor =>
      'Recommandation limitée par un seuil minimum de sécurité calorique. Examinez les données de profil et les journaux récents avant de postuler.';

  @override
  String get adaptiveRecommendationWarningUnresolvedFood =>
      'Certaines entrées nutritionnelles n\'ont pas pu être entièrement résolues pour les calories. Vérifiez les journaux récents avant de postuler.';

  @override
  String get adaptiveRecommendationWarningLargeAdjustment =>
      'Ajustement important détecté. Veuillez vérifier l\'intégralité de votre journalisation récente avant de postuler.';

  @override
  String get adaptiveRecommendationWarningMacroConstrained =>
      'La répartition macro était limitée par le budget calorique. Vérifiez si votre taux cible est trop agressif.';

  @override
  String get adaptiveRecommendationWarningConservative =>
      'Examen suggéré : la recommandation a été ajustée de manière conservatrice en raison de la variabilité des données.';

  @override
  String get adaptiveRecommendationDataBasisHintDefault =>
      'Construit à partir des journaux récents et de leur exhaustivité.';

  @override
  String get adaptiveRecommendationDataBasisHintPriorOnly =>
      'Basé uniquement sur le profil/les données antérieures. Ajoutez des journaux de poids et de consommation récents pour un ajustement adaptatif.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseWeight =>
      'Les journaux de poids récents sont rares, la qualité des tendances est donc limitée.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseIntake =>
      'Les journaux d’admission récents sont rares, donc l’inférence de maintenance est limitée.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseWeightAndIntake =>
      'Les registres récents de poids et de consommation sont rares, cette recommandation est donc plus conservatrice.';

  @override
  String get adaptiveConfidenceNotEnoughData => 'Profil/antérieur seulement';

  @override
  String get adaptiveConfidenceLow => 'Journaux récents limités';

  @override
  String get adaptiveConfidenceMedium => 'Journaux récents utilisables';

  @override
  String get adaptiveConfidenceHigh => 'Journaux récents solides';

  @override
  String get adaptiveRecommendationRecalculatedSnack =>
      'Recommandation recalculée.';

  @override
  String get adaptiveRecommendationAppliedToGoalsSnack =>
      'Recommandation appliquée aux objectifs actifs.';

  @override
  String get adaptiveRecommendationNotAvailableSnack =>
      'Aucune recommandation disponible pour postuler.';

  @override
  String get settingsSectionApp => 'Application';

  @override
  String get settingsAppearanceSubtitle =>
      'Ajustez le thème, le style visuel et l\'haptique';

  @override
  String get settingsShowSugarInDiaryOverviewTitle =>
      'Afficher le sucre dans l\'aperçu du journal';

  @override
  String get settingsShowSugarInDiaryOverviewSubtitle =>
      'Affiche le sucre dans la section supérieure d\'aperçu quotidien';

  @override
  String get settingsOverviewExtraNutrientTitle =>
      'Nutriment supplémentaire dans l\'aperçu';

  @override
  String get settingsOverviewExtraNutrientSubtitle =>
      'Ajoutez un troisième nutriment à l\'aperçu quotidien';

  @override
  String get settingsSectionHealthTracking => 'Santé et suivi';

  @override
  String get settingsStepsSubtitle =>
      'Suivi, politique de source et fournisseurs';

  @override
  String get settingsSleepSubtitle =>
      'Importation, autorisations et état de veille';

  @override
  String get settingsPulseSubtitle =>
      'Analyse du pouls et accès à la fréquence cardiaque en option';

  @override
  String get settingsHealthExportSubtitle =>
      'Gérer l’exportation Apple Health et Health Connect';

  @override
  String get settingsSectionNutritionAndData => 'Nutrition et données';

  @override
  String get settingsSectionSupportAbout => 'Assistance / À propos';

  @override
  String get settingsHapticFeedbackTitle => 'Retour haptique';

  @override
  String get settingsHapticFeedbackSubtitle =>
      'Vibrations légères pour les confirmations et l\'attente de l\'IA';

  @override
  String get stepsSettingsEnableTrackingTitle => 'Activer le suivi des étapes';

  @override
  String get stepsSettingsEnableTrackingSubtitle =>
      'Lire les données d\'étape d\'Apple Health / Health Connect';

  @override
  String get stepsSettingsSourcePolicyTitle => 'Politique de source';

  @override
  String get stepsSettingsSourcePolicyAutoDominant =>
      'Automatique (source dominante)';

  @override
  String get stepsSettingsSourcePolicyAutoDominantSubtitle =>
      'Recommandé : utilisez une source par jour pour éviter les chevauchements d\'inflation.';

  @override
  String get stepsSettingsSourcePolicyMaxPerHour =>
      'Fusionner (maximum par heure)';

  @override
  String get stepsSettingsSourcePolicyMaxPerHourSubtitle =>
      'Combinez les sources en prenant la tranche horaire la plus élevée.';

  @override
  String get stepsSettingsProviderFilterTitle => 'Filtre de fournisseur';

  @override
  String get pulseTitle => 'Impulsion';

  @override
  String get pulseChartTitle => 'Pouls au fil du temps';

  @override
  String get pulseRangeLabel => 'Gamme';

  @override
  String get pulseAverageLabel => 'Moyenne';

  @override
  String get pulseRestingLabel => 'Repos';

  @override
  String get pulseInsufficientData =>
      'Trop peu d\'échantillons d\'impulsions pour un graphique fiable.';

  @override
  String get pulseMethodNote =>
      'Le pouls moyen est pondéré dans le temps. Le pouls au repos est une estimation prudente à partir des 20 % d’échantillons les plus bas de la période sélectionnée.';

  @override
  String pulseSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count échantillons',
      one: '1 echantillon',
      zero: 'Aucun echantillon',
    );
    return '$_temp0';
  }

  @override
  String get pulseQualityReady => 'Bonne couverture';

  @override
  String get pulseQualityLimited => 'Données limitées';

  @override
  String get pulseQualityInsufficient => 'Très clairsemé';

  @override
  String get pulseQualityNoData => 'Aucune donnée';

  @override
  String get pulseNoDataDisabled =>
      'L\'analyse du pouls est désactivée dans les paramètres.';

  @override
  String get pulseNoDataPermissionDenied =>
      'Une autorisation de fréquence cardiaque est requise pour afficher l\'analyse du pouls.';

  @override
  String get pulseNoDataUnavailable =>
      'Les données de pouls ne sont actuellement pas disponibles sur cet appareil.';

  @override
  String get pulseNoDataQueryFailed =>
      'Impossible de lire les données de pouls.';

  @override
  String get pulseNoDataDefault =>
      'Aucun échantillon de légumineuses n’a été trouvé pour cette période.';

  @override
  String get pulseSettingsEnableTitle => 'Activer l\'analyse du pouls';

  @override
  String get pulseSettingsEnableSubtitle =>
      'Lit les données de fréquence cardiaque pour l\'affichage du pouls uniquement lorsque vous l\'activez.';

  @override
  String get pulseSettingsPermissionTitle =>
      'Autoriser l\'accès à la fréquence cardiaque';

  @override
  String get pulseSettingsPermissionSubtitle =>
      'Ouvre Apple Health ou Health Connect pour que Train Libre puisse lire des échantillons de pouls.';

  @override
  String get pulseSettingsAnalysisSubtitle =>
      'Affiche la plage, la moyenne pondérée dans le temps et une estimation prudente du pouls au repos. Pas un diagnostic médical.';

  @override
  String get pulseSettingsPermissionGranted =>
      'L\'accès à la fréquence cardiaque est prêt.';

  @override
  String get pulseSettingsPermissionFailed =>
      'L\'accès à la fréquence cardiaque n\'a pas été accordé.';

  @override
  String get pulseOptInChip => 'S\'inscrire';

  @override
  String get statisticsPulseDescription =>
      'Plage, moyenne pondérée dans le temps et pouls au repos pour les périodes sélectionnées.';

  @override
  String get statisticsPulseOpenCaption => 'Ouvre l\'analyse du pouls';

  @override
  String get healthExportTitle => 'Exportation de santé';

  @override
  String get healthExportAppleHealthTitle => 'Exportation Apple Santé';

  @override
  String get healthExportHealthConnectTitle => 'Exportation Connexion Santé';

  @override
  String get healthExportDomainNutritionHydration => 'Nutrition & hydratation';

  @override
  String get healthExportDomainWorkouts => 'Entraînements';

  @override
  String get healthExportStateIdle => 'Inactif';

  @override
  String get healthExportStateExporting => 'Exportation';

  @override
  String get healthExportStateSuccess => 'Succès';

  @override
  String get healthExportStateFailed => 'Échoué';

  @override
  String get healthExportStateDisabled => 'Désactivé';

  @override
  String get healthExportResultComplete => 'Exportation terminée';

  @override
  String get healthExportResultFailed => 'Échec de l\'exportation';

  @override
  String get healthExportAppleHealthSubtitle =>
      'Exportation unidirectionnelle de Train Libre vers Apple Health';

  @override
  String get healthExportHealthConnectSubtitle =>
      'Exportation unidirectionnelle de Train Libre vers Health Connect';

  @override
  String get healthExportAppleHealthStatusTitle =>
      'Statut d\'exportation d\'Apple Health';

  @override
  String get healthExportHealthConnectStatusTitle =>
      'Statut d\'exportation de Health Connect';

  @override
  String get settingsBaseFoodLanguageTitle =>
      'Langue d\'affichage des aliments';

  @override
  String get settingsBaseFoodLanguageSubtitle =>
      'Choisissez la langue à utiliser pour les noms des aliments de base.';

  @override
  String get settingsBaseFoodLanguageFollowApp =>
      'Suivre la langue de l\'application';

  @override
  String get settingsBaseFoodLanguageEnglish => 'Anglais';

  @override
  String get settingsBaseFoodLanguageGerman => 'Allemand';

  @override
  String get settingsBaseFoodLanguageFrench => 'Français';

  @override
  String get settingsBaseFoodLanguageItalian => 'Italien';

  @override
  String get settingsBaseFoodLanguageJapanese => 'Japonais';

  @override
  String get aiModelLabel => 'Modèle';

  @override
  String get autoBackupStoragePickerUnavailable =>
      'Sélecteur de stockage indisponible. Veuillez redémarrer/réinstaller complètement l\'application après la mise à jour.';

  @override
  String autoBackupFolderPickerFailed(Object error) {
    return 'Échec du sélecteur de dossier : $error';
  }

  @override
  String get healthExportPermissionDenied => 'Autorisation refusée';

  @override
  String get healthExportAdapterUnavailable => 'Adaptateur indisponible';

  @override
  String get healthExportPlatformUnavailable => 'Plateforme indisponible';

  @override
  String get healthExportPlatformNotInstalled => 'Plateforme non installée';

  @override
  String get healthExportExportDisabled => 'Exportation désactivée';

  @override
  String get onboardingMacrosStepTitle => 'Macronutriments';

  @override
  String get onboardingMacrosStepSubtitle =>
      'Comment est composée votre alimentation ?';

  @override
  String get statisticsProviderAppleHealth => 'Pomme Santé';

  @override
  String get statisticsProviderHealthConnect => 'Connexion Santé';

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
  String get unit_kilograms => 'kilos';

  @override
  String get mealEditorHintExample => 'par ex. Bol de poulet';

  @override
  String get mealEditorNoIngredientsYet =>
      'Aucun pour l\'instant – à venir plus tard';

  @override
  String get foodDetailSavedBaseDb => 'Enregistré (base de données de base)';

  @override
  String foodDetailExportError(Object error) {
    return 'Erreur d\'exportation : $error';
  }

  @override
  String get stepsModulePrevious => 'Précédent';

  @override
  String get stepsModuleNext => 'Suivant';

  @override
  String get stepsModuleTotalSteps => 'Nombre total d\'étapes';

  @override
  String get stepsModuleThisWeek => 'Cette semaine';

  @override
  String get stepsModuleThisMonth => 'Ce mois-ci';

  @override
  String stepsModuleUpdated(String time) {
    return 'Mis à jour $time';
  }

  @override
  String get stepsModuleScopeSwitcherSemantics =>
      'Changer la portée de l\'étape';

  @override
  String get stepsModuleDay => 'Jour';

  @override
  String get stepsModuleWeek => 'Semaine';

  @override
  String get stepsModuleMonth => 'Mois';

  @override
  String get stepsModuleHourlyTimeline => 'Chronologie horaire';

  @override
  String get stepsModuleTotal => 'Total';

  @override
  String get stepsModuleActiveHours => 'Heures d\'activité';

  @override
  String get stepsModulePeakHour => 'Heure de pointe';

  @override
  String get stepsModuleAvgPerDay => 'Moy. / Jour';

  @override
  String get stepsModuleGoalHit => 'Objectif atteint';

  @override
  String get stepsModuleGoalDays => 'Jours d\'objectif';

  @override
  String get diarySyncingSteps => 'Étapes de synchronisation...';

  @override
  String get diaryLoadingSleep => 'Chargement du sommeil...';

  @override
  String get unit_milligrams => 'mg';

  @override
  String get scannerPermissionRequired =>
      'L\'accès à la caméra est requis pour scanner les codes-barres.';

  @override
  String get scannerPermissionPermanentlyDenied =>
      'L\'accès à la caméra est définitivement refusé. Veuillez l\'activer dans les paramètres pour scanner les codes-barres.';

  @override
  String get scannerOpenSettings => 'Ouvrir les paramètres';

  @override
  String get scannerGrantPermission => 'Continuer';

  @override
  String get scannerAlignInstruction =>
      'Alignez le code-barres horizontalement à l\'intérieur de la ligne laser rouge';

  @override
  String get about_train_libre => 'À propos de Train Libre';

  @override
  String get legal_notice => 'Mentions légales';

  @override
  String get privacy_policy => 'Charte de confidentialité';

  @override
  String get terms_of_service => 'Conditions d\'utilisation';

  @override
  String get view_in_browser => 'Afficher dans le navigateur';

  @override
  String get legal_document_version => 'Version du document';

  @override
  String get legal_document_last_updated => 'Dernière mise à jour';

  @override
  String get used_libraries => 'Bibliothèques utilisées';

  @override
  String get licensing_info => 'Informations sur la licence';

  @override
  String get project_website => 'Site Web du projet';

  @override
  String get github_repository => 'Dépôt GitHub';

  @override
  String get health_permission_dialog_title =>
      'Données de santé et confidentialité';

  @override
  String get health_permission_dialog_body =>
      'Train Libre doit lire vos données de pas pour afficher des statistiques quotidiennes/hebdomadaires. Vos données restent localement sur votre appareil ; il n\'y a pas de serveur externe.';

  @override
  String get health_permission_continue => 'Continuer';

  @override
  String get health_permission_not_now => 'Pas maintenant';

  @override
  String get welcome_privacy_title => 'Bienvenue et confidentialité';

  @override
  String get welcome_privacy_body =>
      'Pour fournir le suivi des entraînements et des analyses, nous traitons vos données de forme et d\'activité comme décrit dans notre politique de confidentialité.';

  @override
  String get i_agree_to_privacy_policy =>
      'J\'accepte expressément le traitement de mes données de santé et de forme pour le suivi des entraînements et des analyses. Je peux retirer mon consentement à tout moment dans les paramètres.';

  @override
  String get i_agree_to_optional_telemetry =>
      '(Optionnel) Je souhaite partager des statistiques d\'utilisation anonymes pour améliorer la stabilité et les fonctionnalités (aucune donnée personnelle).';

  @override
  String get welcome_back_updated_legal_title =>
      'Bon retour & Politiques mises à jour';

  @override
  String legal_update_body(String version) {
    return 'Nous avons mis à jour notre politique de confidentialité et nos conditions d\'utilisation (Version $version). Pour continuer à utiliser Train Libre, veuillez accepter les conditions mises à jour. Vos données restent conservées sur votre appareil.';
  }

  @override
  String i_agree_to_updated_privacy_policy(String version) {
    return 'J\'accepte expressément la politique de confidentialité mise à jour (v$version) et le traitement de mes données de santé.';
  }

  @override
  String get accept_and_continue => 'Accepter et continuer';

  @override
  String get by_tapping_accept_continue =>
      'En appuyant sur \"Accepter et continuer\", vous acceptez les';

  @override
  String get acceptTermsPrompt => 'J\'accepte les conditions d\'utilisation';

  @override
  String get viewTermsInline => 'Conditions d\'utilisation';

  @override
  String get accept_and_get_started => 'Accepter et commencer';

  @override
  String get by_tapping_accept =>
      'En appuyant sur « Accepter et commencer », vous acceptez nos';

  @override
  String get and_acknowledge => 'et prenez connaissance de notre';

  @override
  String get about_section => 'À propos';

  @override
  String get legal_section => 'Mentions légales et confidentialité';

  @override
  String get aiSettingsInstructionTitle =>
      'Comment fonctionne la reconnaissance des repas par l\'IA';

  @override
  String get aiSettingsInstructionBody =>
      'Cette fonctionnalité utilise l\'IA pour analyser les images d\'aliments et fournir des estimations des nutriments. Vos images ne sont envoyées au fournisseur d\'IA sélectionné que lorsque vous utilisez la fonctionnalité. Il s\'appuie sur une architecture Bring-Your-Own-Key (BYOK), conservant vos données localement sur votre appareil jusqu\'à leur analyse.';

  @override
  String get aiSettingsSetupGuideTitle => 'Guide de configuration';

  @override
  String get aiSettingsSetupGuideBody =>
      'Pour utiliser cette fonctionnalité, vous avez besoin d\'une clé API d\'un fournisseur d\'IA. Google Gemini est utilisé comme exemple principal car il propose actuellement un niveau gratuit pour les développeurs et les utilisateurs.';

  @override
  String get aiSettingsGetApiKeyButton => 'Afficher le guide de configuration';

  @override
  String get legal_document_version_value => '1.2';

  @override
  String get legal_document_last_updated_value => '20 mai 2026';

  @override
  String get muscleChest => 'Pectoraux';

  @override
  String get muscleBack => 'Dos';

  @override
  String get muscleShoulders => 'Épaules';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleQuads => 'Quadriceps';

  @override
  String get muscleHamstrings => 'Ischio-jambiers';

  @override
  String get muscleLegs => 'Jambes';

  @override
  String get muscleArms => 'Bras';

  @override
  String get muscleGlutes => 'Fessiers';

  @override
  String get muscleCalves => 'Mollets';

  @override
  String get muscleLowerBack => 'Bas du dos';

  @override
  String get muscleAbs => 'Abdos';

  @override
  String get muscleAdductors => 'Adducteurs';

  @override
  String get muscleForearms => 'Avant-bras';

  @override
  String get sleepDetailAnalysisHeader => 'Analyse détaillée';

  @override
  String get sleepMetricDurationLabel => 'Durée du sommeil';

  @override
  String get sleepMetricContinuityLabel => 'Continuité (WASO/SE)';

  @override
  String get sleepMetricDepthLabel => 'Profondeur du stade du sommeil';

  @override
  String get sleepMetricTimingLabel => 'Synchronisation circadienne';

  @override
  String get sleepMetricRegularityLabel => 'Régularité';

  @override
  String get sleepBannerTstBottleneck =>
      'Pénalité de durée de sommeil active : votre volume total de sommeil était inférieur à l\'optimum de régénération de 6,5 heures, ce qui limite la libération d\'hormones anabolisantes.';

  @override
  String get sleepBannerRemBottleneck =>
      'Pénalité de déficit de sommeil paradoxal : votre sommeil paradoxal était inférieur à 60 minutes. Cela altère la récupération neuronale et la fraîcheur mentale.';

  @override
  String get sleepBannerN3Bottleneck =>
      'Pénalité de déficit de sommeil profond : manque critique de sommeil profond N3 (<70 min). La réparation physique des tissus musculaires est sous-optimale.';

  @override
  String get sleepBannerTimingBottleneck =>
      'Pénalité de déphasage circadien : votre sommeil en plein milieu s\'est produit après 05h30. Dormir contre l’horloge interne réduit la qualité du sommeil et la sensibilité à l’insuline.';

  @override
  String get sleepBannerDefaultPenalty =>
      'Frein de protection clinique actif : votre volume de sommeil était sous-optimal (<6 h) ou le rythme circadien (début du sommeil) était gravement modifié. Le score total a été limité.';

  @override
  String get infoTdeeTitle => 'Estimateur adaptatif de calories et TDEE';

  @override
  String get infoTdeeExplanation =>
      'Estimation de votre dépense énergétique quotidienne totale (TDEE) en fonction de votre profil, des repas enregistrés et des changements de poids corporel.';

  @override
  String get infoTdeeKeyPoints =>
      '• Lisse les fluctuations de poids quotidiennes à l\'aide d\'un modèle de tendance récursif.\n• Utilise une approche d\'inspiration bayésienne pour adapter les objectifs hebdomadaires de manière conservatrice.\n• Vous alerte si la cohérence de votre journalisation est trop rare pour des mises à jour de haute confiance.';

  @override
  String get infoTdeeTechnicalTitle =>
      'Filtrage récursif bayésien et lissage métabolique';

  @override
  String get infoTdeeTechnicalExplanation =>
      'Plutôt que de s\'appuyer sur des formules statiques, Train Libre modélise votre métabolisme comme un « état caché » dynamique estimé de manière récursive. L\'entretien quotidien observé est calculé en ajustant l\'apport en fonction des changements de masse corporelle. Un coefficient de bruit de processus est ajouté les jours non enregistrés pour augmenter l\'incertitude de l\'estimation, ce qui atténue les mises à jour et empêche les distorsions dues à la rétention d\'eau à court terme.';

  @override
  String get infoRecoveryTitle => 'Estimateur de récupération musculaire';

  @override
  String get infoRecoveryExplanation =>
      'Estimation des courbes de préparation et de récupération spécifiques aux muscles en fonction du volume d\'entraînement, de l\'intensité et de la proximité de l\'échec.';

  @override
  String get infoRecoveryKeyPoints =>
      '• Tient compte du stress musculaire qui se chevauche (par exemple, le développé couché compte pour la poitrine, les triceps et les épaules).\n• Ajuste la vitesse de récupération en fonction du RIR/RPE et étend la fenêtre pour les ensembles mis en échec.\n• Calibre les fenêtres de récupération de base en fonction de la taille du groupe musculaire et des propriétés métaboliques.';

  @override
  String get infoRecoveryTechnicalTitle =>
      'Modèle équivalent de fatigue et de décroissance par morceaux';

  @override
  String get infoRecoveryTechnicalExplanation =>
      'Calcule la préparation dynamique via des courbes de décroissance non linéaires. Le suivi du volume répartit automatiquement la charge entre les groupes musculaires primaires et secondaires. La vitesse de récupération évolue en fonction de la proximité de la défaillance (RIR) et applique une extension de délai stricte pour les ensembles amenés à une défaillance absolue.';

  @override
  String get infoScientificReferencesButton =>
      'Voir les références scientifiques et sources';

  @override
  String get infoScientificDisclaimer =>
      'Cette fonctionnalité repose sur la littérature établie en sciences du sport et en modélisation métabolique. La liste complète des sources évaluées par des pairs est disponible sur notre site web.';

  @override
  String get infoAiMealTitle => 'Centre de capture de repas IA';

  @override
  String get infoAiMealExplanation =>
      'Convertit les photos de repas ou les descriptions textuelles en entrées de journal structurées et les compare à votre base de données de produits privée.';

  @override
  String get infoAiMealKeyPoints =>
      '• Traduit des descriptions imprécises (par exemple, « une tranche de pain ») en estimations de poids métriques.\n• Fait correspondre les suggestions d\'IA hors ligne avec la base de données de produits locale sur votre appareil.\n• Calcule la nutrition localement au lieu de déléguer les calculs à des serveurs externes.';

  @override
  String get infoAiMealTechnicalTitle =>
      'Hybride BYOK AI et correspondance Jaro-Winkler';

  @override
  String get infoAiMealTechnicalExplanation =>
      'Utilise un modèle de confidentialité Bring-Your-Own-Key (BYOK). L’IA fonctionne strictement comme une couche de suggestions. La correspondance est effectuée hors ligne à l\'aide d\'un filtre Jaro-Winkler tokenisé par rapport à la base de données SQLite locale. Il est strictement interdit au fournisseur d\'IA d\'effectuer des calculs nutritionnels via les invites du système.';

  @override
  String get infoSleepTitle => 'Qualité du sommeil (SHS v3.5)';

  @override
  String get infoSleepExplanation =>
      'Calcule un indice de sommeil complet à partir de la quantité, de la continuité, de la profondeur, du timing et de la régularité quotidienne.';

  @override
  String get infoSleepKeyPoints =>
      '• Regroupe cinq dimensions cliniques à l\'aide d\'une somme pondérée.\n• Ajuste automatiquement les exigences si votre portable ne fournit pas d\'étapes spécifiques ou de données d\'efficacité.\n• Vous protège via des multiplicateurs à plafond souple qui limitent le score total si un domaine critique (comme le sommeil paradoxal ou profond) est compromis.';

  @override
  String get infoSleepTechnicalTitle =>
      'Base de référence pondérée et soft-caps continus';

  @override
  String get infoSleepTechnicalExplanation =>
      'Agrége cinq domaines principaux à l\'aide d\'une somme linéaire pondérée : durée (30 %), continuité (20 %), architecture (25 %), synchronisation (15 %) et régularité (10 %). Pour éviter des moyennes trompeuses lorsqu\'un domaine clinique est compromis, le score final est dégradé si des goulots d\'étranglement importants sont détectés au cours des phases de sommeil ou du timing circadien.';

  @override
  String get tdeeRecalculationNotificationTitle => 'TDEE recalculé';

  @override
  String tdeeRecalculationNotificationBody(
      int calories, int protein, int carbs, int fat) {
    return 'Nouveaux objectifs quotidiens : $calories kcal | ${protein}g Protéine | ${carbs}g Glucides | ${fat}g Graisse';
  }

  @override
  String recommendationBannerText(String delta) {
    return 'Nouveaux objectifs disponibles ($delta kcal).';
  }

  @override
  String get recommendationBannerApply => 'Appliquer';

  @override
  String get cancelingAndRollingBack =>
      'Annulation, retour en arrière sécurisé...';

  @override
  String get sleepSyncTitle => 'Synchronisation de l\'historique du sommeil...';

  @override
  String get backupExportTitle => 'Exportation de la sauvegarde...';

  @override
  String get backupImportTitle => 'Importation de la sauvegarde...';

  @override
  String progressImportingNight(int index, int total) {
    return 'Importation de la nuit $index/$total...';
  }

  @override
  String progressExportingTable(String table) {
    return 'Exportation de $table...';
  }

  @override
  String progressImportingTable(String table) {
    return 'Restauration de $table...';
  }

  @override
  String get shareDailyLogTitle => 'Journal quotidien';

  @override
  String get shareSleepStartTime => 'Heure de coucher';

  @override
  String get shareSleepEndTime => 'Heure de réveil';

  @override
  String get shareSleepDeep => 'Sommeil profond';

  @override
  String get shareSleepLight => 'Sommeil léger';

  @override
  String get shareSleepRem => 'Sommeil paradoxal';

  @override
  String get shareSleepAwake => 'Éveillé/Interruptions';

  @override
  String get shareTotalWater => 'Total eau/fluides';

  @override
  String get shareNutritionSummary => 'Résumé de la nutrition';

  @override
  String get shareSleepEfficiency => 'Efficacité';

  @override
  String get shareSleepRestingHeartRate => 'Fréquence cardiaque au repos';

  @override
  String get shareAsTextOrCopy => 'Partager / copier sous forme de texte';

  @override
  String get editExercise => 'Modifier l\'exercice';

  @override
  String exerciseCopyCreated(String exerciseName) {
    return 'Copie de \'$exerciseName\' créée.';
  }

  @override
  String get copySystemExerciseTitle => 'Copier l\'exercice système';

  @override
  String get copySystemExerciseBody =>
      'Cet exercice est fourni par le système et ne peut pas être modifié directement. Souhaitez-vous en créer une copie personnalisée pour le modifier ?';

  @override
  String get createCopyAndEdit => 'Créer une copie et modifier';

  @override
  String get profileEdit => 'Modifier le profil';

  @override
  String get selectBirthday => 'Sélectionner la date de naissance';

  @override
  String get exerciseNoteTitle => 'Note de l\'exercice';

  @override
  String get exerciseNoteHint => 'Saisir des notes ou des indices...';

  @override
  String get deleteNoteTooltip => 'Supprimer la note';

  @override
  String get emptyStateAddFirstExerciseSubtitle =>
      'Ajoutez un exercice pour commencer à enregistrer.';

  @override
  String get syncRoutineTitle => 'Mettre à jour la routine ?';

  @override
  String get syncRoutineSubtitle =>
      'Changements de structure ou d\'ordre détectés.';

  @override
  String syncRoutineBody(String routineName) {
    return 'Souhaitez-vous mettre à jour la routine \'$routineName\' avec les données de la séance en cours (exercices, ordre, séries) ?';
  }

  @override
  String get discard => 'Abandonner';

  @override
  String get updateNow => 'Mettre à jour maintenant';

  @override
  String get syncRoutineSuccess => 'Routine mise à jour avec succès !';

  @override
  String syncRoutineError(String error) {
    return 'Erreur lors de la mise à jour de la routine : $error';
  }

  @override
  String createRoutineError(String error) {
    return 'Erreur lors de la création de la routine : $error';
  }

  @override
  String nutritionPerQuantity(String quantity) {
    return 'Valeurs nutritionnelles pour ${quantity}g';
  }

  @override
  String get settingsLocalModelName => 'Nom du modèle local';

  @override
  String get settingsCustomBaseUrl => 'URL de base personnalisée';

  @override
  String get settingsCustomModelName => 'Nom du modèle personnalisé';

  @override
  String get settingsAiFoodNameLanguage =>
      'Langue des noms d\'aliments par l\'IA';

  @override
  String get settingsRequestTimeout => 'Délai d\'attente de la demande';

  @override
  String settingsSeconds(int seconds) {
    return '$seconds secondes';
  }

  @override
  String get semanticsApplyRecommendation => 'Appliquer la recommandation';

  @override
  String get semanticsDismissBanner => 'Fermer la bannière';

  @override
  String get importedWorkout => 'Séance importée';

  @override
  String get unknownExercise => 'Exercice inconnu';

  @override
  String get devExportBaseDb => 'Exporter la base de données de base';

  @override
  String get initCheckingExercises => 'Vérification des exercices...';

  @override
  String get initLoadingRemoteManifest => 'Chargement du manifeste distant...';

  @override
  String get initExercisesUpToDate => 'Exercices à jour';

  @override
  String get initNoDownloadRequired => 'Aucun téléchargement distant requis.';

  @override
  String get initLoadingExercises => 'Chargement des exercices...';

  @override
  String initDownloadingRemoteCatalog(String version) {
    return 'Téléchargement du catalogue d\'exercices distant $version...';
  }

  @override
  String get initPreparingImport =>
      'Préparation du téléchargement pour l\'importation...';

  @override
  String get initExercisesReady => 'Exercices prêts';

  @override
  String initImportingRemoteCatalog(String version) {
    return 'Importation du catalogue d\'exercices distant $version...';
  }

  @override
  String initCheckingProductDatabase(String country) {
    return 'Vérification de la base de données produits ($country)...';
  }

  @override
  String get initProductDatabaseUpToDate => 'Base de données produits à jour';

  @override
  String get initLoadingProductDatabase =>
      'Chargement de la base de données produits...';

  @override
  String initDownloadingProductBundle(String version) {
    return 'Téléchargement du pack de produits distant $version...';
  }

  @override
  String get initProductDatabaseReady => 'Base de données produits prête';

  @override
  String initImportingProductBundle(String version) {
    return 'Importation du pack de produits distant $version...';
  }

  @override
  String get initNoOffBundle =>
      'Aucun pack OFF/distant disponible. Les données OFF locales existantes restent inchangées.';

  @override
  String initEntriesProgress(String processed, String totalCount) {
    return '$processed / $totalCount entrées';
  }

  @override
  String initUpdateTask(String task) {
    return 'Mettre à jour $task';
  }

  @override
  String initCheckingTask(String task) {
    return 'Vérification de $task...';
  }

  @override
  String initTaskUpToDate(String task) {
    return '$task à jour';
  }

  @override
  String get initInitializing => 'Initialisation...';

  @override
  String get initPreparation => 'Préparation...';

  @override
  String get initReady => 'Prêt';

  @override
  String yearsOld(int age) {
    return '$age ans';
  }

  @override
  String get customFoodsTitle => 'Aliments personnalisés';

  @override
  String get deleteFoodConfirmTitle => 'Supprimer l\'aliment';

  @override
  String get deleteFoodConfirmBody =>
      'Êtes-vous sûr de vouloir supprimer cet aliment personnalisé ? Les journaux historiques ne seront pas affectés.';

  @override
  String get foodItemDeleted => 'Aliment supprimé';

  @override
  String get copySystemFoodTitle => 'Copier l\'aliment système';

  @override
  String get copySystemFoodBody =>
      'Les aliments système ne peuvent pas être modifiés directement. Souhaitez-vous créer une copie personnalisée et la modifier ?';

  @override
  String foodCopyCreated(String name) {
    return 'Copie créée : $name';
  }

  @override
  String get nutritionPer100g => 'Valeurs nutritionnelles pour 100g';

  @override
  String nutritionPerPortion(int grams) {
    return 'Valeurs nutritionnelles par portion (${grams}g)';
  }

  @override
  String get workoutConflictTitle => 'Entraînement en cours';

  @override
  String get workoutConflictContent =>
      'Vous avez déjà une séance d\'entraînement active. Voulez-vous la reprendre ou l\'abandonner pour en commencer une nouvelle ?';

  @override
  String get resumeWorkoutButton => 'Reprendre l\'entraînement';

  @override
  String get discardAndStartButton => 'Abandonner et recommencer';

  @override
  String get profileTapToSetUp => 'Appuyer pour configurer';

  @override
  String get customLabel => 'Personnalisé';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get languageAuto => 'Auto';

  @override
  String aiValidationCostEstimation(num tokenCount) {
    return 'Coût : ~$tokenCount jetons';
  }

  @override
  String showAllWithCount(num count) {
    return 'Tout afficher ($count)';
  }

  @override
  String repsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count répétitions',
      one: '1 répétition',
    );
    return '$_temp0';
  }

  @override
  String get offDownloadTitle =>
      'Télécharger les catalogues de base de données';

  @override
  String get offDownloadBody =>
      'Pour accéder à la recherche complète de produits hors ligne, au scanner de codes-barres et aux fonctionnalités d\'IA, veuillez initialiser les catalogues locaux. Vous téléchargerez les dernières versions de la base de données depuis GitHub.';

  @override
  String get offDownloadConfirm => 'Télécharger maintenant';

  @override
  String get offDownloadCancel => 'Pas maintenant';

  @override
  String get offDownloadCTA => 'Télécharger la base de données';

  @override
  String get offPlaceholderText =>
      'Les fonctionnalités de nutrition nécessitent le catalogue de base de données local.';

  @override
  String get backupImportLockedTitle => 'Catalogue de base de données requis';

  @override
  String get backupImportLockedBody =>
      'Avant d\'importer une sauvegarde, le catalogue d\'exercices et le catalogue nutritionnel doivent être entièrement téléchargés et initialisés pour éviter toute incohérence des données. Veuillez d\'abord télécharger les bases de données requises.';

  @override
  String get wgerPlaceholderText =>
      'Le catalogue d\'exercices nécessite le téléchargement du catalogue de base de données local.';

  @override
  String get onboardingRegionTitle => 'Sélectionner la région';

  @override
  String get onboardingRegionExplanation =>
      'Sélectionnez le pays où vous achetez vos courses. Cela garantit que nous téléchargeons la base de données Open Food Facts correcte pour vos produits locaux.';

  @override
  String get onboardingRegionSettingsHint =>
      'Vous pouvez modifier cela à tout moment plus tard dans Paramètres → Nutrition → Région de la base de données.';

  @override
  String get clearSearch => 'Effacer la recherche';

  @override
  String rollingDaysLabel(int days) {
    return 'Les $days derniers jours (glissant)';
  }

  @override
  String get muscleTraps => 'Trapèzes';

  @override
  String get muscleObliques => 'Obliques';

  @override
  String get icloudSyncErrorTitle => 'Échec de la synchronisation iCloud';

  @override
  String get icloudSyncErrorHelp =>
      'Veuillez vous assurer que iCloud Drive est activé dans les réglages système d\'iOS sous Réglages -> [Votre Nom] -> iCloud -> iCloud Drive.';

  @override
  String get icloudSyncErrorCopyLog =>
      'Copier le journal technique des erreurs';

  @override
  String get icloudSyncErrorClose => 'Fermer';

  @override
  String get icloudSyncErrorCopied =>
      'Journal des erreurs copié dans le presse-papiers !';

  @override
  String icloudLastSynced(String date) {
    return 'Dernière synchronisation : $date';
  }

  @override
  String get icloudNeverSynced => 'Jamais synchronisé';

  @override
  String get emptyStateDiaryColdStartTitle => 'Bienvenue dans votre Journal !';

  @override
  String get emptyStateDiaryColdStartSubtitle =>
      'Gardez une trace de votre alimentation et de votre hydratation ici.';

  @override
  String get emptyStateActiveGapOverlay =>
      'Aucune donnée disponible pour cette période';

  @override
  String get emptyStateDiaryColdStartCallToAction =>
      'Enregistrez votre première entrée ici';

  @override
  String get statisticsColdStartTitle => 'Bienvenue dans vos statistiques !';

  @override
  String get statisticsColdStartSubtitle =>
      'Vos progrès seront visualisés ici dès que vous aurez enregistré vos premiers entraînements, repas ou suivi vos pas et votre sommeil.';

  @override
  String get statisticsActiveGapTitle => 'Aucune donnée disponible';

  @override
  String get reviewPromptTitle => 'Aimez-vous Train Libre ?';

  @override
  String get reviewPromptSubtitle =>
      'Vos retours nous aident à améliorer l\'application sans publicité ni traqueurs.';

  @override
  String get reviewPromptYes => 'Oui, j\'aime bien';

  @override
  String get reviewPromptNo => 'Non, pas vraiment';

  @override
  String get reviewPromptLater => 'Rappelez-moi plus tard';

  @override
  String get updateAvailableTitle => 'Mise à jour disponible';

  @override
  String get statusReady => 'Prêt';

  @override
  String get statusRequired => 'Requis';

  @override
  String get updatesAvailableBody =>
      'De nouvelles mises à jour sont disponibles pour vos catalogues locaux. Souhaitez-vous les mettre à jour maintenant ?';

  @override
  String get exerciseCatalogWger => 'Catalogue d\'exercices (wger)';

  @override
  String get nutritionCatalogOff => 'Catalogue de nutrition (OFF)';

  @override
  String get workoutImportZeroNew =>
      '0 nouvel entraînement importé (tous existaient déjà).';

  @override
  String get telemetryDeleteDialogTitle =>
      'Supprimer les données de télémétrie ?';

  @override
  String get telemetryDeleteDialogBody =>
      'Voulez-vous vraiment supprimer vos données de télémétrie passées ?\n\nCe qui suit va se produire :\n• Tous les UUID d\'appareil, ID de session et compteurs locaux enregistrés sur cet appareil seront réinitialisés.\n• Une demande de suppression (\$delete_person) sera envoyée aux serveurs PostHog dans l\'UE pour y supprimer vos données.\n• Le SDK de télémétrie sera entièrement réinitialisé.';

  @override
  String get telemetryDeleteConfirmButton => 'Supprimer les données maintenant';

  @override
  String liveActivitySetPosition(int index, int total) {
    return 'Série $index sur $total';
  }

  @override
  String get liveActivityOverdueLabel => 'en retard de';

  @override
  String get liveActivityRirLabel => 'RIR';

  @override
  String get liveActivityRpeLabel => 'RPE';

  @override
  String get liveActivityAddExercise => 'Ajouter un exercice';

  @override
  String get liveActivityOpenApp => 'Ouvrir l\'app';

  @override
  String get unit_pounds => 'lbs';

  @override
  String get unit_kilometers => 'km';

  @override
  String get unit_miles => 'mi';

  @override
  String get liveActivitySkipShort => 'Passer';

  @override
  String get whatsNewTitle => 'Nouveautés';

  @override
  String get whatsNewSubtitle =>
      'Voici ce qui a changé depuis ta dernière mise à jour.';

  @override
  String whatsNewVersionHeader(String version) {
    return 'Version $version';
  }

  @override
  String get whatsNewCta => 'C\'est parti';

  @override
  String get whatsNewAboutRow => 'Nouveautés';

  @override
  String get whatsNewAboutRowSubtitle =>
      'Points forts de cette version et des précédentes';

  @override
  String get mealAnalysisPreparing => 'Préparation de la prise de vue';

  @override
  String get mealAnalysisAnalyzing => 'Analyse du repas';

  @override
  String get mealAnalysisMatching => 'Correspondance des ingrédients';

  @override
  String get mealAnalysisFailed => 'Cela n\'a pas fonctionné';

  @override
  String get mealAnalysisProcessingTag => 'AI VISION PROCESSING';

  @override
  String get aiScannerTitle => 'Scanner IA';

  @override
  String get aiCaptureAnalyzing => 'Analyse…';

  @override
  String aiCaptureAnalyzeMeal(int count) {
    return 'Analyser le repas ($count)';
  }

  @override
  String get aiCaptureAnalyzeText => 'Analyser le texte';

  @override
  String get aiCaptureDescribeHint =>
      'Décris le repas (p. ex. 2 œufs avec du pain grillé)…';

  @override
  String get aiCaptureBarcodeDetected => 'Code-barres détecté';

  @override
  String get aiCaptureLogBarcode => 'Ajouter';

  @override
  String aiCaptureBarcodeFallback(String code) {
    return 'Code-barres $code';
  }

  @override
  String get aiCaptureMoveCloser => 'Approche-toi un peu';

  @override
  String get aiCaptureMoveAway => 'Éloigne-toi un peu';

  @override
  String get aiCaptureOpenSettings => 'Ouvrir les réglages';

  @override
  String get voiceDictationTitle => 'Dicter le repas';

  @override
  String get voiceHoldToTalk => 'Maintiens pour parler';

  @override
  String get voiceSpeakNow => 'Parle maintenant — relâche pour terminer';

  @override
  String get voiceExampleStandalone =>
      'p. ex. « Un kebab aux légumes avec pain plat et sauce à l’ail »';

  @override
  String get voiceExampleWithPhoto =>
      'Ajoute ce que la photo ne montre pas — p. ex. « frit dans deux cuillères d’huile d’olive »';

  @override
  String get voiceNetworkNotice =>
      'Cet appareil ne reconnaît pas la parole localement. L’enregistrement est envoyé à la reconnaissance vocale du système pour être transcrit.';

  @override
  String get voiceTapToRecord => 'Touchez pour enregistrer';

  @override
  String get voiceTapToFinish => 'À l’écoute — touchez pour terminer';

  @override
  String get voiceStarting => 'Un instant…';

  @override
  String get voiceTidyingUp => 'Nettoyage du texte…';

  @override
  String get voiceNothingHeard =>
      'Rien n’a été reconnu. Réessayez ou saisissez le texte.';

  @override
  String get voiceLanguage => 'Langue';

  @override
  String get voiceLanguageTitle => 'Langue de dictée';

  @override
  String get voiceLanguageSystem => 'Comme l’appareil';

  @override
  String get voiceLanguageHint =>
      'Choisissez la langue que vous parlez, pas celle de l’app.';

  @override
  String get voiceCleanedNotice => 'Mots de remplissage supprimés';

  @override
  String get voiceRetake => 'Réenregistrer';

  @override
  String voiceTidiedIn(String seconds) {
    return 'Mis au propre par l’IA en $seconds s';
  }

  @override
  String get aiDepthImageTitle => 'Envoyer aussi la carte de profondeur';

  @override
  String get aiDepthImageSubtitle =>
      'Joint le relief en fausses couleurs comme deuxième image, pour que le modèle juge aussi la hauteur et pas seulement le contour. Coûte une image de plus par analyse.';

  @override
  String get aiVoiceTidyTitle => 'Mettre la dictée au propre avec l’IA';

  @override
  String get aiVoiceTidySubtitle =>
      'Après avoir parlé, le texte est corrigé et découpé en points. Coûte une requête et quelques secondes.';

  @override
  String get voicePermissionTitle => 'Microphone et reconnaissance vocale';

  @override
  String get voicePermissionBody =>
      'Pour dicter un repas, Train Libre a besoin du microphone pendant l’enregistrement et de la reconnaissance vocale pour transcrire vos paroles. La reconnaissance se fait sur votre appareil dès que possible. Rien n’est enregistré ni conservé.';

  @override
  String get voicePermissionContinue => 'Continuer';

  @override
  String get voiceApplyText => 'Utiliser ce texte';

  @override
  String get voiceTranscriptHint => 'Texte reconnu — modifiable ici';

  @override
  String get voiceUnavailablePermission =>
      'La dictée nécessite l’accès au micro et à la reconnaissance vocale. Tu peux toujours saisir le texte.';

  @override
  String get voiceUnavailableUnsupported =>
      'Cet appareil ne propose pas de reconnaissance vocale. Tu peux saisir le texte.';

  @override
  String get voiceUnavailableFailed =>
      'La reconnaissance vocale n’a pas pu démarrer. Tu peux saisir le texte.';

  @override
  String get mealFallbackTitle => 'Repas';

  @override
  String mealIngredientCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingrédients',
      one: '1 ingrédient',
    );
    return '$_temp0';
  }

  @override
  String get mealDetailOptions => 'Options';

  @override
  String get mealDetailAddIngredient => 'Ajouter un ingrédient';

  @override
  String get mealDetailSaveAsTemplate => 'Enregistrer comme modèle';

  @override
  String get mealDetailSavedAsTemplate => 'Enregistré comme modèle de repas.';

  @override
  String get mealDetailChangeMealType => 'Changer le type de repas';

  @override
  String get mealDetailSelectMealType => 'Choisir le type de repas';

  @override
  String get mealDetailAmountInGrams => 'Quantité en grammes';

  @override
  String get mealDetailApply => 'Appliquer';

  @override
  String get mealDeleteQuestion => 'Que faire de ce repas ?';

  @override
  String get mealDeleteUngroupTitle => 'Dissoudre uniquement le groupe';

  @override
  String mealDeleteUngroupBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'La photo et le groupe sont supprimés. Les $count entrées restent seules dans le journal — tes totaux du jour ne changent pas.',
      one:
          'La photo et le groupe sont supprimés. L’entrée reste seule dans le journal — tes totaux du jour ne changent pas.',
    );
    return '$_temp0';
  }

  @override
  String get mealDeleteAllTitle => 'Supprimer le repas et ses entrées';

  @override
  String mealDeleteAllBody(int count, int kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'La photo, le groupe et les $count entrées disparaissent du journal. $kcal kcal sont retirées de ta journée.',
      one:
          'La photo, le groupe et l’entrée disparaissent du journal. $kcal kcal sont retirées de ta journée.',
    );
    return '$_temp0';
  }

  @override
  String get reanalysisTitle => 'Nouveau résultat';

  @override
  String get reanalysisSubtitle =>
      'C’est toi qui décides ce qui reste enregistré.';

  @override
  String get reanalysisPrevious => 'ACTUEL';

  @override
  String get reanalysisNew => 'NOUVEAU';

  @override
  String get reanalysisKeepPrevious => 'Garder l’actuel';

  @override
  String get reanalysisApplyNew => 'Utiliser le nouveau';

  @override
  String get reanalysisDiffHint => 'Marqué = diffère de ce qui est enregistré';

  @override
  String get aiReviewDiscardTitle => 'Abandonner ce repas ?';

  @override
  String get aiReviewDiscardBody =>
      'L’analyse n’a pas été enregistrée et sera perdue.';

  @override
  String get aiLidarScaleTitle => 'Envoyer l’échelle LiDAR';

  @override
  String get aiLidarScaleSubtitle =>
      'Mesure la distance et la taille du cadre en centimètres et les transmet à l’IA. Désactive pour comparer si l’estimation s’améliore vraiment.';

  @override
  String get mealPhotoStorageSection => 'Photos de repas (stockage)';

  @override
  String get mealPhotoRetentionTitle => 'Durée de conservation';

  @override
  String get mealPhotoRetentionBody =>
      'Les photos sont supprimées automatiquement à l’expiration du délai. Les entrées nutritionnelles du journal sont conservées.';

  @override
  String mealPhotoRetentionDays(int days) {
    return '$days jours';
  }

  @override
  String get mealPhotoRetentionDefaultSuffix => '(par défaut)';

  @override
  String get mealPhotoRetentionUnlimited => 'Illimité';

  @override
  String get mealPhotoRetentionSaved => 'Durée de conservation enregistrée.';

  @override
  String get mealPhotoDeleteAll => 'Supprimer toutes les photos locales';

  @override
  String get mealPhotoDeleteAllTitle =>
      'Supprimer toutes les photos de repas ?';

  @override
  String get mealPhotoDeleteAllBody =>
      'Seuls les fichiers image sont supprimés de l’appareil. Tes entrées et calories dans le journal restent inchangées.';

  @override
  String get mealPhotoDeleted => 'Photos supprimées.';

  @override
  String get speechSectionTitle => 'Saisie vocale et dictée';

  @override
  String get speechOnDeviceActive =>
      'Reconnaissance vocale sur l’appareil active';

  @override
  String get speechOnDeviceBody =>
      'Les repas dictés (« 2 œufs avec pain grillé et café ») sont transcrits directement sur ton appareil et restent privés.';

  @override
  String get aiCaptureTourStepShutterTitle => 'Photographier le repas';

  @override
  String get aiCaptureTourStepShutterDesc =>
      'Prends jusqu\'à 4 photos sous différents angles avec le déclencheur. Sur les appareils compatibles, le LiDAR capture automatiquement les données de profondeur.';

  @override
  String get aiCaptureTourStepBarcodeTitle =>
      'Détection automatique de code-barres';

  @override
  String get aiCaptureTourStepBarcodeDesc =>
      'Place les aliments emballés devant la caméra : le code-barres est reconnu instantanément en temps réel. Ce bouton permet d\'activer ou désactiver le scanner.';

  @override
  String get aiCaptureTourBarcodeDemoProduct => 'Flocons d\'avoine bio 500g';

  @override
  String get aiCaptureTourBarcodeDemoHint =>
      'Voici comment s\'affiche la détection de code-barres !';

  @override
  String get aiCaptureTourStepGalleryTitle => 'Photos depuis la galerie';

  @override
  String get aiCaptureTourStepGalleryDesc =>
      'Tu as déjà pris des photos ? Sélectionne jusqu\'à 4 images directement depuis ta photothèque.';

  @override
  String get aiCaptureTourStepVoiceTitle => 'Dictée vocale';

  @override
  String get aiCaptureTourStepVoiceDesc =>
      'Appuie sur le micro pour énoncer ingrédients, marques ou portions (ex. « 200g de poulet avec du riz »). L\'IA nettoie et analyse ton dictat automatiquement.';

  @override
  String get aiCaptureTourStepTextTitle => 'Texte et notes';

  @override
  String get aiCaptureTourStepTextDesc =>
      'Ajoute des précisions ou décris ton repas entièrement par texte si tu ne souhaites pas prendre de photo.';

  @override
  String get aiCaptureTourStepAnalyzeTitle => 'Analyse IA intelligente';

  @override
  String get aiCaptureTourStepAnalyzeDesc =>
      'Dès qu\'une photo, dictée ou note est prête, appuie sur Analyser. L\'IA détecte les aliments, estime les portions et fait le lien avec tes macros.';

  @override
  String get aiCaptureTourReplayTooltip => 'Revoir l\'introduction';

  @override
  String get workoutPhotoAdd => 'Ajouter une photo';

  @override
  String get workoutPhotoTake => 'Prendre une photo';

  @override
  String get workoutPhotoFromLibrary => 'Choisir dans la bibliothèque';

  @override
  String get workoutPhotoRemove => 'Supprimer la photo';

  @override
  String get workoutPhotoRemoveConfirm =>
      'Voulez-vous vraiment supprimer cette photo ?';

  @override
  String get workoutPhotoLimitReached => 'Maximum de 4 photos atteint';

  @override
  String workoutPhotoPagination(int current, int total) {
    return '$current sur $total';
  }
}
