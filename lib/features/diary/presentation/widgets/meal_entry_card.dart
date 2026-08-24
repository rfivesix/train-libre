// lib/features/diary/presentation/widgets/meal_entry_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../domain/models/meal_entry.dart';
import '../../domain/models/tracked_food_item.dart';
import '../../../../widgets/common/glass_actionable_card.dart';

/// Card widget representing a grouped meal in the Diary screen (Screens D1, D2, D6a).
class MealEntryCard extends StatefulWidget {
  final MealEntry mealEntry;
  final List<TrackedFoodItem> items;
  final VoidCallback? onTapDetail;
  final VoidCallback? onLongPressMeal;
  final ValueChanged<TrackedFoodItem>? onEditItem;
  final Future<void> Function(int)? onDeleteItem;

  const MealEntryCard({
    super.key,
    required this.mealEntry,
    required this.items,
    this.onTapDetail,
    this.onLongPressMeal,
    this.onEditItem,
    this.onDeleteItem,
  });

  @override
  State<MealEntryCard> createState() => _MealEntryCardState();
}

class _MealEntryCardState extends State<MealEntryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F1F1E) : const Color(0xFFF1F1EA);
    final titleColor = isDark ? Colors.white : const Color(0xFF12120F);
    final subtitleColor = isDark ? const Color(0xFF8A8A82) : const Color(0xFF6A6A62);
    final branchLineColor = isDark ? const Color(0xFF33332E) : const Color(0xFFD6D6C8);

    // Compute totals
    int totalKcal = 0;
    for (final it in widget.items) {
      final factor = it.entry.quantityInGrams / 100.0;
      totalKcal += (it.item.calories * factor).round();
    }

    final timeStr = DateFormat('HH:mm').format(widget.mealEntry.consumedAt);
    final countStr = '${widget.items.length} ${widget.items.length == 1 ? "Zutat" : "Zutaten"} · $timeStr';
    final hasPhoto = widget.mealEntry.photoPath != null &&
        widget.mealEntry.photoPath!.isNotEmpty &&
        File(widget.mealEntry.photoPath!).existsSync();

    return GlassActionableCard(
      dismissibleKey: Key('meal_entry_${widget.mealEntry.id}'),
      onEdit: widget.onTapDetail,
      onDelete: widget.onLongPressMeal,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTapDetail,
              onLongPress: widget.onLongPressMeal,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Photo Thumbnail (48x48) if photo exists (D1), else flush left (D6a)
                    if (hasPhoto) ...[
                      _buildPhotoThumb(isDark),
                      const SizedBox(width: 12),
                    ],

                    // Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.mealEntry.title ?? 'Mahlzeit',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: titleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            countStr,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Kcal and Expand Toggle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalKcal kcal',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              _isExpanded ? LucideIcons.chevron_up : LucideIcons.chevron_down,
                              size: 16,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expanded In-Place Sub-Items (Screen D2)
            if (_isExpanded && widget.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 36, right: 12, bottom: 12),
                child: Stack(
                  children: [
                    // Vertical Tree Line
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 12,
                      child: Container(
                        width: 1.5,
                        color: branchLineColor,
                      ),
                    ),

                    // Sub-ingredient rows
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Column(
                        children: widget.items.map((tracked) {
                          final factor = tracked.entry.quantityInGrams / 100.0;
                          final itemKcal = (tracked.item.calories * factor).round();

                          return GlassActionableCard(
                            dismissibleKey: Key('meal_item_${tracked.entry.id}'),
                            onEdit: () => widget.onEditItem?.call(tracked),
                            onDelete: () => tracked.entry.id != null
                                ? widget.onDeleteItem?.call(tracked.entry.id!)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            tracked.item.name,
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: titleColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${tracked.entry.quantityInGrams} g',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '$itemKcal kcal',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFFD6D6C8) : const Color(0xFF3A3A34),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumb(bool isDark) {
    final photoPath = widget.mealEntry.photoThumbPath ?? widget.mealEntry.photoPath;
    final file = photoPath != null ? File(photoPath) : null;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF2B2B27) : const Color(0xFFD6D6CE),
      ),
      clipBehavior: Clip.antiAlias,
      child: file != null && file.existsSync()
          ? Image.file(file, fit: BoxFit.cover)
          : Center(
              child: Text(
                'FOTO',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
                  color: isDark ? const Color(0xFF7E7E74) : const Color(0xFF9A9A90),
                ),
              ),
            ),
    );
  }
}
