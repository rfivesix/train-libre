import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../services/unit_service.dart';
import '../../domain/models/routine_exercise.dart';
import '../../domain/models/set_template.dart';
import '../../../exercise_catalog/presentation/exercise_detail_screen.dart';
import 'workout_card.dart';
import 'routine_set_row_widget.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../util/time_util.dart';

String _formatPauseTime(int? seconds) => formatPauseDuration(seconds);

class EditRoutineExerciseCard extends StatelessWidget {
  final RoutineExercise routineExercise;
  final int index;
  final bool isCardio;
  final Map<int, TextEditingController> repsControllers;
  final Map<int, TextEditingController> weightControllers;
  final Map<int, TextEditingController> rirControllers;
  final VoidCallback onEditNotes;
  final VoidCallback onEditPauseTime;
  final VoidCallback onDeleteExercise;
  final VoidCallback onAddSet;
  final Function(SetTemplate) onShowSetTypePicker;
  final Function(SetTemplate, int listIndex) onRemoveSet;
  final bool isDragging;
  final bool isDraggedItem;
  final Function(PointerDownEvent)? onPointerDown;
  final Function(PointerUpEvent)? onPointerUp;
  final Function(PointerCancelEvent)? onPointerCancel;
  final Function(PointerMoveEvent)? onPointerMove;
  final bool isEditMode;

  const EditRoutineExerciseCard({
    super.key,
    required this.routineExercise,
    required this.index,
    required this.isCardio,
    required this.repsControllers,
    required this.weightControllers,
    required this.rirControllers,
    required this.onEditNotes,
    required this.onEditPauseTime,
    required this.onDeleteExercise,
    required this.onAddSet,
    required this.onShowSetTypePicker,
    required this.onRemoveSet,
    this.isDragging = false,
    this.isDraggedItem = false,
    this.onPointerDown,
    this.onPointerUp,
    this.onPointerCancel,
    this.onPointerMove,
    this.isEditMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return WorkoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            title: Listener(
              onPointerDown: onPointerDown,
              onPointerUp: onPointerUp,
              onPointerCancel: onPointerCancel,
              onPointerMove: onPointerMove,
              child: isEditMode
                  ? ReorderableDelayedDragStartListener(
                      index: index,
                      child: _buildTitleContent(
                          context, routineExercise, textTheme, colorScheme),
                    )
                  : _buildTitleContent(
                      context, routineExercise, textTheme, colorScheme),
            ),
            leading: null,
            trailing: isEditMode
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.pencil),
                        tooltip: l10n.exerciseNoteTitle,
                        onPressed: onEditNotes,
                      ),
                      if (routineExercise.pauseSeconds != null &&
                          routineExercise.pauseSeconds! > 0)
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: onEditPauseTime,
                          child: Text(
                            _formatPauseTime(routineExercise.pauseSeconds),
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: DesignConstants.spacingL,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(LucideIcons.timer),
                          tooltip: l10n.editPauseTime,
                          onPressed: onEditPauseTime,
                        ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.trash_2,
                          color: DesignConstants.brandRedColor,
                        ),
                        tooltip: l10n.removeExercise,
                        onPressed: onDeleteExercise,
                      ),
                    ],
                  )
                : (routineExercise.pauseSeconds != null &&
                        routineExercise.pauseSeconds! > 0)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.timer,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatPauseTime(routineExercise.pauseSeconds),
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : null,
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
                      if (routineExercise.notes != null &&
                          routineExercise.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            bottom: 12.0,
                          ),
                          child: InkWell(
                            onTap: isEditMode ? onEditNotes : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    LucideIcons.file_text,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderRow(context, routineExercise, l10n),
                              ...routineExercise.setTemplates
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final setIndex = entry.key;
                                final setTemplate = entry.value;

                                int workingSetIndex = 0;
                                for (int i = 0; i <= setIndex; i++) {
                                  if (routineExercise.setTemplates[i].setType !=
                                      'warmup') {
                                    workingSetIndex++;
                                  }
                                }

                                return RoutineSetRowWidget(
                                  key: ValueKey(setTemplate.id),
                                  setIndex: workingSetIndex,
                                  rowIndex: setIndex,
                                  routineExercise: routineExercise,
                                  template: setTemplate,
                                  listIndex: setIndex,
                                  isCardio: isCardio,
                                  repsController:
                                      repsControllers[setTemplate.id!]!,
                                  weightController:
                                      weightControllers[setTemplate.id!]!,
                                  rirController:
                                      rirControllers[setTemplate.id!]!,
                                  onShowSetTypePicker: () =>
                                      onShowSetTypePicker(setTemplate),
                                  onRemoveSet: () =>
                                      onRemoveSet(setTemplate, setIndex),
                                  isEditMode: isEditMode,
                                );
                              }),
                              if (isEditMode) ...[
                                const SizedBox(
                                    height: DesignConstants.spacingS),
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

  Widget _buildHeaderRow(
    BuildContext context,
    RoutineExercise re,
    AppLocalizations l10n,
  ) {
    if (isCardio) {
      return Row(
        children: [
          _buildHeader(l10n.setLabel, flex: 2),
          _buildHeader(
              l10n.cardioDistanceLabel(context
                  .read<UnitService>()
                  .suffixFor(UnitDimension.distance)),
              flex: 4),
          const SizedBox(width: 8),
          _buildHeader(l10n.cardioTimeLabel, flex: 4),
          const SizedBox(width: 8),
          _buildHeader(l10n.cardioIntensityLabel, flex: 2),
          const SizedBox(width: 48),
        ],
      );
    }
    return Row(
      children: [
        _buildHeader(l10n.setLabel, flex: 2),
        _buildHeader(
          context.read<UnitService>().suffixFor(UnitDimension.weight),
          flex: 2,
        ),
        const SizedBox(width: 8),
        _buildHeader(l10n.repsLabel, flex: 2),
        const SizedBox(width: 8),
        _buildHeader("RIR", flex: 2),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildHeader(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _buildTitleContent(
    BuildContext context,
    RoutineExercise routineExercise,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ExerciseDetailScreen(
            exercise: routineExercise.exercise,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          routineExercise.exercise.getLocalizedName(context),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDraggedItem ? colorScheme.primary : null,
          ),
        ),
      ),
    );
  }
}
