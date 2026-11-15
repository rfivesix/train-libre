import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:train_libre/services/haptic_feedback_service.dart';
import 'package:train_libre/widgets/common/platform_adaptive_slider.dart';

void main() {
  testWidgets('iOS supports taps, steps, RTL and disabled controls', (
    tester,
  ) async {
    double value = 10;
    var changes = 0;
    var starts = 0;
    var ends = 0;
    var enabled = true;
    var direction = TextDirection.ltr;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Directionality(
                textDirection: direction,
                child: Center(
                  child: SizedBox(
                    width: 300,
                    child: PlatformAdaptiveSlider(
                      value: value,
                      min: 10,
                      max: 30,
                      divisions: 4,
                      semanticLabel: 'Timeout',
                      semanticValue: '${value.round()} s',
                      semanticFormatter: (value) => '${value.round()} s',
                      focusNode: focusNode,
                      onChanged: enabled
                          ? (next) => setState(() {
                              value = next;
                              changes++;
                            })
                          : null,
                      onChangeStart: (_) => starts++,
                      onChangeEnd: (_) => ends++,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(find.byType(GlassSlider), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    final semantics = tester.ensureSemantics();
    final sliderSemantics = tester.getSemantics(
      find.bySemanticsLabel('Timeout'),
    );
    expect(sliderSemantics.label, 'Timeout');
    expect(sliderSemantics.value, '10 s');
    expect(sliderSemantics.increasedValue, '15 s');
    semantics.dispose();
    final bounds = tester.getRect(find.byType(GlassSlider));
    await tester.tapAt(Offset(bounds.right - 16, bounds.center.dy));
    await tester.pumpAndSettle();
    expect(value, 30);
    expect(starts, 1);
    expect(ends, 1);
    update(() => direction = TextDirection.rtl);
    await tester.pump();
    await tester.tapAt(Offset(bounds.right - 16, bounds.center.dy));
    await tester.pumpAndSettle();
    expect(value, 10);
    HapticFeedbackService.instance.setEnabled(false);
    addTearDown(() => HapticFeedbackService.instance.setEnabled(true));
    update(() {});
    await tester.pump();
    await tester.dragFrom(
      Offset(bounds.right - 16, bounds.center.dy),
      const Offset(-130, 0),
    );
    await tester.pumpAndSettle();
    expect(value, greaterThan(10));
    expect((value - 10) % 5, 0);
    final beforeKey = value;
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(value, (beforeKey + 5).clamp(10, 30));
    update(() => enabled = false);
    await tester.pump();
    final previousChanges = changes;
    await tester.tapAt(Offset(bounds.left + 16, bounds.center.dy));
    await tester.pump();
    expect(changes, previousChanges);
  });

  testWidgets('Android uses Material 3 with discrete and continuous values', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android, useMaterial3: true),
        home: const Scaffold(
          body: Column(
            children: [
              PlatformAdaptiveSlider(
                value: 0.5,
                semanticLabel: 'Continuous',
                onChanged: null,
              ),
              PlatformAdaptiveSlider(
                value: 0.5,
                semanticLabel: 'Steps',
                divisions: 4,
                onChanged: null,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(GlassSlider), findsNothing);
    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    expect(sliders.length, 2);
    expect(sliders.first.divisions, isNull);
    expect(sliders.last.divisions, 4);
    // ignore: deprecated_member_use
    expect(sliders.first.year2023, isFalse);
  });
}
