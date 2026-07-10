import 'package:flutter/material.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';

/// A standardized dual-silhouette body highlighter (front and back).
///
/// Displays the front and back body models side-by-side with equal sizing
/// and no labels or dividers to adhere to the "Anti-Slop" design system.
class DualBodyHighlighter extends StatelessWidget {
  final BodyGender gender;
  final List<BodyPartHighlightData> frontHighlights;
  final List<BodyPartHighlightData> backHighlights;
  final double height;
  final double outlineWidth;
  final void Function(BodyPartSlug, BodyPartHighlightData)? onBodyPartTap;

  const DualBodyHighlighter({
    super.key,
    required this.gender,
    required this.frontHighlights,
    required this.backHighlights,
    this.height = 200.0,
    this.outlineWidth = 0.8,
    this.onBodyPartTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: BodyHighlighter(
              gender: gender,
              side: BodySide.front,
              highlightedParts: frontHighlights,
              outlineWidth: outlineWidth,
              onBodyPartTap: onBodyPartTap,
            ),
          ),
          Expanded(
            child: BodyHighlighter(
              gender: gender,
              side: BodySide.back,
              highlightedParts: backHighlights,
              outlineWidth: outlineWidth,
              onBodyPartTap: onBodyPartTap,
            ),
          ),
        ],
      ),
    );
  }
}
