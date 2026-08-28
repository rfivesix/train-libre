import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:async';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../application/feedback_report_actions.dart';
import '../data/adaptive_nutrition_diagnostics_provider.dart';
import '../data/backup_restore_diagnostics_provider.dart';
import '../data/performance_diagnostics_provider.dart';
import '../domain/feedback_report_builder.dart';
import '../domain/feedback_report_models.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/app_button.dart';

class FeedbackReportScreen extends StatefulWidget {
  final FeedbackReportBuilder? reportBuilder;
  final FeedbackReportActions? actions;

  const FeedbackReportScreen({
    super.key,
    this.reportBuilder,
    this.actions,
  });

  @override
  State<FeedbackReportScreen> createState() => _FeedbackReportScreenState();
}

class _FeedbackReportScreenState extends State<FeedbackReportScreen> {
  late final FeedbackReportBuilder _reportBuilder;
  late final FeedbackReportActions _actions;
  final TextEditingController _noteController = TextEditingController();

  bool _includeAdaptiveDiagnostics = true;
  bool _includeBackupRestoreDiagnostics = true;
  bool _includePerformanceDiagnostics = true;
  bool _includeUserNote = true;

  bool _isGeneratingPreview = false;
  bool _isCopying = false;
  bool _isSaving = false;
  bool _isSharing = false;
  bool _isEmailing = false;

  String? _previewText;
  String? _savedFilePath;

  @override
  void initState() {
    super.initState();
    _reportBuilder = widget.reportBuilder ??
        FeedbackReportBuilder(
          adaptiveDiagnosticsProvider: AdaptiveNutritionDiagnosticsProvider(),
          backupRestoreDiagnosticsProvider: BackupRestoreDiagnosticsProvider(),
          performanceDiagnosticsProvider: PerformanceDiagnosticsProvider(),
        );
    _actions = widget.actions ?? FeedbackReportActions();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.feedbackReport));
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  FeedbackReportLocalizedCopy _copy(AppLocalizations l10n) {
    return FeedbackReportLocalizedCopy(
      title: l10n.feedbackReportReportTitle,
      generatedLabel: l10n.feedbackReportReportGeneratedAt,
      appVersionLabel: l10n.feedbackReportReportAppVersion,
      buildNumberLabel: l10n.feedbackReportReportBuildNumber,
      platformLabel: l10n.feedbackReportReportPlatform,
      osVersionLabel: l10n.feedbackReportReportOsVersion,
      unavailableValue: l10n.feedbackReportUnavailable,
      userNoteSectionTitle: l10n.feedbackReportSectionUserNote,
      adaptiveSectionTitle: l10n.feedbackReportSectionAdaptiveNutrition,
      backupRestoreSectionTitle: l10n.feedbackReportSectionBackupRestore,
    );
  }

  Future<void> _generatePreview() async {
    if (_isGeneratingPreview) {
      return;
    }

    setState(() {
      _isGeneratingPreview = true;
    });

    final l10n = AppLocalizations.of(context)!;
    final copy = _copy(l10n);
    final report = await _reportBuilder.build(
      options: FeedbackReportOptions(
        includeAdaptiveNutritionDiagnostics: _includeAdaptiveDiagnostics,
        includeBackupRestoreDiagnostics: _includeBackupRestoreDiagnostics,
        includePerformanceDiagnostics: _includePerformanceDiagnostics,
        includeUserNote: _includeUserNote,
      ),
      copy: copy,
      userNote: _noteController.text,
    );

    final previewText = FeedbackReportSerializer.toPlainText(
      report: report,
      copy: copy,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isGeneratingPreview = false;
      _previewText = previewText;
      _savedFilePath = null;
    });
  }

  Future<void> _copyReport() async {
    final previewText = _previewText;
    if (previewText == null || _isCopying) {
      return;
    }

    setState(() => _isCopying = true);
    try {
      await _actions.copyReport(previewText);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $error')),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _isCopying = false);
      }
    }

    _trackReportSubmission('copied');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.feedbackReportCopied)),
    );
  }

  Future<void> _saveReportFile() async {
    final previewText = _previewText;
    if (previewText == null || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    String? savedPath;
    try {
      final file =
          await _actions.saveReportToTemporaryFile(reportText: previewText);
      savedPath = file.path;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $error')),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    _trackReportSubmission('saved_file');
    if (!mounted) return;
    setState(() => _savedFilePath = savedPath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.feedbackReportSavedToTemporaryFile,
        ),
      ),
    );
  }

  Future<void> _shareReport() async {
    final previewText = _previewText;
    if (previewText == null || _isSharing) {
      return;
    }

    setState(() => _isSharing = true);
    final l10n = AppLocalizations.of(context)!;
    ShareResultStatus? status;
    try {
      status = await _actions.shareReport(
        reportText: previewText,
        existingFilePath: _savedFilePath,
        subject: l10n.feedbackReportEmailSubject,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $error')),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }

    _trackReportSubmission('shared');
    if (!mounted) return;
    final wasShared = status == ShareResultStatus.success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasShared
              ? l10n.feedbackReportShareCompleted
              : l10n.feedbackReportShareCanceled,
        ),
      ),
    );
  }

  Future<void> _openEmailDraft() async {
    final previewText = _previewText;
    if (previewText == null || _isEmailing) {
      return;
    }

    setState(() => _isEmailing = true);
    final includeNote = _includeUserNote ? _noteController.text.trim() : null;
    final l10n = AppLocalizations.of(context)!;
    var opened = false;
    try {
      opened = await _actions.openFeedbackEmailDraft(
        reportText: previewText,
        userNote: includeNote,
        subject: l10n.feedbackReportEmailSubject,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $error')),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _isEmailing = false);
      }
    }

    _trackReportSubmission('email');
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.feedbackReportEmailOpenFailed),
        ),
      );
    }
  }

  List<String> get _activeIncludedSections => [
        if (_includeAdaptiveDiagnostics) 'adaptive_nutrition',
        if (_includeBackupRestoreDiagnostics) 'backup_restore',
        if (_includePerformanceDiagnostics) 'performance',
        if (_includeUserNote && _noteController.text.trim().isNotEmpty)
          'user_note',
      ];

  /// Diagnostic keys whose values are body measurements or nutrition
  /// quantities. They are never attached to the telemetry event.
  ///
  /// The report the user sends through email, share or file export still
  /// contains the full detail — those channels are under the user's own control
  /// and go to the developer directly. The PostHog event only carries the
  /// counters, confidence levels and state flags needed to reproduce a bug.
  static bool _isSensitiveDiagnosticKey(String key) {
    // Pure counters keep their signal without revealing a measured value.
    if (key.endsWith('_count') || key.endsWith('_days')) return false;
    return key.contains('weight') ||
        key.contains('_kg') ||
        key.contains('kcal') ||
        key.contains('calorie') ||
        key.contains('protein') ||
        key.contains('carbs') ||
        key.contains('fat') ||
        key.contains('maintenance');
  }

  Map<String, dynamic> _buildDiagnosticsSummary(String? reportText) {
    if (reportText == null || reportText.isEmpty) return {};
    final summary = <String, dynamic>{};
    // The free-text note is deliberately NOT included. It is unconstrained user
    // input that can contain names, diagnoses or contact details; only its
    // length is reported, via `userNoteLength`.
    final lines = reportText.split('\n');
    for (final rawLine in lines) {
      var line = rawLine.trim();
      if (line.startsWith('- ')) {
        line = line.substring(2).trim();
      }
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        final key = line.substring(0, colonIndex).trim();
        final valueStr = line.substring(colonIndex + 1).trim();

        final isDiagnosticKey = key.startsWith('feature_') ||
            key.contains('goal_') ||
            key.contains('target_') ||
            key.contains('due_') ||
            key.contains('recommendation') ||
            key.contains('calories') ||
            key.contains('protein') ||
            key.contains('carbs') ||
            key.contains('fat') ||
            key.contains('weight') ||
            key.contains('maintenance') ||
            key.contains('confidence') ||
            key.contains('warning') ||
            key.contains('input_') ||
            key.contains('posterior_') ||
            key.contains('prior_') ||
            key.contains('phase_') ||
            key.contains('backup_') ||
            key.contains('estimator_');

        if (isDiagnosticKey && !_isSensitiveDiagnosticKey(key)) {
          final safeKey =
              'diag_${key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}';
          final numValue = double.tryParse(valueStr);
          if (numValue != null) {
            summary[safeKey] = numValue;
          } else if (valueStr == 'yes' || valueStr == 'true') {
            summary[safeKey] = true;
          } else if (valueStr == 'no' || valueStr == 'false') {
            summary[safeKey] = false;
          } else {
            summary[safeKey] = valueStr;
          }
        }
      }
    }
    return summary;
  }

  void _trackReportSubmission(String submissionMethod) {
    final noteText = _noteController.text.trim();
    final summary = _buildDiagnosticsSummary(_previewText);
    unawaited(TelemetryService.instance.trackFeedbackReportSubmitted(
      includedSections: _activeIncludedSections,
      hasUserNote: _includeUserNote && noteText.isNotEmpty,
      userNoteLength: _includeUserNote ? noteText.length : 0,
      submissionMethod: submissionMethod,
      diagnosticsSummary: summary,
    ));
  }

  Future<void> _sendAnonymousReportToPostHog() async {
    final previewText = _previewText;
    if (previewText == null) return;

    // Direct submission rides on the telemetry pipeline, which drops everything
    // while the user is opted out. Reporting success in that case would claim a
    // delivery that never happened, so check first and point at the channels
    // that do work.
    final canSubmit = await TelemetryService.instance.isOptedIn();

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final isGerman = l10n.localeName.startsWith('de');

    if (!canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isGerman
                ? 'Direktversand benötigt die anonyme Nutzungsstatistik. '
                    'Aktiviere sie in den Einstellungen oder nutze E-Mail bzw. Teilen.'
                : 'Direct submission requires anonymous usage statistics. '
                    'Enable it in Settings, or use email or share instead.',
          ),
        ),
      );
      return;
    }

    _trackReportSubmission('posthog_direct');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isGerman
              ? 'Diagnosebericht direkt an Entwickler gesendet. Vielen Dank!'
              : 'Diagnostic report sent directly to developer. Thank you!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      key: const Key('feedback_report_screen'),
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.feedbackReportScreenTitle,
      ),
      body: ListView(
        key: const Key('feedback_report_scroll_view'),
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          AppInfoRow(
            title: l10n.feedbackReportPrivacyTitle,
            subtitle: l10n.feedbackReportPrivacyBody,
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          AppSectionHeader(title: l10n.feedbackReportOptionalNoteTitle),
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.all(DesignConstants.spacingL),
              child: TextField(
                key: const Key('feedback_report_note_field'),
                controller: _noteController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: l10n.feedbackReportOptionalNoteLabel,
                  hintText: l10n.feedbackReportOptionalNoteHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          AppSectionHeader(title: l10n.feedbackReportIncludeSectionTitle),
          SummaryCard(
            child: Column(
              children: [
                PlatformAdaptiveSwitchListTile(
                  key: const Key('feedback_report_toggle_adaptive'),
                  secondary: const Icon(LucideIcons.activity),
                  title: Text(
                    l10n.feedbackReportIncludeAdaptiveNutrition,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: _includeAdaptiveDiagnostics,
                  onChanged: (value) {
                    setState(() => _includeAdaptiveDiagnostics = value);
                  },
                ),
                const Divider(height: 1),
                PlatformAdaptiveSwitchListTile(
                  key: const Key('feedback_report_toggle_backup'),
                  secondary: const Icon(LucideIcons.cloud_upload),
                  title: Text(
                    l10n.feedbackReportIncludeBackupRestore,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: _includeBackupRestoreDiagnostics,
                  onChanged: (value) {
                    setState(() => _includeBackupRestoreDiagnostics = value);
                  },
                ),
                const Divider(height: 1),
                PlatformAdaptiveSwitchListTile(
                  key: const Key('feedback_report_toggle_performance'),
                  secondary: const Icon(LucideIcons.gauge),
                  title: Text(
                    l10n.feedbackReportIncludePerformance,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: _includePerformanceDiagnostics,
                  onChanged: (value) {
                    setState(() => _includePerformanceDiagnostics = value);
                  },
                ),
                const Divider(height: 1),
                PlatformAdaptiveSwitchListTile(
                  key: const Key('feedback_report_toggle_note'),
                  secondary: const Icon(LucideIcons.sticky_note),
                  title: Text(
                    l10n.feedbackReportIncludeUserNote,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: _includeUserNote,
                  onChanged: (value) {
                    setState(() => _includeUserNote = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              key: const Key('feedback_report_generate_preview_button'),
              onPressed: _isGeneratingPreview ? null : _generatePreview,
              label: l10n.feedbackReportGeneratePreview,
              tooltip: l10n.feedbackReportGeneratePreview,
            ),
          ),
          if (_previewText != null) ...[
            const SizedBox(height: DesignConstants.spacingXL),
            AppSectionHeader(title: l10n.feedbackReportPreviewTitle),
            SummaryCard(
              child: Padding(
                padding: const EdgeInsets.all(DesignConstants.spacingL),
                child: SizedBox(
                  height: 280,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _previewText!,
                      key: const Key('feedback_report_preview_text'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                key: const Key('feedback_report_action_send_posthog'),
                onPressed: _sendAnonymousReportToPostHog,
                label: l10n.localeName.startsWith('de')
                    ? 'Direkt an Entwickler senden'
                    : 'Send directly to developer',
                tooltip: l10n.localeName.startsWith('de')
                    ? 'Direkt an Entwickler senden'
                    : 'Send directly to developer',
                icon: LucideIcons.send,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton.secondary(
                  key: const Key('feedback_report_action_copy'),
                  onPressed: _isCopying ? null : _copyReport,
                  label: l10n.feedbackReportActionCopy,
                  tooltip: l10n.feedbackReportActionCopy,
                  icon: LucideIcons.copy,
                ),
                AppButton.secondary(
                  key: const Key('feedback_report_action_save'),
                  onPressed: _isSaving ? null : _saveReportFile,
                  label: l10n.feedbackReportActionSave,
                  tooltip: l10n.feedbackReportActionSave,
                  icon: LucideIcons.download,
                ),
                AppButton.secondary(
                  key: const Key('feedback_report_action_share'),
                  onPressed: _isSharing ? null : _shareReport,
                  label: l10n.feedbackReportActionShare,
                  tooltip: l10n.feedbackReportActionShare,
                  icon: DesignConstants.adaptiveShareIcon,
                ),
                AppButton.secondary(
                  key: const Key('feedback_report_action_email'),
                  onPressed: _isEmailing ? null : _openEmailDraft,
                  label: l10n.feedbackReportActionEmail,
                  tooltip: l10n.feedbackReportActionEmail,
                  icon: LucideIcons.mail,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
