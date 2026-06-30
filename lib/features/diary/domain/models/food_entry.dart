// lib/models/food_entry.dart

/// Represents a single food intake record.
///
/// Links a [FoodItem] (via [barcode]) to a specific time, quantity, and meal type.
class FoodEntry {
  /// Unique identifier for the food entry.
  final int? id;

  /// The barcode of the consumed [FoodItem].
  final String barcode;

  /// The exact time when the food was consumed.
  final DateTime timestamp;

  /// The amount consumed in grams.
  final int quantityInGrams;

  /// The type of meal (e.g., "Breakfast", "Lunch", "Dinner", "Snack").
  final String mealType;

  /// Last modification timestamp from persistence when available.
  final DateTime? updatedAt;

  /// FK to the archived POINT-IN-TIME snapshot in OffProductsArchive.
  final int? archiveLocalId;

  /// Creates a new [FoodEntry] instance.
  FoodEntry({
    this.id,
    required this.barcode,
    required this.timestamp,
    required this.quantityInGrams,
    required this.mealType,
    this.updatedAt,
    this.archiveLocalId,
  });

  /// Converts the [FoodEntry] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'timestamp': timestamp.toIso8601String(),
      'quantity_in_grams': quantityInGrams,
      'meal_type': mealType,
      'archive_local_id': archiveLocalId,
    };
  }

  FoodEntry copyWith({
    int? id,
    String? barcode,
    DateTime? timestamp,
    int? quantityInGrams,
    String? mealType,
    DateTime? updatedAt,
    int? archiveLocalId,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      timestamp: timestamp ?? this.timestamp,
      quantityInGrams: quantityInGrams ?? this.quantityInGrams,
      mealType: mealType ?? this.mealType,
      updatedAt: updatedAt ?? this.updatedAt,
      archiveLocalId: archiveLocalId ?? this.archiveLocalId,
    );
  }
}
