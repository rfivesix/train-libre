import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../domain/models/set_log.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../util/time_util.dart';
import '../../../../widgets/common/platform_adaptive_pickers.dart' as adaptive_pickers;
import '../../../../util/design_constants.dart';

/// A single row representing a set within an exercise log.
/// Supports both view mode and edit mode (via nullable text controllers).
class WorkoutLogSetRow extends StatelessWidget {
  final SetLog setLog;
  final int rowIndex;
  final int workingSetIndex;
  final String exerciseName;
  final bool isEditMode;
  final bool isCardio;
  final TextEditingController? weightController;
  final TextEditingController? repsController;
  final TextEditingController? rirController;
  final VoidCallback onDelete;
  final VoidCallback onSetTypeTap;

  const WorkoutLogSetRow({
    super.key,
    required this.setLog,
    required this.rowIndex,
    required this.workingSetIndex,
    required this.exerciseName,
    required this.isEditMode,
    required this.isCardio,
    this.weightController,
    this.repsController,
    this.rirController,
    required this.onDelete,
    required this.onSetTypeTap,
  });

  @override
  Widget build(BuildContext context) {
    final setType = setLog.setType;
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final bool isColoredRow = rowIndex > 0 && rowIndex.isOdd;
    final Color rowColor = isColoredRow
        ? (isLightMode
            ? Colors.grey.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.1))
        : Colors.transparent;
    final unitService = context.read<UnitService>();

    // View Values
    String val1Display, val2Display;
    if (isCardio) {
      val1Display = setLog.distanceKm == null
          ? '-'
          : setLog.distanceKm!
              .toStringAsFixed(3)
              .replaceAll(RegExp(r'0*$'), '')
              .replaceAll(RegExp(r'\.$'), '');
      final sec = setLog.durationSeconds ?? 0;
      val2Display = sec > 0 ? formatPauseDuration(sec) : '-';
    } else {
      val1Display = setLog.weightKg == null
          ? '-'
          : unitService.formatDisplayWeight(setLog.weightKg!);
      val2Display = setLog.reps?.toString() ?? '-';
    }

    final currentSetE1rm = _calculateBrzyckiE1rm(setLog);
    final showCurrentSetE1rm = !isCardio && currentSetE1rm != null;
    final bool hasPR = setLog.isMaxWeightPR ||
        setLog.isMaxVolumePR ||
        setLog.isMaxEst1RMPR ||
        setLog.isMaxDistancePR ||
        setLog.isMaxDurationPR ||
        setLog.isFastestPacePR;

    final rowContent = Row(
      children: [
        // 1. SET NUMBER
        Expanded(
          flex: 2,
          child: Center(
            child: GestureDetector(
              onTap: () {
                if (isEditMode) onSetTypeTap();
              },
              child: Text(
                _getSetDisplayText(setType, workingSetIndex),
                style: TextStyle(
                  color: _getSetTypeColor(setType),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // 2. INPUT 1: WEIGHT / DISTANCE
        Expanded(
          flex: isCardio ? 4 : 2,
          child: isEditMode
              ? TextFormField(
                  controller: weightController,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: "-",
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Text(
                  val1Display,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(width: 8),

        // 3. INPUT 2: REPS / TIME
        Expanded(
          flex: isCardio ? 4 : 2,
          child: isEditMode
              ? TextFormField(
                  controller: repsController,
                  readOnly: isCardio,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: isCardio ? [TimerInputFormatter()] : null,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: isCardio ? "00:00" : "-",
                  ),
                  onTap: isCardio
                      ? () async {
                          final currentSeconds =
                              parsePauseDuration(repsController?.text ?? "") ??
                                  0;
                          final newDuration =
                              await adaptive_pickers.showAdaptiveDurationPicker(
                            context: context,
                            initialDuration: Duration(seconds: currentSeconds),
                          );
                          if (newDuration != null) {
                            final seconds = newDuration.inSeconds;
                            repsController?.text =
                                seconds > 0 ? formatPauseDuration(seconds) : "";
                          }
                        }
                      : null,
                )
              : Text(
                  val2Display,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(width: 8),

        // 4. INPUT 3: RIR / INTENSITY
        Expanded(
          flex: 2,
          child: isEditMode
              ? TextFormField(
                  controller: rirController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: "-",
                  ),
                )
              : Text(
                  setLog.rir?.toString() ?? '-',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
        ),

        // 5. CHECKBOX / DELETE
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: SizedBox(
            width: 48,
            child: isEditMode
                ? IconButton(
                    icon: const Icon(
                      LucideIcons.trash_2,
                      color: DesignConstants.brandRedColor,
                    ),
                    onPressed: onDelete,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );

    return Container(
      color: rowColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: rowContent,
          ),
          if (showCurrentSetE1rm || hasPR)
            Padding(
              padding: const EdgeInsets.only(right: 12.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasPR) ...[
                    _buildPRBadge(context, setLog),
                    if (showCurrentSetE1rm) const SizedBox(width: 8),
                  ],
                  if (showCurrentSetE1rm)
                    Text(
                      '${unitService.formatDisplayWeight(currentSetE1rm)} ${unitService.suffixFor(UnitDimension.weight)}',
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
      ),
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

  bool _isQualifyingSetForE1rm(SetLog setLog) {
    final reps = setLog.reps;
    final weight = setLog.weightKg;
    final isWarmup = setLog.setType == 'warmup';
    final isCompleted = setLog.isCompleted == true;

    if (isWarmup) return false;
    if (!isCompleted) return false;
    if (weight == null || weight <= 0) return false;
    if (reps == null || reps <= 0 || reps > 10) return false;

    return true;
  }

  double? _calculateBrzyckiE1rm(SetLog setLog) {
    if (!_isQualifyingSetForE1rm(setLog)) {
      return null;
    }

    final reps = setLog.reps!;
    final weight = setLog.weightKg!;
    return weight * (36 / (37 - reps));
  }

  Widget _buildPRBadge(BuildContext context, SetLog setLog) {
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
          "+${setLog.volumePRDiff!.toStringAsFixed(0)} ${unitService.suffixFor(UnitDimension.weight)} (Vol)";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.trophy,
            color: Colors.amber,
            size: 14,
          ),
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
    );
  }
}
