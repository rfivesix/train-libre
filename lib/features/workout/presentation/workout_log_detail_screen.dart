// lib/screens/workout_log_detail_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'widgets/exercise_record_data.dart';
import '../../../../services/unit_service.dart';
import '../../../widgets/common/algorithm_info_sheet.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';

import '../domain/repositories/workout_repository.dart';
import '../data/sources/workout_local_data_source.dart';
import '../../sharing/share_service.dart';
import '../../../generated/app_localizations.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../domain/models/set_log.dart';
import '../domain/models/exercise_block_key.dart';
import '../domain/models/workout_log.dart';
import '../../../services/profile_service.dart';
import '../../../services/health/workout_heart_rate_models.dart';
import '../../../services/health/workout_heart_rate_service.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../pulse/application/pulse_tracking_service.dart';
import '../../exercise_catalog/presentation/exercise_catalog_screen.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/dual_body_highlighter.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/card_morph_route.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/common.dart';
import 'widgets/workout_photo_card.dart';
import 'widgets/workout_summary_bar.dart';
import 'widgets/workout_heart_rate_section.dart';
import '../domain/classification/exercise_log_mask.dart';
import '../domain/classification/set_load.dart';
import 'widgets/workout_exercise_log_card.dart';
import 'widgets/muscle_color_helper.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../exercise_catalog/domain/body_slug_mapper.dart';
import 'edit_routine_screen.dart';
import 'reorder_scroll_anchor.dart';
import 'widgets/exercise_notes_dialog.dart';
import 'widgets/reorder_drag_proxy.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../util/time_util.dart';
import '../../../widgets/common/app_button.dart';
import '../../../services/telemetry/telemetry_service.dart';

/// A detailed view for a single completed [WorkoutLog].
///
/// Displays the full set log for each exercise performed during the session.
/// Supports an edit mode to adjust notes, start times, and set-level data.
class WorkoutLogDetailScreen extends StatefulWidget {
  /// The unique identifier of the workout log to display.
  final int logId;
  const WorkoutLogDetailScreen({super.key, required this.logId});

  @override
  State<WorkoutLogDetailScreen> createState() => _WorkoutLogDetailScreenState();
}

class _WorkoutLogDetailScreenState extends State<WorkoutLogDetailScreen> {
  bool _isLoading = true;
  WorkoutLog? _log;
  final WorkoutHeartRateService _heartRateService =
      const WorkoutHeartRateService();
  WorkoutHeartRateSummary? _heartRateSummary;
  Map<ExerciseBlockKey, List<SetLog>> _groupedSets = {};
  Map<ExerciseBlockKey, Exercise> _exerciseDetails = {};

  /// The user's body weight on the day of this workout, when recorded.
  ///
  /// Dated rather than current, for the same reason tonnage is: a workout from
  /// last spring was performed at last spring's weight, and re-valuing it at
  /// today's would move a past number for a present reason.
  double? _bodyweightKg;
  final Map<ExerciseBlockKey, List<ExerciseRecordData>> _newRecordsPerExercise =
      {};
  Map<ExerciseBlockKey, String> _exerciseNotes = {};
  bool _isEditMode = false;
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
    if (!_isEditMode) return;
    _touchedAnchorId = anchorId;
    _pointerDownPosition = event.position;
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted && !_isDragging && _isEditMode) {
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
      _trackReorderHover(event.position.dy);
    }
  }

  double? _lastDragPointerY;

  void _trackReorderHover(double pointerGlobalY) {
    _lastDragPointerY = pointerGlobalY;
    ReorderHapticFeedback.onPointerMove(
      pointerGlobalY: pointerGlobalY,
      anchor: _scrollAnchor,
      itemIds: _groupedSets.keys.map((key) => key.anchorId).toList(),
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

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;

  // Use weightController for KG or DISTANCE
  final Map<int, TextEditingController> _weightControllers = {};
  // Use repsController for REPS or TIME (min)
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _rirControllers = {};
  final Set<ExerciseBlockKey> _deletingExercises = <ExerciseBlockKey>{};

  void _onDeleteExercise(ExerciseBlockKey key, List<SetLog> sets) {
    if (_deletingExercises.contains(key)) return;
    HapticFeedbackService.instance.selectionFeedback();
    setState(() {
      _deletingExercises.add(key);
    });
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        setState(() {
          _deletingExercises.remove(key);
          for (var set in sets) {
            _weightControllers.remove(set.id!)?.dispose();
            _repsControllers.remove(set.id!)?.dispose();
            _rirControllers.remove(set.id!)?.dispose();
          }
          _groupedSets.remove(key);
          _exerciseNotes.remove(key);
        });
      }
    });
  }

  bool _pulseTrackingEnabled = false;
  DateTime? _editedStartTime;
  static const ShareService _shareService = ShareService();

  StreamSubscription<List<SetLog>>? _setLogsSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.workoutDetail));
    _scrollController.addListener(_onScrollUpdated);
    _notesController = TextEditingController();
    _loadDetails();
    _setLogsSubscription = context
        .read<IWorkoutRepository>()
        .watchSetLogsForWorkout(widget.logId)
        .listen(_onSetLogsUpdated);
  }

  void _onScrollUpdated() {
    if (_isDragActive && _lastDragPointerY != null) {
      _trackReorderHover(_lastDragPointerY!);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollUpdated);
    _setLogsSubscription?.cancel();
    _collapseTimer?.cancel();
    _expandTimer?.cancel();
    _scrollAnchor.discard();
    _scrollController.dispose();
    _notesController.dispose();
    _clearControllers();
    super.dispose();
  }

  void _onSetLogsUpdated(List<SetLog> updatedSets) async {
    if (!mounted || _isEditMode || _log == null) return;

    final repo = context.read<IWorkoutRepository>();
    final mutableSets = List<SetLog>.from(updatedSets);
    await _calculateHistoricalPRs(mutableSets,
        beforeTimestamp: _log!.startTime);

    final updatedGroups = groupSetsByExerciseBlock(mutableSets);
    final updatedDetails = <ExerciseBlockKey, Exercise>{};

    for (var set in mutableSets) {
      final key = ExerciseBlockKey.fromSet(set);
      final existing = _exerciseDetails[key];
      if (existing != null) {
        updatedDetails[key] = existing;
      } else {
        final ex = await repo.resolveExerciseForSetLog(set);
        if (ex != null) {
          updatedDetails[key] = ex;
        }
      }
    }

    final bodyweights = await repo.getBodyweightHistory();
    final bodyweightKg = bodyweights.at(_log!.startTime);

    if (!mounted || _isEditMode) return;

    setState(() {
      _log = _log!.copyWith(sets: mutableSets);
      _groupedSets = updatedGroups;
      _exerciseDetails = updatedDetails;
      _bodyweightKg = bodyweightKg;
    });
  }

  void _clearControllers() {
    for (var c in _weightControllers.values) {
      c.dispose();
    }
    for (var c in _repsControllers.values) {
      c.dispose();
    }
    for (var c in _rirControllers.values) {
      c.dispose();
    }
    _weightControllers.clear();
    _repsControllers.clear();
    _rirControllers.clear();
  }

  bool _isCardio(ExerciseBlockKey key) {
    final ex = _exerciseDetails[key];
    return ex?.isCardio ?? false;
  }

  ExerciseLogMask _maskFor(ExerciseBlockKey key) =>
      ExerciseLogMask.forExercise(_exerciseDetails[key]);

  int _nextExerciseBlock() {
    var next = 0;
    for (final key in _groupedSets.keys) {
      final block = key.exerciseBlock;
      if (block != null && block >= next) next = block + 1;
    }
    return next;
  }

  ({String label, Color color, bool continuesAbove, bool continuesBelow})?
      _historySupersetStyleAt(int index) {
    final groups = [
      for (final sets in _groupedSets.values)
        sets.isEmpty ? null : sets.first.supersetGroup,
    ];
    if (index < 0 || index >= groups.length) return null;
    final group = groups[index];
    if (group == null) return null;
    final indices = <int>[
      for (var i = 0; i < groups.length; i++)
        if (groups[i] == group) i,
    ];
    if (indices.length < 2 ||
        indices.last - indices.first + 1 != indices.length) {
      return null;
    }
    final validGroups = <int>[];
    for (final candidate in groups.whereType<int>()) {
      if (!validGroups.contains(candidate)) validGroups.add(candidate);
    }
    final groupIndex = validGroups.indexOf(group);
    final memberIndex = index - indices.first;
    return (
      label: '${_supersetLetter(groupIndex)}${memberIndex + 1}',
      color: DesignConstants
          .supersetColors[groupIndex % DesignConstants.supersetColors.length],
      continuesAbove: memberIndex > 0,
      continuesBelow: memberIndex < indices.length - 1,
    );
  }

  void _toggleSupersetAfter(int upperIndex) {
    final entries = _groupedSets.entries.toList();
    if (upperIndex < 0 || upperIndex + 1 >= entries.length) return;

    final groups = [
      for (final entry in entries)
        entry.value.isEmpty ? null : entry.value.first.supersetGroup,
    ];
    final upperGroup = groups[upperIndex];
    final lowerGroup = groups[upperIndex + 1];
    final maxGroup = groups.whereType<int>().fold<int>(
          0,
          (max, group) => group > max ? group : max,
        );

    void updateGroup(int index, int? group) {
      final entry = entries[index];
      _groupedSets[entry.key] = [
        for (final set in entry.value)
          group == null
              ? set.copyWith(clearSupersetGroup: true)
              : set.copyWith(supersetGroup: group),
      ];
    }

    setState(() {
      if (upperGroup != null && upperGroup == lowerGroup) {
        var start = upperIndex;
        while (start > 0 && groups[start - 1] == upperGroup) {
          start--;
        }
        var end = upperIndex + 1;
        while (end + 1 < groups.length && groups[end + 1] == upperGroup) {
          end++;
        }
        final nextGroup = maxGroup + 1;
        for (var index = start; index <= upperIndex; index++) {
          updateGroup(
              index, index == start && index == upperIndex ? null : upperGroup);
        }
        for (var index = upperIndex + 1; index <= end; index++) {
          updateGroup(index,
              index == upperIndex + 1 && index == end ? null : nextGroup);
        }
      } else {
        final mergedGroup = upperGroup ?? lowerGroup ?? maxGroup + 1;
        var start = upperIndex;
        if (upperGroup != null) {
          while (start > 0 && groups[start - 1] == upperGroup) {
            start--;
          }
        }
        var end = upperIndex + 1;
        if (lowerGroup != null) {
          while (end + 1 < groups.length && groups[end + 1] == lowerGroup) {
            end++;
          }
        }
        for (var index = start; index <= end; index++) {
          updateGroup(index, mergedGroup);
        }
      }
    });
  }

  String _supersetLetter(int index) {
    var value = index + 1;
    final codes = <int>[];
    while (value > 0) {
      value--;
      codes.add(65 + value % 26);
      value ~/= 26;
    }
    return String.fromCharCodes(codes.reversed);
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

  Future<void> _loadDetails({bool preserveEditState = false}) async {
    if (!preserveEditState) {
      setState(() => _isLoading = true);
    }

    final data = await WorkoutLocalDataSource.instance.getWorkoutLogById(
      widget.logId,
    );
    if (data == null) {
      if (mounted) {
        setState(() {
          _heartRateSummary = null;
          _isLoading = false;
        });
      }
      return;
    }

    final savedExerciseNotes = await WorkoutLocalDataSource.instance
        .getWorkoutExerciseNotes(widget.logId);

    final heartRateFuture = _heartRateService.loadForWorkoutWindow(
      startTime: data.startTime,
      endTime: data.endTime,
    );

    final pulseTrackingFuture = PulseTrackingService().isTrackingEnabled();
    // ignore: use_build_context_synchronously
    final unitService = context.read<UnitService>();

    // Resolve exercise metadata via stored exercise_id when available.
    final Map<ExerciseBlockKey, Exercise> details = {};
    for (final set in data.sets) {
      final key = ExerciseBlockKey.fromSet(set);
      if (details.containsKey(key)) continue;
      final ex = await WorkoutLocalDataSource.instance.resolveExerciseForSetLog(
        set,
      );
      if (ex != null) {
        details[key] = ex;
      }
    }

    _notesController.text = data.notes ?? '';
    _editedStartTime = data.startTime;

    // Populate controllers
    _clearControllers();
    for (final setLog in data.sets) {
      // Distinguish cardio vs strength for initial values
      final isCardio =
          details[ExerciseBlockKey.fromSet(setLog)]?.isCardio ?? false;

      String val1, val2;

      if (isCardio) {
        // Cardio: Val1 = Distance, Val2 = Duration
        val1 = setLog.distanceKm == null
            ? ''
            : setLog.distanceKm!
                .toStringAsFixed(3)
                .replaceAll(RegExp(r'0*$'), '')
                .replaceAll(RegExp(r'\.$'), '');
        val2 = formatPauseDuration(setLog.durationSeconds);
      } else {
        // Strength: Val1 = weight, Val2 = reps
        val1 = setLog.weightKg == null
            ? ''
            : unitService.formatDisplayWeight(setLog.weightKg!);
        val2 = setLog.reps?.toString() ?? '';
      }

      _weightControllers[setLog.id!] = TextEditingController(text: val1);
      _repsControllers[setLog.id!] = TextEditingController(text: val2);
      _rirControllers[setLog.id!] = TextEditingController(
        text: setLog.rir?.toString() ?? '',
      );
    }

    if (!mounted) return;
    final heartRateSummary = await heartRateFuture;
    final pulseTrackingEnabled = await pulseTrackingFuture;
    if (!mounted) return;

    // Recalculate PRs for historical view
    await _calculateHistoricalPRs(data.sets, beforeTimestamp: data.startTime);

    // Re-group because copies were made
    final updatedGroups = groupSetsByExerciseBlock(data.sets);
    final notesByBlock = <ExerciseBlockKey, String>{};
    for (final key in updatedGroups.keys) {
      final note = savedExerciseNotes[key.exerciseName];
      if (note != null) notesByBlock[key] = note;
    }

    setState(() {
      _log = data;
      _groupedSets = updatedGroups;
      _exerciseDetails = details;
      _exerciseNotes = notesByBlock;
      _heartRateSummary = heartRateSummary;
      _pulseTrackingEnabled = pulseTrackingEnabled;
      if (!preserveEditState) {
        _isLoading = false;
      }
    });
  }

  Future<void> _calculateHistoricalPRs(
    List<SetLog> sets, {
    DateTime? beforeTimestamp,
  }) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    _newRecordsPerExercise.clear();
    final db = WorkoutLocalDataSource.instance;
    final Map<String, Map<String, double>> historicalBests = {};

    for (var i = 0; i < sets.length; i++) {
      final setLog = sets[i];
      final exName = setLog.exerciseName;
      final blockKey = ExerciseBlockKey.fromSet(setLog);

      if (!historicalBests.containsKey(exName)) {
        historicalBests[exName] = await db.getExerciseBests(
          exName,
          excludeWorkoutLogId: widget.logId,
          beforeTimestamp: beforeTimestamp,
        );
      }

      final bests = historicalBests[exName]!;
      final currentWeight = setLog.weightKg ?? 0.0;
      // Valued the same way getExerciseBests values the history it is being
      // compared against; otherwise a body-weight set is a record every time.
      final setMask = _maskFor(blockKey);
      final currentVolume = setTonnageKg(
        trackingType: setMask.trackingType,
        loadMode: setMask.loadMode,
        loggedWeightKg: setLog.weightKg,
        reps: setLog.reps,
        bodyweightKg: _bodyweightKg,
      );
      final currentEst1rm = setMask.estimatedOneRepMax(
            loggedWeightKg: setLog.weightKg,
            reps: setLog.reps,
            bodyweightKg: _bodyweightKg,
          ) ??
          0.0;

      bool isMaxWeightPR = false;
      bool isMaxVolumePR = false;
      bool isMaxEst1RMPR = false;
      double? weightDiff;
      double? volumeDiff;
      double? est1rmDiff;

      bool isMaxDistancePR = false;
      bool isMaxDurationPR = false;
      bool isFastestPacePR = false;
      double? distanceDiff;
      int? durationDiff;
      double? paceDiff;

      final currentDistance = setLog.distanceKm ?? 0.0;
      final currentDuration = setLog.durationSeconds ?? 0;
      double currentPace = double.infinity;
      if (currentDistance > 0 && currentDuration > 0) {
        currentPace = currentDuration / currentDistance;
      }

      if (setLog.isCompleted == true && setLog.setType != 'warmup') {
        if (currentWeight > 0) {
          final oldMaxWeight = bests['maxWeight'] ?? 0.0;
          if (currentWeight > oldMaxWeight) {
            isMaxWeightPR = true;
            weightDiff = oldMaxWeight > 0 ? currentWeight - oldMaxWeight : null;
            bests['maxWeight'] = currentWeight;
          }

          final oldMaxVolume = bests['maxVolume'] ?? 0.0;
          if (currentVolume > oldMaxVolume) {
            isMaxVolumePR = true;
            volumeDiff = oldMaxVolume > 0 ? currentVolume - oldMaxVolume : null;
            bests['maxVolume'] = currentVolume;
          }

          final oldMaxEst1rm = bests['maxEst1rm'] ?? 0.0;
          if (currentEst1rm > oldMaxEst1rm) {
            isMaxEst1RMPR = true;
            est1rmDiff = oldMaxEst1rm > 0 ? currentEst1rm - oldMaxEst1rm : null;
            bests['maxEst1rm'] = currentEst1rm;
          }
        }

        if (currentDistance > 0 || currentDuration > 0) {
          final oldMaxDistance = bests['maxDistance'] ?? 0.0;
          if (currentDistance > oldMaxDistance) {
            isMaxDistancePR = true;
            distanceDiff =
                oldMaxDistance > 0 ? currentDistance - oldMaxDistance : null;
            bests['maxDistance'] = currentDistance;
          }

          final oldMaxDuration = bests['maxDuration']?.toInt() ?? 0;
          if (currentDuration > oldMaxDuration) {
            isMaxDurationPR = true;
            durationDiff =
                oldMaxDuration > 0 ? currentDuration - oldMaxDuration : null;
            bests['maxDuration'] = currentDuration.toDouble();
          }

          final oldFastestPace = bests['fastestPace'] ?? 0.0;
          if (currentPace != double.infinity &&
              (oldFastestPace == 0.0 || currentPace < oldFastestPace)) {
            isFastestPacePR = true;
            paceDiff = oldFastestPace > 0 ? oldFastestPace - currentPace : null;
            bests['fastestPace'] = currentPace;
          }
        }

        // Add to _newRecordsPerExercise
        if (isMaxWeightPR ||
            isMaxVolumePR ||
            isMaxEst1RMPR ||
            isMaxDistancePR ||
            isMaxDurationPR ||
            isFastestPacePR) {
          _newRecordsPerExercise.putIfAbsent(blockKey, () => []);

          if (isMaxWeightPR) {
            _newRecordsPerExercise[blockKey]!.add(ExerciseRecordData.weight(
              label: l10n.exerciseMetricMaxWeight,
              valueKg: currentWeight,
              diffKg: weightDiff,
            ));
          }
          if (isMaxVolumePR) {
            _newRecordsPerExercise[blockKey]!.add(ExerciseRecordData.weight(
              label: l10n.exerciseMetricVolume,
              valueKg: currentVolume,
              diffKg: volumeDiff,
              fractionDigits: 0,
            ));
          }
          if (isMaxEst1RMPR) {
            _newRecordsPerExercise[blockKey]!.add(ExerciseRecordData.weight(
              label: l10n.exerciseMetricEst1RM,
              valueKg: currentEst1rm,
              diffKg: est1rmDiff,
            ));
          }
          if (isMaxDistancePR) {
            _newRecordsPerExercise[blockKey]!.add(ExerciseRecordData.cardio(
              label: 'Best Distance',
              value:
                  '${currentDistance.toStringAsFixed(2).replaceAll(RegExp(r"0*$"), "").replaceAll(RegExp(r"\.$"), "")} km',
              diff: distanceDiff != null
                  ? '+${distanceDiff.toStringAsFixed(2).replaceAll(RegExp(r"0*$"), "").replaceAll(RegExp(r"\.$"), "")} km'
                  : null,
            ));
          }
          if (isMaxDurationPR) {
            final m = currentDuration ~/ 60;
            final s = currentDuration % 60;
            String? diffStr;
            if (durationDiff != null) {
              final dm = durationDiff ~/ 60;
              final ds = durationDiff % 60;
              diffStr = '+${dm > 0 ? '${dm}m ' : ''}${ds}s';
            }
            _newRecordsPerExercise[blockKey]!.add(ExerciseRecordData.cardio(
              label: 'Longest Duration',
              value: '${m}m ${s}s',
              diff: diffStr,
            ));
          }
          if (isFastestPacePR) {
            final pm = currentPace.toInt() ~/ 60;
            final ps = currentPace.toInt() % 60;
            String? diffStr;
            if (paceDiff != null) {
              final dm = paceDiff.toInt() ~/ 60;
              final ds = paceDiff.toInt() % 60;
              diffStr = '-${dm > 0 ? '${dm}m ' : ''}${ds}s';
            }
            _newRecordsPerExercise[blockKey]!.add(ExerciseRecordData.cardio(
              label: 'Fastest Pace',
              value: '${pm}m ${ps}s / km',
              diff: diffStr,
            ));
          }
        }
      }

      sets[i] = setLog.copyWith(
        isMaxWeightPR: isMaxWeightPR,
        isMaxVolumePR: isMaxVolumePR,
        isMaxEst1RMPR: isMaxEst1RMPR,
        weightPRDiff: weightDiff,
        volumePRDiff: volumeDiff,
        est1rmPRDiff: est1rmDiff,
        isMaxDistancePR: isMaxDistancePR,
        isMaxDurationPR: isMaxDurationPR,
        isFastestPacePR: isFastestPacePR,
        distancePRDiff: distanceDiff,
        durationPRDiff: durationDiff,
        pacePRDiff: paceDiff,
      );
    }
  }

  // Formatting now uses UnitService so this helper is no longer needed.

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (_isEditMode) {
        _loadDetails(preserveEditState: true);
      } else {
        _loadDetails();
      }
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showAdaptiveDatePicker(
      context: context,
      initialDate: _editedStartTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showAdaptiveTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_editedStartTime ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _editedStartTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    try {
      final l10n = AppLocalizations.of(context)!;
      final dbHelper = WorkoutLocalDataSource.instance;
      final unitService = context.read<UnitService>();

      final initialSetIds = _log!.sets.map((s) => s.id!).toSet();
      final currentSets = _groupedSets.values.expand((sets) => sets).toList();

      final idsToDelete = initialSetIds
          .difference(currentSets.map((s) => s.id!).toSet())
          .toList();

      final List<SetLog> setsToUpdate = [];
      final List<SetLog> setsToInsert = [];

      int currentOrder = 0;

      for (final blockEntry in _groupedSets.entries) {
        for (final setLog in blockEntry.value) {
          // Distinguish again what the controller values mean.
          final isCardio = _isCardio(ExerciseBlockKey.fromSet(setLog));

          final val1Input = double.tryParse(
                _weightControllers[setLog.id!]?.text.replaceAll(',', '.') ??
                    '0',
              ) ??
              0.0;
          final val1 = isCardio
              ? val1Input
              : unitService.convertToMetric(val1Input, UnitDimension.weight);
          final repsText = _repsControllers[setLog.id!]?.text ?? '';
          final val2 = isCardio
              ? (parsePauseDuration(repsText) ?? 0).toDouble()
              : (double.tryParse(repsText.replaceAll(',', '.')) ?? 0.0);
          final rir = int.tryParse(_rirControllers[setLog.id!]?.text ?? '');

          SetLog updatedSet;

          if (isCardio) {
            // Val1 = Distance, Val2 = Seconds
            updatedSet = setLog.copyWith(
              distanceKm: val1,
              durationSeconds: val2.round(),
              rir: rir,
              clearRir: rir == null,
              logOrder: currentOrder++,
              // Set weight/reps to 0/null for cardio to avoid bad data?
              weightKg: 0,
              reps: 0,
            );
          } else {
            // Val1 = Weight, Val2 = Reps (int)
            updatedSet = setLog.copyWith(
              weightKg: val1,
              reps: val2.toInt(),
              rir: rir,
              clearRir: rir == null,
              logOrder: currentOrder++,
              // Cardio Felder nullen
              distanceKm: null,
              durationSeconds: null,
            );
          }

          if (initialSetIds.contains(setLog.id)) {
            setsToUpdate.add(updatedSet);
          } else {
            setsToInsert.add(updatedSet);
          }
        }
      }

      final dbInstance = await dbHelper.database;
      await dbInstance.transaction(() async {
        await dbHelper.updateWorkoutLogDetails(
          widget.logId,
          _editedStartTime!,
          _notesController.text,
        );
        if (idsToDelete.isNotEmpty) await dbHelper.deleteSetLogs(idsToDelete);
        if (setsToUpdate.isNotEmpty) await dbHelper.updateSetLogs(setsToUpdate);
        for (final set in setsToInsert) {
          await dbHelper.insertSetLog(
            set.copyWith(id: null, workoutLogId: widget.logId),
          );
        }
        for (final key in _exerciseNotes.keys) {
          final note = _exerciseNotes[key];
          await dbHelper.saveWorkoutExerciseNote(
            workoutLogId: widget.logId,
            exerciseName: key.exerciseName,
            notes: note != null && note.isNotEmpty ? note : null,
          );
        }
      });

      if (mounted) {
        HapticFeedbackService.instance.confirmationFeedback();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineSaved)));
      }

      setState(() => _isEditMode = false);
      _loadDetails();
    } catch (e, stackTrace) {
      debugPrint("Error saving changes: $e");
      debugPrint(stackTrace.toString());
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${l10n.error}: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showSaveAsRoutineDialog() async {
    final repo = context.read<IWorkoutRepository>();
    final l10n = AppLocalizations.of(context)!;
    final defaultName =
        _log!.routineName != null && _log!.routineName!.isNotEmpty
            ? "${_log!.routineName} (Kopie)"
            : "Meine neue Routine";

    final controller = TextEditingController(text: defaultName);

    final routineName = await showGlassBottomMenu<String?>(
      context: context,
      title: l10n.saveAsRoutineTitle,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingS,
                  vertical: DesignConstants.spacingXS),
              child: Text(
                l10n.saveAsRoutinePrompt,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.formFieldRoutineName,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusM),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.primary(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        close();
                        Navigator.of(ctx).pop(name);
                      }
                    },
                    label: l10n.save,
                    tooltip: l10n.save,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (routineName != null && routineName.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final newRoutine = await repo.createRoutineFromWorkout(
          workoutLogId: widget.logId,
          name: routineName,
        );

        final newRoutineWithDetails = await WorkoutLocalDataSource.instance
            .getRoutineById(newRoutine.id!);

        if (mounted) {
          final navigator = Navigator.of(context);
          HapticFeedbackService.instance.confirmationFeedback();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.saveAsRoutineSuccess),
              action: SnackBarAction(
                label: l10n.snackbarRoutineSavedAction,
                onPressed: () {
                  if (newRoutineWithDetails != null) {
                    navigator.push(
                      CardMorphRoute(
                        builder: (context) =>
                            EditRoutineScreen(routine: newRoutineWithDetails),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.createRoutineError(e.toString()))),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _editExerciseNotes(BuildContext context, ExerciseBlockKey key) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showGlassBottomMenu<String?>(
      context: context,
      title: l10n.exerciseNoteTitle,
      contentBuilder: (ctx, close) {
        return ExerciseNotesDialog(
          initialNotes: _exerciseNotes[key],
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
        _exerciseNotes[key] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.watch<UnitService>();
    final locale = Localizations.localeOf(context).toString();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    double totalVolume = 0.0;
    if (_log != null) {
      for (final set in _log!.sets) {
        totalVolume += (set.weightKg ?? 0) * (set.reps ?? 0);
      }
    }
    final Duration duration =
        _log?.endTime?.difference(_log!.startTime) ?? Duration.zero;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(
        title: l10n.workoutDetailsTitle,
        actions: [
          if (!_isLoading && _log != null)
            _isEditMode
                ? TextButton(
                    onPressed: _saveChanges,
                    child: Text(
                      l10n.save,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: l10n.edit,
                    icon: const Icon(LucideIcons.pencil),
                    onPressed: _toggleEditMode,
                  ),
          if (!_isLoading && _log != null && !_isEditMode) ...[
            IconButton(
              tooltip: l10n.saveAsRoutineTitle,
              icon: const Icon(LucideIcons.bookmark_plus),
              onPressed: _showSaveAsRoutineDialog,
            ),
            IconButton(
              tooltip: l10n.share,
              icon: Icon(DesignConstants.adaptiveShareIcon),
              onPressed: () => _shareService.showWorkoutShareSheet(
                context: context,
                workout: _log!,
              ),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _log == null
              ? Center(child: Text(l10n.workoutNotFound))
              : Column(
                  children: [
                    WorkoutSummaryBar(
                      duration: duration,
                      volume: totalVolume,
                      sets: _log!.sets.length,
                      progress: null,
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        children: [
                          if (_isEditMode)
                            ReorderHeadroom(
                              height: _isDragging ? _dynamicHeadroom : 0.0,
                            ),
                          // Header Info (Clean Hero section)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal:
                                  DesignConstants.screenPaddingHorizontal,
                              vertical: DesignConstants.spacingM,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _log!.routineName ??
                                              l10n.freeWorkoutTitle,
                                          style:
                                              textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (_isEditMode)
                                        IconButton(
                                          tooltip: l10n.selectDateTitle,
                                          icon: Icon(
                                            LucideIcons.calendar,
                                            size: 20,
                                            color: colorScheme.primary,
                                          ),
                                          onPressed: _pickDateTime,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat.yMMMMd(locale).add_Hm().format(
                                          _editedStartTime ?? _log!.startTime,
                                        ),
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (_isEditMode) ...[
                                    const SizedBox(
                                        height: DesignConstants.spacingM),
                                    TextFormField(
                                      controller: _notesController,
                                      decoration: InputDecoration(
                                        labelText: l10n.notesLabel,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            DesignConstants.borderRadiusM,
                                          ),
                                        ),
                                      ),
                                      maxLines: 3,
                                    ),
                                  ] else if (_log!.notes != null &&
                                      _log!.notes!.isNotEmpty) ...[
                                    const SizedBox(
                                        height: DesignConstants.spacingM),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(
                                          DesignConstants.spacingM),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(
                                          DesignConstants.borderRadiusM,
                                        ),
                                        border: Border.all(
                                          color: colorScheme.outlineVariant
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Text(
                                        '${l10n.notesLabel}: ${_log!.notes!}',
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Workout Photos (UNDER Header Info)
                          if (_log!.photoPaths.isNotEmpty || _isEditMode)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                DesignConstants.screenPaddingHorizontal,
                                0,
                                DesignConstants.screenPaddingHorizontal,
                                DesignConstants.spacingM,
                              ),
                              child: WorkoutPhotoCard(
                                workoutLogId: _log!.id,
                                photoPaths: _log!.photoPaths,
                                isEditable: _isEditMode,
                                onPhotosChanged: (updatedPaths) {
                                  setState(() {
                                    _log = _log!.copyWith(
                                      photoPaths: updatedPaths,
                                    );
                                  });
                                },
                              ),
                            ),
                          if (_exerciseDetails.isNotEmpty) ...[
                            Builder(
                              builder: (context) {
                                final heatmapWidget = _buildMuscleHeatmap(l10n);
                                if (heatmapWidget is SizedBox) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        DesignConstants.screenPaddingHorizontal,
                                    vertical: DesignConstants.spacingM,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppSectionHeader(
                                        title: l10n
                                            .analyticsRecentDistributionHeatmap,
                                        padding: EdgeInsets.zero,
                                      ),
                                      const SizedBox(
                                        height: DesignConstants.spacingM,
                                      ),
                                      heatmapWidget,
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                          if (_heartRateSummary != null &&
                              (_pulseTrackingEnabled ||
                                  _heartRateSummary!.hasData))
                            Padding(
                              padding: DesignConstants.cardPadding.copyWith(
                                top: 0,
                              ),
                              child: WorkoutHeartRateSection(
                                summary: _heartRateSummary!,
                                pulseTrackingEnabled: _pulseTrackingEnabled,
                              ),
                            ),

                          // NEW RECORDS SECTION
                          if (_newRecordsPerExercise.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal:
                                    DesignConstants.screenPaddingHorizontal,
                              ),
                              child: AppSectionHeader(
                                title: l10n.workoutSummaryNewRecordsTitle,
                                padding: EdgeInsets.zero,
                                action: AlgorithmInfoButton(
                                  title:
                                      "Estimated 1-Rep Max Heuristic (Epley Equation)",
                                  explanation:
                                      "Estimates maximal strength capacities based on submaximal workloads to allow safe, non-clinical progression tracking.",
                                  keyPoints: const [
                                    "1RM ≈ w * (36 / (37 - r)) where w = weight, r = repetitions (valid for r <= 10).",
                                    "Estimates are sports-science heuristics designed for healthy individuals.",
                                    "Provides a safe way to track strength progression without testing true failure.",
                                  ],
                                  technicalTitle: "Epley Equation Details",
                                  technicalExplanation:
                                      "The Epley equation estimates one-repetition maximum (1RM) as 1RM = w * (1 + r/30) which simplifies to w * (36 / (37 - r)) for r <= 10. Research suggests this linear approximation is reliable for low repetitions (2-10 reps) in healthy active individuals, but tends to overestimate capacity beyond 10 repetitions.",
                                  citationUrl:
                                      "https://rfivesix.github.io/train-libre/intelligent-workouts/#evidence",
                                ),
                              ),
                            ),
                            const SizedBox(height: DesignConstants.spacingS),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal:
                                    DesignConstants.screenPaddingHorizontal,
                              ),
                              child: Column(
                                children:
                                    _newRecordsPerExercise.entries.map((entry) {
                                  return SummaryCard(
                                    child: ListTile(
                                      leading: const Icon(
                                        LucideIcons.trophy,
                                        color: Colors.amber,
                                      ),
                                      title: Text(
                                        _exerciseDetails[entry.key]
                                                ?.getLocalizedName(context) ??
                                            entry.key.exerciseName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        entry.value
                                            .map((record) => record.format(
                                                context.read<UnitService>()))
                                            .join(', '),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: DesignConstants.spacingL),
                          ],

                          // EXERCISE LIST SECTION HEADER
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal:
                                  DesignConstants.screenPaddingHorizontal,
                              vertical: DesignConstants.spacingS,
                            ),
                            child: AppSectionHeader(
                              title: l10n.workoutSummaryExerciseOverview,
                              padding: EdgeInsets.zero,
                            ),
                          ),

                          // Sets
                          if (!_isEditMode)
                            ..._groupedSets.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((indexedEntry) {
                              final index = indexedEntry.key;
                              final entry = indexedEntry.value;
                              final key = entry.key;
                              final exerciseName = key.exerciseName;
                              final Exercise? exercise = _exerciseDetails[key];
                              final List<SetLog> sets = entry.value;
                              final isCardio = _isCardio(key);
                              final supersetStyle =
                                  _historySupersetStyleAt(index);

                              return WorkoutExerciseLogCard(
                                exerciseName: exerciseName,
                                exercise: exercise,
                                sets: sets,
                                isEditMode: false,
                                isCardio: isCardio,
                                mask: _maskFor(key),
                                bodyweightKg: _bodyweightKg,
                                weightControllers: _weightControllers,
                                repsControllers: _repsControllers,
                                rirControllers: _rirControllers,
                                exerciseNote: _exerciseNotes[key],
                                onEditNotes: (_) =>
                                    _editExerciseNotes(context, key),
                                onDeleteExercise: (_) {
                                  setState(() {
                                    for (var set in sets) {
                                      _weightControllers
                                          .remove(set.id!)
                                          ?.dispose();
                                      _repsControllers
                                          .remove(set.id!)
                                          ?.dispose();
                                      _rirControllers
                                          .remove(set.id!)
                                          ?.dispose();
                                    }
                                    _groupedSets.remove(key);
                                    _exerciseNotes.remove(key);
                                  });
                                },
                                onAddSet: () {},
                                onDeleteSet: (setId) {},
                                onSetTypeTap: (setId) {},
                                index: -1,
                                supersetLabel: supersetStyle?.label,
                                supersetColor: supersetStyle?.color,
                                continuesSupersetAbove:
                                    supersetStyle?.continuesAbove ?? false,
                                continuesSupersetBelow:
                                    supersetStyle?.continuesBelow ?? false,
                              );
                            })
                          else ...[
                            Listener(
                              onPointerMove: (e) {
                                if (_isDragActive) {
                                  _trackReorderHover(e.position.dy);
                                }
                              },
                              child: ReorderableListView.builder(
                                buildDefaultDragHandles: false,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                onReorderStart: (index) {
                                  if (!_isEditMode) return;
                                  _isDragActive = true;
                                  ReorderHapticFeedback.onDragStart(index);
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
                                  if (index >= 0 &&
                                      index < _groupedSets.length) {
                                    final entry =
                                        _groupedSets.entries.elementAt(index);
                                    final key = entry.key;
                                    final exerciseName = key.exerciseName;
                                    final Exercise? exercise =
                                        _exerciseDetails[key];
                                    final List<SetLog> sets = entry.value;
                                    final isCardio = _isCardio(key);
                                    final supersetStyle =
                                        _historySupersetStyleAt(index);

                                    final proxyChild = WorkoutExerciseLogCard(
                                      exerciseName: exerciseName,
                                      exercise: exercise,
                                      sets: sets,
                                      isEditMode: true,
                                      isCardio: isCardio,
                                      mask: _maskFor(key),
                                      bodyweightKg: _bodyweightKg,
                                      isDragging: true,
                                      weightControllers: _weightControllers,
                                      repsControllers: _repsControllers,
                                      rirControllers: _rirControllers,
                                      exerciseNote: _exerciseNotes[key],
                                      onEditNotes: (_) {},
                                      onDeleteExercise: (_) {},
                                      onAddSet: () {},
                                      onDeleteSet: (_) {},
                                      onSetTypeTap: (_) {},
                                      index: index,
                                      supersetLabel: supersetStyle?.label,
                                      supersetColor: supersetStyle?.color,
                                    );
                                    return buildReorderDragProxy(
                                        context, proxyChild, animation);
                                  }
                                  return buildReorderDragProxy(
                                      context, child, animation);
                                },
                                onReorderItem: (int oldIndex, int newIndex) {
                                  setState(() {
                                    final entries =
                                        _groupedSets.entries.toList();
                                    final item = entries.removeAt(oldIndex);
                                    entries.insert(newIndex, item);
                                    _groupedSets.clear();
                                    for (var entry in entries) {
                                      _groupedSets[entry.key] = entry.value;
                                    }
                                  });
                                },
                                itemCount: _groupedSets.length,
                                itemBuilder: (context, index) {
                                  final entry =
                                      _groupedSets.entries.elementAt(index);
                                  final key = entry.key;
                                  final exerciseName = key.exerciseName;
                                  final Exercise? exercise =
                                      _exerciseDetails[key];
                                  final List<SetLog> sets = entry.value;
                                  final isCardio = _isCardio(key);
                                  final supersetStyle =
                                      _historySupersetStyleAt(index);

                                  final isDeleting =
                                      _deletingExercises.contains(key);

                                  return KeyedSubtree(
                                    key: _scrollAnchor.keyFor(key.anchorId),
                                    child: AnimatedSize(
                                      duration: kReorderCardResizeDuration,
                                      curve: Curves.easeInOutCubic,
                                      alignment: Alignment.topCenter,
                                      child: isDeleting
                                          ? const SizedBox(
                                              width: double.infinity, height: 0)
                                          : AnimatedOpacity(
                                              duration: const Duration(
                                                  milliseconds: 180),
                                              curve: Curves.easeOut,
                                              opacity: isDeleting ? 0.0 : 1.0,
                                              child: RepaintBoundary(
                                                key: ValueKey(key.anchorId),
                                                child: Column(
                                                  children: [
                                                    WorkoutExerciseLogCard(
                                                      exerciseName:
                                                          exerciseName,
                                                      exercise: exercise,
                                                      sets: sets,
                                                      isEditMode: true,
                                                      isCardio: isCardio,
                                                      mask: _maskFor(key),
                                                      bodyweightKg:
                                                          _bodyweightKg,
                                                      isDragging: _isDragging,
                                                      onPointerDown: (e) =>
                                                          _onDragPointerDown(
                                                              e,
                                                              key.anchorId,
                                                              index),
                                                      onPointerMove:
                                                          _onDragPointerMove,
                                                      onPointerUp:
                                                          _onDragPointerUp,
                                                      onPointerCancel:
                                                          _onDragPointerCancel,
                                                      weightControllers:
                                                          _weightControllers,
                                                      repsControllers:
                                                          _repsControllers,
                                                      rirControllers:
                                                          _rirControllers,
                                                      exerciseNote:
                                                          _exerciseNotes[key],
                                                      onEditNotes: (_) =>
                                                          _editExerciseNotes(
                                                              context, key),
                                                      onDeleteExercise: (_) =>
                                                          _onDeleteExercise(
                                                              key, sets),
                                                      onAddSet: () {
                                                        final newSet = SetLog(
                                                          id: -DateTime.now()
                                                              .millisecondsSinceEpoch,
                                                          workoutLogId:
                                                              _log!.id!,
                                                          exerciseName:
                                                              exerciseName,
                                                          setType: 'normal',
                                                          isCompleted: true,
                                                          exerciseBlock:
                                                              key.exerciseBlock,
                                                        );
                                                        setState(() {
                                                          sets.add(newSet);
                                                          _weightControllers[
                                                                  newSet.id!] =
                                                              TextEditingController();
                                                          _repsControllers[
                                                                  newSet.id!] =
                                                              TextEditingController();
                                                          _rirControllers[
                                                                  newSet.id!] =
                                                              TextEditingController();
                                                        });
                                                      },
                                                      onDeleteSet: (setId) {
                                                        setState(() {
                                                          sets.removeWhere(
                                                              (s) =>
                                                                  s.id ==
                                                                  setId);
                                                          _weightControllers
                                                              .remove(setId)
                                                              ?.dispose();
                                                          _repsControllers
                                                              .remove(setId)
                                                              ?.dispose();
                                                          _rirControllers
                                                              .remove(setId)
                                                              ?.dispose();
                                                        });
                                                      },
                                                      onSetTypeTap: (setId) =>
                                                          _showSetTypePicker(
                                                              setId),
                                                      index: index,
                                                      supersetLabel:
                                                          supersetStyle?.label,
                                                      supersetColor:
                                                          supersetStyle?.color,
                                                      continuesSupersetAbove:
                                                          supersetStyle
                                                                  ?.continuesAbove ??
                                                              false,
                                                      continuesSupersetBelow:
                                                          supersetStyle
                                                                  ?.continuesBelow ??
                                                              false,
                                                      onToggleSupersetBelow:
                                                          index + 1 <
                                                                  _groupedSets
                                                                      .length
                                                              ? () =>
                                                                  _toggleSupersetAfter(
                                                                      index)
                                                              : null,
                                                      isConnectedBelow: index +
                                                                  1 <
                                                              _groupedSets
                                                                  .length &&
                                                          entry.value.first
                                                                  .supersetGroup !=
                                                              null &&
                                                          entry.value.first
                                                                  .supersetGroup ==
                                                              _groupedSets
                                                                  .entries
                                                                  .elementAt(
                                                                      index + 1)
                                                                  .value
                                                                  .first
                                                                  .supersetGroup,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          // Add Exercise (Edit Mode)
                          if (_isEditMode)
                            Padding(
                              padding: const EdgeInsets.all(
                                  DesignConstants.spacingL),
                              child: MorphSourceScope(
                                builder: (context, setHidden) => Builder(
                                  builder: (btnCtx) {
                                    // Flies with the container, so the catalog
                                    // dissolves out of the button instead of
                                    // being there from the first frame.
                                    late final Widget addButton;
                                    addButton = TextButton.icon(
                                      onPressed: () async {
                                        final selectedExercise =
                                            await Navigator.of(context)
                                                .push<Exercise>(
                                          CardMorphRoute(
                                            sourceContext: btnCtx,
                                            sourceBorderRadius: 14.0,
                                            sourceBuilder: (_) => addButton,
                                            onSourceVisibilityChanged:
                                                setHidden,
                                            builder: (context) =>
                                                const ExerciseCatalogScreen(
                                                    isSelectionMode: true),
                                          ),
                                        );
                                        if (selectedExercise != null) {
                                          setState(() {
                                            final exerciseBlock =
                                                _nextExerciseBlock();
                                            final exerciseName =
                                                selectedExercise
                                                    .getLocalizedName(context);
                                            final key = ExerciseBlockKey(
                                              exerciseBlock: exerciseBlock,
                                              exerciseName: exerciseName,
                                            );
                                            // Store exercise details locally so _isCardio and name work.
                                            _exerciseDetails[key] =
                                                selectedExercise;

                                            final newSet = SetLog(
                                              id: -DateTime.now()
                                                  .millisecondsSinceEpoch,
                                              workoutLogId: _log!.id!,
                                              exerciseName: exerciseName,
                                              setType: 'normal',
                                              isCompleted: true,
                                              exerciseBlock: exerciseBlock,
                                              // Set default values
                                              weightKg: 0,
                                              reps: 0,
                                              distanceKm: 0,
                                              durationSeconds: 0,
                                            );
                                            _groupedSets[key] = [newSet];

                                            _weightControllers[newSet.id!] =
                                                TextEditingController();
                                            _repsControllers[newSet.id!] =
                                                TextEditingController();
                                            _rirControllers[newSet.id!] =
                                                TextEditingController();
                                          });
                                        }
                                      },
                                      icon: const Icon(LucideIcons.plus),
                                      label:
                                          Text(l10n.addExerciseToWorkoutButton),
                                    );
                                    return addButton;
                                  },
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

  Widget _buildMuscleHeatmap(AppLocalizations l10n) {
    final muscleCounts = <BodyPartSlug, int>{};

    for (final key in _groupedSets.keys) {
      final ex = _exerciseDetails[key];
      if (ex == null || ex.isCardio) continue;

      final exerciseSlugs = <BodyPartSlug>{};
      for (final muscleName in ex.primaryMuscles) {
        exerciseSlugs.addAll(BodySlugMapper.fromRawName(muscleName));
      }

      for (final slug in exerciseSlugs) {
        muscleCounts[slug] = (muscleCounts[slug] ?? 0) + 1;
      }
    }

    final highlights = MuscleColorHelper.mapSlugWorkloadToPrimaryColors(
      context,
      muscleCounts.map((k, v) => MapEntry(k, v.toDouble())),
    );

    if (highlights.isEmpty) return const SizedBox.shrink();

    return DualBodyHighlighter(
      gender: context.watch<ProfileService>().gender.toBodyGender(),
      frontHighlights: BodySlugMapper.forSide(highlights, BodySide.front),
      backHighlights: BodySlugMapper.forSide(highlights, BodySide.back),
    );
  }

  void _changeSetType(int setLogId, String newType) {
    setState(() {
      for (var entry in _groupedSets.entries) {
        for (var setLog in entry.value) {
          if (setLog.id == setLogId) {
            final index = entry.value.indexOf(setLog);
            entry.value[index] = setLog.copyWith(setType: newType);
            break;
          }
        }
      }
    });
  }

  void _showSetTypePicker(int setLogId) {
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
          onTap: () => _changeSetType(setLogId, opt['type'] as String),
        );
      }).toList(),
    );
  }
}
