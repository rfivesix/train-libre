import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../services/ai/apple_foundation_service.dart';
import '../../../services/ai_service.dart';

/// Lightweight in-memory turn passed as conversation context during the UI demo.
class AiOverlayLiveChatTurn {
  final String prompt;
  final String response;

  const AiOverlayLiveChatTurn({
    required this.prompt,
    required this.response,
  });
}

class AiOverlayChatConfiguration {
  const AiOverlayChatConfiguration(this.provider, this.model, this.apiKey);
  final AiProvider provider;
  final String model;
  final String apiKey;
}

/// Provider transport for the overlay. It uses the credentials and models
/// already configured in [AiService]. Approval and persistence are enforced
/// by the caller before this transport receives app data.
class AiOverlayLiveChatService {
  AiOverlayLiveChatService._();

  static final AiOverlayLiveChatService instance = AiOverlayLiveChatService._();

  static const String _defaultSystemPrompt =
      'Du bist ein hilfreicher, direkter KI-Assistent in der Fitness- und '
      'Ernährungs-App Train Libre. Antworte natürlich, präzise und in der '
      'Sprache des Nutzers.';

  /// Streams a chat response for [prompt] using the currently configured AI model.
  Stream<String> streamChat({
    required String prompt,
    List<AiOverlayLiveChatTurn> history = const [],
    AiOverlayChatConfiguration? configuration,
    Future<void> Function()? onDispatch,
    bool smoothWords = true,
  }) async* {
    final resolved = configuration ?? await resolveConfiguration();
    final provider = resolved.provider;
    final apiKey = resolved.apiKey;
    final model = resolved.model;
    final timeoutSeconds = await AiService.instance.getAiTimeoutSeconds();
    final timeout = Duration(seconds: timeoutSeconds.clamp(15, 300));

    final rawChunks = _streamFromProvider(
      provider: provider,
      apiKey: apiKey,
      model: model,
      prompt: prompt,
      history: history,
      timeout: timeout,
      onDispatch: onDispatch,
    );

    if (!smoothWords) {
      yield* rawChunks;
      return;
    }

    await for (final chunk in _smoothWordStream(rawChunks)) {
      yield chunk;
    }
  }

  Future<AiOverlayChatConfiguration> resolveConfiguration() async {
    final resolved = await _resolveEffectiveProvider();
    return AiOverlayChatConfiguration(
        resolved.provider,
        await AiService.instance.getSelectedModel(resolved.provider),
        resolved.apiKey);
  }

  /// Resolves the selected provider, falling back to another configured
  /// provider if the active default has no credentials on this device.
  Future<({AiProvider provider, String apiKey})>
      _resolveEffectiveProvider() async {
    final selected = await AiService.instance.getSelectedProvider();

    if (selected == AiProvider.appleFoundation) {
      if (await AppleFoundationService.instance.isAvailable()) {
        return (provider: AiProvider.appleFoundation, apiKey: '');
      }
      final fallback = await _findConfiguredCloudProvider();
      if (fallback != null) return fallback;
      throw const AiUnsupportedFeatureException(
        'Apple Intelligence ist auf diesem Gerät nicht verfügbar und es ist '
        'kein API-Schlüssel in den KI-Einstellungen hinterlegt.',
      );
    }

    if (selected == AiProvider.ollama) {
      return (provider: AiProvider.ollama, apiKey: '');
    }

    if (selected == AiProvider.custom) {
      final key = await AiService.instance.getApiKey(AiProvider.custom) ?? '';
      return (provider: AiProvider.custom, apiKey: key);
    }

    final key = await AiService.instance.getApiKey(selected);
    if (key != null && key.trim().isNotEmpty) {
      return (provider: selected, apiKey: key.trim());
    }

    final fallback = await _findConfiguredCloudProvider();
    if (fallback != null) return fallback;

    if (await AppleFoundationService.instance.isAvailable()) {
      return (provider: AiProvider.appleFoundation, apiKey: '');
    }

    throw const AiKeyMissingException();
  }

  Future<({AiProvider provider, String apiKey})?>
      _findConfiguredCloudProvider() async {
    const cloudProviders = <AiProvider>[
      AiProvider.openai,
      AiProvider.gemini,
      AiProvider.anthropic,
      AiProvider.mistral,
      AiProvider.xai,
    ];
    for (final provider in cloudProviders) {
      final key = await AiService.instance.getApiKey(provider);
      if (key != null && key.trim().isNotEmpty) {
        return (provider: provider, apiKey: key.trim());
      }
    }
    return null;
  }

  /// Ensures providers that emit multi-word chunks (such as Gemini SSE or
  /// Apple Intelligence) still reveal smoothly word-by-word in the UI while
  /// passing single-token chunks through without extra latency.
  Stream<String> _smoothWordStream(Stream<String> source) async* {
    final wordPiecesPattern = RegExp(r'\S+\s*|\s+');
    await for (final chunk in source) {
      if (chunk.isEmpty) continue;
      final pieces = wordPiecesPattern
          .allMatches(chunk)
          .map((m) => m.group(0)!)
          .toList(growable: false);
      if (pieces.length <= 1) {
        yield chunk;
        continue;
      }
      for (var i = 0; i < pieces.length; i++) {
        yield pieces[i];
        if (i < pieces.length - 1 && pieces[i].trim().isNotEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 32));
        }
      }
    }
  }

  Stream<String> _streamFromProvider({
    required AiProvider provider,
    required String apiKey,
    required String model,
    required String prompt,
    required List<AiOverlayLiveChatTurn> history,
    required Duration timeout,
    Future<void> Function()? onDispatch,
    bool modelRefreshAttempted = false,
  }) async* {
    try {
      switch (provider) {
        case AiProvider.appleFoundation:
          yield* _streamAppleFoundation(
            prompt: prompt,
            history: history,
            timeout: timeout,
            onDispatch: onDispatch,
          );
        case AiProvider.openai:
          yield* _streamOpenAiCompatible(
            provider: provider,
            endpoint: 'https://api.openai.com/v1/chat/completions',
            apiKey: apiKey,
            model: _normalizeOpenAiModelId(model),
            prompt: prompt,
            history: history,
            timeout: timeout,
            onDispatch: onDispatch,
          );
        case AiProvider.mistral:
          yield* _streamOpenAiCompatible(
            provider: provider,
            endpoint: 'https://api.mistral.ai/v1/chat/completions',
            apiKey: apiKey,
            model: model,
            prompt: prompt,
            history: history,
            timeout: timeout,
            onDispatch: onDispatch,
          );
        case AiProvider.xai:
          yield* _streamOpenAiCompatible(
            provider: provider,
            endpoint: 'https://api.x.ai/v1/chat/completions',
            apiKey: apiKey,
            model: model,
            prompt: prompt,
            history: history,
            timeout: timeout,
            onDispatch: onDispatch,
          );
        case AiProvider.ollama:
          final customUrl = await AiService.instance.getCustomBaseUrl();
          final endpoint = _resolveOpenAiEndpoint(
            customUrl,
            defaultBaseUrl: 'http://localhost:11434/v1',
          );
          yield* _streamOpenAiCompatible(
            provider: provider,
            endpoint: endpoint,
            apiKey: apiKey,
            model: model,
            prompt: prompt,
            history: history,
            timeout: timeout,
            onDispatch: onDispatch,
          );
        case AiProvider.custom:
          final customUrl = await AiService.instance.getCustomBaseUrl();
          if (customUrl == null || customUrl.trim().isEmpty) {
            throw const AiNetworkException(
              'Keine Basis-URL für den benutzerdefinierten KI-Anbieter konfiguriert.',
            );
          }
          final endpoint = _resolveOpenAiEndpoint(
            customUrl,
            defaultBaseUrl: customUrl,
          );
          yield* _streamOpenAiCompatible(
            provider: provider,
            endpoint: endpoint,
            apiKey: apiKey,
            model: model,
            prompt: prompt,
            history: history,
            timeout: timeout,
            onDispatch: onDispatch,
          );
        case AiProvider.gemini:
          yield* _streamGemini(
            apiKey: apiKey,
            model: model,
            prompt: prompt,
            history: history,
            timeout: timeout,
            onDispatch: onDispatch,
          );
        case AiProvider.anthropic:
          yield* _streamAnthropic(
            apiKey: apiKey,
            model: model,
            prompt: prompt,
            history: history,
            timeout: timeout,
            onDispatch: onDispatch,
          );
      }
    } on AiNetworkException catch (e) {
      if (onDispatch == null &&
          !modelRefreshAttempted &&
          provider != AiProvider.ollama &&
          provider != AiProvider.custom &&
          provider != AiProvider.appleFoundation &&
          RegExp(
            r'(model not found|model does not exist|unknown model|invalid model|model is not supported|not_found_error)',
            caseSensitive: false,
          ).hasMatch(e.message)) {
        final options = await AiService.instance.loadModelOptions(provider);
        final alternatives =
            options.options.where((option) => option.id != model);
        if (alternatives.isNotEmpty) {
          final fallbackModel = alternatives.first.id;
          await AiService.instance.setSelectedModel(provider, fallbackModel);
          yield* _streamFromProvider(
            provider: provider,
            apiKey: apiKey,
            model: fallbackModel,
            prompt: prompt,
            history: history,
            timeout: timeout,
            onDispatch: onDispatch,
            modelRefreshAttempted: true,
          );
          return;
        }
      }
      rethrow;
    }
  }

  Stream<String> _streamAppleFoundation({
    required String prompt,
    required List<AiOverlayLiveChatTurn> history,
    required Duration timeout,
    Future<void> Function()? onDispatch,
  }) async* {
    final fullPrompt = StringBuffer();
    if (history.isNotEmpty) {
      final recent =
          history.length > 6 ? history.sublist(history.length - 6) : history;
      for (final turn in recent) {
        if (turn.prompt.trim().isEmpty) continue;
        fullPrompt.writeln('Nutzer: ${turn.prompt.trim()}');
        if (turn.response.trim().isNotEmpty) {
          fullPrompt.writeln('Assistent: ${turn.response.trim()}');
        }
      }
      fullPrompt.writeln();
      fullPrompt.write('Nutzer: $prompt');
    } else {
      fullPrompt.write(prompt);
    }

    if (onDispatch != null) await onDispatch();
    final response = await AppleFoundationService.instance
        .generateMealJson(
          prompt: fullPrompt.toString(),
          systemPrompt: _defaultSystemPrompt,
        )
        .timeout(timeout);
    yield response;
  }

  Stream<String> _streamOpenAiCompatible({
    required AiProvider provider,
    required String endpoint,
    required String apiKey,
    required String model,
    required String prompt,
    required List<AiOverlayLiveChatTurn> history,
    required Duration timeout,
    Future<void> Function()? onDispatch,
  }) async* {
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _defaultSystemPrompt},
      for (final turn in history)
        if (turn.prompt.trim().isNotEmpty) ...[
          {'role': 'user', 'content': turn.prompt},
          if (turn.response.trim().isNotEmpty)
            {'role': 'assistant', 'content': turn.response},
        ],
      {'role': 'user', 'content': prompt},
    ];

    final isOpenAi = provider == AiProvider.openai;
    final isReasoningModel = isOpenAi && _isOpenAiReasoningModel(model);

    Map<String, dynamic> buildRequestMap({
      bool includeReasoningEffort = true,
      bool useLegacyMaxTokens = false,
    }) {
      final legacyFamily = useLegacyMaxTokens ||
          !isOpenAi ||
          model.toLowerCase().startsWith('gpt-3') ||
          model.toLowerCase().startsWith('gpt-4') ||
          model.toLowerCase().startsWith('text-');
      return <String, dynamic>{
        'model': model,
        'messages': messages,
        'stream': true,
        if (legacyFamily) 'max_tokens': 4096 else 'max_completion_tokens': 8192,
        if (isReasoningModel && includeReasoningEffort)
          'reasoning_effort': 'low',
      };
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    };

    final client = http.Client();
    try {
      var requestMap = buildRequestMap();
      var streamedResponse = await _sendStreamingPost(
        client: client,
        uri: Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(requestMap),
        timeout: timeout,
        onDispatch: onDispatch,
      );

      if (streamedResponse.statusCode == 400) {
        final errorBody =
            await streamedResponse.stream.bytesToString().timeout(timeout);
        final lowerError =
            (_extractErrorMessage(errorBody) ?? errorBody).toLowerCase();

        if (lowerError.contains('reasoning_effort') ||
            lowerError.contains('unrecognized request argument')) {
          requestMap = buildRequestMap(includeReasoningEffort: false);
          streamedResponse = await _sendStreamingPost(
            client: client,
            uri: Uri.parse(endpoint),
            headers: headers,
            body: jsonEncode(requestMap),
            timeout: timeout,
            onDispatch: onDispatch,
          );
        } else if (lowerError.contains('max_completion_tokens')) {
          requestMap = buildRequestMap(
            includeReasoningEffort: false,
            useLegacyMaxTokens: true,
          );
          streamedResponse = await _sendStreamingPost(
            client: client,
            uri: Uri.parse(endpoint),
            headers: headers,
            body: jsonEncode(requestMap),
            timeout: timeout,
            onDispatch: onDispatch,
          );
        } else {
          _throwForStatus(streamedResponse.statusCode, errorBody);
        }
      }

      if (streamedResponse.statusCode != 200) {
        final errorBody =
            await streamedResponse.stream.bytesToString().timeout(timeout);
        _throwForStatus(streamedResponse.statusCode, errorBody);
      }

      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final rawLine in lines.timeout(timeout)) {
        final line = rawLine.trim();
        if (line.isEmpty || !line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty) continue;
        if (payload == '[DONE]') break;

        Map<String, dynamic> decoded;
        try {
          decoded = jsonDecode(payload) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }

        final choices = decoded['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) continue;
        final choice = choices.first;
        if (choice is! Map<String, dynamic>) continue;

        final delta = choice['delta'];
        if (delta is Map<String, dynamic>) {
          final content = delta['content'];
          if (content is String && content.isNotEmpty) {
            yield content;
          } else if (content is List) {
            for (final part in content) {
              if (part is Map<String, dynamic>) {
                final text = part['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              }
            }
          }
        } else {
          final message = choice['message'];
          if (message is Map<String, dynamic>) {
            final content = message['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          }
        }
      }
    } on TimeoutException {
      throw const AiTimeoutException();
    } on SocketException catch (e) {
      throw AiNetworkException('Netzwerkfehler: ${e.message}');
    } finally {
      client.close();
    }
  }

  Stream<String> _streamAnthropic({
    required String apiKey,
    required String model,
    required String prompt,
    required List<AiOverlayLiveChatTurn> history,
    required Duration timeout,
    Future<void> Function()? onDispatch,
  }) async* {
    final messages = <Map<String, dynamic>>[
      for (final turn in history)
        if (turn.prompt.trim().isNotEmpty &&
            turn.response.trim().isNotEmpty) ...[
          {'role': 'user', 'content': turn.prompt},
          {'role': 'assistant', 'content': turn.response},
        ],
      {'role': 'user', 'content': prompt},
    ];

    final request = <String, dynamic>{
      'model': model,
      'system': _defaultSystemPrompt,
      'max_tokens': 2000,
      'stream': true,
      'messages': messages,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    };

    final client = http.Client();
    try {
      final streamedResponse = await _sendStreamingPost(
        client: client,
        uri: Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: headers,
        body: jsonEncode(request),
        timeout: timeout,
        onDispatch: onDispatch,
      );

      if (streamedResponse.statusCode != 200) {
        final errorBody =
            await streamedResponse.stream.bytesToString().timeout(timeout);
        _throwForStatus(streamedResponse.statusCode, errorBody);
      }

      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final rawLine in lines.timeout(timeout)) {
        final line = rawLine.trim();
        if (line.isEmpty || !line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty || payload == '[DONE]') continue;

        Map<String, dynamic> decoded;
        try {
          decoded = jsonDecode(payload) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }

        final type = decoded['type'] as String?;
        if (type == 'content_block_delta') {
          final delta = decoded['delta'] as Map<String, dynamic>?;
          if (delta?['type'] == 'text_delta') {
            final text = delta?['text'] as String?;
            if (text != null && text.isNotEmpty) {
              yield text;
            }
          }
        } else if (type == 'error') {
          final error = decoded['error'] as Map<String, dynamic>?;
          final msg = error?['message'] as String? ?? 'Anthropic stream error';
          throw AiNetworkException(msg);
        } else if (type == 'message_stop') {
          break;
        }
      }
    } on TimeoutException {
      throw const AiTimeoutException();
    } on SocketException catch (e) {
      throw AiNetworkException('Netzwerkfehler: ${e.message}');
    } finally {
      client.close();
    }
  }

  Stream<String> _streamGemini({
    required String apiKey,
    required String model,
    required String prompt,
    required List<AiOverlayLiveChatTurn> history,
    required Duration timeout,
    Future<void> Function()? onDispatch,
  }) async* {
    final candidates = _geminiModelCandidates(model);
    final routes = <(String, String)>[
      for (final candidate in candidates)
        for (final version in const ['v1beta', 'v1']) (candidate, version),
    ];

    Map<String, dynamic> buildRequest({
      required String candidate,
      required bool includeThinkingConfig,
      required bool useSystemInstruction,
    }) {
      final contents = <Map<String, dynamic>>[
        for (final turn in history)
          if (turn.prompt.trim().isNotEmpty &&
              turn.response.trim().isNotEmpty) ...[
            {
              'role': 'user',
              'parts': [
                {'text': turn.prompt},
              ],
            },
            {
              'role': 'model',
              'parts': [
                {'text': turn.response},
              ],
            },
          ],
        {
          'role': 'user',
          'parts': [
            {
              'text': useSystemInstruction
                  ? prompt
                  : '$_defaultSystemPrompt\n\n$prompt',
            },
          ],
        },
      ];

      return <String, dynamic>{
        if (useSystemInstruction)
          'systemInstruction': {
            'parts': [
              {'text': _defaultSystemPrompt},
            ],
          },
        'contents': contents,
        'generationConfig': {
          'maxOutputTokens': 4096,
          if (includeThinkingConfig &&
              candidate.toLowerCase().startsWith('gemini-2.5-flash'))
            'thinkingConfig': {
              'thinkingBudget': 0,
            },
        },
      };
    }

    final client = http.Client();
    try {
      http.StreamedResponse? activeResponse;
      String? lastErrorBody;
      int lastStatusCode = 400;

      for (final (candidate, version) in routes) {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/$version/models/$candidate:streamGenerateContent?alt=sse&key=$apiKey',
        );
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        };

        var response = await _sendStreamingPost(
          client: client,
          uri: uri,
          headers: headers,
          body: jsonEncode(
            buildRequest(
              candidate: candidate,
              includeThinkingConfig: true,
              useSystemInstruction: version == 'v1beta',
            ),
          ),
          timeout: timeout,
          onDispatch: onDispatch,
        );

        if (response.statusCode == 400) {
          final errBody =
              await response.stream.bytesToString().timeout(timeout);
          final lower =
              (_extractErrorMessage(errBody) ?? errBody).toLowerCase();
          if (lower.contains('thinking') ||
              lower.contains('systeminstruction') ||
              lower.contains('unknown field')) {
            response = await _sendStreamingPost(
              client: client,
              uri: uri,
              headers: headers,
              body: jsonEncode(
                buildRequest(
                  candidate: candidate,
                  includeThinkingConfig: false,
                  useSystemInstruction: false,
                ),
              ),
              timeout: timeout,
              onDispatch: onDispatch,
            );
          } else {
            lastStatusCode = response.statusCode;
            lastErrorBody = errBody;
            if (lower.contains('model') || lower.contains('version')) {
              continue;
            }
            _throwForStatus(lastStatusCode, lastErrorBody);
          }
        }

        if (response.statusCode == 200) {
          activeResponse = response;
          break;
        }

        lastStatusCode = response.statusCode;
        lastErrorBody = await response.stream.bytesToString().timeout(timeout);
        if (response.statusCode == 404) {
          continue;
        }
        _throwForStatus(lastStatusCode, lastErrorBody);
      }

      if (activeResponse == null) {
        _throwForStatus(lastStatusCode, lastErrorBody ?? '');
      }

      final lines = activeResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final rawLine in lines.timeout(timeout)) {
        final line = rawLine.trim();
        if (line.isEmpty || !line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty || payload == '[DONE]') continue;

        Map<String, dynamic> decoded;
        try {
          decoded = jsonDecode(payload) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }

        final candidatesList = decoded['candidates'] as List<dynamic>?;
        if (candidatesList == null || candidatesList.isEmpty) continue;
        final firstCandidate = candidatesList.first;
        if (firstCandidate is! Map<String, dynamic>) continue;
        final content = firstCandidate['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts == null) continue;

        for (final part in parts) {
          if (part is! Map<String, dynamic>) continue;
          if (part['thought'] == true) continue;
          final text = part['text'] as String?;
          if (text != null && text.isNotEmpty) {
            yield text;
          }
        }
      }
    } on TimeoutException {
      throw const AiTimeoutException();
    } on SocketException catch (e) {
      throw AiNetworkException('Netzwerkfehler: ${e.message}');
    } finally {
      client.close();
    }
  }

  Future<http.StreamedResponse> _sendStreamingPost({
    required http.Client client,
    required Uri uri,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
    Future<void> Function()? onDispatch,
  }) async {
    final request = http.Request('POST', uri)
      ..headers.addAll(headers)
      ..body = body;
    final response = await client.send(request).timeout(timeout);
    if (onDispatch != null) await onDispatch();
    return response;
  }

  String _resolveOpenAiEndpoint(
    String? customUrl, {
    required String defaultBaseUrl,
  }) {
    final base = (customUrl != null && customUrl.trim().isNotEmpty)
        ? customUrl.trim()
        : defaultBaseUrl;
    final trimmed = base.replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/chat/completions')) {
      return trimmed;
    }
    if (trimmed == 'http://localhost:11434' ||
        trimmed == 'http://127.0.0.1:11434') {
      return '$trimmed/v1/chat/completions';
    }
    return '$trimmed/chat/completions';
  }

  bool _isOpenAiReasoningModel(String modelId) {
    final id = modelId.toLowerCase();
    return id.startsWith('o1') ||
        id.startsWith('o3') ||
        id.startsWith('o4') ||
        id.startsWith('gpt-5') ||
        id.startsWith('gpt-6') ||
        id.contains('-luna') ||
        id.contains('-terra') ||
        id.contains('-sol') ||
        id.contains('reasoning') ||
        id.contains('thinking');
  }

  String _normalizeOpenAiModelId(String modelId) {
    final lower = modelId.toLowerCase();
    final match =
        RegExp(r'^([a-z0-9.\-]+?)-\d{4}-\d{2}-\d{2}$').firstMatch(lower);
    if (match != null) return match.group(1)!;
    return modelId;
  }

  List<String> _geminiModelCandidates(String model) {
    final normalized =
        model.startsWith('models/') ? model.substring('models/'.length) : model;
    final candidates = <String>[normalized];
    const aliasFallbacks = <String, List<String>>{
      'gemini-flash-latest': ['gemini-2.5-flash', 'gemini-2.0-flash'],
      'gemini-pro-latest': ['gemini-2.5-pro', 'gemini-1.5-pro'],
      'gemini-flash-lite-latest': ['gemini-2.5-flash-lite'],
    };
    final mapped = aliasFallbacks[normalized];
    if (mapped != null) candidates.addAll(mapped);
    if (normalized.endsWith('-latest')) {
      candidates.add(normalized.replaceFirst(RegExp(r'-latest$'), ''));
    }
    return candidates.toSet().toList(growable: false);
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'] as String?;
          if (message != null && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Never _throwForStatus(int statusCode, String body) {
    if (statusCode == 401 || statusCode == 403) {
      throw const AiAuthException();
    }
    if (statusCode == 429) {
      throw const AiRateLimitException();
    }
    final message = _extractErrorMessage(body);
    throw AiNetworkException(
      message != null
          ? 'API returned status $statusCode: $message'
          : 'API returned status $statusCode',
    );
  }
}
