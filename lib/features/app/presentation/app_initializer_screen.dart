import '../../../core/performance/startup_trace.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../util/design_constants.dart';

import '../../../core/infrastructure/backup_manager.dart';
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../data/database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/local_notification_service.dart';
import '../../workout/presentation/live_workout_view_model.dart';
import 'main_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../nutrition_recommendation/data/recommendation_service.dart';
import '../../profile/data/goal_repository_impl.dart';
import '../../profile/data/legacy_goal_migration.dart';
import '../../profile/domain/services/goal_notification_orchestrator.dart';
import '../../workout/domain/services/workout_plan_notification_orchestrator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../onboarding/data/telemetry_consent_prompt.dart';
import '../../diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';
import '../../diary/presentation/ai_meal_review_reveal_route.dart';

/// A splash screen responsible for app-wide initialization.
///
/// It handles database updates, auto-backup checks, and determines
/// whether to navigate to [OnboardingScreen] or [MainScreen].
class AppInitializerScreen extends StatefulWidget {
  final bool forceUpdate;
  final bool isModal;
  final bool skipOffDatabase;

  const AppInitializerScreen({
    super.key,
    this.forceUpdate = false,
    this.isModal = false,
    this.skipOffDatabase = false,
  });

  @override
  State<AppInitializerScreen> createState() => _AppInitializerScreenState();
}

class _AppInitializerScreenState extends State<AppInitializerScreen> {
  // UI state displayed while initialization is running.
  String _currentTask = '';
  String _currentDetail = '';
  double _progress = 0.0;
  bool _canSkipRemoteCatalog = false;
  bool _skipRemoteCatalogRequested = false;
  bool _isContractingForExit = false;
  _PendingStartupProgress? _pendingProgress;
  bool _progressFrameScheduled = false;

  @override
  void initState() {
    super.initState();
    // Start initialization right after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    if (!widget.isModal) {
      await StartupTrace.instance.measure(
        'core_services',
        _prepareCoreServices,
      );

      // The screen is already visible at this point. Advance it before the
      // catalog work starts so the cloud reflects the complete startup path.
      _setStartupProgress(
        task: 'Initialisiere...',
        detail: 'Vorbereitung...',
        progress: 0.12,
      );

      // Cold Start first launch prompt is handled during onboarding region selection.
    }

    final isOffDbInitialized =
        await BasisDataManager.instance.isOffDatabaseInitialized();
    final skipOffDb =
        widget.skipOffDatabase || (!isOffDbInitialized && !widget.forceUpdate);

    // 1) Run basis-data update checks and stream progress to the UI.
    await BasisDataManager.instance.checkForBasisDataUpdate(
      force: widget.forceUpdate,
      skipOffDatabase: skipOffDb,
      onProgress: (task, detail, progress) {
        _queueStartupProgress(
          task: task,
          detail: detail,
          progress: _screenProgressFor(task, progress),
          canSkipRemoteCatalog: false,
        );
      },
      onRemoteProgress: (task, detail, progress, {required canSkip}) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        _queueStartupProgress(
          task: task,
          detail: _skipRemoteCatalogRequested
              ? l10n.appInitSkippingRemoteDownload
              : detail,
          progress: _screenProgressFor(task, progress),
          canSkipRemoteCatalog: canSkip && !_skipRemoteCatalogRequested,
        );
      },
      isRemoteSkipRequested: () => _skipRemoteCatalogRequested,
    );

    // Show completion feedback before navigation.
    _flushQueuedProgress();
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _currentTask = l10n.appInitFinalizing;
        _currentDetail = l10n.appInitCheckingBackups;
        _progress = 0.97;
        _canSkipRemoteCatalog = false;
      });
    }

    if (widget.isModal) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    // 2) Trigger due auto-backup checks.
    try {
      await StartupTrace.instance.measure(
        'auto_backup_check',
        BackupManager.instance.runAutoBackupIfDue,
      );
    } catch (e) {
      debugPrint("Auto-backup startup failed: $e");
    }

    // 3) Decide target route based on onboarding state.
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') == true;

    if (!mounted) return;

    // Like the AI meal flow, the living cloud first contracts into the calm
    // circle that is the source shape for the vapor reveal.
    setState(() {
      _progress = 1.0;
      _isContractingForExit = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted) return;

    final targetScreen =
        hasSeenOnboarding ? const MainScreen() : const OnboardingScreen();
    // Use the exact, proven reveal route from the AI meal scan instead of a
    // second startup-specific implementation of the vapor transition.
    Navigator.of(context).pushReplacement(
      AiMealReviewRevealRoute<void>(
        originCenter: Offset(
          MediaQuery.sizeOf(context).width / 2,
          MediaQuery.sizeOf(context).height * 0.455,
        ),
        vaporCoreRadius: 42,
        duration: const Duration(milliseconds: 760),
        builder: (_) => targetScreen,
      ),
    );
  }

  /// Converts each catalog's local 0–1 import progress into one continuous
  /// startup journey. A later stage never makes the cloud move backwards.
  double _screenProgressFor(String task, double progress) {
    final normalized = progress.clamp(0.0, 1.0);
    final (start, end) = switch (task) {
      final value when value.contains('Übungen') => (0.12, 0.40),
      final value when value.contains('Basis-Produkte') => (0.40, 0.62),
      final value when value.contains('Kategorien') => (0.62, 0.76),
      final value when value.contains('Produktdatenbank') => (0.76, 0.94),
      _ => (0.12, 0.94),
    };
    return (start + (end - start) * normalized).clamp(_progress, 0.94);
  }

  /// Importers can report many batches per second. Retaining only the newest
  /// update until the next frame protects the raster thread from a burst of
  /// full-screen rebuilds while preserving the visible final progress.
  void _queueStartupProgress({
    required String task,
    required String detail,
    required double progress,
    required bool canSkipRemoteCatalog,
  }) {
    if (!mounted) return;
    _pendingProgress = _PendingStartupProgress(
      task: task,
      detail: detail,
      progress: progress,
      canSkipRemoteCatalog: canSkipRemoteCatalog,
    );
    if (_progressFrameScheduled) return;
    _progressFrameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _progressFrameScheduled = false;
      _flushQueuedProgress();
    });
  }

  void _flushQueuedProgress() {
    final update = _pendingProgress;
    _pendingProgress = null;
    if (!mounted || update == null) return;
    _setStartupProgress(
      task: update.task,
      detail: update.detail,
      progress: update.progress,
      canSkipRemoteCatalog: update.canSkipRemoteCatalog,
    );
  }

  void _setStartupProgress({
    required String task,
    required String detail,
    required double progress,
    bool? canSkipRemoteCatalog,
  }) {
    if (!mounted) return;
    setState(() {
      _currentTask = task;
      _currentDetail = detail;
      _progress = progress.clamp(_progress, 1.0);
      if (canSkipRemoteCatalog != null) {
        _canSkipRemoteCatalog = canSkipRemoteCatalog;
      }
    });
  }

  Future<void> _prepareCoreServices() async {
    LiveWorkoutViewModel? workoutSessionManager;
    try {
      workoutSessionManager = context.read<LiveWorkoutViewModel>();
    } catch (_) {
      workoutSessionManager = null;
    }

    final tasks = <Future<void>>[
      StartupTrace.instance
          .measure(
        'standard_supplements',
        DatabaseHelper.instance.ensureStandardSupplements,
      )
          .catchError((e) {
        debugPrint("Standard supplement setup failed: $e");
      }),
      // Counts this launch towards the telemetry follow-up's threshold, and
      // anchors installations that predate the prompt. Swallows its own
      // errors; it must never hold up a launch.
      () async {
        final isOptedIn = await TelemetryService.instance.isOptedIn();
        await TelemetryConsentPrompt.instance
            .registerLaunch(isOptedIn: isOptedIn);
      }()
          .catchError((e) {
        debugPrint("Telemetry follow-up launch registration failed: $e");
      }),
      StartupTrace.instance.measure(
        'notifications_init',
        () async {
          await LocalNotificationService.instance.initialize();
          try {
            await LegacyGoalMigration().run();
            await AdaptiveNutritionRecommendationService()
                .refreshRecommendationIfDue();
            await GoalNotificationOrchestrator(
              goalRepository: GoalRepositoryImpl(),
            ).synchronize();
            await WorkoutPlanNotificationOrchestrator().synchronize();
          } catch (e) {
            debugPrint("Startup goal/recommendation check failed: $e");
          }
        },
      ).catchError((e) {
        debugPrint("Local notification initialization failed: $e");
      }),
      if (workoutSessionManager != null)
        StartupTrace.instance
            .measure(
          'workout_restore',
          workoutSessionManager.tryRestoreSession,
        )
            .catchError((e) {
          debugPrint("Workout session restore failed: $e");
        }),
      StartupTrace.instance.measure(
        'telemetry_init',
        () async {
          await TelemetryService.instance.init();
          final packageInfo = await PackageInfo.fromPlatform();
          final (localeStr, countryCode) =
              TelemetryService.resolveSystemLocaleAndCountry();

          unawaited(TelemetryService.instance.trackAppLaunched(
            appVersion: packageInfo.version,
            osVersion: Platform.operatingSystemVersion,
            platform: Platform.operatingSystem,
            locale: localeStr,
            country: countryCode,
          ));
        },
      ).catchError((e) {
        debugPrint("Telemetry startup tracking failed: $e");
      }),
    ];

    await Future.wait(tasks);
  }

  String _getLocalizedProgress(BuildContext context, String raw) {
    if (raw.isEmpty) return '';
    final l10n = AppLocalizations.of(context)!;

    if (raw == 'Prüfe Übungen...') {
      return l10n.initCheckingExercises;
    } else if (raw == 'Update Übungen') {
      return l10n.initUpdateTask(l10n.shareExercisesLabel);
    } else if (raw == 'Übungen bereit') {
      return l10n.initExercisesReady;
    } else if (raw == 'Übungen aktuell') {
      return l10n.initExercisesUpToDate;
    } else if (raw == 'Lade Übungen...') {
      return l10n.initLoadingExercises;
    } else if (raw == 'Basis-Produkte') {
      return l10n.tabBaseFoods;
    } else if (raw == 'Update Basis-Produkte') {
      return l10n.initUpdateTask(l10n.tabBaseFoods);
    } else if (raw == 'Prüfe Basis-Produkte...') {
      return l10n.initCheckingTask(l10n.tabBaseFoods);
    } else if (raw == 'Basis-Produkte aktuell') {
      return l10n.initTaskUpToDate(l10n.tabBaseFoods);
    } else if (raw == 'Kategorien') {
      return l10n.category_label;
    } else if (raw == 'Update Kategorien') {
      return l10n.initUpdateTask(l10n.category_label);
    } else if (raw == 'Prüfe Kategorien...') {
      return l10n.initCheckingTask(l10n.category_label);
    } else if (raw == 'Kategorien aktuell') {
      return l10n.initTaskUpToDate(l10n.category_label);
    } else if (raw == 'Remote-Manifest wird geladen...') {
      return l10n.initLoadingRemoteManifest;
    } else if (raw == 'Kein Remote-Download erforderlich.') {
      return l10n.initNoDownloadRequired;
    } else if (raw == 'Download wird verifiziert...') {
      return l10n.initPreparingImport;
    } else if (raw == 'Download wird für den Import vorbereitet...') {
      return l10n.initPreparingImport;
    } else if (raw == 'Basis-Produkte sind aktuell.') {
      return l10n.initTaskUpToDate(l10n.tabBaseFoods);
    } else if (raw == 'Kategorien sind aktuell.') {
      return l10n.initTaskUpToDate(l10n.category_label);
    } else if (raw == 'Initialisiere...') {
      return l10n.initInitializing;
    } else if (raw == 'Vorbereitung...') {
      return l10n.initPreparation;
    } else if (raw == 'Bereit') {
      return l10n.initReady;
    } else if (raw == 'Suche nach Remote-Katalog-Updates...') {
      return l10n.initCheckingExercises;
    } else if (raw == 'Suche nach Remote-OFF-Katalog-Updates...') {
      return l10n.initLoadingRemoteManifest;
    } else if (raw ==
        'Kein OFF-Bundle/Remote verfügbar. Vorhandene lokale OFF-Daten bleiben unverändert.') {
      return l10n.initNoOffBundle;
    }

    if (raw.startsWith('Remote-Übungskatalog ') &&
        raw.endsWith(' wird heruntergeladen.')) {
      final version = raw.substring(21, raw.length - 21);
      return l10n.initDownloadingRemoteCatalog(version);
    }
    if (raw.startsWith('Remote-Übungskatalog ') &&
        raw.endsWith(' wird importiert.')) {
      final version = raw.substring(21, raw.length - 17);
      return l10n.initImportingRemoteCatalog(version);
    }
    if (raw.startsWith('Remote-Katalog ') && raw.endsWith(' gefunden.')) {
      final version = raw.substring(15, raw.length - 10);
      return l10n.initImportingRemoteCatalog(version);
    }
    if (raw.startsWith('Remote-OFF-Katalog ') &&
        raw.endsWith(' wird heruntergeladen.')) {
      final version = raw.substring(19, raw.length - 21);
      return l10n.initDownloadingProductBundle(version);
    }
    if (raw.startsWith('Remote-OFF-Katalog ') &&
        raw.endsWith(' wird importiert.')) {
      final version = raw.substring(19, raw.length - 17);
      return l10n.initImportingProductBundle(version);
    }
    if (raw.startsWith('Remote-OFF-Katalog ') && raw.endsWith(' gefunden.')) {
      final version = raw.substring(19, raw.length - 10);
      return l10n.initImportingProductBundle(version);
    }
    if (raw.startsWith('OFF-Datenbank ist aktuell (Version: ') &&
        raw.endsWith(').')) {
      return l10n.initProductDatabaseUpToDate;
    }

    final checkDbReg = RegExp(r'^Prüfe Produktdatenbank \((.+)\)\.\.\.$');
    if (checkDbReg.hasMatch(raw)) {
      final country = checkDbReg.firstMatch(raw)!.group(1) ?? '';
      return l10n.initCheckingProductDatabase(country);
    }

    final dbAktuellReg = RegExp(r'^Produktdatenbank \((.+)\) aktuell$');
    if (dbAktuellReg.hasMatch(raw)) {
      return l10n.initProductDatabaseUpToDate;
    }

    final ladeDbReg = RegExp(r'^Lade Produktdatenbank \((.+)\)\.\.\.$');
    if (ladeDbReg.hasMatch(raw)) {
      return l10n.initLoadingProductDatabase;
    }

    final dbBereitReg = RegExp(r'^Produktdatenbank \((.+)\) bereit$');
    if (dbBereitReg.hasMatch(raw)) {
      return l10n.initProductDatabaseReady;
    }

    final updateDbReg = RegExp(r'^Update Produktdatenbank \((.+)\)$');
    if (updateDbReg.hasMatch(raw)) {
      final country = updateDbReg.firstMatch(raw)!.group(1) ?? '';
      return l10n.initUpdateTask(
          l10n.initCheckingProductDatabase(country).replaceAll('...', ''));
    }

    final dbReg = RegExp(r'^Produktdatenbank \((.+)\)$');
    if (dbReg.hasMatch(raw)) {
      final country = dbReg.firstMatch(raw)!.group(1) ?? '';
      return l10n.initCheckingProductDatabase(country).replaceAll('...', '');
    }

    final uebersetzungenReg = RegExp(r'^(\d+)\s*/\s*(\d+)\s+Übersetzungen$');
    if (uebersetzungenReg.hasMatch(raw)) {
      final match = uebersetzungenReg.firstMatch(raw)!;
      final processed = match.group(1) ?? '';
      final total = match.group(2) ?? '';
      return l10n.initEntriesProgress(processed, total);
    }

    if (raw == 'Bereinige veraltete OFF-Daten...') {
      return l10n.initPreparation;
    }

    final eintraegeReg = RegExp(r'^(\d+)\s*/\s*(\d+)\s+Einträge$');
    if (eintraegeReg.hasMatch(raw)) {
      final match = eintraegeReg.firstMatch(raw)!;
      final processed = match.group(1) ?? '';
      final total = match.group(2) ?? '';
      return l10n.initEntriesProgress(processed, total);
    }

    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final percentage = (_progress * 100).round();

    final displayTask = _currentTask.isEmpty
        ? l10n.appInitStarting
        : _getLocalizedProgress(context, _currentTask);

    final displayDetail = _currentDetail.isEmpty
        ? l10n.appInitInitializing
        : _getLocalizedProgress(context, _currentDetail);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: l10n.appInitStarting,
              value: '$percentage%',
              child: _buildStartupCloud(theme),
            ),
            const SizedBox(height: 28),

            // Main status text.
            Text(
              displayTask,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),

            // Secondary detail text.
            Text(
              displayDetail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_canSkipRemoteCatalog) ...[
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _skipRemoteCatalogRequested = true;
                      _canSkipRemoteCatalog = false;
                      _currentDetail = l10n.appInitSkippingRemoteDownload;
                    });
                  },
                  icon: const Icon(LucideIcons.skip_forward),
                  label: Text(l10n.appInitSkipDownload),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStartupCloud(ThemeData theme) {
    final cloud = RepaintBoundary(
      child: AiNeuralCloudOrbWidget(
        size: 172,
        // Stage 1 is already the living, uncoloured cloud. The startup
        // percentage only charges its colour; it contracts only for the
        // intentional vapor exit.
        morph: _isContractingForExit ? 0 : 1,
        // Fade the charged colour back to the same base tone as the vapor
        // during the contraction, so circle and first vapor frame meet.
        tint: _isContractingForExit ? 0 : _progress,
        // This is a small, isolated vector paint. The slow flow keeps the
        // intended alive-at-rest feel, while the disabled ambient glow avoids
        // an expensive fullscreen-style blur.
        animate: true,
        flowSpeed: 0.35,
        showAmbientGlow: false,
        baseColor: theme.colorScheme.onSurfaceVariant,
        accentColor: theme.colorScheme.primary,
      ),
    );
    return cloud;
  }
}

class _PendingStartupProgress {
  const _PendingStartupProgress({
    required this.task,
    required this.detail,
    required this.progress,
    required this.canSkipRemoteCatalog,
  });

  final String task;
  final String detail;
  final double progress;
  final bool canSkipRemoteCatalog;
}
