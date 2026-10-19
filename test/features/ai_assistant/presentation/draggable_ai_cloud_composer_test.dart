import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/draggable_ai_cloud.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'tapping the AI overlay input field expands composer while preserving EditableTextState and opening keyboard',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('de'),
          home: Scaffold(
            body: SizedBox.expand(
              child: DraggableAiCloud(
                semanticLabel: 'KI-Wolke',
                semanticHint: 'Tippen',
                liveliness: 0.5,
              ),
            ),
          ),
        ),
      );

      // Expand the AI cloud by tapping the orb
      final orbGesture = find.bySemanticsLabel('KI-Wolke');
      await tester.tap(orbGesture.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final editableBefore = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(tester.testTextInput.hasAnyClients, isFalse);

      // Tap the input field once
      await tester.tap(textFieldFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final editableAfter = tester.state<EditableTextState>(
        find.byType(EditableText),
      );

      // The same EditableTextState must remain mounted and keep its active
      // TextInputConnection so the software keyboard stays visible.
      expect(identical(editableBefore, editableAfter), isTrue);
      expect(editableAfter.renderEditable.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      // The expanded composer actions (including send arrow) must be visible.
      expect(find.byIcon(LucideIcons.arrow_up), findsOneWidget);
    },
  );
}
