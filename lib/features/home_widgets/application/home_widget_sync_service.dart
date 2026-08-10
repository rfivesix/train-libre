import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/infrastructure/user_preferences_repository.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/unit_service.dart';
import '../../diary/domain/calculate_daily_nutrition_use_case.dart';
import '../../diary/domain/models/food_item.dart';
import '../../diary/domain/repositories/diary_repository.dart';
import '../../supplements/domain/repositories/supplement_repository.dart';
import '../data/home_widget_channel.dart';
import '../domain/build_home_widget_snapshot.dart';

/// Keeps the iOS Home Screen widgets in sync with the diary.
///
/// ## Why this recomputes instead of reusing `DiaryViewModel`
///
/// `DiaryViewModel.dailyNutrition` follows `selectedDate`, which is whatever day
/// the user happens to be browsing. Publishing that would push a historical day
/// to the Home Screen the moment somebody scrolls back through their diary. This
/// service therefore always resolves the *logical today* itself and reads that
/// day, independent of any UI state.
///
/// ## Why there is no polling
///
/// Nutrition data cannot change while the app is closed — HealthKit nutrition
/// and hydration are write-only in this app, only steps/sleep/heart rate are
/// ever read back. So a snapshot written on every mutation is not an
/// approximation, it is exact, and a periodic refresh would only spend the
/// widget's limited daily reload budget on data that provably did not change.
class HomeWidgetSyncService {
  final IDiaryRepository _diaryRepo;
  final SupplementRepository _supplementRepo;
  final UnitService _unitService;
  final HomeWidgetChannel _channel;
  final UserPreferencesRepository _prefsRepo =
      UserPreferencesRepository.instance;
  final CalculateDailyNutritionUseCase _calculateUseCase =
      CalculateDailyNutritionUseCase();

  HomeWidgetSyncService({
    required IDiaryRepository diaryRepo,
    required SupplementRepository supplementRepo,
    required UnitService unitService,
    HomeWidgetChannel channel = const HomeWidgetChannel(),
  })  : _diaryRepo = diaryRepo,
        _supplementRepo = supplementRepo,
        _unitService = unitService,
        _channel = channel;

  Timer? _debounce;
  bool _isRunning = false;
  bool _needsReRun = false;

  /// Coalesces the burst of calls a single user action produces (insert, then
  /// the diary reload, then the health sync) into one snapshot write.
  void scheduleRefresh({
    required AppLocalizations l10n,
    required bool isAiEnabled,
  }) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(refresh(l10n: l10n, isAiEnabled: isAiEnabled));
    });
  }

  /// Rebuilds the snapshot for the logical today and hands it to iOS.
  ///
  /// Never throws: a failure here must not take down whatever diary operation
  /// triggered it.
  Future<void> refresh({
    required AppLocalizations l10n,
    required bool isAiEnabled,
  }) async {
    if (!await _channel.isSupported()) return;

    if (_isRunning) {
      _needsReRun = true;
      return;
    }
    _isRunning = true;
    _needsReRun = false;

    try {
      final now = DateTime.now();
      final day = _logicalToday(now);

      final goals = await _diaryRepo.watchGoalsForDate(day).first;
      final foodEntries = await _diaryRepo.watchEntriesForDate(day).first;
      final fluidEntries = await _diaryRepo.watchFluidEntriesForDate(day).first;

      final archiveIds = <int>{};
      final barcodes = <String>{};
      for (final entry in foodEntries) {
        if (entry.archiveLocalId != null) {
          archiveIds.add(entry.archiveLocalId!);
        } else {
          barcodes.add(entry.barcode);
        }
      }

      final archiveProducts = archiveIds.isEmpty
          ? <int, FoodItem>{}
          : await _diaryRepo.getProductsByArchiveIds(archiveIds.toList());

      final legacyProducts = <String, FoodItem>{};
      if (barcodes.isNotEmpty) {
        for (final p in await _diaryRepo.getProductsByBarcodes(
          barcodes.toList(),
        )) {
          legacyProducts[p.barcode] = p;
        }
      }

      final state = _calculateUseCase.execute(
        goals: goals,
        targetSugar: await _prefsRepo.getTargetSugar() ?? 50,
        targetFiber: await _prefsRepo.getTargetFiber() ?? 30,
        targetSalt: await _prefsRepo.getTargetSalt() ?? 6,
        targetCaffeine: await _prefsRepo.getTargetCaffeine() ?? 400,
        foodEntries: foodEntries,
        fluidEntries: fluidEntries,
        foodProductsByBarcode: legacyProducts,
        foodProductsByArchiveLocalId: archiveProducts,
        // Workout logs feed only `DailyNutritionState.workoutSummary`, never
        // `summary` — and the widget renders `summary`. Everything that *does*
        // feed `summary` is loaded above; supplements are included because they
        // populate `summary.caffeine`.
        workoutLogs: const [],
        supplementsForDate:
            await _supplementRepo.watchSupplementsForDate(day).first,
        allSupplements: await _supplementRepo.getAllSupplements(),
        todaysSupplementLogs:
            await _supplementRepo.watchSupplementLogsForDate(day).first,
      );

      final snapshot = buildHomeWidgetSnapshot(
        nutrition: state.summary,
        extraNutrient: await _prefsRepo.getOverviewExtraNutrient(),
        l10n: l10n,
        unitService: _unitService,
        isAiEnabled: isAiEnabled,
        now: now,
      );

      await _channel.writeSnapshot(snapshot);
    } catch (e, st) {
      debugPrint('HomeWidgetSyncService.refresh failed: $e\n$st');
    } finally {
      _isRunning = false;
      if (_needsReRun) {
        _needsReRun = false;
        unawaited(refresh(l10n: l10n, isAiEnabled: isAiEnabled));
      }
    }
  }

  Future<void> clear() => _channel.clearSnapshot();

  void dispose() {
    _debounce?.cancel();
  }

  /// Same rule as `resolveDiaryInitialDate`, applied to date-only.
  DateTime _logicalToday(DateTime now) {
    final base = now.hour < 3 ? now.subtract(const Duration(days: 1)) : now;
    return DateTime(base.year, base.month, base.day);
  }
}
