import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../data/whats_new_service.dart';
import '../domain/whats_new_release.dart';

/// Shows the "What's New" bottom sheet for [releases] (newest first).
///
/// Does nothing when [releases] is empty. [markSeen] should stay `true` for the
/// automatic post-update presentation and `false` when the user opened the
/// history themselves from the About screen.
Future<void> showWhatsNewSheet(
  BuildContext context,
  List<WhatsNewRelease> releases, {
  bool markSeen = true,
}) async {
  if (releases.isEmpty) return;

  final l10n = AppLocalizations.of(context);
  if (l10n == null) return;

  unawaited(
    TelemetryService.instance.trackScreenView(screenName: ScreenName.whatsNew),
  );
  if (markSeen) {
    unawaited(
      TelemetryService.instance
          .trackFeatureUsed(featureKey: FeatureKey.whatsNewViewed),
    );
  }

  await showGlassBottomMenu<void>(
    context: context,
    title: l10n.whatsNewTitle,
    contentBuilder: (ctx, close) => _WhatsNewContent(
      releases: releases,
      onClose: close,
      showSingleVersionHeader: releases.length == 1,
    ),
  );

  if (markSeen) {
    await WhatsNewService.instance.markSeen();
  }
}

class _WhatsNewContent extends StatelessWidget {
  const _WhatsNewContent({
    required this.releases,
    required this.onClose,
    required this.showSingleVersionHeader,
  });

  final List<WhatsNewRelease> releases;
  final VoidCallback onClose;

  /// A single release gets a compact subtitle instead of a section header, so
  /// the common case after an update does not read like a changelog archive.
  final bool showSingleVersionHeader;

  String _headerFor(BuildContext context, WhatsNewRelease release) {
    final l10n = AppLocalizations.of(context)!;
    final label = l10n.whatsNewVersionHeader(release.version);
    final date = release.releaseDate;
    if (date == null) return label;
    final formatted =
        DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(date);
    return '$label · $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignConstants.spacingS,
          0,
          DesignConstants.spacingS,
          DesignConstants.spacingM,
        ),
        child: Text(
          showSingleVersionHeader
              ? _headerFor(context, releases.first)
              : l10n.whatsNewSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    ];

    for (final release in releases) {
      if (!showSingleVersionHeader) {
        children.add(
          AppSectionHeader(
            title: _headerFor(context, release),
            isFirst: release == releases.first,
          ),
        );
      }
      for (final entry in release.entries) {
        children.add(_WhatsNewEntryTile(entry: entry));
      }
    }

    children.add(const SizedBox(height: DesignConstants.spacingL));
    children.add(
      AppButton.primary(
        label: l10n.whatsNewCta,
        semanticsLabel: l10n.whatsNewCta,
        onPressed: onClose,
      ),
    );
    children.add(const SizedBox(height: DesignConstants.spacingS));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// One highlight row: icon, headline, description.
///
/// Deliberately not a glass card — the surrounding sheet already pushes a
/// backdrop filter, and one per row would cost a full framebuffer round trip
/// each on a tile-based GPU.
class _WhatsNewEntryTile extends StatelessWidget {
  const _WhatsNewEntryTile({required this.entry});

  final WhatsNewEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
        vertical: DesignConstants.spacingM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
            ),
            child: Icon(
              entry.icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: DesignConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (entry.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
