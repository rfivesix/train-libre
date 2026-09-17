// lib/features/analytics/presentation/widgets/macro_section_card.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../theme/app_colors.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../statistics/data/macro_analytics_data_adapter.dart';
import '../../../statistics/domain/timeframe_block.dart';
import '../macro_statistics_screen.dart';

/// Preview card embedded in Statistics Hub showing macronutrient overview for selected timeframe.
class MacroSectionCard extends StatefulWidget {
  final MacroAnalyticsDataAdapter adapter;
  final TimeframeBlock activeBlockType;
  final DateTime? anchorDate;
  final bool isRolling;
  final String? rangeLabel;
  final VoidCallback? onTap;

  const MacroSectionCard({
    super.key,
    this.adapter = const MacroAnalyticsDataAdapter(),
    this.activeBlockType = TimeframeBlock.week,
    this.anchorDate,
    this.isRolling = true,
    this.rangeLabel,
    this.onTap,
  });

  @override
  State<MacroSectionCard> createState() => _MacroSectionCardState();
}

class _MacroSectionCardState extends State<MacroSectionCard> {
  MacroPeriodSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MacroSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeBlockType != widget.activeBlockType ||
        oldWidget.anchorDate != widget.anchorDate ||
        oldWidget.isRolling != widget.isRolling) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final bounds = widget.isRolling
          ? widget.activeBlockType.getRollingBounds()
          : widget.activeBlockType.getBounds(
              widget.anchorDate ?? DateTime.now(),
              DateTime(2020),
            );
      final summary = await widget.adapter.fetchSummary(range: bounds);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = null;
        _isLoading = false;
      });
    }
  }

  List<DailyMacroIntake> _previewBars(List<DailyMacroIntake> all) {
    if (all.length <= 31) return all;
    final int step = (all.length / 28).ceil();
    final List<DailyMacroIntake> result = [];
    for (int i = 0; i < all.length; i += step) {
      final chunk = all.sublist(i, min(i + step, all.length));
      int cals = 0;
      double p = 0;
      double c = 0;
      double f = 0;
      int tracked = 0;
      for (final day in chunk) {
        cals += day.calories;
        p += day.proteinGrams;
        c += day.carbsGrams;
        f += day.fatGrams;
        if (day.hasData) tracked++;
      }
      final divisor = tracked > 0 ? tracked : chunk.length;
      result.add(DailyMacroIntake(
        date: chunk.first.date,
        calories: (cals / divisor).round(),
        proteinGrams: p / divisor,
        carbsGrams: c / divisor,
        fatGrams: f / divisor,
      ));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final macroColors = theme.extension<MacroColors>();

    final proteinColor = macroColors?.protein ?? Colors.red;
    final carbsColor = macroColors?.carbs ?? Colors.green.shade400;
    final fatColor = macroColors?.fat ?? Colors.purple.shade300;

    final displayDays = _previewBars(_summary?.dailyIntakes ?? []);
    int maxKcal = 1;
    for (final d in displayDays) {
      if (d.calories > maxKcal) maxKcal = d.calories;
    }
    final avgKcal = _summary?.avgCalories ?? 0;

    return SummaryCard(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: widget.onTap ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MacroStatisticsScreen(
                    initialRangeIndex: widget.activeBlockType.index,
                    initialAnchorDate: widget.anchorDate,
                    initialIsRolling: widget.isRolling,
                  ),
                ),
              );
            },
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        child: Padding(
          padding: DesignConstants.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Makronährstoffe',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.rangeLabel ??
                    (widget.activeBlockType == TimeframeBlock.week
                        ? 'Letzte 7 Tage'
                        : widget.activeBlockType.name),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: DesignConstants.spacingM),

              // 7 Mini Bars
              SizedBox(
                height: 56,
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(
                          displayDays.isEmpty ? 7 : displayDays.length,
                          (index) {
                            if (index >= displayDays.length) {
                              return Expanded(
                                child: Container(
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.08),
                                ),
                              );
                            }
                            final item = displayDays[index];
                            if (item.calories <= 0) {
                              return Expanded(
                                child: Container(
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }

                            final ratio =
                                (item.calories / maxKcal).clamp(0.1, 1.0);
                            final carbsKcal = max(0.0, item.carbsGrams * 4);
                            final proteinKcal = max(0.0, item.proteinGrams * 4);
                            final fatKcal = max(0.0, item.fatGrams * 9);
                            final totalMacroKcal =
                                carbsKcal + proteinKcal + fatKcal;

                            final cFlex = totalMacroKcal > 0
                                ? max(1, (carbsKcal / totalMacroKcal * 100).round())
                                : 33;
                            final fFlex = totalMacroKcal > 0
                                ? max(1, (fatKcal / totalMacroKcal * 100).round())
                                : 33;
                            final pFlex = totalMacroKcal > 0
                                ? max(1, (proteinKcal / totalMacroKcal * 100).round())
                                : 34;

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: displayDays.length <= 7
                                      ? 3.0
                                      : (displayDays.length <= 31 ? 1.0 : 0.5),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final barHeight =
                                        constraints.maxHeight * ratio;
                                    return Align(
                                      alignment: Alignment.bottomCenter,
                                      child: SizedBox(
                                        height: barHeight,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(2),
                                          child: Column(
                                            verticalDirection:
                                                VerticalDirection.up,
                                            children: [
                                              Expanded(
                                                flex: cFlex,
                                                child:
                                                    Container(color: carbsColor),
                                              ),
                                              Expanded(
                                                flex: fFlex,
                                                child:
                                                    Container(color: fatColor),
                                              ),
                                              Expanded(
                                                flex: pFlex,
                                                child: Container(
                                                    color: proteinColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: DesignConstants.spacingM),

              // Bottom row: average kcal + chevron
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    avgKcal > 0 ? '$avgKcal kcal' : '-- kcal',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    LucideIcons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
