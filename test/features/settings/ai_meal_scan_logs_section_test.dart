import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/settings/presentation/widgets/ai_meal_scan_logs_section.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/ai_meal_scan_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AiMealScanLogService.instance.clear();
  });

  testWidgets('shows a scan timeline and copies privacy-safe diagnostics',
      (tester) async {
    final logs = AiMealScanLogService.instance;
    await tester.runAsync(() async {
      await logs.start(
        id: 'scan-1',
        provider: 'openai',
        inputMode: 'photo',
        photoCount: 2,
        startedAt: DateTime(2026, 10, 3, 15, 53),
      );
      await logs.setModel('scan-1', 'gpt-6-luna');
      await logs.event('scan-1', AiMealScanLogStage.preparationFinished,
          elapsedMilliseconds: 800, durationMilliseconds: 800);
      await logs.event('scan-1', AiMealScanLogStage.validationFinished,
          elapsedMilliseconds: 20000,
          durationMilliseconds: 2500,
          result: AiMealScanLogResult.needsRepair,
          candidate: AiMealScanLogCandidate.primary,
          validationScore: 68,
          issueCategories: [AiMealScanLogIssueCategory.semanticMatch]);
      await logs.event('scan-1', AiMealScanLogStage.providerUsageReported,
          elapsedMilliseconds: 20001,
          callIndex: 1,
          inputTokens: 2200,
          outputTokens: 1800,
          totalTokens: 4000,
          usageComplete: true);
      await logs.event('scan-1', AiMealScanLogStage.reviewVisible,
          elapsedMilliseconds: 18000);
      await logs.event('scan-1', AiMealScanLogStage.preliminaryNutritionReady,
          elapsedMilliseconds: 20100);
      await logs.event('scan-1', AiMealScanLogStage.reviewReady,
          elapsedMilliseconds: 37000);
      await logs.finish('scan-1',
          result: AiMealScanLogResult.accepted,
          durationMilliseconds: 37000,
          selectedValidationRounds: 2,
          totalValidationRuns: 2,
          repairRounds: 1,
          primaryFirstPassAccepted: false,
          hedgeStarted: false);
      await logs.usage('scan-1',
          calls: 2,
          inputTokens: 9000,
          outputTokens: 2812,
          totalTokens: 11812,
          complete: true);
    });

    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(child: AiMealScanLogsSection()),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('gpt-6-luna'), findsOneWidget);
    expect(find.textContaining('37.0 s'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ai_scan_logs_copy_all')));
    await tester.pump();
    expect(clipboardText, contains('11812 total'));
    expect(clipboardText, contains('validationFinished'));
    expect(clipboardText, contains('candidate=primary'));
    expect(clipboardText, contains('issues=semanticMatch'));
    expect(clipboardText, contains('call=1 tokens=2200/1800/4000'));
    expect(clipboardText, contains('preliminaryNutritionReady'));
    expect(clipboardText, contains('reviewReady'));
    expect(clipboardText, isNot(contains('API key')));

    await tester.tap(find.byKey(const Key('ai_scan_log_scan-1')));
    await tester.pumpAndSettle();
    expect(find.text('First validation passed'), findsOneWidget);
    expect(find.byKey(const Key('ai_scan_log_copy_scan-1')), findsOneWidget);
  });

  test('keeps only 20 locally stored scans and allowlists metadata', () async {
    final logs = AiMealScanLogService.instance;
    for (var i = 0; i < 21; i++) {
      await logs.start(
        id: 'scan-$i',
        provider: i == 0 ? 'secret endpoint' : 'gemini',
        inputMode: i == 0 ? 'private meal text' : 'text_only',
        photoCount: 0,
        startedAt: DateTime(2026, 10, 3),
      );
    }
    expect(logs.entries, hasLength(20));
    expect(logs.entries.last.id, 'scan-1');

    await logs.start(
      id: 'safe-scan',
      provider: 'secret endpoint',
      inputMode: 'private meal text',
      photoCount: 0,
      startedAt: DateTime(2026, 10, 3),
    );
    final text = logs.export(logs.entries.first);
    expect(text, contains('Provider: unknown'));
    expect(text, isNot(contains('secret endpoint')));
    expect(text, isNot(contains('private meal text')));
  });
}
