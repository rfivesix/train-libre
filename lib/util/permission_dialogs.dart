// lib/util/permission_dialogs.dart

import 'package:flutter/material.dart';
import 'design_constants.dart';

import '../features/app/presentation/widgets/glass_bottom_menu.dart';

/// Shows a glass-styled explanation dialog before the system permission popup.
///
/// [title] and [body] provide context for why the permission is needed.
/// Returns true if the user clicks the continue button.
Future<bool> showPrePermissionDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String continueLabel,
  required String cancelLabel,
}) async {
  final result = await showGlassBottomMenu<bool>(
    context: context,
    title: title,
    isDismissible: false,
    enableDrag: false,
    contentBuilder: (ctx, close) {
      return PopScope(
        canPop: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  close();
                  Navigator.of(ctx).pop(true);
                },
                child: Text(continueLabel),
              ),
            ),
          ],
        ),
      );
    },
  );

  return result ?? false;
}
