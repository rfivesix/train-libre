import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/presentation/widgets/live_workout_rest_bar.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';

void main() {
  testWidgets('set timer controls adjust elapsed time and stop the timer', (
    tester,
  ) async {
    final adjustments = <int>[];
    var stopped = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LiveWorkoutRestBar(
            isRunning: true,
            isDoneBanner: false,
            remainingRestSeconds: 3663,
            onAdjustRestTime: adjustments.add,
            onCancelRest: () => stopped = true,
            actionLabel: 'Stop timer',
            actionIcon: Icons.stop,
            formatAsStopwatch: true,
          ),
        ),
      ),
    );
    expect(find.text('1:01:03'), findsOneWidget);
    await tester.tap(find.text('-15'));
    await tester.tap(find.text('+15'));
    await tester.tap(find.byIcon(Icons.stop));
    expect(adjustments, [-15, 15]);
    expect(stopped, isTrue);
  });

  testWidgets(
    'finished rest retains the adjustment controls and can be dismissed',
    (tester) async {
      final adjustments = <int>[];
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LiveWorkoutRestBar(
              isRunning: false,
              isDoneBanner: true,
              remainingRestSeconds: 0,
              onAdjustRestTime: adjustments.add,
              onCancelRest: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('00:00'), findsNothing);
      await tester.tap(find.text('+15'));
      await tester.tap(find.text('-15'));
      expect(adjustments, [15, -15]);
      await tester.tap(find.text('OK'));
      expect(dismissed, isTrue);
    },
  );
}
