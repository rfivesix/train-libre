import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/sources/workout_local_data_source.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/routine.dart';
import '../domain/repositories/workout_repository.dart';
import '../../../services/haptic_feedback_service.dart';
import 'edit_routine_screen.dart';
import '../../exercise_catalog/presentation/exercise_catalog_screen.dart';
import 'live_workout_screen.dart';
import 'routines_screen.dart';
import 'workout_history_screen.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/summary_card.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'live_workout_view_model.dart';
import '../../../widgets/common/app_button.dart';

/// The central management screen for all workout-related activities.
///
/// Provides quick actions to start an empty workout, launch saved routines,
/// and navigate to workout history, routine management, and the exercise catalog.
class WorkoutHubScreen extends StatefulWidget {
  const WorkoutHubScreen({super.key});

  @override
  State<WorkoutHubScreen> createState() => _WorkoutHubScreenState();
}

class _WorkoutHubScreenState extends State<WorkoutHubScreen> {
  late final Stream<List<Routine>> _routinesStream;
  late final l10n = AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
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
          MaterialPageRoute(
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

  void _startEmptyWorkout() async {
    final canProceed = await _checkAndHandleOngoingWorkout();
    if (!canProceed) return;
    if (!mounted) return;

    final newLog = await WorkoutLocalDataSource.instance.startWorkout(
      routineName: l10n.free_training,
    );
    if (mounted) {
      HapticFeedbackService.instance.confirmationFeedback();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LiveWorkoutScreen(workoutLog: newLog),
        ),
      );
    }
  }

  void _startRoutine(Routine routine) async {
    final canProceed = await _checkAndHandleOngoingWorkout();
    if (!canProceed) return;
    if (!mounted) return;

    // Need the full routine details to start.
    final detailedRoutine =
        await WorkoutLocalDataSource.instance.getRoutineById(
      routine.id!,
    );
    if (detailedRoutine == null) return;

    final newLog = await WorkoutLocalDataSource.instance.startWorkout(
      routineName: routine.name,
    );
    if (mounted) {
      HapticFeedbackService.instance.confirmationFeedback();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LiveWorkoutScreen(
            routine: detailedRoutine,
            workoutLog: newLog,
          ),
        ),
      );
    }
  }

  Future<void> _createNewRoutine() async {
    // Navigates to the editor for a new routine.
    final created = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const EditRoutineScreen()));
    if (created == true) {
      HapticFeedbackService.instance.confirmationFeedback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double appBarHeight = MediaQuery.of(
      context,
    ).padding.top; // + kToolbarHeight;

    // 2. Get your base padding from your design constants
    const EdgeInsets basePadding = DesignConstants
        .cardPadding; // This is EdgeInsets.all(DesignConstants.spacingL)

    // 3. Create the final combined padding
    final EdgeInsets finalPadding = basePadding.copyWith(
      // Take the original top value (16.0) and add the app bar height
      top: basePadding.top + appBarHeight,
    );

    return ListView(
      padding: finalPadding,
      children: [
        AppSectionHeader(title: l10n.workoutSectionStart),
        SummaryCard(
          child: InkWell(
            onTap: _startEmptyWorkout,
            borderRadius: BorderRadius.circular(
              DesignConstants.borderRadiusM,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.circle_plus, size: 28),
                  const SizedBox(width: DesignConstants.spacingM),
                  Text(
                    l10n.startEmptyWorkoutButton,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingXL),
        AppSectionHeader(title: l10n.workoutSectionMyPlans),
        SizedBox(
          height: 160,
          child: StreamBuilder<List<Routine>>(
            stream: _routinesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final routines = snapshot.data ?? [];
              if (routines.isEmpty) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCreateRoutineCard(context, l10n),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignConstants.spacingS,
                          vertical: DesignConstants.spacingM,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.emptyStateWorkoutRoutinesCallout,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                    height: 1.3,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: routines.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCreateRoutineCard(context, l10n);
                  }
                  return _buildRoutineCard(
                    context,
                    routines[index - 1],
                  );
                },
              );
            },
          ),
        ),
        _buildNavigationTile(
          context: context,
          icon: LucideIcons.list,
          title: l10n.workoutAllRoutines,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RoutinesScreen(),
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingXL),
        AppSectionHeader(title: l10n.workoutSectionHistoryLibrary),
        _buildNavigationTile(
          context: context,
          icon: LucideIcons.history,
          title: l10n.workoutEntryWorkouts,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const WorkoutHistoryScreen(),
            ),
          ),
        ),
        _buildNavigationTile(
          context: context,
          icon: LucideIcons.folder_open,
          title: l10n.drawerExerciseCatalog,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ExerciseCatalogScreen(),
            ),
          ),
        ),
        const BottomContentSpacer(),
      ],
    );
  }

  Widget _buildCreateRoutineCard(BuildContext context, AppLocalizations l10n) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 12) / 2.5; // Etwas schmaler
    return SizedBox(
      width: cardWidth,
      child: Padding(
        padding: const EdgeInsets.only(right: DesignConstants.spacingM),
        child: SummaryCard(
          child: InkWell(
            onTap: _createNewRoutine,
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.circle_plus,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  Text(l10n.addRoutineButton, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineCard(BuildContext context, Routine routine) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 12) / 2;

    return SizedBox(
      width: cardWidth,
      // FIX: Add spacing here as padding, not as margin.
      child: Padding(
        padding: const EdgeInsets.only(right: DesignConstants.spacingM),
        child: SummaryCard(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditRoutineScreen(routine: routine),
                ),
              );
            },
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    routine.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppButton.primary(
                    onPressed: () => _startRoutine(routine),
                    label: l10n.start_button,
                    tooltip: l10n.start_button,
                    size: AppButtonSize.medium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SummaryCard(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(LucideIcons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        ),
      ),
    );
  }
}
