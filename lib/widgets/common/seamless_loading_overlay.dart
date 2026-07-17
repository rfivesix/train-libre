import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../util/design_constants.dart';

/// A wrapper widget that provides a seamless loading experience.
/// If [isLoading] and [isEmpty] are both true, displays the [child] wrapped
/// in a [Skeletonizer] for a premium shimmer effect (or [fallback] if provided).
/// If [isLoading] is true but [isEmpty] is false, shows a subtle spinner overlay.
class SeamlessLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final bool isEmpty;
  final Widget child;
  final bool extendBodyBehindAppBar;
  final Widget? fallback;

  const SeamlessLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.child,
    this.extendBodyBehindAppBar = false,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && isEmpty) {
      if (fallback != null) return fallback!;
      return Skeletonizer(
        enabled: true,
        child: IgnorePointer(child: child),
      );
    }

    if (isLoading) {
      final topPadding = extendBodyBehindAppBar
          ? MediaQuery.of(context).padding.top + kToolbarHeight
          : 0.0;

      return Stack(
        children: [
          child,
          Positioned(
            top: topPadding + DesignConstants.spacingM,
            right: DesignConstants.spacingM,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      );
    }

    return child;
  }
}
