import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../domain/models/set_log.dart';
import '../../../exercise_catalog/domain/models/exercise.dart';
import '../../../exercise_catalog/presentation/exercise_detail_screen.dart';
import '../../../../widgets/common/card_morph_route.dart';
import '../../../../widgets/common/morph_source.dart';
import 'workout_card.dart';
import '../../domain/classification/exercise_log_mask.dart';
import 'log_mask_labels.dart';
import 'workout_log_set_row.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../util/design_constants.dart';

/// A card widget grouping all set logs for a single exercise.
/// Displays headers, exercise notes, set lists, and drag handle for reordering.
class WorkoutExerciseLogCard extends StatelessWidget {
  final String exerciseName;
  final Exercise? exercise;
  final List<SetLog> sets;
  final bool isEditMode;
  final bool isCardio;

  /// Which inputs each set row shows. Derived from the exercise by the caller,
  /// which is the only place that has it.
  final ExerciseLogMask mask;

  /// Body weight on the day of this workout, when recorded.
  final double? bodyweightKg;
  final Map<int, TextEditingController> weightControllers;
  final Map<int, TextEditingController> repsControllers;
  final Map<int, TextEditingController> rirControllers;
  final String? exerciseNote;
  final Function(String exerciseName) onEditNotes;
  final Function(String exerciseName) onDeleteExercise;
  final VoidCallback onAddSet;
  final Function(int setLogId) onDeleteSet;
  final Function(int setLogId) onSetTypeTap;
  final int index;
  final bool isDragging;
  final bool isDraggedItem;
  final void Function(PointerDownEvent)? onPointerDown;
  final void Function(PointerMoveEvent)? onPointerMove;
  final void Function(PointerUpEvent)? onPointerUp;
  final void Function(PointerCancelEvent)? onPointerCancel;

  const WorkoutExerciseLogCard({
    super.key,
    required this.exerciseName,
    required this.exercise,
    required this.sets,
    required this.isEditMode,
    required this.isCardio,
    required this.mask,
    this.bodyweightKg,
    required this.weightControllers,
    required this.repsControllers,
    required this.rirControllers,
    required this.exerciseNote,
    required this.onEditNotes,
    required this.onDeleteExercise,
    required this.onAddSet,
    required this.onDeleteSet,
    required this.onSetTypeTap,
    required this.index,
    this.isDragging = false,
    this.isDraggedItem = false,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    // Shared by the edit and the read-only branch below, and handed to the
    // morph route as the copy that flies inside the growing container — the
    // detail screen then dissolves out of the title instead of being drawn
    // over it from the first frame.
    final title = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        exercise?.getLocalizedName(context) ?? exerciseName,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDraggedItem ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
    );

    void openDetail(
      BuildContext titleCtx,
      MorphSourceVisibilityCallback setHidden,
    ) {
      if (exercise == null) return;
      Navigator.of(titleCtx).push(
        CardMorphRoute(
          sourceContext: titleCtx,
          sourceBorderRadius: 12.0,
          sourceBuilder: (_) => title,
          onSourceVisibilityChanged: setHidden,
          builder: (context) => ExerciseDetailScreen(exercise: exercise!),
        ),
      );
    }

    return WorkoutCard(
      key: isEditMode ? ValueKey(exerciseName) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            leading: null,
            title: isEditMode
                ? Listener(
                    onPointerDown: onPointerDown,
                    onPointerMove: onPointerMove,
                    onPointerUp: onPointerUp,
                    onPointerCancel: onPointerCancel,
                    child: ReorderableDelayedDragStartListener(
                      index: index,
                      child: MorphSourceScope(
                        builder: (context, setHidden) => Builder(
                          builder: (titleCtx) => InkWell(
                            onTap: () => openDetail(titleCtx, setHidden),
                            child: title,
                          ),
                        ),
                      ),
                    ),
                  )
                : MorphSourceScope(
                    builder: (context, setHidden) => Builder(
                      builder: (titleCtx) => InkWell(
                        onTap: () => openDetail(titleCtx, setHidden),
                        child: title,
                      ),
                    ),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEditMode)
                  IconButton(
                    icon: const Icon(LucideIcons.pencil),
                    tooltip: l10n.exerciseNoteTitle,
                    onPressed: () => onEditNotes(exerciseName),
                  ),
                if (isEditMode)
                  IconButton(
                    icon: const Icon(
                      LucideIcons.trash_2,
                      color: DesignConstants.brandRedColor,
                    ),
                    tooltip: l10n.removeExercise,
                    onPressed: () => onDeleteExercise(exerciseName),
                  )
                else
                  const Icon(LucideIcons.info),
              ],
            ),
          ),
          isDragging
              ? const SizedBox.shrink()
              : AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (exerciseNote != null && exerciseNote!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            bottom: 12.0,
                          ),
                          child: InkWell(
                            onTap: isEditMode
                                ? () => onEditNotes(exerciseName)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    LucideIcons.file_text,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      exerciseNote!,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Headed by the same mask the rows use.
                              Builder(builder: (context) {
                                final unitService = context.read<UnitService>();
                                final primary = LogMaskLabels.primaryHeader(
                                    mask, l10n, unitService);
                                final secondary =
                                    LogMaskLabels.secondaryHeader(mask, l10n);
                                final wide =
                                    mask.logsDistance || mask.logsDuration;
                                return Row(
                                  children: [
                                    _buildHeader(l10n.setLabel, flex: 2),
                                    if (primary != null)
                                      _buildHeader(primary, flex: wide ? 4 : 2)
                                    else
                                      Expanded(
                                          flex: wide ? 4 : 2,
                                          child: const SizedBox.shrink()),
                                    const SizedBox(width: 8),
                                    if (secondary != null)
                                      _buildHeader(secondary,
                                          flex: wide ? 4 : 2)
                                    else
                                      Expanded(
                                          flex: wide ? 4 : 2,
                                          child: const SizedBox.shrink()),
                                    const SizedBox(width: 8),
                                    _buildHeader(
                                      mask.logsDistance
                                          ? l10n.cardioIntensityShortLabel
                                          : 'RIR',
                                      flex: 2,
                                    ),
                                    const SizedBox(width: 48),
                                  ],
                                );
                              }),

                              // Set Rows
                              ...sets.asMap().entries.map((setEntry) {
                                final setLog = setEntry.value;
                                final rowIndex = setEntry.key;
                                int workingSetIndex = 0;
                                for (int i = 0; i <= rowIndex; i++) {
                                  if (sets[i].setType != 'warmup') {
                                    workingSetIndex++;
                                  }
                                }

                                return WorkoutLogSetRow(
                                  setLog: setLog,
                                  rowIndex: rowIndex,
                                  workingSetIndex: workingSetIndex,
                                  exerciseName: exerciseName,
                                  isEditMode: isEditMode,
                                  mask: mask,
                                  bodyweightKg: bodyweightKg,
                                  weightController:
                                      weightControllers[setLog.id],
                                  repsController: repsControllers[setLog.id],
                                  rirController: rirControllers[setLog.id],
                                  onDelete: () => onDeleteSet(setLog.id!),
                                  onSetTypeTap: () => onSetTypeTap(setLog.id!),
                                );
                              }),

                              if (isEditMode)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: TextButton.icon(
                                    onPressed: onAddSet,
                                    icon: const Icon(LucideIcons.plus),
                                    label: Text(l10n.addSetButton),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
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
}
