import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../nutrition_recommendation/data/recommendation_service.dart';
import '../../../profile/data/goal_repository_impl.dart';
import '../../../profile/domain/models/goal_model.dart';
import '../../../profile/domain/repositories/goal_repository.dart';
import '../../../profile/presentation/widgets/adaptive_review_card.dart';

/// Shows the existing weekly-review card at the top of today's diary when a
/// review is waiting for a decision.
///
/// The card deliberately reuses [AdaptiveReviewCard] so its wording, actions,
/// and visual design stay identical to the Nutrition Hub while the product
/// placement is evaluated.
class PendingReviewDiaryCard extends StatefulWidget {
  final IGoalRepository? goalRepository;
  final AdaptiveNutritionRecommendationService? recommendationService;

  const PendingReviewDiaryCard({
    super.key,
    this.goalRepository,
    this.recommendationService,
  });

  @override
  State<PendingReviewDiaryCard> createState() => _PendingReviewDiaryCardState();
}

class _PendingReviewDiaryCardState extends State<PendingReviewDiaryCard> {
  late final IGoalRepository _goalRepository;
  late final AdaptiveNutritionRecommendationService _recommendationService;
  Goal? _activeGoal;
  GoalReviewRecord? _pendingReview;
  bool _isRecommendationDue = false;
  DateTime? _nextDueAt;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _goalRepository = widget.goalRepository ?? GoalRepositoryImpl();
    _recommendationService = widget.recommendationService ??
        AdaptiveNutritionRecommendationService();
    _load();
  }

  Future<void> _load() async {
    final goal = await _goalRepository.getActiveGoal();
    if (goal == null) {
      if (mounted) {
        setState(() {
          _activeGoal = null;
          _pendingReview = null;
        });
      }
      return;
    }

    final results = await Future.wait([
      _goalRepository.getPendingReview(goal.id),
      _recommendationService.loadState(refreshIfDue: false),
    ]);
    if (!mounted) return;

    final recommendationState =
        results[1] as AdaptiveNutritionRecommendationState;
    setState(() {
      _activeGoal = goal;
      _pendingReview = results[0] as GoalReviewRecord?;
      _isRecommendationDue = recommendationState.isAdaptiveRecommendationDueNow;
      _nextDueAt = recommendationState.nextAdaptiveRecommendationDueAt;
    });
  }

  Future<void> _applyRecommendation() async {
    if (_isApplying) return;
    setState(() => _isApplying = true);

    final applied =
        await _recommendationService.applyLatestRecommendationToActiveTargets();
    if (!mounted) return;

    setState(() => _isApplying = false);
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          applied
              ? l10n.adaptiveRecommendationAppliedToGoalsSnack
              : l10n.adaptiveRecommendationNotAvailableSnack,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    // This deliberately matches the Nutrition Hub's current placement rule:
    // a review is promoted only while it requires a decision.
    if (_activeGoal == null || _pendingReview == null) {
      return const SizedBox.shrink();
    }

    return AdaptiveReviewCard(
      activeGoal: _activeGoal,
      pendingReview: _pendingReview,
      isRecommendationDue: _isRecommendationDue,
      nextDueAt: _nextDueAt,
      onApply: _isApplying ? null : _applyRecommendation,
      onRefresh: _load,
    );
  }
}
