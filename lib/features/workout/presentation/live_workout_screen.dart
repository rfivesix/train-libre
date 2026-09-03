// lib/screens/live_workout_screen.dart
// FINAL: Cardio fix + null safety + header logic

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../util/design_constants.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/card_morph_route.dart';
import '../../../widgets/common/morph_source.dart';
import '../data/sources/workout_local_data_source.dart';
import '../../../generated/app_localizations.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../domain/models/routine.dart';
import '../domain/models/routine_exercise.dart';
import '../domain/models/set_log.dart';
import '../../../services/haptic_feedback_service.dart';
import '../domain/live_activity/workout_live_activity_strings.dart';
import 'live_workout_view_model.dart';
import 'reorder_scroll_anchor.dart';
import '../domain/detect_personal_record_use_case.dart';
import '../../../services/unit_service.dart';
import 'widgets/workout_summary_bar.dart';
import '../../exercise_catalog/presentation/exercise_catalog_screen.dart';
import '../../exercise_catalog/presentation/exercise_detail_screen.dart';
import 'package:provider/provider.dart';
import 'workout_summary_screen.dart';
import 'widgets/workout_card.dart';
import 'widgets/reorder_drag_proxy.dart';
import 'widgets/pr_celebration_banner.dart';
import 'widgets/exercise_e1rm_summary.dart';
import 'widgets/live_workout_set_row.dart';
import 'widgets/exercise_notes_dialog.dart';
import 'widgets/routine_pause_time_dialog.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../util/time_util.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/empty_states/cold_start_empty_state.dart';
import '../../../services/telemetry/telemetry_service.dart';

import '../domain/models/workout_log.dart';

String _formatPauseTime(int? seconds) => formatPauseDuration(seconds);

/// The active workout tracking screen, managing the real-time session state.
///
/// Handles input for sets, reps, weight, RPE/RIR, and cardio metrics. Coordinates
/// with [LiveWorkoutViewModel] to persist progress and provide rest timers.
class LiveWorkoutScreen extends StatefulWidget {
  /// Optional [Routine] used to initialize the workout exercises.
  final Routine? routine;

  /// The [WorkoutLog] representing the current active session.
  final WorkoutLog workoutLog;

  /// Optional initial action to run when opened via deep link (e.g. 'add_exercise').
  final String? initialAction;

  const LiveWorkoutScreen({
    super.key,
    this.routine,
    required this.workoutLog,
    this.initialAction,
  });

  /// The route this screen currently occupies, if it is on the stack at all.
  ///
  /// The Live Activity deep link uses it to return to an already open screen
  /// instead of pushing a second copy on top of the first — otherwise every
  /// tap on the Dynamic Island stacks another instance.
  static Route<dynamic>? activeRoute;

  /// Invoked when the Live Activity deep link returns to an already open
  /// screen. `initState` does not run again in that case, so the screen would
  /// otherwise stay wherever the user last scrolled it.
  static VoidCallback? onDeepLinkReturn;

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _canPop = false;
  bool _isDragging = false;
  bool _isDragActive = false;
  double _dynamicHeadroom = 0.0;
  Timer? _collapseTimer;
  Timer? _expandTimer;
  Offset? _pointerDownPosition;
  Object? _touchedAnchorId;
  final ScrollController _scrollController = ScrollController();
  late final ReorderScrollAnchor _scrollAnchor =
      ReorderScrollAnchor(_scrollController);

  void _onDragPointerDown(PointerDownEvent event, Object anchorId, int index) {
    _touchedAnchorId = anchorId;
    _pointerDownPosition = event.position;
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted && !_isDragging) {
        final headroom = calculateDynamicReorderHeadroom(
          context: context,
          scrollController: _scrollController,
          pointerGlobalY: event.position.dy,
          itemIndex: index,
        );
        setState(() {
          _dynamicHeadroom = headroom;
        });
        _scrollAnchor.pin(
          _touchedAnchorId,
          () => setState(() => _isDragging = true),
        );
      }
    });
  }

  void _onDragPointerMove(PointerMoveEvent event) {
    if (_pointerDownPosition != null) {
      final distance = (event.position - _pointerDownPosition!).distance;
      if (distance > 4.0) {
        _collapseTimer?.cancel();
        if (!_isDragActive && _isDragging) {
          _scrollAnchor.pin(
            _touchedAnchorId,
            () => setState(() {
              _isDragging = false;
              _dynamicHeadroom = 0.0;
            }),
          );
        }
      }
    }
    if (_isDragActive) {
      final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);
      _trackReorderHover(event.position.dy, manager.exercises);
    }
  }

  double? _lastDragPointerY;

  void _trackReorderHover(
      double pointerGlobalY, List<RoutineExercise> exercises) {
    _lastDragPointerY = pointerGlobalY;
    ReorderHapticFeedback.onPointerMove(
      pointerGlobalY: pointerGlobalY,
      anchor: _scrollAnchor,
      itemIds: [
        for (int i = 0; i < exercises.length; i++) exercises[i].id ?? i,
      ],
    );
  }

  void _onDragPointerUp(PointerUpEvent event) {
    _collapseTimer?.cancel();
    if (!_isDragActive && _isDragging) {
      _scheduleExpandAfterDrop();
    }
  }

  void _onDragPointerCancel(PointerCancelEvent event) {
    _collapseTimer?.cancel();
    if (!_isDragActive && _isDragging) {
      _scheduleExpandAfterDrop();
    }
  }

  /// How many frames the scroll may spend hunting for its target before it
  /// gives up. Each attempt either waits for data or advances one viewport.
  static const int _maxScrollAttempts = 24;

  /// Brings the exercise holding the next open set to the top of the list.
  ///
  /// Two things make this less trivial than an `ensureVisible` call. The
  /// exercises load asynchronously, so the first frames have nothing to scroll
  /// to; and the list is lazy, so a card further down has no context to align
  /// against until it has been built. The method therefore retries across
  /// frames, stepping the viewport towards the target until the card exists,
  /// then aligns it exactly.
  void _scrollToActiveExercise({bool animated = true, int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);
      final exercises = manager.exercises;
      if (exercises.isEmpty) {
        _retryScroll(animated: animated, attempt: attempt);
        return;
      }

      int activeIndex = 0;
      for (int i = 0; i < exercises.length; i++) {
        final hasUncompleted = exercises[i].setTemplates.any((t) {
          final log = t.id != null ? manager.setLogs[t.id] : null;
          return log?.isCompleted != true;
        });
        if (hasUncompleted) {
          activeIndex = i;
          break;
        }
      }

      final targetExercise = exercises[activeIndex];
      final targetContext =
          _scrollAnchor.keyFor(targetExercise.id ?? activeIndex).currentContext;

      if (targetContext == null) {
        // Not built yet — walk down a viewport at a time so the list
        // materializes the cards in between, then look again.
        final position = _scrollController.position;
        if (position.pixels >= position.maxScrollExtent) return;
        _scrollController.jumpTo(
          (position.pixels + position.viewportDimension)
              .clamp(position.minScrollExtent, position.maxScrollExtent),
        );
        _retryScroll(animated: animated, attempt: attempt);
        return;
      }

      // alignment 0 puts the card's top edge at the top of the viewport, which
      // starts directly below the summary bar and its divider — so the
      // exercise title lands right underneath them.
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.0,
        duration: animated ? const Duration(milliseconds: 350) : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _retryScroll({required bool animated, required int attempt}) {
    if (attempt >= _maxScrollAttempts) return;
    _scrollToActiveExercise(animated: animated, attempt: attempt + 1);
  }

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

  /// This screen's own route, captured while the element is still active so
  /// `dispose()` can compare against it without an inherited-widget lookup.
  Route<dynamic>? _ownRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.liveWorkout));
    _scrollController.addListener(_onScrollUpdated);
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final manager = Provider.of<LiveWorkoutViewModel>(
        context,
        listen: false,
      );
      _prEventsSubscription = manager.prEvents.listen((event) {
        _prQueue.add(event);
        _processPRQueue();
      });

      // Await the load: it starts the workout and fetches previous
      // performances, and until it finishes there are no exercises to scroll
      // to at all. Scrolling before it returned was the whole reason the
      // screen always opened at the top.
      await manager.loadInitialData(
        widget.workoutLog,
        widget.routine?.exercises,
      );
      if (!mounted) return;

      // A Live Activity command can be queued before this screen exists at
      // all (e.g. tapped while the app was on another screen, or cold) — the
      // lifecycle-based drain in didChangeAppLifecycleState only fires while
      // this screen is already mounted, so it would otherwise sit stranded
      // and greyed out until some unrelated resume happens to fire later.
      await manager.applyPendingLiveActivityCommands();
      if (!mounted) return;

      _scrollToActiveExercise(animated: false);

      if (widget.initialAction == 'add_exercise') {
        _addExercise();
      }
    });
  }

  void _onScrollUpdated() {
    if (_isDragActive && _lastDragPointerY != null) {
      final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);
      _trackReorderHover(_lastDragPointerY!, manager.exercises);
    }
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
    // Compare against the cached reference, never `ModalRoute.of(context)`:
    // looking up an inherited widget in dispose() is illegal, because the
    // element is already deactivated by then.
    if (identical(LiveWorkoutScreen.activeRoute, _ownRoute)) {
      LiveWorkoutScreen.activeRoute = null;
      LiveWorkoutScreen.onDeepLinkReturn = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScrollUpdated);
    _collapseTimer?.cancel();
    _expandTimer?.cancel();
    _scrollAnchor.discard();
    _scrollController.dispose();
    _prEventsSubscription?.cancel();
    _prAnimationController.dispose();
    super.dispose();
  }

  /// The Live Activity has no string catalog of its own — everything it shows
  /// is formatted here and shipped across the channel.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ownRoute = ModalRoute.of(context);
    LiveWorkoutScreen.activeRoute = _ownRoute;
    LiveWorkoutScreen.onDeepLinkReturn = () {
      // Tapping the Live Activity body itself returns here via URL deep link
      // rather than an app-lifecycle resume, so it needs its own drain too.
      unawaited(
        Provider.of<LiveWorkoutViewModel>(context, listen: false)
            .applyPendingLiveActivityCommands(),
      );
      _scrollToActiveExercise();
    };
    final l10n = AppLocalizations.of(context)!;
    final unitService = Provider.of<UnitService>(context);
    Provider.of<LiveWorkoutViewModel>(context, listen: false)
        .configureLiveActivity(
      localeName: Localizations.localeOf(context).toLanguageTag(),
      strings: WorkoutLiveActivityStrings(
        setPosition: (index, total) =>
            l10n.liveActivitySetPosition(index, total),
        weightUnit:
            unitService.isMetric ? l10n.unit_kilograms : l10n.unit_pounds,
        distanceUnit:
            unitService.isMetric ? l10n.unit_kilometers : l10n.unit_miles,
        repsShort: l10n.repsShort,
        rirLabel: l10n.liveActivityRirLabel,
        rpeLabel: l10n.liveActivityRpeLabel,
        addExercise: l10n.liveActivityAddExercise,
        openApp: l10n.liveActivityOpenApp,
        // Short form on purpose: the button is 58pt wide, and the full
        // German "Überspringen" wraps to two lines in it.
        skip: l10n.liveActivitySkipShort,
        overduePrefix: l10n.liveActivityOverdueLabel,
        restDoneTitle: l10n.restTimerNotificationTitle,
        restDoneBody: l10n.restTimerNotificationBody,
      ),
    );
  }

  /// Buttons in the Live Activity run in another process; their commands are
  /// queued in the App Group and applied here once the app is back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed || !mounted) return;
    unawaited(
      Provider.of<LiveWorkoutViewModel>(context, listen: false)
          .applyPendingLiveActivityCommands(),
    );
  }

  // --- Cardio check helper ---
  bool _isCardio(RoutineExercise re) {
    return re.exercise.isCardio;
  }

  Widget _buildExerciseCardHeader(
    BuildContext context,
    RoutineExercise routineExercise,
    int index,
    AppLocalizations l10n,
    TextTheme textTheme,
    ColorScheme colorScheme, {
    required void Function(RoutineExercise)? onEditPauseTime,
    bool isProxy = false,
  }) {
    final titleContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        routineExercise.exercise.getLocalizedName(context),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      leading: null,
      title: isProxy
          ? titleContent
          : Listener(
              onPointerDown: (e) =>
                  _onDragPointerDown(e, routineExercise.id ?? index, index),
              onPointerMove: _onDragPointerMove,
              onPointerUp: _onDragPointerUp,
              onPointerCancel: _onDragPointerCancel,
              child: ReorderableDelayedDragStartListener(
                index: index,
                child: MorphSourceScope(
                  builder: (context, setHidden) => Builder(
                    builder: (titleCtx) => InkWell(
                      onTap: () => Navigator.of(context).push(
                        CardMorphRoute(
                          sourceContext: titleCtx,
                          sourceBorderRadius: 12.0,
                          // The title flies inside the container, so the
                          // detail screen dissolves out of it instead of being
                          // the only thing drawn while the container grows.
                          sourceBuilder: (_) => titleContent,
                          onSourceVisibilityChanged: setHidden,
                          builder: (context) => ExerciseDetailScreen(
                            exercise: routineExercise.exercise,
                          ),
                        ),
                      ),
                      child: titleContent,
                    ),
                  ),
                ),
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            tooltip: l10n.exerciseNoteTitle,
            onPressed: isProxy
                ? null
                : () => _editExerciseNotes(context, routineExercise),
          ),
          Selector<LiveWorkoutViewModel, int?>(
            selector: (_, vm) => vm.pauseTimes[routineExercise.id!],
            builder: (context, livePauseVal, child) {
              final liveHasPause = livePauseVal != null && livePauseVal > 0;
              if (liveHasPause) {
                return TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: isProxy
                      ? null
                      : (onEditPauseTime != null
                          ? () => onEditPauseTime(routineExercise)
                          : null),
                  child: Text(
                    _formatPauseTime(livePauseVal),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: DesignConstants.spacingL,
                    ),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(LucideIcons.timer),
                tooltip: l10n.editPauseTime,
                onPressed: isProxy
                    ? null
                    : (onEditPauseTime != null
                        ? () => onEditPauseTime(routineExercise)
                        : null),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.trash_2,
              color: DesignConstants.brandRedColor,
            ),
            tooltip: l10n.removeExercise,
            onPressed: isProxy ? null : () => _removeExercise(routineExercise),
          ),
        ],
      ),
    );
  }

  /// Expands the cards once the drop animation and the reorder have finished.
  void _scheduleExpandAfterDrop() {
    _expandTimer?.cancel();
    _expandTimer = Timer(
      kReorderDropSettleDuration,
      () {
        if (mounted && _isDragging && !_isDragActive) {
          _scrollAnchor.pin(
            _touchedAnchorId,
            () => setState(() {
              _isDragging = false;
              _dynamicHeadroom = 0.0;
            }),
          );
        }
      },
    );
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
                  child: AppButton.secondary(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(null);
                    },
                    label: l10n.cancel,
                    tooltip: l10n.cancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.primary(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop((
                        title: titleController.text.trim(),
                        notes: notesController.text.trim(),
                      ));
                    },
                    label: l10n.finishWorkoutButton,
                    tooltip: l10n.finishWorkoutButton,
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

  void _onReorderItem(int oldIndex, int newIndex) {
    Provider.of<LiveWorkoutViewModel>(
      context,
      listen: false,
    ).reorderExercise(oldIndex, newIndex);
  }

  final Set<int> _deletingExerciseIds = <int>{};

  void _removeExercise(RoutineExercise exerciseToRemove) {
    final id = exerciseToRemove.id;
    if (id == null || _deletingExerciseIds.contains(id)) return;
    HapticFeedbackService.instance.selectionFeedback();
    setState(() {
      _deletingExerciseIds.add(id);
    });
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        _deletingExerciseIds.remove(id);
        Provider.of<LiveWorkoutViewModel>(
          context,
          listen: false,
        ).removeExercise(id);
      }
    });
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
      await manager.updateExerciseNotes(re.exercise.canonicalName, result);
    }
  }

  void _addExercise({
    BuildContext? sourceContext,
    WidgetBuilder? sourceBuilder,
    void Function(bool hidden)? onSourceVisibilityChanged,
  }) async {
    final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);
    final selectedExercise = await Navigator.of(context).push<Exercise>(
      CardMorphRoute(
        sourceContext: sourceContext,
        sourceBorderRadius: 28.0,
        sourceBuilder: sourceBuilder,
        onSourceVisibilityChanged: onSourceVisibilityChanged,
        builder: (context) =>
            const ExerciseCatalogScreen(isSelectionMode: true),
      ),
    );

    if (selectedExercise != null) {
      final lastSets = await WorkoutLocalDataSource.instance
          .getLastSetsForExercise(selectedExercise.canonicalName);
      if (mounted) {
        setState(() {
          manager.lastPerformances[selectedExercise.canonicalName] = lastSets;
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
          _buildHeader(
              l10n.cardioDistanceLabel(
                  unitService.suffixFor(UnitDimension.distance)),
              flex: 4),
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
        ? " (+${unitService.formatDisplayWeight(pr.diff!)} ${unitService.suffixFor(UnitDimension.weight)})"
        : "";

    return PrCelebrationBanner(
      slideAnimation: _prSlideAnimation,
      exerciseName: pr.exerciseName,
      localizedRecordType: localizedRecordType,
      achievementText: achievementText,
      diffText: diffText,
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    // The top of the FAB from the bottom of the screen is:
    // 24.0 (bottom offset) + safeAreaBottom + 64.0 (FAB height) = 88.0 + safeAreaBottom
    // We add 12px so the arrow head points just above the button.
    final fabTopOffset = 100.0 + MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: ColdStartEmptyState(
        icon: LucideIcons.circle_plus,
        title: l10n.emptyStateAddFirstExercise,
        subtitle: l10n.emptyStateAddFirstExerciseSubtitle,
        callToAction: l10n.fabAddExercise,
        targetCenter: false,
        customEndXOffset: 110.0, // Center of the wide right-aligned FAB
        customTargetYOffset: fabTopOffset,
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

      final result = await showGlassBottomMenu<({bool saved, int? value})>(
        context: context,
        title: l10n.editPauseTimeTitle,
        headerTrailing: (currentPause != null && currentPause > 0)
            ? TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  HapticFeedbackService.instance.selectionFeedback();
                  Navigator.of(context).pop((saved: true, value: 0));
                },
                child: Text(
                  l10n.removeTimer,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber,
                  ),
                ),
              )
            : null,
        contentBuilder: (ctx, close) {
          return RoutinePauseTimeDialog(
            initialPauseSeconds: currentPause,
            onSave: (seconds) {
              close();
              Navigator.of(ctx).pop((saved: true, value: seconds));
            },
            onCancel: () {
              close();
              Navigator.of(ctx).pop((saved: false, value: null));
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
            // Down, not back: this does not leave the workout, it minimizes
            // it into the running workout bar above the bottom navigation.
            leading: IconButton(
              tooltip: l10n.minimizeWorkoutButton,
              icon: const Icon(LucideIcons.chevron_down),
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
                                ? _buildEmptyState(context, l10n)
                                : Listener(
                                    onPointerMove: (e) {
                                      if (_isDragActive) {
                                        final manager =
                                            Provider.of<LiveWorkoutViewModel>(
                                                context,
                                                listen: false);
                                        _trackReorderHover(
                                            e.position.dy, manager.exercises);
                                      }
                                    },
                                    child: ReorderableListView.builder(
                                      scrollController: _scrollController,
                                      buildDefaultDragHandles: false,
                                      scrollCacheExtent:
                                          const ScrollCacheExtent.pixels(
                                              1500.0),
                                      header: ReorderHeadroom(
                                        height: _isDragging
                                            ? _dynamicHeadroom
                                            : 0.0,
                                      ),
                                      padding: EdgeInsets.only(
                                        bottom: (showRestBar
                                                ? 220.0
                                                : DesignConstants
                                                    .bottomContentSpacer) +
                                            MediaQuery.paddingOf(context)
                                                .bottom,
                                      ),
                                      onReorderStart: (index) {
                                        _isDragActive = true;
                                        ReorderHapticFeedback.onDragStart(
                                            index);
                                        _scrollAnchor.discard();
                                        _collapseTimer?.cancel();
                                        _expandTimer?.cancel();
                                        if (!_isDragging) {
                                          setState(() {
                                            _isDragging = true;
                                          });
                                        }
                                      },
                                      onReorderEnd: (index) {
                                        _isDragActive = false;
                                        ReorderHapticFeedback.onDragEnd();
                                        _scheduleExpandAfterDrop();
                                      },
                                      proxyDecorator: (Widget child, int index,
                                          Animation<double> animation) {
                                        final l10n =
                                            AppLocalizations.of(context)!;
                                        final theme = Theme.of(context);
                                        if (index >= 0 &&
                                            index < exercises.length) {
                                          final routineExercise =
                                              exercises[index];
                                          final proxyChild = WorkoutCard(
                                            child: _buildExerciseCardHeader(
                                              context,
                                              routineExercise,
                                              index,
                                              l10n,
                                              theme.textTheme,
                                              theme.colorScheme,
                                              onEditPauseTime: null,
                                              isProxy: true,
                                            ),
                                          );
                                          return buildReorderDragProxy(
                                              context, proxyChild, animation);
                                        }
                                        return buildReorderDragProxy(
                                            context, child, animation);
                                      },
                                      onReorderItem: _onReorderItem,
                                      itemCount: exercises.length,
                                      itemBuilder: (context, index) {
                                        final routineExercise =
                                            exercises[index];
                                        final showE1rmSummary =
                                            !_isCardio(routineExercise);

                                        final isDeleting = _deletingExerciseIds
                                            .contains(routineExercise.id);

                                        return KeyedSubtree(
                                          key: _scrollAnchor.keyFor(
                                            routineExercise.id ?? index,
                                          ),
                                          child: AnimatedSize(
                                            duration:
                                                kReorderCardResizeDuration,
                                            curve: Curves.easeInOutCubic,
                                            alignment: Alignment.topCenter,
                                            child: isDeleting
                                                ? const SizedBox(
                                                    width: double.infinity,
                                                    height: 0)
                                                : AnimatedOpacity(
                                                    duration: const Duration(
                                                        milliseconds: 180),
                                                    curve: Curves.easeOut,
                                                    opacity:
                                                        isDeleting ? 0.0 : 1.0,
                                                    child: RepaintBoundary(
                                                      key: ValueKey(
                                                          routineExercise.id),
                                                      child: WorkoutCard(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            _buildExerciseCardHeader(
                                                              context,
                                                              routineExercise,
                                                              index,
                                                              l10n,
                                                              textTheme,
                                                              colorScheme,
                                                              onEditPauseTime:
                                                                  editPauseTime,
                                                            ),
                                                            _isDragging
                                                                ? const SizedBox
                                                                    .shrink()
                                                                : AnimatedSize(
                                                                    duration: const Duration(
                                                                        milliseconds:
                                                                            250),
                                                                    curve: Curves
                                                                        .easeInOut,
                                                                    alignment:
                                                                        Alignment
                                                                            .topCenter,
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        if (routineExercise.notes !=
                                                                                null &&
                                                                            routineExercise.notes!.isNotEmpty)
                                                                          Padding(
                                                                            padding:
                                                                                const EdgeInsets.only(
                                                                              left: 16.0,
                                                                              right: 16.0,
                                                                              bottom: 12.0,
                                                                            ),
                                                                            child:
                                                                                InkWell(
                                                                              onTap: () => _editExerciseNotes(context, routineExercise),
                                                                              borderRadius: BorderRadius.circular(8),
                                                                              child: Container(
                                                                                width: double.infinity,
                                                                                padding: const EdgeInsets.all(12),
                                                                                decoration: BoxDecoration(
                                                                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                                                                  borderRadius: BorderRadius.circular(8),
                                                                                  border: Border.all(
                                                                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                                                                                  ),
                                                                                ),
                                                                                child: Row(
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Icon(
                                                                                      Icons.description_outlined,
                                                                                      size: 16,
                                                                                      color: colorScheme.onSurfaceVariant,
                                                                                    ),
                                                                                    const SizedBox(width: 8),
                                                                                    Expanded(
                                                                                      child: Text(
                                                                                        routineExercise.notes!,
                                                                                        style: textTheme.bodyMedium?.copyWith(
                                                                                          color: colorScheme.onSurfaceVariant,
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
                                                                            manager:
                                                                                manager,
                                                                          ),
                                                                        Padding(
                                                                          padding:
                                                                              const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                0.0,
                                                                          ),
                                                                          child: Selector<
                                                                              LiveWorkoutViewModel,
                                                                              Map<int, SetLog>>(
                                                                            selector:
                                                                                (context, vm) {
                                                                              final map = <int, SetLog>{};
                                                                              for (final template in routineExercise.setTemplates) {
                                                                                final log = vm.setLogs[template.id];
                                                                                if (log != null) {
                                                                                  map[template.id!] = log;
                                                                                }
                                                                              }
                                                                              return map;
                                                                            },
                                                                            shouldRebuild:
                                                                                (prev, next) {
                                                                              if (prev.length != next.length) {
                                                                                return true;
                                                                              }
                                                                              for (final key in prev.keys) {
                                                                                final prevLog = prev[key];
                                                                                final nextLog = next[key];
                                                                                if (prevLog == null || nextLog == null) {
                                                                                  return true;
                                                                                }
                                                                                if (prevLog.setType != nextLog.setType || prevLog.isCompleted != nextLog.isCompleted) {
                                                                                  return true;
                                                                                }
                                                                              }
                                                                              return false;
                                                                            },
                                                                            builder: (context,
                                                                                exerciseSetLogs,
                                                                                child) {
                                                                              return AnimatedSize(
                                                                                duration: const Duration(milliseconds: 260),
                                                                                curve: Curves.easeInOutCubic,
                                                                                alignment: Alignment.topCenter,
                                                                                child: Column(
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    // FIX: Insert header row dynamically.
                                                                                    _buildHeaderRow(
                                                                                      routineExercise,
                                                                                      l10n,
                                                                                    ),

                                                                                    // Set Rows
                                                                                    ...routineExercise.setTemplates.asMap().entries.map((setEntry) {
                                                                                      final templateId = setEntry.value.id!;
                                                                                      final template = setEntry.value; // <--- Template
                                                                                      final setLog = exerciseSetLogs[templateId];

                                                                                      if (setLog == null) {
                                                                                        return const SizedBox.shrink();
                                                                                      }
                                                                                      int workingSetIndex = 0;
                                                                                      for (int i = 0; i <= setEntry.key; i++) {
                                                                                        final currentTemplateId = routineExercise.setTemplates[i].id!;
                                                                                        if (exerciseSetLogs[currentTemplateId]?.setType != 'warmup') {
                                                                                          workingSetIndex++;
                                                                                        }
                                                                                      }

                                                                                      return LiveWorkoutSetRow(
                                                                                        setIndex: workingSetIndex,
                                                                                        rowIndex: setEntry.key,
                                                                                        templateId: templateId,
                                                                                        setLog: setLog,
                                                                                        lastPerfSets: manager.lastPerformances[routineExercise.exercise.canonicalName] ?? [],
                                                                                        template: template,
                                                                                        manager: manager,
                                                                                        isCardio: _isCardio(routineExercise),
                                                                                      );
                                                                                    }),
                                                                                    Padding(
                                                                                      padding: const EdgeInsets.symmetric(
                                                                                        horizontal: 16.0,
                                                                                      ),
                                                                                      child: TextButton.icon(
                                                                                        onPressed: () => _addSet(routineExercise),
                                                                                        icon: const Icon(LucideIcons.plus),
                                                                                        label: Text(l10n.addSetButton),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Soft bottom fade-out vignette shadow underneath rest timer, FAB & attribution
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: DesignConstants.bottomVignetteHeight,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: DesignConstants.bottomVignetteGradient(
                              Theme.of(context).brightness == Brightness.dark,
                            ),
                          ),
                        ),
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
                            padding: const EdgeInsets.only(
                              bottom: 12.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _HiddenWhileKeyboardVisible(
                                  child: AnimatedBuilder(
                                    animation: manager,
                                    builder: (context, _) {
                                      final isRunning =
                                          manager.remainingRestSeconds > 0;
                                      final isDoneBanner =
                                          !isRunning && manager.showRestDone;
                                      final showRestBar =
                                          isRunning || isDoneBanner;

                                      return AnimatedSlide(
                                        duration:
                                            const Duration(milliseconds: 320),
                                        curve: Curves.easeInOutCubic,
                                        offset: showRestBar
                                            ? Offset.zero
                                            : const Offset(0.0, 1.25),
                                        child: AnimatedOpacity(
                                          duration:
                                              const Duration(milliseconds: 280),
                                          curve: Curves.easeInOutCubic,
                                          opacity: showRestBar ? 1.0 : 0.0,
                                          child: IgnorePointer(
                                            ignoring: !showRestBar,
                                            child: _LiveWorkoutRestBar(
                                              isRunning: isRunning,
                                              isDoneBanner: isDoneBanner,
                                              remainingRestSeconds:
                                                  manager.remainingRestSeconds,
                                              onAdjustRestTime:
                                                  manager.adjustRestTime,
                                              onCancelRest: manager.cancelRest,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Consumer<LiveWorkoutViewModel>(
                      builder: (context, vm, child) {
                        final showRestBar =
                            vm.remainingRestSeconds > 0 || vm.showRestDone;
                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeInOutCubic,
                          bottom: showRestBar
                              ? (20.0 +
                                  DesignConstants.workoutOverlayHeight +
                                  8.0) // 12.0px outer padding + 8.0px inner bottom margin + 64.0px rest bar height + 8.0px gap = 92.0px
                              : (12.0 + MediaQuery.paddingOf(context).bottom),
                          right: 16.0,
                          child: RepaintBoundary(
                            child: _HiddenWhileKeyboardVisible(
                              child: _LiveWorkoutFab(onPressed: _addExercise),
                            ),
                          ),
                        );
                      },
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

  String _formatDisplayWeightText(
    String metricText,
    UnitService unitService, {
    int fractionDigits = 1,
  }) {
    final value = _extractNumericValue(metricText);
    if (value == null) return metricText;
    return '${unitService.formatDisplayWeight(value, fractionDigits: fractionDigits)} ${unitService.suffixFor(UnitDimension.weight)}';
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
  final void Function({
    BuildContext? sourceContext,
    WidgetBuilder? sourceBuilder,
    void Function(bool hidden)? onSourceVisibilityChanged,
  }) onPressed;

  const _LiveWorkoutFab({required this.onPressed});

  @override
  State<_LiveWorkoutFab> createState() => _LiveWorkoutFabState();
}

/// Removes its child while the software keyboard is up.
///
/// The bottom of the live workout screen carries two floating elements — the
/// add-exercise button and the rest bar — and both sit exactly where the
/// keyboard appears. Shared so the two cannot drift apart.
class _HiddenWhileKeyboardVisible extends StatefulWidget {
  final Widget child;

  const _HiddenWhileKeyboardVisible({required this.child});

  @override
  State<_HiddenWhileKeyboardVisible> createState() =>
      _HiddenWhileKeyboardVisibleState();
}

class _HiddenWhileKeyboardVisibleState
    extends State<_HiddenWhileKeyboardVisible> with WidgetsBindingObserver {
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
  Widget build(BuildContext context) =>
      _keyboardHeight > 0 ? const SizedBox.shrink() : widget.child;
}

class _LiveWorkoutFabState extends State<_LiveWorkoutFab> {
  bool _isFabHidden = false;

  @override
  Widget build(BuildContext context) {
    final showRestBar = context.select<LiveWorkoutViewModel, bool>(
        (vm) => vm.remainingRestSeconds > 0 || vm.showRestDone);

    Widget buildFabContent({VoidCallback? onPressed}) {
      final fab = GlassFab(
        label: AppLocalizations.of(context)!.fabAddExercise,
        onPressed: onPressed ?? () {},
      );

      if (showRestBar) {
        return ClipPath(
          clipper: const _LiveWorkoutFabShadowClipper(),
          child: fab,
        );
      }
      return fab;
    }

    return Opacity(
      opacity: _isFabHidden ? 0.0 : 1.0,
      child: IgnorePointer(
        ignoring: _isFabHidden,
        child: Builder(
          builder: (fabCtx) => buildFabContent(
            onPressed: () => widget.onPressed(
              sourceContext: fabCtx,
              sourceBuilder: (_) => buildFabContent(),
              onSourceVisibilityChanged: (hidden) {
                if (mounted) setState(() => _isFabHidden = hidden);
              },
            ),
          ),
        ),
      ),
    );
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

class _LiveWorkoutRestBar extends StatefulWidget {
  const _LiveWorkoutRestBar({
    required this.isRunning,
    required this.isDoneBanner,
    required this.remainingRestSeconds,
    required this.onAdjustRestTime,
    required this.onCancelRest,
  });

  final bool isRunning;
  final bool isDoneBanner;
  final int remainingRestSeconds;
  final void Function(int seconds) onAdjustRestTime;
  final VoidCallback onCancelRest;

  @override
  State<_LiveWorkoutRestBar> createState() => _LiveWorkoutRestBarState();
}

class _LiveWorkoutRestBarState extends State<_LiveWorkoutRestBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morphController;
  late final Animation<double> _morphAnimation;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: widget.isDoneBanner ? 1.0 : 0.0,
    );
    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant _LiveWorkoutRestBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDoneBanner && !oldWidget.isDoneBanner) {
      _morphController.forward(from: 0.0);
    } else if (!widget.isDoneBanner && oldWidget.isDoneBanner) {
      _morphController.reverse();
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final double r = DesignConstants.workoutOverlayHeight / 2;

    const saturatedAccent = DesignConstants.brandAccentColor;
    final defaultGlass = DesignConstants.liquidGlassSettings(isDark);
    final doneGlass = LiquidGlassSettings(
      thickness: 30,
      blur: 0.0,
      glassColor: saturatedAccent,
      lightIntensity: isDark ? 0.55 : 0.80,
      saturation: 1.0,
      ambientRim: 0.2,
    );

    final restSeconds = widget.remainingRestSeconds;
    final minutes = restSeconds ~/ 60;
    final seconds = restSeconds % 60;
    final timerStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: DesignConstants.workoutOverlayHeight,
        child: Stack(
          children: [
            // Drop shadow base
            Positioned.fill(
              child: ClipPath(
                clipper: ShadowOuterClipper(borderRadius: r),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(r),
                    boxShadow: DesignConstants.glassShadow(isDark),
                  ),
                ),
              ),
            ),

            AnimatedBuilder(
              animation: _morphAnimation,
              builder: (context, _) {
                final t = _morphAnimation.value;

                return Stack(
                  children: [
                    // Layer 1: Dark Glass Timer Pill
                    if (t < 1.0)
                      Positioned.fill(
                        child: Opacity(
                          opacity: (1.0 - t).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 1.0 - (0.04 * t),
                            child: IgnorePointer(
                              ignoring: t > 0.5,
                              child: GlassAdaptiveScope(
                                maxQuality: DesignConstants.defaultGlassQuality,
                                minQuality: DesignConstants.minGlassQuality,
                                child: GlassContainer(
                                  useOwnLayer: true,
                                  height: DesignConstants.workoutOverlayHeight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 12.0),
                                  shape: LiquidRoundedSuperellipse(
                                      borderRadius: r),
                                  quality: DesignConstants.defaultGlassQuality,
                                  settings: defaultGlass,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // -15 Button
                                      SizedBox(
                                        height: 38,
                                        width: 48,
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            backgroundColor: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.08)
                                                : Colors.black
                                                    .withValues(alpha: 0.06),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.1)
                                                    : Colors.black.withValues(
                                                        alpha: 0.05),
                                              ),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () =>
                                              widget.onAdjustRestTime(-15),
                                          child: Text(
                                            "-15",
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
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
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            backgroundColor: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.08)
                                                : Colors.black
                                                    .withValues(alpha: 0.06),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.1)
                                                    : Colors.black.withValues(
                                                        alpha: 0.05),
                                              ),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () =>
                                              widget.onAdjustRestTime(15),
                                          child: Text(
                                            "+15",
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
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
                                        child: AppButton.primary(
                                          onPressed: widget.onCancelRest,
                                          label: l10n.skipButton,
                                          tooltip: l10n.skipButton,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Layer 2: Radiant Yellow "Pause is over" Pill
                    if (t > 0.0)
                      Positioned.fill(
                        child: Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.95 + (0.05 * t),
                            child: IgnorePointer(
                              ignoring: t <= 0.5,
                              child: GlassAdaptiveScope(
                                maxQuality: DesignConstants.defaultGlassQuality,
                                minQuality: DesignConstants.minGlassQuality,
                                child: GlassContainer(
                                  useOwnLayer: true,
                                  height: DesignConstants.workoutOverlayHeight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 12.0),
                                  shape: LiquidRoundedSuperellipse(
                                      borderRadius: r),
                                  quality: DesignConstants.defaultGlassQuality,
                                  settings: doneGlass,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.circle_check,
                                              color: Colors.black),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.restOverLabel,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
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
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                          ),
                                          onPressed: widget.onCancelRest,
                                          child: Text(
                                            l10n.snackbar_button_ok,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
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
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
