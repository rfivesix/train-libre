import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database_helper.dart';
import '../../features/diary/domain/models/food_entry.dart';
import '../../features/workout/domain/models/set_log.dart';
import '../../features/workout/data/sources/workout_local_data_source.dart';
import '../../features/sleep/data/repository/sleep_query_repository.dart';
import '../../util/date_util.dart';
import '../../generated/app_localizations.dart';
import '../../features/sleep/data/persistence/dao/sleep_canonical_dao.dart';
import 'user_preferences_repository.dart';

class ShareService {
  const ShareService();

  /// Captures a [RepaintBoundary] identified by [boundaryKey], encodes it as a PNG,
  /// saves it to a temporary file, and triggers the native share sheet.
  Future<void> shareWidgetAsImage(GlobalKey boundaryKey) async {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Share boundary was not found or not rendered yet.');
    }

    // Capture the repaint boundary
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Could not encode image.');
    }

    final uint8List = byteData.buffer.asUint8List();

    // Save to a temporary file
    final tempDir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(tempDir.path, 'train-libre-share-$stamp.png'));
    await file.writeAsBytes(uint8List, flush: true);

    // Share the image
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
  }

  /// Queries all local DAOs/repositories for the selected date, compiles the data into
  /// a clean human-and-LLM-readable Markdown string, and shares it via the native share sheet.
  Future<void> shareDailyLogAsText(DateTime date,
      {AppLocalizations? l10n}) async {
    final dbHelper = DatabaseHelper.instance;
    final targetDate = date.dateOnly;
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final end =
        DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

    // 1. Fetch Food Entries and map them to Food Items
    final foodEntries = await dbHelper.getEntriesForDate(targetDate);
    final barcodes = foodEntries.map((e) => e.barcode).toSet().toList();
    final foodItemsList =
        await dbHelper.productLocalDataSource.getProductsByBarcodes(barcodes);
    final foodItemsMap = {for (final item in foodItemsList) item.barcode: item};

    // 2. Fetch Fluids
    final fluidEntries =
        await dbHelper.diaryLocalDataSource.getFluidEntriesForDate(targetDate);

    // 3. Fetch Workouts
    final workouts = await dbHelper.workoutLocalDataSource
        .getWorkoutLogsForDateRange(start, end);

    // 4. Fetch Sleep
    final sleepRepo = DriftSleepQueryRepository(database: dbHelper.dbInstance);
    final sleepAnalysis = await sleepRepo.getNightlyAnalysisByDate(targetDate);

    // 5. Fetch Measurements (Metrics)
    final sessions =
        await dbHelper.profileLocalDataSource.getMeasurementSessions();
    final dailySessions =
        sessions.where((s) => s.timestamp.isSameDate(targetDate)).toList();

    // 6. Fetch Goals
    final goalsData = await dbHelper.getGoalsForDate(targetDate);
    final targetSugar =
        await UserPreferencesRepository.instance.getTargetSugar() ?? 50;

    // Localized Headers/Titles
    final titleDailyLog =
        l10n?.shareDailyLogTitle ?? '[l10n:shareDailyLogTitle]';
    final headerNutrition =
        l10n?.nutritionHubTitle ?? '[l10n:nutritionHubTitle]';
    final headerWorkouts = l10n?.workoutsLabel ?? '[l10n:workoutsLabel]';
    final headerSleep = l10n?.sleepSectionTitle ?? '[l10n:sleepSectionTitle]';
    final headerMetrics =
        l10n?.measurementsScreenTitle ?? '[l10n:measurementsScreenTitle]';

    // Localized Labels
    final labelCalories = l10n?.calories ?? '[l10n:calories]';
    final labelProtein = l10n?.protein ?? '[l10n:protein]';
    final labelCarbs = l10n?.carbs ?? '[l10n:carbs]';
    final labelFat = l10n?.fat ?? '[l10n:fat]';
    final labelSugar = l10n?.sugar ?? '[l10n:sugar]';
    final labelSalt = l10n?.salt ?? '[l10n:salt]';
    final labelFiber = l10n?.fiber ?? '[l10n:fiber]';
    final labelWater = l10n?.water ?? '[l10n:water]';
    final labelSummary =
        l10n?.shareNutritionSummary ?? '[l10n:shareNutritionSummary]';
    final labelFluids = l10n?.waterHeader ?? '[l10n:waterHeader]';

    final labelSleepStart =
        l10n?.shareSleepStartTime ?? '[l10n:shareSleepStartTime]';
    final labelSleepEnd = l10n?.shareSleepEndTime ?? '[l10n:shareSleepEndTime]';
    final labelSleepDeep = l10n?.shareSleepDeep ?? '[l10n:shareSleepDeep]';
    final labelSleepLight = l10n?.shareSleepLight ?? '[l10n:shareSleepLight]';
    final labelSleepRem = l10n?.shareSleepRem ?? '[l10n:shareSleepRem]';
    final labelSleepAwake = l10n?.shareSleepAwake ?? '[l10n:shareSleepAwake]';
    final labelSleepScore =
        l10n?.sleepHubScoreLabel ?? '[l10n:sleepHubScoreLabel]';
    final labelSleepDuration =
        l10n?.sleepMetricDurationTitle ?? '[l10n:sleepMetricDurationTitle]';
    final labelSleepEfficiency =
        l10n?.shareSleepEfficiency ?? '[l10n:shareSleepEfficiency]';
    final labelSleepHeartRate =
        l10n?.shareSleepRestingHeartRate ?? '[l10n:shareSleepRestingHeartRate]';

    final labelNotes = l10n?.notesLabel ?? '[l10n:notesLabel]';
    final labelReps = l10n?.repsLabelShort ?? '[l10n:repsLabelShort]';
    final labelWeight = l10n?.kgLabelShort ?? '[l10n:kgLabelShort]';

    // Units
    final unitKcal = l10n?.unit_kcal ?? '[l10n:unit_kcal]';
    final unitG = l10n?.unit_grams ?? '[l10n:unit_grams]';
    final unitMl = l10n?.unit_milliliters ?? '[l10n:unit_milliliters]';

    // 7. Build the Markdown content
    final buffer = StringBuffer();

    // Date Header
    final dateStr =
        '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    buffer.writeln('# $titleDailyLog: $dateStr\n');

    // Section: Nutrition
    buffer.writeln('## $headerNutrition');
    if (foodEntries.isEmpty && fluidEntries.isEmpty) {
      final labelNoNutrition =
          l10n?.nothingTrackedYet ?? '[l10n:nothingTrackedYet]';
      buffer.writeln('$labelNoNutrition\n');
    } else {
      // Group foods by meal type
      final mealGroups = <String, List<FoodEntry>>{
        'mealtypeBreakfast': [],
        'mealtypeLunch': [],
        'mealtypeDinner': [],
        'mealtypeSnack': [],
      };

      for (final entry in foodEntries) {
        mealGroups.putIfAbsent(entry.mealType, () => []).add(entry);
      }

      final mealOrder = [
        'mealtypeBreakfast',
        'mealtypeLunch',
        'mealtypeDinner',
        'mealtypeSnack'
      ];
      double totalKcal = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      double totalSugar = 0;
      double totalSalt = 0;
      double totalFiber = 0;

      for (final mealKey in mealOrder) {
        final entries = mealGroups[mealKey] ?? [];
        if (entries.isEmpty) continue;

        final groupTitle = _getMealName(mealKey, l10n);
        buffer.writeln('### $groupTitle');
        for (final entry in entries) {
          final item = foodItemsMap[entry.barcode];
          final grams = entry.quantityInGrams;
          if (item != null) {
            final name =
                item.getLocalizedName(null, languageCode: l10n?.localeName);
            final ratio = grams / 100.0;
            final kcal = (item.calories * ratio).round();
            final pStr = (item.protein * ratio).toStringAsFixed(1);
            final cStr = (item.carbs * ratio).toStringAsFixed(1);
            final fStr = (item.fat * ratio).toStringAsFixed(1);
            final sugarStr = ((item.sugar ?? 0.0) * ratio).toStringAsFixed(1);
            final saltStr = ((item.salt ?? 0.0) * ratio).toStringAsFixed(1);
            final fiberStr = ((item.fiber ?? 0.0) * ratio).toStringAsFixed(1);

            buffer.writeln(
                '- $name: $grams$unitG - $kcal $unitKcal ($labelProtein: $pStr$unitG, $labelCarbs: $cStr$unitG, $labelFat: $fStr$unitG, $labelSugar: $sugarStr$unitG, $labelSalt: $saltStr$unitG, $labelFiber: $fiberStr$unitG)');

            totalKcal += item.calories * ratio;
            totalProtein += item.protein * ratio;
            totalCarbs += item.carbs * ratio;
            totalFat += item.fat * ratio;
            totalSugar += (item.sugar ?? 0.0) * ratio;
            totalSalt += (item.salt ?? 0.0) * ratio;
            totalFiber += (item.fiber ?? 0.0) * ratio;
          } else {
            final name = entry.barcode;
            buffer.writeln('- $name: $grams$unitG');
          }
        }
        buffer.writeln();
      }

      // Fluids
      double totalWater = 0;
      if (fluidEntries.isNotEmpty) {
        buffer.writeln('### $labelFluids');
        for (final entry in fluidEntries) {
          final name =
              entry.name.isNotEmpty ? entry.name : (l10n?.water ?? 'Drink');
          final ml = entry.quantityInMl;
          totalWater += ml;

          // Deduplication: Only add calories/macros if not already counted via FoodEntry.
          // This mirrors the logic in lib/features/diary/domain/calculate_daily_nutrition_use_case.dart
          final isLinked = entry.linkedFoodEntryId != null;
          final isDuplicateOfFood = foodEntries.any((food) {
            if (isLinked) return entry.linkedFoodEntryId == food.id;

            // Heuristic match if not explicitly linked (same time and similar quantity)
            final timeDiff =
                entry.timestamp.difference(food.timestamp).inSeconds.abs();
            return timeDiff < 2 && entry.quantityInMl == food.quantityInGrams;
          });

          final kcalForDisplay = entry.kcal ?? 0.0;
          final kcalStr = kcalForDisplay > 0
              ? ' (${kcalForDisplay.round()} $unitKcal)'
              : '';
          buffer.writeln('- $name: $ml$unitMl$kcalStr');

          if (!isDuplicateOfFood && !isLinked) {
            totalKcal += entry.kcal ?? 0.0;
            final ratio = ml / 100.0;
            totalCarbs += (entry.carbsPer100ml ?? 0.0) * ratio;
            totalSugar += (entry.sugarPer100ml ?? 0.0) * ratio;
          }
        }
        buffer.writeln();
      }

      // Summary
      final targetKcal = goalsData?.targetCalories;
      final targetProtein = goalsData?.targetProtein;
      final targetCarbs = goalsData?.targetCarbs;
      final targetFat = goalsData?.targetFat;

      buffer.writeln('**$labelSummary:**');
      buffer.writeln(
          '- $labelCalories: ${totalKcal.round()}${targetKcal != null ? ' / $targetKcal' : ''} $unitKcal');
      buffer.writeln(
          '- $labelProtein: ${totalProtein.toStringAsFixed(1)}${targetProtein != null ? ' / $targetProtein' : ''}$unitG');
      buffer.writeln(
          '- $labelCarbs: ${totalCarbs.toStringAsFixed(1)}${targetCarbs != null ? ' / $targetCarbs' : ''}$unitG');
      buffer.writeln(
          '- $labelFat: ${totalFat.toStringAsFixed(1)}${targetFat != null ? ' / $targetFat' : ''}$unitG');
      buffer.writeln(
          '- $labelSugar: ${totalSugar.toStringAsFixed(1)} / $targetSugar$unitG');
      final targetWater = goalsData?.targetWater ?? 3000;
      buffer.writeln(
          '- $labelWater: ${totalWater.round()} / $targetWater $unitMl\n');
    }

    // Section: Workouts
    buffer.writeln('## $headerWorkouts');
    if (workouts.isEmpty) {
      final labelNoWorkouts = l10n?.emptyHistory ?? '[l10n:emptyHistory]';
      buffer.writeln('$labelNoWorkouts\n');
    } else {
      for (final workout in workouts) {
        final routineName =
            workout.routineName ?? (l10n?.workoutSectionStart ?? 'Workout');
        final startTimeStr = _formatTime(workout.startTime);
        final endTimeStr = workout.endTime != null
            ? ' - ${_formatTime(workout.endTime!)}'
            : '';
        buffer.writeln('### $routineName ($startTimeStr$endTimeStr)');
        if (workout.notes != null && workout.notes!.isNotEmpty) {
          buffer.writeln('*$labelNotes: ${workout.notes}*');
        }

        // Group sets by exercise
        final exerciseSets = <String, List<SetLog>>{};
        final exerciseOrder = <String>[];
        for (final set in workout.sets) {
          final exerciseName = set.exerciseName;
          if (!exerciseSets.containsKey(exerciseName)) {
            exerciseSets[exerciseName] = [];
            exerciseOrder.add(exerciseName);
          }
          exerciseSets[exerciseName]!.add(set);
        }

        for (final exerciseName in exerciseOrder) {
          buffer.writeln('#### $exerciseName');
          final sets = exerciseSets[exerciseName] ?? [];
          for (var i = 0; i < sets.length; i++) {
            final set = sets[i];
            final typePrefix = set.setType != 'work'
                ? '[${_getSetTypeName(set.setType, l10n).toUpperCase()}] '
                : '';
            final completedStr = set.isCompleted == true ? '✓' : '✗';

            String detailStr = '';
            if (set.weightKg != null && set.reps != null) {
              detailStr =
                  '${set.weightKg} $labelWeight x ${set.reps} $labelReps';
            } else if (set.distanceKm != null && set.durationSeconds != null) {
              final durStr = _formatDurationSeconds(set.durationSeconds!);
              detailStr = '${set.distanceKm} km in $durStr';
            } else if (set.reps != null) {
              detailStr = '${set.reps} $labelReps';
            } else if (set.durationSeconds != null) {
              final durStr = _formatDurationSeconds(set.durationSeconds!);
              detailStr = durStr;
            }

            final rpeRirStr = (set.rpe != null || set.rir != null)
                ? ' (RPE: ${set.rpe ?? '-'}, RIR: ${set.rir ?? '-'})'
                : '';

            final labelSet = l10n != null
                ? l10n.shareSetNumber(i + 1)
                : '[l10n:shareSetNumber(${i + 1})]';
            buffer.writeln(
                '- $labelSet: $typePrefix$detailStr$rpeRirStr [$completedStr]');
          }
          buffer.writeln();
        }
      }
    }

    // Section: Sleep
    buffer.writeln('## $headerSleep');
    if (sleepAnalysis == null) {
      final labelNoSleep =
          l10n?.sleepEmptyDayNoData ?? '[l10n:sleepEmptyDayNoData]';
      buffer.writeln('$labelNoSleep\n');
    } else {
      final startLocal = sleepAnalysis.sessionStartAtUtc?.toLocal();
      final endLocal = sleepAnalysis.sessionEndAtUtc?.toLocal();
      final startTimeStr = startLocal != null ? _formatTime(startLocal) : 'N/A';
      final endTimeStr = endLocal != null ? _formatTime(endLocal) : 'N/A';

      final segmentsDao = SleepCanonicalStageSegmentsDao(dbHelper.dbInstance);
      final segments =
          await segmentsDao.findBySessionId(sleepAnalysis.sessionId);

      double deepMinutes = 0.0;
      double lightMinutes = 0.0;
      double remMinutes = 0.0;
      double awakeMinutes = 0.0;

      for (final segment in segments) {
        final durationMinutes =
            segment.endedAt.difference(segment.startedAt).inSeconds / 60.0;
        final stage = segment.stage.toLowerCase();
        if (stage.contains('deep')) {
          deepMinutes += durationMinutes;
        } else if (stage.contains('rem')) {
          remMinutes += durationMinutes;
        } else if (stage.contains('awake') || stage.contains('wake')) {
          awakeMinutes += durationMinutes;
        } else {
          lightMinutes += durationMinutes;
        }
      }

      final duration = sleepAnalysis.totalSleepMinutes != null
          ? '${(sleepAnalysis.totalSleepMinutes! / 60).floor()}h ${sleepAnalysis.totalSleepMinutes! % 60}m'
          : 'N/A';
      final scoreStr = sleepAnalysis.score != null
          ? '${sleepAnalysis.score!.round()}/100'
          : 'N/A';
      final efficiencyStr = sleepAnalysis.sleepEfficiencyPct != null
          ? '${(sleepAnalysis.sleepEfficiencyPct!).round()}%'
          : 'N/A';
      final hrStr = sleepAnalysis.restingHeartRateBpm != null
          ? '${sleepAnalysis.restingHeartRateBpm!.round()} bpm'
          : 'N/A';

      buffer.writeln('- $labelSleepStart: $startTimeStr');
      buffer.writeln('- $labelSleepEnd: $endTimeStr');
      buffer
          .writeln('- $labelSleepDeep: ${deepMinutes.toStringAsFixed(1)} min');
      buffer.writeln(
          '- $labelSleepLight: ${lightMinutes.toStringAsFixed(1)} min');
      buffer.writeln('- $labelSleepRem: ${remMinutes.toStringAsFixed(1)} min');
      buffer.writeln(
          '- $labelSleepAwake: ${awakeMinutes.toStringAsFixed(1)} min');
      buffer.writeln('- $labelSleepDuration: $duration');
      buffer.writeln('- $labelSleepScore: $scoreStr');
      buffer.writeln('- $labelSleepEfficiency: $efficiencyStr');
      buffer.writeln('- $labelSleepHeartRate: $hrStr\n');
    }

    // Section: Metrics
    buffer.writeln('## $headerMetrics');
    if (dailySessions.isEmpty) {
      final labelNoMetrics =
          l10n?.measurementsEmptyState ?? '[l10n:measurementsEmptyState]';
      buffer.writeln('$labelNoMetrics\n');
    } else {
      for (final session in dailySessions) {
        for (final m in session.measurements) {
          final typeLabel = _getMetricName(m.type, l10n);
          buffer.writeln('- $typeLabel: ${m.value} ${m.unit}');
        }
      }
      buffer.writeln();
    }

    // Trigger share
    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString().trim(),
        subject: '$titleDailyLog $dateStr',
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
  }

  String _getSetTypeName(String type, AppLocalizations? l10n) {
    if (l10n != null) {
      switch (type.toLowerCase()) {
        case 'warmup':
          return l10n.setTypeWarmup;
        case 'work':
          return l10n.setTypeWork;
        case 'failure':
          return l10n.setTypeFailure;
        case 'dropset':
          return l10n.setTypeDropset;
        case 'superset':
          return l10n.setTypeSuperset;
        case 'other':
          return l10n.setTypeOther;
      }
    }
    switch (type.toLowerCase()) {
      case 'warmup':
        return 'Warm-up';
      case 'work':
        return 'Work sets';
      case 'failure':
        return 'Failure';
      case 'dropset':
        return 'Dropset';
      case 'superset':
        return 'Superset';
      default:
        return type;
    }
  }

  String _getMealName(String key, AppLocalizations? l10n) {
    if (l10n != null) {
      switch (key) {
        case 'mealtypeBreakfast':
          return l10n.mealtypeBreakfast;
        case 'mealtypeLunch':
          return l10n.mealtypeLunch;
        case 'mealtypeDinner':
          return l10n.mealtypeDinner;
        case 'mealtypeSnack':
          return l10n.mealtypeSnack;
      }
    }
    switch (key) {
      case 'mealtypeBreakfast':
        return '[l10n:mealtypeBreakfast]';
      case 'mealtypeLunch':
        return '[l10n:mealtypeLunch]';
      case 'mealtypeDinner':
        return '[l10n:mealtypeDinner]';
      case 'mealtypeSnack':
        return '[l10n:mealtypeSnack]';
      default:
        return key;
    }
  }

  String _getMetricName(String key, AppLocalizations? l10n) {
    switch (key) {
      case 'weight':
        return l10n?.measurementWeight ?? '[l10n:measurementWeight]';
      case 'body_fat':
        return l10n?.measurementFatPercent ?? '[l10n:measurementFatPercent]';
      default:
        if (key.isEmpty) return key;
        return key[0].toUpperCase() + key.substring(1).replaceAll('_', ' ');
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDurationSeconds(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m}m ${s}s';
    }
    if (m > 0) {
      return '${m}m ${s}s';
    }
    return '${s}s';
  }

  ui.Rect _sharePositionOrigin() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return const ui.Rect.fromLTWH(0, 0, 1, 1);
    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return ui.Rect.fromLTWH(
      0,
      0,
      math.max(1, logicalSize.width),
      math.max(1, logicalSize.height),
    );
  }
}
