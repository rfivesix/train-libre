import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/services/voice/transcript_cleanup.dart';

void main() {
  group('TranscriptCleanup', () {
    test('drops German hesitation sounds and particles', () {
      expect(
        TranscriptCleanup.clean('ähm ich hatte halt quasi einen Apfel'),
        'Ich hatte einen Apfel',
      );
    });

    test('drops English hesitation sounds', () {
      expect(
        TranscriptCleanup.clean('um I had uh two eggs'),
        'I had two eggs',
      );
    });

    test('drops multi-word fillers', () {
      expect(
        TranscriptCleanup.clean('I had, you know, a salad'),
        'I had, a salad',
      );
    });

    test('normalises spoken units to symbols', () {
      expect(
        TranscriptCleanup.clean('500 Gramm Hähnchen und 200 Milliliter Milch'),
        '500 g Hähnchen und 200 ml Milch',
      );
    });

    test('collapses a repeated word from a restarted sentence', () {
      expect(
        TranscriptCleanup.clean('das das Brot mit Butter'),
        'Das Brot mit Butter',
      );
    });

    test('keeps meaningful words that merely look like fillers', () {
      // "like" and "actually" are not on the filler list on purpose.
      expect(
        TranscriptCleanup.clean('I actually like the sauce'),
        'I actually like the sauce',
      );
    });

    test('capitalises the first surviving word', () {
      expect(TranscriptCleanup.clean('ähm apfel'), 'Apfel');
    });

    test('returns empty for input that was only filler', () {
      expect(TranscriptCleanup.clean('ähm äh um'), '');
      expect(TranscriptCleanup.clean('   '), '');
    });

    test('tidies punctuation stranded by a removed word', () {
      expect(
        TranscriptCleanup.clean('Ein Apfel, ähm, und eine Banane'),
        'Ein Apfel, und eine Banane',
      );
    });

    test('leaves an already clean transcript alone', () {
      const input = 'Ein Teller Nudeln mit Tomatensauce';
      expect(TranscriptCleanup.clean(input), input);
    });
  });
}
