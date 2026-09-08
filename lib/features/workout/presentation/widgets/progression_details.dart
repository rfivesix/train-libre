import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/platform_adaptive_dropdown.dart';
import '../../domain/models/set_log.dart';
import '../../domain/progression/progression_v15.dart';

String policyLabel(AppLocalizations l, ProgressionPolicy p) =>
    p == ProgressionPolicy.linkedWorkingSets
        ? l.progressionTogether
        : l.progressionIndividually;
String completionLabel(AppLocalizations l, SetCompletion c) => switch (c) {
      SetCompletion.completed => l.progressionCompleted,
      SetCompletion.abandoned => l.progressionAbandoned,
      SetCompletion.stoppedForPain => l.progressionPain,
      SetCompletion.equipmentInterrupted => l.progressionEquipmentInterrupted,
    };
String reviewLabel(AppLocalizations l, ReviewKind k) => switch (k) {
      ReviewKind.largeStepTrial => l.progressionLargeStep,
      ReviewKind.overRepBridge => l.progressionBridge,
      ReviewKind.stepUnavailable => l.progressionUnavailable,
      ReviewKind.farAboveRange => l.progressionOvershoot,
      ReviewKind.stallCandidate => l.progressionStall,
      ReviewKind.modeBoundary => l.progressionBoundary,
    };

Future<double?> chooseProgressionBaseline(
    BuildContext context, double? initial) async {
  final l = AppLocalizations.of(context)!;
  final units = context.read<UnitService>();
  final controller = TextEditingController(
      text: initial == null
          ? ''
          : units.formatDisplayWeight(initial, fractionDigits: 2));
  return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
              title: Text(l.progressionRecalibrate),
              content: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.progressionDismiss)),
                FilledButton(
                    onPressed: () {
                      final value =
                          double.tryParse(controller.text.replaceAll(',', '.'));
                      if (value != null && value.isFinite && value >= 0) {
                        Navigator.pop(context,
                            units.convertToMetric(value, UnitDimension.weight));
                      }
                    },
                    child: Text(l.progressionAccept))
              ]));
}

class ProgressionDetails extends StatelessWidget {
  final SetLog log;
  final List<ProgressionReview> reviews;
  final bool showCompletionPicker;
  final Future<void> Function(ProgressionReview, ReviewAction,
      {double? chosenLoad})? onDecision;
  final ValueChanged<SetCompletion>? onCompletion;
  const ProgressionDetails(
      {super.key,
      required this.log,
      this.reviews = const [],
      this.showCompletionPicker = false,
      this.onDecision,
      this.onCompletion});
  @override
  Widget build(BuildContext context) {
    if (!showCompletionPicker && reviews.isEmpty) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    final units = context.read<UnitService>();
    final config = log.progression;
    String load(double? v) =>
        v == null ? '—' : units.formatDisplayWeight(v, fractionDigits: 2);
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignConstants.spacingM,
        DesignConstants.spacingXS,
        DesignConstants.spacingM,
        DesignConstants.spacingS,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showCompletionPicker && onCompletion != null)
                PlatformAdaptiveDropdownFormField<SetCompletion>(
                  key:
                      ValueKey('set_completion_${log.id ?? log.logOrder ?? 0}'),
                  value: config.completion,
                  decoration:
                      InputDecoration(labelText: l.progressionSetOutcome),
                  items: SetCompletion.values
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(completionLabel(l, c))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onCompletion!(value);
                  },
                ),
              if (showCompletionPicker &&
                  config.completion == SetCompletion.stoppedForPain)
                Padding(
                  padding: const EdgeInsets.only(top: DesignConstants.spacingS),
                  child: Text(l.progressionPainGuidance),
                ),
              if (showCompletionPicker && reviews.isNotEmpty)
                const SizedBox(height: DesignConstants.spacingM),
              if (config.completion == SetCompletion.completed)
                ...reviews.map((review) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: DesignConstants.spacingXS),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reviewLabel(l, review.kind)),
                          Text(
                              '${load(review.currentLoad)} → ${load(review.targetLoad)}${review.relativeJump == null ? '' : ' (${(review.relativeJump! * 100).toStringAsFixed(1)}%)'}${review.targetReps == null ? '' : ' × ${review.targetReps}'}'),
                          if (onDecision != null)
                            Wrap(spacing: 8, children: [
                              if (review.kind == ReviewKind.farAboveRange)
                                TextButton(
                                    onPressed: () => onDecision!(
                                        review, ReviewAction.confirmedLog),
                                    child: Text(l.progressionConfirmLog))
                              else if (review.targetLoad != null)
                                TextButton(
                                    onPressed: () => onDecision!(
                                        review, ReviewAction.accepted),
                                    child: Text(l.progressionAccept)),
                              if (review.kind == ReviewKind.farAboveRange ||
                                  review.kind == ReviewKind.stepUnavailable)
                                TextButton(
                                    onPressed: () async {
                                      final chosen =
                                          await chooseProgressionBaseline(
                                              context, review.currentLoad);
                                      if (chosen != null) {
                                        await onDecision!(
                                            review, ReviewAction.recalibrated,
                                            chosenLoad: chosen);
                                      }
                                    },
                                    child: Text(l.progressionRecalibrate)),
                              TextButton(
                                  onPressed: () => onDecision!(
                                      review, ReviewAction.rejected),
                                  child: Text(l.progressionDecline)),
                              TextButton(
                                  onPressed: () => onDecision!(
                                      review, ReviewAction.dismissed),
                                  child: Text(l.progressionDismiss)),
                            ]),
                        ]))),
            ],
          ),
        ),
      ),
    );
  }
}
