// lib/features/diary/presentation/nutrition_hub_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../data/database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/card_morph_route.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/summary_card.dart';
import '../../nutrition_recommendation/data/recommendation_service.dart';
import '../../nutrition_recommendation/presentation/nutrition_recommendation_card.dart';
import '../../profile/data/goal_repository_impl.dart';
import '../../profile/domain/models/goal_model.dart';
import '../../profile/domain/models/goal_progress.dart';
import '../../profile/domain/repositories/goal_repository.dart';
import '../../profile/presentation/my_goals_screen.dart';
import '../../profile/presentation/widgets/adaptive_review_card.dart';
import '../../profile/presentation/widgets/goal_progress_hero_card.dart';
import '../../supplements/presentation/supplement_hub_screen.dart';
import 'add_food_screen.dart';
import 'meal_screen.dart';

/// A portal for overviewing nutrition, progress, and meal planning.
///
/// Designed as a coherent progress dashboard featuring:
/// 1. Status & Active Goal / Trajectory
/// 2. Adaptive Review & Recommendations
/// 3. Daily Operating Targets
/// 4. Saved Meals
/// 5. Tools & Library
class NutritionHubScreen extends StatefulWidget {
  final IGoalRepository? goalRepository;

  const NutritionHubScreen({super.key, this.goalRepository});

  @override
  State<NutritionHubScreen> createState() => _NutritionHubScreenState();
}

class _NutritionHubScreenState extends State<NutritionHubScreen> {
  Future<Map<String, dynamic>>? _hubDataFuture;
  final _recommendationService = AdaptiveNutritionRecommendationService();
  late final IGoalRepository _goalRepository;
  bool _isApplyingRecommendation = false;

  @override
  void initState() {
    super.initState();
    _goalRepository = widget.goalRepository ?? GoalRepositoryImpl();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hubDataFuture == null) {
      _hubDataFuture = _loadHubData(refreshIfDue: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkBackgroundRecommendationDue();
      });
    }
  }

  Future<void> _checkBackgroundRecommendationDue() async {
    if (!mounted) return;
    final state = await _recommendationService.loadState(refreshIfDue: false);
    if (state.isAdaptiveRecommendationDueNow) {
      await _recommendationService.refreshRecommendationIfDue();
      if (mounted) {
        setState(() {
          _hubDataFuture = _loadHubData(refreshIfDue: false);
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _hubDataFuture = _loadHubData(refreshIfDue: true);
    });
  }

  Future<Map<String, dynamic>> _loadHubData({bool refreshIfDue = false}) async {
    final today = DateTime.now();
    final goals = await DatabaseHelper.instance.getGoalsForDate(today);
    final meals = await DatabaseHelper.instance.getMeals();

    final activeGoal = await _goalRepository.getActiveGoal();
    GoalProgress? activeProgress;
    GoalReviewRecord? pendingReview;
    if (activeGoal != null) {
      activeProgress = await _goalRepository.getGoalProgress(activeGoal);
      pendingReview = await _goalRepository.getPendingReview(activeGoal.id);
    }

    final recommendationState =
        await _recommendationService.loadState(refreshIfDue: refreshIfDue);

    return {
      'meals': meals,
      'dailyGoals': goals,
      'activeGoal': activeGoal,
      'activeProgress': activeProgress,
      'pendingReview': pendingReview,
      'recommendationState': recommendationState,
    };
  }

  Future<void> _applyRecommendation() async {
    if (_isApplyingRecommendation) return;
    setState(() => _isApplyingRecommendation = true);

    final applied =
        await _recommendationService.applyLatestRecommendationToActiveTargets();
    if (!mounted) return;
    setState(() => _isApplyingRecommendation = false);

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
    await _refreshData();
  }

  bool _isRecalculatingRecommendation = false;

  Future<void> _recalculateRecommendationNow() async {
    if (_isRecalculatingRecommendation) return;
    setState(() => _isRecalculatingRecommendation = true);

    await _recommendationService.recalculateRecommendationNow();
    if (!mounted) return;
    setState(() => _isRecalculatingRecommendation = false);

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.adaptiveRecommendationRecalculatedSnack),
      ),
    );
    await _refreshData();
  }

  Future<void> _createMealAndOpenEditor([
    BuildContext? sourceContext,
    MorphSourceVisibilityCallback? onSourceVisibilityChanged,
  ]) async {
    final l10n = AppLocalizations.of(context)!;
    final defaultName = l10n.mealNameLabel;
    final newMealId = await DatabaseHelper.instance.insertMeal(
      name: defaultName,
      notes: '',
    );
    final meal = {'id': newMealId, 'name': defaultName, 'notes': ''};

    if (!mounted) return;
    if (sourceContext != null && sourceContext.mounted) {
      await Navigator.of(context).push(
        CardMorphRoute(
          sourceContext: sourceContext,
          sourceBuilder: (_) => _buildCreateMealCard(context, l10n),
          sourceBorderRadius: DesignConstants.borderRadiusM,
          onSourceVisibilityChanged: onSourceVisibilityChanged,
          builder: (_) => MealScreen(meal: meal, startInEdit: true),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MealScreen(meal: meal, startInEdit: true),
        ),
      );
    }

    final items = await DatabaseHelper.instance.getMealItems(newMealId);
    final createdMeals = await DatabaseHelper.instance.getMeals();
    final createdMeal = createdMeals.firstWhere(
      (m) => m['id'] == newMealId,
      orElse: () => {},
    );

    if (createdMeal.isNotEmpty &&
        (createdMeal['name'] as String) == defaultName &&
        items.isEmpty) {
      await DatabaseHelper.instance.deleteMeal(newMealId);
    }

    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final double appBarHeight = MediaQuery.of(context).padding.top;

    const EdgeInsets basePadding = DesignConstants.cardPadding;
    final EdgeInsets finalPadding = basePadding.copyWith(
      top: basePadding.top + appBarHeight,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _hubDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text(l10n.error));
          }

          final data = snapshot.data!;
          final meals = data['meals'] as List<Map<String, dynamic>>;
          final activeGoal = data['activeGoal'] as Goal?;
          final activeProgress = data['activeProgress'] as GoalProgress?;
          final pendingReview = data['pendingReview'] as GoalReviewRecord?;
          final recommendationState = data['recommendationState']
              as AdaptiveNutritionRecommendationState;

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: finalPadding,
              children: [
                // Modul 1: Ziel- & Fortschrittskarte
                RepaintBoundary(
                  child: GoalProgressHeroCard(
                    goal: activeGoal,
                    progress: activeProgress,
                    onRefresh: _refreshData,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingL),

                // Modul 2: Wöchentlicher Review (falls fällig oder ausstehend)
                if (pendingReview != null) ...[
                  RepaintBoundary(
                    child: AdaptiveReviewCard(
                      activeGoal: activeGoal,
                      pendingReview: pendingReview,
                      isRecommendationDue:
                          recommendationState.isAdaptiveRecommendationDueNow,
                      nextDueAt:
                          recommendationState.nextAdaptiveRecommendationDueAt,
                      onApply: _applyRecommendation,
                      onRefresh: _refreshData,
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                ],

                // Modul 3: Adaptive Nutrition Recommendations (1:1)
                RepaintBoundary(
                  child: _buildGoalsAndRecommendationCard(
                    context,
                    recommendationState,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingXL),

                // Modul 4: Gespeicherte Mahlzeiten
                AppSectionHeader(title: l10n.nutritionSectionMyMeals),
                RepaintBoundary(
                  child: SizedBox(
                    height: 160,
                    child: meals.isEmpty
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCreateMealCard(context, l10n),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: DesignConstants.spacingS,
                                    vertical: DesignConstants.spacingM,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.emptyStateNutritionRecipesCallout,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.6),
                                              height: 1.3,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: meals.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildCreateMealCard(context, l10n);
                              }
                              return _buildMealCard(context, meals[index - 1]);
                            },
                          ),
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingXL),

                // Modul 5: Werkzeuge & Bibliothek
                AppSectionHeader(title: l10n.nutritionSectionToolsAndLibrary),
                RepaintBoundary(
                  child: Builder(
                    builder: (sourceCtx) => MorphSourceScope(
                      builder: (context, setHidden) => _buildNavigationCard(
                        context: context,
                        icon: LucideIcons.pill,
                        title: l10n.supplementTrackerTitle,
                        subtitle: l10n.supplementTrackerDescription,
                        onTap: () {
                          Navigator.of(context).push(
                            CardMorphRoute(
                              sourceContext: sourceCtx,
                              sourceBuilder: (_) => _buildNavigationCard(
                                context: context,
                                icon: LucideIcons.pill,
                                title: l10n.supplementTrackerTitle,
                                subtitle: l10n.supplementTrackerDescription,
                                onTap: () {},
                              ),
                              sourceBorderRadius: DesignConstants.borderRadiusM,
                              onSourceVisibilityChanged: setHidden,
                              builder: (_) => const SupplementHubScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: Builder(
                    builder: (sourceCtx) => MorphSourceScope(
                      builder: (context, setHidden) => _buildNavigationCard(
                        context: context,
                        icon: LucideIcons.search,
                        title: l10n.drawerFoodExplorer,
                        subtitle: l10n.data_from_off_and_wger,
                        onTap: () {
                          Navigator.of(context).push(
                            CardMorphRoute(
                              sourceContext: sourceCtx,
                              sourceBuilder: (_) => _buildNavigationCard(
                                context: context,
                                icon: LucideIcons.search,
                                title: l10n.drawerFoodExplorer,
                                subtitle: l10n.data_from_off_and_wger,
                                onTap: () {},
                              ),
                              sourceBorderRadius: DesignConstants.borderRadiusM,
                              onSourceVisibilityChanged: setHidden,
                              builder: (_) => const AddFoodScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const BottomContentSpacer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalsAndRecommendationCard(
    BuildContext context,
    AdaptiveNutritionRecommendationState recommendationState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        NutritionRecommendationCard(
          goal: recommendationState.goal,
          targetRateKgPerWeek: recommendationState.targetRateKgPerWeek,
          recommendation: recommendationState.latestGeneratedRecommendation,
          maintenanceEstimate: recommendationState.latestMaintenanceEstimate,
          generatedAt: recommendationState.latestGeneratedAt,
          nextAdaptiveRecommendationDueAt:
              recommendationState.nextAdaptiveRecommendationDueAt,
          isAdaptiveRecommendationDueNow:
              recommendationState.isAdaptiveRecommendationDueNow,
          isRecalculating: _isRecalculatingRecommendation,
          isApplying: _isApplyingRecommendation,
          onRecalculate: _recalculateRecommendationNow,
          onApply: _applyRecommendation,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton.primary(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MyGoalsScreen()));
            },
            label: l10n.my_goals,
            tooltip: l10n.my_goals,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateMealCard(BuildContext context, AppLocalizations l10n) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 12) / 2.5;
    return SizedBox(
      width: cardWidth,
      child: Padding(
        padding: const EdgeInsets.only(right: DesignConstants.spacingM),
        child: MorphSourceScope(
          builder: (context, setHidden) => Builder(
            builder: (sourceCtx) {
              Widget cardWidget() => SummaryCard(
                    child: InkWell(
                      onTap: () =>
                          _createMealAndOpenEditor(sourceCtx, setHidden),
                      borderRadius:
                          BorderRadius.circular(DesignConstants.borderRadiusM),
                      child: Padding(
                        padding: DesignConstants.cardPadding,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.circle_plus,
                              size: 40,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: DesignConstants.spacingS),
                            Text(l10n.mealsCreate, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  );

              return cardWidget();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, Map<String, dynamic> meal) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 12) / 2;
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: cardWidth,
      child: Padding(
        padding: const EdgeInsets.only(right: DesignConstants.spacingM),
        child: MorphSourceScope(
          builder: (context, setHidden) => Builder(
            builder: (sourceCtx) {
              Widget buildCardBody({bool showButton = true}) => SummaryCard(
                    child: Padding(
                      padding: DesignConstants.cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            meal['name'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (showButton)
                            AppButton.primary(
                              onPressed: () {},
                              label: l10n.edit,
                              tooltip: l10n.edit,
                              size: AppButtonSize.medium,
                            ),
                        ],
                      ),
                    ),
                  );

              void openEditor() {
                Navigator.of(context)
                    .push(
                      CardMorphRoute(
                        sourceContext: sourceCtx,
                        sourceBuilder: (_) => buildCardBody(showButton: true),
                        sourceBorderRadius: DesignConstants.borderRadiusM,
                        onSourceVisibilityChanged: setHidden,
                        builder: (_) => MealScreen(meal: meal),
                      ),
                    )
                    .then((_) => _refreshData());
              }

              return SummaryCard(
                child: InkWell(
                  onTap: openEditor,
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusM),
                  child: Padding(
                    padding: DesignConstants.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          meal['name'] as String,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppButton.primary(
                          onPressed: openEditor,
                          label: l10n.edit,
                          tooltip: l10n.edit,
                          size: AppButtonSize.medium,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SummaryCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: DesignConstants.spacingM,
          horizontal: DesignConstants.spacingL,
        ),
        leading: Icon(
          icon,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(LucideIcons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
