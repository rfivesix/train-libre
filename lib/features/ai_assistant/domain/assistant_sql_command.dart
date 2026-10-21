import 'dart:convert';

sealed class AssistantSqlCommand {
  const AssistantSqlCommand();

  factory AssistantSqlCommand.parse(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final decoded = jsonDecode(text);
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
      default:
        throw const FormatException('Unknown SQL assistant command.');
    }
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
  const AssistantSqlDataRequestCommand(this.categories,
      {this.dateExpression, this.scope});
  final List<String> categories;
  final String? dateExpression;
  final Map<String, dynamic>? scope;
}
