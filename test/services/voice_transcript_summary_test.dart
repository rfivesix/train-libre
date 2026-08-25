import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/services/ai_service.dart';

void main() {
  final service = AiService.forTesting();

  group('parsing the tidy response', () {
    test('reads bullets with their notes', () {
      final summary = service.parseVoiceSummaryForTesting('''
{"bullets":[
  {"text":"500 g Hähnchen","notes":["Trockengewicht"]},
  {"text":"200 g Reis","notes":[]},
  {"text":"Sriracha-Sauce","notes":["etwas dazu"]}
],"context":"zum Mittagessen"}
''');

      expect(summary, isNotNull);
      expect(summary!.bullets, hasLength(3));
      expect(summary.bullets.first.text, '500 g Hähnchen');
      expect(summary.bullets.first.notes, ['Trockengewicht']);
      expect(summary.bullets[1].notes, isEmpty);
      expect(summary.context, 'zum Mittagessen');
    });

    test('survives a fenced response', () {
      final summary = service.parseVoiceSummaryForTesting(
        '```json\n{"bullets":[{"text":"Ein Apfel"}]}\n```',
      );
      expect(summary!.bullets.single.text, 'Ein Apfel');
    });

    test('survives prose around the JSON', () {
      final summary = service.parseVoiceSummaryForTesting(
        'Here you go:\n{"bullets":[{"text":"Ein Apfel"}]}\nHope that helps.',
      );
      expect(summary!.bullets.single.text, 'Ein Apfel');
    });

    test('skips malformed bullets rather than failing outright', () {
      final summary = service.parseVoiceSummaryForTesting(
        '{"bullets":[{"text":""},{"nope":1},{"text":"Ein Apfel","notes":"x"}]}',
      );
      expect(summary!.bullets, hasLength(1));
      expect(summary.bullets.single.text, 'Ein Apfel');
      expect(summary.bullets.single.notes, isEmpty);
    });

    test('returns null for anything that is not the expected shape', () {
      expect(service.parseVoiceSummaryForTesting('not json'), isNull);
      expect(service.parseVoiceSummaryForTesting('{"bullets":"nope"}'), isNull);
      expect(service.parseVoiceSummaryForTesting(''), isNull);
    });
  });

  group('what gets handed to the meal analysis', () {
    test('one food per line, qualifiers kept with their food', () {
      final summary = service.parseVoiceSummaryForTesting(
        '{"bullets":['
        '{"text":"500 g Hähnchen","notes":["Trockengewicht","gebraten"]},'
        '{"text":"200 g Reis"}'
        '],"context":"zum Mittagessen"}',
      )!;

      expect(
        summary.toMarkdown(),
        '- 500 g Hähnchen\n'
        '  - Trockengewicht\n'
        '  - gebraten\n'
        '- 200 g Reis\n'
        '\n'
        'zum Mittagessen',
      );
    });

    test('omits an absent context', () {
      final summary = service.parseVoiceSummaryForTesting(
        '{"bullets":[{"text":"Ein Apfel"}]}',
      )!;
      expect(summary.toMarkdown(), '- Ein Apfel');
    });
  });
}
