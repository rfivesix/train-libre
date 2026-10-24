import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/draggable_ai_cloud.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'tapping the AI orb for a new chat expands composer and opens keyboard automatically',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(top: 48, bottom: 34),
            ),
            child: const Scaffold(
              body: SizedBox.expand(
                child: DraggableAiCloud(
                  semanticLabel: 'KI-Wolke',
                  semanticHint: 'Tippen',
                  liveliness: 0.5,
                ),
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

      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );

      // While opening animation is still loading (800ms), keyboard should NOT be shown yet
      expect(editable.renderEditable.hasFocus, isFalse);

      // Once the opening animation has fully loaded (900ms+), keyboard opens automatically
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      await tester.pump();

      // For a new chat, the keyboard must open automatically after animation finishes.
      final editableAfter = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableAfter.renderEditable.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      // The expanded composer actions (including send arrow) must be visible.
      expect(find.byIcon(LucideIcons.arrow_up), findsOneWidget);

      // Send a prompt to create existing messages in the chat
      await tester.enterText(textFieldFinder, 'Hallo KI');
      await tester.pump();
      await tester.tap(find.byIcon(LucideIcons.arrow_up));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // With chat turns present, the "New Chat" icon button appears in the header
      final newChatButton = find.byIcon(LucideIcons.square_pen);
      expect(newChatButton, findsOneWidget);

      // Tap "New Chat" button in header toolbar -> should start new chat and auto-focus keyboard
      await tester.tap(newChatButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      final editableNewChat = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableNewChat.renderEditable.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      // Now close the cloud overlay (collapse)
      final closeButton = find.byIcon(LucideIcons.x);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();

      // After closing, keyboard must be dismissed
      expect(tester.testTextInput.isVisible, isFalse);

      // Reopen the cloud overlay for the empty new chat
      await tester.tap(orbGesture.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Before animation finishes, keyboard should not be visible yet
      final editableReopenEarly = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableReopenEarly.renderEditable.hasFocus, isFalse);

      // Once animation finishes, keyboard must show again on reopening empty chat
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      await tester.pump();

      final editableReopen = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableReopen.renderEditable.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
    },
  );

  testWidgets(
    'opening cloud with existing messages or draft does not show keyboard automatically',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(top: 48, bottom: 34),
            ),
            child: const Scaffold(
              body: SizedBox.expand(
                child: DraggableAiCloud(
                  semanticLabel: 'KI-Wolke',
                  semanticHint: 'Tippen',
                  liveliness: 0.5,
                ),
              ),
            ),
          ),
        ),
      );

      final orbGesture = find.bySemanticsLabel('KI-Wolke');
      final closeButton = find.byIcon(LucideIcons.x);
      final textFieldFinder = find.byType(TextField);

      // Open empty chat
      await tester.tap(orbGesture.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();

      // Keyboard opened automatically for empty chat
      expect(tester.testTextInput.isVisible, isTrue);

      // Enter a draft prompt, but don't send it yet
      await tester.enterText(textFieldFinder, 'Draft prompt');
      await tester.pump();

      // Close the cloud
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);

      // Reopen the cloud with an existing draft prompt -> keyboard must NOT auto-open
      await tester.tap(orbGesture.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();

      final editableWithDraft = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableWithDraft.renderEditable.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);

      // Now send the prompt so the chat has messages
      await tester.tap(find.byIcon(LucideIcons.arrow_up));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Close the cloud
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);

      // Reopen the cloud with existing chat messages -> keyboard must NOT auto-open
      await tester.tap(orbGesture.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();

      final editableWithMessages = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableWithMessages.renderEditable.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);

      // But clicking "New Chat" button will start a fresh chat and auto-focus the keyboard
      final newChatButton = find.byIcon(LucideIcons.square_pen);
      expect(newChatButton, findsOneWidget);
      await tester.tap(newChatButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      final editableFresh = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableFresh.renderEditable.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
    },
  );
}
