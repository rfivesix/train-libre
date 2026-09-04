import '../../../../widgets/common/platform_adaptive_pickers.dart'
    as adaptive_pickers;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/haptic_feedback_service.dart';
import '../../../../services/unit_service.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../domain/classification/exercise_log_mask.dart';
import 'log_mask_labels.dart';
import '../../domain/models/set_log.dart';
import '../../domain/models/set_template.dart';
import '../live_workout_view_model.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../util/time_util.dart';
import '../../../../util/design_constants.dart';

/// An interactive row representing a single set in an active workout session.
///
/// Supports text fields for weight/distance, reps/time, RIR/intensity, type selections,
/// personal record tags, last session copy shortcuts, and swipe-to-delete actions.
class LiveWorkoutSetRow extends StatelessWidget {
  final int setIndex;
  final int rowIndex;
  final int templateId;
  final SetLog setLog;
  final List<SetLog> lastPerfSets;
  final SetTemplate template;
  final LiveWorkoutViewModel manager;

  /// Which two inputs this row shows, and what they mean. Replaces the single
  /// `isCardio` flag, which could only say "distance and time" or "weight and
  /// reps" and had no way to express a plank or a pull-up.
  final ExerciseLogMask mask;

  /// The user's current body weight, when recorded. See
  /// [WorkoutLogSetRow.bodyweightKg].
  final double? bodyweightKg;

  const LiveWorkoutSetRow({
    super.key,
    required this.setIndex,
    required this.rowIndex,
    required this.templateId,
    required this.setLog,
    required this.lastPerfSets,
    required this.template,
    required this.manager,
    required this.mask,
    this.bodyweightKg,
  });

  /// True where the old flag was: the row logs a distance and a duration.
  bool get isCardio => mask.logsDistance && mask.logsDuration;

  /// Column widths, shared with the heading above the row.
  SetRowFlex get flex => SetRowFlex.forMask(mask);

  void _removeSet(int templateId) {
    manager.removeSet(templateId);
  }

  void _changeSetType(int templateId, String newType) {
    manager.updateSet(templateId, setType: newType);
  }

  void _showSetTypePicker(BuildContext context, int templateId) {
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
        'symbol': buildSymbol('N', Colors.grey),
      },
      {
        'type': 'warmup',
        'label': l10n.set_type_warmup,
        'symbol': buildSymbol('W', Colors.orange),
      },
      {
        'type': 'failure',
        'label': l10n.set_type_failure,
        'symbol': buildSymbol('F', DesignConstants.brandRedColor),
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
          onTap: () => _changeSetType(templateId, opt['type'] as String),
        );
      }).toList(),
    );
  }

  String _getSetDisplayText(String setType, int setIndex) {
    switch (setType) {
      case 'warmup':
        return 'W';
      case 'failure':
        return 'F';
      case 'dropset':
        return 'D';
      default:
        return '$setIndex';
    }
  }

  Color _getSetTypeColor(String setType) {
    switch (setType) {
      case 'warmup':
        return Colors.orange;
      case 'dropset':
        return Colors.blue;
      case 'failure':
        return DesignConstants.brandRedColor;
      default:
        return Colors.grey;
    }
  }

  bool _isQualifyingSetForE1rm(
    SetLog setLog, {
    required bool requireCompleted,
  }) {
    final reps = setLog.reps;
    final weight = setLog.weightKg;
    final isWarmup = setLog.setType == 'warmup';
    final isCompleted = setLog.isCompleted == true;

    if (isWarmup) return false;
    if (requireCompleted && !isCompleted) return false;
    // A positive *effective* load, not a positive typed number: a pull-up
    // has no weight in the column and still lifts the user.
    final load = mask.effectiveLoadKg(weight, bodyweightKg);
    if (load == null || load <= 0) return false;
    if (reps == null || reps <= 0 || reps > 10) return false;

    return true;
  }

  double? _calculateBrzyckiE1rm(
    SetLog setLog, {
    required bool requireCompleted,
  }) {
    if (!_isQualifyingSetForE1rm(setLog, requireCompleted: requireCompleted)) {
      return null;
    }

    return mask.estimatedOneRepMax(
      loggedWeightKg: setLog.weightKg,
      reps: setLog.reps,
      bodyweightKg: bodyweightKg,
    );
  }

  Widget _buildPRBadge(SetLog setLog, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.read<UnitService>();
    String label = l10n.newPersonalRecordLabel;

    if (setLog.isMaxWeightPR && setLog.weightPRDiff != null) {
      label =
          "+${unitService.formatDisplayWeight(setLog.weightPRDiff!)} ${unitService.suffixFor(UnitDimension.weight)}";
    } else if (setLog.isMaxEst1RMPR && setLog.est1rmPRDiff != null) {
      label =
          "+${unitService.formatDisplayWeight(setLog.est1rmPRDiff!)} ${unitService.suffixFor(UnitDimension.weight)} (1RM)";
    } else if (setLog.isMaxVolumePR && setLog.volumePRDiff != null) {
      label =
          "+${unitService.formatDisplayWeight(setLog.volumePRDiff!, fractionDigits: 0)} ${unitService.suffixFor(UnitDimension.weight)} (Vol)";
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Tooltip(
        message: l10n.prBadgeTooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.trophy, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final log = context.select<LiveWorkoutViewModel, SetLog?>(
          (vm) => vm.setLogs[templateId],
        ) ??
        setLog;
    final bool isCompleted = log.isCompleted ?? false;
    final unitService = context.read<UnitService>();
    final showsIntensity = showsIntensityColumn(context, mask);

    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final Color? textColor =
        isCompleted ? (isLightMode ? Colors.black : Colors.white) : null;
    final bool isColoredRow = rowIndex > 0 && rowIndex.isOdd;
    final Color rowColor = isColoredRow
        ? (isLightMode
            ? Colors.grey.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.1))
        : Colors.transparent;

    // Hint Logic
    String weightHint = '0';
    String repHint = '0';
    final String rirHint = isCompleted
        ? '-'
        : (template.targetRir != null ? template.targetRir.toString() : '-');

    final double tWeight = template.targetWeight ?? 0.0;
    weightHint = switch (mask.primary) {
      LogField.distance => '-',
      // An added-weight column starts empty, not at zero: empty means "just
      // me", and the set still counts with the user's full body weight. A
      // zero would claim the pull-up moved nothing.
      LogField.addedWeight => '+0',
      LogField.assistance => '-0',
      _ => tWeight > 0
          ? unitService
              .convertDisplayValue(tWeight, UnitDimension.weight)
              .toStringAsFixed(1)
              .replaceAll('.0', '')
          : '0',
    };
    repHint = mask.logsDuration
        ? '00:00'
        : ((template.targetReps?.isNotEmpty == true)
            ? template.targetReps!
            : '0');

    final rowContent = Row(
      children: [
        // 1. SET NUMBER
        Expanded(
          flex: flex.index,
          child: Center(
            child: GestureDetector(
              onTap: () =>
                  isCompleted ? null : _showSetTypePicker(context, templateId),
              child: Text(
                _getSetDisplayText(log.setType, setIndex),
                style: TextStyle(
                  color: isCompleted
                      ? (log.setType == 'normal'
                          ? (isLightMode ? Colors.black : Colors.white)
                          : _getSetTypeColor(log.setType))
                      : _getSetTypeColor(log.setType),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // 2. LAST PERFORMANCE (tap to apply)
        Expanded(
          flex: flex.lastTime,
          child: GestureDetector(
            onTap: (!isCompleted && rowIndex < lastPerfSets.length)
                ? () {
                    final lastSet = lastPerfSets[rowIndex];
                    double? metricWeight;
                    double? distance;
                    int? reps;
                    int? duration;

                    // Copies whatever this exercise actually logs. The
                    // cell now shows a duration for a plank, so tapping
                    // it has to apply one rather than a weight the row
                    // never had.
                    if (mask.logsDistance) {
                      if (lastSet.distanceKm != null) {
                        distance = lastSet.distanceKm;
                        manager.weightControllers[templateId]?.text = lastSet
                            .distanceKm!
                            .toStringAsFixed(3)
                            .replaceAll(RegExp(r'0*$'), '')
                            .replaceAll(RegExp(r'\.$'), '');
                      }
                    } else if (mask.showsPrimary && lastSet.weightKg != null) {
                      final displayWeight = unitService
                          .convertDisplayValue(
                            lastSet.weightKg!,
                            UnitDimension.weight,
                          )
                          .toStringAsFixed(1)
                          .replaceAll('.0', '');
                      manager.weightControllers[templateId]?.text =
                          displayWeight;
                      metricWeight = lastSet.weightKg;
                    }

                    if (mask.logsDuration) {
                      if (lastSet.durationSeconds != null) {
                        duration = lastSet.durationSeconds;
                        manager.repsControllers[templateId]?.text =
                            formatPauseDuration(duration);
                      }
                    } else if (mask.logsReps && lastSet.reps != null) {
                      manager.repsControllers[templateId]?.text =
                          lastSet.reps.toString();
                      reps = lastSet.reps;
                    }

                    // Explicitly propagate and bind to the underlying state model
                    manager.updateSet(
                      templateId,
                      weight: metricWeight,
                      reps: reps,
                      distance: distance,
                      duration: duration,
                    );

                    HapticFeedbackService.instance.selectionFeedback();
                  }
                : null,
            // Shrinks rather than truncates. Widening the column covers the
            // ordinary cardio row, but "12.5 km · 1:02:33" in an imperial
            // locale will outgrow any fixed width, and half a value with an
            // ellipsis after it is worse than the whole value set smaller.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                LogMaskLabels.lastPerformance(
                  mask,
                  rowIndex < lastPerfSets.length
                      ? lastPerfSets[rowIndex]
                      : null,
                  AppLocalizations.of(context)!,
                  unitService,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // 3. INPUT 1: WEIGHT / ADDED WEIGHT / ASSISTANCE / DISTANCE
        Expanded(
          flex: flex.primary,
          child: !mask.showsPrimary
              // A plank has nothing to put here. An empty box invites a
              // number that would mean nothing.
              ? const SizedBox.shrink()
              : TextFormField(
                  controller: manager.weightControllers[templateId],
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: weightHint,
                    hintStyle: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.5),
                      fontSize: 18,
                    ),
                  ),
                  enabled: !isCompleted,
                  onChanged: (text) {
                    final String sanitized = text.replaceAll(',', '.');
                    final double? val;
                    if (sanitized.contains('-')) {
                      final parts = sanitized.split('-');
                      if (parts.length == 2) {
                        final min = double.tryParse(parts[0].trim());
                        final max = double.tryParse(parts[1].trim());
                        if (min != null && max != null) {
                          val = (min + max) / 2;
                        } else {
                          val = null;
                        }
                      } else {
                        val = null;
                      }
                    } else {
                      val = double.tryParse(sanitized);
                    }
                    final clearValue = val == null && text.isEmpty;

                    if (mask.logsDistance) {
                      if (val != manager.setLogs[templateId]?.distanceKm ||
                          clearValue) {
                        manager.updateSet(
                          templateId,
                          distance: val,
                          clearDistance: clearValue,
                        );
                      }
                    } else {
                      final metricValue = val == null
                          ? null
                          : unitService.convertToMetric(
                              val, UnitDimension.weight);
                      if (metricValue !=
                              manager.setLogs[templateId]?.weightKg ||
                          clearValue) {
                        manager.updateSet(
                          templateId,
                          weight: metricValue,
                          clearWeight: clearValue,
                        );
                      }
                    }
                  },
                ),
        ),

        // 4. INPUT 2: REPS / TIME
        Expanded(
          flex: flex.secondary,
          child: !mask.showsSecondary
              ? const SizedBox.shrink()
              : TextFormField(
                  controller: manager.repsControllers[templateId],
                  readOnly: mask.logsDuration,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters:
                      mask.logsDuration ? [TimerInputFormatter()] : null,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: repHint,
                    hintStyle: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.5),
                      fontSize: 18,
                    ),
                  ),
                  enabled: !isCompleted,
                  onTap: (mask.logsDuration && !isCompleted)
                      ? () async {
                          final currentSeconds =
                              manager.setLogs[templateId]?.durationSeconds ?? 0;
                          final newDuration =
                              await adaptive_pickers.showAdaptiveDurationPicker(
                            context: context,
                            initialDuration: Duration(seconds: currentSeconds),
                          );
                          if (newDuration != null) {
                            final seconds = newDuration.inSeconds;
                            final clearDuration = seconds == 0;
                            if (seconds !=
                                    manager
                                        .setLogs[templateId]?.durationSeconds ||
                                clearDuration) {
                              manager.repsControllers[templateId]?.text =
                                  formatPauseDuration(seconds);
                              manager.updateSet(
                                templateId,
                                duration: seconds,
                                clearDuration: clearDuration,
                              );
                            }
                          }
                        }
                      : null,
                  onChanged: (text) {
                    if (mask.logsDuration) {
                      final seconds = parsePauseDuration(text);
                      final clearDuration = seconds == null && text.isEmpty;
                      if (seconds !=
                              manager.setLogs[templateId]?.durationSeconds ||
                          clearDuration) {
                        manager.updateSet(
                          templateId,
                          duration: seconds,
                          clearDuration: clearDuration,
                        );
                      }
                    } else {
                      final int? val;
                      if (text.contains('-')) {
                        final parts = text.split('-');
                        if (parts.length == 2) {
                          final min = int.tryParse(parts[0].trim());
                          final max = int.tryParse(parts[1].trim());
                          if (min != null && max != null) {
                            val = ((min + max) / 2).round();
                          } else {
                            val = null;
                          }
                        } else {
                          val = null;
                        }
                      } else {
                        val = int.tryParse(text);
                      }
                      final clearValue = val == null && text.isEmpty;
                      if (val != manager.setLogs[templateId]?.reps ||
                          clearValue) {
                        manager.updateSet(
                          templateId,
                          reps: val,
                          clearReps: clearValue,
                        );
                      }
                    }
                  },
                ),
        ),

        // 5. INPUT 3: RIR / INTENSITY
        //
        // Absent where there are no reps to hold in reserve — a plank, a dead
        // hang — where the column holds its place for the checkbox below it.
        // Below "pro" it is gone from every card at once, placeholder
        // included, and the fields beside it widen.
        if (showsIntensity || keepsIntensityPlaceholder(context, mask))
          Expanded(
            flex: flex.intensity,
            child: !showsIntensity
                ? const SizedBox.shrink()
                : TextFormField(
                    controller: manager.rirControllers[templateId],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      fillColor: Colors.transparent,
                      hintText: rirHint,
                      hintStyle: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.5),
                        fontSize: 18,
                      ),
                    ),
                    enabled: !isCompleted,
                    onChanged: (text) {
                      final val = int.tryParse(text);
                      final clearValue = val == null && text.isEmpty;
                      if (val != manager.setLogs[templateId]?.rir ||
                          clearValue) {
                        manager.updateSet(templateId,
                            rir: val, clearRir: clearValue);
                      }
                    },
                  ),
          ),

        // 6. CHECKBOX
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                child: IconButton(
                  tooltip: isCompleted ? l10n.undo : l10n.doneButtonLabel,
                  icon: Icon(
                    isCompleted ? LucideIcons.circle_check : LucideIcons.circle,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                  onPressed: () async {
                    if (!isCompleted) {
                      HapticFeedbackService.instance.confirmationFeedback();
                    } else {
                      HapticFeedbackService.instance.selectionFeedback();
                    }
                    // updateSet fills the input fields with the values it
                    // resolved from the template, for every completion path.
                    await manager.updateSet(
                      templateId,
                      isCompleted: !isCompleted,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final currentSetE1rm = _calculateBrzyckiE1rm(log, requireCompleted: false);
    final showCurrentSetE1rm = !isCardio && currentSetE1rm != null;

    final bool hasPR = isCompleted &&
        (log.isMaxWeightPR ||
            log.isMaxVolumePR ||
            log.isMaxEst1RMPR ||
            log.isMaxDistancePR ||
            log.isMaxDurationPR ||
            log.isFastestPacePR);

    final rowWithSubInfo = Column(
      children: [
        rowContent,
        if (showCurrentSetE1rm || hasPR)
          Padding(
            padding: const EdgeInsets.only(right: 12.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasPR) ...[
                  _buildPRBadge(log, context),
                  if (showCurrentSetE1rm) const SizedBox(width: 8),
                ],
                if (showCurrentSetE1rm)
                  Text(
                    l10n.liveWorkoutE1rmCurrentSet(
                      unitService.formatDisplayWeight(currentSetE1rm),
                      unitService.suffixFor(UnitDimension.weight),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );

    return Dismissible(
      key: ValueKey('set_$templateId'),
      direction:
          isCompleted ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) => _removeSet(templateId),
      background: Container(
        color: DesignConstants.brandRedColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(LucideIcons.trash_2, color: Colors.white),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color:
                  isCompleted ? Colors.green.withValues(alpha: 0.3) : rowColor,
            ),
          ),
          rowWithSubInfo,
        ],
      ),
    );
  }
}
