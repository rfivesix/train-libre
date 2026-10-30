import 'package:flutter/material.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../../util/design_constants.dart';
import '../../../data/assistant_history_repository.dart';
import '../../../domain/assistant_data_request.dart';

/// An inline permission request card asking the user to approve or deny data access.
class CloudOverlayPermissionCard extends StatelessWidget {
  const CloudOverlayPermissionCard({
    super.key,
    required this.theme,
    required this.contrastColor,
    required this.surfaceColor,
    required this.isVisible,
    required this.pendingAccess,
    required this.permissionPending,
    required this.permissionApproved,
    required this.useLiveAi,
    required this.onResolvePermission,
    this.onAnimatedSizeEnd,
  });

  final ThemeData theme;
  final Color contrastColor;
  final Color surfaceColor;
  final bool isVisible;
  final AssistantAccessRecord? pendingAccess;
  final bool permissionPending;
  final bool? permissionApproved;
  final bool useLiveAi;
  final ValueChanged<bool> onResolvePermission;
  final VoidCallback? onAnimatedSizeEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isDe = locale.toLowerCase().startsWith('de');
    final isDarkSurface = surfaceColor.computeLuminance() < 0.5;
    final cardTextColor = contrastColor;
    final actionColor =
        isDarkSurface ? Colors.amber.shade300 : Colors.amber.shade700;
    final glassTheme = theme.copyWith(
      brightness: isDarkSurface ? Brightness.dark : Brightness.light,
    );
    const radius = 18.0;
    final localizedCategories = pendingAccess?.categories
            .map((c) => AssistantDataCategory.localizeName(c, locale))
            .join(', ') ??
        '';
    final rawScopeLabel =
        pendingAccess?.scope['label']?.toString() ?? 'current';
    final localizedScopeLabel =
        localizeAssistantScopeLabel(rawScopeLabel, locale);
    final scopeStart = pendingAccess?.scope['start']?.toString();
    final scopeEnd = pendingAccess?.scope['end']?.toString();
    final periodLine = isDe
        ? 'Zeitraum: $localizedScopeLabel'
            '${scopeStart == null ? '' : ' — $scopeStart bis ${scopeEnd ?? scopeStart}'}'
        : 'Period: $localizedScopeLabel'
            '${scopeStart == null ? '' : ' — $scopeStart to ${scopeEnd ?? scopeStart}'}';
    final card = Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: DesignConstants.glassShadow(isDarkSurface),
        ),
        child: Theme(
          data: glassTheme,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(
                alpha: isDarkSurface ? 0.12 : 0.08,
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.amber.withValues(
                  alpha: isDarkSurface ? 0.48 : 0.34,
                ),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  useLiveAi
                      ? (isDe ? 'Datenzugriffsanfrage' : 'Data access request')
                      : l10n.aiOverlayDemoRequestLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cardTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPermissionScope(
                  useLiveAi
                      ? '${isDe ? 'Kategorien' : 'Categories'}: $localizedCategories'
                      : l10n.aiOverlayDemoScope,
                  theme,
                  cardTextColor,
                ),
                const SizedBox(height: 4),
                _buildPermissionScope(
                  useLiveAi ? periodLine : l10n.aiOverlayDemoScopeDetails,
                  theme,
                  cardTextColor,
                ),
                const SizedBox(height: 10),
                Text(
                  useLiveAi
                      ? (isDe
                          ? 'Diese Anfrage kann Daten der genannten Kategorien und des Zeitraums verwenden. Der Anbieter kann durch einen Wechsel oder Ausweichanbieter vom zuvor angezeigten Anbieter abweichen.'
                          : 'This request may use data from these categories and period. A provider change or fallback can result in a different recipient.')
                      : l10n.aiOverlayDemoPurpose,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cardTextColor.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 10),
                if (permissionPending)
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton(
                        onPressed: () => onResolvePermission(false),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              cardTextColor.withValues(alpha: 0.72),
                        ),
                        child: Text(l10n.aiOverlayDemoDeny),
                      ),
                      FilledButton(
                        onPressed: () => onResolvePermission(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: actionColor,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(l10n.aiOverlayDemoAllowOnce),
                      ),
                    ],
                  )
                else
                  Text(
                    useLiveAi
                        ? (permissionApproved == true
                            ? (isDe
                                ? 'Datenzugriff einmalig freigegeben.'
                                : 'Data access approved once.')
                            : (isDe
                                ? 'Datenzugriff abgelehnt.'
                                : 'Data access declined.'))
                        : (permissionApproved == true
                            ? l10n.aiOverlayDemoApprovedFeedback
                            : l10n.aiOverlayDemoDeniedFeedback),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cardTextColor.withValues(alpha: 0.72),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      onEnd: onAnimatedSizeEnd,
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: isVisible ? 1 : 0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          opacity: isVisible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: ExcludeSemantics(
              excluding: !isVisible,
              child: card,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildPermissionScope(
    String text,
    ThemeData theme,
    Color contrastColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 9, right: 9),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: contrastColor.withValues(alpha: 0.76),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: contrastColor),
            ),
          ),
        ],
      ),
    );
  }
}
