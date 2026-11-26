import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/sharing/share_link_codec.dart';

void main() {
  test('shared workout accepts fractional actual and prescribed RPE', () {
    final payload = ShareLinkPayload.fromJson({
      'v': 1,
      't': 'workout',
      'n': 'Workout',
      'd': {
        'start': '2026-11-26T12:00:00Z',
        'sets': [
          {'exercise_name': 'Squat', 'set_type': 'normal', 'rpe': 8.5, 'prescribed_rpe': 7.5},
        ],
      },
    });
    expect((payload.data['sets'] as List).single['rpe'], 8.5);
  });
}
