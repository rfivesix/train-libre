// test/features/diary/presentation/ai_meal_capture_tour_test.dart

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/diary/presentation/ai_meal_capture_screen.dart';
import 'package:train_libre/features/diary/presentation/widgets/ai_meal_capture_tour_overlay.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/navigation/app_route_observer.dart';
import 'package:train_libre/services/ai_meal_capture_tour_service.dart';

class MockPermissionHandlerPlatform extends PermissionHandlerPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return PermissionStatus.granted;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    return {for (var p in permissions) p: PermissionStatus.granted};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUpAll(() {
    PermissionHandlerPlatform.instance = MockPermissionHandlerPlatform();
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(db);
    BasisDataManager.instance.invalidateCatalogPresenceCache();
    SharedPreferences.setMockInitialValues({
      'installed_off_version_de': '202608010000',
    });

    await db.into(db.products).insert(const ProductsCompanion(
          barcode: drift.Value('off-1'),
          name: drift.Value('OFF product'),
          calories: drift.Value(100),
          protein: drift.Value(1),
          carbs: drift.Value(2),
          fat: drift.Value(3),
          source: drift.Value('off'),
        ));

    // Mock QR view channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('net.touchcapture.qr.flutterqr/qrview_0'),
      (call) async {
        return null;
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('net.touchcapture.qr.flutterqr/qrview_0'),
      null,
    );
    await db.close();
  });

  Widget buildCaptureScreen() {
    return MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: [appRouteObserver],
      home: const AiMealCaptureScreen(),
    );
  }

  group('AiMealCaptureTourService', () {
    test('isTourCompleted defaults to false and can be marked or reset', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AiMealCaptureTourService.instance;

      expect(await service.isTourCompleted(), isFalse);

      await service.markTourCompleted();
      expect(await service.isTourCompleted(), isTrue);

      await service.resetTour();
      expect(await service.isTourCompleted(), isFalse);
    });
  });

  group('AiMealCaptureTourOverlay', () {
    testWidgets('renders title, description, progress, next and skip labels', (tester) async {
      var nextClicked = false;
      var skipClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiMealCaptureTourOverlay(
              targetRect: const Rect.fromLTWH(50, 100, 80, 80),
              title: 'Test Step Title',
              description: 'Test Step Description',
              progressLabel: '1/6',
              nextLabel: 'Weiter',
              skipLabel: 'Überspringen',
              onNext: () => nextClicked = true,
              onSkip: () => skipClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Step Title'), findsOneWidget);
      expect(find.text('Test Step Description'), findsOneWidget);
      expect(find.text('1/6'), findsOneWidget);
      expect(find.text('Weiter'), findsOneWidget);
      expect(find.text('Überspringen'), findsOneWidget);

      await tester.tap(find.text('Weiter'));
      expect(nextClicked, isTrue);

      await tester.tap(find.text('Überspringen'));
      expect(skipClicked, isTrue);
    });
  });

  group('AiMealCaptureScreen Interactive Tour', () {
    testWidgets('automatically starts tour on first launch and steps through all 6 steps', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'installed_off_version_de': '202608010000',
        'ai_meal_capture_tour_completed': false,
      });

      await tester.pumpWidget(buildCaptureScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Step 1: Shutter
      expect(find.byType(AiMealCaptureTourOverlay), findsOneWidget);
      expect(find.text('1/6'), findsOneWidget);

      // Advance to Step 2: Barcode
      await tester.tap(find.text('Weiter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('2/6'), findsOneWidget);
      // Dummy barcode banner should be visible
      expect(find.text('Bio-Haferflocken 500g'), findsOneWidget);

      // Advance to Step 3: Gallery
      await tester.tap(find.text('Weiter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('3/6'), findsOneWidget);

      // Advance to Step 4: Voice
      await tester.tap(find.text('Weiter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('4/6'), findsOneWidget);

      // Advance to Step 5: Text
      await tester.tap(find.text('Weiter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('5/6'), findsOneWidget);

      // Advance to Step 6: AI Analysis
      await tester.tap(find.text('Weiter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('6/6'), findsOneWidget);
      expect(find.text('Fertig'), findsOneWidget);

      // Complete tour
      await tester.tap(find.text('Fertig'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(AiMealCaptureTourOverlay), findsNothing);
      expect(await AiMealCaptureTourService.instance.isTourCompleted(), isTrue);
    });

    testWidgets('skipping tour immediately dismisses overlay and marks tour completed', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'installed_off_version_de': '202608010000',
        'ai_meal_capture_tour_completed': false,
      });

      await tester.pumpWidget(buildCaptureScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(AiMealCaptureTourOverlay), findsOneWidget);

      await tester.tap(find.text('Überspringen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(AiMealCaptureTourOverlay), findsNothing);
      expect(await AiMealCaptureTourService.instance.isTourCompleted(), isTrue);
    });

    testWidgets('info button in app bar can restart the tour at any time', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'installed_off_version_de': '202608010000',
        'ai_meal_capture_tour_completed': true,
      });

      await tester.pumpWidget(buildCaptureScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Initially no tour because it was marked completed
      expect(find.byType(AiMealCaptureTourOverlay), findsNothing);

      // Tap info icon in app bar
      final infoButton = find.byTooltip('Einführung ansehen');
      expect(infoButton, findsOneWidget);
      await tester.tap(infoButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Tour should now be active
      expect(find.byType(AiMealCaptureTourOverlay), findsOneWidget);
      expect(find.text('1/6'), findsOneWidget);
    });
  });
}
