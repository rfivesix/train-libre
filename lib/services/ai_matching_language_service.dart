// lib/services/ai_matching_language_service.dart

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_data_sources.dart';
import 'base_food_language_service.dart';
import 'off_catalog_country_service.dart';

/// Context containing the user's primary UI language and the active OFF food catalog language.
class AiMatchingContext {
  /// Primary language code for food display names (e.g., 'de', 'en', 'fr').
  final String appLanguage;

  /// Primary language code of the active OFF catalog (e.g., 'de', 'fr', 'en', 'it', 'ja').
  final String catalogLanguage;

  const AiMatchingContext({
    required this.appLanguage,
    required this.catalogLanguage,
  });

  /// Whether the food catalog language differs from the user's app UI language.
  bool get hasDifferentCatalogLanguage => appLanguage != catalogLanguage;
}

/// Helper extension to map [OffCatalogCountry] to its primary language code.
extension OffCatalogCountryLanguageX on OffCatalogCountry {
  String get primaryLanguageCode => switch (this) {
        OffCatalogCountry.de ||
        OffCatalogCountry.at ||
        OffCatalogCountry.ch =>
          'de',
        OffCatalogCountry.us || OffCatalogCountry.uk => 'en',
        OffCatalogCountry.fr => 'fr',
        OffCatalogCountry.it => 'it',
        OffCatalogCountry.jp => 'ja',
      };
}

/// Legacy enum kept for backward compatibility.
enum AiMatchingLanguage {
  auto,
  en,
  de,
  fr,
  it,
  ja,
}

/// Persists and resolves AI matching language context.
class AiMatchingLanguageService {
  const AiMatchingLanguageService._();

  /// Resolves the current [AiMatchingContext] based on app locale and active OFF catalog country.
  static Future<AiMatchingContext> resolveMatchingContext({
    required BuildContext context,
    SharedPreferences? prefs,
  }) async {
    final locale = Localizations.localeOf(context).languageCode;
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    final activeOffCountry =
        OffCatalogCountryService.readActiveCountryFromPrefs(resolvedPrefs);

    final baseFoodChoice =
        await BaseFoodLanguageService.readChoice(prefs: resolvedPrefs);
    final appLang = BaseFoodLanguageService.resolveLanguageCodeFromLocale(
      choice: baseFoodChoice,
      locale: locale,
      activeCountry: activeOffCountry,
    );

    final catalogLang = activeOffCountry.primaryLanguageCode;

    return AiMatchingContext(
      appLanguage: appLang,
      catalogLanguage: catalogLang,
    );
  }

  /// Deprecated: Read the persisted choice. Returns [AiMatchingLanguage.auto].
  static Future<AiMatchingLanguage> readChoice({
    SharedPreferences? prefs,
  }) async {
    return AiMatchingLanguage.auto;
  }

  /// Deprecated: Write choice stub.
  static Future<void> writeChoice(
    AiMatchingLanguage choice, {
    SharedPreferences? prefs,
  }) async {}

  /// Resolve the effective language code for AI matching.
  static Future<String> resolveLanguageCode({
    AiMatchingLanguage choice = AiMatchingLanguage.auto,
    required BuildContext context,
  }) async {
    final matchingContext = await resolveMatchingContext(context: context);
    return matchingContext.appLanguage;
  }
}
