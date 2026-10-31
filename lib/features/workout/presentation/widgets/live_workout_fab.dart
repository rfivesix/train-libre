import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/glass_fab.dart';
import '../live_workout_view_model.dart';

class LiveWorkoutFab extends StatefulWidget {
  final void Function({
    BuildContext? sourceContext,
    WidgetBuilder? sourceBuilder,
    void Function(bool hidden)? onSourceVisibilityChanged,
  })
  onPressed;

  const LiveWorkoutFab({super.key, required this.onPressed});

  @override
  State<LiveWorkoutFab> createState() => _LiveWorkoutFabState();
}

class _LiveWorkoutFabState extends State<LiveWorkoutFab> {
  bool _isFabHidden = false;

  @override
  Widget build(BuildContext context) {
    final showRestBar = context.select<LiveWorkoutViewModel, bool>(
      (vm) => vm.remainingRestSeconds > 0 || vm.showRestDone,
    );

    Widget buildFabContent({VoidCallback? onPressed}) {
      final fab = GlassFab(
        label: AppLocalizations.of(context)!.fabAddExercise,
        onPressed: onPressed ?? () {},
      );

      if (showRestBar) {
        return ClipPath(
          clipper: const LiveWorkoutFabShadowClipper(),
          child: fab,
        );
      }
      return fab;
    }

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

/// Removes its child while the software keyboard is up.
///
/// The bottom of the live workout screen carries two floating elements — the
/// add-exercise button and the rest bar — and both sit exactly where the
/// keyboard appears. Shared so the two cannot drift apart.
class HiddenWhileKeyboardVisible extends StatefulWidget {
  final Widget child;

  const HiddenWhileKeyboardVisible({super.key, required this.child});

  @override
  State<HiddenWhileKeyboardVisible> createState() =>
      _HiddenWhileKeyboardVisibleState();
}

class _HiddenWhileKeyboardVisibleState extends State<HiddenWhileKeyboardVisible>
    with WidgetsBindingObserver {
  double _keyboardHeight = 0;

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
  Widget build(BuildContext context) =>
      _keyboardHeight > 0 ? const SizedBox.shrink() : widget.child;
}

/// A clipper that crops the FAB drop shadow at the bottom (exactly 8.0 logical
/// pixels below the FAB edge) so it terminates where the rest bar begins.
class LiveWorkoutFabShadowClipper extends CustomClipper<Path> {
  const LiveWorkoutFabShadowClipper();

  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.addRect(
      Rect.fromLTRB(
        -50.0,
        -50.0,
        size.width + 50.0,
        size.height + 8.0, // cut off exactly at the top of the rest bar (8.0px below FAB bottom)
      ),
    );
    return path;
  }

  @override
  bool shouldReclip(covariant LiveWorkoutFabShadowClipper oldClipper) => false;
}
