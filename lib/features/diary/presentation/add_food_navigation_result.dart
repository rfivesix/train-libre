import '../../../services/telemetry/telemetry_service.dart';
import '../domain/models/food_item.dart';

/// A [FoodItem] that was resolved by scanning a barcode.
///
/// The barcode scanner pops this instead of a bare [FoodItem] so the screen that
/// finally logs the entry can attribute it to the scanner rather than to manual
/// search. It carries no extra state beyond that provenance marker.
class ScannedFoodItem {
  final FoodItem item;

  const ScannedFoodItem(this.item);
}

/// Interprets values returned by [AddFoodScreen] routes.
class AddFoodNavigationResult {
  final bool shouldRefresh;
  final FoodItem? selectedFoodItem;

  /// Which surface the selection came from, as a [FoodLogSource] value. Pass
  /// this straight into `insertFoodEntry(telemetrySource: ...)`.
  final String source;

  const AddFoodNavigationResult({
    required this.shouldRefresh,
    required this.selectedFoodItem,
    this.source = FoodLogSource.manualSearch,
  });

  factory AddFoodNavigationResult.fromRouteResult(Object? result) {
    if (result == true) {
      return const AddFoodNavigationResult(
        shouldRefresh: true,
        selectedFoodItem: null,
      );
    }
    if (result is ScannedFoodItem) {
      return AddFoodNavigationResult(
        shouldRefresh: false,
        selectedFoodItem: result.item,
        source: FoodLogSource.barcodeScan,
      );
    }
    if (result is FoodItem) {
      return AddFoodNavigationResult(
        shouldRefresh: false,
        selectedFoodItem: result,
      );
    }
    return const AddFoodNavigationResult(
      shouldRefresh: false,
      selectedFoodItem: null,
    );
  }
}
