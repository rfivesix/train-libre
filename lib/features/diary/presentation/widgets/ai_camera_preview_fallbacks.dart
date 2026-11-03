import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../generated/app_localizations.dart';

/// Fallback view shown when camera permission has not been granted.
class AiCameraFallbackView extends StatelessWidget {
  const AiCameraFallbackView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: const Color(0xFF121212),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.camera_off, size: 48, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'Kamerazugriff erforderlich',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Bitte erlaube den Kamerazugriff in den Einstellungen, um Mahlzeiten direkt live zu erfassen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: openAppSettings,
              child: Text(
                l10n.aiCaptureOpenSettings,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simulated camera preview demo showing an artistic plate layout when
/// running on iOS Simulator.
class AiSimulatorCameraDemo extends StatelessWidget {
  const AiSimulatorCameraDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.12),
              radius: 1.15,
              colors: [Color(0xFF78543B), Color(0xFF38291F), Color(0xFF171411)],
              stops: [0, 0.58, 1],
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280, maxHeight: 280),
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth;
                  Widget foodPiece({
                    required double left,
                    required double top,
                    required double width,
                    required double height,
                    required Color color,
                    double angle = 0,
                    double radius = 0.12,
                  }) {
                    return Positioned(
                      left: size * left,
                      top: size * top,
                      child: Transform.rotate(
                        angle: angle,
                        child: Container(
                          width: size * width,
                          height: size * height,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(size * radius),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 8,
                                offset: const Offset(1, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE4D7C0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.38),
                              blurRadius: 28,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(size * 0.07),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Color(0xFFFFFCF3), Color(0xFFF1E9D8)],
                            ),
                          ),
                        ),
                      ),
                      foodPiece(
                        left: 0.20,
                        top: 0.28,
                        width: 0.34,
                        height: 0.19,
                        color: const Color(0xFFB86A35),
                        angle: -0.38,
                      ),
                      foodPiece(
                        left: 0.47,
                        top: 0.22,
                        width: 0.30,
                        height: 0.16,
                        color: const Color(0xFF8E4C2D),
                        angle: 0.25,
                      ),
                      foodPiece(
                        left: 0.48,
                        top: 0.49,
                        width: 0.32,
                        height: 0.17,
                        color: const Color(0xFFCF8644),
                        angle: -0.2,
                      ),
                      foodPiece(
                        left: 0.22,
                        top: 0.57,
                        width: 0.29,
                        height: 0.16,
                        color: const Color(0xFF9A512C),
                        angle: 0.3,
                      ),
                      foodPiece(
                        left: 0.35,
                        top: 0.40,
                        width: 0.29,
                        height: 0.16,
                        color: const Color(0xFF678249),
                        angle: 0.15,
                      ),
                      foodPiece(
                        left: 0.25,
                        top: 0.43,
                        width: 0.16,
                        height: 0.11,
                        color: const Color(0xFFE8AE58),
                        angle: -0.6,
                      ),
                      foodPiece(
                        left: 0.61,
                        top: 0.39,
                        width: 0.15,
                        height: 0.11,
                        color: const Color(0xFF719352),
                        angle: 0.45,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
