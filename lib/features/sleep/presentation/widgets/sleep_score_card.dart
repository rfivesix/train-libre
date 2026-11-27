import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../data/sleep_day_repository.dart';
import '../../domain/sleep_enums.dart';

class SleepContributorColors {
  static const Color duration = Color(0xFF0A84FF);
  static const Color continuity = Color(0xFF00D4A6);
  static const Color deep = Color(0xFF5E5CE6);
  static const Color rem = Color(0xFF32ADE6);
  static const Color regularity = Color(0xFFFF6B57);
}

class SleepScoreRingSegment {
  const SleepScoreRingSegment({
    required this.weight,
    required this.fillRatio,
    required this.color,
  });

  final double weight;
  final double fillRatio;
  final Color color;
}

class SleepScoreCard extends StatelessWidget {
  const SleepScoreCard({super.key, required this.overview});
  final SleepDayOverviewData overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final score = overview.analysis.score;
    final scoring = overview.scoringResult;
    final minutes = overview.totalSleepMinutes;
    final dateFormat = MediaQuery.of(context).alwaysUse24HourFormat
        ? DateFormat.Hm()
        : DateFormat.jm();
    String duration(Duration? d) =>
        d == null ? '–' : '${d.inHours}h ${d.inMinutes % 60}m';

    final quality = score == null
        ? l10n.sleepQualityUnavailable
        : switch (overview.analysis.sleepQuality) {
            SleepQualityBucket.good => l10n.sleepQualityGood,
            SleepQualityBucket.average => l10n.sleepQualityAverage,
            SleepQualityBucket.poor => l10n.sleepQualityPoor,
            SleepQualityBucket.unavailable => l10n.sleepQualityUnavailable,
          };

    final fallbackScore = score;
    final segments = <SleepScoreRingSegment>[
      SleepScoreRingSegment(
        weight: 0.45,
        fillRatio:
            ((scoring != null ? scoring.durationScore : fallbackScore) ?? 0.0) /
            100.0,
        color: SleepContributorColors.duration,
      ),
      SleepScoreRingSegment(
        weight: 0.25,
        fillRatio:
            ((scoring != null ? scoring.continuityScore : fallbackScore) ??
                0.0) /
            100.0,
        color: SleepContributorColors.continuity,
      ),
      SleepScoreRingSegment(
        weight: 0.10,
        fillRatio:
            ((scoring != null ? scoring.deepScore : fallbackScore) ?? 0.0) /
            100.0,
        color: SleepContributorColors.deep,
      ),
      SleepScoreRingSegment(
        weight: 0.10,
        fillRatio:
            ((scoring != null ? scoring.remScore : fallbackScore) ?? 0.0) /
            100.0,
        color: SleepContributorColors.rem,
      ),
      SleepScoreRingSegment(
        weight: 0.10,
        fillRatio:
            ((scoring != null ? scoring.regularityScore : fallbackScore) ??
                0.0) /
            100.0,
        color: SleepContributorColors.regularity,
      ),
    ];

    final timeSpanText =
        '${dateFormat.format(overview.session.startAtUtc.toLocal())} – ${dateFormat.format(overview.session.endAtUtc.toLocal())}';
    final durationText = minutes == null
        ? l10n.sleepMetricUnavailable
        : duration(Duration(minutes: minutes));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CustomPaint(
                      painter: SleepScoreRingPainter(
                        segments: segments,
                        maxStrokeWidth: 38.0,
                        cornerRadius: 10.0,
                        gapPixels: 6.0,
                      ),
                    ),
                  ),
                  Text(
                    score == null ? '–' : '${score.round()}',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 68,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                quality,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingS),
              Text(
                '· $durationText',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                timeSpanText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SleepScoreRingPainter extends CustomPainter {
  const SleepScoreRingPainter({
    required this.segments,
    required this.maxStrokeWidth,
    this.cornerRadius = 9.0,
    this.gapPixels = 6.0,
  });

  final List<SleepScoreRingSegment> segments;
  final double maxStrokeWidth;
  final double cornerRadius;
  final double gapPixels;

  @override
  void paint(Canvas canvas, Size size) {
    final outerRadius = math.min(size.width, size.height) / 2;
    final innerRadius = outerRadius - maxStrokeWidth;
    if (innerRadius <= 0 || maxStrokeWidth <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    // Start near right-bottom (~15 degrees) so the 45% blue segment sits along
    // the bottom/right and the 25% mint segment sits on the left, matching Apple Health.
    var cursorAngle = 0.25;

    final trackPaint = Paint()..style = PaintingStyle.fill;
    final fillPaint = Paint()..style = PaintingStyle.fill;

    for (final segment in segments) {
      final slotAngle = segment.weight * 2 * math.pi;
      final theta0 = cursorAngle;
      final theta1 = cursorAngle + slotAngle;

      final trackPath = _buildRoundedAnnularSectorPath(
        center: center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        theta0: theta0,
        theta1: theta1,
        halfGap: gapPixels / 2,
        cornerRadius: cornerRadius,
      );

      trackPaint.color = segment.color.withValues(alpha: 0.25);
      canvas.drawPath(trackPath, trackPaint);

      final clampedFill = segment.fillRatio.clamp(0.0, 1.0);
      if (clampedFill > 0) {
        final fillThickness = math.max(3.0, maxStrokeWidth * clampedFill);
        final fillOuterRadius = innerRadius + fillThickness;
        final fillPath = _buildRoundedAnnularSectorPath(
          center: center,
          innerRadius: innerRadius,
          outerRadius: fillOuterRadius,
          theta0: theta0,
          theta1: theta1,
          halfGap: gapPixels / 2,
          cornerRadius: math.min(cornerRadius, fillThickness / 2),
        );

        fillPaint.color = segment.color;
        canvas.save();
        canvas.clipPath(trackPath);
        canvas.drawPath(fillPath, fillPaint);
        canvas.restore();
      }

      cursorAngle = theta1;
    }
  }

  Path _buildRoundedAnnularSectorPath({
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required double theta0,
    required double theta1,
    required double halfGap,
    required double cornerRadius,
  }) {
    final thickness = outerRadius - innerRadius;
    if (thickness <= 0 || theta1 <= theta0) return Path();

    final maxRadialCorner = thickness / 2;
    final midRadius = (innerRadius + outerRadius) / 2;
    final maxAngularCorner = math.max(
      0.5,
      ((theta1 - theta0) * midRadius / 2) - halfGap - 0.5,
    );
    final rc = math.min(
      cornerRadius,
      math.min(maxRadialCorner, maxAngularCorner),
    );

    if (rc <= 0.5) {
      final inOffset = math.asin((halfGap / innerRadius).clamp(0.0, 0.999));
      final outOffset = math.asin((halfGap / outerRadius).clamp(0.0, 0.999));
      final aInStart = theta0 + inOffset;
      final aInEnd = theta1 - inOffset;
      final aOutStart = theta0 + outOffset;
      final aOutEnd = theta1 - outOffset;
      if (aInEnd <= aInStart || aOutEnd <= aOutStart) return Path();

      return Path()
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerRadius),
          aOutStart,
          aOutEnd - aOutStart,
          true,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          aInEnd,
          -(aInEnd - aInStart),
          false,
        )
        ..close();
    }

    final rInCenter = innerRadius + rc;
    final rOutCenter = outerRadius - rc;
    final wallOffset = halfGap + rc;

    final inAngleDelta = math.asin((wallOffset / rInCenter).clamp(0.0, 0.999));
    final outAngleDelta = math.asin(
      (wallOffset / rOutCenter).clamp(0.0, 0.999),
    );

    final aInStart = theta0 + inAngleDelta;
    final aInEnd = theta1 - inAngleDelta;
    final aOutStart = theta0 + outAngleDelta;
    final aOutEnd = theta1 - outAngleDelta;

    if (aInEnd <= aInStart || aOutEnd <= aOutStart) {
      return _buildRoundedAnnularSectorPath(
        center: center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        theta0: theta0,
        theta1: theta1,
        halfGap: halfGap,
        cornerRadius: 0.0,
      );
    }

    Offset polar(double r, double angle) =>
        Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));

    final vOutStart = polar(rOutCenter, aOutStart);
    final vOutEnd = polar(rOutCenter, aOutEnd);
    final vInEnd = polar(rInCenter, aInEnd);
    final vInStart = polar(rInCenter, aInStart);

    final path = Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        aOutStart,
        aOutEnd - aOutStart,
        true,
      )
      ..arcTo(
        Rect.fromCircle(center: vOutEnd, radius: rc),
        aOutEnd,
        (theta1 + (math.pi / 2)) - aOutEnd,
        false,
      )
      ..arcTo(
        Rect.fromCircle(center: vInEnd, radius: rc),
        theta1 + (math.pi / 2),
        (aInEnd + math.pi) - (theta1 + (math.pi / 2)),
        false,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        aInEnd,
        -(aInEnd - aInStart),
        false,
      )
      ..arcTo(
        Rect.fromCircle(center: vInStart, radius: rc),
        aInStart + math.pi,
        (theta0 + (1.5 * math.pi)) - (aInStart + math.pi),
        false,
      )
      ..arcTo(
        Rect.fromCircle(center: vOutStart, radius: rc),
        theta0 - (math.pi / 2),
        aOutStart - (theta0 - (math.pi / 2)),
        false,
      )
      ..close();

    return path;
  }

  @override
  bool shouldRepaint(covariant SleepScoreRingPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.maxStrokeWidth != maxStrokeWidth ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.gapPixels != gapPixels;
  }
}
