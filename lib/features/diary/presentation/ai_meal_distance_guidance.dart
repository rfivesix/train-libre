/// Distance guidance derived only from a current live camera measurement.
///
/// A missing, invalid, or unsupported measurement clears the guidance so an
/// old photo or stale depth frame can never leave the scanner hint visible.
class AiMealDistanceGuidance {
  static const double minDistanceCm = 15;
  static const double maxDistanceCm = 120;

  AiMealDistanceHint? _hint;

  AiMealDistanceHint? get hint => _hint;

  AiMealDistanceHint? update(double? distanceCm) {
    if (distanceCm == null || !distanceCm.isFinite || distanceCm <= 0) {
      _hint = null;
    } else if (distanceCm < minDistanceCm) {
      _hint = AiMealDistanceHint.moveAway;
    } else if (distanceCm > maxDistanceCm) {
      _hint = AiMealDistanceHint.moveCloser;
    } else {
      _hint = null;
    }
    return _hint;
  }
}

enum AiMealDistanceHint { moveAway, moveCloser }
