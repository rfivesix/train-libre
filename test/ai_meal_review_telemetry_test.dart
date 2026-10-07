import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/services/ai_meal_review_telemetry.dart';

void main() {
  test('successful save emits one unchanged outcome', () async {
    final events = <Map<String, dynamic>>[];
    final tracker = AiMealReviewTelemetry(
      requestId: 'random-scan-id',
      send: (event, properties) async {
        expect(event, 'ai_meal_review_finished');
        events.add(properties);
      },
    );
    await tracker.finish(saved: true);
    await tracker.finish(saved: false);
    expect(events, hasLength(1));
    expect(events.single['outcome'], 'saved_unchanged');
    expect(events.single['request_id'], 'random-scan-id');
  });

  test('manual edit, AI correction, and discard stay distinct', () async {
    Future<Map<String, dynamic>> eventFor({
      required bool saved,
      bool manual = false,
      bool correction = false,
    }) async {
      late Map<String, dynamic> event;
      final tracker = AiMealReviewTelemetry(
        requestId: 'scan',
        send: (_, properties) async => event = properties,
      );
      if (manual) tracker.markManualEdit();
      if (correction) tracker.markCorrectionSubmitted();
      await tracker.finish(saved: saved);
      return event;
    }

    expect((await eventFor(saved: true, manual: true))['outcome'],
        'saved_after_manual_edit');
    final corrected = await eventFor(saved: true, correction: true);
    expect(corrected['outcome'], 'saved_after_ai_correction');
    expect(corrected['ai_correction_rounds_count'], 1);
    expect((await eventFor(saved: false, correction: true))['outcome'],
        'discarded');
  });
}
