import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that provides a "springy" scale animation and haptic feedback
/// when tapped or when its selection state changes.
class SpringyScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final double scaleDown;
  final Duration duration;

  const SpringyScale({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<SpringyScale> createState() => _SpringyScaleState();
}

class _SpringyScaleState extends State<SpringyScale> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the target scale based on pressed and selected states.
    double targetScale = 1.0;
    if (_isPressed) {
      targetScale = widget.scaleDown;
    } else if (widget.isSelected) {
      targetScale = 1.05; // Subtle pop for selection
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap != null
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: targetScale,
        duration: widget.duration,
        curve: Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}
