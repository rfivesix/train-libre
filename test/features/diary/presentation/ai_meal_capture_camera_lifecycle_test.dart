// test/features/diary/presentation/ai_meal_capture_camera_lifecycle_test.dart

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/diary/presentation/ai_meal_capture_screen.dart';
import 'package:train_libre/features/diary/presentation/scanner_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/navigation/app_route_observer.dart';

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

  final List<String> qrCalls = [];
  late AppDatabase db;

  setUpAll(() {
    PermissionHandlerPlatform.instance = MockPermissionHandlerPlatform();
  });

  setUp(() async {
    qrCalls.clear();
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

    for (var i = 0; i < 20; i++) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              MethodChannel('net.touchcapture.qr.flutterqr/qrview_$i'),
              (MethodCall call) async {
        qrCalls.add(call.method);
        return true;
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              MethodChannel('net.touchcapture.qr.flutterqrplus/qrview_$i'),
              (MethodCall call) async {
        qrCalls.add(call.method);
        return true;
      });
    }
  });

  tearDown(() async {
    for (var i = 0; i < 20; i++) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              MethodChannel('net.touchcapture.qr.flutterqr/qrview_$i'),
              null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              MethodChannel('net.touchcapture.qr.flutterqrplus/qrview_$i'),
              null);
    }
    await db.close();
  });

  group('AiMealCaptureScreen Camera Lifecycle', () {
    testWidgets('suspends camera on nested route push and resumes on pop',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [appRouteObserver],
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AiMealCaptureScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AiMealCaptureScreen), findsOneWidget);

      // Push a nested screen on top of AiMealCaptureScreen
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Child Screen')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // While child screen is top, simulate app background and resume
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Pop the child screen back to AiMealCaptureScreen
      navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AiMealCaptureScreen), findsOneWidget);
    });

    testWidgets('handles app lifecycle changes', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [appRouteObserver],
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AiMealCaptureScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // App is paused
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // App is resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.byType(AiMealCaptureScreen), findsOneWidget);
    });

    testWidgets('toggles flash on button tap and resets on suspension',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [appRouteObserver],
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AiMealCaptureScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final flashFinder = find.widgetWithIcon(IconButton, LucideIcons.zap_off);
      expect(flashFinder, findsOneWidget);

      final uiKitFinder = find.byType(UiKitView);
      if (uiKitFinder.evaluate().isNotEmpty) {
        final uikit = tester.widget<UiKitView>(uiKitFinder);
        uikit.onPlatformViewCreated?.call(0);
      }
      final androidFinder = find.byType(AndroidView);
      if (androidFinder.evaluate().isNotEmpty) {
        final android = tester.widget<AndroidView>(androidFinder);
        android.onPlatformViewCreated?.call(0);
      }
      await tester.pump();

      final flashButtonFinder = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Blitz ein-/ausschalten',
      );
      expect(flashButtonFinder, findsOneWidget);

      // Tap to toggle flash on
      await tester.tap(flashButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(qrCalls, contains('toggleFlash'));

      // Pushing a new route suspends camera and resets flash
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Overlay Screen')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.widgetWithIcon(IconButton, LucideIcons.zap_off), findsOneWidget);
    });
  });

  group('ScannerScreen Camera Lifecycle', () {
    testWidgets('subscribes to route observer and handles route changes',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [appRouteObserver],
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ScannerScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Push nested route
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Child')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Pop back
      navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ScannerScreen), findsOneWidget);
    });

    testWidgets('renders flash button and handles toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ScannerScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final flashFinder = find.widgetWithIcon(IconButton, LucideIcons.zap_off);
      expect(flashFinder, findsOneWidget);

      final uiKitFinder = find.byType(UiKitView);
      if (uiKitFinder.evaluate().isNotEmpty) {
        final uikit = tester.widget<UiKitView>(uiKitFinder);
        uikit.onPlatformViewCreated?.call(0);
      }
      final androidFinder = find.byType(AndroidView);
      if (androidFinder.evaluate().isNotEmpty) {
        final android = tester.widget<AndroidView>(androidFinder);
        android.onPlatformViewCreated?.call(0);
      }
      await tester.pump();

      final flashButtonFinder = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Blitz ein-/ausschalten',
      );
      expect(flashButtonFinder, findsOneWidget);

      await tester.tap(flashButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(qrCalls, contains('toggleFlash'));
    });
  });
}
