import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/domain/parsers/rep_range_parser.dart';

void main() {
  group('parseRepRange', () {
    test('parses hyphenated range "8-12"', () {
      final result = parseRepRange('8-12');
      expect(result, isNotNull);
      expect(result!.min, 8);
      expect(result.max, 12);
    });

    test('parses en-dash range "8–12"', () {
      final result = parseRepRange('8\u201312');
      expect(result, isNotNull);
      expect(result!.min, 8);
      expect(result.max, 12);
    });

    test('handles outer and inner whitespace', () {
      final result1 = parseRepRange('  8 - 12  ');
      expect(result1, isNotNull);
      expect(result1!.min, 8);
      expect(result1.max, 12);

      final result2 = parseRepRange(' 8 \u2013 12 ');
      expect(result2, isNotNull);
      expect(result2!.min, 8);
      expect(result2.max, 12);
    });

    test('parses single number "8" as (8, 8)', () {
      final result = parseRepRange('8');
      expect(result, isNotNull);
      expect(result!.min, 8);
      expect(result.max, 8);

      final resultSpaced = parseRepRange('  15  ');
      expect(resultSpaced, isNotNull);
      expect(resultSpaced!.min, 15);
      expect(resultSpaced.max, 15);
    });

    test('returns null for invalid or unparseable formats', () {
      expect(parseRepRange(null), isNull);
      expect(parseRepRange(''), isNull);
      expect(parseRepRange('   '), isNull);
      expect(parseRepRange('8-'), isNull);
      expect(parseRepRange('-12'), isNull);
      expect(parseRepRange('8-12-16'), isNull);
      expect(parseRepRange('abc'), isNull);
      expect(parseRepRange('8-abc'), isNull);
      expect(parseRepRange('abc-12'), isNull);
      expect(parseRepRange('0'), isNull);
      expect(parseRepRange('-5'), isNull);
      expect(parseRepRange('12-8'), isNull); // min > max
    });
  });
}
