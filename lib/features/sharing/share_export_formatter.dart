import 'package:intl/intl.dart';

import '../../generated/app_localizations.dart';
import '../../services/unit_service.dart';
import 'share_link_codec.dart';

/// Human-readable exports built from the same snapshot used for JSON and links.
class ShareExportFormatter {
  const ShareExportFormatter._();

  static String format(
    ShareLinkPayload payload,
    AppLocalizations l10n,
    UnitService units,
    String locale,
  ) {
    final number = NumberFormat.decimalPattern(locale);
    String weight(num kilograms) =>
        '${number.format(units.convertDisplayValue(kilograms.toDouble(), UnitDimension.weight))} ${units.suffixFor(UnitDimension.weight)}';

    String setLine(Map set, int index) {
      final parts = <String>[
        '${index + 1}. ${_setType(set['type'] as String, l10n)}'
      ];
      if (set['reps'] != null) parts.add('${set['reps']} ${l10n.repsShort}');
      if (set['weight'] is num) parts.add(weight(set['weight'] as num));
      if (set['rir'] != null) parts.add('RIR ${set['rir']}');
      return parts.join(' · ');
    }

    void appendRoutine(StringBuffer buffer, ShareLinkPayload routine) {
      for (final raw in routine.data['exercises'] as List) {
        final exercise = raw as Map;
        buffer.writeln('• ${exercise['name']}');
        final muscles =
            (exercise['muscles'] as List?)?.whereType<String>().toList() ?? [];
        if (muscles.isNotEmpty) {
          buffer.writeln('  ${l10n.shareTargetMuscles}: ${muscles.join(', ')}');
        }
        for (final entry in (exercise['sets'] as List).asMap().entries) {
          buffer.writeln('  ${setLine(entry.value as Map, entry.key)}');
        }
        if (exercise['pause'] != null) {
          buffer.writeln('  ${l10n.shareRestSeconds}: ${exercise['pause']}');
        }
        if ((exercise['notes'] as String?)?.trim().isNotEmpty == true) {
          buffer.writeln('  ${exercise['notes']}');
        }
      }
    }

    final buffer = StringBuffer()
      ..writeln('${l10n.appTitle} · ${payload.name}');
    switch (payload.type) {
      case 'routine':
        buffer.writeln();
        appendRoutine(buffer, payload);
      case 'plan':
        final days = payload.data['days'] as List;
        buffer
          ..writeln(payload.data['kind'] == 'week'
              ? l10n.sharePlanWeekly
              : l10n.sharePlanSequence)
          ..writeln('${days.length} ${l10n.shareDays}')
          ..writeln();
        for (final entry in days.asMap().entries) {
          final raw = entry.value;
          if (raw == null) {
            buffer.writeln(
                '${l10n.shareDay} ${entry.key + 1}: ${l10n.shareRestDay}');
            continue;
          }
          final routine =
              ShareLinkPayload.fromJson(Map<String, dynamic>.from(raw as Map));
          buffer.writeln('${l10n.shareDay} ${entry.key + 1}: ${routine.name}');
          appendRoutine(buffer, routine);
          buffer.writeln();
        }
      case 'recipe':
        final items = payload.data['items'] as List;
        double total(String key) => items.fold<double>(0, (sum, raw) {
              final item = raw as Map;
              return sum +
                  ((item[key] as num?)?.toDouble() ?? 0) *
                      (item['grams'] as num).toDouble() /
                      100;
            });
        buffer
          ..writeln('${l10n.sharePortions}: ${payload.data['portions'] ?? 1}')
          ..writeln(
              '${l10n.shareTotal}: ${number.format(total('kcal').round())} kcal · '
              'P ${number.format(total('protein'))} g · '
              'C ${number.format(total('carbs'))} g · '
              'F ${number.format(total('fat'))} g')
          ..writeln()
          ..writeln('${l10n.shareIngredients}:');
        for (final raw in items) {
          final item = raw as Map;
          buffer.writeln(
              '• ${item['name']} · ${number.format(item['grams'])} ${item['unit'] ?? 'g'}');
        }
        if ((payload.data['notes'] as String?)?.trim().isNotEmpty == true) {
          buffer
            ..writeln()
            ..writeln(payload.data['notes']);
        }
      default:
        throw const FormatException('Unsupported text export');
    }
    return buffer.toString().trimRight();
  }

  static String _setType(String raw, AppLocalizations l10n) => switch (raw) {
        'warmup' => l10n.setTypeWarmup,
        'failure' => l10n.setTypeFailure,
        'dropset' => l10n.setTypeDropset,
        'superset' => l10n.setTypeSuperset,
        _ => l10n.setTypeWork,
      };
}
