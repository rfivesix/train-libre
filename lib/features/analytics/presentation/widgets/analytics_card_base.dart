import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import '../statistics_hub_view_model.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class AnalyticsCardBase {
  static const double chipBackgroundOpacity = 0.14;
  static const double miniBarOpacity = 0.75;

  static Widget buildSectionLoadingCard(
    BuildContext context,
    AppLocalizations l10n,
    StatisticsHubSectionId sectionId,
    String title,
  ) {
    return SummaryCard(
      key: Key('statistics_section_loading_${sectionId.name}'),
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.spacingL),
        child: Row(
          children: [
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: DesignConstants.spacingM),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              l10n.load_dots,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildSectionErrorCard(
    BuildContext context,
    AppLocalizations l10n,
    VoidCallback onRetry,
    StatisticsHubSectionId sectionId,
    String title,
  ) {
    return SummaryCard(
      key: Key('statistics_section_error_${sectionId.name}'),
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCardHeading(context, label: title),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.sleepStatusTechnicalError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            TextButton(
              onPressed: onRetry,
              child: Text(MaterialLocalizations.of(context)
                  .refreshIndicatorSemanticLabel),
            ),
          ],
        ),
      ),
    );
  }

  static Widget decorateSectionCard<T>(
    BuildContext context, {
    required SectionLoadState<T> state,
    required Widget child,
  }) {
    if (!state.hasData || !state.hasError) {
      return child;
    }
    return Stack(
      children: [
        child,
        Positioned(
          top: 10,
          right: 10,
          child: Icon(
            LucideIcons.triangle_alert,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  static Widget buildCardHeading(
    BuildContext context, {
    required String label,
    String? chipText,
  }) {
    final chipColor = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (chipText != null && chipText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingS,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: chipBackgroundOpacity),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              chipText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }

  static Widget buildHeaderWithChevron(
    BuildContext context, {
    required String label,
    String? chipText,
    bool trailingIcon = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: buildCardHeading(context, label: label, chipText: chipText),
        ),
        if (trailingIcon) ...[
          const SizedBox(width: DesignConstants.spacingS),
          buildDrillDownHint(context),
        ],
      ],
    );
  }

  static Widget buildDrillDownHint(BuildContext context) {
    return Icon(
      LucideIcons.chevron_right,
      size: 18,
      color: Theme.of(context).colorScheme.outline,
    );
  }

  static Widget buildMicroCaption(BuildContext context, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
    );
  }

  static Widget buildRangeChip(BuildContext context, String label) {
    final chipColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: chipBackgroundOpacity),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  static Widget buildMiniBars(
    BuildContext context, {
    required List<double> values,
    required Color color,
    required String semanticsLabel,
  }) {
    // BOLT OPTIMIZATION: Replaced chained .where().toList() and .map().toList()
    // with a single-pass loop for max calculation, and collection-for for rendering,
    // avoiding unnecessary list allocations on every build.
    double max = 0;
    bool hasValid = false;
    for (final v in values) {
      if (v.isFinite) {
        hasValid = true;
        if (v > max) max = v;
      }
    }

    if (!hasValid) return const SizedBox.shrink();

    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: 20,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final v in values)
              if (v.isFinite)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FractionallySizedBox(
                      heightFactor: max <= 0 ? 0.2 : (v / max).clamp(0.08, 1.0),
                      alignment: Alignment.bottomCenter,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: miniBarOpacity),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
