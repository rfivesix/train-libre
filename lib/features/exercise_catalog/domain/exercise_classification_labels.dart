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
