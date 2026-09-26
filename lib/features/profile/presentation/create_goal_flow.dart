// lib/features/profile/presentation/create_goal_flow.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/unit_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../data/goal_repository_impl.dart';
import '../domain/repositories/goal_repository.dart';
import 'widgets/goal_flow/goal_baseline_step.dart';
import 'widgets/goal_flow/goal_flow_state.dart';
import 'widgets/goal_flow/goal_motivation_step.dart';
import 'widgets/goal_flow/goal_pace_timeline_step.dart';
import 'widgets/goal_flow/goal_preset_step.dart';
import 'widgets/goal_flow/goal_review_step.dart';
import 'widgets/goal_flow/goal_target_step.dart';

class CreateGoalFlow extends StatefulWidget {
  final IGoalRepository? repository;

  const CreateGoalFlow({super.key, this.repository});

  @override
  State<CreateGoalFlow> createState() => _CreateGoalFlowState();
}

class _CreateGoalFlowState extends State<CreateGoalFlow> {
  late final IGoalRepository _repository =
      widget.repository ?? GoalRepositoryImpl();

  final GoalFlowState _state = GoalFlowState();

  int _currentStep = 0;
  static const int _totalSteps = 6;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _state.detectBaseline(_repository, context.read<UnitService>());
      }
    });
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _state.disposeControllers();
    super.dispose();
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    final unitService = context.read<UnitService>();
    final l10n = AppLocalizations.of(context)!;

    if (_currentStep == 0) {
      _state.validatePresetStep(l10n);
    } else if (_currentStep == 1) {
      final error = _state.validateBaselineStep(unitService, l10n);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }
      _state.prepareTargetDefaults(unitService);
    } else if (_currentStep == 2) {
      final error = _state.validateTargetStep(unitService, l10n);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitGoal() async {
    final unitService = context.read<UnitService>();
    final l10n = AppLocalizations.of(context)!;

    try {
      final success = await _state.submitGoal(
        context: context,
        repository: _repository,
        unitService: unitService,
        l10n: l10n,
      );
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.goalCreateError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: GlobalAppBar(
        title: l10n.createGoalTitle,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          onPressed: _previousStep,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignConstants.spacingL,
                DesignConstants.spacingS,
                DesignConstants.spacingL,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    l10n.goalStepProgress(_currentStep + 1, _totalSteps),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: (_currentStep + 1) / _totalSteps,
                        color: theme.colorScheme.primary,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageStorage(
                bucket: PageStorageBucket(),
                child: SingleChildScrollView(
                  key: ValueKey('goal_flow_step_$_currentStep'),
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignConstants.spacingM,
                  ),
                  child: _buildCurrentStepContent(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignConstants.spacingL),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: AppButton.secondary(
                        label: l10n.back,
                        onPressed: _previousStep,
                      ),
                    ),
                  if (_currentStep > 0)
                    const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    flex: 2,
                    child: AppButton.primary(
                      label: _currentStep == _totalSteps - 1
                          ? (_state.isSaving
                              ? l10n.saving
                              : l10n.goalConfirmCreateButton)
                          : l10n.continueButton,
                      onPressed: _state.isSaving
                          ? null
                          : (_currentStep == _totalSteps - 1
                              ? _submitGoal
                              : _nextStep),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return GoalPresetStep(state: _state);
      case 1:
        return GoalBaselineStep(state: _state, repository: _repository);
      case 2:
        return GoalTargetStep(state: _state);
      case 3:
        return GoalPaceTimelineStep(state: _state);
      case 4:
        return GoalMotivationStep(state: _state);
      case 5:
        return GoalReviewStep(state: _state);
      default:
        return const SizedBox.shrink();
    }
  }
}
