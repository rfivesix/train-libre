import 'package:flutter/material.dart';
import '../../../../config/app_data_sources.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/common.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class RegionSelectionSlide extends StatelessWidget {
  final OffCatalogCountry selectedCountry;
  final ValueChanged<OffCatalogCountry> onSelectCountry;

  const RegionSelectionSlide({
    super.key,
    required this.selectedCountry,
    required this.onSelectCountry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const Key('onboarding_region_page'),
      padding: const EdgeInsets.all(DesignConstants.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: DesignConstants.spacingXL),
          Text(
            l10n.onboardingRegionTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Text(
            l10n.onboardingRegionExplanation,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXXL),
          DropdownButtonHideUnderline(
            child: PlatformAdaptiveDropdownFormField<OffCatalogCountry>(
              key: const Key('onboarding_region_dropdown'),
              value: selectedCountry,
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.globe),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusM),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingM,
                  vertical: DesignConstants.spacingL,
                ),
              ),
              items: [
                for (final country
                    in AppDataSources.supportedOffCatalogCountries)
                  DropdownMenuItem(
                    value: country,
                    child: Text(
                      _countryLabel(country, l10n),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
              ],
              onChanged: (val) {
                if (val != null) {
                  onSelectCountry(val);
                }
              },
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXXL),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
            ),
            child: Text(
              l10n.onboardingRegionSettingsHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _countryLabel(OffCatalogCountry country, AppLocalizations l10n) {
    return switch (country) {
      OffCatalogCountry.de => l10n.settingsFoodDbRegionGermany,
      OffCatalogCountry.ch => l10n.settingsFoodDbRegionSwitzerland,
      OffCatalogCountry.us => l10n.settingsFoodDbRegionUnitedStates,
      OffCatalogCountry.uk => l10n.settingsFoodDbRegionUnitedKingdom,
      OffCatalogCountry.fr => l10n.settingsFoodDbRegionFrance,
      OffCatalogCountry.it => l10n.settingsFoodDbRegionItaly,
      OffCatalogCountry.jp => l10n.settingsFoodDbRegionJapan,
      OffCatalogCountry.at => l10n.settingsFoodDbRegionAustria,
    };
  }
}
