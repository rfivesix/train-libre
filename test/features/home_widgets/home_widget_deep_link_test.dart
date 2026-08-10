import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/home_widgets/home_widget_deep_link.dart';

void main() {
  group('diary link', () {
    test('parses the scheme form iOS delivers', () {
      expect(
          parseHomeWidgetDeepLink('trainlibre://diary'), isA<OpenDiaryLink>());
    });

    test('parses the path form Flutter sometimes reports', () {
      expect(parseHomeWidgetDeepLink('/diary'), isA<OpenDiaryLink>());
    });

    test('tolerates a trailing slash', () {
      expect(
        parseHomeWidgetDeepLink('trainlibre://diary/'),
        isA<OpenDiaryLink>(),
      );
    });
  });

  group('quick action link', () {
    for (final key in [
      HomeWidgetAction.aiMealCapture,
      HomeWidgetAction.scanBarcode,
      HomeWidgetAction.startWorkout,
      HomeWidgetAction.addMeasurement,
      HomeWidgetAction.logSupplement,
      HomeWidgetAction.addLiquid,
      HomeWidgetAction.addFood,
    ]) {
      test('parses $key', () {
        expect(
          parseHomeWidgetDeepLink('trainlibre://action/$key'),
          QuickActionLink(key),
        );
      });
    }

    test('parses the path form', () {
      expect(
        parseHomeWidgetDeepLink('/action/start_workout'),
        const QuickActionLink('start_workout'),
      );
    });

    test('rejects an unknown action rather than forwarding it', () {
      expect(parseHomeWidgetDeepLink('trainlibre://action/rm_rf'), isNull);
    });

    test('rejects an action with no key', () {
      expect(parseHomeWidgetDeepLink('trainlibre://action'), isNull);
    });

    test('rejects extra path segments', () {
      expect(
        parseHomeWidgetDeepLink('trainlibre://action/add_liquid/500'),
        isNull,
      );
    });
  });

  group('unrelated routes are left alone', () {
    test('the live workout deep link is not claimed', () {
      expect(parseHomeWidgetDeepLink('trainlibre://workout/live'), isNull);
    });

    test('the root route is not claimed', () {
      expect(parseHomeWidgetDeepLink('/'), isNull);
    });

    test('an empty string is not claimed', () {
      expect(parseHomeWidgetDeepLink(''), isNull);
    });
  });

  group('statistics widgets', () {
    test('the recovery widget opens the recovery tracker', () {
      expect(
        parseHomeWidgetDeepLink('trainlibre://analytics/recovery'),
        const OpenRecoveryLink(),
      );
      // Path form, as Flutter sometimes presents the route.
      expect(
        parseHomeWidgetDeepLink('/analytics/recovery'),
        const OpenRecoveryLink(),
      );
    });

    test('another analytics screen is not claimed', () {
      expect(parseHomeWidgetDeepLink('trainlibre://analytics/volume'), isNull);
      expect(parseHomeWidgetDeepLink('trainlibre://analytics'), isNull);
    });

    test('the steps widget opens the steps module', () {
      expect(
          parseHomeWidgetDeepLink('trainlibre://steps'), const OpenStepsLink());
    });

    test('the measurements widget carries its configuration', () {
      expect(
        parseHomeWidgetDeepLink(
          'trainlibre://measurements?metric=waist&period=3m',
        ),
        const OpenMeasurementsLink(metricId: 'waist', periodKey: '3m'),
      );
    });

    test('a measurements link without a configuration still opens the screen',
        () {
      expect(
        parseHomeWidgetDeepLink('trainlibre://measurements'),
        const OpenMeasurementsLink(),
      );
    });

    test('an unknown period is dropped rather than taking the metric with it',
        () {
      // The screen has its own default timeframe; the metric is still worth
      // honouring.
      expect(
        parseHomeWidgetDeepLink(
          'trainlibre://measurements?metric=weight&period=2y',
        ),
        const OpenMeasurementsLink(metricId: 'weight'),
      );
    });

    test('the last workout widget opens that workout', () {
      expect(
        parseHomeWidgetDeepLink('trainlibre://workout/log/12345'),
        const OpenWorkoutLogLink(12345),
      );
    });

    test('a workout log id that is not a number is not claimed', () {
      expect(parseHomeWidgetDeepLink('trainlibre://workout/log/abc'), isNull);
      expect(parseHomeWidgetDeepLink('trainlibre://workout/log'), isNull);
    });
  });

  test('period keys stay in lockstep with the widget extension', () {
    // Mirrors MeasurementPeriod's raw values in MeasurementsWidget.swift. A
    // change here without a change there silently drops the timeframe on tap.
    expect(HomeWidgetMeasurementPeriod.all, {'7d', '1m', '3m', '6m', 'max'});
  });

  test('action keys stay in lockstep with the widget extension', () {
    // Mirrors QuickActionKind in QuickActionEntity.swift. A change here without
    // a change there produces tiles that silently do nothing.
    expect(HomeWidgetAction.all, {
      'ai_meal_capture',
      'scan_barcode',
      'start_workout',
      'add_measurement',
      'log_supplement',
      'add_liquid',
      'add_food',
    });
  });
}
