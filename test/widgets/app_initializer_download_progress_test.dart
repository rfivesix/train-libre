import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/app/presentation/app_initializer_screen.dart';
import 'package:train_libre/features/diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/widgets/common/long_running_operation_overlay.dart';
import 'package:train_libre/widgets/common/operation_progress_widget.dart';
import 'package:train_libre/widgets/common/summary_card.dart';

Widget _buildApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
      'AppInitializerScreen in modal mode uses OperationProgressWidget and no AI cloud orb',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        const AppInitializerScreen(
          forceUpdate: true,
          isModal: true,
          skipOffDatabase: true,
        ),
      ),
    );

    // Initial frame should immediately render horizontal progress widget, not AI neural orb.
    expect(find.byType(AiNeuralCloudOrbWidget), findsNothing);
    expect(find.byType(OperationProgressWidget), findsOneWidget);
    expect(find.byIcon(LucideIcons.download), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets(
      'LongRunningOperationOverlay uses OperationProgressWidget and shows percentage',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        LongRunningOperationOverlay(
          title: 'Restoring',
          initialStatus: 'Restoring database...',
          icon: LucideIcons.download,
          operation: (token, updateProgress) async {
            updateProgress('Restoring tables...', 0.45);
          },
        ),
      ),
    );

    // Frame after callback runs
    await tester.pump();
    expect(find.byType(OperationProgressWidget), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Restoring tables...'), findsOneWidget);
  });

  testWidgets(
      'OperationProgressWidget displays icon, title, detail, horizontal bar, and percentage',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        const Scaffold(
          body: OperationProgressWidget(
            icon: LucideIcons.database,
            title: 'Exporting Data',
            detail: 'Processing workouts...',
            progress: 0.68,
          ),
        ),
      ),
    );

    expect(find.byType(SummaryCard), findsOneWidget);
    expect(find.byType(AdaptiveGlass), findsOneWidget);
    expect(find.byIcon(LucideIcons.database), findsOneWidget);
    expect(find.text('Exporting Data'), findsOneWidget);
    expect(find.text('Processing workouts...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('68%'), findsOneWidget);
  });

  testWidgets(
      'OperationProgressWidget formats indeterminate state correctly without percentage',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        const Scaffold(
          body: OperationProgressWidget(
            icon: LucideIcons.cloud_upload,
            title: 'Preparing Backup',
            progress: null,
          ),
        ),
      ),
    );

    expect(find.byType(SummaryCard), findsOneWidget);
    expect(find.byIcon(LucideIcons.cloud_upload), findsOneWidget);
    expect(find.text('Preparing Backup'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets(
      'OperationProgressWidget renders detail on left and percentage on right in a single row',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        const Scaffold(
          body: OperationProgressWidget(
            icon: LucideIcons.download,
            title: 'Update Lebensmittel-Datenbank (DE)',
            detail: '105.000 / 238.930 Einträge',
            progress: 0.42,
          ),
        ),
      ),
    );

    expect(find.text('Update Lebensmittel-Datenbank (DE)'), findsOneWidget);
    expect(find.text('105.000 / 238.930 Einträge'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);

    final detailTextWidget =
        tester.widget<Text>(find.text('105.000 / 238.930 Einträge'));
    expect(detailTextWidget.maxLines, 1);
    expect(detailTextWidget.overflow, TextOverflow.ellipsis);
    expect(detailTextWidget.textAlign, TextAlign.left);

    final percentTextWidget = tester.widget<Text>(find.text('42%'));
    expect(percentTextWidget.textAlign, TextAlign.right);

    // Verify both are inside the same Row
    final rowFinder = find.ancestor(
      of: find.text('105.000 / 238.930 Einträge'),
      matching: find.byType(Row),
    );
    expect(rowFinder, findsOneWidget);
    expect(
      find.descendant(of: rowFinder, matching: find.text('42%')),
      findsOneWidget,
    );

    // Verify AdaptiveGlass icon is outside SummaryCard and positioned above it
    expect(
      find.descendant(
        of: find.byType(SummaryCard),
        matching: find.byType(AdaptiveGlass),
      ),
      findsNothing,
    );
    final iconTop = tester.getTopLeft(find.byType(AdaptiveGlass)).dy;
    final cardTop = tester.getTopLeft(find.byType(SummaryCard)).dy;
    expect(iconTop, lessThan(cardTop));
  });
}
