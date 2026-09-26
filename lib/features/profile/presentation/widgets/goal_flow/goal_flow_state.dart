import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../../services/unit_service.dart';
import '../../../domain/models/goal_model.dart';
import '../../../domain/repositories/goal_repository.dart';
import '../../../domain/services/goal_notification_orchestrator.dart';
import '../../../../app/presentation/widgets/glass_bottom_menu.dart';

/// Central state and validation logic for the 6-step goal creation flow.
/// Shared between standalone [CreateGoalFlow] and the integrated onboarding flow.
class GoalFlowState extends ChangeNotifier {
  // Step 0: Absicht / Preset
  GoalPreset preset = GoalPreset.loseWeight;
  final TextEditingController customTitleController = TextEditingController();
  String customDirection = 'lose'; // 'lose', 'gain', 'maintain'

  // Step 1: Startdatum & Baseline
  DateTime startDate = DateTime.now();
  double? detectedBaselineWeight; // in kg
  DateTime? detectedBaselineDate;
  String? detectedBaselineMeasurementId;
  final TextEditingController baselineWeightController = TextEditingController();
  bool isManualBaselineMode = false;
  bool isEditingBaseline = false;
  bool showManualBaselineInput = false;

  GoalTrackingMode trackingMode = GoalTrackingMode.weeklyRate;

  // Step 2: Zielgewicht
  final TextEditingController targetWeightController = TextEditingController();
  bool showManualTargetWeightInput = false;

  // Step 3: Tempo & Zieldatum (Interaktiver Planer)
  DateTime? targetDate;
  double weeklyRateKg = 0.50; // positive magnitude
  String selectedRatePreset = 'moderate'; // 'gentle', 'moderate', 'athletic', 'aggressive', 'custom'
  String selectedDurationPreset = 'custom'; // '8', '12', '16', '24', 'custom'

  // Step 4: Motivation
  final TextEditingController reasonController = TextEditingController();
  final FocusNode reasonFocusNode = FocusNode();

  // Step 5: Review & Aktivieren
  bool isNutritionDriver = true;
  bool isSaving = false;

  /// Optional callback invoked when the baseline weight is modified.
  ValueChanged<double>? onBaselineChanged;

  void setDurationPreset(String val) {
    if (val == 'ongoing') {
      selectedDurationPreset = 'ongoing';
      targetDate = null;
    } else if (val == 'custom') {
      selectedDurationPreset = 'custom';
    } else {
      final w = int.tryParse(val) ?? 12;
      selectedDurationPreset = val;
      targetDate = startDate.add(Duration(days: w * 7));
    }
    notifyListeners();
  }

  void setRatePresetCustom() {
    selectedRatePreset = 'custom';
    notifyListeners();
  }

  void setDurationPresetCustom() {
    selectedDurationPreset = 'custom';
    notifyListeners();
  }

  void setTargetDate(DateTime picked) {
    targetDate = picked;
    notifyListeners();
  }

  void setNutritionDriver(bool value) {
    isNutritionDriver = value;
    notifyListeners();
  }

  void setReason(String suggestion) {
    reasonController.text = suggestion;
    notifyListeners();
  }

  void disposeControllers() {
    customTitleController.dispose();
    baselineWeightController.dispose();
    targetWeightController.dispose();
    reasonController.dispose();
    reasonFocusNode.dispose();
    super.dispose();
  }

  /// Initialize baseline from an existing known weight (e.g. from onboarding measurements).
  void initBaselineFromKnownWeight({
    required double weightKg,
    required UnitService unitService,
    DateTime? date,
    String? measurementId,
  }) {
    detectedBaselineWeight = weightKg;
    detectedBaselineDate = date ?? startDate;
    detectedBaselineMeasurementId = measurementId;
    final disp = unitService.convertDisplayValue(
      weightKg,
      UnitDimension.weight,
    );
    baselineWeightController.text = disp.toStringAsFixed(1);
    isManualBaselineMode = false;
    isEditingBaseline = false;
    notifyListeners();
  }

  /// Detects latest weight from database at or before [startDate].
  Future<void> detectBaseline(IGoalRepository repository, UnitService unitService) async {
    final startEndOfDay = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      23,
      59,
      59,
    );

    final row = await repository.findLatestWeightAtOrBefore(startEndOfDay);

    detectedBaselineWeight = row?.valueKg;
    detectedBaselineDate = row?.date;
    detectedBaselineMeasurementId = row?.id;
    if (row?.valueKg != null && baselineWeightController.text.isEmpty) {
      final disp = unitService.convertDisplayValue(
        row!.valueKg,
        UnitDimension.weight,
      );
      baselineWeightController.text = disp.toStringAsFixed(1);
      isEditingBaseline = false;
    }
    if (row?.valueKg == null) {
      isEditingBaseline = true;
      showManualBaselineInput = true;
    }
    notifyListeners();
  }

  void updatePreset(GoalPreset newPreset) {
    preset = newPreset;
    notifyListeners();
  }

  void updateCustomDirection(String direction) {
    customDirection = direction;
    notifyListeners();
  }

  void updateStartDate(DateTime newDate) {
    startDate = newDate;
    notifyListeners();
  }

  void toggleEditingBaseline() {
    isEditingBaseline = !isEditingBaseline;
    notifyListeners();
  }

  void toggleManualBaselineInput() {
    showManualBaselineInput = !showManualBaselineInput;
    notifyListeners();
  }

  void toggleManualTargetWeightInput() {
    showManualTargetWeightInput = !showManualTargetWeightInput;
    notifyListeners();
  }

  void setBaselineManual(double weightKg, UnitService unitService) {
    detectedBaselineWeight = weightKg;
    isManualBaselineMode = true;
    final disp = unitService.convertDisplayValue(weightKg, UnitDimension.weight);
    baselineWeightController.text = disp.toStringAsFixed(1);
    onBaselineChanged?.call(weightKg);
    notifyListeners();
  }

  double? getBaselineKg(UnitService unitService) {
    if (!isManualBaselineMode && detectedBaselineWeight != null) {
      return detectedBaselineWeight;
    }
    final text = baselineWeightController.text.trim();
    if (text.isEmpty) {
      return detectedBaselineWeight;
    }
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return detectedBaselineWeight;
    }
    return unitService.convertToMetric(parsed, UnitDimension.weight);
  }

  double? getTargetKg(UnitService unitService) {
    final text = targetWeightController.text.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return null;
    return unitService.convertToMetric(parsed, UnitDimension.weight);
  }

  double getDeltaKg(UnitService unitService) {
    final b = getBaselineKg(unitService);
    final t = getTargetKg(unitService);
    if (b == null || t == null) return 0.0;
    return (t - b).abs();
  }

  bool get isMaintain {
    return preset == GoalPreset.maintainWeight ||
        preset == GoalPreset.recomposition ||
        (preset == GoalPreset.custom && customDirection == 'maintain');
  }

  bool get isLosing {
    return preset == GoalPreset.loseWeight ||
        (preset == GoalPreset.custom && customDirection == 'lose');
  }

  bool get isGaining {
    return preset == GoalPreset.gainWeight ||
        (preset == GoalPreset.custom && customDirection == 'gain');
  }

  void onTargetDateChanged(
    DateTime newDate,
    UnitService unitService, {
    String? durationPreset,
  }) {
    targetDate = newDate;
    final delta = getDeltaKg(unitService);
    if (delta > 0) {
      final days = max(7, newDate.difference(startDate).inDays);
      final weeks = days / 7.0;
      weeklyRateKg = (delta / weeks).clamp(0.05, 2.0);
    }
    if (durationPreset != null) {
      selectedDurationPreset = durationPreset;
    } else {
      syncDurationPreset();
    }
    syncRatePreset();
    notifyListeners();
  }

  void onWeeklyRateChanged(
    double newRate,
    UnitService unitService, {
    String? ratePreset,
  }) {
    weeklyRateKg = newRate;
    final delta = getDeltaKg(unitService);
    if (delta > 0 && newRate > 0) {
      final weeks = delta / newRate;
      final days = (weeks * 7).round();
      targetDate = startDate.add(Duration(days: max(7, days)));
    }
    if (ratePreset != null) {
      selectedRatePreset = ratePreset;
    } else {
      syncRatePreset();
    }
    syncDurationPreset();
    notifyListeners();
  }

  void onTargetWeightChanged(double newWeight, UnitService unitService) {
    targetWeightController.text = newWeight.toStringAsFixed(1);
    final delta = getDeltaKg(unitService);
    if (delta > 0 && weeklyRateKg > 0) {
      final weeks = delta / weeklyRateKg;
      final days = (weeks * 7).round();
      targetDate = startDate.add(Duration(days: max(7, days)));
      syncDurationPreset();
    }
    notifyListeners();
  }

  void syncRatePreset() {
    if ((weeklyRateKg - 0.25).abs() < 0.03) {
      selectedRatePreset = 'gentle';
    } else if ((weeklyRateKg - 0.50).abs() < 0.03) {
      selectedRatePreset = 'moderate';
    } else if ((weeklyRateKg - 0.75).abs() < 0.03) {
      selectedRatePreset = 'athletic';
    } else if ((weeklyRateKg - 1.00).abs() < 0.03) {
      selectedRatePreset = 'aggressive';
    } else {
      selectedRatePreset = 'custom';
    }
  }

  void syncDurationPreset() {
    if (targetDate == null) {
      selectedDurationPreset = 'custom';
      return;
    }
    final days = targetDate!.difference(startDate).inDays;
    final weeks = (days / 7).round();
    if (weeks == 8 && (days - 56).abs() <= 3) {
      selectedDurationPreset = '8';
    } else if (weeks == 12 && (days - 84).abs() <= 3) {
      selectedDurationPreset = '12';
    } else if (weeks == 16 && (days - 112).abs() <= 3) {
      selectedDurationPreset = '16';
    } else if (weeks == 24 && (days - 168).abs() <= 3) {
      selectedDurationPreset = '24';
    } else {
      selectedDurationPreset = 'custom';
    }
  }

  /// Sets up default target values and timelines once baseline is confirmed.
  void prepareTargetDefaults(UnitService unitService) {
    final baseline = getBaselineKg(unitService);
    if (baseline == null) return;
    isEditingBaseline = false;

    if (isMaintain) {
      trackingMode = GoalTrackingMode.open;
      if (selectedDurationPreset == 'custom' && targetDate == null) {
        selectedDurationPreset = 'ongoing';
      }
    } else {
      trackingMode = GoalTrackingMode.targetWeight;
      final dispBase = unitService.convertDisplayValue(baseline, UnitDimension.weight);
      if (targetWeightController.text.trim().isEmpty) {
        if (isLosing) {
          final diff = unitService.convertDisplayValue(5.0, UnitDimension.weight);
          final targetDisp = max(30.0, dispBase - diff);
          targetWeightController.text = targetDisp.toStringAsFixed(1);
        } else if (isGaining) {
          final diff = unitService.convertDisplayValue(3.0, UnitDimension.weight);
          targetWeightController.text = (dispBase + diff).toStringAsFixed(1);
        } else {
          targetWeightController.text = dispBase.toStringAsFixed(1);
        }
      }

      if (targetDate == null) {
        final delta = getDeltaKg(unitService);
        final weeks = (weeklyRateKg > 0 && delta > 0)
            ? max(1, (delta / weeklyRateKg).round())
            : 12;
        targetDate = startDate.add(Duration(days: max(7, weeks * 7)));
        syncDurationPreset();
        syncRatePreset();
      }
    }
    notifyListeners();
  }

  /// Validates Step 0 (Preset). Sets default title for custom preset if empty.
  void validatePresetStep(AppLocalizations l10n) {
    if (preset == GoalPreset.custom && customTitleController.text.trim().isEmpty) {
      customTitleController.text = l10n.goalPresetCustom;
    }
  }

  /// Validates Step 1 (Baseline). Returns error string if invalid.
  String? validateBaselineStep(UnitService unitService, AppLocalizations l10n) {
    final baseline = getBaselineKg(unitService);
    if (baseline == null || baseline <= 0) {
      return l10n.goalEnterBaselineWeightPrompt(
        unitService.unitString(UnitDimension.weight),
      );
    }
    return null;
  }

  /// Validates Step 2 (Target). Returns error string if invalid.
  String? validateTargetStep(UnitService unitService, AppLocalizations l10n) {
    if (isMaintain) return null;

    final baseline = getBaselineKg(unitService);
    final target = getTargetKg(unitService);
    if (target == null || target <= 0) {
      return l10n.goalTargetWeightLabel(
        unitService.unitString(UnitDimension.weight),
      );
    }
    if (baseline != null) {
      if (isLosing && target >= baseline) {
        return l10n.goalTargetDirectionLoseError;
      }
      if (isGaining && target <= baseline) {
        return l10n.goalTargetDirectionGainError;
      }
    }
    return null;
  }

  /// Assembles the goal title based on preset and custom title.
  String resolveGoalTitle(AppLocalizations l10n) {
    if (preset == GoalPreset.custom && customTitleController.text.trim().isNotEmpty) {
      return customTitleController.text.trim();
    }
    switch (preset) {
      case GoalPreset.loseWeight:
        return l10n.goalPresetLoseWeight;
      case GoalPreset.gainWeight:
        return l10n.goalPresetGainWeight;
      case GoalPreset.maintainWeight:
        return l10n.goalPresetMaintainWeight;
      case GoalPreset.recomposition:
        return l10n.goalPresetRecomposition;
      case GoalPreset.custom:
        return l10n.goalPresetCustom;
    }
  }

  /// Persists the goal into [repository] and handles notification synchronization.
  Future<bool> submitGoal({
    required BuildContext context,
    required IGoalRepository repository,
    required UnitService unitService,
    required AppLocalizations l10n,
    bool checkConfirmation = true,
  }) async {
    if (isSaving) return false;
    isSaving = true;
    notifyListeners();

    final title = resolveGoalTitle(l10n);
    final baselineKg = getBaselineKg(unitService);
    final targetKg = getTargetKg(unitService);

    double? signedWeeklyRateKg;
    if (isMaintain) {
      signedWeeklyRateKg = 0.0;
    } else if (isLosing) {
      signedWeeklyRateKg = -weeklyRateKg.abs();
    } else {
      signedWeeklyRateKg = weeklyRateKg.abs();
    }

    trackingMode = isMaintain ? GoalTrackingMode.open : GoalTrackingMode.targetWeight;

    try {
      final previouslyActive = await repository.getActiveNutritionGoal();
      if (previouslyActive != null && checkConfirmation && context.mounted) {
        final replace = await showGlassConfirmation(
          context: context,
          title: l10n.goalReplaceActiveTitle,
          content: l10n.goalReplaceActiveBody,
          confirmLabel: l10n.goalReplaceActiveConfirm,
          isDanger: false,
        );
        if (replace != true) {
          isSaving = false;
          notifyListeners();
          return false;
        }
      }

      await repository.createGoal(
        preset: preset == GoalPreset.custom
            ? switch (customDirection) {
                'lose' => GoalPreset.loseWeight,
                'gain' => GoalPreset.gainWeight,
                _ => GoalPreset.maintainWeight,
              }
            : preset,
        title: title,
        reason: reasonController.text.trim().isNotEmpty
            ? reasonController.text.trim()
            : null,
        startDate: startDate,
        trackingMode: trackingMode,
        baselineMeasurementId: isManualBaselineMode ? null : detectedBaselineMeasurementId,
        baselineValueKg: baselineKg,
        baselineDate: isManualBaselineMode ? startDate : (detectedBaselineDate ?? startDate),
        targetDate: targetDate,
        targetMetric: 'weight',
        targetValue: isMaintain ? baselineKg : targetKg,
        targetUnit: 'kg',
        desiredWeeklyRateKg: signedWeeklyRateKg,
        isNutritionDriver: isNutritionDriver,
      );

      final notifications = GoalNotificationOrchestrator(goalRepository: repository);
      if (previouslyActive != null) {
        await notifications.goalBecameInactive(previouslyActive.id);
      }
      await notifications.synchronize();

      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      isSaving = false;
      notifyListeners();
      rethrow;
    }
  }
}
