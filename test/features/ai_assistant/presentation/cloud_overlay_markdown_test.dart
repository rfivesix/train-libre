import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:train_libre/features/ai_assistant/presentation/widgets/cloud_overlay/cloud_overlay_markdown.dart';

void main() {
  testWidgets('renders Markdown inside the migrated Material theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CloudOverlayMarkdown(
            rawResponse: 'A **bold** answer',
            contrastColor: Colors.white,
            softColor: Colors.black,
            isStreaming: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('answer', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
