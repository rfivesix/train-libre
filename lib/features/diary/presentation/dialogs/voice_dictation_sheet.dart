// lib/features/diary/presentation/dialogs/voice_dictation_sheet.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/haptic_feedback_service.dart';
import '../../../../services/telemetry/telemetry_service.dart';
import '../../../../services/telemetry/telemetry_buckets.dart';
import '../../../../services/voice/transcript_cleanup.dart';
import '../../../../services/voice/voice_dictation_service.dart';
import '../../../../services/voice/voice_dictation_settings.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';
import '../widgets/ai_neural_cloud_orb_widget.dart';
import '../widgets/animated_transcript_text.dart';

/// What the user decided to do with a finished transcript.
class VoiceDictationResult {
  final String text;

  /// True when they asked for the analysis to start straight away rather than
  /// returning to the viewfinder.
  final bool analyzeNow;

  const VoiceDictationResult({required this.text, required this.analyzeNow});
}

/// Opens the dictation sheet and returns what the user accepted, or null.
///
/// A full-height sheet rather than a small panel: dictating is the whole task
/// while it is happening, and the transcript needs room to be read back before
/// it is trusted.
Future<VoiceDictationResult?> showVoiceDictationSheet({
  required BuildContext context,
  String? initialText,
  required String exampleHint,
  required String analyzeLabel,
}) {
  return showGlassBottomMenu<VoiceDictationResult>(
    context: context,
    expandToFullHeight: true,
    contentBuilder: (ctx, _) => _VoiceDictationView(
      initialText: initialText ?? '',
      exampleHint: exampleHint,
      analyzeLabel: analyzeLabel,
    ),
  );
}

enum _DictationPhase { idle, starting, listening, tidying, done }

class _VoiceDictationView extends StatefulWidget {
  final String initialText;
  final String exampleHint;
  final String analyzeLabel;

  const _VoiceDictationView({
    required this.initialText,
    required this.exampleHint,
    required this.analyzeLabel,
  });

  @override
  State<_VoiceDictationView> createState() => _VoiceDictationViewState();
}

class _VoiceDictationViewState extends State<_VoiceDictationView> {
  final _editController = TextEditingController();
  final _editFocusNode = FocusNode();

  _DictationPhase _phase = _DictationPhase.idle;
  String _liveTranscript = '';
  bool _cleanedSomething = false;
  bool _editing = false;
  double _level = 0;

  /// Bullets from the AI pass, or null when it did not run or did not help.
  VoiceTranscriptSummary? _summary;

  /// Everything the user had before this session, kept in front of whatever
  /// they dictate now.
  late final String _baseText = widget.initialText.trim();

  String? _localeId;
  String _localeLabel = '';
  List<({String id, String name})> _locales = const [];

  @override
  void initState() {
    super.initState();
    _editController.text = _baseText;
    _liveTranscript = _baseText;
    _editFocusNode.addListener(_handleEditFocusChanged);
    unawaited(_loadLocales());
  }

  @override
  void dispose() {
    unawaited(VoiceDictationService.instance.cancel());
    _editFocusNode
      ..removeListener(_handleEditFocusChanged)
      ..dispose();
    _editController.dispose();
    super.dispose();
  }

  /// Leaving the field must also leave edit layout. Otherwise an iOS keyboard
  /// dismissal leaves the tall transcript editor in place and hides the orb.
  void _handleEditFocusChanged() {
    if (!_editFocusNode.hasFocus) _finishEditing();
  }

  void _finishEditing() {
    if (!mounted || !_editing) return;
    setState(() {
      _liveTranscript = _editController.text;
      _editing = false;
    });
  }

  Future<void> _loadLocales() async {
    final stored = await VoiceDictationSettings.instance.localeId();
    final locales = await VoiceDictationService.instance.availableLocales();
    final system = await VoiceDictationService.instance.systemLocaleId();
    if (!mounted) return;

    final effective = stored ?? system;
    setState(() {
      _locales = locales;
      _localeId = stored;
      _localeLabel = _labelFor(effective, locales);
    });
  }

  String _labelFor(
    String? id,
    List<({String id, String name})> locales,
  ) {
    if (id == null) return '';
    for (final locale in locales) {
      if (locale.id.toLowerCase() == id.toLowerCase()) return locale.name;
    }
    return id;
  }

  Future<void> _toggleRecording() async {
    if (_phase == _DictationPhase.listening) {
      await _stop();
      return;
    }
    if (_phase == _DictationPhase.starting ||
        _phase == _DictationPhase.tidying) {
      return;
    }
    await _start();
  }

  final Stopwatch _recordingStopwatch = Stopwatch();

  Future<void> _start() async {
    setState(() {
      _phase = _DictationPhase.starting;
      _cleanedSomething = false;
      _editing = false;
      // Stale from the previous run, and the cloud would open already swollen.
      _level = 0;
      // "Record again" starts over. Leaving the finished transcript on screen
      // meant it sat there looking accepted until the first new word replaced
      // it — and stayed for good if the user said nothing.
      _liveTranscript = _baseText;
      _editController.text = _baseText;
      _summary = null;
    });

    final chosen =
        _localeId ?? await VoiceDictationService.instance.systemLocaleId();
    if (!mounted) return;

    _recordingStopwatch
      ..reset()
      ..start();

    final started = await VoiceDictationService.instance.start(
      localeId: chosen,
      onPartial: (text) {
        if (!mounted) return;
        setState(() => _liveTranscript = _merge(text));
      },
      onFinal: (text) {
        if (!mounted) return;
        setState(() => _liveTranscript = _merge(text));
      },
      onSoundLevel: (level) {
        if (!mounted) return;
        setState(() => _level = level);
      },
      onStopped: _handleRecognizerStopped,
    );

    if (!mounted) return;
    if (!started) {
      _recordingStopwatch.stop();
      unawaited(TelemetryService.instance.trackVoiceDictationCompleted(
        durationBucket: '<5s',
        aiTidyUpEnabled: false,
        surface: 'ai_meal_capture',
        success: false,
        errorCode: 'start_failed',
      ));
      setState(() => _phase = _DictationPhase.idle);
      return;
    }
    setState(() => _phase = _DictationPhase.listening);
    // The native recognizer may have stopped during its startup handshake.
    // Do not leave the sheet visually recording when iOS has released the mic.
    if (!VoiceDictationService.instance.isListening) {
      unawaited(_stop());
    }
  }

  void _handleRecognizerStopped() {
    if (!mounted || _phase != _DictationPhase.listening) return;
    unawaited(_stop());
  }

  String _merge(String spoken) =>
      _baseText.isEmpty ? spoken : '$_baseText $spoken';

  /// Already 0 to 1 — `VoiceDictationService` normalises the platform scale.
  double get _normalizedLevel => _level.clamp(0.0, 1.0);


  /// True while the cloud should be a cloud rather than a resting circle.
  bool get _isRecordingShape =>
      _phase == _DictationPhase.starting ||
      _phase == _DictationPhase.listening ||
      _phase == _DictationPhase.tidying;

  Future<void> _stop() async {
    _recordingStopwatch.stop();
    final durationBucket =
        TelemetryBuckets.getVoiceDurationBucket(_recordingStopwatch.elapsed);
    unawaited(TelemetryService.instance.trackFeatureUsed(
      featureKey: FeatureKey.voiceDictationUsed,
    ));

    setState(() {
      _phase = _DictationPhase.tidying;
      _level = 0;
    });
    await VoiceDictationService.instance.stop();

    // A short beat before the tidied text lands: the recognizer delivers its
    // final result just after `stop`, and swapping the text underneath the
    // user mid-word looks like a glitch rather than a finishing touch.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    final raw = _liveTranscript.trim();
    final cleaned = TranscriptCleanup.clean(raw);
    // The local pass lands first and unconditionally: it costs nothing, needs
    // no network and no key, and it is what remains if the request below fails.
    setState(() {
      _cleanedSomething = cleaned.isNotEmpty && cleaned != raw;
      _liveTranscript = cleaned;
      _editController.text = cleaned;
    });

    if (cleaned.isEmpty) {
      unawaited(TelemetryService.instance.trackVoiceDictationCompleted(
        durationBucket: durationBucket,
        aiTidyUpEnabled: false,
        surface: 'ai_meal_capture',
        success: true,
      ));
      setState(() => _phase = _DictationPhase.done);
      HapticFeedbackService.instance.confirmationFeedback();
      return;
    }

    // Rules cannot fix a misheard food name — "Sriracha" comes back as "Sir
    // Ratscher" and no dictionary of filler words will ever catch that.
    final tidyEnabled = await VoiceDictationSettings.instance.isAiTidyEnabled();
    if (!mounted) return;
    if (!tidyEnabled) {
      unawaited(TelemetryService.instance.trackVoiceDictationCompleted(
        durationBucket: durationBucket,
        aiTidyUpEnabled: false,
        surface: 'ai_meal_capture',
        success: true,
      ));
      setState(() => _phase = _DictationPhase.done);
      HapticFeedbackService.instance.confirmationFeedback();
      return;
    }

    final summary = await AiService.instance.tidyVoiceTranscript(cleaned);
    if (!mounted) return;

    unawaited(TelemetryService.instance.trackVoiceDictationCompleted(
      durationBucket: durationBucket,
      aiTidyUpEnabled: true,
      surface: 'ai_meal_capture',
      success: true,
    ));

    setState(() {
      _summary = summary;
      if (summary != null) {
        _liveTranscript = summary.toMarkdown();
        _editController.text = _liveTranscript;
      }
      _phase = _DictationPhase.done;
    });
    HapticFeedbackService.instance.confirmationFeedback();
  }

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showGlassBottomMenu<String>(
      context: context,
      title: l10n.voiceLanguageTitle,
      contentBuilder: (ctx, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: DesignConstants.spacingM,
              ),
              child: Text(
                l10n.voiceLanguageHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView(
                shrinkWrap: true,
                children: [
                  _languageTile(ctx, null, l10n.voiceLanguageSystem),
                  for (final locale in _locales)
                    _languageTile(ctx, locale.id, locale.name),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (selected == null || !mounted) return;
    final id = selected == _systemSentinel ? null : selected;
    await VoiceDictationSettings.instance.setLocaleId(id);
    if (!mounted) return;
    final system = await VoiceDictationService.instance.systemLocaleId();
    if (!mounted) return;
    setState(() {
      _localeId = id;
      _localeLabel = _labelFor(id ?? system, _locales);
    });
  }

  static const String _systemSentinel = '__system__';

  Widget _languageTile(BuildContext ctx, String? id, String label) {
    final isSelected = id == null ? _localeId == null : _localeId == id;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final accent = isDark
        ? DesignConstants.brandAccentColor
        : DesignConstants.brandAccentColorLightMode;
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: isSelected
          ? Icon(LucideIcons.check, size: 18, color: accent)
          : null,
      onTap: () => Navigator.of(ctx).pop(id ?? _systemSentinel),
    );
  }

  /// The tidied transcript as one line per food, with whatever the user said
  /// about that food indented underneath it.
  Widget _buildBullets(
    VoiceTranscriptSummary summary,
    Color ink,
    Color muted,
    Color accentColor,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final bullet in summary.bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7, right: 10),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bullet.text,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 17,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
                // Indented under its food rather than appended to the line: a
                // qualifier read as part of the name would send the analysis
                // looking for a product called "Hähnchen Trockengewicht".
                for (final note in bullet.notes)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 8),
                          child: Container(
                            width: 10,
                            height: 1.5,
                            color: muted,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            note,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (summary.context != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              summary.context!,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: muted,
              ),
            ),
          ),
        const SizedBox(height: 6),
        // Shown so the wait can be judged rather than guessed at.
        Text(
          l10n.voiceTidiedIn(
              (summary.elapsed.inMilliseconds / 1000).toStringAsFixed(1)),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: muted.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Future<void> _finish({required bool analyzeNow}) async {
    final text = (_editing ? _editController.text : _liveTranscript).trim();
    await VoiceDictationService.instance.cancel();
    if (!mounted) return;
    Navigator.of(context).pop(
      VoiceDictationResult(text: text, analyzeNow: analyzeNow),
    );
  }

  String _statusFor(AppLocalizations l10n) => switch (_phase) {
        _DictationPhase.idle => l10n.voiceTapToRecord,
        _DictationPhase.starting => l10n.voiceStarting,
        _DictationPhase.listening => l10n.voiceTapToFinish,
        _DictationPhase.tidying => l10n.voiceTidyingUp,
        _DictationPhase.done => l10n.voiceRetake,
      };

  Widget _buildRecordingControls(
    BuildContext context,
    AppLocalizations l10n,
    Color ink,
    Color muted,
    Color accentColor,
    ThemeData theme,
  ) {
    if (_editing) {
      return KeyedSubtree(
        key: const ValueKey('editing_compact_controls'),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: DesignConstants.spacingS),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _finishEditing,
              style: TextButton.styleFrom(foregroundColor: ink),
              child: Text(
                l10n.doneButtonLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('recording_controls'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: Text(
              _statusFor(l10n),
              key: ValueKey(_phase),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: _phase == _DictationPhase.idle
                ? Text(
                    widget.exampleHint,
                    key: const ValueKey('hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                      color: muted,
                    ),
                  )
                : const SizedBox(height: 16, key: ValueKey('empty_hint')),
          ),
          if (VoiceDictationService.instance.lastRunUsedNetwork) ...[
            const SizedBox(height: 8),
            Text(
              l10n.voiceNetworkNotice,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.orange.withValues(alpha: 0.9),
              ),
            ),
          ],
          const SizedBox(height: DesignConstants.spacingM),
          SizedBox(
            height: 170,
            child: Center(
              child: AiNeuralCloudOrbWidget(
                size: 170,
                onTap: _toggleRecording,
                accentColor: _phase == _DictationPhase.tidying
                    ? accentColor
                    : DesignConstants.brandRedColor,
                morph: _isRecordingShape ? 1.0 : 0.0,
                energy: _isRecordingShape ? _normalizedLevel : 0.0,
                flowSpeed: 0.55,
                tint: _isRecordingShape ? 0.4 : 0.0,
                tintEnergyGain: _isRecordingShape ? 0.4 : 0.0,
                showAmbientGlow: true,
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
        ],
      ),
    );
  }

  Widget _buildDoneActions(
    BuildContext context,
    AppLocalizations l10n,
    Color ink,
    Color muted,
    Color accentColor,
  ) {
    return KeyedSubtree(
      key: const ValueKey('done_actions'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_cleanedSomething) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.sparkles, size: 13, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  l10n.voiceCleanedNotice,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingM),
          ],
          AppButton.primary(
            onPressed: () => _finish(analyzeNow: true),
            label: widget.analyzeLabel,
            tooltip: widget.analyzeLabel,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedbackService.instance.lightImpact();
                    _start();
                  },
                  icon: const Icon(LucideIcons.rotate_ccw, size: 15),
                  label: Text(
                    l10n.voiceRetake,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: muted,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 14,
                color: muted.withValues(alpha: 0.2),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => _finish(analyzeNow: false),
                  style: TextButton.styleFrom(
                    foregroundColor: muted,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    l10n.voiceApplyText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? Colors.white : const Color(0xFF12120F);
    final muted = ink.withValues(alpha: 0.6);
    final accentColor = isDark
        ? DesignConstants.brandAccentColor
        : DesignConstants.brandAccentColorLightMode;

    final isListening = _phase == _DictationPhase.listening;
    final hasText = _liveTranscript.trim().isNotEmpty;
    final isDone = _phase == _DictationPhase.done && hasText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Language chip — reachable before speaking so language is correct.
        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            onPressed: _locales.isEmpty ? null : _pickLanguage,
            icon: const Icon(LucideIcons.languages, size: 16),
            label: Text(
              _localeLabel.isEmpty
                  ? l10n.voiceLanguage
                  : '${l10n.voiceLanguage}: $_localeLabel',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: TextButton.styleFrom(foregroundColor: muted),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),

        // Transcript card: positioned in the upper portion for primary readability.
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusL),
              border: Border.all(
                color: isListening
                    ? DesignConstants.brandRedColor.withValues(alpha: 0.6)
                    : ink.withValues(alpha: 0.12),
              ),
            ),
            child: _editing
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _finishEditing,
                            style: TextButton.styleFrom(
                              foregroundColor: ink,
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(
                              l10n.doneButtonLabel,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: TextField(
                          controller: _editController,
                          focusNode: _editFocusNode,
                          autofocus: true,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                              fontSize: 17, height: 1.4, color: ink),
                          decoration: InputDecoration.collapsed(
                            hintText: l10n.voiceTranscriptHint,
                            hintStyle: TextStyle(color: muted),
                          ),
                          onChanged: (value) => _liveTranscript = value,
                          onTapOutside: (_) => _editFocusNode.unfocus(),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: GestureDetector(
                      onTap: hasText
                          ? () => setState(() {
                                _editController.text = _liveTranscript;
                                _editing = true;
                              })
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: _summary != null
                          ? _buildBullets(_summary!, ink, muted, accentColor)
                          : AnimatedTranscriptText(
                              text: _liveTranscript,
                              placeholder: _phase == _DictationPhase.done
                                  ? l10n.voiceNothingHeard
                                  : l10n.voiceTranscriptHint,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 17,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                              placeholderStyle:
                                  TextStyle(fontSize: 15, color: muted),
                            ),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: DesignConstants.spacingM),

        // Bottom area:
        // Shows the recording orb while dictating/processing, and transitions
        // to the action buttons ("Analyze text" / "Use this text" / "Record again")
        // once transcription and cleanup have finished.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isDone
              ? _buildDoneActions(context, l10n, ink, muted, accentColor)
              : _buildRecordingControls(
                  context,
                  l10n,
                  ink,
                  muted,
                  accentColor,
                  theme,
                ),
        ),
      ],
    );
  }
}
