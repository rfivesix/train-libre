import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/features/workout/presentation/widgets/workout_keyboard_accessory_bar.dart';

void main() {
  testWidgets('next uses the focused field custom action', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    var invoked = false;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Stack(children: [
        WorkoutKeyboardNextAction(onNext: () => invoked = true, child: const TextField(autofocus: true)),
        const WorkoutKeyboardAccessoryBar(),
      ])),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.chevron_right));
    await tester.pump();
    expect(invoked, isTrue);
  });
}
