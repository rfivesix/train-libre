import 'dart:io';
import 'package:flutter/services.dart';
import 'package:train_libre/core/media/app_media_store.dart';
import 'dart:collection';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/ai_assistant/application/assistant_chat_service.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_history_repository.dart';
import 'package:train_libre/features/ai_assistant/domain/assistant_data_action.dart';
import 'package:train_libre/features/ai_assistant/domain/assistant_data_request.dart';
import 'package:train_libre/features/ai_assistant/domain/assistant_intent_planner.dart';

String dataDecision(List<String> categories,
        {String? expression, String? start, String? end}) =>
    jsonEncode({
      'kind': 'data',
      'categories': categories,
      if (expression != null) 'dateExpression': expression,
      if (start != null && end != null)
        'scope': {'start': start, 'end': end, 'label': 'model period'},
    });

class _FakeAction implements AssistantDataAction {
  int reads = 0;
  bool fail = false;
  AssistantDateScope? lastScope;
  List<Map<String, dynamic>> records = [
    {
      'ref': 'workout:42',
      'startedAt': '2026-10-18T09:00:00',
      'sets': [
        {'ref': 'set:7', 'exercise': 'Squat', 'reps': 5},
      ]
    },
  ];
  @override
  Set<AssistantDataCategory> get categories => {AssistantDataCategory.workouts};
  @override
  Future<AssistantActionResult> read(
      AssistantDataCategory category, AssistantDateScope? scope) async {
    reads++;
    lastScope = scope;
    if (fail) {
      return AssistantActionResult(
          category: category,
          status: AssistantActionStatus.error,
          error: 'Unavailable');
    }
    return AssistantActionResult(
        category: category,
        status: AssistantActionStatus.success,
        records: records);
  }
}

class _OtherAction implements AssistantDataAction {
  _OtherAction([this.category = AssistantDataCategory.nutrition]);
  final AssistantDataCategory category;
  int reads = 0;
  @override
  Set<AssistantDataCategory> get categories => {category};
  @override
  Future<AssistantActionResult> read(
      AssistantDataCategory category, AssistantDateScope? scope) async {
    reads++;
    return AssistantActionResult(
        category: category,
        status: AssistantActionStatus.success,
        records: const [
          {'ref': 'nutrition:private', 'caloriesKcal': 1800}
        ]);
  }
}

class _FakeModel implements AssistantModelClient {
  final decisions = Queue<String>();
  final answerResponses = Queue<String>();
  final streamedAnswerResponses = Queue<List<String>>();
  final interpretationPrompts = <String>[];
  final answerPrompts = <String>[];
  int answers = 0;
  String? answerPrompt;
  bool dispatch = true;

  @override
  Future<AssistantModelIdentity> identity() async =>
      const AssistantModelIdentity('test-provider', 'test-model', null);

  @override
  Future<String> interpret({
    required String prompt,
    required AssistantModelIdentity identity,
  }) async {
    interpretationPrompts.add(prompt);
    return decisions.isEmpty
        ? dataDecision(['workouts'], expression: 'last Sunday')
        : decisions.removeFirst();
  }

  @override
  Stream<String> answer(
      {required String prompt,
      required AssistantModelIdentity identity,
      required Future<void> Function() onDispatch}) async* {
    answers++;
    answerPrompt = prompt;
    answerPrompts.add(prompt);
    if (!dispatch) throw StateError('Network unavailable');
    await onDispatch();
    if (streamedAnswerResponses.isNotEmpty) {
      for (final chunk in streamedAnswerResponses.removeFirst()) {
        yield chunk;
      }
      return;
    }
    yield answerResponses.isEmpty
        ? jsonEncode({'type': 'answer', 'answer': 'Grounded answer'})
        : answerResponses.removeFirst();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late AssistantHistoryRepository history;
  late _FakeAction action;
  late _FakeModel model;
  late AssistantChatService chat;
  final now = DateTime(2026, 10, 20, 12);

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('assistant_chat_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );
    AppMediaStore.instance.resetForTesting();
    database = AppDatabase(NativeDatabase.memory());
    history = AssistantHistoryRepository(database);
    action = _FakeAction();
    model = _FakeModel();
    chat = AssistantChatService(
        history: history, data: AssistantDataGateway([action]), model: model);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    AppMediaStore.instance.resetForTesting();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
    await database.close();
  });

  test('ordinary chat gets a persisted answer without data approval', () async {
    model.decisions.add(jsonEncode({'kind': 'chat', 'answer': 'Hello there!'}));
    final submission =
        await chat.submit('Hi, can we talk?', now: now, locale: 'en');
    expect(submission.access, isNull);
    expect(submission.clarification, 'Hello there!');
    expect(action.reads, 0);
    expect(model.answers, 0);
    expect((await history.accessForConversation(submission.conversationId)),
        isEmpty);
    final saved = await history.messages(submission.conversationId);
    expect(saved.map((message) => message.role), ['user', 'assistant']);
    expect(saved.last.status, 'chat');
    expect(saved.last.content, 'Hello there!');
    expect(saved.last.providerId, 'test-provider');
    expect(saved.last.modelId, 'test-model');
    model.decisions.add(jsonEncode({'kind': 'chat', 'answer': 'Of course.'}));
    await chat.submit('What did you just say?',
        conversationId: submission.conversationId, now: now, locale: 'en');
    expect(model.interpretationPrompts.last, contains('Hello there!'));
    expect(action.reads, 0);
  });

  test('natural question receives inferred narrow scope before any read',
      () async {
    model.decisions.add(
        dataDecision(['workouts'], start: '2026-10-07', end: '2026-10-20'));
    final submission = await chat.submit('How am I doing with training?',
        now: now, locale: 'en');
    expect(submission.access, isNotNull);
    expect(submission.request!.categories, {AssistantDataCategory.workouts});
    expect(submission.request!.scope!.start, DateTime(2026, 10, 7));
    expect(submission.request!.scope!.end, DateTime(2026, 10, 20));
    expect(action.reads, 0);
    expect(model.answers, 0);
    expect(submission.access!.scope['start'], '2026-10-07');
    expect(model.interpretationPrompts.single, isNot(contains('workout:42')));
  });

  test('model date expression is resolved in local civil time', () async {
    model.decisions.add(dataDecision(['workouts'],
        expression: 'last Sunday', start: '2026-10-17', end: '2026-10-17'));
    final submission = await chat.submit('How was my training last Sunday?',
        now: now, locale: 'en');
    expect(submission.request!.scope!.start, DateTime(2026, 10, 18));
    expect(submission.access!.scope['timezone'], now.timeZoneName);
    expect(action.reads, 0);
  });

  test('diary request from a named date becomes a reviewable range', () async {
    chat = AssistantChatService(
        history: history,
        data: AssistantDataGateway(
            [action, _OtherAction(AssistantDataCategory.diary)]),
        model: model);
    model.decisions.add(dataDecision(['diary'], expression: 'from May 1'));
    final submission = await chat.submit('Show me my diary from May 1',
        now: now, locale: 'en');
    expect(submission.request!.categories, {AssistantDataCategory.diary});
    expect(submission.request!.scope!.start, DateTime(2026, 5, 1));
    expect(submission.request!.scope!.end, DateTime(2026, 10, 20));
    expect(submission.access!.scope['start'], '2026-05-01');
    expect(action.reads, 0);
  });

  test('explicit month name and German date resolve without special syntax',
      () {
    const resolver = AssistantDateResolver();
    expect(resolver.resolveDate('May 1', now: now, locale: 'en')!.start,
        DateTime(2026, 5, 1));
    expect(resolver.resolveDate('1. Mai', now: now, locale: 'de')!.start,
        DateTime(2026, 5, 1));
    final sinceMay =
        resolver.resolveDate('from May 1', now: now, locale: 'en')!;
    expect(sinceMay.start, DateTime(2026, 5, 1));
    expect(sinceMay.end, DateTime(2026, 10, 20));
    expect(resolver.resolveDate('last Sunday', now: now, locale: 'en')!.start,
        DateTime(2026, 10, 18));
    expect(
        resolver
            .resolveDate('01.10.2026 to 07.10.2026', now: now, locale: 'de')!
            .end,
        DateTime(2026, 10, 7));
    expect(resolver.resolveDate('10/11/2026', now: now, locale: 'en-US')!.start,
        DateTime(2026, 10, 11));
    expect(resolver.resolveDate('10/11/2026', now: now, locale: 'de-DE')!.start,
        DateTime(2026, 11, 10));
    expect(resolver.resolveDate('10/11/2026', now: now, locale: 'en'), isNull);
  });

  test('ambiguous intent asks one specific question and keeps context',
      () async {
    model.decisions.add(jsonEncode({
      'kind': 'clarify',
      'question': 'Do you mean your training progress or your sleep?'
    }));
    final first = await chat.submit('How am I doing?', now: now, locale: 'en');
    expect(first.access, isNull);
    expect(first.clarification, contains('training progress or your sleep'));
    expect(action.reads, 0);
    model.decisions.add(
        dataDecision(['workouts'], start: '2026-10-07', end: '2026-10-20'));
    final second = await chat.submit('Training',
        conversationId: first.conversationId, now: now, locale: 'en');
    expect(second.access, isNotNull);
    expect(model.interpretationPrompts.last, contains('How am I doing?'));
    expect(model.interpretationPrompts.last,
        contains('Do you mean your training progress or your sleep?'));
    expect(action.reads, 0);
  });

  test('persists approved conversation and requires fresh follow-up approval',
      () async {
    final first = await chat.submit('How was my training last Sunday?',
        now: now, locale: 'en');
    await chat
        .approveAndAnswer(first.access!.id, first.userMessage.content)
        .drain<void>();
    final reopened = AssistantHistoryRepository(database);
    final saved = await reopened.messages(first.conversationId);
    expect(saved.last.content, 'Grounded answer');
    expect(saved.last.providerId, 'test-provider');
    model.decisions.add(dataDecision(['workouts'], expression: 'yesterday'));
    final followUp = await chat.submit('And yesterday?',
        conversationId: first.conversationId, now: now, locale: 'en');
    expect(followUp.access!.status, 'pending');
    expect(followUp.request!.scope!.start, DateTime(2026, 10, 19));
    expect(model.interpretationPrompts.last,
        contains('How was my training last Sunday?'));
    expect(
        model.interpretationPrompts.last, isNot(contains('Grounded answer')));
    expect(action.reads, 1);
    expect(model.answers, 1);
  });

  test('streams only the answer field while the model generates its JSON',
      () async {
    model.streamedAnswerResponses.add([
      '{"type":"answer","answer":"Your approved ',
      'training data shows a steady increase.',
      ' Keep it up!"}',
    ]);
    model.decisions.add(dataDecision(['workouts'],
        start: '2026-10-18', end: '2026-10-18'));
    final submission = await chat.submit('How was my training last Sunday?',
        now: now, locale: 'en');

    final chunks = await chat
        .approveAndAnswer(submission.access!.id, submission.userMessage.content)
        .toList();

    expect(chunks, [
      'Your approved ',
      'training data shows a steady increase.',
      ' Keep it up!',
    ]);
    final saved = await history.messages(submission.conversationId);
    expect(saved.last.content, chunks.join());
  });

  test('clearing app data removes conversations and access records', () async {
    final submission =
        await chat.submit('My workouts last Sunday', now: now, locale: 'en');
    await DatabaseHelper.forTesting(database).clearAllUserData();
    expect(await history.conversations(), isEmpty);
    expect(await history.messages(submission.conversationId), isEmpty);
    expect(await history.access(submission.access!.id), isNull);
  });

  test('denial never reads or transmits records', () async {
    final submission =
        await chat.submit('My workouts last Sunday', now: now, locale: 'en');
    await chat.deny(submission.access!.id);
    final audit = await history.access(submission.access!.id);
    expect(audit!.status, 'denied');
    expect(audit.sharedAt, isNull);
    expect(audit.sharedManifest, isEmpty);
    expect(action.reads, 0);
    expect(model.answers, 0);
  });

  test('audit describes only the records actually transmitted', () async {
    model.answerResponses.addAll([
      jsonEncode({
        'type': 'query',
        'sql': 'SELECT ref, startedAt FROM data_workouts',
      }),
      jsonEncode({'type': 'answer', 'answer': 'Grounded answer'}),
    ]);
    final submission =
        await chat.submit('My workouts last Sunday', now: now, locale: 'en');
    await chat
        .approveAndAnswer(submission.access!.id, submission.userMessage.content)
        .drain<void>();
    final audit = await history.access(submission.access!.id);
    expect(audit!.status, 'shared');
    expect(audit.decidedAt, isNotNull);
    expect(audit.sharedAt, isNotNull);
    expect(audit.providerId, 'test-provider');
    expect(audit.modelId, 'test-model');
    final analysis = audit.sharedManifest['sqlAnalysis'] as Map;
    expect(analysis['queryCount'], 1);
    final queryAudit = (analysis['queries'] as List).single as Map;
    expect(queryAudit['tables'], ['data_workouts']);
    expect(queryAudit['rowCount'], 1);
    expect(queryAudit['payloadSha256'], hasLength(64));
    expect(model.answerPrompts.first, contains('Table data_workouts'));
    expect(model.answerPrompts.first, isNot(contains('workout:42')));
    expect(model.answerPrompts.last, contains('workout:42'));
  });

  test('schema-only analysis is audited without claiming records were shared',
      () async {
    final submission = await chat.submit('How many workouts do I have?',
        now: now, locale: 'en');
    await chat
        .approveAndAnswer(submission.access!.id, submission.userMessage.content)
        .drain<void>();

    final audit = await history.access(submission.access!.id);
    expect(audit!.status, 'not_shared');
    expect(audit.sharedAt, isNull);
    expect(audit.sharedManifest, isEmpty);
    expect(model.answerPrompts.single, contains('Schema and column meanings'));
    expect(model.answerPrompts.single, isNot(contains('workout:42')));
  });

  test('approval reads and sends only proposed categories and period',
      () async {
    model.answerResponses.addAll([
      jsonEncode({
        'type': 'query',
        'sql': 'SELECT ref FROM data_workouts',
      }),
      jsonEncode({'type': 'answer', 'answer': 'Grounded answer'}),
    ]);
    final other = _OtherAction();
    chat = AssistantChatService(
        history: history,
        data: AssistantDataGateway([action, other]),
        model: model);
    model.decisions.add(dataDecision(['workouts'], expression: 'last Sunday'));
    final submission = await chat.submit('How was training last Sunday?',
        now: now, locale: 'en');
    await chat
        .approveAndAnswer(submission.access!.id, submission.userMessage.content)
        .drain<void>();
    expect(action.lastScope!.start, DateTime(2026, 10, 18));
    expect(action.lastScope!.end, DateTime(2026, 10, 18));
    expect(other.reads, 0);
    expect(model.answerPrompts.first, contains('data_workouts'));
    expect(model.answerPrompts.first, isNot(contains('workout:42')));
    expect(model.answerPrompts.last, contains('workout:42'));
    expect(model.answerPrompt, isNot(contains('nutrition:private')));
    final audit = await history.access(submission.access!.id);
    expect(audit!.sharedManifest.keys, ['sqlAnalysis']);
    expect(
        ((audit.sharedManifest['sqlAnalysis'] as Map)['queries'] as List)
            .single['tables'],
        ['data_workouts']);
  });

  test('missing records produce a local answer without transmission', () async {
    action.records = [];
    final submission =
        await chat.submit('My workouts last Sunday', now: now, locale: 'en');
    final answer = await chat
        .approveAndAnswer(submission.access!.id, submission.userMessage.content)
        .join();
    expect(answer, contains('No records'));
    expect(model.answers, 0);
    final audit = await history.access(submission.access!.id);
    expect(audit!.status, 'no_data');
    expect(audit.sharedAt, isNull);
  });

  test('invalid model proposal cannot create approval or read records',
      () async {
    model.decisions.add(dataDecision(['secretDatabase'],
        start: '2026-10-18', end: '2026-10-18'));
    final submission =
        await chat.submit('Check my data', now: now, locale: 'en');
    expect(submission.access, isNull);
    expect(submission.clarification, contains('rephrase'));
    expect(action.reads, 0);
    expect(model.answers, 0);
    expect(await history.accessForConversation(submission.conversationId),
        isEmpty);
  });

  test('unavailable read action is rejected before an approval request',
      () async {
    model.decisions.add(dataDecision(['sleep'], expression: 'yesterday'));
    final submission =
        await chat.submit('How did I sleep?', now: now, locale: 'en');
    expect(submission.access, isNull);
    expect(submission.clarification, contains('cannot read'));
    expect(action.reads, 0);
    expect(model.answers, 0);
  });

  test('invalid date and oversized scope are rejected', () {
    const planner = AssistantIntentPlanner();
    final impossible = planner.parse(
        dataDecision(['workouts'], start: '2026-02-30', end: '2026-03-01'),
        now: now,
        locale: 'en');
    expect(impossible.kind, AssistantIntentKind.clarify);
    final oversized = planner.parse(
        dataDecision(['workouts'], start: '2025-01-01', end: '2026-10-20'),
        now: now,
        locale: 'en');
    expect(oversized.kind, AssistantIntentKind.clarify);
    final historicalPlan = planner.parse(
        dataDecision(['trainingPlans'], start: '2026-10-01', end: '2026-10-01'),
        now: now,
        locale: 'en');
    expect(historicalPlan.kind, AssistantIntentKind.clarify);
    final unknownExpression = planner.parse(
        dataDecision(['workouts'], expression: 'the day before that'),
        now: now,
        locale: 'en');
    expect(unknownExpression.kind, AssistantIntentKind.clarify);
  });

  test('model can infer a bounded default when date is omitted', () {
    const planner = AssistantIntentPlanner();
    final intent =
        planner.parse(dataDecision(['workouts']), now: now, locale: 'en');
    expect(intent.request!.scope!.start, DateTime(2026, 10, 7));
    expect(intent.request!.scope!.end, DateTime(2026, 10, 20));
    expect(intent.request!.scope!.label, contains('inferred'));
  });

  test('ambiguous target is clarified without choosing an unstable row number',
      () async {
    action.records = [
      {'ref': 'workout:42', 'startedAt': '2026-10-18T09:00:00'},
      {'ref': 'workout:43', 'startedAt': '2026-10-18T18:00:00'},
    ];
    final first = await chat.submit('Show my workout last Sunday',
        now: now, locale: 'en');
    model.answerResponses.addAll([
      jsonEncode({
        'type': 'query',
        'sql': 'SELECT ref FROM data_workouts',
      }),
      jsonEncode({
        'type': 'answer',
        'answer': 'Do you mean the morning or evening workout?'
      }),
    ]);
    final answer = await chat
        .approveAndAnswer(first.access!.id, first.userMessage.content)
        .join();
    expect(answer, contains('morning or evening'));
    expect(answer, isNot(contains('Reply with a number')));
    expect(model.answers, greaterThan(0));
    expect(model.answerPrompt, contains('workout:42'));
    expect(model.answerPrompt, contains('workout:43'));
  });

  test('read failure sends nothing and leaves no shared manifest', () async {
    action.fail = true;
    final submission =
        await chat.submit('My workouts last Sunday', now: now, locale: 'en');
    await chat
        .approveAndAnswer(submission.access!.id, submission.userMessage.content)
        .drain<void>();
    final audit = await history.access(submission.access!.id);
    expect(audit!.status, 'error');
    expect(audit.sharedManifest, isEmpty);
    expect(audit.sharedAt, isNull);
    expect(model.answers, 0);
  });

  test('provider failure before dispatch does not mark records shared',
      () async {
    model.dispatch = false;
    final submission =
        await chat.submit('My workouts last Sunday', now: now, locale: 'en');
    await expectLater(
        chat.approveAndAnswer(
            submission.access!.id, submission.userMessage.content),
        emitsError(isA<StateError>()));
    final audit = await history.access(submission.access!.id);
    expect(audit!.status, 'error');
    expect(audit.sharedAt, isNull);
    expect(audit.sharedManifest, isEmpty);
  });

  test('expired approval cannot fetch or transmit records', () async {
    final submission =
        await chat.submit('My workouts last Sunday', now: now, locale: 'en');
    await database.customStatement(
        'UPDATE assistant_data_access SET requested_at=? WHERE id=?', [
      DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 1))
          .toIso8601String(),
      submission.access!.id,
    ]);
    await expectLater(
        chat.approveAndAnswer(
            submission.access!.id, submission.userMessage.content),
        emitsError(isA<StateError>()));
    final audit = await history.access(submission.access!.id);
    expect(audit!.status, 'expired');
    expect(audit.sharedAt, isNull);
    expect(action.reads, 0);
    expect(model.answers, 0);
  });

  test('saves AI-provided contextual conversation title and German responses',
      () async {
    model.decisions.add(jsonEncode({
      'kind': 'data',
      'title': 'Trainingsanalyse Sonntag',
      'categories': ['workouts'],
      'dateExpression': 'letzten Sonntag',
    }));
    final submission = await chat.submit(
      'Kannst du mir sagen wie mein Training letzten Sonntag war?',
      now: now,
      locale: 'de-DE',
    );
    final conversations = await history.conversations();
    expect(conversations.single.title, 'Trainingsanalyse Sonntag');

    final denied = await chat.deny(submission.access!.id, locale: 'de-DE');
    expect(denied.content, contains('Datenzugriff abgelehnt'));
  });

  test('synthesizes contextual conversation title when model omits title',
      () async {
    model.decisions
        .add(dataDecision(['workouts'], expression: 'letzten Sonntag'));
    await chat.submit(
      'Kannst du mir sagen wie mein Training letzten Sonntag war?',
      now: now,
      locale: 'de-DE',
    );
    final conversations = await history.conversations();
    expect(conversations.single.title, 'Trainingseinheiten · letzten sonntag');
  });
}
