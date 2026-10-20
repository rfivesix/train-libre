import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Future<String> interpret(
          {required String prompt,
          required AssistantModelIdentity identity}) async =>
      prompt.contains('Current user message: "Hi there"')
          ? '{"kind":"chat","answer":"Hello!"}'
          : '{"kind":"data","categories":["workouts"],"dateExpression":"2026-10-18"}';

  @override
  Stream<String> answer(
      {required String prompt,
      required AssistantModelIdentity identity,
      required Future<void> Function() onDispatch}) async* {
    throw StateError('Denied access must not invoke the model for an answer');
  }
}

class _LongStreamingModel implements AssistantModelClient {
  @override
  Future<AssistantModelIdentity> identity() async =>
      const AssistantModelIdentity('openai', 'gpt-6-luna', null);

  @override
  Future<String> interpret(
          {required String prompt,
          required AssistantModelIdentity identity}) async =>
      '{"kind":"data","categories":["workouts"],"dateExpression":"2026-10-18","title":"Gewichtsverlauf September"}';

  @override
  Stream<String> answer(
      {required String prompt,
      required AssistantModelIdentity identity,
      required Future<void> Function() onDispatch}) async* {
    await onDispatch();
    yield 'Am 1. September lag das Gewicht bei 90,7 kg. ';
    await Future<void>.delayed(const Duration(milliseconds: 900));
    yield 'Am 30. September lag es bei 89,2 kg.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('overlay saves a denied request and reopens its conversation',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(database);
    addTearDown(DatabaseHelper.closeAndResetDriftDb);
    await database.into(database.workoutLogs).insert(
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
                    localDataSource: WorkoutLocalDataSource(database))),
            Provider<IDiaryRepository>.value(
                value: NutritionRepository(
                    localDataSource: DiaryLocalDataSource(database))),
            Provider<IProfileRepository>.value(
                value: ProfileRepository(
                    localDataSource: ProfileLocalDataSource(database))),
            Provider<IGoalRepository>.value(
                value: GoalRepositoryImpl(database: database)),
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
            ))),
          ),
        );

    await tester.pumpWidget(app(const ValueKey('first')));
    await tester.tap(find.bySemanticsLabel('AI cloud').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.enterText(find.byType(TextField), 'Hi there');
    await tester.tap(find.byIcon(LucideIcons.arrow_up));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Hello!'), findsOneWidget);
    expect(find.text('Data access request').hitTestable(), findsNothing);
    await tester.enterText(find.byType(TextField), 'My workouts on 2026-10-18');
    await tester.tap(find.byIcon(LucideIcons.arrow_up));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Data access request').hitTestable(), findsOneWidget);
    expect(find.textContaining('workouts'), findsWidgets);
    tester
        .widget<TextButton>(find.ancestor(
          of: find.text('Decline'),
          matching: find.byType(TextButton),
        ))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final history = AssistantHistoryRepository(database);
    final conversation = (await history.conversations()).single;
    final access =
        (await history.accessForConversation(conversation.id)).single;
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
    await tester.tap(find.text('Data access'));
    await tester.pump();
    expect(find.textContaining('Status: denied'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pump();
    expect(find.textContaining('Status: denied'), findsNothing);
  });

  testWidgets(
      'approved data stream continues rendering chunks after loading cloud dismisses',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(database);
    addTearDown(DatabaseHelper.closeAndResetDriftDb);
    await database.into(database.workoutLogs).insert(
          WorkoutLogsCompanion.insert(
            startTime: DateTime(2026, 10, 18, 9),
            endTime: drift.Value(DateTime(2026, 10, 18, 10)),
            status: const drift.Value('completed'),
            routineNameSnapshot: const drift.Value('Push'),
          ),
        );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<IWorkoutRepository>.value(
              value: WorkoutRepository(
                  localDataSource: WorkoutLocalDataSource(database))),
          Provider<IDiaryRepository>.value(
              value: NutritionRepository(
                  localDataSource: DiaryLocalDataSource(database))),
          Provider<IProfileRepository>.value(
              value: ProfileRepository(
                  localDataSource: ProfileLocalDataSource(database))),
          Provider<IGoalRepository>.value(
              value: GoalRepositoryImpl(database: database)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: Scaffold(
            body: SizedBox.expand(
              child: DraggableAiCloud(
                semanticLabel: 'AI cloud',
                semanticHint: 'Open',
                liveliness: 0.1,
                useLiveAi: true,
                modelClient: _LongStreamingModel(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('AI cloud').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.enterText(
      find.byType(TextField),
      'Wie viel Gewicht habe ich im September verloren?',
    );
    await tester.tap(find.byIcon(LucideIcons.arrow_up));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Datenzugriffsanfrage').hitTestable(), findsOneWidget);
    tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    final history = AssistantHistoryRepository(database);
    final conversations = await history.conversations();
    final messages = await history.messages(conversations.single.id);
    expect(
      messages.last.content,
      'Am 1. September lag das Gewicht bei 90,7 kg. Am 30. September lag es bei 89,2 kg.',
    );
    expect(
      find.textContaining('Am 30. September lag es bei 89,2 kg.'),
      findsOneWidget,
    );
  });
}
