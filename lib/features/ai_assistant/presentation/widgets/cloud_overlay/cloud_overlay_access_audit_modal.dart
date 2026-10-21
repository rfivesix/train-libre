import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

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

    final actions = <GlassMenuAction>[
      GlassMenuAction(
        icon: access.status == 'approved' || access.status == 'shared'
            ? LucideIcons.shield_check
            : (access.status == 'denied'
                ? LucideIcons.shield_x
                : LucideIcons.shield_alert),
        label: isDe ? 'Status: $statusText' : 'Status: $statusText',
        subtitle: isDe ? 'Datenfreigabestatus' : 'Data access status',
        onTap: () {},
      ),
      GlassMenuAction(
        icon: LucideIcons.clock,
        label: isDe ? 'Angefragt' : 'Requested',
        subtitle: access.requestedAt.toLocal().toString().split('.').first,
        onTap: () {},
      ),
      if (access.decidedAt != null)
        GlassMenuAction(
          icon: LucideIcons.circle_check,
          label: isDe ? 'Entschieden' : 'Decided',
          subtitle: access.decidedAt!.toLocal().toString().split('.').first,
          onTap: () {},
        ),
      GlassMenuAction(
        icon: LucideIcons.layout_grid,
        label: isDe ? 'Kategorien' : 'Categories',
        subtitle: categoriesText,
        onTap: () {},
      ),
      GlassMenuAction(
        icon: LucideIcons.calendar,
        label: isDe ? 'Zeitraum' : 'Scope',
        subtitle: scopeText,
        onTap: () {},
      ),
      if (access.providerId != null)
        GlassMenuAction(
          icon: LucideIcons.bot,
          label: isDe ? 'Modell' : 'Provider',
          subtitle: modelDisplay ?? access.providerId!,
          onTap: () {},
        ),
      if (access.sharedAt != null)
        GlassMenuAction(
          icon: LucideIcons.send,
          label: isDe ? 'Übertragen' : 'Shared',
          subtitle: access.sharedAt!.toLocal().toString().split('.').first,
          onTap: () {},
        ),
      if (manifest['sqlAnalysis'] is Map)
        for (final query
            in ((manifest['sqlAnalysis'] as Map)['queries'] as List? ??
                const []))
          if (query is Map)
            GlassMenuAction(
              icon: LucideIcons.database,
              label: isDe ? 'SQL-Abfrage' : 'SQL query',
              subtitle:
                  '${(query['tables'] as List? ?? const []).join(', ')} · '
                  '${query['rowCount'] ?? 0} ${isDe ? 'Ergebnisse' : 'result rows'}'
                  '${query['truncated'] == true ? (isDe ? ' · gekürzt' : ' · truncated') : ''}',
              onTap: () {},
            ),
      for (final entry in manifest.entries)
        if (entry.key != 'sqlAnalysis')
          GlassMenuAction(
            icon: LucideIcons.database,
            label: AssistantDataCategory.localizeName(entry.key, locale),
            subtitle:
                '${(entry.value as Map)['count']} ${isDe ? 'Einträge' : 'records'}\n'
                '${((entry.value as Map)['references'] as List).join(', ')}',
            onTap: () {},
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
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // Prevent taps inside sheet from dismissing
              child: GlassBottomMenuSheet(
                title: isDe ? 'Datenzugriff' : 'Data access',
                headerTrailing: TextButton(
                  onPressed: onClose,
                  child: Text(isDe ? 'Schließen' : 'Close'),
                ),
                actions: actions,
                onClose: onClose,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
