import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/media/app_media_store.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/ai_assistant/application/assistant_chat_service.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_history_repository.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/draggable_ai_cloud.dart';
import 'package:train_libre/features/diary/data/nutrition_repository.dart';
import 'package:train_libre/features/diary/data/sources/diary_local_data_source.dart';
import 'package:train_libre/features/diary/domain/repositories/diary_repository.dart';
import 'package:train_libre/features/profile/data/goal_repository_impl.dart';
import 'package:train_libre/features/profile/data/profile_repository.dart';
import 'package:train_libre/features/profile/data/sources/profile_local_data_source.dart';
import 'package:train_libre/features/profile/domain/repositories/goal_repository.dart';
import 'package:train_libre/features/profile/domain/repositories/profile_repository.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/data/workout_repository.dart';
import 'package:train_libre/features/workout/domain/repositories/workout_repository.dart';
import 'package:train_libre/generated/app_localizations.dart';

class _Model implements AssistantModelClient {
  @override
  Future<AssistantModelIdentity> identity() async =>
      const AssistantModelIdentity('test', 'test-model', null);

  @override
  Future<String> interpret({
    required String prompt,
    required AssistantModelIdentity identity,
  }) async => prompt.contains('Current user message: "Hi there"')
      ? '{"kind":"chat","answer":"Hello!"}'
      : '{"kind":"data","categories":["workouts"],"dateExpression":"2026-10-18"}';

  @override
  Stream<String> answer({
    required String prompt,
    required AssistantModelIdentity identity,
    required Future<void> Function() onDispatch,
  }) async* {
    throw StateError('Denied access must not invoke the model for an answer');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('overlay saves a denied request and reopens its conversation', (
    tester,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'assistant_overlay_history_test',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
    AppMediaStore.instance.resetForTesting();
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      AppMediaStore.instance.resetForTesting();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(database);
    addTearDown(DatabaseHelper.closeAndResetDriftDb);
    await database
        .into(database.workoutLogs)
        .insert(
          WorkoutLogsCompanion.insert(
            startTime: DateTime(2026, 10, 18, 9),
            endTime: drift.Value(DateTime(2026, 10, 18, 10)),
            status: const drift.Value('completed'),
            routineNameSnapshot: const drift.Value('Push'),
          ),
        );

    Widget app(Key key) => MultiProvider(
      providers: [
        Provider<IWorkoutRepository>.value(
          value: WorkoutRepository(
            localDataSource: WorkoutLocalDataSource(database),
          ),
        ),
        Provider<IDiaryRepository>.value(
          value: NutritionRepository(
            localDataSource: DiaryLocalDataSource(database),
          ),
        ),
        Provider<IProfileRepository>.value(
          value: ProfileRepository(
            localDataSource: ProfileLocalDataSource(database),
          ),
        ),
        Provider<IGoalRepository>.value(
          value: GoalRepositoryImpl(database: database),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SizedBox.expand(
            child: DraggableAiCloud(
              key: key,
              semanticLabel: 'AI cloud',
              semanticHint: 'Open',
              liveliness: 0.1,
              useLiveAi: true,
              modelClient: _Model(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(const ValueKey('first')));
    await tester.tap(find.bySemanticsLabel('AI cloud').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Hi there');
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.arrow_up));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Hello!'), findsOneWidget);
    expect(find.text('Data access request').hitTestable(), findsNothing);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'My workouts on 2026-10-18');
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.arrow_up));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Data access request').hitTestable(), findsOneWidget);
    expect(find.textContaining('workouts'), findsWidgets);
    tester
        .widget<TextButton>(
          find.ancestor(
            of: find.text('Decline'),
            matching: find.byType(TextButton),
          ),
        )
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final history = AssistantHistoryRepository(database);
    final conversation = (await history.conversations()).single;
    final access = (await history.accessForConversation(conversation.id))
        .single;
    expect(access.status, 'denied');
    expect(access.sharedAt, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(const ValueKey('reopened')));
    await tester.tap(find.bySemanticsLabel('AI cloud').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('My workouts on 2026-10-18'), findsOneWidget);
    expect(find.textContaining('No app data was sent'), findsOneWidget);

    // Tapping "Data access" opens the in-overlay audit modal without requiring
    // a Navigator ancestor above DraggableAiCloud.
    await tester.tap(find.bySemanticsLabel('More options'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Data access'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Status: denied'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Status: denied'), findsNothing);

    // After a cold start, an old conversation remains saved but is not
    // automatically reopened as the active chat.
    await tester.pumpWidget(const SizedBox.shrink());
    await database.customStatement(
      'UPDATE assistant_conversations SET updated_at = ? WHERE id = ?',
      [
        DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 31))
            .toIso8601String(),
        conversation.id,
      ],
    );
    await tester.pumpWidget(app(const ValueKey('after-inactivity')));
    await tester.tap(find.bySemanticsLabel('AI cloud').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('My workouts on 2026-10-18'), findsNothing);
    expect((await history.conversations()).single.id, conversation.id);
  });
}
