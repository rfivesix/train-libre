import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/workout/domain/live_workout_notification_preferences.dart';
import 'package:train_libre/services/local_notification_service.dart';
import 'package:train_libre/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('timer sound switches between playback and silent-aware audio', () {
    final enabled = SoundService.timerAudioContext(true);
    final disabled = SoundService.timerAudioContext(false);
    expect(enabled.iOS.category, AVAudioSessionCategory.playback);
    expect(disabled.iOS.category, AVAudioSessionCategory.ambient);
    expect(enabled.android.usageType, AndroidUsageType.alarm);
    expect(disabled.android.usageType, AndroidUsageType.notification);
    expect(enabled.android.audioFocus, AndroidAudioFocus.none);
    expect(disabled.android.audioFocus, AndroidAudioFocus.none);
  });

  test('defaults preserve the existing workout notification and sound behavior',
      () async {
    SharedPreferences.setMockInitialValues({});
    expect(await LiveWorkoutNotificationPreferences.restNotificationsEnabled(),
        isTrue);
    expect(await LiveWorkoutNotificationPreferences.ignoreSilentMode(), isTrue);
  });

  test(
      'disabled rest notifications do not initialize or call the notification plugin',
      () async {
    SharedPreferences.setMockInitialValues({
      LiveWorkoutNotificationPreferences.restNotificationsKey: false,
      LiveWorkoutNotificationPreferences.ignoreSilentModeKey: false,
    });
    final calls = <MethodCall>[];
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await LocalNotificationService.instance
        .scheduleRestTimerDoneNotification(secondsFromNow: 10);
    await LocalNotificationService.instance
        .showRestTimerDoneNotification(foreground: true);
    expect(calls, isEmpty);
    expect(
        await LiveWorkoutNotificationPreferences.ignoreSilentMode(), isFalse);
  });
}
