import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/ai_assistant/data/ai_overlay_demo_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AiOverlayDemoSettings.configuration.value =
        const AiOverlayDemoConfiguration();
  });

  test('floating assistant defaults off for a new install', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    AiOverlayDemoSettings.initialize(preferences);

    expect(AiOverlayDemoSettings.configuration.value.enabled, isFalse);
  });

  test('initialization preserves an explicitly saved launcher preference',
      () async {
    SharedPreferences.setMockInitialValues({'ai_overlay_demo_enabled': true});
    final preferences = await SharedPreferences.getInstance();

    AiOverlayDemoSettings.initialize(preferences);

    expect(AiOverlayDemoSettings.configuration.value.enabled, isTrue);
  });
}
