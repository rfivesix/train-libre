import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/services/haptic_feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('vibration');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    HapticFeedbackService.instance.setEnabled(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'hasCustomVibrationsSupport' ? true : null;
        });
  });
  tearDown(() {
    HapticFeedbackService.instance.setEnabled(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test('disabled haptics do not request a vibration', () async {
    HapticFeedbackService.instance.setEnabled(false);
    await HapticFeedbackService.instance.personalRecordFeedback();
    expect(calls, isEmpty);
  });
  test('record feedback sends one rising pattern without audio', () async {
    await HapticFeedbackService.instance.personalRecordFeedback();
    final call = calls.singleWhere((call) => call.method == 'vibrate');
    final arguments = Map<Object?, Object?>.from(call.arguments as Map);
    expect(arguments['pattern'], [35, 85, 35, 80, 45, 100, 110]);
    expect(arguments['intensities'], [90, 0, 130, 0, 175, 0, 240]);
  });
}
