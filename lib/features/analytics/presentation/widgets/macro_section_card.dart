// lib/features/analytics/presentation/widgets/macro_section_card.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../theme/app_colors.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../statistics/data/macro_analytics_data_adapter.dart';
import '../macro_statistics_screen.dart';

/// Preview card embedded in Statistics Hub showing 7-day macronutrient overview.
class MacroSectionCard extends StatefulWidget {
  final MacroAnalyticsDataAdapter adapter;

  const MacroSectionCard({
    super.key,
    this.adapter = const MacroAnalyticsDataAdapter(),
  });

  @override
  State<MacroSectionCard> createState() => _MacroSectionCardState();
}

class _MacroSectionCardState extends State<MacroSectionCard> {
  List<DailyMacroIntake> _recentDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final days = await widget.adapter.fetchRecentDays(days: 7);
      if (!mounted) return;
      setState(() {
        _recentDays = days;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final macroColors = theme.extension<MacroColors>();

    final proteinColor = macroColors?.protein ?? Colors.red;
    final carbsColor = macroColors?.carbs ?? Colors.green.shade400;
    final fatColor = macroColors?.fat ?? Colors.purple.shade300;

    int maxKcal = 1;
    int sumKcal = 0;
    int trackedCount = 0;
    for (final d in _recentDays) {
      if (d.calories > maxKcal) maxKcal = d.calories;
      if (d.hasData) {
        sumKcal += d.calories;
        trackedCount++;
      }
    }
    final avgKcal = trackedCount > 0 ? (sumKcal / trackedCount).round() : 0;

    return SummaryCard(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MacroStatisticsScreen(),
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
                'Letzte 7 Tage',
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
                          max(7, _recentDays.length),
                          (index) {
                            if (index >= _recentDays.length) {
                              return Expanded(
                                child: Container(
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.08),
                                ),
                              );
                            }
                            final item = _recentDays[index];
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
                                padding: const EdgeInsets.symmetric(horizontal: 3),
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
