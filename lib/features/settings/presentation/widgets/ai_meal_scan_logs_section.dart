import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/ai_meal_scan_log_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/common.dart';
import '../../../../widgets/common/summary_card.dart';

/// Local, content-free AI scan diagnostics shown directly on the main lab tab.
class AiMealScanLogsSection extends StatefulWidget {
  const AiMealScanLogsSection({super.key});

  @override
  State<AiMealScanLogsSection> createState() => _AiMealScanLogsSectionState();
}

class _AiMealScanLogsSectionState extends State<AiMealScanLogsSection> {
  final _logs = AiMealScanLogService.instance;

  @override
  void initState() {
    super.initState();
    _logs.addListener(_refresh);
    _logs.load();
  }

  @override
  void dispose() {
    _logs.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.aiScanLogsCopied),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _confirmClear() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.aiScanLogsClear),
        content: Text(l10n.aiScanLogsClearConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed == true) await _logs.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entries = _logs.entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.aiScanLogsTitle),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: DesignConstants.spacingM),
          child: Text(l10n.aiScanLogsPrivacy,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        if (entries.isEmpty)
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.all(DesignConstants.spacingM),
              child:
                  Text(l10n.aiScanLogsEmpty, style: theme.textTheme.bodyMedium),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingM),
            child: Row(children: [
              Text(l10n.aiScanLogsCount(entries.length),
                  style: theme.textTheme.labelMedium),
              const Spacer(),
              TextButton.icon(
                key: const Key('ai_scan_logs_copy_all'),
                onPressed: () => _copy(_logs.exportAll()),
                icon: const Icon(LucideIcons.copy, size: 16),
                label: Text(l10n.aiScanLogsCopyAll),
              ),
              IconButton(
                key: const Key('ai_scan_logs_clear'),
                tooltip: l10n.aiScanLogsClear,
                onPressed: _confirmClear,
                icon: const Icon(LucideIcons.trash, size: 18),
              ),
            ]),
          ),
          for (final log in entries)
            _LogCard(
              key: ValueKey(log.id),
              log: log,
              onCopy: () => _copy(_logs.export(log)),
            ),
        ],
      ],
    );
  }
}

class _LogCard extends StatelessWidget {
  final AiMealScanLog log;
  final VoidCallback onCopy;

  const _LogCard({super.key, required this.log, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final date =
        MaterialLocalizations.of(context).formatMediumDate(log.startedAt);
    final time = TimeOfDay.fromDateTime(log.startedAt).format(context);
    final duration = log.durationMilliseconds == null
        ? '…'
        : '${(log.durationMilliseconds! / 1000).toStringAsFixed(1)} s';
    return SummaryCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: Key('ai_scan_log_${log.id}'),
        tilePadding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacingL,
            vertical: DesignConstants.spacingXS),
        childrenPadding: const EdgeInsets.fromLTRB(DesignConstants.spacingL, 0,
            DesignConstants.spacingL, DesignConstants.spacingL),
        title: Row(children: [
          Expanded(
              child: Text('$date · $time',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700))),
          Text(duration,
              style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700)),
        ]),
        subtitle: Text(
            '${log.model ?? log.provider} · ${_inputLabel(l10n, log.inputMode)} · ${_resultLabel(l10n, log.result)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        children: [
          const Divider(height: 1),
          const SizedBox(height: DesignConstants.spacingM),
          _DetailRow(l10n.aiScanLogsPhotos, '${log.photoCount}'),
          _DetailRow(
              l10n.aiScanLogsFirstPass,
              log.primaryFirstPassAccepted == null
                  ? '–'
                  : log.primaryFirstPassAccepted!
                      ? l10n.yes
                      : l10n.no),
          _DetailRow(l10n.aiScanLogsValidations,
              '${log.selectedValidationRounds ?? '–'} / ${log.totalValidationRuns ?? '–'}'),
          _DetailRow(l10n.aiScanLogsRepairs, '${log.repairRounds ?? '–'}'),
          _DetailRow(
              l10n.aiScanLogsHedge,
              log.hedgeStarted == null
                  ? '–'
                  : log.hedgeStarted!
                      ? l10n.yes
                      : l10n.no),
          _DetailRow(
              l10n.aiScanLogsTokens,
              log.usageComplete == true
                  ? '${log.totalTokens} (${log.inputTokens} ↓ / ${log.outputTokens} ↑)'
                  : l10n.aiScanLogsUnknown),
          _DetailRow(l10n.aiScanLogsCalls, '${log.providerCalls ?? '–'}'),
          if (log.reviewResult != null)
            _DetailRow(
                l10n.aiScanLogsReview, _resultLabel(l10n, log.reviewResult!)),
          if (log.correctionRounds != null)
            _DetailRow(l10n.aiScanLogsCorrections, '${log.correctionRounds}'),
          const SizedBox(height: DesignConstants.spacingM),
          Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.aiScanLogsTimeline,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700))),
          const SizedBox(height: DesignConstants.spacingS),
          for (final event in log.events)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                    width: 70,
                    child: Text(
                        '+${(event.elapsedMilliseconds / 1000).toStringAsFixed(1)} s',
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ]))),
                Expanded(
                    child: Text(_eventLabel(l10n, event),
                        style: theme.textTheme.bodySmall)),
              ]),
            ),
          const SizedBox(height: DesignConstants.spacingM),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: Key('ai_scan_log_copy_${log.id}'),
                onPressed: onCopy,
                icon: const Icon(LucideIcons.copy, size: 16),
                label: Text(l10n.aiScanLogsCopy),
              )),
        ],
      ),
    );
  }

  String _inputLabel(AppLocalizations l10n, String value) => switch (value) {
        'text_only' => l10n.aiScanLogsInputText,
        'photo' => l10n.aiScanLogsInputPhoto,
        'multimodal' => l10n.aiScanLogsInputMixed,
        _ => value,
      };

  String _eventLabel(AppLocalizations l10n, AiMealScanLogEvent event) {
    final parts = <String>[
      '${_stageLabel(l10n, event.stage)}${event.round == null ? '' : ' #${event.round}'}',
      if (event.candidate != null)
        event.candidate == AiMealScanLogCandidate.primary
            ? l10n.aiScanLogsCandidatePrimary
            : l10n.aiScanLogsCandidateHedge,
      if (event.durationMilliseconds != null)
        '${(event.durationMilliseconds! / 1000).toStringAsFixed(1)} s',
      if (event.result != null) _resultLabel(l10n, event.result!),
      if (event.validationScore != null)
        '${l10n.aiScanLogsScore} ${event.validationScore}',
      for (final category in event.issueCategories) _issueLabel(l10n, category),
      if (event.callIndex != null) '${l10n.aiScanLogsCall} #${event.callIndex}',
      if (event.usageComplete != null)
        event.usageComplete == true
            ? '${event.totalTokens} (${event.inputTokens} ↓ / ${event.outputTokens} ↑)'
            : l10n.aiScanLogsUnknown,
    ];
    return parts.join(' · ');
  }

  String _issueLabel(
          AppLocalizations l10n, AiMealScanLogIssueCategory category) =>
      switch (category) {
        AiMealScanLogIssueCategory.semanticMatch =>
          l10n.aiScanLogsIssueSemantic,
        AiMealScanLogIssueCategory.catalogMatch => l10n.aiScanLogsIssueCatalog,
        AiMealScanLogIssueCategory.quantity => l10n.aiScanLogsIssueQuantity,
        AiMealScanLogIssueCategory.nutritionAnchor =>
          l10n.aiScanLogsIssueNutrition,
        AiMealScanLogIssueCategory.preparationState =>
          l10n.aiScanLogsIssuePreparation,
        AiMealScanLogIssueCategory.confidence => l10n.aiScanLogsIssueConfidence,
        AiMealScanLogIssueCategory.otherValidation => l10n.aiScanLogsIssueOther,
      };

  String _resultLabel(AppLocalizations l10n, AiMealScanLogResult result) =>
      switch (result) {
        AiMealScanLogResult.running => l10n.aiScanLogsRunning,
        AiMealScanLogResult.accepted => l10n.aiScanLogsAccepted,
        AiMealScanLogResult.needsRepair => l10n.aiScanLogsNeedsRepair,
        AiMealScanLogResult.failed => l10n.aiScanLogsFailed,
        AiMealScanLogResult.cancelled => l10n.aiScanLogsCancelled,
        AiMealScanLogResult.savedUnchanged => l10n.aiScanLogsSavedUnchanged,
        AiMealScanLogResult.savedAfterManualEdit => l10n.aiScanLogsSavedEdited,
        AiMealScanLogResult.savedAfterAiCorrection =>
          l10n.aiScanLogsSavedCorrected,
        AiMealScanLogResult.discarded => l10n.aiScanLogsDiscarded,
      };

  String _stageLabel(AppLocalizations l10n, AiMealScanLogStage stage) =>
      switch (stage) {
        AiMealScanLogStage.requested => l10n.aiScanLogsStageRequested,
        AiMealScanLogStage.preparationFinished => l10n.aiScanLogsStagePrepared,
        AiMealScanLogStage.primaryStarted => l10n.aiScanLogsStagePrimary,
        AiMealScanLogStage.hedgeStarted => l10n.aiScanLogsStageHedge,
        AiMealScanLogStage.providerFinished => l10n.aiScanLogsStageProvider,
        AiMealScanLogStage.providerUsageReported => l10n.aiScanLogsStageUsage,
        AiMealScanLogStage.validationFinished => l10n.aiScanLogsStageValidation,
        AiMealScanLogStage.candidateSelected => l10n.aiScanLogsStageSelected,
        AiMealScanLogStage.repairStarted => l10n.aiScanLogsStageRepairStart,
        AiMealScanLogStage.repairFinished => l10n.aiScanLogsStageRepairEnd,
        AiMealScanLogStage.reviewVisible => l10n.aiScanLogsStageReview,
        AiMealScanLogStage.correctionStarted =>
          l10n.aiScanLogsStageCorrectionStart,
        AiMealScanLogStage.correctionFinished =>
          l10n.aiScanLogsStageCorrectionEnd,
      };
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style?.copyWith(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
