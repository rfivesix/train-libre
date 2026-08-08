import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:train_libre/services/unit_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late UnitService unitService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
    unitService = UnitService();
    await Future.delayed(Duration.zero);
  });



  group('WeeklyTargetRateCatalog custom rate support', () {
    test('coerces preset rates properly', () {
      final defaultGain = WeeklyTargetRateCatalog.defaultForGoal(
        BodyweightGoal.gainWeight,
        unitService,
      );
      expect(defaultGain.kgPerWeek, equals(0.25));

      final coerced = WeeklyTargetRateCatalog.coerceTargetRate(
        goal: BodyweightGoal.gainWeight,
        kgPerWeek: 0.25,
        unitService: unitService,
      );
      expect(coerced, equals(defaultGain.kgPerWeek));
    });


    test('preserves custom rate for gain goal', () {
      // User case: 370 g/week = 0.37 kg/week
      final customRate = 0.37;
      final coerced = WeeklyTargetRateCatalog.coerceTargetRate(
        goal: BodyweightGoal.gainWeight,
        kgPerWeek: customRate,
        unitService: unitService,
      );
      expect(coerced, equals(0.37));
      expect(
        WeeklyTargetRateCatalog.isPreset(
          goal: BodyweightGoal.gainWeight,
          kgPerWeek: customRate,
          unitService: unitService,
        ),
        isFalse,
      );
    });

    test('preserves custom rate for loss goal', () {
      final customRate = -0.37;
      final coerced = WeeklyTargetRateCatalog.coerceTargetRate(
        goal: BodyweightGoal.loseWeight,
        kgPerWeek: customRate,
        unitService: unitService,
      );
      expect(coerced, equals(-0.37));
      expect(
        WeeklyTargetRateCatalog.isPreset(
          goal: BodyweightGoal.loseWeight,
          kgPerWeek: customRate,
          unitService: unitService,
        ),
        isFalse,
      );
    });

    test('coerces out-of-bounds custom rate to default', () {
      final defaultRate = WeeklyTargetRateCatalog.defaultForGoal(
        BodyweightGoal.gainWeight,
        unitService,
      ).kgPerWeek;
      final coerced = WeeklyTargetRateCatalog.coerceTargetRate(
        goal: BodyweightGoal.gainWeight,
        kgPerWeek: 5.0,
        unitService: unitService,
      );
      expect(coerced, equals(defaultRate));
    });
  });
}

