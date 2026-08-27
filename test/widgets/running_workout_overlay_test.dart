import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/app/presentation/widgets/running_workout_overlay.dart';
import 'package:train_libre/generated/app_localizations.dart';

Widget _host({
  String elapsed = '05:23',
  String rest = '01:53',
  bool isResting = false,
  String? exerciseName = 'Lat Pulldown (Cable)',
  VoidCallback? onExpand,
  VoidCallback? onDiscard,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: Center(
        child: RunningWorkoutOverlay(
          elapsedDuration: elapsed,
          restDuration: rest,
          isResting: isResting,
          exerciseName: exerciseName,
          onExpand: onExpand ?? () {},
          onDiscard: onDiscard ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the workout duration and the next exercise while running',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.textContaining('Workout'), findsOneWidget);
    expect(find.textContaining('05:23'), findsOneWidget);
    expect(find.text('Lat Pulldown (Cable)'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevron_up), findsOneWidget);
    expect(find.byIcon(LucideIcons.trash_2), findsOneWidget);
  });

  testWidgets('switches to the rest countdown while a pause runs',
      (tester) async {
    await tester.pumpWidget(_host(isResting: true));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rest'), findsOneWidget);
    expect(find.textContaining('01:53'), findsOneWidget);
    expect(find.textContaining('05:23'), findsNothing);
  });

  testWidgets('leaves the second row out when no exercise is in the workout',
      (tester) async {
    await tester.pumpWidget(_host(exerciseName: null));
    await tester.pumpAndSettle();

    expect(find.textContaining('Workout'), findsOneWidget);
    // No placeholder copy — the row is simply absent.
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('tapping the bar expands, tapping the bin discards',
      (tester) async {
    var expanded = 0;
    var discarded = 0;
    await tester.pumpWidget(_host(
      onExpand: () => expanded++,
      onDiscard: () => discarded++,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lat Pulldown (Cable)'));
    await tester.pump();
    expect(expanded, 1);
    expect(discarded, 0);

    await tester.tap(find.byIcon(LucideIcons.trash_2));
    await tester.pump();
    expect(discarded, 1);
    // The discard button must not double as the expand target.
    expect(expanded, 1);
  });
}
