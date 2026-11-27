import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';

class AddSetButton extends StatelessWidget {
  const AddSetButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text(AppLocalizations.of(context)!.addSetButton),
        style: TextButton.styleFrom(
          foregroundColor: colors.onSurface,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? DesignConstants.summaryCardDarkMode
              : DesignConstants.summaryCardSecondaryLightMode,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(DesignConstants.borderRadiusS),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
