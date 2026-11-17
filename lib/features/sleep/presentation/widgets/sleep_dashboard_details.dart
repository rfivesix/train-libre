import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_section_header.dart';
import '../../../analytics/domain/models/chart_data_point.dart';
import '../../../profile/presentation/widgets/measurement_chart_widget.dart';
import '../../../pulse/application/pulse_tracking_service.dart';
import '../../../pulse/data/hrv_repository.dart';
import '../../data/repository/sleep_query_repository.dart';
import '../../data/sleep_day_repository.dart';
import '../../domain/aggregation/sleep_period_aggregations.dart';
import '../../domain/sleep_enums.dart';

class SleepGoalCard extends StatefulWidget {
  const SleepGoalCard({
    super.key,
    required this.overview,
    required this.repository,
  });
  final SleepDayOverviewData overview;
  final SleepQueryRepository? repository;
  @override
  State<SleepGoalCard> createState() => _SleepGoalCardState();
}

class _SleepGoalCardState extends State<SleepGoalCard> {
  Future<List<SleepDayAggregate>>? _future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SleepGoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.overview.analysis.nightDate !=
            widget.overview.analysis.nightDate) {
      _load();
    }
  }

  void _load() {
    final repo = widget.repository;
    final day = widget.overview.analysis.nightDate;
    if (repo == null) {
      _future = null;
      return;
    }
    final first = DateTime(day.year, day.month, day.day - 6);
    final last = DateTime(day.year, day.month, day.day);
    _future = repo
        .getAnalysesInRange(fromInclusive: first, toInclusive: last)
        .then((analyses) {
          final byDate = {
            for (final a in analyses)
              DateTime(a.nightDate.year, a.nightDate.month, a.nightDate.day): a,
          };
          return List.generate(7, (i) {
            final date = DateTime(first.year, first.month, first.day + i);
            final a = byDate[date];
            return SleepDayAggregate(
              date: date,
              score: a?.score,
              sleepQuality: a?.sleepQuality ?? SleepQualityBucket.unavailable,
              totalSleepMinutes: a?.totalSleepMinutes,
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final minutes = widget.overview.totalSleepMinutes;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: l10n.sleepDashboardGoal,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (minutes != null)
                Expanded(
                  child: Text(
                    '${l10n.sleepDashboardTonightDelta}: ${minutes - 480 < 0 ? '−' : '+'}${(minutes - 480).abs() ~/ 60}h ${(minutes - 480).abs() % 60}m · ${(minutes / 480 * 100).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                const Spacer(),
              Text(
                minutes == null
                    ? '–'
                    : '${minutes ~/ 60}h ${minutes % 60}m / 8h',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (minutes != null) ...[
            const SizedBox(height: DesignConstants.spacingS),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: (minutes / 480).clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
          FutureBuilder<List<SleepDayAggregate>>(
            future: _future,
            builder: (context, snapshot) {
              final days =
                  snapshot.data
                      ?.where((d) => d.totalSleepMinutes != null)
                      .toList() ??
                  [];
              if (days.isEmpty) {
                return const SizedBox.shrink();
              }
              final diff = days.fold<int>(
                0,
                (sum, d) => sum + d.totalSleepMinutes! - 480,
              );
              final sign = diff < 0 ? '−' : '+';
              final abs = diff.abs();
              return Padding(
                padding: const EdgeInsets.only(top: DesignConstants.spacingM),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.sleepDashboardSevenDays(days.length),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '$sign${abs ~/ 60}h ${abs % 60}m',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SleepNightHeartCharts extends StatefulWidget {
  const SleepNightHeartCharts({
    super.key,
    required this.overview,
    required this.repository,
  });
  final SleepDayOverviewData overview;
  final SleepQueryRepository? repository;
  @override
  State<SleepNightHeartCharts> createState() => _SleepNightHeartChartsState();
}

class _SleepNightHeartChartsState extends State<SleepNightHeartCharts> {
  Future<_NightHrv>? _hrv;
  bool? _lastPulseTrackingEnabled;
  @override
  void initState() {
    super.initState();
    _lastPulseTrackingEnabled =
        PulseTrackingService.trackingEnabledListenable.value;
    PulseTrackingService.trackingEnabledListenable.addListener(
      _onPulseTrackingChanged,
    );
    _load();
  }

  void _onPulseTrackingChanged() {
    final enabled = PulseTrackingService.trackingEnabledListenable.value;
    final shouldReload = _lastPulseTrackingEnabled == false && enabled == true;
    _lastPulseTrackingEnabled = enabled;
    if (shouldReload && mounted) setState(_load);
  }

  @override
  void dispose() {
    PulseTrackingService.trackingEnabledListenable.removeListener(
      _onPulseTrackingChanged,
    );
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SleepNightHeartCharts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overview.session.id != widget.overview.session.id ||
        oldWidget.overview.session.startAtUtc !=
            widget.overview.session.startAtUtc ||
        oldWidget.overview.session.endAtUtc !=
            widget.overview.session.endAtUtc ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  void _load() {
    final session = widget.overview.session;
    final day = widget.overview.analysis.nightDate;
    _hrv = () async {
      final summary = await HealthHrvRepository().getSummary(
        fromUtc: session.startAtUtc.subtract(const Duration(days: 31)),
        toUtc: session.endAtUtc,
      );
      final current = summary.samples
          .where(
            (s) =>
                !s.startUtc.isBefore(session.startAtUtc) &&
                s.startUtc.isBefore(session.endAtUtc),
          )
          .toList();
      final sources = current.map((s) => s.sourceId).toSet();
      final repo = widget.repository;
      if (repo == null || current.isEmpty) {
        return _NightHrv(summary.state, current, null, 0);
      }
      final history = await repo.getAnalysesInRange(
        fromInclusive: DateTime(day.year, day.month, day.day - 30),
        toInclusive: DateTime(day.year, day.month, day.day - 1),
      );
      final means = <double>[];
      for (final night in history) {
        final start = night.sessionStartAtUtc, end = night.sessionEndAtUtc;
        if (start == null || end == null) continue;
        final values = summary.samples
            .where(
              (s) =>
                  sources.contains(s.sourceId) &&
                  !s.startUtc.isBefore(start) &&
                  s.startUtc.isBefore(end),
            )
            .map((s) => s.sdnnMs)
            .toList();
        if (values.isNotEmpty) {
          means.add(values.reduce((a, b) => a + b) / values.length);
        }
      }
      final baseline = means.length < 5
          ? null
          : means.reduce((a, b) => a + b) / means.length;
      return _NightHrv(summary.state, current, baseline, means.length);
    }();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final timeFormatter = DateFormat.Hm(locale);
    final overview = widget.overview;
    final start = overview.session.startAtUtc;
    final end = overview.session.endAtUtc;
    final hrPoints =
        overview.heartRateSamples
            .where(
              (p) =>
                  !p.sampledAtUtc.isBefore(start) &&
                  !p.sampledAtUtc.isAfter(end) &&
                  p.bpm.isFinite,
            )
            .map(
              (p) => ChartDataPoint(
                date: p.sampledAtUtc.toLocal(),
                value: p.bpm,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => a.date.compareTo(b.date));

    final hrMin = hrPoints.isEmpty
        ? null
        : hrPoints.map((e) => e.value).reduce(math.min).round();
    final hrAvg = hrPoints.isEmpty
        ? null
        : (hrPoints.map((e) => e.value).reduce((a, b) => a + b) /
                  hrPoints.length)
              .round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hrPoints.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingL,
            ),
            child: AppSectionHeader(
              title: l10n.sleepDashboardNightHeartRate,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          MeasurementChartWidget.fromData(
            key: const ValueKey('sleep-heart-chart-bpm'),
            dataPoints: hrPoints,
            unit: l10n.sleepBpmUnit,
            axisMode: MeasurementChartAxisMode.time,
            valueFractionDigits: 0,
            referenceLineValue: overview.hasHeartRateBaseline
                ? overview.baselineSleepHr
                : null,
            valueLabelBuilder: (value, unit) => '${value.round()} $unit',
            selectedDateLabelBuilder: (value) => timeFormatter.format(value),
            axisLabelBuilder: (value, _) => timeFormatter.format(value),
            trailingSummaryLabel:
                '${l10n.workoutHeartRateMinLabel}: $hrMin ${l10n.sleepBpmUnit} · ${l10n.workoutHeartRateAverageLabel}: $hrAvg ${l10n.sleepBpmUnit}',
            edgeToEdge: true,
          ),
        ],
        ValueListenableBuilder<bool?>(
          valueListenable: PulseTrackingService.trackingEnabledListenable,
          builder: (context, enabled, _) {
            if (!Platform.isIOS || enabled == false) {
              return const SizedBox.shrink();
            }
            return FutureBuilder<_NightHrv>(
              future: _hrv,
              builder: (context, snapshot) {
                final summary = snapshot.data;
                if (summary?.state == HrvState.disabled ||
                    summary?.state == HrvState.unavailable ||
                    summary?.state == HrvState.queryFailed ||
                    snapshot.hasError) {
                  return const SizedBox.shrink();
                }
                final samples = summary?.samples ?? [];
                final hrvPoints =
                    samples
                        .map(
                          (s) => ChartDataPoint(
                            date: s.startUtc.toLocal(),
                            value: s.sdnnMs,
                          ),
                        )
                        .toList(growable: false)
                      ..sort((a, b) => a.date.compareTo(b.date));

                if (hrvPoints.isEmpty) {
                  return const SizedBox.shrink();
                }

                final hrvMin = hrvPoints
                    .map((e) => e.value)
                    .reduce(math.min)
                    .round();
                final hrvAvg =
                    (hrvPoints.map((e) => e.value).reduce((a, b) => a + b) /
                            hrvPoints.length)
                        .round();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hrPoints.isNotEmpty)
                      const SizedBox(height: DesignConstants.spacingM),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignConstants.spacingL,
                      ),
                      child: AppSectionHeader(
                        title: l10n.sleepDashboardNightHrv,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    MeasurementChartWidget.fromData(
                      key: const ValueKey('sleep-heart-chart-ms'),
                      dataPoints: hrvPoints,
                      unit: 'ms',
                      axisMode: MeasurementChartAxisMode.time,
                      valueFractionDigits: 0,
                      referenceLineValue: summary?.baseline,
                      valueLabelBuilder: (value, unit) =>
                          '${value.round()} $unit',
                      selectedDateLabelBuilder: (value) =>
                          timeFormatter.format(value),
                      axisLabelBuilder: (value, _) =>
                          timeFormatter.format(value),
                      trailingSummaryLabel:
                          '${l10n.workoutHeartRateMinLabel}: $hrvMin ms · ${l10n.workoutHeartRateAverageLabel}: $hrvAvg ms',
                      edgeToEdge: true,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _NightHrv {
  const _NightHrv(this.state, this.samples, this.baseline, this.nights);
  final HrvState state;
  final List<HrvSample> samples;
  final double? baseline;
  final int nights;
}
