import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:train_libre/services/ai_service.dart';

/// Minimal secure storage so the service can hold an API key without a
/// platform channel.
class _InMemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _values.remove(key);
      return;
    }
    _values[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _values.remove(key);
  }
}

/// A service whose OpenAI `/v1/models` call is answered by [respond].
///
/// There is no API key to test against here, so every assertion below is made
/// against injected response bodies — never against the live provider.
Future<AiService> _openAiServiceWith(
  Future<http.Response> Function(Uri uri) respond, {
  int? timeoutSeconds,
}) async {
  final storage = _InMemorySecureStorage();
  final service = AiService.forTesting(
    secureStorage: storage,
    httpGet: (uri, {headers}) => respond(uri),
  );
  await service.setApiKey(AiProvider.openai, 'sk-test');
  if (timeoutSeconds != null) {
    await service.setAiTimeoutSeconds(timeoutSeconds);
  }
  return service;
}

http.Response _modelsResponse(List<String> ids) {
  return http.Response(
    jsonEncode({
      'data': [
        for (final id in ids) {'id': id, 'object': 'model'},
      ],
    }),
    200,
  );
}

Future<List<String>> _openAiIds(List<String> ids) async {
  final service = await _openAiServiceWith((_) async => _modelsResponse(ids));
  final result = await service.loadModelOptions(AiProvider.openai);
  expect(result.isFallback, isFalse);
  expect(result.error, isNull);
  return result.options.map((o) => o.id).toList();
}

void main() {
  group('OpenAI model filter', () {
    test('keeps the o-series, which the gpt- prefix filter used to drop',
        () async {
      final ids = await _openAiIds([
        'gpt-5.4',
        'o3',
        'o4-mini',
        'o3-pro',
      ]);

      expect(ids, containsAll(['o3', 'o4-mini', 'o3-pro']));
    });

    test('keeps model names that follow no known scheme', () async {
      // The point of the rewrite: an id nobody predicted must still show up.
      final ids = await _openAiIds([
        'gpt-5.4',
        'atlas-1',
        'orion-preview-2',
        'gpt-6',
      ]);

      expect(ids, containsAll(['atlas-1', 'orion-preview-2', 'gpt-6']));
    });

    test('drops non-chat modalities', () async {
      final ids = await _openAiIds([
        'gpt-5.4',
        'text-embedding-3-large',
        'whisper-1',
        'tts-1-hd',
        'gpt-image-1',
        'omni-moderation-latest',
        'gpt-4o-realtime-preview',
        'gpt-4o-transcribe',
        'sora-2',
        'gpt-5-codex',
        'o3-deep-research',
        'computer-use-preview',
      ]);

      expect(ids, ['gpt-5.4']);
    });

    test('collapses dated snapshots for every family, not just gpt-', () async {
      final ids = await _openAiIds([
        'gpt-5.4-2026-03-01',
        'o3-2025-04-16',
      ]);

      expect(ids..sort(), ['gpt-5.4', 'o3']);
    });
  });

  group('OpenAI model ranking', () {
    test('a newer generation outranks the hardcoded flagship hint', () async {
      // `gpt-5.4` is rankingHints[0] and the metadata default; `gpt-6` appears
      // in no hardcoded list at all and must still come first.
      final ids = await _openAiIds(['gpt-5.4', 'gpt-6', 'o5']);

      expect(ids.first, 'gpt-6');
    });

    test('within one generation the flagship beats mini and nano', () async {
      final ids = await _openAiIds([
        'gpt-6-nano',
        'gpt-6-mini',
        'gpt-6',
        'gpt-6-pro',
      ]);

      expect(ids, ['gpt-6-pro', 'gpt-6', 'gpt-6-mini', 'gpt-6-nano']);
    });

    test('rolling ids rank above their pinned dated twins', () async {
      final ids = await _openAiIds(['gpt-6', 'gpt-6-2027-01-09']);

      // The snapshot normalizes to `gpt-6`, so a differently shaped pin is
      // used to prove the penalty rather than the normalizer.
      expect(ids.first, 'gpt-6');
    });

    test('deprecated and legacy ids sink to the bottom', () async {
      final ids = await _openAiIds([
        'gpt-6-legacy',
        'gpt-4o',
        'gpt-6',
      ]);

      expect(ids.last, 'gpt-6-legacy');
    });
  });

  group('OpenAI model list size', () {
    test('keeps far more than the old ten entries', () async {
      final many = List<String>.generate(30, (i) => 'gpt-6-variant$i');

      final ids = await _openAiIds(many);

      expect(ids.length, 30);
    });

    test('still caps a pathological response', () async {
      final many = List<String>.generate(200, (i) => 'gpt-6-variant$i');

      final ids = await _openAiIds(many);

      expect(ids.length, AiService.maxModelOptions);
    });
  });

  group('model list failures surface instead of being swallowed', () {
    Future<AiModelListResult> resultFor(
      Future<http.Response> Function(Uri uri) respond, {
      int? timeoutSeconds,
    }) async {
      final service =
          await _openAiServiceWith(respond, timeoutSeconds: timeoutSeconds);
      return service.loadModelOptions(AiProvider.openai);
    }

    test('a rejected key reports auth, not a shorter model list', () async {
      final result = await resultFor(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'Incorrect API key provided.'},
          }),
          401,
        ),
      );

      expect(result.isFallback, isTrue);
      expect(result.error?.kind, AiModelListErrorKind.auth);
      expect(result.error?.statusCode, 401);
      expect(result.error?.providerMessage, 'Incorrect API key provided.');
      expect(result.options.every((o) => o.isFallback), isTrue);
      expect(
        result.options.first.id,
        'gpt-5.4',
        reason: 'the emergency fallback list is still served',
      );
    });

    test('403 is reported as auth too', () async {
      final result = await resultFor((_) async => http.Response('{}', 403));

      expect(result.error?.kind, AiModelListErrorKind.auth);
      expect(result.error?.statusCode, 403);
    });

    test('429 is reported as a rate limit', () async {
      final result = await resultFor((_) async => http.Response('{}', 429));

      expect(result.error?.kind, AiModelListErrorKind.rateLimit);
      expect(result.error?.statusCode, 429);
    });

    test('any other status keeps its code', () async {
      final result = await resultFor((_) async => http.Response('nope', 503));

      expect(result.error?.kind, AiModelListErrorKind.http);
      expect(result.error?.statusCode, 503);
    });

    test('a dead connection is reported as a network error', () async {
      final result = await resultFor(
        (_) async => throw const SocketException('Connection refused'),
      );

      expect(result.isFallback, isTrue);
      expect(result.error?.kind, AiModelListErrorKind.network);
      expect(result.error?.providerMessage, 'Connection refused');
    });

    test('an http client failure is reported as a network error', () async {
      final result = await resultFor(
        (_) async => throw http.ClientException('Connection closed'),
      );

      expect(result.error?.kind, AiModelListErrorKind.network);
    });

    test('a stalled provider is reported as a timeout', () async {
      final result = await resultFor(
        (_) => Future<http.Response>.delayed(
          const Duration(seconds: 30),
          () => _modelsResponse(['gpt-6']),
        ),
        timeoutSeconds: 1,
      );

      expect(result.isFallback, isTrue);
      expect(result.error?.kind, AiModelListErrorKind.timeout);
    });

    test('an unreadable body is reported as a response error', () async {
      final result =
          await resultFor((_) async => http.Response('<html>nope</html>', 200));

      expect(result.isFallback, isTrue);
      expect(result.error?.kind, AiModelListErrorKind.response);
    });

    test('a 200 that filters down to nothing is still a failure', () async {
      final result = await resultFor(
        (_) async => _modelsResponse(['whisper-1', 'text-embedding-3-large']),
      );

      expect(result.isFallback, isTrue);
      expect(result.error?.kind, AiModelListErrorKind.response);
    });

    test('a missing key is named as such rather than looking like an error',
        () async {
      final service = AiService.forTesting(
        secureStorage: _InMemorySecureStorage(),
        httpGet: (uri, {headers}) async =>
            fail('no request may be made without a key'),
      );

      final result = await service.loadModelOptions(AiProvider.openai);

      expect(result.isFallback, isTrue);
      expect(result.error?.kind, AiModelListErrorKind.missingKey);
      expect(result.error?.isBenign, isTrue);
    });

    test('providers without a listing endpoint are marked unsupported',
        () async {
      final service = AiService.forTesting(
        secureStorage: _InMemorySecureStorage(),
        httpGet: (uri, {headers}) async => fail('no request expected'),
      );

      for (final provider in [AiProvider.ollama, AiProvider.custom]) {
        final result = await service.loadModelOptions(provider);
        expect(result.error?.kind, AiModelListErrorKind.unsupported);
        expect(result.error?.isBenign, isTrue);
      }
    });

    test('a successful load reports no error at all', () async {
      final result = await resultFor((_) async => _modelsResponse(['gpt-6']));

      expect(result.isFallback, isFalse);
      expect(result.error, isNull);
      expect(result.options.single.id, 'gpt-6');
      expect(result.options.single.isFallback, isFalse);
    });
  });

  group('other providers keep working through the shared filter', () {
    Future<List<String>> idsFor(
      AiProvider provider,
      http.Response response,
    ) async {
      final storage = _InMemorySecureStorage();
      final service = AiService.forTesting(
        secureStorage: storage,
        httpGet: (uri, {headers}) async => response,
      );
      await service.setApiKey(provider, 'test-key');
      final result = await service.loadModelOptions(provider);
      expect(result.isFallback, isFalse);
      return result.options.map((o) => o.id).toList();
    }

    test('gemini keeps generateContent models and drops embeddings', () async {
      final ids = await idsFor(
        AiProvider.gemini,
        http.Response(
          jsonEncode({
            'models': [
              {
                'name': 'models/gemini-3-ultra',
                'supportedGenerationMethods': ['generateContent'],
              },
              {
                'name': 'models/gemini-flash-latest',
                'supportedGenerationMethods': ['generateContent'],
              },
              {
                'name': 'models/gemini-embedding-001',
                'supportedGenerationMethods': ['generateContent'],
              },
              {
                'name': 'models/gemini-2.5-pro',
                'supportedGenerationMethods': ['countTokens'],
              },
            ],
          }),
          200,
        ),
      );

      // `gemini-3-ultra` matches no hardcoded hint and still wins on version.
      expect(ids.first, 'gemini-3-ultra');
      expect(ids, contains('gemini-flash-latest'));
      expect(ids, isNot(contains('gemini-embedding-001')));
      expect(ids, isNot(contains('gemini-2.5-pro')));
    });

    test('anthropic drops only models explicitly reported as text-only',
        () async {
      final ids = await idsFor(
        AiProvider.anthropic,
        http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'claude-opus-5-0',
                // No capabilities block at all — must not be dropped, or a
                // payload change would empty the whole picker.
              },
              {
                'id': 'claude-sonnet-4-6',
                'capabilities': {
                  'image_input': {'supported': true},
                },
              },
              {
                'id': 'claude-text-only-1',
                'capabilities': {
                  'image_input': {'supported': false},
                },
              },
            ],
          }),
          200,
        ),
      );

      expect(ids, containsAll(['claude-opus-5-0', 'claude-sonnet-4-6']));
      expect(ids, isNot(contains('claude-text-only-1')));
      expect(ids.first, 'claude-opus-5-0');
    });

    test('mistral keeps models outside the old prefix allow-list', () async {
      final ids = await idsFor(
        AiProvider.mistral,
        http.Response(
          jsonEncode({
            'data': [
              {'id': 'mistral-large-3'},
              {'id': 'open-mixtral-8x22b'},
              {'id': 'codestral-latest'},
              {'id': 'mistral-embed'},
            ],
          }),
          200,
        ),
      );

      expect(ids, containsAll(['mistral-large-3', 'open-mixtral-8x22b']));
      expect(ids, isNot(contains('codestral-latest')));
      expect(ids, isNot(contains('mistral-embed')));
    });

    test('xai keeps a renamed family and drops image generation', () async {
      final ids = await idsFor(
        AiProvider.xai,
        http.Response(
          jsonEncode({
            'data': [
              {'id': 'grok-5'},
              {'id': 'sonic-2-fast'},
              {'id': 'grok-image-1-imagine'},
            ],
          }),
          200,
        ),
      );

      expect(ids, containsAll(['grok-5', 'sonic-2-fast']));
      expect(ids, isNot(contains('grok-image-1-imagine')));
    });

    test(
        'OpenAI temperature rules omit temperature for reasoning & luna models',
        () {
      final service = AiService.instance;
      // Reasoning / fixed-temperature families
      expect(service.openAiSupportsCustomTemperature('o1'), isFalse);
      expect(service.openAiSupportsCustomTemperature('o3-mini'), isFalse);
      expect(service.openAiSupportsCustomTemperature('o4-preview'), isFalse);
      expect(service.openAiSupportsCustomTemperature('gpt-5.6-luna'), isFalse);
      expect(service.openAiSupportsCustomTemperature('gpt-5.6-terra'), isFalse);
      expect(service.openAiSupportsCustomTemperature('gpt-5.6-sol'), isFalse);
      expect(service.openAiSupportsCustomTemperature('custom-reasoning-model'),
          isFalse);

      // Standard models that accept custom temperature
      expect(service.openAiSupportsCustomTemperature('gpt-5.4-mini'), isTrue);
      expect(service.openAiSupportsCustomTemperature('gpt-4o'), isTrue);
      expect(service.openAiSupportsCustomTemperature('gpt-4o-mini'), isTrue);
      expect(service.openAiSupportsCustomTemperature('gpt-3.5-turbo'), isTrue);
    });
  });
}
