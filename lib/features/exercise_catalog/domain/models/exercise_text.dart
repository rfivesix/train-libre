import 'package:flutter/foundation.dart';

/// The texts of one exercise in one language.
///
/// The catalog ships 22 of these per exercise and the registry is a file in
/// the data repo, so nothing here may be keyed by a language known at compile
/// time. That is the whole reason this type exists instead of four flat
/// `nameDe`/`nameEn`/`descriptionDe`/`descriptionEn` fields.
@immutable
class ExerciseText {
  final String name;
  final String description;

  const ExerciseText({required this.name, this.description = ''});

  bool get isEmpty => name.trim().isEmpty;

  ExerciseText copyWith({String? name, String? description}) => ExerciseText(
        name: name ?? this.name,
        description: description ?? this.description,
      );

  @override
  bool operator ==(Object other) =>
      other is ExerciseText &&
      other.name == name &&
      other.description == description;

  @override
  int get hashCode => Object.hash(name, description);

  @override
  String toString() => 'ExerciseText($name)';
}

/// Resolves which language's texts to show, in order.
///
/// The tail is fixed: English, then German. English because it is the one
/// language the catalog is curated in end to end, German because this app's
/// own content started there and some rows still have nothing else.
///
/// Whether the *requested* language makes the list is a question for the data
/// repo, answered by `catalog_languages.displayable` — see
/// [ExerciseLocaleChain]. This function only knows the ordering.
List<String> exerciseLocaleChain(String languageCode, {bool include = true}) {
  final requested = languageCode.trim().toLowerCase();
  return {
    if (include && requested.isNotEmpty) requested,
    'en',
    'de',
  }.toList(growable: false);
}
