import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../statistics/domain/recovery_payload_models.dart';
import '../../../statistics/domain/recovery_domain_service.dart';
import '../../../statistics/presentation/statistics_formatter.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class RecoverySectionCard extends StatelessWidget {
  final SectionLoadState<RecoveryAnalyticsPayload> state;
  final VoidCallback onRetry;
  final VoidCallback onTap;
  final String? chipText;

  const RecoverySectionCard({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onTap,
    this.chipText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.recovery;
    final title = l10n.metricsMuscleReadiness;


    if (state.hasError && !state.hasData) {
      return AnalyticsCardBase.buildSectionErrorCard(
        context,
        l10n,
        onRetry,
        sectionId,
        title,
      );
    }

    final data = state.data;
    final recovering = data?.totals.recovering ?? 0;
    final ready = data?.totals.ready ?? 0;
    final fresh = data?.totals.fresh ?? 0;
    final hasData = data?.hasData ?? false;
    final overallState = data?.overallState ?? '';

    final recoveryHeadline =
        StatisticsPresentationFormatter.recoveryOverallLabel(
      l10n,
      overallState,
    );

    final iconColor = StatisticsPresentationFormatter.recoveryOverallColor(
      context,
      overallState,
    );

    return AnalyticsCardBase.decorateSectionCard(
      context,
      state: state,
      child: SummaryCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnalyticsCardBase.buildHeaderWithChevron(
                context,
                label: title,
                chipText: chipText ?? (hasData ? l10n.currentlyTracking : null),
              ),
              Text(
                recoveryHeadline,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
              ),
              const SizedBox(height: DesignConstants.spacingL),
              if (hasData)
                Row(
                  children: [
                    _buildReadinessPill(
                      context,
                      l10n,
                      state: RecoveryDomainService.stateRecovering,
                      count: recovering,
                      total: recovering + ready + fresh,
                    ),
                    const SizedBox(width: DesignConstants.spacingS),
                    _buildReadinessPill(
                      context,
                      l10n,
                      state: RecoveryDomainService.stateReady,
                      count: ready,
                      total: recovering + ready + fresh,
                    ),
                    const SizedBox(width: DesignConstants.spacingS),
                    _buildReadinessPill(
                      context,
                      l10n,
                      state: RecoveryDomainService.stateFresh,
                      count: fresh,
                      total: recovering + ready + fresh,
                    ),
                  ],
                )
              else
                Text(
                  l10n.recoveryHubNoDataSummary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadinessPill(
    BuildContext context,
    AppLocalizations l10n, {
    required String state,
    required int count,
    required int total,
  }) {
    final color =
        StatisticsPresentationFormatter.recoveryStateColor(context, state);
    final percent = total > 0 ? (count / total * 100).round() : 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(DesignConstants.borderRadiusL);

    final surfaceBase = isDark
        ? DesignConstants.summaryCardDarkMode
        : theme.colorScheme.surface.withValues(alpha: 0.95);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingM,
              vertical: DesignConstants.spacingM,
            ),
            decoration: BoxDecoration(
              color: surfaceBase,
              borderRadius: radius,
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.35 : 0.25),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$count',
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  StatisticsPresentationFormatter.recoveryStateLabel(
                      l10n, state),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$percent%',
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
