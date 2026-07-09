import re

with open("lib/widgets/common/platform_adaptive_pickers.dart", "r") as f:
    content = f.read()

# Add showAdaptiveDurationPicker
new_function = """
Future<Duration?> showAdaptiveDurationPicker({
  required BuildContext context,
  required Duration initialDuration,
  String? title,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);

  final Color barrierColor = isDark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.3);

  Duration selectedDuration = initialDuration;

  final selected = await showModalBottomSheet<Duration>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor,
    builder: (ctx) {
      final kb = MediaQuery.of(ctx).viewInsets.bottom;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: kb),
        child: _GlassPickerSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: DesignConstants.spacingL),
                  child: Center(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: DesignConstants.spacingL),
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hms,
                    initialTimerDuration: initialDuration,
                    onTimerDurationChanged: (Duration newDuration) {
                      selectedDuration = newDuration;
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: DesignConstants.spacingL,
                  right: DesignConstants.spacingL,
                  top: DesignConstants.spacingXS,
                  bottom: DesignConstants.spacingM,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingM),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.primary,
                          foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
                        ),
                        onPressed: () => Navigator.pop(ctx, selectedDuration),
                        child: Text(l10n?.snackbarButtonOK ?? 'OK'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  return selected;
}
"""

if "showAdaptiveDurationPicker" not in content:
    content = content + new_function
    with open("lib/widgets/common/platform_adaptive_pickers.dart", "w") as f:
        f.write(content)
