import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../../pulse/domain/pulse_models.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class PulseSectionCard extends StatelessWidget {
  final SectionLoadState<PulseAnalysisSummary> state;
  final String fallbackRangeLabel;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  const PulseSectionCard({
    super.key,
    required this.state,
    required this.fallbackRangeLabel,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.pulse;
    final title = l10n.pulseTitle;

    if (state.isLoading && !state.hasData) {
      return AnalyticsCardBase.buildSectionLoadingCard(
        context,
        l10n,
        sectionId,
        title,
      );
    }
    if (state.hasError && !state.hasData) {
      return AnalyticsCardBase.buildSectionErrorCard(
        context,
        l10n,
        onRetry,
        sectionId,
        title,
      );
    }

    final summary = state.data;
    final chipLabel = fallbackRangeLabel;
    final hasMetrics = summary?.hasCoreMetrics ?? false;
    final rangeValue = !hasMetrics
        ? '--'
        : '${summary!.minBpm!.round()}-${summary.maxBpm!.round()}';
    final averageValue =
        summary?.averageBpm == null ? '--' : '${summary!.averageBpm!.round()}';
    final restingValue =
        summary?.restingBpm == null ? '--' : '${summary!.restingBpm!.round()}';
    final stateText = summary == null
        ? l10n.load_dots
        : summary.hasData
            ? '${l10n.pulseSampleCount(summary.sampleCount)} - ${_pulseQualityLabel(l10n, summary.quality)}'
            : _pulseNoDataMessage(l10n, summary.noDataReason);

    return AnalyticsCardBase.decorateSectionCard(
      context,
      state: state,
      child: SummaryCard(
        key: const Key('statistics_pulse_card'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnalyticsCardBase.buildHeaderWithChevron(
                context,
                label: title,
                chipText: chipLabel,
              ),
              const SizedBox(height: DesignConstants.spacingL),
              _buildTwoColumnGrid([
                ValueSummaryCard(
                  label: l10n.pulseRangeLabel,
                  value: rangeValue,
                  subtitle:
                      summary?.minBpm == null ? l10n.noData : l10n.sleepBpmUnit,
                  disableShadow: true,
                ),
                ValueSummaryCard(
                  label: l10n.pulseAverageLabel,
                  value: averageValue,
                  subtitle: summary?.averageBpm == null
                      ? l10n.noData
                      : l10n.sleepBpmUnit,
                  disableShadow: true,
                ),
                ValueSummaryCard(
                  label: l10n.pulseRestingLabel,
                  value: restingValue,
                  subtitle: summary?.restingBpm == null
                      ? l10n.noData
                      : l10n.sleepBpmUnit,
                  disableShadow: true,
                ),
              ]),
              const SizedBox(height: DesignConstants.spacingS),
              Text(
                stateText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTwoColumnGrid(List<Widget> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : const SizedBox();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(child: right),
            ],
          ),
        ),
      );
      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: DesignConstants.spacingS));
      }
    }
    return Column(children: rows);
  }

  String _pulseQualityLabel(AppLocalizations l10n, PulseDataQuality quality) {
    return switch (quality) {
      PulseDataQuality.ready => l10n.pulseQualityReady,
      PulseDataQuality.limited => l10n.pulseQualityLimited,
      PulseDataQuality.insufficient => l10n.pulseQualityInsufficient,
      PulseDataQuality.noData => l10n.pulseQualityNoData,
    };
  }

  String _pulseNoDataMessage(AppLocalizations l10n, PulseNoDataReason reason) {
    return switch (reason) {
      PulseNoDataReason.disabled => l10n.pulseNoDataDisabled,
      PulseNoDataReason.permissionDenied => l10n.pulseNoDataPermissionDenied,
      PulseNoDataReason.platformUnavailable => l10n.pulseNoDataUnavailable,
      PulseNoDataReason.queryFailed => l10n.pulseNoDataQueryFailed,
      _ => l10n.pulseNoDataDefault,
    };
  }
}
