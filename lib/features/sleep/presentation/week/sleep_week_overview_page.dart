import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';

import '../../../../widgets/common/seamless_loading_overlay.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../domain/aggregation/sleep_period_aggregations.dart';
import '../../domain/sleep_enums.dart';
import '../../data/repository/sleep_query_repository.dart';
import '../sleep_navigation.dart';
import '../details/sleep_data_unavailable_card.dart';
import '../widgets/sleep_period_scope_layout.dart';

const _sleepOverviewSectionSpacing = DesignConstants.spacingM;

class SleepWeekOverviewPage extends StatefulWidget {
  const SleepWeekOverviewPage({
    super.key,
    required this.anchorDay,
    required this.repository,
  });

  final DateTime anchorDay;
  final SleepQueryRepository repository;

  @override
  State<SleepWeekOverviewPage> createState() => _SleepWeekOverviewPageState();
}

class _SleepWeekOverviewPageState extends State<SleepWeekOverviewPage> {
  late DateTime _anchorDay;
  late final SleepQueryRepository _repository;
  WeekSleepAggregation? _aggregation;
  bool _isLoading = true;
  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _anchorDay = DateTime(
      widget.anchorDay.year,
      widget.anchorDay.month,
      widget.anchorDay.day,
    );
    _repository = widget.repository;
    _loadWeek();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SleepPeriodScopeLayout(
      appBarTitle: l10n.sleepSectionTitle,
      selectedScope: SleepPeriodScope.week,
      anchorDate: _anchorDay,
      isRolling: _isRolling,
      onScopeChanged: _onScopeChanged,
      onShiftPeriod: _shiftPeriod,
      onAnchorChanged: (selection) {
        final date = selection.anchorDate;
        setState(() {
          _anchorDay = date;
          _isRolling = false;
        });
        _loadWeek();
      },
      child: SeamlessLoadingOverlay(
        isLoading: _isLoading,
        isEmpty: _aggregation == null,
        child: _aggregation == null
            ? const SizedBox.shrink()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WeekSummaryCard(aggregation: _aggregation!),
                  const SizedBox(height: _sleepOverviewSectionSpacing),
                  WeekWindowCard(
                    aggregation: _aggregation!,
                    onTapDay: (day) =>
                        SleepNavigation.openDayForDate(context, day),
                  ),
                  if (_aggregation!.days.every((day) => day.score == null)) ...[
                    const SizedBox(height: _sleepOverviewSectionSpacing),
                    SleepDataUnavailableCard(
                      message: l10n.sleepWeekNoScoredNights,
                      margin: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _loadWeek() async {
    setState(() => _isLoading = true);
    try {
      final weekStart = _anchorDay.subtract(
        Duration(days: _anchorDay.weekday - DateTime.monday),
      );
      final analyses = await _repository.getAnalysesInRange(
        fromInclusive: weekStart,
        toInclusive: weekStart.add(const Duration(days: 6)),
      );
      final aggregation = const SleepPeriodAggregationEngine().aggregateWeek(
        weekStart: weekStart,
        analyses: analyses,
      );
      if (!mounted) return;
      setState(() {
        _aggregation = aggregation;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('SleepWeekOverviewPage: failed to load week: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onScopeChanged(SleepPeriodScope scope) async {
    if (scope == SleepPeriodScope.day) {
      await SleepNavigation.openDayForDate(context, _anchorDay, replace: true);
      return;
    }
    if (scope == SleepPeriodScope.month) {
      await SleepNavigation.openMonthForDate(
        context,
        _anchorDay,
        replace: true,
      );
      return;
    }
  }

  void _shiftPeriod(int direction) {
    setState(() {
      _anchorDay = _anchorDay.add(Duration(days: 7 * direction));
    });
    _loadWeek();
  }
}

class WeekSummaryCard extends StatelessWidget {
  const WeekSummaryCard({super.key, required this.aggregation});

  final WeekSleepAggregation aggregation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String formatDuration(Duration? value) {
      if (value == null) return '--';
      final h = value.inHours;
      final m = value.inMinutes.remainder(60);
      return '${h}h ${m}m';
    }

    final mean = aggregation.meanScore == null
        ? '--'
        : aggregation.meanScore!.toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignConstants.cardPaddingInternal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ValueSummaryCard(
                  value: mean,
                  label: l10n.sleepMeanScoreLabel(''),
                ),
              ),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                child: ValueSummaryCard(
                  value: formatDuration(aggregation.weekdayAverageDuration),
                  label: l10n.sleepWeekdayAvgDurationLabel(''),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Row(
            children: [
              Expanded(
                child: ValueSummaryCard(
                  value: formatDuration(aggregation.weekendAverageDuration),
                  label: l10n.sleepWeekendAvgDurationLabel(''),
                ),
              ),
              const SizedBox(width: DesignConstants.spacingS),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class WeekWindowCard extends StatelessWidget {
  const WeekWindowCard({
    super.key,
    required this.aggregation,
    required this.onTapDay,
  });

  static const int _fallbackMinMinutes = 20 * 60;
  static const int _fallbackMaxMinutes = 36 * 60;

  final WeekSleepAggregation aggregation;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bounds = _resolveBounds(aggregation.sleepWindows);
    final locale = Localizations.localeOf(context).toString();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.cardPaddingInternal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sleepSleepWindowTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: DesignConstants.spacingS),
          SizedBox(
            height: 208,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [
                      Expanded(
                        child: _TimeAxisLabels(
                          tickMinutes: bounds.tickMinutes,
                          minMinutes: bounds.minMinutes,
                          maxMinutes: bounds.maxMinutes,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const SizedBox(height: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: aggregation.days.map((day) {
                                      final window = aggregation.sleepWindows
                                          .firstWhere((segment) =>
                                              segment.date == day.date);
                                      final scoreFill = _scoreFillColor(
                                        context,
                                        day.sleepQuality,
                                      );
                                      final top = window.normalizedTop(
                                        minMinutes: bounds.minMinutes,
                                        maxMinutes: bounds.maxMinutes,
                                      );
                                      final height = window.normalizedHeight(
                                        minMinutes: bounds.minMinutes,
                                        maxMinutes: bounds.maxMinutes,
                                      );
                                      return Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          child: InkWell(
                                            onTap: () => onTapDay(day.date),
                                            borderRadius: BorderRadius.circular(
                                              DesignConstants.borderRadiusS,
                                            ),
                                            child: LayoutBuilder(
                                              builder: (context, inner) {
                                                final maxHeight =
                                                    inner.maxHeight;
                                                final barTop = top * maxHeight;
                                                final barHeight =
                                                    (height * maxHeight)
                                                        .clamp(4.0, maxHeight)
                                                        .toDouble();
                                                return Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Theme.of(
                                                            context,
                                                          )
                                                              .colorScheme
                                                              .surfaceContainerHighest,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                      ),
                                                    ),
                                                    if (window.hasData)
                                                      Positioned(
                                                        top: barTop,
                                                        left: 0,
                                                        right: 0,
                                                        height: barHeight,
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: scoreFill,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              6,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(growable: false),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _TimeGridPainter(
                                        tickMinutes: bounds.tickMinutes,
                                        minMinutes: bounds.minMinutes,
                                        maxMinutes: bounds.maxMinutes,
                                        color: Theme.of(
                                          context,
                                        )
                                            .colorScheme
                                            .outlineVariant
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 48,
                        child: Row(
                          children: aggregation.days.map((day) {
                            final score = day.score;
                            final scoreFill = _scoreFillColor(
                              context,
                              day.sleepQuality,
                            );
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: InkWell(
                                  onTap: () => onTapDay(day.date),
                                  borderRadius: BorderRadius.circular(
                                    DesignConstants.borderRadiusS,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scoreFill,
                                          borderRadius: BorderRadius.circular(
                                            DesignConstants.borderRadiusS,
                                          ),
                                          border: Border.all(
                                            color: scoreFill.withValues(
                                                alpha: 0.7),
                                          ),
                                        ),
                                        child: Text(
                                          score == null
                                              ? '--'
                                              : score.round().toString(),
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: _fixedTextColor(context),
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat.E(locale).format(day.date),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: _fixedTextColor(context),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(growable: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _SleepWindowBounds _resolveBounds(List<SleepWindowSegment> windows) {
    int? earliestStart;
    int? latestEnd;

    for (final window in windows) {
      if (window.hasData) {
        if (earliestStart == null ||
            window.displayStartMinutes < earliestStart) {
          earliestStart = window.displayStartMinutes;
        }
        if (latestEnd == null || window.displayEndMinutes > latestEnd) {
          latestEnd = window.displayEndMinutes;
        }
      }
    }

    if (earliestStart == null || latestEnd == null) {
      return _SleepWindowBounds(
        minMinutes: _fallbackMinMinutes,
        maxMinutes: _fallbackMaxMinutes,
        tickMinutes: _buildTickMinutes(
          minMinutes: _fallbackMinMinutes,
          maxMinutes: _fallbackMaxMinutes,
        ),
      );
    }

    final flooredHour = (earliestStart ~/ 60) * 60;
    final minMinutes = earliestStart % 60 == 0 ? flooredHour - 60 : flooredHour;

    final ceilBase = ((latestEnd + 59) ~/ 60) * 60;
    final maxMinutes = latestEnd % 60 == 0 ? ceilBase + 60 : ceilBase;

    return _SleepWindowBounds(
      minMinutes: minMinutes,
      maxMinutes: maxMinutes,
      tickMinutes: _buildTickMinutes(
        minMinutes: minMinutes,
        maxMinutes: maxMinutes,
      ),
    );
  }

  List<int> _buildTickMinutes(
      {required int minMinutes, required int maxMinutes}) {
    final spanMinutes = math.max(60, maxMinutes - minMinutes);
    final spanHours = (spanMinutes / 60).ceil();
    final stepHours = switch (spanHours) {
      <= 8 => 1,
      <= 12 => 2,
      <= 18 => 3,
      <= 24 => 4,
      _ => 6,
    };
    final step = stepHours * 60;
    final ticks = <int>[];
    for (var minute = minMinutes; minute <= maxMinutes; minute += step) {
      ticks.add(minute);
    }
    if (ticks.isEmpty || ticks.last != maxMinutes) {
      ticks.add(maxMinutes);
    }
    return ticks;
  }

  Color _scoreFillColor(BuildContext context, SleepQualityBucket quality) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (quality) {
      SleepQualityBucket.good => const Color(0xFF81C784),
      SleepQualityBucket.average => const Color(0xFFFFD54F),
      SleepQualityBucket.poor => const Color(0xFFEF5350),
      SleepQualityBucket.unavailable =>
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
    };
  }

  Color _fixedTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}

class _SleepWindowBounds {
  const _SleepWindowBounds({
    required this.minMinutes,
    required this.maxMinutes,
    required this.tickMinutes,
  });

  final int minMinutes;
  final int maxMinutes;
  final List<int> tickMinutes;
}

class _TimeAxisLabels extends StatelessWidget {
  const _TimeAxisLabels({
    required this.tickMinutes,
    required this.minMinutes,
    required this.maxMinutes,
  });

  final List<int> tickMinutes;
  final int minMinutes;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    const labelHeight = 14.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final range = math.max(1, maxMinutes - minMinutes).toDouble();
        return Stack(
          children: [
            for (final minute in tickMinutes)
              Positioned(
                top: _positionForMinute(
                  minute.toDouble(),
                  height,
                  range,
                  labelHeight,
                ),
                right: 6,
                child: Text(
                  _formatTickLabel(minute),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _positionForMinute(
    double minute,
    double height,
    double range,
    double labelHeight,
  ) {
    final normalized = ((minute - minMinutes) / range).clamp(0.0, 1.0);
    final centered = (normalized * height) - (labelHeight / 2);
    return centered.clamp(0.0, math.max(0.0, height - labelHeight));
  }

  String _formatTickLabel(int minute) {
    var hours = (minute ~/ 60) % 24;
    if (hours < 0) hours += 24;
    return '$hours:00';
  }
}

class _TimeGridPainter extends CustomPainter {
  _TimeGridPainter({
    required this.tickMinutes,
    required this.minMinutes,
    required this.maxMinutes,
    required this.color,
  });

  final List<int> tickMinutes;
  final int minMinutes;
  final int maxMinutes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final range = math.max(1, maxMinutes - minMinutes).toDouble();
    for (final minute in tickMinutes) {
      final normalized = ((minute - minMinutes) / range).clamp(0.0, 1.0);
      final y = normalized * size.height;
      _drawDashedLine(canvas, paint, Offset(0, y), Offset(size.width, y));
    }
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    var progress = 0.0;
    while (progress < distance) {
      final current = progress / distance;
      final next = (progress + dashWidth) / distance;
      final from = Offset(start.dx + dx * current, start.dy + dy * current);
      final to = Offset(
        start.dx + dx * next.clamp(0.0, 1.0),
        start.dy + dy * next.clamp(0.0, 1.0),
      );
      canvas.drawLine(from, to, paint);
      progress += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TimeGridPainter oldDelegate) {
    return oldDelegate.tickMinutes != tickMinutes ||
        oldDelegate.minMinutes != minMinutes ||
        oldDelegate.maxMinutes != maxMinutes ||
        oldDelegate.color != color;
  }
}
