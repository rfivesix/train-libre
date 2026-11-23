import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/value_summary_card.dart';

class StepsPeriodSummary extends StatelessWidget {
  const StepsPeriodSummary({
    super.key,
    required this.total,
    required this.firstMetric,
    required this.secondMetric,
    this.dailyGoal,
  });

  final int total;
  final ValueSummaryCard firstMetric;
  final ValueSummaryCard secondMetric;
  final int? dailyGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final totalColor = theme.brightness == Brightness.dark
        ? colors.primary
        : Color.alphaBlend(
            colors.onSurface.withValues(alpha: 0.25),
            colors.primary,
          );
    final locale = Localizations.localeOf(context).toString();
    final goal = dailyGoal;
    final numberFormat = NumberFormat.decimalPattern(locale);
    final secondaryStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.stepsModuleTotalSteps,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  numberFormat.format(total),
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: totalColor,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (goal != null) ...[
          const SizedBox(height: DesignConstants.spacingS),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: DesignConstants.spacingS,
            runSpacing: DesignConstants.spacingXS,
            children: [
              Text(
                '${l10n.stepsModuleGoalProgress} · ${NumberFormat.percentPattern(locale).format(total / goal)}',
                style: secondaryStyle,
              ),
              Text(
                '${l10n.goalTargetLabel} · ${numberFormat.format(goal)}',
                style: secondaryStyle,
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          ExcludeSemantics(
            child: LinearProgressIndicator(
              value: (total / goal).clamp(0.0, 1.0),
              minHeight: 4,
              borderRadius: BorderRadius.circular(
                DesignConstants.borderRadiusS,
              ),
              backgroundColor: theme.cardColor,
            ),
          ),
        ],
        const SizedBox(height: DesignConstants.spacingL),
        LayoutBuilder(
          builder: (context, constraints) {
            final labelWidth =
                (constraints.maxWidth - DesignConstants.spacingS) / 2 -
                2 * DesignConstants.spacingM;
            final labelStyle = theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            );
            final labelsFit = [firstMetric.label, secondMetric.label].every((
              label,
            ) {
              final painter = TextPainter(
                text: TextSpan(text: label, style: labelStyle),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                locale: Localizations.localeOf(context),
                maxLines: 1,
              )..layout();
              final fits = painter.width <= labelWidth;
              painter.dispose();
              return fits;
            });
            return labelsFit
                ? IntrinsicHeight(
                    child: Row(
                      spacing: DesignConstants.spacingS,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: firstMetric),
                        Expanded(child: secondMetric),
                      ],
                    ),
                  )
                : Column(
                    spacing: DesignConstants.spacingS,
                    children: [firstMetric, secondMetric],
                  );
          },
        ),
      ],
    );
  }
}
