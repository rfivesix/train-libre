import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/services/ai/local_ai_model_manager.dart';
import 'package:train_libre/services/ai/apple_foundation_service.dart';
import 'package:train_libre/services/ai_service.dart';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final storage = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        if (call.method == 'getApplicationSupportDirectory') {
          return '/tmp';
        }
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        if (call.method == 'write') {
          final args = call.arguments as Map;
          storage[args['key'] as String] = args['value'] as String;
          return null;
        }
        if (call.method == 'read') {
          final args = call.arguments as Map;
          return storage[args['key'] as String];
        }
        return null;
      },
    );
  });

  group('LocalAiModelManager', () {
    test('contains curated vision models including Qwen-3-VL-4B', () {
      final models = LocalAiModelManager.availableModels;
      expect(models.length, greaterThanOrEqualTo(3));

      final qwen3 = models.firstWhere((m) => m.id == 'qwen-3-vl-4b');
      expect(qwen3.name, contains('Qwen-3-VL'));
      expect(qwen3.isRecommended, isTrue);
      expect(qwen3.formattedSize, '2.3 GB'); // 2497281664 bytes = ~2.3 GB
      expect(qwen3.downloadUrl, contains('Qwen3-VL-4B-Instruct-GGUF'));

      final qwen25 = models.firstWhere((m) => m.id == 'qwen-2.5-vl-3b');
      expect(qwen25.name, contains('Qwen-2.5-VL'));
      expect(qwen25.downloadUrl, contains('Qwen2.5-VL-3B-Instruct-GGUF'));

      final smolVlm = models.firstWhere((m) => m.id == 'smolvlm-2.2b');
      expect(smolVlm.name, contains('SmolVLM'));
    });

    test('selectModel updates selectedModelId and persists to SharedPreferences',
        () async {
      final manager = LocalAiModelManager.instance;
      await manager.initialize();

      await manager.selectModel('qwen-2.5-vl-3b');
      expect(manager.selectedModelId, 'qwen-2.5-vl-3b');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('local_ai_selected_model'), 'qwen-2.5-vl-3b');

      await manager.selectModel('qwen-3-vl-4b');
      expect(manager.selectedModelId, 'qwen-3-vl-4b');
    });
  });

  group('AppleFoundationService', () {
    test('isAvailable returns false on non-iOS test environment gracefully',
        () async {
      final service = AppleFoundationService.instance;
      final available = await service.isAvailable(forceRefresh: true);
      // In tests (macOS host / non-iOS), availability gracefully resolves to false
      expect(available, isFalse);
    });
  });

  group('AiService Provider Integration', () {
    test('AiProvider includes appleFoundation and localModel', () {
      expect(AiProvider.values, contains(AiProvider.appleFoundation));
      expect(AiProvider.values, contains(AiProvider.localModel));
    });

    test('metadata for localModel and appleFoundation exist', () {
      final service = AiService.instance;
      final localMeta = service.getProviderMetadata(AiProvider.localModel);
      expect(localMeta.defaultModel, 'qwen-3-vl-4b');
      expect(localMeta.supportsVision, isTrue);

      final appleMeta = service.getProviderMetadata(AiProvider.appleFoundation);
      expect(appleMeta.defaultModel, 'apple-foundation-system');
      expect(appleMeta.supportsVision, isTrue);
    });

    test('getActiveModelDisplayName returns formatted model name for providers',
        () async {
      final service = AiService.instance;
      final manager = LocalAiModelManager.instance;
      await manager.initialize();

      await service.setSelectedProvider(AiProvider.localModel);
      await manager.selectModel('qwen-3-vl-4b');
      final localName = await service.getActiveModelDisplayName();
      expect(localName, contains('Qwen-3-VL'));
      expect(localName, contains('(Lokal)'));

      await service.setSelectedProvider(AiProvider.appleFoundation);
      final appleName = await service.getActiveModelDisplayName();
      expect(appleName, 'Apple Intelligence');
    });
  });
}
