import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android disables PostHog automatic setup before telemetry consent', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(
      manifest,
      contains('<meta-data android:name="com.posthog.posthog.AUTO_INIT" '
          'android:value="false" />'),
    );
  });
}
