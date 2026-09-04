import "../../../services/unit_service.dart";

import 'models/set_log.dart';
import 'classification/exercise_log_mask.dart';
import 'classification/set_load.dart';

class PRDetectionResult {
  final SetLog updatedSetLog;
  final List<PRAlert> alerts;

  PRDetectionResult(this.updatedSetLog, this.alerts);
}

class PRAlert {
  final String exerciseName;
  final String recordType;
  final String achievementValue;
  final double? diff;

  PRAlert({
    required this.exerciseName,
    required this.recordType,
    required this.achievementValue,
    this.diff,
  });
}

class DetectPersonalRecordUseCase {
  PRDetectionResult execute({
    required SetLog currentSet,
    required Map<String, double> historicalBests,
    required UnitService unitService,
    ExerciseLogMask? mask,
    double? bodyweightKg,
  }) {
    final currentWeight = currentSet.weightKg ?? 0.0;

    // The historical bests this is compared against are computed from the
    // effective load, so this side has to be too — otherwise a body-weight
    // exercise reads as a permanent personal record and an assisted one never
    // reaches its own history.
    final effectiveMask = mask ?? ExerciseLogMask.weightAndReps;
    final currentVolume = setTonnageKg(
      trackingType: effectiveMask.trackingType,
      loadMode: effectiveMask.loadMode,
      loggedWeightKg: currentSet.weightKg,
      reps: currentSet.reps,
      bodyweightKg: bodyweightKg,
    );

    final currentEst1rm = effectiveMask.estimatedOneRepMax(
          loggedWeightKg: currentSet.weightKg,
          reps: currentSet.reps,
          bodyweightKg: bodyweightKg,
        ) ??
        0.0;

    final currentDistance = currentSet.distanceKm ?? 0.0;
    final currentDuration = currentSet.durationSeconds ?? 0;
    double currentPace = double.infinity;
    if (currentDistance > 0 && currentDuration > 0) {
      currentPace = currentDuration / currentDistance;
    }

    bool isMaxWeightPR = false;
    bool isMaxVolumePR = false;
    bool isMaxEst1RMPR = false;

    bool isMaxDistancePR = false;
    bool isMaxDurationPR = false;
    bool isFastestPacePR = false;

    double? weightDiff;
    double? volumeDiff;
    double? est1rmDiff;

    double? distanceDiff;
    int? durationDiff;
    double? paceDiff;

    // Weight, volume and estimated 1RM are three different questions, and each
    // has to be asked on its own terms.
    //
    // All three used to sit behind `currentWeight > 0` — did the user type a
    // number into the weight column. That is the wrong gate twice over. A
    // pull-up at body weight leaves the column empty, so it could never set a
    // record of any kind however many reps it gained; and on an assistance
    // machine the number *is* there but means its opposite, so the easiest set
    // of the session read as a weight record.
    //
    // Volume and e1RM already know what a set was worth, because they are
    // computed from the effective load. They only needed to be let out.
    if (currentWeight > 0 && effectiveMask.weightMeansResistance) {
      final oldMaxWeight = historicalBests['maxWeight'] ?? 0.0;
      if (currentWeight > oldMaxWeight) {
        if (oldMaxWeight > 0) {
          isMaxWeightPR = true;
          weightDiff = currentWeight - oldMaxWeight;
        }
        historicalBests['maxWeight'] = currentWeight; // Updating local map
      }
    }

    if (currentVolume > 0) {
      final oldMaxVolume = historicalBests['maxVolume'] ?? 0.0;
      if (currentVolume > oldMaxVolume) {
        if (oldMaxVolume > 0) {
          isMaxVolumePR = true;
          volumeDiff = currentVolume - oldMaxVolume;
        }
        historicalBests['maxVolume'] = currentVolume;
      }
    }

    if (currentEst1rm > 0) {
      final oldMaxEst1rm = historicalBests['maxEst1rm'] ?? 0.0;
      if (currentEst1rm > oldMaxEst1rm) {
        if (oldMaxEst1rm > 0) {
          isMaxEst1RMPR = true;
          est1rmDiff = currentEst1rm - oldMaxEst1rm;
        }
        historicalBests['maxEst1rm'] = currentEst1rm;
      }
    }

    if (currentDistance > 0 || currentDuration > 0) {
      final oldMaxDistance = historicalBests['maxDistance'] ?? 0.0;
      if (currentDistance > oldMaxDistance) {
        if (oldMaxDistance > 0) {
          isMaxDistancePR = true;
          distanceDiff = currentDistance - oldMaxDistance;
        }
        historicalBests['maxDistance'] = currentDistance;
      }

      final oldMaxDuration = historicalBests['maxDuration']?.toInt() ?? 0;
      if (currentDuration > oldMaxDuration) {
        if (oldMaxDuration > 0) {
          isMaxDurationPR = true;
          durationDiff = currentDuration - oldMaxDuration;
        }
        historicalBests['maxDuration'] = currentDuration.toDouble();
      }

      final oldFastestPace = historicalBests['fastestPace'] ?? 0.0;
      if (currentPace != double.infinity &&
          (oldFastestPace == 0.0 || currentPace < oldFastestPace)) {
        if (oldFastestPace > 0) {
          isFastestPacePR = true;
          paceDiff = oldFastestPace - currentPace;
        }
        historicalBests['fastestPace'] = currentPace;
      }
    }

    final alerts = <PRAlert>[];

    if (isMaxWeightPR || isMaxVolumePR || isMaxEst1RMPR) {
      if (isMaxWeightPR) {
        alerts.add(PRAlert(
          exerciseName: currentSet.exerciseName,
          recordType: "Best Max Weight",
          achievementValue:
              "${unitService.convertDisplayValue(currentWeight, UnitDimension.weight).toStringAsFixed(1).replaceAll('.0', '')} ${unitService.suffixFor(UnitDimension.weight)}",
          diff: weightDiff,
        ));
      }
      if (isMaxVolumePR) {
        alerts.add(PRAlert(
          exerciseName: currentSet.exerciseName,
          recordType: "Best Volume Set",
          achievementValue:
              "${unitService.convertDisplayValue(currentVolume, UnitDimension.weight).toStringAsFixed(1).replaceAll('.0', '')} ${unitService.suffixFor(UnitDimension.weight)}",
          diff: volumeDiff,
        ));
      }
      if (isMaxEst1RMPR) {
        alerts.add(PRAlert(
          exerciseName: currentSet.exerciseName,
          recordType: "Best 1-Rep Max",
          achievementValue:
              "${unitService.convertDisplayValue(currentEst1rm, UnitDimension.weight).toStringAsFixed(1).replaceAll('.0', '')} ${unitService.suffixFor(UnitDimension.weight)}",
          diff: est1rmDiff,
        ));
      }
    }

    if (isMaxDistancePR || isMaxDurationPR || isFastestPacePR) {
      if (isMaxDistancePR) {
        alerts.add(PRAlert(
          exerciseName: currentSet.exerciseName,
          recordType: "Best Distance",
          achievementValue:
              "${unitService.convertDisplayValue(currentDistance, UnitDimension.distance).toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '')} ${unitService.suffixFor(UnitDimension.distance)}",
          diff: distanceDiff,
        ));
      }
      if (isMaxDurationPR) {
        final m = currentDuration ~/ 60;
        final s = currentDuration % 60;
        alerts.add(PRAlert(
          exerciseName: currentSet.exerciseName,
          recordType: "Longest Duration",
          achievementValue: "${m}m ${s}s",
          diff: durationDiff?.toDouble(),
        ));
      }
      if (isFastestPacePR) {
        final pm = currentPace.toInt() ~/ 60;
        final ps = currentPace.toInt() % 60;
        alerts.add(PRAlert(
          exerciseName: currentSet.exerciseName,
          recordType: "Fastest Pace",
          achievementValue: "${pm}m ${ps}s / km",
          diff: paceDiff,
        ));
      }
    }

    final updatedLog = currentSet.copyWith(
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

    return PRDetectionResult(updatedLog, alerts);
  }
}
