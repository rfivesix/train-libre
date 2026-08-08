import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/config/app_data_sources.dart';
import 'package:train_libre/services/ai_matching_language_service.dart';
import 'package:train_libre/services/off_catalog_country_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiMatchingLanguageService & OffCatalogCountryLanguageX Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('OffCatalogCountry language mapping resolves correctly', () {
      expect(OffCatalogCountry.de.primaryLanguageCode, equals('de'));
      expect(OffCatalogCountry.at.primaryLanguageCode, equals('de'));
      expect(OffCatalogCountry.ch.primaryLanguageCode, equals('de'));
      expect(OffCatalogCountry.us.primaryLanguageCode, equals('en'));
      expect(OffCatalogCountry.uk.primaryLanguageCode, equals('en'));
      expect(OffCatalogCountry.fr.primaryLanguageCode, equals('fr'));
      expect(OffCatalogCountry.it.primaryLanguageCode, equals('it'));
      expect(OffCatalogCountry.jp.primaryLanguageCode, equals('ja'));
    });

    test('AiMatchingContext identifies different catalog language correctly', () {
      const same = AiMatchingContext(appLanguage: 'de', catalogLanguage: 'de');
      expect(same.hasDifferentCatalogLanguage, isFalse);

      const diff = AiMatchingContext(appLanguage: 'de', catalogLanguage: 'fr');
      expect(diff.hasDifferentCatalogLanguage, isTrue);
    });

    test('writeActiveCountry sets catalog language correctly in prefs', () async {
      final prefs = await SharedPreferences.getInstance();
      await OffCatalogCountryService.writeActiveCountry(OffCatalogCountry.fr, prefs: prefs);

      final country = OffCatalogCountryService.readActiveCountryFromPrefs(prefs);
      expect(country, equals(OffCatalogCountry.fr));
      expect(country.primaryLanguageCode, equals('fr'));
    });
  });
}
