// lib/features/depth_scan/domain/models/item_region.dart

import 'dart:convert';

/// A localized continuous region of a food item in a photo.
class ItemRegion {
  /// Normalized bounding box `[x, y, width, height]`, values 0.0 to 1.0, top-left origin.
  final List<double> box;

  /// Optional polygon vertices `[x1, y1, x2, y2, ...]`, 4 to 12 points, clockwise.
  final List<double>? polygon;

  /// Optional sub-piece label (e.g. "Stück 1").
  final String? pieceLabel;

  const ItemRegion({
    required this.box,
    this.polygon,
    this.pieceLabel,
  });

  double get x => box.isNotEmpty ? box[0] : 0.0;
  double get y => box.length > 1 ? box[1] : 0.0;
  double get width => box.length > 2 ? box[2] : 0.0;
  double get height => box.length > 3 ? box[3] : 0.0;
  double get area => width * height;

  Map<String, dynamic> toMap() {
    return {
      'box': box,
      if (polygon != null) 'polygon': polygon,
      if (pieceLabel != null) 'piece_label': pieceLabel,
    };
  }

  factory ItemRegion.fromMap(Map<String, dynamic> map) {
    List<double> parseDoubles(dynamic val) {
      if (val is List) {
        return val.map((e) => (e as num).toDouble()).toList();
      }
      return [];
    }

    return ItemRegion(
      box: parseDoubles(map['box']),
      polygon: map['polygon'] != null ? parseDoubles(map['polygon']) : null,
      pieceLabel: map['piece_label'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ItemRegion.fromJson(String jsonStr) =>
      ItemRegion.fromMap(jsonDecode(jsonStr) as Map<String, dynamic>);
}
