import 'package:material_ui/material_ui.dart';

import 'camera_glass_surface.dart';

/// Photo shutter shared by the chat camera and meal scanner.
class CameraShutterButton extends StatelessWidget {
  const CameraShutterButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.overPlatformView = false,
  });

  static const double dimension = 76;

  final String label;
  final VoidCallback? onPressed;
  final bool overPlatformView;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: CameraGlassSurface(
          dimension: dimension,
          isDarkSurface: true,
          overPlatformView: overPlatformView,
          child: const Center(
            child: SizedBox.square(
              dimension: 58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
