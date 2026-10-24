import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/cloud_overlay/cloud_overlay_prompt_suggestions.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/draggable_ai_cloud.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CloudOverlayPromptSuggestions', () {
    testWidgets('renders all three starter options with correct labels and icons in German', (tester) async {
      String? selectedPrompt;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: Scaffold(
            body: CloudOverlayPromptSuggestions(
              contrastColor: Colors.white,
              onSelectPrompt: (prompt) => selectedPrompt = prompt,
            ),
          ),
        ),
      );

      // Check titles
      expect(find.text('Heutige Nährwerte prüfen'), findsOneWidget);
      expect(find.text('Erholungsstatus abfragen'), findsOneWidget);
      expect(find.text('Mahlzeit nach Makros vorschlagen'), findsOneWidget);

      // Check icons
      expect(find.byIcon(LucideIcons.chart_pie), findsOneWidget);
      expect(find.byIcon(LucideIcons.biceps_flexed), findsOneWidget);
      expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);

      // Tap on nutrition suggestion
      await tester.tap(find.text('Heutige Nährwerte prüfen'));
      await tester.pump();

      expect(
        selectedPrompt,
        contains('Wie sieht meine Nährwert- und Makrobilanz für heute aus?'),
      );

      // Tap on recovery suggestion
      await tester.tap(find.text('Erholungsstatus abfragen'));
      await tester.pump();

      expect(
        selectedPrompt,
        contains('Wie ist mein aktueller Erholungsstatus?'),
      );

      // Tap on meal suggestion
      await tester.tap(find.text('Mahlzeit nach Makros vorschlagen'));
      await tester.pump();

      expect(
        selectedPrompt,
        contains('Prüfe mein heutiges Ernährungstagebuch und meine verbleibenden Makros'),
      );
    });

    testWidgets('starter suggestions appear on empty chat and disappear when typing', (tester) async {
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

      // Expand cloud overlay
      final orbGesture = find.bySemanticsLabel('KI-Wolke');
      await tester.tap(orbGesture.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Starter suggestions are visible in empty chat
      expect(find.byType(CloudOverlayPromptSuggestions), findsOneWidget);
      expect(find.text('Heutige Nährwerte prüfen'), findsOneWidget);
      expect(find.text('Erholungsstatus abfragen'), findsOneWidget);
      expect(find.text('Mahlzeit nach Makros vorschlagen'), findsOneWidget);

      // Type text into the text field -> suggestions must disappear
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'A');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final crossFade = tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade));
      expect(crossFade.crossFadeState, equals(CrossFadeState.showSecond));

      // Clear text field again -> suggestions reappear
      await tester.enterText(textFieldFinder, '');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final crossFadeReappeared = tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade));
      expect(crossFadeReappeared.crossFadeState, equals(CrossFadeState.showFirst));
    });

    testWidgets('tapping a starter suggestion sends prompt and hides suggestions', (tester) async {
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

      // Expand cloud overlay
      final orbGesture = find.bySemanticsLabel('KI-Wolke');
      await tester.tap(orbGesture.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text('Erholungsstatus abfragen'), findsOneWidget);

      // Tap on recovery suggestion
      await tester.tap(find.text('Erholungsstatus abfragen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Prompt is now submitted into chat
      final crossFadeAfter = tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade));
      expect(crossFadeAfter.crossFadeState, equals(CrossFadeState.showSecond));
    });

    testWidgets('starting voice recording hides starter suggestions', (tester) async {
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

      // Expand cloud overlay
      final orbGesture = find.bySemanticsLabel('KI-Wolke');
      await tester.tap(orbGesture.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.byType(CloudOverlayPromptSuggestions), findsOneWidget);
      final crossFadeBefore = tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade));
      expect(crossFadeBefore.crossFadeState, equals(CrossFadeState.showFirst));

      // Tap microphone button
      final micButton = find.byIcon(LucideIcons.mic);
      expect(micButton, findsOneWidget);
      await tester.tap(micButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Starter suggestions must be hidden while recording is starting or active
      final crossFadeDuring = tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade));
      expect(crossFadeDuring.crossFadeState, equals(CrossFadeState.showSecond));
    });

    testWidgets('tapping retry does not leave prompt in the composer text field', (tester) async {
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

      // Expand cloud overlay
      final orbGesture = find.bySemanticsLabel('KI-Wolke');
      await tester.tap(orbGesture.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Tap nutrition suggestion
      await tester.tap(find.text('Heutige Nährwerte prüfen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final textFieldFinder = find.byType(TextField);
      final editable = tester.widget<TextField>(textFieldFinder);
      expect(editable.controller?.text, isEmpty);

      // Retry button (rotate_cw)
      final retryButton = find.byIcon(LucideIcons.rotate_cw);
      if (retryButton.evaluate().isNotEmpty) {
        await tester.tap(retryButton.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final editableAfter = tester.widget<TextField>(textFieldFinder);
        expect(editableAfter.controller?.text, isEmpty);
      }
    });
  });
}
