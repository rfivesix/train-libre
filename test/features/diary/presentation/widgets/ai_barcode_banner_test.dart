import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';
import 'package:train_libre/features/diary/presentation/widgets/ai_barcode_banner.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  group('AiBarcodeBanner', () {
    testWidgets('renders barcode icon, product name, and handles tap', (
      tester,
    ) async {
      var logged = false;

      final product = FoodItem(
        barcode: '123456',
        name: 'Haferflocken',
        nameDe: 'Haferflocken',
        nameEn: 'Oats',
        nameFr: '',
        nameIt: '',
        nameJa: '',
        brand: 'Köln',
        calories: 360,
        protein: 13.5,
        carbs: 58.7,
        fat: 7.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AiBarcodeBanner(
              detectedBarcode: '123456',
              detectedProduct: product,
              isLoggingBarcode: false,
              onLogBarcode: () => logged = true,
              primaryAccent: Colors.amber,
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.scan_barcode), findsOneWidget);
      expect(find.text('Haferflocken'), findsOneWidget);
      expect(find.text('Barcode erkannt'), findsOneWidget);
      expect(find.text('Loggen'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      expect(logged, isTrue);
    });

    testWidgets('renders fallback text when product is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AiBarcodeBanner(
              detectedBarcode: '987654321',
              detectedProduct: null,
              isLoggingBarcode: false,
              onLogBarcode: () {},
              primaryAccent: Colors.amber,
            ),
          ),
        ),
      );

      expect(find.text('Barcode 987654321'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoggingBarcode is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AiBarcodeBanner(
              detectedBarcode: '123456',
              detectedProduct: null,
              isLoggingBarcode: true,
              onLogBarcode: () {},
              primaryAccent: Colors.amber,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loggen'), findsNothing);
    });
  });

  group('AiDemoBarcodeBanner', () {
    testWidgets('renders demo hints and assigns bannerKey to Material', (
      tester,
    ) async {
      final bannerKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AiDemoBarcodeBanner(
              bannerKey: bannerKey,
              primaryAccent: Colors.amber,
            ),
          ),
        ),
      );

      expect(find.byKey(bannerKey), findsOneWidget);
      expect(find.byIcon(LucideIcons.scan_barcode), findsOneWidget);
      expect(
        find.text("Jo, so sieht's aus, wenn du einen Barcode scannst!"),
        findsOneWidget,
      );
      expect(find.text('Bio-Haferflocken 500g'), findsOneWidget);
      expect(find.text('Loggen'), findsOneWidget);
    });
  });
}
