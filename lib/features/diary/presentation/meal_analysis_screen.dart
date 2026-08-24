// lib/features/diary/presentation/meal_analysis_screen.dart

import 'dart:io';
import '../../../generated/app_localizations.dart';
import 'dart:ui';

import 'package:flutter/material.dart';

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

/// PLACEHOLDER — blocking screen shown while a meal is analysed.
///
/// This is scaffolding, not the finished thing: it holds the position, the
/// route behaviour and the phase wiring so the real design can drop straight
/// in. What it already gets right and the replacement must keep:
///
/// * It blocks. The user cannot edit the input underneath while a request is
///   in flight, which was possible before.
/// * It shows no fake progress. Indeterminate motion only.
/// * It can be left. A request that hangs must not trap the user.
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
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => MealAnalysisScreen(
        controller: controller,
        previewImage: previewImage,
        onCancel: onCancel,
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  String _label(AppLocalizations l10n, MealAnalysisPhase phase) {
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
    return PopScope(
      // Leaving is offered explicitly below rather than by a back swipe, so a
      // half-finished request cannot be left behind by accident.
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (previewImage != null) ...[
              Image.file(previewImage!, fit: BoxFit.cover),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(color: Colors.black.withValues(alpha: 0.55)),
              ),
            ],
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFFC9EF00),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<MealAnalysisPhase>(
                    valueListenable: controller,
                    builder: (context, phase, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          _label(l10n, phase),
                          key: ValueKey(phase),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  if (onCancel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: TextButton(
                        onPressed: onCancel,
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.7),
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
