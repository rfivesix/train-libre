import 'package:flutter/material.dart';

import '../../../diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';

/// Briefly turns a newly generated value into the app's existing AI cloud,
/// then lets the generated accent fade back to the ordinary input colour.
///
/// The input itself remains mounted throughout, so its controller, focus and
/// keyboard state are never lost when a fresh suggestion arrives.
class GeneratedValueMorph extends StatefulWidget {
  final String? suggestionKey;
  final Color accentColor;
  final Color restingColor;
  final Widget Function(Color textColor) childBuilder;

  const GeneratedValueMorph({
    super.key,
    required this.suggestionKey,
    required this.accentColor,
    required this.restingColor,
    required this.childBuilder,
  });

  @override
  State<GeneratedValueMorph> createState() => _GeneratedValueMorphState();
}

class _GeneratedValueMorphState extends State<GeneratedValueMorph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isGenerated => widget.suggestionKey != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    if (_isGenerated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward(from: 0);
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(GeneratedValueMorph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isGenerated && oldWidget.suggestionKey != widget.suggestionKey) {
      _controller.forward(from: 0);
    } else if (!_isGenerated) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGenerated) return widget.childBuilder(widget.restingColor);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        final cloudVisible = value >= 0.14 && value <= 0.56;
        final double inputOpacity = cloudVisible
            ? 0.18
            : (value < 0.14 ? 1 - (value / 0.14) * 0.82 : 1);
        final fadeToRest = value <= 0.58 ? 0.0 : ((value - 0.58) / 0.42);
        final textColor = Color.lerp(
          widget.accentColor,
          widget.restingColor,
          Curves.easeOutCubic.transform(fadeToRest.clamp(0.0, 1.0)),
        )!;

        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: inputOpacity,
              child: widget.childBuilder(textColor),
            ),
            if (cloudVisible)
              IgnorePointer(
                child: Semantics(
                  excludeSemantics: true,
                  child: Transform.scale(
                    scale: 0.72 +
                        Curves.easeOutBack.transform(
                              ((value - 0.14) / 0.42).clamp(0.0, 1.0),
                            ) *
                            0.28,
                    child: AiNeuralCloudOrbWidget(
                      size: 28,
                      showAmbientGlow: false,
                      baseColor: Colors.white,
                      accentColor: widget.accentColor,
                      // The stage-two tint from the AI scan's charge scale.
                      tint: 0.4,
                      energy: 0.35,
                      flowSpeed: 2.2,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
