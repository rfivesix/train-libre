import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/presentation/widgets/running_workout_bar.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  testWidgets(
    'RunningWorkoutBar does not overflow on small width or Dynamic Type',
    (tester) async {
      tester.view.physicalSize = const Size(320, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 100),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: RunningWorkoutBar(
                timeText: '01:23:45',
                onResume: () {},
                onDiscard: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RunningWorkoutBar), findsOneWidget);
    },
  );
}
