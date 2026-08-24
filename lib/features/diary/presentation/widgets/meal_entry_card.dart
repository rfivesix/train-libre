// lib/features/diary/presentation/widgets/meal_entry_card.dart

import '../../data/meal_photo_store.dart';
import '../../../../generated/app_localizations.dart';
import 'diary_food_row.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF12120F);
    final subtitleColor =
        isDark ? const Color(0xFF8A8A82) : const Color(0xFF6A6A62);
    final branchLineColor =
        isDark ? const Color(0xFF33332E) : const Color(0xFFD6D6C8);

    // Compute totals
    int totalKcal = 0;
    for (final it in widget.items) {
      final factor = it.entry.quantityInGrams / 100.0;
      totalKcal += (it.item.calories * factor).round();
    }

    final timeStr = DateFormat('HH:mm').format(widget.mealEntry.consumedAt);
    final countStr =
        '${l10n.mealIngredientCount(widget.items.length)} · $timeStr';
    final photoFile =
        MealPhotoStore.instance.resolveSync(widget.mealEntry.photoPath);
    final hasPhoto = photoFile != null && photoFile.existsSync();

    // No background of its own: this already sits inside the meal-type card,
    // and a second filled, rounded surface made the diary look like nested
    // boxes rather than one list.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Only the header is swipeable. Wrapping the whole block meant a
          // meal's swipe actions competed with those of its own ingredients,
          // which are `GlassActionableCard`s in their own right.
          GlassActionableCard(
            dismissibleKey: Key('meal_entry_${widget.mealEntry.id}'),
            onEdit: widget.onTapDetail,
            onDelete: widget.onLongPressMeal,
            // Deleting a meal asks its own question — keep the meal but drop
            // the grouping, or remove everything. The generic confirmation
            // would have been a second, differently worded dialog on top.
            confirmDelete: () async => true,
            child: // Header Row
                //
                // The photo sits *behind* the text rather than beside it, fading
                // out towards the middle. A thumbnail in front pushed the title in
                // by its own width, so meals and plain entries no longer started at
                // the same edge — the one thing this list needs to get right.
                InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTapDetail,
              onLongPress: widget.onLongPressMeal,
              child: Stack(
                children: [
                  if (hasPhoto)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        // Reaches past the left edge of the row and fades out
                        // well before the numbers on the right. The previous
                        // version stopped at a fixed fraction of the width,
                        // which left a visible vertical seam.
                        child: Transform.translate(
                          offset: const Offset(-18, 0),
                          child: ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white,
                                Colors.white,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.18, 0.72],
                            ).createShader(rect),
                            blendMode: BlendMode.dstIn,
                            child: Opacity(
                              opacity: isDark ? 0.30 : 0.20,
                              child: Image.file(
                                photoFile,
                                fit: BoxFit.cover,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        // Title & Subtitle — flush with every other row
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.mealEntry.title ??
                                    l10n.mealFallbackTitle,
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
                        const SizedBox(width: 8),
                        // Same columns as every other row, including the
                        // reserved trailing slot the chevron lives in.
                        const SizedBox(width: kDiaryAmountColumnWidth),
                        SizedBox(
                          width: kDiaryEnergyColumnWidth,
                          child: Text(
                            '$totalKcal kcal',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: titleColor,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: kDiaryTrailingColumnWidth,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Icon(
                              _isExpanded
                                  ? LucideIcons.chevron_up
                                  : LucideIcons.chevron_down,
                              size: 16,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded In-Place Sub-Items (Screen D2)
          if (_isExpanded && widget.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
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
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      children: widget.items.map((tracked) {
                        final factor = tracked.entry.quantityInGrams / 100.0;
                        final itemKcal =
                            (tracked.item.calories * factor).round();

                        return GlassActionableCard(
                          dismissibleKey: Key('meal_item_${tracked.entry.id}'),
                          onEdit: () => widget.onEditItem?.call(tracked),
                          onDelete: () => tracked.entry.id != null
                              ? widget.onDeleteItem?.call(tracked.entry.id!)
                              : null,
                          child: DiaryFoodRow(
                            name: tracked.item.name,
                            amountLabel: '${tracked.entry.quantityInGrams} g',
                            energyLabel: '$itemKcal kcal',
                            isNested: true,
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
    );
  }
}
