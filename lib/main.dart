// lib/main.dart

import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'util/design_constants.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/sleep/presentation/sleep_navigation.dart';
import 'generated/app_localizations.dart';
import 'navigation/app_route_observer.dart';
// App startup routing is delegated to the dedicated initializer screen.
import 'features/app/presentation/app_initializer_screen.dart';
import 'services/profile_service.dart';
import 'services/unit_service.dart';
import 'features/workout/presentation/live_workout_view_model.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'theme/app_colors.dart';
import 'package:intl/date_symbol_data_local.dart'; // FIX: Initialize intl formatting
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'features/onboarding/presentation/initial_consent_screen.dart';
import 'features/onboarding/presentation/legal_update_consent_screen.dart';
import 'features/app/presentation/legal_screen.dart';
import 'core/infrastructure/icloud_sync_service.dart';

import 'features/diary/domain/repositories/diary_repository.dart';
import 'features/diary/data/nutrition_repository.dart';
import 'features/workout/domain/repositories/workout_repository.dart';
import 'features/workout/data/workout_repository.dart';
import 'features/exercise_catalog/domain/repositories/exercise_catalog_repository.dart';
import 'features/exercise_catalog/data/exercise_catalog_repository.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'data/drift_database.dart' as db;
import 'data/database_helper.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/diary/data/sources/diary_local_data_source.dart';
import 'features/workout/data/sources/workout_local_data_source.dart';
import 'features/exercise_catalog/data/sources/exercise_catalog_local_data_source.dart';
import 'features/profile/data/sources/profile_local_data_source.dart';
import 'features/supplements/domain/repositories/supplement_repository.dart';
import 'features/supplements/data/supplement_repository_impl.dart';
import 'features/supplements/data/sources/supplement_local_data_source.dart';
import 'package:workmanager/workmanager.dart';
import 'features/nutrition_recommendation/data/recommendation_service.dart';
import 'services/local_notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      
      final database = db.AppDatabase();
      DatabaseHelper.setDriftDb(database);
      
      await LocalNotificationService.instance.initialize();
      
      final service = AdaptiveNutritionRecommendationService(
        databaseHelper: DatabaseHelper.instance,
      );
      
      // Attempt to generate/refresh if due, which will also notify the user
      // via the stream in LocalNotificationService.
      await service.refreshRecommendationIfDue();
      
      return Future.value(true);
    } catch (e) {
      debugPrint("Background task error: $e");
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Liquid Glass shaders and pipeline
  await LiquidGlassWidgets.initialize();

  // FIX: Ensures DateFormat does not throw LocaleDataException on non-en_US locales.
  await initializeDateFormatting();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final hasAcceptedConsent = prefs.getBool('hasAcceptedConsent') ?? false;
  final acceptedLegalVersion = prefs.getString('acceptedLegalVersion');

  final isFreshInstall = !hasAcceptedConsent && acceptedLegalVersion == null;
  final isLegalOutdated = acceptedLegalVersion != kCurrentLegalVersion;

  // Load previously settled glass quality to avoid warmup jank on cold starts
  final savedGlassQuality = prefs.getString('glass_quality');
  final initialGlassQuality = savedGlassQuality != null
      ? GlassQuality.values.byName(savedGlassQuality)
      : null;

  final database = db.AppDatabase();
  DatabaseHelper.setDriftDb(database);
  final diaryLocalDataSource = DiaryLocalDataSource(database);
  final workoutLocalDataSource = WorkoutLocalDataSource(database);
  final exerciseCatalogLocalDataSource =
      ExerciseCatalogLocalDataSource(database);
  final profileLocalDataSource = ProfileLocalDataSource(database);
  final supplementLocalDataSource = SupplementLocalDataSource(database);

  final workoutRepository =
      WorkoutRepository(localDataSource: workoutLocalDataSource);

  final themeService = ThemeService(); // Create an instance
  final unitService = UnitService();

  // Create the workout session manager before injecting it. Restoration is
  // handled by AppInitializerScreen after the first frame is visible.
  final workoutSessionManager = LiveWorkoutViewModel(
      repository: workoutRepository, unitService: unitService);

  // Start the app with all required providers and Liquid Glass Setup.
  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      adaptiveConfig: GlassAdaptiveScopeConfig(
        initialQuality: initialGlassQuality ?? DesignConstants.defaultGlassQuality,
        maxQuality: DesignConstants.defaultGlassQuality,
        allowStepUp: true,
        onQualityChanged: (_, to) => prefs.setString('glass_quality', to.name),
      ),
      child: MultiProvider(
        providers: [
          Provider<IDiaryRepository>(
            create: (_) => NutritionRepository(
              localDataSource: diaryLocalDataSource,
            ),
          ),
          Provider<IWorkoutRepository>.value(value: workoutRepository),
          Provider<SupplementRepository>(
            create: (_) => SupplementRepositoryImpl(
              localDataSource: supplementLocalDataSource,
            ),
          ),
          Provider<IExerciseCatalogRepository>(
            create: (_) => ExerciseCatalogRepository(
              localDataSource: exerciseCatalogLocalDataSource,
            ),
          ),
          Provider<IProfileRepository>(
            create: (_) => ProfileRepository(
              localDataSource: profileLocalDataSource,
            ),
          ),
          ChangeNotifierProvider.value(value: workoutSessionManager),
          ChangeNotifierProvider(
            create: (context) {
              final profileService = ProfileService();
              final repository = context.read<IProfileRepository>();
              profileService.initialize(repository);
              return profileService;
            },
          ),
          ChangeNotifierProvider.value(value: unitService),
          ChangeNotifierProvider.value(value: themeService),
        ],
        child: MyApp(
          home: isFreshInstall
              ? const InitialConsentScreen(
                  nextScreen:
                      AppInitializerScreen(skipOffDatabase: true))
              : (isLegalOutdated
                  ? const LegalUpdateConsentScreen(
                      nextScreen:
                          AppInitializerScreen(skipOffDatabase: true))
                  : const AppInitializerScreen(skipOffDatabase: true)),
        ),
      ),
    ),
  );

  // Background update checks are handled by AppInitializerScreen.
  Workmanager().initialize(
    callbackDispatcher,
  );
  
  Workmanager().registerPeriodicTask(
    "1",
    "tdeeCalculationTask",
    frequency: const Duration(hours: 12),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

/// The entry point of the Train Libre application.
///
/// This application is a fitness tracker that allows users to log workouts,
/// manage supplements, and track body measurements.
class RestartWidget extends StatefulWidget {
  final Widget child;

  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
}

class MyApp extends StatefulWidget {
  final Widget home;

  /// Creates the root widget for the application.
  const MyApp({super.key, required this.home});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: _onAppPause,
      onHide: _onAppPause,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  /// Silently snapshot and upload the database to iCloud when the app is
  /// backgrounded. Only runs if the user has enabled iCloud sync.
  Future<void> _onAppPause() async {
    final db = DatabaseHelper.driftDb;
    if (db == null) return;
    // Fire-and-forget — we intentionally do not await so the UI is never
    // blocked by the sync operation.
    unawaited(ICloudSyncService.instance.syncIfEnabled(db));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    const cardDark = Color(0xFF171717);
    const cardLight = Color(0xFFF3F3F3);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final themeService = context.watch<ThemeService>();
        final isAndroid =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
        final useDynamicMaterialColors =
            isAndroid && themeService.materialColorsEnabled;

        // Use brand accent by default; optional Android toggle enables dynamic Material colors.
        final Color lightSeed = useDynamicMaterialColors
            ? (lightDynamic?.primary ??
                DesignConstants.brandAccentColorLightMode)
            : DesignConstants.brandAccentColorLightMode;
        final Color darkSeed = useDynamicMaterialColors
            ? (darkDynamic?.primary ?? DesignConstants.brandAccentColor)
            : DesignConstants.brandAccentColor;

        // --- Light scheme from seed, but without Material You UI ---
        final lightScheme = ColorScheme.fromSeed(
          seedColor: lightSeed,
          brightness: Brightness.light,
        ).copyWith(
          primary: lightSeed,
          onPrimary: Colors.black,
          surface: Colors.white,
          error: DesignConstants.brandRedColor,
        );

        // --- Dark scheme from seed + OLED black ---
        final seededDark = ColorScheme.fromSeed(
          seedColor: darkSeed,
          brightness: Brightness.dark,
        );
        final darkScheme = seededDark.copyWith(
          primary: darkSeed,
          onPrimary: Colors.black,
          surface: Colors.black,
          surfaceDim: Colors.black,
          surfaceBright: Colors.black,
          surfaceContainerLowest: Colors.black,
          surfaceContainerLow: Colors.black,
          surfaceContainer: Colors.black,
          surfaceContainerHigh: Colors.black,
          surfaceContainerHighest: Colors.black,
          error: DesignConstants.brandRedColor,
        );

        // --- Light theme (Material 2, but with ColorScheme from seed) ---
        final baseLightTheme = ThemeData(
          useMaterial3: false, // No Material You
          colorScheme: lightScheme,
          extensions: [
            AppSurfaces(summaryCard: cardLight),
            MacroColors(
              calories: Colors.orange,
              protein: Theme.of(context).colorScheme.error,
              carbs: Colors.green.shade400,
              fat: Colors.purple.shade300,
              water: Colors.blue,
              sugar: Colors.pink.shade200,
              fiber: Colors.brown.shade400,
              salt: Theme.of(context).colorScheme.onSurfaceVariant,
              caffeine: Colors.brown,
            ),
          ],
          primaryColor: lightScheme.primary, // Accent in Material 2 contexts
          scaffoldBackgroundColor: const Color(0xFFF2F2F2),
          canvasColor: Colors.white,
          cardColor: cardLight,

          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,

          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            },
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF3F3F3),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
              borderSide: BorderSide(color: lightScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingM,
              vertical: DesignConstants.spacingM,
            ),
          ),

          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: cardLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            elevation: 0,
          ),

          snackBarTheme: SnackBarThemeData(
            backgroundColor: lightScheme.primary,
            contentTextStyle: TextStyle(
              color: lightScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
            ),
          ),

          dividerTheme: DividerThemeData(
            color: Colors.black.withValues(alpha: 0.08),
            thickness: 1,
            space: 24,
          ),

          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            headlineLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            headlineMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            headlineSmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            titleLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            titleMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            bodyLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Colors.black87,
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.black87,
            ),
            bodySmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.black54,
            ),
            labelLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF757575), // grey[600]
              letterSpacing: 0.2,
            ),
            labelMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
            labelSmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: lightScheme.primary,
              foregroundColor: lightScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusM),
              ),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: lightScheme.primary,
            foregroundColor: lightScheme.onPrimary,
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
            color: lightScheme.primary,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: lightScheme.primary,
            selectionColor: lightScheme.primary.withValues(alpha: 0.25),
            selectionHandleColor: lightScheme.primary,
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.all(lightScheme.primary),
          ),
          radioTheme: RadioThemeData(
            fillColor: WidgetStateProperty.all(lightScheme.primary),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return lightScheme.outline;
            }),
            trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return lightScheme.primary;
              }
              return lightScheme.surfaceContainerHighest;
            }),
            trackOutlineColor:
                WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.transparent;
              }
              return lightScheme.outline;
            }),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: cardLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );

        // --- Dark theme (Material 2, OLED, accent from seed) ---
        final baseDarkTheme = ThemeData(
          useMaterial3: false, // No Material You
          colorScheme: darkScheme,
          extensions: [
            AppSurfaces(summaryCard: cardDark),
            MacroColors(
              calories: Colors.orange,
              protein: Theme.of(context).colorScheme.error,
              carbs: Colors.green.shade400,
              fat: Colors.purple.shade300,
              water: Colors.blue,
              sugar: Colors.pink.shade200,
              fiber: Colors.brown.shade400,
              salt: Theme.of(context).colorScheme.onSurfaceVariant,
              caffeine: Colors.brown,
            ),
          ],
          primaryColor: darkScheme.primary, // Accent in Material 2 contexts
          scaffoldBackgroundColor: Colors.black,
          canvasColor: Colors.black,
          cardColor: cardDark,

          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,

          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            },
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1C1C1C),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
              borderSide: BorderSide(color: darkScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingM,
              vertical: DesignConstants.spacingM,
            ),
          ),

          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            elevation: 0,
          ),

          snackBarTheme: SnackBarThemeData(
            backgroundColor: darkScheme.primary,
            contentTextStyle: TextStyle(
              color: darkScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
            ),
          ),

          dividerTheme: DividerThemeData(
            color: Colors.white.withValues(alpha: 0.08),
            thickness: 1,
            space: 24,
          ),

          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headlineLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headlineMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headlineSmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titleLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titleMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            bodyLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Colors.white,
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.white,
            ),
            bodySmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.white,
            ),
            labelLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
            labelMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            labelSmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkScheme.primary,
              foregroundColor: darkScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusM),
              ),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: darkScheme.primary,
            foregroundColor: darkScheme.onPrimary,
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
            color: darkScheme.primary,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: darkScheme.primary,
            selectionColor: darkScheme.primary.withValues(alpha: 0.35),
            selectionHandleColor: darkScheme.primary,
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.all(darkScheme.primary),
          ),
          radioTheme: RadioThemeData(
            fillColor: WidgetStateProperty.all(darkScheme.primary),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return darkScheme.onPrimary;
              }
              return darkScheme.outline;
            }),
            trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return darkScheme.primary;
              }
              return darkScheme.surfaceContainerHighest;
            }),
            trackOutlineColor:
                WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.transparent;
              }
              return darkScheme.outline;
            }),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );

        return MaterialApp(
          navigatorKey: _navigatorKey,
          navigatorObservers: [appRouteObserver],
          debugShowCheckedModeBanner: false,
          scrollBehavior: NoGlowScrollBehavior(),
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          title: "Train Libre",
          theme: baseLightTheme,
          darkTheme: baseDarkTheme,
          themeMode: themeService.themeMode,
          onGenerateRoute: SleepNavigation.onGenerateRoute,
          builder: (context, child) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            );
          },
          home: widget.home,
        );
      },
    );
  }
}

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // No glow effects
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // iOS-Style: Bouncing
    return const BouncingScrollPhysics();
  }
}
