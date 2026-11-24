import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/settings/presentation/ai_settings_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/ai_service.dart';
import 'package:train_libre/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const appleChannel = MethodChannel('trainlibre.ai/apple_foundation');
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Map<String, String> secureStore;

  void setupChannels({required AiProvider selectedProvider}) {
    secureStore = <String, String>{
      AiService.selectedProviderStorageKey: selectedProvider.name,
    };
    messenger.setMockMethodCallHandler(secureStorageChannel, (call) async {
      final args = Map<String, dynamic>.from(call.arguments as Map? ?? {});
      final key = args['key'] as String?;
      switch (call.method) {
        case 'read':
          return key == null ? null : secureStore[key];
        case 'write':
          if (key != null && args['value'] is String) {
            secureStore[key] = args['value'] as String;
          }
          return null;
        case 'delete':
          if (key != null) secureStore.remove(key);
          return null;
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(appleChannel, (call) async {
      if (call.method == 'isAvailable') return true;
      return false;
    });
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(secureStorageChannel, null);
    messenger.setMockMethodCallHandler(appleChannel, null);
  });

  Widget buildApp() {
    return ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AiSettingsScreen(),
      ),
    );
  }

  testWidgets(
    'hides LiDAR switches and nutrition estimation method when Apple Intelligence is selected',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        'ai_enabled': true,
        AiService.selectedProviderStorageKey: AiProvider.appleFoundation.name,
      });
      setupChannels(selectedProvider: AiProvider.appleFoundation);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Send LiDAR scale'), findsNothing);
      expect(find.text('Send the depth map too'), findsNothing);
      expect(find.text('Nutrition estimation method'), findsNothing);
      expect(find.text('Apple Intelligence'), findsWidgets);
    },
  );

  testWidgets(
    'shows nutrition estimation method for external providers',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        'ai_enabled': true,
        AiService.selectedProviderStorageKey: AiProvider.openai.name,
      });
      setupChannels(selectedProvider: AiProvider.openai);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Nutrition estimation method'), findsOneWidget);
      expect(find.text('OpenAI'), findsWidgets);
    },
  );
}
