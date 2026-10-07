// lib/features/settings/presentation/developer_lab/nutrition_sandbox_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/app_segmented_control.dart';
import '../../../../widgets/common/app_section_header.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../profile/presentation/weekly_goal_review_screen.dart';
import '../../../profile/presentation/widgets/adaptive_review_card.dart';
import 'nutrition_sandbox_state.dart';

enum _ReviewPreviewMode { card, screen }

class NutritionSandboxWidget extends StatefulWidget {
  final NutritionSandboxState state;
  final bool showOverview;
  final bool showControls;

  const NutritionSandboxWidget({
    super.key,
    required this.state,
    this.showOverview = true,
    this.showControls = true,
  });

  @override
  State<NutritionSandboxWidget> createState() => _NutritionSandboxWidgetState();
}

class _NutritionSandboxWidgetState extends State<NutritionSandboxWidget> {
  NutritionSandboxState get _state => widget.state;
  _ReviewPreviewMode _previewMode = _ReviewPreviewMode.card;

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

  String _humanStatus(String action) {
    switch (action) {
      case 'adjust_targets':
        return 'Nutrition targets should be adjusted';
      case 'keep_targets_intake_differs':
        return 'Keep targets and review logged intake';
      case 'trajectory_change_needed':
        return 'The goal trajectory needs attention';
      case 'insufficient_data':
        return 'More data is needed before acting';
      case 'keep_targets':
      default:
        return 'The current plan is working';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assessment = _state.evaluateAssessment();
    final reviewRecord = _state.buildSyntheticReviewRecord();
    final syntheticGoal = _state.buildSyntheticGoal();
    final dateFormat =
        DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showOverview) ...[
          AppSectionHeader(title: 'Live Review-Vorschau'),
          AppSegmentedControl<_ReviewPreviewMode>(
            children: const {
              _ReviewPreviewMode.card: 'Karte',
              _ReviewPreviewMode.screen: 'Review-Screen',
            },
            groupValue: _previewMode,
            onValueChanged: (value) => setState(() => _previewMode = value),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          if (_previewMode == _ReviewPreviewMode.card)
            AdaptiveReviewCard(
              activeGoal: syntheticGoal,
              pendingReview: reviewRecord,
              isRecommendationDue: true,
              onOpenReview: _openFullScreenPreview,
            )
          else
            SummaryCard(
              child: Padding(
                padding: DesignConstants.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vollständiger Weekly Review mit den aktuellen Sandbox-Werten.',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        label: 'Review-Screen öffnen',
                        onPressed: _openFullScreenPreview,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: DesignConstants.spacingM),
          SummaryCard(
            margin: EdgeInsets.zero,
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Engine-Diagnose'),
                subtitle: Text(
                  '${assessment.overallStatus} · '
                  '${assessment.recentMomentumStatus} · '
                  '${assessment.nutritionAction}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: DesignConstants.spacingM,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _humanStatus(assessment.nutritionAction),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: DesignConstants.spacingS),
                        Text(
                          _state.buildExplanation(assessment),
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: DesignConstants.spacingM),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildBadge(
                              'Status: ${assessment.overallStatus}',
                              _statusColor(assessment.overallStatus),
                            ),
                            _buildBadge(
                              'Momentum: ${assessment.recentMomentumStatus}',
                              Colors.indigo,
                            ),
                            _buildBadge(
                              'Action: ${assessment.nutritionAction}',
                              _actionColor(assessment.nutritionAction),
                            ),
                            _buildBadge(
                              'Quality: ${assessment.dataQuality}',
                              assessment.dataQuality == 'sufficient'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ],
                        ),
                        const Divider(height: DesignConstants.spacingL),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricItem(
                                'Erwartet',
                                assessment.expectedValue != null
                                    ? '${assessment.expectedValue!.toStringAsFixed(1)} kg'
                                    : '--',
                              ),
                            ),
                            Expanded(
                              child: _buildMetricItem(
                                'Abweichung',
                                assessment.trajectoryGap != null
                                    ? '${assessment.trajectoryGap! > 0 ? '+' : ''}${assessment.trajectoryGap!.toStringAsFixed(1)} kg'
                                    : '--',
                                highlight: assessment.trajectoryGap != null &&
                                    assessment.trajectoryGap!.abs() > 0.5,
                              ),
                            ),
                            Expanded(
                              child: _buildMetricItem(
                                'Erforderliche Rate',
                                assessment.requiredRemainingRateKgPerWeek !=
                                        null
                                    ? '${assessment.requiredRemainingRateKgPerWeek!.toStringAsFixed(2)} kg/W'
                                    : '--',
                              ),
                            ),
                          ],
                        ),
                        if (assessment.projectedTargetDate != null) ...[
                          const SizedBox(height: DesignConstants.spacingS),
                          Text(
                            'Prognostiziertes Zieldatum: ${dateFormat.format(assessment.projectedTargetDate!)}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.primary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (widget.showControls) ...[
          const SizedBox(height: DesignConstants.spacingM),
          SummaryCard(
            margin: EdgeInsets.zero,
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Sandbox-Eingaben'),
                subtitle: const Text(
                  'Änderungen aktualisieren die Vorschau direkt.',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _state.reset,
                      child: const Text('Zurücksetzen'),
                    ),
                    const Icon(LucideIcons.chevron_down),
                  ],
                ),
                children: [
                  const AppSectionHeader(title: '1. Ziel & Zeitachse'),
                  _buildGoalTimelineInputs(),
                  const SizedBox(height: DesignConstants.spacingM),
                  const AppSectionHeader(title: '2. Gewichtsverlauf'),
                  _buildProgressInputs(),
                  const SizedBox(height: DesignConstants.spacingM),
                  const AppSectionHeader(
                    title: '3. Ernährung & Datenbasis',
                  ),
                  _buildDataInputs(),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openFullScreenPreview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SandboxReviewPreview(state: _state),
      ),
    );
  }

  Widget _buildGoalTimelineInputs() {
    return SummaryCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          children: [
            _buildSliderRow(
              label: 'Startgewicht (Baseline)',
              value: _state.baselineWeightKg,
              min: 50,
              max: 140,
              divisions: 180,
              unit: 'kg',
              onChanged: _state.setBaselineWeight,
            ),
            _buildSliderRow(
              label: 'Zielgewicht',
              value: _state.targetWeightKg,
              min: 50,
              max: 140,
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
              onChanged: (value) => _state.setTotalPlannedWeeks(value.round()),
            ),
            _buildSliderRow(
              label: 'Verstrichene Zeit',
              value: _state.elapsedWeeks.toDouble(),
              min: 0,
              max: 40,
              divisions: 40,
              unit: 'Wochen',
              decimals: 0,
              onChanged: (value) => _state.setElapsedWeeks(value.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInputs() {
    return SummaryCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          children: [
            _buildSliderRow(
              label: 'Aktuelles Gewicht (geglättet)',
              value: _state.currentWeightKg,
              min: 50,
              max: 140,
              divisions: 180,
              unit: 'kg',
              onChanged: _state.setCurrentWeight,
            ),
            _buildSliderRow(
              label: 'Trend letzte 7 Tage (recent rate)',
              value: _state.recentRateKgPerWeek,
              min: -2,
              max: 2,
              divisions: 80,
              unit: 'kg/Woche',
              decimals: 2,
              onChanged: _state.setRecentRate,
            ),
            _buildSliderRow(
              label: 'Trend letzte 21 Tage (operating rate)',
              value: _state.operatingRateKgPerWeek,
              min: -2,
              max: 2,
              divisions: 80,
              unit: 'kg/Woche',
              decimals: 2,
              onChanged: _state.setOperatingRate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataInputs() {
    return SummaryCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          children: [
            _buildSliderRow(
              label: 'Wiegungen in letzten 7 Tagen (mind. 3)',
              value: _state.weightObservationCount.toDouble(),
              min: 0,
              max: 7,
              divisions: 7,
              unit: '/ 7',
              decimals: 0,
              onChanged: (value) =>
                  _state.setWeightObservationCount(value.round()),
            ),
            _buildSliderRow(
              label: 'Geloggte Tage in letzten 7 Tagen (mind. 4)',
              value: _state.nutritionLoggedDays.toDouble(),
              min: 0,
              max: 7,
              divisions: 7,
              unit: '/ 7',
              decimals: 0,
              onChanged: (value) =>
                  _state.setNutritionLoggedDays(value.round()),
            ),
            _buildSliderRow(
              label: 'Aktuelles Kalorienziel',
              value: _state.currentCalories.toDouble(),
              min: 1200,
              max: 4000,
              divisions: 56,
              unit: 'kcal',
              decimals: 0,
              onChanged: (value) => _state.setCurrentCalories(value.round()),
            ),
            _buildSliderRow(
              label: 'Durchschnittlich geloggte Kalorien',
              value: _state.averageLoggedCalories.toDouble(),
              min: 1200,
              max: 4500,
              divisions: 66,
              unit: 'kcal',
              decimals: 0,
              onChanged: (value) =>
                  _state.setAverageLoggedCalories(value.round()),
            ),
            _buildSliderRow(
              label: 'TDEE-Schätzung',
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

  Widget _buildMetricItem(String title, String value,
      {bool highlight = false}) {
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
    final displayVal = decimals == 0
        ? value.round().toString()
        : value.toStringAsFixed(decimals);
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
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              TextButton(
                onPressed: () => _editNumericValue(
                  label: label,
                  value: value,
                  min: min,
                  max: max,
                  decimals: decimals,
                  onChanged: onChanged,
                ),
                child: Text(
                  '$displayVal $unit',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

  Future<void> _editNumericValue({
    required String label,
    required double value,
    required double min,
    required double max,
    required int decimals,
    required ValueChanged<double> onChanged,
  }) async {
    final controller = TextEditingController(
      text: decimals == 0
          ? value.round().toString()
          : value.toStringAsFixed(decimals),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(
            helperText:
                '${min.toStringAsFixed(decimals)} – ${max.toStringAsFixed(decimals)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              Navigator.of(dialogContext).pop(parsed?.clamp(min, max));
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) onChanged(result);
  }
}

class _SandboxReviewPreview extends StatelessWidget {
  final NutritionSandboxState state;

  const _SandboxReviewPreview({required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => WeeklyGoalReviewScreen(
        goal: state.buildSyntheticGoal(),
        review: state.buildSyntheticReviewRecord(),
        previewOnly: true,
      ),
    );
  }
}
