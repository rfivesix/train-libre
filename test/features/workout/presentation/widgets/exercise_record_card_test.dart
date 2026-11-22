import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/workout/presentation/widgets/exercise_record_card.dart';
import 'package:train_libre/features/workout/presentation/widgets/exercise_record_data.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/widgets/common/summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
  });

  testWidgets(
    'renders amber-outlined card without trophy icon and shows each record on its own row',
    (tester) async {
      final unitService = UnitService();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ExerciseRecordCard(
              exerciseName: 'Bench Press',
              unitService: unitService,
              records: const [
                ExerciseRecordData.weight(
                  label: 'Max. Gewicht',
                  valueKg: 100,
                  diffKg: 5,
                ),
                ExerciseRecordData.weight(
                  label: 'Volumen',
                  valueKg: 370,
                  diffKg: 20,
                  fractionDigits: 0,
                ),
                ExerciseRecordData.cardio(
                  label: 'Best Distance',
                  value: '0.5 km',
                  diff: '+0.1 km',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsNothing);
      final card = tester.widget<SummaryCard>(find.byType(SummaryCard));
      expect(card.borderColor, isNotNull);

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Max. Gewicht'), findsOneWidget);
      expect(find.text('100 kg'), findsOneWidget);
      expect(find.text('+5 kg'), findsOneWidget);
      expect(find.text('Volumen'), findsOneWidget);
      expect(find.text('370 kg'), findsOneWidget);
      expect(find.text('+20 kg'), findsOneWidget);
      expect(find.text('Best Distance'), findsOneWidget);
      expect(find.text('0.5 km'), findsOneWidget);
      expect(find.text('+0.1 km'), findsOneWidget);
    },
  );
}
