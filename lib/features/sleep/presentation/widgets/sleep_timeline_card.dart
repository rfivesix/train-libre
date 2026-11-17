import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_section_header.dart';
import '../../data/sleep_day_repository.dart';
import '../../domain/sleep_domain.dart';

class SleepTimelineCard extends StatefulWidget {
  const SleepTimelineCard({super.key, required this.overview});

  final SleepDayOverviewData overview;

  @override
  State<SleepTimelineCard> createState() => _SleepTimelineCardState();
}

class _SleepTimelineCardState extends State<SleepTimelineCard> {
  _ChartStageSegment? _selected;
  SleepDayOverviewData get overview => widget.overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final chartSegments = _toChartSegments(overview.timelineSegments);
    if (chartSegments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignConstants.spacingL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: l10n.sleepTimelineTitle,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.sleepTimelineUnavailable,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final chartStart = chartSegments.first.startAtUtc;
    final chartEnd = chartSegments.last.endAtUtc;
    final colors = _sleepStageColors();
    final stages = _allStageRows(l10n, colors);
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final timeFormatter = use24h ? DateFormat.Hm() : DateFormat.jm();

    Duration stageDuration(_SleepChartStage stage) => chartSegments
        .where((segment) => segment.stage == stage)
        .fold(
          Duration.zero,
          (total, segment) =>
              total + segment.endAtUtc.difference(segment.startAtUtc),
        );

    final totalStageSeconds = stages.fold<int>(
      0,
      (sum, entry) => sum + stageDuration(entry.$1).inSeconds,
    );
    int stagePercent(_SleepChartStage stage) => totalStageSeconds > 0
        ? ((stageDuration(stage).inSeconds / totalStageSeconds) * 100).round()
        : 0;

    final axisTextStyle = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        );

    const double rowHeight = 36.0;
    const double totalChartHeight = rowHeight * 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: l10n.sleepTimelineTitle,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: DesignConstants.spacingS),
          SizedBox(
            height: totalChartHeight,
            width: double.infinity,
            child: CustomPaint(
              painter: _DashedHorizontalRowsPainter(
                rowCount: 4,
                gridColor: theme.colorScheme.outlineVariant,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: DesignConstants.spacingM,
                      ),
                      child: Column(
                        children: [
                          for (final (stage, label, color) in stages)
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: color,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${stagePercent(stage)}%',
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      _formatStageDuration(
                                        stageDuration(stage),
                                      ),
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
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
                  Expanded(
                    flex: 1,
                    child: _SleepTimelinePlot(
                      onSelected: (segment) =>
                          setState(() => _selected = segment),
                      segments: chartSegments,
                      startAtUtc: chartStart,
                      endAtUtc: chartEnd,
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXS),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _selected == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(
                          right: DesignConstants.spacingM,
                        ),
                        child: Text(
                          '${stages.firstWhere((e) => e.$1 == _selected!.stage).$2} · ${timeFormatter.format(_selected!.startAtUtc.toLocal())} – ${timeFormatter.format(_selected!.endAtUtc.toLocal())}',
                          style: axisTextStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
              Expanded(
                flex: 1,
                child: SizedBox(
                  key: const Key('sleep-timeline-axis'),
                  height: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeFormatter.format(chartStart.toLocal()),
                        key: const Key('sleep-timeline-tick-0'),
                        style: axisTextStyle,
                      ),
                      Text(
                        timeFormatter.format(chartEnd.toLocal()),
                        key: const Key('sleep-timeline-tick-1'),
                        style: axisTextStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedHorizontalRowsPainter extends CustomPainter {
  const _DashedHorizontalRowsPainter({
    required this.rowCount,
    required this.gridColor,
  });

  final int rowCount;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (rowCount <= 0) return;
    final rowHeight = size.height / rowCount;
    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.45)
      ..strokeWidth = 1.0;

    for (var i = 1; i <= rowCount; i++) {
      final y = i * rowHeight;
      _drawDashedHorizontalLine(
        canvas,
        y: y,
        left: 0,
        right: size.width,
        paint: paint,
      );
    }
  }

  void _drawDashedHorizontalLine(
    Canvas canvas, {
    required double y,
    required double left,
    required double right,
    required Paint paint,
  }) {
    const dashLength = 3.0;
    const gapLength = 3.0;
    var x = left;
    while (x < right) {
      final x2 = (x + dashLength).clamp(left, right);
      canvas.drawLine(Offset(x, y), Offset(x2, y), paint);
      x += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedHorizontalRowsPainter oldDelegate) {
    return oldDelegate.rowCount != rowCount ||
        oldDelegate.gridColor != gridColor;
  }
}

class _SleepTimelinePlot extends StatelessWidget {
  const _SleepTimelinePlot({
    required this.segments,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.colors,
    required this.onSelected,
  });

  final List<_ChartStageSegment> segments;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final Map<_SleepChartStage, Color> colors;
  final ValueChanged<_ChartStageSegment?> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final ratio = (details.localPosition.dx / constraints.maxWidth)
                .clamp(0.0, 1.0);
            final time = startAtUtc.add(
              Duration(
                milliseconds:
                    (endAtUtc.difference(startAtUtc).inMilliseconds * ratio)
                        .round(),
              ),
            );
            final matches = segments.where(
              (s) => !time.isBefore(s.startAtUtc) && time.isBefore(s.endAtUtc),
            );
            onSelected(matches.isEmpty ? null : matches.first);
          },
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _SleepStagesPainter(
                segments: segments,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                colors: colors,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResolvedStageLayout {
  const _ResolvedStageLayout({
    required this.stage,
    required this.transitionLeft,
    required this.transitionRight,
    required this.yCenter,
    required this.innerRect,
    required this.haloRect,
    required this.connectedToPrev,
    required this.connectedToNext,
  });

  final _SleepChartStage stage;
  final double transitionLeft;
  final double transitionRight;
  final double yCenter;
  final Rect innerRect;
  final Rect haloRect;
  final bool connectedToPrev;
  final bool connectedToNext;
}

class _SleepStagesPainter extends CustomPainter {
  _SleepStagesPainter({
    required this.segments,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.colors,
  });

  final List<_ChartStageSegment> segments;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final Map<_SleepChartStage, Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final totalMs =
        endAtUtc.millisecondsSinceEpoch - startAtUtc.millisecondsSinceEpoch;
    if (totalMs <= 0 || segments.isEmpty || size.width <= 0) return;

    const stageCount = 4;
    final rowHeight = size.height / stageCount;
    const haloPad = 2.5;
    const verticalInset = 6.5;
    final blockHeight = math.max(6.0, rowHeight - (verticalInset * 2));

    final trackLeft = haloPad / 2;
    final trackRight = math.max(trackLeft + 1.0, size.width - (haloPad / 2));
    final trackWidth = trackRight - trackLeft;

    double rawXFor(DateTime value) {
      final elapsed =
          value.millisecondsSinceEpoch - startAtUtc.millisecondsSinceEpoch;
      return trackLeft + ((elapsed / totalMs).clamp(0.0, 1.0) * trackWidth);
    }

    int rowIndexFor(_SleepChartStage stage) {
      return switch (stage) {
        _SleepChartStage.awake => 0,
        _SleepChartStage.rem => 1,
        _SleepChartStage.light => 2,
        _SleepChartStage.deep => 3,
      };
    }

    double yCenterFor(_SleepChartStage stage) {
      return (rowIndexFor(stage) + 0.5) * rowHeight;
    }

    final layouts = _resolveSegmentLayouts(
      rawXFor: rawXFor,
      yCenterFor: yCenterFor,
      blockHeight: blockHeight,
      haloPad: haloPad,
      minX: trackLeft,
      maxX: trackRight,
    );

    // Layer 1: Unified translucent ribbon path.
    // At every transition t between segment i and segment i+1:
    // - Segment i's inner pill ends at t - haloPad/2, so its right halo border is [t - haloPad/2, t + haloPad/2].
    // - Segment i+1's inner pill starts at t + haloPad/2, so its left halo border is [t - haloPad/2, t + haloPad/2].
    // - The vertical bridge is [t - haloPad/2, t + haloPad/2] from yCenter_i to yCenter_{i+1},
    //   which is 100% collinear with both halo borders without ever intruding into innerRect!
    var ribbonPath = Path();
    for (var i = 0; i < layouts.length; i++) {
      final current = layouts[i];
      final innerR = math.min(
        5.5,
        math.min(current.innerRect.width / 2, current.innerRect.height / 2),
      );
      final outerR = Radius.circular(innerR + haloPad);

      final prevUp =
          current.connectedToPrev &&
          i > 0 &&
          layouts[i - 1].yCenter < current.yCenter;
      final prevDown =
          current.connectedToPrev &&
          i > 0 &&
          layouts[i - 1].yCenter > current.yCenter;
      final nextUp =
          current.connectedToNext &&
          i + 1 < layouts.length &&
          layouts[i + 1].yCenter < current.yCenter;
      final nextDown =
          current.connectedToNext &&
          i + 1 < layouts.length &&
          layouts[i + 1].yCenter > current.yCenter;

      final segmentHaloPath = Path()
        ..addRRect(
          RRect.fromRectAndCorners(
            current.haloRect,
            topLeft: prevUp ? Radius.zero : outerR,
            bottomLeft: prevDown ? Radius.zero : outerR,
            topRight: nextUp ? Radius.zero : outerR,
            bottomRight: nextDown ? Radius.zero : outerR,
          ),
        );
      ribbonPath = Path.combine(
        PathOperation.union,
        ribbonPath,
        segmentHaloPath,
      );

      // Add smooth concave inner fillets where a vertical bridge wall meets the horizontal top/bottom of haloRect.
      final filletR = math.min(
        3.5,
        math.min(current.innerRect.width / 2, current.innerRect.height / 2),
      );
      if (filletR > 0.5) {
        if (prevUp) {
          ribbonPath = Path.combine(
            PathOperation.union,
            ribbonPath,
            _concaveFillet(
              corner: Offset(current.innerRect.left, current.haloRect.top),
              dx: filletR,
              dy: -filletR,
              radius: filletR,
              clockwise: true,
            ),
          );
        }
        if (prevDown) {
          ribbonPath = Path.combine(
            PathOperation.union,
            ribbonPath,
            _concaveFillet(
              corner: Offset(current.innerRect.left, current.haloRect.bottom),
              dx: filletR,
              dy: filletR,
              radius: filletR,
              clockwise: false,
            ),
          );
        }
        if (nextUp) {
          ribbonPath = Path.combine(
            PathOperation.union,
            ribbonPath,
            _concaveFillet(
              corner: Offset(current.innerRect.right, current.haloRect.top),
              dx: -filletR,
              dy: -filletR,
              radius: filletR,
              clockwise: false,
            ),
          );
        }
        if (nextDown) {
          ribbonPath = Path.combine(
            PathOperation.union,
            ribbonPath,
            _concaveFillet(
              corner: Offset(current.innerRect.right, current.haloRect.bottom),
              dx: -filletR,
              dy: filletR,
              radius: filletR,
              clockwise: true,
            ),
          );
        }
      }

      if (current.connectedToNext && i + 1 < layouts.length) {
        final next = layouts[i + 1];
        final transitionX = current.transitionRight;
        final bridgeTop = math.min(current.yCenter, next.yCenter);
        final bridgeBottom = math.max(current.yCenter, next.yCenter);
        final bridgeRect = Rect.fromLTRB(
          transitionX - (haloPad / 2),
          bridgeTop,
          transitionX + (haloPad / 2),
          bridgeBottom,
        );
        final bridgePath = Path()..addRect(bridgeRect);
        ribbonPath = Path.combine(PathOperation.union, ribbonPath, bridgePath);
      }
    }

    final awakeColor =
        colors[_SleepChartStage.awake] ?? const Color(0xFFFF6B57);
    final remColor = colors[_SleepChartStage.rem] ?? const Color(0xFF32ADE6);
    final lightColor =
        colors[_SleepChartStage.light] ?? const Color(0xFF0A84FF);
    final deepColor = colors[_SleepChartStage.deep] ?? const Color(0xFF5E5CE6);

    final ribbonPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          awakeColor.withValues(alpha: 0.32),
          remColor.withValues(alpha: 0.32),
          lightColor.withValues(alpha: 0.32),
          deepColor.withValues(alpha: 0.32),
        ],
        stops: const [0.12, 0.38, 0.62, 0.88],
      ).createShader(Offset.zero & size);

    canvas.drawPath(ribbonPath, ribbonPaint);

    // Layer 2: Crisp solid inner stage pills, concentric with the outer halo curves.
    final segmentPaint = Paint()..style = PaintingStyle.fill;
    for (final item in layouts) {
      final radius = math.min(
        5.5,
        math.min(item.innerRect.width / 2, item.innerRect.height / 2),
      );
      segmentPaint.color = colors[item.stage] ?? const Color(0xFF0A84FF);
      canvas.drawRRect(
        RRect.fromRectAndRadius(item.innerRect, Radius.circular(radius)),
        segmentPaint,
      );
    }
  }

  Path _concaveFillet({
    required Offset corner,
    required double dx,
    required double dy,
    required double radius,
    required bool clockwise,
  }) {
    return Path()
      ..moveTo(corner.dx, corner.dy + dy)
      ..lineTo(corner.dx, corner.dy)
      ..lineTo(corner.dx + dx, corner.dy)
      ..arcToPoint(
        Offset(corner.dx, corner.dy + dy),
        radius: Radius.circular(radius),
        clockwise: clockwise,
      )
      ..close();
  }

  List<_ResolvedStageLayout> _resolveSegmentLayouts({
    required double Function(DateTime) rawXFor,
    required double Function(_SleepChartStage) yCenterFor,
    required double blockHeight,
    required double haloPad,
    required double minX,
    required double maxX,
  }) {
    final count = segments.length;
    final x1List = List<double>.filled(count, 0.0);
    final x2List = List<double>.filled(count, 0.0);
    final connected = List<bool>.filled(count, false);

    for (var i = 0; i < count; i++) {
      x1List[i] = rawXFor(segments[i].startAtUtc);
      x2List[i] = rawXFor(segments[i].endAtUtc);
      if (i + 1 < count &&
          segments[i + 1].startAtUtc
                  .difference(segments[i].endAtUtc)
                  .inSeconds
                  .abs() <=
              1) {
        connected[i] = true;
      }
    }

    // Each segment needs at least haloPad (for the shared border walls) + 2.4px (for the inner pill).
    const desiredMinSlot = 5.0;
    var runStart = 0;
    while (runStart < count) {
      var runEnd = runStart;
      while (runEnd < count - 1 && connected[runEnd]) {
        runEnd++;
      }
      final segCount = runEnd - runStart + 1;
      final runLeft = x1List[runStart];
      final runRight = math.max(runLeft + desiredMinSlot, x2List[runEnd]);
      final availableWidth = math.max(desiredMinSlot, maxX - minX);
      final minSegWidth = math.min(desiredMinSlot, availableWidth / segCount);

      final boundaries = List<double>.filled(segCount + 1, 0.0);
      boundaries[0] = runLeft;
      boundaries[segCount] = runRight;
      for (var j = 1; j < segCount; j++) {
        boundaries[j] = x2List[runStart + j - 1];
      }

      for (var j = 1; j <= segCount; j++) {
        if (boundaries[j] < boundaries[j - 1] + minSegWidth) {
          boundaries[j] = boundaries[j - 1] + minSegWidth;
        }
      }
      if (boundaries[segCount] > maxX) {
        boundaries[segCount] = maxX;
        for (var j = segCount - 1; j >= 0; j--) {
          if (boundaries[j] > boundaries[j + 1] - minSegWidth) {
            boundaries[j] = math.max(minX, boundaries[j + 1] - minSegWidth);
          }
        }
      }

      for (var j = 0; j < segCount; j++) {
        x1List[runStart + j] = boundaries[j];
        x2List[runStart + j] = boundaries[j + 1];
      }

      runStart = runEnd + 1;
    }

    final result = <_ResolvedStageLayout>[];
    for (var i = 0; i < count; i++) {
      final stage = segments[i].stage;
      final yCenter = yCenterFor(stage);
      final yTop = yCenter - (blockHeight / 2);
      final tLeft = x1List[i];
      final tRight = x2List[i];
      final innerLeft = tLeft + (haloPad / 2);
      final innerRight = math.max(innerLeft + 1.5, tRight - (haloPad / 2));
      final innerRect = Rect.fromLTRB(
        innerLeft,
        yTop,
        innerRight,
        yTop + blockHeight,
      );
      final haloRect = innerRect.inflate(haloPad);
      result.add(
        _ResolvedStageLayout(
          stage: stage,
          transitionLeft: tLeft,
          transitionRight: tRight,
          yCenter: yCenter,
          innerRect: innerRect,
          haloRect: haloRect,
          connectedToPrev: i > 0 && connected[i - 1],
          connectedToNext: connected[i],
        ),
      );
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _SleepStagesPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.startAtUtc != startAtUtc ||
        oldDelegate.endAtUtc != endAtUtc ||
        oldDelegate.colors != colors;
  }
}

enum _SleepChartStage { awake, rem, light, deep }

class _ChartStageSegment {
  const _ChartStageSegment({
    required this.startAtUtc,
    required this.endAtUtc,
    required this.stage,
  });

  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final _SleepChartStage stage;
}

List<_ChartStageSegment> _toChartSegments(List<SleepStageSegment> segments) {
  final sorted = [...segments]
    ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));
  final result = <_ChartStageSegment>[];
  for (final segment in sorted) {
    final chartStage = switch (segment.stage) {
      CanonicalSleepStage.awake ||
      CanonicalSleepStage.outOfBed => _SleepChartStage.awake,
      CanonicalSleepStage.rem => _SleepChartStage.rem,
      CanonicalSleepStage.light => _SleepChartStage.light,
      CanonicalSleepStage.deep => _SleepChartStage.deep,
      _ => null,
    };
    if (chartStage == null) continue;
    if (segment.endAtUtc.isBefore(segment.startAtUtc) ||
        segment.endAtUtc.isAtSameMomentAs(segment.startAtUtc)) {
      continue;
    }
    if (result.isNotEmpty &&
        result.last.stage == chartStage &&
        segment.startAtUtc.difference(result.last.endAtUtc).inSeconds.abs() <=
            1) {
      final previous = result.removeLast();
      final mergedEnd = segment.endAtUtc.isAfter(previous.endAtUtc)
          ? segment.endAtUtc
          : previous.endAtUtc;
      result.add(
        _ChartStageSegment(
          startAtUtc: previous.startAtUtc,
          endAtUtc: mergedEnd,
          stage: chartStage,
        ),
      );
      continue;
    }
    result.add(
      _ChartStageSegment(
        startAtUtc: segment.startAtUtc,
        endAtUtc: segment.endAtUtc,
        stage: chartStage,
      ),
    );
  }
  return result;
}

List<(_SleepChartStage, String, Color)> _allStageRows(
  AppLocalizations l10n,
  Map<_SleepChartStage, Color> colors,
) {
  return [
    (
      _SleepChartStage.awake,
      l10n.sleepStageAwakeLabel,
      colors[_SleepChartStage.awake]!,
    ),
    (
      _SleepChartStage.rem,
      l10n.sleepStageRemLabel,
      colors[_SleepChartStage.rem]!,
    ),
    (
      _SleepChartStage.light,
      l10n.sleepStageLightLabel,
      colors[_SleepChartStage.light]!,
    ),
    (
      _SleepChartStage.deep,
      l10n.sleepStageDeepLabel,
      colors[_SleepChartStage.deep]!,
    ),
  ];
}

Map<_SleepChartStage, Color> _sleepStageColors() {
  return const {
    _SleepChartStage.awake: Color(0xFFFF6B57),
    _SleepChartStage.rem: Color(0xFF32ADE6),
    _SleepChartStage.light: Color(0xFF0A84FF),
    _SleepChartStage.deep: Color(0xFF5E5CE6),
  };
}

String _formatStageDuration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes % 60;
  if (hours <= 0) {
    return '${minutes}m';
  }
  return '${hours}h ${minutes}m';
}
