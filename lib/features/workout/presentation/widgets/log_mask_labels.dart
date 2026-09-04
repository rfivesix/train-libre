import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/time_util.dart';
import '../../domain/classification/exercise_log_mask.dart';
import '../../domain/models/set_log.dart';

/// Column headings and the "last time" cell, following the same mask as the
/// input fields.
///
/// They did not, which is how a plank ended up with a column headed "Reps" and
/// a history reading "0kg × 0". The fields were wired to the mask and the
/// labels above and beside them were not — the same half-landing as when the
/// mask existed only in the model.
///
/// Kept out of the widgets so the strings can be asserted directly, without
/// pumping a live workout.
class LogMaskLabels {
  const LogMaskLabels._();

  /// Heading for the left input column, or null when there is no such column.
  static String? primaryHeader(
    ExerciseLogMask mask,
    AppLocalizations l10n,
    UnitService unitService,
  ) {
    final weightSuffix = unitService.suffixFor(UnitDimension.weight);
    switch (mask.primary) {
      case LogField.weight:
        return weightSuffix;
      // The sign carries the meaning: `+` is on top of body weight, `−` is
      // taken off it. Losing that distinction is what made the assisted e1RM
      // run backwards in the first place.
      case LogField.addedWeight:
        return '+$weightSuffix';
      case LogField.assistance:
        return '−$weightSuffix';
      case LogField.distance:
        return l10n.cardioDistanceLabel(
          unitService.suffixFor(UnitDimension.distance),
        );
      case LogField.reps:
      case LogField.duration:
      case LogField.none:
        return null;
    }
  }

  /// Heading for the right input column, or null when there is no such column.
  static String? secondaryHeader(ExerciseLogMask mask, AppLocalizations l10n) {
    switch (mask.secondary) {
      case LogField.reps:
        return l10n.repsLabel;
      case LogField.duration:
        return l10n.cardioTimeLabel;
      default:
        return null;
    }
  }

  /// The "last time" cell for [setLog], or `-` when there was no last time.
  ///
  /// Shaped by the mask, so a timed exercise reads "02:00" rather than
  /// "0kg × 0" and a body-weight set with nothing added reads "10 Wdh" rather
  /// than claiming zero kilograms.
  static String lastPerformance(
    ExerciseLogMask mask,
    SetLog? setLog,
    AppLocalizations l10n,
    UnitService unitService,
  ) {
    if (setLog == null) return '-';

    String weight(double kg) => unitService
        .convertDisplayValue(kg, UnitDimension.weight)
        .toStringAsFixed(1)
        .replaceAll('.0', '');
    final weightSuffix = unitService.suffixFor(UnitDimension.weight);

    final parts = <String>[];

    switch (mask.primary) {
      case LogField.weight:
        final kg = setLog.weightKg;
        if (kg != null && kg > 0) {
          parts.add('${weight(kg)} $weightSuffix');
        }
      case LogField.addedWeight:
        final kg = setLog.weightKg;
        // Nothing added is not zero added: the set happened, it just happened
        // at body weight. Omitting the term says that; "+0 kg" would not.
        if (kg != null && kg > 0) {
          parts.add('+${weight(kg)} $weightSuffix');
        }
      case LogField.assistance:
        final kg = setLog.weightKg;
        if (kg != null && kg > 0) {
          parts.add('−${weight(kg)} $weightSuffix');
        }
      case LogField.distance:
        final km = setLog.distanceKm;
        if (km != null && km > 0) {
          final value = unitService.convertDisplayValue(
            km,
            UnitDimension.distance,
          );
          parts.add(
            '${value.toStringAsFixed(1)} '
            '${unitService.suffixFor(UnitDimension.distance)}',
          );
        }
      case LogField.reps:
      case LogField.duration:
      case LogField.none:
        break;
    }

    switch (mask.secondary) {
      case LogField.reps:
        final reps = setLog.reps;
        if (reps != null && reps > 0) {
          // "70 kg × 6" when there is a weight beside it, "10 Wdh" when there
          // is not — a bare "6" would say nothing.
          parts.add(parts.isEmpty ? '$reps ${l10n.repsLabel}' : '$reps');
        }
      case LogField.duration:
        final seconds = setLog.durationSeconds;
        if (seconds != null && seconds > 0) {
          parts.add(formatPauseDuration(seconds));
        }
      default:
        break;
    }

    if (parts.isEmpty) return '-';
    if (parts.length == 1) return parts.first;

    // "70 kg × 6" for a lift, "5.0 km · 28:14" for a run: the multiplication
    // sign only makes sense where the two numbers actually multiply.
    final joiner = mask.logsReps && mask.logsWeight ? ' × ' : ' · ';
    return parts.join(joiner);
  }
}
