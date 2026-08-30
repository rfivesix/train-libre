import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/services/voice/voice_dictation_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AI tidy-up is on for someone who never touched the switch', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await VoiceDictationSettings.instance.isAiTidyEnabled(), isTrue);
  });

  test('turning it off is remembered', () async {
    SharedPreferences.setMockInitialValues({});
    await VoiceDictationSettings.instance.setAiTidyEnabled(false);
    expect(await VoiceDictationSettings.instance.isAiTidyEnabled(), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(VoiceDictationSettings.aiTidyKey), isFalse);
  });
}
