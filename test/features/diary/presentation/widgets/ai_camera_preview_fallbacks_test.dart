import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/presentation/widgets/ai_camera_preview_fallbacks.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  group('AiCameraFallbackView', () {
    testWidgets('renders icon, text, and settings button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AiCameraFallbackView(),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.camera_off), findsOneWidget);
      expect(find.text('Kamerazugriff erforderlich'), findsOneWidget);
      expect(
        find.text(
          'Bitte erlaube den Kamerazugriff in den Einstellungen, um Mahlzeiten direkt live zu erfassen.',
        ),
        findsOneWidget,
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('AiSimulatorCameraDemo', () {
    testWidgets('renders simulator demo plate and gradient background',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 320,
              child: AiSimulatorCameraDemo(),
            ),
          ),
        ),
      );

      expect(find.byType(AiSimulatorCameraDemo), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(AspectRatio), findsOneWidget);
    });
  });
}
