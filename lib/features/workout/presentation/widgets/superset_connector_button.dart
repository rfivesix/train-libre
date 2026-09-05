import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';

/// Connects or disconnects this exercise and the one below it as a superset.
///
/// Sits at the trailing end of the "add set" row so the action shares that
/// line instead of floating between two cards.
class SupersetConnectorButton extends StatelessWidget {
  /// Whether this exercise is already in the same superset as the next one.
  final bool isConnected;

  final VoidCallback onPressed;

  const SupersetConnectorButton({
    super.key,
    required this.isConnected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label =
        isConnected ? l10n.disconnectSupersetShort : l10n.connectSupersetShort;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              semanticsLabel:
                  isConnected ? l10n.disconnectSuperset : l10n.connectSuperset,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            isConnected ? LucideIcons.unlink : LucideIcons.link,
            size: 18,
          ),
        ],
      ),
    );
  }
}
