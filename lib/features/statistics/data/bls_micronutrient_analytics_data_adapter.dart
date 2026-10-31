import 'package:flutter/material.dart';

import '../../../data/database_helper.dart';
import '../../../services/bls_food_catalog_refresh_service.dart';
import '../domain/timeframe_block.dart';

class MicronutrientAverage {
  const MicronutrientAverage({
    required this.code,
    required this.name,
    required this.group,
    required this.unit,
    required this.averagePerLoggedDay,
    required this.loggedDays,
  });

  final String code;
  final String name;
  final String group;
  final String unit;
  final double averagePerLoggedDay;
  final int loggedDays;
}

class MicronutrientPeriodSummary {
  const MicronutrientPeriodSummary({
    required this.nutrients,
    required this.blsLoggedDays,
    required this.blsFoodEntries,
    required this.catalogAvailable,
  });

  final List<MicronutrientAverage> nutrients;
  final int blsLoggedDays;
  final int blsFoodEntries;
  final bool catalogAvailable;
}

class BlsMicronutrientAnalyticsDataAdapter {
  const BlsMicronutrientAnalyticsDataAdapter();

  Future<MicronutrientPeriodSummary> fetchSummary({
    required DateTimeRange range,
    required String languageCode,
  }) async {
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final foodEntries = await DatabaseHelper.instance.getEntriesForDateRange(
      start,
      endOfDay,
    );
    final blsEntries = foodEntries
        .where((entry) => entry.barcode.startsWith('bls:'))
        .where((entry) => entry.quantityInGrams > 0)
        .toList(growable: false);
    if (blsEntries.isEmpty) {
      return const MicronutrientPeriodSummary(
        nutrients: [],
        blsLoggedDays: 0,
        blsFoodEntries: 0,
        catalogAvailable: true,
      );
    }

    final catalogAvailable = await BlsFoodCatalogRefreshService.instance
        .isInstalled();
    if (!catalogAvailable) {
      return MicronutrientPeriodSummary(
        nutrients: const [],
        blsLoggedDays: 0,
        blsFoodEntries: blsEntries.length,
        catalogAvailable: false,
      );
    }

    final facts = await const BlsNutrientRepository().getFactsForBarcodes(
      blsEntries.map((entry) => entry.barcode),
      languageCode,
    );
    final factsByBarcode = <String, List<BlsNutrientFact>>{};
    for (final fact in facts) {
      factsByBarcode.putIfAbsent(fact.barcode, () => []).add(fact);
    }

    final totalsByCode = <String, Map<DateTime, double>>{};
    final factByCode = <String, BlsNutrientFact>{};
    final blsDays = <DateTime>{};
    for (final entry in blsEntries) {
      final day = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      final entryFacts = factsByBarcode[entry.barcode];
      if (entryFacts == null || entryFacts.isEmpty) continue;
      blsDays.add(day);
      for (final fact in entryFacts) {
        final value = fact.value;
        if (value == null || !value.isFinite) continue;
        final dailyTotals = totalsByCode.putIfAbsent(fact.code, () => {});
        dailyTotals.update(
          day,
          (total) => total + value * entry.quantityInGrams / 100,
          ifAbsent: () => value * entry.quantityInGrams / 100,
        );
        factByCode.putIfAbsent(fact.code, () => fact);
      }
    }

    final averages = <MicronutrientAverage>[];
    for (final entry in totalsByCode.entries) {
      final nutrient = factByCode[entry.key]!;
      final values = entry.value.values;
      final loggedDays = values.length;
      if (loggedDays == 0) continue;
      averages.add(
        MicronutrientAverage(
          code: nutrient.code,
          name: nutrient.name,
          group: nutrient.group,
          unit: nutrient.unit,
          averagePerLoggedDay:
              values.fold<double>(0, (sum, value) => sum + value) / loggedDays,
          loggedDays: loggedDays,
        ),
      );
    }
    averages.sort((a, b) {
      final groupComparison = a.group.compareTo(b.group);
      return groupComparison != 0 ? groupComparison : a.name.compareTo(b.name);
    });

    return MicronutrientPeriodSummary(
      nutrients: List.unmodifiable(averages),
      blsLoggedDays: blsDays.length,
      blsFoodEntries: blsEntries.length,
      catalogAvailable: true,
    );
  }

  static DateTimeRange rangeFor({
    required TimeframeBlock block,
    required DateTime anchor,
    required bool isRolling,
  }) {
    final bounds = isRolling
        ? block.getRollingBounds()
        : block.getBounds(anchor, DateTime(2020));
    return DateTimeRange(start: bounds.start, end: bounds.end);
  }
}
