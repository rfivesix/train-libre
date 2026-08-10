import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';

import '../../exercise_catalog/domain/body_slug_mapper.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../data/home_widget_channel.dart';

/// Renders the muscle heatmap of the last workout into the App Group, where the
/// Last Workout widget draws it.
///
/// ## Why a rendered image rather than muscle slugs in the snapshot
///
/// The silhouettes are SVG path data owned by `flutter_body_highlighter`, and
/// the workload shading is the app's. Reimplementing either as SwiftUI paths
/// would create a second body model that drifts away from the app's on the first
/// anatomy fix, for a picture the user sees side by side with the in-app one.
/// Rendering the real widget keeps one source of truth.
///
/// ## Why it renders without a BuildContext
///
/// The obvious place to rasterise a widget is an `Overlay`, which needs a live
/// screen. That made the heatmap depend on the user visiting the workout
/// summary — so every workout logged before this feature existed, and every
/// workout whose summary was dismissed quickly, had no heatmap at all. The
/// widget then fell back to its icon forever.
///
/// So the render happens on a private pipeline instead: a `RenderRepaintBoundary`
/// under a `RenderView` of its own, built and laid out by hand. Nothing about
/// the body highlighter needs a screen — the paths are Dart constants and the
/// parse results are cached, with no asset or network I/O anywhere — which is
/// what makes this safe rather than clever.
class WorkoutHeatmapPublisher {
  final HomeWidgetChannel _channel;

  const WorkoutHeatmapPublisher({
    HomeWidgetChannel channel = const HomeWidgetChannel(),
  }) : _channel = channel;

  /// Logical size of the render. Two silhouettes side by side are roughly
  /// square, and so is the medium widget's right-hand pane.
  static const Size canvasSize = Size(240, 240);

  /// Rasterised at 3x for the densest screens, and because the large widget
  /// shows the same file at roughly twice the size.
  static const double pixelRatio = 3;

  /// A base tone that reads on both the light and the dark widget surface.
  ///
  /// The in-app silhouette takes its base from the current theme, which is the
  /// wrong source here: the widget follows the *system* appearance, and the app
  /// may well be pinned to the other one. A mid grey at partial opacity is
  /// legible either way.
  static final Color baseColor = const Color(0xFF8E8E93).withValues(alpha: 0.32);
  static final Color outlineColor =
      const Color(0xFF8E8E93).withValues(alpha: 0.55);

  /// The five workload tiers, coldest to hottest.
  ///
  /// `MuscleColorHelper` shades by the theme's primary at rising alpha, which
  /// needs a `BuildContext` and would render a lime-on-transparent map that
  /// disappears against a light widget. The tiers here are the design
  /// document's own heat ramp — yellow through orange to the brand red — which
  /// reads as load at a glance and holds up on both surfaces.
  static const List<Color> intensityColors = [
    Color(0xFFFFE082),
    Color(0xFFFFC107),
    Color(0xFFFF9800),
    Color(0xFFF4511E),
    Color(0xFFE5253A),
  ];

  /// Renders the heatmap for [workoutId] and publishes it.
  ///
  /// Returns false when there was nothing to draw or the write failed. Never
  /// throws: a missing heatmap costs the widget one pane and must not be able
  /// to disturb whatever triggered the sync.
  Future<bool> publish({
    required int workoutId,
    required Iterable<Exercise> exercises,
    required BodyGender gender,
  }) async {
    final bytes = await renderPng(exercises: exercises, gender: gender);
    if (bytes == null) return false;

    return _channel.writeSharedFile(
      HomeWidgetChannel.workoutHeatmapFileName(workoutId),
      bytes,
    );
  }

  /// The PNG for [exercises], or null when there is nothing to draw.
  ///
  /// Separate from [publish] so the render — the part that runs its own build
  /// and layout pipeline — can be exercised without an App Group to write into.
  @visibleForTesting
  Future<Uint8List?> renderPng({
    required Iterable<Exercise> exercises,
    required BodyGender gender,
  }) async {
    try {
      final highlights = _highlights(exercises);
      if (highlights.isEmpty) return null;

      return await _render(
        _HeatmapCanvas(
          gender: gender,
          frontHighlights: BodySlugMapper.forSide(highlights, BodySide.front),
          backHighlights: BodySlugMapper.forSide(highlights, BodySide.back),
        ),
      );
    } catch (e, st) {
      debugPrint('WorkoutHeatmapPublisher.renderPng failed: $e\n$st');
      return null;
    }
  }

  /// The same workload count `WorkoutSummaryScreen._buildMuscleHeatmap` uses:
  /// one point per exercise that trains a muscle, cardio excluded.
  List<BodyPartHighlightData> _highlights(Iterable<Exercise> exercises) {
    final counts = <BodyPartSlug, double>{};
    for (final exercise in exercises) {
      if (exercise.isCardio) continue;
      final slugs = <BodyPartSlug>{};
      for (final name in exercise.primaryMuscles) {
        slugs.addAll(BodySlugMapper.fromRawName(name));
      }
      for (final slug in slugs) {
        counts[slug] = (counts[slug] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return const [];

    // Same five-tier bucketing as `MuscleColorHelper`, against this renderer's
    // own ramp.
    final peak = counts.values.reduce((a, b) => a > b ? a : b);
    return counts.entries.map((entry) {
      final tier = peak > 0
          ? (entry.value / peak * intensityColors.length).ceil().clamp(
                1,
                intensityColors.length,
              )
          : 1;
      return BodyPartHighlightData(
        slug: entry.key,
        color: intensityColors[tier - 1],
      );
    }).toList();
  }

  /// Rasterises [child] on a render tree of its own.
  ///
  /// The background is left transparent so the PNG sits on whatever surface the
  /// widget draws it on, in either appearance.
  Future<Uint8List?> _render(Widget child) async {
    final boundary = RenderRepaintBoundary();
    final view = WidgetsBinding.instance.platformDispatcher.views.first;

    final renderView = RenderView(
      view: view,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(canvasSize),
        physicalConstraints: BoxConstraints.tight(canvasSize) * pixelRatio,
        devicePixelRatio: pixelRatio,
      ),
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: boundary,
      ),
    );

    final pipelineOwner = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();

    final buildOwner = BuildOwner(focusManager: FocusManager());
    final element = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: MediaQuery(
        // An explicit MediaQuery: there is no `View` above this tree to inherit
        // one from, and the body highlighter's layout would otherwise assert.
        data: MediaQueryData(size: canvasSize, devicePixelRatio: pixelRatio),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.fromSize(size: canvasSize, child: child),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    try {
      buildOwner.buildScope(element);
      buildOwner.finalizeTree();
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } finally {
      // Rebuilding the adapter with no child unmounts the subtree through the
      // normal lifecycle, so the private pipeline cannot outlive this call
      // holding a dirty element.
      RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
          .attachToRenderTree(buildOwner, element);
      buildOwner.buildScope(element);
      buildOwner.finalizeTree();
      pipelineOwner.rootNode = null;
      renderView.dispose();
    }
  }
}

/// Front and back silhouettes, sized to fill the render canvas.
///
/// Not `DualBodyHighlighter`: that one takes its colours from the ambient theme,
/// and this render has to be legible under both appearances — see
/// [WorkoutHeatmapPublisher.baseColor].
class _HeatmapCanvas extends StatelessWidget {
  final BodyGender gender;
  final List<BodyPartHighlightData> frontHighlights;
  final List<BodyPartHighlightData> backHighlights;

  const _HeatmapCanvas({
    required this.gender,
    required this.frontHighlights,
    required this.backHighlights,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _side(BodySide.front, frontHighlights)),
        Expanded(child: _side(BodySide.back, backHighlights)),
      ],
    );
  }

  Widget _side(BodySide side, List<BodyPartHighlightData> highlights) {
    return BodyHighlighter(
      gender: gender,
      side: side,
      highlightedParts: highlights,
      baseColor: WorkoutHeatmapPublisher.baseColor,
      outlineColor: WorkoutHeatmapPublisher.outlineColor,
      outlineWidth: 0.8,
    );
  }
}
