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
    });
  });
}
