// lib/screens/edit_routine_screen.dart
// FINAL: Cardio Clean-Up (1 Set, Cleaner Layout, Empty Defaults)

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../data/sources/workout_local_data_source.dart';
import '../../sharing/share_service.dart';
import '../../../generated/app_localizations.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../domain/models/routine.dart';
import '../domain/models/routine_exercise.dart';
import '../domain/models/set_template.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../exercise_catalog/presentation/exercise_catalog_screen.dart';
import '../../../util/design_constants.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../exercise_catalog/presentation/widgets/wger_attribution_widget.dart';
import 'widgets/edit_routine_exercise_card.dart';
import 'widgets/exercise_notes_dialog.dart';
import 'widgets/routine_pause_time_dialog.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// A screen for creating or modifying a [Routine].
///
/// Allows users to name their routine and manage a list of [RoutineExercise] items.
/// Each exercise can have multiple sets with target reps, weight, and RIR.
class EditRoutineScreen extends StatefulWidget {
  /// The [Routine] to be edited. If null, a new routine is created.
  final Routine? routine;
  const EditRoutineScreen({super.key, this.routine});

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  final _nameController = TextEditingController();
  List<RoutineExercise> _routineExercises = [];
  bool _isNewRoutine = true;
  int? _routineId;
  String _originalName = '';
  bool _isLoading = false;

  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _rirControllers = {};
  static const ShareService _shareService = ShareService();

  String _originalState = '';
  bool _canPop = false;

  String _serializeState() {
    final sb = StringBuffer();
    sb.write(_nameController.text.trim());
    sb.write('|');
    for (var re in _routineExercises) {
      sb.write('${re.id}:${re.notes ?? ''}:${re.pauseSeconds ?? ''};');
      for (var st in re.setTemplates) {
        final reps = _repsControllers[st.id]?.text ?? '';
        final weight = _weightControllers[st.id]?.text ?? '';
        final rir = _rirControllers[st.id]?.text ?? '';
        sb.write('${st.id}:${st.setType}:$reps:$weight:$rir,');
      }
      sb.write(';');
    }
    return sb.toString();
  }

  bool _hasUnsavedChanges() {
    return _serializeState() != _originalState;
  }

  void _handlePopAttempt([Object? result]) async {
    if (!_hasUnsavedChanges()) {
      setState(() {
        _canPop = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(result);
      });
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGlassBottomMenu<bool?>(
      context: context,
      title: l10n.unsavedChangesTitle,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingS),
              child: Text(
                l10n.unsavedChangesContent,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(false);
                    },
                    child: Text(l10n.discardButton),
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(true);
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

    if (confirmed == null) {
      return;
    }

    if (!confirmed) {
      if (mounted) {
        setState(() {
          _canPop = true;
        });
        Navigator.of(context).pop(false);
      }
    } else {
      final success = await _persistRoutineState();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.snackbarRoutineSaved)),
        );
        HapticFeedbackService.instance.confirmationFeedback();
        setState(() {
          _canPop = true;
        });
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      _isNewRoutine = false;
      _routineId = widget.routine!.id;
      _nameController.text = widget.routine!.name;
      _originalName = widget.routine!.name;
      _loadExercisesForRoutine();
    } else {
      _originalState = _serializeState();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var c in _repsControllers.values) {
      c.dispose();
    }
    for (var c in _weightControllers.values) {
      c.dispose();
    }
    for (var c in _rirControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isCardio(RoutineExercise re) {
    return re.exercise.categoryName.toLowerCase() == 'cardio';
  }

  Future<void> _loadExercisesForRoutine() async {
    if (_routineId == null) return;
    setState(() => _isLoading = true);
    final routineWithExercises =
        await WorkoutLocalDataSource.instance.getRoutineById(_routineId!);
    if (mounted && routineWithExercises != null) {
      for (var c in _repsControllers.values) {
        c.dispose();
      }
      for (var c in _weightControllers.values) {
        c.dispose();
      }
      for (var c in _rirControllers.values) {
        c.dispose();
      }

      _repsControllers.clear();
      _weightControllers.clear();
      _rirControllers.clear();

      for (var re in routineWithExercises.exercises) {
        final isCardio = _isCardio(re);
        for (var st in re.setTemplates) {
          // FIX: For cardio, show empty when the value is "8-12" (DB default).
          String repsText = st.targetReps ?? '';
          if (isCardio && repsText == '8-12') repsText = '';

          _repsControllers[st.id!] = TextEditingController(text: repsText);
          final String weightText = (st.targetWeight == null)
              ? ''
              : (isCardio
                  ? st.targetWeight!
                      .toStringAsFixed(3)
                      .replaceAll(RegExp(r'0*$'), '')
                      .replaceAll(RegExp(r'\.$'), '')
                  : st.targetWeight!.toString());
          _weightControllers[st.id!] = TextEditingController(text: weightText);
          _rirControllers[st.id!] = TextEditingController(
            text: st.targetRir?.toString() ?? '',
          );
        }
      }

      setState(() {
        _routineExercises = routineWithExercises.exercises;
        _isLoading = false;
      });
      _originalState = _serializeState();
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addExercises() async {
    if (_isNewRoutine) {
      final success = await _persistRoutineState(isAddingExercise: true);
      if (!success) return;
    }
    if (!mounted) return;
    final selectedExercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (context) =>
            const ExerciseCatalogScreen(isSelectionMode: true),
      ),
    );

    if (selectedExercise != null && _routineId != null) {
      // FIX: Check cardio before adding.
      final isCardio = selectedExercise.categoryName.toLowerCase() == 'cardio';
      final initialSetCount = isCardio ? 1 : 3;

      final newRoutineExercise =
          await WorkoutLocalDataSource.instance.addExerciseToRoutine(
        _routineId!,
        selectedExercise.id!,
        initialSetCount: initialSetCount,
      ); // Parameters

      if (newRoutineExercise != null) {
        for (var st in newRoutineExercise.setTemplates) {
          // FIX: Empty reps for cardio.
          final defaultReps = isCardio ? '' : st.targetReps;

          _repsControllers[st.id!] = TextEditingController(text: defaultReps);
          final String weightText = (st.targetWeight == null)
              ? ''
              : (isCardio
                  ? st.targetWeight!
                      .toStringAsFixed(3)
                      .replaceAll(RegExp(r'0*$'), '')
                      .replaceAll(RegExp(r'\.$'), '')
                  : st.targetWeight!.toString());
          _weightControllers[st.id!] = TextEditingController(text: weightText);
          _rirControllers[st.id!] = TextEditingController(
            text: st.targetRir?.toString() ?? '',
          );
        }
        setState(() {
          _routineExercises = [..._routineExercises, newRoutineExercise];
        });
        HapticFeedbackService.instance.confirmationFeedback();
        _originalState = _serializeState();
      }
    }
  }

  Future<bool> _persistRoutineState({bool isAddingExercise = false}) async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.validatorPleaseEnterRoutineName)),
        );
      }
      return false;
    }

    int? currentRoutineId = _routineId;

    if (_isNewRoutine) {
      final newRoutine = await WorkoutLocalDataSource.instance.createRoutine(
        _nameController.text.trim(),
      );
      currentRoutineId = newRoutine.id;
      if (mounted) {
        setState(() {
          _routineId = newRoutine.id;
          _isNewRoutine = false;
          _originalName = newRoutine.name;
        });
      }
      if (mounted && !isAddingExercise) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineCreated)));
      }
    } else {
      if (_nameController.text.trim() != _originalName) {
        await WorkoutLocalDataSource.instance.updateRoutineName(
          currentRoutineId!,
          _nameController.text.trim(),
        );
      }
    }

    final db = WorkoutLocalDataSource.instance;
    for (var re in _routineExercises) {
      final List<SetTemplate> currentTemplates = [];
      for (var set in re.setTemplates) {
        final rirText = _rirControllers[set.id!]?.text ?? '';
        currentTemplates.add(
          set.copyWith(
            targetReps: _repsControllers[set.id!]?.text,
            targetWeight: double.tryParse(
              _weightControllers[set.id!]!.text.replaceAll(',', '.'),
            ),
            targetRir: int.tryParse(rirText),
            clearTargetRir: rirText.isEmpty,
          ),
        );
      }
      await db.replaceSetTemplatesForExercise(re.id!, currentTemplates);
      await db.updateRoutineExerciseNotes(re.id!, re.notes);
    }

    _originalState = _serializeState();
    return true;
  }

  Future<bool> _saveRoutine() async {
    final success = await _persistRoutineState();
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.snackbarRoutineSaved)));
      HapticFeedbackService.instance.confirmationFeedback();
      setState(() {
        _canPop = true;
      });
      Navigator.of(context).pop(true);
    }
    return success;
  }

  void _addSet(RoutineExercise routineExercise) {
    setState(() {
      final isCardio = _isCardio(routineExercise);
      final newSet = SetTemplate(
        id: DateTime.now().millisecondsSinceEpoch,
        setType: 'normal',
        targetReps: isCardio ? '' : '8-12', // FIX
      );

      final exerciseIndex = _routineExercises.indexOf(routineExercise);
      if (exerciseIndex == -1) return;

      final updatedTemplates = [...routineExercise.setTemplates, newSet];
      final updatedExercise = RoutineExercise(
        id: routineExercise.id,
        exercise: routineExercise.exercise,
        setTemplates: updatedTemplates,
        pauseSeconds: routineExercise.pauseSeconds,
      );
      _routineExercises[exerciseIndex] = updatedExercise;

      _repsControllers[newSet.id!] = TextEditingController(
        text: newSet.targetReps,
      );
      _weightControllers[newSet.id!] = TextEditingController();
      _rirControllers[newSet.id!] = TextEditingController();
    });
  }

  void _removeSet(RoutineExercise re, int setTemplateId, int index) {
    setState(() {
      final exerciseIndex = _routineExercises.indexOf(re);
      if (exerciseIndex == -1) return;

      final updatedTemplates = [...re.setTemplates];
      updatedTemplates.removeAt(index);

      final updatedExercise = re.copyWith(setTemplates: updatedTemplates);
      _routineExercises[exerciseIndex] = updatedExercise;

      _repsControllers.remove(setTemplateId)?.dispose();
      _weightControllers.remove(setTemplateId)?.dispose();
      _rirControllers.remove(setTemplateId)?.dispose();
    });
  }

  void _editExerciseNotes(BuildContext context, RoutineExercise re) async {
    final l10n = AppLocalizations.of(context)!;
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
      setState(() {
        final exerciseIndex = _routineExercises.indexOf(re);
        if (exerciseIndex != -1) {
          _routineExercises[exerciseIndex] = re.copyWith(
            notes: result,
            clearNotes: result.isEmpty,
          );
        }
      });
      if (re.id != null) {
        await WorkoutLocalDataSource.instance.updateRoutineExerciseNotes(
            re.id!, result.isNotEmpty ? result : null);
      }
      _originalState = _serializeState();
    }
  }

  void _changeSetType(SetTemplate setTemplate, String newType) {
    setState(() {
      final reIndex = _routineExercises.indexWhere(
        (re) => re.setTemplates.contains(setTemplate),
      );
      if (reIndex == -1) return;

      final routineExercise = _routineExercises[reIndex];
      final setIndex = routineExercise.setTemplates.indexOf(setTemplate);
      if (setIndex == -1) return;

      final updatedTemplates = [...routineExercise.setTemplates];
      updatedTemplates[setIndex] = setTemplate.copyWith(setType: newType);

      _routineExercises[reIndex] = RoutineExercise(
        id: routineExercise.id,
        exercise: routineExercise.exercise,
        setTemplates: updatedTemplates,
        pauseSeconds: routineExercise.pauseSeconds,
      );
    });
  }

  void _showSetTypePicker(SetTemplate setTemplate) {
    final l10n = AppLocalizations.of(context)!;

    Widget buildSymbol(String char, Color color) {
      return Text(
        char,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final options = [
      {
        'type': 'normal',
        'label': l10n.set_type_normal,
        'symbol':
            buildSymbol('N', Theme.of(context).colorScheme.onSurfaceVariant),
      },
      {
        'type': 'warmup',
        'label': l10n.set_type_warmup,
        'symbol': buildSymbol('W', Colors.orange),
      },
      {
        'type': 'failure',
        'label': l10n.set_type_failure,
        'symbol': buildSymbol('F', Theme.of(context).colorScheme.error),
      },
      {
        'type': 'dropset',
        'label': l10n.set_type_dropset,
        'symbol': buildSymbol('D', Colors.blue),
      },
    ];

    showGlassBottomMenu(
      context: context,
      title: l10n.changeSetTypTitle,
      actions: options.map((opt) {
        return GlassMenuAction(
          customIcon: opt['symbol'] as Widget,
          label: opt['label'] as String,
          onTap: () => _changeSetType(setTemplate, opt['type'] as String),
        );
      }).toList(),
    );
  }

  void _editPauseTime(RoutineExercise re) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showGlassBottomMenu<({bool saved, int? value})>(
      context: context,
      title: l10n.editPauseTimeTitle,
      contentBuilder: (ctx, close) {
        return RoutinePauseTimeDialog(
          initialPauseSeconds: re.pauseSeconds,
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
      await WorkoutLocalDataSource.instance
          .updatePauseTime(re.id!, result.value);
      setState(() {
        final exerciseIndex = _routineExercises.indexOf(re);
        if (exerciseIndex != -1) {
          _routineExercises[exerciseIndex] = re.copyWith(
            pauseSeconds: result.value,
          );
        }
      });
      _originalState = _serializeState();
    }
  }

  void _deleteSingleExercise(RoutineExercise ex) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDeleteConfirmation(
      context,
      title: l10n.deleteExerciseConfirmTitle,
      content: l10n.deleteExerciseConfirmContent(
        ex.exercise.getLocalizedName(context),
      ),
    );

    if (confirmed && _routineId != null) {
      await WorkoutLocalDataSource.instance.removeExerciseFromRoutine(ex.id!);
      _loadExercisesForRoutine();
    }
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
      final RoutineExercise item = _routineExercises.removeAt(oldIndex);
      _routineExercises.insert(newIndex, item);
    });
    if (_routineId != null) {
      WorkoutLocalDataSource.instance.updateExerciseOrder(
        _routineId!,
        _routineExercises,
      );
    }
    _originalState = _serializeState();
  }

  void _shareCurrentRoutine() {
    final name = _nameController.text.trim();
    final routine = Routine(
      id: _routineId,
      name: name.isEmpty ? _originalName : name,
      exercises: _routineExercises,
    );
    _shareService.showRoutineShareSheet(context: context, routine: routine);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final double topPadding =
        MediaQuery.paddingOf(context).top + kToolbarHeight;

    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: PopScope(
          canPop: _canPop,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            _handlePopAttempt(result);
          },
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: GlobalAppBar(
              automaticallyImplyLeading: false,
              leading: Navigator.of(context).canPop()
                  ? IconButton(
                      icon: const Icon(LucideIcons.arrow_left),
                      onPressed: () => _handlePopAttempt(),
                    )
                  : null,
              title:
                  _isNewRoutine ? l10n.titleNewRoutine : l10n.titleEditRoutine,
              actions: [
                if (!_isNewRoutine)
                  IconButton(
                    tooltip: l10n.share,
                    icon: const Icon(LucideIcons.share),
                    onPressed: _shareCurrentRoutine,
                  ),
                TextButton(
                  onPressed: () => _saveRoutine(),
                  child: Text(
                    l10n.save,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                // Layer 1 (Bottom): The full scrollable viewport container
                RepaintBoundary(
                  child: Column(
                    children: [
                      Padding(
                        padding: DesignConstants.cardPadding.copyWith(
                          top: DesignConstants.cardPadding.top + topPadding,
                        ),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                              labelText: l10n.formFieldRoutineName),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.validatorPleaseEnterRoutineName;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: DesignConstants.spacingXS),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                      ),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _routineExercises.isEmpty
                                ? Center(
                                    child: Text(
                                      l10n.emptyStateAddFirstExercise,
                                      style: textTheme.titleMedium,
                                    ),
                                  )
                                : ReorderableListView.builder(
                                    scrollCacheExtent:
                                        const ScrollCacheExtent.pixels(1500.0),
                                    itemCount: _routineExercises.length,
                                    padding: EdgeInsets.only(
                                      bottom: DesignConstants
                                              .bottomContentSpacer +
                                          MediaQuery.paddingOf(context).bottom,
                                    ),
                                    proxyDecorator: (Widget child, int index,
                                        Animation<double> anim) {
                                      return Material(
                                        elevation: 4.0,
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        child: child,
                                      );
                                    },
                                    onReorderItem: _onReorderItem,
                                    itemBuilder: (context, index) {
                                      final routineExercise =
                                          _routineExercises[index];
                                      final bool isCardio =
                                          _isCardio(routineExercise);

                                      return EditRoutineExerciseCard(
                                        key: ValueKey(routineExercise.id),
                                        routineExercise: routineExercise,
                                        index: index,
                                        isCardio: isCardio,
                                        repsControllers: _repsControllers,
                                        weightControllers: _weightControllers,
                                        rirControllers: _rirControllers,
                                        onEditNotes: () => _editExerciseNotes(
                                            context, routineExercise),
                                        onEditPauseTime: () =>
                                            _editPauseTime(routineExercise),
                                        onDeleteExercise: () =>
                                            _deleteSingleExercise(
                                                routineExercise),
                                        onAddSet: () =>
                                            _addSet(routineExercise),
                                        onShowSetTypePicker: _showSetTypePicker,
                                        onRemoveSet: (template, listIndex) =>
                                            _removeSet(routineExercise,
                                                template.id!, listIndex),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),

                // Layer 2 (Top): Wger attribution — pinned just below the FAB
                Positioned(
                  bottom: 8.0 + MediaQuery.paddingOf(context).bottom / 2,
                  left: 0,
                  right: 0,
                  child: RepaintBoundary(
                    child: WgerAttributionWidget(
                      textStyle: textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(1, 1),
                            blurRadius: 4.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 24.0 + MediaQuery.paddingOf(context).bottom,
                  right: 16.0,
                  child: RepaintBoundary(
                    child: _EditRoutineFab(onPressed: _addExercises),
                  ),
                ),

                // --- Keyboard Done Accessory Bar ---
                const _KeyboardDoneBar(),
              ],
            ),
          ),
        ));
  }
}

class _KeyboardDoneBar extends StatefulWidget {
  const _KeyboardDoneBar();

  @override
  State<_KeyboardDoneBar> createState() => _KeyboardDoneBarState();
}

class _KeyboardDoneBarState extends State<_KeyboardDoneBar>
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
          padding:
              const EdgeInsets.symmetric(horizontal: DesignConstants.spacingL),
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

class _EditRoutineFab extends StatefulWidget {
  final VoidCallback onPressed;

  const _EditRoutineFab({required this.onPressed});

  @override
  State<_EditRoutineFab> createState() => _EditRoutineFabState();
}

class _EditRoutineFabState extends State<_EditRoutineFab>
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
    return GlassFab(
      label: AppLocalizations.of(context)!.fabAddExercise,
      onPressed: widget.onPressed,
    );
  }
}
