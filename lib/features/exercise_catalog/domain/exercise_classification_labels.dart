// lib/features/exercise_catalog/domain/exercise_classification_labels.dart
import 'package:flutter/widgets.dart';

import '../../../generated/app_localizations.dart';

/// Readable names for the catalog's classification vocabularies.
///
/// Three closed sets of eight identifiers in total, which is why they are
/// translated rather than prettified from the identifier the way usage tags
/// are: `isolation` happens to read as a word in English and as nothing at all
/// in Japanese, and these labels sit on the exercise detail screen where every
/// other line is in the user's language.
///
/// Every method returns null for an unknown or absent value. That is the
/// common case, not an error: 32 catalog rows carry no classification, and
/// user-created exercises never will. A null means "draw nothing here".
abstract final class ExerciseClassificationLabels {
  /// `compound` | `isolation`.
  static String? mechanic(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'compound':
        return l10n.exerciseMechanicCompound;
      case 'isolation':
        return l10n.exerciseMechanicIsolation;
    }
    return null;
  }

  /// `bilateral` | `unilateral` | `alternating`.
  static String? laterality(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'bilateral':
        return l10n.exerciseLateralityBilateral;
      case 'unilateral':
        return l10n.exerciseLateralityUnilateral;
      case 'alternating':
        return l10n.exerciseLateralityAlternating;
    }
    return null;
  }

  /// `push` | `pull` | `static`.
  ///
  /// Derived upstream from [movementPattern], and null for the patterns that
  /// are honestly neither — 266 of the catalog's 909 rows.
  static String? forceVector(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'push':
        return l10n.exerciseForcePush;
      case 'pull':
        return l10n.exerciseForcePull;
      case 'static':
        return l10n.exerciseForceStatic;
    }
    return null;
  }

  /// One of the catalog's 31 movement patterns.
  ///
  /// `other` returns null on purpose. It is the vocabulary's own admission
  /// that it has no better answer for 76 exercises, and a chip reading
  /// "Other" tells the reader nothing they did not already know.
  static String? movementPattern(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'horizontal_push':
        return l10n.exercisePatternHorizontalPush;
      case 'horizontal_pull':
        return l10n.exercisePatternHorizontalPull;
      case 'vertical_push':
        return l10n.exercisePatternVerticalPush;
      case 'vertical_pull':
        return l10n.exercisePatternVerticalPull;
      case 'squat':
        return l10n.exercisePatternSquat;
      case 'hinge':
        return l10n.exercisePatternHinge;
      case 'lunge':
        return l10n.exercisePatternLunge;
      case 'gait':
        return l10n.exercisePatternGait;
      case 'carry':
        return l10n.exercisePatternCarry;
      case 'rotation':
        return l10n.exercisePatternRotation;
      case 'anti_rotation':
        return l10n.exercisePatternAntiRotation;
      case 'anti_extension':
        return l10n.exercisePatternAntiExtension;
      case 'anti_flexion':
        return l10n.exercisePatternAntiFlexion;
      case 'anti_lateral_flexion':
        return l10n.exercisePatternAntiLateralFlexion;
      case 'spinal_flexion':
        return l10n.exercisePatternSpinalFlexion;
      case 'spinal_extension':
        return l10n.exercisePatternSpinalExtension;
      case 'elbow_flexion':
        return l10n.exercisePatternElbowFlexion;
      case 'elbow_extension':
        return l10n.exercisePatternElbowExtension;
      case 'shoulder_flexion':
        return l10n.exercisePatternShoulderFlexion;
      case 'shoulder_abduction':
        return l10n.exercisePatternShoulderAbduction;
      case 'scapular_elevation':
        return l10n.exercisePatternScapularElevation;
      case 'hip_extension':
        return l10n.exercisePatternHipExtension;
      case 'hip_abduction':
        return l10n.exercisePatternHipAbduction;
      case 'hip_adduction':
        return l10n.exercisePatternHipAdduction;
      case 'knee_flexion':
        return l10n.exercisePatternKneeFlexion;
      case 'knee_extension':
        return l10n.exercisePatternKneeExtension;
      case 'plantar_flexion':
        return l10n.exercisePatternPlantarFlexion;
      case 'dorsiflexion':
        return l10n.exercisePatternDorsiflexion;
      case 'wrist_flexion':
        return l10n.exercisePatternWristFlexion;
      case 'wrist_extension':
        return l10n.exercisePatternWristExtension;
    }
    return null;
  }

  /// `warmup` | `activation` | `main_lift` | `accessory` | `conditioning` |
  /// `finisher` | `cooldown` | `prehab`.
  ///
  /// The catalog ships these as identifiers with no translation table of their
  /// own, the way it has one for muscles and equipment. They were rendered by
  /// title-casing the identifier, which left a German filter menu reading
  /// "Accessory" and "Main Lift".
  static String? usageTag(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'warmup':
        return l10n.exerciseUsageWarmup;
      case 'activation':
        return l10n.exerciseUsageActivation;
      case 'main_lift':
        return l10n.exerciseUsageMainLift;
      case 'accessory':
        return l10n.exerciseUsageAccessory;
      case 'conditioning':
        return l10n.exerciseUsageConditioning;
      case 'finisher':
        return l10n.exerciseUsageFinisher;
      case 'cooldown':
        return l10n.exerciseUsageCooldown;
      case 'prehab':
        return l10n.exerciseUsagePrehab;
    }
    return null;
  }

  /// `beginner` | `intermediate` | `advanced`.
  static String? difficulty(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'beginner':
        return l10n.exerciseDifficultyBeginner;
      case 'intermediate':
        return l10n.exerciseDifficultyIntermediate;
      case 'advanced':
        return l10n.exerciseDifficultyAdvanced;
    }
    return null;
  }
}
