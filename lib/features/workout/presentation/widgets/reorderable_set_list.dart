import 'package:material_ui/material_ui.dart';

import '../../../../util/design_constants.dart';
import '../reorder_scroll_anchor.dart';
import 'reorder_drag_proxy.dart';

/// Renders an exercise's set rows and enables vertical drag-and-drop reordering
/// within that exercise when [enabled] is true and [onReorderSet] is provided.
class ReorderableSetList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool enabled;
  final void Function(int oldIndex, int newIndex)? onReorderSet;

  const ReorderableSetList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.enabled,
    this.onReorderSet,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || onReorderSet == null || itemCount <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < itemCount; i++) itemBuilder(context, i)],
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      onReorderStart: ReorderHapticFeedback.onDragStart,
      onReorderEnd: (_) => ReorderHapticFeedback.onDragEnd(),
      proxyDecorator: (child, index, animation) => buildReorderDragProxy(
        context,
        child,
        animation,
        borderRadius: DesignConstants.borderRadiusM,
      ),
      onReorderItem: onReorderSet!,
      itemBuilder: (context, index) {
        final row = itemBuilder(context, index);
        final rowKey = row.key;
        return ReorderableDelayedDragStartListener(
          key: rowKey != null
              ? ValueKey<Key>(rowKey)
              : ValueKey<String>('reorder_set_$index'),
          index: index,
          child: row,
        );
      },
    );
  }
}
