// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get selectDateTitle => 'Select Date';

  @override
  String get selectTimeTitle => 'Select Time';

  @override
  String get selectDateTimeTitle => 'Select Date & Time';

  @override
  String get mealDetailChangeDateTime => 'Change date and time';

  @override
  String mealMovedToDate(String date) {
    return 'Meal moved to $date';
  }

  @override
  String get removeTimer => 'Remove Timer';

  @override
  String get noTimerLabel => 'No Timer';

  @override
  String get appTitle => 'Train Libre';

  @override
  String get bannerText => 'Recommendation / Current Workout';

  @override
  String get calories => 'Calories';

  @override
  String get water => 'Water';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get steps => 'Steps';

  @override
  String get daily => 'Daily';

  @override
  String get nowLabel => 'Now';

  @override
  String get today => 'Today';

  @override
  String get workoutSection => 'Workout section - not yet implemented';

  @override
  String get addMenuTitle => 'What do you want to add?';

  @override
  String get addFoodOption => 'add Food';

  @override
  String get addLiquidOption => 'add Liquid';

  @override
  String get searchHintText => 'Search...';

  @override
  String get mealtypeBreakfast => 'Breakfast';

  @override
  String get mealtypeLunch => 'Lunch';

  @override
  String get mealtypeDinner => 'Dinner';

  @override
  String get mealtypeSnack => 'Snack';

  @override
  String get waterHeader => 'Water & Drinks';

  @override
  String get openFoodFactsSource => 'Data from Open Food Facts';

  @override
  String get tabRecent => 'Recent';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get fabCreateOwnFood => 'Custom Food';

  @override
  String get recentEmptyState =>
      'Your recently used food items\nwill appear here.';

  @override
  String get favoritesEmptyState =>
      'You don\'t have any favorites yet.\nMark a food with the heart icon to see it here.';

  @override
  String get searchInitialHint => 'Please enter a search term.';

  @override
  String get searchNoResults => 'No results found.';

  @override
  String get createFoodScreenTitle => 'Create Custom Food';

  @override
  String get formFieldName => 'Name of the food';

  @override
  String get formFieldBrand => 'Brand (optional)';

  @override
  String get formSectionMainNutrients => 'Main Nutrients (per 100g)';

  @override
  String get formFieldCalories => 'Calories (kcal)';

  @override
  String get formFieldProtein => 'Protein (g)';

  @override
  String get formFieldCarbs => 'Carbohydrates (g)';

  @override
  String get formFieldFat => 'Fat (g)';

  @override
  String get formSectionOptionalNutrients =>
      'Additional Nutrients (optional, per 100g)';

  @override
  String get formFieldSugar => 'Of which sugars (g)';

  @override
  String get formFieldFiber => 'Fiber (g)';

  @override
  String get formFieldKj => 'Kilojoules (kJ)';

  @override
  String get formFieldSalt => 'Salt (g)';

  @override
  String get formFieldSodium => 'Sodium (mg)';

  @override
  String get formFieldCalcium => 'Calcium (mg)';

  @override
  String get buttonSave => 'Save';

  @override
  String get validatorPleaseEnterName => 'Please enter a name.';

  @override
  String get validatorPleaseEnterNumber => 'Please enter a valid number.';

  @override
  String snackbarSaveSuccess(String foodName) {
    return '$foodName was saved successfully.';
  }

  @override
  String get foodDetailSegmentPortion => 'Portion';

  @override
  String get foodDetailSegment100g => '100g';

  @override
  String get sugar => 'Sugar';

  @override
  String get fiber => 'Fiber';

  @override
  String get salt => 'Salt';

  @override
  String get caffeine => 'Caffeine';

  @override
  String get explorerScreenTitle => 'Food Explorer';

  @override
  String get nutritionScreenTitle => 'Nutrition Analysis';

  @override
  String get entriesForDateRangeLabel => 'Entries for';

  @override
  String get noEntriesForPeriod => 'No entries for this period yet.';

  @override
  String get waterEntryTitle => 'Water';

  @override
  String get profileScreenTitle => 'Profile';

  @override
  String get profileDailyGoals => 'Daily Goals';

  @override
  String get profileDailyGoalsCL => 'DAILY GOALS';

  @override
  String get snackbarGoalsSaved => 'Goals saved successfully!';

  @override
  String get measurementsScreenTitle => 'Measurements';

  @override
  String get measurementsEmptyState =>
      'No measurements recorded yet.\nStart with the \'+\' button.';

  @override
  String get addMeasurementDialogTitle => 'Add New Measurement';

  @override
  String get formFieldMeasurementType => 'Type of Measurement';

  @override
  String formFieldMeasurementValue(Object unit) {
    return 'Value ($unit)';
  }

  @override
  String get validatorPleaseEnterValue => 'Please enter a value';

  @override
  String get measurementWeight => 'Body Weight';

  @override
  String get measurementFatPercent => 'Body Fat';

  @override
  String get measurementNeck => 'Neck';

  @override
  String get measurementShoulder => 'Shoulder';

  @override
  String get measurementChest => 'Chest';

  @override
  String get measurementLeftBicep => 'Left Bicep';

  @override
  String get measurementRightBicep => 'Right Bicep';

  @override
  String get measurementLeftForearm => 'Left Forearm';

  @override
  String get measurementRightForearm => 'Right Forearm';

  @override
  String get measurementAbdomen => 'Abdomen';

  @override
  String get measurementWaist => 'Waist';

  @override
  String get measurementHips => 'Hips';

  @override
  String get measurementLeftThigh => 'Left Thigh';

  @override
  String get measurementRightThigh => 'Right Thigh';

  @override
  String get measurementLeftCalf => 'Left Calf';

  @override
  String get measurementRightCalf => 'Right Calf';

  @override
  String get drawerMenuTitle => 'Train Libre Menu';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerFoodExplorer => 'Food Explorer';

  @override
  String get drawerDataManagement => 'Data Backup';

  @override
  String get drawerMeasurements => 'Measurements';

  @override
  String get dataManagementTitle => 'Data Backup';

  @override
  String get exportCardTitle => 'Export Data';

  @override
  String get exportCardDescription =>
      'Saves all your journal entries, favorites, and custom foods into a single backup file.';

  @override
  String get exportCardButton => 'Create Backup';

  @override
  String get importCardTitle => 'Import Data';

  @override
  String get importCardDescription =>
      'Restores your data from a previously created backup file. WARNING: All data currently stored in the app will be overwritten!';

  @override
  String get importCardButton => 'Restore Backup';

  @override
  String get recommendationDefault => 'Track your first meal!';

  @override
  String recommendationOverTarget(Object count, Object difference) {
    return 'Last $count days: +$difference kcal over target';
  }

  @override
  String recommendationUnderTarget(Object count, Object difference) {
    return 'Last $count days: $difference kcal under target';
  }

  @override
  String recommendationOnTarget(Object count) {
    return 'Last $count days: Target achieved ✅';
  }

  @override
  String get recommendationFirstEntry => 'Great, your first entry is logged!';

  @override
  String get dialogConfirmTitle => 'Confirmation Required';

  @override
  String get dialogConfirmImportContent =>
      'Do you really want to restore data from this backup?\n\nWARNING: All your current entries, favorites, and custom foods will be permanently deleted and replaced.';

  @override
  String get dialogButtonCancel => 'Cancel';

  @override
  String get dialogButtonOverwrite => 'Yes, overwrite all';

  @override
  String get snackbarNoFileSelected => 'No file selected.';

  @override
  String get snackbarImportSuccessTitle => 'Import successful!';

  @override
  String get snackbarImportSuccessContent =>
      'Your data has been restored. It is recommended to restart the app for a correct display.';

  @override
  String get snackbarButtonOK => 'OK';

  @override
  String get snackbarImportError => 'Error while importing data.';

  @override
  String get snackbarExportSuccess =>
      'Backup file has been passed to the system. Please choose a location to save.';

  @override
  String get snackbarExportFailed => 'Export canceled or failed.';

  @override
  String get profileUserHeight => 'Height (cm)';

  @override
  String get workoutRoutinesTitle => 'Routines';

  @override
  String get workoutHistoryTitle => 'Workout History';

  @override
  String get workoutHistoryButton => 'History';

  @override
  String get emptyRoutinesTitle => 'No Routines Found';

  @override
  String get emptyRoutinesSubtitle =>
      'Create your first routine or start a blank workout.';

  @override
  String get createFirstRoutineButton => 'Create First Routine';

  @override
  String get startEmptyWorkoutButton => 'Free Workout';

  @override
  String get editRoutineSubtitle => 'Tap to edit, or start the workout.';

  @override
  String get startButton => 'Start';

  @override
  String get addRoutineButton => 'New Routine';

  @override
  String get freeWorkoutTitle => 'Free Workout';

  @override
  String get finishWorkoutButton => 'Finish';

  @override
  String get addSetButton => 'Add Set';

  @override
  String get addExerciseToWorkoutButton => 'Add Exercise to Workout';

  @override
  String get lastTimeLabel => 'Last Time';

  @override
  String get setLabel => 'Set';

  @override
  String kgLabel(String unit) {
    return 'Weight ($unit)';
  }

  @override
  String get repsLabel => 'Reps';

  @override
  String cardioDistanceLabel(String unit) {
    return 'Distance ($unit)';
  }

  @override
  String get cardioTimeLabel => 'Time';

  @override
  String get cardioIntensityLabel => 'Intens.';

  @override
  String get cardioIntensityShortLabel => 'Int.';

  @override
  String get restTimerLabel => 'Rest';

  @override
  String get skipButton => 'Skip';

  @override
  String get appInitStarting => 'Starting app...';

  @override
  String get appInitInitializing => 'Initializing...';

  @override
  String get appInitFinalizing => 'Finalizing';

  @override
  String get appInitCheckingBackups => 'Checking backups...';

  @override
  String get appInitSkipDownload => 'Skip download';

  @override
  String get appInitSkippingRemoteDownload => 'Skipping remote download...';

  @override
  String get emptyHistory => 'No completed workouts yet.';

  @override
  String get workoutDetailsTitle => 'Workout Details';

  @override
  String get workoutHeartRateSectionTitle => 'Heart Rate';

  @override
  String get workoutHeartRateAverageLabel => 'Avg';

  @override
  String get workoutHeartRateMaxLabel => 'Max';

  @override
  String get workoutHeartRateMinLabel => 'Min';

  @override
  String get workoutHeartRateQualityReady => 'Good coverage';

  @override
  String get workoutHeartRateQualityLimited => 'Limited data';

  @override
  String get workoutHeartRateQualityInsufficient => 'Very sparse';

  @override
  String get workoutHeartRateQualityNoData => 'No data';

  @override
  String get workoutHeartRateNoDataGeneral =>
      'No heart-rate samples were found for this workout window.';

  @override
  String get workoutHeartRateNoDataPermission =>
      'Heart-rate permission is required to show workout HR.';

  @override
  String get workoutHeartRateNoDataUnavailable =>
      'Heart-rate data is currently unavailable on this device.';

  @override
  String get workoutHeartRateNoDataWorkoutNotFinished =>
      'Heart-rate summary appears after a finished workout.';

  @override
  String get workoutHeartRateNoDataInvalidWindow =>
      'Workout time window is invalid, so HR cannot be analyzed.';

  @override
  String get workoutHeartRateNoDataQueryFailed =>
      'Could not read heart-rate data for this workout.';

  @override
  String get workoutHeartRateLimitedChartHint =>
      'Not enough consistent samples for a reliable chart.';

  @override
  String workoutHeartRateSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples',
      one: '1 sample',
      zero: 'No samples',
    );
    return '$_temp0';
  }

  @override
  String get workoutNotFound => 'Workout not found.';

  @override
  String get totalVolumeLabel => 'Total Volume';

  @override
  String get notesLabel => 'Notes';

  @override
  String get workoutImportTitle => 'External Workout Import';

  @override
  String get workoutImportDescription =>
      'Import your training history from a CSV or Excel export file.';

  @override
  String get workoutImportButton => 'Import Workout Data';

  @override
  String workoutImportSuccess(Object count) {
    return 'Successfully imported $count workouts!';
  }

  @override
  String get workoutImportFailed => 'Import failed. Please check the file.';

  @override
  String get importUnitSelectionTitle => 'Import Unit';

  @override
  String get importUnitSelectionDescription =>
      'In which unit is the data in the file provided?';

  @override
  String get unitMetricLabel => 'Metric (kg)';

  @override
  String get unitImperialLabel => 'Imperial (lbs)';

  @override
  String get excelExportButton => 'Excel Export (.xlsx)';

  @override
  String get exportWorkoutHistory => 'Workout History';

  @override
  String get exportNutritionDiary => 'Nutrition Diary';

  @override
  String get exportMeasurements => 'Measurements';

  @override
  String get startWorkout => 'Start Workout';

  @override
  String get addMeasurement => 'Add Measurement';

  @override
  String get filterToday => 'Today';

  @override
  String get filter7Days => '7 Days';

  @override
  String get filter30Days => '30 Days';

  @override
  String get filter30DaysShort => '30D';

  @override
  String get filter90DaysShort => '90D';

  @override
  String get filter180DaysShort => '180D';

  @override
  String get filter7DaysShort => '7D';

  @override
  String get filter1MonthShort => '1M';

  @override
  String get filter3MonthsShort => '3M';

  @override
  String get filter6MonthsShort => '6M';

  @override
  String get filter1YearShort => '1Y';

  @override
  String get filterMax => 'MAX';

  @override
  String get filterAll => 'All';

  @override
  String get showLess => 'Show less';

  @override
  String get showMoreDetails => 'Show more details';

  @override
  String get deleteConfirmTitle => 'Confirm Deletion';

  @override
  String get deleteConfirmContent => 'Do you really want to delete this entry?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get unsavedChangesTitle => 'Unsaved Changes';

  @override
  String get unsavedChangesContent =>
      'You have unsaved changes. Do you want to save them before leaving?';

  @override
  String get share => 'Share';

  @override
  String get shareWorkout => 'Share workout';

  @override
  String get shareRoutine => 'Share routine';

  @override
  String get shareAsImage => 'Share as image';

  @override
  String get shareAsText => 'Share as text';

  @override
  String get sharedFromTrainLibre => 'Shared from Train Libre';

  @override
  String get sharedWithTrainLibre => 'Shared with Train Libre';

  @override
  String get shareImageSummary => 'Summary';

  @override
  String get shareImageExercises => 'Exercises';

  @override
  String get shareImageMuscleFocus => 'Muscle focus';

  @override
  String get shareImageMinimal => 'Minimal';

  @override
  String get volume => 'Volume';

  @override
  String moreExercises(int count) {
    return '+ $count more exercises';
  }

  @override
  String shareSetNumber(int number) {
    return 'Set $number';
  }

  @override
  String get repsShort => 'reps';

  @override
  String get shareFailed => 'Sharing failed';

  @override
  String get workoutShareTitle => 'Workout';

  @override
  String get routineShareTitle => 'Routine';

  @override
  String get setTypeWarmup => 'Warm-up';

  @override
  String get setTypeWork => 'Work sets';

  @override
  String get setTypeFailure => 'Failure';

  @override
  String get setTypeDropset => 'Dropset';

  @override
  String get setTypeSuperset => 'Superset';

  @override
  String get setTypeOther => 'Other';

  @override
  String get setTypeWarmupSuffix => 'Warm-up';

  @override
  String get setTypeFailureSuffix => 'Failure';

  @override
  String get setTypeDropsetSuffix => 'Dropset';

  @override
  String get setTypeSupersetSuffix => 'Superset';

  @override
  String get setTypeOtherSuffix => 'Other';

  @override
  String warmupSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warm-up sets',
      one: '1 warm-up set',
    );
    return '$_temp0';
  }

  @override
  String workSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count work sets',
      one: '1 work set',
    );
    return '$_temp0';
  }

  @override
  String failureSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count failure sets',
      one: '1 failure set',
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
      other: '$count other sets',
      one: '1 other set',
    );
    return '$_temp0';
  }

  @override
  String warmupCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warm-up',
      one: '1 warm-up',
    );
    return '$_temp0';
  }

  @override
  String workCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count work',
      one: '1 work',
    );
    return '$_temp0';
  }

  @override
  String failureCompactCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count failure',
      one: '1 failure',
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
      other: '$count other',
      one: '1 other',
    );
    return '$_temp0';
  }

  @override
  String get shareExercisesLabel => 'exercises';

  @override
  String get shareSetsLabel => 'sets';

  @override
  String get shareSetLabel => 'set';

  @override
  String get tabBaseFoods => 'Base Foods';

  @override
  String get baseFoodsEmptyState =>
      'This section will soon be filled with a curated list of base foods like fruits, vegetables, and more.';

  @override
  String get noBrand => 'No Brand';

  @override
  String get unknown => 'Unknown';

  @override
  String backupFileSubject(String timestamp) {
    return 'Train Libre App Backup - $timestamp';
  }

  @override
  String foodItemSubtitle(String brand, int calories) {
    return '$brand - $calories kcal / 100g';
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
  String get exerciseCatalogTitle => 'Exercise Catalog';

  @override
  String get filterByMuscle => 'Filter by muscle group';

  @override
  String get noExercisesFound => 'No exercises found.';

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String get filterByCategory => 'Filter by category';

  @override
  String get edit => 'Edit';

  @override
  String get repsLabelShort => 'reps';

  @override
  String get titleNewRoutine => 'New Routine';

  @override
  String get titleEditRoutine => 'Edit Routine';

  @override
  String get editRoutine => 'Edit Routine';

  @override
  String get validatorPleaseEnterRoutineName =>
      'Please enter a name for the routine.';

  @override
  String get snackbarRoutineCreated =>
      'Routine created. Now add some exercises.';

  @override
  String get snackbarRoutineSaved => 'Routine saved.';

  @override
  String get saveAsRoutineButton => 'Save as routine';

  @override
  String get saveAsRoutineTitle => 'Save as Routine';

  @override
  String get saveAsRoutinePrompt => 'Please enter a name for the new routine:';

  @override
  String get saveAsRoutineSuccess => 'Routine created!';

  @override
  String get snackbarRoutineSavedAction => 'View';

  @override
  String get formFieldRoutineName => 'Name of the routine';

  @override
  String get emptyStateAddFirstExercise => 'Add your first exercise.';

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
  String get fabAddExercise => 'Add Exercise';

  @override
  String get drawerExerciseCatalog => 'Exercise Catalog';

  @override
  String get lastWorkoutTitle => 'Last Workout';

  @override
  String get repeatButton => 'Repeat';

  @override
  String get weightHistoryTitle => 'Weight History';

  @override
  String get hideSummary => 'Hide Summary';

  @override
  String get showSummary => 'Show Summary';

  @override
  String get exerciseDataAttribution => 'Exercise data from OpenExerciseDB';

  @override
  String get exerciseDataLicense => 'Exercise data licence';

  @override
  String get exerciseDataUpstream => 'Derived in part from wger';

  @override
  String get duplicate => 'Duplicate';

  @override
  String deleteRoutineConfirmContent(String routineName) {
    return 'Are you sure you want to permanently delete the routine \'$routineName\'?';
  }

  @override
  String get editPauseTimeTitle => 'Edit Pause Duration';

  @override
  String get pauseInSeconds => 'Pause in seconds';

  @override
  String get editPauseTime => 'Edit Pause';

  @override
  String pauseDuration(int seconds) {
    return '$seconds second pause';
  }

  @override
  String maxPauseDuration(int seconds) {
    return 'Pauses up to ${seconds}s';
  }

  @override
  String get deleteWorkoutConfirmContent =>
      'Are you sure you want to permanently delete this workout log?';

  @override
  String get removeExercise => 'Remove Exercise';

  @override
  String get deleteExerciseConfirmTitle => 'Remove Exercise?';

  @override
  String deleteExerciseConfirmContent(String exerciseName) {
    return 'Are you sure you want to remove \'$exerciseName\' from this routine?';
  }

  @override
  String get doneButtonLabel => 'Done';

  @override
  String get setRestTimeButton => 'Set rest time';

  @override
  String get deleteExerciseButton => 'Delete exercise';

  @override
  String get deleteCustomExerciseTitle => 'Delete Custom Exercise';

  @override
  String deleteCustomExerciseBody(String name) {
    return 'This will permanently delete \"$name\". This cannot be undone.';
  }

  @override
  String get deleteCustomExerciseWithLogsWarning =>
      'This exercise appears in your workout history. Your log entries will be kept, but the exercise link will be removed.';

  @override
  String get deleteCustomExerciseWithRoutinesWarning =>
      'This exercise is used in one or more routines. It will be removed from those routines.';

  @override
  String get deleteCustomExerciseSuccess => 'Exercise deleted.';

  @override
  String get restOverLabel => 'Pause is over';

  @override
  String get workoutRunningLabel => 'Workout is active …';

  @override
  String get continueButton => 'Continue';

  @override
  String get discardButton => 'Discard';

  @override
  String get workoutStatsTitle => 'Training (7 days)';

  @override
  String get workoutsLabel => 'Workouts';

  @override
  String get durationLabel => 'Duration';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get setsLabel => 'Sets';

  @override
  String get muscleSplitLabel => 'Muscle Split';

  @override
  String get snackbar_could_not_open_open_link => 'Could not open link';

  @override
  String get chart_no_data_for_period => 'No chart data for this period';

  @override
  String get amount_in_milliliters => 'Amount in milliliters';

  @override
  String get amount_in_grams => 'Amount in grams';

  @override
  String get meal_label => 'Meal';

  @override
  String get add_to_water_intake => 'Add to water intake';

  @override
  String get create_exercise_screen_title => 'Create Custom Exercise';

  @override
  String get exercise_name_label => 'Exercise name';

  @override
  String get category_label => 'Category';

  @override
  String get description_optional_label => 'Description (optional)';

  @override
  String get primary_muscles_label => 'Primary muscles';

  @override
  String get primary_muscles_hint => 'e.g. Chest, Triceps';

  @override
  String get secondary_muscles_label => 'Secondary muscles (optional)';

  @override
  String get secondary_muscles_hint => 'e.g. Shoulders';

  @override
  String get fluidNameLabel => 'Name';

  @override
  String get sugarPer100mlLabel => 'Sugar (g / 100ml)';

  @override
  String get set_type_normal => 'Normal';

  @override
  String get set_type_warmup => 'Warmup';

  @override
  String get set_type_failure => 'Failure';

  @override
  String get set_type_dropset => 'Dropset';

  @override
  String get set_reps_hint => '8-12';

  @override
  String get data_export_button => 'Export';

  @override
  String get data_import_button => 'Import';

  @override
  String get snackbar_button_ok => 'OK';

  @override
  String get measurement_session_detail_view =>
      'Detailview of measurement session';

  @override
  String get unit_grams => 'g';

  @override
  String get unit_kcal => 'kcal';

  @override
  String get delete_profile_picture_button => 'Delete profile picture';

  @override
  String get attribution_title => 'Attribution';

  @override
  String get add_liquid_title => 'Add fluid';

  @override
  String get add_button => 'Add';

  @override
  String get discard_button => 'Discard';

  @override
  String get continue_workout_button => 'Continue';

  @override
  String get minimizeWorkoutButton => 'Minimize';

  @override
  String get soon_available_snackbar => 'This screen will be available soon';

  @override
  String get start_button => 'Start';

  @override
  String get today_overview_text => 'TODAY IN FOCUS';

  @override
  String get quick_add_text => 'QUICK ADD';

  @override
  String get scann_barcode_capslock => 'Scan barcode';

  @override
  String get protocol_today_capslock => 'TODAY\'S PROTOCOL';

  @override
  String get my_plans_capslock => 'MY PLANS';

  @override
  String get overview_capslock => 'OVERVIEW';

  @override
  String get manage_all_plans => 'Manage all plans';

  @override
  String get workoutSectionStart => 'Start';

  @override
  String get workoutSectionMyPlans => 'My plans';

  @override
  String get emptyStateWorkoutRoutinesCallout =>
      'Create your first routine to track your workouts in the gym in a structured way.';

  @override
  String get workoutSectionHistoryLibrary => 'History & library';

  @override
  String get workoutAllRoutines => 'All routines';

  @override
  String get workoutEntryWorkouts => 'Workouts';

  @override
  String get free_training => 'free training';

  @override
  String get my_consistency => 'MY CONSISTENCY';

  @override
  String get calendar_currently_not_available =>
      'The calendar view will be available soon.';

  @override
  String get in_depth_analysis => 'IN-DEPTH ANALYSIS';

  @override
  String get body_measurements => 'Body measurements';

  @override
  String get measurements_description =>
      'Analyze weight, body fat percentage and circumference.';

  @override
  String get nutrition_description => 'Evaluate macros, calories and trends.';

  @override
  String get training_analysis => 'Training analysis';

  @override
  String get training_analysis_description =>
      'Track volume, strength and progression.';

  @override
  String get load_dots => 'loading...';

  @override
  String get profile_capslock => 'PROFILE';

  @override
  String get settings_capslock => 'SETTINGS';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsUpdateFoodDatabase => 'Update Databases';

  @override
  String get settingsUpdateFoodDatabaseSubtitle =>
      'Check for updates to the food and exercise databases manually.';

  @override
  String get settingsUpdateFoodDatabaseSuccess =>
      'Databases successfully updated.';

  @override
  String settingsUpdateFoodDatabaseError(String error) {
    return 'Error updating databases: $error';
  }

  @override
  String get settingsGuidedTourSectionTitle => 'Guided tour';

  @override
  String get settingsRestartAppTourTitle => 'Restart app tour';

  @override
  String get settingsRestartAppTourSubtitle =>
      'Run the short in-app walkthrough again.';

  @override
  String get my_goals => 'My goals';

  @override
  String get my_goals_description => 'Adjust calories, macros and water.';

  @override
  String get backup_and_import => 'Data backup & import';

  @override
  String get backup_and_import_description =>
      'Create backups, restore, and import data.';

  @override
  String get feedbackReportSettingsSectionTitle => 'Support';

  @override
  String get feedbackReportSettingsEntryTitle => 'Send feedback';

  @override
  String get feedbackReportSettingsEntrySubtitle =>
      'Create a local diagnostic report and choose how to share it.';

  @override
  String get about_and_legal_capslock => 'ABOUT & LEGAL';

  @override
  String get feedbackReportScreenTitle => 'Feedback report';

  @override
  String get feedbackReportPrivacyTitle => 'Privacy first';

  @override
  String get feedbackReportPrivacyBody =>
      'This report is generated locally on your device. Nothing is sent automatically. Only what you see in the preview is included when you choose copy, save, share, or email. Email opens a draft to feedback@schotte.me so you can review, edit, or cancel before sending.';

  @override
  String get feedbackReportOptionalNoteTitle => 'Optional note';

  @override
  String get feedbackReportOptionalNoteLabel => 'Your note (optional)';

  @override
  String get feedbackReportOptionalNoteHint =>
      'Describe what happened, expected behavior, and steps to reproduce.';

  @override
  String get feedbackReportIncludeSectionTitle => 'Include in report';

  @override
  String get feedbackReportIncludeAdaptiveNutrition =>
      'Adaptive nutrition diagnostics';

  @override
  String get feedbackReportIncludeBackupRestore =>
      'Backup / restore diagnostics';

  @override
  String get feedbackReportIncludePerformance =>
      'Performance log (frame timings)';

  @override
  String get settingsPerformanceLogTitle => 'Performance Log';

  @override
  String get settingsPerformanceLogSubtitle =>
      'Shows which screens drop frames';

  @override
  String get performanceLogIntro =>
      'Records refresh rate and dropped frames on this device. Runs in the background and only leaves the device when you share the log.';

  @override
  String get performanceLogDeviceLabel => 'Device';

  @override
  String get performanceLogDisplayLabel => 'Display';

  @override
  String get performanceLogFramesLabel => 'Frames';

  @override
  String get performanceLogJankLabel => 'Dropped frames';

  @override
  String get performanceLogStallsLabel => 'Stalls';

  @override
  String get performanceLogCopyButton => 'Copy';

  @override
  String get performanceLogShareButton => 'Share';

  @override
  String get performanceLogCopiedSnack => 'Performance log copied.';

  @override
  String get performanceLogScreensSection => 'Screens';

  @override
  String get performanceLogEmpty => 'No frames recorded yet.';

  @override
  String get performanceLogStallsSection => 'Stalls (UI thread blocked)';

  @override
  String get performanceLogStartupSection => 'Startup & resume';

  @override
  String get performanceLogStartupEmpty => 'No startup measured yet.';

  @override
  String get performanceLogStartupCold => 'Cold start';

  @override
  String get performanceLogStartupResume => 'Resume';

  @override
  String get performanceLogStartupUnattributed => 'Framework & first render';

  @override
  String get performanceLogSevereLabel => 'severe';

  @override
  String get performanceLogPauseTitle => 'Pause recording';

  @override
  String get performanceLogResetTitle => 'Reset measurements';

  @override
  String get performanceLogResetDialogBody =>
      'All recorded frame statistics and stalls will be deleted. Recording starts from zero afterwards.';

  @override
  String get performanceLogResetConfirm => 'Reset';

  @override
  String get performanceLogResetDoneSnack => 'Measurements reset.';

  @override
  String get feedbackReportIncludeUserNote => 'User note';

  @override
  String get feedbackReportGeneratePreview => 'Generate preview';

  @override
  String get feedbackReportPreviewTitle => 'Preview';

  @override
  String get feedbackReportActionCopy => 'Copy';

  @override
  String get feedbackReportActionSave => 'Save';

  @override
  String get feedbackReportActionShare => 'Share';

  @override
  String get feedbackReportActionEmail => 'Email';

  @override
  String get feedbackReportCopied => 'Report copied to clipboard.';

  @override
  String get feedbackReportSavedToTemporaryFile =>
      'Saved to a temporary report file.';

  @override
  String get feedbackReportShareCompleted => 'Share sheet opened.';

  @override
  String get feedbackReportShareCanceled => 'Share canceled.';

  @override
  String get feedbackReportEmailOpenFailed => 'Could not open email app.';

  @override
  String get feedbackReportEmailSubject => 'Train Libre feedback report';

  @override
  String get feedbackReportReportTitle => 'Train Libre Feedback Report';

  @override
  String get feedbackReportReportGeneratedAt => 'Generated';

  @override
  String get feedbackReportReportAppVersion => 'App version';

  @override
  String get feedbackReportReportBuildNumber => 'Build number';

  @override
  String get feedbackReportReportPlatform => 'Platform';

  @override
  String get feedbackReportReportOsVersion => 'OS version';

  @override
  String get feedbackReportUnavailable => 'unavailable';

  @override
  String get feedbackReportSectionUserNote => 'User note';

  @override
  String get feedbackReportSectionAdaptiveNutrition =>
      'Adaptive nutrition diagnostics';

  @override
  String get feedbackReportSectionBackupRestore =>
      'Backup / restore diagnostics';

  @override
  String get attribution_and_license => 'Attribution & Licenses';

  @override
  String get data_from_off_and_wger => 'Data from Open Food Facts and wger.';

  @override
  String get app_version => 'App version';

  @override
  String get all_measurements => 'ALL MEASUREMENTS';

  @override
  String get all_measurements_no_cap => 'All measurements';

  @override
  String get date_and_time_of_measurement => 'Date & time of measurement';

  @override
  String get onbWelcomeTitle => 'Welcome to Train Libre';

  @override
  String get onbWelcomeBody =>
      'Let’s start by setting personal goals to guide training and nutrition.';

  @override
  String get onbTrackTitle => 'Track everything';

  @override
  String get onbTrackBody =>
      'Log nutrition, workouts, and measurements — all in one place.';

  @override
  String get onbPrivacyTitle => 'Offline-first & privacy';

  @override
  String get onbPrivacyBody =>
      'Your data stays on the device. No cloud accounts, no background sync.';

  @override
  String get onbFinishTitle => 'All set';

  @override
  String get onbFinishBody =>
      'You’re ready to explore the app. You can adjust settings anytime.';

  @override
  String get onbFinishCta => 'Let’s go!';

  @override
  String get onbShowTutorialAgain => 'Show onboarding again';

  @override
  String get appTourOfferTitle => 'Take a quick app tour?';

  @override
  String get appTourOfferBody =>
      'Get a short walkthrough of the main app areas. You can skip now and restart later in Settings.';

  @override
  String get appTourOfferStart => 'Start tour';

  @override
  String get appTourOfferSkip => 'Maybe later';

  @override
  String get appTourSkip => 'Skip';

  @override
  String get appTourNext => 'Next';

  @override
  String get appTourDone => 'Done';

  @override
  String get appTourStepNavigationTitle => 'Main navigation';

  @override
  String get appTourStepNavigationBody =>
      'Use the bottom tabs to move between Diary, Workout, Statistics, and Nutrition.';

  @override
  String get appTourStepQuickActionsTitle => 'Quick actions';

  @override
  String get appTourStepQuickActionsBody =>
      'Tap the plus button to quickly add food, fluids, measurements, workouts, and more.';

  @override
  String get appTourStepDiaryTitle => 'Diary';

  @override
  String get appTourStepDiaryBody =>
      'Diary is your daily overview. Track meals, hydration, supplements, and your day at a glance.';

  @override
  String get appTourStepWorkoutTitle => 'Workout';

  @override
  String get appTourStepWorkoutBody =>
      'Workout is where you start sessions, manage routines, and review your training history.';

  @override
  String get appTourStepNutritionTitle => 'Nutrition';

  @override
  String get appTourStepNutritionBody =>
      'Nutrition helps you plan meals, review targets, and access tools like meal templates.';

  @override
  String get appTourStepStatisticsTitle => 'Statistics';

  @override
  String get appTourStepStatisticsBody =>
      'Statistics shows trends and progress so you can understand how your data changes over time.';

  @override
  String get appTourRestartTitle => 'View App Tour';

  @override
  String get appTourRestartSubtitle =>
      'Review the introduction and key features';

  @override
  String get onbSetGoalsCta => 'Set goals';

  @override
  String get onbHeaderTitle => 'Tutorial';

  @override
  String get onbHeaderSkip => 'Skip';

  @override
  String get onbBack => 'Back';

  @override
  String get onbNext => 'Next';

  @override
  String get onbGuideTitle => 'How this tutorial works';

  @override
  String get onbGuideBody =>
      'Swipe between slides or use Next. Tap the buttons on each slide to try features. You can finish anytime with Skip.';

  @override
  String get onbCtaOpenNutrition => 'Open nutrition';

  @override
  String get onbCtaLearnMore => 'Learn more';

  @override
  String get onbBadgeDone => 'Done';

  @override
  String get onbTipSetGoals => 'Tip: adjust targets first';

  @override
  String get onbTipAddEntry => 'Tip: add one entry today';

  @override
  String get onbTipLocalControl => 'You control all data locally';

  @override
  String get onbTrackHowBody =>
      'How to log nutrition:\n• Open the Food tab.\n• Tap the + button.\n• Search products or scan a barcode.\n• Adjust portion and time.\n• Save to your diary.';

  @override
  String get onbMeasureTitle => 'Track measurements';

  @override
  String get onbMeasureBody =>
      'How to add measurements:\n• Open the Stats tab.\n• Tap the + button.\n• Choose a metric (e.g., weight, waist, body fat).\n• Enter value and time.\n• Save to your history.';

  @override
  String get onbTipMeasureToday =>
      'Tip: add today’s weight to start your graph';

  @override
  String get onbTrainTitle => 'Train with routines';

  @override
  String get onbTrainBody =>
      'Create a routine and start a workout:\n• Open the Train tab.\n• Tap Create routine to add exercises and sets.\n• Save the routine.\n• Tap Start to begin, or use “Start empty workout”.';

  @override
  String get onbTipStartWorkout =>
      'Tip: start an empty workout to log a quick session';

  @override
  String get unitsSection => 'units';

  @override
  String get weightUnit => 'Weight units';

  @override
  String get lengthUnit => 'unit of length';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get noFavorites => 'No Favorites';

  @override
  String get nothingTrackedYet => 'Nothing tracked yet';

  @override
  String snackbarBarcodeNotFound(String barcode) {
    return 'No product found for barcode \"$barcode\".';
  }

  @override
  String get categoryHint => 'e.g. Chest, Back, Legs...';

  @override
  String get validatorPleaseEnterCategory => 'Please enter a category.';

  @override
  String get dialogEnterPasswordImport => 'Enter password to import backup';

  @override
  String get dataManagementBackupTitle => 'Train Libre Data Backup';

  @override
  String get dataManagementBackupDescription =>
      'Back up or restore all your app data. Ideal for changing devices.';

  @override
  String get exportEncrypted => 'Export Encrypted';

  @override
  String get dialogPasswordForExport => 'Password for encrypted export';

  @override
  String get snackbarEncryptedBackupShared => 'Encrypted backup shared.';

  @override
  String get exportFailed => 'Export failed.';

  @override
  String get csvExportTitle => 'Data Export (CSV)';

  @override
  String get csvExportDescription =>
      'Export parts of your data as a CSV file for analysis in other programs.';

  @override
  String get snackbarSharingNutrition => 'Sharing nutrition diary...';

  @override
  String get snackbarExportFailedNoEntries =>
      'Export failed. There may be no entries yet.';

  @override
  String get snackbarSharingMeasurements => 'Sharing measurements...';

  @override
  String get snackbarSharingWorkouts => 'Sharing workout history...';

  @override
  String get mapExercisesTitle => 'Map Exercises';

  @override
  String get mapExercisesDescription =>
      'Map unknown names from logs to wger exercises.';

  @override
  String get mapExercisesButton => 'Start Mapping';

  @override
  String get autoBackupTitle => 'Automatic Backups';

  @override
  String get autoBackupDescription =>
      'Periodically saves a backup in the folder. Current folder:';

  @override
  String get autoBackupDefaultFolder => 'App-Documents/Backups (Default)';

  @override
  String get autoBackupChooseFolder => 'Choose Folder';

  @override
  String get autoBackupCopyPath => 'Copy Path';

  @override
  String get autoBackupRunNow => 'Check & Run Auto-Backup Now';

  @override
  String get icloudAutoBackupTitle => 'iCloud Auto-Backup';

  @override
  String get icloudAutoBackupDescription =>
      'Automatically syncs your database to iCloud Drive whenever the app goes into the background. Your data can be restored on a new device or after reinstalling.';

  @override
  String get icloudBackupNow => 'Backup to iCloud Now';

  @override
  String get icloudBackupUploading => 'Uploading…';

  @override
  String get icloudBackupSuccess => 'Backup uploaded successfully.';

  @override
  String get icloudBackupFailed =>
      'Backup failed. Check your iCloud connection.';

  @override
  String get autoBackupRequestAccessSubtitle =>
      'To automatically back up your data, Train Libre needs access to a folder you choose. Your backups will be stored there.';

  @override
  String get snackbarAutoBackupSuccess => 'Auto-Backup completed.';

  @override
  String get snackbarAutoBackupFailed => 'Auto-Backup failed or was canceled.';

  @override
  String get localDataDeletionCardTitle => 'Local app data';

  @override
  String get localDataDeletionCardDescription =>
      'Permanently delete user-owned data stored on this device and reset Train Libre to a fresh local state.';

  @override
  String get deleteAllLocalAppData => 'Delete all local app data';

  @override
  String get localDataDeletionConfirmTitle => 'Delete all local app data?';

  @override
  String get localDataDeletionConfirmBody =>
      'This permanently deletes locally stored workouts, nutrition logs, measurements, supplements, settings/state, cached analytics, and local app data.\n\nThis does not delete data already exported to Apple Health or Health Connect.\n\nThis does not delete external provider data or remote public catalog sources. Bundled app assets and required default catalogs are kept or recreated so the app can launch after reset.';

  @override
  String get localDataDeletionTypeDeleteLabel => 'Type DELETE to confirm';

  @override
  String get localDataDeletionSuccessTitle => 'Local data deleted';

  @override
  String get localDataDeletionSuccessBody =>
      'Train Libre will return to its initial setup state.';

  @override
  String get localDataDeletionFailed =>
      'Local data could not be deleted. Please try again.';

  @override
  String get noUnknownExercisesFound => 'No unknown exercises found';

  @override
  String snackbarAutoBackupFolderSet(String path) {
    return 'Auto-backup folder set:\n$path';
  }

  @override
  String get snackbarPathCopied => 'Path copied';

  @override
  String get passwordLabel => 'Password';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get involvedMuscles => 'Involved Muscles';

  @override
  String get primaryLabel => 'Primary:';

  @override
  String get secondaryLabel => 'Secondary:';

  @override
  String get noMusclesSpecified => 'No muscles specified.';

  @override
  String get frontLabel => 'Front';

  @override
  String get backLabel => 'Back';

  @override
  String get noSelection => 'No selection';

  @override
  String get selectButton => 'Select';

  @override
  String get applyingChanges => 'Applying changes...';

  @override
  String get applyMapping => 'Apply Mapping';

  @override
  String get mappingSuggestions => 'Suggestions';

  @override
  String get mappingSuggestionsEmpty => 'No matching exercises found';

  @override
  String get personalData => 'Personal Data';

  @override
  String get personalDataCL => 'PERSONAL DATA';

  @override
  String get macroDistribution => 'Macronutrient Distribution';

  @override
  String get dialogFinishWorkoutBody =>
      'Are you sure you want to finish this workout?';

  @override
  String get attributionText =>
      'This app uses data from external sources:\n\n● Exercise data from OpenExerciseDB (github.com/rfivesix/OpenExerciseDB), licensed under CC BY-SA 4.0, derived in part from the wger project (wger.de).\n\n● Food database from Open Food Facts (openfoodfacts.org), available under the Open Database License (ODbL).';

  @override
  String get errorRoutineNotFound => 'Routine not found';

  @override
  String get workoutHistoryEmptyTitle => 'Your history is empty';

  @override
  String get workoutSummaryTitle => 'Workout Complete';

  @override
  String get workoutSummaryExerciseOverview => 'Exercise Overview';

  @override
  String get nutritionDiary => 'Diary';

  @override
  String get detailedNutrientGoals => 'Detailed Nutrients';

  @override
  String get detailedNutrientGoalsCL => 'DETAILED NUTRIENTS';

  @override
  String get supplementTrackerTitle => 'Supplement Tracker';

  @override
  String get supplementTrackerDescription => 'Track goals, limits, and intake.';

  @override
  String get createSupplementTitle => 'Create Supplement';

  @override
  String get supplementNameLabel => 'Supplement Name';

  @override
  String get defaultDoseLabel => 'Default Dose';

  @override
  String get unitLabel => 'Unit';

  @override
  String get dailyGoalLabel => 'Daily Goal (optional)';

  @override
  String get dailyLimitLabel => 'Daily Limit (optional)';

  @override
  String get dailyProgressTitle => 'Daily Progress';

  @override
  String get todaysLogTitle => 'Today\'s Log';

  @override
  String get logIntakeTitle => 'Log Intake';

  @override
  String get emptySupplementGoals =>
      'Set goals or limits for supplements to see your progress here.';

  @override
  String get emptySupplementLogs => 'No intake logged for today yet.';

  @override
  String get doseLabel => 'Dose';

  @override
  String get settingsDescription => 'Theme, units, data and more';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get caffeinePrompt => 'Caffeine (optional)';

  @override
  String get caffeineUnit => 'mg per 100ml';

  @override
  String get profile => 'Profile';

  @override
  String get measurementWeightCapslock => 'BODY WEIGHT';

  @override
  String get diary => 'Diary';

  @override
  String get analysis => 'Analysis';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get dayBeforeYesterday => 'Two days ago';

  @override
  String get statistics => 'Statistics';

  @override
  String get workout => 'Workout';

  @override
  String get addFoodTitle => 'add food';

  @override
  String get nutritionExplorerTitle => 'Nutrition Explorer';

  @override
  String get myMeals => 'My Recipes';

  @override
  String get myMealsCL => 'MY RECIPES';

  @override
  String get nutritionSectionTodayInFocus => 'Today in focus';

  @override
  String get nutritionSectionMyMeals => 'My recipes';

  @override
  String get emptyStateNutritionRecipesCallout =>
      'Create your first recipe to quickly log your frequent meals.';

  @override
  String get nutritionSectionToolsAndLibrary => 'Tools & library';

  @override
  String get supplement_caffeine => 'Caffeine';

  @override
  String get supplement_creatine_monohydrate => 'Creatine Monohydrate';

  @override
  String get manageSupplementsTitle => 'Manage supplements';

  @override
  String get deleted => 'deleted';

  @override
  String get operationNotAllowed => 'This operation isn\'t allowed';

  @override
  String get emptySupplements => 'No supplements available';

  @override
  String get undo => 'Undo';

  @override
  String get deleteSupplementConfirm =>
      'Are you sure you want to delete this supplement? All historical data will be lost.\n\nTip: You can simply untrack it by editing the supplement instead.';

  @override
  String get editSupplementLogTitle => 'Edit Log Entry';

  @override
  String get deleteSupplementLogConfirm =>
      'Are you sure you want to delete this log entry?';

  @override
  String get fieldRequired => 'Required';

  @override
  String get unitNotSupported => 'Unit not supported.';

  @override
  String get caffeineUnitLocked => 'For caffeine the unit is fixed: mg.';

  @override
  String get caffeineMustBeMg => 'Caffeine must be recorded in mg.';

  @override
  String get tabCatalogSearch => 'Catalog';

  @override
  String get tabMeals => 'Recipes';

  @override
  String get emptyCategory => 'No entries';

  @override
  String get searchSectionBase => 'Base foods';

  @override
  String get searchSectionOther => 'Other results';

  @override
  String get mealsComingSoonTitle => 'Recipes (coming soon)';

  @override
  String get mealsComingSoonBody =>
      'Soon you will be able to create your own recipes from multiple foods.';

  @override
  String get mealsEmptyTitle => 'No recipe templates saved';

  @override
  String get mealsEmptyBody =>
      'Create recipes to quickly log multiple foods at once.';

  @override
  String get mealsEmptyBodyWithShortcut =>
      'In the diary, use the “Save as recipe” option below your Breakfast or Dinner to save common food combinations as a quick template.';

  @override
  String get mealsCreateManually => 'Create recipe manually';

  @override
  String get saveMealTemplateShortcut => 'Save as recipe';

  @override
  String get mealsCreate => 'Create recipe';

  @override
  String get mealsEdit => 'Edit recipe';

  @override
  String get mealsDelete => 'Delete recipe';

  @override
  String get mealsAddToDiary => 'Add food';

  @override
  String get mealNameLabel => 'Recipe name';

  @override
  String get mealNotesLabel => 'Notes';

  @override
  String get mealIngredientsTitle => 'Ingredients';

  @override
  String get mealAddIngredient => 'Add ingredient';

  @override
  String get mealIngredientAmountLabel => 'Amount';

  @override
  String get mealDeleteConfirmTitle => 'Delete recipe';

  @override
  String mealDeleteConfirmBody(Object name) {
    return 'Are you sure you want to delete the recipe \'$name\'? All its ingredients will also be removed.';
  }

  @override
  String mealAddedToDiary(Object name) {
    return 'Recipe \'$name\' has been added to your diary.';
  }

  @override
  String get mealSaved => 'Recipe saved.';

  @override
  String get mealDeleted => 'Recipe deleted.';

  @override
  String get confirm => 'Confirm';

  @override
  String get addMealToDiaryTitle => 'Add to diary';

  @override
  String get mealTypeLabel => 'Recipe';

  @override
  String get amountLabel => 'Amount';

  @override
  String get mealAddedToDiarySuccess => 'Recipe added to diary';

  @override
  String get error => 'Error';

  @override
  String get mealsViewTitle => 'mealsViewTitle';

  @override
  String get noNotes => 'No notes';

  @override
  String get ingredientsCapsLock => 'INGREDIENTS';

  @override
  String get nutritionSectionLabel => 'NUTRITION FACTS';

  @override
  String get nutritionCalculatedForCurrentAmounts => 'for current quantities';

  @override
  String get startCapsLock => 'START';

  @override
  String get nutritionHubSubtitle =>
      'Discover insights, track meals, and plan your nutrition here soon.';

  @override
  String get nutritionHubTitle => 'Nutrition';

  @override
  String get nutrition => 'Nutrition';

  @override
  String get changeSetTypTitle => 'Change set type';

  @override
  String get settingsVisualStyleTitle => 'Visual Style';

  @override
  String get settingsVisualStyleStandard => 'Frosted Glass';

  @override
  String get settingsVisualStyleLiquid => 'Liquid Glass (Fluid)';

  @override
  String get settingsVisualStyleLiquidDesc => 'Rounded, floating UI elements';

  @override
  String get settingsMaterialColorsTitle => 'Material colors';

  @override
  String get settingsMaterialColorsSubtitle =>
      'Use dynamic system colors (Material You) instead of the Train Libre brand accent';

  @override
  String get settingsFoodDbSectionTitle => 'Food database';

  @override
  String get settingsFoodDbRegionTitle => 'Food database region';

  @override
  String get settingsFoodDbRegionSubtitle =>
      'Select which Open Food Facts product catalog region is used for food search.';

  @override
  String get settingsFoodDbRegionCurrent => 'Current region';

  @override
  String get settingsFoodDbRegionDialogTitle => 'Choose food database region';

  @override
  String get settingsFoodDbRegionDialogSubtitle =>
      'This changes the Open Food Facts catalog source used by product search.';

  @override
  String get settingsFoodDbRegionSearchPlaceholder => 'Search region...';

  @override
  String get settingsFoodDbRegionNoResults => 'No region found';

  @override
  String get settingsFoodDbRegionIssueHint =>
      'If your country is not listed yet, feel free to open a GitHub issue and request support.';

  @override
  String get settingsFoodDbRegionGermany => 'Germany (DE)';

  @override
  String get settingsFoodDbRegionSwitzerland => 'Switzerland (CH)';

  @override
  String get settingsFoodDbRegionUnitedStates => 'United States (US)';

  @override
  String get settingsFoodDbRegionFrance => 'France (FR)';

  @override
  String get settingsFoodDbRegionItaly => 'Italy (IT)';

  @override
  String get settingsFoodDbRegionJapan => 'Japan (JP)';

  @override
  String get settingsFoodDbRegionAustria => 'Austria (AT)';

  @override
  String get settingsColorfulMacroBadgesTitle => 'Colorful Macro Badges';

  @override
  String get settingsColorfulMacroBadgesSubtitle =>
      'Uses the color-coded badge design from AI verification in the diary as well.';

  @override
  String get settingsFoodDbRegionUnitedKingdom => 'United Kingdom (UK)';

  @override
  String settingsFoodDbRegionChanged(String region) {
    return 'Food database region set to $region. Changes apply on the next catalog refresh/import cycle.';
  }

  @override
  String get searchBaseFoodHint => 'Search base foods';

  @override
  String get searchNoHits => 'No hits.';

  @override
  String get onbSubtitleWelcome =>
      'Your central tool for fitness, nutrition & progress.';

  @override
  String get onbBodyWelcome =>
      'We help you set and track your goals. Efficiently log workouts, nutrition, supplements, and body measurements.';

  @override
  String get onbBodyNutritionVisual =>
      'Log meals with just a few clicks. Keep an eye on calories, macros, and water to effortlessly track your goal.';

  @override
  String get onbBodyMeasurementsVisual =>
      'Visualize your progress. The weight and circumference chart makes your success visible and keeps you motivated.';

  @override
  String get onbBodyWorkoutVisual =>
      'Create routines and start your training in seconds. Log sets, weights, and rests for maximum progression.';

  @override
  String get onbTitleAppLayout => 'Navigation & Quick-Add';

  @override
  String get onbBodyAppLayout =>
      'The bottom bar allows quick switching between areas. Use the large [+] button to log everything instantly.';

  @override
  String get dataHubTitle => 'Data Hub';

  @override
  String get resumeButton => 'Resume';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Train Libre';

  @override
  String get onboardingWelcomeSubtitle =>
      'Let\'s set up your profile to get the best results.';

  @override
  String get onboardingMissionTitle => 'Our Mission';

  @override
  String get onboardingMissionBody =>
      'Train Libre is for dedicated natural bodybuilders who demand science-based, data-driven progress.';

  @override
  String get onboardingFeatureWorkoutTitle => 'Workout Tracker';

  @override
  String get onboardingFeatureWorkoutBody =>
      'Log sets (RIR/RPE) and follow your muscle recovery.';

  @override
  String get onboardingFeatureTdeeTitle => 'Adaptive TDEE';

  @override
  String get onboardingFeatureTdeeBody =>
      'An integrated Kalman filter calculates your real calorie expenditure.';

  @override
  String get onboardingFeatureNutritionTitle => 'Nutrition & Water';

  @override
  String get onboardingFeatureNutritionBody =>
      'Track macros, water, and use optional AI image recognition.';

  @override
  String get onboardingFeaturePrivacyTitle => '100% Private & Local';

  @override
  String get onboardingFeaturePrivacyBody =>
      'No accounts, no forced cloud. Your data belongs to you.';

  @override
  String get onboardingSettingsHint =>
      'All settings can be changed later at any time in Settings.';

  @override
  String get adaptiveRatePerWeekLabel => 'Weekly Target Rate';

  @override
  String get customTargetRateOption => 'Custom';

  @override
  String get customTargetRateDialogTitle => 'Set Custom Target Rate';

  @override
  String get onboardingNameTitle => 'What\'s your name?';

  @override
  String get onboardingNameLabel => 'Your Name';

  @override
  String get onboardingNameError => 'Please enter your name';

  @override
  String get onboardingDobTitle => 'When were you born?';

  @override
  String get onboardingDobLabel => 'Date of Birth';

  @override
  String get onboardingDobError => 'Please select your date of birth';

  @override
  String get onboardingWeightTitle => 'Current Weight';

  @override
  String get onboardingWeightLabel => 'Weight';

  @override
  String get onboardingWeightError => 'Please enter a valid weight';

  @override
  String get onboardingGoalsTitle => 'Your Nutrition Goals';

  @override
  String get onboardingGoalsSubtitle =>
      'You can change these later in settings.';

  @override
  String get onboardingGoalCalories => 'Daily Calories (kcal)';

  @override
  String get onboardingGoalProtein => 'Protein (g)';

  @override
  String get onboardingGoalCarbs => 'Carbs (g)';

  @override
  String get onboardingGoalFat => 'Fat (g)';

  @override
  String get onboardingGoalWater => 'Water';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingFinish => 'Start Tracking';

  @override
  String get onboardingAiHealthTitle => 'AI & Health';

  @override
  String get onboardingAiHealthSubtitle =>
      'Optional setup: configure AI meal capture with BYOK (Bring Your Own Key) and choose which health data Train Libre may read.';

  @override
  String get onboardingOpenSettings => 'Open';

  @override
  String get onboardingUnitSystemTitle => 'Choose your Unit System';

  @override
  String get onboardingUnitSystemSubtitle =>
      'You can change this later in Settings.';

  @override
  String get onboardingUnitMetric => 'Metric';

  @override
  String get onboardingUnitMetricSubtitle => 'kg, cm, ml';

  @override
  String get onboardingUnitImperial => 'Imperial';

  @override
  String get onboardingUnitImperialSubtitle => 'lbs, in, fl oz';

  @override
  String get onboardingHeightLabel => 'Height';

  @override
  String get onboardingGenderLabel => 'Gender';

  @override
  String get onboardingBioDataInfo =>
      'Your age and biological sex determine the baseline recovery windows of your muscle recovery model and feed into the algorithms of your Sleep Health Engine.';

  @override
  String get onboardingFieldCannotBeEmpty => 'This field cannot be empty.';

  @override
  String get onboardingPhysiologicalRangeWarning =>
      'Warning: This value is outside the expected physiological range. Our sports-science analytics and heuristic engines are not calibrated for extreme metrics. If this value is intentional, click \'Next\' again to proceed anyway.';

  @override
  String get onboardingMeasurementsTitle => 'Measurements & Baseline';

  @override
  String get onboardingMeasurementsSubtitle =>
      'Set your current baseline for the adaptive recommendation.';

  @override
  String get onboardingMeasurementsDisclaimer =>
      'You can enter and log your weight, body fat, and other measurements at any time in the dashboard.';

  @override
  String onboardingWaterNeedLabel(String unit) {
    return 'Water need ($unit)';
  }

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderDiverse => 'Diverse';

  @override
  String get vegan => 'Vegan';

  @override
  String get vegetarian => 'Vegetarian';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get aiSettingsTitle => 'AI Meal Capture';

  @override
  String get aiSettingsDescription => 'Configure AI-powered meal recognition.';

  @override
  String get aiProviderSection => 'AI Provider';

  @override
  String get aiProviderLabel => 'Provider';

  @override
  String get aiApiKeySection => 'API Key';

  @override
  String get aiApiKeyLabel => 'API Key';

  @override
  String get aiApiKeyHint => 'Paste your API key here';

  @override
  String get aiSaveKey => 'Save Key';

  @override
  String get aiTestConnection => 'Test';

  @override
  String get aiTestSuccess => 'Connection successful!';

  @override
  String get aiKeySaved => 'API key saved securely.';

  @override
  String get aiPrivacySection => 'Privacy';

  @override
  String get aiPrivacyDisclosure =>
      'Images, text, and generated prompts are sent to the selected AI provider only when you use an AI action. Provider retention and processing follow that provider\'s terms. Your API key is stored encrypted on this device only.';

  @override
  String get aiMealCapture => 'AI Meal';

  @override
  String get aiCaptureTitle => 'AI Meal Capture';

  @override
  String get aiCaptureTabPhoto => 'Photo';

  @override
  String get aiCaptureTabText => 'Text';

  @override
  String get aiCapturePhotoHint =>
      'Take or select up to 4 photos of your meal.';

  @override
  String get aiCaptureTextHint =>
      'Describe your meal (e.g. \"Grilled chicken with rice and salad\")...';

  @override
  String get aiAnalyzeButton => 'Analyze';

  @override
  String get aiAnalyzing => 'Analyzing your meal...';

  @override
  String get aiReviewTitle => 'Review Suggestions';

  @override
  String aiReviewFoundItems(int count) {
    return 'AI found $count items';
  }

  @override
  String get aiReviewNoMatch => 'No match — tap to search';

  @override
  String aiReviewUncertain(int percent) {
    return 'Unsure ($percent%)';
  }

  @override
  String get aiReviewConfidence => 'Confidence';

  @override
  String get aiReviewAddItem => 'Add item manually';

  @override
  String get aiReviewReplaceItem => 'Replace item';

  @override
  String get aiReviewSaveToDiary => 'Save to Diary';

  @override
  String get aiReviewFeedbackHint => 'Describe what the AI got wrong...';

  @override
  String get aiReviewRetryButton => 'Retry with Feedback';

  @override
  String get aiReviewFeedbackSection => 'Correction';

  @override
  String get aiErrorNoKey =>
      'No API key configured. Please set one in Settings → AI Meal Capture.';

  @override
  String get aiErrorNetwork =>
      'Network error. Please check your connection and try again.';

  @override
  String get aiErrorAuth => 'Authentication failed. Please check your API key.';

  @override
  String get aiErrorParse =>
      'Could not understand the AI response. Please try again.';

  @override
  String get aiErrorRateLimit => 'Too many requests. Please wait a moment.';

  @override
  String get aiEnableTitle => 'Enable AI Features';

  @override
  String get aiEnableSubtitle =>
      'Allows the use of AI for meal recognition. Disabling this hides all AI buttons in the app.';

  @override
  String get aiCustomInstructionsTitle => 'Global AI Instructions';

  @override
  String get aiCustomInstructionsSubtitle =>
      'Give the AI fixed rules (e.g., allergies, no-go foods like \'no bowls\', or intolerances) to be followed with every capture.';

  @override
  String get aiValidationNoMatchedItemsSaveYet =>
      'No matched items can be saved yet.';

  @override
  String get aiValidationNoMatchedIngredientsSaveYet =>
      'No matched ingredients can be saved yet.';

  @override
  String get aiValidationSomeItemsNeedReviewTitle => 'Some items need review';

  @override
  String get aiValidationSomeIngredientsNeedReviewTitle =>
      'Some ingredients need review';

  @override
  String get aiValidationSaveMatchedItemsButton => 'Save matched items';

  @override
  String get aiValidationSaveMatchedIngredientsButton =>
      'Save matched ingredients';

  @override
  String get aiValidationValidationPassedTitle => 'Validation passed';

  @override
  String get aiValidationReviewSuggestedTitle => 'Review suggested';

  @override
  String get aiValidationMacroFitValidatedTitle => 'Macro fit validated';

  @override
  String get aiValidationNeedsReviewTitle => 'Needs review';

  @override
  String get aiValidationRepairLimitReachedReview =>
      'Automatic repair limit reached. Please review before saving.';

  @override
  String get aiValidationRecentMealContextIncluded =>
      'Recent meal context was included.';

  @override
  String get aiValidationGeneratedWithoutRecentMealHistory =>
      'Generated without recent meal history.';

  @override
  String get aiValidationApiKeyRequiredTitle => 'API Key Required';

  @override
  String aiValidationScoreLabel(int score) {
    return 'Score $score/100';
  }

  @override
  String aiValidationDeltaSummary(
      int kcalDelta, int proteinDelta, int carbsDelta, int fatDelta) {
    return 'Delta: $kcalDelta kcal · ${proteinDelta}g Protein · ${carbsDelta}g Carbs · ${fatDelta}g Fat';
  }

  @override
  String aiValidationPartialSaveItemsMessage(
      int unmatchedCount, int matchedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unmatchedCount,
      locale: localeName,
      other:
          '$unmatchedCount items do not have a local database match and will not be saved.',
      one: '1 item does not have a local database match and will not be saved.',
    );
    return '$_temp0 Save the $matchedCount matched item(s) only?';
  }

  @override
  String aiValidationPartialSaveIngredientsMessage(
      int unmatchedCount, int matchedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      unmatchedCount,
      locale: localeName,
      other:
          '$unmatchedCount ingredients do not have a local database match and will not be saved.',
      one:
          '1 ingredient does not have a local database match and will not be saved.',
    );
    return '$_temp0 Save the $matchedCount matched ingredient(s) only?';
  }

  @override
  String get aiValidationEmptyItemName => 'An item has no food name.';

  @override
  String aiValidationDuplicateItemMerged(String name) {
    return 'Duplicate \"$name\" entries were merged before validation.';
  }

  @override
  String get aiValidationInvalidQuantity => 'Quantity must be greater than 0g.';

  @override
  String get aiValidationTinyQuantity =>
      'Quantity is very small; review the gram amount.';

  @override
  String get aiValidationExtremeQuantity =>
      'Quantity is implausibly high for one meal item.';

  @override
  String get aiValidationLargeQuantity =>
      'Quantity is unusually large; review the gram amount.';

  @override
  String get aiValidationLowAiConfidence =>
      'AI confidence is low for this item.';

  @override
  String get aiValidationUnmatchedItem => 'No local database match was found.';

  @override
  String get aiValidationWeakDbMatch => 'The local database match is weak.';

  @override
  String get aiValidationPartialDbMatch =>
      'The local database match is partial.';

  @override
  String get aiValidationAmbiguousDbMatch =>
      'Several local database matches look similarly plausible.';

  @override
  String get aiValidationStateMismatch =>
      'The AI item state may not match the database entry.';

  @override
  String get aiValidationZeroNutritionMatch =>
      'The matched database entry has no usable nutrition data.';

  @override
  String get aiValidationImplausibleFoodDensity =>
      'Matched food has unusually high kcal per 100g.';

  @override
  String get aiValidationMacroEnergyMismatch =>
      'Matched food macros do not align well with kcal.';

  @override
  String get aiValidationImplausibleItemNutrition =>
      'Nutrition for this quantity is unusually high.';

  @override
  String get aiValidationEmptyMeal => 'The AI returned no meal items.';

  @override
  String get aiValidationAllItemsUnmatched =>
      'No item could be matched to the local food database.';

  @override
  String aiValidationPartialUnmatchedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items cannot be saved until matched.',
      one: '1 item cannot be saved until matched.',
    );
    return '$_temp0';
  }

  @override
  String get aiValidationZeroTotalKcal => 'Matched items produce 0 kcal.';

  @override
  String get aiValidationCaptureTotalKcalExtreme =>
      'Total kcal is implausibly high for one captured meal.';

  @override
  String get aiValidationCaptureTotalKcalHigh =>
      'Total kcal is unusually high; review portions.';

  @override
  String get aiValidationMacroTotalExtreme =>
      'Total macros are implausibly high.';

  @override
  String get aiValidationMacroTotalHigh =>
      'Total macros are unusually high; review portions.';

  @override
  String aiValidationTargetKcalMismatch(int delta) {
    return 'Calories miss the target by $delta kcal.';
  }

  @override
  String aiValidationTargetProteinMismatch(int delta) {
    return 'Protein misses the target by ${delta}g.';
  }

  @override
  String aiValidationTargetCarbsMismatch(int delta) {
    return 'Carbs miss the target by ${delta}g.';
  }

  @override
  String aiValidationTargetFatMismatch(int delta) {
    return 'Fat misses the target by ${delta}g.';
  }

  @override
  String aiValidationUnknownIssue(String code) {
    return 'Validation issue: $code';
  }

  @override
  String get currentlyTracking => 'Currently';

  @override
  String get currentlyTrackingDesc => 'Show in daily tracker hub';

  @override
  String get filter3Months => '3 Months';

  @override
  String get filter6Months => '6 Months';

  @override
  String get sectionConsistency => 'Consistency & Frequency';

  @override
  String get metricsWorkoutsWeek => 'Workouts (Week)';

  @override
  String get metricsCurrentStreak => 'Current Streak';

  @override
  String get metricsActiveWeeks => 'weeks active';

  @override
  String get placeholderCalendarHeatmap => 'Calendar Heatmap Visual';

  @override
  String get consistencyTrackerTitle => 'Consistency Tracker';

  @override
  String get consistencyTrackerComingSoon =>
      'Consistency & Habit Tracker (Coming Soon)';

  @override
  String get sectionMuscleVolume => 'Muscle Groups & Volume';

  @override
  String get metricsTopTrained => 'Top Trained';

  @override
  String get metricsMostNeglected => 'Most Neglected';

  @override
  String get placeholderMuscleHeatmap => 'Muscle Heatmap Visual';

  @override
  String get muscleAnalyticsTitle => 'Muscle Group Analytics';

  @override
  String get muscleAnalyticsComingSoon =>
      'Muscle Volume & Heatmaps (Coming Soon)';

  @override
  String get sectionPerformance => 'Performance & PRs';

  @override
  String get metricsRecentPrs => 'Recent PRs';

  @override
  String get metricsVolumeLifted => 'Volume Lifted';

  @override
  String get metricsMostImproved => 'Most Improved';

  @override
  String get exerciseAnalyticsTitle => 'Exercise Analytics';

  @override
  String get exerciseAnalyticsSubtitle =>
      'Search and analyze specific exercises';

  @override
  String get prDashboardTitle => 'PR Dashboard';

  @override
  String get prDashboardComingSoon => 'Records & Progress (Coming Soon)';

  @override
  String get exerciseAnalyticsComingSoon =>
      'Exercise search & specific trends (Coming Soon)';

  @override
  String get sectionRecovery => 'Recovery';

  @override
  String get metricsMuscleReadiness => 'Muscle Readiness';

  @override
  String get recoveryTrackerTitle => 'Recovery Tracker';

  @override
  String get recoveryTrackerComingSoon =>
      'Muscle readiness & fatigue (Coming Soon)';

  @override
  String get recoveryOverallMostlyRecovered => 'Mostly recovered';

  @override
  String get recoveryOverallMixed => 'Mixed recovery state';

  @override
  String get recoveryOverallSeveralRecovering =>
      'Several muscle groups still recovering';

  @override
  String get recoveryOverallInsufficientData =>
      'Not enough data for recovery insight yet';

  @override
  String recoveryHubCountsSummary(int recovering, int ready, int fresh) {
    return 'Recovering: $recovering  Ready: $ready  Fresh: $fresh';
  }

  @override
  String get recoveryHubNoDataSummary =>
      'Keep logging workouts to unlock recovery insights.';

  @override
  String get recoveryByMuscleTitle => 'Recovery by Muscle';

  @override
  String get recoveryStateRecovering => 'Recovering';

  @override
  String get recoveryStateReady => 'Ready';

  @override
  String get recoveryStateFresh => 'Fresh';

  @override
  String get recoveryStateUnknown => 'Unknown';

  @override
  String recoveryLastLoadedHours(int hours) {
    return 'Last significantly loaded: $hours h ago';
  }

  @override
  String get recoveryFatigueContextHigh =>
      'Fatigue context: high session fatigue';

  @override
  String get recoveryFatigueContextBaseline =>
      'Fatigue context: baseline session fatigue';

  @override
  String recoveryExplanationWithHighFatigue(String muscle, int hours) {
    return '$muscle: last significantly loaded $hours h ago, with high session fatigue.';
  }

  @override
  String recoveryExplanationBasic(String muscle, int hours) {
    return '$muscle: last significantly loaded $hours h ago.';
  }

  @override
  String get recoveryHeuristicDisclaimer =>
      'This is a conservative heuristic based on recent significant loading and session effort. It is not a medical recovery measurement.';

  @override
  String get recoveryReadinessLabel => 'Readiness';

  @override
  String recoveryRecentLoad(String sets) {
    return 'Last load: $sets equivalent sets';
  }

  @override
  String recoveryLastLoadPressure(String level) {
    return 'Last load pressure: $level';
  }

  @override
  String get recoveryPressureLow => 'low';

  @override
  String get recoveryPressureModerate => 'moderate';

  @override
  String get recoveryPressureHigh => 'high';

  @override
  String get recoveryPressureVeryHigh => 'very high';

  @override
  String recoveryCurrentWindow(int recoveringUpper, int readyUpper) {
    return 'Current window: recovering until about $recoveringUpper h, ready until about $readyUpper h.';
  }

  @override
  String recoveryWindowHeuristic(int from, int to) {
    return 'Current window: recovering until about $from h, ready until about $to h.';
  }

  @override
  String get recoveryRadarHeuristicCaption =>
      'Radar overview of current readiness by muscle. Status badges remain the primary signal.';

  @override
  String get recoveryNoDataBody =>
      'Not enough significant training load has been logged yet to estimate muscle recovery.';

  @override
  String get sectionBodyNutrition => 'Body & Nutrition';

  @override
  String get statisticsSectionTraining => 'Training';

  @override
  String get statisticsSectionBody => 'Body';

  @override
  String get statisticsEnableStepTrackingHint =>
      'Enable step tracking in Settings';

  @override
  String get statisticsNoStepDataYet => 'No step data yet';

  @override
  String get statisticsTotalSteps => 'Total steps';

  @override
  String get statisticsLast7Days => 'Last 7 days';

  @override
  String get statisticsLast30Days => 'Last 30 days';

  @override
  String get statisticsLast3Months => 'Last 3 months';

  @override
  String get statisticsLast6Months => 'Last 6 months';

  @override
  String get metricsCurrentWeight => 'Current Weight';

  @override
  String get metricsAvgCalories => 'Avg. Calories';

  @override
  String get placeholderWeightTrend => 'Weight Trend Line Chart';

  @override
  String get exerciseAnalyticsPrsLabel => 'PERSONAL RECORDS';

  @override
  String get exerciseAnalyticsTrendsLabel => 'TRENDS';

  @override
  String get exerciseAnalyticsNoData => 'No tracking data for this exercise.';

  @override
  String get exerciseAnalyticsNotEnoughData => 'Not enough data';

  @override
  String get exerciseAnalyticsChartWeight => 'Weight Over Time (kg)';

  @override
  String get exerciseAnalyticsChartVolume => 'Volume Over Time (kg)';

  @override
  String get exerciseAnalyticsChartSets => 'Sets Over Time';

  @override
  String get exerciseMetricMaxWeight => 'Max Weight';

  @override
  String get exerciseMetricVolume => 'Volume';

  @override
  String get exerciseMetricEst1RM => 'Est. 1RM';

  @override
  String get exerciseMetricDistance => 'Distance';

  @override
  String get exerciseMetricDuration => 'Duration';

  @override
  String get exerciseMetricPace => 'Pace';

  @override
  String get prBannerBestMaxWeight => 'Best Max Weight';

  @override
  String get prBannerBestVolumeSet => 'Best Volume Set';

  @override
  String get prBannerBest1RM => 'Best 1-Rep Max';

  @override
  String get newPersonalRecordLabel => 'New Personal Record';

  @override
  String get prBadgeTooltip => 'New Personal Record!';

  @override
  String get workoutSummaryNewRecordsTitle => 'New Records';

  @override
  String get allTimeRecordsLabel => 'All-Time Records';

  @override
  String get recentActivityLabel => 'Recent Activity';

  @override
  String get prsByRepRangeLabel => 'Best Set by Rep Range';

  @override
  String get volumeAnalyticsTitle => 'Volume Analytics';

  @override
  String get weeklyTonnageLabel => 'Weekly Tonnage';

  @override
  String get volumeByMuscleLabel => 'By Muscle Group';

  @override
  String get topExercisesLabel => 'Top Exercises';

  @override
  String get thisWeekLabel => 'This Week';

  @override
  String get avgPerWeekLabel => 'Avg / Week';

  @override
  String get streakLabel => 'Streak';

  @override
  String get trainingCalendarLabel => 'Training Calendar';

  @override
  String get workoutsPerWeekLabel => 'Workouts per Week';

  @override
  String get totalWorkoutsLabel => 'Total';

  @override
  String get weeksLabel => 'Weeks';

  @override
  String get tonnageKgLabel => 'Tonnage (kg)';

  @override
  String get noWorkoutDataLabel =>
      'No workout data yet. Start logging to see stats.';

  @override
  String get analyticsSectionVolumeMuscles => 'Volume & Muscle Groups';

  @override
  String get analyticsSectionPerformanceRecords => 'Performance & Records';

  @override
  String get analyticsTopVolume => 'Top Trained';

  @override
  String get analyticsLowestVolume => 'Lowest Volume';

  @override
  String get analyticsRecentRecords => 'Recent Records';

  @override
  String analyticsPerfWithReps(String weight, int reps, Object unit) {
    return '$weight $unit x $reps';
  }

  @override
  String get analyticsKgThisWeek => 'kg (this week)';

  @override
  String get analyticsRecoverySummary => '3 recovering, 8 ready';

  @override
  String get analyticsViewDetails => 'View details';

  @override
  String get analyticsRepRangeSuffix => ' reps';

  @override
  String get analyticsNoRecordYet => 'No record yet';

  @override
  String get analyticsNotableImprovements => 'Notable Improvements';

  @override
  String get analyticsNoPrTrendInWindow =>
      'There is no clear PR trend in this window yet.';

  @override
  String analyticsE1rmProgress(String previous, String recent, Object unit) {
    return 'e1RM $previous -> $recent $unit';
  }

  @override
  String get analyticsUnitKg => 'kg';

  @override
  String get analyticsUnitSets => 'sets';

  @override
  String get analyticsViewLabel => 'View';

  @override
  String get analyticsViewWeek => 'Week';

  @override
  String get analyticsViewMonth => 'Month';

  @override
  String get analyticsViewByExercise => 'By Exercise';

  @override
  String get analyticsViewByMuscle => 'By Muscle Group';

  @override
  String get analyticsMetricLabel => 'Metric';

  @override
  String get analyticsMovedWeightKg => 'Moved Weight (kg)';

  @override
  String get analyticsWorkSets => 'Work Sets';

  @override
  String get analyticsVolumeContextWithSets =>
      'Moved weight = weight x reps. Switch to work sets for count-based load.';

  @override
  String get analyticsVolumeContextTonnageOnly =>
      'This view uses moved weight (weight x reps).';

  @override
  String get analyticsKpisHeader => 'KPIs';

  @override
  String get analyticsTrainingDaysPerWeek => 'Training Days / Week';

  @override
  String get analyticsLast4Weeks => 'last 4 weeks';

  @override
  String get analyticsRhythm => 'Rhythm';

  @override
  String get analyticsVsPrior4Weeks => 'vs the previous 4 weeks';

  @override
  String get analyticsRollingConsistency => 'Rolling Consistency';

  @override
  String get analyticsWeeksAtLeast2Workouts => 'weeks with at least 2 sessions';

  @override
  String get analyticsInTimeframe => 'In timeframe';

  @override
  String get analyticsVsPriorPeriod => 'vs prior period';

  @override
  String get analyticsCalendarExplainer =>
      'Color intensity reflects sessions per day, making this a true consistency map.';

  @override
  String get analyticsSelectDayPrompt =>
      'Select a day to inspect session count.';

  @override
  String analyticsSelectedDayWorkouts(String date, int count) {
    return '$date: $count sessions';
  }

  @override
  String get analyticsTotalSessions => 'Total Sessions';

  @override
  String get analyticsPlaceholderWeightValue => '82.5';

  @override
  String get analyticsPlaceholderWeightTrend => 'kg (-0.5)';

  @override
  String get analyticsPlaceholderCaloriesValue => '2,450';

  @override
  String get analyticsPlaceholderCaloriesUnit => 'kcal/day';

  @override
  String get analyticsMuscleWeeklySets => 'Weekly Sets';

  @override
  String get analyticsMuscleTopFrequency => 'Top Frequency';

  @override
  String get analyticsPerWeekAbbrev => 'wk';

  @override
  String get analyticsKeepTrackingUnlockInsights =>
      'Keep tracking to unlock insights.';

  @override
  String get analyticsGuidanceNoClearWeakPoint =>
      'Guidance: No clear weak point in this period.';

  @override
  String analyticsGuidanceLowerEmphasis(String muscles) {
    return 'Guidance: Lower recent emphasis on $muscles.';
  }

  @override
  String get analyticsPeriodLabel => 'Period';

  @override
  String get analyticsEquivalentSetsExplainer =>
      'Equivalent hard sets use primary x1.0 and secondary x0.3 weighting. Frequency counts only days reaching >= 1.0 equivalent sets.';

  @override
  String get analyticsWeeklySetsByMuscle => 'Ø Weekly Sets by Muscle';

  @override
  String get analyticsFrequencyByMuscle => 'Frequency by Muscle';

  @override
  String get analyticsRecentDistributionHeatmap =>
      'Recent Distribution Heatmap';

  @override
  String get analyticsRadarOverviewTitle => 'Radar Overview';

  @override
  String get analyticsRadarVolumeCaption =>
      'Shows relative volume distribution across muscles for a quick at-a-glance summary.';

  @override
  String get analyticsGuidanceTitle => 'Guidance';

  @override
  String get analyticsGuidanceDirectionalDisclaimer =>
      'This is directional guidance based on your recent set distribution, not an absolute diagnosis.';

  @override
  String get analyticsGuidanceSoftenedDisclaimer =>
      'Insights are intentionally softened until enough data is available.';

  @override
  String analyticsWeekTotalEquivalentSets(String value) {
    return 'Ø $value equivalent sets per week';
  }

  @override
  String get analyticsFrequencyRuleFooter =>
      'Frequency counts only days where the muscle reached >= 1.0 equivalent sets.';

  @override
  String liveWorkoutE1rmCurrentSet(String value, Object unit) {
    return 'e1RM $value $unit';
  }

  @override
  String liveWorkoutE1rmBestSession(String value, Object unit) {
    return 'Best e1RM this session: $value $unit';
  }

  @override
  String liveWorkoutE1rmVsLastSession(String delta, Object unit) {
    return 'vs last session: $delta $unit';
  }

  @override
  String get bodyNutritionCorrelationTitle => 'Body & Nutrition Trends';

  @override
  String get metricsWeightChange => 'Weight Change';

  @override
  String get analyticsKcalPerDay => 'kcal/day';

  @override
  String get analyticsDaysWithWeightData => 'days with weight';

  @override
  String get analyticsDayUnitLabel => 'days';

  @override
  String get analyticsPerDayLabel => 'per day';

  @override
  String get analyticsEffectiveRangeLabel => 'Effective range';

  @override
  String get analyticsAxisXLabel => 'X';

  @override
  String get analyticsAxisYLabel => 'Y';

  @override
  String get analyticsHighConfidenceLabel => 'Higher-confidence pattern';

  @override
  String get analyticsLowConfidenceLabel => 'Lower-confidence pattern';

  @override
  String get analyticsObservedPatternLabel => 'Observed pattern';

  @override
  String get analyticsBodyNutritionTrendContext =>
      'Weight and calories over time';

  @override
  String analyticsBodyNutritionTrendContextHint(Object unit) {
    return 'The chart scales each series to fit the same space; tooltips show raw $unit and kcal values.';
  }

  @override
  String analyticsBodyNutritionNormalizedHint(Object unit) {
    return 'The chart scales weight and calories to fit the same space; tooltips show raw $unit and kcal values.';
  }

  @override
  String analyticsBodyNutritionTotalWeightLabel(Object unit) {
    return 'Total weight ($unit)';
  }

  @override
  String get analyticsBodyNutritionTotalCaloriesLabel =>
      'Total calories (kcal)';

  @override
  String analyticsWeightTrendLabel(String unit) {
    return 'Weight ($unit)';
  }

  @override
  String get analyticsCaloriesTrendLabel => 'Calories (kcal)';

  @override
  String get analyticsInterpretationTitle => 'Interpretation';

  @override
  String get analyticsBodyNutritionConfidenceHighHint =>
      'Data coverage in this range is strong enough for a more reliable pattern read.';

  @override
  String get analyticsBodyNutritionConfidenceModerateHint =>
      'Data coverage is moderate. Trends are useful context, but keep logging for stronger confidence.';

  @override
  String get analyticsBodyNutritionConfidenceLowHint =>
      'Data coverage in this range is still limited, so treat this as early context.';

  @override
  String get analyticsBodyNutritionLowConfidenceNudge =>
      'Keep logging weight and calories regularly to improve confidence.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceHigh =>
      'Interpretation confidence: higher. Use this as trend context, not a direct cause statement.';

  @override
  String get analyticsBodyNutritionInterpretationConfidenceLow =>
      'Interpretation confidence: lower. Use this as an early pattern signal and keep tracking.';

  @override
  String get analyticsCorrelationDisclaimer =>
      'This view provides trend context. It does not prove that calorie changes directly caused weight changes.';

  @override
  String get analyticsInsightStableWeightCaloriesUp =>
      'Weight trend is stable while average calories increased.';

  @override
  String get analyticsInsightWeightUpCaloriesUp =>
      'Weight is trending upward alongside higher average calorie intake.';

  @override
  String get analyticsInsightCaloriesDownWeightStable =>
      'Recent calorie reduction has not yet clearly changed the weight trend.';

  @override
  String get analyticsInsightWeightDownCaloriesDown =>
      'Weight is trending downward alongside lower average calorie intake.';

  @override
  String get analyticsInsightMixedPattern =>
      'Weight and calorie trends are mixed without a clear relationship yet.';

  @override
  String get analyticsInsightNotEnoughData =>
      'Not enough consistent data yet for a meaningful trend read.';

  @override
  String get analyticsModerateConfidenceLabel => 'Moderate-confidence pattern';

  @override
  String get analyticsInsufficientConfidenceLabel =>
      'Insufficient data confidence';

  @override
  String get analyticsTrendRising => 'Rising';

  @override
  String get analyticsTrendFalling => 'Falling';

  @override
  String get analyticsTrendStable => 'Stable';

  @override
  String get analyticsTrendUnclear => 'Unclear';

  @override
  String get analyticsRelationshipAlignedCut =>
      'Lower intake and falling bodyweight are aligned.';

  @override
  String get analyticsRelationshipAlignedBulk =>
      'Higher intake and rising bodyweight are aligned.';

  @override
  String get analyticsRelationshipStableMaintenance =>
      'Weight and intake look broadly stable.';

  @override
  String get analyticsRelationshipMixed => 'Signals are mixed or delayed.';

  @override
  String get analyticsRelationshipInsufficient =>
      'Not enough consistent overlap to classify the pattern yet.';

  @override
  String analyticsBasedOnDataCoverage(int weightDays, int calorieDays) {
    return 'Based on $weightDays weigh-ins and $calorieDays calorie days';
  }

  @override
  String get restTimerNotificationTitle => 'Rest finished';

  @override
  String get restTimerNotificationBody =>
      'Your pause timer is over. Ready for the next set.';

  @override
  String get onboardingContinueSetup => 'Set Up Profile';

  @override
  String get onboardingRestoreFromBackup => 'Restore from Backup';

  @override
  String get onboardingRestoreImporting => 'Importing backup...';

  @override
  String get onboardingRestoreSuccess => 'Backup restored successfully!';

  @override
  String get onboardingRestoreFailed =>
      'Import failed. Please check the file and try again.';

  @override
  String get onboardingRestoreFromICloud => 'Restore from iCloud';

  @override
  String get onboardingRestoreICloudSuccess =>
      'iCloud backup restored successfully!';

  @override
  String get onboardingRestoreICloudFailed =>
      'iCloud restore failed. Check your connection and try again.';

  @override
  String get finishWorkoutTitleLabel => 'Workout Title';

  @override
  String get finishWorkoutNotesLabel => 'Notes (optional)';

  @override
  String get finishWorkoutNotesHint => 'How did the workout go?';

  @override
  String get sleepSectionTitle => 'Sleep';

  @override
  String get sleepSectionSubtitleDayEntry =>
      'Day overview and detail drill-downs';

  @override
  String get sleepSectionSubtitleAllEntry =>
      'Sleep day, week, and month views are available from this entry';

  @override
  String get sleepScopeDay => 'Day';

  @override
  String get sleepScopeWeek => 'Week';

  @override
  String get sleepScopeMonth => 'Month';

  @override
  String get sleepWeekSummaryTitle => 'Week summary';

  @override
  String get sleepMonthSummaryTitle => 'Month summary';

  @override
  String get sleepSleepWindowTitle => 'Sleep window';

  @override
  String get sleepDailyScoreTitle => 'Daily score';

  @override
  String get sleepMonthDailyScoreStatesTitle => 'Daily score states';

  @override
  String sleepMeanScoreLabel(String value) {
    return 'Mean score: $value';
  }

  @override
  String get sleepHubScoreLabel => 'Sleep score';

  @override
  String get sleepHubAverageLabel => 'Average';

  @override
  String get sleepHubBedtimeLabel => 'Bedtime';

  @override
  String get sleepHubInterruptionsLabel => 'Interruptions';

  @override
  String sleepHubInterruptionsSummary(int count, String duration) {
    return '$count wake-ups, $duration total';
  }

  @override
  String sleepWeekdayAvgDurationLabel(String value) {
    return 'Weekday avg duration: $value';
  }

  @override
  String sleepWeekendAvgDurationLabel(String value) {
    return 'Weekend avg duration: $value';
  }

  @override
  String get sleepWeekNoScoredNights =>
      'No scored sleep nights available in this week yet.';

  @override
  String get sleepMonthNoScoredNights =>
      'No scored sleep nights available this month yet.';

  @override
  String get sleepSettingsSectionTitle => 'Sleep';

  @override
  String get sleepEnableTrackingTitle => 'Enable sleep tracking';

  @override
  String get sleepEnableTrackingSubtitle =>
      'Read sleep and overnight heart rate from Health Connect / HealthKit';

  @override
  String get sleepHealthConnectionStatusTitle => 'Health connection status';

  @override
  String get sleepRequestAccessTitle => 'Request access';

  @override
  String get sleepRequestAccessSubtitle =>
      'Request or re-request sleep/heart-rate permissions';

  @override
  String get sleepImportNowTitle => 'Import sleep data now';

  @override
  String get sleepImportNowSubtitle =>
      'Import all available sleep data (all time)';

  @override
  String get sleepRawImportsTitle => 'View raw sleep imports';

  @override
  String get sleepRawImportsSubtitle => 'Show recent Health Connect payloads';

  @override
  String get sleepDataStatusTitle => 'Data status';

  @override
  String get sleepDataStatusSubtitle =>
      'Permissions granted. If no sleep appears yet, run a manual import below.';

  @override
  String get sleepDataStatusSubtitleIos =>
      'Connection active. If data is missing (0 sessions imported), manually verify the read permissions in the Apple Health app.';

  @override
  String get sleepNoPermissionSubtitle =>
      'Sleep and heart-rate permissions are required to import sleep data.';

  @override
  String get sleepFeatureUnavailableTitle => 'Feature unavailable';

  @override
  String get sleepFeatureUnavailableSubtitle =>
      'Sleep import is unavailable on this device or Health Connect is not installed.';

  @override
  String get sleepNoRawImportsFound => 'No raw sleep imports found yet.';

  @override
  String get sleepRawImportsSheetTitle => 'Raw sleep imports (latest)';

  @override
  String sleepImportFinishedSessions(int count) {
    return 'Sleep import finished ($count sessions).';
  }

  @override
  String get sleepImportUnavailableCheckPermissions =>
      'Sleep import unavailable. Check permissions.';

  @override
  String get sleepStatusChecking => 'Checking permission status…';

  @override
  String get sleepStatusReady => 'Ready';

  @override
  String get sleepStatusDenied => 'Denied';

  @override
  String get sleepStatusPartial => 'Partial access';

  @override
  String get sleepStatusUnavailable => 'Unavailable on this device';

  @override
  String get sleepStatusNotInstalled => 'Health Connect not installed';

  @override
  String get sleepStatusTechnicalError => 'Technical error';

  @override
  String get sleepConnectHealthDataTitle => 'Connect health data';

  @override
  String get sleepConnectHealthDataMessage =>
      'Connect HealthKit or Health Connect to import sleep records.';

  @override
  String get sleepPermissionDeniedTitle => 'Permission denied';

  @override
  String get sleepPermissionDeniedMessage =>
      'Sleep permissions are denied. Open settings to grant access.';

  @override
  String get sleepSourceUnavailableTitle => 'Source unavailable';

  @override
  String get sleepSourceUnavailableMessage =>
      'Sleep data source is unavailable or not installed on this device.';

  @override
  String get sleepEmptyDayNoData => 'No sleep data available for this day.';

  @override
  String get sleepEmptyDayConnectMessage =>
      'Connect Health Connect/HealthKit in Settings and import recent sleep data.';

  @override
  String get sleepOpenSettingsButton => 'Open settings';

  @override
  String get sleepImportNowButton => 'Import now';

  @override
  String get sleepImportFinishedRefreshing =>
      'Sleep import finished. Refreshing...';

  @override
  String get sleepImportUnavailableSettingsHint =>
      'Sleep import not available. Check permissions in Settings.';

  @override
  String get sleepTimelineTitle => 'Timeline';

  @override
  String get sleepTimelineUnavailable =>
      'No stage timeline available for this night.';

  @override
  String get sleepSessionTypeCore => 'Core Sleep';

  @override
  String get sleepSessionTypeNap => 'Nap';

  @override
  String get sleepIntervalsDrawerTitle => 'Sleep Intervals';

  @override
  String get sleepStageDeepLabel => 'Deep';

  @override
  String get sleepStageLightLabel => 'Light';

  @override
  String get sleepStageRemLabel => 'REM';

  @override
  String get sleepStageAwakeLabel => 'Awake';

  @override
  String get sleepScoreCardTitle => 'Sleep quality';

  @override
  String get sleepScoreUnavailableForNight =>
      'Score unavailable for this night.';

  @override
  String sleepScoreCompletenessLabel(String value) {
    return 'Score completeness: $value';
  }

  @override
  String get sleepQualityGood => 'Good';

  @override
  String get sleepQualityAverage => 'Average';

  @override
  String get sleepQualityPoor => 'Poor';

  @override
  String get sleepQualityUnavailable => 'Unavailable';

  @override
  String get sleepQualitySubtitleGood => 'Recovery looked strong overnight.';

  @override
  String get sleepQualitySubtitleAverage =>
      'Sleep was okay with room for improvement.';

  @override
  String get sleepQualitySubtitlePoor => 'Recovery signals were weak tonight.';

  @override
  String get sleepQualitySubtitleUnavailable =>
      'Not enough data to score this night.';

  @override
  String get sleepQualityRegularityNotContributing =>
      'Regularity did not contribute (<5 valid days).';

  @override
  String get sleepQualityRegularityPreliminary =>
      'Regularity is preliminary (5-6 valid days).';

  @override
  String sleepQualityRegularityStable(int days) {
    return 'Regularity is stable ($days days).';
  }

  @override
  String sleepRegularityNightView(int count) {
    return '$count-night view';
  }

  @override
  String get sleepMetricUnavailable => 'Unavailable';

  @override
  String get sleepMetricDurationTitle => 'Duration';

  @override
  String get sleepMetricHeartRateTitle => 'Heart rate';

  @override
  String get sleepMetricRegularityTitle => 'Regularity';

  @override
  String get sleepMetricDepthTitle => 'Depth';

  @override
  String get sleepMetricInterruptionsTitle => 'Interruptions';

  @override
  String get sleepMetricDepthLowConfidence => 'Low confidence';

  @override
  String get sleepMetricDepthStagesAvailable => 'Stages available';

  @override
  String get sleepDurationUnavailable => 'Duration data is unavailable.';

  @override
  String get sleepDurationStatusWithinTarget => 'Within target';

  @override
  String get sleepDurationStatusBelowTarget => 'Below target';

  @override
  String get sleepDurationSubtitle =>
      'Your total sleep duration for this night.';

  @override
  String get sleepDurationBenchmarkHint =>
      'Adults often do best with roughly 7–9 hours. This benchmark helps you see where your night sits in that range.';

  @override
  String get sleepDepthUnavailable => 'Depth data is unavailable.';

  @override
  String get sleepDepthConfidenceTooLow =>
      'Stage confidence is too low for a reliable depth breakdown.';

  @override
  String get sleepDepthBreakdownUnavailable =>
      'Stage duration breakdown is unavailable for this night.';

  @override
  String get sleepDepthRatingRestorative => 'Restorative';

  @override
  String get sleepDepthRatingLightLeaning => 'Light-leaning';

  @override
  String sleepDepthStageConfidenceLabel(String value) {
    return 'Stage confidence: $value';
  }

  @override
  String get sleepDepthSubtitle =>
      'Stage distribution based on derived timeline segments.';

  @override
  String get sleepInterruptionsUnavailable =>
      'Interruptions data is unavailable.';

  @override
  String get sleepInterruptionsStatusNoneDetected => 'None detected';

  @override
  String get sleepInterruptionsStatusDetected => 'Detected';

  @override
  String get sleepInterruptionsSubtitle =>
      'Qualifying wake interruptions overnight.';

  @override
  String get sleepInterruptionsTotalWakeDuration => 'Total wake duration';

  @override
  String get sleepInterruptionsFootnote =>
      'This view includes only qualifying interruptions from derived analysis outputs.';

  @override
  String get sleepRegularityUnavailable => 'Regularity data is unavailable.';

  @override
  String sleepRegularityNightRange(int count) {
    return '$count-night range';
  }

  @override
  String get sleepRegularityStatusSufficientTrend => 'Sufficient trend data';

  @override
  String get sleepRegularityStatusLimitedTrend => 'Limited trend data';

  @override
  String get sleepRegularitySubtitle =>
      'Bedtime and wake windows for recent nights.';

  @override
  String get sleepRegularityAverageBedtime => 'Average bedtime';

  @override
  String get sleepRegularityAverageWake => 'Average wake';

  @override
  String get sleepHeartRateUnavailable =>
      'Sleep heart-rate data is unavailable.';

  @override
  String get sleepHeartRateStatusNoSampleSeries =>
      'No sample series for this night';

  @override
  String get sleepHeartRateStatusBaselineNotEstablished =>
      'Baseline not established';

  @override
  String get sleepHeartRateStatusComparisonUnavailable =>
      'Baseline comparison unavailable';

  @override
  String get sleepHeartRateStatusBelowBaseline => 'Below baseline';

  @override
  String get sleepHeartRateStatusAboveBaseline => 'Above baseline';

  @override
  String get sleepHeartRateNoSamplesText =>
      'No persisted sleep heart-rate samples are available for this night.';

  @override
  String get sleepHeartRateBaselineNotEstablishedText =>
      'Baseline not established yet. This is neutral and expected early on.';

  @override
  String get sleepHeartRateComparisonUnavailableText =>
      'Baseline comparison is currently unavailable for this night.';

  @override
  String sleepHeartRateDeltaText(String direction, String delta, String unit) {
    return 'Your sleep HR is $direction baseline by $delta $unit.';
  }

  @override
  String get sleepHeartRateDirectionBelow => 'below';

  @override
  String get sleepHeartRateDirectionAbove => 'above';

  @override
  String get sleepHeartRateComparedBaselineSubtitle =>
      'Compared with your established sleep baseline.';

  @override
  String get sleepHeartRateNoBaselineSubtitle =>
      'Baseline is not established yet. This is neutral.';

  @override
  String get sleepHeartRateSamplesUnavailable =>
      'No heart-rate samples were stored for this night. Trend chart is unavailable.';

  @override
  String sleepHeartRateDashedLineHint(String value, String unit) {
    return 'Dashed line shows baseline ($value $unit).';
  }

  @override
  String get sleepBpmUnit => 'bpm';

  @override
  String get sleepRawImportImportedAt => 'Imported at';

  @override
  String get sleepRawImportStatus => 'Status';

  @override
  String get sleepRawImportSource => 'Source';

  @override
  String get sleepRawImportApp => 'App';

  @override
  String get sleepRawImportConfidence => 'Confidence';

  @override
  String get sleepRawImportPayload => 'Payload';

  @override
  String get adaptiveBodyweightTargetSectionTitle =>
      'Adaptive bodyweight target';

  @override
  String get adaptiveRecommendationSettingsSectionTitle =>
      'Recommendation settings';

  @override
  String get adaptiveGoalDirectionLabel => 'Goal direction';

  @override
  String get adaptiveGoalLose => 'Lose weight';

  @override
  String get adaptiveGoalMaintain => 'Maintain weight';

  @override
  String get adaptiveGoalGain => 'Gain weight';

  @override
  String adaptiveRatePerWeek(String value, Object unit) {
    return '$value $unit/week';
  }

  @override
  String get adaptivePriorActivityLabel => 'Baseline daily activity';

  @override
  String get adaptivePriorActivityLow => 'Low activity';

  @override
  String get adaptivePriorActivityModerate => 'Moderate activity';

  @override
  String get adaptivePriorActivityHigh => 'High activity';

  @override
  String get adaptivePriorActivityVeryHigh => 'Very high activity';

  @override
  String get adaptivePriorActivityHelpIntro =>
      'Baseline daily activity only (separate from extra cardio):';

  @override
  String get adaptivePriorActivityHelpLowLine =>
      'Low: mostly sitting, student/pupil or office routine.';

  @override
  String get adaptivePriorActivityHelpModerateLine =>
      'Moderate: mixed sitting, walking, and standing.';

  @override
  String get adaptivePriorActivityHelpHighLine =>
      'High: lots of standing/walking or a physically active job.';

  @override
  String get adaptivePriorActivityHelpVeryHighLine =>
      'Very high: very movement-heavy routine/job with consistently high daily activity.';

  @override
  String get adaptiveExtraCardioLabel =>
      'Extra cardio/endurance outside the app';

  @override
  String get adaptiveExtraCardioOption0 => '0 h/week';

  @override
  String get adaptiveExtraCardioOption1 => '1 h/week';

  @override
  String get adaptiveExtraCardioOption2 => '2 h/week';

  @override
  String get adaptiveExtraCardioOption3 => '3 h/week';

  @override
  String get adaptiveExtraCardioOption5 => '5 h/week';

  @override
  String get adaptiveExtraCardioOption7Plus => '7+ h/week';

  @override
  String get adaptiveExtraCardioHelp =>
      'Include jogging, running, cycling, swimming, or other endurance sessions not logged as Train Libre workouts.';

  @override
  String get onboardingAdaptiveGoalTitle => 'Adaptive nutrition recommendation';

  @override
  String get onboardingAdaptiveGoalSubtitle =>
      'Set your direction and weekly rate. We create a conservative starting recommendation and adapt it with your logs.';

  @override
  String get adaptiveRecommendationGenerating => 'Generating...';

  @override
  String get adaptiveRecommendationRefresh => 'Refresh recommendation';

  @override
  String get onboardingAdaptiveSummaryEmpty =>
      'Set your goal inputs and tap refresh to preview your starting recommendation.';

  @override
  String get onboardingAdaptiveSummaryTitle => 'Recommendation preview';

  @override
  String onboardingAdaptiveSummaryCalories(int value) {
    return 'Calories: $value kcal';
  }

  @override
  String onboardingAdaptiveSummaryProtein(int value) {
    return 'Protein: $value g';
  }

  @override
  String onboardingAdaptiveSummaryCarbs(int value) {
    return 'Carbs: $value g';
  }

  @override
  String onboardingAdaptiveSummaryFat(int value) {
    return 'Fat: $value g';
  }

  @override
  String onboardingAdaptiveSummaryConfidence(String value) {
    return 'Data basis: $value';
  }

  @override
  String get onboardingAdaptiveSummaryApply => 'Apply to daily goals';

  @override
  String get onboardingAdaptiveSummaryApplied => 'Applied to daily goals';

  @override
  String get onboardingBodyFatPageTitle => 'Body fat %';

  @override
  String get onboardingBodyFatPageSubtitle =>
      'Optional step: enter a rough estimate if you know it.';

  @override
  String get onboardingBodyFatOptionalLabel => 'Body fat % (optional)';

  @override
  String get onboardingBodyFatOptionalHelper =>
      'Optional: only enter this if you roughly know your value. Leaving it empty is okay. It helps personalize the initial recommendation.';

  @override
  String get onboardingBodyFatHelpAction => 'How do I estimate this?';

  @override
  String get bodyFatGuidanceTitle => 'Body fat % guidance';

  @override
  String get bodyFatGuidanceIntro =>
      'Body-fat percentage can only be estimated roughly from appearance. This is orientation only, not a precise diagnosis.';

  @override
  String get bodyFatGuidanceDisclaimer =>
      'Appearance can vary strongly at the same body-fat level due to muscle mass, fat distribution, genetics, water retention, posture, and lighting.';

  @override
  String get bodyFatGuidanceSexLabel => 'Reference sex';

  @override
  String bodyFatGuidancePercent(int percent) {
    return '$percent%';
  }

  @override
  String get bodyFatGuidanceMale10 => 'Very lean, clear definition.';

  @override
  String get bodyFatGuidanceMale15 => 'Athletic, visibly defined.';

  @override
  String get bodyFatGuidanceMale20 => 'Sporty, slightly softer.';

  @override
  String get bodyFatGuidanceMale25 =>
      'Less definition, more waist and belly softness.';

  @override
  String get bodyFatGuidanceMale30 => 'Clearly softer, rounder.';

  @override
  String get bodyFatGuidanceMale35 =>
      'Very soft, almost no visible definition.';

  @override
  String get bodyFatGuidanceMale40 =>
      'Strongly rounder appearance, no visible definition.';

  @override
  String get bodyFatGuidanceFemale15 => 'Very lean, very defined.';

  @override
  String get bodyFatGuidanceFemale20 => 'Lean and athletic.';

  @override
  String get bodyFatGuidanceFemale25 => 'Fit, lightly soft.';

  @override
  String get bodyFatGuidanceFemale30 =>
      'Soft, healthy-looking average athletic-to-normal range.';

  @override
  String get bodyFatGuidanceFemale35 => 'Noticeably softer.';

  @override
  String get bodyFatGuidanceFemale40 =>
      'Clearly softer, rounder overall appearance.';

  @override
  String get adaptiveRecommendationCardTitle => 'Adaptive recommendation';

  @override
  String get adaptiveRecommendationEmptyBody =>
      'Track weight and nutrition for about a week to unlock your first weekly recommendation.';

  @override
  String adaptiveRecommendationGoalLine(String goal, String rate) {
    return 'Goal: $goal ($rate)';
  }

  @override
  String adaptiveRecommendationMaintenanceLine(int value) {
    return 'Maintenance estimate: $value kcal';
  }

  @override
  String adaptiveRecommendationMaintenanceRangeLine(int lower, int upper) {
    return 'Likely range: $lower-$upper kcal';
  }

  @override
  String get adaptiveRecommendationUncertaintyHintNarrow =>
      'Your likely maintenance range is fairly tight. Small day-to-day shifts are normal.';

  @override
  String get adaptiveRecommendationUncertaintyHintModerate =>
      'Your likely maintenance range is moderate right now. Some movement week to week is normal.';

  @override
  String get adaptiveRecommendationUncertaintyHintWide =>
      'Your likely maintenance range is still wide. This is normal while we gather more steady data.';

  @override
  String get adaptiveRecommendationStabilizingHint =>
      'We are still adapting to your recent phase, so this estimate can move more than usual.';

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
    return 'Data basis: $value';
  }

  @override
  String adaptiveRecommendationDataBasisLine(
      int windowDays, int weightLogs, int intakeDays) {
    return 'Data basis: $windowDays days, $weightLogs weight logs, $intakeDays intake days';
  }

  @override
  String adaptiveRecommendationActiveCaloriesLine(int value) {
    return 'Current active calories: $value kcal';
  }

  @override
  String adaptiveRecommendationCalculatedAtLine(String value) {
    return 'Calculated at: $value';
  }

  @override
  String adaptiveRecommendationNextDueLine(String value) {
    return 'Next adaptive recommendation due: $value';
  }

  @override
  String adaptiveRecommendationNextDueShort(String value) {
    return 'Next $value';
  }

  @override
  String get adaptiveRecommendationDueNowLine =>
      'A new adaptive recommendation is due this week.';

  @override
  String get adaptiveRecommendationDueNowShort => 'Due this week';

  @override
  String get adaptiveRecommendationMaintenanceLabel => 'Estimated maintenance';

  @override
  String get adaptiveRecommendationMaintenanceSourceLabel =>
      'Profile prior + recent logs';

  @override
  String get adaptiveRecommendationMaintenanceUnit => 'kcal/day';

  @override
  String get adaptiveRecommendationMacroTargetsLabel => 'Recommended targets';

  @override
  String get adaptiveRecommendationTargetCaloriesLabel => 'Target kcal';

  @override
  String get adaptiveRecommendationDataQualityLabel => 'Data quality';

  @override
  String get adaptiveRecommendationEnergyDensityLabel =>
      'Effective energy density';

  @override
  String adaptiveRecommendationEnergyDensityValue(int value) {
    return '$value kcal/kg';
  }

  @override
  String get adaptiveRecommendationEnergyDensityExplanation =>
      'Dynamic value based on weight and water-loss ratio';

  @override
  String get adaptiveRecommendationRecalculateNowAction => 'Recalculate now';

  @override
  String get adaptiveRecommendationRecalculating => 'Recalculating...';

  @override
  String get adaptiveRecommendationApplying => 'Applying...';

  @override
  String get adaptiveRecommendationApplyAction => 'Apply recommendation';

  @override
  String get adaptiveRecommendationWarningCalorieFloor =>
      'Recommendation constrained by a minimum calorie safety floor. Review profile data and recent logs before applying.';

  @override
  String get adaptiveRecommendationWarningUnresolvedFood =>
      'Some nutrition entries could not be fully resolved for calories. Check recent logs before applying.';

  @override
  String get adaptiveRecommendationWarningLargeAdjustment =>
      'Large adjustment detected. Please review your recent logging completeness before applying.';

  @override
  String get adaptiveRecommendationWarningMacroConstrained =>
      'Macro split was constrained by the calorie budget. Check if your target rate is too aggressive.';

  @override
  String get adaptiveRecommendationWarningConservative =>
      'Review suggested: recommendation was adjusted conservatively due to data variability.';

  @override
  String get adaptiveRecommendationDataBasisHintDefault =>
      'Built from recent logs and their completeness.';

  @override
  String get adaptiveRecommendationDataBasisHintPriorOnly =>
      'Based on profile/prior data only. Add recent weight and intake logs for adaptive adjustment.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseWeight =>
      'Recent weight logs are sparse, so trend quality is limited.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseIntake =>
      'Recent intake logs are sparse, so maintenance inference is limited.';

  @override
  String get adaptiveRecommendationDataBasisHintSparseWeightAndIntake =>
      'Recent weight and intake logs are sparse, so this recommendation is more conservative.';

  @override
  String get adaptiveConfidenceNotEnoughData => 'Profile/prior only';

  @override
  String get adaptiveConfidenceLow => 'Limited recent logs';

  @override
  String get adaptiveConfidenceMedium => 'Usable recent logs';

  @override
  String get adaptiveConfidenceHigh => 'Strong recent logs';

  @override
  String get adaptiveRecommendationRecalculatedSnack =>
      'Recommendation recalculated.';

  @override
  String get adaptiveRecommendationAppliedToGoalsSnack =>
      'Recommendation applied to active goals.';

  @override
  String get adaptiveRecommendationNotAvailableSnack =>
      'No recommendation available to apply.';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsAppearanceSubtitle =>
      'Adjust theme, visual style, and haptics';

  @override
  String get settingsShowSugarInDiaryOverviewTitle =>
      'Show sugar in Diary overview';

  @override
  String get settingsShowSugarInDiaryOverviewSubtitle =>
      'Shows sugar in the top daily overview section';

  @override
  String get settingsOverviewExtraNutrientTitle =>
      'Additional Nutrient in Overview';

  @override
  String get settingsOverviewExtraNutrientSubtitle =>
      'Add a third nutrient tile to the daily overview section';

  @override
  String get settingsSectionHealthTracking => 'Health & Tracking';

  @override
  String get settingsStepsSubtitle => 'Tracking, source policy, and providers';

  @override
  String get settingsSleepSubtitle => 'Import, permissions, and sleep status';

  @override
  String get settingsPulseSubtitle =>
      'Opt-in pulse analysis and heart-rate access';

  @override
  String get settingsHealthExportSubtitle =>
      'Manage Apple Health and Health Connect export';

  @override
  String get settingsSectionNutritionAndData => 'Nutrition & Data';

  @override
  String get settingsSectionSupportAbout => 'Support / About';

  @override
  String get settingsHapticFeedbackTitle => 'Haptic feedback';

  @override
  String get settingsHapticFeedbackSubtitle =>
      'Light vibrations for confirmations and AI waiting';

  @override
  String get stepsSettingsEnableTrackingTitle => 'Enable steps tracking';

  @override
  String get stepsSettingsEnableTrackingSubtitle =>
      'Read step data from Apple Health / Health Connect';

  @override
  String get stepsSettingsSourcePolicyTitle => 'Source policy';

  @override
  String get stepsSettingsSourcePolicyAutoDominant => 'Auto (dominant source)';

  @override
  String get stepsSettingsSourcePolicyAutoDominantSubtitle =>
      'Recommended: use one source per day to avoid overlap inflation.';

  @override
  String get stepsSettingsSourcePolicyMaxPerHour => 'Merge (max per hour)';

  @override
  String get stepsSettingsSourcePolicyMaxPerHourSubtitle =>
      'Combine sources by taking the highest hourly bucket.';

  @override
  String get stepsSettingsProviderFilterTitle => 'Provider filter';

  @override
  String get pulseTitle => 'Pulse';

  @override
  String get pulseChartTitle => 'Pulse over time';

  @override
  String get pulseRangeLabel => 'Range';

  @override
  String get pulseAverageLabel => 'Average';

  @override
  String get pulseRestingLabel => 'Resting';

  @override
  String get pulseInsufficientData =>
      'Too few pulse samples for a reliable chart.';

  @override
  String get pulseMethodNote =>
      'Average pulse is time-weighted. Resting pulse is a conservative estimate from the lowest 20% of samples in the selected period.';

  @override
  String pulseSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count samples',
      one: '1 sample',
      zero: 'No samples',
    );
    return '$_temp0';
  }

  @override
  String get pulseQualityReady => 'Good coverage';

  @override
  String get pulseQualityLimited => 'Limited data';

  @override
  String get pulseQualityInsufficient => 'Very sparse';

  @override
  String get pulseQualityNoData => 'No data';

  @override
  String get pulseNoDataDisabled => 'Pulse analysis is disabled in Settings.';

  @override
  String get pulseNoDataPermissionDenied =>
      'Heart-rate permission is required to show pulse analysis.';

  @override
  String get pulseNoDataUnavailable =>
      'Pulse data is currently unavailable on this device.';

  @override
  String get pulseNoDataQueryFailed => 'Could not read pulse data.';

  @override
  String get pulseNoDataDefault =>
      'No pulse samples were found for this period.';

  @override
  String get pulseSettingsEnableTitle => 'Enable pulse analysis';

  @override
  String get pulseSettingsEnableSubtitle =>
      'Reads heart-rate data for the pulse view only when you turn this on.';

  @override
  String get pulseSettingsPermissionTitle => 'Allow heart-rate access';

  @override
  String get pulseSettingsPermissionSubtitle =>
      'Opens Apple Health or Health Connect so Train Libre can read pulse samples.';

  @override
  String get pulseSettingsAnalysisSubtitle =>
      'Shows range, time-weighted average, and a conservative resting-pulse estimate. Not a medical diagnosis.';

  @override
  String get pulseSettingsPermissionGranted => 'Heart-rate access is ready.';

  @override
  String get pulseSettingsPermissionFailed =>
      'Heart-rate access was not granted.';

  @override
  String get pulseOptInChip => 'Opt-in';

  @override
  String get statisticsPulseDescription =>
      'Range, time-weighted average, and resting pulse for selected periods.';

  @override
  String get statisticsPulseOpenCaption => 'Opens pulse analysis';

  @override
  String get healthExportTitle => 'Health export';

  @override
  String get healthExportAppleHealthTitle => 'Apple Health export';

  @override
  String get healthExportHealthConnectTitle => 'Health Connect export';

  @override
  String get healthExportDomainNutritionHydration => 'Nutrition & hydration';

  @override
  String get healthExportDomainWorkouts => 'Workouts';

  @override
  String get healthExportStateIdle => 'Idle';

  @override
  String get healthExportStateExporting => 'Exporting';

  @override
  String get healthExportStateSuccess => 'Success';

  @override
  String get healthExportStateFailed => 'Failed';

  @override
  String get healthExportStateDisabled => 'Disabled';

  @override
  String get healthExportResultComplete => 'Export complete';

  @override
  String get healthExportResultFailed => 'Export failed';

  @override
  String get healthExportAppleHealthSubtitle =>
      'One-way export from Train Libre to Apple Health';

  @override
  String get healthExportHealthConnectSubtitle =>
      'One-way export from Train Libre to Health Connect';

  @override
  String get healthExportAppleHealthStatusTitle => 'Apple Health export status';

  @override
  String get healthExportHealthConnectStatusTitle =>
      'Health Connect export status';

  @override
  String get settingsBaseFoodLanguageTitle => 'Base food display language';

  @override
  String get settingsBaseFoodLanguageSubtitle =>
      'Choose which language to use for base food names.';

  @override
  String get settingsBaseFoodLanguageFollowApp => 'Follow app language';

  @override
  String get settingsBaseFoodLanguageEnglish => 'English';

  @override
  String get settingsBaseFoodLanguageGerman => 'German';

  @override
  String get settingsBaseFoodLanguageFrench => 'French';

  @override
  String get settingsBaseFoodLanguageItalian => 'Italian';

  @override
  String get settingsBaseFoodLanguageJapanese => 'Japanese';

  @override
  String get aiModelLabel => 'Model';

  @override
  String get aiModelListFallbackTitle => 'Showing the built-in model list';

  @override
  String get aiModelListRetry => 'Reload models';

  @override
  String get aiModelListErrorMissingKey =>
      'Save your API key to load the current models from the provider.';

  @override
  String get aiModelListErrorNetwork =>
      'The provider could not be reached. Check your internet connection.';

  @override
  String get aiModelListErrorTimeout =>
      'The provider did not answer within the configured timeout.';

  @override
  String aiModelListErrorAuth(Object status) {
    return 'The provider rejected your API key (HTTP $status). Check the key and its permissions.';
  }

  @override
  String aiModelListErrorRateLimit(Object status) {
    return 'The provider is rate limiting or out of quota (HTTP $status). Try again shortly.';
  }

  @override
  String aiModelListErrorHttp(Object status) {
    return 'The provider answered with HTTP $status.';
  }

  @override
  String get aiModelListErrorResponse =>
      'The provider\'s model list could not be read.';

  @override
  String get autoBackupStoragePickerUnavailable =>
      'Storage picker unavailable. Please fully restart/reinstall the app after updating.';

  @override
  String autoBackupFolderPickerFailed(Object error) {
    return 'Folder picker failed: $error';
  }

  @override
  String get healthExportPermissionDenied => 'Permission denied';

  @override
  String get healthExportAdapterUnavailable => 'Adapter unavailable';

  @override
  String get healthExportPlatformUnavailable => 'Platform unavailable';

  @override
  String get healthExportPlatformNotInstalled => 'Platform not installed';

  @override
  String get healthExportExportDisabled => 'Export disabled';

  @override
  String get onboardingMacrosStepTitle => 'Macronutrients';

  @override
  String get onboardingMacrosStepSubtitle => 'How is your nutrition composed?';

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
  String get statisticsProviderLocal => 'Local';

  @override
  String get unit_milliliters => 'ml';

  @override
  String get unit_kilograms => 'kg';

  @override
  String get mealEditorHintExample => 'e.g. Chicken bowl';

  @override
  String get mealEditorNoIngredientsYet => 'None yet – coming later';

  @override
  String get foodDetailSavedBaseDb => 'Saved (base DB)';

  @override
  String foodDetailExportError(Object error) {
    return 'Export error: $error';
  }

  @override
  String get stepsModulePrevious => 'Previous';

  @override
  String get stepsModuleNext => 'Next';

  @override
  String get stepsModuleTotalSteps => 'Total Steps';

  @override
  String get stepsModuleThisWeek => 'This Week';

  @override
  String get stepsModuleThisMonth => 'This Month';

  @override
  String stepsModuleUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get stepsModuleScopeSwitcherSemantics => 'Switch step scope';

  @override
  String get stepsModuleDay => 'Day';

  @override
  String get stepsModuleWeek => 'Week';

  @override
  String get stepsModuleMonth => 'Month';

  @override
  String get stepsModuleHourlyTimeline => 'Hourly Timeline';

  @override
  String get stepsModuleTotal => 'Total';

  @override
  String get stepsModuleActiveHours => 'Active Hours';

  @override
  String get stepsModulePeakHour => 'Peak Hour';

  @override
  String get stepsModuleAvgPerDay => 'Avg / Day';

  @override
  String get stepsModuleGoalHit => 'Goal Hit';

  @override
  String get stepsModuleGoalDays => 'Goal Days';

  @override
  String get diarySyncingSteps => 'Syncing steps...';

  @override
  String get diaryLoadingSleep => 'Loading sleep...';

  @override
  String get unit_milligrams => 'mg';

  @override
  String get scannerPermissionRequired =>
      'Camera access is required to scan barcodes.';

  @override
  String get scannerPermissionPermanentlyDenied =>
      'Camera access is permanently denied. Please enable it in settings to scan barcodes.';

  @override
  String get scannerOpenSettings => 'Open Settings';

  @override
  String get scannerGrantPermission => 'Continue';

  @override
  String get scannerAlignInstruction =>
      'Align barcode horizontally inside the red laser line';

  @override
  String get scannerToggleFlash => 'Toggle flashlight';

  @override
  String get about_train_libre => 'About Train Libre';

  @override
  String get legal_notice => 'Legal Notice';

  @override
  String get privacy_policy => 'Privacy Policy';

  @override
  String get terms_of_service => 'Terms of Service';

  @override
  String get view_in_browser => 'View in Browser';

  @override
  String get legal_document_version => 'Version';

  @override
  String get legal_document_last_updated => 'Last update';

  @override
  String get used_libraries => 'Used Libraries';

  @override
  String get licensing_info => 'Licensing Information';

  @override
  String get project_website => 'Project Website';

  @override
  String get github_repository => 'GitHub Repository';

  @override
  String get health_permission_dialog_title => 'Health Data & Privacy';

  @override
  String get health_permission_dialog_body =>
      'Train Libre needs to read your step data to show daily/weekly statistics. Your data stays locally on your device; there is no external server.';

  @override
  String get health_permission_continue => 'Continue';

  @override
  String get health_permission_not_now => 'Not now';

  @override
  String get welcome_privacy_title => 'Welcome & Privacy';

  @override
  String get welcome_privacy_body =>
      'To provide workout tracking and training insights, we process your fitness and activity data as described in our Privacy Policy.';

  @override
  String get i_agree_to_privacy_policy =>
      'I explicitly consent to the processing of my fitness and health data for workout tracking and training insights. I can withdraw my consent at any time in Settings.';

  @override
  String get i_agree_to_optional_telemetry =>
      '(Optional) I want to share pseudonymised usage statistics to help improve app stability and features (zero personal or health data).';

  @override
  String get welcome_back_updated_legal_title =>
      'Welcome Back & Updated Policies';

  @override
  String legal_update_body(String version) {
    return 'We have updated our Privacy Policy and Terms of Service (Version $version). To continue using Train Libre, please acknowledge the updated terms. All your existing data remains safely stored on your device.';
  }

  @override
  String i_agree_to_updated_privacy_policy(String version) {
    return 'I explicitly consent to the updated Privacy Policy (v$version) and the processing of my fitness and health data.';
  }

  @override
  String get accept_and_continue => 'Accept & Continue';

  @override
  String get by_tapping_accept_continue =>
      'By tapping \"Accept & Continue\", you agree to the updated';

  @override
  String get acceptTermsPrompt => 'I accept the Terms of Service';

  @override
  String get viewTermsInline => 'Terms of Service';

  @override
  String get accept_and_get_started => 'Accept & Get Started';

  @override
  String get by_tapping_accept =>
      'By tapping \"Accept & Get Started\", you agree to our';

  @override
  String get and_acknowledge => 'and acknowledge our';

  @override
  String get about_section => 'About';

  @override
  String get legal_section => 'Legal';

  @override
  String get aiSettingsInstructionTitle => 'How AI Meal Recognition Works';

  @override
  String get aiSettingsInstructionBody =>
      'This feature uses AI to analyze food images and provide nutrient estimates. Your images are only sent to the selected AI provider when you use the feature. It relies on a Bring-Your-Own-Key (BYOK) architecture, keeping your data locally on your device until analysis.';

  @override
  String get aiSettingsSetupGuideTitle => 'Setup Guide';

  @override
  String get aiSettingsSetupGuideBody =>
      'To use this feature, you need an API key from an AI provider. Google Gemini is used as a primary example because it currently offers a free tier for developers and users.';

  @override
  String get aiSettingsGetApiKeyButton => 'View Setup Guide';

  @override
  String get legal_document_version_value => '1.2';

  @override
  String get legal_document_last_updated_value => 'May 20, 2026';

  @override
  String get muscleChest => 'Chest';

  @override
  String get muscleBack => 'Back';

  @override
  String get muscleShoulders => 'Shoulders';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleQuads => 'Quadriceps';

  @override
  String get muscleHamstrings => 'Hamstrings';

  @override
  String get muscleLegs => 'Legs';

  @override
  String get muscleArms => 'Arms';

  @override
  String get muscleGlutes => 'Glutes';

  @override
  String get muscleCalves => 'Calves';

  @override
  String get muscleLowerBack => 'Lower Back';

  @override
  String get muscleAbs => 'Abs';

  @override
  String get muscleAdductors => 'Adductors';

  @override
  String get muscleForearms => 'Forearms';

  @override
  String get sleepDetailAnalysisHeader => 'Detailed Analysis';

  @override
  String get sleepMetricDurationLabel => 'Sleep Duration';

  @override
  String get sleepMetricContinuityLabel => 'Continuity (WASO/SE)';

  @override
  String get sleepMetricDepthLabel => 'Sleep Stage Depth';

  @override
  String get sleepMetricTimingLabel => 'Circadian Timing';

  @override
  String get sleepMetricRegularityLabel => 'Regularity';

  @override
  String get sleepBannerTstBottleneck =>
      'Sleep duration penalty active: Your total sleep volume was below the regenerative optimum of 6.5 hours, which restricts anabolic hormone release.';

  @override
  String get sleepBannerRemBottleneck =>
      'REM sleep deficiency penalty: Your REM sleep was below 60 minutes. This impairs neuronal recovery and mental freshness.';

  @override
  String get sleepBannerN3Bottleneck =>
      'Deep sleep deficiency penalty: Critical lack of N3 deep sleep (<70 min). Physical muscle tissue repair is suboptimal.';

  @override
  String get sleepBannerTimingBottleneck =>
      'Circadian phase shift penalty: Your mid-sleep was after 05:30 AM. Sleeping against the inner clock reduces sleep quality and insulin sensitivity.';

  @override
  String get sleepBannerDefaultPenalty =>
      'Clinical protective brake active: Your sleep volume was suboptimal (<6h) or circadian timing (sleep onset) was severely shifted. The total score has been limited.';

  @override
  String get infoTdeeTitle => 'Adaptive Calorie & TDEE Estimator';

  @override
  String get infoTdeeExplanation =>
      'Estimates your Total Daily Energy Expenditure (TDEE) based on your profile, logged meals, and bodyweight changes.';

  @override
  String get infoTdeeKeyPoints =>
      '• Smooths out daily weight fluctuations using a recursive trend model.\n• Uses a Bayesian-inspired approach to adapt weekly targets conservatively.\n• Alerts you if your logging consistency is too sparse for high-confidence updates.';

  @override
  String get infoTdeeTechnicalTitle =>
      'Bayesian Recursive Filtering & Metabolic Smoothing';

  @override
  String get infoTdeeTechnicalExplanation =>
      'Rather than relying on static formulas, Train Libre models your metabolism as a dynamic \'hidden state\' estimated recursively. Daily observed maintenance is computed by adjusting intake against body mass changes. A process noise coefficient is added on unlogged days to increase the estimation uncertainty, which dampens updates and prevents skewing from short-term water retention.';

  @override
  String get infoRecoveryTitle => 'Muscle Recovery Estimator';

  @override
  String get infoRecoveryExplanation =>
      'Estimates muscle-specific readiness and recovery curves based on training volume, intensity, and proximity to failure.';

  @override
  String get infoRecoveryKeyPoints =>
      '• Accounts for overlapping muscle stress (e.g., Bench Press counts for Chest, Triceps, and Shoulders).\n• Scales recovery speed based on RIR/RPE and extends the window for sets taken to failure.\n• Calibrates baseline recovery windows based on muscle group size and metabolic properties.';

  @override
  String get infoRecoveryTechnicalTitle =>
      'Equivalent Set Fatigue & Piecewise Decay Model';

  @override
  String get infoRecoveryTechnicalExplanation =>
      'Calculates dynamic readiness via non-linear decay curves. Volume tracking automatically distributes load between primary and secondary muscle groups. Recovery speed scales based on proximity to failure (RIR) and applies a strict timeline extension for sets taken to absolute failure.';

  @override
  String get infoScientificReferencesButton =>
      'View Scientific References & Sources';

  @override
  String get infoScientificDisclaimer =>
      'This feature uses established sports science and metabolic modeling literature as its foundation. The full list of peer-reviewed sources is available on our website.';

  @override
  String get infoAiMealTitle => 'AI Meal Capture Hub';

  @override
  String get infoAiMealExplanation =>
      'Converts meal photos or text descriptions into structured diary entries and matches them against your private product database.';

  @override
  String get infoAiMealKeyPoints =>
      '• Translates imprecise descriptions (e.g., \'a slice of bread\') into metric weight estimates.\n• Matches AI suggestions offline against the local product database on your device.\n• Computes nutrition locally instead of delegating calculations to external servers.';

  @override
  String get infoAiMealTechnicalTitle =>
      'Hybrid BYOK AI & Jaro-Winkler Matching';

  @override
  String get infoAiMealTechnicalExplanation =>
      'Uses a Bring-Your-Own-Key (BYOK) privacy model. The AI functions strictly as a suggestion layer. Matching is performed offline using a tokenized Jaro-Winkler filter against the local SQLite database. The AI provider is strictly prohibited from performing nutritional calculations via system prompts.';

  @override
  String get infoSleepTitle => 'Sleep Quality (SHS v3.5)';

  @override
  String get infoSleepExplanation =>
      'Calculates a comprehensive sleep index from quantity, continuity, depth, timing, and daily regularity.';

  @override
  String get infoSleepKeyPoints =>
      '• Aggregates five clinical dimensions using a weighted sum.\n• Automatically scales requirements if your wearable does not provide specific stages or efficiency data.\n• Protects you via soft-cap multipliers that limit the total score if a critical domain (like REM or Deep sleep) is compromised.';

  @override
  String get infoSleepTechnicalTitle =>
      'Weighted Baseline & Continuous Soft-Caps';

  @override
  String get infoSleepTechnicalExplanation =>
      'Aggregates five primary domains using a weighted linear sum: Duration (30%), Continuity (20%), Architecture (25%), Timing (15%), and Regularity (10%). To prevent misleading averages when a clinical domain is compromised, the final score is degraded if significant bottlenecks are detected in sleep stages or circadian timing.';

  @override
  String get tdeeRecalculationNotificationTitle => 'TDEE Recalculated';

  @override
  String tdeeRecalculationNotificationBody(
      int calories, int protein, int carbs, int fat) {
    return 'New daily targets: $calories kcal | ${protein}g Protein | ${carbs}g Carbs | ${fat}g Fat';
  }

  @override
  String recommendationBannerText(String delta) {
    return 'New targets available ($delta kcal).';
  }

  @override
  String get recommendationBannerApply => 'Apply';

  @override
  String get cancelingAndRollingBack => 'Canceling, rolling back safely...';

  @override
  String get sleepSyncTitle => 'Syncing Sleep History...';

  @override
  String get backupExportTitle => 'Exporting Backup...';

  @override
  String get backupImportTitle => 'Importing Backup...';

  @override
  String progressImportingNight(int index, int total) {
    return 'Importing Night $index/$total...';
  }

  @override
  String progressExportingTable(String table) {
    return 'Exporting $table...';
  }

  @override
  String progressImportingTable(String table) {
    return 'Restoring $table...';
  }

  @override
  String get shareDailyLogTitle => 'Daily Log';

  @override
  String get shareSleepStartTime => 'Start time';

  @override
  String get shareSleepEndTime => 'End time';

  @override
  String get shareSleepDeep => 'Deep Sleep';

  @override
  String get shareSleepLight => 'Light Sleep';

  @override
  String get shareSleepRem => 'REM Sleep';

  @override
  String get shareSleepAwake => 'Awake/Interruptions';

  @override
  String get shareTotalWater => 'Total Water/Fluids';

  @override
  String get shareNutritionSummary => 'Total Nutrition Summary';

  @override
  String get shareSleepEfficiency => 'Efficiency';

  @override
  String get shareSleepRestingHeartRate => 'Resting Heart Rate';

  @override
  String get shareAsTextOrCopy => 'Share / copy as text';

  @override
  String get editExercise => 'Edit Exercise';

  @override
  String exerciseCopyCreated(String exerciseName) {
    return 'Copy of \'$exerciseName\' created.';
  }

  @override
  String get copySystemExerciseTitle => 'Copy System Exercise';

  @override
  String get copySystemExerciseBody =>
      'This exercise is system-provided and cannot be directly edited. Would you like to create a custom copy to edit it?';

  @override
  String get createCopyAndEdit => 'Create Copy & Edit';

  @override
  String get profileEdit => 'Edit Profile';

  @override
  String get selectBirthday => 'Select date of birth';

  @override
  String get exerciseNoteTitle => 'Exercise Note';

  @override
  String get exerciseNoteHint => 'Enter notes or hints...';

  @override
  String get deleteNoteTooltip => 'Delete note';

  @override
  String get emptyStateAddFirstExerciseSubtitle =>
      'Add an exercise to start logging.';

  @override
  String get syncRoutineTitle => 'Update Routine?';

  @override
  String get syncRoutineSubtitle => 'Structure or order changes detected.';

  @override
  String syncRoutineBody(String routineName) {
    return 'Would you like to update the routine \'$routineName\' with the current workout data (exercises, order, sets)?';
  }

  @override
  String get discard => 'Discard';

  @override
  String get updateNow => 'Update Now';

  @override
  String get syncRoutineSuccess => 'Routine updated successfully!';

  @override
  String syncRoutineError(String error) {
    return 'Error updating routine: $error';
  }

  @override
  String createRoutineError(String error) {
    return 'Error creating routine: $error';
  }

  @override
  String nutritionPerQuantity(String quantity) {
    return 'Nutrition per ${quantity}g';
  }

  @override
  String get settingsLocalModelName => 'Local Model Name';

  @override
  String get settingsCustomBaseUrl => 'Custom Base URL';

  @override
  String get settingsCustomModelName => 'Custom Model Name';

  @override
  String get settingsAiFoodNameLanguage => 'AI Food Name Language';

  @override
  String get settingsRequestTimeout => 'Request Timeout';

  @override
  String settingsSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get semanticsApplyRecommendation => 'Apply Recommendation';

  @override
  String get semanticsDismissBanner => 'Dismiss Banner';

  @override
  String get importedWorkout => 'Imported Workout';

  @override
  String get unknownExercise => 'Unknown Exercise';

  @override
  String get devExportBaseDb => 'Export base database';

  @override
  String get initCheckingExercises => 'Checking exercises...';

  @override
  String get initLoadingRemoteManifest => 'Loading remote manifest...';

  @override
  String get initExercisesUpToDate => 'Exercises up to date';

  @override
  String get initNoDownloadRequired => 'No remote download required.';

  @override
  String get initLoadingExercises => 'Loading exercises...';

  @override
  String initDownloadingRemoteCatalog(String version) {
    return 'Downloading remote exercise catalog $version...';
  }

  @override
  String get initPreparingImport => 'Preparing download for import...';

  @override
  String get initExercisesReady => 'Exercises ready';

  @override
  String initImportingRemoteCatalog(String version) {
    return 'Importing remote exercise catalog $version...';
  }

  @override
  String initCheckingProductDatabase(String country) {
    return 'Checking product database ($country)...';
  }

  @override
  String get initProductDatabaseUpToDate => 'Product database up to date';

  @override
  String get initLoadingProductDatabase => 'Loading product database...';

  @override
  String initDownloadingProductBundle(String version) {
    return 'Downloading remote product bundle $version...';
  }

  @override
  String get initProductDatabaseReady => 'Product database ready';

  @override
  String initImportingProductBundle(String version) {
    return 'Importing remote product bundle $version...';
  }

  @override
  String get initNoOffBundle =>
      'No OFF bundle/remote available. Existing local OFF data remains unchanged.';

  @override
  String initEntriesProgress(String processed, String totalCount) {
    return '$processed / $totalCount entries';
  }

  @override
  String initUpdateTask(String task) {
    return 'Update $task';
  }

  @override
  String initCheckingTask(String task) {
    return 'Checking $task...';
  }

  @override
  String initTaskUpToDate(String task) {
    return '$task up to date';
  }

  @override
  String get initInitializing => 'Initializing...';

  @override
  String get initPreparation => 'Preparing...';

  @override
  String get initReady => 'Ready';

  @override
  String yearsOld(int age) {
    return '$age years old';
  }

  @override
  String get customFoodsTitle => 'Custom Foods';

  @override
  String get deleteFoodConfirmTitle => 'Delete Food Item';

  @override
  String get deleteFoodConfirmBody =>
      'Are you sure you want to delete this custom food item? Historical logs will not be affected.';

  @override
  String get foodItemDeleted => 'Food item deleted';

  @override
  String get copySystemFoodTitle => 'Copy System Food';

  @override
  String get copySystemFoodBody =>
      'System foods cannot be edited directly. Would you like to create a custom copy and edit it?';

  @override
  String foodCopyCreated(String name) {
    return 'Copy created: $name';
  }

  @override
  String get nutritionPer100g => 'Nutrition per 100g';

  @override
  String nutritionPerPortion(int grams) {
    return 'Nutrition per Portion (${grams}g)';
  }

  @override
  String get workoutConflictTitle => 'Workout in Progress';

  @override
  String get workoutConflictContent =>
      'You already have an active workout session. Would you like to resume it, or discard it to start a new one?';

  @override
  String get resumeWorkoutButton => 'Resume Workout';

  @override
  String get discardAndStartButton => 'Discard & Start New';

  @override
  String get profileTapToSetUp => 'Tap to set up';

  @override
  String get customLabel => 'Custom';

  @override
  String get noData => 'No data';

  @override
  String get languageAuto => 'Auto';

  @override
  String aiValidationCostEstimation(num tokenCount) {
    return 'Cost: ~$tokenCount tokens';
  }

  @override
  String showAllWithCount(num count) {
    return 'Show all ($count)';
  }

  @override
  String repsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Reps',
      one: '1 Rep',
    );
    return '$_temp0';
  }

  @override
  String get offDownloadTitle => 'Download Database Catalogs';

  @override
  String get offDownloadBody =>
      'To access full offline product search, barcode scanning, and AI features, please initialize the local catalogs. You will download the latest database releases from GitHub.';

  @override
  String get offDownloadConfirm => 'Download Now';

  @override
  String get offDownloadCancel => 'Not Now';

  @override
  String get offDownloadCTA => 'Download Database';

  @override
  String get offPlaceholderText =>
      'Nutrition features require the local database catalog.';

  @override
  String get backupImportLockedTitle => 'Database Catalog Required';

  @override
  String get backupImportLockedBody =>
      'Before importing a backup, both the exercise catalog and nutrition catalog must be fully downloaded and initialized to prevent data inconsistency. Please download the required databases first.';

  @override
  String get wgerPlaceholderText =>
      'Exercise catalog features require the local database catalog.';

  @override
  String get onboardingRegionTitle => 'Select Region';

  @override
  String get onboardingRegionExplanation =>
      'Select the country where you buy your groceries. This ensures we download the correct Open Food Facts database for your local products.';

  @override
  String get onboardingRegionSettingsHint =>
      'You can change this at any time later in Settings → Nutrition → Database Region.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String rollingDaysLabel(int days) {
    return 'Last $days days (rolling)';
  }

  @override
  String get muscleTraps => 'Traps';

  @override
  String get muscleObliques => 'Obliques';

  @override
  String get icloudSyncErrorTitle => 'iCloud Sync Failed';

  @override
  String get icloudSyncErrorHelp =>
      'Please ensure that iCloud Drive is enabled in your iOS System Settings under Settings -> [Your Name] -> iCloud -> iCloud Drive.';

  @override
  String get icloudSyncErrorCopyLog => 'Copy Technical Error Log';

  @override
  String get icloudSyncErrorClose => 'Close';

  @override
  String get icloudSyncErrorCopied => 'Error log copied to clipboard!';

  @override
  String icloudLastSynced(String date) {
    return 'Last synced: $date';
  }

  @override
  String get icloudNeverSynced => 'Never synced';

  @override
  String get emptyStateDiaryColdStartTitle => 'Welcome to your Diary!';

  @override
  String get emptyStateDiaryColdStartSubtitle =>
      'Keep track of your nutrition and hydration here.';

  @override
  String get emptyStateActiveGapOverlay => 'No data available for this period';

  @override
  String get emptyStateDiaryColdStartCallToAction =>
      'Log your first entry here';

  @override
  String get statisticsColdStartTitle => 'Welcome to your Analytics!';

  @override
  String get statisticsColdStartSubtitle =>
      'Your progress will be visualized here as soon as you log your first workouts, meals, or track your steps and sleep.';

  @override
  String get statisticsActiveGapTitle => 'No data available';

  @override
  String get reviewPromptTitle => 'Do you like Train Libre?';

  @override
  String get reviewPromptSubtitle =>
      'Your feedback helps us continuously improve the app without ads or trackers.';

  @override
  String get reviewPromptYes => 'Yes, I like it';

  @override
  String get reviewPromptNo => 'No, not really';

  @override
  String get reviewPromptLater => 'Remind me later';

  @override
  String get updateAvailableTitle => 'Update Available';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusRequired => 'Required';

  @override
  String get updatesAvailableBody =>
      'New updates are available for your local catalogs. Would you like to update now?';

  @override
  String get exerciseCatalogWger => 'Exercise Catalog (OpenExerciseDB)';

  @override
  String get nutritionCatalogOff => 'Nutrition Catalog (OFF)';

  @override
  String get workoutImportZeroNew =>
      '0 new workouts imported (all already existed).';

  @override
  String get telemetryDeleteDialogTitle => 'Delete Telemetry Data?';

  @override
  String get telemetryDeleteDialogBody =>
      'Do you really want to delete your past telemetry data?\n\nThe following will happen:\n• All device UUIDs, session IDs, and local counters stored on this device will be reset.\n• A deletion request (\$delete_person) will be sent to PostHog servers in the EU to remove your data there.\n• The telemetry SDK will be fully reset.';

  @override
  String get telemetryDeleteConfirmButton => 'Delete data now';

  @override
  String get telemetryConsentTitle => 'Help improve Train Libre?';

  @override
  String get telemetryConsentBody =>
      'Train Libre is built independently by a single developer, without accounts and without ads. If you like, you can share pseudonymised usage statistics. They help me understand which features are used and where the app can be improved.';

  @override
  String get telemetryConsentPointAnonymous =>
      'Pseudonymised: No name, no email, no workout, diary, weight, nutrition, or health data. Only screen views, feature usage, and error reports are transmitted.';

  @override
  String get telemetryConsentPointNotSold =>
      'Not for advertising: Data is never sold and never used for marketing or advertising. Processed on servers in the EU.';

  @override
  String get telemetryConsentPointRevocable =>
      'Voluntary: Can be disabled in Settings at any time. Stored telemetry data can also be deleted there.';

  @override
  String get telemetryConsentAccept => 'Yes, share usage data';

  @override
  String get telemetryConsentDecline => 'No, thanks';

  @override
  String get settingsTelemetryToggleTitle =>
      'Share pseudonymised usage statistics';

  @override
  String get settingsTelemetryToggleSubtitle =>
      'Helps improve the app. Pseudonymised, without personal or health data.';

  @override
  String get settingsTelemetryDeleteTitle => 'Delete telemetry data';

  @override
  String get settingsTelemetryDeleteSubtitle =>
      'Deletes all stored IDs locally and on the PostHog server';

  @override
  String liveActivitySetPosition(int index, int total) {
    return 'Set $index of $total';
  }

  @override
  String get liveActivityOverdueLabel => 'overdue by';

  @override
  String get liveActivityRirLabel => 'RIR';

  @override
  String get liveActivityRpeLabel => 'RPE';

  @override
  String get liveActivityAddExercise => 'Add exercise';

  @override
  String get liveActivityOpenApp => 'Open app';

  @override
  String get unit_pounds => 'lbs';

  @override
  String get unit_kilometers => 'km';

  @override
  String get unit_miles => 'mi';

  @override
  String get liveActivitySkipShort => 'Skip';

  @override
  String get whatsNewTitle => 'What\'s New';

  @override
  String get whatsNewSubtitle => 'Here\'s what changed since your last update.';

  @override
  String whatsNewVersionHeader(String version) {
    return 'Version $version';
  }

  @override
  String get whatsNewCta => 'Let\'s go';

  @override
  String get whatsNewAboutRow => 'What\'s New';

  @override
  String get whatsNewAboutRowSubtitle =>
      'Release highlights of this and earlier versions';

  @override
  String get mealAnalysisPreparing => 'Preparing the capture';

  @override
  String get mealAnalysisAnalyzing => 'Analyzing the meal';

  @override
  String get mealAnalysisMatching => 'Matching the ingredients';

  @override
  String get mealAnalysisFailed => 'That did not work';

  @override
  String get mealAnalysisProcessingTag => 'AI VISION PROCESSING';

  @override
  String get aiScannerTitle => 'AI scanner';

  @override
  String get aiCaptureAnalyzing => 'Analyzing…';

  @override
  String aiCaptureAnalyzeMeal(int count) {
    return 'Analyze meal ($count)';
  }

  @override
  String get aiCaptureAnalyzeText => 'Analyze text';

  @override
  String get aiCaptureDescribeHint =>
      'Describe the meal (e.g. 2 eggs with toast)…';

  @override
  String get aiCaptureBarcodeDetected => 'Barcode detected';

  @override
  String get aiCaptureLogBarcode => 'Log';

  @override
  String aiCaptureBarcodeFallback(String code) {
    return 'Barcode $code';
  }

  @override
  String get aiCaptureMoveCloser => 'Move a little closer';

  @override
  String get aiCaptureMoveAway => 'Move back a little';

  @override
  String get aiCaptureOpenSettings => 'Open settings';

  @override
  String get voiceDictationTitle => 'Dictate the meal';

  @override
  String get voiceHoldToTalk => 'Hold to speak';

  @override
  String get voiceSpeakNow => 'Speak now — release to finish';

  @override
  String get voiceExampleStandalone =>
      'e.g. “A vegetable kebab with flatbread and garlic sauce”';

  @override
  String get voiceExampleWithPhoto =>
      'Add what the photo cannot show — e.g. “fried in two tablespoons of olive oil”';

  @override
  String get voiceNetworkNotice =>
      'This device cannot recognize speech locally. The recording is sent to the system’s speech recognition to be transcribed.';

  @override
  String get voiceTapToRecord => 'Tap to start recording';

  @override
  String get voiceTapToFinish => 'Listening — tap to finish';

  @override
  String get voiceStarting => 'Getting ready…';

  @override
  String get voiceTidyingUp => 'Tidying up your words…';

  @override
  String get voiceNothingHeard =>
      'Nothing was recognized. Try again, or type it instead.';

  @override
  String get voiceLanguage => 'Language';

  @override
  String get voiceLanguageTitle => 'Dictation language';

  @override
  String get voiceLanguageSystem => 'Follow the device';

  @override
  String get voiceLanguageHint =>
      'Pick the language you speak, not the one the app is in.';

  @override
  String get voiceCleanedNotice => 'Filler words removed';

  @override
  String get voiceRetake => 'Record again';

  @override
  String voiceTidiedIn(String seconds) {
    return 'Tidied up by AI in $seconds s';
  }

  @override
  String get aiDepthImageTitle => 'Send the depth map too';

  @override
  String get aiDepthImageSubtitle =>
      'Attaches the false-colour relief of the meal as a second image, so the model can judge height as well as outline. Costs one extra image per analysis.';

  @override
  String get aiVoiceTidyTitle => 'Tidy up dictation with AI';

  @override
  String get aiVoiceTidySubtitle =>
      'After you finish speaking, the transcript is corrected and split into bullet points. Costs one request and a few seconds.';

  @override
  String get voicePermissionTitle => 'Microphone and speech recognition';

  @override
  String get voicePermissionBody =>
      'To dictate a meal, Train Libre needs the microphone while you hold the button, and speech recognition to turn what you said into text. Recognition runs on your device whenever it can. Nothing is recorded or kept.';

  @override
  String get voicePermissionContinue => 'Continue';

  @override
  String get voiceApplyText => 'Use this text';

  @override
  String get voiceTranscriptHint => 'Recognized text — editable here';

  @override
  String get voiceUnavailablePermission =>
      'Dictation needs microphone and speech recognition access. You can still type the text.';

  @override
  String get voiceUnavailableUnsupported =>
      'This device offers no speech recognition. You can type the text instead.';

  @override
  String get voiceUnavailableFailed =>
      'Speech recognition could not be started. You can type the text instead.';

  @override
  String get mealFallbackTitle => 'Meal';

  @override
  String mealIngredientCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredients',
      one: '1 ingredient',
    );
    return '$_temp0';
  }

  @override
  String get mealDetailOptions => 'Options';

  @override
  String get mealDetailAddIngredient => 'Add ingredient';

  @override
  String get mealDetailSaveAsTemplate => 'Save as template';

  @override
  String get mealDetailSavedAsTemplate => 'Saved as a meal template.';

  @override
  String get mealDetailChangeMealType => 'Change meal type';

  @override
  String get mealDetailSelectMealType => 'Select meal type';

  @override
  String get mealDetailAmountInGrams => 'Amount in grams';

  @override
  String get mealDetailApply => 'Apply';

  @override
  String get mealDeleteQuestion => 'What should happen to this meal?';

  @override
  String get mealDeleteUngroupTitle => 'Only remove the grouping';

  @override
  String mealDeleteUngroupBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The photo and the grouping are removed. The $count entries stay in the diary on their own — your daily totals do not change.',
      one:
          'The photo and the grouping are removed. The entry stays in the diary on its own — your daily totals do not change.',
    );
    return '$_temp0';
  }

  @override
  String get mealDeleteAllTitle => 'Delete the meal and its entries';

  @override
  String mealDeleteAllBody(int count, int kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The photo, the grouping and all $count entries disappear from the diary. $kcal kcal are removed from your day.',
      one:
          'The photo, the grouping and the entry disappear from the diary. $kcal kcal are removed from your day.',
    );
    return '$_temp0';
  }

  @override
  String get reanalysisTitle => 'New result';

  @override
  String get reanalysisSubtitle => 'You decide what stays saved.';

  @override
  String get reanalysisPrevious => 'CURRENT';

  @override
  String get reanalysisNew => 'NEW';

  @override
  String get reanalysisKeepPrevious => 'Keep current';

  @override
  String get reanalysisApplyNew => 'Use the new one';

  @override
  String get reanalysisDiffHint => 'Marked = differs from what is saved';

  @override
  String get aiReviewDiscardTitle => 'Discard this meal?';

  @override
  String get aiReviewDiscardBody =>
      'The analysis has not been saved and will be lost.';

  @override
  String get aiLidarScaleTitle => 'Send LiDAR scale';

  @override
  String get aiLidarScaleSubtitle =>
      'Measures distance and frame size in centimetres and passes them to the AI. Switch off to compare whether the estimate actually improves.';

  @override
  String get mealPhotoStorageSection => 'Meal photos (storage)';

  @override
  String get mealPhotoRetentionTitle => 'Retention period';

  @override
  String get mealPhotoRetentionBody =>
      'Photos are deleted automatically once the period is over. The nutrition entries in the diary remain.';

  @override
  String mealPhotoRetentionDays(int days) {
    return '$days days';
  }

  @override
  String get mealPhotoRetentionDefaultSuffix => '(default)';

  @override
  String get mealPhotoRetentionUnlimited => 'Unlimited';

  @override
  String get mealPhotoRetentionSaved => 'Retention period saved.';

  @override
  String get mealPhotoDeleteAll => 'Delete all local photos';

  @override
  String get mealPhotoDeleteAllTitle => 'Delete all meal photos?';

  @override
  String get mealPhotoDeleteAllBody =>
      'Only the image files are removed from the device. Your entries and calories in the diary stay exactly as they are.';

  @override
  String get mealPhotoDeleted => 'Photos deleted.';

  @override
  String get speechSectionTitle => 'Voice input & dictation';

  @override
  String get speechOnDeviceActive => 'On-device speech recognition active';

  @override
  String get speechOnDeviceBody =>
      'Spoken meals (“2 eggs with toast and coffee”) are turned into text directly on your device and stay private.';

  @override
  String get aiCaptureTourStepShutterTitle => 'Capture Meal Photos';

  @override
  String get aiCaptureTourStepShutterDesc =>
      'Take up to 4 photos of your meal from different angles with the shutter. On supported devices, LiDAR automatically captures depth data for even more accurate portion estimates.';

  @override
  String get aiCaptureTourStepBarcodeTitle => 'Automatic Barcode Detection';

  @override
  String get aiCaptureTourStepBarcodeDesc =>
      'Hold packaged foods in front of the camera – barcodes are automatically recognized in real time. Use this button to toggle the live scanner on or off anytime.';

  @override
  String get aiCaptureTourBarcodeDemoProduct => 'Organic Rolled Oats 500g';

  @override
  String get aiCaptureTourBarcodeDemoHint =>
      'Here\'s what it looks like when you scan a barcode!';

  @override
  String get aiCaptureTourStepGalleryTitle => 'Select from Library';

  @override
  String get aiCaptureTourStepGalleryDesc =>
      'Already took photos of your meal? Choose up to 4 images directly from your photo library.';

  @override
  String get aiCaptureTourStepVoiceTitle => 'Voice Dictation';

  @override
  String get aiCaptureTourStepVoiceDesc =>
      'Tap the microphone to dictate ingredients, brands, or amounts (e.g. \'200g chicken breast with rice\'). AI tidies and analyzes your speech automatically.';

  @override
  String get aiCaptureTourStepTextTitle => 'Text & Notes';

  @override
  String get aiCaptureTourStepTextDesc =>
      'Add written notes or describe your meal purely via text if you don\'t want to take a photo.';

  @override
  String get aiCaptureTourStepAnalyzeTitle => 'Smart AI Analysis';

  @override
  String get aiCaptureTourStepAnalyzeDesc =>
      'Once a photo, voice transcript, or text is ready, tap Analyze. The AI identifies food items, estimates portions, and matches everything against your nutrition targets.';

  @override
  String get aiCaptureTourReplayTooltip => 'Replay capture guide';

  @override
  String get workoutPhotoAdd => 'Add photo';

  @override
  String get workoutPhotoTake => 'Take photo';

  @override
  String get workoutPhotoFromLibrary => 'Choose from library';

  @override
  String get workoutPhotoRemove => 'Remove photo';

  @override
  String get workoutPhotoRemoveConfirm =>
      'Are you sure you want to remove this photo?';

  @override
  String get workoutPhotoLimitReached => 'Maximum of 4 photos reached';

  @override
  String workoutPhotoPagination(int current, int total) {
    return '$current of $total';
  }

  @override
  String get catalogFilterTitle => 'Filter';

  @override
  String get catalogFilterBodyRegion => 'Body region';

  @override
  String get catalogFilterEquipment => 'Equipment';

  @override
  String get catalogFilterUsage => 'Purpose';

  @override
  String get catalogFilterReset => 'Reset';

  @override
  String get catalogFilterCombineHint =>
      'Several picks in one section widen the results; picks across sections narrow them.';

  @override
  String get catalogFilterDifficulty => 'Difficulty';

  @override
  String get catalogFilterMechanic => 'Mechanic';

  @override
  String get catalogFilterLaterality => 'Sides';

  @override
  String get exerciseDifficultyBeginner => 'Beginner';

  @override
  String get exerciseDifficultyIntermediate => 'Intermediate';

  @override
  String get exerciseDifficultyAdvanced => 'Advanced';

  @override
  String get exerciseMechanicCompound => 'Compound';

  @override
  String get exerciseMechanicIsolation => 'Isolation';

  @override
  String get exerciseLateralityBilateral => 'Both sides';

  @override
  String get exerciseLateralityUnilateral => 'One side';

  @override
  String get exerciseLateralityAlternating => 'Alternating';

  @override
  String get exerciseUsageWarmup => 'Warm-up';

  @override
  String get exerciseUsageActivation => 'Activation';

  @override
  String get exerciseUsageMainLift => 'Main lift';

  @override
  String get exerciseUsageAccessory => 'Accessory';

  @override
  String get exerciseUsageConditioning => 'Conditioning';

  @override
  String get exerciseUsageFinisher => 'Finisher';

  @override
  String get exerciseUsageCooldown => 'Cool-down';

  @override
  String get exerciseUsagePrehab => 'Prehab';

  @override
  String get exerciseForcePush => 'Push';

  @override
  String get exerciseForcePull => 'Pull';

  @override
  String get exerciseForceStatic => 'Static';

  @override
  String get exercisePatternHorizontalPush => 'Horizontal push';

  @override
  String get exercisePatternHorizontalPull => 'Horizontal pull';

  @override
  String get exercisePatternVerticalPush => 'Vertical push';

  @override
  String get exercisePatternVerticalPull => 'Vertical pull';

  @override
  String get exercisePatternSquat => 'Squat';

  @override
  String get exercisePatternHinge => 'Hip hinge';

  @override
  String get exercisePatternLunge => 'Lunge';

  @override
  String get exercisePatternGait => 'Gait';

  @override
  String get exercisePatternCarry => 'Carry';

  @override
  String get exercisePatternRotation => 'Rotation';

  @override
  String get exercisePatternAntiRotation => 'Anti-rotation';

  @override
  String get exercisePatternAntiExtension => 'Anti-extension';

  @override
  String get exercisePatternAntiFlexion => 'Anti-flexion';

  @override
  String get exercisePatternAntiLateralFlexion => 'Anti-lateral flexion';

  @override
  String get exercisePatternSpinalFlexion => 'Spinal flexion';

  @override
  String get exercisePatternSpinalExtension => 'Spinal extension';

  @override
  String get exercisePatternElbowFlexion => 'Elbow flexion';

  @override
  String get exercisePatternElbowExtension => 'Elbow extension';

  @override
  String get exercisePatternShoulderFlexion => 'Shoulder flexion';

  @override
  String get exercisePatternShoulderAbduction => 'Shoulder abduction';

  @override
  String get exercisePatternScapularElevation => 'Scapular elevation';

  @override
  String get exercisePatternHipExtension => 'Hip extension';

  @override
  String get exercisePatternHipAbduction => 'Hip abduction';

  @override
  String get exercisePatternHipAdduction => 'Hip adduction';

  @override
  String get exercisePatternKneeFlexion => 'Knee flexion';

  @override
  String get exercisePatternKneeExtension => 'Knee extension';

  @override
  String get exercisePatternPlantarFlexion => 'Plantar flexion';

  @override
  String get exercisePatternDorsiflexion => 'Dorsiflexion';

  @override
  String get exercisePatternWristFlexion => 'Wrist flexion';

  @override
  String get exercisePatternWristExtension => 'Wrist extension';
}
