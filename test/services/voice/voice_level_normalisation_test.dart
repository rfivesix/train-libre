import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/services/voice/voice_dictation_service.dart';

void main() {
  group('normalizeDbLevel (Apple, dBFS)', () {
    test('silence and anything below the floor read as zero', () {
      expect(VoiceDictationService.normalizeDbLevel(-60), 0);
      expect(VoiceDictationService.normalizeDbLevel(-45), 0);
    });

    test('the loudest encodable signal reads as one', () {
      expect(VoiceDictationService.normalizeDbLevel(0), 1);
    });

    test('normal speech lands in the usable middle of the range', () {
      // ~-25 dBFS is a person talking at arm's length. This is the case the
      // old Android-shaped mapping flattened to zero, which is why the cloud
      // never reacted to a voice on iOS.
      final level = VoiceDictationService.normalizeDbLevel(-25);
      expect(level, greaterThan(0.3));
      expect(level, lessThan(0.6));
    });

    test('is monotonic', () {
      expect(
        VoiceDictationService.normalizeDbLevel(-30),
        lessThan(VoiceDictationService.normalizeDbLevel(-10)),
      );
    });

    test('an rms of zero yields -infinity, which must not escape', () {
      expect(
          VoiceDictationService.normalizeDbLevel(double.negativeInfinity), 0);
      expect(VoiceDictationService.normalizeDbLevel(double.nan), 0);
    });
  });

  group('normalizeAndroidLevel', () {
    test('maps the platform range onto 0 to 1', () {
      expect(VoiceDictationService.normalizeAndroidLevel(-2), 0);
      expect(VoiceDictationService.normalizeAndroidLevel(10), 1);
      expect(
          VoiceDictationService.normalizeAndroidLevel(4), closeTo(0.5, 0.01));
    });

    test('clamps outside the range', () {
      expect(VoiceDictationService.normalizeAndroidLevel(-20), 0);
      expect(VoiceDictationService.normalizeAndroidLevel(40), 1);
    });
  });
}
