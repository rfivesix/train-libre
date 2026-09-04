import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/exercise_catalog/domain/body_slug_mapper.dart';
import 'package:train_libre/features/exercise_catalog/domain/muscle_vocabulary.dart';
import 'package:train_libre/generated/app_localizations.dart';

/// Coarsening a muscle list is not the same as coarsening each of its names.
///
/// Front and rear deltoid both resolve to the shoulder region, and naming them
/// one at a time prints "Shoulders, Shoulders" — the failure this file exists
/// to keep out.
MuscleVocabulary _shoulderVocabulary({bool withGroupName = true}) {
  return MuscleVocabulary(
    byId: const {
      'shoulders': MuscleNode(
        id: 'shoulders',
        parentId: null,
        level: 'group',
        groupId: 'shoulders',
        legacyGroup: null,
        bodySlugs: ['front-deltoids', 'back-deltoids'],
      ),
      'front_deltoid': MuscleNode(
        id: 'front_deltoid',
        parentId: 'deltoid',
        level: 'head',
        groupId: 'shoulders',
        legacyGroup: null,
        bodySlugs: ['front-deltoids'],
      ),
      'rear_deltoid': MuscleNode(
        id: 'rear_deltoid',
        parentId: 'deltoid',
        level: 'head',
        groupId: 'shoulders',
        legacyGroup: null,
        bodySlugs: ['back-deltoids'],
      ),
    },
    namesById: {
      if (withGroupName) 'shoulders': const {'en': 'Shoulder region'},
      'front_deltoid': const {'en': 'Front deltoid'},
      'rear_deltoid': const {'en': 'Rear deltoid'},
    },
  );
}

Future<List<String>> _names(
  WidgetTester tester, {
  required MuscleVocabulary vocabulary,
  required bool coarse,
}) async {
  late List<String> names;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          names = BodySlugMapper.localizeAll(
            context,
            const ['front_deltoid', 'rear_deltoid'],
            vocabulary: vocabulary,
            coarse: coarse,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return names;
}

void main() {
  testWidgets('pro keeps every head under its own name', (tester) async {
    expect(
      await _names(
        tester,
        vocabulary: _shoulderVocabulary(),
        coarse: false,
      ),
      ['Front deltoid', 'Rear deltoid'],
    );
  });

  testWidgets('below pro the two heads become one region', (tester) async {
    expect(
      await _names(
        tester,
        vocabulary: _shoulderVocabulary(),
        coarse: true,
      ),
      ['Shoulder region'],
    );
  });

  testWidgets('a group the catalog has not translated still reads as a group',
      (tester) async {
    // The group key falls through to the app's own muscle strings rather than
    // surfacing "Front_deltoid" — which is what the head's id would have done.
    expect(
      await _names(
        tester,
        vocabulary: _shoulderVocabulary(withGroupName: false),
        coarse: true,
      ),
      ['Shoulders'],
    );
  });
}
