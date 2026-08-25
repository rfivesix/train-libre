// lib/features/diary/presentation/dialogs/voice_dictation_sheet.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/haptic_feedback_service.dart';
import '../../../../services/voice/transcript_cleanup.dart';
import '../../../../services/voice/voice_dictation_service.dart';
import '../../../../services/voice/voice_dictation_settings.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';
import '../widgets/ai_neural_cloud_orb_widget.dart';
import '../widgets/animated_transcript_text.dart';

/// Opens the dictation sheet and returns the text the user accepted, or null.
///
/// A full-height sheet rather than a small panel: dictating is the whole task
/// while it is happening, and the transcript needs room to be read back before
/// it is trusted.
Future<String?> showVoiceDictationSheet({
  required BuildContext context,
  String? initialText,
  required String exampleHint,
}) {
  return showGlassBottomMenu<String>(
    context: context,
    expandToFullHeight: true,
    contentBuilder: (ctx, _) => _VoiceDictationView(
      initialText: initialText ?? '',
      exampleHint: exampleHint,
    ),
  );
}

enum _DictationPhase { idle, starting, listening, tidying, done }

class _VoiceDictationView extends StatefulWidget {
  final String initialText;
  final String exampleHint;

  const _VoiceDictationView({
    required this.initialText,
    required this.exampleHint,
  });

  @override
  State<_VoiceDictationView> createState() => _VoiceDictationViewState();
}

class _VoiceDictationViewState extends State<_VoiceDictationView> {
  final _editController = TextEditingController();

  _DictationPhase _phase = _DictationPhase.idle;
  String _liveTranscript = '';
  bool _cleanedSomething = false;
  bool _editing = false;
  double _level = 0;

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
    unawaited(_loadLocales());
  }

  @override
  void dispose() {
    unawaited(VoiceDictationService.instance.cancel());
    _editController.dispose();
    super.dispose();
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

  Future<void> _start() async {
    setState(() {
      _phase = _DictationPhase.starting;
      _cleanedSomething = false;
      _editing = false;
    });

    final chosen =
        _localeId ?? await VoiceDictationService.instance.systemLocaleId();
    if (!mounted) return;

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
    );

    if (!mounted) return;
    if (!started) {
      setState(() => _phase = _DictationPhase.idle);
      return;
    }
    HapticFeedbackService.instance.selectionFeedback();
    setState(() => _phase = _DictationPhase.listening);
  }

  String _merge(String spoken) =>
      _baseText.isEmpty ? spoken : '$_baseText $spoken';

  Future<void> _stop() async {
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
    setState(() {
      _cleanedSomething = cleaned.isNotEmpty && cleaned != raw;
      _liveTranscript = cleaned;
      _editController.text = cleaned;
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
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: isSelected
          ? const Icon(LucideIcons.check, size: 18, color: Color(0xFFC9EF00))
          : null,
      onTap: () => Navigator.of(ctx).pop(id ?? _systemSentinel),
    );
  }

  String _statusFor(AppLocalizations l10n) => switch (_phase) {
        _DictationPhase.idle => l10n.voiceTapToRecord,
        _DictationPhase.starting => l10n.voiceStarting,
        _DictationPhase.listening => l10n.voiceTapToFinish,
        _DictationPhase.tidying => l10n.voiceTidyingUp,
        _DictationPhase.done => l10n.voiceRetake,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? Colors.white : const Color(0xFF12120F);
    final muted = ink.withValues(alpha: 0.6);
    const lime = Color(0xFFC9EF00);

    final isListening = _phase == _DictationPhase.listening;
    final hasText = _liveTranscript.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Language chip — the one control that has to be reachable before
        // speaking, because getting it wrong wastes the whole recording.
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

        // The orb doubles as the record button: tap once to start, once to
        // stop. Holding meant a one-handed user could not do anything else,
        // and a slipped finger silently ended the sentence.
        //
        // It stands down while the transcript is being edited: the keyboard
        // takes most of the sheet, and the text is what matters then.
        if (!_editing)
          Expanded(
            flex: 4,
            child: Center(
              child: GestureDetector(
                onTap: _toggleRecording,
                behavior: HitTestBehavior.opaque,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  scale: isListening
                      ? 1.0 + ((_level.clamp(-2.0, 10.0) + 2) / 12) * 0.16
                      : 0.86,
                  child: AiNeuralCloudOrbWidget(
                    size: 200,
                    showAmbientGlow:
                        isListening || _phase == _DictationPhase.tidying,
                  ),
                ),
              ),
            ),
          ),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
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
        Text(
          widget.exampleHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w500,
            fontSize: 12.5,
            color: muted,
          ),
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

        const SizedBox(height: DesignConstants.spacingL),

        // Transcript: revealed as it is spoken, editable once it is finished.
        Expanded(
          flex: 5,
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
                    ? lime.withValues(alpha: 0.6)
                    : ink.withValues(alpha: 0.12),
              ),
            ),
            child: _editing
                ? TextField(
                    controller: _editController,
                    autofocus: true,
                    maxLines: null,
                    expands: false,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: 17, height: 1.4, color: ink),
                    decoration: InputDecoration.collapsed(
                      hintText: l10n.voiceTranscriptHint,
                      hintStyle: TextStyle(color: muted),
                    ),
                    onChanged: (value) => _liveTranscript = value,
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
                      child: AnimatedTranscriptText(
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
                        placeholderStyle: TextStyle(fontSize: 15, color: muted),
                      ),
                    ),
                  ),
          ),
        ),

        if (_cleanedSomething) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.sparkles, size: 13, color: lime),
              const SizedBox(width: 6),
              Text(
                l10n.voiceCleanedNotice,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: lime,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: DesignConstants.spacingL),
        AppButton.primary(
          onPressed: () async {
            final text =
                (_editing ? _editController.text : _liveTranscript).trim();
            await VoiceDictationService.instance.cancel();
            if (!context.mounted) return;
            Navigator.of(context).pop(text);
          },
          label: l10n.voiceApplyText,
          tooltip: l10n.voiceApplyText,
        ),
        const SizedBox(height: DesignConstants.spacingS),
      ],
    );
  }
}
