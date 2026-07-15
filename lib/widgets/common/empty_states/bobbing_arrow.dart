import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class BobbingArrow extends StatefulWidget {
  final Color? color;
  final double size;
  final IconData icon;

  const BobbingArrow({
    super.key, 
    this.color, 
    this.size = 32,
    this.icon = LucideIcons.arrow_down,
  });

  @override
  State<BobbingArrow> createState() => _BobbingArrowState();
}

class _BobbingArrowState extends State<BobbingArrow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
