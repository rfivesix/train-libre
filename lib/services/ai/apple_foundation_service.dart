import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'ai_cancellation.dart';
import '../ai_service.dart';

/// Service interfacing with Apple's native FoundationModels framework on iOS.
class AppleFoundationService {
  AppleFoundationService._({bool forceIosForTesting = false})
      : _forceIosForTesting = forceIosForTesting;
  static final AppleFoundationService instance = AppleFoundationService._();

  @visibleForTesting
  factory AppleFoundationService.forTesting() =>
      AppleFoundationService._(forceIosForTesting: true);

  final bool _forceIosForTesting;
  bool get _isIos => _forceIosForTesting || (!kIsWeb && Platform.isIOS);

  static const MethodChannel _channel = MethodChannel(
    'trainlibre.ai/apple_foundation',
  );

  int _nextRequestId = 0;

  /// Checks live availability, which may change in iOS settings at any time.
  /// [forceRefresh] remains for compatibility; results are no longer cached.
  Future<bool> isAvailable({bool forceRefresh = false}) async {
    if (!_isIos) return false;
    try {
      final available =
          await _channel.invokeMethod<bool>('isAvailable') ?? false;
      return available;
    } on PlatformException catch (e) {
      debugPrint('[AppleFoundationService] isAvailable error: $e');
      return false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Prewarms the Apple Foundation Models session in the background so the model
  /// is already cached in memory when the user triggers an analysis.
  Future<bool> prewarm({String? systemPrompt}) async {
    if (!_isIos) return false;
    try {
      return await _channel.invokeMethod<bool>('prewarm', {
            if (systemPrompt != null) 'systemPrompt': systemPrompt,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Whether this OS build can actually consume image attachments. Older
  /// FoundationModels builds accepted the field but silently ignored images.
  Future<bool> supportsImageInput() async {
    if (!_isIos) return false;
    try {
      return await _channel.invokeMethod<bool>('supportsImageInput') ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Sends a structured prompt (and optional base64 images) to Apple's on-device Foundation Model.
  /// [systemPrompt] specifies the model instructions separately from the user [prompt].
  Future<String> generateMealJson({
    required String prompt,
    String? systemPrompt,
    List<String>? imagesBase64,
    Duration? timeout,
  }) async {
    if (!_isIos) {
      throw UnsupportedError(
        'Apple Foundation Models are only available on iOS devices.',
      );
    }
    try {
      final requestId = '${++_nextRequestId}';
      final cancellation = AiCancellation.current;
      if (cancellation?.isCancelled ?? false) {
        throw const AiCancelledException();
      }
      final generation = _channel.invokeMethod<String>('generateMealJson', {
        'requestId': requestId,
        'prompt': prompt,
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
        'images': imagesBase64 ?? const <String>[],
      });
      void cancelNative() {
        unawaited(_channel.invokeMethod<void>(
            'cancel', {'requestId': requestId}).catchError((Object _) {}));
      }

      final pending = Future.any<String?>([
        generation,
        if (cancellation != null)
          cancellation.whenCancelled.then((_) {
            cancelNative();
            throw const AiCancelledException();
          }),
      ]);
      final response = await (timeout == null
          ? pending
          : pending.timeout(timeout, onTimeout: () {
              cancelNative();
              throw const AiTimeoutException();
            }));
      if (response == null || response.trim().isEmpty) {
        throw const AiParseException();
      }
      return response;
    } on PlatformException catch (e) {
      if (e.code == 'UNAVAILABLE' ||
          e.code == 'DEVICE_NOT_ELIGIBLE' ||
          e.code == 'APPLE_INTELLIGENCE_DISABLED' ||
          e.code == 'MODEL_NOT_READY' ||
          e.code == 'UNSUPPORTED_IOS_VERSION' ||
          e.code == 'FRAMEWORK_UNAVAILABLE') {
        throw const AiAppleUnavailableException();
      }
      if (e.code == 'CANCELLED') throw const AiCancelledException();
      if (e.code == 'RATE_LIMITED') throw const AiRateLimitException();
      if (e.code == 'INVALID_RESPONSE') throw const AiParseException();
      throw const AiAppleGenerationException();
    }
  }
}
