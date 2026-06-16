// lib/screens/live_workout_screen.dart
// FINAL: Cardio fix + null safety + header logic

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../util/design_constants.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/glass_fab.dart';
import '../data/sources/workout_local_data_source.dart';
import '../../../generated/app_localizations.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../domain/models/routine.dart';
import '../domain/models/routine_exercise.dart';
import '../domain/models/set_log.dart';
import '../domain/models/workout_log.dart';
import '../../../services/haptic_feedback_service.dart';
import 'live_workout_view_model.dart';
import '../domain/detect_personal_record_use_case.dart';
import '../../../services/unit_service.dart';
import '../../exercise_catalog/presentation/widgets/wger_attribution_widget.dart';
import 'widgets/workout_summary_bar.dart';
import '../../exercise_catalog/presentation/exercise_catalog_screen.dart';
import '../../exercise_catalog/presentation/exercise_detail_screen.dart';
import 'package:provider/provider.dart';
import 'workout_summary_screen.dart';
import 'widgets/workout_card.dart';
import 'widgets/pr_celebration_banner.dart';
import 'widgets/exercise_e1rm_summary.dart';
import 'widgets/live_workout_set_row.dart';
import 'widgets/exercise_notes_dialog.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../util/time_util.dart';

String _formatPauseTime(int? seconds) => formatPauseDuration(seconds);
int? _parsePauseTime(String text) => parsePauseDuration(text);

/// The active workout tracking screen, managing the real-time session state.
///
/// Handles input for sets, reps, weight, RPE/RIR, and cardio metrics. Coordinates
/// with [LiveWorkoutViewModel] to persist progress and provide rest timers.
class LiveWorkoutScreen extends StatefulWidget {
  /// Optional [Routine] used to initialize the workout exercises.
  final Routine? routine;

  /// The [WorkoutLog] representing the current active session.
  final WorkoutLog workoutLog;

  const LiveWorkoutScreen({super.key, this.routine, required this.workoutLog});

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen>
    with TickerProviderStateMixin {
  bool _canPop = false;

  void _handleBack() {
    setState(() {
      _canPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  // PR Celebration State
  StreamSubscription<PRAlert>? _prEventsSubscription;
  final List<PRAlert> _prQueue = [];
  bool _isShowingPR = false;
  PRAlert? _currentPR;
  late final AnimationController _prAnimationController;
  late final Animation<Offset> _prSlideAnimation;

  @override
  void initState() {
    super.initState();

    _prAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _prSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _prAnimationController,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final manager = Provider.of<LiveWorkoutViewModel>(
        context,
        listen: false,
      );
      manager.loadInitialData(widget.workoutLog, widget.routine?.exercises);

      _prEventsSubscription = manager.prEvents.listen((event) {
        _prQueue.add(event);
        _processPRQueue();
      });
    });
  }

  void _processPRQueue() async {
    if (_isShowingPR || _prQueue.isEmpty) return;

    _isShowingPR = true;
    _currentPR = _prQueue.removeAt(0);
    if (mounted) setState(() {});

    await _prAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      await _prAnimationController.reverse();
      _isShowingPR = false;
      _currentPR = null;
      setState(() {});
      _processPRQueue();
    }
  }

  @override
  void dispose() {
    _prEventsSubscription?.cancel();
    _prAnimationController.dispose();
    super.dispose();
  }

  // --- Cardio check helper ---
  bool _isCardio(RoutineExercise re) {
    return re.exercise.categoryName.toLowerCase() == 'cardio';
  }

  Future<void> _finishWorkout() async {
    final l10n = AppLocalizations.of(context)!;
    final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);

    // Pre-fill the title with the routine name or "Free Workout"
    final defaultTitle =
        manager.workoutLog?.routineName ?? l10n.freeWorkoutTitle;
    final titleController = TextEditingController(text: defaultTitle);
    final notesController = TextEditingController();

    final result = await showGlassBottomMenu<({String title, String notes})>(
      context: context,
      title: l10n.finishWorkoutButton,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                l10n.dialogFinishWorkoutBody,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: l10n.finishWorkoutTitleLabel,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: l10n.finishWorkoutNotesLabel,
                hintText: l10n.finishWorkoutNotesHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(null);
                    },
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop((
                        title: titleController.text.trim(),
                        notes: notesController.text.trim(),
                      ));
                    },
                    child: Text(l10n.finishWorkoutButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    titleController.dispose();
    notesController.dispose();

    if (result != null && mounted) {
      final logId = manager.workoutLog?.id;
      await manager.finishWorkout(
        title: result.title.isNotEmpty ? result.title : null,
        notes: result.notes.isNotEmpty ? result.notes : null,
      );
      if (mounted && logId != null) {
        HapticFeedbackService.instance.confirmationFeedback();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WorkoutSummaryScreen(logId: logId),
          ),
        );
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    Provider.of<LiveWorkoutViewModel>(
      context,
      listen: false,
    ).reorderExercise(oldIndex, newIndex);
  }

  void _removeExercise(RoutineExercise exerciseToRemove) {
    Provider.of<LiveWorkoutViewModel>(
      context,
      listen: false,
    ).removeExercise(exerciseToRemove.id!);
  }

  void _editExerciseNotes(BuildContext context, RoutineExercise re) async {
    final l10n = AppLocalizations.of(context)!;
    final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);

    final result = await showGlassBottomMenu<String?>(
      context: context,
      title: l10n.exerciseNoteTitle,
      contentBuilder: (ctx, close) {
        return ExerciseNotesDialog(
          initialNotes: re.notes,
          onSave: (notes) {
            close();
            Navigator.of(ctx).pop(notes);
          },
          onDelete: () {
            close();
            Navigator.of(ctx).pop('');
          },
          onCancel: () {
            close();
            Navigator.of(ctx).pop(null);
          },
        );
      },
    );

    if (result != null) {
      await manager.updateExerciseNotes(re.exercise.nameEn, result);
    }
  }

  void _addExercise() async {
    final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);
    final selectedExercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (context) =>
            const ExerciseCatalogScreen(isSelectionMode: true),
      ),
    );

    if (selectedExercise != null) {
      final lastSets = await WorkoutLocalDataSource.instance
          .getLastSetsForExercise(selectedExercise.nameEn);
      if (mounted) {
        setState(() {
          manager.lastPerformances[selectedExercise.nameEn] = lastSets;
        });
      }
      await manager.addExercise(selectedExercise);
    }
  }

  void _addSet(RoutineExercise re) {
    Provider.of<LiveWorkoutViewModel>(
      context,
      listen: false,
    ).addSetToExercise(re.id!);
  }

  // --- HEADER HELPER ---
  Widget _buildHeaderRow(RoutineExercise re, AppLocalizations l10n) {
    // Important: cardio check here.
    final bool isCardio = _isCardio(re);
    final unitService = context.read<UnitService>();

    if (isCardio) {
      return Row(
        children: [
          _buildHeader(l10n.setLabel, flex: 2), // Set Nr.
          _buildHeader(l10n.lastTimeLabel, flex: 3), // History/Last
          _buildHeader(l10n.cardioDistanceLabel, flex: 4),
          _buildHeader(l10n.cardioTimeLabel, flex: 4),
          _buildHeader(l10n.cardioIntensityLabel, flex: 2),
          const SizedBox(
              width: 56), // Space for checkbox (48 width + 8 padding)
        ],
      );
    }
    // Standard Strength Header
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeader(l10n.setLabel, flex: 1),
        _buildHeader(l10n.lastTimeLabel, flex: 2),
        _buildHeader(unitService.suffixFor(UnitDimension.weight), flex: 2),
        _buildHeader(l10n.repsLabel, flex: 2),
        _buildHeader("RIR", flex: 1),
        const SizedBox(width: 56), // Space for checkbox (48 width + 8 padding)
      ],
    );
  }

  Widget _buildHeader(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getLocalizedRecordType(String recordType) {
    final l10n = AppLocalizations.of(context)!;
    switch (recordType) {
      case "Best Max Weight":
        return l10n.prBannerBestMaxWeight;
      case "Best Volume Set":
        return l10n.prBannerBestVolumeSet;
      case "Best 1-Rep Max":
        return l10n.prBannerBest1RM;
      default:
        return recordType;
    }
  }

  Widget _buildPRCelebrationBanner() {
    final pr = _currentPR;
    if (pr == null) return const SizedBox.shrink();

    final localizedRecordType = _getLocalizedRecordType(pr.recordType);
    final unitService = context.read<UnitService>();
    final String achievementText = _formatDisplayWeightText(
      pr.achievementValue,
      unitService,
    );
    final String diffText = pr.diff != null
        ? " (+${_formatDisplayWeightValue(pr.diff!, unitService)} ${unitService.suffixFor(UnitDimension.weight)})"
        : "";

    return PrCelebrationBanner(
      slideAnimation: _prSlideAnimation,
      exerciseName: pr.exerciseName,
      localizedRecordType: localizedRecordType,
      achievementText: achievementText,
      diffText: diffText,
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.circle_plus,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Text(
              l10n.emptyStateAddFirstExercise,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.emptyStateAddFirstExerciseSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            ElevatedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n.fabAddExercise),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.watch<UnitService>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);

    final isLoading =
        context.select<LiveWorkoutViewModel, bool>((vm) => vm.isLoading);
    final isActive =
        context.select<LiveWorkoutViewModel, bool>((vm) => vm.isActive);
    final routineName = context.select<LiveWorkoutViewModel, String?>(
        (vm) => vm.workoutLog?.routineName);
    final exercises =
        context.select<LiveWorkoutViewModel, List<RoutineExercise>>(
            (vm) => vm.exercises);
    final showRestBar = context.select<LiveWorkoutViewModel, bool>(
        (vm) => vm.remainingRestSeconds > 0 || vm.showRestDone);

    // If the workout was just finished, the manager state is cleared.
    // We return a blank scaffold to avoid any errors during the Navigator transition.
    if (!isActive && !isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    }

    // Edit rest helper
    void editPauseTime(RoutineExercise routineExercise) async {
      final currentPause = manager.pauseTimes[routineExercise.id!];
      final controller = TextEditingController(
        text: currentPause == null || currentPause == 0
            ? ''
            : _formatPauseTime(currentPause),
      );

      final result = await showGlassBottomMenu<({bool saved, int? value})>(
        context: context,
        title: l10n.editPauseTimeTitle,
        contentBuilder: (ctx, close) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    inputFormatters: [TimerInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.restTimerLabel,
                      hintText: "00:00",
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.redAccent),
                              onPressed: () {
                                controller.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            close();
                            Navigator.of(ctx).pop((saved: false, value: null));
                          },
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final val = _parsePauseTime(controller.text);
                            close();
                            Navigator.of(ctx).pop((saved: true, value: val));
                          },
                          child: Text(l10n.save),
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

      if (result != null && result.saved) {
        manager.updatePauseTime(routineExercise.id!, result.value ?? 0);
      }
    }

    if (!isLoading) {
      manager.syncControllers();
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: PopScope(
        canPop: _canPop,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          // The system back swipe won't pop the route automatically because canPop is false.
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          extendBody: true,
          appBar: AppBar(
            automaticallyImplyLeading:
                false, // We will provide our own back button
            leading: IconButton(
              icon: const Icon(LucideIcons.arrow_left),
              onPressed: _handleBack,
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: colorScheme.onSurface,
            scrolledUnderElevation: 0,
            centerTitle: false,
            title: Text(
              routineName ?? l10n.freeWorkoutTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            actions: [
              TextButton(
                onPressed: _finishWorkout,
                child: Text(
                  l10n.finishWorkoutButton,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    // Layer 1 (Bottom): The full scrollable viewport container
                    RepaintBoundary(
                      child: Column(
                        children: [
                          Consumer<LiveWorkoutViewModel>(
                            builder: (context, vm, _) {
                              final planned = vm.setLogs.length;
                              final completed = vm.setLogs.values
                                  .where((s) => s.isCompleted == true)
                                  .length;
                              final progress =
                                  planned == 0 ? 0.0 : completed / planned;
                              return WorkoutSummaryBar(
                                duration: vm.elapsedDuration,
                                volume: vm.totalVolume,
                                sets: planned,
                                progress: progress,
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.1),
                          ),
                          Expanded(
                            child: exercises.isEmpty
                                ? _buildEmptyState(l10n)
                                : ReorderableListView.builder(
                                    scrollCacheExtent:
                                        const ScrollCacheExtent.pixels(1500.0),
                                    padding: EdgeInsets.only(
                                      bottom: (showRestBar
                                              ? 180.0
                                              : DesignConstants
                                                  .bottomContentSpacer) +
                                          MediaQuery.paddingOf(context).bottom,
                                    ),
                                    onReorder: _onReorder,
                                    itemCount: exercises.length,
                                    itemBuilder: (context, index) {
                                      final routineExercise = exercises[index];
                                      final showE1rmSummary =
                                          !_isCardio(routineExercise);
                                      final pauseVal = manager
                                          .pauseTimes[routineExercise.id!];
                                      final hasPause =
                                          pauseVal != null && pauseVal > 0;
                                      return RepaintBoundary(
                                        key: ValueKey(routineExercise.id),
                                        child: WorkoutCard(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16.0,
                                                  vertical: 8.0,
                                                ),
                                                leading:
                                                    ReorderableDragStartListener(
                                                  index: index,
                                                  child: const Icon(LucideIcons
                                                      .grip_vertical),
                                                ),
                                                title: InkWell(
                                                  onTap: () =>
                                                      Navigator.of(context)
                                                          .push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ExerciseDetailScreen(
                                                        exercise:
                                                            routineExercise
                                                                .exercise,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: 4.0,
                                                    ),
                                                    child: Text(
                                                      routineExercise.exercise
                                                          .getLocalizedName(
                                                              context),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: textTheme
                                                          .titleLarge
                                                          ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        LucideIcons.pencil,
                                                      ),
                                                      tooltip:
                                                          "Notizen bearbeiten",
                                                      onPressed: () =>
                                                          _editExerciseNotes(
                                                              context,
                                                              routineExercise),
                                                    ),
                                                    if (hasPause)
                                                      TextButton(
                                                        style: TextButton
                                                            .styleFrom(
                                                          minimumSize:
                                                              const Size(
                                                                  48, 48),
                                                          padding:
                                                              EdgeInsets.zero,
                                                        ),
                                                        onPressed: () =>
                                                            editPauseTime(
                                                                routineExercise),
                                                        child: Text(
                                                          _formatPauseTime(
                                                              pauseVal),
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                            color: colorScheme
                                                                .primary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize:
                                                                DesignConstants
                                                                    .spacingL,
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      IconButton(
                                                        icon: const Icon(
                                                          LucideIcons.timer,
                                                        ),
                                                        tooltip:
                                                            l10n.editPauseTime,
                                                        onPressed: () =>
                                                            editPauseTime(
                                                          routineExercise,
                                                        ),
                                                      ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        LucideIcons.trash_2,
                                                        color: Colors.redAccent,
                                                      ),
                                                      tooltip:
                                                          l10n.removeExercise,
                                                      onPressed: () =>
                                                          _removeExercise(
                                                        routineExercise,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (routineExercise.notes !=
                                                      null &&
                                                  routineExercise
                                                      .notes!.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 16.0,
                                                    right: 16.0,
                                                    bottom: 12.0,
                                                  ),
                                                  child: InkWell(
                                                    onTap: () =>
                                                        _editExerciseNotes(
                                                            context,
                                                            routineExercise),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Container(
                                                      width: double.infinity,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      decoration: BoxDecoration(
                                                        color: colorScheme
                                                            .surfaceContainerHighest
                                                            .withValues(
                                                                alpha: 0.5),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        border: Border.all(
                                                          color: colorScheme
                                                              .onSurfaceVariant
                                                              .withValues(
                                                                  alpha: 0.1),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .description_outlined,
                                                            size: 16,
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              routineExercise
                                                                  .notes!,
                                                              style: textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                color: colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              if (showE1rmSummary)
                                                ExerciseE1rmSummary(
                                                  routineExercise:
                                                      routineExercise,
                                                  manager: manager,
                                                ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 0.0,
                                                ),
                                                child: Selector<
                                                    LiveWorkoutViewModel,
                                                    Map<int, SetLog>>(
                                                  selector: (context, vm) {
                                                    final map = <int, SetLog>{};
                                                    for (final template
                                                        in routineExercise
                                                            .setTemplates) {
                                                      final log = vm
                                                          .setLogs[template.id];
                                                      if (log != null) {
                                                        map[template.id!] = log;
                                                      }
                                                    }
                                                    return map;
                                                  },
                                                  shouldRebuild: (prev, next) {
                                                    if (prev.length !=
                                                        next.length) {
                                                      return true;
                                                    }
                                                    for (final key
                                                        in prev.keys) {
                                                      final prevLog = prev[key];
                                                      final nextLog = next[key];
                                                      if (prevLog == null ||
                                                          nextLog == null) {
                                                        return true;
                                                      }
                                                      if (prevLog.setType !=
                                                              nextLog.setType ||
                                                          prevLog.isCompleted !=
                                                              nextLog
                                                                  .isCompleted) {
                                                        return true;
                                                      }
                                                    }
                                                    return false;
                                                  },
                                                  builder: (context,
                                                      exerciseSetLogs, child) {
                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // FIX: Insert header row dynamically.
                                                        _buildHeaderRow(
                                                          routineExercise,
                                                          l10n,
                                                        ),

                                                        // Set Rows
                                                        ...routineExercise
                                                            .setTemplates
                                                            .asMap()
                                                            .entries
                                                            .map((setEntry) {
                                                          final templateId =
                                                              setEntry
                                                                  .value.id!;
                                                          final template = setEntry
                                                              .value; // <--- Template
                                                          final setLog =
                                                              exerciseSetLogs[
                                                                  templateId];

                                                          if (setLog == null) {
                                                            return const SizedBox
                                                                .shrink();
                                                          }
                                                          int workingSetIndex =
                                                              0;
                                                          for (int i = 0;
                                                              i <= setEntry.key;
                                                              i++) {
                                                            final currentTemplateId =
                                                                routineExercise
                                                                    .setTemplates[
                                                                        i]
                                                                    .id!;
                                                            if (exerciseSetLogs[
                                                                        currentTemplateId]
                                                                    ?.setType !=
                                                                'warmup') {
                                                              workingSetIndex++;
                                                            }
                                                          }

                                                          return LiveWorkoutSetRow(
                                                            setIndex:
                                                                workingSetIndex,
                                                            rowIndex:
                                                                setEntry.key,
                                                            templateId:
                                                                templateId,
                                                            setLog: setLog,
                                                            lastPerfSets: manager
                                                                        .lastPerformances[
                                                                    routineExercise
                                                                        .exercise
                                                                        .nameEn] ??
                                                                [],
                                                            template: template,
                                                            manager: manager,
                                                            isCardio: _isCardio(
                                                                routineExercise),
                                                          );
                                                        }),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 16.0,
                                                          ),
                                                          child:
                                                              TextButton.icon(
                                                            onPressed: () =>
                                                                _addSet(
                                                                    routineExercise),
                                                            icon: const Icon(
                                                                LucideIcons
                                                                    .plus),
                                                            label: Text(l10n
                                                                .addSetButton),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Layer 2 (Top): Floating/sticky Liquid Glass bar, FAB, and attribution
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: RepaintBoundary(
                        child: SafeArea(
                          top: false,
                          bottom: false,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  (MediaQuery.paddingOf(context).bottom * 0.3)
                                      .clamp(4.0, 12.0),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AnimatedBuilder(
                                  animation: manager,
                                  builder: (context, _) {
                                    final bar = _buildRestBottomBar(
                                        l10n, colorScheme, manager);
                                    return bar ?? const SizedBox.shrink();
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 10.0, top: 0.0),
                                  child: WgerAttributionWidget(
                                    textStyle: textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      shadows: [
                                        Shadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.5),
                                          offset: const Offset(1, 1),
                                          blurRadius: 4.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: (showRestBar ? 104.0 : 24.0) +
                          MediaQuery.paddingOf(context).bottom,
                      right: 16.0,
                      child: RepaintBoundary(
                        child: _LiveWorkoutFab(onPressed: _addExercise),
                      ),
                    ),

                    // --- Top Celebration Banner ---
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: RepaintBoundary(
                        child: _buildPRCelebrationBanner(),
                      ),
                    ),

                    // --- Keyboard Done Accessory Bar ---
                    const _LiveWorkoutKeyboardDoneBar(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget? _buildRestBottomBar(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    LiveWorkoutViewModel manager,
  ) {
    final isRunning = manager.remainingRestSeconds > 0;
    final isDoneBanner = !isRunning && manager.showRestDone;
    if (!isRunning && !isDoneBanner) return null;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const double r = 37;

    if (isRunning) {
      final restSeconds = manager.remainingRestSeconds;
      final minutes = restSeconds ~/ 60;
      final seconds = restSeconds % 60;
      final timerStr =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SizedBox(
          height: 74.0,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipPath(
                  clipper: ShadowOuterClipper(borderRadius: r),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(r),
                      boxShadow: DesignConstants.glassShadow,
                    ),
                  ),
                ),
              ),
              GlassAdaptiveScope(
                minQuality: GlassQuality.premium,
                maxQuality: GlassQuality.premium,
                child: AdaptiveGlass(
                  settings: DesignConstants.liquidGlassSettings(isDark),
                  shape: const LiquidRoundedSuperellipse(borderRadius: r),
                  quality: GlassQuality.premium,
                  child: GlassGlow(
                    glowColor:
                        Colors.white.withValues(alpha: isDark ? 0.24 : 0.18),
                    glowRadius: 1.0,
                    child: Container(
                      height: 74.0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: DesignConstants.glassNeutralTint(isDark),
                        borderRadius: BorderRadius.circular(r),
                      ),
                      foregroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(r),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.20)
                              : Colors.black.withValues(alpha: 0.08),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // -15 Button
                          SizedBox(
                            height: 38,
                            width: 48,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () => manager.adjustRestTime(-15),
                              child: Text(
                                "-15",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Timer Text
                          Container(
                            height: 38,
                            alignment: Alignment.center,
                            child: Text(
                              timerStr,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // +15 Button
                          SizedBox(
                            height: 38,
                            width: 48,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () => manager.adjustRestTime(15),
                              child: Text(
                                "+15",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Skip Button
                          SizedBox(
                            height: 38,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onPressed: () => manager.cancelRest(),
                              child: Text(
                                l10n.skipButton,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: 74.0,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipPath(
                clipper: ShadowOuterClipper(borderRadius: r),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(r),
                    boxShadow: DesignConstants.glassShadow,
                  ),
                ),
              ),
            ),
            GlassAdaptiveScope(
              minQuality: GlassQuality.premium,
              maxQuality: GlassQuality.premium,
              child: AdaptiveGlass(
                settings: LiquidGlassSettings(
                  thickness: 30,
                  blur: 2.0,
                  glassColor:
                      Colors.green.withValues(alpha: isDark ? 0.20 : 0.25),
                  lightIntensity: isDark ? 0.55 : 0.80,
                  saturation: 1.20,
                ),
                shape: const LiquidRoundedSuperellipse(borderRadius: r),
                quality: GlassQuality.premium,
                child: GlassGlow(
                  glowColor:
                      Colors.white.withValues(alpha: isDark ? 0.24 : 0.18),
                  glowRadius: 1.0,
                  child: Container(
                    height: 74.0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color:
                          Colors.green.withValues(alpha: isDark ? 0.50 : 0.70),
                      borderRadius: BorderRadius.circular(r),
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.circle_check,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              l10n.restOverLabel, //"Pause vorbei!",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 38,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: () => manager.cancelRest(),
                            child: Text(
                              l10n.snackbar_button_ok,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDisplayWeightText(
    String metricText,
    UnitService unitService, {
    int fractionDigits = 1,
  }) {
    final value = _extractNumericValue(metricText);
    if (value == null) return metricText;
    return '${_formatDisplayWeightValue(value, unitService, fractionDigits: fractionDigits)} ${unitService.suffixFor(UnitDimension.weight)}';
  }

  String _formatDisplayWeightValue(
    double metricValue,
    UnitService unitService, {
    int fractionDigits = 1,
  }) {
    return unitService
        .convertDisplayValue(metricValue, UnitDimension.weight)
        .toStringAsFixed(fractionDigits)
        .replaceAll('.0', '');
  }

  double? _extractNumericValue(String text) {
    final match = RegExp(r'[-+]?\d+(?:[.,]\d+)?').firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(0)!.replaceAll(',', '.'));
  }
}

class _LiveWorkoutKeyboardDoneBar extends StatefulWidget {
  const _LiveWorkoutKeyboardDoneBar();

  @override
  State<_LiveWorkoutKeyboardDoneBar> createState() =>
      _LiveWorkoutKeyboardDoneBarState();
}

class _LiveWorkoutKeyboardDoneBarState
    extends State<_LiveWorkoutKeyboardDoneBar> with WidgetsBindingObserver {
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateKeyboardHeight();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _updateKeyboardHeight();
  }

  void _updateKeyboardHeight() {
    if (!mounted) return;
    final view = View.of(context);
    final newHeight = view.viewInsets.bottom / view.devicePixelRatio;
    if (newHeight != _keyboardHeight) {
      setState(() {
        _keyboardHeight = newHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_keyboardHeight <= 0) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 8.0,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFF5F5F7),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Text(
                  l10n.doneButtonLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveWorkoutFab extends StatefulWidget {
  final VoidCallback onPressed;

  const _LiveWorkoutFab({required this.onPressed});

  @override
  State<_LiveWorkoutFab> createState() => _LiveWorkoutFabState();
}

class _LiveWorkoutFabState extends State<_LiveWorkoutFab>
    with WidgetsBindingObserver {
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateKeyboardHeight();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _updateKeyboardHeight();
  }

  void _updateKeyboardHeight() {
    if (!mounted) return;
    final view = View.of(context);
    final newHeight = view.viewInsets.bottom / view.devicePixelRatio;
    if (newHeight != _keyboardHeight) {
      setState(() {
        _keyboardHeight = newHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_keyboardHeight > 0) {
      return const SizedBox.shrink();
    }
    final showRestBar = context.select<LiveWorkoutViewModel, bool>(
        (vm) => vm.remainingRestSeconds > 0 || vm.showRestDone);

    final fab = GlassFab(
      label: AppLocalizations.of(context)!.fabAddExercise,
      onPressed: widget.onPressed,
    );

    if (showRestBar) {
      return Transform.translate(
        offset: const Offset(0, 8.0),
        child: ClipPath(
          clipper: const _LiveWorkoutFabShadowClipper(),
          child: fab,
        ),
      );
    }
    return fab;
  }
}

/// A clipper that crops the FAB drop shadow at the bottom (exactly 8.0 logical
/// pixels below the FAB edge) so it terminates where the rest bar begins.
class _LiveWorkoutFabShadowClipper extends CustomClipper<Path> {
  const _LiveWorkoutFabShadowClipper();

  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.addRect(Rect.fromLTRB(
      -50.0,
      -50.0,
      size.width + 50.0,
      size.height +
          8.0, // cut off exactly at the top of the rest bar (8.0px below FAB bottom)
    ));
    return path;
  }

  @override
  bool shouldReclip(covariant _LiveWorkoutFabShadowClipper oldClipper) => false;
}
