import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/glass_fab.dart';

class EditRoutineFab extends StatefulWidget {
  final void Function({
    BuildContext? sourceContext,
    WidgetBuilder? sourceBuilder,
    void Function(bool hidden)? onSourceVisibilityChanged,
  })
  onPressed;

  const EditRoutineFab({super.key, required this.onPressed});

  @override
  State<EditRoutineFab> createState() => _EditRoutineFabState();
}

class _EditRoutineFabState extends State<EditRoutineFab>
    with WidgetsBindingObserver {
  double _keyboardHeight = 0;
  bool _isFabHidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateKeyboardHeight();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _updateKeyboardHeight();
  }

  void _updateKeyboardHeight() {
    if (!mounted) return;
    final view = View.of(context);
    final newHeight = view.viewInsets.bottom / view.devicePixelRatio;
    if (newHeight != _keyboardHeight) {
      setState(() {
        _keyboardHeight = newHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_keyboardHeight > 0) {
      return const SizedBox.shrink();
    }
    Widget buildFabContent({VoidCallback? onPressed}) => GlassFab(
      label: AppLocalizations.of(context)!.fabAddExercise,
      onPressed: onPressed ?? () {},
    );

    return Opacity(
      opacity: _isFabHidden ? 0.0 : 1.0,
      child: IgnorePointer(
        ignoring: _isFabHidden,
        child: Builder(
          builder: (fabCtx) => buildFabContent(
            onPressed: () => widget.onPressed(
              sourceContext: fabCtx,
              sourceBuilder: (_) => buildFabContent(),
              onSourceVisibilityChanged: (hidden) {
                if (mounted) setState(() => _isFabHidden = hidden);
              },
            ),
          ),
        ),
      ),
    );
  }
}
