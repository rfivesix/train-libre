import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../services/telemetry/telemetry_service.dart';
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
/// Features an organic, hardware-accelerated **Living Cloud Orb** animation
/// with dynamic multi-harmonic undulations and butter-smooth ripple transitions.
/// Adapts seamlessly between Dark and Light mode.
///
/// Core invariants:
/// * It blocks: The user cannot edit inputs underneath while a request is in flight.
/// * Indeterminate motion: No fake percentages.
/// * Escape hatch: Can be cancelled anytime via [onCancel].
class MealAnalysisScreen extends StatefulWidget {
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

  @override
  State<MealAnalysisScreen> createState() => _MealAnalysisScreenState();
}

class _MealAnalysisScreenState extends State<MealAnalysisScreen> {
  final GlobalKey<AiNeuralCloudOrbWidgetState> _orbKey =
      GlobalKey<AiNeuralCloudOrbWidgetState>();

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.mealAnalysis));
    widget.controller.addListener(_onPhaseChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPhaseChanged);
    super.dispose();
  }

  void _onPhaseChanged() {
    if (!mounted) return;
    HapticFeedbackService.instance.selectionFeedback();
    _orbKey.currentState?.triggerRipple();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final orbSize = (screenWidth * 0.78).clamp(260.0, 360.0);

    final textColor = isDark ? Colors.white : const Color(0xFF09090B);
    final cancelColor =
        isDark ? const Color(0xFFFF453A) : const Color(0xFFDC2626);

    return PopScope(
      // Leaving is offered explicitly below rather than by a back swipe, so a
      // half-finished request cannot be left behind by accident.
      canPop: false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _orbKey.currentState?.incrementCharge();
        },
        child: Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Atmosphere or Frosted Captured Backdrop
              if (widget.previewImage != null) ...[
                Positioned.fill(
                  child: Image.file(
                    widget.previewImage!,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      color: isDark
                          ? const Color(0xE607090E)
                          : const Color(0xE6F8FAFC),
                    ),
                  ),
                ),
              ] else ...[
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.95,
                        colors: isDark
                            ? const [
                                Color(0xFF090C06),
                                Color(0xFF05070A),
                                Colors.black,
                              ]
                            : const [
                                Color(0xFFF7FEE7),
                                Color(0xFFF8FAFC),
                                Colors.white,
                              ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ],

              // 2. Living Cloud Orb & Minimal Status
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // Center Living Cloud Orb
                    Center(
                      child: AiNeuralCloudOrbWidget(
                        key: _orbKey,
                        size: orbSize,
                        showAmbientGlow: true,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Clean Status Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ValueListenableBuilder<MealAnalysisPhase>(
                        valueListenable: widget.controller,
                        builder: (context, phase, _) {
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.12),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              _statusLabel(l10n, phase),
                              key: ValueKey(phase),
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: textColor,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Cancel / Abbrechen Button in Red
                    if (widget.onCancel != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: TextButton(
                          onPressed: widget.onCancel,
                          style: TextButton.styleFrom(
                            foregroundColor: cancelColor,
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
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: cancelColor,
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
      ),
    );
  }
}
