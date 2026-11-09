import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/ai_service.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../../widgets/common/app_button.dart';

enum AiMealErrorAction { retry, edit, settings, cancel }

/// Presents only actionable, localized information; raw provider errors stay out
/// of the UI and diagnostics.
Future<AiMealErrorAction> showAiMealErrorMenu({
  required BuildContext context,
  required Object error,
  required bool apple,
  bool canEdit = false,
}) async {
  final l = AppLocalizations.of(context)!;
  final (title, body) = switch (error) {
    AiEmptyMealException() => (l.aiFailureEmptyTitle, l.aiFailureEmptyBody),
    AiTimeoutException() => (
        l.aiFailureTimeoutTitle,
        apple ? l.aiFailureAppleTimeoutBody : l.aiFailureTimeoutBody
      ),
    AiAppleUnavailableException() => (
        l.aiFailureUnavailableTitle,
        l.aiFailureUnavailableBody
      ),
    AiUnsupportedFeatureException() when apple => (
        l.aiFailureUnavailableTitle,
        l.aiFailureUnsupportedImage
      ),
    AiNetworkException() => (l.aiFailureNetworkTitle, l.aiFailureNetworkBody),
    AiKeyMissingException() || AiAuthException() => (
        l.aiFailureSetupTitle,
        l.aiFailureSetupBody
      ),
    AiRateLimitException() => (l.aiFailureRateTitle, l.aiFailureRateBody),
    _ => (l.aiFailureTitle, l.aiFailureGenericBody),
  };
  final showAppleHint = apple &&
      (error is AiEmptyMealException ||
          error is AiParseException ||
          error is AiAppleGenerationException);
  final result = await showGlassBottomMenu<AiMealErrorAction>(
    context: context,
    title: title,
    contentBuilder: (sheetContext, _) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(body, textAlign: TextAlign.center),
        if (showAppleHint) ...[
          const SizedBox(height: 12),
          Text(l.aiFailureAppleHint, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 16),
        AppButton.primary(
          label: l.retry,
          tooltip: l.retry,
          onPressed: () =>
              Navigator.of(sheetContext).pop(AiMealErrorAction.retry),
        ),
        const SizedBox(height: 8),
        AppButton.secondary(
          label: l.aiFailureSettings,
          tooltip: l.aiFailureSettings,
          onPressed: () =>
              Navigator.of(sheetContext).pop(AiMealErrorAction.settings),
        ),
        if (canEdit) ...[
          const SizedBox(height: 8),
          AppButton.secondary(
            label: l.aiFailureEdit,
            tooltip: l.aiFailureEdit,
            onPressed: () =>
                Navigator.of(sheetContext).pop(AiMealErrorAction.edit),
          ),
        ],
        const SizedBox(height: 8),
        AppButton.secondary(
          label: l.cancel,
          tooltip: l.cancel,
          onPressed: () =>
              Navigator.of(sheetContext).pop(AiMealErrorAction.cancel),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
  return result ?? AiMealErrorAction.cancel;
}
