import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/app/presentation/widgets/glass_bottom_menu.dart';
import 'package:train_libre/services/theme_service.dart';
import 'package:train_libre/widgets/common/platform_adaptive_pickers.dart';

void main() {
  for (final sheet in <Widget>[
    const GlassBottomMenuSheet(contentBuilder: _content),
    const GlassPickerSheet(child: Text('Picker')),
  ]) {
    testWidgets('${sheet.runtimeType} does not follow the glass slider', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = ThemeService();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      Widget buildSheet() => ChangeNotifierProvider<ThemeService>.value(
        value: service,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: sheet),
        ),
      );
      await tester.pumpWidget(buildSheet());
      await tester.pump();
      final before = tester
          .widgetList<AdaptiveGlass>(find.byType(AdaptiveGlass))
          .map((w) => w.settings)
          .toList();
      Iterable<Color?> sheetTints() => tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((w) => w.decoration)
          .whereType<ShapeDecoration>()
          .map((decoration) => decoration.color)
          .where((color) => color != null);
      final beforeTints = sheetTints().toList();
      expect(before, isNotEmpty);
      expect(before.first.blur, 8);
      expect(beforeTints, isNotEmpty);
      await service.setGlassAppearance(1);
      await tester.pumpWidget(buildSheet());
      await tester.pump();
      final after = tester
          .widgetList<AdaptiveGlass>(find.byType(AdaptiveGlass))
          .map((w) => w.settings)
          .toList();
      expect(after.map((s) => s.blur), before.map((s) => s.blur));
      expect(after.map((s) => s.glassColor), before.map((s) => s.glassColor));
      expect(sheetTints(), beforeTints);
      await tester.pumpWidget(const SizedBox.shrink());
      service.dispose();
    });
  }
}

Widget _content(BuildContext context, VoidCallback close) =>
    const SizedBox(height: 80);
