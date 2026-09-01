// The rule this file exists to protect: the telemetry question is asked once
// during onboarding, and — only after a no — exactly once more, at the earliest
// after two weeks and five launches. Never a third time, whatever happens.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/onboarding/data/telemetry_consent_prompt.dart';

void main() {
  late TelemetryConsentPrompt prompt;
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 3, 1, 9, 0);
    prompt = TelemetryConsentPrompt.instance;
    prompt.clockOverride = () => now;
  });

  tearDown(() => prompt.resetForTesting());

  /// Fast-forwards the clock and runs [count] launches through the counter.
  Future<void> live({required int days, required int launches}) async {
    for (var i = 0; i < launches; i++) {
      now = now.add(Duration(days: days ~/ (launches == 0 ? 1 : launches)));
      await prompt.registerLaunch(isOptedIn: false);
    }
    now = DateTime(2026, 3, 1, 9, 0).add(Duration(days: days));
  }

  Future<bool> due() => prompt.isFollowUpDue(isOptedIn: false);

  group('after opting in during onboarding', () {
    setUp(() => prompt.recordOnboardingAnswer(optedIn: true));

    test('never asks again', () async {
      await live(days: 365, launches: 50);
      expect(await due(), isFalse);
    });
  });

  group('after declining during onboarding', () {
    setUp(() => prompt.recordOnboardingAnswer(optedIn: false));

    test('is not due before the waiting period is over', () async {
      await live(days: 13, launches: 20);
      expect(await due(), isFalse);
    });

    test('is not due before the app has actually been used', () async {
      await live(days: 60, launches: 4);
      expect(await due(), isFalse);
    });

    test('is due once both thresholds are met', () async {
      await live(days: 14, launches: 5);
      expect(await due(), isTrue);
    });

    test('never asks a third time, whatever the second answer was', () async {
      await live(days: 30, launches: 10);
      expect(await due(), isTrue);

      await prompt.markFollowUpShown();
      expect(await due(), isFalse);

      await live(days: 400, launches: 100);
      expect(await due(), isFalse);
    });

    test('stops asking as soon as the user opts in elsewhere', () async {
      await live(days: 30, launches: 10);

      // The switch in Settings, or a restored backup that had it on.
      await prompt.registerLaunch(isOptedIn: true);

      expect(await prompt.isFollowUpDue(isOptedIn: false), isFalse,
          reason: 'the launch with telemetry on closed the subject for good');
    });

    test('keeps waiting when the clock jumps backwards', () async {
      await live(days: 30, launches: 10);
      now = DateTime(2026, 1, 1);
      expect(await due(), isFalse);
    });
  });

  group('installations that predate the prompt', () {
    test('are anchored on their first launch rather than asked at once',
        () async {
      // No onboarding answer on record: this user consented long ago.
      await prompt.registerLaunch(isOptedIn: false);
      expect(await due(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(TelemetryConsentPrompt.anchorKey), isNotNull);
    });

    test('serve the same waiting period as everyone else', () async {
      await prompt.registerLaunch(isOptedIn: false);
      await live(days: 14, launches: 5);
      expect(await due(), isTrue);
    });

    test('are never anchored when telemetry is already on', () async {
      await prompt.registerLaunch(isOptedIn: true);
      await live(days: 365, launches: 50);
      expect(await due(), isFalse);
    });
  });
}
