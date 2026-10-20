# Localization architecture

Train Libre has separate localization systems for app UI strings and catalog content. Adding a language to one does not automatically translate the other.

## App UI strings

The canonical message catalogs are `lib/l10n/app_en.arb`, `app_de.arb`, `app_fr.arb`, `app_it.arb`, and `app_ja.arb`. Flutter's generated localization output is under `lib/generated/`; edit the ARB sources, not generated Dart. `lib/main.dart` configures the generated delegates and `AppLocalizations.supportedLocales` on the app's `MaterialApp`.

To add or change UI translations:

1. Add the locale's ARB catalog and keep its message keys and placeholder metadata aligned with the other catalogs (English is the reference catalog).
2. Update locale-specific UI choices or formatters if the feature explicitly enumerates languages; the Flutter locale list alone does not update those controls.
3. Run the localization generator configured by the Flutter project (`flutter gen-l10n`) and review generated changes.
4. Search native UI resources separately when the text belongs to an iOS widget/extension or Android resource rather than Flutter.

Fallback behavior for Flutter-generated messages follows the configured Flutter localization delegates and supported locale list. A missing translation in an individual ARB should be fixed in the catalog; do not infer fallback behavior for product/catalog data from Flutter's UI fallback.

## Food catalog display languages

`BaseFoodLanguageService` (`lib/services/base_food_language_service.dart`) persists a separate food display preference (`auto`, `en`, `de`, `fr`, `it`, `ja`) in SharedPreferences. In automatic mode it considers the app language and active OFF catalog country, then falls back to English. It returns a language code used by catalog lookup; it does not control the app's UI locale.

The base-food import and product schema are implemented in `lib/data/` and catalog tooling. Current data uses localized fields for supported languages, while exercise catalog translations use their own catalog schema and locale-selection logic. Check the actual importer, catalog manifest, and schema before adding a translation column or claiming an exercise fallback chain. Food search/index behavior is described in [Food search](food_search.md).

## Adding locale support safely

For a new locale, inspect each independent surface that needs it:

- Flutter ARB strings, generated localization, and any explicit settings labels.
- Base-food display preference enum/resolution and available catalog columns/data.
- Exercise catalog translations and language selection/fallback code.
- Food-search normalization and alias data where language-specific matching is intended.
- Native iOS/Android widget and configuration strings.
- Website/legal and store metadata, which are separate assets and release workflows.

Only list a locale as supported on a surface after its data and fallback behavior are present. Catalog generation scripts and source datasets are not interchangeable with the app's UI localization pipeline.
