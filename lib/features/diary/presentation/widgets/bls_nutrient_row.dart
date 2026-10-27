import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/bls_food_catalog_refresh_service.dart';
import '../../../../util/design_constants.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';

/// A row presenting a single BLS nutrient fact with its scaled numeric value,
/// unit, and optional provenance/reference information dialog.
class BlsNutrientRow extends StatelessWidget {
  final BlsNutrientFact fact;
  final double? displayValue;

  const BlsNutrientRow({
    super.key,
    required this.fact,
    this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = displayValue;
    final displayNumber = value == null
        ? (fact.valueText?.isNotEmpty == true ? fact.valueText! : '-')
        : '${value.toStringAsFixed(3)} ${fact.unit}'.trim();
    final provenance = [
      if (fact.origin != null && fact.origin != '-') fact.origin!,
      if (fact.reference != null && fact.reference != '-') fact.reference!,
    ].join(' · ');
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignConstants.spacingS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fact.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: DesignConstants.spacingM),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (provenance.isNotEmpty) ...[
                  IconButton(
                    tooltip: l10n.blsNutrientDetails,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(LucideIcons.info, size: 18),
                    onPressed: () => _showBlsNutrientDetails(context),
                  ),
                  const SizedBox(width: DesignConstants.spacingXS),
                ],
                Flexible(
                  child: Text(
                    displayNumber,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBlsNutrientDetails(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    await showGlassBottomMenu<void>(
      context: context,
      title: fact.name,
      contentBuilder: (context, close) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fact.origin != null && fact.origin != '-') ...[
            _NutrientMetadataRow(
              label: l10n.blsNutrientOrigin,
              value: fact.origin!,
              theme: theme,
            ),
          ],
          if (fact.reference != null && fact.reference != '-') ...[
            if (fact.origin != null && fact.origin != '-')
              const SizedBox(height: DesignConstants.spacingM),
            _NutrientMetadataRow(
              label: l10n.blsNutrientReference,
              value: fact.reference!,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _NutrientMetadataRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _NutrientMetadataRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = theme.textTheme.labelLarge;
    final valueStyle = theme.textTheme.bodyMedium;

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = (TextPainter(
          text: TextSpan(text: label, style: labelStyle),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout(maxWidth: constraints.maxWidth))
            .width;
        final valueWidth = (TextPainter(
          text: TextSpan(text: value, style: valueStyle),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout(maxWidth: constraints.maxWidth))
            .width;
        final fitsInOneLine =
            labelWidth + valueWidth + DesignConstants.spacingM <=
                constraints.maxWidth;

        if (fitsInOneLine) {
          return Row(
            children: [
              Text(label, style: labelStyle),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: SelectableText(
                  value,
                  textAlign: TextAlign.end,
                  style: valueStyle,
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            SelectableText(value, style: valueStyle),
          ],
        );
      },
    );
  }
}
