import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../config/app_data_sources.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';

class OffCatalogRegionPickerContent extends StatefulWidget {
  final OffCatalogCountry initialSelection;
  final String Function(OffCatalogCountry, AppLocalizations)
  countryLabelResolver;

  const OffCatalogRegionPickerContent({
    super.key,
    required this.initialSelection,
    required this.countryLabelResolver,
  });

  @override
  State<OffCatalogRegionPickerContent> createState() =>
      _OffCatalogRegionPickerContentState();
}

class _OffCatalogRegionPickerContentState
    extends State<OffCatalogRegionPickerContent> {
  late OffCatalogCountry _draftSelection;
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _draftSelection = widget.initialSelection;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final query = _searchQuery.toLowerCase().trim();
    final filteredCountries = AppDataSources.supportedOffCatalogCountries.where(
      (country) {
        if (query.isEmpty) return true;
        final label = widget.countryLabelResolver(country, l10n).toLowerCase();
        final code = country.code.toLowerCase();
        return label.contains(query) || code.contains(query);
      },
    ).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsFoodDbRegionDialogSubtitle),
        const SizedBox(height: DesignConstants.spacingM),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n.settingsFoodDbRegionSearchPlaceholder,
            prefixIcon: Icon(
              LucideIcons.search,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    tooltip: l10n.clearSearch,
                    icon: Icon(
                      LucideIcons.x,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
        ),
        const SizedBox(height: DesignConstants.spacingM),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: filteredCountries.isEmpty
              ? Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    l10n.settingsFoodDbRegionNoResults,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                )
              : SingleChildScrollView(
                  child: RadioGroup<OffCatalogCountry>(
                    groupValue: _draftSelection,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _draftSelection = value);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final country in filteredCountries)
                          RadioListTile<OffCatalogCountry>(
                            contentPadding: EdgeInsets.zero,
                            value: country,
                            title: Text(
                              widget.countryLabelResolver(country, l10n),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Text(
          l10n.settingsFoodDbRegionIssueHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: DesignConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: DesignConstants.spacingM),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(_draftSelection),
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
