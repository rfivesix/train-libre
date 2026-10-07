import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service interfacing with Apple's native FoundationModels framework on iOS.
class AppleFoundationService {
  AppleFoundationService._();
  static final AppleFoundationService instance = AppleFoundationService._();

  static const MethodChannel _channel =
      MethodChannel('trainlibre.ai/apple_foundation');

  bool? _cachedAvailability;

  /// Checks whether Apple Foundation Models are supported and available on this device.
  Future<bool> isAvailable({bool forceRefresh = false}) async {
    if (!kIsWeb && !Platform.isIOS) return false;
    if (!forceRefresh && _cachedAvailability != null) {
      return _cachedAvailability!;
    }
    try {
      final available =
          await _channel.invokeMethod<bool>('isAvailable') ?? false;
      _cachedAvailability = available;
      return available;
    } on PlatformException catch (e) {
      debugPrint('[AppleFoundationService] isAvailable error: $e');
      _cachedAvailability = false;
      return false;
    } on MissingPluginException {
      _cachedAvailability = false;
      return false;
    } catch (_) {
      _cachedAvailability = false;
      return false;
    }
  }

  /// Prewarms the Apple Foundation Models session in the background so the model
  /// is already cached in memory when the user triggers an analysis.
  Future<bool> prewarm({String? systemPrompt}) async {
    if (!kIsWeb && !Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('prewarm', {
            if (systemPrompt != null) 'systemPrompt': systemPrompt,
          }) ??
          false;
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
  }) async {
    if (!kIsWeb && !Platform.isIOS) {
      throw UnsupportedError(
        'Apple Foundation Models are only available on iOS devices.',
      );
    }
    try {
      final response = await _channel.invokeMethod<String>(
        'generateMealJson',
        {
          'prompt': prompt,
          if (systemPrompt != null) 'systemPrompt': systemPrompt,
          'images': imagesBase64 ?? const <String>[],
        },
      );
      if (response == null || response.trim().isEmpty) {
        throw StateError('Apple Foundation Model returned an empty response.');
      }
      return response;
    } on PlatformException catch (e) {
      throw StateError(
        'Apple Foundation Model failed: ${e.message ?? e.code}',
      );
    }
  }
}
