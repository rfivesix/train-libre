// lib/screens/data_management_screen.dart (final and complete)

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../../core/infrastructure/backup_manager.dart';
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../core/infrastructure/export_manager.dart';
import '../../../core/infrastructure/import_manager.dart';
import '../../../generated/app_localizations.dart';
import '../../../widgets/common/summary_card.dart';
import '../../app/presentation/app_initializer_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../onboarding/presentation/initial_consent_screen.dart';
import '../../exercise_catalog/presentation/exercise_mapping_screen.dart';
import '../../../services/local_app_data_reset_service.dart';
import '../../workout/presentation/live_workout_view_model.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart'; // New
import 'package:flutter/services.dart'; // New (Clipboard)
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../services/storage/saf_storage_service.dart';
import '../../../widgets/common/long_running_operation_overlay.dart';
import '../../../util/cancellation_token.dart';
import 'widgets/data_backup_card.dart';
import 'widgets/data_auto_backup_card.dart';
import 'widgets/local_data_deletion_card.dart';
import 'widgets/csv_export_card.dart';
import 'widgets/migration_card.dart';
import 'widgets/exercise_mapping_card.dart';
import 'widgets/icloud_sync_card.dart';
import '../../../core/infrastructure/icloud_sync_service.dart';
import '../../../data/database_helper.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/app_button.dart';
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';

/// A screen for managing application data and backups.
///
/// Provides tools for manual and automated backups (JSON), CSV exports for
/// nutrition and workouts, and importing data from third-party services.
class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({
    super.key,
    LocalAppDataResetter? localDataResetter,
    VoidCallback? onResetComplete,
  })  : _localDataResetter = localDataResetter,
        _onResetComplete = onResetComplete;

  final LocalAppDataResetter? _localDataResetter;
  final VoidCallback? _onResetComplete;

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  // Loading states for the different actions
  bool _isCsvExportRunning = false;
  final bool _isMigrationRunning = false;
  bool _isLocalResetRunning = false;
  String? _autoBackupDir; // New
  String? _lastAutoBackupFilePath;
  String? _lastAutoBackupDirUsed;
  String? _lastAutoBackupError;
  bool _lastAutoBackupUsedFallback = false;
  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.dataManagement));
    _loadAutoBackupDir(); // New
  }

  Future<void> _loadAutoBackupDir() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoBackupDir = prefs.getString('auto_backup_dir');
      _lastAutoBackupFilePath = prefs.getString('auto_backup_last_file_path');
      _lastAutoBackupDirUsed = prefs.getString('auto_backup_last_dir_used');
      _lastAutoBackupError = prefs.getString('auto_backup_last_error');
      _lastAutoBackupUsedFallback =
          prefs.getBool('auto_backup_last_used_fallback') ?? false;
    });
  }

  // --- Unchanged: full-backup logic ---
  void _performFullExport() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    bool success = false;
    bool wasCanceled = false;

    try {
      success = await LongRunningOperationOverlay.run(
        context: context,
        title: l10n.backupExportTitle,
        initialStatus: l10n.backupExportTitle,
        icon: LucideIcons.upload,
        operation: (token, updateProgress) async {
          await BackupManager.instance.exportFullBackup(token, (
            tableName,
            progress,
          ) {
            final statusText = l10n.progressExportingTable(tableName);
            updateProgress(statusText, progress);
          });
        },
      );
    } catch (e) {
      if (e is OperationCanceledException) {
        wasCanceled = true;
      }
      success = false;
    }

    if (success) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.snackbarExportSuccess)),
      );
    } else if (!wasCanceled) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.snackbarExportFailed),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _performFullImport() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final wgerInitialized =
        await BasisDataManager.instance.isExerciseCatalogInitialized();
    if (!mounted) return;

    if (!wgerInitialized) {
      await BasisDataManager.instance.promptOffDatabaseDownloadIfFirstTime(
        context,
      );
      return;
    }

    final filePath = result.files.single.path!;
    final confirmed = await showDeleteConfirmation(
      context,
      title: l10n.dialogConfirmTitle,
      content: l10n.dialogConfirmImportContent,
      confirmLabel: l10n.dialogButtonOverwrite,
    );

    if (confirmed == true) {
      bool success = false;
      bool wasCanceled = false;

      Future<bool> runImport([String? passphrase]) async {
        try {
          return await LongRunningOperationOverlay.run(
            context: context,
            title: l10n.backupImportTitle,
            initialStatus: l10n.backupImportTitle,
            icon: LucideIcons.download,
            operation: (token, updateProgress) async {
              await BackupManager.instance.importFullBackupAuto(
                filePath,
                passphrase: passphrase,
                token: token,
                onProgress: (tableName, progress) {
                  final statusText = l10n.progressImportingTable(tableName);
                  updateProgress(statusText, progress);
                },
              );
            },
          );
        } catch (e) {
          if (e is OperationCanceledException) {
            wasCanceled = true;
          }
          return false;
        }
      }

      success = await runImport();

      if (!success && !wasCanceled) {
        // File may be encrypted or failed; ask for password
        final pw = await _askPassword(title: l10n.dialogEnterPasswordImport);
        if (pw != null) {
          success = await runImport(pw);
        }
      }

      if (success) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const OnboardingScreen(forceImportMode: true),
          ),
          (route) => false,
        );
      } else {
        if (!wasCanceled) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.snackbarImportError),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  // --- Externer Workout-Import (neutral) ---
  void _performWorkoutImport() async {
    final l10n = AppLocalizations.of(context)!;

    // 1. Ask for unit
    final bool? isImperial = await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.importUnitSelectionTitle,
      contentBuilder: (ctx, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.importUnitSelectionDescription),
          const SizedBox(height: DesignConstants.spacingL),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  label: l10n.unitMetricLabel,
                  tooltip: l10n.unitMetricLabel,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.secondary(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  label: l10n.unitImperialLabel,
                  tooltip: l10n.unitImperialLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isImperial == null) return;

    int count = 0;
    bool wasCanceled = false;

    if (!mounted) return;
    try {
      final success = await LongRunningOperationOverlay.run(
        context: context,
        title: l10n.workoutImportButton,
        initialStatus: l10n.workoutImportButton,
        icon: LucideIcons.download,
        operation: (token, updateProgress) async {
          updateProgress(l10n.workoutImportButton, 0.2);
          count = await ImportManager().importWorkoutFile(
            isImperial: isImperial,
            defaultWorkoutTitle: l10n.importedWorkout,
            defaultExerciseName: l10n.unknownExercise,
          );
          if (count > 0) {
            unawaited(TelemetryService.instance
                .trackFeatureUsed(featureKey: FeatureKey.workoutImported));
          }
          updateProgress(l10n.workoutImportButton, 1.0);
        },
      );
      if (!success) wasCanceled = true;
    } catch (e) {
      count = -1;
    }

    if (!mounted || wasCanceled) return;

    final unknown =
        await WorkoutLocalDataSource.instance.findUnknownExerciseNames();

    if (mounted && unknown.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExerciseMappingScreen(unknownNames: unknown),
        ),
      );
    }

    if (!mounted) return;

    if (count > 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.workoutImportSuccess(count))));
    } else if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.workoutImportZeroNew),
        ),
      );
    } else if (count == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.workoutImportFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _performExcelExport() async {
    setState(() => _isCsvExportRunning = true);
    try {
      await ExportManager.exportToExcel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.snackbarExportFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCsvExportRunning = false);
    }
  }

  // --- New: helper method for all CSV exports ---
  void _exportCsv(
    Future<bool> Function() exportFunction,
    String successMessage,
    String failureMessage,
  ) async {
    setState(() => _isCsvExportRunning = true);
    final success = await exportFunction();
    if (!mounted) return;
    setState(() => _isCsvExportRunning = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage), backgroundColor: Colors.orange),
      );
    }
  }
  // lib/screens/data_management_screen.dart

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isApple = Platform.isIOS || Platform.isMacOS;

    // This calculation is correct.
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.dataHubTitle),
      body: SingleChildScrollView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SummaryCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DataBackupCard(
                    isFullBackupRunning: false,
                    onExportPressed: _performFullExport,
                    onImportPressed: _performFullImport,
                    onExportEncryptedPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final pw = await _askPassword(
                        title: l10n.dialogPasswordForExport,
                      );
                      if (!context.mounted) return;
                      if (pw == null || pw.isEmpty) return;

                      bool ok = false;
                      bool wasCanceled = false;
                      try {
                        ok = await LongRunningOperationOverlay.run(
                          context: context,
                          title: l10n.backupExportTitle,
                          initialStatus: l10n.backupExportTitle,
                          icon: LucideIcons.lock,
                          operation: (token, updateProgress) async {
                            await BackupManager.instance
                                .exportFullBackupEncrypted(pw, token, (
                              tableName,
                              progress,
                            ) {
                              final statusText =
                                  l10n.progressExportingTable(tableName);
                              updateProgress(statusText, progress);
                            });
                          },
                        );
                      } catch (e) {
                        if (e is OperationCanceledException) {
                          wasCanceled = true;
                        }
                        ok = false;
                      }

                      if (!wasCanceled) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? l10n.snackbarEncryptedBackupShared
                                  : l10n.exportFailed,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  if (!isApple)
                    DataAutoBackupCard(
                      autoBackupDir: _autoBackupDir,
                      lastAutoBackupFilePath: _lastAutoBackupFilePath,
                      lastAutoBackupDirUsed: _lastAutoBackupDirUsed,
                      lastAutoBackupUsedFallback: _lastAutoBackupUsedFallback,
                      onPickDirectory: _pickAutoBackupDirectory,
                      onCopyPath: _copyAutoBackupPathToClipboard,
                      onRunNow: () async {
                        final ok =
                            await BackupManager.instance.runAutoBackupIfDue(
                          interval: const Duration(days: 1),
                          encrypted: false,
                          passphrase: null,
                          retention: 7,
                          dirPath: _autoBackupDir,
                          force: true, // New: run immediately
                        );
                        await _loadAutoBackupDir();
                        if (!mounted) return;
                        final successText = ok
                            ? (_lastAutoBackupFilePath != null &&
                                    _lastAutoBackupFilePath!.isNotEmpty
                                ? '${l10n.snackbarAutoBackupSuccess}\n$_lastAutoBackupFilePath'
                                : l10n.snackbarAutoBackupSuccess)
                            : (_lastAutoBackupError != null &&
                                    _lastAutoBackupError!.isNotEmpty
                                ? '${l10n.snackbarAutoBackupFailed}\n$_lastAutoBackupError'
                                : l10n.snackbarAutoBackupFailed);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(successText),
                            backgroundColor: ok
                                ? (_lastAutoBackupUsedFallback
                                    ? Colors.orange
                                    : null)
                                : Theme.of(this.context).colorScheme.error,
                          ),
                        );
                      },
                    ),
                  if (isApple)
                    ICloudSyncCard(
                      onBackupNow: ({onProgress}) async {
                        final db = DatabaseHelper.driftDb!;
                        return await ICloudSyncService.instance.backupNow(
                          db,
                          onProgress: onProgress,
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
            LocalDataDeletionCard(
              isLocalResetRunning: _isLocalResetRunning,
              onDeletePressed: _confirmAndDeleteLocalData,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            CsvExportCard(
              isCsvExportRunning: _isCsvExportRunning,
              onExcelExportPressed: _performExcelExport,
              onNutritionExportPressed: () => _exportCsv(
                BackupManager.instance.exportNutritionAsCsv,
                l10n.snackbarSharingNutrition,
                l10n.snackbarExportFailedNoEntries,
              ),
              onMeasurementsExportPressed: () => _exportCsv(
                BackupManager.instance.exportMeasurementsAsCsv,
                l10n.snackbarSharingMeasurements,
                l10n.snackbarExportFailedNoEntries,
              ),
              onWorkoutsExportPressed: () => _exportCsv(
                BackupManager.instance.exportWorkoutsAsCsv,
                l10n.snackbarSharingWorkouts,
                l10n.snackbarExportFailedNoEntries,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
            MigrationCard(
              isMigrationRunning: _isMigrationRunning,
              onImportPressed: _performWorkoutImport,
            ),
            const SizedBox(height: DesignConstants.spacingS),
            ExerciseMappingCard(onMapPressed: _openExerciseMapping),
          ],
        ),
      ),
    );
  }

  Future<void> _openExerciseMapping() async {
    final unknown =
        await WorkoutLocalDataSource.instance.findUnknownExerciseNames();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (unknown.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noUnknownExercisesFound)));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseMappingScreen(unknownNames: unknown),
      ),
    );
  }

  Future<void> _confirmAndDeleteLocalData() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showLocalDataDeletionConfirmation(l10n);
    if (!confirmed || !mounted) return;

    LiveWorkoutViewModel? sessionManager;
    try {
      sessionManager = context.read<LiveWorkoutViewModel>();
    } catch (_) {
      sessionManager = null;
    }

    setState(() => _isLocalResetRunning = true);
    try {
      final resetter = widget._localDataResetter ?? LocalAppDataResetService();
      await resetter.deleteAllLocalAppData();
      await sessionManager?.clearLocalSessionState();

      if (!mounted) return;
      setState(() => _isLocalResetRunning = false);

      if (widget._onResetComplete != null) {
        widget._onResetComplete!();
        return;
      }

      await showGlassBottomMenu<void>(
        context: context,
        title: l10n.localDataDeletionSuccessTitle,
        isDismissible: false,
        enableDrag: false,
        contentBuilder: (ctx, close) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.localDataDeletionSuccessBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignConstants.spacingM),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                onPressed: () => Navigator.of(ctx).pop(),
                label: l10n.snackbarButtonOK,
                tooltip: l10n.snackbarButtonOK,
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => InitialConsentScreen(
            nextScreen: const AppInitializerScreen(skipOffDatabase: true),
          ),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLocalResetRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.localDataDeletionFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<bool> _showLocalDataDeletionConfirmation(AppLocalizations l10n) async {
    final controller = TextEditingController();
    final result = await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.localDataDeletionConfirmTitle,
      contentBuilder: (ctx, close) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final canConfirm = controller.text.trim() == 'DELETE';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.localDataDeletionConfirmBody,
                  key: const Key('delete_local_data_warning_copy'),
                ),
                const SizedBox(height: DesignConstants.spacingL),
                TextField(
                  key: const Key('delete_local_data_confirmation_field'),
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.localDataDeletionTypeDeleteLabel,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: DesignConstants.spacingL),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        key: const Key('cancel_delete_local_data_button'),
                        onPressed: () {
                          close();
                          Navigator.of(ctx).pop(false);
                        },
                        label: l10n.cancel,
                        tooltip: l10n.cancel,
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingM),
                    Expanded(
                      child: AppButton.primary(
                        key: const Key('confirm_delete_local_data_button'),
                        onPressed: canConfirm
                            ? () {
                                close();
                                Navigator.of(ctx).pop(true);
                              }
                            : null,
                        label: l10n.delete,
                        tooltip: l10n.delete,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
    return result ?? false;
  }

  Future<void> _pickAutoBackupDirectory() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();

    final confirmed = await showGlassBottomMenu<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      title: l10n.autoBackupChooseFolder,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingS,
              ),
              child: Text(
                l10n.autoBackupRequestAccessSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(false);
                    },
                    label: l10n.cancel,
                    tooltip: l10n.cancel,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.primary(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(true);
                    },
                    label: l10n.onboardingNext,
                    tooltip: l10n.onboardingNext,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (Platform.isAndroid) {
      SafPickedDirectory? picked;
      try {
        picked = await SafStorageService.instance.pickDirectory();
      } on MissingPluginException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.autoBackupStoragePickerUnavailable),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      } on PlatformException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.autoBackupFolderPickerFailed(e.message ?? e.code),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      if (picked == null) return;
      final selected = picked;
      await prefs.setString('auto_backup_dir', selected.displayPath);
      await prefs.setString('auto_backup_tree_uri', selected.treeUri);
      setState(() => _autoBackupDir = selected.displayPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.snackbarAutoBackupFolderSet(selected.displayPath)),
        ),
      );
      return;
    }

    // Non-Android fallback: directory path picker.
    final path = await FilePicker.getDirectoryPath();
    if (path == null) return;
    await prefs.setString('auto_backup_dir', path);
    await prefs.remove('auto_backup_tree_uri');
    setState(() => _autoBackupDir = path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.snackbarAutoBackupFolderSet(path))),
    );
  }

  Future<void> _copyAutoBackupPathToClipboard() async {
    final path = _autoBackupDir;
    final l10n = AppLocalizations.of(context)!;
    if (path == null || path.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: path));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.snackbarPathCopied)));
  }

  Future<String?> _askPassword({required String title}) async {
    final controller = TextEditingController();
    bool obscure = true;
    final l10n = AppLocalizations.of(context)!;

    return showGlassBottomMenu<String?>(
      context: context,
      title: title,
      contentBuilder: (ctx, close) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    suffixIcon: IconButton(
                      tooltip: l10n.passwordLabel,
                      icon: Icon(
                        obscure ? LucideIcons.eye_off : LucideIcons.eye,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingL),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        onPressed: () {
                          close();
                          Navigator.of(ctx).pop(null);
                        },
                        label: l10n.dialogButtonCancel,
                        tooltip: l10n.dialogButtonCancel,
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingM),
                    Expanded(
                      child: AppButton.primary(
                        onPressed: () {
                          final value = controller.text.trim();
                          close();
                          Navigator.of(ctx).pop(value);
                        },
                        label: l10n.snackbarButtonOK,
                        tooltip: l10n.snackbarButtonOK,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
