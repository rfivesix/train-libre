// lib/features/depth_scan/domain/item_region_validator.dart

import 'models/item_region.dart';

class ValidatedItemRegions<T> {
  final T item;
  final List<ItemRegion> validRegions;
  final double kcal;

  const ValidatedItemRegions({
    required this.item,
    required this.validRegions,
    required this.kcal,
  });
}

/// Strict validation chain for AI-suggested visual regions.
///
/// Prevents faulty or confusing overlays from reaching the user interface.
class ItemRegionValidator {
  static const double minBoxArea = 0.015; // 1.5% of frame
  static const double maxBoxArea = 0.60;  // 60% of frame
  static const double maxSingleRegionSoupThreshold = 0.65; // 65% of frame -> Soup rule
  static const int maxCalloutsTotal = 5;

  /// Validates a single bounding box.
  static bool isBoxValid(List<double> box) {
    if (box.length < 4) return false;
    final x = box[0];
    final y = box[1];
    final w = box[2];
    final h = box[3];

    if (x < -0.05 || y < -0.05 || w <= 0.01 || h <= 0.01) return false;
    if (x > 1.05 || y > 1.05) return false;
    if (x + w > 1.10 || y + h > 1.10) return false;

    final area = w * h;
    return area >= minBoxArea && area <= maxBoxArea;
  }

  /// Calculates Intersection over Union (IoU) of two 2D boxes [x, y, w, h].
  static double calculateBoxIou(List<double> a, List<double> b) {
    if (a.length < 4 || b.length < 4) return 0.0;
    final ax1 = a[0];
    final ay1 = a[1];
    final ax2 = a[0] + a[2];
    final ay2 = a[1] + a[3];

    final bx1 = b[0];
    final by1 = b[1];
    final bx2 = b[0] + b[2];
    final by2 = b[1] + b[3];

    final ix1 = ax1 > bx1 ? ax1 : bx1;
    final iy1 = ay1 > by1 ? ay1 : by1;
    final ix2 = ax2 < bx2 ? ax2 : bx2;
    final iy2 = ay2 < by2 ? ay2 : by2;

    final iw = (ix2 - ix1).clamp(0.0, 1.0);
    final ih = (iy2 - iy1).clamp(0.0, 1.0);
    final interArea = iw * ih;

    final areaA = a[2] * a[3];
    final areaB = b[2] * b[3];
    final unionArea = areaA + areaB - interArea;

    if (unionArea <= 0.0) return 0.0;
    return interArea / unionArea;
  }

  /// Validates and filters candidate items with their regions.
  ///
  /// Returns a map/list of items with at most 5 total callouts, sorted by kcal contribution.
  /// If soup rule triggers or fewer than 2 valid items exist, returns empty list (no overlay).
  static List<ValidatedItemRegions<T>> validateMealItems<T>({
    required List<T> items,
    required List<ItemRegion> Function(T) regionsExtractor,
    required double Function(T) kcalExtractor,
  }) {
    if (items.isEmpty) return [];

    // Step 1: Check for Soup rule (any region covering > 65% of entire frame)
    for (final item in items) {
      for (final region in regionsExtractor(item)) {
        if (region.area >= maxSingleRegionSoupThreshold) {
          // Entire dish / soup bowl marked -> Suppress all callouts
          return [];
        }
      }
    }

    // Step 2: Validate individual regions per item
    final candidates = <ValidatedItemRegions<T>>[];

    for (final item in items) {
      final rawRegions = regionsExtractor(item);
      final validRegions = <ItemRegion>[];

      for (final r in rawRegions) {
        if (!isBoxValid(r.box)) continue;

        // Check polygon validity if present
        List<double>? sanitizedPolygon = r.polygon;
        if (sanitizedPolygon != null) {
          if (sanitizedPolygon.length < 8 || sanitizedPolygon.length > 24) {
            sanitizedPolygon = null; // Fallback to box
          }
        }

        validRegions.add(ItemRegion(
          box: [
            r.box[0].clamp(0.0, 1.0),
            r.box[1].clamp(0.0, 1.0),
            r.box[2].clamp(0.01, 1.0),
            r.box[3].clamp(0.01, 1.0),
          ],
          polygon: sanitizedPolygon,
          pieceLabel: r.pieceLabel,
        ));

        if (validRegions.length >= 4) break; // Max 4 regions per item
      }

      if (validRegions.isNotEmpty) {
        // Total area of all regions for this item must not exceed 60%
        final totalItemArea = validRegions.fold(0.0, (sum, reg) => sum + reg.area);
        if (totalItemArea <= maxBoxArea) {
          candidates.add(ValidatedItemRegions(
            item: item,
            validRegions: validRegions,
            kcal: kcalExtractor(item),
          ));
        }
      }
    }

    // Step 3: Deduplicate overlapping regions across items (IoU > 0.6)
    final deduplicated = <ValidatedItemRegions<T>>[];
    final acceptedBoxes = <List<double>>[];

    // Sort candidates by kcal descending so higher energy items have priority
    candidates.sort((a, b) => b.kcal.compareTo(a.kcal));

    for (final cand in candidates) {
      final nonOverlappingRegions = <ItemRegion>[];

      for (final reg in cand.validRegions) {
        bool overlaps = false;
        for (final accepted in acceptedBoxes) {
          if (calculateBoxIou(reg.box, accepted) > 0.6) {
            overlaps = true;
            break;
          }
        }
        if (!overlaps) {
          nonOverlappingRegions.add(reg);
          acceptedBoxes.add(reg.box);
        }
      }

      if (nonOverlappingRegions.isNotEmpty) {
        deduplicated.add(ValidatedItemRegions(
          item: cand.item,
          validRegions: nonOverlappingRegions,
          kcal: cand.kcal,
        ));
      }
    }

    // Step 4: Display limits
    // If fewer than 2 items have valid regions -> show 0 callouts (no lonely single label)
    if (deduplicated.length < 2) {
      return [];
    }

    // Return top 5 items by kcal
    return deduplicated.take(maxCalloutsTotal).toList();
  }
}
