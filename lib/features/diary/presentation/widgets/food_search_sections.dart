import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/app_section_header.dart';
import '../../domain/models/food_item.dart';

/// Section layout shared by both pickers. The data source already reserves
/// candidates per source; this only adds headers, preserving each source's rank.
class FoodSearchSections {
  FoodSearchSections(List<FoodItem> foods) {
    for (final source in const [
      FoodItemSource.base,
      FoodItemSource.user,
      FoodItemSource.off,
    ]) {
      final matches = foods.where((food) => food.source == source).toList();
      if (matches.isEmpty) continue;
      _rows.add((source: source, food: null));
      _rows.addAll(matches.map((food) => (source: source, food: food)));
    }
  }

  final _rows = <({FoodItemSource source, FoodItem? food})>[];
  int get length => _rows.length;
  bool get isEmpty => _rows.isEmpty;

  Widget buildRow(int index, AppLocalizations l10n,
      Widget Function(FoodItem) itemBuilder) {
    final row = _rows[index];
    if (row.food case final food?) return itemBuilder(food);
    return AppSectionHeader(
      key: ValueKey('food-search-section-${row.source.name}'),
      title: switch (row.source) {
        FoodItemSource.base => l10n.searchSectionBase,
        FoodItemSource.user => l10n.customFoodsTitle,
        FoodItemSource.off => l10n.searchSectionOther,
      },
      autoUpperCase: false,
      isFirst: index == 0,
    );
  }
}
