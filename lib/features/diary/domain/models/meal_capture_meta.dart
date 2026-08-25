// lib/features/diary/domain/models/meal_capture_meta.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../depth_scan/domain/models/depth_scale_facts.dart';

/// Everything about *how* a meal was captured, stored as JSON on the meal entry.
///
/// Deliberately schemaless in the database: this is the part of the feature
/// still moving, and a nullable text column costs nothing while the shape
/// settles.
class MealCaptureMeta {
  final DepthScaleFacts? depthFacts;
  final String? provider;
  final String? model;

  /// Every photo of this meal, relative to the application support directory.
  ///
  /// Lives here rather than in its own column because a meal usually has one
  /// photo and `MealEntry.photoPath` still holds it; this only carries the
  /// extras. Regions always refer to the first photo.
  final List<String> extraPhotoPaths;

  const MealCaptureMeta({
    this.depthFacts,
    this.provider,
    this.model,
    this.extraPhotoPaths = const [],
  });

  bool get isEmpty =>
      depthFacts == null && provider == null && extraPhotoPaths.isEmpty;

  Map<String, dynamic> toMap() => {
        if (depthFacts != null) 'depth': depthFacts!.toMap(),
        if (provider != null) 'provider': provider,
        if (model != null) 'model': model,
        if (extraPhotoPaths.isNotEmpty) 'extra_photos': extraPhotoPaths,
      };

  String toJson() => jsonEncode(toMap());

  factory MealCaptureMeta.fromMap(Map<String, dynamic> map) {
    final rawDepth = map['depth'];
    return MealCaptureMeta(
      depthFacts: rawDepth is Map
          ? DepthScaleFacts.fromMap(Map<String, dynamic>.from(rawDepth))
          : null,
      provider: map['provider'] as String?,
      model: map['model'] as String?,
      extraPhotoPaths: map['extra_photos'] is List
          ? (map['extra_photos'] as List).whereType<String>().toList()
          : const [],
    );
  }

  /// Tolerant parse: malformed or outdated metadata degrades to "no extras"
  /// rather than breaking the meal it belongs to.
  static MealCaptureMeta? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return MealCaptureMeta.fromMap(Map<String, dynamic>.from(decoded));
    } catch (e) {
      debugPrint('[MealCaptureMeta] parse failed: $e');
      return null;
    }
  }
}
