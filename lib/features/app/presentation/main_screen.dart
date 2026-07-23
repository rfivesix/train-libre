import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../data/database_helper.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../diary/presentation/dialogs/fluid_dialog_content.dart';
import '../../supplements/presentation/dialogs/log_supplement_menu.dart';
import '../../diary/presentation/dialogs/quantity_dialog_content.dart';
import '../../../generated/app_localizations.dart';
import '../../diary/domain/models/food_entry.dart';
import '../../diary/domain/models/fluid_entry.dart';
import '../../diary/domain/models/food_item.dart';
import '../../workout/domain/models/routine.dart';
import '../../supplements/domain/models/supplement.dart';
import '../../supplements/domain/models/supplement_log.dart';
import '../../workout/domain/models/workout_log.dart';
import '../../diary/presentation/add_food_navigation_result.dart';
import '../../diary/presentation/add_food_screen.dart';
import '../../diary/presentation/meal_editor_screen.dart';
import '../../diary/presentation/ai_meal_capture_screen.dart';
import '../../profile/presentation/measurements_screen.dart';
import '../../diary/presentation/diary_screen.dart';
import '../../workout/presentation/edit_routine_screen.dart';
import '../../workout/presentation/live_workout_screen.dart';
import '../../diary/presentation/nutrition_hub_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../analytics/presentation/statistics_hub_screen.dart';
import '../../workout/presentation/workout_hub_screen.dart';
import '../../../services/profile_service.dart';
import '../../steps/data/steps_aggregation_repository.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../services/theme_service.dart';
import '../../../services/base_food_language_service.dart';
import '../../workout/presentation/live_workout_view_model.dart';
import '../../../util/date_util.dart';
import '../../../util/design_constants.dart';
import 'widgets/glass_bottom_menu.dart';
import 'widgets/running_workout_overlay.dart';
import 'widgets/speed_dial_menu_overlay.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/keep_alive_page.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../navigation/app_route_observer.dart';
import '../../../services/app_tour_service.dart';
import '../../onboarding/presentation/widgets/app_tour_overlay.dart';
import '../../../services/app_review_service.dart';
import '../../../widgets/common/app_button.dart';

/// The root scaffold containing the main navigation structure.
///
/// Hosts the bottom navigation bar and manages switching between primary tabs:
/// Diary, Workout, Statistics, and Nutrition Hub. Also provides the global Speed Dial.
class MainScreen extends StatefulWidget {
  /// The optional index of the tab to be displayed initially.
  final int? initialTabIndex;
  const MainScreen({super.key, this.initialTabIndex});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin, RouteAware {
  late PageController _pageController;
  int _currentIndex = 0;
  final GlobalKey<DiaryScreenState> _tagebuchKey =
      GlobalKey<DiaryScreenState>();
  final GlobalKey<StatisticsHubScreenState> _statsKey =
      GlobalKey<StatisticsHubScreenState>();
  final GlobalKey _tourNavigationBarKey = GlobalKey();
  final GlobalKey _tourFabKey = GlobalKey();
  final GlobalKey _tourDiaryTabKey = GlobalKey();
  final GlobalKey _tourWorkoutTabKey = GlobalKey();
  final GlobalKey _tourStatisticsTabKey = GlobalKey();
  final GlobalKey _tourNutritionTabKey = GlobalKey();
  bool _isAddMenuOpen = false;
  bool _isTourActive = false;
  bool _isTourOfferVisible = false;
  bool _isRouteObserverAttached = false;
  int _tourStepIndex = 0;
  Rect? _tourTargetRect;
  late final AnimationController _menuController;
  final StepsAggregationRepository _stepsRepository =
      HealthStepsAggregationRepository();

  ThemeService get themeService =>
      Provider.of<ThemeService>(context, listen: false);

  double get kNavBarHeight => DesignConstants.bottomNavigationBarHeight;
  double kBarFabGap = 12.0;

  DateTime get _currentActiveDate {
    if (_currentIndex == 0 && _tagebuchKey.currentState != null) {
      return _tagebuchKey.currentState!.selectedDateNotifier.value.dateOnly;
    }
    return DateTime.now().dateOnly;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingAppTourEntry();
      AppReviewService.instance.checkAndRequestReview();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_isRouteObserverAttached && route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
      _isRouteObserverAttached = true;
    }
  }

  @override
  void didPush() {
    _handlePendingAppTourEntry();
  }

  @override
  void didPopNext() {
    _handlePendingAppTourEntry();
  }

  @override
  void dispose() {
    if (_isRouteObserverAttached) {
      appRouteObserver.unsubscribe(this);
    }
    _pageController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_isWarping) {
      return;
    }
    setState(() => _currentIndex = index);
    if (index == 2) {
      if (mounted && _currentIndex == 2) {
        _statsKey.currentState?.refresh();
      }
    }
  }

  final bool _isWarping = false;

  void _onNavigationTapped(int index) {
    if (!_pageController.hasClients) return;
    _pageController.jumpToPage(index);
  }

  void _toggleAddMenu() {
    HapticFeedbackService.instance.lightImpact();
    setState(() {
      _isAddMenuOpen = !_isAddMenuOpen;
      if (_isAddMenuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  void _executeAddMenuAction(String action) async {
    switch (action) {
      case 'start_workout':
        _showStartWorkoutMenu();
        break;
      case 'add_measurement':
        _showAddMeasurementMenu();
        break;
      case 'add_food':
        _handleAddFood();
        break;
      case 'add_liquid':
        await _showAddFluidMenu();
        break;
      case 'log_supplement':
        _showLogSupplementMenu();
        break;
      case 'ai_meal_capture':
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                AiMealCaptureScreen(initialDate: _currentActiveDate),
          ),
        );
        if (result == true) _refreshHomeScreen();
        break;
    }
  }

  Future<void> _refreshHomeScreen() async {
    if (_currentIndex == 0) {
      await _tagebuchKey.currentState?.syncHealthData(
        forceStepsRefresh: false, // Don't force 30-day refresh on every log
      );
    } else {
      // If we're not on the diary tab, we still want to trigger a background sync if due
      await _stepsRepository.refresh(force: false);
    }
  }

  Future<void> _refreshDiaryForActiveDate({
    bool queueIfInFlight = false,
  }) async {
    if (_currentIndex != 0) return;
    await _tagebuchKey.currentState?.syncHealthData();
  }

  Future<void> _showLogSupplementMenu() async {
    // ... (supplement selection stays the same) ...
    final l10n = AppLocalizations.of(context)!;
    final Supplement? selectedSupplement =
        await showGlassBottomMenu<Supplement>(
      context: context,
      title: l10n.logIntakeTitle,
      contentBuilder: (ctx, close) => LogSupplementMenu(close: close),
    );

    if (selectedSupplement == null || !mounted) return;

    // FIX: Get date
    final targetDate = _currentActiveDate;
    final initialTimestamp = targetDate.withCurrentTime;

    final result = await showGlassBottomMenu<(double, DateTime)?>(
      context: context,
      title: localizeSupplementName(selectedSupplement, l10n),
      contentBuilder: (ctx, close) {
        return LogSupplementDoseBody(
          supplement: selectedSupplement,
          initialTimestamp: initialTimestamp, // <--- FIX: Pass date with time
          primaryLabel: l10n.add_button,
          onCancel: close,
          onSubmit: (dose, ts) {
            close();
            Navigator.of(ctx).pop((dose, ts));
          },
        );
      },
    );

    if (result != null) {
      final newLog = SupplementLog(
        supplementId: selectedSupplement.id!,
        dose: result.$1,
        unit: selectedSupplement.unit,
        timestamp: result.$2,
      );
      try {
        await DatabaseHelper.instance.insertSupplementLog(newLog);
        HapticFeedbackService.instance.confirmationFeedback();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.error)),
          );
        }
      } finally {
        _refreshHomeScreen();
      }
    }
  }

  void _showAddMeasurementMenu() {
    final l10n = AppLocalizations.of(context)!;
    showGlassBottomMenu<bool?>(
      context: context,
      title: l10n.addMeasurement,
      contentBuilder: (ctx, close) {
        return MeasurementFormSheet(
          initialDate: _currentActiveDate,
          onSaved: () {
            close();
            _refreshHomeScreen();
          },
        );
      },
    );
  }

  Future<void> _showStartWorkoutMenu() async {
    final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);
    if (manager.isActive) {
      final choice = await showActiveWorkoutConflictDialog(context);
      if (choice == ActiveWorkoutConflictResult.resume) {
        if (!mounted) return;
        if (manager.workoutLog != null) {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => LiveWorkoutScreen(
                    workoutLog: manager.workoutLog!,
                    routine: null,
                  ),
                ),
              )
              .then((_) => _refreshHomeScreen());
        }
        return;
      } else if (choice == ActiveWorkoutConflictResult.discard) {
        final logId = manager.workoutLog?.id;
        if (logId != null) {
          await WorkoutLocalDataSource.instance.deleteWorkoutLog(logId);
        }
        await manager.clearLocalSessionState();
      } else {
        return; // Cancelled
      }
    }

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final routines = await WorkoutLocalDataSource.instance.getAllRoutines();
    if (!mounted) return;

    // Wait for the menu result.
    // The menu closes itself and returns the data.
    final result =
        await showGlassBottomMenu<({WorkoutLog log, Routine? routine})>(
      context: context,
      title: l10n.startWorkout,
      applySafeAreaBottom: false,
      contentBuilder: (ctx, close) {
        final bottomInset = MediaQuery.of(ctx).viewPadding.bottom;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        Widget glassCard({required Widget child, EdgeInsets? padding}) {
          return Material(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: padding ??
                  const EdgeInsets.symmetric(
                      horizontal: DesignConstants.spacingM,
                      vertical: DesignConstants.spacingM),
              child: child,
            ),
          );
        }

        final freeWorkoutTile = glassCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              // 1. Create workout
              final newWorkoutLog = await WorkoutLocalDataSource.instance
                  .startWorkout(routineName: l10n.freeWorkoutTitle);

              if (!ctx.mounted) return;

              // 2. Close menu and return data
              // Use Navigator.of(ctx).pop(...), not 'close()', to send data.
              Navigator.of(ctx).pop((log: newWorkoutLog, routine: null));
            },
            child: Row(
              children: [
                const Icon(LucideIcons.play),
                const SizedBox(width: DesignConstants.spacingM),
                Text(
                  l10n.startEmptyWorkoutButton,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        );

        final routinesList = ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 4 + bottomInset),
            shrinkWrap: true,
            itemCount: routines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final r = routines[i];
              return glassCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppButton.primary(
                      onPressed: () async {
                        // Show loading indicator on top of the menu.
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        final fullRoutine = await WorkoutLocalDataSource
                            .instance
                            .getRoutineById(r.id!);
                        final newWorkoutLog = await WorkoutLocalDataSource
                            .instance
                            .startWorkout(routineName: r.name);

                        if (!mounted) return;
                        Navigator.of(context).pop(); // Close loading indicator

                        if (fullRoutine != null && ctx.mounted) {
                          // Close menu and return data
                          Navigator.of(
                            ctx,
                          ).pop((log: newWorkoutLog, routine: fullRoutine));
                        }
                      },
                      label: l10n.startButton,
                      tooltip: l10n.startButton,
                      size: AppButtonSize.small,
                    ),
                    const SizedBox(width: DesignConstants.spacingM),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                            DesignConstants.borderRadiusM),
                        onTap: () {
                          // Editing navigates directly (that is ok because it is a new screen).
                          // pop+push would also be better here, but keep this for edit,
                          // because the user wants to return to the menu while editing.
                          // Close only the menu here without a result.
                          close();
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => EditRoutineScreen(routine: r),
                                ),
                              )
                              .then((_) => _refreshHomeScreen());
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(ctx)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.editRoutineSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingS),
                    Icon(
                      LucideIcons.ellipsis_vertical,
                      color: Theme.of(ctx).textTheme.bodyMedium?.color,
                    ),
                  ],
                ),
              );
            },
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            freeWorkoutTile,
            if (routines.isNotEmpty) ...[
              const SizedBox(height: DesignConstants.spacingM),
              routinesList,
            ] else ...[
              SizedBox(height: bottomInset),
            ],
          ],
        );
      },
    );

    // The actual navigation to the workout happens here,
    // after the menu is closed.
    if (!mounted) return;
    if (result != null) {
      HapticFeedbackService.instance.confirmationFeedback();
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => LiveWorkoutScreen(
                routine: result.routine,
                workoutLog: result.log,
              ),
            ),
          )
          .then((_) => _refreshHomeScreen());
    }
  }

  Future<void> _handleAddFood() async {
    final l10n = AppLocalizations.of(context)!;
    // FIX: Get date
    final targetDate = _currentActiveDate;
    final fallbackMealType =
        MealTypeTimeExtension.fromCurrentTime().toMealTypeKey;

    final routeResult = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => AddFoodScreen(
          initialDate: targetDate, // <--- Pass-through
          initialMealType: fallbackMealType, // <--- Use time-based fallback
        ),
      ),
    );

    if (!mounted) return;

    final addFoodResult = AddFoodNavigationResult.fromRouteResult(routeResult);
    if (addFoodResult.shouldRefresh) {
      _refreshHomeScreen();
      return;
    }

    final selectedFoodItem = addFoodResult.selectedFoodItem;
    if (selectedFoodItem == null) return;

    // FIX: Pass date and dynamic meal type.
    final result = await _showQuantityMenu(
      selectedFoodItem,
      initialDate: targetDate,
      initialMealType: fallbackMealType,
    );

    if (result == null || !mounted) return;

    final int quantity = result.quantity;
    final DateTime timestamp =
        result.timestamp; // This now comes correctly from the dialog.
    final String mealType = result.mealType;
    final bool isLiquid = result.isLiquid;
    final double? caffeinePer100 = result.caffeinePer100ml;

    // ... (remaining logic: insertFoodEntry, insertFluidEntry, etc. stays the same) ...
    // The timestamp here is already correct because it comes from the dialog,
    // initialized with targetDate.

    final newFoodEntry = FoodEntry(
      barcode: selectedFoodItem.barcode,
      timestamp: timestamp,
      quantityInGrams: quantity,
      mealType: mealType,
    );

    try {
      final newFoodEntryId = await DatabaseHelper.instance.insertFoodEntry(
        newFoodEntry,
      );
      HapticFeedbackService.instance.confirmationFeedback();

      if (isLiquid) {
        // ... insertFluidEntry with timestamp ...
        final newFluidEntry = FluidEntry(
          timestamp: timestamp,
          quantityInMl: quantity,
          name: selectedFoodItem.name,
          kcal: (selectedFoodItem.calories / 100 * quantity).round(),
          sugarPer100ml: result.sugarPer100ml,
          carbsPer100ml: result.sugarPer100ml,
          caffeinePer100ml: result.caffeinePer100ml,
          linkedFoodEntryId: newFoodEntryId,
        );
        await DatabaseHelper.instance.insertFluidEntry(newFluidEntry);
      }

      if (isLiquid && caffeinePer100 != null && caffeinePer100 > 0) {
        // ... logCaffeineDose ...
        final totalCaffeine = (caffeinePer100 / 100.0) * quantity;
        await _logCaffeineDose(
          totalCaffeine,
          timestamp,
          foodEntryId: newFoodEntryId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error)),
        );
      }
    } finally {
      _refreshHomeScreen();
    }
  }

  Future<void> _showAddFluidMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final key = GlobalKey<FluidDialogContentState>();
    final targetDate = _currentActiveDate; // <--- FIX

    await showGlassBottomMenu(
      context: context,
      title: l10n.add_liquid_title,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FluidDialogContent(
              key: key,
              initialTimestamp: targetDate.withCurrentTime,
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    onPressed: close,
                    label: l10n.cancel,
                    tooltip: l10n.cancel,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.primary(
                    onPressed: () async {
                      final state = key.currentState;
                      if (state == null) return;
                      final quantity = int.tryParse(state.quantityText);
                      if (quantity == null || quantity <= 0) return;

                      final name = state.nameText;
                      final sugarPer100ml = double.tryParse(
                        state.sugarText.replaceAll(',', '.'),
                      );
                      final caffeinePer100ml = double.tryParse(
                        state.caffeineText.replaceAll(',', '.'),
                      );
                      final kcal = (sugarPer100ml != null)
                          ? ((sugarPer100ml / 100) * quantity * 4).round()
                          : null;

                      final newEntry = FluidEntry(
                        timestamp: state.selectedDateTime,
                        quantityInMl: quantity,
                        name: name,
                        kcal: kcal,
                        sugarPer100ml: sugarPer100ml,
                        carbsPer100ml: sugarPer100ml,
                        caffeinePer100ml: caffeinePer100ml,
                      );

                      try {
                        final newId = await DatabaseHelper.instance
                            .insertFluidEntry(newEntry);
                        HapticFeedbackService.instance.confirmationFeedback();

                        if (caffeinePer100ml != null && caffeinePer100ml > 0) {
                          final totalCaffeine =
                              (caffeinePer100ml / 100.0) * quantity;
                          await _logCaffeineDose(
                            totalCaffeine,
                            state.selectedDateTime,
                            fluidEntryId: newId,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.error)),
                          );
                        }
                      } finally {
                        close();
                        await _refreshDiaryForActiveDate(queueIfInFlight: true);
                      }
                    },
                    label: l10n.add_button,
                    tooltip: l10n.add_button,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _logCaffeineDose(
    double doseMg,
    DateTime timestamp, {
    int? foodEntryId,
    int? fluidEntryId,
  }) async {
    if (doseMg <= 0) return;

    final supplements = await DatabaseHelper.instance.getAllSupplements();
    Supplement? caffeineSupplement;
    for (final s in supplements) {
      if ((s.code == 'caffeine') || s.name.toLowerCase() == 'caffeine') {
        caffeineSupplement = s;
        break;
      }
    }

    if (caffeineSupplement?.id == null) return;

    await DatabaseHelper.instance.insertSupplementLog(
      SupplementLog(
        supplementId: caffeineSupplement!.id!,
        dose: doseMg,
        unit: 'mg',
        timestamp: timestamp,
        sourceFoodEntryId: foodEntryId,
        sourceFluidEntryId: fluidEntryId,
      ),
    );
  }

  Future<
      ({
        int quantity,
        DateTime timestamp,
        String mealType,
        bool isLiquid,
        double? sugarPer100ml,
        double? caffeinePer100ml,
      })?> _showQuantityMenu(
    FoodItem item, {
    DateTime? initialDate, // <--- New parameter
    String? initialMealType,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();

    return showGlassBottomMenu(
      context: context,
      title: () {
        final themeService = Provider.of<ThemeService>(context, listen: false);
        final baseFoodLang = BaseFoodLanguageService.resolveLanguageCode(
          choice: themeService.baseFoodLanguage,
          context: context,
        );
        return item.source == FoodItemSource.base
            ? item.getLocalizedName(context, languageCode: baseFoodLang)
            : item.getLocalizedName(context);
      }(),
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuantityDialogContent(
              key: dialogStateKey,
              item: item,
              initialMealType: initialMealType,
              initialTimestamp: (initialDate ?? DateTime.now()).withCurrentTime,
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(null);
                    },
                    label: l10n.cancel,
                    tooltip: l10n.cancel,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.primary(
                    onPressed: () {
                      final state = dialogStateKey.currentState;
                      if (state != null) {
                        final quantity = int.tryParse(state.quantityText);
                        final sugar = double.tryParse(
                          state.sugarText.replaceAll(',', '.'),
                        );
                        final caffeine = double.tryParse(
                          state.caffeineText.replaceAll(',', '.'),
                        );
                        if (quantity != null && quantity > 0) {
                          HapticFeedbackService.instance.confirmationFeedback();
                          close();
                          Navigator.of(ctx).pop((
                            quantity: quantity,
                            timestamp: state.selectedDateTime,
                            mealType: state.selectedMealType,
                            isLiquid: state.isLiquid,
                            sugarPer100ml: sugar,
                            caffeinePer100ml: caffeine,
                          ));
                        }
                      }
                    },
                    label: l10n.add_button,
                    tooltip: l10n.add_button,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String localizeSupplementName(Supplement s, AppLocalizations l10n) {
    switch (s.code) {
      case 'caffeine':
        return l10n.supplement_caffeine;
      case 'creatine_monohydrate':
        return l10n.supplement_creatine_monohydrate;
      default:
        return s.name;
    }
  }

  // Replace this method
  GlobalAppBar _buildAppBar(
    BuildContext context,
    int index,
    AppLocalizations l10n,
  ) {
    switch (index) {
      case 1: // Workout
        return GlobalAppBar(
          title: l10n.workout,
          actions: [_profileAppBarButton(context)],
        );
      case 2: // Stats
        return GlobalAppBar(
          title: l10n.statistics,
          actions: [_profileAppBarButton(context)],
        );
      case 3: // Nutrition Hub
        return GlobalAppBar(
          title: l10n.nutritionHubTitle,
          actions: [_profileAppBarButton(context)],
        );
      case 0: // Diary
      default:
        return GlobalAppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          titleWidget: DiaryAppBar(
            diaryKey: _tagebuchKey,
          ),
          actions: [
            IconButton(
              icon: Icon(
                DesignConstants.adaptiveShareIcon,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              tooltip: l10n.share,
              onPressed: () {
                _tagebuchKey.currentState?.shareAsText();
              },
            ),
            _profileAppBarButton(context),
          ],
        );
    }
  }

  List<Map<String, dynamic>> _getSpeedDialActions(AppLocalizations l10n) {
    return [
      {
        'icon': LucideIcons.glass_water,
        'label': l10n.addLiquidOption,
        'action': 'add_liquid',
      },
      {
        'icon': LucideIcons.utensils,
        'label': l10n.addFoodOption,
        'action': 'add_food',
      },
      {
        'icon': LucideIcons.ruler,
        'label': l10n.addMeasurement,
        'action': 'add_measurement',
      },
      {
        'icon': LucideIcons.dumbbell,
        'label': l10n.startWorkout,
        'action': 'start_workout',
      },
      {
        'icon': LucideIcons.pill,
        'label': l10n.logIntakeTitle,
        'action': 'log_supplement',
      },
      if (themeService.isAiEnabled)
        {
          'icon': LucideIcons.sparkles,
          'label': l10n.aiMealCapture,
          'action': 'ai_meal_capture',
          'gradient': true,
        },
    ];
  }

  List<_AppTourStep> _buildAppTourSteps(AppLocalizations l10n) {
    return [
      _AppTourStep(
        anchorKey: _tourNavigationBarKey,
        tabIndex: 0,
        title: l10n.appTourStepNavigationTitle,
        description: l10n.appTourStepNavigationBody,
      ),
      _AppTourStep(
        anchorKey: _tourFabKey,
        tabIndex: 0,
        title: l10n.appTourStepQuickActionsTitle,
        description: l10n.appTourStepQuickActionsBody,
      ),
      _AppTourStep(
        anchorKey: _tourDiaryTabKey,
        tabIndex: 0,
        title: l10n.appTourStepDiaryTitle,
        description: l10n.appTourStepDiaryBody,
      ),
      _AppTourStep(
        anchorKey: _tourWorkoutTabKey,
        tabIndex: 1,
        title: l10n.appTourStepWorkoutTitle,
        description: l10n.appTourStepWorkoutBody,
      ),
      _AppTourStep(
        anchorKey: _tourNutritionTabKey,
        tabIndex: 3,
        title: l10n.appTourStepNutritionTitle,
        description: l10n.appTourStepNutritionBody,
      ),
      _AppTourStep(
        anchorKey: _tourStatisticsTabKey,
        tabIndex: 2,
        title: l10n.appTourStepStatisticsTitle,
        description: l10n.appTourStepStatisticsBody,
      ),
    ];
  }

  Rect? _rectForKey(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return null;
    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  Future<void> _handlePendingAppTourEntry() async {
    if (!mounted || _isTourActive || _isTourOfferVisible) return;
    final entry = await AppTourService.instance.consumePendingEntryPoint();
    if (!mounted || entry == null) return;

    switch (entry) {
      case AppTourEntryPoint.postOnboardingOffer:
        await _startAppTour();
        break;
      case AppTourEntryPoint.settingsRestart:
        await _startAppTour();
        break;
    }
  }

  Future<void> _startAppTour() async {
    if (!mounted) return;
    await AppTourService.instance.markOfferShown();
    setState(() {
      _isTourActive = true;
      _tourStepIndex = 0;
      _tourTargetRect = null;
      _isAddMenuOpen = false;
    });
    _menuController.reverse();
    await _showAppTourStep(0);
  }

  Future<void> _showAppTourStep(int index) async {
    if (!mounted || !_isTourActive) return;
    final l10n = AppLocalizations.of(context)!;
    final steps = _buildAppTourSteps(l10n);
    if (index < 0 || index >= steps.length) return;
    final step = steps[index];

    if (_currentIndex != step.tabIndex) {
      _onNavigationTapped(step.tabIndex);
    }

    setState(() {
      _tourStepIndex = index;
      _tourTargetRect = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isTourActive) return;
      final targetRect =
          _rectForKey(step.anchorKey) ?? _rectForKey(_tourNavigationBarKey);
      setState(() => _tourTargetRect = targetRect);
    });
  }

  Future<void> _nextTourStep() async {
    if (!mounted || !_isTourActive) return;
    final l10n = AppLocalizations.of(context)!;
    final steps = _buildAppTourSteps(l10n);
    final nextIndex = _tourStepIndex + 1;
    if (nextIndex >= steps.length) {
      await _completeAppTour();
      return;
    }
    await _showAppTourStep(nextIndex);
  }

  Future<void> _skipAppTour() async {
    if (!mounted || !_isTourActive) return;
    setState(() {
      _isTourActive = false;
      _tourTargetRect = null;
      _tourStepIndex = 0;
    });
    await AppTourService.instance.markSkipped();
  }

  Future<void> _completeAppTour() async {
    if (!mounted || !_isTourActive) return;
    setState(() {
      _isTourActive = false;
      _tourTargetRect = null;
      _tourStepIndex = 0;
    });
    await AppTourService.instance.markCompleted();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final l10n = AppLocalizations.of(context)!;
    final appTourSteps = _buildAppTourSteps(l10n);
    final activeTourStep = (_isTourActive &&
            _tourStepIndex >= 0 &&
            _tourStepIndex < appTourSteps.length)
        ? appTourSteps[_tourStepIndex]
        : null;

    final manager = context.watch<LiveWorkoutViewModel>();
    final bool isWorkoutRunning = manager.isActive;
    final String elapsed = _formatDuration(manager.elapsedDuration);

    // Animation parameters
    // const basePad = 120.0; // Unused locally
    // final runningPad = manager.isActive ? 68.0 : 0.0; // Unused locally

    // Because we use a completely custom floating Bottom Navigation Bar and Workout Bar,
    // the system Scaffold does not automatically inset floating Snackbars.
    // By providing a transparent dummy bottomNavigationBar, ScaffoldMessenger
    // will natively push up all Snackbars (including those from settings).
    final double dynamicBottomPadding = isWorkoutRunning
        ? (DesignConstants.bottomNavigationBarHeight +
            DesignConstants.workoutOverlayHeight +
            48.0)
        : (DesignConstants.bottomNavigationBarHeight + 48.0);

    return Stack(
      children: [
        RepaintBoundary(
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            appBar: _buildAppBar(context, _currentIndex, l10n),
            bottomNavigationBar: SizedBox(height: dynamicBottomPadding),
            body: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: <Widget>[
                KeepAlivePage(
                  storageKey: const PageStorageKey('tab_tagebuch'),
                  child: DiaryScreen(contentKey: _tagebuchKey),
                ),
                const KeepAlivePage(
                  storageKey: PageStorageKey('tab_workout'),
                  child: WorkoutHubScreen(),
                ),
                KeepAlivePage(
                  storageKey: const PageStorageKey('tab_stats'),
                  child: StatisticsHubScreen(key: _statsKey),
                ),
                const KeepAlivePage(
                  storageKey: PageStorageKey('tab_nutrition'),
                  child: NutritionHubScreen(),
                ),
              ],
            ),
          ),
        ),
        // Laufendes Workout Overlay
        if (isWorkoutRunning)
          Positioned(
            bottom: kNavBarHeight +
                32, // pill clears nav bar top (96px) with 8px gap from internal margin
            left: 16,
            right: 16,
            child: RepaintBoundary(
              child: RunningWorkoutOverlay(
                elapsedDuration: elapsed,
                onContinue: () {
                  final log = context.read<LiveWorkoutViewModel>().workoutLog;
                  if (log != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LiveWorkoutScreen(workoutLog: log, routine: null),
                      ),
                    );
                  }
                },
                onDiscard: () async {
                  final l10n = AppLocalizations.of(context)!;
                  final wsm = context.read<LiveWorkoutViewModel>();
                  final logId = wsm.workoutLog?.id;

                  // FIX: showDeleteConfirmation instead of showDialog.
                  final confirmed = await showDeleteConfirmation(
                    context,
                    title: l10n.discard_button, // "Discard"
                    content:
                        l10n.deleteWorkoutConfirmContent, // "Really delete?"
                    confirmLabel: l10n.discard_button, // Red button: "Discard"
                  );

                  if (confirmed) {
                    if (logId != null) {
                      await WorkoutLocalDataSource.instance.deleteWorkoutLog(
                        logId,
                      );
                    }
                    await wsm.finishWorkout();
                  }
                },
              ),
            ),
          ),
        // Bottom Nav Bar & FAB
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: RepaintBoundary(
            child: KeyedSubtree(
              key: _tourNavigationBarKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double horizontalPadding = 0.0;
                  final double verticalPadding = 20.0;
                  final double spacing = 8.0;
                  final double extraButtonSize = DesignConstants.fabSize;
                  final double maxTabW = constraints.maxWidth -
                      (horizontalPadding * 2) -
                      (extraButtonSize + spacing);

                  return Stack(
                    children: [
                      // Shadow layers underneath the glass tabs & FAB to provide physical depth matching standard style
                      IgnorePointer(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: verticalPadding,
                          ),
                          child: Row(
                            children: [
                              ClipPath(
                                clipper: ShadowOuterClipper(
                                    borderRadius: DesignConstants
                                            .bottomNavigationBarHeight /
                                        2),
                                child: Container(
                                  width: maxTabW,
                                  height: DesignConstants
                                      .bottomNavigationBarHeight, // Match barHeight
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        DesignConstants
                                                .bottomNavigationBarHeight /
                                            2),
                                    boxShadow: DesignConstants.glassShadow,
                                  ),
                                ),
                              ),
                              SizedBox(width: spacing),
                              ClipPath(
                                clipper: ShadowOuterClipper(
                                    borderRadius: DesignConstants.fabSize / 2,
                                    isOval: true),
                                child: Container(
                                  width: extraButtonSize,
                                  height: DesignConstants
                                      .fabSize, // Match barHeight
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        DesignConstants.fabSize / 2),
                                    boxShadow: DesignConstants.glassShadow,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Material(
                        type: MaterialType.transparency,
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            letterSpacing: -0.2,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: verticalPadding,
                            ),
                            child: GlassAdaptiveScope(
                              maxQuality: DesignConstants.defaultGlassQuality,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GlassTabBar.bottom(
                                      selectedIndex: _currentIndex,
                                      onTabSelected: _onNavigationTapped,
                                      barHeight: DesignConstants
                                          .bottomNavigationBarHeight,
                                      barBorderRadius: DesignConstants
                                              .bottomNavigationBarHeight /
                                          2,
                                      tabWidth: null,
                                      horizontalPadding: 0.0,
                                      verticalPadding: 0.0,
                                      quality: DesignConstants.defaultGlassQuality,
                                      indicatorExpansion:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                      selectedIconColor:
                                          theme.colorScheme.primary,
                                      unselectedIconColor:
                                          isDark ? Colors.white : Colors.black,
                                      indicatorColor:
                                          (isDark ? Colors.white : Colors.black)
                                              .withValues(alpha: 0.15),
                                      settings:
                                          DesignConstants.liquidGlassSettings(
                                              isDark),
                                      tabs: [
                                        GlassTab(
                                          label: l10n.diary,
                                          icon: Icon(
                                            LucideIcons.notebook,
                                            key: _tourDiaryTabKey,
                                          ),
                                          activeIcon:
                                              const Icon(LucideIcons.notebook),
                                        ),
                                        GlassTab(
                                          label: l10n.workout,
                                          icon: Icon(
                                            LucideIcons.dumbbell,
                                            key: _tourWorkoutTabKey,
                                          ),
                                          activeIcon:
                                              const Icon(LucideIcons.dumbbell),
                                        ),
                                        GlassTab(
                                          label: l10n.statistics,
                                          icon: Icon(
                                            LucideIcons.chart_no_axes_column,
                                            key: _tourStatisticsTabKey,
                                          ),
                                          activeIcon: const Icon(
                                              LucideIcons.chart_no_axes_column),
                                        ),
                                        GlassTab(
                                          label: l10n.nutrition,
                                          icon: Icon(
                                            LucideIcons.utensils,
                                            key: _tourNutritionTabKey,
                                          ),
                                          activeIcon:
                                              const Icon(LucideIcons.utensils),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: spacing),
                                  AnimatedBuilder(
                                    animation: _menuController,
                                    builder: (context, child) {
                                      final double v = _menuController.value;
                                      return Transform.scale(
                                        scale: 1.0 - v,
                                        child: Opacity(
                                          opacity: (1.0 - v).clamp(0.0, 1.0),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: AdaptiveGlass(
                                      shape: const LiquidOval(),
                                      settings:
                                          DesignConstants.liquidGlassSettings(
                                              isDark),
                                      quality: DesignConstants.defaultGlassQuality,
                                      useOwnLayer: true,
                                      isInteractive:
                                          true, //false, // Force blur in minimal quality
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: _toggleAddMenu,
                                          child: SizedBox(
                                            width: extraButtonSize,
                                            height: DesignConstants.fabSize,
                                            child: Center(
                                              child: Icon(
                                                LucideIcons.plus,
                                                key: _tourFabKey,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        // Speed Dial Menu Animation
        SpeedDialMenuOverlay(
          animation: _menuController,
          actions: _getSpeedDialActions(l10n),
          onClose: () {
            setState(() {
              _isAddMenuOpen = false;
              _menuController.reverse();
            });
          },
          onActionTap: (actionKey) {
            setState(() {
              _isAddMenuOpen = false;
              _menuController.reverse();
            });
            _executeAddMenuAction(actionKey);
          },
        ),
        if (_isTourActive && activeTourStep != null)
          AppTourOverlay(
            targetRect: _tourTargetRect,
            title: activeTourStep.title,
            description: activeTourStep.description,
            progressLabel: '${_tourStepIndex + 1}/${appTourSteps.length}',
            nextLabel: _tourStepIndex == appTourSteps.length - 1
                ? l10n.appTourDone
                : l10n.appTourNext,
            skipLabel: l10n.appTourSkip,
            onNext: _nextTourStep,
            onSkip: _skipAppTour,
          ),
      ],
    );
  }

  Widget _profileAppBarButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        right: DesignConstants.screenPaddingHorizontal,
      ),
      child: Tooltip(
        message: AppLocalizations.of(context)!.profile,
        child: Semantics(
          label: AppLocalizations.of(context)!.profile,
          button: true,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
              // Refresh diary data when returning from profile/settings
              _refreshHomeScreen();
            },
            child: Consumer<ProfileService>(
              builder: (context, profileService, _) {
                final hasImage = profileService.profileImagePath != null;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final bgCircleColor = isDark ? Colors.white : Colors.black;
                final initialTextColor = isDark ? Colors.black : Colors.white;
                final initial = profileService.initialLetter;

                return Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasImage ? Colors.transparent : bgCircleColor,
                    ),
                    child: hasImage
                        ? CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.transparent,
                            backgroundImage: FileImage(
                              File(profileService.profileImagePath!),
                            ),
                          )
                        : Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: initialTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),

          ),
        ),
      ),
    );
  }
}

class _AppTourStep {
  final GlobalKey anchorKey;
  final int tabIndex;
  final String title;
  final String description;

  const _AppTourStep({
    required this.anchorKey,
    required this.tabIndex,
    required this.title,
    required this.description,
  });
}
