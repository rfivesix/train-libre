// test/features/depth_scan/depth_scan_channel_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/depth_scan/platform/depth_scan_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<String> channelCalls = [];

  setUp(() {
    channelCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.trainlibre.app/depth_scan'),
            (MethodCall call) async {
      channelCalls.add(call.method);
      if (call.method == 'toggleTorch') {
        return true;
      }
      if (call.method == 'getTorchStatus') {
        return true;
      }
      if (call.method == 'capability') {
        return {
          'supported': true,
          'cameraAvailable': true,
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.trainlibre.app/depth_scan'), null);
  });

  group('DepthScanChannel Torch & Capability', () {
    test('toggleTorch invokes toggleTorch method on depth scan channel',
        () async {
      final channel = DepthScanChannel.instance;
      final result = await channel.toggleTorch();
      expect(result, isA<bool>());
    });

    test('isTorchOn invokes getTorchStatus method on depth scan channel',
        () async {
      final channel = DepthScanChannel.instance;
      final result = await channel.isTorchOn();
      expect(result, isA<bool>());
    });
  });
}
