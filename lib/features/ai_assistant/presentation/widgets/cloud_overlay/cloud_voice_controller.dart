import 'dart:async';
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker, TickerProvider;

import '../../../../../generated/app_localizations.dart';
import '../../../../../services/voice/voice_dictation_service.dart';
import '../../../../../services/voice/voice_dictation_settings.dart';
import 'cloud_voice_waveform.dart';

/// Manages the full voice recording and simulation lifecycle for the AI cloud overlay.
class CloudVoiceController extends ChangeNotifier {
  final TickerProvider vsync;
  final VoidCallback? onUnfocus;
  final ValueChanged<String>? onShowMessage;
  final void Function(String text, {required bool sendNow}) onCommitText;
  final ValueGetter<String> getBaseText;

  bool _voiceStarting = false;
  bool _voiceRecording = false;
  bool _voiceStopping = false;
  bool _voiceSimulation = false;
  bool _voiceFinalizing = false;
  bool _sendVoiceAfterStop = false;
  int _voiceSessionId = 0;
  String _voiceBaseText = '';
  String _voiceTranscript = '';
  final List<VoiceWaveSample> _voiceLevelHistory = <VoiceWaveSample>[];
  Timer? _voiceSimulationTimer;
  double _latestVoiceLevel = 0;
  int _lastVoiceWaveSampleIndex = 0;
  late final Ticker _voiceWaveTicker;
  final ValueNotifier<double> _voiceWaveOffset = ValueNotifier<double>(0);
  Future<bool>? _iosSimulatorCheck;
  bool _isDisposed = false;

  CloudVoiceController({
    required this.vsync,
    required this.onCommitText,
    required this.getBaseText,
    this.onUnfocus,
    this.onShowMessage,
  }) {
    _voiceWaveTicker = vsync.createTicker((elapsed) {
      const sampleSpacing = 6.0;
      final position = elapsed.inMicroseconds * 0.000045;
      _voiceWaveOffset.value = position;
      final sampleIndex = (position / sampleSpacing).floor();
      if (sampleIndex > _lastVoiceWaveSampleIndex &&
          !_isDisposed &&
          (_voiceRecording || _voiceStarting)) {
        for (var index = _lastVoiceWaveSampleIndex + 1;
            index <= sampleIndex;
            index++) {
          _appendVoiceLevel(_latestVoiceLevel, index * sampleSpacing);
        }
        _lastVoiceWaveSampleIndex = sampleIndex;
        notifyListeners();
      }
    });
  }

  bool get isStarting => _voiceStarting;
  bool get isRecording => _voiceRecording;
  bool get isStopping => _voiceStopping;
  bool get isActive => _voiceStarting || _voiceRecording || _voiceStopping;
  double get latestVoiceLevel => _latestVoiceLevel;
  List<VoiceWaveSample> get levelHistory => _voiceLevelHistory;
  ValueNotifier<double> get waveOffset => _voiceWaveOffset;

  Future<bool> _isIosSimulator() {
    if (!kDebugMode || defaultTargetPlatform != TargetPlatform.iOS) {
      return Future<bool>.value(false);
    }
    return _iosSimulatorCheck ??= DeviceInfoPlugin()
        .iosInfo
        .then((info) => !info.isPhysicalDevice)
        .catchError((Object _) => false);
  }

  Future<void> _startSimulatedVoiceInput(int sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (_isDisposed || sessionId != _voiceSessionId) return;

    _voiceSimulation = true;
    _voiceStarting = false;
    _voiceRecording = true;
    _startVoiceWaveAnimation();
    notifyListeners();

    const sample = 'Das ist eine simulierte Spracheingabe im iOS-Simulator.';
    var elapsedMs = 0;
    _voiceSimulationTimer?.cancel();
    _voiceSimulationTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (timer) {
        if (_isDisposed || sessionId != _voiceSessionId || !_voiceSimulation) {
          timer.cancel();
          return;
        }
        elapsedMs += 80;
        final transcriptCharacters =
            ((elapsedMs - 450) / 34).floor().clamp(0, sample.length);
        final pulse = (math.sin(elapsedMs / 170) + 1) / 2;
        final variation = (math.sin(elapsedMs / 73) + 1) / 2;
        final level = 0.12 + pulse * 0.58 + variation * 0.22;
        _latestVoiceLevel = level;
        _voiceTranscript = sample.substring(0, transcriptCharacters);
        notifyListeners();
      },
    );
  }

  Future<void> start(BuildContext context) async {
    if (_voiceStarting || _voiceRecording || _voiceStopping || _isDisposed) {
      return;
    }

    final sessionId = ++_voiceSessionId;
    onUnfocus?.call();
    _voiceBaseText = getBaseText().trim();
    _voiceTranscript = '';
    _voiceLevelHistory.clear();
    _latestVoiceLevel = 0;
    _sendVoiceAfterStop = false;
    _voiceStarting = true;
    _voiceStopping = false;
    notifyListeners();

    final simulateVoice = await _isIosSimulator();
    if (_isDisposed || sessionId != _voiceSessionId) return;
    if (simulateVoice) {
      await _startSimulatedVoiceInput(sessionId);
      return;
    }

    final service = VoiceDictationService.instance;
    final availability = await service.prepare();
    if (_isDisposed || sessionId != _voiceSessionId) return;
    if (!availability.available) {
      _voiceStarting = false;
      notifyListeners();
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        final message = switch (availability.reason) {
          VoiceUnavailableReason.permissionDenied =>
            l10n.voiceUnavailablePermission,
          VoiceUnavailableReason.unsupported =>
            l10n.voiceUnavailableUnsupported,
          _ => l10n.voiceUnavailableFailed,
        };
        onShowMessage?.call(message);
      }
      return;
    }

    final localeId = await VoiceDictationSettings.instance.localeId();
    if (_isDisposed || sessionId != _voiceSessionId) return;
    final started = await service.start(
      localeId: localeId,
      onPartial: (text) {
        if (_isDisposed || sessionId != _voiceSessionId) return;
        _voiceTranscript = text;
        notifyListeners();
      },
      onFinal: (text) {
        if (_isDisposed || sessionId != _voiceSessionId) return;
        _voiceTranscript = text;
        notifyListeners();
      },
      onSoundLevel: (level) {
        if (_isDisposed || sessionId != _voiceSessionId) return;
        _latestVoiceLevel = level;
        notifyListeners();
      },
      onStopped: () => unawaited(stop(sessionId)),
    );
    if (_isDisposed || sessionId != _voiceSessionId) {
      if (started) unawaited(service.cancel());
      return;
    }
    if (!started) {
      _voiceStarting = false;
      notifyListeners();
      if (context.mounted) {
        onShowMessage?.call(
          AppLocalizations.of(context)!.voiceUnavailableFailed,
        );
      }
      return;
    }
    if (!service.isListening) {
      unawaited(stop(sessionId));
      return;
    }
    _voiceStarting = false;
    _voiceRecording = true;
    _startVoiceWaveAnimation();
    notifyListeners();
    if (service.lastRunUsedNetwork && context.mounted) {
      onShowMessage?.call(
        AppLocalizations.of(context)!.voiceNetworkNotice,
      );
    }
  }

  Future<void> stop([int? requestedSessionId]) async {
    final sessionId = requestedSessionId ?? _voiceSessionId;
    if (sessionId != _voiceSessionId || _voiceFinalizing || _isDisposed) return;
    if (!_voiceStarting && !_voiceRecording) return;

    _voiceFinalizing = true;
    _voiceStarting = false;
    _voiceStopping = true;
    notifyListeners();

    _voiceSimulationTimer?.cancel();
    _voiceWaveTicker.stop();
    if (!_voiceSimulation) {
      await VoiceDictationService.instance.stop();
    }
    await Future<void>.delayed(
      Duration(milliseconds: _voiceSimulation ? 120 : 450),
    );
    if (_isDisposed || sessionId != _voiceSessionId) return;

    final dictatedText = _voiceTranscript.trim();
    final combinedText = [
      if (_voiceBaseText.isNotEmpty) _voiceBaseText,
      if (dictatedText.isNotEmpty) dictatedText,
    ].join(' ');

    _voiceRecording = false;
    _voiceStopping = false;
    _voiceSimulation = false;
    _voiceFinalizing = false;
    final shouldSend = _sendVoiceAfterStop;
    _sendVoiceAfterStop = false;
    notifyListeners();

    onCommitText(combinedText, sendNow: shouldSend);
  }

  void _appendVoiceLevel(double level, double position) {
    _voiceLevelHistory.add(
      VoiceWaveSample(
        position: position,
        level: level.clamp(0.0, 1.0).toDouble(),
      ),
    );
    if (_voiceLevelHistory.length > 120) _voiceLevelHistory.removeAt(0);
  }

  void _startVoiceWaveAnimation() {
    _voiceWaveOffset.value = 0;
    _voiceLevelHistory.clear();
    _lastVoiceWaveSampleIndex = 0;
    _appendVoiceLevel(_latestVoiceLevel, 0);
    _voiceWaveTicker.start();
  }

  Future<void> send() async {
    if (_voiceStopping || (!_voiceStarting && !_voiceRecording)) return;
    if (_voiceFinalizing) {
      _sendVoiceAfterStop = true;
      return;
    }
    _sendVoiceAfterStop = true;
    await stop();
  }

  Future<void> cancel() async {
    if (!_voiceStarting && !_voiceRecording && !_voiceStopping) return;
    ++_voiceSessionId;
    _voiceFinalizing = false;
    _sendVoiceAfterStop = false;
    _voiceSimulationTimer?.cancel();
    _voiceWaveTicker.stop();
    final wasSimulating = _voiceSimulation;
    _voiceStarting = false;
    _voiceRecording = false;
    _voiceStopping = false;
    _latestVoiceLevel = 0;
    _voiceTranscript = '';
    _voiceSimulation = false;
    notifyListeners();
    if (!wasSimulating) await VoiceDictationService.instance.cancel();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _voiceSimulationTimer?.cancel();
    _voiceWaveTicker.dispose();
    _voiceWaveOffset.dispose();
    if ((_voiceStarting || _voiceRecording || _voiceStopping) &&
        !_voiceSimulation) {
      unawaited(VoiceDictationService.instance.cancel());
    }
    super.dispose();
  }
}
