import 'package:material_ui/material_ui.dart';

import '../../../../util/design_constants.dart';
import '../../../../widgets/common/value_summary_card.dart';

class NutritionMetricGrid extends StatelessWidget {
  final List<NutritionMetric> metrics;

  const NutritionMetricGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueTextColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final labelTextColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF1C1C1E).withValues(alpha: 0.85);
    final diaryBarShadows = isDark
        ? const [
            Shadow(
              color: Color.fromRGBO(0, 0, 0, 0.35),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ]
        : null;
    final diaryBarGradient = isDark
        ? LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.black.withValues(alpha: 0.15), Colors.transparent],
            stops: const [0.0, 1.0],
          )
        : null;
    final cards = metrics.map((metric) {
      final displayValue = metric.value == null
          ? metric.missingValue ?? '-'
          : '${metric.decimals == 0 ? metric.value!.round() : metric.value!.toStringAsFixed(metric.decimals)} ${metric.unit}'
                .trim();
      return ValueSummaryCard(
        label: metric.label,
        value: displayValue,
        valueColor: valueTextColor,
        labelColor: labelTextColor,
        backgroundColor: metric.color,
        backgroundOverlayGradient: diaryBarGradient,
        textShadows: diaryBarShadows,
        showShadow: true,
      );
    }).toList();

    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[i]),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                child: i + 1 < cards.length ? cards[i + 1] : const SizedBox(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < cards.length) {
        rows.add(const SizedBox(height: DesignConstants.spacingS));
      }
    }
    return Column(children: rows);
  }
}

class NutritionMetric {
  final String label;
  final double? value;
  final String? missingValue;
  final String unit;
  final Color color;
  final int decimals;

  const NutritionMetric(
    this.label,
    this.value,
    this.missingValue,
    this.unit,
    this.color, {
    this.decimals = 1,
  });
}
