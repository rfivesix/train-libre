import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';

/// Asks whether the user wants to share anonymous usage statistics.
///
/// Shown twice at most: once right after the initial consent, and — only if
/// that first answer was no — once more after the user has lived with the app
/// for a while. See `TelemetryConsentPrompt` for when the second one is due.
///
/// Deliberately kept out of the consent screen itself. The consent there is
/// the one the user has to give to use the app at all; bundling an optional
/// choice into the same form makes it much harder to argue that the optional
/// one was freely given. Asking separately, after the obligatory part is
/// settled, keeps the two apart.
///
/// The two answers are equally weighted on purpose: same size, same row, no
/// pre-selection, and declining takes exactly one tap. Nothing about the sheet
/// may make the decline harder to reach than the accept.
///
/// Returns `true` if the user opted in, `false` if they declined, and `null`
/// if the sheet was dismissed without an answer — the caller treats the last
/// two the same, but only an explicit answer is worth remembering as such.
Future<bool?> showTelemetryConsentSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return showGlassBottomMenu<bool>(
    context: context,
    title: l10n.telemetryConsentTitle,
    contentBuilder: (ctx, close) {
      final theme = Theme.of(ctx);

      Widget point(IconData icon, String text) => Padding(
            padding: const EdgeInsets.only(bottom: DesignConstants.spacingM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 2.0,
                    right: DesignConstants.spacingM,
                  ),
                  child: Icon(icon, size: 20, color: theme.colorScheme.primary),
                ),
                Expanded(
                  child: Text(text, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          );

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.telemetryConsentBody,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: DesignConstants.spacingL),
          point(LucideIcons.eye_off, l10n.telemetryConsentPointAnonymous),
          point(LucideIcons.ban, l10n.telemetryConsentPointNotSold),
          point(LucideIcons.settings, l10n.telemetryConsentPointRevocable),
          const SizedBox(height: DesignConstants.spacingS),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  key: const Key('telemetry_consent_decline'),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  label: l10n.telemetryConsentDecline,
                  tooltip: l10n.telemetryConsentDecline,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.primary(
                  key: const Key('telemetry_consent_accept'),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  label: l10n.telemetryConsentAccept,
                  tooltip: l10n.telemetryConsentAccept,
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
