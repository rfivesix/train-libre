import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../../widgets/common/app_info_row.dart';
import '../../../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../data/assistant_history_repository.dart';
import '../../../domain/assistant_data_request.dart';
import 'cloud_overlay_formatters.dart';
export 'cloud_overlay_formatters.dart' show formatModelDisplayName;

/// Localizes data access status strings.
String localizeAccessStatus(String status, {required bool isDe}) {
  if (status == 'not_shared') {
    return isDe ? 'Keine Datensätze übertragen' : 'No records shared';
  }
  if (!isDe) return status;
  return switch (status) {
    'pending' => 'Ausstehend',
    'approved' => 'Freigegeben',
    'denied' => 'Abgelehnt',
    'shared' => 'Übertragen',
    'not_shared' => 'Keine Datensätze übertragen',
    'no_data' => 'Keine Daten im Zeitraum (nichts übertragen)',
    'unresolved' => 'Rückfrage offen (nichts übertragen)',
    'expired' => 'Abgelaufen (nichts übertragen)',
    'error' => 'Fehler (nichts übertragen)',
    _ => status,
  };
}

/// In-overlay modal bottom sheet displaying the audit record of an AI data access request.
class CloudOverlayAccessAuditModal extends StatelessWidget {
  const CloudOverlayAccessAuditModal({
    super.key,
    required this.access,
    required this.onClose,
  });

  final AssistantAccessRecord access;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLocale = Localizations.localeOf(context).toString();
    String formatTimestamp(DateTime timestamp) =>
        DateFormat.yMMMd(dateLocale).add_Hm().format(timestamp.toLocal());
    final isDe = locale.toLowerCase().startsWith('de');
    final manifest = access.sharedManifest;
    final categoriesText = access.categories
        .map((c) => AssistantDataCategory.localizeName(c, locale))
        .join(', ');
    final rawScopeLabel = access.scope['label']?.toString() ?? 'current';
    final localizedScopeLabel =
        localizeAssistantScopeLabel(rawScopeLabel, locale);
    final start = access.scope['start']?.toString();
    final end = access.scope['end']?.toString();
    final scopeText = start == null
        ? localizedScopeLabel
        : isDe
            ? '$localizedScopeLabel ($start bis ${end ?? start})'
            : '$localizedScopeLabel ($start to ${end ?? start})';
    final statusText = localizeAccessStatus(access.status, isDe: isDe);
    final modelDisplay =
        formatModelDisplayName(access.providerId, access.modelId);
    final isDark = theme.brightness == Brightness.dark;

    final rows = <Widget>[
      _accessInfoRow(
        icon: access.status == 'approved' || access.status == 'shared'
            ? LucideIcons.shield_check
            : (access.status == 'denied'
                ? LucideIcons.shield_x
                : LucideIcons.shield_alert),
        title: isDe ? 'Status: $statusText' : 'Status: $statusText',
        subtitle: isDe ? 'Datenfreigabestatus' : 'Data access status',
      ),
      _accessInfoRow(
        icon: LucideIcons.clock,
        title: isDe ? 'Angefragt' : 'Requested',
        subtitle: formatTimestamp(access.requestedAt),
      ),
      if (access.decidedAt != null)
        _accessInfoRow(
          icon: LucideIcons.circle_check,
          title: isDe ? 'Entschieden' : 'Decided',
          subtitle: formatTimestamp(access.decidedAt!),
        ),
      _accessInfoRow(
        icon: LucideIcons.layout_grid,
        title: isDe ? 'Kategorien' : 'Categories',
        subtitle: categoriesText,
      ),
      _accessInfoRow(
        icon: LucideIcons.calendar,
        title: isDe ? 'Zeitraum' : 'Scope',
        subtitle: scopeText,
      ),
      if (access.providerId != null)
        _accessInfoRow(
          icon: LucideIcons.bot,
          title: isDe ? 'Modell' : 'Provider',
          subtitle: modelDisplay ?? access.providerId!,
        ),
      if (access.sharedAt != null)
        _accessInfoRow(
          icon: LucideIcons.send,
          title: isDe ? 'Übertragen' : 'Shared',
          subtitle: formatTimestamp(access.sharedAt!),
        ),
      if (manifest['sqlAnalysis'] is Map)
        for (final query
            in ((manifest['sqlAnalysis'] as Map)['queries'] as List? ??
                const []))
          if (query is Map)
            _accessInfoRow(
              icon: LucideIcons.database,
              title: isDe ? 'SQL-Abfrage' : 'SQL query',
              subtitle:
                  '${(query['tables'] as List? ?? const []).join(', ')} · '
                  '${query['rowCount'] ?? 0} ${isDe ? 'Ergebnisse' : 'result rows'}'
                  '${query['truncated'] == true ? (isDe ? ' · gekürzt' : ' · truncated') : ''}',
            ),
      for (final entry in manifest.entries)
        if (entry.key != 'sqlAnalysis')
          _accessInfoRow(
            icon: LucideIcons.database,
            title: AssistantDataCategory.localizeName(entry.key, locale),
            subtitle:
                '${(entry.value as Map)['count']} ${isDe ? 'Einträge' : 'records'}\n'
                '${((entry.value as Map)['references'] as List).join(', ')}',
          ),
    ];

    final Color barrierColor = isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.3);

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: barrierColor,
          child: DraggableScrollableSheet(
            initialChildSize: 0.86,
            minChildSize: 0.44,
            maxChildSize: 0.94,
            snap: true,
            snapSizes: const [0.44, 0.86, 0.94],
            builder: (sheetContext, scrollController) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Prevent taps inside sheet from dismissing
              child: GlassBottomMenuSheet(
                title: isDe ? 'Datenzugriff' : 'Data access',
                headerTrailing: TextButton(
                  onPressed: onClose,
                  child: Text(isDe ? 'Schließen' : 'Close'),
                ),
                contentBuilder: (_, __) => ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(top: 4, bottom: 20),
                  children: rows,
                ),
                scrollController: scrollController,
                onClose: onClose,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _accessInfoRow({
  required IconData icon,
  required String title,
  required String subtitle,
}) =>
    AppInfoRow(
      title: title,
      subtitle: subtitle,
      leading: Icon(icon, size: 23),
    );
