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
