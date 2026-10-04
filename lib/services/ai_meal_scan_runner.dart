import 'dart:async';

import 'ai_meal_validation.dart';
import 'ai_meal_scan_log_service.dart';

typedef AiCandidateLoader = Future<AiMealCandidate> Function();

class AiScanRunResult {
  final AiRepairOutcome outcome;
  final bool hedgeStarted;
  final Future<bool?> primaryFirstPassAccepted;
  final Future<List<String>> primaryIssueCategories;
  final Future<int> validationRunsTotalCount;
  final Future<int> providerSeconds;
  final Future<int> validationSeconds;
  final int repairSeconds;

  const AiScanRunResult({
    required this.outcome,
    required this.hedgeStarted,
    required this.primaryFirstPassAccepted,
    required this.primaryIssueCategories,
    required this.validationRunsTotalCount,
    required this.providerSeconds,
    required this.validationSeconds,
    required this.repairSeconds,
  });
}

class _CandidateCheck {
  final AiMealScanLogCandidate source;
  final AiMealCandidate? candidate;
  final AiValidationResult? validation;
  final Object? error;
  final StackTrace? stackTrace;

  const _CandidateCheck(this.source, this.candidate, this.validation,
      this.error, this.stackTrace);

  bool get accepted =>
      validation != null &&
      validation!.passed &&
      !validation!.needsSemanticSelection;
}

/// Runs the existing full validator on every AI candidate. A hedge only races
/// independent initial responses; repair remains a single bounded chain.
class AiMealScanRunner {
  final AiMealValidationEngine validationEngine;
  final Duration hedgeDelay;
  final bool enableHedge;

  const AiMealScanRunner({
    required this.validationEngine,
    this.hedgeDelay = const Duration(seconds: 4),
    this.enableHedge = false,
  });

  Future<AiScanRunResult> run({
    required AiCandidateLoader analyze,
    required AiCandidateRepairer repairer,
    required bool fastMode,
    bool Function()? isCancelled,
    void Function()? onValidating,
    void Function(AiMealCandidate candidate)? onCandidateReady,
    void Function(AiValidationResult validation, int elapsedMilliseconds)?
        onValidationReady,
    void Function(AiMealScanLogStage stage, int elapsedMilliseconds,
            {int? durationMilliseconds,
            AiMealScanLogResult? result,
            int? round,
            AiMealScanLogCandidate? candidate,
            int? validationScore,
            List<AiMealScanLogIssueCategory>? issueCategories})?
        onProgress,
  }) async {
    final runWatch = Stopwatch()..start();
    void ensureActive() {
      if (isCancelled?.call() ?? false) {
        throw StateError('Scan cancelled');
      }
    }

    var providerMilliseconds = 0;
    var validationMilliseconds = 0;
    var primaryResponseReceived = false;
    Future<_CandidateCheck> check(AiMealScanLogCandidate source) async {
      final primaryCall = source == AiMealScanLogCandidate.primary;
      final providerWatch = Stopwatch()..start();
      Stopwatch? validationWatch;
      try {
        ensureActive();
        onProgress?.call(
            primaryCall
                ? AiMealScanLogStage.primaryStarted
                : AiMealScanLogStage.hedgeStarted,
            runWatch.elapsedMilliseconds,
            candidate: source);
        final candidate = await analyze();
        if (primaryCall) {
          primaryResponseReceived = true;
          onCandidateReady?.call(candidate);
        }
        providerMilliseconds += providerWatch.elapsedMilliseconds;
        providerWatch.stop();
        onProgress?.call(
            AiMealScanLogStage.providerFinished, runWatch.elapsedMilliseconds,
            durationMilliseconds: providerWatch.elapsedMilliseconds,
            candidate: source);
        onValidating?.call();
        validationWatch = Stopwatch()..start();
        final validation = await validationEngine.validateMealCandidate(
          candidate: candidate,
          mode: AiValidationMode.capture,
        );
        onValidationReady?.call(validation, runWatch.elapsedMilliseconds);
        validationMilliseconds += validationWatch.elapsedMilliseconds;
        validationWatch.stop();
        onProgress?.call(
            AiMealScanLogStage.validationFinished, runWatch.elapsedMilliseconds,
            durationMilliseconds: validationWatch.elapsedMilliseconds,
            result: validation.passed && !validation.needsSemanticSelection
                ? AiMealScanLogResult.accepted
                : AiMealScanLogResult.needsRepair,
            candidate: source,
            validationScore: validation.score,
            issueCategories: _issueCategories(validation));
        return _CandidateCheck(source, candidate, validation, null, null);
      } catch (error, stackTrace) {
        if (providerWatch.isRunning) {
          providerMilliseconds += providerWatch.elapsedMilliseconds;
          providerWatch.stop();
        }
        if (validationWatch?.isRunning ?? false) {
          validationMilliseconds += validationWatch!.elapsedMilliseconds;
          validationWatch.stop();
        }
        return _CandidateCheck(source, null, null, error, stackTrace);
      }
    }

    final primary = check(AiMealScanLogCandidate.primary);
    var primarySettled = false;
    unawaited(primary.then((_) => primarySettled = true));
    Future<_CandidateCheck>? hedge;
    if (enableHedge && fastMode) {
      await Future.any<void>([
        primary.then((_) {}),
        Future<void>.delayed(hedgeDelay),
      ]);
      if (!primarySettled &&
          !primaryResponseReceived &&
          !(isCancelled?.call() ?? false)) {
        hedge = check(AiMealScanLogCandidate.hedge);
      }
    }

    _CandidateCheck selected;
    if (hedge == null) {
      selected = await primary;
    } else {
      final first = await Future.any([
        primary.then((value) => (0, value)),
        hedge.then((value) => (1, value)),
      ]);
      if (first.$2.accepted) {
        selected = first.$2;
      } else {
        final other = await (first.$1 == 0 ? hedge : primary);
        if (other.accepted) {
          selected = other;
        } else if (first.$2.validation == null) {
          selected = other.validation != null ? other : first.$2;
        } else if (other.validation == null ||
            first.$2.validation!.score >= other.validation!.score) {
          selected = first.$2;
        } else {
          selected = other;
        }
      }
    }

    if (selected.validation == null || selected.candidate == null) {
      Error.throwWithStackTrace(
        selected.error ?? StateError('AI analysis returned no candidate'),
        selected.stackTrace ?? StackTrace.current,
      );
    }

    onProgress?.call(
        AiMealScanLogStage.candidateSelected, runWatch.elapsedMilliseconds,
        candidate: selected.source,
        validationScore: selected.validation!.score,
        issueCategories: _issueCategories(selected.validation!));

    ensureActive();
    final repairWatch = Stopwatch()..start();
    final outcome = await AiRepairOrchestrator(
      validationEngine: validationEngine,
    ).run(
      initialCandidate: selected.candidate!,
      initialValidation: selected.validation,
      mode: AiValidationMode.capture,
      repairer: (candidate, validation, attempt) {
        ensureActive();
        onProgress?.call(
            AiMealScanLogStage.repairStarted, runWatch.elapsedMilliseconds,
            round: attempt);
        final repairCallWatch = Stopwatch()..start();
        return repairer(candidate, validation, attempt).then((repaired) {
          onProgress?.call(
              AiMealScanLogStage.repairFinished, runWatch.elapsedMilliseconds,
              durationMilliseconds: repairCallWatch.elapsedMilliseconds,
              round: attempt);
          return repaired;
        });
      },
      onRepairValidation: (round, validation, durationMilliseconds) {
        onValidationReady?.call(validation, runWatch.elapsedMilliseconds);
        onProgress?.call(
            AiMealScanLogStage.validationFinished, runWatch.elapsedMilliseconds,
            durationMilliseconds: durationMilliseconds,
            result: validation.passed && !validation.needsSemanticSelection
                ? AiMealScanLogResult.accepted
                : AiMealScanLogResult.needsRepair,
            round: round,
            candidate: selected.source,
            validationScore: validation.score,
            issueCategories: _issueCategories(validation));
      },
    );
    repairWatch.stop();
    final primaryResult = primary.then((result) => result.validation);
    return AiScanRunResult(
      outcome: outcome,
      hedgeStarted: hedge != null,
      primaryFirstPassAccepted: primaryResult.then((validation) =>
          validation == null
              ? null
              : validation.passed && !validation.needsSemanticSelection),
      primaryIssueCategories: primaryResult.then((validation) {
        if (validation == null) return const <String>[];
        final categories = <String>{};
        for (final issue in validation.allIssues) {
          if (issue.severity == AiValidationSeverity.info) continue;
          if (issue.code == 'ambiguous_nutrition_match') {
            categories.add('semantic_match');
          } else if (issue.code.contains('quantity') ||
              issue.code.contains('kcal') ||
              issue.code.contains('macro')) {
            categories.add('quantity_or_anchor');
          } else {
            categories.add('other_validation');
          }
        }
        return categories.toList(growable: false);
      }),
      validationRunsTotalCount: Future.wait([
        primary,
        if (hedge != null) hedge,
      ]).then((checks) =>
          checks.where((check) => check.validation != null).length +
          outcome.repairPassesUsed),
      providerSeconds: Future.wait([
        primary,
        if (hedge != null) hedge,
      ]).then((_) => (providerMilliseconds / 1000).round()),
      validationSeconds: Future.wait([
        primary,
        if (hedge != null) hedge,
      ]).then((_) => (validationMilliseconds / 1000).round()),
      repairSeconds: (repairWatch.elapsedMilliseconds / 1000).round(),
    );
  }

  static List<AiMealScanLogIssueCategory> _issueCategories(
      AiValidationResult validation) {
    final categories = <AiMealScanLogIssueCategory>{};
    for (final issue in validation.allIssues) {
      if (issue.severity == AiValidationSeverity.info) continue;
      final code = issue.code;
      categories.add(switch (code) {
        'ambiguous_nutrition_match' => AiMealScanLogIssueCategory.semanticMatch,
        'unmatched_item' ||
        'all_items_unmatched' ||
        'weak_db_match' ||
        'ambiguous_db_match' ||
        'partial_unmatched_items' ||
        'zero_nutrition_match' =>
          AiMealScanLogIssueCategory.catalogMatch,
        'invalid_quantity' ||
        'tiny_quantity' ||
        'large_quantity' ||
        'extreme_quantity' ||
        'implausible_portion_density' =>
          AiMealScanLogIssueCategory.quantity,
        'state_mismatch' => AiMealScanLogIssueCategory.preparationState,
        'low_ai_confidence' => AiMealScanLogIssueCategory.confidence,
        'anchor_kcal_deviation' ||
        'anchor_kcal_extreme' ||
        'anchor_macro_profile_deviation' ||
        'capture_total_kcal_extreme' ||
        'capture_total_kcal_high' ||
        'macro_energy_mismatch' ||
        'macro_total_extreme' ||
        'macro_total_high' ||
        'implausible_food_density' ||
        'implausible_item_nutrition' ||
        'zero_total_kcal' =>
          AiMealScanLogIssueCategory.nutritionAnchor,
        _ => AiMealScanLogIssueCategory.otherValidation,
      });
    }
    return categories.toList(growable: false);
  }
}
