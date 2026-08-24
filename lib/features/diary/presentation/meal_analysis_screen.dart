// lib/features/diary/presentation/meal_analysis_screen.dart

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../generated/app_localizations.dart';
import 'widgets/ai_neural_cloud_orb_widget.dart';

/// Stages the capture screen walks through while a meal is being analysed.
///
/// Deliberately coarse: these are the moments where the wait actually changes
/// character, not a progress bar. There is no way to know how far along a
/// provider request is, and inventing a percentage would be a lie.
enum MealAnalysisPhase {
  preparing,
  analyzing,
  matching,
  failed,
}

/// Drives [MealAnalysisScreen] from the capture screen.
class MealAnalysisController extends ValueNotifier<MealAnalysisPhase> {
  MealAnalysisController() : super(MealAnalysisPhase.preparing);
}

/// Immersive blocking screen shown while a meal is being analysed.
///
/// Features an abstract, hardware-accelerated **Liquid Cloud Orb** animation
/// with 3 organic rotating clouds with position-based scale modulation.
///
/// Core invariants:
/// * It blocks: The user cannot edit inputs underneath while a request is in flight.
/// * Indeterminate motion: No fake percentages.
/// * Escape hatch: Can be cancelled anytime via [onCancel].
class MealAnalysisScreen extends StatelessWidget {
  final MealAnalysisController controller;
  final File? previewImage;
  final VoidCallback? onCancel;

  const MealAnalysisScreen({
    super.key,
    required this.controller,
    this.previewImage,
    this.onCancel,
  });

  /// Opens the screen as an opaque route with a soft fade.
  static Route<void> route({
    required MealAnalysisController controller,
    File? previewImage,
    VoidCallback? onCancel,
  }) {
    return PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => MealAnalysisScreen(
        controller: controller,
        previewImage: previewImage,
        onCancel: onCancel,
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  String _statusLabel(AppLocalizations l10n, MealAnalysisPhase phase) {
    return switch (phase) {
      MealAnalysisPhase.preparing => l10n.mealAnalysisPreparing,
      MealAnalysisPhase.analyzing => l10n.mealAnalysisAnalyzing,
      MealAnalysisPhase.matching => l10n.mealAnalysisMatching,
      MealAnalysisPhase.failed => l10n.mealAnalysisFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final orbSize = (screenWidth * 0.78).clamp(260.0, 360.0);

    return PopScope(
      // Leaving is offered explicitly below rather than by a back swipe, so a
      // half-finished request cannot be left behind by accident.
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Deep Space Atmosphere or Frosted Captured Backdrop
            if (previewImage != null) ...[
              Positioned.fill(
                child: Image.file(
                  previewImage!,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Container(
                    color: const Color(0xE607090E),
                  ),
                ),
              ),
            ] else ...[
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.95,
                      colors: [
                        Color(0xFF090C06),
                        Color(0xFF05070A),
                        Colors.black,
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ],

            // 2. Abstract Liquid Cloud Orb & Minimal Status
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Center 3-Cloud Liquid Orb
                  Center(
                    child: AiNeuralCloudOrbWidget(
                      size: orbSize,
                      showAmbientGlow: true,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Clean Status Text (No processing tag)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ValueListenableBuilder<MealAnalysisPhase>(
                      valueListenable: controller,
                      builder: (context, phase, _) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.15),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _statusLabel(l10n, phase),
                            key: ValueKey(phase),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Cancel / Abbrechen Button
                  if (onCancel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF453A),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFFFF453A),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
