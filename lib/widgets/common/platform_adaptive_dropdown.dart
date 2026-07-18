import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

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

  const PlatformAdaptivePopupMenu({
    super.key,
    required this.icon,
    required this.items,
    required this.onSelected,
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
      quality: GlassQuality.premium,
      child: GlassMenu(
        menuWidth: 200,
        settings: menuSettings,
        triggerBuilder: (context, toggle) => GestureDetector(
          onTap: toggle,
          behavior: HitTestBehavior.opaque,
          child: icon,
        ),
        items: items.map((item) {
          return GlassMenuItem(
            title: item.label,
            icon: item.icon != null ? Icon(item.icon, size: 20) : null,
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
        final effectiveDecoration =
            (decoration ?? const InputDecoration()).copyWith(
          errorText: state.errorText ?? errorText,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final menuWidth =
                constraints.maxWidth > 0 ? constraints.maxWidth : 280.0;
            return AdaptiveLiquidGlassLayer(
              settings: menuSettings,
              quality: GlassQuality.premium,
              child: GlassMenu(
                menuWidth: menuWidth,
                autoAdjustToScreen: true,
                settings: menuSettings,
                triggerBuilder: (context, toggle) {
                  return GestureDetector(
                    onTap: onChanged == null ? null : toggle,
                    behavior: HitTestBehavior.opaque,
                    child: InputDecorator(
                      decoration: effectiveDecoration,
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
