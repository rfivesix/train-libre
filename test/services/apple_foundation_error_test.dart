import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/services/ai/ai_cancellation.dart';
import 'package:train_libre/services/ai/apple_foundation_service.dart';
import 'package:train_libre/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('trainlibre.ai/apple_foundation');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('availability is refreshed after iOS settings change', () async {
    var available = false;
    messenger.setMockMethodCallHandler(channel, (_) async => available);
    final service = AppleFoundationService.forTesting();
    expect(await service.isAvailable(), isFalse);
    available = true;
    expect(await service.isAvailable(), isTrue);
  });

  test('timeout cancels the matching native request', () async {
    final response = Completer<String?>();
    String? requestId;
    String? cancelledId;
    messenger.setMockMethodCallHandler(channel, (call) async {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      if (call.method == 'generateMealJson') {
        requestId = args['requestId'] as String;
        return response.future;
      }
      if (call.method == 'cancel') cancelledId = args['requestId'] as String;
      return null;
    });
    final service = AppleFoundationService.forTesting();
    await expectLater(
      service.generateMealJson(
          prompt: 'meal', timeout: const Duration(milliseconds: 10)),
      throwsA(isA<AiTimeoutException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(requestId, isNotNull);
    expect(cancelledId, requestId);
    response.complete('late response');
  });

  test('cancellation stops waiting and ignores a late response', () async {
    final response = Completer<String?>();
    var cancelled = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'generateMealJson') return response.future;
      if (call.method == 'cancel') cancelled = true;
      return null;
    });
    final operation = AiCancellation();
    final service = AppleFoundationService.forTesting();
    final result =
        operation.run(() => service.generateMealJson(prompt: 'meal'));
    operation.cancel();
    await expectLater(result, throwsA(isA<AiCancelledException>()));
    await Future<void>.delayed(Duration.zero);
    expect(cancelled, isTrue);
    response.complete('late response');
  });

  test('native unavailability and generation errors remain distinct', () async {
    var code = 'UNAVAILABLE';
    messenger.setMockMethodCallHandler(
        channel, (_) async => throw PlatformException(code: code));
    final service = AppleFoundationService.forTesting();
    await expectLater(service.generateMealJson(prompt: 'meal'),
        throwsA(isA<AiAppleUnavailableException>()));
    code = 'GENERATION_FAILED';
    await expectLater(service.generateMealJson(prompt: 'meal'),
        throwsA(isA<AiAppleGenerationException>()));
  });

  test('explicit empty meal differs from malformed JSON', () {
    final service = AiService.forTesting();
    expect(() => service.parseMealCandidateForTesting('{"items":[]}'),
        throwsA(isA<AiEmptyMealException>()));
    expect(() => service.parseMealCandidateForTesting('{"items":[{}]}'),
        throwsA(isA<AiEmptyMealException>()));
    expect(() => service.parseMealCandidateForTesting('[]'),
        throwsA(isA<AiEmptyMealException>()));
    expect(() => service.parseMealCandidateForTesting('{"items":['),
        throwsA(isA<AiParseException>()));
  });
}
