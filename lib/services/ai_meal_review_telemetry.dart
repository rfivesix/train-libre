import 'telemetry/telemetry_service.dart';

typedef AiReviewEventSender = Future<void> Function(
    String event, Map<String, dynamic> properties);

/// Owns the single terminal review event, independent of transient save errors.
class AiMealReviewTelemetry {
  final String? requestId;
  final AiReviewEventSender _send;
  final Stopwatch _watch = Stopwatch()..start();
  bool manualEdited = false;
  int correctionRounds = 0;
  bool _finished = false;

  AiMealReviewTelemetry({
    required this.requestId,
    AiReviewEventSender? send,
  }) : _send = send ??
            ((event, properties) =>
                TelemetryService.instance.track(event, properties: properties));

  void markManualEdit() => manualEdited = true;
  void markCorrectionSubmitted() => correctionRounds++;

  Future<void> finish({required bool saved}) {
    if (_finished || requestId == null) return Future<void>.value();
    _finished = true;
    _watch.stop();
    final outcome = !saved
        ? 'discarded'
        : correctionRounds > 0
            ? 'saved_after_ai_correction'
            : manualEdited
                ? 'saved_after_manual_edit'
                : 'saved_unchanged';
    return _send('ai_meal_review_finished', {
      'request_id': requestId!,
      'outcome': outcome,
      'ai_correction_rounds_count': correctionRounds,
      'review_duration_seconds': (_watch.elapsedMilliseconds / 1000).round(),
    });
  }
}
