import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/bls_food_catalog_refresh_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_section_header.dart';
import 'bls_nutrient_row.dart';

/// Ranks BLS nutrient groups to display them in a logical nutritional order
/// (vitamins first, followed by minerals/elements, fatty acids, amino acids, etc.).
int blsNutrientGroupRank(String group) {
  final normalized = group.toLowerCase();
  if (normalized.contains('vitamin')) {
    return normalized.contains('fat-soluble') ||
            normalized.contains('fettlöslich')
        ? 0
        : 1;
  }
  if (normalized.contains('element') || normalized.contains('mineral')) {
    return 2;
  }
  if (normalized.contains('fatty acid') || normalized.contains('fettsäure')) {
    return 3;
  }
  if (normalized.contains('amino')) return 4;
  if (normalized.contains('carbohydrate') ||
      normalized.contains('kohlenhydrat')) {
    return 5;
  }
  if (normalized.contains('fiber') || normalized.contains('ballaststoff')) {
    return 6;
  }
  if (normalized.contains('organic acid') ||
      normalized.contains('organische säure')) {
    return 7;
  }
  if (normalized.contains('sugar alcohol') ||
      normalized.contains('zuckeralkohol')) {
    return 8;
  }
  if (normalized.contains('macro') ||
      normalized.contains('energy') ||
      normalized.contains('energie')) {
    return 9;
  }
  return 10;
}

/// A section presenting categorized BLS nutrient groups with section headers
/// and individual nutrient rows, or an empty/loading state if no nutrients
/// are available yet.
class BlsNutrientGroupsSection extends StatelessWidget {
  final List<BlsNutrientFact> blsNutrients;
  final bool isLoading;
  final double? Function(double?) getDisplayValue;
  final bool Function(BlsNutrientFact) isCommonNutrient;

  const BlsNutrientGroupsSection({
    super.key,
    required this.blsNutrients,
    required this.isLoading,
    required this.getDisplayValue,
    required this.isCommonNutrient,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groups = <String, List<BlsNutrientFact>>{};
    for (final fact in blsNutrients) {
      if (isCommonNutrient(fact)) continue;
      groups.putIfAbsent(fact.group, () => []).add(fact);
    }
    if (groups.isEmpty) {
      if (blsNutrients.isNotEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: DesignConstants.spacingM,
        ),
        child: isLoading
            ? Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Text(l10n.initLoadingRemoteManifest),
                ],
              )
            : Text(l10n.blsNutrientsUnavailable),
      );
    }

    final orderedGroups = groups.entries.toList()
      ..sort((a, b) {
        final rankA = blsNutrientGroupRank(a.key);
        final rankB = blsNutrientGroupRank(b.key);
        final rankOrder = rankA.compareTo(rankB);
        return rankOrder != 0 ? rankOrder : a.key.compareTo(b.key);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in orderedGroups) ...[
          AppSectionHeader(
            title: entry.key,
            padding: const EdgeInsets.only(
              top: DesignConstants.spacingXXL,
              bottom: DesignConstants.spacingS,
            ),
          ),
          for (final fact in entry.value)
            BlsNutrientRow(
              fact: fact,
              displayValue: getDisplayValue(fact.value),
            ),
        ],
      ],
    );
  }
}
