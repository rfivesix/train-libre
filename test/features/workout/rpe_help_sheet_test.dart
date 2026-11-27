import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:train_libre/features/app/presentation/widgets/glass_bottom_menu.dart';
import 'package:train_libre/features/workout/presentation/widgets/rpe_help_sheet.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  testWidgets('RPE guide uses glass sheet and explains three effort levels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showRpeHelpSheet(context),
              child: const Text('Open guide'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open guide'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassBottomMenuSheet), findsOneWidget);
    expect(find.text('Maximum effort'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Moderate'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });
}
