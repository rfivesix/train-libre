// lib/features/depth_scan/presentation/widgets/depth_legend.dart

import 'package:flutter/material.dart';

import '../../data/depth_map_renderer.dart';

/// The colour-to-distance scale of a rendered depth map.
///
/// A continuous bar rather than one row per band: at twenty bands a list is a
/// wall of near-identical lines, and what the reader needs is the mapping and
/// its two ends, not twenty individual intervals.
class DepthLegend extends StatelessWidget {
  final DepthBandRender render;

  /// Extra facts under the bar. Off in the app, on in the inspector.
  final bool showDiagnostics;

  const DepthLegend({
    super.key,
    required this.render,
    this.showDiagnostics = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF12120F);
    final muted = ink.withValues(alpha: 0.6);

    // Nearest on the left, matching how the numbers read.
    final colors = [
      for (final rgb in render.palette.reversed)
        Color.fromRGBO(rgb[0], rgb[1], rgb[2], 1),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final color in colors)
                  Expanded(child: ColoredBox(color: color)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${render.minDistanceCm.toStringAsFixed(1)} cm',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: ink),
            ),
            Text(
              '${render.bandCount} Stufen · ${render.stepCm.toStringAsFixed(1)} cm',
              style: TextStyle(fontSize: 11, color: muted),
            ),
            Text(
              '${render.maxDistanceCm.toStringAsFixed(1)} cm',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: ink),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Hell = nah an der Kamera, dunkel = weiter weg. '
          'Grau = kein Messwert.',
          style: TextStyle(fontSize: 11, height: 1.3, color: muted),
        ),
        if (showDiagnostics) ...[
          const SizedBox(height: 4),
          Text(
            'Gemessen ${render.nearestCm.toStringAsFixed(1)}–'
            '${render.farthestCm.toStringAsFixed(1)} cm · '
            '${(render.outsideRangeFraction * 100).toStringAsFixed(0)} % außerhalb · '
            '${(render.invalidFraction * 100).toStringAsFixed(0)} % ohne Messwert'
            '${render.autoRanged ? ' · Bereich automatisch' : ''}',
            style: TextStyle(fontSize: 11, height: 1.3, color: muted),
          ),
        ],
      ],
    );
  }
}
