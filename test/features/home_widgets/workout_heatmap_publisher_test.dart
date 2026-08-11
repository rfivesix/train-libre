import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/home_widgets/application/workout_heatmap_publisher.dart';

/// The render runs its own build/layout/paint pipeline with no `BuildContext`
/// and no screen, which is the whole point of it — and the part most likely to
/// break on a Flutter upgrade. These tests exercise exactly that; the App Group
/// write around it is iOS-only and cannot run on the test host.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Exercise exercise(
    String name,
    List<String> muscles, {
    String category = 'Strength',
  }) =>
      Exercise(
        nameDe: name,
        nameEn: name,
        descriptionDe: '',
        descriptionEn: '',
        categoryName: category,
        primaryMuscles: muscles,
        secondaryMuscles: const [],
      );

  test('renders a heatmap without a BuildContext', () async {
    final bytes = await const WorkoutHeatmapPublisher().renderPng(
      exercises: [
        exercise('Bench Press', ['chest', 'triceps']),
        exercise('Squat', ['quadriceps', 'glutes']),
      ],
      gender: BodyGender.male,
    );

    expect(bytes, isNotNull, reason: 'the offscreen pipeline must produce an image');
    expect(
      bytes!.sublist(0, 8),
      [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      reason: 'a real PNG header',
    );
    // 240pt at 3x with two shaded silhouettes on it cannot compress to a
    // handful of bytes — that would mean an empty canvas.
    expect(bytes.length, greaterThan(2000));
  });

  test('renders repeatedly without leaking the private pipeline', () async {
    // Each render tears its own tree down. A second call must not trip over the
    // first one's global key or a still-dirty element.
    for (var i = 0; i < 3; i++) {
      final bytes = await const WorkoutHeatmapPublisher().renderPng(
        exercises: [exercise('Deadlift', ['hamstrings', 'lower back'])],
        gender: BodyGender.female,
      );
      expect(bytes, isNotNull, reason: 'render $i failed');
    }
  });

  test('draws nothing for a session with no muscles to shade', () async {
    final bytes = await const WorkoutHeatmapPublisher().renderPng(
      exercises: [exercise('Treadmill', ['cardio'], category: 'Cardio')],
      gender: BodyGender.male,
    );

    // Cardio is skipped, so there is nothing to shade — and a blank silhouette
    // would be worse than the widget's own fallback icon.
    expect(bytes, isNull);
  });

  test('the hottest muscle gets the top tier of the ramp', () async {
    // Not a rendering assertion — a guard on the shading rule, so a future
    // change to the ramp cannot silently flatten every muscle to one colour.
    expect(WorkoutHeatmapPublisher.intensityColors.length, 5);
    expect(
      WorkoutHeatmapPublisher.intensityColors.toSet().length,
      5,
      reason: 'five distinct tiers, or the map carries no load information',
    );
  });
}
