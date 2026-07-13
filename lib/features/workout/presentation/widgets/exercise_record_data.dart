import '../../../../services/unit_service.dart';

class ExerciseRecordData {
  final String label;
  final double valueKg;
  final double? diffKg;
  final int fractionDigits;

  final String? valueStr;
  final String? diffStr;
  final bool isCardio;

  const ExerciseRecordData.weight({
    required this.label,
    required this.valueKg,
    this.diffKg,
    this.fractionDigits = 1,
  })  : valueStr = null,
        diffStr = null,
        isCardio = false;

  const ExerciseRecordData.cardio({
    required this.label,
    required String value,
    String? diff,
  })  : valueKg = 0,
        diffKg = null,
        fractionDigits = 1,
        valueStr = value,
        diffStr = diff,
        isCardio = true;

  String format(UnitService unitService) {
    if (isCardio) {
      final diffText = diffStr == null ? '' : ' ($diffStr)';
      return '$label ($valueStr$diffText)';
    }

    final value = unitService.convertDisplayValue(
      valueKg,
      UnitDimension.weight,
    );
    final diffText = diffKg == null
        ? ''
        : ' (+${unitService.formatDisplayWeight(diffKg!, fractionDigits: fractionDigits)})';
    return '$label (${value.toStringAsFixed(fractionDigits).replaceAll('.0', '')} ${unitService.suffixFor(UnitDimension.weight)}$diffText)';
  }
}
