// lib/screens/app_initializer_screen.dart

import 'package:flutter/material.dart';
import '../../../util/design_constants.dart';

import '../../../core/infrastructure/backup_manager.dart';
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../data/database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/local_notification_service.dart';
import '../../workout/presentation/live_workout_view_model.dart';
import 'main_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

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
  bool _isDone = false;
  bool _canSkipRemoteCatalog = false;
  bool _skipRemoteCatalogRequested = false;

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
      await _prepareCoreServices();

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
        if (!mounted) return;
        setState(() {
          _currentTask = task;
          _currentDetail = detail;
          _progress = progress;
          _canSkipRemoteCatalog = false;
        });
      },
      onRemoteProgress: (task, detail, progress, {required canSkip}) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _currentTask = task;
          _currentDetail = _skipRemoteCatalogRequested
              ? l10n.appInitSkippingRemoteDownload
              : detail;
          _progress = progress;
          _canSkipRemoteCatalog = canSkip && !_skipRemoteCatalogRequested;
        });
      },
      isRemoteSkipRequested: () => _skipRemoteCatalogRequested,
    );

    // Show completion feedback before navigation.
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _currentTask = l10n.appInitFinalizing;
        _currentDetail = l10n.appInitCheckingBackups;
        _progress = 1.0;
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
      await BackupManager.instance.runAutoBackupIfDue();
    } catch (e) {
      debugPrint("Auto-backup startup failed: $e");
    }

    // 3) Decide target route based on onboarding state.
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') == true;

    if (!mounted) return;

    // Navigate to the next screen.
    setState(() => _isDone = true);

    Widget targetScreen =
        hasSeenOnboarding ? const MainScreen() : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => targetScreen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _prepareCoreServices() async {
    LiveWorkoutViewModel? workoutSessionManager;
    try {
      workoutSessionManager = context.read<LiveWorkoutViewModel>();
    } catch (_) {
      workoutSessionManager = null;
    }

    try {
      await DatabaseHelper.instance.ensureStandardSupplements();
    } catch (e) {
      debugPrint("Standard supplement setup failed: $e");
    }

    try {
      await LocalNotificationService.instance.initialize();
    } catch (e) {
      debugPrint("Local notification initialization failed: $e");
    }

    if (workoutSessionManager != null) {
      try {
        await workoutSessionManager.tryRestoreSession();
      } catch (e) {
        debugPrint("Workout session restore failed: $e");
      }
    }
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
    // If initialization is done, render an empty container until navigation completes.
    if (_isDone) {
      return Container(color: Theme.of(context).scaffoldBackgroundColor);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

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
            // Icon shown during startup.
            Icon(
              LucideIcons.download,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 40),

            // Main status text.
            Text(
              displayTask,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),

            // Progress bar.
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress > 0
                    ? _progress
                    : null, // null renders an indeterminate spinner style.
                minHeight: 8,
                backgroundColor: isDark
                    ? Colors.white10
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),

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
}
