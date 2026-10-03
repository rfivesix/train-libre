import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';
import 'package:train_libre/services/ai_meal_scan_runner.dart';
import 'package:train_libre/services/ai_meal_scan_log_service.dart';
import 'package:train_libre/services/ai_meal_validation.dart';
import 'package:train_libre/services/ai_service.dart';

const accepted = AiMealCandidate(
  items: [AiMealCandidateItem(name: 'Rice', grams: 100)],
);
const rejected = AiMealCandidate(
  items: [AiMealCandidateItem(name: 'Unknown', grams: 100)],
);

AiMealValidationEngine testEngine() => AiMealValidationEngine(
      matchLoader: (item) async => item.name == 'Rice' || item.name == 'Apple'
          ? [
              FoodItem(
                barcode: item.name.toLowerCase(),
                name: item.name,
                calories: 130,
                protein: 3,
                carbs: 28,
                fat: 0.3,
                source: FoodItemSource.base,
              ),
            ]
          : [],
    );

void main() {
  test('accepted first candidate does one validation and no repair', () async {
    var calls = 0;
    var repairs = 0;
    var validationsStarted = 0;
    final result = await AiMealScanRunner(
      validationEngine: testEngine(),
      hedgeDelay: const Duration(milliseconds: 20),
    ).run(
      fastMode: true,
      onValidating: () => validationsStarted++,
      analyze: () async {
        calls++;
        return accepted;
      },
      repairer: (candidate, validation, attempt) async {
        repairs++;
        return candidate;
      },
    );
    expect(calls, 1);
    expect(repairs, 0);
    expect(validationsStarted, 1);
    expect(result.hedgeStarted, isFalse);
    expect(await result.primaryFirstPassAccepted, isTrue);
    expect(result.outcome.validationRunsCount, 1);
    expect(await result.validationRunsTotalCount, 1);
  });

  test('late primary is counted separately when hedge is accepted', () async {
    final primary = Completer<AiMealCandidate>();
    var calls = 0;
    var repairs = 0;
    final result = await AiMealScanRunner(
      validationEngine: testEngine(),
      hedgeDelay: const Duration(milliseconds: 1),
    ).run(
      fastMode: true,
      analyze: () {
        calls++;
        return calls == 1 ? primary.future : Future.value(accepted);
      },
      repairer: (candidate, validation, attempt) async {
        repairs++;
        return candidate;
      },
    );
    expect(result.hedgeStarted, isTrue);
    expect(result.outcome.validation.passed, isTrue);
    expect(repairs, 0);
    primary.complete(rejected);
    expect(await result.primaryFirstPassAccepted, isFalse);
    expect(await result.validationRunsTotalCount, 2);
    expect(result.outcome.validationRunsCount, 1);
  });

  test('invalid candidate is repaired and every validation is counted',
      () async {
    var repairs = 0;
    final stages = <AiMealScanLogStage>[];
    final validationResults = <AiMealScanLogResult>[];
    final selectedCandidates = <AiMealScanLogCandidate>[];
    final result = await AiMealScanRunner(
      validationEngine: testEngine(),
    ).run(
      fastMode: false,
      onProgress: (stage, elapsedMilliseconds,
          {durationMilliseconds,
          result,
          round,
          candidate,
          validationScore,
          issueCategories}) {
        stages.add(stage);
        if (stage == AiMealScanLogStage.candidateSelected) {
          selectedCandidates.add(candidate!);
        }
        if (stage == AiMealScanLogStage.validationFinished) {
          validationResults.add(result!);
        }
      },
      analyze: () async => rejected,
      repairer: (candidate, validation, attempt) async {
        repairs++;
        return accepted;
      },
    );
    expect(repairs, 1);
    expect(await result.primaryFirstPassAccepted, isFalse);
    expect(result.outcome.validationRunsCount, 2);
    expect(await result.validationRunsTotalCount, 2);
    expect(stages, [
      AiMealScanLogStage.primaryStarted,
      AiMealScanLogStage.providerFinished,
      AiMealScanLogStage.validationFinished,
      AiMealScanLogStage.candidateSelected,
      AiMealScanLogStage.repairStarted,
      AiMealScanLogStage.repairFinished,
      AiMealScanLogStage.validationFinished,
    ]);
    expect(validationResults, [
      AiMealScanLogResult.needsRepair,
      AiMealScanLogResult.accepted,
    ]);
    expect(selectedCandidates, [AiMealScanLogCandidate.primary]);
  });

  test('cancellation starts no hedge and no repair', () async {
    final pending = Completer<AiMealCandidate>();
    var cancelled = false;
    var calls = 0;
    var repairs = 0;
    final run = AiMealScanRunner(
      validationEngine: testEngine(),
      hedgeDelay: const Duration(milliseconds: 1),
    ).run(
      fastMode: true,
      isCancelled: () => cancelled,
      analyze: () {
        calls++;
        return pending.future;
      },
      repairer: (candidate, validation, attempt) async {
        repairs++;
        return accepted;
      },
    );
    cancelled = true;
    pending.complete(rejected);
    await expectLater(run, throwsStateError);
    expect(calls, 1);
    expect(repairs, 0);
  });

  test('reported tokens accumulate while missing usage remains unknown', () {
    final reports = <AiUsageRequestReport>[];
    final collector = AiUsageCollector(onRequestCompleted: reports.add);
    final first = collector.startRequest();
    final second = collector.startRequest();
    expect(collector.pendingCount, 2);
    collector.finishRequest(
        const AiTokenUsage(
          inputTokens: 100,
          outputTokens: 20,
          totalTokens: 120,
        ),
        requestId: second);
    expect(collector.totalTokens, 120);
    expect(collector.pendingCount, 1);
    collector.finishRequest(null, requestId: first);
    expect(collector.pendingCount, 0);
    expect(collector.usageComplete, isFalse);
    expect(reports.map((report) => report.requestIndex), [second, first]);
    expect(reports.first.usage?.totalTokens, 120);
    expect(reports.last.usage, isNull);
    collector.dispose();
  });

  test('synthetic meals retain baseline ingredients, quantities and matches',
      () async {
    const meals = [
      (accepted, accepted),
      (rejected, accepted),
      (
        AiMealCandidate(items: [
          AiMealCandidateItem(name: 'Rice', grams: 150),
          AiMealCandidateItem(name: 'Apple', grams: 90),
        ]),
        AiMealCandidate(items: [
          AiMealCandidateItem(name: 'Rice', grams: 150),
          AiMealCandidateItem(name: 'Apple', grams: 90),
        ]),
      ),
    ];
    for (final (initial, repaired) in meals) {
      final baseline = await AiRepairOrchestrator(
        validationEngine: testEngine(),
      ).run(
        initialCandidate: initial,
        mode: AiValidationMode.capture,
        repairer: (_, __, ___) async => repaired,
      );
      final faster = await AiMealScanRunner(
        validationEngine: testEngine(),
      ).run(
        fastMode: false,
        analyze: () async => initial,
        repairer: (_, __, ___) async => repaired,
      );
      expect(faster.outcome.validation.passed, baseline.validation.passed);
      expect(faster.outcome.repairPassesUsed, baseline.repairPassesUsed);
      expect(
        faster.outcome.validation.items
            .map((item) => (
                  item.candidate.name,
                  item.candidate.grams,
                  item.match.bestMatch?.barcode,
                ))
            .toList(),
        baseline.validation.items
            .map((item) => (
                  item.candidate.name,
                  item.candidate.grams,
                  item.match.bestMatch?.barcode,
                ))
            .toList(),
      );
    }
  });
}
