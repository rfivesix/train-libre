import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/settings/presentation/settings_screen.dart';
import 'package:train_libre/features/sleep/platform/permissions/sleep_permission_controller.dart';
import 'package:train_libre/features/sleep/platform/permissions/sleep_permission_models.dart';
import 'package:train_libre/features/sleep/platform/permissions/sleep_permissions_service.dart';
import 'package:train_libre/features/sleep/platform/sleep_sync_service.dart';
import 'package:train_libre/features/workout/domain/models/prescription_enums.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/theme_service.dart';
import 'package:train_libre/services/training_autonomy_service.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/util/cancellation_token.dart';

class _StubPermissionService implements SleepPermissionsService {
  const _StubPermissionService();

  @override
  Future<SleepPermissionOutcome> checkStatus() async =>
      const SleepPermissionOutcome.ready();

  @override
  Future<SleepPermissionOutcome> requestAccess() async =>
      const SleepPermissionOutcome.ready();
}

class _FakeSleepSettingsService implements SleepSettingsService {
  _FakeSleepSettingsService({required this.controller});

  final SleepPermissionController controller;

  @override
  SleepPermissionController buildPermissionController() => controller;

  @override
  Future<bool> isTrackingEnabled() async => false;

  @override
  Future<void> setTrackingEnabled(bool value) async {}

  @override
  Future<SleepSyncResult> importRecent({
    int lookbackDays = 30,
    bool forceFullSync = false,
    CancellationToken? token,
    void Function(int index, int total)? onProgress,
  }) async {
    return const SleepSyncResult(
      success: true,
      permissionState: SleepPermissionState.ready,
      importedSessions: 0,
    );
  }

  @override
  Future<SleepSyncResult?> importRecentIfDue({
    int lookbackDays = 30,
    Duration minInterval = const Duration(hours: 6),
    bool force = false,
  }) async =>
      null;

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TrainingAutonomyService', () {
    test('defaults to AutonomyLevel.off (strict opt-in)', () async {
      final service = TrainingAutonomyService();
      await service.initialize();

      expect(service.level, equals(AutonomyLevel.off));
      expect(service.isSuggestEnabled, isFalse);
    });

    test('updates level and persists to preferences', () async {
      final service = TrainingAutonomyService();
      await service.initialize();

      await service.setLevel(AutonomyLevel.suggest);
      expect(service.level, equals(AutonomyLevel.suggest));
      expect(service.isSuggestEnabled, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('training_autonomy_level'), equals('suggest'));

      // New instance reads persisted value
      final service2 = TrainingAutonomyService();
      await service2.initialize();
      expect(service2.level, equals(AutonomyLevel.suggest));
      expect(service2.isSuggestEnabled, isTrue);
    });

    test('can toggle back to off', () async {
      final service = TrainingAutonomyService();
      await service.initialize();

      await service.setLevel(AutonomyLevel.suggest);
      expect(service.level, equals(AutonomyLevel.suggest));

      await service.setLevel(AutonomyLevel.off);
      expect(service.level, equals(AutonomyLevel.off));
      expect(service.isSuggestEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('training_autonomy_level'), equals('off'));
    });
  });

  group('SettingsScreen progression widget test', () {
    testWidgets('renders training progression entry and title in German',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      PackageInfo.setMockInitialValues(
        appName: 'Train Libre',
        packageName: 'com.example.train_libre',
        version: '1.4.0',
        buildNumber: '1',
        buildSignature: '',
      );

      final sleepController =
          SleepPermissionController(const _StubPermissionService());
      final sleepService =
          _FakeSleepSettingsService(controller: sleepController);
      final autonomyService = TrainingAutonomyService();
      await autonomyService.initialize();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeService()),
            ChangeNotifierProvider(create: (_) => UnitService()),
            ChangeNotifierProvider.value(value: autonomyService),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('de'),
            home: SettingsScreen(
              sleepSyncService: sleepService,
              sleepPermissionController: sleepController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_training_progression_entry')),
          findsOneWidget);
      expect(find.text('Trainingsprogression'), findsOneWidget);
      expect(find.textContaining('Aus'), findsOneWidget);
    });
  });
}
