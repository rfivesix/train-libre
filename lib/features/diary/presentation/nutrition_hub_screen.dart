// lib/features/diary/presentation/nutrition_hub_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart' as db;
import '../../../generated/app_localizations.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/card_morph_route.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/summary_card.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../analytics/domain/models/chart_data_point.dart';
import '../../nutrition_recommendation/data/recommendation_service.dart';
import '../../nutrition_recommendation/presentation/nutrition_recommendation_card.dart';
import '../../statistics/data/macro_analytics_data_adapter.dart';
import '../../profile/data/goal_repository_impl.dart';
import '../../profile/domain/models/goal_model.dart';
import '../../profile/domain/models/goal_progress.dart';
import '../../profile/domain/repositories/goal_repository.dart';
import '../../profile/domain/services/goal_notification_orchestrator.dart';
import '../../profile/domain/repositories/profile_repository.dart';
import '../../profile/presentation/goal_detail_screen.dart';
import '../../profile/presentation/widgets/active_goal_dashboard_widget.dart';
import '../../profile/presentation/widgets/adaptive_review_card.dart';
import '../../supplements/presentation/supplement_hub_screen.dart';
import '../data/sources/product_local_data_source.dart';
import '../domain/models/food_entry.dart';
import '../domain/models/food_item.dart';
import '../domain/models/meal_entry.dart';
import '../../supplements/domain/models/supplement.dart';
import '../../supplements/domain/models/supplement_log.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../sharing/share_service.dart';
import 'meal_screen.dart';
import 'widgets/confirm_log_meal_bottom_sheet.dart';

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
  final Map<int, Future<List<Map<String, dynamic>>>> _mealItemsCache = {};

  IProfileRepository? _profileRepo;

  @override
  void initState() {
    super.initState();
    _goalRepository = widget.goalRepository ?? GoalRepositoryImpl();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileRepo ??= context.read<IProfileRepository>();
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
      _mealItemsCache.clear();
      _hubDataFuture = _loadHubData(refreshIfDue: true);
    });
  }

  Future<List<Map<String, dynamic>>> _mealItems(int mealId) =>
      _mealItemsCache.putIfAbsent(
        mealId,
        () async => List<Map<String, dynamic>>.from(
          await DatabaseHelper.instance.getMealItems(mealId),
        ),
      );

  Future<Map<String, FoodItem>> _productsForMealItems(
    List<Map<String, dynamic>> items,
  ) async {
    final barcodes = items
        .map((item) => item['barcode'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final products =
        await ProductLocalDataSource.instance.getProductsByBarcodes(barcodes);
    return {for (final product in products) product.barcode: product};
  }

  Future<void> _logRecipe(Map<String, dynamic> meal) async {
    final l10n = AppLocalizations.of(context)!;
    final mealId = meal['id'] as int;
    final items = await _mealItems(mealId);
    if (items.isEmpty || !mounted) return;

    final products = await _productsForMealItems(items);
    if (!mounted) return;

    await showGlassBottomMenu<bool>(
      context: context,
      contentBuilder: (sheetContext, close) => ConfirmLogMealBottomSheet(
        mealName: meal['name'] as String,
        rawItems: items,
        products: products,
        recipeCookedWeightInGrams:
            (meal['cooked_weight_in_grams'] as num?)?.toInt(),
        recipeServingCount: (meal['serving_count'] as num?)?.toInt(),
        initialDate: DateTime.now(),
        initialMealType: 'mealtypeBreakfast',
        onSave: (date, mealType, quantities) async {
          final foodEntries = items.map((item) {
            final barcode = item['barcode'] as String;
            return FoodEntry(
              barcode: barcode,
              timestamp: date,
              quantityInGrams: quantities[item['id']?.toString() ?? barcode] ??
                  (item['quantity_in_grams'] as int),
              mealType: mealType,
            );
          }).toList();
          final foodEntryIds =
              await DatabaseHelper.instance.insertMealEntryWithFoodEntries(
                  MealEntry(
                    id: const Uuid().v4(),
                    title: meal['name'] as String,
                    consumedAt: date,
                    mealType: mealType,
                    source: 'template',
                  ),
                  foodEntries);
          for (var i = 0; i < foodEntries.length; i++) {
            final barcode = foodEntries[i].barcode;
            final quantity = foodEntries[i].quantityInGrams;
            final product = products[barcode];
            final caffeinePer100ml = product?.effectiveCaffeinePer100ml;
            if (product?.isFluidOrLiquid == true &&
                caffeinePer100ml != null &&
                caffeinePer100ml > 0) {
              await _logCaffeineDose(
                caffeinePer100ml * (quantity / 100.0),
                date,
                foodEntryId: foodEntryIds[i],
              );
            }
          }
          if (!mounted) return;
          HapticFeedbackService.instance.confirmationFeedback();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.mealAddedToDiarySuccess)),
          );
        },
      ),
    );
  }

  Future<void> _logCaffeineDose(
    double doseMg,
    DateTime timestamp, {
    required int foodEntryId,
  }) async {
    if (doseMg <= 0) return;
    final supplements = await DatabaseHelper.instance.getAllSupplements();
    final caffeine = supplements.firstWhere(
      (supplement) => supplement.isCaffeine,
      orElse: () => Supplement(
        name: 'Caffeine',
        defaultDose: 100,
        unit: 'mg',
        dailyLimit: 400,
        code: 'caffeine',
        isBuiltin: true,
      ),
    );
    final caffeineId =
        caffeine.id ?? await DatabaseHelper.instance.insertSupplement(caffeine);
    await DatabaseHelper.instance.insertSupplementLog(
      SupplementLog(
        supplementId: caffeineId,
        dose: doseMg,
        unit: 'mg',
        timestamp: timestamp,
        sourceFoodEntryId: foodEntryId,
      ),
    );
  }

  Future<Map<String, dynamic>> _loadHubData({bool refreshIfDue = false}) async {
    final today = DateTime.now();
    final goals = await DatabaseHelper.instance.getGoalsForDate(today);
    final meals = await DatabaseHelper.instance.getMeals();

    await GoalNotificationOrchestrator(goalRepository: _goalRepository)
        .synchronize();
    final activeGoal = await _goalRepository.getActiveGoal();
    GoalProgress? activeProgress;
    GoalReviewRecord? pendingReview;
    List<ChartDataPoint> chartPoints = [];
    if (activeGoal != null) {
      activeProgress = await _goalRepository.getGoalProgress(activeGoal);
      pendingReview = await _goalRepository.getPendingReview(activeGoal.id);

      final profileRepo = _profileRepo;
      final startDate = activeGoal.startDate.subtract(const Duration(days: 1));
      final endDate = DateTime.now().add(const Duration(days: 1));
      if (profileRepo != null) {
        try {
          chartPoints = await profileRepo.getChartDataForTypeAndRange(
            'weight',
            DateTimeRange(start: startDate, end: endDate),
          );
        } catch (_) {
          chartPoints = [];
        }
      }

      final baseline = activeProgress?.baselineValue;
      if (baseline != null) {
        if (chartPoints.isEmpty) {
          chartPoints = [
            ChartDataPoint(
              date: activeGoal.startDate,
              value: baseline,
            ),
          ];
        } else if (chartPoints.first.date.isAfter(activeGoal.startDate)) {
          chartPoints.insert(
            0,
            ChartDataPoint(
              date: activeGoal.startDate,
              value: baseline,
            ),
          );
        }
      }
    }

    final recommendationState =
        await _recommendationService.loadState(refreshIfDue: refreshIfDue);
    final recentDailyIntakes =
        await const MacroAnalyticsDataAdapter().fetchRecentDays(days: 7);

    return {
      'meals': meals,
      'dailyGoals': goals,
      'activeGoal': activeGoal,
      'activeProgress': activeProgress,
      'pendingReview': pendingReview,
      'chartPoints': chartPoints,
      'recommendationState': recommendationState,
      'recentDailyIntakes': recentDailyIntakes,
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

  Future<void> _createMealAndOpenEditor() async {
    final l10n = AppLocalizations.of(context)!;
    final defaultName = l10n.mealNameLabel;
    final newMealId = await DatabaseHelper.instance.insertMeal(
      name: defaultName,
      notes: '',
    );
    final meal = {'id': newMealId, 'name': defaultName, 'notes': ''};

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealScreen(meal: meal, startInEdit: true),
      ),
    );

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
          final chartPoints =
              (data['chartPoints'] as List<ChartDataPoint>?) ?? const [];
          final pendingReview = data['pendingReview'] as GoalReviewRecord?;
          final recommendationState = data['recommendationState']
              as AdaptiveNutritionRecommendationState;

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: finalPadding,
              children: [
                // Modul 1: Ziel- & Fortschrittskarte (Vollständiges Goal-Dashboard)
                ActiveGoalDashboardWidget(
                  goal: activeGoal,
                  progress: activeProgress,
                  chartPoints: chartPoints,
                  onRefresh: _refreshData,
                  onBaselineRecorded: () async {
                    await _goalRepository
                        .captureMissingBaseline(activeGoal!.id);
                    await _refreshData();
                  },
                  bleedChartToEdges: true,
                  onHeaderTap: activeGoal != null
                      ? () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  GoalDetailScreen(goalId: activeGoal.id),
                            ),
                          );
                          _refreshData();
                        }
                      : null,
                ),
                const SizedBox(height: DesignConstants.spacingL),

                // Modul 2: Wöchentlicher Review (falls fällig oder ausstehend)
                if (pendingReview != null) ...[
                  AdaptiveReviewCard(
                    activeGoal: activeGoal,
                    pendingReview: pendingReview,
                    isRecommendationDue:
                        recommendationState.isAdaptiveRecommendationDueNow,
                    nextDueAt:
                        recommendationState.nextAdaptiveRecommendationDueAt,
                    onRefresh: _refreshData,
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                ],

                // A pending review is the single primary action. It already
                // contains the recommendation, so the standalone card returns
                // after the review has been completed.
                if (pendingReview == null) ...[
                  AppSectionHeader(
                    title: l10n.adaptiveRecommendationCardTitle,
                  ),
                  _buildGoalsAndRecommendationCard(
                    context,
                    recommendationState,
                    data['dailyGoals'] as db.DailyGoalsHistoryData?,
                    data['recentDailyIntakes'] as List<DailyMacroIntake>?,
                  ),
                  const SizedBox(height: DesignConstants.spacingXL),
                ],

                // Supplements are a first-class nutrition workflow, not a
                // utility hidden after recipes or exploration tools.
                AppSectionHeader(title: l10n.supplementTrackerTitle),
                Builder(
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
                const SizedBox(height: DesignConstants.spacingXL),

                // Recipes mirror workout routines: one clear creation action,
                // followed by the complete saved collection in a vertical list.
                AppSectionHeader(title: l10n.nutritionSectionMyMeals),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    label: l10n.mealsCreate,
                    onPressed: _createMealAndOpenEditor,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingM),
                if (meals.isEmpty)
                  SummaryCard(
                    child: Text(
                      l10n.emptyStateNutritionRecipesCallout,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            height: 1.3,
                          ),
                    ),
                  )
                else
                  for (final meal in meals) ...[
                    _buildRecipeCard(context, meal),
                    const SizedBox(height: DesignConstants.spacingS),
                  ],
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
    db.DailyGoalsHistoryData? currentGoals,
    List<DailyMacroIntake>? recentDailyIntakes,
  ) {
    return NutritionRecommendationCard(
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
      currentCalories: currentGoals?.targetCalories,
      currentProteinGrams: currentGoals?.targetProtein,
      currentCarbsGrams: currentGoals?.targetCarbs,
      currentFatGrams: currentGoals?.targetFat,
      recentDailyIntakes: recentDailyIntakes,
    );
  }

  Widget _buildRecipeCard(BuildContext context, Map<String, dynamic> meal) {
    final l10n = AppLocalizations.of(context)!;
    return MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (sourceContext) {
          late final Widget card;
          Future<void> openRecipe({bool edit = false}) async {
            await Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: sourceContext,
                sourceBuilder: (_) => card,
                onSourceVisibilityChanged: setHidden,
                builder: (_) => MealScreen(meal: meal, startInEdit: edit),
              ),
            );
            await _refreshData();
          }

          card = SummaryCard(
            onTap: openRecipe,
            child: Padding(
              padding: const EdgeInsets.all(DesignConstants.spacingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meal['name'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      PlatformAdaptivePopupMenu<String>(
                        icon: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(LucideIcons.ellipsis),
                        ),
                        items: [
                          PlatformAdaptivePopupMenuItem(
                              value: 'share',
                              label: l10n.share,
                              icon: DesignConstants.adaptiveShareIcon),
                          PlatformAdaptivePopupMenuItem(
                              value: 'edit',
                              label: l10n.mealsEdit,
                              icon: LucideIcons.pencil),
                          PlatformAdaptivePopupMenuItem(
                              value: 'duplicate',
                              label: l10n.mealDuplicate,
                              icon: LucideIcons.copy),
                          PlatformAdaptivePopupMenuItem(
                              value: 'delete',
                              label: l10n.mealsDelete,
                              icon: LucideIcons.trash,
                              isDestructive: true),
                        ],
                        onSelected: (action) async {
                          switch (action) {
                            case 'share':
                              await const ShareService().showRecipeShareSheet(
                                  context: context, meal: meal);
                              break;
                            case 'edit':
                              await openRecipe(edit: true);
                              break;
                            case 'duplicate':
                              await DatabaseHelper.instance.duplicateMeal(
                                  meal['id'] as int,
                                  copySuffix: l10n.mealCopySuffix);
                              await _refreshData();
                              break;
                            case 'delete':
                              await _deleteRecipe(meal, l10n);
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      label: l10n.mealsAddToDiary,
                      onPressed: () => _logRecipe(meal),
                    ),
                  ),
                ],
              ),
            ),
          );
          return card;
        },
      ),
    );
  }

  Future<void> _deleteRecipe(
    Map<String, dynamic> meal,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: l10n.mealDeleteConfirmTitle,
      content: l10n.mealDeleteConfirmBody(meal['name'] as String),
    );
    if (!confirmed) return;
    await DatabaseHelper.instance.deleteMeal(meal['id'] as int);
    await _refreshData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mealDeleted)),
      );
    }
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
