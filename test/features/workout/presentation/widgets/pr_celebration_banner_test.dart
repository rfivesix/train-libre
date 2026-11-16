import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/presentation/widgets/pr_celebration_banner.dart';
import 'package:train_libre/features/workout/presentation/widgets/pr_sparkle_burst.dart';

void main() {
  testWidgets('only the first record shows the celebration burst', (
    tester,
  ) async {
    Widget banner(bool celebrate) => MaterialApp(
      home: Scaffold(
        body: PrCelebrationBanner(
          slideAnimation: const AlwaysStoppedAnimation(Offset.zero),
          celebrationAnimation: const AlwaysStoppedAnimation(0.5),
          celebrate: celebrate,
          exerciseName: 'Squat',
          localizedRecordType: 'Record',
          achievementText: '100 kg',
          diffText: '',
        ),
      ),
    );
    await tester.pumpWidget(banner(true));
    expect(find.byType(PrSparkleBurst), findsOneWidget);
    await tester.pumpWidget(banner(false));
    expect(find.byType(PrSparkleBurst), findsNothing);
    expect(find.text('Squat'), findsOneWidget);
  });
}
