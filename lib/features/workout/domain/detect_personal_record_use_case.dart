import 'models/set_log.dart';

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
  }) {
    final currentWeight = currentSet.weightKg ?? 0.0;
    final currentReps = currentSet.reps ?? 0;
    final currentVolume = currentWeight * currentReps;

    double currentEst1rm = 0.0;
    if (currentReps > 0 && currentReps <= 10) {
      currentEst1rm = currentWeight * (36 / (37 - currentReps));
    }

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

    if (currentWeight > 0) {
      final oldMaxWeight = historicalBests['maxWeight'] ?? 0.0;
      if (currentWeight > oldMaxWeight) {
        isMaxWeightPR = true;
        weightDiff = oldMaxWeight > 0 ? currentWeight - oldMaxWeight : null;
        historicalBests['maxWeight'] = currentWeight; // Updating local map
      }

      final oldMaxVolume = historicalBests['maxVolume'] ?? 0.0;
      if (currentVolume > oldMaxVolume) {
        isMaxVolumePR = true;
        volumeDiff = oldMaxVolume > 0 ? currentVolume - oldMaxVolume : null;
        historicalBests['maxVolume'] = currentVolume;
      }

      final oldMaxEst1rm = historicalBests['maxEst1rm'] ?? 0.0;
      if (currentEst1rm > oldMaxEst1rm) {
        isMaxEst1RMPR = true;
        est1rmDiff = oldMaxEst1rm > 0 ? currentEst1rm - oldMaxEst1rm : null;
        historicalBests['maxEst1rm'] = currentEst1rm;
      }
    }

    if (currentDistance > 0 || currentDuration > 0) {
      final oldMaxDistance = historicalBests['maxDistance'] ?? 0.0;
      if (currentDistance > oldMaxDistance) {
        isMaxDistancePR = true;
        distanceDiff =
            oldMaxDistance > 0 ? currentDistance - oldMaxDistance : null;
        historicalBests['maxDistance'] = currentDistance;
      }

      final oldMaxDuration = historicalBests['maxDuration']?.toInt() ?? 0;
      if (currentDuration > oldMaxDuration) {
        isMaxDurationPR = true;
        durationDiff =
            oldMaxDuration > 0 ? currentDuration - oldMaxDuration : null;
        historicalBests['maxDuration'] = currentDuration.toDouble();
      }

      final oldFastestPace = historicalBests['fastestPace'] ?? 0.0;
      if (currentPace != double.infinity &&
          (oldFastestPace == 0.0 || currentPace < oldFastestPace)) {
        isFastestPacePR = true;
        paceDiff = oldFastestPace > 0 ? oldFastestPace - currentPace : null;
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
              "${currentWeight.toStringAsFixed(1).replaceAll('.0', '')} kg",
          diff: weightDiff,
        ));
      }
      if (isMaxVolumePR) {
        alerts.add(PRAlert(
          exerciseName: currentSet.exerciseName,
          recordType: "Best Volume Set",
          achievementValue: "${currentVolume.toStringAsFixed(0)} kg",
          diff: volumeDiff,
        ));
      }
      if (isMaxEst1RMPR) {
        alerts.add(PRAlert(
          exerciseName: currentSet.exerciseName,
          recordType: "Best 1-Rep Max",
          achievementValue:
              "${currentEst1rm.toStringAsFixed(1).replaceAll('.0', '')} kg",
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
              "${currentDistance.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '')} km",
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
