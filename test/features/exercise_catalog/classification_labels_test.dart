import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/exercise_catalog/domain/exercise_classification_labels.dart';
import 'package:train_libre/generated/app_localizations.dart';

/// The catalog's classification vocabularies, in every UI language.
///
/// The failure this guards against is silent: a value the catalog ships but
/// the switch does not name returns null, and the chip simply does not appear
/// — no crash, no analyzer complaint, nothing in a screenshot anyone reviews.
///
/// The value lists here are the catalog's, not the app's. If the data repo
/// adds a fourth difficulty this test fails, which is the point.
const _mechanics = ['compound', 'isolation'];
const _lateralities = ['bilateral', 'unilateral', 'alternating'];
const _difficulties = ['beginner', 'intermediate', 'advanced'];
const _forceVectors = ['push', 'pull', 'static'];

/// Every pattern the shipped catalog carries, minus `other` — which is the
/// vocabulary admitting it has no answer, and draws no chip.
const _movementPatterns = [
  'anti_extension',
  'anti_flexion',
  'anti_lateral_flexion',
  'anti_rotation',
  'carry',
  'dorsiflexion',
  'elbow_extension',
  'elbow_flexion',
  'gait',
  'hinge',
  'hip_abduction',
  'hip_adduction',
  'hip_extension',
  'horizontal_pull',
  'horizontal_push',
  'knee_extension',
  'knee_flexion',
  'lunge',
  'plantar_flexion',
  'rotation',
  'scapular_elevation',
  'shoulder_abduction',
  'shoulder_flexion',
  'spinal_extension',
  'spinal_flexion',
  'squat',
  'vertical_pull',
  'vertical_push',
  'wrist_extension',
  'wrist_flexion',
];

const _usageTags = [
  'warmup',
  'activation',
  'main_lift',
  'accessory',
  'conditioning',
  'finisher',
  'cooldown',
  'prehab',
];

void main() {
  Future<BuildContext> contextFor(WidgetTester tester, String locale) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        home: Builder(builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        }),
      ),
    );
    return captured;
  }

  for (final locale in ['en', 'de', 'fr', 'it', 'ja']) {
    testWidgets('every catalog value has a $locale label', (tester) async {
      final context = await contextFor(tester, locale);

      final labels = <String>[];
      for (final value in _mechanics) {
        final label = ExerciseClassificationLabels.mechanic(context, value);
        expect(label, isNotNull, reason: 'mechanic $value in $locale');
        labels.add(label!);
      }
      for (final value in _lateralities) {
        final label = ExerciseClassificationLabels.laterality(context, value);
        expect(label, isNotNull, reason: 'laterality $value in $locale');
        labels.add(label!);
      }
      for (final value in _difficulties) {
        final label = ExerciseClassificationLabels.difficulty(context, value);
        expect(label, isNotNull, reason: 'difficulty $value in $locale');
        labels.add(label!);
      }
      for (final value in _usageTags) {
        final label = ExerciseClassificationLabels.usageTag(context, value);
        expect(label, isNotNull, reason: 'usage tag $value in $locale');
        labels.add(label!);
      }
      for (final value in _forceVectors) {
        final label = ExerciseClassificationLabels.forceVector(context, value);
        expect(label, isNotNull, reason: 'force vector $value in $locale');
        expect(label!.trim(), isNotEmpty);
      }
      for (final value in _movementPatterns) {
        final label =
            ExerciseClassificationLabels.movementPattern(context, value);
        expect(label, isNotNull, reason: 'movement pattern $value in $locale');
        expect(label!.trim(), isNotEmpty);
      }

      for (final label in labels) {
        expect(label.trim(), isNotEmpty);
      }
      // Two values of one axis reading identically would make the filter
      // offer the same chip twice.
      expect(labels.toSet().length, labels.length,
          reason: 'duplicate labels in $locale: $labels');
    });
  }

  testWidgets('an unset or unknown value draws nothing', (tester) async {
    final context = await contextFor(tester, 'en');
    for (final value in [null, '', 'plyometric', 'BEGINNER']) {
      expect(ExerciseClassificationLabels.mechanic(context, value), isNull);
      expect(ExerciseClassificationLabels.laterality(context, value), isNull);
      expect(ExerciseClassificationLabels.difficulty(context, value), isNull);
      expect(ExerciseClassificationLabels.usageTag(context, value), isNull);
      expect(ExerciseClassificationLabels.forceVector(context, value), isNull);
      expect(
        ExerciseClassificationLabels.movementPattern(context, value),
        isNull,
      );
    }
  });

  testWidgets('"other" is not a chip', (tester) async {
    // 76 catalog rows carry it. It is the vocabulary saying it has no better
    // answer, and printing "Other" would tell the reader nothing.
    final context = await contextFor(tester, 'de');
    expect(
      ExerciseClassificationLabels.movementPattern(context, 'other'),
      isNull,
    );
  });
}
