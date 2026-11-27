import 'package:material_ui/material_ui.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:train_libre/features/workout/presentation/widgets/rpe_gradient_slider.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/features/workout/presentation/widgets/rpe_picker.dart';
import 'package:train_libre/features/workout/domain/log_workout_set_use_case.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';

void main() {
  testWidgets('slider gives haptic feedback only for a changed step', (
    tester,
  ) async {
    var feedback = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') feedback++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showRpePicker(context, value: 8),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final slider = find.byType(RpeGradientSlider);
    await tester.tapAt(tester.getCenter(slider));
    await tester.pump();
    expect(feedback, 0);
    await tester.tapAt(tester.getCenter(slider) + const Offset(35, 0));
    await tester.pump();
    expect(feedback, 1);
  });
  test('failure sets record maximum effort and RPE can be cleared', () {
    final set = SetLog(
      workoutLogId: 1,
      exerciseName: 'Test',
      setType: 'normal',
      rpe: 8.5,
      rir: 2,
    );
    final cleared = LogWorkoutSetUseCase()
        .execute(oldLog: set, clearRpe: true, clearRir: true)
        .updatedSet;
    expect(cleared.rpe, isNull);
    expect(cleared.rir, isNull);
    final failure = LogWorkoutSetUseCase()
        .execute(oldLog: set, setType: 'failure')
        .updatedSet;
    expect(failure.rpe, 10);
    expect(failure.rir, 0);
  });

  testWidgets('picker preserves half values and can complete', (tester) async {
    RpePickerResult? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showRpePicker(
                  context,
                  value: 8.5,
                  allowComplete: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('8.5'), findsWidgets);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(result?.value, 8.5);
    expect(result?.complete, true);
  });
  testWidgets('picker can clear an existing rating', (tester) async {
    RpePickerResult? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showRpePicker(context, value: 9);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.value, isNull);
    expect(result!.complete, isFalse);
  });

  testWidgets(
    'help keeps the selection, and plus and minus save without completing',
    (tester) async {
      RpePickerResult? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await showRpePicker(
                  context,
                  value: 8.5,
                  allowComplete: true,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();
      expect(find.text('What is RPE?'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.keyboard_off));
      await tester.pumpAndSettle();
      expect(result?.value, 8.5);
      expect(result?.complete, isFalse);
    },
  );

  testWidgets('picker fits a narrow screen with larger text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showRpePicker(context, allowComplete: true),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final panel = tester.getRect(find.byKey(const ValueKey('rpe-main-panel')));
    final controls = tester.getRect(
      find.byKey(const ValueKey('rpe-side-controls')),
    );
    expect(controls.top, panel.top);
    expect(controls.bottom, panel.bottom);
    expect(find.byIcon(LucideIcons.keyboard_off), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
