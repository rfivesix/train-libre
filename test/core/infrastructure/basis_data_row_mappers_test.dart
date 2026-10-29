import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/config/app_data_sources.dart';
import 'package:train_libre/core/infrastructure/basis_data_row_mappers.dart';
import 'package:train_libre/services/base_food_language_service.dart';

void main() {
  group('BasisDataRowMappers static parsers', () {
    test('parseInt parses nums, falls back to 0', () {
      expect(BasisDataRowMappers.parseInt(42), 42);
      expect(BasisDataRowMappers.parseInt(42.9), 42);
      expect(BasisDataRowMappers.parseInt(null), 0);
    });

    test('parseDouble parses nums, falls back to 0.0', () {
      expect(BasisDataRowMappers.parseDouble(42), 42.0);
      expect(BasisDataRowMappers.parseDouble(42.5), 42.5);
      expect(BasisDataRowMappers.parseDouble(null), 0.0);
    });

    test('parseString converts to string, falls back to empty', () {
      expect(BasisDataRowMappers.parseString('abc'), 'abc');
      expect(BasisDataRowMappers.parseString(123), '123');
      expect(BasisDataRowMappers.parseString(null), '');
    });

    test('nullableString returns trimmed non-empty or null', () {
      expect(BasisDataRowMappers.nullableString('  hello  '), 'hello');
      expect(BasisDataRowMappers.nullableString('   '), isNull);
      expect(BasisDataRowMappers.nullableString(null), isNull);
    });

    test('parseNullableDouble parses num and string doubles', () {
      expect(BasisDataRowMappers.parseNullableDouble(12.5), 12.5);
      expect(BasisDataRowMappers.parseNullableDouble(' 12.5 '), 12.5);
      expect(BasisDataRowMappers.parseNullableDouble(null), isNull);
      expect(BasisDataRowMappers.parseNullableDouble('abc'), isNull);
    });

    test('parseBool parses booleans, numbers, and strings', () {
      expect(BasisDataRowMappers.parseBool(true), isTrue);
      expect(BasisDataRowMappers.parseBool(false), isFalse);
      expect(BasisDataRowMappers.parseBool(1), isTrue);
      expect(BasisDataRowMappers.parseBool(0), isFalse);
      expect(BasisDataRowMappers.parseBool('1'), isTrue);
      expect(BasisDataRowMappers.parseBool('true'), isTrue);
      expect(BasisDataRowMappers.parseBool('TRUE'), isTrue);
      expect(BasisDataRowMappers.parseBool('0'), isFalse);
      expect(BasisDataRowMappers.parseBool(null), isFalse);
    });

    test('optionalText handles absent, null, empty and valid values', () {
      expect(BasisDataRowMappers.optionalText({}, 'missing').present, isFalse);
      expect(BasisDataRowMappers.optionalText({'status': null}, 'status').value,
          isNull);
      expect(
          BasisDataRowMappers.optionalText({'status': '   '}, 'status').value,
          isNull);
      expect(
          BasisDataRowMappers.optionalText({'status': 'active'}, 'status')
              .value,
          'active');
    });

    test('optionalBool handles absent, null, and values', () {
      expect(BasisDataRowMappers.optionalBool({}, 'missing').present, isFalse);
      expect(
          BasisDataRowMappers.optionalBool({'supported': null}, 'supported')
              .value,
          isFalse);
      expect(
          BasisDataRowMappers.optionalBool({'supported': '1'}, 'supported')
              .value,
          isTrue);
      expect(
          BasisDataRowMappers.optionalBool({'supported': true}, 'supported')
              .value,
          isTrue);
    });
  });

  group('BasisDataRowMappers row mapping', () {
    test('mapCategoryRow maps category columns', () {
      final companion = BasisDataRowMappers.mapCategoryRow({
        'key': 'cat_fruits',
        'name_de': 'Früchte',
        'name_en': 'Fruits',
        'emoji': '🍎',
      });
      expect(companion.key.value, 'cat_fruits');
      expect(companion.nameDe.value, 'Früchte');
      expect(companion.nameEn.value, 'Fruits');
      expect(companion.emoji.value, '🍎');
    });

    test('mapExerciseBundle extracts exercise fields and translations', () {
      final bundle = BasisDataRowMappers.mapExerciseBundle({
        'id': 'bench_press',
        'category_name': 'Chest',
        'muscles_primary': 'Pectoralis',
        'muscles_secondary': 'Triceps',
        'status': 'published',
        'modality': 'free_weight',
        'name_de': 'Bankdrücken',
        'name_en': 'Bench Press',
        'description_de': 'Flachbankdrücken',
      });

      expect(bundle.exerciseFields['id'], 'bench_press');
      expect(bundle.exerciseFields['category_name'], 'Chest');
      expect(bundle.exerciseFields['status'], 'published');
      expect(bundle.exerciseFields['modality'], 'free_weight');
      expect(bundle.translationFields.length, 5); // de, en, fr, it, ja
      expect(
          bundle.translationFields
              .firstWhere((t) => t['language_code'] == 'de')['name'],
          'Bankdrücken');
      expect(
          bundle.translationFields
              .firstWhere((t) => t['language_code'] == 'en')['name'],
          'Bench Press');
    });

    test('mapProductRow maps nutrients, barcode, and beverage heuristic', () {
      final companion = BasisDataRowMappers.mapProductRow(
        {
          'barcode': '4000123456789',
          'name_de': 'Apfelsaft',
          'calories': 45,
          'protein': 0.1,
          'carbs': 11.0,
          'fat': 0.1,
          'sugar': 10.5,
          'fiber': 0.2,
          'salt': 0.01,
          'category': 'en:beverages,en:fruit-juices',
          'product_quantity': 1000.0,
          'product_quantity_unit': 'ml',
        },
        sourceLabel: 'base',
        preferredLanguage: 'de',
      );

      expect(companion.barcode.value, '4000123456789');
      expect(companion.name.value, 'Apfelsaft');
      expect(companion.calories.value, 45);
      expect(companion.carbs.value, 11.0);
      expect(companion.isFluid.value, isTrue);
      expect(companion.source.value, 'base');
    });

    test('resolveBaseFoodLangCode handles choice and offCountry', () {
      expect(
        BasisDataRowMappers.resolveBaseFoodLangCode(
          choice: BaseFoodLanguage.en,
          offCountry: OffCatalogCountry.de,
        ),
        'en',
      );
      expect(
        BasisDataRowMappers.resolveBaseFoodLangCode(
          choice: BaseFoodLanguage.auto,
          offCountry: OffCatalogCountry.de,
        ),
        'de',
      );
      expect(
        BasisDataRowMappers.resolveBaseFoodLangCode(
          choice: BaseFoodLanguage.auto,
          offCountry: OffCatalogCountry.us,
        ),
        'en',
      );
      expect(
        BasisDataRowMappers.resolveBaseFoodLangCode(
          choice: BaseFoodLanguage.auto,
          offCountry: OffCatalogCountry.fr,
        ),
        'fr',
      );
    });

    test(
        'resolveBaseFoodLangCode handles preferredLanguage and availableLanguages fallback',
        () {
      expect(
        BasisDataRowMappers.resolveBaseFoodLangCode(
          preferredLanguage: 'fr',
          availableLanguages: ['de', 'en', 'fr'],
        ),
        'fr',
      );
      expect(
        BasisDataRowMappers.resolveBaseFoodLangCode(
          preferredLanguage: 'es',
          availableLanguages: ['de', 'en', 'fr'],
          defaultLanguage: 'de',
        ),
        'de',
      );
    });
  });
}
