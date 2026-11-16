import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/presentation/widgets/finish_workout_menu.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';
import 'package:train_libre/widgets/common/app_button.dart';

void main() {
  testWidgets('finish returns the entered title and notes', (tester) async {
    FinishWorkoutChoice? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showFinishWorkoutMenu(context, 'Push');
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Notes');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AppButton && widget.variant == AppButtonVariant.primary,
      ),
    );
    await tester.pumpAndSettle();
    expect(result, (title: 'Push', notes: 'Notes', discard: false));
  });

  testWidgets(
    'discard requires confirmation and cancelling keeps the finish menu',
    (tester) async {
      FinishWorkoutChoice? result;
      var returned = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showFinishWorkoutMenu(context, 'Push');
                  returned = true;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final discard = find.byWidgetPredicate(
        (widget) => widget is AppButton && widget.label == 'Discard workout',
      );
      await tester.tap(discard);
      await tester.pumpAndSettle();
      expect(returned, isFalse);
      expect(
        find.text(
          'Are you sure you want to permanently delete this workout log?',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find
            .byWidgetPredicate(
              (widget) => widget is AppButton && widget.label == 'Cancel',
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(returned, isFalse);
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.tap(discard);
      await tester.pumpAndSettle();
      await tester.tap(discard.last);
      await tester.pumpAndSettle();
      expect(returned, isTrue);
      expect(result?.discard, isTrue);
    },
  );
}
