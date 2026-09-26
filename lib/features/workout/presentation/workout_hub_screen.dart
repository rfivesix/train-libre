import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../data/sources/workout_local_data_source.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/routine.dart';
import '../domain/repositories/workout_repository.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../sharing/share_service.dart';
import 'edit_routine_screen.dart';
import '../../exercise_catalog/presentation/exercise_catalog_screen.dart';
import '../../analytics/presentation/recovery_tracker_screen.dart';
import '../../analytics/presentation/statistics_hub_view_model.dart';
import '../../analytics/presentation/widgets/recovery_section_card.dart';
import '../../statistics/data/statistics_hub_data_adapter.dart';
import '../../statistics/domain/recovery_payload_models.dart';
import '../../statistics/domain/timeframe_block.dart';
import 'live_workout_screen.dart';
import 'live_workout_view_model.dart';
import '../data/manual_training_plan_repository.dart';
import '../domain/models/manual_training_plan.dart';
import 'manual_plan_screen.dart';
import 'manual_plan_text.dart';
import 'widgets/manual_plan_ui.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/card_morph_route.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/empty_states/card_empty_state_overlay.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';

/// The central management screen for all workout-related activities.
///
/// Features the active manual training plan hero, muscle readiness / recovery,
/// quick actions for starting an empty workout or creating a routine, and the
/// full vertical list of routines with Hevy-style cards.
class WorkoutHubScreen extends StatefulWidget {
  const WorkoutHubScreen({super.key});

  @override
  State<WorkoutHubScreen> createState() => _WorkoutHubScreenState();
}

class _WorkoutHubScreenState extends State<WorkoutHubScreen> {
  final _manualPlans = ManualTrainingPlanRepository();
  int _manualPlanRefresh = 0;
  late final Stream<List<Routine>> _routinesStream;
  late Future<RecoveryAnalyticsPayload> _recoveryFuture;
  late final l10n = AppLocalizations.of(context)!;
  static const ShareService _shareService = ShareService();
  final Set<int> _dismissedRoutineIds = {};

  @override
  void initState() {
    super.initState();
    _routinesStream = Provider.of<IWorkoutRepository>(context, listen: false)
        .watchAllRoutinesWithDetails();
    _recoveryFuture = _loadRecovery();
  }

  Future<RecoveryAnalyticsPayload> _loadRecovery() {
    return StatisticsHubDataAdapter(
      workoutDatabaseHelper: WorkoutLocalDataSource.instance,
    ).fetchRecovery(
      selectedBlockType: TimeframeBlock.week,
      anchorDate: DateTime.now(),
    );
  }

  void _retryRecovery() {
    setState(() => _recoveryFuture = _loadRecovery());
  }

  Future<
      ({
        ManualTrainingPlan plan,
        PlannedCalendarDay? today,
        PlannedCalendarDay? next
      })?> _loadManualPlanSummary() async {
    final plan = await _manualPlans.activePlan();
    if (plan == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = await _manualPlans.calendar(
      plan.id,
      today,
      DateTime(today.year, today.month, today.day + 28),
    );
    return (
      plan: plan,
      today:
          days.where((day) => DateUtils.isSameDay(day.date, today)).firstOrNull,
      next: days
          .where((day) =>
              !day.day.isRest && day.status == PlannedDayStatus.planned)
          .firstOrNull,
    );
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

  void _startEmptyWorkout({
    BuildContext? sourceContext,
    WidgetBuilder? sourceBuilder,
    MorphSourceVisibilityCallback? onSourceVisibilityChanged,
  }) async {
    final sourceRect = CardMorphRoute.measureRect(sourceContext);
    final canProceed = await _checkAndHandleOngoingWorkout();
    if (!canProceed) return;
    if (!mounted) return;

    final newLog = await WorkoutLocalDataSource.instance.startWorkout(
      routineName: l10n.free_training,
    );
    if (mounted) {
      HapticFeedbackService.instance.confirmationFeedback();
      Navigator.of(context).push(
        CardMorphRoute(
          sourceRect: sourceRect,
          sourceBuilder: sourceBuilder,
          onSourceVisibilityChanged: onSourceVisibilityChanged,
          builder: (context) => LiveWorkoutScreen(workoutLog: newLog),
        ),
      );
    }
  }

  void _startRoutine(
    Routine routine, {
    BuildContext? sourceContext,
    WidgetBuilder? sourceBuilder,
    MorphSourceVisibilityCallback? onSourceVisibilityChanged,
  }) async {
    final sourceRect = CardMorphRoute.measureRect(sourceContext);
    final canProceed = await _checkAndHandleOngoingWorkout();
    if (!canProceed) return;
    if (!mounted) return;

    if (routine.id != null) {
      await WorkoutLocalDataSource.instance.touchRoutineLastUsed(routine.id!);
    }

    final detailedRoutine =
        await WorkoutLocalDataSource.instance.getRoutineById(
      routine.id!,
    );
    if (detailedRoutine == null || !mounted) return;

    final newLog = await WorkoutLocalDataSource.instance.startWorkout(
      routineName: routine.name,
    );
    unawaited(TelemetryService.instance
        .trackFeatureUsed(featureKey: FeatureKey.routineStarted));
    if (mounted) {
      HapticFeedbackService.instance.confirmationFeedback();
      Navigator.of(context).push(
        CardMorphRoute(
          sourceRect: sourceRect,
          sourceBuilder: sourceBuilder,
          onSourceVisibilityChanged: onSourceVisibilityChanged,
          builder: (context) => LiveWorkoutScreen(
            routine: detailedRoutine,
            workoutLog: newLog,
          ),
        ),
      );
    }
  }

  Future<void> _createNewRoutine({
    BuildContext? sourceContext,
    WidgetBuilder? sourceBuilder,
    MorphSourceVisibilityCallback? onSourceVisibilityChanged,
  }) async {
    final created = await Navigator.of(context).push(
      CardMorphRoute(
        sourceContext: sourceContext,
        sourceBuilder: sourceBuilder,
        onSourceVisibilityChanged: onSourceVisibilityChanged,
        builder: (context) => const EditRoutineScreen(),
      ),
    );
    if (created == true) {
      HapticFeedbackService.instance.confirmationFeedback();
    }
  }

  Future<void> _openRoutineEditor(
    Routine routine, {
    BuildContext? sourceContext,
    WidgetBuilder? sourceBuilder,
    MorphSourceVisibilityCallback? onSourceVisibilityChanged,
  }) async {
    if (routine.id == null) return;
    final sourceRect = CardMorphRoute.measureRect(sourceContext);
    final fullRoutine =
        await WorkoutLocalDataSource.instance.getRoutineById(routine.id!);
    if (!mounted || fullRoutine == null) return;

    final updated = await Navigator.of(context).push<bool>(
      CardMorphRoute(
        sourceRect: sourceRect,
        sourceBuilder: sourceBuilder,
        onSourceVisibilityChanged: onSourceVisibilityChanged,
        builder: (context) => EditRoutineScreen(routine: fullRoutine),
      ),
    );
    if (updated == true) {
      HapticFeedbackService.instance.confirmationFeedback();
    }
  }

  void _duplicateRoutine(int routineId) async {
    await WorkoutLocalDataSource.instance.duplicateRoutine(routineId);
    HapticFeedbackService.instance.confirmationFeedback();
  }

  Future<void> _shareRoutine(Routine routine) async {
    if (routine.id == null) return;
    final fullRoutine =
        await WorkoutLocalDataSource.instance.getRoutineById(routine.id!);
    if (!mounted || fullRoutine == null) return;
    await _shareService.showRoutineShareSheet(
      context: context,
      routine: fullRoutine,
    );
  }

  void _deleteRoutine(BuildContext context, Routine routine) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDeleteConfirmation(
      context,
      content: l10n.deleteRoutineConfirmContent(routine.name),
    );

    if (confirmed) {
      if (routine.id != null) {
        setState(() {
          _dismissedRoutineIds.add(routine.id!);
        });
        await WorkoutLocalDataSource.instance.deleteRoutine(routine.id!);
      }
    }
  }

  String _formatRoutineExercisesSubtitle(
    BuildContext context,
    Routine routine,
  ) {
    if (routine.exercises.isEmpty) {
      return AppLocalizations.of(context)!.editRoutineSubtitle;
    }
    final locale = Localizations.localeOf(context).languageCode;
    final names = routine.exercises
        .map((re) => re.exercise.localizedNameFor(locale))
        .where((name) => name.trim().isNotEmpty)
        .toList();
    if (names.isEmpty) {
      return AppLocalizations.of(context)!.editRoutineSubtitle;
    }
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double appBarHeight = MediaQuery.of(context).padding.top;

    const EdgeInsets basePadding = DesignConstants.cardPadding;
    final EdgeInsets finalPadding = basePadding.copyWith(
      top: basePadding.top + appBarHeight,
    );

    return ListView(
      padding: finalPadding,
      children: [
        // 1. Trainingsplan (Hero)
        AppSectionHeader(title: ManualPlanText(context).get('plan')),
        FutureBuilder(
          key: ValueKey(_manualPlanRefresh),
          future: _loadManualPlanSummary(),
          builder: (context, snapshot) {
            final summary = snapshot.data;
            final plan = summary?.plan;
            final today = summary?.today;
            final next = summary?.next;
            final text = ManualPlanText(context);
            final locale = Localizations.localeOf(context).toString();
            Future<void> openPlan({
              BuildContext? sourceContext,
              WidgetBuilder? sourceBuilder,
              MorphSourceVisibilityCallback? onSourceVisibilityChanged,
            }) async {
              await Navigator.of(context).push(
                CardMorphRoute(
                  sourceContext: sourceContext,
                  sourceBuilder: sourceBuilder,
                  onSourceVisibilityChanged: onSourceVisibilityChanged,
                  builder: (_) => const ManualPlanScreen(),
                ),
              );
              if (mounted) setState(() => _manualPlanRefresh++);
            }

            if (plan == null) {
              Widget buildCard({VoidCallback? onTap}) => WorkoutPlanHeroCard(
                    eyebrow: text.get('plan'),
                    title: text.get('noPlan'),
                    subtitle: text.get('hubNoPlanDescription'),
                    onTap: onTap,
                  );
              return MorphSourceScope(
                builder: (context, setHidden) => Builder(
                  builder: (cardContext) => buildCard(
                    onTap: () => openPlan(
                      sourceContext: cardContext,
                      sourceBuilder: (_) => buildCard(),
                      onSourceVisibilityChanged: setHidden,
                    ),
                  ),
                ),
              );
            }

            final displayDay = today ?? next;
            final isTodayWorkout = today != null && !today.day.isRest;
            String subtitle;
            if (displayDay == null) {
              subtitle = text.get('hubNoUpcomingWorkout');
            } else if (today?.day.isRest == true && next != null) {
              subtitle = '${text.get('nextUp')}: ${next.day.routineName}'
                  '${DesignConstants.metadataSeparator}'
                  '${DateFormat.MMMEd(locale).format(next.date)}';
            } else if (isTodayWorkout) {
              subtitle = plannedDayMetadata(context, today.day);
            } else {
              final when = DateUtils.isSameDay(displayDay.date, DateTime.now())
                  ? text.get('today')
                  : DateFormat.MMMEd(locale).format(displayDay.date);
              subtitle = '$when${DesignConstants.metadataSeparator}'
                  '${plannedDayMetadata(context, displayDay.day)}';
            }

            final canStart =
                isTodayWorkout && today.status == PlannedDayStatus.planned;
            Widget buildCard({VoidCallback? onTap, VoidCallback? onAction}) =>
                WorkoutPlanHeroCard(
                  eyebrow: plan.name,
                  title: displayDay?.day.routineName ?? text.get('rest'),
                  subtitle: subtitle,
                  status: displayDay?.status,
                  onTap: onTap,
                  actionLabel: canStart ? text.get('start') : null,
                  onAction: onAction,
                );

            return MorphSourceScope(
              builder: (context, setHidden) => Builder(
                builder: (cardContext) => buildCard(
                  onTap: () => openPlan(
                    sourceContext: cardContext,
                    sourceBuilder: (_) => buildCard(
                      onAction: canStart ? () {} : null,
                    ),
                    onSourceVisibilityChanged: setHidden,
                  ),
                  onAction: canStart
                      ? () async {
                          await startManualPlanDay(
                            context,
                            plan,
                            today,
                            sourceRect: CardMorphRoute.measureRect(cardContext),
                            sourceBuilder: (_) => buildCard(onAction: () {}),
                            onSourceVisibilityChanged: setHidden,
                          );
                          if (mounted) setState(() => _manualPlanRefresh++);
                        }
                      : null,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: DesignConstants.spacingXL),

        // 2. Recovery (Muscle Readiness)
        AppSectionHeader(title: l10n.sectionRecovery),
        _buildRecoveryCard(context, l10n),
        const SizedBox(height: DesignConstants.spacingXL),

        // 3. Schnellstart (Duo-Row)
        AppSectionHeader(title: l10n.workoutSectionStart),
        _buildQuickStartRow(context, l10n),
        const SizedBox(height: DesignConstants.spacingXL),

        // 4. Routinen (Vertikale Liste)
        StreamBuilder<List<Routine>>(
          stream: _routinesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(DesignConstants.spacingL),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final routines = (snapshot.data ?? [])
                .where((r) => !_dismissedRoutineIds.contains(r.id))
                .toList();

            final routinesHeader = l10n.workoutAllRoutines;
            final countBadge =
                routines.isNotEmpty ? ' (${routines.length})' : '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader(title: '$routinesHeader$countBadge'),
                if (routines.isEmpty)
                  _buildEmptyRoutinesCard(context, l10n)
                else
                  for (final routine in routines)
                    _buildVerticalRoutineCard(context, routine, l10n),
              ],
            );
          },
        ),

        // 5. Übungskatalog (Dezent am Ende unterhalb der Routinenliste)
        const SizedBox(height: DesignConstants.spacingL),
        _buildNavigationTile(
          context: context,
          icon: LucideIcons.folder_open,
          title: l10n.drawerExerciseCatalog,
          destination: () => const ExerciseCatalogScreen(),
        ),
        const BottomContentSpacer(),
      ],
    );
  }

  Widget _buildRecoveryCard(BuildContext context, AppLocalizations l10n) {
    return FutureBuilder<RecoveryAnalyticsPayload>(
      future: _recoveryFuture,
      builder: (context, snapshot) {
        final SectionLoadState<RecoveryAnalyticsPayload> state;
        if (snapshot.connectionState == ConnectionState.waiting) {
          state = const SectionLoadState(isLoading: true);
        } else if (snapshot.hasError) {
          state = SectionLoadState(
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
        } else {
          state = SectionLoadState(data: snapshot.data);
        }

        Widget buildCard({required VoidCallback onTap}) => RecoverySectionCard(
              state: state,
              chipText: null,
              onRetry: _retryRecovery,
              onTap: onTap,
            );

        final card = MorphSourceScope(
          builder: (context, setHidden) => Builder(
            builder: (cardContext) => buildCard(
              onTap: () {
                Navigator.of(context).push(
                  CardMorphRoute(
                    sourceContext: cardContext,
                    sourceBuilder: (_) => buildCard(onTap: () {}),
                    onSourceVisibilityChanged: setHidden,
                    builder: (_) => const RecoveryTrackerScreen(),
                  ),
                );
              },
            ),
          ),
        );

        if (state.data?.hasData ?? false) return card;
        return CardEmptyStateOverlay(
          isEmpty: !state.isLoading,
          message: l10n.emptyStateActiveGapOverlay,
          child: card,
        );
      },
    );
  }

  Widget _buildQuickStartRow(BuildContext context, AppLocalizations l10n) {
    Widget buildEmptyWorkoutContent() => SummaryCard(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: DesignConstants.spacingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.circle_plus,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: DesignConstants.spacingS),
                Flexible(
                  child: Text(
                    l10n.startEmptyWorkoutButton,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );

    Widget buildCreateRoutineContent() => SummaryCard(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: DesignConstants.spacingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.folder_plus,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: DesignConstants.spacingS),
                Flexible(
                  child: Text(
                    l10n.addRoutineButton,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        Expanded(
          child: MorphSourceScope(
            builder: (context, setHidden) => Builder(
              builder: (cardCtx) => SummaryCard(
                margin: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => _startEmptyWorkout(
                    sourceContext: cardCtx,
                    sourceBuilder: (_) => buildEmptyWorkoutContent(),
                    onSourceVisibilityChanged: setHidden,
                  ),
                  borderRadius: BorderRadius.circular(
                    DesignConstants.borderRadiusM,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14.0,
                      horizontal: DesignConstants.spacingM,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.circle_plus,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: DesignConstants.spacingS),
                        Flexible(
                          child: Text(
                            l10n.startEmptyWorkoutButton,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
        const SizedBox(width: DesignConstants.spacingM),
        Expanded(
          child: MorphSourceScope(
            builder: (context, setHidden) => Builder(
              builder: (cardCtx) => SummaryCard(
                margin: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => _createNewRoutine(
                    sourceContext: cardCtx,
                    sourceBuilder: (_) => buildCreateRoutineContent(),
                    onSourceVisibilityChanged: setHidden,
                  ),
                  borderRadius: BorderRadius.circular(
                    DesignConstants.borderRadiusM,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14.0,
                      horizontal: DesignConstants.spacingM,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.folder_plus,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: DesignConstants.spacingS),
                        Flexible(
                          child: Text(
                            l10n.addRoutineButton,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildEmptyRoutinesCard(BuildContext context, AppLocalizations l10n) {
    return SummaryCard(
      margin: const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
      padding: DesignConstants.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.emptyRoutinesTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: DesignConstants.spacingXS),
          Text(
            l10n.emptyRoutinesSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalRoutineCard(
    BuildContext context,
    Routine routine,
    AppLocalizations l10n,
  ) {
    final exercisesSubtitle = _formatRoutineExercisesSubtitle(context, routine);

    Widget buildCardBody({VoidCallback? onStart}) => SummaryCard(
          margin: const EdgeInsets.symmetric(
            vertical: DesignConstants.spacingXS,
          ),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignConstants.cardPaddingInternal,
                  DesignConstants.cardPaddingInternal,
                  DesignConstants.spacingS,
                  DesignConstants.spacingXS,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            routine.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: DesignConstants.spacingS),
                        const Icon(
                          LucideIcons.ellipsis_vertical,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignConstants.spacingXS),
                    Text(
                      exercisesSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.65),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignConstants.cardPaddingInternal,
                  DesignConstants.spacingS,
                  DesignConstants.cardPaddingInternal,
                  DesignConstants.cardPaddingInternal,
                ),
                child: AppButton.primary(
                  onPressed: onStart ?? () {},
                  label: l10n.startWorkout,
                ),
              ),
            ],
          ),
        );

    return MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) => SummaryCard(
          margin: const EdgeInsets.symmetric(
            vertical: DesignConstants.spacingXS,
          ),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top tappable area -> opens editor
              InkWell(
                onTap: () => _openRoutineEditor(
                  routine,
                  sourceContext: cardCtx,
                  sourceBuilder: (_) => buildCardBody(),
                  onSourceVisibilityChanged: setHidden,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DesignConstants.borderRadiusL),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignConstants.cardPaddingInternal,
                    DesignConstants.cardPaddingInternal,
                    DesignConstants.spacingS,
                    DesignConstants.spacingXS,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              routine.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PlatformAdaptivePopupMenu<String>(
                            icon: Icon(
                              LucideIcons.ellipsis_vertical,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              size: 20,
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
                              PlatformAdaptivePopupMenuItem(
                                value: 'duplicate',
                                label: l10n.duplicate,
                                icon: LucideIcons.copy,
                              ),
                              PlatformAdaptivePopupMenuItem(
                                value: 'share',
                                label: l10n.share,
                                icon: DesignConstants.adaptiveShareIcon,
                              ),
                              PlatformAdaptivePopupMenuItem(
                                value: 'delete',
                                label: l10n.delete,
                                icon: LucideIcons.trash,
                                isDestructive: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignConstants.spacingXS),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: DesignConstants.spacingS,
                        ),
                        child: Text(
                          exercisesSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.65),
                                    height: 1.35,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom full-width start button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignConstants.cardPaddingInternal,
                  DesignConstants.spacingS,
                  DesignConstants.cardPaddingInternal,
                  DesignConstants.cardPaddingInternal,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    onPressed: () => _startRoutine(
                      routine,
                      sourceContext: cardCtx,
                      sourceBuilder: (_) => buildCardBody(),
                      onSourceVisibilityChanged: setHidden,
                    ),
                    label: l10n.startWorkout,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget Function() destination,
  }) {
    Widget buildTileContent() => SummaryCard(
          child: ListTile(
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(LucideIcons.chevron_right),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
            ),
          ),
        );

    return MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) => SummaryCard(
          child: ListTile(
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(LucideIcons.chevron_right),
            onTap: () => Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => buildTileContent(),
                onSourceVisibilityChanged: setHidden,
                builder: (_) => destination(),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
            ),
          ),
        ),
      ),
    );
  }
}
