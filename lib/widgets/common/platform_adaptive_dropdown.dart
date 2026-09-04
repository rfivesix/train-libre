import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../util/design_constants.dart';

/// Configuration item for [PlatformAdaptivePopupMenu].
class PlatformAdaptivePopupMenuItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final bool isDestructive;

  PlatformAdaptivePopupMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.isDestructive = false,
  });
}

/// A platform-adaptive Popup/Context Menu button.
///
/// On Android, displays a themed Material 3 [PopupMenuButton].
/// On iOS, displays a [GlassMenu] that morphs smoothly from its trigger button.
class PlatformAdaptivePopupMenu<T> extends StatelessWidget {
  final Widget icon;
  final List<PlatformAdaptivePopupMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final T? selectedValue;
  final double menuWidth;

  const PlatformAdaptivePopupMenu({
    super.key,
    required this.icon,
    required this.items,
    required this.onSelected,
    this.selectedValue,
    this.menuWidth = 260.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuSettings = LiquidGlassSettings(
      thickness: 30,
      blur: 8.0,
      glassColor: isDark
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.88)
          : Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
      lightIntensity: isDark ? 0.55 : 0.80,
      saturation: 1.20,
    );

    return AdaptiveLiquidGlassLayer(
      settings: menuSettings,
      quality: DesignConstants.defaultGlassQuality,
      child: GlassMenu(
        menuWidth: menuWidth,
        settings: menuSettings,
        triggerBuilder: (context, toggle) => GestureDetector(
          onTap: toggle,
          behavior: HitTestBehavior.opaque,
          child: icon,
        ),
        items: items.map((item) {
          final isSelected =
              selectedValue != null && item.value == selectedValue;
          return GlassMenuItem(
            title: item.label,
            icon: item.icon != null ? Icon(item.icon, size: 20) : null,
            isSelected: isSelected,
            trailing: isSelected
                ? Icon(
                    LucideIcons.check,
                    size: 18,
                    color: isDark ? Colors.white : Colors.black87,
                  )
                : null,
            isDestructive: item.isDestructive,
            onTap: () {
              onSelected(item.value);
            },
          );
        }).toList(),
      ),
    );
  }
}

/// A platform-adaptive Dropdown Form Field.
///
/// On Android, displays a themed Material 3 [DropdownButtonFormField].
/// On iOS, displays a custom [GlassMenu] selector designed to look like a
/// glass text/input field with chevron selectors.
class PlatformAdaptiveDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;
  final FormFieldValidator<T>? validator;
  final FormFieldSetter<T>? onSaved;
  final AutovalidateMode? autovalidateMode;
  final String? errorText;

  const PlatformAdaptiveDropdownFormField({
    super.key,
    this.value,
    this.initialValue,
    required this.items,
    this.onChanged,
    this.decoration,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.errorText,
  });

  T? get _effectiveValue => value ?? initialValue;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: _effectiveValue,
      validator: validator,
      onSaved: onSaved,
      autovalidateMode: autovalidateMode,
      builder: (FormFieldState<T> state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final menuSettings = LiquidGlassSettings(
          thickness: 30,
          blur: 8.0,
          glassColor: isDark
              ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.88)
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
          lightIntensity: isDark ? 0.55 : 0.80,
          saturation: 1.20,
        );

        // Find the currently selected item or fall back to the first item
        DropdownMenuItem<T>? selectedItem;
        for (final item in items) {
          if (item.value == state.value) {
            selectedItem = item;
            break;
          }
        }
        if (selectedItem == null && items.isNotEmpty) {
          selectedItem = items.first;
        }

        final selectedText =
            selectedItem != null ? _getItemText(selectedItem.child) : '';
        // Keep the collapsed trigger visually identical to a regular text field:
        // take the fill straight from the input theme (white in Light, 0xFF2C2C2E
        // in Dark) and stay borderless like the themed fields do.
        final containerFillColor =
            Theme.of(context).inputDecorationTheme.fillColor ??
                (isDark ? const Color(0xFF2C2C2E) : Colors.white);

        const borderColor = Colors.transparent;

        final defaultDecoration = InputDecoration(
          filled: true,
          fillColor: containerFillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacingM,
            vertical: DesignConstants.spacingS + 2,
          ),
        );

        final mergedDecoration = defaultDecoration.copyWith(
          labelText: decoration?.labelText,
          hintText: decoration?.hintText,
          helperText: decoration?.helperText,
          prefixIcon: decoration?.prefixIcon,
          suffixIcon: decoration?.suffixIcon,
          errorText: state.errorText ?? decoration?.errorText ?? errorText,
          fillColor: decoration?.fillColor ?? containerFillColor,
          filled: decoration?.filled ?? true,
          contentPadding: decoration?.contentPadding,
          border: decoration?.border != null &&
                  decoration?.border != const OutlineInputBorder()
              ? decoration?.border
              : defaultDecoration.border,
          enabledBorder: decoration?.enabledBorder != null &&
                  decoration?.enabledBorder != const OutlineInputBorder()
              ? decoration?.enabledBorder
              : defaultDecoration.enabledBorder,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final menuWidth =
                constraints.maxWidth > 0 ? constraints.maxWidth : 280.0;
            return AdaptiveLiquidGlassLayer(
              settings: menuSettings,
              quality: DesignConstants.defaultGlassQuality,
              child: GlassMenu(
                menuWidth: menuWidth,
                autoAdjustToScreen: true,
                settings: menuSettings,
                triggerBuilder: (context, toggle) {
                  return GestureDetector(
                    onTap: onChanged == null ? null : toggle,
                    behavior: HitTestBehavior.opaque,
                    child: InputDecorator(
                      decoration: mergedDecoration,
                      isEmpty: selectedText.isEmpty,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              selectedText,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                items: items.map((item) {
                  final isSelected = item.value == state.value;
                  return GlassMenuItem(
                    title: _getItemText(item.child),
                    isSelected: isSelected,
                    trailing: isSelected
                        ? Icon(
                            LucideIcons.check,
                            size: 18,
                            color: isDark ? Colors.white : Colors.black87,
                          )
                        : null,
                    onTap: () {
                      state.didChange(item.value);
                      onChanged?.call(item.value);
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  String _getItemText(Widget child) {
    if (child is Text) {
      return child.data ?? '';
    }
    return child.toString();
  }
}

/// A collapsed field that opens a menu and allows more than one answer.
///
/// [PlatformAdaptiveDropdownFormField] beside it is single-select: picking a
/// value replaces the previous one. The catalog filter needs the same collapsed
/// look — a field with a chevron that expands into a glass menu — while letting
/// several options stand at once, because "chest or back" is a legitimate
/// filter and forcing one of them would be a worse answer than a long list.
///
/// Selected items carry a checkmark, and the collapsed field names them, so
/// the current filter is readable without opening anything.
///
/// One known cost: `GlassMenu` calls its own close after every item tap and
/// offers no way to opt out, so each additional option costs a reopen. That is
/// the price of using the app's existing menu rather than a second one built
/// beside it; a filter is usually one or two picks per axis.
class PlatformAdaptiveMultiSelectField<T> extends StatelessWidget {
  /// Shown above the field, and inside it while nothing is selected.
  final String label;

  final List<PlatformAdaptivePopupMenuItem<T>> items;

  /// The currently selected values.
  final List<T> selected;

  /// Called with the value whose selection was flipped.
  final ValueChanged<T> onToggled;

  const PlatformAdaptiveMultiSelectField({
    super.key,
    required this.label,
    required this.items,
    required this.selected,
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final menuSettings = LiquidGlassSettings(
      thickness: 30,
      blur: 8.0,
      glassColor: isDark
          ? theme.colorScheme.surface.withValues(alpha: 0.88)
          : theme.colorScheme.surface.withValues(alpha: 0.94),
      lightIntensity: isDark ? 0.55 : 0.80,
      saturation: 1.20,
    );

    // What the collapsed field says. The selected labels rather than a count:
    // "Chest, Back" answers "what am I filtering by" without opening anything,
    // and ellipsises when there are too many to fit.
    final selectedLabels = items
        .where((item) => selected.contains(item.value))
        .map((item) => item.label)
        .toList(growable: false);
    final summary = selectedLabels.join(', ');

    final fillColor = theme.inputDecorationTheme.fillColor ??
        (isDark ? const Color(0xFF2C2C2E) : Colors.white);
    const borderColor = Colors.transparent;

    OutlineInputBorder border([Color color = borderColor, double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
          borderSide: BorderSide(color: color, width: width),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth =
            constraints.maxWidth > 0 ? constraints.maxWidth : 280.0;
        return AdaptiveLiquidGlassLayer(
          settings: menuSettings,
          quality: DesignConstants.defaultGlassQuality,
          child: GlassMenu(
            menuWidth: menuWidth,
            autoAdjustToScreen: true,
            settings: menuSettings,
            triggerBuilder: (context, toggle) => GestureDetector(
              onTap: toggle,
              behavior: HitTestBehavior.opaque,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  filled: true,
                  fillColor: fillColor,
                  border: border(),
                  enabledBorder: border(),
                  focusedBorder: border(theme.colorScheme.primary, 2),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.spacingM,
                    vertical: DesignConstants.spacingS + 2,
                  ),
                ),
                isEmpty: summary.isEmpty,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        summary,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
            items: items.map((item) {
              final isSelected = selected.contains(item.value);
              return GlassMenuItem(
                title: item.label,
                isSelected: isSelected,
                trailing: isSelected
                    ? Icon(
                        LucideIcons.check,
                        size: 18,
                        color: isDark ? Colors.white : Colors.black87,
                      )
                    : null,
                // The menu closes itself afterwards — see the class comment.
                onTap: () => onToggled(item.value),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
