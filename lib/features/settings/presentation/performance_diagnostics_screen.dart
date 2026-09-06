import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/performance/device_label.dart';
import '../../../core/performance/jank_recorder.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../core/performance/startup_trace.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/platform_adaptive_switch_list_tile.dart';
import '../../../widgets/common/summary_card.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../feedback_report/application/feedback_report_actions.dart';
import '../../feedback_report/data/performance_diagnostics_provider.dart';

/// Shows where the app dropped frames, per screen.
///
/// The measurements themselves stay in English: they are technical output meant
/// to be copied into a bug report, and translating `worst_raster` would only
/// make numbers harder to compare across reports.
class PerformanceDiagnosticsScreen extends StatefulWidget {
  const PerformanceDiagnosticsScreen({
    super.key,
    this.recorder,
    this.actions,
    this.deviceLabelLoader,
  });

  final JankRecorder? recorder;
  final FeedbackReportActions? actions;
  final DeviceLabelLoader? deviceLabelLoader;

  @override
  State<PerformanceDiagnosticsScreen> createState() =>
      _PerformanceDiagnosticsScreenState();
}

class _PerformanceDiagnosticsScreenState
    extends State<PerformanceDiagnosticsScreen> {
  late final JankRecorder _recorder;
  late final FeedbackReportActions _actions;
  late final PerformanceDiagnosticsProvider _provider;

  Timer? _refreshTimer;
  PerfSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _recorder = widget.recorder ?? JankRecorder.instance;
    _actions = widget.actions ?? FeedbackReportActions();
    _provider = PerformanceDiagnosticsProvider(
      recorder: _recorder,
      deviceLabelLoader: widget.deviceLabelLoader,
      maxScreens: 40,
      maxStalls: 25,
    );
    _snapshot = _recorder.snapshot();
    // Polling once a second rather than rebuilding per frame batch: a live
    // readout that repaints every frame would add jank to the very screen
    // meant to measure it.
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _snapshot = _recorder.snapshot());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<String> _buildReportText() async {
    final lines = await _provider.buildLines(now: DateTime.now());
    return 'Train Libre — performance log\n${lines.join('\n')}';
  }

  Future<void> _copy() async {
    final text = await _buildReportText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.performanceLogCopiedSnack),
      ),
    );
  }

  Future<void> _share() async {
    final text = await _buildReportText();
    await _actions.shareReport(
      reportText: text,
      subject: 'Train Libre performance log',
    );
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.performanceLogResetTitle,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.performanceLogResetDialogBody,
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.danger(
                    key: const Key('performance_diagnostics_reset_confirm'),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    label: l10n.performanceLogResetConfirm,
                    tooltip: l10n.performanceLogResetTitle,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _recorder.reset();
    // The startup section renders from a separate, separately persisted
    // source, so resetting the jank recorder alone leaves the cold-start and
    // resume runs standing after the user has cleared the log.
    await StartupTrace.instance.reset();
    if (!mounted) return;
    setState(() => _snapshot = _recorder.snapshot());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.performanceLogResetDoneSnack)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = _snapshot ?? _recorder.snapshot();
    final startup = StartupTrace.instance.snapshot();
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('performance_diagnostics_screen'),
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.settingsPerformanceLogTitle),
      body: ListView(
        key: const Key('performance_diagnostics_scroll_view'),
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.all(DesignConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.performanceLogIntro,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  _MetricRow(
                    label: l10n.performanceLogDisplayLabel,
                    value: '${snapshot.refreshRateHz.toStringAsFixed(0)} Hz · '
                        'Budget ${snapshot.frameBudgetMs.toStringAsFixed(1)} ms',
                  ),
                  _MetricRow(
                    label: l10n.performanceLogFramesLabel,
                    value: '${snapshot.totalFrames}',
                  ),
                  _MetricRow(
                    label: l10n.performanceLogJankLabel,
                    value: '${snapshot.totalJankFrames} '
                        '(${(snapshot.totalJankRatio * 100).toStringAsFixed(1)}%)',
                  ),
                  _MetricRow(
                    label: l10n.performanceLogStallsLabel,
                    value: '${snapshot.stalls.length}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),
          Row(
            children: [
              Expanded(
                child: AppButton.primary(
                  key: const Key('performance_diagnostics_copy_button'),
                  onPressed: _copy,
                  label: l10n.performanceLogCopyButton,
                  tooltip: l10n.performanceLogCopyButton,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.secondary(
                  key: const Key('performance_diagnostics_share_button'),
                  onPressed: _share,
                  label: l10n.performanceLogShareButton,
                  tooltip: l10n.performanceLogShareButton,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          AppSectionHeader(title: l10n.performanceLogScreensSection),
          if (snapshot.screens.isEmpty)
            SummaryCard(
              child: Padding(
                padding: const EdgeInsets.all(DesignConstants.spacingL),
                child: Text(
                  l10n.performanceLogEmpty,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            SummaryCard(
              child: Column(
                children: [
                  for (var i = 0; i < snapshot.screens.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _ScreenRow(
                      stats: snapshot.screens[i],
                      severeLabel: l10n.performanceLogSevereLabel,
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: DesignConstants.spacingXL),
          AppSectionHeader(title: l10n.performanceLogStartupSection),
          if (startup.isEmpty)
            SummaryCard(
              child: Padding(
                padding: const EdgeInsets.all(DesignConstants.spacingL),
                child: Text(
                  l10n.performanceLogStartupEmpty,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            SummaryCard(
              child: Column(
                children: [
                  for (var i = 0; i < startup.runs.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _StartupRunTile(
                      run: startup.runs[i],
                      coldLabel: l10n.performanceLogStartupCold,
                      resumeLabel: l10n.performanceLogStartupResume,
                      unattributedLabel: l10n.performanceLogStartupUnattributed,
                    ),
                  ],
                ],
              ),
            ),
          if (snapshot.stalls.isNotEmpty) ...[
            const SizedBox(height: DesignConstants.spacingXL),
            AppSectionHeader(title: l10n.performanceLogStallsSection),
            SummaryCard(
              child: Column(
                children: [
                  for (var i = 0; i < snapshot.stalls.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        LucideIcons.octagon_alert,
                        color: theme.colorScheme.error,
                      ),
                      title: Text('${snapshot.stalls[i].durationMs} ms'),
                      subtitle: Text(
                        '${snapshot.stalls[i].screen} · '
                        '${_formatTime(snapshot.stalls[i].at)}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: DesignConstants.spacingXL),
          SummaryCard(
            child: Column(
              children: [
                PlatformAdaptiveSwitchListTile(
                  key: const Key('performance_diagnostics_pause_switch'),
                  secondary: const Icon(LucideIcons.circle_pause),
                  title: Text(
                    l10n.performanceLogPauseTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: snapshot.isPaused,
                  onChanged: (value) {
                    _recorder.setPaused(value);
                    setState(() => _snapshot = _recorder.snapshot());
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('performance_diagnostics_reset_tile'),
                  leading: const Icon(LucideIcons.trash),
                  title: Text(l10n.performanceLogResetTitle),
                  onTap: _confirmReset,
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
        ],
      ),
    );
  }
}

String _formatTime(DateTime value) {
  String two(int input) => input.toString().padLeft(2, '0');
  return '${two(value.day)}.${two(value.month)}. '
      '${two(value.hour)}:${two(value.minute)}';
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            value,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ScreenRow extends StatelessWidget {
  const _ScreenRow({required this.stats, required this.severeLabel});

  final ScreenPerfStats stats;
  final String severeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jankPercent = stats.jankRatio * 100;

    final Color severityColor;
    if (jankPercent >= 5) {
      severityColor = theme.colorScheme.error;
    } else if (jankPercent >= 1) {
      severityColor = theme.colorScheme.tertiary;
    } else {
      severityColor = theme.colorScheme.onSurfaceVariant;
    }

    return ListTile(
      title: Text(
        stats.screen,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'frames ${stats.frames} · '
        'worst ${stats.worstFrameMs.toStringAsFixed(0)} ms · '
        'build ${stats.worstBuildMs.toStringAsFixed(0)} ms / '
        'raster ${stats.worstRasterMs.toStringAsFixed(0)} ms · '
        'cause ${stats.dominantCause}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${jankPercent.toStringAsFixed(1)}%',
            style: theme.textTheme.titleSmall?.copyWith(
              color: severityColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (stats.severeFrames > 0)
            Text(
              '${stats.severeFrames} $severeLabel',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

/// One launch or resume, broken into the phases that were measured.
///
/// The phase names stay English on purpose, matching the rest of the log:
/// they are identifiers in the code, and a translated one cannot be searched
/// for in a bug report.
class _StartupRunTile extends StatelessWidget {
  const _StartupRunTile({
    required this.run,
    required this.coldLabel,
    required this.resumeLabel,
    required this.unattributedLabel,
  });

  final StartupRun run;
  final String coldLabel;
  final String resumeLabel;
  final String unattributedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worst = run.worstPhase;
    final phases = [...run.phases]
      ..sort((a, b) => b.durationMs.compareTo(a.durationMs));

    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        run.kind == StartupRunKind.cold ? coldLabel : resumeLabel,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        '${run.toFirstFrameMs} ms · ${_formatTime(run.at)}'
        '${worst == null ? '' : ' · ${worst.name} ${worst.durationMs} ms'}',
      ),
      childrenPadding: const EdgeInsets.only(
        left: DesignConstants.spacingL,
        right: DesignConstants.spacingL,
        bottom: DesignConstants.spacingM,
      ),
      children: [
        for (final phase in phases)
          _MetricRow(label: phase.name, value: '${phase.durationMs} ms'),
        _MetricRow(
          label: unattributedLabel,
          value: '${run.unattributedMs} ms',
        ),
      ],
    );
  }
}
