import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Colorful, illustrative camera scene used in the iOS Simulator.
///
/// It is only a visual preview: it does not provide a barcode to the scanner.
class BarcodeCameraPreviewDemo extends StatelessWidget {
  const BarcodeCameraPreviewDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.12),
                  radius: 1.18,
                  colors: [
                    Color(0xFF526958),
                    Color(0xFF293A34),
                    Color(0xFF151B1A),
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
            ),
            Positioned(
              left: -width * 0.12,
              right: -width * 0.12,
              top: height * 0.27,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFB68C54).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: -width * 0.10,
              right: -width * 0.10,
              top: height * 0.72,
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFB68C54).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.38),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            _ShelfPack(
              left: width * 0.08,
              top: height * 0.19,
              width: width * 0.16,
              height: height * 0.19,
              color: const Color(0xFFE9A653),
              rotation: -0.08,
            ),
            _ShelfPack(
              right: width * 0.09,
              top: height * 0.17,
              width: width * 0.17,
              height: height * 0.22,
              color: const Color(0xFF6689B8),
              rotation: 0.06,
            ),
            _ShelfPack(
              left: width * 0.10,
              top: height * 0.66,
              width: width * 0.17,
              height: height * 0.15,
              color: const Color(0xFFDB7957),
              rotation: 0.04,
            ),
            _ShelfPack(
              right: width * 0.08,
              top: height * 0.64,
              width: width * 0.16,
              height: height * 0.18,
              color: const Color(0xFF8EAB67),
              rotation: -0.07,
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width * 0.54,
                  maxHeight: height * 0.61,
                ),
                child: AspectRatio(
                  aspectRatio: 0.62,
                  child: Transform.rotate(
                    angle: -0.035,
                    child: const _DemoOatCarton(),
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

class _ShelfPack extends StatelessWidget {
  const _ShelfPack({
    this.left,
    this.right,
    required this.top,
    required this.width,
    required this.height,
    required this.color,
    required this.rotation,
  });

  final double? left;
  final double? right;
  final double top;
  final double width;
  final double height;
  final Color color;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(2, 5),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: 7,
              height: height * 0.52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoOatCarton extends StatelessWidget {
  const _DemoOatCarton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3D5), Color(0xFFE8D8B8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF526958),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF718C59),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.leaf,
                    size: 23,
                    color: Color(0xFFFFF3D5),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'OAT',
                  style: TextStyle(
                    color: Color(0xFF34473C),
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                    height: 1,
                  ),
                ),
                const Text(
                  'BARISTA',
                  style: TextStyle(
                    color: Color(0xFF68725B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 17,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFB6C67B).withValues(alpha: 0.7),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(18),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 22,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD9CCAE)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _DemoBarcode(),
                  const SizedBox(height: 3),
                  Text(
                    '5 901234 567890',
                    style: TextStyle(
                      color: const Color(0xFF2B302C).withValues(alpha: 0.85),
                      fontSize: 7,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoBarcode extends StatelessWidget {
  const _DemoBarcode();

  static const _bars = [
    2,
    1,
    1,
    3,
    1,
    2,
    3,
    1,
    2,
    1,
    1,
    3,
    2,
    1,
    3,
    2,
    1,
    1,
    2,
    3,
    1,
    2,
    1,
    3,
    1,
    2,
    2,
    1,
    3,
    1,
    2,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _bars.length; index++) ...[
            Expanded(
              flex: _bars[index],
              child: ColoredBox(
                color:
                    index.isEven ? const Color(0xFF202722) : Colors.transparent,
              ),
            ),
            if (index != _bars.length - 1) const SizedBox(width: 1),
          ],
        ],
      ),
    );
  }
}
