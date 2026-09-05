import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('it'),
    Locale('ja')
  ];

  /// No description provided for @selectDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDateTitle;

  /// No description provided for @selectTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTimeTitle;

  /// No description provided for @selectDateTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTimeTitle;

  /// No description provided for @mealDetailChangeDateTime.
  ///
  /// In en, this message translates to:
  /// **'Change date and time'**
  String get mealDetailChangeDateTime;

  /// No description provided for @mealMovedToDate.
  ///
  /// In en, this message translates to:
  /// **'Meal moved to {date}'**
  String mealMovedToDate(String date);

  /// No description provided for @removeTimer.
  ///
  /// In en, this message translates to:
  /// **'Remove Timer'**
  String get removeTimer;

  /// No description provided for @connectSuperset.
  ///
  /// In en, this message translates to:
  /// **'Connect as superset'**
  String get connectSuperset;

  /// No description provided for @disconnectSuperset.
  ///
  /// In en, this message translates to:
  /// **'Dissolve superset'**
  String get disconnectSuperset;

  /// No description provided for @connectSupersetShort.
  ///
  /// In en, this message translates to:
  /// **'Superset'**
  String get connectSupersetShort;

  /// No description provided for @disconnectSupersetShort.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get disconnectSupersetShort;

  /// No description provided for @noTimerLabel.
  ///
  /// In en, this message translates to:
  /// **'No Timer'**
  String get noTimerLabel;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Train Libre'**
  String get appTitle;

  /// No description provided for @bannerText.
  ///
  /// In en, this message translates to:
  /// **'Recommendation / Current Workout'**
  String get bannerText;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowLabel;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @workoutSection.
  ///
  /// In en, this message translates to:
  /// **'Workout section - not yet implemented'**
  String get workoutSection;

  /// No description provided for @addMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to add?'**
  String get addMenuTitle;

  /// No description provided for @addFoodOption.
  ///
  /// In en, this message translates to:
  /// **'add Food'**
  String get addFoodOption;

  /// No description provided for @addLiquidOption.
  ///
  /// In en, this message translates to:
  /// **'add Liquid'**
  String get addLiquidOption;

  /// No description provided for @searchHintText.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHintText;

  /// No description provided for @mealtypeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealtypeBreakfast;

  /// No description provided for @mealtypeLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealtypeLunch;

  /// No description provided for @mealtypeDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealtypeDinner;

  /// No description provided for @mealtypeSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealtypeSnack;

  /// No description provided for @waterHeader.
  ///
  /// In en, this message translates to:
  /// **'Water & Drinks'**
  String get waterHeader;

  /// No description provided for @openFoodFactsSource.
  ///
  /// In en, this message translates to:
  /// **'Data from Open Food Facts'**
  String get openFoodFactsSource;

  /// No description provided for @tabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get tabRecent;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// No description provided for @fabCreateOwnFood.
  ///
  /// In en, this message translates to:
  /// **'Custom Food'**
  String get fabCreateOwnFood;

  /// No description provided for @recentEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Your recently used food items\nwill appear here.'**
  String get recentEmptyState;

  /// No description provided for @favoritesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any favorites yet.\nMark a food with the heart icon to see it here.'**
  String get favoritesEmptyState;

  /// No description provided for @searchInitialHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter a search term.'**
  String get searchInitialHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get searchNoResults;

  /// No description provided for @createFoodScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Food'**
  String get createFoodScreenTitle;

  /// No description provided for @formFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name of the food'**
  String get formFieldName;

  /// No description provided for @formFieldBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get formFieldBrand;

  /// No description provided for @formSectionMainNutrients.
  ///
  /// In en, this message translates to:
  /// **'Main Nutrients (per 100g)'**
  String get formSectionMainNutrients;

  /// No description provided for @formFieldCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get formFieldCalories;

  /// No description provided for @formFieldProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get formFieldProtein;

  /// No description provided for @formFieldCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates (g)'**
  String get formFieldCarbs;

  /// No description provided for @formFieldFat.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get formFieldFat;

  /// No description provided for @formSectionOptionalNutrients.
  ///
  /// In en, this message translates to:
  /// **'Additional Nutrients (optional, per 100g)'**
  String get formSectionOptionalNutrients;

  /// No description provided for @formFieldSugar.
  ///
  /// In en, this message translates to:
  /// **'Of which sugars (g)'**
  String get formFieldSugar;

  /// No description provided for @formFieldFiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber (g)'**
  String get formFieldFiber;

  /// No description provided for @formFieldKj.
  ///
  /// In en, this message translates to:
  /// **'Kilojoules (kJ)'**
  String get formFieldKj;

  /// No description provided for @formFieldSalt.
  ///
  /// In en, this message translates to:
  /// **'Salt (g)'**
  String get formFieldSalt;

  /// No description provided for @formFieldSodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium (mg)'**
  String get formFieldSodium;

  /// No description provided for @formFieldCalcium.
  ///
  /// In en, this message translates to:
  /// **'Calcium (mg)'**
  String get formFieldCalcium;

  /// No description provided for @buttonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// No description provided for @validatorPleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name.'**
  String get validatorPleaseEnterName;

  /// No description provided for @validatorPleaseEnterNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number.'**
  String get validatorPleaseEnterNumber;

  /// No description provided for @snackbarSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'{foodName} was saved successfully.'**
  String snackbarSaveSuccess(String foodName);

  /// No description provided for @foodDetailSegmentPortion.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get foodDetailSegmentPortion;

  /// No description provided for @foodDetailSegment100g.
  ///
  /// In en, this message translates to:
  /// **'100g'**
  String get foodDetailSegment100g;

  /// No description provided for @sugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get sugar;

  /// No description provided for @fiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get fiber;

  /// No description provided for @salt.
  ///
  /// In en, this message translates to:
  /// **'Salt'**
  String get salt;

  /// No description provided for @caffeine.
  ///
  /// In en, this message translates to:
  /// **'Caffeine'**
  String get caffeine;

  /// No description provided for @explorerScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Food Explorer'**
  String get explorerScreenTitle;

  /// No description provided for @nutritionScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Analysis'**
  String get nutritionScreenTitle;

  /// No description provided for @entriesForDateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Entries for'**
  String get entriesForDateRangeLabel;

  /// No description provided for @noEntriesForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No entries for this period yet.'**
  String get noEntriesForPeriod;

  /// No description provided for @waterEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waterEntryTitle;

  /// No description provided for @profileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileScreenTitle;

  /// No description provided for @profileDailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals'**
  String get profileDailyGoals;

  /// No description provided for @profileDailyGoalsCL.
  ///
  /// In en, this message translates to:
  /// **'DAILY GOALS'**
  String get profileDailyGoalsCL;

  /// No description provided for @snackbarGoalsSaved.
  ///
  /// In en, this message translates to:
  /// **'Goals saved successfully!'**
  String get snackbarGoalsSaved;

  /// No description provided for @measurementsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurementsScreenTitle;

  /// No description provided for @measurementsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No measurements recorded yet.\nStart with the \'+\' button.'**
  String get measurementsEmptyState;

  /// No description provided for @addMeasurementDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Measurement'**
  String get addMeasurementDialogTitle;

  /// No description provided for @formFieldMeasurementType.
  ///
  /// In en, this message translates to:
  /// **'Type of Measurement'**
  String get formFieldMeasurementType;

  /// No description provided for @formFieldMeasurementValue.
  ///
  /// In en, this message translates to:
  /// **'Value ({unit})'**
  String formFieldMeasurementValue(Object unit);

  /// No description provided for @validatorPleaseEnterValue.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get validatorPleaseEnterValue;

  /// No description provided for @measurementWeight.
  ///
  /// In en, this message translates to:
  /// **'Body Weight'**
  String get measurementWeight;

  /// No description provided for @measurementFatPercent.
  ///
  /// In en, this message translates to:
  /// **'Body Fat'**
  String get measurementFatPercent;

  /// No description provided for @measurementNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get measurementNeck;

  /// No description provided for @measurementShoulder.
  ///
  /// In en, this message translates to:
  /// **'Shoulder'**
  String get measurementShoulder;

  /// No description provided for @measurementChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get measurementChest;

  /// No description provided for @measurementLeftBicep.
  ///
  /// In en, this message translates to:
  /// **'Left Bicep'**
  String get measurementLeftBicep;

  /// No description provided for @measurementRightBicep.
  ///
  /// In en, this message translates to:
  /// **'Right Bicep'**
  String get measurementRightBicep;

  /// No description provided for @measurementLeftForearm.
  ///
  /// In en, this message translates to:
  /// **'Left Forearm'**
  String get measurementLeftForearm;

  /// No description provided for @measurementRightForearm.
  ///
  /// In en, this message translates to:
  /// **'Right Forearm'**
  String get measurementRightForearm;

  /// No description provided for @measurementAbdomen.
  ///
  /// In en, this message translates to:
  /// **'Abdomen'**
  String get measurementAbdomen;

  /// No description provided for @measurementWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get measurementWaist;

  /// No description provided for @measurementHips.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get measurementHips;

  /// No description provided for @measurementLeftThigh.
  ///
  /// In en, this message translates to:
  /// **'Left Thigh'**
  String get measurementLeftThigh;

  /// No description provided for @measurementRightThigh.
  ///
  /// In en, this message translates to:
  /// **'Right Thigh'**
  String get measurementRightThigh;

  /// No description provided for @measurementLeftCalf.
  ///
  /// In en, this message translates to:
  /// **'Left Calf'**
  String get measurementLeftCalf;

  /// No description provided for @measurementRightCalf.
  ///
  /// In en, this message translates to:
  /// **'Right Calf'**
  String get measurementRightCalf;

  /// No description provided for @drawerMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Train Libre Menu'**
  String get drawerMenuTitle;

  /// No description provided for @drawerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get drawerDashboard;

  /// No description provided for @drawerFoodExplorer.
  ///
  /// In en, this message translates to:
  /// **'Food Explorer'**
  String get drawerFoodExplorer;

  /// No description provided for @drawerDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get drawerDataManagement;

  /// No description provided for @drawerMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get drawerMeasurements;

  /// No description provided for @dataManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get dataManagementTitle;

  /// No description provided for @exportCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportCardTitle;

  /// No description provided for @exportCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Saves all your journal entries, favorites, and custom foods into a single backup file.'**
  String get exportCardDescription;

  /// No description provided for @exportCardButton.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get exportCardButton;

  /// No description provided for @importCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importCardTitle;

  /// No description provided for @importCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Restores your data from a previously created backup file. WARNING: All data currently stored in the app will be overwritten!'**
  String get importCardDescription;

  /// No description provided for @importCardButton.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get importCardButton;

  /// No description provided for @recommendationDefault.
  ///
  /// In en, this message translates to:
  /// **'Track your first meal!'**
  String get recommendationDefault;

  /// No description provided for @recommendationOverTarget.
  ///
  /// In en, this message translates to:
  /// **'Last {count} days: +{difference} kcal over target'**
  String recommendationOverTarget(Object count, Object difference);

  /// No description provided for @recommendationUnderTarget.
  ///
  /// In en, this message translates to:
  /// **'Last {count} days: {difference} kcal under target'**
  String recommendationUnderTarget(Object count, Object difference);

  /// No description provided for @recommendationOnTarget.
  ///
  /// In en, this message translates to:
  /// **'Last {count} days: Target achieved ✅'**
  String recommendationOnTarget(Object count);

  /// No description provided for @recommendationFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Great, your first entry is logged!'**
  String get recommendationFirstEntry;

  /// No description provided for @dialogConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation Required'**
  String get dialogConfirmTitle;

  /// No description provided for @dialogConfirmImportContent.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to restore data from this backup?\n\nWARNING: All your current entries, favorites, and custom foods will be permanently deleted and replaced.'**
  String get dialogConfirmImportContent;

  /// No description provided for @dialogButtonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogButtonCancel;

  /// No description provided for @dialogButtonOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Yes, overwrite all'**
  String get dialogButtonOverwrite;

  /// No description provided for @snackbarNoFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected.'**
  String get snackbarNoFileSelected;

  /// No description provided for @snackbarImportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Import successful!'**
  String get snackbarImportSuccessTitle;

  /// No description provided for @snackbarImportSuccessContent.
  ///
  /// In en, this message translates to:
  /// **'Your data has been restored. It is recommended to restart the app for a correct display.'**
  String get snackbarImportSuccessContent;

  /// No description provided for @snackbarButtonOK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get snackbarButtonOK;

  /// No description provided for @snackbarImportError.
  ///
  /// In en, this message translates to:
  /// **'Error while importing data.'**
  String get snackbarImportError;

  /// No description provided for @snackbarExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup file has been passed to the system. Please choose a location to save.'**
  String get snackbarExportSuccess;

  /// No description provided for @snackbarExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export canceled or failed.'**
  String get snackbarExportFailed;

  /// No description provided for @profileUserHeight.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get profileUserHeight;

  /// No description provided for @workoutRoutinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get workoutRoutinesTitle;

  /// No description provided for @workoutHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout History'**
  String get workoutHistoryTitle;

  /// No description provided for @workoutHistoryButton.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get workoutHistoryButton;

  /// No description provided for @emptyRoutinesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Routines Found'**
  String get emptyRoutinesTitle;

  /// No description provided for @emptyRoutinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first routine or start a blank workout.'**
  String get emptyRoutinesSubtitle;

  /// No description provided for @createFirstRoutineButton.
  ///
  /// In en, this message translates to:
  /// **'Create First Routine'**
  String get createFirstRoutineButton;

  /// No description provided for @startEmptyWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Free Workout'**
  String get startEmptyWorkoutButton;

  /// No description provided for @editRoutineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit, or start the workout.'**
  String get editRoutineSubtitle;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @addRoutineButton.
  ///
  /// In en, this message translates to:
  /// **'New Routine'**
  String get addRoutineButton;

  /// No description provided for @freeWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Workout'**
  String get freeWorkoutTitle;

  /// No description provided for @finishWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishWorkoutButton;

  /// No description provided for @addSetButton.
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get addSetButton;

  /// No description provided for @addExerciseToWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise to Workout'**
  String get addExerciseToWorkoutButton;

  /// No description provided for @lastTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Time'**
  String get lastTimeLabel;

  /// No description provided for @setLabel.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setLabel;

  /// No description provided for @kgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight ({unit})'**
  String kgLabel(String unit);

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsLabel;

  /// No description provided for @cardioDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance ({unit})'**
  String cardioDistanceLabel(String unit);

  /// No description provided for @cardioTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get cardioTimeLabel;

  /// No description provided for @cardioIntensityLabel.
  ///
  /// In en, this message translates to:
  /// **'Intens.'**
  String get cardioIntensityLabel;

  /// No description provided for @cardioIntensityShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Int.'**
  String get cardioIntensityShortLabel;

  /// No description provided for @restTimerLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restTimerLabel;

  /// No description provided for @skipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// No description provided for @appInitStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting app...'**
  String get appInitStarting;

  /// No description provided for @appInitInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get appInitInitializing;

  /// No description provided for @appInitFinalizing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing'**
  String get appInitFinalizing;

  /// No description provided for @appInitCheckingBackups.
  ///
  /// In en, this message translates to:
  /// **'Checking backups...'**
  String get appInitCheckingBackups;

  /// No description provided for @appInitSkipDownload.
  ///
  /// In en, this message translates to:
  /// **'Skip download'**
  String get appInitSkipDownload;

  /// No description provided for @appInitSkippingRemoteDownload.
  ///
  /// In en, this message translates to:
  /// **'Skipping remote download...'**
  String get appInitSkippingRemoteDownload;

  /// No description provided for @emptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No completed workouts yet.'**
  String get emptyHistory;

  /// No description provided for @workoutDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Details'**
  String get workoutDetailsTitle;

  /// No description provided for @workoutHeartRateSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get workoutHeartRateSectionTitle;

  /// No description provided for @workoutHeartRateAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get workoutHeartRateAverageLabel;

  /// No description provided for @workoutHeartRateMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get workoutHeartRateMaxLabel;

  /// No description provided for @workoutHeartRateMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get workoutHeartRateMinLabel;

  /// No description provided for @workoutHeartRateQualityReady.
  ///
  /// In en, this message translates to:
  /// **'Good coverage'**
  String get workoutHeartRateQualityReady;

  /// No description provided for @workoutHeartRateQualityLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited data'**
  String get workoutHeartRateQualityLimited;

  /// No description provided for @workoutHeartRateQualityInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Very sparse'**
  String get workoutHeartRateQualityInsufficient;

  /// No description provided for @workoutHeartRateQualityNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get workoutHeartRateQualityNoData;

  /// No description provided for @workoutHeartRateNoDataGeneral.
  ///
  /// In en, this message translates to:
  /// **'No heart-rate samples were found for this workout window.'**
  String get workoutHeartRateNoDataGeneral;

  /// No description provided for @workoutHeartRateNoDataPermission.
  ///
  /// In en, this message translates to:
  /// **'Heart-rate permission is required to show workout HR.'**
  String get workoutHeartRateNoDataPermission;

  /// No description provided for @workoutHeartRateNoDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Heart-rate data is currently unavailable on this device.'**
  String get workoutHeartRateNoDataUnavailable;

  /// No description provided for @workoutHeartRateNoDataWorkoutNotFinished.
  ///
  /// In en, this message translates to:
  /// **'Heart-rate summary appears after a finished workout.'**
  String get workoutHeartRateNoDataWorkoutNotFinished;

  /// No description provided for @workoutHeartRateNoDataInvalidWindow.
  ///
  /// In en, this message translates to:
  /// **'Workout time window is invalid, so HR cannot be analyzed.'**
  String get workoutHeartRateNoDataInvalidWindow;

  /// No description provided for @workoutHeartRateNoDataQueryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read heart-rate data for this workout.'**
  String get workoutHeartRateNoDataQueryFailed;

  /// No description provided for @workoutHeartRateLimitedChartHint.
  ///
  /// In en, this message translates to:
  /// **'Not enough consistent samples for a reliable chart.'**
  String get workoutHeartRateLimitedChartHint;

  /// No description provided for @workoutHeartRateSampleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No samples} one{1 sample} other{{count} samples}}'**
  String workoutHeartRateSampleCount(int count);

  /// No description provided for @workoutNotFound.
  ///
  /// In en, this message translates to:
  /// **'Workout not found.'**
  String get workoutNotFound;

  /// No description provided for @totalVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Volume'**
  String get totalVolumeLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @workoutImportTitle.
  ///
  /// In en, this message translates to:
  /// **'External Workout Import'**
  String get workoutImportTitle;

  /// No description provided for @workoutImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Import your training history from a CSV or Excel export file.'**
  String get workoutImportDescription;

  /// No description provided for @workoutImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import Workout Data'**
  String get workoutImportButton;

  /// No description provided for @workoutImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} workouts!'**
  String workoutImportSuccess(Object count);

  /// No description provided for @workoutImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed. Please check the file.'**
  String get workoutImportFailed;

  /// No description provided for @importUnitSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Unit'**
  String get importUnitSelectionTitle;

  /// No description provided for @importUnitSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'In which unit is the data in the file provided?'**
  String get importUnitSelectionDescription;

  /// No description provided for @unitMetricLabel.
  ///
  /// In en, this message translates to:
  /// **'Metric (kg)'**
  String get unitMetricLabel;

  /// No description provided for @unitImperialLabel.
  ///
  /// In en, this message translates to:
  /// **'Imperial (lbs)'**
  String get unitImperialLabel;

  /// No description provided for @excelExportButton.
  ///
  /// In en, this message translates to:
  /// **'Excel Export (.xlsx)'**
  String get excelExportButton;

  /// No description provided for @exportWorkoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Workout History'**
  String get exportWorkoutHistory;

  /// No description provided for @exportNutritionDiary.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Diary'**
  String get exportNutritionDiary;

  /// No description provided for @exportMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get exportMeasurements;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get startWorkout;

  /// No description provided for @addMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Add Measurement'**
  String get addMeasurement;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filter7Days.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get filter7Days;

  /// No description provided for @filter30Days.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get filter30Days;

  /// No description provided for @filter30DaysShort.
  ///
  /// In en, this message translates to:
  /// **'30D'**
  String get filter30DaysShort;

  /// No description provided for @filter90DaysShort.
  ///
  /// In en, this message translates to:
  /// **'90D'**
  String get filter90DaysShort;

  /// No description provided for @filter180DaysShort.
  ///
  /// In en, this message translates to:
  /// **'180D'**
  String get filter180DaysShort;

  /// No description provided for @filter7DaysShort.
  ///
  /// In en, this message translates to:
  /// **'7D'**
  String get filter7DaysShort;

  /// No description provided for @filter1MonthShort.
  ///
  /// In en, this message translates to:
  /// **'1M'**
  String get filter1MonthShort;

  /// No description provided for @filter3MonthsShort.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get filter3MonthsShort;

  /// No description provided for @filter6MonthsShort.
  ///
  /// In en, this message translates to:
  /// **'6M'**
  String get filter6MonthsShort;

  /// No description provided for @filter1YearShort.
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get filter1YearShort;

  /// No description provided for @filterMax.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get filterMax;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @showMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Show more details'**
  String get showMoreDetails;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this entry?'**
  String get deleteConfirmContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesContent.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to save them before leaving?'**
  String get unsavedChangesContent;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareWorkout.
  ///
  /// In en, this message translates to:
  /// **'Share workout'**
  String get shareWorkout;

  /// No description provided for @shareRoutine.
  ///
  /// In en, this message translates to:
  /// **'Share routine'**
  String get shareRoutine;

  /// No description provided for @shareAsImage.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get shareAsImage;

  /// No description provided for @shareAsText.
  ///
  /// In en, this message translates to:
  /// **'Share as text'**
  String get shareAsText;

  /// No description provided for @sharedFromTrainLibre.
  ///
  /// In en, this message translates to:
  /// **'Shared from Train Libre'**
  String get sharedFromTrainLibre;

  /// No description provided for @sharedWithTrainLibre.
  ///
  /// In en, this message translates to:
  /// **'Shared with Train Libre'**
  String get sharedWithTrainLibre;

  /// No description provided for @shareImageSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get shareImageSummary;

  /// No description provided for @shareImageExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get shareImageExercises;

  /// No description provided for @shareImageMuscleFocus.
  ///
  /// In en, this message translates to:
  /// **'Muscle focus'**
  String get shareImageMuscleFocus;

  /// No description provided for @shareImageMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get shareImageMinimal;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @moreExercises.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more exercises'**
  String moreExercises(int count);

  /// No description provided for @shareSetNumber.
  ///
  /// In en, this message translates to:
  /// **'Set {number}'**
  String shareSetNumber(int number);

  /// No description provided for @repsShort.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get repsShort;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Sharing failed'**
  String get shareFailed;

  /// No description provided for @workoutShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutShareTitle;

  /// No description provided for @routineShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get routineShareTitle;

  /// No description provided for @setTypeWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get setTypeWarmup;

  /// No description provided for @setTypeWork.
  ///
  /// In en, this message translates to:
  /// **'Work sets'**
  String get setTypeWork;

  /// No description provided for @setTypeFailure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get setTypeFailure;

  /// No description provided for @setTypeDropset.
  ///
  /// In en, this message translates to:
  /// **'Dropset'**
  String get setTypeDropset;

  /// No description provided for @setTypeSuperset.
  ///
  /// In en, this message translates to:
  /// **'Superset'**
  String get setTypeSuperset;

  /// No description provided for @setTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get setTypeOther;

  /// No description provided for @setTypeWarmupSuffix.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get setTypeWarmupSuffix;

  /// No description provided for @setTypeFailureSuffix.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get setTypeFailureSuffix;

  /// No description provided for @setTypeDropsetSuffix.
  ///
  /// In en, this message translates to:
  /// **'Dropset'**
  String get setTypeDropsetSuffix;

  /// No description provided for @setTypeSupersetSuffix.
  ///
  /// In en, this message translates to:
  /// **'Superset'**
  String get setTypeSupersetSuffix;

  /// No description provided for @setTypeOtherSuffix.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get setTypeOtherSuffix;

  /// No description provided for @warmupSetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 warm-up set} other{{count} warm-up sets}}'**
  String warmupSetCount(num count);

  /// No description provided for @workSetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 work set} other{{count} work sets}}'**
  String workSetCount(num count);

  /// No description provided for @failureSetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 failure set} other{{count} failure sets}}'**
  String failureSetCount(num count);

  /// No description provided for @dropsetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 dropset} other{{count} dropsets}}'**
  String dropsetCount(num count);

  /// No description provided for @supersetSetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 superset} other{{count} supersets}}'**
  String supersetSetCount(num count);

  /// No description provided for @otherSetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 other set} other{{count} other sets}}'**
  String otherSetCount(num count);

  /// No description provided for @warmupCompactCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 warm-up} other{{count} warm-up}}'**
  String warmupCompactCount(num count);

  /// No description provided for @workCompactCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 work} other{{count} work}}'**
  String workCompactCount(num count);

  /// No description provided for @failureCompactCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 failure} other{{count} failure}}'**
  String failureCompactCount(num count);

  /// No description provided for @dropsetCompactCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 dropset} other{{count} dropsets}}'**
  String dropsetCompactCount(num count);

  /// No description provided for @supersetCompactCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 superset} other{{count} supersets}}'**
  String supersetCompactCount(num count);

  /// No description provided for @otherCompactCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 other} other{{count} other}}'**
  String otherCompactCount(num count);

  /// No description provided for @shareExercisesLabel.
  ///
  /// In en, this message translates to:
  /// **'exercises'**
  String get shareExercisesLabel;

  /// No description provided for @shareSetsLabel.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get shareSetsLabel;

  /// No description provided for @shareSetLabel.
  ///
  /// In en, this message translates to:
  /// **'set'**
  String get shareSetLabel;

  /// No description provided for @tabBaseFoods.
  ///
  /// In en, this message translates to:
  /// **'Base Foods'**
  String get tabBaseFoods;

  /// No description provided for @baseFoodsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'This section will soon be filled with a curated list of base foods like fruits, vegetables, and more.'**
  String get baseFoodsEmptyState;

  /// No description provided for @noBrand.
  ///
  /// In en, this message translates to:
  /// **'No Brand'**
  String get noBrand;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @backupFileSubject.
  ///
  /// In en, this message translates to:
  /// **'Train Libre App Backup - {timestamp}'**
  String backupFileSubject(String timestamp);

  /// No description provided for @foodItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{brand} - {calories} kcal / 100g'**
  String foodItemSubtitle(String brand, int calories);

  /// No description provided for @foodListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{grams}g - {time}'**
  String foodListSubtitle(int grams, String time);

  /// No description provided for @foodListTrailingKcal.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String foodListTrailingKcal(int calories);

  /// No description provided for @waterListTrailingMl.
  ///
  /// In en, this message translates to:
  /// **'{milliliters} ml'**
  String waterListTrailingMl(int milliliters);

  /// No description provided for @exerciseCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise Catalog'**
  String get exerciseCatalogTitle;

  /// No description provided for @filterByMuscle.
  ///
  /// In en, this message translates to:
  /// **'Filter by muscle group'**
  String get filterByMuscle;

  /// No description provided for @noExercisesFound.
  ///
  /// In en, this message translates to:
  /// **'No exercises found.'**
  String get noExercisesFound;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterByCategory;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @repsLabelShort.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get repsLabelShort;

  /// No description provided for @titleNewRoutine.
  ///
  /// In en, this message translates to:
  /// **'New Routine'**
  String get titleNewRoutine;

  /// No description provided for @titleEditRoutine.
  ///
  /// In en, this message translates to:
  /// **'Edit Routine'**
  String get titleEditRoutine;

  /// No description provided for @editRoutine.
  ///
  /// In en, this message translates to:
  /// **'Edit Routine'**
  String get editRoutine;

  /// No description provided for @validatorPleaseEnterRoutineName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the routine.'**
  String get validatorPleaseEnterRoutineName;

  /// No description provided for @snackbarRoutineCreated.
  ///
  /// In en, this message translates to:
  /// **'Routine created. Now add some exercises.'**
  String get snackbarRoutineCreated;

  /// No description provided for @snackbarRoutineSaved.
  ///
  /// In en, this message translates to:
  /// **'Routine saved.'**
  String get snackbarRoutineSaved;

  /// No description provided for @saveAsRoutineButton.
  ///
  /// In en, this message translates to:
  /// **'Save as routine'**
  String get saveAsRoutineButton;

  /// No description provided for @saveAsRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Save as Routine'**
  String get saveAsRoutineTitle;

  /// No description provided for @saveAsRoutinePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the new routine:'**
  String get saveAsRoutinePrompt;

  /// No description provided for @saveAsRoutineSuccess.
  ///
  /// In en, this message translates to:
  /// **'Routine created!'**
  String get saveAsRoutineSuccess;

  /// No description provided for @snackbarRoutineSavedAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get snackbarRoutineSavedAction;

  /// No description provided for @formFieldRoutineName.
  ///
  /// In en, this message translates to:
  /// **'Name of the routine'**
  String get formFieldRoutineName;

  /// No description provided for @emptyStateAddFirstExercise.
  ///
  /// In en, this message translates to:
  /// **'Add your first exercise.'**
  String get emptyStateAddFirstExercise;

  /// No description provided for @setCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 set}other{{count} sets}}'**
  String setCount(int count);

  /// No description provided for @fabAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get fabAddExercise;

  /// No description provided for @drawerExerciseCatalog.
  ///
  /// In en, this message translates to:
  /// **'Exercise Catalog'**
  String get drawerExerciseCatalog;

  /// No description provided for @lastWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Last Workout'**
  String get lastWorkoutTitle;

  /// No description provided for @repeatButton.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatButton;

  /// No description provided for @weightHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight History'**
  String get weightHistoryTitle;

  /// No description provided for @hideSummary.
  ///
  /// In en, this message translates to:
  /// **'Hide Summary'**
  String get hideSummary;

  /// No description provided for @showSummary.
  ///
  /// In en, this message translates to:
  /// **'Show Summary'**
  String get showSummary;

  /// No description provided for @exerciseDataAttribution.
  ///
  /// In en, this message translates to:
  /// **'Exercise data from OpenExerciseDB'**
  String get exerciseDataAttribution;

  /// No description provided for @exerciseDataLicense.
  ///
  /// In en, this message translates to:
  /// **'Exercise data licence'**
  String get exerciseDataLicense;

  /// No description provided for @exerciseDataUpstream.
  ///
  /// In en, this message translates to:
  /// **'Derived in part from wger'**
  String get exerciseDataUpstream;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @deleteRoutineConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete the routine \'{routineName}\'?'**
  String deleteRoutineConfirmContent(String routineName);

  /// No description provided for @editPauseTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Pause Duration'**
  String get editPauseTimeTitle;

  /// No description provided for @pauseInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Pause in seconds'**
  String get pauseInSeconds;

  /// No description provided for @editPauseTime.
  ///
  /// In en, this message translates to:
  /// **'Edit Pause'**
  String get editPauseTime;

  /// No description provided for @pauseDuration.
  ///
  /// In en, this message translates to:
  /// **'{seconds} second pause'**
  String pauseDuration(int seconds);

  /// No description provided for @maxPauseDuration.
  ///
  /// In en, this message translates to:
  /// **'Pauses up to {seconds}s'**
  String maxPauseDuration(int seconds);

  /// No description provided for @deleteWorkoutConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this workout log?'**
  String get deleteWorkoutConfirmContent;

  /// No description provided for @removeExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove Exercise'**
  String get removeExercise;

  /// No description provided for @deleteExerciseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Exercise?'**
  String get deleteExerciseConfirmTitle;

  /// No description provided for @deleteExerciseConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \'{exerciseName}\' from this routine?'**
  String deleteExerciseConfirmContent(String exerciseName);

  /// No description provided for @doneButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButtonLabel;

  /// No description provided for @setRestTimeButton.
  ///
  /// In en, this message translates to:
  /// **'Set rest time'**
  String get setRestTimeButton;

  /// No description provided for @deleteExerciseButton.
  ///
  /// In en, this message translates to:
  /// **'Delete exercise'**
  String get deleteExerciseButton;

  /// No description provided for @deleteCustomExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Custom Exercise'**
  String get deleteCustomExerciseTitle;

  /// No description provided for @deleteCustomExerciseBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete \"{name}\". This cannot be undone.'**
  String deleteCustomExerciseBody(String name);

  /// No description provided for @deleteCustomExerciseWithLogsWarning.
  ///
  /// In en, this message translates to:
  /// **'This exercise appears in your workout history. Your log entries will be kept, but the exercise link will be removed.'**
  String get deleteCustomExerciseWithLogsWarning;

  /// No description provided for @deleteCustomExerciseWithRoutinesWarning.
  ///
  /// In en, this message translates to:
  /// **'This exercise is used in one or more routines. It will be removed from those routines.'**
  String get deleteCustomExerciseWithRoutinesWarning;

  /// No description provided for @deleteCustomExerciseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exercise deleted.'**
  String get deleteCustomExerciseSuccess;

  /// No description provided for @restOverLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause is over'**
  String get restOverLabel;

  /// No description provided for @workoutRunningLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout is active …'**
  String get workoutRunningLabel;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @discardButton.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardButton;

  /// No description provided for @workoutStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Training (7 days)'**
  String get workoutStatsTitle;

  /// No description provided for @workoutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutsLabel;

  /// Label for workout duration summary
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeLabel;

  /// Label for number of sets summary
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get setsLabel;

  /// Label for muscle split bar chart
  ///
  /// In en, this message translates to:
  /// **'Muscle Split'**
  String get muscleSplitLabel;

  /// No description provided for @snackbar_could_not_open_open_link.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get snackbar_could_not_open_open_link;

  /// No description provided for @chart_no_data_for_period.
  ///
  /// In en, this message translates to:
  /// **'No chart data for this period'**
  String get chart_no_data_for_period;

  /// No description provided for @amount_in_milliliters.
  ///
  /// In en, this message translates to:
  /// **'Amount in milliliters'**
  String get amount_in_milliliters;

  /// No description provided for @amount_in_grams.
  ///
  /// In en, this message translates to:
  /// **'Amount in grams'**
  String get amount_in_grams;

  /// No description provided for @meal_label.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get meal_label;

  /// No description provided for @add_to_water_intake.
  ///
  /// In en, this message translates to:
  /// **'Add to water intake'**
  String get add_to_water_intake;

  /// No description provided for @create_exercise_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Exercise'**
  String get create_exercise_screen_title;

  /// No description provided for @exercise_name_label.
  ///
  /// In en, this message translates to:
  /// **'Exercise name'**
  String get exercise_name_label;

  /// No description provided for @category_label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category_label;

  /// No description provided for @description_optional_label.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get description_optional_label;

  /// No description provided for @primary_muscles_label.
  ///
  /// In en, this message translates to:
  /// **'Primary muscles'**
  String get primary_muscles_label;

  /// No description provided for @primary_muscles_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chest, Triceps'**
  String get primary_muscles_hint;

  /// No description provided for @secondary_muscles_label.
  ///
  /// In en, this message translates to:
  /// **'Secondary muscles (optional)'**
  String get secondary_muscles_label;

  /// No description provided for @secondary_muscles_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Shoulders'**
  String get secondary_muscles_hint;

  /// No description provided for @fluidNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fluidNameLabel;

  /// No description provided for @sugarPer100mlLabel.
  ///
  /// In en, this message translates to:
  /// **'Sugar (g / 100ml)'**
  String get sugarPer100mlLabel;

  /// No description provided for @set_type_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get set_type_normal;

  /// No description provided for @set_type_warmup.
  ///
  /// In en, this message translates to:
  /// **'Warmup'**
  String get set_type_warmup;

  /// No description provided for @set_type_failure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get set_type_failure;

  /// No description provided for @set_type_dropset.
  ///
  /// In en, this message translates to:
  /// **'Dropset'**
  String get set_type_dropset;

  /// No description provided for @set_reps_hint.
  ///
  /// In en, this message translates to:
  /// **'8-12'**
  String get set_reps_hint;

  /// No description provided for @data_export_button.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get data_export_button;

  /// No description provided for @data_import_button.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get data_import_button;

  /// No description provided for @snackbar_button_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get snackbar_button_ok;

  /// No description provided for @measurement_session_detail_view.
  ///
  /// In en, this message translates to:
  /// **'Detailview of measurement session'**
  String get measurement_session_detail_view;

  /// No description provided for @unit_grams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unit_grams;

  /// No description provided for @unit_kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get unit_kcal;

  /// No description provided for @delete_profile_picture_button.
  ///
  /// In en, this message translates to:
  /// **'Delete profile picture'**
  String get delete_profile_picture_button;

  /// No description provided for @attribution_title.
  ///
  /// In en, this message translates to:
  /// **'Attribution'**
  String get attribution_title;

  /// No description provided for @add_liquid_title.
  ///
  /// In en, this message translates to:
  /// **'Add fluid'**
  String get add_liquid_title;

  /// No description provided for @add_button.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add_button;

  /// No description provided for @discard_button.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard_button;

  /// No description provided for @continue_workout_button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_workout_button;

  /// No description provided for @minimizeWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get minimizeWorkoutButton;

  /// No description provided for @soon_available_snackbar.
  ///
  /// In en, this message translates to:
  /// **'This screen will be available soon'**
  String get soon_available_snackbar;

  /// No description provided for @start_button.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start_button;

  /// No description provided for @today_overview_text.
  ///
  /// In en, this message translates to:
  /// **'TODAY IN FOCUS'**
  String get today_overview_text;

  /// No description provided for @quick_add_text.
  ///
  /// In en, this message translates to:
  /// **'QUICK ADD'**
  String get quick_add_text;

  /// No description provided for @scann_barcode_capslock.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scann_barcode_capslock;

  /// No description provided for @protocol_today_capslock.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S PROTOCOL'**
  String get protocol_today_capslock;

  /// No description provided for @my_plans_capslock.
  ///
  /// In en, this message translates to:
  /// **'MY PLANS'**
  String get my_plans_capslock;

  /// No description provided for @overview_capslock.
  ///
  /// In en, this message translates to:
  /// **'OVERVIEW'**
  String get overview_capslock;

  /// No description provided for @manage_all_plans.
  ///
  /// In en, this message translates to:
  /// **'Manage all plans'**
  String get manage_all_plans;

  /// No description provided for @workoutSectionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get workoutSectionStart;

  /// No description provided for @workoutSectionMyPlans.
  ///
  /// In en, this message translates to:
  /// **'My plans'**
  String get workoutSectionMyPlans;

  /// No description provided for @emptyStateWorkoutRoutinesCallout.
  ///
  /// In en, this message translates to:
  /// **'Create your first routine to track your workouts in the gym in a structured way.'**
  String get emptyStateWorkoutRoutinesCallout;

  /// No description provided for @workoutSectionHistoryLibrary.
  ///
  /// In en, this message translates to:
  /// **'History & library'**
  String get workoutSectionHistoryLibrary;

  /// No description provided for @workoutAllRoutines.
  ///
  /// In en, this message translates to:
  /// **'All routines'**
  String get workoutAllRoutines;

  /// No description provided for @workoutEntryWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutEntryWorkouts;

  /// No description provided for @free_training.
  ///
  /// In en, this message translates to:
  /// **'free training'**
  String get free_training;

  /// No description provided for @my_consistency.
  ///
  /// In en, this message translates to:
  /// **'MY CONSISTENCY'**
  String get my_consistency;

  /// No description provided for @calendar_currently_not_available.
  ///
  /// In en, this message translates to:
  /// **'The calendar view will be available soon.'**
  String get calendar_currently_not_available;

  /// No description provided for @in_depth_analysis.
  ///
  /// In en, this message translates to:
  /// **'IN-DEPTH ANALYSIS'**
  String get in_depth_analysis;

  /// No description provided for @body_measurements.
  ///
  /// In en, this message translates to:
  /// **'Body measurements'**
  String get body_measurements;

  /// No description provided for @measurements_description.
  ///
  /// In en, this message translates to:
  /// **'Analyze weight, body fat percentage and circumference.'**
  String get measurements_description;

  /// No description provided for @nutrition_description.
  ///
  /// In en, this message translates to:
  /// **'Evaluate macros, calories and trends.'**
  String get nutrition_description;

  /// No description provided for @training_analysis.
  ///
  /// In en, this message translates to:
  /// **'Training analysis'**
  String get training_analysis;

  /// No description provided for @training_analysis_description.
  ///
  /// In en, this message translates to:
  /// **'Track volume, strength and progression.'**
  String get training_analysis_description;

  /// No description provided for @load_dots.
  ///
  /// In en, this message translates to:
  /// **'loading...'**
  String get load_dots;

  /// No description provided for @profile_capslock.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profile_capslock;

  /// No description provided for @settings_capslock.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings_capslock;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsUpdateFoodDatabase.
  ///
  /// In en, this message translates to:
  /// **'Update Databases'**
  String get settingsUpdateFoodDatabase;

  /// No description provided for @settingsUpdateFoodDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check for updates to the food and exercise databases manually.'**
  String get settingsUpdateFoodDatabaseSubtitle;

  /// No description provided for @settingsUpdateFoodDatabaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Databases successfully updated.'**
  String get settingsUpdateFoodDatabaseSuccess;

  /// No description provided for @settingsUpdateFoodDatabaseError.
  ///
  /// In en, this message translates to:
  /// **'Error updating databases: {error}'**
  String settingsUpdateFoodDatabaseError(String error);

  /// No description provided for @settingsGuidedTourSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Guided tour'**
  String get settingsGuidedTourSectionTitle;

  /// No description provided for @settingsRestartAppTourTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart app tour'**
  String get settingsRestartAppTourTitle;

  /// No description provided for @settingsRestartAppTourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run the short in-app walkthrough again.'**
  String get settingsRestartAppTourSubtitle;

  /// No description provided for @my_goals.
  ///
  /// In en, this message translates to:
  /// **'My goals'**
  String get my_goals;

  /// No description provided for @my_goals_description.
  ///
  /// In en, this message translates to:
  /// **'Adjust calories, macros and water.'**
  String get my_goals_description;

  /// No description provided for @backup_and_import.
  ///
  /// In en, this message translates to:
  /// **'Data backup & import'**
  String get backup_and_import;

  /// No description provided for @backup_and_import_description.
  ///
  /// In en, this message translates to:
  /// **'Create backups, restore, and import data.'**
  String get backup_and_import_description;

  /// No description provided for @feedbackReportSettingsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get feedbackReportSettingsSectionTitle;

  /// No description provided for @feedbackReportSettingsEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedbackReportSettingsEntryTitle;

  /// No description provided for @feedbackReportSettingsEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a local diagnostic report and choose how to share it.'**
  String get feedbackReportSettingsEntrySubtitle;

  /// No description provided for @about_and_legal_capslock.
  ///
  /// In en, this message translates to:
  /// **'ABOUT & LEGAL'**
  String get about_and_legal_capslock;

  /// No description provided for @feedbackReportScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback report'**
  String get feedbackReportScreenTitle;

  /// No description provided for @feedbackReportPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy first'**
  String get feedbackReportPrivacyTitle;

  /// No description provided for @feedbackReportPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'This report is generated locally on your device. Nothing is sent automatically. Only what you see in the preview is included when you choose copy, save, share, or email. Email opens a draft to feedback@schotte.me so you can review, edit, or cancel before sending.'**
  String get feedbackReportPrivacyBody;

  /// No description provided for @feedbackReportOptionalNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get feedbackReportOptionalNoteTitle;

  /// No description provided for @feedbackReportOptionalNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Your note (optional)'**
  String get feedbackReportOptionalNoteLabel;

  /// No description provided for @feedbackReportOptionalNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened, expected behavior, and steps to reproduce.'**
  String get feedbackReportOptionalNoteHint;

  /// No description provided for @feedbackReportIncludeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Include in report'**
  String get feedbackReportIncludeSectionTitle;

  /// No description provided for @feedbackReportIncludeAdaptiveNutrition.
  ///
  /// In en, this message translates to:
  /// **'Adaptive nutrition diagnostics'**
  String get feedbackReportIncludeAdaptiveNutrition;

  /// No description provided for @feedbackReportIncludeBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup / restore diagnostics'**
  String get feedbackReportIncludeBackupRestore;

  /// No description provided for @feedbackReportIncludePerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance log (frame timings)'**
  String get feedbackReportIncludePerformance;

  /// No description provided for @settingsPerformanceLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance Log'**
  String get settingsPerformanceLogTitle;

  /// No description provided for @settingsPerformanceLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows which screens drop frames'**
  String get settingsPerformanceLogSubtitle;

  /// No description provided for @performanceLogIntro.
  ///
  /// In en, this message translates to:
  /// **'Records refresh rate and dropped frames on this device. Runs in the background and only leaves the device when you share the log.'**
  String get performanceLogIntro;

  /// No description provided for @performanceLogDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get performanceLogDeviceLabel;

  /// No description provided for @performanceLogDisplayLabel.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get performanceLogDisplayLabel;

  /// No description provided for @performanceLogFramesLabel.
  ///
  /// In en, this message translates to:
  /// **'Frames'**
  String get performanceLogFramesLabel;

  /// No description provided for @performanceLogJankLabel.
  ///
  /// In en, this message translates to:
  /// **'Dropped frames'**
  String get performanceLogJankLabel;

  /// No description provided for @performanceLogStallsLabel.
  ///
  /// In en, this message translates to:
  /// **'Stalls'**
  String get performanceLogStallsLabel;

  /// No description provided for @performanceLogCopyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get performanceLogCopyButton;

  /// No description provided for @performanceLogShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get performanceLogShareButton;

  /// No description provided for @performanceLogCopiedSnack.
  ///
  /// In en, this message translates to:
  /// **'Performance log copied.'**
  String get performanceLogCopiedSnack;

  /// No description provided for @performanceLogScreensSection.
  ///
  /// In en, this message translates to:
  /// **'Screens'**
  String get performanceLogScreensSection;

  /// No description provided for @performanceLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No frames recorded yet.'**
  String get performanceLogEmpty;

  /// No description provided for @performanceLogStallsSection.
  ///
  /// In en, this message translates to:
  /// **'Stalls (UI thread blocked)'**
  String get performanceLogStallsSection;

  /// No description provided for @performanceLogStartupSection.
  ///
  /// In en, this message translates to:
  /// **'Startup & resume'**
  String get performanceLogStartupSection;

  /// No description provided for @performanceLogStartupEmpty.
  ///
  /// In en, this message translates to:
  /// **'No startup measured yet.'**
  String get performanceLogStartupEmpty;

  /// No description provided for @performanceLogStartupCold.
  ///
  /// In en, this message translates to:
  /// **'Cold start'**
  String get performanceLogStartupCold;

  /// No description provided for @performanceLogStartupResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get performanceLogStartupResume;

  /// No description provided for @performanceLogStartupUnattributed.
  ///
  /// In en, this message translates to:
  /// **'Framework & first render'**
  String get performanceLogStartupUnattributed;

  /// No description provided for @performanceLogSevereLabel.
  ///
  /// In en, this message translates to:
  /// **'severe'**
  String get performanceLogSevereLabel;

  /// No description provided for @performanceLogPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause recording'**
  String get performanceLogPauseTitle;

  /// No description provided for @performanceLogResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset measurements'**
  String get performanceLogResetTitle;

  /// No description provided for @performanceLogResetDialogBody.
  ///
  /// In en, this message translates to:
  /// **'All recorded frame statistics and stalls will be deleted. Recording starts from zero afterwards.'**
  String get performanceLogResetDialogBody;

  /// No description provided for @performanceLogResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get performanceLogResetConfirm;

  /// No description provided for @performanceLogResetDoneSnack.
  ///
  /// In en, this message translates to:
  /// **'Measurements reset.'**
  String get performanceLogResetDoneSnack;

  /// No description provided for @feedbackReportIncludeUserNote.
  ///
  /// In en, this message translates to:
  /// **'User note'**
  String get feedbackReportIncludeUserNote;

  /// No description provided for @feedbackReportGeneratePreview.
  ///
  /// In en, this message translates to:
  /// **'Generate preview'**
  String get feedbackReportGeneratePreview;

  /// No description provided for @feedbackReportPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get feedbackReportPreviewTitle;

  /// No description provided for @feedbackReportActionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get feedbackReportActionCopy;

  /// No description provided for @feedbackReportActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get feedbackReportActionSave;

  /// No description provided for @feedbackReportActionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get feedbackReportActionShare;

  /// No description provided for @feedbackReportActionEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get feedbackReportActionEmail;

  /// No description provided for @feedbackReportCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied to clipboard.'**
  String get feedbackReportCopied;

  /// No description provided for @feedbackReportSavedToTemporaryFile.
  ///
  /// In en, this message translates to:
  /// **'Saved to a temporary report file.'**
  String get feedbackReportSavedToTemporaryFile;

  /// No description provided for @feedbackReportShareCompleted.
  ///
  /// In en, this message translates to:
  /// **'Share sheet opened.'**
  String get feedbackReportShareCompleted;

  /// No description provided for @feedbackReportShareCanceled.
  ///
  /// In en, this message translates to:
  /// **'Share canceled.'**
  String get feedbackReportShareCanceled;

  /// No description provided for @feedbackReportEmailOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app.'**
  String get feedbackReportEmailOpenFailed;

  /// No description provided for @feedbackReportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Train Libre feedback report'**
  String get feedbackReportEmailSubject;

  /// No description provided for @feedbackReportReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Train Libre Feedback Report'**
  String get feedbackReportReportTitle;

  /// No description provided for @feedbackReportReportGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get feedbackReportReportGeneratedAt;

  /// No description provided for @feedbackReportReportAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get feedbackReportReportAppVersion;

  /// No description provided for @feedbackReportReportBuildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build number'**
  String get feedbackReportReportBuildNumber;

  /// No description provided for @feedbackReportReportPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get feedbackReportReportPlatform;

  /// No description provided for @feedbackReportReportOsVersion.
  ///
  /// In en, this message translates to:
  /// **'OS version'**
  String get feedbackReportReportOsVersion;

  /// No description provided for @feedbackReportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'unavailable'**
  String get feedbackReportUnavailable;

  /// No description provided for @feedbackReportSectionUserNote.
  ///
  /// In en, this message translates to:
  /// **'User note'**
  String get feedbackReportSectionUserNote;

  /// No description provided for @feedbackReportSectionAdaptiveNutrition.
  ///
  /// In en, this message translates to:
  /// **'Adaptive nutrition diagnostics'**
  String get feedbackReportSectionAdaptiveNutrition;

  /// No description provided for @feedbackReportSectionBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup / restore diagnostics'**
  String get feedbackReportSectionBackupRestore;

  /// No description provided for @attribution_and_license.
  ///
  /// In en, this message translates to:
  /// **'Attribution & Licenses'**
  String get attribution_and_license;

  /// No description provided for @data_from_off_and_wger.
  ///
  /// In en, this message translates to:
  /// **'Data from Open Food Facts and wger.'**
  String get data_from_off_and_wger;

  /// No description provided for @app_version.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get app_version;

  /// No description provided for @all_measurements.
  ///
  /// In en, this message translates to:
  /// **'ALL MEASUREMENTS'**
  String get all_measurements;

  /// No description provided for @all_measurements_no_cap.
  ///
  /// In en, this message translates to:
  /// **'All measurements'**
  String get all_measurements_no_cap;

  /// No description provided for @date_and_time_of_measurement.
  ///
  /// In en, this message translates to:
  /// **'Date & time of measurement'**
  String get date_and_time_of_measurement;

  /// Onboarding slide 1 title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Train Libre'**
  String get onbWelcomeTitle;

  /// Onboarding slide 1 description
  ///
  /// In en, this message translates to:
  /// **'Let’s start by setting personal goals to guide training and nutrition.'**
  String get onbWelcomeBody;

  /// Onboarding slide 2 title
  ///
  /// In en, this message translates to:
  /// **'Track everything'**
  String get onbTrackTitle;

  /// Onboarding slide 2 description
  ///
  /// In en, this message translates to:
  /// **'Log nutrition, workouts, and measurements — all in one place.'**
  String get onbTrackBody;

  /// Onboarding slide 3 title
  ///
  /// In en, this message translates to:
  /// **'Offline-first & privacy'**
  String get onbPrivacyTitle;

  /// Onboarding slide 3 description
  ///
  /// In en, this message translates to:
  /// **'Your data stays on the device. No cloud accounts, no background sync.'**
  String get onbPrivacyBody;

  /// Onboarding final slide title
  ///
  /// In en, this message translates to:
  /// **'All set'**
  String get onbFinishTitle;

  /// Onboarding final slide description
  ///
  /// In en, this message translates to:
  /// **'You’re ready to explore the app. You can adjust settings anytime.'**
  String get onbFinishBody;

  /// Final button label to finish onboarding
  ///
  /// In en, this message translates to:
  /// **'Let’s go!'**
  String get onbFinishCta;

  /// Settings item to reopen onboarding
  ///
  /// In en, this message translates to:
  /// **'Show onboarding again'**
  String get onbShowTutorialAgain;

  /// No description provided for @appTourOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a quick app tour?'**
  String get appTourOfferTitle;

  /// No description provided for @appTourOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Get a short walkthrough of the main app areas. You can skip now and restart later in Settings.'**
  String get appTourOfferBody;

  /// No description provided for @appTourOfferStart.
  ///
  /// In en, this message translates to:
  /// **'Start tour'**
  String get appTourOfferStart;

  /// No description provided for @appTourOfferSkip.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get appTourOfferSkip;

  /// No description provided for @appTourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get appTourSkip;

  /// No description provided for @appTourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get appTourNext;

  /// No description provided for @appTourDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get appTourDone;

  /// No description provided for @appTourStepNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Main navigation'**
  String get appTourStepNavigationTitle;

  /// No description provided for @appTourStepNavigationBody.
  ///
  /// In en, this message translates to:
  /// **'Use the bottom tabs to move between Diary, Workout, Statistics, and Nutrition.'**
  String get appTourStepNavigationBody;

  /// No description provided for @appTourStepQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get appTourStepQuickActionsTitle;

  /// No description provided for @appTourStepQuickActionsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the plus button to quickly add food, fluids, measurements, workouts, and more.'**
  String get appTourStepQuickActionsBody;

  /// No description provided for @appTourStepDiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get appTourStepDiaryTitle;

  /// No description provided for @appTourStepDiaryBody.
  ///
  /// In en, this message translates to:
  /// **'Diary is your daily overview. Track meals, hydration, supplements, and your day at a glance.'**
  String get appTourStepDiaryBody;

  /// No description provided for @appTourStepWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get appTourStepWorkoutTitle;

  /// No description provided for @appTourStepWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'Workout is where you start sessions, manage routines, and review your training history.'**
  String get appTourStepWorkoutBody;

  /// No description provided for @appTourStepNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get appTourStepNutritionTitle;

  /// No description provided for @appTourStepNutritionBody.
  ///
  /// In en, this message translates to:
  /// **'Nutrition helps you plan meals, review targets, and access tools like meal templates.'**
  String get appTourStepNutritionBody;

  /// No description provided for @appTourStepStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get appTourStepStatisticsTitle;

  /// No description provided for @appTourStepStatisticsBody.
  ///
  /// In en, this message translates to:
  /// **'Statistics shows trends and progress so you can understand how your data changes over time.'**
  String get appTourStepStatisticsBody;

  /// No description provided for @appTourRestartTitle.
  ///
  /// In en, this message translates to:
  /// **'View App Tour'**
  String get appTourRestartTitle;

  /// No description provided for @appTourRestartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review the introduction and key features'**
  String get appTourRestartSubtitle;

  /// Optional CTA linking to Goals screen from onboarding
  ///
  /// In en, this message translates to:
  /// **'Set goals'**
  String get onbSetGoalsCta;

  /// Onboarding header title
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get onbHeaderTitle;

  /// Skip button label in onboarding header
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbHeaderSkip;

  /// Back button in onboarding footer
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onbBack;

  /// Next button in onboarding footer
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// Guide banner title in onboarding
  ///
  /// In en, this message translates to:
  /// **'How this tutorial works'**
  String get onbGuideTitle;

  /// Guide banner description in onboarding
  ///
  /// In en, this message translates to:
  /// **'Swipe between slides or use Next. Tap the buttons on each slide to try features. You can finish anytime with Skip.'**
  String get onbGuideBody;

  /// CTA to open nutrition tracking from onboarding
  ///
  /// In en, this message translates to:
  /// **'Open nutrition'**
  String get onbCtaOpenNutrition;

  /// CTA to learn more about privacy/offline
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get onbCtaLearnMore;

  /// Badge label shown after completing CTA
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get onbBadgeDone;

  /// Hint text on goals slide
  ///
  /// In en, this message translates to:
  /// **'Tip: adjust targets first'**
  String get onbTipSetGoals;

  /// Hint text on nutrition slide
  ///
  /// In en, this message translates to:
  /// **'Tip: add one entry today'**
  String get onbTipAddEntry;

  /// Hint on privacy slide about local data control
  ///
  /// In en, this message translates to:
  /// **'You control all data locally'**
  String get onbTipLocalControl;

  /// Onboarding slide 2 replacement body: step-by-step nutrition logging instructions
  ///
  /// In en, this message translates to:
  /// **'How to log nutrition:\n• Open the Food tab.\n• Tap the + button.\n• Search products or scan a barcode.\n• Adjust portion and time.\n• Save to your diary.'**
  String get onbTrackHowBody;

  /// Onboarding slide title for measurements
  ///
  /// In en, this message translates to:
  /// **'Track measurements'**
  String get onbMeasureTitle;

  /// Step-by-step instructions for adding measurements
  ///
  /// In en, this message translates to:
  /// **'How to add measurements:\n• Open the Stats tab.\n• Tap the + button.\n• Choose a metric (e.g., weight, waist, body fat).\n• Enter value and time.\n• Save to your history.'**
  String get onbMeasureBody;

  /// Hint for measurements slide
  ///
  /// In en, this message translates to:
  /// **'Tip: add today’s weight to start your graph'**
  String get onbTipMeasureToday;

  /// Onboarding slide title for training routines
  ///
  /// In en, this message translates to:
  /// **'Train with routines'**
  String get onbTrainTitle;

  /// Instructions for creating a routine and starting a workout
  ///
  /// In en, this message translates to:
  /// **'Create a routine and start a workout:\n• Open the Train tab.\n• Tap Create routine to add exercises and sets.\n• Save the routine.\n• Tap Start to begin, or use “Start empty workout”.'**
  String get onbTrainBody;

  /// Hint for training slide
  ///
  /// In en, this message translates to:
  /// **'Tip: start an empty workout to log a quick session'**
  String get onbTipStartWorkout;

  /// No description provided for @unitsSection.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitsSection;

  /// No description provided for @weightUnit.
  ///
  /// In en, this message translates to:
  /// **'Weight units'**
  String get weightUnit;

  /// No description provided for @lengthUnit.
  ///
  /// In en, this message translates to:
  /// **'unit of length'**
  String get lengthUnit;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No Favorites'**
  String get noFavorites;

  /// No description provided for @nothingTrackedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing tracked yet'**
  String get nothingTrackedYet;

  /// No description provided for @snackbarBarcodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No product found for barcode \"{barcode}\".'**
  String snackbarBarcodeNotFound(String barcode);

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chest, Back, Legs...'**
  String get categoryHint;

  /// No description provided for @validatorPleaseEnterCategory.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category.'**
  String get validatorPleaseEnterCategory;

  /// No description provided for @dialogEnterPasswordImport.
  ///
  /// In en, this message translates to:
  /// **'Enter password to import backup'**
  String get dialogEnterPasswordImport;

  /// No description provided for @dataManagementBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Train Libre Data Backup'**
  String get dataManagementBackupTitle;

  /// No description provided for @dataManagementBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Back up or restore all your app data. Ideal for changing devices.'**
  String get dataManagementBackupDescription;

  /// No description provided for @exportEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Export Encrypted'**
  String get exportEncrypted;

  /// No description provided for @dialogPasswordForExport.
  ///
  /// In en, this message translates to:
  /// **'Password for encrypted export'**
  String get dialogPasswordForExport;

  /// No description provided for @snackbarEncryptedBackupShared.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup shared.'**
  String get snackbarEncryptedBackupShared;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed.'**
  String get exportFailed;

  /// No description provided for @csvExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Export (CSV)'**
  String get csvExportTitle;

  /// No description provided for @csvExportDescription.
  ///
  /// In en, this message translates to:
  /// **'Export parts of your data as a CSV file for analysis in other programs.'**
  String get csvExportDescription;

  /// No description provided for @snackbarSharingNutrition.
  ///
  /// In en, this message translates to:
  /// **'Sharing nutrition diary...'**
  String get snackbarSharingNutrition;

  /// No description provided for @snackbarExportFailedNoEntries.
  ///
  /// In en, this message translates to:
  /// **'Export failed. There may be no entries yet.'**
  String get snackbarExportFailedNoEntries;

  /// No description provided for @snackbarSharingMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Sharing measurements...'**
  String get snackbarSharingMeasurements;

  /// No description provided for @snackbarSharingWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Sharing workout history...'**
  String get snackbarSharingWorkouts;

  /// No description provided for @mapExercisesTitle.
  ///
  /// In en, this message translates to:
  /// **'Map Exercises'**
  String get mapExercisesTitle;

  /// No description provided for @mapExercisesDescription.
  ///
  /// In en, this message translates to:
  /// **'Map unknown names from logs to wger exercises.'**
  String get mapExercisesDescription;

  /// No description provided for @mapExercisesButton.
  ///
  /// In en, this message translates to:
  /// **'Start Mapping'**
  String get mapExercisesButton;

  /// No description provided for @autoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic Backups'**
  String get autoBackupTitle;

  /// No description provided for @autoBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Periodically saves a backup in the folder. Current folder:'**
  String get autoBackupDescription;

  /// No description provided for @autoBackupDefaultFolder.
  ///
  /// In en, this message translates to:
  /// **'App-Documents/Backups (Default)'**
  String get autoBackupDefaultFolder;

  /// No description provided for @autoBackupChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get autoBackupChooseFolder;

  /// No description provided for @autoBackupCopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy Path'**
  String get autoBackupCopyPath;

  /// No description provided for @autoBackupRunNow.
  ///
  /// In en, this message translates to:
  /// **'Check & Run Auto-Backup Now'**
  String get autoBackupRunNow;

  /// No description provided for @icloudAutoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'iCloud Auto-Backup'**
  String get icloudAutoBackupTitle;

  /// No description provided for @icloudAutoBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically syncs your database to iCloud Drive whenever the app goes into the background. Your data can be restored on a new device or after reinstalling.'**
  String get icloudAutoBackupDescription;

  /// No description provided for @icloudBackupNow.
  ///
  /// In en, this message translates to:
  /// **'Backup to iCloud Now'**
  String get icloudBackupNow;

  /// No description provided for @icloudBackupUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get icloudBackupUploading;

  /// No description provided for @icloudBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup uploaded successfully.'**
  String get icloudBackupSuccess;

  /// No description provided for @icloudBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed. Check your iCloud connection.'**
  String get icloudBackupFailed;

  /// No description provided for @autoBackupRequestAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To automatically back up your data, Train Libre needs access to a folder you choose. Your backups will be stored there.'**
  String get autoBackupRequestAccessSubtitle;

  /// No description provided for @snackbarAutoBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Auto-Backup completed.'**
  String get snackbarAutoBackupSuccess;

  /// No description provided for @snackbarAutoBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto-Backup failed or was canceled.'**
  String get snackbarAutoBackupFailed;

  /// No description provided for @localDataDeletionCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Local app data'**
  String get localDataDeletionCardTitle;

  /// No description provided for @localDataDeletionCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete user-owned data stored on this device and reset Train Libre to a fresh local state.'**
  String get localDataDeletionCardDescription;

  /// No description provided for @deleteAllLocalAppData.
  ///
  /// In en, this message translates to:
  /// **'Delete all local app data'**
  String get deleteAllLocalAppData;

  /// No description provided for @localDataDeletionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all local app data?'**
  String get localDataDeletionConfirmTitle;

  /// No description provided for @localDataDeletionConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes locally stored workouts, nutrition logs, measurements, supplements, settings/state, cached analytics, and local app data.\n\nThis does not delete data already exported to Apple Health or Health Connect.\n\nThis does not delete external provider data or remote public catalog sources. Bundled app assets and required default catalogs are kept or recreated so the app can launch after reset.'**
  String get localDataDeletionConfirmBody;

  /// No description provided for @localDataDeletionTypeDeleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get localDataDeletionTypeDeleteLabel;

  /// No description provided for @localDataDeletionSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Local data deleted'**
  String get localDataDeletionSuccessTitle;

  /// No description provided for @localDataDeletionSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Train Libre will return to its initial setup state.'**
  String get localDataDeletionSuccessBody;

  /// No description provided for @localDataDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Local data could not be deleted. Please try again.'**
  String get localDataDeletionFailed;

  /// No description provided for @noUnknownExercisesFound.
  ///
  /// In en, this message translates to:
  /// **'No unknown exercises found'**
  String get noUnknownExercisesFound;

  /// No description provided for @snackbarAutoBackupFolderSet.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup folder set:\n{path}'**
  String snackbarAutoBackupFolderSet(String path);

  /// No description provided for @snackbarPathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied'**
  String get snackbarPathCopied;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @involvedMuscles.
  ///
  /// In en, this message translates to:
  /// **'Involved Muscles'**
  String get involvedMuscles;

  /// No description provided for @primaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary:'**
  String get primaryLabel;

  /// No description provided for @secondaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Secondary:'**
  String get secondaryLabel;

  /// No description provided for @noMusclesSpecified.
  ///
  /// In en, this message translates to:
  /// **'No muscles specified.'**
  String get noMusclesSpecified;

  /// No description provided for @frontLabel.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get frontLabel;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @noSelection.
  ///
  /// In en, this message translates to:
  /// **'No selection'**
  String get noSelection;

  /// No description provided for @selectButton.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectButton;

  /// No description provided for @applyingChanges.
  ///
  /// In en, this message translates to:
  /// **'Applying changes...'**
  String get applyingChanges;

  /// No description provided for @applyMapping.
  ///
  /// In en, this message translates to:
  /// **'Apply Mapping'**
  String get applyMapping;

  /// No description provided for @mappingSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get mappingSuggestions;

  /// No description provided for @mappingSuggestionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching exercises found'**
  String get mappingSuggestionsEmpty;

  /// No description provided for @personalData.
  ///
  /// In en, this message translates to:
  /// **'Personal Data'**
  String get personalData;

  /// No description provided for @personalDataCL.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL DATA'**
  String get personalDataCL;

  /// No description provided for @macroDistribution.
  ///
  /// In en, this message translates to:
  /// **'Macronutrient Distribution'**
  String get macroDistribution;

  /// No description provided for @dialogFinishWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to finish this workout?'**
  String get dialogFinishWorkoutBody;

  /// No description provided for @attributionText.
  ///
  /// In en, this message translates to:
  /// **'This app uses data from external sources:\n\n● Exercise data from OpenExerciseDB (github.com/rfivesix/OpenExerciseDB), licensed under CC BY-SA 4.0, derived in part from the wger project (wger.de).\n\n● Food database from Open Food Facts (openfoodfacts.org), available under the Open Database License (ODbL).'**
  String get attributionText;

  /// No description provided for @errorRoutineNotFound.
  ///
  /// In en, this message translates to:
  /// **'Routine not found'**
  String get errorRoutineNotFound;

  /// No description provided for @workoutHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your history is empty'**
  String get workoutHistoryEmptyTitle;

  /// No description provided for @workoutSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Complete'**
  String get workoutSummaryTitle;

  /// No description provided for @workoutSummaryExerciseOverview.
  ///
  /// In en, this message translates to:
  /// **'Exercise Overview'**
  String get workoutSummaryExerciseOverview;

  /// No description provided for @nutritionDiary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get nutritionDiary;

  /// No description provided for @detailedNutrientGoals.
  ///
  /// In en, this message translates to:
  /// **'Detailed Nutrients'**
  String get detailedNutrientGoals;

  /// No description provided for @detailedNutrientGoalsCL.
  ///
  /// In en, this message translates to:
  /// **'DETAILED NUTRIENTS'**
  String get detailedNutrientGoalsCL;

  /// No description provided for @supplementTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplement Tracker'**
  String get supplementTrackerTitle;

  /// No description provided for @supplementTrackerDescription.
  ///
  /// In en, this message translates to:
  /// **'Track goals, limits, and intake.'**
  String get supplementTrackerDescription;

  /// No description provided for @createSupplementTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Supplement'**
  String get createSupplementTitle;

  /// No description provided for @supplementNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplement Name'**
  String get supplementNameLabel;

  /// No description provided for @defaultDoseLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Dose'**
  String get defaultDoseLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @dailyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal (optional)'**
  String get dailyGoalLabel;

  /// No description provided for @dailyLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Limit (optional)'**
  String get dailyLimitLabel;

  /// No description provided for @dailyProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Progress'**
  String get dailyProgressTitle;

  /// No description provided for @todaysLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Log'**
  String get todaysLogTitle;

  /// No description provided for @logIntakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Intake'**
  String get logIntakeTitle;

  /// No description provided for @emptySupplementGoals.
  ///
  /// In en, this message translates to:
  /// **'Set goals or limits for supplements to see your progress here.'**
  String get emptySupplementGoals;

  /// No description provided for @emptySupplementLogs.
  ///
  /// In en, this message translates to:
  /// **'No intake logged for today yet.'**
  String get emptySupplementLogs;

  /// No description provided for @doseLabel.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get doseLabel;

  /// No description provided for @settingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Theme, units, data and more'**
  String get settingsDescription;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @caffeinePrompt.
  ///
  /// In en, this message translates to:
  /// **'Caffeine (optional)'**
  String get caffeinePrompt;

  /// No description provided for @caffeineUnit.
  ///
  /// In en, this message translates to:
  /// **'mg per 100ml'**
  String get caffeineUnit;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @measurementWeightCapslock.
  ///
  /// In en, this message translates to:
  /// **'BODY WEIGHT'**
  String get measurementWeightCapslock;

  /// No description provided for @diary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diary;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @dayBeforeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Two days ago'**
  String get dayBeforeYesterday;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @addFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'add food'**
  String get addFoodTitle;

  /// No description provided for @nutritionExplorerTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Explorer'**
  String get nutritionExplorerTitle;

  /// No description provided for @myMeals.
  ///
  /// In en, this message translates to:
  /// **'My Recipes'**
  String get myMeals;

  /// No description provided for @myMealsCL.
  ///
  /// In en, this message translates to:
  /// **'MY RECIPES'**
  String get myMealsCL;

  /// No description provided for @nutritionSectionTodayInFocus.
  ///
  /// In en, this message translates to:
  /// **'Today in focus'**
  String get nutritionSectionTodayInFocus;

  /// No description provided for @nutritionSectionMyMeals.
  ///
  /// In en, this message translates to:
  /// **'My recipes'**
  String get nutritionSectionMyMeals;

  /// No description provided for @emptyStateNutritionRecipesCallout.
  ///
  /// In en, this message translates to:
  /// **'Create your first recipe to quickly log your frequent meals.'**
  String get emptyStateNutritionRecipesCallout;

  /// No description provided for @nutritionSectionToolsAndLibrary.
  ///
  /// In en, this message translates to:
  /// **'Tools & library'**
  String get nutritionSectionToolsAndLibrary;

  /// No description provided for @supplement_caffeine.
  ///
  /// In en, this message translates to:
  /// **'Caffeine'**
  String get supplement_caffeine;

  /// No description provided for @supplement_creatine_monohydrate.
  ///
  /// In en, this message translates to:
  /// **'Creatine Monohydrate'**
  String get supplement_creatine_monohydrate;

  /// No description provided for @manageSupplementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage supplements'**
  String get manageSupplementsTitle;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'deleted'**
  String get deleted;

  /// No description provided for @operationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This operation isn\'t allowed'**
  String get operationNotAllowed;

  /// No description provided for @emptySupplements.
  ///
  /// In en, this message translates to:
  /// **'No supplements available'**
  String get emptySupplements;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @deleteSupplementConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this supplement? All historical data will be lost.\n\nTip: You can simply untrack it by editing the supplement instead.'**
  String get deleteSupplementConfirm;

  /// No description provided for @editSupplementLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Log Entry'**
  String get editSupplementLogTitle;

  /// No description provided for @deleteSupplementLogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this log entry?'**
  String get deleteSupplementLogConfirm;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @unitNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Unit not supported.'**
  String get unitNotSupported;

  /// No description provided for @caffeineUnitLocked.
  ///
  /// In en, this message translates to:
  /// **'For caffeine the unit is fixed: mg.'**
  String get caffeineUnitLocked;

  /// No description provided for @caffeineMustBeMg.
  ///
  /// In en, this message translates to:
  /// **'Caffeine must be recorded in mg.'**
  String get caffeineMustBeMg;

  /// No description provided for @tabCatalogSearch.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get tabCatalogSearch;

  /// No description provided for @tabMeals.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get tabMeals;

  /// No description provided for @emptyCategory.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get emptyCategory;

  /// No description provided for @searchSectionBase.
  ///
  /// In en, this message translates to:
  /// **'Base foods'**
  String get searchSectionBase;

  /// No description provided for @searchSectionOther.
  ///
  /// In en, this message translates to:
  /// **'Other results'**
  String get searchSectionOther;

  /// No description provided for @mealsComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipes (coming soon)'**
  String get mealsComingSoonTitle;

  /// No description provided for @mealsComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Soon you will be able to create your own recipes from multiple foods.'**
  String get mealsComingSoonBody;

  /// No description provided for @mealsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recipe templates saved'**
  String get mealsEmptyTitle;

  /// No description provided for @mealsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create recipes to quickly log multiple foods at once.'**
  String get mealsEmptyBody;

  /// No description provided for @mealsEmptyBodyWithShortcut.
  ///
  /// In en, this message translates to:
  /// **'In the diary, use the “Save as recipe” option below your Breakfast or Dinner to save common food combinations as a quick template.'**
  String get mealsEmptyBodyWithShortcut;

  /// No description provided for @mealsCreateManually.
  ///
  /// In en, this message translates to:
  /// **'Create recipe manually'**
  String get mealsCreateManually;

  /// No description provided for @saveMealTemplateShortcut.
  ///
  /// In en, this message translates to:
  /// **'Save as recipe'**
  String get saveMealTemplateShortcut;

  /// No description provided for @mealsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create recipe'**
  String get mealsCreate;

  /// No description provided for @mealsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit recipe'**
  String get mealsEdit;

  /// No description provided for @mealsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete recipe'**
  String get mealsDelete;

  /// No description provided for @mealsAddToDiary.
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get mealsAddToDiary;

  /// No description provided for @mealNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipe name'**
  String get mealNameLabel;

  /// No description provided for @mealNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get mealNotesLabel;

  /// No description provided for @mealIngredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get mealIngredientsTitle;

  /// No description provided for @mealAddIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get mealAddIngredient;

  /// No description provided for @mealIngredientAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get mealIngredientAmountLabel;

  /// No description provided for @mealDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recipe'**
  String get mealDeleteConfirmTitle;

  /// No description provided for @mealDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the recipe \'{name}\'? All its ingredients will also be removed.'**
  String mealDeleteConfirmBody(Object name);

  /// No description provided for @mealAddedToDiary.
  ///
  /// In en, this message translates to:
  /// **'Recipe \'{name}\' has been added to your diary.'**
  String mealAddedToDiary(Object name);

  /// No description provided for @mealSaved.
  ///
  /// In en, this message translates to:
  /// **'Recipe saved.'**
  String get mealSaved;

  /// No description provided for @mealDeleted.
  ///
  /// In en, this message translates to:
  /// **'Recipe deleted.'**
  String get mealDeleted;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @addMealToDiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to diary'**
  String get addMealToDiaryTitle;

  /// No description provided for @mealTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get mealTypeLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @mealAddedToDiarySuccess.
  ///
  /// In en, this message translates to:
  /// **'Recipe added to diary'**
  String get mealAddedToDiarySuccess;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @mealsViewTitle.
  ///
  /// In en, this message translates to:
  /// **'mealsViewTitle'**
  String get mealsViewTitle;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get noNotes;

  /// No description provided for @ingredientsCapsLock.
  ///
  /// In en, this message translates to:
  /// **'INGREDIENTS'**
  String get ingredientsCapsLock;

  /// No description provided for @nutritionSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'NUTRITION FACTS'**
  String get nutritionSectionLabel;

  /// No description provided for @nutritionCalculatedForCurrentAmounts.
  ///
  /// In en, this message translates to:
  /// **'for current quantities'**
  String get nutritionCalculatedForCurrentAmounts;

  /// No description provided for @startCapsLock.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get startCapsLock;

  /// No description provided for @nutritionHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover insights, track meals, and plan your nutrition here soon.'**
  String get nutritionHubSubtitle;

  /// No description provided for @nutritionHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionHubTitle;

  /// No description provided for @nutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutrition;

  /// No description provided for @changeSetTypTitle.
  ///
  /// In en, this message translates to:
  /// **'Change set type'**
  String get changeSetTypTitle;

  /// No description provided for @settingsVisualStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Visual Style'**
  String get settingsVisualStyleTitle;

  /// No description provided for @settingsVisualStyleStandard.
  ///
  /// In en, this message translates to:
  /// **'Frosted Glass'**
  String get settingsVisualStyleStandard;

  /// No description provided for @settingsVisualStyleLiquid.
  ///
  /// In en, this message translates to:
  /// **'Liquid Glass (Fluid)'**
  String get settingsVisualStyleLiquid;

  /// No description provided for @settingsVisualStyleLiquidDesc.
  ///
  /// In en, this message translates to:
  /// **'Rounded, floating UI elements'**
  String get settingsVisualStyleLiquidDesc;

  /// No description provided for @settingsMaterialColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Material colors'**
  String get settingsMaterialColorsTitle;

  /// No description provided for @settingsMaterialColorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use dynamic system colors (Material You) instead of the Train Libre brand accent'**
  String get settingsMaterialColorsSubtitle;

  /// No description provided for @settingsFoodDbSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Food database'**
  String get settingsFoodDbSectionTitle;

  /// No description provided for @settingsFoodDbRegionTitle.
  ///
  /// In en, this message translates to:
  /// **'Food database region'**
  String get settingsFoodDbRegionTitle;

  /// No description provided for @settingsFoodDbRegionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select which Open Food Facts product catalog region is used for food search.'**
  String get settingsFoodDbRegionSubtitle;

  /// No description provided for @settingsFoodDbRegionCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current region'**
  String get settingsFoodDbRegionCurrent;

  /// No description provided for @settingsFoodDbRegionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose food database region'**
  String get settingsFoodDbRegionDialogTitle;

  /// No description provided for @settingsFoodDbRegionDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This changes the Open Food Facts catalog source used by product search.'**
  String get settingsFoodDbRegionDialogSubtitle;

  /// No description provided for @settingsFoodDbRegionSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search region...'**
  String get settingsFoodDbRegionSearchPlaceholder;

  /// No description provided for @settingsFoodDbRegionNoResults.
  ///
  /// In en, this message translates to:
  /// **'No region found'**
  String get settingsFoodDbRegionNoResults;

  /// No description provided for @settingsFoodDbRegionIssueHint.
  ///
  /// In en, this message translates to:
  /// **'If your country is not listed yet, feel free to open a GitHub issue and request support.'**
  String get settingsFoodDbRegionIssueHint;

  /// No description provided for @settingsFoodDbRegionGermany.
  ///
  /// In en, this message translates to:
  /// **'Germany (DE)'**
  String get settingsFoodDbRegionGermany;

  /// No description provided for @settingsFoodDbRegionSwitzerland.
  ///
  /// In en, this message translates to:
  /// **'Switzerland (CH)'**
  String get settingsFoodDbRegionSwitzerland;

  /// No description provided for @settingsFoodDbRegionUnitedStates.
  ///
  /// In en, this message translates to:
  /// **'United States (US)'**
  String get settingsFoodDbRegionUnitedStates;

  /// No description provided for @settingsFoodDbRegionFrance.
  ///
  /// In en, this message translates to:
  /// **'France (FR)'**
  String get settingsFoodDbRegionFrance;

  /// No description provided for @settingsFoodDbRegionItaly.
  ///
  /// In en, this message translates to:
  /// **'Italy (IT)'**
  String get settingsFoodDbRegionItaly;

  /// No description provided for @settingsFoodDbRegionJapan.
  ///
  /// In en, this message translates to:
  /// **'Japan (JP)'**
  String get settingsFoodDbRegionJapan;

  /// No description provided for @settingsFoodDbRegionAustria.
  ///
  /// In en, this message translates to:
  /// **'Austria (AT)'**
  String get settingsFoodDbRegionAustria;

  /// No description provided for @settingsColorfulMacroBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Colorful Macro Badges'**
  String get settingsColorfulMacroBadgesTitle;

  /// No description provided for @settingsColorfulMacroBadgesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses the color-coded badge design from AI verification in the diary as well.'**
  String get settingsColorfulMacroBadgesSubtitle;

  /// No description provided for @settingsFoodDbRegionUnitedKingdom.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom (UK)'**
  String get settingsFoodDbRegionUnitedKingdom;

  /// No description provided for @settingsFoodDbRegionChanged.
  ///
  /// In en, this message translates to:
  /// **'Food database region set to {region}. Changes apply on the next catalog refresh/import cycle.'**
  String settingsFoodDbRegionChanged(String region);

  /// No description provided for @searchBaseFoodHint.
  ///
  /// In en, this message translates to:
  /// **'Search base foods'**
  String get searchBaseFoodHint;

  /// No description provided for @searchNoHits.
  ///
  /// In en, this message translates to:
  /// **'No hits.'**
  String get searchNoHits;

  /// No description provided for @onbSubtitleWelcome.
  ///
  /// In en, this message translates to:
  /// **'Your central tool for fitness, nutrition & progress.'**
  String get onbSubtitleWelcome;

  /// No description provided for @onbBodyWelcome.
  ///
  /// In en, this message translates to:
  /// **'We help you set and track your goals. Efficiently log workouts, nutrition, supplements, and body measurements.'**
  String get onbBodyWelcome;

  /// No description provided for @onbBodyNutritionVisual.
  ///
  /// In en, this message translates to:
  /// **'Log meals with just a few clicks. Keep an eye on calories, macros, and water to effortlessly track your goal.'**
  String get onbBodyNutritionVisual;

  /// No description provided for @onbBodyMeasurementsVisual.
  ///
  /// In en, this message translates to:
  /// **'Visualize your progress. The weight and circumference chart makes your success visible and keeps you motivated.'**
  String get onbBodyMeasurementsVisual;

  /// No description provided for @onbBodyWorkoutVisual.
  ///
  /// In en, this message translates to:
  /// **'Create routines and start your training in seconds. Log sets, weights, and rests for maximum progression.'**
  String get onbBodyWorkoutVisual;

  /// No description provided for @onbTitleAppLayout.
  ///
  /// In en, this message translates to:
  /// **'Navigation & Quick-Add'**
  String get onbTitleAppLayout;

  /// No description provided for @onbBodyAppLayout.
  ///
  /// In en, this message translates to:
  /// **'The bottom bar allows quick switching between areas. Use the large [+] button to log everything instantly.'**
  String get onbBodyAppLayout;

  /// No description provided for @dataHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Hub'**
  String get dataHubTitle;

  /// No description provided for @resumeButton.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeButton;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Train Libre'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your profile to get the best results.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingMissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get onboardingMissionTitle;

  /// No description provided for @onboardingMissionBody.
  ///
  /// In en, this message translates to:
  /// **'Train Libre is for dedicated natural bodybuilders who demand science-based, data-driven progress.'**
  String get onboardingMissionBody;

  /// No description provided for @onboardingFeatureWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Tracker'**
  String get onboardingFeatureWorkoutTitle;

  /// No description provided for @onboardingFeatureWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'Log sets (RIR/RPE) and follow your muscle recovery.'**
  String get onboardingFeatureWorkoutBody;

  /// No description provided for @onboardingFeatureTdeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive TDEE'**
  String get onboardingFeatureTdeeTitle;

  /// No description provided for @onboardingFeatureTdeeBody.
  ///
  /// In en, this message translates to:
  /// **'An integrated Kalman filter calculates your real calorie expenditure.'**
  String get onboardingFeatureTdeeBody;

  /// No description provided for @onboardingFeatureNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition & Water'**
  String get onboardingFeatureNutritionTitle;

  /// No description provided for @onboardingFeatureNutritionBody.
  ///
  /// In en, this message translates to:
  /// **'Track macros, water, and use optional AI image recognition.'**
  String get onboardingFeatureNutritionBody;

  /// No description provided for @onboardingFeaturePrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'100% Private & Local'**
  String get onboardingFeaturePrivacyTitle;

  /// No description provided for @onboardingFeaturePrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'No accounts, no forced cloud. Your data belongs to you.'**
  String get onboardingFeaturePrivacyBody;

  /// No description provided for @onboardingSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'All settings can be changed later at any time in Settings.'**
  String get onboardingSettingsHint;

  /// No description provided for @adaptiveRatePerWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly Target Rate'**
  String get adaptiveRatePerWeekLabel;

  /// No description provided for @customTargetRateOption.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customTargetRateOption;

  /// No description provided for @customTargetRateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Custom Target Rate'**
  String get customTargetRateDialogTitle;

  /// No description provided for @onboardingNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onboardingNameTitle;

  /// No description provided for @onboardingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get onboardingNameLabel;

  /// No description provided for @onboardingNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get onboardingNameError;

  /// No description provided for @onboardingDobTitle.
  ///
  /// In en, this message translates to:
  /// **'When were you born?'**
  String get onboardingDobTitle;

  /// No description provided for @onboardingDobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get onboardingDobLabel;

  /// No description provided for @onboardingDobError.
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth'**
  String get onboardingDobError;

  /// No description provided for @onboardingWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get onboardingWeightTitle;

  /// No description provided for @onboardingWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get onboardingWeightLabel;

  /// No description provided for @onboardingWeightError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight'**
  String get onboardingWeightError;

  /// No description provided for @onboardingGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Nutrition Goals'**
  String get onboardingGoalsTitle;

  /// No description provided for @onboardingGoalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change these later in settings.'**
  String get onboardingGoalsSubtitle;

  /// No description provided for @onboardingGoalCalories.
  ///
  /// In en, this message translates to:
  /// **'Daily Calories (kcal)'**
  String get onboardingGoalCalories;

  /// No description provided for @onboardingGoalProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get onboardingGoalProtein;

  /// No description provided for @onboardingGoalCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get onboardingGoalCarbs;

  /// No description provided for @onboardingGoalFat.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get onboardingGoalFat;

  /// No description provided for @onboardingGoalWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get onboardingGoalWater;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Start Tracking'**
  String get onboardingFinish;

  /// No description provided for @onboardingAiHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'AI & Health'**
  String get onboardingAiHealthTitle;

  /// No description provided for @onboardingAiHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional setup: configure AI meal capture with BYOK (Bring Your Own Key) and choose which health data Train Libre may read.'**
  String get onboardingAiHealthSubtitle;

  /// No description provided for @onboardingOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get onboardingOpenSettings;

  /// No description provided for @onboardingUnitSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your Unit System'**
  String get onboardingUnitSystemTitle;

  /// No description provided for @onboardingUnitSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get onboardingUnitSystemSubtitle;

  /// No description provided for @onboardingUnitMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get onboardingUnitMetric;

  /// No description provided for @onboardingUnitMetricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'kg, cm, ml'**
  String get onboardingUnitMetricSubtitle;

  /// No description provided for @onboardingUnitImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get onboardingUnitImperial;

  /// No description provided for @onboardingUnitImperialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'lbs, in, fl oz'**
  String get onboardingUnitImperialSubtitle;

  /// No description provided for @onboardingHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get onboardingHeightLabel;

  /// No description provided for @onboardingGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get onboardingGenderLabel;

  /// No description provided for @onboardingBioDataInfo.
  ///
  /// In en, this message translates to:
  /// **'Your age and biological sex determine the baseline recovery windows of your muscle recovery model and feed into the algorithms of your Sleep Health Engine.'**
  String get onboardingBioDataInfo;

  /// No description provided for @onboardingFieldCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'This field cannot be empty.'**
  String get onboardingFieldCannotBeEmpty;

  /// No description provided for @onboardingPhysiologicalRangeWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: This value is outside the expected physiological range. Our sports-science analytics and heuristic engines are not calibrated for extreme metrics. If this value is intentional, click \'Next\' again to proceed anyway.'**
  String get onboardingPhysiologicalRangeWarning;

  /// No description provided for @onboardingMeasurementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Measurements & Baseline'**
  String get onboardingMeasurementsTitle;

  /// No description provided for @onboardingMeasurementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your current baseline for the adaptive recommendation.'**
  String get onboardingMeasurementsSubtitle;

  /// No description provided for @onboardingMeasurementsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'You can enter and log your weight, body fat, and other measurements at any time in the dashboard.'**
  String get onboardingMeasurementsDisclaimer;

  /// No description provided for @onboardingWaterNeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Water need ({unit})'**
  String onboardingWaterNeedLabel(String unit);

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderDiverse.
  ///
  /// In en, this message translates to:
  /// **'Diverse'**
  String get genderDiverse;

  /// No description provided for @vegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get vegan;

  /// No description provided for @vegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get vegetarian;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @aiSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Meal Capture'**
  String get aiSettingsTitle;

  /// No description provided for @aiSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Configure AI-powered meal recognition.'**
  String get aiSettingsDescription;

  /// No description provided for @aiProviderSection.
  ///
  /// In en, this message translates to:
  /// **'AI Provider'**
  String get aiProviderSection;

  /// No description provided for @aiProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get aiProviderLabel;

  /// No description provided for @aiApiKeySection.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get aiApiKeySection;

  /// No description provided for @aiApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get aiApiKeyLabel;

  /// No description provided for @aiApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your API key here'**
  String get aiApiKeyHint;

  /// No description provided for @aiSaveKey.
  ///
  /// In en, this message translates to:
  /// **'Save Key'**
  String get aiSaveKey;

  /// No description provided for @aiTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get aiTestConnection;

  /// No description provided for @aiTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get aiTestSuccess;

  /// No description provided for @aiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API key saved securely.'**
  String get aiKeySaved;

  /// No description provided for @aiPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get aiPrivacySection;

  /// No description provided for @aiPrivacyDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Images, text, and generated prompts are sent to the selected AI provider only when you use an AI action. Provider retention and processing follow that provider\'s terms. Your API key is stored encrypted on this device only.'**
  String get aiPrivacyDisclosure;

  /// No description provided for @aiMealCapture.
  ///
  /// In en, this message translates to:
  /// **'AI Meal'**
  String get aiMealCapture;

  /// No description provided for @aiCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Meal Capture'**
  String get aiCaptureTitle;

  /// No description provided for @aiCaptureTabPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get aiCaptureTabPhoto;

  /// No description provided for @aiCaptureTabText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get aiCaptureTabText;

  /// No description provided for @aiCapturePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Take or select up to 4 photos of your meal.'**
  String get aiCapturePhotoHint;

  /// No description provided for @aiCaptureTextHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your meal (e.g. \"Grilled chicken with rice and salad\")...'**
  String get aiCaptureTextHint;

  /// No description provided for @aiAnalyzeButton.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get aiAnalyzeButton;

  /// No description provided for @aiAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your meal...'**
  String get aiAnalyzing;

  /// No description provided for @aiReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Suggestions'**
  String get aiReviewTitle;

  /// No description provided for @aiReviewFoundItems.
  ///
  /// In en, this message translates to:
  /// **'AI found {count} items'**
  String aiReviewFoundItems(int count);

  /// No description provided for @aiReviewNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match — tap to search'**
  String get aiReviewNoMatch;

  /// No description provided for @aiReviewUncertain.
  ///
  /// In en, this message translates to:
  /// **'Unsure ({percent}%)'**
  String aiReviewUncertain(int percent);

  /// No description provided for @aiReviewConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get aiReviewConfidence;

  /// No description provided for @aiReviewAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item manually'**
  String get aiReviewAddItem;

  /// No description provided for @aiReviewReplaceItem.
  ///
  /// In en, this message translates to:
  /// **'Replace item'**
  String get aiReviewReplaceItem;

  /// No description provided for @aiReviewSaveToDiary.
  ///
  /// In en, this message translates to:
  /// **'Save to Diary'**
  String get aiReviewSaveToDiary;

  /// No description provided for @aiReviewFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what the AI got wrong...'**
  String get aiReviewFeedbackHint;

  /// No description provided for @aiReviewRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry with Feedback'**
  String get aiReviewRetryButton;

  /// No description provided for @aiReviewFeedbackSection.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get aiReviewFeedbackSection;

  /// No description provided for @aiErrorNoKey.
  ///
  /// In en, this message translates to:
  /// **'No API key configured. Please set one in Settings → AI Meal Capture.'**
  String get aiErrorNoKey;

  /// No description provided for @aiErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection and try again.'**
  String get aiErrorNetwork;

  /// No description provided for @aiErrorAuth.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please check your API key.'**
  String get aiErrorAuth;

  /// No description provided for @aiErrorParse.
  ///
  /// In en, this message translates to:
  /// **'Could not understand the AI response. Please try again.'**
  String get aiErrorParse;

  /// No description provided for @aiErrorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment.'**
  String get aiErrorRateLimit;

  /// No description provided for @aiEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable AI Features'**
  String get aiEnableTitle;

  /// No description provided for @aiEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allows the use of AI for meal recognition. Disabling this hides all AI buttons in the app.'**
  String get aiEnableSubtitle;

  /// No description provided for @aiCustomInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Global AI Instructions'**
  String get aiCustomInstructionsTitle;

  /// No description provided for @aiCustomInstructionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Give the AI fixed rules (e.g., allergies, no-go foods like \'no bowls\', or intolerances) to be followed with every capture.'**
  String get aiCustomInstructionsSubtitle;

  /// No description provided for @aiValidationNoMatchedItemsSaveYet.
  ///
  /// In en, this message translates to:
  /// **'No matched items can be saved yet.'**
  String get aiValidationNoMatchedItemsSaveYet;

  /// No description provided for @aiValidationNoMatchedIngredientsSaveYet.
  ///
  /// In en, this message translates to:
  /// **'No matched ingredients can be saved yet.'**
  String get aiValidationNoMatchedIngredientsSaveYet;

  /// No description provided for @aiValidationSomeItemsNeedReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Some items need review'**
  String get aiValidationSomeItemsNeedReviewTitle;

  /// No description provided for @aiValidationSomeIngredientsNeedReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Some ingredients need review'**
  String get aiValidationSomeIngredientsNeedReviewTitle;

  /// No description provided for @aiValidationSaveMatchedItemsButton.
  ///
  /// In en, this message translates to:
  /// **'Save matched items'**
  String get aiValidationSaveMatchedItemsButton;

  /// No description provided for @aiValidationSaveMatchedIngredientsButton.
  ///
  /// In en, this message translates to:
  /// **'Save matched ingredients'**
  String get aiValidationSaveMatchedIngredientsButton;

  /// No description provided for @aiValidationValidationPassedTitle.
  ///
  /// In en, this message translates to:
  /// **'Validation passed'**
  String get aiValidationValidationPassedTitle;

  /// No description provided for @aiValidationReviewSuggestedTitle.
  ///
  /// In en, this message translates to:
  /// **'Review suggested'**
  String get aiValidationReviewSuggestedTitle;

  /// No description provided for @aiValidationMacroFitValidatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Macro fit validated'**
  String get aiValidationMacroFitValidatedTitle;

  /// No description provided for @aiValidationNeedsReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get aiValidationNeedsReviewTitle;

  /// No description provided for @aiValidationRepairLimitReachedReview.
  ///
  /// In en, this message translates to:
  /// **'Automatic repair limit reached. Please review before saving.'**
  String get aiValidationRepairLimitReachedReview;

  /// No description provided for @aiValidationRecentMealContextIncluded.
  ///
  /// In en, this message translates to:
  /// **'Recent meal context was included.'**
  String get aiValidationRecentMealContextIncluded;

  /// No description provided for @aiValidationGeneratedWithoutRecentMealHistory.
  ///
  /// In en, this message translates to:
  /// **'Generated without recent meal history.'**
  String get aiValidationGeneratedWithoutRecentMealHistory;

  /// No description provided for @aiValidationApiKeyRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'API Key Required'**
  String get aiValidationApiKeyRequiredTitle;

  /// No description provided for @aiValidationScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score {score}/100'**
  String aiValidationScoreLabel(int score);

  /// No description provided for @aiValidationDeltaSummary.
  ///
  /// In en, this message translates to:
  /// **'Delta: {kcalDelta} kcal · {proteinDelta}g Protein · {carbsDelta}g Carbs · {fatDelta}g Fat'**
  String aiValidationDeltaSummary(
      int kcalDelta, int proteinDelta, int carbsDelta, int fatDelta);

  /// No description provided for @aiValidationPartialSaveItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'{unmatchedCount, plural, =1{1 item does not have a local database match and will not be saved.} other{{unmatchedCount} items do not have a local database match and will not be saved.}} Save the {matchedCount} matched item(s) only?'**
  String aiValidationPartialSaveItemsMessage(
      int unmatchedCount, int matchedCount);

  /// No description provided for @aiValidationPartialSaveIngredientsMessage.
  ///
  /// In en, this message translates to:
  /// **'{unmatchedCount, plural, =1{1 ingredient does not have a local database match and will not be saved.} other{{unmatchedCount} ingredients do not have a local database match and will not be saved.}} Save the {matchedCount} matched ingredient(s) only?'**
  String aiValidationPartialSaveIngredientsMessage(
      int unmatchedCount, int matchedCount);

  /// No description provided for @aiValidationEmptyItemName.
  ///
  /// In en, this message translates to:
  /// **'An item has no food name.'**
  String get aiValidationEmptyItemName;

  /// No description provided for @aiValidationDuplicateItemMerged.
  ///
  /// In en, this message translates to:
  /// **'Duplicate \"{name}\" entries were merged before validation.'**
  String aiValidationDuplicateItemMerged(String name);

  /// No description provided for @aiValidationInvalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than 0g.'**
  String get aiValidationInvalidQuantity;

  /// No description provided for @aiValidationTinyQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity is very small; review the gram amount.'**
  String get aiValidationTinyQuantity;

  /// No description provided for @aiValidationExtremeQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity is implausibly high for one meal item.'**
  String get aiValidationExtremeQuantity;

  /// No description provided for @aiValidationLargeQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity is unusually large; review the gram amount.'**
  String get aiValidationLargeQuantity;

  /// No description provided for @aiValidationLowAiConfidence.
  ///
  /// In en, this message translates to:
  /// **'AI confidence is low for this item.'**
  String get aiValidationLowAiConfidence;

  /// No description provided for @aiValidationUnmatchedItem.
  ///
  /// In en, this message translates to:
  /// **'No local database match was found.'**
  String get aiValidationUnmatchedItem;

  /// No description provided for @aiValidationWeakDbMatch.
  ///
  /// In en, this message translates to:
  /// **'The local database match is weak.'**
  String get aiValidationWeakDbMatch;

  /// No description provided for @aiValidationPartialDbMatch.
  ///
  /// In en, this message translates to:
  /// **'The local database match is partial.'**
  String get aiValidationPartialDbMatch;

  /// No description provided for @aiValidationAmbiguousDbMatch.
  ///
  /// In en, this message translates to:
  /// **'Several local database matches look similarly plausible.'**
  String get aiValidationAmbiguousDbMatch;

  /// No description provided for @aiValidationStateMismatch.
  ///
  /// In en, this message translates to:
  /// **'The AI item state may not match the database entry.'**
  String get aiValidationStateMismatch;

  /// No description provided for @aiValidationZeroNutritionMatch.
  ///
  /// In en, this message translates to:
  /// **'The matched database entry has no usable nutrition data.'**
  String get aiValidationZeroNutritionMatch;

  /// No description provided for @aiValidationImplausibleFoodDensity.
  ///
  /// In en, this message translates to:
  /// **'Matched food has unusually high kcal per 100g.'**
  String get aiValidationImplausibleFoodDensity;

  /// No description provided for @aiValidationMacroEnergyMismatch.
  ///
  /// In en, this message translates to:
  /// **'Matched food macros do not align well with kcal.'**
  String get aiValidationMacroEnergyMismatch;

  /// No description provided for @aiValidationImplausibleItemNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition for this quantity is unusually high.'**
  String get aiValidationImplausibleItemNutrition;

  /// No description provided for @aiValidationEmptyMeal.
  ///
  /// In en, this message translates to:
  /// **'The AI returned no meal items.'**
  String get aiValidationEmptyMeal;

  /// No description provided for @aiValidationAllItemsUnmatched.
  ///
  /// In en, this message translates to:
  /// **'No item could be matched to the local food database.'**
  String get aiValidationAllItemsUnmatched;

  /// No description provided for @aiValidationPartialUnmatchedItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item cannot be saved until matched.} other{{count} items cannot be saved until matched.}}'**
  String aiValidationPartialUnmatchedItems(int count);

  /// No description provided for @aiValidationZeroTotalKcal.
  ///
  /// In en, this message translates to:
  /// **'Matched items produce 0 kcal.'**
  String get aiValidationZeroTotalKcal;

  /// No description provided for @aiValidationCaptureTotalKcalExtreme.
  ///
  /// In en, this message translates to:
  /// **'Total kcal is implausibly high for one captured meal.'**
  String get aiValidationCaptureTotalKcalExtreme;

  /// No description provided for @aiValidationCaptureTotalKcalHigh.
  ///
  /// In en, this message translates to:
  /// **'Total kcal is unusually high; review portions.'**
  String get aiValidationCaptureTotalKcalHigh;

  /// No description provided for @aiValidationMacroTotalExtreme.
  ///
  /// In en, this message translates to:
  /// **'Total macros are implausibly high.'**
  String get aiValidationMacroTotalExtreme;

  /// No description provided for @aiValidationMacroTotalHigh.
  ///
  /// In en, this message translates to:
  /// **'Total macros are unusually high; review portions.'**
  String get aiValidationMacroTotalHigh;

  /// No description provided for @aiValidationTargetKcalMismatch.
  ///
  /// In en, this message translates to:
  /// **'Calories miss the target by {delta} kcal.'**
  String aiValidationTargetKcalMismatch(int delta);

  /// No description provided for @aiValidationTargetProteinMismatch.
  ///
  /// In en, this message translates to:
  /// **'Protein misses the target by {delta}g.'**
  String aiValidationTargetProteinMismatch(int delta);

  /// No description provided for @aiValidationTargetCarbsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Carbs miss the target by {delta}g.'**
  String aiValidationTargetCarbsMismatch(int delta);

  /// No description provided for @aiValidationTargetFatMismatch.
  ///
  /// In en, this message translates to:
  /// **'Fat misses the target by {delta}g.'**
  String aiValidationTargetFatMismatch(int delta);

  /// No description provided for @aiValidationUnknownIssue.
  ///
  /// In en, this message translates to:
  /// **'Validation issue: {code}'**
  String aiValidationUnknownIssue(String code);

  /// No description provided for @currentlyTracking.
  ///
  /// In en, this message translates to:
  /// **'Currently'**
  String get currentlyTracking;

  /// No description provided for @currentlyTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Show in daily tracker hub'**
  String get currentlyTrackingDesc;

  /// No description provided for @filter3Months.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get filter3Months;

  /// No description provided for @filter6Months.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get filter6Months;

  /// No description provided for @sectionConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency & Frequency'**
  String get sectionConsistency;

  /// No description provided for @metricsWorkoutsWeek.
  ///
  /// In en, this message translates to:
  /// **'Workouts (Week)'**
  String get metricsWorkoutsWeek;

  /// No description provided for @metricsCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get metricsCurrentStreak;

  /// No description provided for @metricsActiveWeeks.
  ///
  /// In en, this message translates to:
  /// **'weeks active'**
  String get metricsActiveWeeks;

  /// No description provided for @placeholderCalendarHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Calendar Heatmap Visual'**
  String get placeholderCalendarHeatmap;

  /// No description provided for @consistencyTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Consistency Tracker'**
  String get consistencyTrackerTitle;

  /// No description provided for @consistencyTrackerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Consistency & Habit Tracker (Coming Soon)'**
  String get consistencyTrackerComingSoon;

  /// No description provided for @sectionMuscleVolume.
  ///
  /// In en, this message translates to:
  /// **'Muscle Groups & Volume'**
  String get sectionMuscleVolume;

  /// No description provided for @metricsTopTrained.
  ///
  /// In en, this message translates to:
  /// **'Top Trained'**
  String get metricsTopTrained;

  /// No description provided for @metricsMostNeglected.
  ///
  /// In en, this message translates to:
  /// **'Most Neglected'**
  String get metricsMostNeglected;

  /// No description provided for @placeholderMuscleHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Muscle Heatmap Visual'**
  String get placeholderMuscleHeatmap;

  /// No description provided for @muscleAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Muscle Group Analytics'**
  String get muscleAnalyticsTitle;

  /// No description provided for @muscleAnalyticsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Muscle Volume & Heatmaps (Coming Soon)'**
  String get muscleAnalyticsComingSoon;

  /// No description provided for @sectionPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance & PRs'**
  String get sectionPerformance;

  /// No description provided for @metricsRecentPrs.
  ///
  /// In en, this message translates to:
  /// **'Recent PRs'**
  String get metricsRecentPrs;

  /// No description provided for @metricsVolumeLifted.
  ///
  /// In en, this message translates to:
  /// **'Volume Lifted'**
  String get metricsVolumeLifted;

  /// No description provided for @metricsMostImproved.
  ///
  /// In en, this message translates to:
  /// **'Most Improved'**
  String get metricsMostImproved;

  /// No description provided for @exerciseAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise Analytics'**
  String get exerciseAnalyticsTitle;

  /// No description provided for @exerciseAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search and analyze specific exercises'**
  String get exerciseAnalyticsSubtitle;

  /// No description provided for @prDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'PR Dashboard'**
  String get prDashboardTitle;

  /// No description provided for @prDashboardComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Records & Progress (Coming Soon)'**
  String get prDashboardComingSoon;

  /// No description provided for @exerciseAnalyticsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Exercise search & specific trends (Coming Soon)'**
  String get exerciseAnalyticsComingSoon;

  /// No description provided for @sectionRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get sectionRecovery;

  /// No description provided for @metricsMuscleReadiness.
  ///
  /// In en, this message translates to:
  /// **'Muscle Readiness'**
  String get metricsMuscleReadiness;

  /// No description provided for @recoveryTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Tracker'**
  String get recoveryTrackerTitle;

  /// No description provided for @recoveryTrackerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Muscle readiness & fatigue (Coming Soon)'**
  String get recoveryTrackerComingSoon;

  /// No description provided for @recoveryOverallMostlyRecovered.
  ///
  /// In en, this message translates to:
  /// **'Mostly recovered'**
  String get recoveryOverallMostlyRecovered;

  /// No description provided for @recoveryOverallMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed recovery state'**
  String get recoveryOverallMixed;

  /// No description provided for @recoveryOverallSeveralRecovering.
  ///
  /// In en, this message translates to:
  /// **'Several muscle groups still recovering'**
  String get recoveryOverallSeveralRecovering;

  /// No description provided for @recoveryOverallInsufficientData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for recovery insight yet'**
  String get recoveryOverallInsufficientData;

  /// No description provided for @recoveryHubCountsSummary.
  ///
  /// In en, this message translates to:
  /// **'Recovering: {recovering}  Ready: {ready}  Fresh: {fresh}'**
  String recoveryHubCountsSummary(int recovering, int ready, int fresh);

  /// No description provided for @recoveryHubNoDataSummary.
  ///
  /// In en, this message translates to:
  /// **'Keep logging workouts to unlock recovery insights.'**
  String get recoveryHubNoDataSummary;

  /// No description provided for @recoveryByMuscleTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery by Muscle'**
  String get recoveryByMuscleTitle;

  /// No description provided for @recoveryStateRecovering.
  ///
  /// In en, this message translates to:
  /// **'Recovering'**
  String get recoveryStateRecovering;

  /// No description provided for @recoveryStateReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get recoveryStateReady;

  /// No description provided for @recoveryStateFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get recoveryStateFresh;

  /// No description provided for @recoveryStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get recoveryStateUnknown;

  /// No description provided for @recoveryLastLoadedHours.
  ///
  /// In en, this message translates to:
  /// **'Last significantly loaded: {hours} h ago'**
  String recoveryLastLoadedHours(int hours);

  /// No description provided for @recoveryFatigueContextHigh.
  ///
  /// In en, this message translates to:
  /// **'Fatigue context: high session fatigue'**
  String get recoveryFatigueContextHigh;

  /// No description provided for @recoveryFatigueContextBaseline.
  ///
  /// In en, this message translates to:
  /// **'Fatigue context: baseline session fatigue'**
  String get recoveryFatigueContextBaseline;

  /// No description provided for @recoveryExplanationWithHighFatigue.
  ///
  /// In en, this message translates to:
  /// **'{muscle}: last significantly loaded {hours} h ago, with high session fatigue.'**
  String recoveryExplanationWithHighFatigue(String muscle, int hours);

  /// No description provided for @recoveryExplanationBasic.
  ///
  /// In en, this message translates to:
  /// **'{muscle}: last significantly loaded {hours} h ago.'**
  String recoveryExplanationBasic(String muscle, int hours);

  /// No description provided for @recoveryHeuristicDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is a conservative heuristic based on recent significant loading and session effort. It is not a medical recovery measurement.'**
  String get recoveryHeuristicDisclaimer;

  /// No description provided for @recoveryReadinessLabel.
  ///
  /// In en, this message translates to:
  /// **'Readiness'**
  String get recoveryReadinessLabel;

  /// No description provided for @recoveryRecentLoad.
  ///
  /// In en, this message translates to:
  /// **'Last load: {sets} equivalent sets'**
  String recoveryRecentLoad(String sets);

  /// No description provided for @recoveryLastLoadPressure.
  ///
  /// In en, this message translates to:
  /// **'Last load pressure: {level}'**
  String recoveryLastLoadPressure(String level);

  /// No description provided for @recoveryPressureLow.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get recoveryPressureLow;

  /// No description provided for @recoveryPressureModerate.
  ///
  /// In en, this message translates to:
  /// **'moderate'**
  String get recoveryPressureModerate;

  /// No description provided for @recoveryPressureHigh.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get recoveryPressureHigh;

  /// No description provided for @recoveryPressureVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'very high'**
  String get recoveryPressureVeryHigh;

  /// No description provided for @recoveryCurrentWindow.
  ///
  /// In en, this message translates to:
  /// **'Current window: recovering until about {recoveringUpper} h, ready until about {readyUpper} h.'**
  String recoveryCurrentWindow(int recoveringUpper, int readyUpper);

  /// No description provided for @recoveryWindowHeuristic.
  ///
  /// In en, this message translates to:
  /// **'Current window: recovering until about {from} h, ready until about {to} h.'**
  String recoveryWindowHeuristic(int from, int to);

  /// No description provided for @recoveryRadarHeuristicCaption.
  ///
  /// In en, this message translates to:
  /// **'Radar overview of current readiness by muscle. Status badges remain the primary signal.'**
  String get recoveryRadarHeuristicCaption;

  /// No description provided for @recoveryNoDataBody.
  ///
  /// In en, this message translates to:
  /// **'Not enough significant training load has been logged yet to estimate muscle recovery.'**
  String get recoveryNoDataBody;

  /// No description provided for @sectionBodyNutrition.
  ///
  /// In en, this message translates to:
  /// **'Body & Nutrition'**
  String get sectionBodyNutrition;

  /// No description provided for @statisticsSectionTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get statisticsSectionTraining;

  /// No description provided for @statisticsSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get statisticsSectionBody;

  /// No description provided for @statisticsEnableStepTrackingHint.
  ///
  /// In en, this message translates to:
  /// **'Enable step tracking in Settings'**
  String get statisticsEnableStepTrackingHint;

  /// No description provided for @statisticsNoStepDataYet.
  ///
  /// In en, this message translates to:
  /// **'No step data yet'**
  String get statisticsNoStepDataYet;

  /// No description provided for @statisticsTotalSteps.
  ///
  /// In en, this message translates to:
  /// **'Total steps'**
  String get statisticsTotalSteps;

  /// No description provided for @statisticsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get statisticsLast7Days;

  /// No description provided for @statisticsLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get statisticsLast30Days;

  /// No description provided for @statisticsLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get statisticsLast3Months;

  /// No description provided for @statisticsLast6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get statisticsLast6Months;

  /// No description provided for @metricsCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get metricsCurrentWeight;

  /// No description provided for @metricsAvgCalories.
  ///
  /// In en, this message translates to:
  /// **'Avg. Calories'**
  String get metricsAvgCalories;

  /// No description provided for @placeholderWeightTrend.
  ///
  /// In en, this message translates to:
  /// **'Weight Trend Line Chart'**
  String get placeholderWeightTrend;

  /// No description provided for @exerciseAnalyticsPrsLabel.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL RECORDS'**
  String get exerciseAnalyticsPrsLabel;

  /// No description provided for @exerciseAnalyticsTrendsLabel.
  ///
  /// In en, this message translates to:
  /// **'TRENDS'**
  String get exerciseAnalyticsTrendsLabel;

  /// No description provided for @exerciseAnalyticsNoData.
  ///
  /// In en, this message translates to:
  /// **'No tracking data for this exercise.'**
  String get exerciseAnalyticsNoData;

  /// No description provided for @exerciseAnalyticsNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data'**
  String get exerciseAnalyticsNotEnoughData;

  /// No description provided for @exerciseAnalyticsChartWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight Over Time (kg)'**
  String get exerciseAnalyticsChartWeight;

  /// No description provided for @exerciseAnalyticsChartVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume Over Time (kg)'**
  String get exerciseAnalyticsChartVolume;

  /// No description provided for @exerciseAnalyticsChartSets.
  ///
  /// In en, this message translates to:
  /// **'Sets Over Time'**
  String get exerciseAnalyticsChartSets;

  /// No description provided for @exerciseMetricMaxWeight.
  ///
  /// In en, this message translates to:
  /// **'Max Weight'**
  String get exerciseMetricMaxWeight;

  /// No description provided for @exerciseMetricVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get exerciseMetricVolume;

  /// No description provided for @exerciseMetricEst1RM.
  ///
  /// In en, this message translates to:
  /// **'Est. 1RM'**
  String get exerciseMetricEst1RM;

  /// No description provided for @exerciseMetricDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get exerciseMetricDistance;

  /// No description provided for @exerciseMetricDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get exerciseMetricDuration;

  /// No description provided for @exerciseMetricPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get exerciseMetricPace;

  /// No description provided for @prBannerBestMaxWeight.
  ///
  /// In en, this message translates to:
  /// **'Best Max Weight'**
  String get prBannerBestMaxWeight;

  /// No description provided for @prBannerBestVolumeSet.
  ///
  /// In en, this message translates to:
  /// **'Best Volume Set'**
  String get prBannerBestVolumeSet;

  /// No description provided for @prBannerBest1RM.
  ///
  /// In en, this message translates to:
  /// **'Best 1-Rep Max'**
  String get prBannerBest1RM;

  /// No description provided for @newPersonalRecordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Personal Record'**
  String get newPersonalRecordLabel;

  /// No description provided for @prBadgeTooltip.
  ///
  /// In en, this message translates to:
  /// **'New Personal Record!'**
  String get prBadgeTooltip;

  /// No description provided for @workoutSummaryNewRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'New Records'**
  String get workoutSummaryNewRecordsTitle;

  /// No description provided for @allTimeRecordsLabel.
  ///
  /// In en, this message translates to:
  /// **'All-Time Records'**
  String get allTimeRecordsLabel;

  /// No description provided for @recentActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivityLabel;

  /// No description provided for @prsByRepRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Best Set by Rep Range'**
  String get prsByRepRangeLabel;

  /// No description provided for @volumeAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Volume Analytics'**
  String get volumeAnalyticsTitle;

  /// No description provided for @weeklyTonnageLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly Tonnage'**
  String get weeklyTonnageLabel;

  /// No description provided for @volumeByMuscleLabel.
  ///
  /// In en, this message translates to:
  /// **'By Muscle Group'**
  String get volumeByMuscleLabel;

  /// No description provided for @topExercisesLabel.
  ///
  /// In en, this message translates to:
  /// **'Top Exercises'**
  String get topExercisesLabel;

  /// No description provided for @thisWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeekLabel;

  /// No description provided for @avgPerWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg / Week'**
  String get avgPerWeekLabel;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streakLabel;

  /// No description provided for @trainingCalendarLabel.
  ///
  /// In en, this message translates to:
  /// **'Training Calendar'**
  String get trainingCalendarLabel;

  /// No description provided for @workoutsPerWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Workouts per Week'**
  String get workoutsPerWeekLabel;

  /// No description provided for @totalWorkoutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalWorkoutsLabel;

  /// No description provided for @weeksLabel.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get weeksLabel;

  /// No description provided for @tonnageKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Tonnage (kg)'**
  String get tonnageKgLabel;

  /// No description provided for @noWorkoutDataLabel.
  ///
  /// In en, this message translates to:
  /// **'No workout data yet. Start logging to see stats.'**
  String get noWorkoutDataLabel;

  /// No description provided for @analyticsSectionVolumeMuscles.
  ///
  /// In en, this message translates to:
  /// **'Volume & Muscle Groups'**
  String get analyticsSectionVolumeMuscles;

  /// No description provided for @analyticsSectionPerformanceRecords.
  ///
  /// In en, this message translates to:
  /// **'Performance & Records'**
  String get analyticsSectionPerformanceRecords;

  /// No description provided for @analyticsTopVolume.
  ///
  /// In en, this message translates to:
  /// **'Top Trained'**
  String get analyticsTopVolume;

  /// No description provided for @analyticsLowestVolume.
  ///
  /// In en, this message translates to:
  /// **'Lowest Volume'**
  String get analyticsLowestVolume;

  /// No description provided for @analyticsRecentRecords.
  ///
  /// In en, this message translates to:
  /// **'Recent Records'**
  String get analyticsRecentRecords;

  /// No description provided for @analyticsPerfWithReps.
  ///
  /// In en, this message translates to:
  /// **'{weight} {unit} x {reps}'**
  String analyticsPerfWithReps(String weight, int reps, Object unit);

  /// No description provided for @analyticsKgThisWeek.
  ///
  /// In en, this message translates to:
  /// **'kg (this week)'**
  String get analyticsKgThisWeek;

  /// No description provided for @analyticsRecoverySummary.
  ///
  /// In en, this message translates to:
  /// **'3 recovering, 8 ready'**
  String get analyticsRecoverySummary;

  /// No description provided for @analyticsViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get analyticsViewDetails;

  /// No description provided for @analyticsRepRangeSuffix.
  ///
  /// In en, this message translates to:
  /// **' reps'**
  String get analyticsRepRangeSuffix;

  /// No description provided for @analyticsNoRecordYet.
  ///
  /// In en, this message translates to:
  /// **'No record yet'**
  String get analyticsNoRecordYet;

  /// No description provided for @analyticsNoRecordsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No personal bests in this period'**
  String get analyticsNoRecordsInPeriod;

  /// No description provided for @analyticsNotableImprovements.
  ///
  /// In en, this message translates to:
  /// **'Notable Improvements'**
  String get analyticsNotableImprovements;

  /// No description provided for @analyticsNoPrTrendInWindow.
  ///
  /// In en, this message translates to:
  /// **'There is no clear PR trend in this window yet.'**
  String get analyticsNoPrTrendInWindow;

  /// No description provided for @analyticsE1rmProgress.
  ///
  /// In en, this message translates to:
  /// **'e1RM {previous} -> {recent} {unit}'**
  String analyticsE1rmProgress(String previous, String recent, Object unit);

  /// No description provided for @analyticsUnitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get analyticsUnitKg;

  /// No description provided for @analyticsUnitSets.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get analyticsUnitSets;

  /// No description provided for @analyticsViewLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get analyticsViewLabel;

  /// No description provided for @analyticsViewWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get analyticsViewWeek;

  /// No description provided for @analyticsViewMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get analyticsViewMonth;

  /// No description provided for @analyticsViewByExercise.
  ///
  /// In en, this message translates to:
  /// **'By Exercise'**
  String get analyticsViewByExercise;

  /// No description provided for @analyticsViewByMuscle.
  ///
  /// In en, this message translates to:
  /// **'By Muscle Group'**
  String get analyticsViewByMuscle;

  /// No description provided for @analyticsMetricLabel.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get analyticsMetricLabel;

  /// No description provided for @analyticsMovedWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Moved Weight (kg)'**
  String get analyticsMovedWeightKg;

  /// No description provided for @analyticsWorkSets.
  ///
  /// In en, this message translates to:
  /// **'Work Sets'**
  String get analyticsWorkSets;

  /// No description provided for @analyticsVolumeContextWithSets.
  ///
  /// In en, this message translates to:
  /// **'Moved weight = weight x reps. Switch to work sets for count-based load.'**
  String get analyticsVolumeContextWithSets;

  /// No description provided for @analyticsVolumeContextTonnageOnly.
  ///
  /// In en, this message translates to:
  /// **'This view uses moved weight (weight x reps).'**
  String get analyticsVolumeContextTonnageOnly;

  /// No description provided for @analyticsKpisHeader.
  ///
  /// In en, this message translates to:
  /// **'KPIs'**
  String get analyticsKpisHeader;

  /// No description provided for @analyticsTrainingDaysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Training Days / Week'**
  String get analyticsTrainingDaysPerWeek;

  /// No description provided for @analyticsLast4Weeks.
  ///
  /// In en, this message translates to:
  /// **'last 4 weeks'**
  String get analyticsLast4Weeks;

  /// No description provided for @analyticsRhythm.
  ///
  /// In en, this message translates to:
  /// **'Rhythm'**
  String get analyticsRhythm;

  /// No description provided for @analyticsVsPrior4Weeks.
  ///
  /// In en, this message translates to:
  /// **'vs the previous 4 weeks'**
  String get analyticsVsPrior4Weeks;

  /// No description provided for @analyticsRollingConsistency.
  ///
  /// In en, this message translates to:
  /// **'Rolling Consistency'**
  String get analyticsRollingConsistency;

  /// No description provided for @analyticsWeeksAtLeast2Workouts.
  ///
  /// In en, this message translates to:
  /// **'weeks with at least 2 sessions'**
  String get analyticsWeeksAtLeast2Workouts;

  /// No description provided for @analyticsInTimeframe.
  ///
  /// In en, this message translates to:
  /// **'In timeframe'**
  String get analyticsInTimeframe;

  /// No description provided for @analyticsVsPriorPeriod.
  ///
  /// In en, this message translates to:
  /// **'vs prior period'**
  String get analyticsVsPriorPeriod;

  /// No description provided for @analyticsCalendarExplainer.
  ///
  /// In en, this message translates to:
  /// **'Color intensity reflects sessions per day, making this a true consistency map.'**
  String get analyticsCalendarExplainer;

  /// No description provided for @analyticsSelectDayPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a day to inspect session count.'**
  String get analyticsSelectDayPrompt;

  /// No description provided for @analyticsSelectedDayWorkouts.
  ///
  /// In en, this message translates to:
  /// **'{date}: {count} sessions'**
  String analyticsSelectedDayWorkouts(String date, int count);

  /// No description provided for @analyticsTotalSessions.
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get analyticsTotalSessions;

  /// No description provided for @analyticsPlaceholderWeightValue.
  ///
  /// In en, this message translates to:
  /// **'82.5'**
  String get analyticsPlaceholderWeightValue;

  /// No description provided for @analyticsPlaceholderWeightTrend.
  ///
  /// In en, this message translates to:
  /// **'kg (-0.5)'**
  String get analyticsPlaceholderWeightTrend;

  /// No description provided for @analyticsPlaceholderCaloriesValue.
  ///
  /// In en, this message translates to:
  /// **'2,450'**
  String get analyticsPlaceholderCaloriesValue;

  /// No description provided for @analyticsPlaceholderCaloriesUnit.
  ///
  /// In en, this message translates to:
  /// **'kcal/day'**
  String get analyticsPlaceholderCaloriesUnit;

  /// No description provided for @analyticsMuscleWeeklySets.
  ///
  /// In en, this message translates to:
  /// **'Weekly Sets'**
  String get analyticsMuscleWeeklySets;

  /// No description provided for @analyticsMuscleTopFrequency.
  ///
  /// In en, this message translates to:
  /// **'Top Frequency'**
  String get analyticsMuscleTopFrequency;

  /// No description provided for @analyticsPerWeekAbbrev.
  ///
  /// In en, this message translates to:
  /// **'wk'**
  String get analyticsPerWeekAbbrev;

  /// No description provided for @analyticsKeepTrackingUnlockInsights.
  ///
  /// In en, this message translates to:
  /// **'Keep tracking to unlock insights.'**
  String get analyticsKeepTrackingUnlockInsights;

  /// No description provided for @analyticsGuidanceNoClearWeakPoint.
  ///
  /// In en, this message translates to:
  /// **'Guidance: No clear weak point in this period.'**
  String get analyticsGuidanceNoClearWeakPoint;

  /// No description provided for @analyticsGuidanceLowerEmphasis.
  ///
  /// In en, this message translates to:
  /// **'Guidance: Lower recent emphasis on {muscles}.'**
  String analyticsGuidanceLowerEmphasis(String muscles);

  /// No description provided for @analyticsPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get analyticsPeriodLabel;

  /// No description provided for @analyticsEquivalentSetsExplainer.
  ///
  /// In en, this message translates to:
  /// **'Equivalent hard sets use primary x1.0 and secondary x0.3 weighting. Frequency counts only days reaching >= 1.0 equivalent sets.'**
  String get analyticsEquivalentSetsExplainer;

  /// No description provided for @analyticsWeeklySetsByMuscle.
  ///
  /// In en, this message translates to:
  /// **'Ø Weekly Sets by Muscle'**
  String get analyticsWeeklySetsByMuscle;

  /// No description provided for @analyticsFrequencyByMuscle.
  ///
  /// In en, this message translates to:
  /// **'Frequency by Muscle'**
  String get analyticsFrequencyByMuscle;

  /// No description provided for @analyticsRecentDistributionHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Recent Distribution Heatmap'**
  String get analyticsRecentDistributionHeatmap;

  /// No description provided for @analyticsRadarOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Radar Overview'**
  String get analyticsRadarOverviewTitle;

  /// No description provided for @analyticsRadarVolumeCaption.
  ///
  /// In en, this message translates to:
  /// **'Shows relative volume distribution across muscles for a quick at-a-glance summary.'**
  String get analyticsRadarVolumeCaption;

  /// No description provided for @analyticsGuidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Guidance'**
  String get analyticsGuidanceTitle;

  /// No description provided for @analyticsGuidanceDirectionalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is directional guidance based on your recent set distribution, not an absolute diagnosis.'**
  String get analyticsGuidanceDirectionalDisclaimer;

  /// No description provided for @analyticsGuidanceSoftenedDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Insights are intentionally softened until enough data is available.'**
  String get analyticsGuidanceSoftenedDisclaimer;

  /// No description provided for @analyticsWeekTotalEquivalentSets.
  ///
  /// In en, this message translates to:
  /// **'Ø {value} equivalent sets per week'**
  String analyticsWeekTotalEquivalentSets(String value);

  /// No description provided for @analyticsFrequencyRuleFooter.
  ///
  /// In en, this message translates to:
  /// **'Frequency counts only days where the muscle reached >= 1.0 equivalent sets.'**
  String get analyticsFrequencyRuleFooter;

  /// No description provided for @liveWorkoutE1rmCurrentSet.
  ///
  /// In en, this message translates to:
  /// **'e1RM {value} {unit}'**
  String liveWorkoutE1rmCurrentSet(String value, Object unit);

  /// No description provided for @liveWorkoutE1rmBestSession.
  ///
  /// In en, this message translates to:
  /// **'Best e1RM this session: {value} {unit}'**
  String liveWorkoutE1rmBestSession(String value, Object unit);

  /// No description provided for @liveWorkoutE1rmVsLastSession.
  ///
  /// In en, this message translates to:
  /// **'vs last session: {delta} {unit}'**
  String liveWorkoutE1rmVsLastSession(String delta, Object unit);

  /// No description provided for @bodyNutritionCorrelationTitle.
  ///
  /// In en, this message translates to:
  /// **'Body & Nutrition Trends'**
  String get bodyNutritionCorrelationTitle;

  /// No description provided for @metricsWeightChange.
  ///
  /// In en, this message translates to:
  /// **'Weight Change'**
  String get metricsWeightChange;

  /// No description provided for @analyticsKcalPerDay.
  ///
  /// In en, this message translates to:
  /// **'kcal/day'**
  String get analyticsKcalPerDay;

  /// No description provided for @analyticsDaysWithWeightData.
  ///
  /// In en, this message translates to:
  /// **'days with weight'**
  String get analyticsDaysWithWeightData;

  /// No description provided for @analyticsDayUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get analyticsDayUnitLabel;

  /// No description provided for @analyticsPerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get analyticsPerDayLabel;

  /// No description provided for @analyticsEffectiveRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective range'**
  String get analyticsEffectiveRangeLabel;

  /// No description provided for @analyticsAxisXLabel.
  ///
  /// In en, this message translates to:
  /// **'X'**
  String get analyticsAxisXLabel;

  /// No description provided for @analyticsAxisYLabel.
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get analyticsAxisYLabel;

  /// No description provided for @analyticsHighConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Higher-confidence pattern'**
  String get analyticsHighConfidenceLabel;

  /// No description provided for @analyticsLowConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Lower-confidence pattern'**
  String get analyticsLowConfidenceLabel;

  /// No description provided for @analyticsObservedPatternLabel.
  ///
  /// In en, this message translates to:
  /// **'Observed pattern'**
  String get analyticsObservedPatternLabel;

  /// No description provided for @analyticsBodyNutritionTrendContext.
  ///
  /// In en, this message translates to:
  /// **'Weight and calories over time'**
  String get analyticsBodyNutritionTrendContext;

  /// No description provided for @analyticsBodyNutritionTrendContextHint.
  ///
  /// In en, this message translates to:
  /// **'The chart scales each series to fit the same space; tooltips show raw {unit} and kcal values.'**
  String analyticsBodyNutritionTrendContextHint(Object unit);

  /// No description provided for @analyticsBodyNutritionNormalizedHint.
  ///
  /// In en, this message translates to:
  /// **'The chart scales weight and calories to fit the same space; tooltips show raw {unit} and kcal values.'**
  String analyticsBodyNutritionNormalizedHint(Object unit);

  /// No description provided for @analyticsBodyNutritionTotalWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Total weight ({unit})'**
  String analyticsBodyNutritionTotalWeightLabel(Object unit);

  /// No description provided for @analyticsBodyNutritionTotalCaloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total calories (kcal)'**
  String get analyticsBodyNutritionTotalCaloriesLabel;

  /// No description provided for @analyticsWeightTrendLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight ({unit})'**
  String analyticsWeightTrendLabel(String unit);

  /// No description provided for @analyticsCaloriesTrendLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get analyticsCaloriesTrendLabel;

  /// No description provided for @analyticsInterpretationTitle.
  ///
  /// In en, this message translates to:
  /// **'Interpretation'**
  String get analyticsInterpretationTitle;

  /// No description provided for @analyticsBodyNutritionConfidenceHighHint.
  ///
  /// In en, this message translates to:
  /// **'Data coverage in this range is strong enough for a more reliable pattern read.'**
  String get analyticsBodyNutritionConfidenceHighHint;

  /// No description provided for @analyticsBodyNutritionConfidenceModerateHint.
  ///
  /// In en, this message translates to:
  /// **'Data coverage is moderate. Trends are useful context, but keep logging for stronger confidence.'**
  String get analyticsBodyNutritionConfidenceModerateHint;

  /// No description provided for @analyticsBodyNutritionConfidenceLowHint.
  ///
  /// In en, this message translates to:
  /// **'Data coverage in this range is still limited, so treat this as early context.'**
  String get analyticsBodyNutritionConfidenceLowHint;

  /// No description provided for @analyticsBodyNutritionLowConfidenceNudge.
  ///
  /// In en, this message translates to:
  /// **'Keep logging weight and calories regularly to improve confidence.'**
  String get analyticsBodyNutritionLowConfidenceNudge;

  /// No description provided for @analyticsBodyNutritionInterpretationConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'Interpretation confidence: higher. Use this as trend context, not a direct cause statement.'**
  String get analyticsBodyNutritionInterpretationConfidenceHigh;

  /// No description provided for @analyticsBodyNutritionInterpretationConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Interpretation confidence: lower. Use this as an early pattern signal and keep tracking.'**
  String get analyticsBodyNutritionInterpretationConfidenceLow;

  /// No description provided for @analyticsCorrelationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This view provides trend context. It does not prove that calorie changes directly caused weight changes.'**
  String get analyticsCorrelationDisclaimer;

  /// No description provided for @analyticsInsightStableWeightCaloriesUp.
  ///
  /// In en, this message translates to:
  /// **'Weight trend is stable while average calories increased.'**
  String get analyticsInsightStableWeightCaloriesUp;

  /// No description provided for @analyticsInsightWeightUpCaloriesUp.
  ///
  /// In en, this message translates to:
  /// **'Weight is trending upward alongside higher average calorie intake.'**
  String get analyticsInsightWeightUpCaloriesUp;

  /// No description provided for @analyticsInsightCaloriesDownWeightStable.
  ///
  /// In en, this message translates to:
  /// **'Recent calorie reduction has not yet clearly changed the weight trend.'**
  String get analyticsInsightCaloriesDownWeightStable;

  /// No description provided for @analyticsInsightWeightDownCaloriesDown.
  ///
  /// In en, this message translates to:
  /// **'Weight is trending downward alongside lower average calorie intake.'**
  String get analyticsInsightWeightDownCaloriesDown;

  /// No description provided for @analyticsInsightMixedPattern.
  ///
  /// In en, this message translates to:
  /// **'Weight and calorie trends are mixed without a clear relationship yet.'**
  String get analyticsInsightMixedPattern;

  /// No description provided for @analyticsInsightNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough consistent data yet for a meaningful trend read.'**
  String get analyticsInsightNotEnoughData;

  /// No description provided for @analyticsModerateConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Moderate-confidence pattern'**
  String get analyticsModerateConfidenceLabel;

  /// No description provided for @analyticsInsufficientConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Insufficient data confidence'**
  String get analyticsInsufficientConfidenceLabel;

  /// No description provided for @analyticsTrendRising.
  ///
  /// In en, this message translates to:
  /// **'Rising'**
  String get analyticsTrendRising;

  /// No description provided for @analyticsTrendFalling.
  ///
  /// In en, this message translates to:
  /// **'Falling'**
  String get analyticsTrendFalling;

  /// No description provided for @analyticsTrendStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get analyticsTrendStable;

  /// No description provided for @analyticsTrendUnclear.
  ///
  /// In en, this message translates to:
  /// **'Unclear'**
  String get analyticsTrendUnclear;

  /// No description provided for @analyticsRelationshipAlignedCut.
  ///
  /// In en, this message translates to:
  /// **'Lower intake and falling bodyweight are aligned.'**
  String get analyticsRelationshipAlignedCut;

  /// No description provided for @analyticsRelationshipAlignedBulk.
  ///
  /// In en, this message translates to:
  /// **'Higher intake and rising bodyweight are aligned.'**
  String get analyticsRelationshipAlignedBulk;

  /// No description provided for @analyticsRelationshipStableMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Weight and intake look broadly stable.'**
  String get analyticsRelationshipStableMaintenance;

  /// No description provided for @analyticsRelationshipMixed.
  ///
  /// In en, this message translates to:
  /// **'Signals are mixed or delayed.'**
  String get analyticsRelationshipMixed;

  /// No description provided for @analyticsRelationshipInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Not enough consistent overlap to classify the pattern yet.'**
  String get analyticsRelationshipInsufficient;

  /// No description provided for @analyticsBasedOnDataCoverage.
  ///
  /// In en, this message translates to:
  /// **'Based on {weightDays} weigh-ins and {calorieDays} calorie days'**
  String analyticsBasedOnDataCoverage(int weightDays, int calorieDays);

  /// No description provided for @restTimerNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest finished'**
  String get restTimerNotificationTitle;

  /// No description provided for @restTimerNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your pause timer is over. Ready for the next set.'**
  String get restTimerNotificationBody;

  /// No description provided for @onboardingContinueSetup.
  ///
  /// In en, this message translates to:
  /// **'Set Up Profile'**
  String get onboardingContinueSetup;

  /// No description provided for @onboardingRestoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get onboardingRestoreFromBackup;

  /// No description provided for @onboardingRestoreImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing backup...'**
  String get onboardingRestoreImporting;

  /// No description provided for @onboardingRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully!'**
  String get onboardingRestoreSuccess;

  /// No description provided for @onboardingRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed. Please check the file and try again.'**
  String get onboardingRestoreFailed;

  /// No description provided for @onboardingRestoreFromICloud.
  ///
  /// In en, this message translates to:
  /// **'Restore from iCloud'**
  String get onboardingRestoreFromICloud;

  /// No description provided for @onboardingRestoreICloudSuccess.
  ///
  /// In en, this message translates to:
  /// **'iCloud backup restored successfully!'**
  String get onboardingRestoreICloudSuccess;

  /// No description provided for @onboardingRestoreICloudFailed.
  ///
  /// In en, this message translates to:
  /// **'iCloud restore failed. Check your connection and try again.'**
  String get onboardingRestoreICloudFailed;

  /// No description provided for @finishWorkoutTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout Title'**
  String get finishWorkoutTitleLabel;

  /// No description provided for @finishWorkoutNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get finishWorkoutNotesLabel;

  /// No description provided for @finishWorkoutNotesHint.
  ///
  /// In en, this message translates to:
  /// **'How did the workout go?'**
  String get finishWorkoutNotesHint;

  /// No description provided for @sleepSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepSectionTitle;

  /// No description provided for @sleepSectionSubtitleDayEntry.
  ///
  /// In en, this message translates to:
  /// **'Day overview and detail drill-downs'**
  String get sleepSectionSubtitleDayEntry;

  /// No description provided for @sleepSectionSubtitleAllEntry.
  ///
  /// In en, this message translates to:
  /// **'Sleep day, week, and month views are available from this entry'**
  String get sleepSectionSubtitleAllEntry;

  /// No description provided for @sleepScopeDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get sleepScopeDay;

  /// No description provided for @sleepScopeWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get sleepScopeWeek;

  /// No description provided for @sleepScopeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get sleepScopeMonth;

  /// No description provided for @sleepWeekSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Week summary'**
  String get sleepWeekSummaryTitle;

  /// No description provided for @sleepMonthSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Month summary'**
  String get sleepMonthSummaryTitle;

  /// No description provided for @sleepSleepWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep window'**
  String get sleepSleepWindowTitle;

  /// No description provided for @sleepDailyScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily score'**
  String get sleepDailyScoreTitle;

  /// No description provided for @sleepMonthDailyScoreStatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily score states'**
  String get sleepMonthDailyScoreStatesTitle;

  /// No description provided for @sleepMeanScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Mean score: {value}'**
  String sleepMeanScoreLabel(String value);

  /// No description provided for @sleepHubScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Sleep score'**
  String get sleepHubScoreLabel;

  /// No description provided for @sleepHubAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get sleepHubAverageLabel;

  /// No description provided for @sleepHubBedtimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get sleepHubBedtimeLabel;

  /// No description provided for @sleepHubInterruptionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Interruptions'**
  String get sleepHubInterruptionsLabel;

  /// No description provided for @sleepHubInterruptionsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} wake-ups, {duration} total'**
  String sleepHubInterruptionsSummary(int count, String duration);

  /// No description provided for @sleepWeekdayAvgDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekday avg duration: {value}'**
  String sleepWeekdayAvgDurationLabel(String value);

  /// No description provided for @sleepWeekendAvgDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekend avg duration: {value}'**
  String sleepWeekendAvgDurationLabel(String value);

  /// No description provided for @sleepWeekNoScoredNights.
  ///
  /// In en, this message translates to:
  /// **'No scored sleep nights available in this week yet.'**
  String get sleepWeekNoScoredNights;

  /// No description provided for @sleepMonthNoScoredNights.
  ///
  /// In en, this message translates to:
  /// **'No scored sleep nights available this month yet.'**
  String get sleepMonthNoScoredNights;

  /// No description provided for @sleepSettingsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepSettingsSectionTitle;

  /// No description provided for @sleepEnableTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable sleep tracking'**
  String get sleepEnableTrackingTitle;

  /// No description provided for @sleepEnableTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read sleep and overnight heart rate from Health Connect / HealthKit'**
  String get sleepEnableTrackingSubtitle;

  /// No description provided for @sleepHealthConnectionStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Health connection status'**
  String get sleepHealthConnectionStatusTitle;

  /// No description provided for @sleepRequestAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get sleepRequestAccessTitle;

  /// No description provided for @sleepRequestAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request or re-request sleep/heart-rate permissions'**
  String get sleepRequestAccessSubtitle;

  /// No description provided for @sleepImportNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Import sleep data now'**
  String get sleepImportNowTitle;

  /// No description provided for @sleepImportNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import all available sleep data (all time)'**
  String get sleepImportNowSubtitle;

  /// No description provided for @sleepRawImportsTitle.
  ///
  /// In en, this message translates to:
  /// **'View raw sleep imports'**
  String get sleepRawImportsTitle;

  /// No description provided for @sleepRawImportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show recent Health Connect payloads'**
  String get sleepRawImportsSubtitle;

  /// No description provided for @sleepDataStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Data status'**
  String get sleepDataStatusTitle;

  /// No description provided for @sleepDataStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions granted. If no sleep appears yet, run a manual import below.'**
  String get sleepDataStatusSubtitle;

  /// No description provided for @sleepDataStatusSubtitleIos.
  ///
  /// In en, this message translates to:
  /// **'Connection active. If data is missing (0 sessions imported), manually verify the read permissions in the Apple Health app.'**
  String get sleepDataStatusSubtitleIos;

  /// No description provided for @sleepNoPermissionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep and heart-rate permissions are required to import sleep data.'**
  String get sleepNoPermissionSubtitle;

  /// No description provided for @sleepFeatureUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature unavailable'**
  String get sleepFeatureUnavailableTitle;

  /// No description provided for @sleepFeatureUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep import is unavailable on this device or Health Connect is not installed.'**
  String get sleepFeatureUnavailableSubtitle;

  /// No description provided for @sleepNoRawImportsFound.
  ///
  /// In en, this message translates to:
  /// **'No raw sleep imports found yet.'**
  String get sleepNoRawImportsFound;

  /// No description provided for @sleepRawImportsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Raw sleep imports (latest)'**
  String get sleepRawImportsSheetTitle;

  /// No description provided for @sleepImportFinishedSessions.
  ///
  /// In en, this message translates to:
  /// **'Sleep import finished ({count} sessions).'**
  String sleepImportFinishedSessions(int count);

  /// No description provided for @sleepImportUnavailableCheckPermissions.
  ///
  /// In en, this message translates to:
  /// **'Sleep import unavailable. Check permissions.'**
  String get sleepImportUnavailableCheckPermissions;

  /// No description provided for @sleepStatusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking permission status…'**
  String get sleepStatusChecking;

  /// No description provided for @sleepStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get sleepStatusReady;

  /// No description provided for @sleepStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get sleepStatusDenied;

  /// No description provided for @sleepStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial access'**
  String get sleepStatusPartial;

  /// No description provided for @sleepStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable on this device'**
  String get sleepStatusUnavailable;

  /// No description provided for @sleepStatusNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Health Connect not installed'**
  String get sleepStatusNotInstalled;

  /// No description provided for @sleepStatusTechnicalError.
  ///
  /// In en, this message translates to:
  /// **'Technical error'**
  String get sleepStatusTechnicalError;

  /// No description provided for @sleepConnectHealthDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect health data'**
  String get sleepConnectHealthDataTitle;

  /// No description provided for @sleepConnectHealthDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Connect HealthKit or Health Connect to import sleep records.'**
  String get sleepConnectHealthDataMessage;

  /// No description provided for @sleepPermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get sleepPermissionDeniedTitle;

  /// No description provided for @sleepPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sleep permissions are denied. Open settings to grant access.'**
  String get sleepPermissionDeniedMessage;

  /// No description provided for @sleepSourceUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Source unavailable'**
  String get sleepSourceUnavailableTitle;

  /// No description provided for @sleepSourceUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Sleep data source is unavailable or not installed on this device.'**
  String get sleepSourceUnavailableMessage;

  /// No description provided for @sleepEmptyDayNoData.
  ///
  /// In en, this message translates to:
  /// **'No sleep data available for this day.'**
  String get sleepEmptyDayNoData;

  /// No description provided for @sleepEmptyDayConnectMessage.
  ///
  /// In en, this message translates to:
  /// **'Connect Health Connect/HealthKit in Settings and import recent sleep data.'**
  String get sleepEmptyDayConnectMessage;

  /// No description provided for @sleepOpenSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get sleepOpenSettingsButton;

  /// No description provided for @sleepImportNowButton.
  ///
  /// In en, this message translates to:
  /// **'Import now'**
  String get sleepImportNowButton;

  /// No description provided for @sleepImportFinishedRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Sleep import finished. Refreshing...'**
  String get sleepImportFinishedRefreshing;

  /// No description provided for @sleepImportUnavailableSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Sleep import not available. Check permissions in Settings.'**
  String get sleepImportUnavailableSettingsHint;

  /// No description provided for @sleepTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get sleepTimelineTitle;

  /// No description provided for @sleepTimelineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No stage timeline available for this night.'**
  String get sleepTimelineUnavailable;

  /// No description provided for @sleepSessionTypeCore.
  ///
  /// In en, this message translates to:
  /// **'Core Sleep'**
  String get sleepSessionTypeCore;

  /// No description provided for @sleepSessionTypeNap.
  ///
  /// In en, this message translates to:
  /// **'Nap'**
  String get sleepSessionTypeNap;

  /// No description provided for @sleepIntervalsDrawerTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep Intervals'**
  String get sleepIntervalsDrawerTitle;

  /// No description provided for @sleepStageDeepLabel.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get sleepStageDeepLabel;

  /// No description provided for @sleepStageLightLabel.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get sleepStageLightLabel;

  /// No description provided for @sleepStageRemLabel.
  ///
  /// In en, this message translates to:
  /// **'REM'**
  String get sleepStageRemLabel;

  /// No description provided for @sleepStageAwakeLabel.
  ///
  /// In en, this message translates to:
  /// **'Awake'**
  String get sleepStageAwakeLabel;

  /// No description provided for @sleepScoreCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep quality'**
  String get sleepScoreCardTitle;

  /// No description provided for @sleepScoreUnavailableForNight.
  ///
  /// In en, this message translates to:
  /// **'Score unavailable for this night.'**
  String get sleepScoreUnavailableForNight;

  /// No description provided for @sleepScoreCompletenessLabel.
  ///
  /// In en, this message translates to:
  /// **'Score completeness: {value}'**
  String sleepScoreCompletenessLabel(String value);

  /// No description provided for @sleepQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get sleepQualityGood;

  /// No description provided for @sleepQualityAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get sleepQualityAverage;

  /// No description provided for @sleepQualityPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get sleepQualityPoor;

  /// No description provided for @sleepQualityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get sleepQualityUnavailable;

  /// No description provided for @sleepQualitySubtitleGood.
  ///
  /// In en, this message translates to:
  /// **'Recovery looked strong overnight.'**
  String get sleepQualitySubtitleGood;

  /// No description provided for @sleepQualitySubtitleAverage.
  ///
  /// In en, this message translates to:
  /// **'Sleep was okay with room for improvement.'**
  String get sleepQualitySubtitleAverage;

  /// No description provided for @sleepQualitySubtitlePoor.
  ///
  /// In en, this message translates to:
  /// **'Recovery signals were weak tonight.'**
  String get sleepQualitySubtitlePoor;

  /// No description provided for @sleepQualitySubtitleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to score this night.'**
  String get sleepQualitySubtitleUnavailable;

  /// No description provided for @sleepQualityRegularityNotContributing.
  ///
  /// In en, this message translates to:
  /// **'Regularity did not contribute (<5 valid days).'**
  String get sleepQualityRegularityNotContributing;

  /// No description provided for @sleepQualityRegularityPreliminary.
  ///
  /// In en, this message translates to:
  /// **'Regularity is preliminary (5-6 valid days).'**
  String get sleepQualityRegularityPreliminary;

  /// No description provided for @sleepQualityRegularityStable.
  ///
  /// In en, this message translates to:
  /// **'Regularity is stable ({days} days).'**
  String sleepQualityRegularityStable(int days);

  /// No description provided for @sleepRegularityNightView.
  ///
  /// In en, this message translates to:
  /// **'{count}-night view'**
  String sleepRegularityNightView(int count);

  /// No description provided for @sleepMetricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get sleepMetricUnavailable;

  /// No description provided for @sleepMetricDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sleepMetricDurationTitle;

  /// No description provided for @sleepMetricHeartRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get sleepMetricHeartRateTitle;

  /// No description provided for @sleepMetricRegularityTitle.
  ///
  /// In en, this message translates to:
  /// **'Regularity'**
  String get sleepMetricRegularityTitle;

  /// No description provided for @sleepMetricDepthTitle.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get sleepMetricDepthTitle;

  /// No description provided for @sleepMetricInterruptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Interruptions'**
  String get sleepMetricInterruptionsTitle;

  /// No description provided for @sleepMetricDepthLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Low confidence'**
  String get sleepMetricDepthLowConfidence;

  /// No description provided for @sleepMetricDepthStagesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Stages available'**
  String get sleepMetricDepthStagesAvailable;

  /// No description provided for @sleepDurationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Duration data is unavailable.'**
  String get sleepDurationUnavailable;

  /// No description provided for @sleepDurationStatusWithinTarget.
  ///
  /// In en, this message translates to:
  /// **'Within target'**
  String get sleepDurationStatusWithinTarget;

  /// No description provided for @sleepDurationStatusBelowTarget.
  ///
  /// In en, this message translates to:
  /// **'Below target'**
  String get sleepDurationStatusBelowTarget;

  /// No description provided for @sleepDurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your total sleep duration for this night.'**
  String get sleepDurationSubtitle;

  /// No description provided for @sleepDurationBenchmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Adults often do best with roughly 7–9 hours. This benchmark helps you see where your night sits in that range.'**
  String get sleepDurationBenchmarkHint;

  /// No description provided for @sleepDepthUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Depth data is unavailable.'**
  String get sleepDepthUnavailable;

  /// No description provided for @sleepDepthConfidenceTooLow.
  ///
  /// In en, this message translates to:
  /// **'Stage confidence is too low for a reliable depth breakdown.'**
  String get sleepDepthConfidenceTooLow;

  /// No description provided for @sleepDepthBreakdownUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Stage duration breakdown is unavailable for this night.'**
  String get sleepDepthBreakdownUnavailable;

  /// No description provided for @sleepDepthRatingRestorative.
  ///
  /// In en, this message translates to:
  /// **'Restorative'**
  String get sleepDepthRatingRestorative;

  /// No description provided for @sleepDepthRatingLightLeaning.
  ///
  /// In en, this message translates to:
  /// **'Light-leaning'**
  String get sleepDepthRatingLightLeaning;

  /// No description provided for @sleepDepthStageConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Stage confidence: {value}'**
  String sleepDepthStageConfidenceLabel(String value);

  /// No description provided for @sleepDepthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stage distribution based on derived timeline segments.'**
  String get sleepDepthSubtitle;

  /// No description provided for @sleepInterruptionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Interruptions data is unavailable.'**
  String get sleepInterruptionsUnavailable;

  /// No description provided for @sleepInterruptionsStatusNoneDetected.
  ///
  /// In en, this message translates to:
  /// **'None detected'**
  String get sleepInterruptionsStatusNoneDetected;

  /// No description provided for @sleepInterruptionsStatusDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get sleepInterruptionsStatusDetected;

  /// No description provided for @sleepInterruptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Qualifying wake interruptions overnight.'**
  String get sleepInterruptionsSubtitle;

  /// No description provided for @sleepInterruptionsTotalWakeDuration.
  ///
  /// In en, this message translates to:
  /// **'Total wake duration'**
  String get sleepInterruptionsTotalWakeDuration;

  /// No description provided for @sleepInterruptionsFootnote.
  ///
  /// In en, this message translates to:
  /// **'This view includes only qualifying interruptions from derived analysis outputs.'**
  String get sleepInterruptionsFootnote;

  /// No description provided for @sleepRegularityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Regularity data is unavailable.'**
  String get sleepRegularityUnavailable;

  /// No description provided for @sleepRegularityNightRange.
  ///
  /// In en, this message translates to:
  /// **'{count}-night range'**
  String sleepRegularityNightRange(int count);

  /// No description provided for @sleepRegularityStatusSufficientTrend.
  ///
  /// In en, this message translates to:
  /// **'Sufficient trend data'**
  String get sleepRegularityStatusSufficientTrend;

  /// No description provided for @sleepRegularityStatusLimitedTrend.
  ///
  /// In en, this message translates to:
  /// **'Limited trend data'**
  String get sleepRegularityStatusLimitedTrend;

  /// No description provided for @sleepRegularitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bedtime and wake windows for recent nights.'**
  String get sleepRegularitySubtitle;

  /// No description provided for @sleepRegularityAverageBedtime.
  ///
  /// In en, this message translates to:
  /// **'Average bedtime'**
  String get sleepRegularityAverageBedtime;

  /// No description provided for @sleepRegularityAverageWake.
  ///
  /// In en, this message translates to:
  /// **'Average wake'**
  String get sleepRegularityAverageWake;

  /// No description provided for @sleepHeartRateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sleep heart-rate data is unavailable.'**
  String get sleepHeartRateUnavailable;

  /// No description provided for @sleepHeartRateStatusNoSampleSeries.
  ///
  /// In en, this message translates to:
  /// **'No sample series for this night'**
  String get sleepHeartRateStatusNoSampleSeries;

  /// No description provided for @sleepHeartRateStatusBaselineNotEstablished.
  ///
  /// In en, this message translates to:
  /// **'Baseline not established'**
  String get sleepHeartRateStatusBaselineNotEstablished;

  /// No description provided for @sleepHeartRateStatusComparisonUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Baseline comparison unavailable'**
  String get sleepHeartRateStatusComparisonUnavailable;

  /// No description provided for @sleepHeartRateStatusBelowBaseline.
  ///
  /// In en, this message translates to:
  /// **'Below baseline'**
  String get sleepHeartRateStatusBelowBaseline;

  /// No description provided for @sleepHeartRateStatusAboveBaseline.
  ///
  /// In en, this message translates to:
  /// **'Above baseline'**
  String get sleepHeartRateStatusAboveBaseline;

  /// No description provided for @sleepHeartRateNoSamplesText.
  ///
  /// In en, this message translates to:
  /// **'No persisted sleep heart-rate samples are available for this night.'**
  String get sleepHeartRateNoSamplesText;

  /// No description provided for @sleepHeartRateBaselineNotEstablishedText.
  ///
  /// In en, this message translates to:
  /// **'Baseline not established yet. This is neutral and expected early on.'**
  String get sleepHeartRateBaselineNotEstablishedText;

  /// No description provided for @sleepHeartRateComparisonUnavailableText.
  ///
  /// In en, this message translates to:
  /// **'Baseline comparison is currently unavailable for this night.'**
  String get sleepHeartRateComparisonUnavailableText;

  /// No description provided for @sleepHeartRateDeltaText.
  ///
  /// In en, this message translates to:
  /// **'Your sleep HR is {direction} baseline by {delta} {unit}.'**
  String sleepHeartRateDeltaText(String direction, String delta, String unit);

  /// No description provided for @sleepHeartRateDirectionBelow.
  ///
  /// In en, this message translates to:
  /// **'below'**
  String get sleepHeartRateDirectionBelow;

  /// No description provided for @sleepHeartRateDirectionAbove.
  ///
  /// In en, this message translates to:
  /// **'above'**
  String get sleepHeartRateDirectionAbove;

  /// No description provided for @sleepHeartRateComparedBaselineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compared with your established sleep baseline.'**
  String get sleepHeartRateComparedBaselineSubtitle;

  /// No description provided for @sleepHeartRateNoBaselineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Baseline is not established yet. This is neutral.'**
  String get sleepHeartRateNoBaselineSubtitle;

  /// No description provided for @sleepHeartRateSamplesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No heart-rate samples were stored for this night. Trend chart is unavailable.'**
  String get sleepHeartRateSamplesUnavailable;

  /// No description provided for @sleepHeartRateDashedLineHint.
  ///
  /// In en, this message translates to:
  /// **'Dashed line shows baseline ({value} {unit}).'**
  String sleepHeartRateDashedLineHint(String value, String unit);

  /// No description provided for @sleepBpmUnit.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get sleepBpmUnit;

  /// No description provided for @sleepRawImportImportedAt.
  ///
  /// In en, this message translates to:
  /// **'Imported at'**
  String get sleepRawImportImportedAt;

  /// No description provided for @sleepRawImportStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sleepRawImportStatus;

  /// No description provided for @sleepRawImportSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sleepRawImportSource;

  /// No description provided for @sleepRawImportApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get sleepRawImportApp;

  /// No description provided for @sleepRawImportConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get sleepRawImportConfidence;

  /// No description provided for @sleepRawImportPayload.
  ///
  /// In en, this message translates to:
  /// **'Payload'**
  String get sleepRawImportPayload;

  /// No description provided for @adaptiveBodyweightTargetSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive bodyweight target'**
  String get adaptiveBodyweightTargetSectionTitle;

  /// No description provided for @adaptiveRecommendationSettingsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendation settings'**
  String get adaptiveRecommendationSettingsSectionTitle;

  /// No description provided for @adaptiveGoalDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal direction'**
  String get adaptiveGoalDirectionLabel;

  /// No description provided for @adaptiveGoalLose.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get adaptiveGoalLose;

  /// No description provided for @adaptiveGoalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain weight'**
  String get adaptiveGoalMaintain;

  /// No description provided for @adaptiveGoalGain.
  ///
  /// In en, this message translates to:
  /// **'Gain weight'**
  String get adaptiveGoalGain;

  /// No description provided for @adaptiveRatePerWeek.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}/week'**
  String adaptiveRatePerWeek(String value, Object unit);

  /// No description provided for @adaptivePriorActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Baseline daily activity'**
  String get adaptivePriorActivityLabel;

  /// No description provided for @adaptivePriorActivityLow.
  ///
  /// In en, this message translates to:
  /// **'Low activity'**
  String get adaptivePriorActivityLow;

  /// No description provided for @adaptivePriorActivityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate activity'**
  String get adaptivePriorActivityModerate;

  /// No description provided for @adaptivePriorActivityHigh.
  ///
  /// In en, this message translates to:
  /// **'High activity'**
  String get adaptivePriorActivityHigh;

  /// No description provided for @adaptivePriorActivityVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very high activity'**
  String get adaptivePriorActivityVeryHigh;

  /// No description provided for @adaptivePriorActivityHelpIntro.
  ///
  /// In en, this message translates to:
  /// **'Baseline daily activity only (separate from extra cardio):'**
  String get adaptivePriorActivityHelpIntro;

  /// No description provided for @adaptivePriorActivityHelpLowLine.
  ///
  /// In en, this message translates to:
  /// **'Low: mostly sitting, student/pupil or office routine.'**
  String get adaptivePriorActivityHelpLowLine;

  /// No description provided for @adaptivePriorActivityHelpModerateLine.
  ///
  /// In en, this message translates to:
  /// **'Moderate: mixed sitting, walking, and standing.'**
  String get adaptivePriorActivityHelpModerateLine;

  /// No description provided for @adaptivePriorActivityHelpHighLine.
  ///
  /// In en, this message translates to:
  /// **'High: lots of standing/walking or a physically active job.'**
  String get adaptivePriorActivityHelpHighLine;

  /// No description provided for @adaptivePriorActivityHelpVeryHighLine.
  ///
  /// In en, this message translates to:
  /// **'Very high: very movement-heavy routine/job with consistently high daily activity.'**
  String get adaptivePriorActivityHelpVeryHighLine;

  /// No description provided for @adaptiveExtraCardioLabel.
  ///
  /// In en, this message translates to:
  /// **'Extra cardio/endurance outside the app'**
  String get adaptiveExtraCardioLabel;

  /// No description provided for @adaptiveExtraCardioOption0.
  ///
  /// In en, this message translates to:
  /// **'0 h/week'**
  String get adaptiveExtraCardioOption0;

  /// No description provided for @adaptiveExtraCardioOption1.
  ///
  /// In en, this message translates to:
  /// **'1 h/week'**
  String get adaptiveExtraCardioOption1;

  /// No description provided for @adaptiveExtraCardioOption2.
  ///
  /// In en, this message translates to:
  /// **'2 h/week'**
  String get adaptiveExtraCardioOption2;

  /// No description provided for @adaptiveExtraCardioOption3.
  ///
  /// In en, this message translates to:
  /// **'3 h/week'**
  String get adaptiveExtraCardioOption3;

  /// No description provided for @adaptiveExtraCardioOption5.
  ///
  /// In en, this message translates to:
  /// **'5 h/week'**
  String get adaptiveExtraCardioOption5;

  /// No description provided for @adaptiveExtraCardioOption7Plus.
  ///
  /// In en, this message translates to:
  /// **'7+ h/week'**
  String get adaptiveExtraCardioOption7Plus;

  /// No description provided for @adaptiveExtraCardioHelp.
  ///
  /// In en, this message translates to:
  /// **'Include jogging, running, cycling, swimming, or other endurance sessions not logged as Train Libre workouts.'**
  String get adaptiveExtraCardioHelp;

  /// No description provided for @onboardingAdaptiveGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive nutrition recommendation'**
  String get onboardingAdaptiveGoalTitle;

  /// No description provided for @onboardingAdaptiveGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your direction and weekly rate. We create a conservative starting recommendation and adapt it with your logs.'**
  String get onboardingAdaptiveGoalSubtitle;

  /// No description provided for @adaptiveRecommendationGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get adaptiveRecommendationGenerating;

  /// No description provided for @adaptiveRecommendationRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh recommendation'**
  String get adaptiveRecommendationRefresh;

  /// No description provided for @onboardingAdaptiveSummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set your goal inputs and tap refresh to preview your starting recommendation.'**
  String get onboardingAdaptiveSummaryEmpty;

  /// No description provided for @onboardingAdaptiveSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendation preview'**
  String get onboardingAdaptiveSummaryTitle;

  /// No description provided for @onboardingAdaptiveSummaryCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories: {value} kcal'**
  String onboardingAdaptiveSummaryCalories(int value);

  /// No description provided for @onboardingAdaptiveSummaryProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein: {value} g'**
  String onboardingAdaptiveSummaryProtein(int value);

  /// No description provided for @onboardingAdaptiveSummaryCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs: {value} g'**
  String onboardingAdaptiveSummaryCarbs(int value);

  /// No description provided for @onboardingAdaptiveSummaryFat.
  ///
  /// In en, this message translates to:
  /// **'Fat: {value} g'**
  String onboardingAdaptiveSummaryFat(int value);

  /// No description provided for @onboardingAdaptiveSummaryConfidence.
  ///
  /// In en, this message translates to:
  /// **'Data basis: {value}'**
  String onboardingAdaptiveSummaryConfidence(String value);

  /// No description provided for @onboardingAdaptiveSummaryApply.
  ///
  /// In en, this message translates to:
  /// **'Apply to daily goals'**
  String get onboardingAdaptiveSummaryApply;

  /// No description provided for @onboardingAdaptiveSummaryApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied to daily goals'**
  String get onboardingAdaptiveSummaryApplied;

  /// No description provided for @onboardingBodyFatPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Body fat %'**
  String get onboardingBodyFatPageTitle;

  /// No description provided for @onboardingBodyFatPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional step: enter a rough estimate if you know it.'**
  String get onboardingBodyFatPageSubtitle;

  /// No description provided for @onboardingBodyFatOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Body fat % (optional)'**
  String get onboardingBodyFatOptionalLabel;

  /// No description provided for @onboardingBodyFatOptionalHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional: only enter this if you roughly know your value. Leaving it empty is okay. It helps personalize the initial recommendation.'**
  String get onboardingBodyFatOptionalHelper;

  /// No description provided for @onboardingBodyFatHelpAction.
  ///
  /// In en, this message translates to:
  /// **'How do I estimate this?'**
  String get onboardingBodyFatHelpAction;

  /// No description provided for @bodyFatGuidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Body fat % guidance'**
  String get bodyFatGuidanceTitle;

  /// No description provided for @bodyFatGuidanceIntro.
  ///
  /// In en, this message translates to:
  /// **'Body-fat percentage can only be estimated roughly from appearance. This is orientation only, not a precise diagnosis.'**
  String get bodyFatGuidanceIntro;

  /// No description provided for @bodyFatGuidanceDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Appearance can vary strongly at the same body-fat level due to muscle mass, fat distribution, genetics, water retention, posture, and lighting.'**
  String get bodyFatGuidanceDisclaimer;

  /// No description provided for @bodyFatGuidanceSexLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference sex'**
  String get bodyFatGuidanceSexLabel;

  /// No description provided for @bodyFatGuidancePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String bodyFatGuidancePercent(int percent);

  /// No description provided for @bodyFatGuidanceMale10.
  ///
  /// In en, this message translates to:
  /// **'Very lean, clear definition.'**
  String get bodyFatGuidanceMale10;

  /// No description provided for @bodyFatGuidanceMale15.
  ///
  /// In en, this message translates to:
  /// **'Athletic, visibly defined.'**
  String get bodyFatGuidanceMale15;

  /// No description provided for @bodyFatGuidanceMale20.
  ///
  /// In en, this message translates to:
  /// **'Sporty, slightly softer.'**
  String get bodyFatGuidanceMale20;

  /// No description provided for @bodyFatGuidanceMale25.
  ///
  /// In en, this message translates to:
  /// **'Less definition, more waist and belly softness.'**
  String get bodyFatGuidanceMale25;

  /// No description provided for @bodyFatGuidanceMale30.
  ///
  /// In en, this message translates to:
  /// **'Clearly softer, rounder.'**
  String get bodyFatGuidanceMale30;

  /// No description provided for @bodyFatGuidanceMale35.
  ///
  /// In en, this message translates to:
  /// **'Very soft, almost no visible definition.'**
  String get bodyFatGuidanceMale35;

  /// No description provided for @bodyFatGuidanceMale40.
  ///
  /// In en, this message translates to:
  /// **'Strongly rounder appearance, no visible definition.'**
  String get bodyFatGuidanceMale40;

  /// No description provided for @bodyFatGuidanceFemale15.
  ///
  /// In en, this message translates to:
  /// **'Very lean, very defined.'**
  String get bodyFatGuidanceFemale15;

  /// No description provided for @bodyFatGuidanceFemale20.
  ///
  /// In en, this message translates to:
  /// **'Lean and athletic.'**
  String get bodyFatGuidanceFemale20;

  /// No description provided for @bodyFatGuidanceFemale25.
  ///
  /// In en, this message translates to:
  /// **'Fit, lightly soft.'**
  String get bodyFatGuidanceFemale25;

  /// No description provided for @bodyFatGuidanceFemale30.
  ///
  /// In en, this message translates to:
  /// **'Soft, healthy-looking average athletic-to-normal range.'**
  String get bodyFatGuidanceFemale30;

  /// No description provided for @bodyFatGuidanceFemale35.
  ///
  /// In en, this message translates to:
  /// **'Noticeably softer.'**
  String get bodyFatGuidanceFemale35;

  /// No description provided for @bodyFatGuidanceFemale40.
  ///
  /// In en, this message translates to:
  /// **'Clearly softer, rounder overall appearance.'**
  String get bodyFatGuidanceFemale40;

  /// No description provided for @adaptiveRecommendationCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive recommendation'**
  String get adaptiveRecommendationCardTitle;

  /// No description provided for @adaptiveRecommendationEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Track weight and nutrition for about a week to unlock your first weekly recommendation.'**
  String get adaptiveRecommendationEmptyBody;

  /// No description provided for @adaptiveRecommendationGoalLine.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal} ({rate})'**
  String adaptiveRecommendationGoalLine(String goal, String rate);

  /// No description provided for @adaptiveRecommendationMaintenanceLine.
  ///
  /// In en, this message translates to:
  /// **'Maintenance estimate: {value} kcal'**
  String adaptiveRecommendationMaintenanceLine(int value);

  /// No description provided for @adaptiveRecommendationMaintenanceRangeLine.
  ///
  /// In en, this message translates to:
  /// **'Likely range: {lower}-{upper} kcal'**
  String adaptiveRecommendationMaintenanceRangeLine(int lower, int upper);

  /// No description provided for @adaptiveRecommendationUncertaintyHintNarrow.
  ///
  /// In en, this message translates to:
  /// **'Your likely maintenance range is fairly tight. Small day-to-day shifts are normal.'**
  String get adaptiveRecommendationUncertaintyHintNarrow;

  /// No description provided for @adaptiveRecommendationUncertaintyHintModerate.
  ///
  /// In en, this message translates to:
  /// **'Your likely maintenance range is moderate right now. Some movement week to week is normal.'**
  String get adaptiveRecommendationUncertaintyHintModerate;

  /// No description provided for @adaptiveRecommendationUncertaintyHintWide.
  ///
  /// In en, this message translates to:
  /// **'Your likely maintenance range is still wide. This is normal while we gather more steady data.'**
  String get adaptiveRecommendationUncertaintyHintWide;

  /// No description provided for @adaptiveRecommendationStabilizingHint.
  ///
  /// In en, this message translates to:
  /// **'We are still adapting to your recent phase, so this estimate can move more than usual.'**
  String get adaptiveRecommendationStabilizingHint;

  /// No description provided for @adaptiveRecommendationCaloriesValue.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal'**
  String adaptiveRecommendationCaloriesValue(int value);

  /// No description provided for @adaptiveRecommendationProteinValue.
  ///
  /// In en, this message translates to:
  /// **'{value} g'**
  String adaptiveRecommendationProteinValue(int value);

  /// No description provided for @adaptiveRecommendationCarbsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} g'**
  String adaptiveRecommendationCarbsValue(int value);

  /// No description provided for @adaptiveRecommendationFatValue.
  ///
  /// In en, this message translates to:
  /// **'{value} g'**
  String adaptiveRecommendationFatValue(int value);

  /// No description provided for @adaptiveRecommendationConfidenceLine.
  ///
  /// In en, this message translates to:
  /// **'Data basis: {value}'**
  String adaptiveRecommendationConfidenceLine(String value);

  /// No description provided for @adaptiveRecommendationDataBasisLine.
  ///
  /// In en, this message translates to:
  /// **'Data basis: {windowDays} days, {weightLogs} weight logs, {intakeDays} intake days'**
  String adaptiveRecommendationDataBasisLine(
      int windowDays, int weightLogs, int intakeDays);

  /// No description provided for @adaptiveRecommendationActiveCaloriesLine.
  ///
  /// In en, this message translates to:
  /// **'Current active calories: {value} kcal'**
  String adaptiveRecommendationActiveCaloriesLine(int value);

  /// No description provided for @adaptiveRecommendationCalculatedAtLine.
  ///
  /// In en, this message translates to:
  /// **'Calculated at: {value}'**
  String adaptiveRecommendationCalculatedAtLine(String value);

  /// No description provided for @adaptiveRecommendationNextDueLine.
  ///
  /// In en, this message translates to:
  /// **'Next adaptive recommendation due: {value}'**
  String adaptiveRecommendationNextDueLine(String value);

  /// No description provided for @adaptiveRecommendationNextDueShort.
  ///
  /// In en, this message translates to:
  /// **'Next {value}'**
  String adaptiveRecommendationNextDueShort(String value);

  /// No description provided for @adaptiveRecommendationDueNowLine.
  ///
  /// In en, this message translates to:
  /// **'A new adaptive recommendation is due this week.'**
  String get adaptiveRecommendationDueNowLine;

  /// No description provided for @adaptiveRecommendationDueNowShort.
  ///
  /// In en, this message translates to:
  /// **'Due this week'**
  String get adaptiveRecommendationDueNowShort;

  /// No description provided for @adaptiveRecommendationMaintenanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated maintenance'**
  String get adaptiveRecommendationMaintenanceLabel;

  /// No description provided for @adaptiveRecommendationMaintenanceSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile prior + recent logs'**
  String get adaptiveRecommendationMaintenanceSourceLabel;

  /// No description provided for @adaptiveRecommendationMaintenanceUnit.
  ///
  /// In en, this message translates to:
  /// **'kcal/day'**
  String get adaptiveRecommendationMaintenanceUnit;

  /// No description provided for @adaptiveRecommendationMacroTargetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommended targets'**
  String get adaptiveRecommendationMacroTargetsLabel;

  /// No description provided for @adaptiveRecommendationTargetCaloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Target kcal'**
  String get adaptiveRecommendationTargetCaloriesLabel;

  /// No description provided for @adaptiveRecommendationDataQualityLabel.
  ///
  /// In en, this message translates to:
  /// **'Data quality'**
  String get adaptiveRecommendationDataQualityLabel;

  /// No description provided for @adaptiveRecommendationEnergyDensityLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective energy density'**
  String get adaptiveRecommendationEnergyDensityLabel;

  /// No description provided for @adaptiveRecommendationEnergyDensityValue.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal/kg'**
  String adaptiveRecommendationEnergyDensityValue(int value);

  /// No description provided for @adaptiveRecommendationEnergyDensityExplanation.
  ///
  /// In en, this message translates to:
  /// **'Dynamic value based on weight and water-loss ratio'**
  String get adaptiveRecommendationEnergyDensityExplanation;

  /// No description provided for @adaptiveRecommendationRecalculateNowAction.
  ///
  /// In en, this message translates to:
  /// **'Recalculate now'**
  String get adaptiveRecommendationRecalculateNowAction;

  /// No description provided for @adaptiveRecommendationRecalculating.
  ///
  /// In en, this message translates to:
  /// **'Recalculating...'**
  String get adaptiveRecommendationRecalculating;

  /// No description provided for @adaptiveRecommendationApplying.
  ///
  /// In en, this message translates to:
  /// **'Applying...'**
  String get adaptiveRecommendationApplying;

  /// No description provided for @adaptiveRecommendationApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Apply recommendation'**
  String get adaptiveRecommendationApplyAction;

  /// No description provided for @adaptiveRecommendationWarningCalorieFloor.
  ///
  /// In en, this message translates to:
  /// **'Recommendation constrained by a minimum calorie safety floor. Review profile data and recent logs before applying.'**
  String get adaptiveRecommendationWarningCalorieFloor;

  /// No description provided for @adaptiveRecommendationWarningUnresolvedFood.
  ///
  /// In en, this message translates to:
  /// **'Some nutrition entries could not be fully resolved for calories. Check recent logs before applying.'**
  String get adaptiveRecommendationWarningUnresolvedFood;

  /// No description provided for @adaptiveRecommendationWarningLargeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Large adjustment detected. Please review your recent logging completeness before applying.'**
  String get adaptiveRecommendationWarningLargeAdjustment;

  /// No description provided for @adaptiveRecommendationWarningMacroConstrained.
  ///
  /// In en, this message translates to:
  /// **'Macro split was constrained by the calorie budget. Check if your target rate is too aggressive.'**
  String get adaptiveRecommendationWarningMacroConstrained;

  /// No description provided for @adaptiveRecommendationWarningConservative.
  ///
  /// In en, this message translates to:
  /// **'Review suggested: recommendation was adjusted conservatively due to data variability.'**
  String get adaptiveRecommendationWarningConservative;

  /// No description provided for @adaptiveRecommendationDataBasisHintDefault.
  ///
  /// In en, this message translates to:
  /// **'Built from recent logs and their completeness.'**
  String get adaptiveRecommendationDataBasisHintDefault;

  /// No description provided for @adaptiveRecommendationDataBasisHintPriorOnly.
  ///
  /// In en, this message translates to:
  /// **'Based on profile/prior data only. Add recent weight and intake logs for adaptive adjustment.'**
  String get adaptiveRecommendationDataBasisHintPriorOnly;

  /// No description provided for @adaptiveRecommendationDataBasisHintSparseWeight.
  ///
  /// In en, this message translates to:
  /// **'Recent weight logs are sparse, so trend quality is limited.'**
  String get adaptiveRecommendationDataBasisHintSparseWeight;

  /// No description provided for @adaptiveRecommendationDataBasisHintSparseIntake.
  ///
  /// In en, this message translates to:
  /// **'Recent intake logs are sparse, so maintenance inference is limited.'**
  String get adaptiveRecommendationDataBasisHintSparseIntake;

  /// No description provided for @adaptiveRecommendationDataBasisHintSparseWeightAndIntake.
  ///
  /// In en, this message translates to:
  /// **'Recent weight and intake logs are sparse, so this recommendation is more conservative.'**
  String get adaptiveRecommendationDataBasisHintSparseWeightAndIntake;

  /// No description provided for @adaptiveConfidenceNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Profile/prior only'**
  String get adaptiveConfidenceNotEnoughData;

  /// No description provided for @adaptiveConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Limited recent logs'**
  String get adaptiveConfidenceLow;

  /// No description provided for @adaptiveConfidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Usable recent logs'**
  String get adaptiveConfidenceMedium;

  /// No description provided for @adaptiveConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'Strong recent logs'**
  String get adaptiveConfidenceHigh;

  /// No description provided for @adaptiveRecommendationRecalculatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Recommendation recalculated.'**
  String get adaptiveRecommendationRecalculatedSnack;

  /// No description provided for @adaptiveRecommendationAppliedToGoalsSnack.
  ///
  /// In en, this message translates to:
  /// **'Recommendation applied to active goals.'**
  String get adaptiveRecommendationAppliedToGoalsSnack;

  /// No description provided for @adaptiveRecommendationNotAvailableSnack.
  ///
  /// In en, this message translates to:
  /// **'No recommendation available to apply.'**
  String get adaptiveRecommendationNotAvailableSnack;

  /// No description provided for @settingsSectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsSectionApp;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust theme, visual style, and haptics'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsShowSugarInDiaryOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Show sugar in Diary overview'**
  String get settingsShowSugarInDiaryOverviewTitle;

  /// No description provided for @settingsShowSugarInDiaryOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows sugar in the top daily overview section'**
  String get settingsShowSugarInDiaryOverviewSubtitle;

  /// No description provided for @settingsOverviewExtraNutrientTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional Nutrient in Overview'**
  String get settingsOverviewExtraNutrientTitle;

  /// No description provided for @settingsOverviewExtraNutrientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a third nutrient tile to the daily overview section'**
  String get settingsOverviewExtraNutrientSubtitle;

  /// No description provided for @settingsSectionHealthTracking.
  ///
  /// In en, this message translates to:
  /// **'Health & Tracking'**
  String get settingsSectionHealthTracking;

  /// No description provided for @settingsStepsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tracking, source policy, and providers'**
  String get settingsStepsSubtitle;

  /// No description provided for @settingsSleepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import, permissions, and sleep status'**
  String get settingsSleepSubtitle;

  /// No description provided for @settingsPulseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Opt-in pulse analysis and heart-rate access'**
  String get settingsPulseSubtitle;

  /// No description provided for @settingsHealthExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Apple Health and Health Connect export'**
  String get settingsHealthExportSubtitle;

  /// No description provided for @settingsSectionNutritionAndData.
  ///
  /// In en, this message translates to:
  /// **'Nutrition & Data'**
  String get settingsSectionNutritionAndData;

  /// No description provided for @settingsSectionSupportAbout.
  ///
  /// In en, this message translates to:
  /// **'Support / About'**
  String get settingsSectionSupportAbout;

  /// No description provided for @settingsHapticFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingsHapticFeedbackTitle;

  /// No description provided for @settingsHapticFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light vibrations for confirmations and AI waiting'**
  String get settingsHapticFeedbackSubtitle;

  /// No description provided for @stepsSettingsEnableTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable steps tracking'**
  String get stepsSettingsEnableTrackingTitle;

  /// No description provided for @stepsSettingsEnableTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read step data from Apple Health / Health Connect'**
  String get stepsSettingsEnableTrackingSubtitle;

  /// No description provided for @stepsSettingsSourcePolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Source policy'**
  String get stepsSettingsSourcePolicyTitle;

  /// No description provided for @stepsSettingsSourcePolicyAutoDominant.
  ///
  /// In en, this message translates to:
  /// **'Auto (dominant source)'**
  String get stepsSettingsSourcePolicyAutoDominant;

  /// No description provided for @stepsSettingsSourcePolicyAutoDominantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended: use one source per day to avoid overlap inflation.'**
  String get stepsSettingsSourcePolicyAutoDominantSubtitle;

  /// No description provided for @stepsSettingsSourcePolicyMaxPerHour.
  ///
  /// In en, this message translates to:
  /// **'Merge (max per hour)'**
  String get stepsSettingsSourcePolicyMaxPerHour;

  /// No description provided for @stepsSettingsSourcePolicyMaxPerHourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Combine sources by taking the highest hourly bucket.'**
  String get stepsSettingsSourcePolicyMaxPerHourSubtitle;

  /// No description provided for @stepsSettingsProviderFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider filter'**
  String get stepsSettingsProviderFilterTitle;

  /// No description provided for @pulseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get pulseTitle;

  /// No description provided for @pulseChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Pulse over time'**
  String get pulseChartTitle;

  /// No description provided for @pulseRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get pulseRangeLabel;

  /// No description provided for @pulseAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get pulseAverageLabel;

  /// No description provided for @pulseRestingLabel.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get pulseRestingLabel;

  /// No description provided for @pulseInsufficientData.
  ///
  /// In en, this message translates to:
  /// **'Too few pulse samples for a reliable chart.'**
  String get pulseInsufficientData;

  /// No description provided for @pulseMethodNote.
  ///
  /// In en, this message translates to:
  /// **'Average pulse is time-weighted. Resting pulse is a conservative estimate from the lowest 20% of samples in the selected period.'**
  String get pulseMethodNote;

  /// No description provided for @pulseSampleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No samples} one{1 sample} other{{count} samples}}'**
  String pulseSampleCount(int count);

  /// No description provided for @pulseQualityReady.
  ///
  /// In en, this message translates to:
  /// **'Good coverage'**
  String get pulseQualityReady;

  /// No description provided for @pulseQualityLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited data'**
  String get pulseQualityLimited;

  /// No description provided for @pulseQualityInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Very sparse'**
  String get pulseQualityInsufficient;

  /// No description provided for @pulseQualityNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get pulseQualityNoData;

  /// No description provided for @pulseNoDataDisabled.
  ///
  /// In en, this message translates to:
  /// **'Pulse analysis is disabled in Settings.'**
  String get pulseNoDataDisabled;

  /// No description provided for @pulseNoDataPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Heart-rate permission is required to show pulse analysis.'**
  String get pulseNoDataPermissionDenied;

  /// No description provided for @pulseNoDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Pulse data is currently unavailable on this device.'**
  String get pulseNoDataUnavailable;

  /// No description provided for @pulseNoDataQueryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read pulse data.'**
  String get pulseNoDataQueryFailed;

  /// No description provided for @pulseNoDataDefault.
  ///
  /// In en, this message translates to:
  /// **'No pulse samples were found for this period.'**
  String get pulseNoDataDefault;

  /// No description provided for @pulseSettingsEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable pulse analysis'**
  String get pulseSettingsEnableTitle;

  /// No description provided for @pulseSettingsEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reads heart-rate data for the pulse view only when you turn this on.'**
  String get pulseSettingsEnableSubtitle;

  /// No description provided for @pulseSettingsPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow heart-rate access'**
  String get pulseSettingsPermissionTitle;

  /// No description provided for @pulseSettingsPermissionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Opens Apple Health or Health Connect so Train Libre can read pulse samples.'**
  String get pulseSettingsPermissionSubtitle;

  /// No description provided for @pulseSettingsAnalysisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows range, time-weighted average, and a conservative resting-pulse estimate. Not a medical diagnosis.'**
  String get pulseSettingsAnalysisSubtitle;

  /// No description provided for @pulseSettingsPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Heart-rate access is ready.'**
  String get pulseSettingsPermissionGranted;

  /// No description provided for @pulseSettingsPermissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Heart-rate access was not granted.'**
  String get pulseSettingsPermissionFailed;

  /// No description provided for @pulseOptInChip.
  ///
  /// In en, this message translates to:
  /// **'Opt-in'**
  String get pulseOptInChip;

  /// No description provided for @statisticsPulseDescription.
  ///
  /// In en, this message translates to:
  /// **'Range, time-weighted average, and resting pulse for selected periods.'**
  String get statisticsPulseDescription;

  /// No description provided for @statisticsPulseOpenCaption.
  ///
  /// In en, this message translates to:
  /// **'Opens pulse analysis'**
  String get statisticsPulseOpenCaption;

  /// No description provided for @healthExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Health export'**
  String get healthExportTitle;

  /// No description provided for @healthExportAppleHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Apple Health export'**
  String get healthExportAppleHealthTitle;

  /// No description provided for @healthExportHealthConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Connect export'**
  String get healthExportHealthConnectTitle;

  /// No description provided for @healthExportDomainNutritionHydration.
  ///
  /// In en, this message translates to:
  /// **'Nutrition & hydration'**
  String get healthExportDomainNutritionHydration;

  /// No description provided for @healthExportDomainWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get healthExportDomainWorkouts;

  /// No description provided for @healthExportStateIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get healthExportStateIdle;

  /// No description provided for @healthExportStateExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting'**
  String get healthExportStateExporting;

  /// No description provided for @healthExportStateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get healthExportStateSuccess;

  /// No description provided for @healthExportStateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get healthExportStateFailed;

  /// No description provided for @healthExportStateDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get healthExportStateDisabled;

  /// No description provided for @healthExportResultComplete.
  ///
  /// In en, this message translates to:
  /// **'Export complete'**
  String get healthExportResultComplete;

  /// No description provided for @healthExportResultFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get healthExportResultFailed;

  /// No description provided for @healthExportAppleHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-way export from Train Libre to Apple Health'**
  String get healthExportAppleHealthSubtitle;

  /// No description provided for @healthExportHealthConnectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-way export from Train Libre to Health Connect'**
  String get healthExportHealthConnectSubtitle;

  /// No description provided for @healthExportAppleHealthStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Apple Health export status'**
  String get healthExportAppleHealthStatusTitle;

  /// No description provided for @healthExportHealthConnectStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Connect export status'**
  String get healthExportHealthConnectStatusTitle;

  /// No description provided for @settingsBaseFoodLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Base food display language'**
  String get settingsBaseFoodLanguageTitle;

  /// No description provided for @settingsBaseFoodLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which language to use for base food names.'**
  String get settingsBaseFoodLanguageSubtitle;

  /// No description provided for @settingsBaseFoodLanguageFollowApp.
  ///
  /// In en, this message translates to:
  /// **'Follow app language'**
  String get settingsBaseFoodLanguageFollowApp;

  /// No description provided for @settingsBaseFoodLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsBaseFoodLanguageEnglish;

  /// No description provided for @settingsBaseFoodLanguageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get settingsBaseFoodLanguageGerman;

  /// No description provided for @settingsBaseFoodLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get settingsBaseFoodLanguageFrench;

  /// No description provided for @settingsBaseFoodLanguageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get settingsBaseFoodLanguageItalian;

  /// No description provided for @settingsBaseFoodLanguageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get settingsBaseFoodLanguageJapanese;

  /// No description provided for @aiModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get aiModelLabel;

  /// No description provided for @aiModelListFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Showing the built-in model list'**
  String get aiModelListFallbackTitle;

  /// No description provided for @aiModelListRetry.
  ///
  /// In en, this message translates to:
  /// **'Reload models'**
  String get aiModelListRetry;

  /// No description provided for @aiModelListErrorMissingKey.
  ///
  /// In en, this message translates to:
  /// **'Save your API key to load the current models from the provider.'**
  String get aiModelListErrorMissingKey;

  /// No description provided for @aiModelListErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'The provider could not be reached. Check your internet connection.'**
  String get aiModelListErrorNetwork;

  /// No description provided for @aiModelListErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The provider did not answer within the configured timeout.'**
  String get aiModelListErrorTimeout;

  /// No description provided for @aiModelListErrorAuth.
  ///
  /// In en, this message translates to:
  /// **'The provider rejected your API key (HTTP {status}). Check the key and its permissions.'**
  String aiModelListErrorAuth(Object status);

  /// No description provided for @aiModelListErrorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'The provider is rate limiting or out of quota (HTTP {status}). Try again shortly.'**
  String aiModelListErrorRateLimit(Object status);

  /// No description provided for @aiModelListErrorHttp.
  ///
  /// In en, this message translates to:
  /// **'The provider answered with HTTP {status}.'**
  String aiModelListErrorHttp(Object status);

  /// No description provided for @aiModelListErrorResponse.
  ///
  /// In en, this message translates to:
  /// **'The provider\'s model list could not be read.'**
  String get aiModelListErrorResponse;

  /// No description provided for @autoBackupStoragePickerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Storage picker unavailable. Please fully restart/reinstall the app after updating.'**
  String get autoBackupStoragePickerUnavailable;

  /// No description provided for @autoBackupFolderPickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Folder picker failed: {error}'**
  String autoBackupFolderPickerFailed(Object error);

  /// No description provided for @healthExportPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get healthExportPermissionDenied;

  /// No description provided for @healthExportAdapterUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Adapter unavailable'**
  String get healthExportAdapterUnavailable;

  /// No description provided for @healthExportPlatformUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Platform unavailable'**
  String get healthExportPlatformUnavailable;

  /// No description provided for @healthExportPlatformNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Platform not installed'**
  String get healthExportPlatformNotInstalled;

  /// No description provided for @healthExportExportDisabled.
  ///
  /// In en, this message translates to:
  /// **'Export disabled'**
  String get healthExportExportDisabled;

  /// No description provided for @onboardingMacrosStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Macronutrients'**
  String get onboardingMacrosStepTitle;

  /// No description provided for @onboardingMacrosStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How is your nutrition composed?'**
  String get onboardingMacrosStepSubtitle;

  /// No description provided for @statisticsProviderAppleHealth.
  ///
  /// In en, this message translates to:
  /// **'Apple Health'**
  String get statisticsProviderAppleHealth;

  /// No description provided for @statisticsProviderHealthConnect.
  ///
  /// In en, this message translates to:
  /// **'Health Connect'**
  String get statisticsProviderHealthConnect;

  /// No description provided for @statisticsProviderWithings.
  ///
  /// In en, this message translates to:
  /// **'Withings'**
  String get statisticsProviderWithings;

  /// No description provided for @statisticsProviderGarmin.
  ///
  /// In en, this message translates to:
  /// **'Garmin'**
  String get statisticsProviderGarmin;

  /// No description provided for @statisticsProviderFitbit.
  ///
  /// In en, this message translates to:
  /// **'Fitbit'**
  String get statisticsProviderFitbit;

  /// No description provided for @statisticsProviderLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get statisticsProviderLocal;

  /// No description provided for @unit_milliliters.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unit_milliliters;

  /// No description provided for @unit_kilograms.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unit_kilograms;

  /// No description provided for @mealEditorHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chicken bowl'**
  String get mealEditorHintExample;

  /// No description provided for @mealEditorNoIngredientsYet.
  ///
  /// In en, this message translates to:
  /// **'None yet – coming later'**
  String get mealEditorNoIngredientsYet;

  /// No description provided for @foodDetailSavedBaseDb.
  ///
  /// In en, this message translates to:
  /// **'Saved (base DB)'**
  String get foodDetailSavedBaseDb;

  /// No description provided for @foodDetailExportError.
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String foodDetailExportError(Object error);

  /// No description provided for @stepsModulePrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get stepsModulePrevious;

  /// No description provided for @stepsModuleNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get stepsModuleNext;

  /// No description provided for @stepsModuleTotalSteps.
  ///
  /// In en, this message translates to:
  /// **'Total Steps'**
  String get stepsModuleTotalSteps;

  /// No description provided for @stepsModuleThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get stepsModuleThisWeek;

  /// No description provided for @stepsModuleThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get stepsModuleThisMonth;

  /// No description provided for @stepsModuleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String stepsModuleUpdated(String time);

  /// No description provided for @stepsModuleScopeSwitcherSemantics.
  ///
  /// In en, this message translates to:
  /// **'Switch step scope'**
  String get stepsModuleScopeSwitcherSemantics;

  /// No description provided for @stepsModuleDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get stepsModuleDay;

  /// No description provided for @stepsModuleWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get stepsModuleWeek;

  /// No description provided for @stepsModuleMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get stepsModuleMonth;

  /// No description provided for @stepsModuleHourlyTimeline.
  ///
  /// In en, this message translates to:
  /// **'Hourly Timeline'**
  String get stepsModuleHourlyTimeline;

  /// No description provided for @stepsModuleTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get stepsModuleTotal;

  /// No description provided for @stepsModuleActiveHours.
  ///
  /// In en, this message translates to:
  /// **'Active Hours'**
  String get stepsModuleActiveHours;

  /// No description provided for @stepsModulePeakHour.
  ///
  /// In en, this message translates to:
  /// **'Peak Hour'**
  String get stepsModulePeakHour;

  /// No description provided for @stepsModuleAvgPerDay.
  ///
  /// In en, this message translates to:
  /// **'Avg / Day'**
  String get stepsModuleAvgPerDay;

  /// No description provided for @stepsModuleGoalHit.
  ///
  /// In en, this message translates to:
  /// **'Goal Hit'**
  String get stepsModuleGoalHit;

  /// No description provided for @stepsModuleGoalDays.
  ///
  /// In en, this message translates to:
  /// **'Goal Days'**
  String get stepsModuleGoalDays;

  /// No description provided for @diarySyncingSteps.
  ///
  /// In en, this message translates to:
  /// **'Syncing steps...'**
  String get diarySyncingSteps;

  /// No description provided for @diaryLoadingSleep.
  ///
  /// In en, this message translates to:
  /// **'Loading sleep...'**
  String get diaryLoadingSleep;

  /// No description provided for @unit_milligrams.
  ///
  /// In en, this message translates to:
  /// **'mg'**
  String get unit_milligrams;

  /// No description provided for @scannerPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera access is required to scan barcodes.'**
  String get scannerPermissionRequired;

  /// No description provided for @scannerPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is permanently denied. Please enable it in settings to scan barcodes.'**
  String get scannerPermissionPermanentlyDenied;

  /// No description provided for @scannerOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get scannerOpenSettings;

  /// No description provided for @scannerGrantPermission.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get scannerGrantPermission;

  /// No description provided for @scannerAlignInstruction.
  ///
  /// In en, this message translates to:
  /// **'Align barcode horizontally inside the red laser line'**
  String get scannerAlignInstruction;

  /// No description provided for @scannerToggleFlash.
  ///
  /// In en, this message translates to:
  /// **'Toggle flashlight'**
  String get scannerToggleFlash;

  /// No description provided for @about_train_libre.
  ///
  /// In en, this message translates to:
  /// **'About Train Libre'**
  String get about_train_libre;

  /// No description provided for @legal_notice.
  ///
  /// In en, this message translates to:
  /// **'Legal Notice'**
  String get legal_notice;

  /// No description provided for @privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy;

  /// No description provided for @terms_of_service.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get terms_of_service;

  /// No description provided for @view_in_browser.
  ///
  /// In en, this message translates to:
  /// **'View in Browser'**
  String get view_in_browser;

  /// No description provided for @legal_document_version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get legal_document_version;

  /// No description provided for @legal_document_last_updated.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get legal_document_last_updated;

  /// No description provided for @used_libraries.
  ///
  /// In en, this message translates to:
  /// **'Used Libraries'**
  String get used_libraries;

  /// No description provided for @licensing_info.
  ///
  /// In en, this message translates to:
  /// **'Licensing Information'**
  String get licensing_info;

  /// No description provided for @project_website.
  ///
  /// In en, this message translates to:
  /// **'Project Website'**
  String get project_website;

  /// No description provided for @github_repository.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get github_repository;

  /// No description provided for @health_permission_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Health Data & Privacy'**
  String get health_permission_dialog_title;

  /// No description provided for @health_permission_dialog_body.
  ///
  /// In en, this message translates to:
  /// **'Train Libre needs to read your step data to show daily/weekly statistics. Your data stays locally on your device; there is no external server.'**
  String get health_permission_dialog_body;

  /// No description provided for @health_permission_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get health_permission_continue;

  /// No description provided for @health_permission_not_now.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get health_permission_not_now;

  /// No description provided for @welcome_privacy_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome & Privacy'**
  String get welcome_privacy_title;

  /// No description provided for @welcome_privacy_body.
  ///
  /// In en, this message translates to:
  /// **'To provide workout tracking and training insights, we process your fitness and activity data as described in our Privacy Policy.'**
  String get welcome_privacy_body;

  /// No description provided for @i_agree_to_privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'I explicitly consent to the processing of my fitness and health data for workout tracking and training insights. I can withdraw my consent at any time in Settings.'**
  String get i_agree_to_privacy_policy;

  /// No description provided for @i_agree_to_optional_telemetry.
  ///
  /// In en, this message translates to:
  /// **'(Optional) I want to share pseudonymised usage statistics to help improve app stability and features (zero personal or health data).'**
  String get i_agree_to_optional_telemetry;

  /// No description provided for @welcome_back_updated_legal_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back & Updated Policies'**
  String get welcome_back_updated_legal_title;

  /// No description provided for @legal_update_body.
  ///
  /// In en, this message translates to:
  /// **'We have updated our Privacy Policy and Terms of Service (Version {version}). To continue using Train Libre, please acknowledge the updated terms. All your existing data remains safely stored on your device.'**
  String legal_update_body(String version);

  /// No description provided for @i_agree_to_updated_privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'I explicitly consent to the updated Privacy Policy (v{version}) and the processing of my fitness and health data.'**
  String i_agree_to_updated_privacy_policy(String version);

  /// No description provided for @accept_and_continue.
  ///
  /// In en, this message translates to:
  /// **'Accept & Continue'**
  String get accept_and_continue;

  /// No description provided for @by_tapping_accept_continue.
  ///
  /// In en, this message translates to:
  /// **'By tapping \"Accept & Continue\", you agree to the updated'**
  String get by_tapping_accept_continue;

  /// No description provided for @acceptTermsPrompt.
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms of Service'**
  String get acceptTermsPrompt;

  /// No description provided for @viewTermsInline.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get viewTermsInline;

  /// No description provided for @accept_and_get_started.
  ///
  /// In en, this message translates to:
  /// **'Accept & Get Started'**
  String get accept_and_get_started;

  /// No description provided for @by_tapping_accept.
  ///
  /// In en, this message translates to:
  /// **'By tapping \"Accept & Get Started\", you agree to our'**
  String get by_tapping_accept;

  /// No description provided for @and_acknowledge.
  ///
  /// In en, this message translates to:
  /// **'and acknowledge our'**
  String get and_acknowledge;

  /// No description provided for @about_section.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about_section;

  /// No description provided for @legal_section.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal_section;

  /// No description provided for @aiSettingsInstructionTitle.
  ///
  /// In en, this message translates to:
  /// **'How AI Meal Recognition Works'**
  String get aiSettingsInstructionTitle;

  /// No description provided for @aiSettingsInstructionBody.
  ///
  /// In en, this message translates to:
  /// **'This feature uses AI to analyze food images and provide nutrient estimates. Your images are only sent to the selected AI provider when you use the feature. It relies on a Bring-Your-Own-Key (BYOK) architecture, keeping your data locally on your device until analysis.'**
  String get aiSettingsInstructionBody;

  /// No description provided for @aiSettingsSetupGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup Guide'**
  String get aiSettingsSetupGuideTitle;

  /// No description provided for @aiSettingsSetupGuideBody.
  ///
  /// In en, this message translates to:
  /// **'To use this feature, you need an API key from an AI provider. Google Gemini is used as a primary example because it currently offers a free tier for developers and users.'**
  String get aiSettingsSetupGuideBody;

  /// No description provided for @aiSettingsGetApiKeyButton.
  ///
  /// In en, this message translates to:
  /// **'View Setup Guide'**
  String get aiSettingsGetApiKeyButton;

  /// No description provided for @legal_document_version_value.
  ///
  /// In en, this message translates to:
  /// **'1.2'**
  String get legal_document_version_value;

  /// No description provided for @legal_document_last_updated_value.
  ///
  /// In en, this message translates to:
  /// **'May 20, 2026'**
  String get legal_document_last_updated_value;

  /// No description provided for @muscleChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get muscleChest;

  /// No description provided for @muscleBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get muscleBack;

  /// No description provided for @muscleShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get muscleShoulders;

  /// No description provided for @muscleBiceps.
  ///
  /// In en, this message translates to:
  /// **'Biceps'**
  String get muscleBiceps;

  /// No description provided for @muscleTriceps.
  ///
  /// In en, this message translates to:
  /// **'Triceps'**
  String get muscleTriceps;

  /// No description provided for @muscleQuads.
  ///
  /// In en, this message translates to:
  /// **'Quadriceps'**
  String get muscleQuads;

  /// No description provided for @muscleHamstrings.
  ///
  /// In en, this message translates to:
  /// **'Hamstrings'**
  String get muscleHamstrings;

  /// No description provided for @muscleLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get muscleLegs;

  /// No description provided for @muscleArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get muscleArms;

  /// No description provided for @muscleGlutes.
  ///
  /// In en, this message translates to:
  /// **'Glutes'**
  String get muscleGlutes;

  /// No description provided for @muscleCalves.
  ///
  /// In en, this message translates to:
  /// **'Calves'**
  String get muscleCalves;

  /// No description provided for @muscleLowerBack.
  ///
  /// In en, this message translates to:
  /// **'Lower Back'**
  String get muscleLowerBack;

  /// No description provided for @muscleAbs.
  ///
  /// In en, this message translates to:
  /// **'Abs'**
  String get muscleAbs;

  /// No description provided for @muscleAdductors.
  ///
  /// In en, this message translates to:
  /// **'Adductors'**
  String get muscleAdductors;

  /// No description provided for @muscleForearms.
  ///
  /// In en, this message translates to:
  /// **'Forearms'**
  String get muscleForearms;

  /// No description provided for @sleepDetailAnalysisHeader.
  ///
  /// In en, this message translates to:
  /// **'Detailed Analysis'**
  String get sleepDetailAnalysisHeader;

  /// No description provided for @sleepMetricDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Sleep Duration'**
  String get sleepMetricDurationLabel;

  /// No description provided for @sleepMetricContinuityLabel.
  ///
  /// In en, this message translates to:
  /// **'Continuity (WASO/SE)'**
  String get sleepMetricContinuityLabel;

  /// No description provided for @sleepMetricDepthLabel.
  ///
  /// In en, this message translates to:
  /// **'Sleep Stage Depth'**
  String get sleepMetricDepthLabel;

  /// No description provided for @sleepMetricTimingLabel.
  ///
  /// In en, this message translates to:
  /// **'Circadian Timing'**
  String get sleepMetricTimingLabel;

  /// No description provided for @sleepMetricRegularityLabel.
  ///
  /// In en, this message translates to:
  /// **'Regularity'**
  String get sleepMetricRegularityLabel;

  /// No description provided for @sleepBannerTstBottleneck.
  ///
  /// In en, this message translates to:
  /// **'Sleep duration penalty active: Your total sleep volume was below the regenerative optimum of 6.5 hours, which restricts anabolic hormone release.'**
  String get sleepBannerTstBottleneck;

  /// No description provided for @sleepBannerRemBottleneck.
  ///
  /// In en, this message translates to:
  /// **'REM sleep deficiency penalty: Your REM sleep was below 60 minutes. This impairs neuronal recovery and mental freshness.'**
  String get sleepBannerRemBottleneck;

  /// No description provided for @sleepBannerN3Bottleneck.
  ///
  /// In en, this message translates to:
  /// **'Deep sleep deficiency penalty: Critical lack of N3 deep sleep (<70 min). Physical muscle tissue repair is suboptimal.'**
  String get sleepBannerN3Bottleneck;

  /// No description provided for @sleepBannerTimingBottleneck.
  ///
  /// In en, this message translates to:
  /// **'Circadian phase shift penalty: Your mid-sleep was after 05:30 AM. Sleeping against the inner clock reduces sleep quality and insulin sensitivity.'**
  String get sleepBannerTimingBottleneck;

  /// No description provided for @sleepBannerDefaultPenalty.
  ///
  /// In en, this message translates to:
  /// **'Clinical protective brake active: Your sleep volume was suboptimal (<6h) or circadian timing (sleep onset) was severely shifted. The total score has been limited.'**
  String get sleepBannerDefaultPenalty;

  /// No description provided for @infoTdeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive Calorie & TDEE Estimator'**
  String get infoTdeeTitle;

  /// No description provided for @infoTdeeExplanation.
  ///
  /// In en, this message translates to:
  /// **'Estimates your Total Daily Energy Expenditure (TDEE) based on your profile, logged meals, and bodyweight changes.'**
  String get infoTdeeExplanation;

  /// No description provided for @infoTdeeKeyPoints.
  ///
  /// In en, this message translates to:
  /// **'• Smooths out daily weight fluctuations using a recursive trend model.\n• Uses a Bayesian-inspired approach to adapt weekly targets conservatively.\n• Alerts you if your logging consistency is too sparse for high-confidence updates.'**
  String get infoTdeeKeyPoints;

  /// No description provided for @infoTdeeTechnicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Bayesian Recursive Filtering & Metabolic Smoothing'**
  String get infoTdeeTechnicalTitle;

  /// No description provided for @infoTdeeTechnicalExplanation.
  ///
  /// In en, this message translates to:
  /// **'Rather than relying on static formulas, Train Libre models your metabolism as a dynamic \'hidden state\' estimated recursively. Daily observed maintenance is computed by adjusting intake against body mass changes. A process noise coefficient is added on unlogged days to increase the estimation uncertainty, which dampens updates and prevents skewing from short-term water retention.'**
  String get infoTdeeTechnicalExplanation;

  /// No description provided for @infoRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Muscle Recovery Estimator'**
  String get infoRecoveryTitle;

  /// No description provided for @infoRecoveryExplanation.
  ///
  /// In en, this message translates to:
  /// **'Estimates muscle-specific readiness and recovery curves based on training volume, intensity, and proximity to failure.'**
  String get infoRecoveryExplanation;

  /// No description provided for @infoRecoveryKeyPoints.
  ///
  /// In en, this message translates to:
  /// **'• Accounts for overlapping muscle stress (e.g., Bench Press counts for Chest, Triceps, and Shoulders).\n• Scales recovery speed based on RIR/RPE and extends the window for sets taken to failure.\n• Calibrates baseline recovery windows based on muscle group size and metabolic properties.'**
  String get infoRecoveryKeyPoints;

  /// No description provided for @infoRecoveryTechnicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Equivalent Set Fatigue & Piecewise Decay Model'**
  String get infoRecoveryTechnicalTitle;

  /// No description provided for @infoRecoveryTechnicalExplanation.
  ///
  /// In en, this message translates to:
  /// **'Calculates dynamic readiness via non-linear decay curves. Volume tracking automatically distributes load between primary and secondary muscle groups. Recovery speed scales based on proximity to failure (RIR) and applies a strict timeline extension for sets taken to absolute failure.'**
  String get infoRecoveryTechnicalExplanation;

  /// No description provided for @infoScientificReferencesButton.
  ///
  /// In en, this message translates to:
  /// **'View Scientific References & Sources'**
  String get infoScientificReferencesButton;

  /// No description provided for @infoScientificDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This feature uses established sports science and metabolic modeling literature as its foundation. The full list of peer-reviewed sources is available on our website.'**
  String get infoScientificDisclaimer;

  /// No description provided for @infoAiMealTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Meal Capture Hub'**
  String get infoAiMealTitle;

  /// No description provided for @infoAiMealExplanation.
  ///
  /// In en, this message translates to:
  /// **'Converts meal photos or text descriptions into structured diary entries and matches them against your private product database.'**
  String get infoAiMealExplanation;

  /// No description provided for @infoAiMealKeyPoints.
  ///
  /// In en, this message translates to:
  /// **'• Translates imprecise descriptions (e.g., \'a slice of bread\') into metric weight estimates.\n• Matches AI suggestions offline against the local product database on your device.\n• Computes nutrition locally instead of delegating calculations to external servers.'**
  String get infoAiMealKeyPoints;

  /// No description provided for @infoAiMealTechnicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Hybrid BYOK AI & Jaro-Winkler Matching'**
  String get infoAiMealTechnicalTitle;

  /// No description provided for @infoAiMealTechnicalExplanation.
  ///
  /// In en, this message translates to:
  /// **'Uses a Bring-Your-Own-Key (BYOK) privacy model. The AI functions strictly as a suggestion layer. Matching is performed offline using a tokenized Jaro-Winkler filter against the local SQLite database. The AI provider is strictly prohibited from performing nutritional calculations via system prompts.'**
  String get infoAiMealTechnicalExplanation;

  /// No description provided for @infoSleepTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep Quality (SHS v3.5)'**
  String get infoSleepTitle;

  /// No description provided for @infoSleepExplanation.
  ///
  /// In en, this message translates to:
  /// **'Calculates a comprehensive sleep index from quantity, continuity, depth, timing, and daily regularity.'**
  String get infoSleepExplanation;

  /// No description provided for @infoSleepKeyPoints.
  ///
  /// In en, this message translates to:
  /// **'• Aggregates five clinical dimensions using a weighted sum.\n• Automatically scales requirements if your wearable does not provide specific stages or efficiency data.\n• Protects you via soft-cap multipliers that limit the total score if a critical domain (like REM or Deep sleep) is compromised.'**
  String get infoSleepKeyPoints;

  /// No description provided for @infoSleepTechnicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Weighted Baseline & Continuous Soft-Caps'**
  String get infoSleepTechnicalTitle;

  /// No description provided for @infoSleepTechnicalExplanation.
  ///
  /// In en, this message translates to:
  /// **'Aggregates five primary domains using a weighted linear sum: Duration (30%), Continuity (20%), Architecture (25%), Timing (15%), and Regularity (10%). To prevent misleading averages when a clinical domain is compromised, the final score is degraded if significant bottlenecks are detected in sleep stages or circadian timing.'**
  String get infoSleepTechnicalExplanation;

  /// No description provided for @tdeeRecalculationNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'TDEE Recalculated'**
  String get tdeeRecalculationNotificationTitle;

  /// No description provided for @tdeeRecalculationNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'New daily targets: {calories} kcal | {protein}g Protein | {carbs}g Carbs | {fat}g Fat'**
  String tdeeRecalculationNotificationBody(
      int calories, int protein, int carbs, int fat);

  /// No description provided for @recommendationBannerText.
  ///
  /// In en, this message translates to:
  /// **'New targets available ({delta} kcal).'**
  String recommendationBannerText(String delta);

  /// No description provided for @recommendationBannerApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get recommendationBannerApply;

  /// No description provided for @cancelingAndRollingBack.
  ///
  /// In en, this message translates to:
  /// **'Canceling, rolling back safely...'**
  String get cancelingAndRollingBack;

  /// No description provided for @sleepSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Syncing Sleep History...'**
  String get sleepSyncTitle;

  /// No description provided for @backupExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Exporting Backup...'**
  String get backupExportTitle;

  /// No description provided for @backupImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Importing Backup...'**
  String get backupImportTitle;

  /// No description provided for @progressImportingNight.
  ///
  /// In en, this message translates to:
  /// **'Importing Night {index}/{total}...'**
  String progressImportingNight(int index, int total);

  /// No description provided for @progressExportingTable.
  ///
  /// In en, this message translates to:
  /// **'Exporting {table}...'**
  String progressExportingTable(String table);

  /// No description provided for @progressImportingTable.
  ///
  /// In en, this message translates to:
  /// **'Restoring {table}...'**
  String progressImportingTable(String table);

  /// No description provided for @shareDailyLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Log'**
  String get shareDailyLogTitle;

  /// No description provided for @shareSleepStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get shareSleepStartTime;

  /// No description provided for @shareSleepEndTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get shareSleepEndTime;

  /// No description provided for @shareSleepDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep Sleep'**
  String get shareSleepDeep;

  /// No description provided for @shareSleepLight.
  ///
  /// In en, this message translates to:
  /// **'Light Sleep'**
  String get shareSleepLight;

  /// No description provided for @shareSleepRem.
  ///
  /// In en, this message translates to:
  /// **'REM Sleep'**
  String get shareSleepRem;

  /// No description provided for @shareSleepAwake.
  ///
  /// In en, this message translates to:
  /// **'Awake/Interruptions'**
  String get shareSleepAwake;

  /// No description provided for @shareTotalWater.
  ///
  /// In en, this message translates to:
  /// **'Total Water/Fluids'**
  String get shareTotalWater;

  /// No description provided for @shareNutritionSummary.
  ///
  /// In en, this message translates to:
  /// **'Total Nutrition Summary'**
  String get shareNutritionSummary;

  /// No description provided for @shareSleepEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get shareSleepEfficiency;

  /// No description provided for @shareSleepRestingHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Resting Heart Rate'**
  String get shareSleepRestingHeartRate;

  /// No description provided for @shareAsTextOrCopy.
  ///
  /// In en, this message translates to:
  /// **'Share / copy as text'**
  String get shareAsTextOrCopy;

  /// No description provided for @editExercise.
  ///
  /// In en, this message translates to:
  /// **'Edit Exercise'**
  String get editExercise;

  /// No description provided for @exerciseCopyCreated.
  ///
  /// In en, this message translates to:
  /// **'Copy of \'{exerciseName}\' created.'**
  String exerciseCopyCreated(String exerciseName);

  /// No description provided for @copySystemExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy System Exercise'**
  String get copySystemExerciseTitle;

  /// No description provided for @copySystemExerciseBody.
  ///
  /// In en, this message translates to:
  /// **'This exercise is system-provided and cannot be directly edited. Would you like to create a custom copy to edit it?'**
  String get copySystemExerciseBody;

  /// No description provided for @createCopyAndEdit.
  ///
  /// In en, this message translates to:
  /// **'Create Copy & Edit'**
  String get createCopyAndEdit;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEdit;

  /// No description provided for @selectBirthday.
  ///
  /// In en, this message translates to:
  /// **'Select date of birth'**
  String get selectBirthday;

  /// No description provided for @exerciseNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise Note'**
  String get exerciseNoteTitle;

  /// No description provided for @exerciseNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Enter notes or hints...'**
  String get exerciseNoteHint;

  /// No description provided for @deleteNoteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get deleteNoteTooltip;

  /// No description provided for @emptyStateAddFirstExerciseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an exercise to start logging.'**
  String get emptyStateAddFirstExerciseSubtitle;

  /// No description provided for @syncRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Routine?'**
  String get syncRoutineTitle;

  /// No description provided for @syncRoutineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Structure or order changes detected.'**
  String get syncRoutineSubtitle;

  /// No description provided for @syncRoutineBody.
  ///
  /// In en, this message translates to:
  /// **'Would you like to update the routine \'{routineName}\' with the current workout data (exercises, order, sets)?'**
  String syncRoutineBody(String routineName);

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @syncRoutineSuccess.
  ///
  /// In en, this message translates to:
  /// **'Routine updated successfully!'**
  String get syncRoutineSuccess;

  /// No description provided for @syncRoutineError.
  ///
  /// In en, this message translates to:
  /// **'Error updating routine: {error}'**
  String syncRoutineError(String error);

  /// No description provided for @createRoutineError.
  ///
  /// In en, this message translates to:
  /// **'Error creating routine: {error}'**
  String createRoutineError(String error);

  /// No description provided for @nutritionPerQuantity.
  ///
  /// In en, this message translates to:
  /// **'Nutrition per {quantity}g'**
  String nutritionPerQuantity(String quantity);

  /// No description provided for @settingsLocalModelName.
  ///
  /// In en, this message translates to:
  /// **'Local Model Name'**
  String get settingsLocalModelName;

  /// No description provided for @settingsCustomBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Custom Base URL'**
  String get settingsCustomBaseUrl;

  /// No description provided for @settingsCustomModelName.
  ///
  /// In en, this message translates to:
  /// **'Custom Model Name'**
  String get settingsCustomModelName;

  /// No description provided for @settingsAiFoodNameLanguage.
  ///
  /// In en, this message translates to:
  /// **'AI Food Name Language'**
  String get settingsAiFoodNameLanguage;

  /// No description provided for @settingsRequestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request Timeout'**
  String get settingsRequestTimeout;

  /// No description provided for @settingsSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String settingsSeconds(int seconds);

  /// No description provided for @semanticsApplyRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Apply Recommendation'**
  String get semanticsApplyRecommendation;

  /// No description provided for @semanticsDismissBanner.
  ///
  /// In en, this message translates to:
  /// **'Dismiss Banner'**
  String get semanticsDismissBanner;

  /// No description provided for @importedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Imported Workout'**
  String get importedWorkout;

  /// No description provided for @unknownExercise.
  ///
  /// In en, this message translates to:
  /// **'Unknown Exercise'**
  String get unknownExercise;

  /// No description provided for @devExportBaseDb.
  ///
  /// In en, this message translates to:
  /// **'Export base database'**
  String get devExportBaseDb;

  /// No description provided for @initCheckingExercises.
  ///
  /// In en, this message translates to:
  /// **'Checking exercises...'**
  String get initCheckingExercises;

  /// No description provided for @initLoadingRemoteManifest.
  ///
  /// In en, this message translates to:
  /// **'Loading remote manifest...'**
  String get initLoadingRemoteManifest;

  /// No description provided for @initExercisesUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Exercises up to date'**
  String get initExercisesUpToDate;

  /// No description provided for @initNoDownloadRequired.
  ///
  /// In en, this message translates to:
  /// **'No remote download required.'**
  String get initNoDownloadRequired;

  /// No description provided for @initLoadingExercises.
  ///
  /// In en, this message translates to:
  /// **'Loading exercises...'**
  String get initLoadingExercises;

  /// No description provided for @initDownloadingRemoteCatalog.
  ///
  /// In en, this message translates to:
  /// **'Downloading remote exercise catalog {version}...'**
  String initDownloadingRemoteCatalog(String version);

  /// No description provided for @initPreparingImport.
  ///
  /// In en, this message translates to:
  /// **'Preparing download for import...'**
  String get initPreparingImport;

  /// No description provided for @initExercisesReady.
  ///
  /// In en, this message translates to:
  /// **'Exercises ready'**
  String get initExercisesReady;

  /// No description provided for @initImportingRemoteCatalog.
  ///
  /// In en, this message translates to:
  /// **'Importing remote exercise catalog {version}...'**
  String initImportingRemoteCatalog(String version);

  /// No description provided for @initCheckingProductDatabase.
  ///
  /// In en, this message translates to:
  /// **'Checking product database ({country})...'**
  String initCheckingProductDatabase(String country);

  /// No description provided for @initProductDatabaseUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Product database up to date'**
  String get initProductDatabaseUpToDate;

  /// No description provided for @initLoadingProductDatabase.
  ///
  /// In en, this message translates to:
  /// **'Loading product database...'**
  String get initLoadingProductDatabase;

  /// No description provided for @initDownloadingProductBundle.
  ///
  /// In en, this message translates to:
  /// **'Downloading remote product bundle {version}...'**
  String initDownloadingProductBundle(String version);

  /// No description provided for @initProductDatabaseReady.
  ///
  /// In en, this message translates to:
  /// **'Product database ready'**
  String get initProductDatabaseReady;

  /// No description provided for @initImportingProductBundle.
  ///
  /// In en, this message translates to:
  /// **'Importing remote product bundle {version}...'**
  String initImportingProductBundle(String version);

  /// No description provided for @initNoOffBundle.
  ///
  /// In en, this message translates to:
  /// **'No OFF bundle/remote available. Existing local OFF data remains unchanged.'**
  String get initNoOffBundle;

  /// No description provided for @initEntriesProgress.
  ///
  /// In en, this message translates to:
  /// **'{processed} / {totalCount} entries'**
  String initEntriesProgress(String processed, String totalCount);

  /// No description provided for @initUpdateTask.
  ///
  /// In en, this message translates to:
  /// **'Update {task}'**
  String initUpdateTask(String task);

  /// No description provided for @initCheckingTask.
  ///
  /// In en, this message translates to:
  /// **'Checking {task}...'**
  String initCheckingTask(String task);

  /// No description provided for @initTaskUpToDate.
  ///
  /// In en, this message translates to:
  /// **'{task} up to date'**
  String initTaskUpToDate(String task);

  /// No description provided for @initInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initInitializing;

  /// No description provided for @initPreparation.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get initPreparation;

  /// No description provided for @initReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get initReady;

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String yearsOld(int age);

  /// No description provided for @customFoodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Foods'**
  String get customFoodsTitle;

  /// No description provided for @deleteFoodConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Food Item'**
  String get deleteFoodConfirmTitle;

  /// No description provided for @deleteFoodConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this custom food item? Historical logs will not be affected.'**
  String get deleteFoodConfirmBody;

  /// No description provided for @foodItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Food item deleted'**
  String get foodItemDeleted;

  /// No description provided for @copySystemFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy System Food'**
  String get copySystemFoodTitle;

  /// No description provided for @copySystemFoodBody.
  ///
  /// In en, this message translates to:
  /// **'System foods cannot be edited directly. Would you like to create a custom copy and edit it?'**
  String get copySystemFoodBody;

  /// No description provided for @foodCopyCreated.
  ///
  /// In en, this message translates to:
  /// **'Copy created: {name}'**
  String foodCopyCreated(String name);

  /// No description provided for @nutritionPer100g.
  ///
  /// In en, this message translates to:
  /// **'Nutrition per 100g'**
  String get nutritionPer100g;

  /// No description provided for @nutritionPerPortion.
  ///
  /// In en, this message translates to:
  /// **'Nutrition per Portion ({grams}g)'**
  String nutritionPerPortion(int grams);

  /// No description provided for @workoutConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout in Progress'**
  String get workoutConflictTitle;

  /// No description provided for @workoutConflictContent.
  ///
  /// In en, this message translates to:
  /// **'You already have an active workout session. Would you like to resume it, or discard it to start a new one?'**
  String get workoutConflictContent;

  /// No description provided for @resumeWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Resume Workout'**
  String get resumeWorkoutButton;

  /// No description provided for @discardAndStartButton.
  ///
  /// In en, this message translates to:
  /// **'Discard & Start New'**
  String get discardAndStartButton;

  /// No description provided for @profileTapToSetUp.
  ///
  /// In en, this message translates to:
  /// **'Tap to set up'**
  String get profileTapToSetUp;

  /// No description provided for @customLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customLabel;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @languageAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get languageAuto;

  /// No description provided for @aiValidationCostEstimation.
  ///
  /// In en, this message translates to:
  /// **'Cost: ~{tokenCount} tokens'**
  String aiValidationCostEstimation(num tokenCount);

  /// No description provided for @showAllWithCount.
  ///
  /// In en, this message translates to:
  /// **'Show all ({count})'**
  String showAllWithCount(num count);

  /// No description provided for @repsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Rep} other{{count} Reps}}'**
  String repsCount(num count);

  /// No description provided for @offDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Database Catalogs'**
  String get offDownloadTitle;

  /// No description provided for @offDownloadBody.
  ///
  /// In en, this message translates to:
  /// **'To access full offline product search, barcode scanning, and AI features, please initialize the local catalogs. You will download the latest database releases from GitHub.'**
  String get offDownloadBody;

  /// No description provided for @offDownloadConfirm.
  ///
  /// In en, this message translates to:
  /// **'Download Now'**
  String get offDownloadConfirm;

  /// No description provided for @offDownloadCancel.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get offDownloadCancel;

  /// No description provided for @offDownloadCTA.
  ///
  /// In en, this message translates to:
  /// **'Download Database'**
  String get offDownloadCTA;

  /// No description provided for @offPlaceholderText.
  ///
  /// In en, this message translates to:
  /// **'Nutrition features require the local database catalog.'**
  String get offPlaceholderText;

  /// No description provided for @backupImportLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Database Catalog Required'**
  String get backupImportLockedTitle;

  /// No description provided for @backupImportLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Before importing a backup, both the exercise catalog and nutrition catalog must be fully downloaded and initialized to prevent data inconsistency. Please download the required databases first.'**
  String get backupImportLockedBody;

  /// No description provided for @wgerPlaceholderText.
  ///
  /// In en, this message translates to:
  /// **'Exercise catalog features require the local database catalog.'**
  String get wgerPlaceholderText;

  /// No description provided for @onboardingRegionTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Region'**
  String get onboardingRegionTitle;

  /// No description provided for @onboardingRegionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Select the country where you buy your groceries. This ensures we download the correct Open Food Facts database for your local products.'**
  String get onboardingRegionExplanation;

  /// No description provided for @onboardingRegionSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'You can change this at any time later in Settings → Nutrition → Database Region.'**
  String get onboardingRegionSettingsHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @rollingDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days (rolling)'**
  String rollingDaysLabel(int days);

  /// No description provided for @muscleTraps.
  ///
  /// In en, this message translates to:
  /// **'Traps'**
  String get muscleTraps;

  /// No description provided for @muscleObliques.
  ///
  /// In en, this message translates to:
  /// **'Obliques'**
  String get muscleObliques;

  /// No description provided for @icloudSyncErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'iCloud Sync Failed'**
  String get icloudSyncErrorTitle;

  /// No description provided for @icloudSyncErrorHelp.
  ///
  /// In en, this message translates to:
  /// **'Please ensure that iCloud Drive is enabled in your iOS System Settings under Settings -> [Your Name] -> iCloud -> iCloud Drive.'**
  String get icloudSyncErrorHelp;

  /// No description provided for @icloudSyncErrorCopyLog.
  ///
  /// In en, this message translates to:
  /// **'Copy Technical Error Log'**
  String get icloudSyncErrorCopyLog;

  /// No description provided for @icloudSyncErrorClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get icloudSyncErrorClose;

  /// No description provided for @icloudSyncErrorCopied.
  ///
  /// In en, this message translates to:
  /// **'Error log copied to clipboard!'**
  String get icloudSyncErrorCopied;

  /// No description provided for @icloudLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {date}'**
  String icloudLastSynced(String date);

  /// No description provided for @icloudNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get icloudNeverSynced;

  /// No description provided for @emptyStateDiaryColdStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your Diary!'**
  String get emptyStateDiaryColdStartTitle;

  /// No description provided for @emptyStateDiaryColdStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep track of your nutrition and hydration here.'**
  String get emptyStateDiaryColdStartSubtitle;

  /// No description provided for @emptyStateActiveGapOverlay.
  ///
  /// In en, this message translates to:
  /// **'No data available for this period'**
  String get emptyStateActiveGapOverlay;

  /// No description provided for @emptyStateDiaryColdStartCallToAction.
  ///
  /// In en, this message translates to:
  /// **'Log your first entry here'**
  String get emptyStateDiaryColdStartCallToAction;

  /// No description provided for @statisticsColdStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your Analytics!'**
  String get statisticsColdStartTitle;

  /// No description provided for @statisticsColdStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be visualized here as soon as you log your first workouts, meals, or track your steps and sleep.'**
  String get statisticsColdStartSubtitle;

  /// No description provided for @statisticsActiveGapTitle.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get statisticsActiveGapTitle;

  /// No description provided for @reviewPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Do you like Train Libre?'**
  String get reviewPromptTitle;

  /// No description provided for @reviewPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps us continuously improve the app without ads or trackers.'**
  String get reviewPromptSubtitle;

  /// No description provided for @reviewPromptYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, I like it'**
  String get reviewPromptYes;

  /// No description provided for @reviewPromptNo.
  ///
  /// In en, this message translates to:
  /// **'No, not really'**
  String get reviewPromptNo;

  /// No description provided for @reviewPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Remind me later'**
  String get reviewPromptLater;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailableTitle;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get statusRequired;

  /// No description provided for @updatesAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'New updates are available for your local catalogs. Would you like to update now?'**
  String get updatesAvailableBody;

  /// No description provided for @exerciseCatalogWger.
  ///
  /// In en, this message translates to:
  /// **'Exercise Catalog (OpenExerciseDB)'**
  String get exerciseCatalogWger;

  /// No description provided for @nutritionCatalogOff.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Catalog (OFF)'**
  String get nutritionCatalogOff;

  /// No description provided for @workoutImportZeroNew.
  ///
  /// In en, this message translates to:
  /// **'0 new workouts imported (all already existed).'**
  String get workoutImportZeroNew;

  /// No description provided for @telemetryDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Telemetry Data?'**
  String get telemetryDeleteDialogTitle;

  /// No description provided for @telemetryDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete your past telemetry data?\n\nThe following will happen:\n• All device UUIDs, session IDs, and local counters stored on this device will be reset.\n• A deletion request (\$delete_person) will be sent to PostHog servers in the EU to remove your data there.\n• The telemetry SDK will be fully reset.'**
  String get telemetryDeleteDialogBody;

  /// No description provided for @telemetryDeleteConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete data now'**
  String get telemetryDeleteConfirmButton;

  /// No description provided for @telemetryConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Help improve Train Libre?'**
  String get telemetryConsentTitle;

  /// No description provided for @telemetryConsentBody.
  ///
  /// In en, this message translates to:
  /// **'Train Libre is built independently by a single developer, without accounts and without ads. If you like, you can share pseudonymised usage statistics. They help me understand which features are used and where the app can be improved.'**
  String get telemetryConsentBody;

  /// No description provided for @telemetryConsentPointAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Pseudonymised: No name, no email, no workout, diary, weight, nutrition, or health data. Only screen views, feature usage, and error reports are transmitted.'**
  String get telemetryConsentPointAnonymous;

  /// No description provided for @telemetryConsentPointNotSold.
  ///
  /// In en, this message translates to:
  /// **'Not for advertising: Data is never sold and never used for marketing or advertising. Processed on servers in the EU.'**
  String get telemetryConsentPointNotSold;

  /// No description provided for @telemetryConsentPointRevocable.
  ///
  /// In en, this message translates to:
  /// **'Voluntary: Can be disabled in Settings at any time. Stored telemetry data can also be deleted there.'**
  String get telemetryConsentPointRevocable;

  /// No description provided for @telemetryConsentAccept.
  ///
  /// In en, this message translates to:
  /// **'Yes, share usage data'**
  String get telemetryConsentAccept;

  /// No description provided for @telemetryConsentDecline.
  ///
  /// In en, this message translates to:
  /// **'No, thanks'**
  String get telemetryConsentDecline;

  /// No description provided for @settingsTelemetryToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Share pseudonymised usage statistics'**
  String get settingsTelemetryToggleTitle;

  /// No description provided for @settingsTelemetryToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps improve the app. Pseudonymised, without personal or health data.'**
  String get settingsTelemetryToggleSubtitle;

  /// No description provided for @settingsTelemetryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete telemetry data'**
  String get settingsTelemetryDeleteTitle;

  /// No description provided for @settingsTelemetryDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deletes all stored IDs locally and on the PostHog server'**
  String get settingsTelemetryDeleteSubtitle;

  /// No description provided for @liveActivitySetPosition.
  ///
  /// In en, this message translates to:
  /// **'Set {index} of {total}'**
  String liveActivitySetPosition(int index, int total);

  /// No description provided for @liveActivityOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'overdue by'**
  String get liveActivityOverdueLabel;

  /// No description provided for @liveActivityRirLabel.
  ///
  /// In en, this message translates to:
  /// **'RIR'**
  String get liveActivityRirLabel;

  /// No description provided for @liveActivityRpeLabel.
  ///
  /// In en, this message translates to:
  /// **'RPE'**
  String get liveActivityRpeLabel;

  /// No description provided for @liveActivityAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get liveActivityAddExercise;

  /// No description provided for @liveActivityOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open app'**
  String get liveActivityOpenApp;

  /// No description provided for @unit_pounds.
  ///
  /// In en, this message translates to:
  /// **'lbs'**
  String get unit_pounds;

  /// No description provided for @unit_kilometers.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unit_kilometers;

  /// No description provided for @unit_miles.
  ///
  /// In en, this message translates to:
  /// **'mi'**
  String get unit_miles;

  /// No description provided for @liveActivitySkipShort.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get liveActivitySkipShort;

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whatsNewTitle;

  /// No description provided for @whatsNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what changed since your last update.'**
  String get whatsNewSubtitle;

  /// Section header above one release's highlights in the What's New sheet.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String whatsNewVersionHeader(String version);

  /// No description provided for @whatsNewCta.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get whatsNewCta;

  /// No description provided for @whatsNewAboutRow.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whatsNewAboutRow;

  /// No description provided for @whatsNewAboutRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Release highlights of this and earlier versions'**
  String get whatsNewAboutRowSubtitle;

  /// No description provided for @mealAnalysisPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the capture'**
  String get mealAnalysisPreparing;

  /// No description provided for @mealAnalysisAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing the meal'**
  String get mealAnalysisAnalyzing;

  /// No description provided for @mealAnalysisMatching.
  ///
  /// In en, this message translates to:
  /// **'Matching the ingredients'**
  String get mealAnalysisMatching;

  /// No description provided for @mealAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'That did not work'**
  String get mealAnalysisFailed;

  /// No description provided for @mealAnalysisProcessingTag.
  ///
  /// In en, this message translates to:
  /// **'AI VISION PROCESSING'**
  String get mealAnalysisProcessingTag;

  /// No description provided for @aiScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'AI scanner'**
  String get aiScannerTitle;

  /// No description provided for @aiCaptureAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing…'**
  String get aiCaptureAnalyzing;

  /// No description provided for @aiCaptureAnalyzeMeal.
  ///
  /// In en, this message translates to:
  /// **'Analyze meal ({count})'**
  String aiCaptureAnalyzeMeal(int count);

  /// No description provided for @aiCaptureAnalyzeText.
  ///
  /// In en, this message translates to:
  /// **'Analyze text'**
  String get aiCaptureAnalyzeText;

  /// No description provided for @aiCaptureDescribeHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the meal (e.g. 2 eggs with toast)…'**
  String get aiCaptureDescribeHint;

  /// No description provided for @aiCaptureBarcodeDetected.
  ///
  /// In en, this message translates to:
  /// **'Barcode detected'**
  String get aiCaptureBarcodeDetected;

  /// No description provided for @aiCaptureLogBarcode.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get aiCaptureLogBarcode;

  /// No description provided for @aiCaptureBarcodeFallback.
  ///
  /// In en, this message translates to:
  /// **'Barcode {code}'**
  String aiCaptureBarcodeFallback(String code);

  /// No description provided for @aiCaptureMoveCloser.
  ///
  /// In en, this message translates to:
  /// **'Move a little closer'**
  String get aiCaptureMoveCloser;

  /// No description provided for @aiCaptureMoveAway.
  ///
  /// In en, this message translates to:
  /// **'Move back a little'**
  String get aiCaptureMoveAway;

  /// No description provided for @aiCaptureOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get aiCaptureOpenSettings;

  /// No description provided for @voiceDictationTitle.
  ///
  /// In en, this message translates to:
  /// **'Dictate the meal'**
  String get voiceDictationTitle;

  /// No description provided for @voiceHoldToTalk.
  ///
  /// In en, this message translates to:
  /// **'Hold to speak'**
  String get voiceHoldToTalk;

  /// No description provided for @voiceSpeakNow.
  ///
  /// In en, this message translates to:
  /// **'Speak now — release to finish'**
  String get voiceSpeakNow;

  /// No description provided for @voiceExampleStandalone.
  ///
  /// In en, this message translates to:
  /// **'e.g. “A vegetable kebab with flatbread and garlic sauce”'**
  String get voiceExampleStandalone;

  /// No description provided for @voiceExampleWithPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add what the photo cannot show — e.g. “fried in two tablespoons of olive oil”'**
  String get voiceExampleWithPhoto;

  /// No description provided for @voiceNetworkNotice.
  ///
  /// In en, this message translates to:
  /// **'This device cannot recognize speech locally. The recording is sent to the system’s speech recognition to be transcribed.'**
  String get voiceNetworkNotice;

  /// No description provided for @voiceTapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to start recording'**
  String get voiceTapToRecord;

  /// No description provided for @voiceTapToFinish.
  ///
  /// In en, this message translates to:
  /// **'Listening — tap to finish'**
  String get voiceTapToFinish;

  /// No description provided for @voiceStarting.
  ///
  /// In en, this message translates to:
  /// **'Getting ready…'**
  String get voiceStarting;

  /// No description provided for @voiceTidyingUp.
  ///
  /// In en, this message translates to:
  /// **'Tidying up your words…'**
  String get voiceTidyingUp;

  /// No description provided for @voiceNothingHeard.
  ///
  /// In en, this message translates to:
  /// **'Nothing was recognized. Try again, or type it instead.'**
  String get voiceNothingHeard;

  /// No description provided for @voiceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get voiceLanguage;

  /// No description provided for @voiceLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Dictation language'**
  String get voiceLanguageTitle;

  /// No description provided for @voiceLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow the device'**
  String get voiceLanguageSystem;

  /// No description provided for @voiceLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the language you speak, not the one the app is in.'**
  String get voiceLanguageHint;

  /// No description provided for @voiceCleanedNotice.
  ///
  /// In en, this message translates to:
  /// **'Filler words removed'**
  String get voiceCleanedNotice;

  /// No description provided for @voiceRetake.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get voiceRetake;

  /// No description provided for @voiceTidiedIn.
  ///
  /// In en, this message translates to:
  /// **'Tidied up by AI in {seconds} s'**
  String voiceTidiedIn(String seconds);

  /// No description provided for @aiDepthImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Send the depth map too'**
  String get aiDepthImageTitle;

  /// No description provided for @aiDepthImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Attaches the false-colour relief of the meal as a second image, so the model can judge height as well as outline. Costs one extra image per analysis.'**
  String get aiDepthImageSubtitle;

  /// No description provided for @aiVoiceTidyTitle.
  ///
  /// In en, this message translates to:
  /// **'Tidy up dictation with AI'**
  String get aiVoiceTidyTitle;

  /// No description provided for @aiVoiceTidySubtitle.
  ///
  /// In en, this message translates to:
  /// **'After you finish speaking, the transcript is corrected and split into bullet points. Costs one request and a few seconds.'**
  String get aiVoiceTidySubtitle;

  /// No description provided for @voicePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone and speech recognition'**
  String get voicePermissionTitle;

  /// No description provided for @voicePermissionBody.
  ///
  /// In en, this message translates to:
  /// **'To dictate a meal, Train Libre needs the microphone while you hold the button, and speech recognition to turn what you said into text. Recognition runs on your device whenever it can. Nothing is recorded or kept.'**
  String get voicePermissionBody;

  /// No description provided for @voicePermissionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get voicePermissionContinue;

  /// No description provided for @voiceApplyText.
  ///
  /// In en, this message translates to:
  /// **'Use this text'**
  String get voiceApplyText;

  /// No description provided for @voiceTranscriptHint.
  ///
  /// In en, this message translates to:
  /// **'Recognized text — editable here'**
  String get voiceTranscriptHint;

  /// No description provided for @voiceUnavailablePermission.
  ///
  /// In en, this message translates to:
  /// **'Dictation needs microphone and speech recognition access. You can still type the text.'**
  String get voiceUnavailablePermission;

  /// No description provided for @voiceUnavailableUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This device offers no speech recognition. You can type the text instead.'**
  String get voiceUnavailableUnsupported;

  /// No description provided for @voiceUnavailableFailed.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition could not be started. You can type the text instead.'**
  String get voiceUnavailableFailed;

  /// No description provided for @mealFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get mealFallbackTitle;

  /// No description provided for @mealIngredientCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ingredient} other{{count} ingredients}}'**
  String mealIngredientCount(int count);

  /// No description provided for @mealDetailOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get mealDetailOptions;

  /// No description provided for @mealDetailAddIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get mealDetailAddIngredient;

  /// No description provided for @mealDetailSaveAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save as template'**
  String get mealDetailSaveAsTemplate;

  /// No description provided for @mealDetailSavedAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Saved as a meal template.'**
  String get mealDetailSavedAsTemplate;

  /// No description provided for @mealDetailChangeMealType.
  ///
  /// In en, this message translates to:
  /// **'Change meal type'**
  String get mealDetailChangeMealType;

  /// No description provided for @mealDetailSelectMealType.
  ///
  /// In en, this message translates to:
  /// **'Select meal type'**
  String get mealDetailSelectMealType;

  /// No description provided for @mealDetailAmountInGrams.
  ///
  /// In en, this message translates to:
  /// **'Amount in grams'**
  String get mealDetailAmountInGrams;

  /// No description provided for @mealDetailApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get mealDetailApply;

  /// No description provided for @mealDeleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'What should happen to this meal?'**
  String get mealDeleteQuestion;

  /// No description provided for @mealDeleteUngroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Only remove the grouping'**
  String get mealDeleteUngroupTitle;

  /// No description provided for @mealDeleteUngroupBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The photo and the grouping are removed. The entry stays in the diary on its own — your daily totals do not change.} other{The photo and the grouping are removed. The {count} entries stay in the diary on their own — your daily totals do not change.}}'**
  String mealDeleteUngroupBody(int count);

  /// No description provided for @mealDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the meal and its entries'**
  String get mealDeleteAllTitle;

  /// No description provided for @mealDeleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The photo, the grouping and the entry disappear from the diary. {kcal} kcal are removed from your day.} other{The photo, the grouping and all {count} entries disappear from the diary. {kcal} kcal are removed from your day.}}'**
  String mealDeleteAllBody(int count, int kcal);

  /// No description provided for @reanalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'New result'**
  String get reanalysisTitle;

  /// No description provided for @reanalysisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You decide what stays saved.'**
  String get reanalysisSubtitle;

  /// No description provided for @reanalysisPrevious.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get reanalysisPrevious;

  /// No description provided for @reanalysisNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get reanalysisNew;

  /// No description provided for @reanalysisKeepPrevious.
  ///
  /// In en, this message translates to:
  /// **'Keep current'**
  String get reanalysisKeepPrevious;

  /// No description provided for @reanalysisApplyNew.
  ///
  /// In en, this message translates to:
  /// **'Use the new one'**
  String get reanalysisApplyNew;

  /// No description provided for @reanalysisDiffHint.
  ///
  /// In en, this message translates to:
  /// **'Marked = differs from what is saved'**
  String get reanalysisDiffHint;

  /// No description provided for @aiReviewDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this meal?'**
  String get aiReviewDiscardTitle;

  /// No description provided for @aiReviewDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The analysis has not been saved and will be lost.'**
  String get aiReviewDiscardBody;

  /// No description provided for @aiLidarScaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Send LiDAR scale'**
  String get aiLidarScaleTitle;

  /// No description provided for @aiLidarScaleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Measures distance and frame size in centimetres and passes them to the AI. Switch off to compare whether the estimate actually improves.'**
  String get aiLidarScaleSubtitle;

  /// No description provided for @mealPhotoStorageSection.
  ///
  /// In en, this message translates to:
  /// **'Meal photos (storage)'**
  String get mealPhotoStorageSection;

  /// No description provided for @mealPhotoRetentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Retention period'**
  String get mealPhotoRetentionTitle;

  /// No description provided for @mealPhotoRetentionBody.
  ///
  /// In en, this message translates to:
  /// **'Photos are deleted automatically once the period is over. The nutrition entries in the diary remain.'**
  String get mealPhotoRetentionBody;

  /// No description provided for @mealPhotoRetentionDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String mealPhotoRetentionDays(int days);

  /// No description provided for @mealPhotoRetentionDefaultSuffix.
  ///
  /// In en, this message translates to:
  /// **'(default)'**
  String get mealPhotoRetentionDefaultSuffix;

  /// No description provided for @mealPhotoRetentionUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get mealPhotoRetentionUnlimited;

  /// No description provided for @mealPhotoRetentionSaved.
  ///
  /// In en, this message translates to:
  /// **'Retention period saved.'**
  String get mealPhotoRetentionSaved;

  /// No description provided for @mealPhotoDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all local photos'**
  String get mealPhotoDeleteAll;

  /// No description provided for @mealPhotoDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all meal photos?'**
  String get mealPhotoDeleteAllTitle;

  /// No description provided for @mealPhotoDeleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'Only the image files are removed from the device. Your entries and calories in the diary stay exactly as they are.'**
  String get mealPhotoDeleteAllBody;

  /// No description provided for @mealPhotoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Photos deleted.'**
  String get mealPhotoDeleted;

  /// No description provided for @speechSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice input & dictation'**
  String get speechSectionTitle;

  /// No description provided for @speechOnDeviceActive.
  ///
  /// In en, this message translates to:
  /// **'On-device speech recognition active'**
  String get speechOnDeviceActive;

  /// No description provided for @speechOnDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Spoken meals (“2 eggs with toast and coffee”) are turned into text directly on your device and stay private.'**
  String get speechOnDeviceBody;

  /// No description provided for @aiCaptureTourStepShutterTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture Meal Photos'**
  String get aiCaptureTourStepShutterTitle;

  /// No description provided for @aiCaptureTourStepShutterDesc.
  ///
  /// In en, this message translates to:
  /// **'Take up to 4 photos of your meal from different angles with the shutter. On supported devices, LiDAR automatically captures depth data for even more accurate portion estimates.'**
  String get aiCaptureTourStepShutterDesc;

  /// No description provided for @aiCaptureTourStepBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic Barcode Detection'**
  String get aiCaptureTourStepBarcodeTitle;

  /// No description provided for @aiCaptureTourStepBarcodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Hold packaged foods in front of the camera – barcodes are automatically recognized in real time. Use this button to toggle the live scanner on or off anytime.'**
  String get aiCaptureTourStepBarcodeDesc;

  /// No description provided for @aiCaptureTourBarcodeDemoProduct.
  ///
  /// In en, this message translates to:
  /// **'Organic Rolled Oats 500g'**
  String get aiCaptureTourBarcodeDemoProduct;

  /// No description provided for @aiCaptureTourBarcodeDemoHint.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what it looks like when you scan a barcode!'**
  String get aiCaptureTourBarcodeDemoHint;

  /// No description provided for @aiCaptureTourStepGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select from Library'**
  String get aiCaptureTourStepGalleryTitle;

  /// No description provided for @aiCaptureTourStepGalleryDesc.
  ///
  /// In en, this message translates to:
  /// **'Already took photos of your meal? Choose up to 4 images directly from your photo library.'**
  String get aiCaptureTourStepGalleryDesc;

  /// No description provided for @aiCaptureTourStepVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Dictation'**
  String get aiCaptureTourStepVoiceTitle;

  /// No description provided for @aiCaptureTourStepVoiceDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone to dictate ingredients, brands, or amounts (e.g. \'200g chicken breast with rice\'). AI tidies and analyzes your speech automatically.'**
  String get aiCaptureTourStepVoiceDesc;

  /// No description provided for @aiCaptureTourStepTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Text & Notes'**
  String get aiCaptureTourStepTextTitle;

  /// No description provided for @aiCaptureTourStepTextDesc.
  ///
  /// In en, this message translates to:
  /// **'Add written notes or describe your meal purely via text if you don\'t want to take a photo.'**
  String get aiCaptureTourStepTextDesc;

  /// No description provided for @aiCaptureTourStepAnalyzeTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart AI Analysis'**
  String get aiCaptureTourStepAnalyzeTitle;

  /// No description provided for @aiCaptureTourStepAnalyzeDesc.
  ///
  /// In en, this message translates to:
  /// **'Once a photo, voice transcript, or text is ready, tap Analyze. The AI identifies food items, estimates portions, and matches everything against your nutrition targets.'**
  String get aiCaptureTourStepAnalyzeDesc;

  /// No description provided for @aiCaptureTourReplayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Replay capture guide'**
  String get aiCaptureTourReplayTooltip;

  /// No description provided for @workoutPhotoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get workoutPhotoAdd;

  /// No description provided for @workoutPhotoTake.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get workoutPhotoTake;

  /// No description provided for @workoutPhotoFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get workoutPhotoFromLibrary;

  /// No description provided for @workoutPhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get workoutPhotoRemove;

  /// No description provided for @workoutPhotoRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this photo?'**
  String get workoutPhotoRemoveConfirm;

  /// No description provided for @workoutPhotoLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum of 4 photos reached'**
  String get workoutPhotoLimitReached;

  /// Pagination indicator for workout photo carousel
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String workoutPhotoPagination(int current, int total);

  /// No description provided for @catalogFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get catalogFilterTitle;

  /// No description provided for @catalogFilterBodyRegion.
  ///
  /// In en, this message translates to:
  /// **'Body region'**
  String get catalogFilterBodyRegion;

  /// No description provided for @catalogFilterEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get catalogFilterEquipment;

  /// No description provided for @catalogFilterUsage.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get catalogFilterUsage;

  /// No description provided for @catalogFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get catalogFilterReset;

  /// No description provided for @catalogFilterCombineHint.
  ///
  /// In en, this message translates to:
  /// **'Several picks in one section widen the results; picks across sections narrow them.'**
  String get catalogFilterCombineHint;

  /// No description provided for @catalogFilterDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get catalogFilterDifficulty;

  /// No description provided for @catalogFilterMechanic.
  ///
  /// In en, this message translates to:
  /// **'Mechanic'**
  String get catalogFilterMechanic;

  /// No description provided for @catalogFilterLaterality.
  ///
  /// In en, this message translates to:
  /// **'Sides'**
  String get catalogFilterLaterality;

  /// No description provided for @exerciseDifficultyBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get exerciseDifficultyBeginner;

  /// No description provided for @exerciseDifficultyIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get exerciseDifficultyIntermediate;

  /// No description provided for @exerciseDifficultyAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get exerciseDifficultyAdvanced;

  /// No description provided for @exerciseMechanicCompound.
  ///
  /// In en, this message translates to:
  /// **'Compound'**
  String get exerciseMechanicCompound;

  /// No description provided for @exerciseMechanicIsolation.
  ///
  /// In en, this message translates to:
  /// **'Isolation'**
  String get exerciseMechanicIsolation;

  /// No description provided for @exerciseLateralityBilateral.
  ///
  /// In en, this message translates to:
  /// **'Both sides'**
  String get exerciseLateralityBilateral;

  /// No description provided for @exerciseLateralityUnilateral.
  ///
  /// In en, this message translates to:
  /// **'One side'**
  String get exerciseLateralityUnilateral;

  /// No description provided for @exerciseLateralityAlternating.
  ///
  /// In en, this message translates to:
  /// **'Alternating'**
  String get exerciseLateralityAlternating;

  /// No description provided for @exerciseUsageWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get exerciseUsageWarmup;

  /// No description provided for @exerciseUsageActivation.
  ///
  /// In en, this message translates to:
  /// **'Activation'**
  String get exerciseUsageActivation;

  /// No description provided for @exerciseUsageMainLift.
  ///
  /// In en, this message translates to:
  /// **'Main lift'**
  String get exerciseUsageMainLift;

  /// No description provided for @exerciseUsageAccessory.
  ///
  /// In en, this message translates to:
  /// **'Accessory'**
  String get exerciseUsageAccessory;

  /// No description provided for @exerciseUsageConditioning.
  ///
  /// In en, this message translates to:
  /// **'Conditioning'**
  String get exerciseUsageConditioning;

  /// No description provided for @exerciseUsageFinisher.
  ///
  /// In en, this message translates to:
  /// **'Finisher'**
  String get exerciseUsageFinisher;

  /// No description provided for @exerciseUsageCooldown.
  ///
  /// In en, this message translates to:
  /// **'Cool-down'**
  String get exerciseUsageCooldown;

  /// No description provided for @exerciseUsagePrehab.
  ///
  /// In en, this message translates to:
  /// **'Prehab'**
  String get exerciseUsagePrehab;

  /// No description provided for @exerciseForcePush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get exerciseForcePush;

  /// No description provided for @exerciseForcePull.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get exerciseForcePull;

  /// No description provided for @exerciseForceStatic.
  ///
  /// In en, this message translates to:
  /// **'Static'**
  String get exerciseForceStatic;

  /// No description provided for @exercisePatternHorizontalPush.
  ///
  /// In en, this message translates to:
  /// **'Horizontal push'**
  String get exercisePatternHorizontalPush;

  /// No description provided for @exercisePatternHorizontalPull.
  ///
  /// In en, this message translates to:
  /// **'Horizontal pull'**
  String get exercisePatternHorizontalPull;

  /// No description provided for @exercisePatternVerticalPush.
  ///
  /// In en, this message translates to:
  /// **'Vertical push'**
  String get exercisePatternVerticalPush;

  /// No description provided for @exercisePatternVerticalPull.
  ///
  /// In en, this message translates to:
  /// **'Vertical pull'**
  String get exercisePatternVerticalPull;

  /// No description provided for @exercisePatternSquat.
  ///
  /// In en, this message translates to:
  /// **'Squat'**
  String get exercisePatternSquat;

  /// No description provided for @exercisePatternHinge.
  ///
  /// In en, this message translates to:
  /// **'Hip hinge'**
  String get exercisePatternHinge;

  /// No description provided for @exercisePatternLunge.
  ///
  /// In en, this message translates to:
  /// **'Lunge'**
  String get exercisePatternLunge;

  /// No description provided for @exercisePatternGait.
  ///
  /// In en, this message translates to:
  /// **'Gait'**
  String get exercisePatternGait;

  /// No description provided for @exercisePatternCarry.
  ///
  /// In en, this message translates to:
  /// **'Carry'**
  String get exercisePatternCarry;

  /// No description provided for @exercisePatternRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get exercisePatternRotation;

  /// No description provided for @exercisePatternAntiRotation.
  ///
  /// In en, this message translates to:
  /// **'Anti-rotation'**
  String get exercisePatternAntiRotation;

  /// No description provided for @exercisePatternAntiExtension.
  ///
  /// In en, this message translates to:
  /// **'Anti-extension'**
  String get exercisePatternAntiExtension;

  /// No description provided for @exercisePatternAntiFlexion.
  ///
  /// In en, this message translates to:
  /// **'Anti-flexion'**
  String get exercisePatternAntiFlexion;

  /// No description provided for @exercisePatternAntiLateralFlexion.
  ///
  /// In en, this message translates to:
  /// **'Anti-lateral flexion'**
  String get exercisePatternAntiLateralFlexion;

  /// No description provided for @exercisePatternSpinalFlexion.
  ///
  /// In en, this message translates to:
  /// **'Spinal flexion'**
  String get exercisePatternSpinalFlexion;

  /// No description provided for @exercisePatternSpinalExtension.
  ///
  /// In en, this message translates to:
  /// **'Spinal extension'**
  String get exercisePatternSpinalExtension;

  /// No description provided for @exercisePatternElbowFlexion.
  ///
  /// In en, this message translates to:
  /// **'Elbow flexion'**
  String get exercisePatternElbowFlexion;

  /// No description provided for @exercisePatternElbowExtension.
  ///
  /// In en, this message translates to:
  /// **'Elbow extension'**
  String get exercisePatternElbowExtension;

  /// No description provided for @exercisePatternShoulderFlexion.
  ///
  /// In en, this message translates to:
  /// **'Shoulder flexion'**
  String get exercisePatternShoulderFlexion;

  /// No description provided for @exercisePatternShoulderAbduction.
  ///
  /// In en, this message translates to:
  /// **'Shoulder abduction'**
  String get exercisePatternShoulderAbduction;

  /// No description provided for @exercisePatternScapularElevation.
  ///
  /// In en, this message translates to:
  /// **'Scapular elevation'**
  String get exercisePatternScapularElevation;

  /// No description provided for @exercisePatternHipExtension.
  ///
  /// In en, this message translates to:
  /// **'Hip extension'**
  String get exercisePatternHipExtension;

  /// No description provided for @exercisePatternHipAbduction.
  ///
  /// In en, this message translates to:
  /// **'Hip abduction'**
  String get exercisePatternHipAbduction;

  /// No description provided for @exercisePatternHipAdduction.
  ///
  /// In en, this message translates to:
  /// **'Hip adduction'**
  String get exercisePatternHipAdduction;

  /// No description provided for @exercisePatternKneeFlexion.
  ///
  /// In en, this message translates to:
  /// **'Knee flexion'**
  String get exercisePatternKneeFlexion;

  /// No description provided for @exercisePatternKneeExtension.
  ///
  /// In en, this message translates to:
  /// **'Knee extension'**
  String get exercisePatternKneeExtension;

  /// No description provided for @exercisePatternPlantarFlexion.
  ///
  /// In en, this message translates to:
  /// **'Plantar flexion'**
  String get exercisePatternPlantarFlexion;

  /// No description provided for @exercisePatternDorsiflexion.
  ///
  /// In en, this message translates to:
  /// **'Dorsiflexion'**
  String get exercisePatternDorsiflexion;

  /// No description provided for @exercisePatternWristFlexion.
  ///
  /// In en, this message translates to:
  /// **'Wrist flexion'**
  String get exercisePatternWristFlexion;

  /// No description provided for @exercisePatternWristExtension.
  ///
  /// In en, this message translates to:
  /// **'Wrist extension'**
  String get exercisePatternWristExtension;

  /// No description provided for @settingsDeveloperTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsDeveloperTitle;

  /// No description provided for @settingsDeveloperSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics and experimental options'**
  String get settingsDeveloperSubtitle;

  /// No description provided for @developerLabExperienceSection.
  ///
  /// In en, this message translates to:
  /// **'Experience level'**
  String get developerLabExperienceSection;

  /// No description provided for @developerLabExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience level'**
  String get developerLabExperienceLabel;

  /// No description provided for @developerLabExperienceHint.
  ///
  /// In en, this message translates to:
  /// **'For testing only — the level is not asked during onboarding yet.'**
  String get developerLabExperienceHint;

  /// No description provided for @experienceLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get experienceLevelBeginner;

  /// No description provided for @experienceLevelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get experienceLevelAdvanced;

  /// No description provided for @experienceLevelPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get experienceLevelPro;

  /// No description provided for @experienceLevelBeginnerDescription.
  ///
  /// In en, this message translates to:
  /// **'No RIR and no cardio intensity. Muscles are named by region, e.g. “Shoulders” instead of front, lateral and rear deltoid.'**
  String get experienceLevelBeginnerDescription;

  /// No description provided for @experienceLevelAdvancedDescription.
  ///
  /// In en, this message translates to:
  /// **'No RIR and no cardio intensity. Muscles are named by region, e.g. “Shoulders” instead of front, lateral and rear deltoid.'**
  String get experienceLevelAdvancedDescription;

  /// No description provided for @experienceLevelProDescription.
  ///
  /// In en, this message translates to:
  /// **'RIR and cardio intensity are shown, and muscles keep their precise anatomical names.'**
  String get experienceLevelProDescription;

  /// No description provided for @diaryWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get diaryWeightLabel;

  /// No description provided for @diaryWeightPitch.
  ///
  /// In en, this message translates to:
  /// **'Your calorie target gets more accurate with a weight history'**
  String get diaryWeightPitch;

  /// No description provided for @diaryWeightStaleNudge.
  ///
  /// In en, this message translates to:
  /// **'It has been a while – regular entries keep your calorie target accurate'**
  String get diaryWeightStaleNudge;

  /// No description provided for @diaryWeightLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get diaryWeightLog;

  /// No description provided for @diaryWeightLogLong.
  ///
  /// In en, this message translates to:
  /// **'Log weight'**
  String get diaryWeightLogLong;

  /// No description provided for @diaryWeightDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day ago} other{{days} days ago}}'**
  String diaryWeightDaysAgo(int days);

  /// No description provided for @diaryWeightToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get diaryWeightToday;

  /// No description provided for @diaryWeightRange.
  ///
  /// In en, this message translates to:
  /// **'Outside the usual range'**
  String get diaryWeightRange;

  /// No description provided for @diaryWeightLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load weight.'**
  String get diaryWeightLoadError;

  /// No description provided for @diaryWeightSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save weight. Please try again.'**
  String get diaryWeightSaveError;

  /// No description provided for @diaryWeightRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get diaryWeightRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr', 'it', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
