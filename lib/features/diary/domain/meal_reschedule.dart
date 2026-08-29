// lib/features/diary/domain/meal_reschedule.dart

import 'models/meal_entry.dart';
import 'models/tracked_food_item.dart';

/// A meal and its items after being moved to a new date and time.
class MealReschedule {
  final MealEntry entry;
  final List<TrackedFoodItem> items;

  const MealReschedule({required this.entry, required this.items});
}

/// The in-memory half of moving a logged meal to [newConsumedAt].
///
/// `DiaryLocalDataSource.moveMealEntryTo` writes the same move to the database.
/// This mirrors it on the objects a screen is already holding, so the screen
/// does not have to reload — and, more importantly, so that a later save of
/// those objects rewrites the timestamps it just moved instead of dragging the
/// meal's items back onto the old day.
///
/// Items are shifted by the meal's own delta rather than pinned to
/// [newConsumedAt]: an item logged ten minutes after the meal stays ten minutes
/// after it, matching what the database does.
MealReschedule rescheduleMeal({
  required MealEntry entry,
  required List<TrackedFoodItem> items,
  required DateTime newConsumedAt,
}) {
  final delta = newConsumedAt.difference(entry.consumedAt);

  return MealReschedule(
    entry: entry.copyWith(consumedAt: newConsumedAt),
    items: items
        .map(
          (tracked) => TrackedFoodItem(
            item: tracked.item,
            entry: tracked.entry.copyWith(
              timestamp: tracked.entry.timestamp.add(delta),
            ),
          ),
        )
        .toList(),
  );
}
