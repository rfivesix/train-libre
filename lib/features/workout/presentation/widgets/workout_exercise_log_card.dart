import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/experience_level_service.dart';
import '../../../../services/unit_service.dart';
import '../../domain/models/set_log.dart';
import '../../../exercise_catalog/domain/models/exercise.dart';
import '../../../exercise_catalog/presentation/exercise_detail_screen.dart';
import '../../../../widgets/common/card_morph_route.dart';
import '../../../../widgets/common/morph_source.dart';
import 'superset_connector_button.dart';
import 'workout_card.dart';
import '../../domain/classification/exercise_log_mask.dart';
import 'log_mask_labels.dart';
import 'workout_log_set_row.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../widgets/common/platform_adaptive_dropdown.dart';
import '../../../../util/time_util.dart';

String _formatPauseTime(int? seconds) => formatPauseDuration(seconds);

/// A card widget grouping all set logs for a single exercise.
/// Displays headers, exercise notes, set lists, and drag handle for reordering.
class WorkoutExerciseLogCard extends StatelessWidget {
  final String exerciseName;
  final Exercise? exercise;
  final List<SetLog> sets;
  final bool isEditMode;
  final bool isCardio;
  final bool showExerciseHeader;

  /// Which inputs each set row shows. Derived from the exercise by the caller,
  /// which is the only place that has it.
  final ExerciseLogMask mask;

  /// Body weight on the day of this workout, when recorded.
  final double? bodyweightKg;
  final Map<int, TextEditingController> weightControllers;
  final Map<int, TextEditingController> repsControllers;
  final Map<int, TextEditingController> rirControllers;
  final String? exerciseNote;
  final int? pauseSeconds;
  final Function(String exerciseName) onEditNotes;
  final VoidCallback? onEditPauseTime;
  final Function(String exerciseName) onDeleteExercise;
  final VoidCallback onAddSet;
  final Function(int setLogId) onDeleteSet;
  final Function(int setLogId)? onSetTypeTap;
  final void Function(int setLogId, String newType)? onSetTypeChanged;
  final int index;
  final bool isDragging;
  final bool isDraggedItem;
  final String? supersetLabel;
  final Color? supersetColor;
  final bool continuesSupersetAbove;
  final bool continuesSupersetBelow;

  /// Connects or disconnects this exercise and the one below it. Null when
  /// there is no exercise below.
  final VoidCallback? onToggleSupersetBelow;

  /// Whether this exercise already shares a superset with the one below.
  final bool isConnectedBelow;
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
    this.showExerciseHeader = true,
    required this.mask,
    this.bodyweightKg,
    required this.weightControllers,
    required this.repsControllers,
    required this.rirControllers,
    required this.exerciseNote,
    this.pauseSeconds,
    required this.onEditNotes,
    this.onEditPauseTime,
    required this.onDeleteExercise,
    required this.onAddSet,
    required this.onDeleteSet,
    this.onSetTypeTap,
    this.onSetTypeChanged,
    required this.index,
    this.isDragging = false,
    this.isDraggedItem = false,
    this.supersetLabel,
    this.supersetColor,
    this.continuesSupersetAbove = false,
    this.continuesSupersetBelow = false,
    this.onToggleSupersetBelow,
    this.isConnectedBelow = false,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
  });

  int? get _effectivePauseSeconds {
    if (pauseSeconds != null) return pauseSeconds;
    for (final s in sets) {
      if (s.restTimeSeconds != null && s.restTimeSeconds! > 0) {
        return s.restTimeSeconds;
      }
    }
    return null;
  }

  Widget _buildPauseTimerRow({
    required int? pauseSeconds,
    required AppLocalizations l10n,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.timer, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            pauseSeconds != null && pauseSeconds > 0
                ? _formatPauseTime(pauseSeconds)
                : l10n.timerOffLabel.toUpperCase(),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final trimmedNote = exerciseNote?.trim();
    final hasExerciseNote = trimmedNote?.isNotEmpty == true;
    final effectivePause = _effectivePauseSeconds;

    // Shared by the edit and the read-only branch below, and handed to the
    // morph route as the copy that flies inside the growing container — the
    // detail screen then dissolves out of the title instead of being drawn
    // over it from the first frame.
    final exerciseTitle = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        exercise?.getLocalizedName(context) ?? exerciseName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDraggedItem ? colorScheme.primary : null,
        ),
      ),
    );
    final title = supersetLabel == null || supersetColor == null
        ? exerciseTitle
        : Row(
            children: [
              Container(
                key: ValueKey('history_superset_badge_$supersetLabel'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: supersetColor!.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: supersetColor!.withValues(alpha: 0.7),
                  ),
                ),
                child: Text(
                  supersetLabel!,
                  style: textTheme.labelLarge?.copyWith(
                    color: supersetColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: exerciseTitle),
            ],
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

    final linkedTitle = MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (titleCtx) => InkWell(
          onTap: () => openDetail(titleCtx, setHidden),
          child: title,
        ),
      ),
    );

    return WorkoutCard(
      key: isEditMode ? ValueKey(exerciseName) : null,
      accentColor: supersetColor,
      continuesSupersetAbove: continuesSupersetAbove,
      continuesSupersetBelow: continuesSupersetBelow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showExerciseHeader)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: isEditMode
                        ? Listener(
                            onPointerDown: onPointerDown,
                            onPointerMove: onPointerMove,
                            onPointerUp: onPointerUp,
                            onPointerCancel: onPointerCancel,
                            child: ReorderableDelayedDragStartListener(
                              index: index,
                              child: linkedTitle,
                            ),
                          )
                        : linkedTitle,
                  ),
                  if (isEditMode && !isDragging)
                    PlatformAdaptivePopupMenu<String>(
                      icon: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(LucideIcons.ellipsis_vertical),
                      ),
                      items: [
                        PlatformAdaptivePopupMenuItem(
                          value: 'notes',
                          label: l10n.editExerciseNotes,
                          icon: LucideIcons.pencil,
                        ),
                        if (onEditPauseTime != null)
                          PlatformAdaptivePopupMenuItem(
                            value: 'timer',
                            label: l10n.editPauseTime,
                            icon: LucideIcons.timer,
                          ),
                        PlatformAdaptivePopupMenuItem(
                          value: 'remove',
                          label: l10n.removeExercise,
                          icon: LucideIcons.trash,
                          isDestructive: true,
                        ),
                      ],
                      onSelected: (action) {
                        switch (action) {
                          case 'notes':
                            onEditNotes(exerciseName);
                            break;
                          case 'timer':
                            onEditPauseTime?.call();
                            break;
                          case 'remove':
                            onDeleteExercise(exerciseName);
                            break;
                        }
                      },
                    )
                  else if (!isEditMode)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(LucideIcons.info),
                    ),
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
                      if (showExerciseHeader)
                        Builder(
                          builder: (context) {
                            final timerRow = _buildPauseTimerRow(
                              pauseSeconds: effectivePause,
                              l10n: l10n,
                              textTheme: textTheme,
                              colorScheme: colorScheme,
                              onTap: isEditMode ? onEditPauseTime : null,
                            );
                            final noteText = Text(
                              hasExerciseNote
                                  ? trimmedNote!
                                  : l10n.workoutNoteAddHint,
                              maxLines: hasExerciseNote ? null : 1,
                              overflow: hasExerciseNote
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                            final noteRow = isEditMode
                                ? InkWell(
                                    onTap: () => onEditNotes(exerciseName),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: noteText,
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: noteText,
                                  );

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: hasExerciseNote
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        noteRow,
                                        const SizedBox(height: 2),
                                        timerRow,
                                      ],
                                    )
                                  : isEditMode
                                      ? Row(
                                          children: [
                                            timerRow,
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: noteRow,
                                              ),
                                            ),
                                          ],
                                        )
                                      : timerRow,
                            );
                          },
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
                                    // Same level as the rows below, so the
                                    // column is present or absent as a whole.
                                    if (context
                                        .watch<ExperienceLevelService>()
                                        .showsIntensity) ...[
                                      const SizedBox(width: 8),
                                      _buildHeader(
                                        mask.logsDistance
                                            ? l10n.cardioIntensityShortLabel
                                            : 'RIR',
                                        flex: 2,
                                      ),
                                    ],
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
                                  onSetTypeTap: onSetTypeTap != null
                                      ? () => onSetTypeTap!(setLog.id!)
                                      : null,
                                  onSetTypeChanged: onSetTypeChanged != null
                                      ? (newType) =>
                                          onSetTypeChanged!(setLog.id!, newType)
                                      : null,
                                );
                              }),

                              if (isEditMode)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: onAddSet,
                                        icon: const Icon(LucideIcons.plus),
                                        label: Text(l10n.addSetButton),
                                      ),
                                      if (onToggleSupersetBelow != null)
                                        Flexible(
                                          child: SupersetConnectorButton(
                                            key: ValueKey(
                                              'history_superset_connector_$index',
                                            ),
                                            isConnected: isConnectedBelow,
                                            onPressed: onToggleSupersetBelow!,
                                          ),
                                        ),
                                    ],
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
