# Spanish and Dutch localization progress

Source: `app_en.arb`, counted by non-`@` message keys at task start (2026-10-29): 2,706. Six app-facing messages were added in this task: Spanish/Dutch base-food language names, the mixed/ready recovery-zone title, and localized feedback direct-send copy. Final target: 2,712 keys per locale.

| Chunk | Source key range | Feature areas | Spanish | Dutch | Review |
|---|---:|---|---|---|---|
| 1 | 1–150 | Diary and food entry, profile and measurements, data management, workout routines and logging | Complete | Complete | Reviewed; key/placeholder check passed. Preserved the explicit positive sign in calorie differences. |
| 2 | 151–300 | App startup, workout history and heart rate, workout import, filters, sharing and set types | Complete | Complete | Reviewed; ARB, placeholder and ICU plural branches passed. Refined Dutch warm-up and failure set terminology. |
| 3 | 301–440 | Food/exercise catalog, routine editing, workout controls and statistics, workout hub | Complete | Complete | Reviewed; ARB and placeholder/plural structure passed. Kept `rutina`/`entrenamiento` and `trainingsschema`/`training` consistent. |
| 4 | 441–580 | Settings, feedback/privacy report, performance diagnostics, onboarding and app tour | Complete | Complete | Reviewed; ARB and placeholder/ICU structure passed. |
| 5 | 581–730 | Backup/export and deletion, exercise mapping, profile/supplements, recipe templates and ingredients | Complete | Complete | Reviewed; ARB and placeholder/ICU structure passed. |
| 6 | 731–880 | Recipe portions and detail, nutrition hub, appearance/food region settings, onboarding/profile setup | Complete | Complete | Reviewed; ARB and placeholder/ICU structure passed. Corrected half-portion phrasing and replaced the source's key-name placeholder for the recipe-list title with its contextual “Recipes” label across all locales. |
| 7 | 881–1030 | Onboarding goals and measurements, AI setup/privacy, meal capture/review and training analytics | Complete | Complete | Reviewed; ARB and placeholder/plural structure passed. |

| 8 | 1031–1180 | Recovery tracker, statistics, exercise and personal-record analytics | Complete | Complete | Reviewed; 150 keys per locale, placeholder check passed. Removed the German/English handwritten recovery-zone title switch and localized the shared label. |
| 9 | 1181–1280 | Training volume/frequency, movement coverage, calendar analytics and nutrition trends | Complete | Complete | Reviewed again after the following pass counted metadata entries; all 100 keys per locale still pass placeholders. Refined Dutch high-confidence wording. |
| 10 | 1281–1430 | Analytics conclusions, restore/workout feedback, sleep summaries and sleep detail | Complete | Complete | Reviewed 150 translatable keys per locale. The first pass counted metadata entries and stopped at 1318; keys 1319–1430 were already translated in both files and were then reviewed in sleep UI context. Placeholder/argument metadata checks passed. |
| 11 | 1431–1580 | Sleep raw-import details, adaptive recommendation setup and settings, body-fat guidance | Complete | Complete | Reviewed 150 messages in context. Placeholders, metadata and argument structures passed; kept language-neutral abbreviations and units where appropriate. |
| 12 | 1581–1730 | Step tracking, health integrations, settings, barcode scanning and consent screens | Complete | Complete | Reviewed 150 messages; placeholders and the `pulseSampleCount` plural structure passed. |
| 13 | 1731–1880 | Legal acknowledgements, AI meal capture, sleep science, workout notes and catalog progress | Complete | Complete | Reviewed 150 messages; argument placeholders and key sets passed. Preserved language-neutral abbreviations and legal version values. |
| 14 | 1881–2030 | Catalog loading, food database, telemetry consent and AI meal capture | Complete | Complete | Reviewed 150 messages; key sets, placeholders, `repsCount` plurals and the `$delete_person` token passed. Reviewed privacy/consent meaning and catalog download context. |
| 15 | 2031–2180 | AI voice and meal review, workout photos, exercise catalog filters and movement classification | Complete | Complete | Reviewed 150 messages; both meal-delete plural structures and placeholders match English. |
| 16 | 2181–2330 | Exercise experience, progression controls, health-safe guidance and goal setup | Complete | Complete | Reviewed 150 messages; diary weight plural branches and goal placeholders match English. Checked progression and safety guidance in context. |
| 17 | 2331–2480 | Goal tracking, weekly reviews, nutrition recommendations and goal management | Complete | Complete | Reviewed 150 messages; placeholders and ICU argument structures passed. |
| 18 | 2481–2630 | Goal notifications, notification settings, AI scan logs and BLS catalog details | Complete | Complete | Reviewed 150 messages; placeholders and ICU structures passed. Preserved proper names and language-neutral labels where appropriate. |
| 19 | 2631–2709 | AI overlay demo, assistant prompts and macro entry | Complete | Complete | Reviewed all 79 remaining messages; both ARBs have the complete 2,709 message-key set and placeholders match English. |
| 20 | 2710–2712 | Feedback report direct-send flow | Complete | Complete | Added and translated three messages in all seven locales, replacing the last direct-send English/German switch. |

All 20 chunks are complete. Final target: 2,712 message keys per locale.

Ambiguous/context-dependent strings: no ambiguous ARB source strings remained after review. The app's separate legal-document content is available only in English and German; `legal_screen.dart` intentionally selects English for Spanish and Dutch until reviewed legal translations are supplied. Several AI-assistant helper/protocol strings also use handwritten English/German branches, so those helper messages can appear in English in Spanish/Dutch sessions even though the localization catalog and AI language code support both locales.

## Catalog integration notes

- OpenExerciseDB already has the needed contract: `exercise_translations.language_code` and `languages.code` carry locale codes, and `BasisDataManager` imports those rows generically. The app's exercise locale chain requests the app language before English and German, so `es` and `nl` flow through without a new schema.
- The bundled BLS base-food contract currently provides German and English product names (`name_de`/`name_en`) and nutrient labels (`name_de`/`name_en`); it has no Spanish or Dutch base-food name columns. The exact integration point for upstream names is the BLS catalog artifact consumed by `BlsFoodCatalogRefreshService`, then `BasisDataRowMappers.mapProductRow` and the local `Products` import. This task does not create catalog translations or a new catalog schema; until upstream `es`/`nl` names are supplied under those codes, base-food display falls back to the available names. BLS nutrient component/group labels now use the existing English fallback for `es` and `nl`.

## Final validation

- `flutter gen-l10n`: passed; generated Spanish and Dutch localization classes and registered both locales.
- ARB audit: passed; both locales contain all 2,712 message keys, with matching metadata, placeholders, and ICU plural/select structures.
- Focused Flutter tests: passed (`localization_es_nl_test.dart`, base-food row-mapper tests, and AI matching language tests).
- `flutter analyze`: passed with no issues.
- `git diff --check`: passed.
