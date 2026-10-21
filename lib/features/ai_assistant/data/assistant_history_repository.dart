import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../data/drift_database.dart';

class AssistantConversation {
  const AssistantConversation(
      this.id, this.title, this.createdAt, this.updatedAt);
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.status,
    this.providerId,
    this.modelId,
    this.error,
  });
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final DateTime createdAt;
  final String status;
  final String? providerId;
  final String? modelId;
  final String? error;
}

class AssistantAccessRecord {
  const AssistantAccessRecord({
    required this.id,
    required this.conversationId,
    required this.messageId,
    required this.categories,
    required this.scope,
    required this.requestedAt,
    required this.status,
    required this.sharedManifest,
    this.decidedAt,
    this.sharedAt,
    this.providerId,
    this.modelId,
    this.error,
  });
  final String id;
  final String conversationId;
  final String messageId;
  final List<String> categories;
  final Map<String, dynamic> scope;
  final DateTime requestedAt;
  final DateTime? decidedAt;
  final DateTime? sharedAt;
  final String status;
  final String? providerId;
  final String? modelId;
  final Map<String, dynamic> sharedManifest;
  final String? error;
}

/// Local history and access ledger. The ledger stores references and field
/// names, while message bodies remain in the chat table.
class AssistantHistoryRepository {
  AssistantHistoryRepository(this.database);
  final AppDatabase database;
  static const _uuid = Uuid();

  Future<List<AssistantConversation>> conversations() async {
    final rows = await database
        .customSelect(
          'SELECT * FROM assistant_conversations ORDER BY updated_at DESC',
        )
        .get();
    return rows
        .map((row) => AssistantConversation(
              row.read<String>('id'),
              row.read<String>('title'),
              DateTime.parse(row.read<String>('created_at')),
              DateTime.parse(row.read<String>('updated_at')),
            ))
        .toList();
  }

  Future<AssistantConversation> createConversation(String firstPrompt,
      {String locale = 'en'}) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final shortTitle = _cleanTitle(firstPrompt);
    await database.customStatement(
      'INSERT INTO assistant_conversations(id,title,created_at,updated_at) VALUES(?,?,?,?)',
      [id, shortTitle, now.toIso8601String(), now.toIso8601String()],
    );
    return AssistantConversation(id, shortTitle, now, now);
  }

  Future<void> updateConversationTitle(String id, String title) async {
    final cleaned = _cleanTitle(title);
    if (cleaned.isEmpty) return;
    await database.customStatement(
      'UPDATE assistant_conversations SET title = ? WHERE id = ?',
      [cleaned, id],
    );
  }

  static String _cleanTitle(String raw) {
    final title = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    return title.length > 70 ? '${title.substring(0, 70)}…' : title;
  }

  Future<List<AssistantMessage>> messages(String conversationId) async {
    final rows = await database.customSelect(
      'SELECT * FROM assistant_messages WHERE conversation_id = ? ORDER BY created_at, rowid',
      variables: [drift.Variable.withString(conversationId)],
    ).get();
    return rows
        .map((row) => AssistantMessage(
              id: row.read<String>('id'),
              conversationId: row.read<String>('conversation_id'),
              role: row.read<String>('role'),
              content: row.read<String>('content'),
              createdAt: DateTime.parse(row.read<String>('created_at')),
              status: row.read<String>('status'),
              providerId: row.read<String?>('provider_id'),
              modelId: row.read<String?>('model_id'),
              error: row.read<String?>('error'),
            ))
        .toList();
  }

  Future<AssistantMessage> addMessage({
    required String conversationId,
    required String role,
    required String content,
    required String status,
    String? providerId,
    String? modelId,
    String? error,
  }) async {
    if (role != 'user' && role != 'assistant') throw ArgumentError.value(role);
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      await database.customStatement(
        'INSERT INTO assistant_messages(id,conversation_id,role,content,created_at,provider_id,model_id,status,error) VALUES(?,?,?,?,?,?,?,?,?)',
        [
          id,
          conversationId,
          role,
          content,
          now.toIso8601String(),
          providerId,
          modelId,
          status,
          error,
        ],
      );
      await database.customStatement(
        'UPDATE assistant_conversations SET updated_at = ? WHERE id = ?',
        [now.toIso8601String(), conversationId],
      );
    });
    return AssistantMessage(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content,
        createdAt: now,
        status: status,
        providerId: providerId,
        modelId: modelId,
        error: error);
  }

  Future<void> updateMessage(String id,
          {required String content,
          required String status,
          String? error,
          String? providerId,
          String? modelId}) =>
      database.customStatement(
        'UPDATE assistant_messages SET content=?, status=?, error=?, provider_id=COALESCE(?,provider_id), model_id=COALESCE(?,model_id) WHERE id=?',
        [content, status, error, providerId, modelId, id],
      );

  Future<AssistantAccessRecord> requestAccess({
    required String conversationId,
    required String messageId,
    required List<String> categories,
    required Map<String, dynamic> scope,
    String? providerId,
    String? modelId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await database.customStatement(
      'INSERT INTO assistant_data_access(id,conversation_id,message_id,categories_json,scope_json,requested_at,status,provider_id,model_id) VALUES(?,?,?,?,?,?,?,?,?)',
      [
        id,
        conversationId,
        messageId,
        jsonEncode(categories),
        jsonEncode(scope),
        now.toIso8601String(),
        'pending',
        providerId,
        modelId
      ],
    );
    return AssistantAccessRecord(
        id: id,
        conversationId: conversationId,
        messageId: messageId,
        categories: categories,
        scope: scope,
        requestedAt: now,
        status: 'pending',
        sharedManifest: const {},
        providerId: providerId,
        modelId: modelId);
  }

  Future<void> decideAccess(String id, {required bool approved}) =>
      database.customStatement(
        "UPDATE assistant_data_access SET status=?, decided_at=? WHERE id=? AND status='pending'",
        [
          approved ? 'approved' : 'denied',
          DateTime.now().toUtc().toIso8601String(),
          id
        ],
      );

  Future<void> markShared(String id, Map<String, dynamic> manifest) =>
      database.customStatement(
        "UPDATE assistant_data_access SET status='shared', shared_at=COALESCE(shared_at, ?), shared_manifest_json=? WHERE id=? AND status IN ('approved','shared')",
        [DateTime.now().toUtc().toIso8601String(), jsonEncode(manifest), id],
      );

  Future<void> markNotShared(String id) => database.customStatement(
        "UPDATE assistant_data_access SET status='not_shared' WHERE id=? AND status='approved'",
        [id],
      );

  Future<void> setAccessProvider(
          String id, String providerId, String modelId) =>
      database.customStatement(
        "UPDATE assistant_data_access SET provider_id=?, model_id=? WHERE id=? AND status='approved'",
        [providerId, modelId, id],
      );

  Future<void> failAccess(String id, String error) => database.customStatement(
        "UPDATE assistant_data_access SET status='error', error=? WHERE id=? AND status IN ('pending','approved','shared')",
        [error, id],
      );

  Future<AssistantAccessRecord?> access(String id) async {
    final row = await database.customSelect(
      'SELECT * FROM assistant_data_access WHERE id=?',
      variables: [drift.Variable.withString(id)],
    ).getSingleOrNull();
    if (row == null) return null;
    return AssistantAccessRecord(
      id: row.read<String>('id'),
      conversationId: row.read<String>('conversation_id'),
      messageId: row.read<String>('message_id'),
      categories: (jsonDecode(row.read<String>('categories_json')) as List)
          .cast<String>(),
      scope: (jsonDecode(row.read<String>('scope_json')) as Map)
          .cast<String, dynamic>(),
      requestedAt: DateTime.parse(row.read<String>('requested_at')),
      decidedAt: _date(row.read<String?>('decided_at')),
      sharedAt: _date(row.read<String?>('shared_at')),
      status: row.read<String>('status'),
      providerId: row.read<String?>('provider_id'),
      modelId: row.read<String?>('model_id'),
      sharedManifest:
          (jsonDecode(row.read<String>('shared_manifest_json')) as Map)
              .cast<String, dynamic>(),
      error: row.read<String?>('error'),
    );
  }

  Future<void> expireAccess(String id) => database.customStatement(
        "UPDATE assistant_data_access SET status='expired', decided_at=? WHERE id=? AND status='pending'",
        [DateTime.now().toUtc().toIso8601String(), id],
      );

  Future<void> markUnresolved(String id) => database.customStatement(
        "UPDATE assistant_data_access SET status='unresolved' WHERE id=? AND status='approved'",
        [id],
      );

  Future<void> markNoData(String id) => database.customStatement(
        "UPDATE assistant_data_access SET status='no_data' WHERE id=? AND status='approved'",
        [id],
      );

  Future<AssistantAccessRecord?> latestAccess(String conversationId,
      {required String status}) async {
    final row = await database.customSelect(
      'SELECT id FROM assistant_data_access WHERE conversation_id=? AND status=? ORDER BY requested_at DESC LIMIT 1',
      variables: [
        drift.Variable.withString(conversationId),
        drift.Variable.withString(status)
      ],
    ).getSingleOrNull();
    return row == null ? null : access(row.read<String>('id'));
  }

  Future<AssistantAccessRecord?> latestContextAccess(
      String conversationId) async {
    final row = await database.customSelect(
      "SELECT id FROM assistant_data_access WHERE conversation_id=? AND status IN ('shared','unresolved') ORDER BY requested_at DESC LIMIT 1",
      variables: [drift.Variable.withString(conversationId)],
    ).getSingleOrNull();
    return row == null ? null : access(row.read<String>('id'));
  }

  Future<List<AssistantAccessRecord>> accessForConversation(
      String conversationId) async {
    final rows = await database.customSelect(
      'SELECT id FROM assistant_data_access WHERE conversation_id=? ORDER BY requested_at',
      variables: [drift.Variable.withString(conversationId)],
    ).get();
    final records = <AssistantAccessRecord>[];
    for (final row in rows) {
      final record = await access(row.read<String>('id'));
      if (record != null) records.add(record);
    }
    return records;
  }

  DateTime? _date(String? value) =>
      value == null ? null : DateTime.parse(value);
}
