import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/sources/workout_local_data_source.dart';
import '../../sharing/share_service.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/routine.dart';
import '../domain/repositories/workout_repository.dart';
import '../../../services/haptic_feedback_service.dart';
import 'edit_routine_screen.dart';
import 'live_workout_screen.dart';
import 'live_workout_view_model.dart';
import '../../../util/design_constants.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/card_morph_route.dart';
import '../../../widgets/common/common.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/app_button.dart';
import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';

/// A screen that displays a list of all saved [Routine] templates.
///
/// Users can start a workout from a routine, duplicate existing ones,
/// or navigate to [EditRoutineScreen] to create or edit routines.
class RoutinesScreen extends StatefulWidget {
  /// Optional ID to automatically open the editor for a specific routine.
  final int? initialRoutineId;
  const RoutinesScreen({super.key, this.initialRoutineId});
  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  static const ShareService _shareService = ShareService();
  late final Stream<List<Routine>> _routinesStream;
  bool _initialRoutineOpened = false;
  bool _isFabHidden = false;
  final Set<int> _dismissedRoutineIds = {};

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.routineList));
    _routinesStream = Provider.of<IWorkoutRepository>(context, listen: false)
        .watchAllRoutines();
  }

  Future<bool> _checkAndHandleOngoingWorkout() async {
    final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);
    if (!manager.isActive) return true;

    final choice = await showActiveWorkoutConflictDialog(context);
    if (choice == ActiveWorkoutConflictResult.resume) {
      if (mounted && manager.workoutLog != null) {
        Navigator.of(context).push(
          CardMorphRoute(
            builder: (context) => LiveWorkoutScreen(
              workoutLog: manager.workoutLog!,
              routine: null,
            ),
          ),
        );
      }
      return false;
    } else if (choice == ActiveWorkoutConflictResult.discard) {
      final logId = manager.workoutLog?.id;
      if (logId != null) {
        await WorkoutLocalDataSource.instance.deleteWorkoutLog(logId);
      }
      await manager.clearLocalSessionState();
      return true;
    }

    return false;
  }

  void _startWorkout(Routine routine,
      {BuildContext? sourceContext,
      WidgetBuilder? sourceBuilder,
      MorphSourceVisibilityCallback? onSourceVisibilityChanged}) async {
    final sourceRect = CardMorphRoute.measureRect(sourceContext);
    final canProceed = await _checkAndHandleOngoingWorkout();
    if (!canProceed) return;
    if (!mounted) return;

    final fullRoutine = await WorkoutLocalDataSource.instance.getRoutineById(
      routine.id!,
    );
    final newWorkoutLog = await WorkoutLocalDataSource.instance.startWorkout(
      routineName: routine.name,
    );
    if (!mounted) return;
    if (fullRoutine != null) {
      HapticFeedbackService.instance.confirmationFeedback();
      Navigator.of(context).push(
        CardMorphRoute(
          sourceRect: sourceRect,
          sourceBuilder: sourceBuilder,
          onSourceVisibilityChanged: onSourceVisibilityChanged,
          builder: (context) => LiveWorkoutScreen(
            routine: fullRoutine,
            workoutLog: newWorkoutLog,
          ),
        ),
      );
    }
  }

  void _startEmptyWorkout({
    BuildContext? sourceContext,
    WidgetBuilder? sourceBuilder,
    MorphSourceVisibilityCallback? onSourceVisibilityChanged,
  }) async {
    // Measured up front: the card is gone from the tree by the time the
    // ongoing-workout check has resolved.
    final sourceRect = CardMorphRoute.measureRect(sourceContext);
    final canProceed = await _checkAndHandleOngoingWorkout();
    if (!canProceed) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final newWorkoutLog = await WorkoutLocalDataSource.instance.startWorkout(
      routineName: l10n.freeWorkoutTitle,
    );
    if (!mounted) return;
    HapticFeedbackService.instance.confirmationFeedback();
    Navigator.of(context).push(
      CardMorphRoute(
        sourceRect: sourceRect,
        sourceBuilder: sourceBuilder,
        onSourceVisibilityChanged: onSourceVisibilityChanged,
        builder: (context) => LiveWorkoutScreen(workoutLog: newWorkoutLog),
      ),
    );
  }

  void _createNewRoutine({
    BuildContext? sourceContext,
    WidgetBuilder? sourceBuilder,
    void Function(bool hidden)? onSourceVisibilityChanged,
  }) {
    Navigator.of(context).push(
      CardMorphRoute(
        sourceContext: sourceContext,
        sourceBorderRadius: 28.0,
        sourceBuilder: sourceBuilder,
        onSourceVisibilityChanged: onSourceVisibilityChanged,
        builder: (context) => const EditRoutineScreen(),
      ),
    );
  }

  // New methods for the menu
  void _duplicateRoutine(int routineId) async {
    await WorkoutLocalDataSource.instance.duplicateRoutine(routineId);
    HapticFeedbackService.instance.confirmationFeedback();
  }

  Future<void> _shareRoutine(Routine routine) async {
    final fullRoutine =
        await WorkoutLocalDataSource.instance.getRoutineById(routine.id!);
    if (!mounted || fullRoutine == null) return;
    await _shareService.showRoutineShareSheet(
      context: context,
      routine: fullRoutine,
    );
  }

  // 1. The menu method
  void _deleteRoutine(BuildContext context, Routine routine) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDeleteConfirmation(
      context,
      content: l10n.deleteRoutineConfirmContent(routine.name),
    );

    if (confirmed) {
      _performDeleteRoutine(routine);
    }
  }

  void _performDeleteRoutine(Routine routine) async {
    await WorkoutLocalDataSource.instance.deleteRoutine(routine.id!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme; // Defined here

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(title: l10n.workoutRoutinesTitle),
      body: StreamBuilder<List<Routine>>(
        stream: _routinesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final routines = (snapshot.data ?? [])
              .where((r) => !_dismissedRoutineIds.contains(r.id))
              .toList();

          // If an initialRoutineId was passed, navigate there directly on first load.
          if (widget.initialRoutineId != null &&
              !_initialRoutineOpened &&
              routines.isNotEmpty) {
            _initialRoutineOpened = true;
            Routine? routineToEdit;
            for (final r in routines) {
              if (r.id == widget.initialRoutineId) {
                routineToEdit = r;
                break;
              }
            }
            if (routineToEdit != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).push(
                  CardMorphRoute(
                    builder: (context) =>
                        EditRoutineScreen(routine: routineToEdit!),
                  ),
                );
              });
            }
          }

          if (routines.isEmpty) {
            return _buildEmptyState(context, l10n, textTheme);
          }

          return ListView.builder(
            padding: DesignConstants.cardPadding.copyWith(
              top: DesignConstants.cardPadding.top + topPadding,
            ),
            itemCount: routines.length + 1, // instead of +2
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildStartEmptyWorkoutCard(context, l10n);
              }
              final routine = routines[index - 1];
              return MorphSourceScope(
                builder: (context, setHidden) => Builder(
                  builder: (cardCtx) {
                    // One definition of the card body, used four times: as the
                    // real card, and as the copy that flies inside the container
                    // for each of the three morphs that start here. The copies
                    // are painted, never tapped, so they take no callbacks and
                    // show a plain icon where the real card has its menu.
                    Widget buildCardBody({
                      VoidCallback? onStart,
                      bool interactive = false,
                    }) =>
                        SummaryCard(
                          child: ListTile(
                            leading: AppButton.primary(
                              onPressed: onStart ?? () {},
                              label: l10n.startButton,
                              tooltip: l10n.startButton,
                              size: AppButtonSize.small,
                            ),
                            title: Text(
                              routine.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(l10n.editRoutineSubtitle),
                            trailing: interactive
                                ? PlatformAdaptivePopupMenu<String>(
                                    icon: Icon(
                                      LucideIcons.ellipsis_vertical,
                                      color: textTheme.bodyMedium?.color,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'duplicate') {
                                        _duplicateRoutine(routine.id!);
                                      } else if (value == 'share') {
                                        _shareRoutine(routine);
                                      } else if (value == 'delete') {
                                        _deleteRoutine(context, routine);
                                      }
                                    },
                                    items: [
                                      PlatformAdaptivePopupMenuItem<String>(
                                        value: 'duplicate',
                                        label: l10n.duplicate,
                                        icon: LucideIcons.copy,
                                      ),
                                      PlatformAdaptivePopupMenuItem<String>(
                                        value: 'share',
                                        label: l10n.share,
                                        icon: DesignConstants.adaptiveShareIcon,
                                      ),
                                      PlatformAdaptivePopupMenuItem<String>(
                                        value: 'delete',
                                        label: l10n.delete,
                                        icon: LucideIcons.trash_2,
                                        isDestructive: true,
                                      ),
                                    ],
                                  )
                                : Icon(
                                    LucideIcons.ellipsis_vertical,
                                    color: textTheme.bodyMedium?.color,
                                  ),
                          ),
                        );

                    return GlassActionableCard(
                      dismissibleKey: Key('routine_${routine.id}'),
                      onEdit: () {
                        Navigator.of(context).push(
                          CardMorphRoute(
                            sourceContext: cardCtx,
                            sourceBuilder: (_) => buildCardBody(),
                            onSourceVisibilityChanged: setHidden,
                            builder: (context) =>
                                EditRoutineScreen(routine: routine),
                          ),
                        );
                      },
                      confirmDelete: () async {
                        return await showDeleteConfirmation(
                          context,
                          content: l10n.deleteRoutineConfirmContent(routine.name),
                        );
                      },
                      onDelete: () {
                        setState(() {
                          if (routine.id != null) {
                            _dismissedRoutineIds.add(routine.id!);
                          }
                        });
                        _performDeleteRoutine(routine);
                      },
                      additionalActions: [
                        GlassContextAction(
                          label: l10n.duplicate,
                          icon: LucideIcons.copy,
                          onTap: () => _duplicateRoutine(routine.id!),
                        ),
                        GlassContextAction(
                          label: l10n.share,
                          icon: DesignConstants.adaptiveShareIcon,
                          onTap: () => _shareRoutine(routine),
                        ),
                      ],
                      onTap: () {
                        Navigator.of(context).push(
                          CardMorphRoute(
                            sourceContext: cardCtx,
                            sourceBuilder: (_) => buildCardBody(),
                            onSourceVisibilityChanged: setHidden,
                            builder: (context) =>
                                EditRoutineScreen(routine: routine),
                          ),
                        );
                      },
                      child: buildCardBody(
                        interactive: true,
                        onStart: () => _startWorkout(
                          routine,
                          sourceContext: cardCtx,
                          sourceBuilder: (_) => buildCardBody(),
                          onSourceVisibilityChanged: setHidden,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Opacity(
        opacity: _isFabHidden ? 0.0 : 1.0,
        child: IgnorePointer(
          ignoring: _isFabHidden,
          child: Builder(
            builder: (fabCtx) {
              Widget buildFab({VoidCallback? onPressed}) => GlassFab(
                    label: l10n.addRoutineButton,
                    onPressed: onPressed ?? () {},
                  );

              return GlassFab(
                label: l10n.addRoutineButton,
                onPressed: () => _createNewRoutine(
                  sourceContext: fabCtx,
                  sourceBuilder: (_) => buildFab(),
                  onSourceVisibilityChanged: (hidden) {
                    if (mounted) setState(() => _isFabHidden = hidden);
                  },
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // FIX 5: _buildStartEmptyWorkoutCard as SummaryCard button
  Widget _buildStartEmptyWorkoutCard(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) {
          // The copy that flies inside the growing container, so the live
          // workout screen dissolves out of this card rather than being the
          // only thing on screen while it grows.
          Widget buildCardBody({VoidCallback? onTap}) => SummaryCard(
                child: ListTile(
                  leading: const Icon(LucideIcons.circle_play),
                  title: Text(
                    l10n.startEmptyWorkoutButton,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: onTap,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignConstants.borderRadiusM),
                  ),
                ),
              );

          return buildCardBody(
            onTap: () => _startEmptyWorkout(
              sourceContext: cardCtx,
              sourceBuilder: (_) => buildCardBody(),
              onSourceVisibilityChanged: setHidden,
            ),
          );
        },
      ),
    );
  }

  // In RoutinesScreen: _buildEmptyState ersetzen/erweitern

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    TextTheme textTheme,
  ) {
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: ColdStartEmptyState(
        icon: LucideIcons.swatch_book,
        title: l10n.emptyRoutinesTitle,
        subtitle: l10n.emptyRoutinesSubtitle,
        callToAction: l10n.addRoutineButton,
        showArrow: true,
        customEndXOffset: 110.0,
        customTargetYOffset: 100.0 + MediaQuery.paddingOf(context).bottom,
      ),
    );
  }
}
