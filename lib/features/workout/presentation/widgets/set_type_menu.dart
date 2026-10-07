import '../../../../widgets/common/platform_adaptive_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';

/// Displays the explanation-rich bottom sheet for workout set types,
/// matching the comprehensive guide from the live workout screen.
void showExplanationRichSetTypeSheet({
  required BuildContext context,
  required ValueChanged<String> onSelected,
}) {
  final l10n = AppLocalizations.of(context)!;

  Widget buildSymbol(String char, Color color) {
    return Text(
      char,
      style: TextStyle(
        color: color,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  final options = [
    {
      'type': 'normal',
      'label': l10n.set_type_normal,
      'subtitle': l10n.set_type_normal_help,
      'symbol': buildSymbol('N', Colors.grey),
    },
    {
      'type': 'warmup',
      'label': l10n.set_type_warmup,
      'subtitle': l10n.set_type_warmup_help,
      'symbol': buildSymbol('W', Colors.orange),
    },
    {
      'type': 'failure',
      'label': l10n.set_type_failure,
      'subtitle': l10n.set_type_failure_help,
      'symbol': buildSymbol('F', DesignConstants.brandRedColor),
    },
    {
      'type': 'dropset',
      'label': l10n.set_type_dropset,
      'subtitle': l10n.set_type_dropset_help,
      'symbol': buildSymbol('D', Colors.blue),
    },
  ];

  showGlassBottomMenu(
    context: context,
    title: l10n.changeSetTypTitle,
    actions: options.map((opt) {
      return GlassMenuAction(
        customIcon: opt['symbol'] as Widget,
        label: opt['label'] as String,
        subtitle: opt['subtitle'] as String,
        onTap: () => onSelected(opt['type'] as String),
      );
    }).toList(),
  );
}

/// A dropdown menu for quick workout set-type selection.
///
/// Uses [PlatformAdaptivePopupMenu] from the shared widgets library.
/// Tapping the trigger opens an inline dropdown popup menu with:
/// - Normal, Warmup, Failure, Dropset
/// - An "Info & Explanations" option that opens the explanation-rich bottom menu.
class SetTypeMenu extends StatelessWidget {
  /// The current set type ('normal', 'warmup', 'failure', 'dropset').
  final String currentSetType;

  /// Callback when a new set type is chosen (either from dropdown or explanation sheet).
  final ValueChanged<String> onSetTypeChanged;

  /// The child widget that acts as the trigger (e.g. Text with set number, SetTypeChip).
  final Widget child;

  /// Whether the menu is enabled. If false, tapping does nothing.
  final bool enabled;

  const SetTypeMenu({
    super.key,
    required this.currentSetType,
    required this.onSetTypeChanged,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget buildSymbol(String char, Color color) {
      return Container(
        width: 24,
        alignment: Alignment.center,
        child: Text(
          char,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return PlatformAdaptivePopupMenu<String>(
      icon: child,
      enabled: enabled,
      selectedValue: currentSetType,
      menuWidth: 260.0,
      onSelected: (value) {
        if (value == 'info') {
          showExplanationRichSetTypeSheet(
            context: context,
            onSelected: onSetTypeChanged,
          );
        } else {
          onSetTypeChanged(value);
        }
      },
      items: [
        PlatformAdaptivePopupMenuItem(
          value: 'normal',
          label: l10n.set_type_normal,
          customIcon: buildSymbol('N', Colors.grey),
        ),
        PlatformAdaptivePopupMenuItem(
          value: 'warmup',
          label: l10n.set_type_warmup,
          customIcon: buildSymbol('W', Colors.orange),
        ),
        PlatformAdaptivePopupMenuItem(
          value: 'failure',
          label: l10n.set_type_failure,
          customIcon: buildSymbol('F', DesignConstants.brandRedColor),
        ),
        PlatformAdaptivePopupMenuItem(
          value: 'dropset',
          label: l10n.set_type_dropset,
          customIcon: buildSymbol('D', Colors.blue),
        ),
        PlatformAdaptivePopupMenuItem(
          value: 'info',
          label: l10n.set_type_info,
          icon: LucideIcons.info,
          showDividerAbove: true,
        ),
      ],
    );
  }
}
