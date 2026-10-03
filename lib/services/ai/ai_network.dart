part of '../ai_service.dart';

extension AiNetwork on AiService {
  int? _tokenCount(dynamic value) => value is int && value >= 0 ? value : null;

  AiTokenUsage? _openAiUsage(Map<String, dynamic> json) {
    final usage = json['usage'];
    if (usage is! Map) return null;
    return AiTokenUsage(
      inputTokens: _tokenCount(usage['prompt_tokens']),
      outputTokens: _tokenCount(usage['completion_tokens']),
      totalTokens: _tokenCount(usage['total_tokens']),
    );
  }

  AiTokenUsage? _anthropicUsage(Map<String, dynamic> json) {
    final usage = json['usage'];
    if (usage is! Map) return null;
    final uncached = _tokenCount(usage['input_tokens']);
    final created = _tokenCount(usage['cache_creation_input_tokens']) ?? 0;
    final read = _tokenCount(usage['cache_read_input_tokens']) ?? 0;
    final input = uncached == null ? null : uncached + created + read;
    final output = _tokenCount(usage['output_tokens']);
    return AiTokenUsage(
      inputTokens: input,
      outputTokens: output,
      totalTokens: input != null && output != null ? input + output : null,
    );
  }

  AiTokenUsage? _geminiUsage(Map<String, dynamic> json) {
    final usage = json['usageMetadata'];
    if (usage is! Map) return null;
    final input = _tokenCount(usage['promptTokenCount']);
    final total = _tokenCount(usage['totalTokenCount']);
    return AiTokenUsage(
      inputTokens: input,
      // Gemini's total includes thinking tokens, unlike candidatesTokenCount.
      outputTokens: input != null && total != null ? total - input : null,
      totalTokens: total,
    );
  }

  /// Strips OpenAI's `-YYYY-MM-DD` snapshot suffix so `gpt-5.4-2026-03-01` and
  /// `gpt-5.4` collapse into one entry.
  ///
  /// Deliberately not anchored on `gpt-`: the o-series and every future naming
  /// scheme get dated snapshots too, and anchoring on today's family prefix is
  /// how the list ends up frozen at one generation.
  String _normalizeOpenAiModelId(String modelId) {
    final lower = modelId.toLowerCase();
    final match =
        RegExp(r'^([a-z0-9.\-]+?)-\d{4}-\d{2}-\d{2}$').firstMatch(lower);
    if (match != null) return match.group(1)!;
    return modelId;
  }

  String _normalizeGeminiModelId(String modelId) {
    if (modelId.startsWith('models/')) {
      return modelId.substring('models/'.length);
    }
    return modelId;
  }

  /// Chooses between the legacy `max_tokens` and the newer
  /// `max_completion_tokens` request parameter.
  ///
  /// For OpenAI the default is inverted on purpose: `max_completion_tokens` is
  /// what every model since gpt-5 and the o-series expects, so an unknown
  /// (read: newly released) id gets the modern parameter and only the two
  /// known-legacy families opt out. An allow-list of new names would have to be
  /// edited on every release day; this list only grows when OpenAI *retires*
  /// something.
  ///
  /// Other providers reaching this method — Ollama and custom OpenAI-compatible
  /// servers — keep `max_tokens`, which is what llama.cpp, vLLM and friends
  /// actually implement.
  Map<String, dynamic> _openAiTokenParams(
    String modelId, {
    AiProvider provider = AiProvider.openai,
  }) {
    final id = modelId.toLowerCase();
    if (provider != AiProvider.openai) {
      return const {'max_tokens': 2000};
    }
    final isLegacyFamily = id.startsWith('gpt-3') ||
        id.startsWith('gpt-4') ||
        id.startsWith('text-') ||
        id.startsWith('davinci') ||
        id.startsWith('babbage');
    if (isLegacyFamily) return const {'max_tokens': 2000};
    return const {'max_completion_tokens': 2000};
  }

  String? _extractProviderErrorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'] as String?;
        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}
    return null;
  }

  List<String> _geminiModelCandidates(String model) {
    final normalized = _normalizeGeminiModelId(model);
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

  Future<http.Response> _postGeminiGenerateContent({
    required String apiKey,
    required String model,
    required String body,
  }) async {
    http.Response? lastResponse;
    final candidates = _geminiModelCandidates(model);
    final cachedRoute = _geminiResolvedRoutes[model];
    final routes = <(String, String)>[
      if (cachedRoute != null) cachedRoute,
      for (final candidate in candidates)
        for (final version in const ['v1beta', 'v1'])
          if ((candidate, version) != cachedRoute) (candidate, version),
    ];

    for (final (candidate, version) in routes) {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/$version/models/$candidate:generateContent?key=$apiKey',
      );
      final timeoutSeconds = await getAiTimeoutSeconds();
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        _geminiResolvedRoutes[model] = (candidate, version);
        return response;
      }
      lastResponse = response;

      final message =
          (_extractProviderErrorMessage(response.body) ?? '').toLowerCase();
      final retryAnotherRoute = response.statusCode == 404 ||
          (response.statusCode == 400 &&
              (message.contains('model') || message.contains('version')));
      if (!retryAnotherRoute) {
        return response;
      }
    }

    return lastResponse ??
        http.Response(
          '{"error":{"message":"Gemini request failed before any response was received."}}',
          400,
        );
  }

  Future<_AiRawResponse> _callAnthropicRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
    double temperature = 0.3,
    bool structuredOutput = false,
  }) async {
    final content = <Map<String, dynamic>>[];
    for (final img64 in imagesBase64) {
      content.add({
        'type': 'image',
        'source': {'type': 'base64', 'media_type': 'image/jpeg', 'data': img64},
      });
    }
    content.add({'type': 'text', 'text': userContent});

    final request = <String, dynamic>{
      'model': model,
      'system': systemPrompt,
      'max_tokens': 2000,
      'temperature': temperature,
      if (structuredOutput)
        'output_config': {
          'format': {'type': 'json_schema', 'schema': _AiPrompts.mealSchema},
        },
      'messages': [
        {'role': 'user', 'content': content},
      ],
    };

    try {
      final timeoutSeconds = await getAiTimeoutSeconds();
      var response = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode(request),
          )
          .timeout(Duration(seconds: timeoutSeconds));
      if (structuredOutput && response.statusCode == 400) {
        final message =
            (_extractProviderErrorMessage(response.body) ?? '').toLowerCase();
        if (message.contains('output_config') || message.contains('schema')) {
          request.remove('output_config');
          response = await http
              .post(
                Uri.parse('https://api.anthropic.com/v1/messages'),
                headers: {
                  'Content-Type': 'application/json',
                  'x-api-key': apiKey,
                  'anthropic-version': '2023-06-01',
                },
                body: jsonEncode(request),
              )
              .timeout(Duration(seconds: timeoutSeconds));
        }
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AiAuthException();
      }
      if (response.statusCode == 429) throw const AiRateLimitException();
      if (response.statusCode != 200) {
        throw AiNetworkException('API returned status ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final contentList = json['content'] as List<dynamic>?;
      if (contentList == null || contentList.isEmpty) {
        throw const AiParseException();
      }
      final textPart = contentList.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['type'] == 'text',
          orElse: () => <String, dynamic>{});
      final text = textPart['text'] as String?;
      if (text == null || text.isEmpty) throw const AiParseException();
      return _AiRawResponse(text, _anthropicUsage(json));
    } on SocketException {
      throw const AiNetworkException();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiNetworkException('Request failed: $e');
    }
  }

  Future<_AiRawResponse> _callMistralRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
    double temperature = 0.3,
    bool structuredOutput = false,
  }) {
    return _callOpenAiCompatibleRaw(
      endpoint: 'https://api.mistral.ai/v1/chat/completions',
      authHeader: 'Bearer $apiKey',
      model: model,
      userContent: userContent,
      imagesBase64: imagesBase64,
      systemPrompt: systemPrompt,
      temperature: temperature,
      structuredOutput: structuredOutput,
    );
  }

  Future<_AiRawResponse> _callXaiRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
    double temperature = 0.3,
  }) {
    return _callOpenAiCompatibleRaw(
      endpoint: 'https://api.x.ai/v1/chat/completions',
      authHeader: 'Bearer $apiKey',
      model: model,
      userContent: userContent,
      imagesBase64: imagesBase64,
      systemPrompt: systemPrompt,
      temperature: temperature,
    );
  }

  Future<_AiRawResponse> _callOpenAiCompatibleRaw({
    required String endpoint,
    required String authHeader,
    required String model,
    required String userContent,
    required List<String> imagesBase64,
    required String systemPrompt,
    double temperature = 0.3,
    bool structuredOutput = false,
  }) async {
    final contentParts = <Map<String, dynamic>>[];
    for (final img64 in imagesBase64) {
      contentParts.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$img64', 'detail': 'low'},
      });
    }
    contentParts.add({'type': 'text', 'text': userContent});

    final request = <String, dynamic>{
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': contentParts},
      ],
      'max_tokens': 2000,
      'temperature': temperature,
      if (structuredOutput)
        'response_format': {
          'type': 'json_schema',
          'json_schema': {
            'name': 'meal_capture',
            'schema': _AiPrompts.mealSchema
          },
        },
    };

    try {
      final timeoutSeconds = await getAiTimeoutSeconds();
      var response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': authHeader,
            },
            body: jsonEncode(request),
          )
          .timeout(Duration(seconds: timeoutSeconds));
      if (structuredOutput && response.statusCode == 400) {
        final message =
            (_extractProviderErrorMessage(response.body) ?? '').toLowerCase();
        if (message.contains('response_format') || message.contains('schema')) {
          request.remove('response_format');
          response = await http
              .post(
                Uri.parse(endpoint),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': authHeader,
                },
                body: jsonEncode(request),
              )
              .timeout(Duration(seconds: timeoutSeconds));
        }
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AiAuthException();
      }
      if (response.statusCode == 429) throw const AiRateLimitException();
      if (response.statusCode != 200) {
        throw AiNetworkException('API returned status ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) throw const AiParseException();
      return _AiRawResponse(
        choices[0]['message']['content'] as String? ?? '',
        _openAiUsage(json),
      );
    } on SocketException {
      throw const AiNetworkException();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiNetworkException('Request failed: $e');
    }
  }

  /// Model ids that are chat-capable in principle.
  ///
  /// This is an *exclusion* list of modalities, never an allow-list of names.
  /// A prefix allow-list (`gpt-`, `grok-`, …) silently drops whole lineages —
  /// that is how OpenAI's o-series disappeared from the picker — and it drops
  /// every future naming scheme by construction. So: let everything through
  /// except what plainly cannot answer a chat/completions call with a photo
  /// attached.
  static const List<String> _nonChatModalityTokens = <String>[
    // Embeddings / retrieval
    'embedding', 'embed', 'rerank',
    // Speech
    'audio', 'tts', 'whisper', 'transcribe', 'transcription', 'speech',
    'voxtral', 'asr', 'voice',
    // Image and video generation
    'image', 'imagen', 'imagine', 'dall-e', 'dalle', 'video', 'sora',
    // Document processing
    'ocr',
    // Safety classifiers
    'moderation', 'guard',
    // Not a chat/completions shape at all
    'realtime',
  ];

  /// Per-provider extras: models that *are* text models but do not belong in a
  /// meal-photo picker, either because they need a different endpoint or
  /// because they are single-purpose (code).
  static const Map<AiProvider, List<String>> _providerExcludedTokens =
      <AiProvider, List<String>>{
    AiProvider.openai: <String>[
      'codex', // code-only
      'deep-research', // async research endpoint, not chat/completions
      'computer-use', // needs the tool-use loop
      'search', // server-side web search; also refuses `temperature`
    ],
    AiProvider.gemini: <String>[
      'aqa', // attributed-question-answering endpoint
      'learnlm', // experimental education tuning
    ],
    AiProvider.mistral: <String>[
      'codestral',
      'devstral',
      'leanstral',
    ],
  };

  bool _isChatCapableModelId(AiProvider provider, String modelId) {
    if (modelId.isEmpty) return false;
    final id = modelId.toLowerCase();
    for (final token in _nonChatModalityTokens) {
      if (id.contains(token)) return false;
    }
    for (final token in _providerExcludedTokens[provider] ?? const <String>[]) {
      if (id.contains(token)) return false;
    }
    return true;
  }

  /// One GET against a provider's model-listing endpoint, with every failure
  /// mode named rather than swallowed.
  ///
  /// The old `catch (_) { return null; }` here is what made a wrong key, a
  /// timeout and a rate limit all look identical to the settings screen — and
  /// identical to "this provider genuinely has three models".
  Future<AiModelIdsFetch> _fetchModelIds({
    required Uri uri,
    Map<String, String>? headers,
    required Set<String> Function(Map<String, dynamic> json) parse,
  }) async {
    http.Response response;
    try {
      final timeoutSeconds = await getAiTimeoutSeconds();
      response = await _httpGet(uri, headers: headers)
          .timeout(Duration(seconds: timeoutSeconds));
    } on TimeoutException {
      return const AiModelIdsFetch.failure(
        AiModelListError(AiModelListErrorKind.timeout),
      );
    } on SocketException catch (e) {
      return AiModelIdsFetch.failure(
        AiModelListError(
          AiModelListErrorKind.network,
          providerMessage: e.message.isEmpty ? null : e.message,
        ),
      );
    } on http.ClientException catch (e) {
      return AiModelIdsFetch.failure(
        AiModelListError(
          AiModelListErrorKind.network,
          providerMessage: e.message.isEmpty ? null : e.message,
        ),
      );
    } catch (e) {
      return AiModelIdsFetch.failure(
        AiModelListError(
          AiModelListErrorKind.network,
          providerMessage: e.toString(),
        ),
      );
    }

    final status = response.statusCode;
    if (status != 200) {
      final providerMessage = _extractProviderErrorMessage(response.body);
      final kind = switch (status) {
        401 || 403 => AiModelListErrorKind.auth,
        429 => AiModelListErrorKind.rateLimit,
        _ => AiModelListErrorKind.http,
      };
      return AiModelIdsFetch.failure(
        AiModelListError(
          kind,
          statusCode: status,
          providerMessage: providerMessage,
        ),
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AiModelIdsFetch.success(parse(json));
    } catch (e) {
      return AiModelIdsFetch.failure(
        AiModelListError(
          AiModelListErrorKind.response,
          statusCode: status,
          providerMessage: e.toString(),
        ),
      );
    }
  }

  Future<AiModelIdsFetch> _loadDynamicModelIds(AiProvider provider) async {
    if (_dynamicModelIdsLoader != null) {
      final ids = await _dynamicModelIdsLoader!(provider);
      if (ids == null) {
        return const AiModelIdsFetch.failure(
          AiModelListError(AiModelListErrorKind.unsupported),
        );
      }
      return AiModelIdsFetch.success(ids);
    }
    final meta = getProviderMetadata(provider);
    if (!meta.supportsDynamicModelLoading) {
      return const AiModelIdsFetch.failure(
        AiModelListError(AiModelListErrorKind.unsupported),
      );
    }
    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) {
      return const AiModelIdsFetch.failure(
        AiModelListError(AiModelListErrorKind.missingKey),
      );
    }

    switch (provider) {
      case AiProvider.openai:
        return _loadOpenAiModels(apiKey);
      case AiProvider.gemini:
        return _loadGeminiModels(apiKey);
      case AiProvider.mistral:
        return _loadMistralModels(apiKey);
      case AiProvider.xai:
        return _loadXaiModels(apiKey);
      case AiProvider.anthropic:
        return _loadAnthropicModels(apiKey);
      case AiProvider.ollama:
      case AiProvider.custom:
        return const AiModelIdsFetch.failure(
          AiModelListError(AiModelListErrorKind.unsupported),
        );
    }
  }

  /// The `data: [{id: …}]` shape OpenAI, Mistral and xAI all share.
  Set<String> _parseOpenAiStyleIds(
    Map<String, dynamic> json,
    AiProvider provider, {
    String Function(String id)? normalize,
  }) {
    final data = json['data'] as List<dynamic>? ?? const [];
    return data
        .map((e) => (e as Map<String, dynamic>)['id'] as String? ?? '')
        .where((id) => _isChatCapableModelId(provider, id))
        .map((id) => normalize?.call(id) ?? id)
        .toSet();
  }

  Future<AiModelIdsFetch> _loadOpenAiModels(String apiKey) {
    return _fetchModelIds(
      uri: Uri.parse('https://api.openai.com/v1/models'),
      headers: {'Authorization': 'Bearer $apiKey'},
      parse: (json) => _parseOpenAiStyleIds(
        json,
        AiProvider.openai,
        normalize: _normalizeOpenAiModelId,
      ),
    );
  }

  Future<AiModelIdsFetch> _loadGeminiModels(String apiKey) {
    return _fetchModelIds(
      uri: Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
      ),
      parse: (json) {
        final data = json['models'] as List<dynamic>? ?? const [];
        return data
            .map((e) => e as Map<String, dynamic>)
            // A real capability flag from the API, not a guess from the name.
            .where(
              (model) =>
                  (model['supportedGenerationMethods'] as List<dynamic>? ??
                          const [])
                      .contains('generateContent'),
            )
            .map((model) => model['name'] as String? ?? '')
            .where((n) => n.startsWith('models/'))
            .map((n) => n.substring('models/'.length))
            // Brand filter, not a version filter: the endpoint also serves the
            // open Gemma weights, whose vision support is inconsistent. It says
            // nothing about which Gemini generation is allowed.
            .where((id) => id.contains('gemini'))
            .where((id) => _isChatCapableModelId(AiProvider.gemini, id))
            .toSet();
      },
    );
  }

  Future<AiModelIdsFetch> _loadMistralModels(String apiKey) {
    return _fetchModelIds(
      uri: Uri.parse('https://api.mistral.ai/v1/models'),
      headers: {'Authorization': 'Bearer $apiKey'},
      parse: (json) => _parseOpenAiStyleIds(json, AiProvider.mistral),
    );
  }

  Future<AiModelIdsFetch> _loadXaiModels(String apiKey) {
    return _fetchModelIds(
      uri: Uri.parse('https://api.x.ai/v1/models'),
      headers: {'Authorization': 'Bearer $apiKey'},
      parse: (json) => _parseOpenAiStyleIds(json, AiProvider.xai),
    );
  }

  Future<AiModelIdsFetch> _loadAnthropicModels(String apiKey) {
    return _fetchModelIds(
      uri: Uri.parse('https://api.anthropic.com/v1/models'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      parse: (json) {
        final data = json['data'] as List<dynamic>? ?? const [];
        return data
            .map((e) => e as Map<String, dynamic>)
            // Drop only models the API *explicitly* reports as text-only.
            // Treating a missing `capabilities` block as "no vision" would
            // empty the entire list the day Anthropic reshapes that payload —
            // and an empty list is indistinguishable from a failed request.
            .where((model) {
              final capabilities =
                  model['capabilities'] as Map<String, dynamic>?;
              final imageInput =
                  capabilities?['image_input'] as Map<String, dynamic>?;
              return imageInput?['supported'] != false;
            })
            .map((model) => model['id'] as String? ?? '')
            .where((id) => _isChatCapableModelId(AiProvider.anthropic, id))
            .toSet();
      },
    );
  }

  bool _openAiSupportsCustomTemperature(
    String modelId, {
    AiProvider provider = AiProvider.openai,
  }) {
    if (provider != AiProvider.openai) return true;
    final id = modelId.toLowerCase();
    // OpenAI reasoning and fixed-temperature model families refuse custom temperature:
    // - o-series: o1, o3, o4, etc.
    // - gpt-5.6+ and specialized variants: -luna, -terra, -sol
    // - reasoning / thinking variants
    final isFixedTemperature = id.startsWith('o1') ||
        id.startsWith('o3') ||
        id.startsWith('o4') ||
        id.contains('-luna') ||
        id.contains('-terra') ||
        id.contains('-sol') ||
        id.contains('reasoning') ||
        id.contains('thinking');
    return !isFixedTemperature;
  }

  Future<_AiRawResponse> _callOpenAiRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
    double temperature = 0.3,
    String? baseUrlOverride,
    AiProvider provider = AiProvider.openai,
    bool structuredOutput = false,
  }) async {
    final effectiveModel = _normalizeOpenAiModelId(model);
    final contentParts = <Map<String, dynamic>>[];
    for (final img64 in imagesBase64) {
      contentParts.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$img64', 'detail': 'low'},
      });
    }
    contentParts.add({'type': 'text', 'text': userContent});

    final sendTemperature =
        _openAiSupportsCustomTemperature(effectiveModel, provider: provider);

    final requestMap = <String, dynamic>{
      'model': effectiveModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': contentParts},
      ],
      ..._openAiTokenParams(effectiveModel, provider: provider),
      if (structuredOutput && provider == AiProvider.openai)
        'response_format': {
          'type': 'json_schema',
          'json_schema': {
            'name': 'meal_capture',
            'strict': true,
            'schema': _AiPrompts.mealSchema,
          },
        },
      if (sendTemperature) 'temperature': temperature,
    };

    final body = jsonEncode(requestMap);

    final endpoint = baseUrlOverride != null && baseUrlOverride.isNotEmpty
        ? '${baseUrlOverride.replaceAll(RegExp(r'/+$'), '')}/chat/completions'
        : 'https://api.openai.com/v1/chat/completions';

    final headers = {
      'Content-Type': 'application/json',
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    };

    try {
      final timeoutSeconds = await getAiTimeoutSeconds();
      var response = await http
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: body,
          )
          .timeout(Duration(seconds: timeoutSeconds));

      // Automatic fallback retry for any model rejecting custom temperature
      if (response.statusCode == 400 && requestMap.containsKey('temperature')) {
        final message = _extractProviderErrorMessage(response.body);
        if (message != null && message.toLowerCase().contains('temperature')) {
          final retryMap = Map<String, dynamic>.from(requestMap)
            ..remove('temperature');
          response = await http
              .post(
                Uri.parse(endpoint),
                headers: headers,
                body: jsonEncode(retryMap),
              )
              .timeout(Duration(seconds: timeoutSeconds));
        }
      }

      if (structuredOutput && response.statusCode == 400) {
        final message =
            (_extractProviderErrorMessage(response.body) ?? '').toLowerCase();
        if (message.contains('response_format') || message.contains('schema')) {
          final retryMap = Map<String, dynamic>.from(requestMap)
            ..remove('response_format');
          response = await http
              .post(
                Uri.parse(endpoint),
                headers: headers,
                body: jsonEncode(retryMap),
              )
              .timeout(Duration(seconds: timeoutSeconds));
        }
      }

      if (response.statusCode == 401) throw const AiAuthException();
      if (response.statusCode == 429) throw const AiRateLimitException();
      if (response.statusCode != 200) {
        final message = _extractProviderErrorMessage(response.body);
        throw AiNetworkException(
          message != null
              ? 'API returned status ${response.statusCode}: $message'
              : 'API returned status ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) throw const AiParseException();
      return _AiRawResponse(
        choices[0]['message']['content'] as String? ?? '',
        _openAiUsage(json),
      );
    } on SocketException catch (e) {
      if (provider == AiProvider.ollama) {
        throw const AiNetworkException(
          'Ollama is offline. Please make sure the Ollama server is running at http://localhost:11434',
        );
      } else if (provider == AiProvider.custom) {
        throw const AiNetworkException(
          'Custom AI provider is offline. Please verify your Base URL and server status.',
        );
      }
      throw AiNetworkException('Network error: ${e.message}');
    } catch (e) {
      if (e is AiServiceException) rethrow;
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('connection refused') ||
          errStr.contains('connection timed out')) {
        if (provider == AiProvider.ollama) {
          throw const AiNetworkException(
            'Ollama is offline. Please make sure the Ollama server is running at http://localhost:11434',
          );
        } else if (provider == AiProvider.custom) {
          throw const AiNetworkException(
            'Custom AI provider is offline. Please verify your Base URL and server status.',
          );
        }
      }
      throw AiNetworkException('Request failed: $e');
    }
  }

  Future<_AiRawResponse> _callGeminiRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
    double temperature = 0.3,
    bool structuredOutput = false,
  }) async {
    final parts = <Map<String, dynamic>>[];
    for (final img64 in imagesBase64) {
      parts.add({
        'inlineData': {'mimeType': 'image/jpeg', 'data': img64},
      });
    }
    parts.add({'text': '$systemPrompt\n\n$userContent'});

    final request = <String, dynamic>{
      'contents': [
        {'parts': parts},
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': 8192,
        if (structuredOutput) ...{
          'responseMimeType': 'application/json',
          'responseJsonSchema': _AiPrompts.mealSchema,
        },
      },
    };

    try {
      var response = await _postGeminiGenerateContent(
        apiKey: apiKey,
        model: model,
        body: jsonEncode(request),
      );
      if (structuredOutput && response.statusCode == 400) {
        final message =
            (_extractProviderErrorMessage(response.body) ?? '').toLowerCase();
        if (message.contains('responsejsonschema') ||
            message.contains('schema')) {
          (request['generationConfig'] as Map<String, dynamic>)
            ..remove('responseMimeType')
            ..remove('responseJsonSchema');
          response = await _postGeminiGenerateContent(
            apiKey: apiKey,
            model: model,
            body: jsonEncode(request),
          );
        }
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AiAuthException();
      }
      if (response.statusCode == 429) throw const AiRateLimitException();
      if (response.statusCode != 200) {
        final message = _extractProviderErrorMessage(response.body);
        throw AiNetworkException(
          message != null
              ? 'API returned status ${response.statusCode}: $message'
              : 'API returned status ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const AiParseException();
      }
      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final allParts = content?['parts'] as List<dynamic>?;
      if (allParts == null || allParts.isEmpty) throw const AiParseException();

      final buffer = StringBuffer();
      for (final p in allParts) {
        final partMap = p as Map<String, dynamic>;
        if (partMap.containsKey('thought') && partMap['thought'] == true) {
          continue;
        }
        if (partMap.containsKey('text')) {
          buffer.write(partMap['text'] as String);
        }
      }
      return _AiRawResponse(buffer.toString(), _geminiUsage(json));
    } on SocketException {
      throw const AiNetworkException();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiNetworkException('Request failed: $e');
    }
  }
}
