import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/presentation/ai_meal_distance_guidance.dart';

void main() {
  group('AiMealDistanceGuidance', () {
    test('updates the hint as live distance changes', () {
      final guidance = AiMealDistanceGuidance();

      expect(guidance.update(10), AiMealDistanceHint.moveAway);
      expect(guidance.hint, AiMealDistanceHint.moveAway);
      expect(guidance.update(70), isNull);
      expect(guidance.hint, isNull);
      expect(guidance.update(140), AiMealDistanceHint.moveCloser);
    });

    test('clears stale guidance when measurement disappears or is invalid', () {
      final guidance = AiMealDistanceGuidance();

      guidance.update(10);
      expect(guidance.update(null), isNull);

      guidance.update(140);
      expect(guidance.update(double.nan), isNull);

      guidance.update(10);
      expect(guidance.update(0), isNull);
    });

    test('keeps guidance hidden inside the supported distance range', () {
      final guidance = AiMealDistanceGuidance();

      expect(guidance.update(15), isNull);
      expect(guidance.update(120), isNull);
      expect(guidance.update(60), isNull);
    });
  });
}
