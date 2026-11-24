import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/cloud_overlay/header_glass_button.dart';
import 'package:train_libre/widgets/common/camera_shutter_button.dart';

void main() {
  testWidgets(
    'Android camera controls blur inside their circles without rims',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const flash = ValueKey('flash');
      const shutter = ValueKey('shutter');
      var flashTaps = 0;
      var shutterTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeaderGlassButton(
                  key: flash,
                  icon: Icons.flash_on,
                  tooltip: 'Flash',
                  isDarkSurface: true,
                  useCameraGlass: true,
                  platformViewBackdrop: true,
                  backgroundColor: Colors.lime,
                  onPressed: () => flashTaps++,
                ),
                CameraShutterButton(
                  key: shutter,
                  label: 'Take photo',
                  overPlatformView: true,
                  onPressed: () => shutterTaps++,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveGlass), findsNothing);
      for (final key in [flash, shutter]) {
        final control = find.byKey(key);
        final dimension = key == flash ? 44.0 : CameraShutterButton.dimension;
        final clip = find.descendant(
          of: control,
          matching: find.byType(ClipRRect),
        );
        expect(tester.getSize(control), Size.square(dimension));
        expect(
          tester.widget<ClipRRect>(clip).borderRadius,
          BorderRadius.circular(dimension / 2),
        );
        expect(
          find.descendant(of: clip, matching: find.byType(BackdropFilter)),
          findsOneWidget,
        );
        final boxes = tester.widgetList<DecoratedBox>(
          find.descendant(of: control, matching: find.byType(DecoratedBox)),
        );
        expect(
          boxes.map((box) => (box.decoration as BoxDecoration).border),
          everyElement(isNull),
        );
      }

      await tester.tap(find.byKey(flash));
      await tester.tapAt(
        tester.getCenter(find.byKey(shutter)) + const Offset(35, 0),
      );
      expect(flashTaps, 1);
      expect(shutterTaps, 1);
    },
  );
}
