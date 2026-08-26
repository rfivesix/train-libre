import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/core/media/app_media_store.dart';
import 'package:train_libre/features/workout/presentation/widgets/workout_photo_card.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/widgets/common/app_button.dart';
import 'package:train_libre/widgets/common/summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDir;

  setUp(() async {
    supportDir =
        await Directory.systemTemp.createTemp('workout_photo_card_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => supportDir.path,
    );
    AppMediaStore.instance.resetForTesting();
    await AppMediaStore.instance.ensureInitialized();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    AppMediaStore.instance.resetForTesting();
    if (await supportDir.exists()) await supportDir.delete(recursive: true);
  });

  File write(String relative, List<int> bytes) {
    final file = File(p.join(supportDir.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return file;
  }

  Widget createWidget({
    required List<String> photoPaths,
    bool isEditable = true,
    ValueChanged<List<String>>? onPhotosChanged,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: SingleChildScrollView(
          child: WorkoutPhotoCard(
            photoPaths: photoPaths,
            isEditable: isEditable,
            onPhotosChanged: onPhotosChanged,
          ),
        ),
      ),
    );
  }

  group('WorkoutPhotoCard', () {
    testWidgets('renders SizedBox.shrink when empty and not editable',
        (tester) async {
      await tester.pumpWidget(
        createWidget(photoPaths: const [], isEditable: false),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AspectRatio), findsNothing);
      expect(find.byIcon(LucideIcons.camera), findsNothing);
    });

    testWidgets(
        'renders compact summary card with camera and gallery when empty and editable',
        (tester) async {
      await tester.pumpWidget(
        createWidget(photoPaths: const [], isEditable: true),
      );
      await tester.pumpAndSettle();

      // Compact card without forced 1:1 AspectRatio and without Add photo header
      expect(find.byType(AspectRatio), findsNothing);
      expect(find.byType(SummaryCard), findsOneWidget);
      expect(find.text('Add photo'), findsNothing);
      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Choose from library'), findsOneWidget);
      expect(find.byIcon(LucideIcons.camera), findsOneWidget);
      expect(find.byIcon(LucideIcons.image), findsOneWidget);
    });

    testWidgets('hides add buttons when 4 photos are present', (tester) async {
      write('media/workouts/p1.jpg', [1, 2, 3]);
      write('media/workouts/p2.jpg', [1, 2, 3]);
      write('media/workouts/p3.jpg', [1, 2, 3]);
      write('media/workouts/p4.jpg', [1, 2, 3]);

      final paths = [
        'media/workouts/p1.jpg',
        'media/workouts/p2.jpg',
        'media/workouts/p3.jpg',
        'media/workouts/p4.jpg',
      ];

      await tester.pumpWidget(
        createWidget(photoPaths: paths, isEditable: true),
      );
      await tester.pumpAndSettle();

      // Carousel is rendered
      expect(find.byType(PageView), findsOneWidget);
      // Delete button is present in header
      expect(find.byIcon(LucideIcons.trash_2), findsOneWidget);
      // Bottom add buttons are hidden because photo count is 4
      expect(find.text('Take photo'), findsNothing);
      expect(find.text('Choose from library'), findsNothing);
    });

    testWidgets(
        'shows glass bottom menu on delete and calls onPhotosChanged on confirm',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testImageBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );

      write('media/workouts/p1.jpg', testImageBytes);
      write('media/workouts/p2.jpg', testImageBytes);

      List<String>? updatedResult;

      await tester.pumpWidget(
        createWidget(
          photoPaths: ['media/workouts/p1.jpg', 'media/workouts/p2.jpg'],
          isEditable: true,
          onPhotosChanged: (paths) => updatedResult = paths,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.trash_2), findsOneWidget);
      await tester.tap(find.byIcon(LucideIcons.trash_2));
      await tester.pumpAndSettle();

      // Glass bottom menu is shown with title and confirm button
      expect(find.text('Remove photo'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Delete in glass bottom menu
      final deleteBtn =
          tester.widgetList<AppButton>(find.byType(AppButton)).last;
      deleteBtn.onPressed?.call();
      await tester.pumpAndSettle();

      expect(updatedResult, ['media/workouts/p2.jpg']);
    });

    testWidgets('renders borderless squircle photo without SummaryCard in view mode',
        (tester) async {
      write('media/workouts/p1.jpg', [1, 2, 3]);
      write('media/workouts/p2.jpg', [1, 2, 3]);

      await tester.pumpWidget(
        createWidget(
          photoPaths: ['media/workouts/p1.jpg', 'media/workouts/p2.jpg'],
          isEditable: false,
        ),
      );
      await tester.pumpAndSettle();

      // In view mode: No SummaryCard frame and no "Add photo" header
      expect(find.byType(SummaryCard), findsNothing);
      expect(find.text('Add photo'), findsNothing);
      expect(find.byType(PageView), findsOneWidget);
      // Top-right counter badge is rendered on multi-photo
      expect(find.text('1 of 2'), findsOneWidget);
      // No trash button
      expect(find.byIcon(LucideIcons.trash_2), findsNothing);
    });
  });
}
