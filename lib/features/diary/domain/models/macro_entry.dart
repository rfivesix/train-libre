/// A manual nutrition log that does not reference a catalog food.
///
/// Nutrient values describe the whole entry when [amount] is null, otherwise
/// they describe 100 g or 100 ml according to [amountUnit].
class MacroEntry {
  final String id;

  /// Optional parent meal for an estimated ingredient snapshot.
  final String? mealEntryId;
  final DateTime timestamp;
  final String mealType;
  final String? name;
  final double? amount;
  final String? amountUnit;
  final bool isFluid;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? sugar;
  final double? fiber;
  final double? salt;
  final double? caffeine;
  final String calculatedNutrient;

  const MacroEntry({
    required this.id,
    this.mealEntryId,
    required this.timestamp,
    required this.mealType,
    this.name,
    this.amount,
    this.amountUnit,
    this.isFluid = false,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sugar,
    this.fiber,
    this.salt,
    this.caffeine,
    required this.calculatedNutrient,
  });

  double get amountFactor => amount == null ? 1 : amount! / 100;
  double get totalCalories => calories * amountFactor;
  double get totalProtein => protein * amountFactor;
  double get totalCarbs => carbs * amountFactor;
  double get totalFat => fat * amountFactor;
  double? get totalSugar => sugar == null ? null : sugar! * amountFactor;
  double? get totalFiber => fiber == null ? null : fiber! * amountFactor;
  double? get totalSalt => salt == null ? null : salt! * amountFactor;
  double? get totalCaffeine =>
      caffeine == null ? null : caffeine! * amountFactor;

  MacroEntry copyWith({
    String? id,
    Object? mealEntryId = _unset,
    DateTime? timestamp,
    String? mealType,
    Object? name = _unset,
    Object? amount = _unset,
    Object? amountUnit = _unset,
    bool? isFluid,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    Object? sugar = _unset,
    Object? fiber = _unset,
    Object? salt = _unset,
    Object? caffeine = _unset,
    String? calculatedNutrient,
  }) =>
      MacroEntry(
        id: id ?? this.id,
        mealEntryId: identical(mealEntryId, _unset)
            ? this.mealEntryId
            : mealEntryId as String?,
        timestamp: timestamp ?? this.timestamp,
        mealType: mealType ?? this.mealType,
        name: identical(name, _unset) ? this.name : name as String?,
        amount: identical(amount, _unset) ? this.amount : amount as double?,
        amountUnit: identical(amountUnit, _unset)
            ? this.amountUnit
            : amountUnit as String?,
        isFluid: isFluid ?? this.isFluid,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        sugar: identical(sugar, _unset) ? this.sugar : sugar as double?,
        fiber: identical(fiber, _unset) ? this.fiber : fiber as double?,
        salt: identical(salt, _unset) ? this.salt : salt as double?,
        caffeine:
            identical(caffeine, _unset) ? this.caffeine : caffeine as double?,
        calculatedNutrient: calculatedNutrient ?? this.calculatedNutrient,
      );

  static const _unset = Object();

  Map<String, dynamic> toMap() => {
        'id': id,
        'meal_entry_id': mealEntryId,
        'timestamp': timestamp.toIso8601String(),
        'meal_type': mealType,
        'name': name,
        'amount': amount,
        'amount_unit': amountUnit,
        'is_fluid': isFluid,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'sugar': sugar,
        'fiber': fiber,
        'salt': salt,
        'caffeine': caffeine,
        'calculated_nutrient': calculatedNutrient,
      };

  factory MacroEntry.fromMap(Map<String, dynamic> map) => MacroEntry(
        id: map['id'] as String,
        mealEntryId: map['meal_entry_id'] as String?,
        timestamp: DateTime.parse(map['timestamp'] as String),
        mealType: map['meal_type'] as String,
        name: map['name'] as String?,
        amount: (map['amount'] as num?)?.toDouble(),
        amountUnit: map['amount_unit'] as String?,
        isFluid: map['is_fluid'] as bool? ?? false,
        calories: (map['calories'] as num).toDouble(),
        protein: (map['protein'] as num).toDouble(),
        carbs: (map['carbs'] as num).toDouble(),
        fat: (map['fat'] as num).toDouble(),
        sugar: (map['sugar'] as num?)?.toDouble(),
        fiber: (map['fiber'] as num?)?.toDouble(),
        salt: (map['salt'] as num?)?.toDouble(),
        caffeine: (map['caffeine'] as num?)?.toDouble(),
        calculatedNutrient: map['calculated_nutrient'] as String? ?? 'calories',
      );
}
