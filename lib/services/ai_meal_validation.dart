import 'dart:convert';

import '../features/diary/data/sources/product_local_data_source.dart';
import '../features/diary/domain/models/food_item.dart';
import 'ai_meal_context.dart';
import 'ai_repair_candidate.dart';

part 'ai/validation/validation_models.dart';
part 'ai/validation/matching_logic.dart';
part 'ai/validation/rules_logic.dart';

class AiMealValidationEngine {
  late final AiFoodMatchLoader _matchLoader;
  final Map<String, Future<List<FoodItem>>> _matchCache = {};
  bool _includeOffCatalog = false;
  final Set<String> _offCatalogItemKeys = {};

  AiMealValidationEngine({
    AiFoodMatchLoader? matchLoader,
  }) {
    final session = ProductLocalDataSource.instance.createAiSearchSession();
    _matchLoader = matchLoader ??
        (item) => defaultMatchLoader(
              item,
              aiSession: session,
              includeOff: _includeOffCatalog ||
                  _offCatalogItemKeys.contains(_itemCacheKey(item)),
            );
  }

  String _itemCacheKey(AiMealCandidateItem item) => jsonEncode([
        item.name,
        item.matchedBarcode,
        item.catalogSearchTerm,
        item.searchTerms,
      ]);

  /// Tries Open Food Facts only for items whose base-food match needs repair.
  void enableOffCatalogFallbackFor(Iterable<AiMealCandidateItem> items) {
    for (final item in items) {
      _offCatalogItemKeys.add(_itemCacheKey(item));
    }
    _matchCache.clear();
  }

  /// Widens matching to Open Food Facts after base-food matching needs repair.
  /// The per-item cache must be cleared because it contains base-only results.
  void enableOffCatalogFallback() {
    if (_includeOffCatalog) return;
    _includeOffCatalog = true;
    _matchCache.clear();
  }

  static Future<List<FoodItem>> defaultMatchLoader(AiMealCandidateItem item,
      {AiCatalogSearchSession? aiSession, bool includeOff = false}) async {
    final helper = ProductLocalDataSource.instance;
    final matches = <FoodItem>[];
    final barcode = item.matchedBarcode?.trim();
    final searchOff =
        includeOff || (item.catalogSearchTerm?.trim().isNotEmpty ?? false);
    final fuzzyFuture = helper.fuzzyMatchForAi(
      item.name,
      catalogSearchTerm: item.catalogSearchTerm,
      searchTerms: item.searchTerms,
      aiSession: aiSession,
      includeOff: searchOff,
    );
    if (searchOff && barcode != null && barcode.isNotEmpty) {
      final selected = await helper.getProductByBarcode(barcode);
      if (selected != null) {
        matches.add(selected);
      }
    }
    final fuzzy = await fuzzyFuture;
    for (final food in fuzzy) {
      if (!matches.any((existing) => existing.barcode == food.barcode)) {
        matches.add(food);
      }
    }
    return matches;
  }

  Future<AiValidationResult> validateMealCandidate({
    required AiMealCandidate candidate,
    required AiValidationMode mode,
    AiMacroTargetContext? targetContext,
  }) async {
    final normalized = _normalize(candidate);
    final mealIssues = <AiValidationIssue>[...normalized.issues];
    final validatedItems = <AiValidatedMealItem>[];
    final items = normalized.candidate.items;
    // SQLite can serve independent reads concurrently; keep a small bound so a
    // complex meal does not flood the database worker. Future.wait retains order.
    for (var start = 0; start < items.length; start += 4) {
      final end = (start + 4).clamp(0, items.length);
      final matchesByItem = await Future.wait([
        for (var i = start; i < end; i++)
          _matchCache.putIfAbsent(
            _itemCacheKey(items[i]),
            () => _matchLoader(items[i]),
          ),
      ]);
      for (var i = start; i < end; i++) {
        final item = items[i];
        final matches = matchesByItem[i - start];
        final match = _evaluateMatch(item, matches);
        final nutrition = match.bestMatch == null
            ? AiNutritionTotals.zero
            : AiNutritionTotals.fromFood(match.bestMatch!, item.grams);
        final issues = _validateItem(
          index: i,
          item: item,
          match: match,
          nutrition: nutrition,
          mode: mode,
        );
        validatedItems.add(
          AiValidatedMealItem(
            candidate: item,
            match: match,
            nutrition: nutrition,
            issues: issues,
          ),
        );
      }
    }

    final totals = validatedItems.fold<AiNutritionTotals>(
      AiNutritionTotals.zero,
      (sum, item) => sum + item.nutrition,
    );
    final macroFit = targetContext == null
        ? null
        : evaluateTargetFit(totals: totals, target: targetContext);
    mealIssues.addAll(
      _validateMeal(
        items: validatedItems,
        totals: totals,
        targetContext: targetContext,
        macroFit: macroFit,
        mode: mode,
        context: normalized.candidate.context,
      ),
    );

    final allIssues = [
      ...mealIssues,
      for (final item in validatedItems) ...item.issues,
    ];
    final score = _computeValidationScore(allIssues, macroFit);
    final passed = _isGoodEnough(
          issues: allIssues,
          score: score,
          macroFit: macroFit,
          mode: mode,
        ) &&
        !allIssues.any(
          (issue) => issue.code == 'ambiguous_nutrition_match',
        );

    return AiValidationResult(
      candidate: normalized.candidate,
      mode: mode,
      items: validatedItems,
      totals: totals,
      macroFit: macroFit,
      issues: mealIssues,
      score: score,
      passed: passed,
    );
  }

  AiTargetFitResult evaluateTargetFit({
    required AiNutritionTotals totals,
    required AiMacroTargetContext target,
  }) {
    final kcalTolerance = kcalToleranceFor(target.kcal);
    final proteinTolerance = macroToleranceFor(target.protein);
    final carbsTolerance = macroToleranceFor(target.carbs);
    final fatTolerance = fatToleranceFor(target.fat);

    final kcalDelta = totals.kcal - target.kcal;
    final proteinDelta = totals.protein - target.protein;
    final carbsDelta = totals.carbs - target.carbs;
    final fatDelta = totals.fat - target.fat;

    return AiTargetFitResult(
      kcalDelta: kcalDelta,
      proteinDelta: proteinDelta,
      carbsDelta: carbsDelta,
      fatDelta: fatDelta,
      kcalTolerance: kcalTolerance,
      proteinTolerance: proteinTolerance,
      carbsTolerance: carbsTolerance,
      fatTolerance: fatTolerance,
      kcalWithinTolerance: kcalDelta.abs() <= kcalTolerance,
      proteinWithinTolerance: proteinDelta.abs() <= proteinTolerance,
      carbsWithinTolerance: carbsDelta.abs() <= carbsTolerance,
      fatWithinTolerance: fatDelta.abs() <= fatTolerance,
    );
  }

  static int kcalToleranceFor(int targetKcal) {
    if (targetKcal <= 0) return 80;
    return _maxInt(80, (targetKcal * 0.2).round());
  }

  static int macroToleranceFor(int targetGrams) {
    if (targetGrams <= 0) return 8;
    return _maxInt(10, (targetGrams * 0.25).round());
  }

  static int fatToleranceFor(int targetGrams) {
    if (targetGrams <= 0) return 6;
    return _maxInt(8, (targetGrams * 0.30).round());
  }

  _NormalizedCandidate _normalize(AiMealCandidate candidate) {
    final issues = <AiValidationIssue>[];
    final byKey = <String, AiMealCandidateItem>{};
    final duplicateNames = <String>{};

    for (var rawIndex = 0; rawIndex < candidate.items.length; rawIndex++) {
      final raw = candidate.items[rawIndex];
      final name = raw.name.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (name.isEmpty) {
        issues.add(
          const AiValidationIssue(
            severity: AiValidationSeverity.error,
            code: 'empty_item_name',
            message: 'An item has no food name.',
          ),
        );
      }
      final normalized = raw.copyWith(
        name: name.isEmpty ? 'Unknown food' : name,
        confidence: raw.confidence?.clamp(0.0, 1.0).toDouble(),
      );
      final baseKey =
          '${_normalizeText(normalized.name)}|${normalized.matchedBarcode ?? ''}';
      final key = normalized.grams > 0 ? baseKey : '$baseKey|$rawIndex';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = normalized;
      } else {
        duplicateNames.add(normalized.name);
        byKey[key] = existing.copyWith(
          grams: existing.grams + normalized.grams,
          confidence: _maxDouble(
            existing.confidence ?? 0,
            normalized.confidence ?? 0,
          ),
        );
      }
    }

    for (final name in duplicateNames) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.info,
          code: 'duplicate_item_merged',
          message: 'Duplicate "$name" entries were merged before validation.',
          parameters: {'name': name},
        ),
      );
    }

    return _NormalizedCandidate(
      candidate: candidate.copyWith(
        mealName: candidate.mealName?.trim(),
        description: candidate.description?.trim(),
        items: byKey.values.toList(growable: false),
      ),
      issues: issues,
    );
  }

  static String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9äöüß ]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static int _maxInt(int a, int b) => a > b ? a : b;
  static double _maxDouble(double a, double b) => a > b ? a : b;

  static bool isPreparedState(String? stateHint) {
    if (stateHint == null) return false;
    const preparedStates = {
      'cooked',
      'boiled',
      'gekocht',
      'fried',
      'gebraten',
      'baked',
      'gebacken',
      'grilled',
      'gegrillt',
    };
    return preparedStates.contains(stateHint.toLowerCase());
  }
}

class AiRepairOrchestrator {
  final AiMealValidationEngine validationEngine;

  const AiRepairOrchestrator({
    required this.validationEngine,
  });

  Future<AiRepairOutcome> run({
    required AiMealCandidate initialCandidate,
    AiValidationResult? initialValidation,
    required AiValidationMode mode,
    required AiCandidateRepairer repairer,
    AiMacroTargetContext? targetContext,
    int maxPasses = maxRepairPasses,
    void Function(
            int round, AiValidationResult result, int durationMilliseconds)?
        onRepairValidation,
  }) async {
    var candidate = initialCandidate;
    var validation = initialValidation ??
        await validationEngine.validateMealCandidate(
          candidate: candidate,
          mode: mode,
          targetContext: targetContext,
        );
    final firstPassAccepted =
        validation.passed && !validation.needsSemanticSelection;
    final firstPassIssueCategories = <String>{
      for (final issue in validation.allIssues)
        if (issue.severity != AiValidationSeverity.info)
          if (issue.code == 'ambiguous_nutrition_match')
            'semantic_match'
          else if (issue.code.contains('quantity') ||
              issue.code.contains('kcal') ||
              issue.code.contains('macro'))
            'quantity_or_anchor'
          else
            'other_validation',
    };
    var repairPasses = 0;

    while ((!validation.passed || validation.needsSemanticSelection) &&
        repairPasses < maxPasses) {
      final fallbackItems = validation.items
          .where((item) =>
              !item.isMatched ||
              item.match.quality == AiMatchQuality.weak ||
              item.match.quality == AiMatchQuality.partial ||
              item.match.isAmbiguous)
          .map((item) => item.candidate)
          .toList(growable: false);
      if (fallbackItems.isNotEmpty) {
        validationEngine.enableOffCatalogFallbackFor(fallbackItems);
        validation = await validationEngine.validateMealCandidate(
          candidate: candidate,
          mode: mode,
          targetContext: targetContext,
        );
        if (validation.passed && !validation.needsSemanticSelection) break;
      }
      repairPasses += 1;
      candidate = await repairer(candidate, validation, repairPasses);
      // Once a repair has started, subsequent validation can use OFF as a
      // fallback for revised names and explicit product selections.
      validationEngine.enableOffCatalogFallback();
      final validationWatch = Stopwatch()..start();
      validation = await validationEngine.validateMealCandidate(
        candidate: candidate,
        mode: mode,
        targetContext: targetContext,
      );
      validationWatch.stop();
      onRepairValidation?.call(
          repairPasses, validation, validationWatch.elapsedMilliseconds);
    }

    final limitReached =
        (!validation.passed || validation.needsSemanticSelection) &&
            repairPasses >= maxPasses;
    return AiRepairOutcome(
      validation: validation.copyWithRepairMetadata(
        repairPassesUsed: repairPasses,
        repairLimitReached: limitReached,
      ),
      repairPassesUsed: repairPasses,
      repairLimitReached: limitReached,
      firstPassAccepted: firstPassAccepted,
      validationRunsCount: repairPasses + 1,
      firstPassIssueCategories:
          firstPassIssueCategories.toList(growable: false),
    );
  }
}
