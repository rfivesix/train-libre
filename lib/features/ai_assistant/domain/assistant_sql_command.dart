import 'dart:convert';

import 'assistant_change_proposal.dart';

sealed class AssistantSqlCommand {
  const AssistantSqlCommand();

  factory AssistantSqlCommand.parse(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      final objectStart = text.indexOf('{');
      if (objectStart < 0) rethrow;
      final objectEnd = _jsonObjectEnd(text, objectStart);
      if (objectEnd == null) rethrow;
      decoded = jsonDecode(text.substring(objectStart, objectEnd + 1));
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object.');
    }
    switch (decoded['type']) {
      case 'query':
        final sql = decoded['sql'];
        if (sql is! String || sql.trim().isEmpty || sql.length > 8000) {
          throw const FormatException('Invalid SQL query command.');
        }
        return AssistantSqlQueryCommand(sql.trim());
      case 'answer':
        final answer = decoded['answer'];
        if (answer is! String ||
            answer.trim().isEmpty ||
            answer.length > 8000) {
          throw const FormatException('Invalid final answer command.');
        }
        return AssistantSqlAnswerCommand(answer.trim());
      case 'request_data':
        final categories = decoded['categories'];
        if (categories is! List ||
            categories.isEmpty ||
            categories.length > 10 ||
            categories.any((value) => value is! String)) {
          throw const FormatException('Invalid additional data request.');
        }
        final expression = decoded['dateExpression'];
        if (expression != null &&
            (expression is! String || expression.length > 100)) {
          throw const FormatException('Invalid additional date expression.');
        }
        final scope = decoded['scope'];
        if (scope != null && scope is! Map<String, dynamic>) {
          throw const FormatException('Invalid additional data scope.');
        }
        return AssistantSqlDataRequestCommand(
          categories.cast<String>(),
          dateExpression: expression as String?,
          scope: scope as Map<String, dynamic>?,
        );
      case 'proposal':
        return AssistantSqlChangeProposalCommand(
          AssistantChangeProposal.fromJson(decoded),
        );
      case 'search_catalog':
        final catalog = decoded['catalog'];
        final query = decoded['query'];
        if (!const {'food', 'exercises'}.contains(catalog) ||
            query is! String ||
            query.trim().length < 2 ||
            query.length > 100) {
          throw const FormatException('Invalid catalog search command.');
        }
        return AssistantSqlCatalogSearchCommand(
          catalog as String,
          query.trim(),
        );
      default:
        throw const FormatException('Unknown SQL assistant command.');
    }
  }

  static int? _jsonObjectEnd(String text, int start) {
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var index = start; index < text.length; index++) {
      final character = text[index];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (character == r'\') {
          escaped = true;
        } else if (character == '"') {
          inString = false;
        }
        continue;
      }
      if (character == '"') {
        inString = true;
      } else if (character == '{') {
        depth++;
      } else if (character == '}') {
        depth--;
        if (depth == 0) return index;
      }
    }
    return null;
  }
}

class AssistantSqlQueryCommand extends AssistantSqlCommand {
  const AssistantSqlQueryCommand(this.sql);
  final String sql;
}

class AssistantSqlAnswerCommand extends AssistantSqlCommand {
  const AssistantSqlAnswerCommand(this.answer);
  final String answer;
}

class AssistantSqlDataRequestCommand extends AssistantSqlCommand {
  const AssistantSqlDataRequestCommand(
    this.categories, {
    this.dateExpression,
    this.scope,
  });
  final List<String> categories;
  final String? dateExpression;
  final Map<String, dynamic>? scope;
}

class AssistantSqlChangeProposalCommand extends AssistantSqlCommand {
  const AssistantSqlChangeProposalCommand(this.proposal);
  final AssistantChangeProposal proposal;
}

class AssistantSqlCatalogSearchCommand extends AssistantSqlCommand {
  const AssistantSqlCatalogSearchCommand(this.catalog, this.query);
  final String catalog;
  final String query;
}
