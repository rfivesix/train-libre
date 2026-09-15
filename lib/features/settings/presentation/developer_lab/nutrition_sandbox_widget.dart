// lib/features/settings/presentation/developer_lab/nutrition_sandbox_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/app_section_header.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../profile/presentation/weekly_goal_review_screen.dart';
import '../../../profile/presentation/widgets/adaptive_review_card.dart';
import 'nutrition_sandbox_state.dart';

class NutritionSandboxWidget extends StatefulWidget {
  final NutritionSandboxState state;

  const NutritionSandboxWidget({super.key, required this.state});

  @override
  State<NutritionSandboxWidget> createState() => _NutritionSandboxWidgetState();
}

class _NutritionSandboxWidgetState extends State<NutritionSandboxWidget> {
  NutritionSandboxState get _state => widget.state;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(NutritionSandboxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_onStateChanged);
      widget.state.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'on_trajectory':
      case 'target_reached':
      case 'on_track':
        return Colors.green;
      case 'behind':
      case 'target_date_needs_review':
      case 'slower':
        return Colors.orange;
      case 'ahead':
      case 'faster':
        return Colors.blue;
      case 'calibrating':
      default:
        return Colors.purple;
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'adjust_targets':
        return Colors.amber.shade700;
      case 'keep_targets':
        return Colors.green;
      case 'keep_targets_intake_differs':
        return Colors.teal;
      case 'trajectory_change_needed':
        return Colors.red.shade400;
      case 'insufficient_data':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assessment = _state.evaluateAssessment();
    final reviewRecord = _state.buildSyntheticReviewRecord();
    final syntheticGoal = _state.buildSyntheticGoal();
    final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live HUD Card
        SummaryCard(
          child: Padding(
            padding: DesignConstants.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.gauge, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: DesignConstants.spacingS),
                    Text(
                      'Live Engine Bewertung',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: DesignConstants.spacingM),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBadge('Status: ${assessment.overallStatus}', _statusColor(assessment.overallStatus)),
                    _buildBadge('Momentum: ${assessment.recentMomentumStatus}', Colors.indigo),
                    _buildBadge('Action: ${assessment.nutritionAction}', _actionColor(assessment.nutritionAction)),
                    _buildBadge('Quality: ${assessment.dataQuality}',
                        assessment.dataQuality == 'sufficient' ? Colors.green : Colors.orange),
                  ],
                ),
                const Divider(height: DesignConstants.spacingL),
                // Key metrics row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Erwartet',
                        assessment.expectedValue != null ? '${assessment.expectedValue!.toStringAsFixed(1)} kg' : '--',
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Abweichung (Gap)',
                        assessment.trajectoryGap != null
                            ? '${assessment.trajectoryGap! > 0 ? '+' : ''}${assessment.trajectoryGap!.toStringAsFixed(1)} kg'
                            : '--',
                        highlight: assessment.trajectoryGap != null && assessment.trajectoryGap!.abs() > 0.5,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Erforderl. Rate',
                        assessment.requiredRemainingRateKgPerWeek != null
                            ? '${assessment.requiredRemainingRateKgPerWeek!.toStringAsFixed(2)} kg/W'
                            : '--',
                      ),
                    ),
                  ],
                ),
                if (assessment.projectedTargetDate != null) ...[
                  const SizedBox(height: DesignConstants.spacingS),
                  Text(
                    'Hochgerechnetes Zieldatum: ${dateFormat.format(assessment.projectedTargetDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
                const SizedBox(height: DesignConstants.spacingM),
                Text(
                  _state.buildExplanation(assessment),
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                ),
                const SizedBox(height: DesignConstants.spacingL),
                // Button to open full review screen
                AppButton.primary(
                  label: 'In Wochen-Review Screen öffnen',
                  tooltip: 'Öffnet WeeklyGoalReviewScreen mit diesen Sandbox-Werten',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WeeklyGoalReviewScreen(
                          goal: syntheticGoal,
                          review: reviewRecord,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: DesignConstants.spacingL),

        // Live Embedded Card Preview
        AppSectionHeader(title: 'Live Vorschau: Review Card (im Hub)'),
        AdaptiveReviewCard(
          activeGoal: syntheticGoal,
          pendingReview: reviewRecord,
          isRecommendationDue: true,
          onApply: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Test-Aktion: Empfehlung angewendet')),
            );
          },
        ),

        const SizedBox(height: DesignConstants.spacingXL),

        // --- Parameter Control Sliders ---
        AppSectionHeader(title: '1. Ziel & Zeitachse'),
        SummaryCard(
          child: Padding(
            padding: DesignConstants.cardPadding,
            child: Column(
              children: [
                _buildSliderRow(
                  label: 'Startgewicht (Baseline)',
                  value: _state.baselineWeightKg,
                  min: 50.0,
                  max: 140.0,
                  divisions: 180,
                  unit: 'kg',
                  onChanged: _state.setBaselineWeight,
                ),
                _buildSliderRow(
                  label: 'Zielgewicht',
                  value: _state.targetWeightKg,
                  min: 50.0,
                  max: 140.0,
                  divisions: 180,
                  unit: 'kg',
                  onChanged: _state.setTargetWeight,
                ),
                _buildSliderRow(
                  label: 'Geplante Gesamtdauer',
                  value: _state.totalPlannedWeeks.toDouble(),
                  min: 2,
                  max: 40,
                  divisions: 38,
                  unit: 'Wochen',
                  decimals: 0,
                  onChanged: (v) => _state.setTotalPlannedWeeks(v.round()),
                ),
                _buildSliderRow(
                  label: 'Verstrichene Zeit',
                  value: _state.elapsedWeeks.toDouble(),
                  min: 0,
                  max: 40,
                  divisions: 40,
                  unit: 'Wochen',
                  decimals: 0,
                  onChanged: (v) => _state.setElapsedWeeks(v.round()),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: DesignConstants.spacingL),

        AppSectionHeader(title: '2. Aktueller Gewichtsverlauf'),
        SummaryCard(
          child: Padding(
            padding: DesignConstants.cardPadding,
            child: Column(
              children: [
                _buildSliderRow(
                  label: 'Aktuelles Gewicht (geglättet)',
                  value: _state.currentWeightKg,
                  min: 50.0,
                  max: 140.0,
                  divisions: 180,
                  unit: 'kg',
                  onChanged: _state.setCurrentWeight,
                ),
                _buildSliderRow(
                  label: 'Trend letzte 7 Tage (recent rate)',
                  value: _state.recentRateKgPerWeek,
                  min: -2.0,
                  max: 2.0,
                  divisions: 80,
                  unit: 'kg/Woche',
                  decimals: 2,
                  onChanged: _state.setRecentRate,
                ),
                _buildSliderRow(
                  label: 'Trend letzte 21 Tage (operating rate)',
                  value: _state.operatingRateKgPerWeek,
                  min: -2.0,
                  max: 2.0,
                  divisions: 80,
                  unit: 'kg/Woche',
                  decimals: 2,
                  onChanged: _state.setOperatingRate,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: DesignConstants.spacingL),

        AppSectionHeader(title: '3. Compliance & Datenbasis (Sufficiency Gate)'),
        SummaryCard(
          child: Padding(
            padding: DesignConstants.cardPadding,
            child: Column(
              children: [
                _buildSliderRow(
                  label: 'Wiegungen in letzten 7 Tagen (Gate >= 3)',
                  value: _state.weightObservationCount.toDouble(),
                  min: 0,
                  max: 7,
                  divisions: 7,
                  unit: '/ 7',
                  decimals: 0,
                  onChanged: (v) => _state.setWeightObservationCount(v.round()),
                ),
                _buildSliderRow(
                  label: 'Geloggte Tage in letzten 7 Tagen (Gate >= 4)',
                  value: _state.nutritionLoggedDays.toDouble(),
                  min: 0,
                  max: 7,
                  divisions: 7,
                  unit: '/ 7',
                  decimals: 0,
                  onChanged: (v) => _state.setNutritionLoggedDays(v.round()),
                ),
                _buildSliderRow(
                  label: 'Aktuelles Kalorienziel',
                  value: _state.currentCalories.toDouble(),
                  min: 1200,
                  max: 4000,
                  divisions: 56,
                  unit: 'kcal',
                  decimals: 0,
                  onChanged: (v) => _state.setCurrentCalories(v.round()),
                ),
                _buildSliderRow(
                  label: 'Durchschnittlich geloggte Kalorien',
                  value: _state.averageLoggedCalories.toDouble(),
                  min: 1200,
                  max: 4500,
                  divisions: 66,
                  unit: 'kcal',
                  decimals: 0,
                  onChanged: (v) => _state.setAverageLoggedCalories(v.round()),
                ),
                _buildSliderRow(
                  label: 'TDEE Schätzung',
                  value: _state.tdeeEstimate,
                  min: 1500,
                  max: 4000,
                  divisions: 50,
                  unit: 'kcal',
                  decimals: 0,
                  onChanged: _state.setTdeeEstimate,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: highlight ? Colors.amber.shade600 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    int decimals = 1,
    required ValueChanged<double> onChanged,
  }) {
    final displayVal = decimals == 0 ? value.round().toString() : value.toStringAsFixed(decimals);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '$displayVal $unit',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
