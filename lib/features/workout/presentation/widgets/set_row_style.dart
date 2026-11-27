import 'package:material_ui/material_ui.dart';

import '../../../../util/design_constants.dart';

InputDecoration setFieldDecoration(
  BuildContext context, {
  required bool isEditable,
  required String hintText,
  TextStyle? hintStyle,
}) {
  final colors = Theme.of(context).colorScheme;
  const radius = BorderRadius.all(
    Radius.circular(DesignConstants.borderRadiusS),
  );

  return InputDecoration(
    isDense: true,
    filled: false,
    hintText: hintText,
    hintStyle: hintStyle,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
    border: InputBorder.none,
    disabledBorder: InputBorder.none,
    enabledBorder: isEditable
        ? OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
              color: colors.onSurface.withValues(alpha: 0.28),
            ),
          )
        : InputBorder.none,
    focusedBorder: isEditable
        ? OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: colors.primary, width: 1.5),
          )
        : InputBorder.none,
  );
}

Color setComparisonTextColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? Colors.grey.shade500
    : Colors.grey.shade600;

class SetRowTile extends StatelessWidget {
  const SetRowTile({super.key, required this.child, this.isCompleted = false});

  final Widget child;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.black.withValues(alpha: isDark ? 0.16 : 0.07)
            : (isDark
                  ? DesignConstants.summaryCardDarkMode
                  : DesignConstants.summaryCardSecondaryLightMode),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
      ),
      child: child,
    );
  }
}
