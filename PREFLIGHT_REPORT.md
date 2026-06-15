## Preflight Report: Train Libre (Updated)

### ❌ Rejections Found (1)

- **[GUIDELINE 5 - China DST] Banned AI Terms in Metadata**
  - **Issue**: The app mentions "Google Gemini", "OpenAI", "ChatGPT", and "Claude" in the user interface (`lib/l10n/app_en.arb`) and documentation/privacy policy. If these appear in screenshots or metadata, the app will be rejected in the China storefront.
  - **File**: `lib/l10n/app_en.arb` (string: `aiSettingsSetupGuideBody`), `assets/privacy/privacy_policy_en.md`
  - **Fix Status**: **SKIPPED** per user request.
  - **Fix**: Either deselect "China mainland" as a storefront in App Store Connect, or remove specific AI brand names from all user-facing strings and screenshots, replacing them with generic terms like "AI Provider".

### ⚠️ Warnings (1)

- **[GUIDELINE 2.1] Missing App Store Review Notes**
  - **Issue**: New submissions require 6 specific sections in the Review Notes, including a link to a demo video on a physical device and a list of external services (the AI providers).
  - **Fix Status**: **PENDING** (Requires manual content: video URL).
  - **Fix**: Prepare Review Notes using the template provided in `.agents/skills/app-store-preflight-skills/references/rules/metadata/review_notes_template.md`. Be sure to include the "External Services" section listing all supported AI providers.

### ✅ Passed (7)

- **[Privacy] Missing Data Types in Privacy Manifest**: **RESOLVED**. Added `NSPrivacyCollectedDataTypeHealth`, `NSPrivacyCollectedDataTypeFitness`, and `NSPrivacyCollectedDataTypeOtherUserContent` to `ios/Runner/PrivacyInfo.xcprivacy`.
- **[Metadata] Competitor Terms in Binary**: **RESOLVED**. Replaced "Android" with "system" in all `.arb` localization files for `settingsMaterialColorsSubtitle`.
- **[Metadata] App Name Length**: "Train Libre" is 11 characters (limit is 30).
- **[Metadata] Bundle ID**: `com.rfivesix.trainlibre` is unique and follows conventions.
- **[Design] Sign in with Apple**: Not required as no other social logins (Google, Facebook, etc.) are implemented.
- **[Privacy] HealthKit Compliance**: App follows "local-first" principles; Health data is not stored in a central cloud backend managed by the developer.
- **[Privacy] Consent Flow**: Onboarding correctly includes an `InitialConsentScreen` for Privacy Policy and Terms of Service.
