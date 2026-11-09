import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/presentation/widgets/ai_meal_error_menu.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/ai_service.dart';

void main() {
  testWidgets('empty Apple result explains uncertainty and returns retry',
      (tester) async {
    AiMealErrorAction? action;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
          builder: (context) => Scaffold(
                  body: TextButton(
                onPressed: () async => action = await showAiMealErrorMenu(
                  context: context,
                  error: const AiEmptyMealException(),
                  apple: true,
                  canEdit: true,
                ),
                child: const Text('open'),
              ))),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('No foods recognized'), findsOneWidget);
    expect(find.textContaining('Apple Intelligence may not recognize'),
        findsOneWidget);
    expect(find.text('Edit input'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(action, AiMealErrorAction.retry);
  });

  testWidgets('timeout does not blame Apple model quality', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
          builder: (context) => Scaffold(
                  body: TextButton(
                onPressed: () => showAiMealErrorMenu(
                    context: context,
                    error: const AiTimeoutException(),
                    apple: true),
                child: const Text('open'),
              ))),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('The request took too long'), findsOneWidget);
    expect(find.textContaining('Apple Intelligence may not recognize'),
        findsNothing);
    expect(find.text('Open AI settings'), findsOneWidget);
  });
}
