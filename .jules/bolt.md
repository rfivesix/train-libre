## 2024-11-20 - Fast Reactive UseCases
**Learning:** `CalculateDailyNutritionUseCase` is executed extremely frequently (e.g. debounced at 16ms in `DiaryViewModel`) on the main thread whenever any diary data changes. Nested loops inside this use case (like iterating over all food entries for every single fluid entry) caused significant performance degradation.
**Action:** Always aim for O(N) complexity in synchronous use cases that are executed reactively in ViewModels. Pre-filter arrays, avoid redundant map lookups, and pull mathematically constant expressions (like `entry.quantityInGrams / 100.0`) out of repeated loops.
## 2024-05-19 - Removed O(N) intermediate lists in calculate_daily_nutrition_use_case.dart
**Learning:** `CalculateDailyNutritionUseCase` runs frequently (e.g., debounced at 16ms) in this codebase, so any memory allocation like `.toList()` or control-flow exceptions (`firstWhere` with `try-catch`) inside it cause significant main-thread blocking overhead.
**Action:** Always favor single-pass `for` loops for data accumulation over chained Iterable methods (`where().toList().forEach()`) in core synchronous UseCases, and strictly avoid control-flow exceptions.
## 2024-11-20 - Set Building over Iterable Pipelines
**Learning:** High-frequency rendering view models often use `where(...).toList()` paired with `.map(...).toSet().toList()` to filter distinct data subsets from a master list (like getting unique IDs from active entities). This O(4N) pipeline generates numerous intermediate arrays to be GC'd.
**Action:** Replace functional-style `.where(...).toList().map(...)` chains with a single `for` loop that evaluates the condition and directly `add`s elements into native `Set` objects, cutting traversal down to O(N) and averting list allocation.
## 2024-05-18 - Avoid try-catch for control flow
**Learning:** Using `try-catch` blocks for control flow, particularly catching `StateError` from `firstWhere` when an item is not found, incurs a significant performance overhead in Dart. This is due to the generation of stack traces when an exception is thrown. In hot paths like Flutter's `build` methods or reactive view models (like `PlatformAdaptiveDropdownFormField` or `DiaryViewModel`), this can cause noticeable main-thread blocking and frame drops.
**Action:** Always prefer manual loops (`for (final item in items) { ... break; }`) or `collection` package helpers (like `firstWhereOrNull`) over `try-catch` with `firstWhere` to gracefully handle missing elements without throwing exceptions.
## 2024-05-19 - Removed nested pipelines in Widget build and ViewModels
**Learning:** In Flutter, the `build` method and `ViewModel` getter methods run frequently. Using combinations of `.where().toList()` and `.map()` creates numerous intermediate collections and closures that pressure the garbage collector, slowing down frame rates and increasing memory footprint.
**Action:** Replace `iterable.where(...).toList()` and chained `.map(...)` calls with standard `for` loop accumulations in critical UI or reactivity paths (like `_MealCard` rendering and `supplementLogsForSupplement`).
## 2024-11-20 - Unnecessary Iterable allocations for drift .isIn()
**Learning:** In Dart and Drift, passing a Set to `.isIn()` is supported directly because `.isIn()` takes an `Iterable<T>`. Chaining `.toList()` (e.g. `barcodesSet.toList()`) creates a redundant intermediate array allocation.
**Action:** Pass the native `Set` directly into `.isIn()` to avoid creating unneeded lists, especially in high-frequency queries or data loading operations.
## 2025-02-12 - Prevent Iterable Copying in Aggregations
**Learning:** Utility functions (like `_averageDuration` or `_meanScore` in the Sleep module) typed as `List<T>` force callers to append `.toList()` to filter pipelines. Additionally, internally combining `whereType`, `where`, and `toList` creates multiple redundant loops and intermediate garbage arrays for simple sums.
**Action:** Always type data parameters as `Iterable` rather than `List` when building aggregation helpers. Inside the function, use a single-pass `for (final item in items)` loop to check conditions and accumulate sums simultaneously. This guarantees O(1) memory and O(N) time for the calculation.
## 2025-02-12 - Optimize `_detectRoutineDelta` Complexity in `workout_summary_screen.dart`
**Learning:** Found nested loops utilizing `.where().toList()` and `.contains()` resulting in O(N^2) complexity to count occurrences of exercise names within sets inside the `_detectRoutineDelta` method.
**Action:** Replace embedded `Iterable` methods in nested loops with single-pass manual traversals that utilize HashMaps (`<String, int>{}`) for frequency counting and deduplication, lowering the time complexity to O(N) and drastically decreasing temporary object allocations.

## 2025-02-13 - Avoid eager List allocations for small local maps
**Learning:** In Dart, chaining `.toList()` after `.map()` forces memory allocation and garbage collection. For short-lived operations where we only need to iterate over the data later, leaving it as an `Iterable` is significantly more memory-efficient. Additionally, calling `.length` on a lazy `MappedIterable` whose source is a `List` delegates to the underlying list, making it O(1) and perfectly safe.
**Action:** When mapping over data arrays in reactive metrics calculations, refrain from appending `.toList()` unless random index access or mutations are actually needed.

## 2024-05-24 - [Avoid `.where().toList()` in UI bounds calculations]
**Learning:** Using chained list operations like `.where((x) => x.cond).toList()` followed by multiple `.map().reduce()` passes on small to medium collections in Flutter UI components creates unnecessary intermediate arrays and puts strain on the GC, particularly on frequent renders like charts.
**Action:** Replace functional array chaining (where/map/reduce toList pipelines) with standard single-pass `for` loops in hot UI paths that compute multiple bounds (min/max), maintaining readability while ensuring O(N) traversal and O(1) memory overhead.
## 2024-05-24 - Remove redundant Iterable allocations when finding min/max bounds in Flutter
**Learning:** Chaining `.map().reduce(math.min)` and `.reduce(math.max)` allocates temporary lists (via `.toList()`) and traverses the collection multiple times. In a framework like Flutter where data is heavily parsed for UI charts (`fl_chart`), this creates unnecessary GC pressure and redundant O(N) passes.
**Action:** Always compute boundaries (min, max, average) in a single-pass `for` loop directly accessing the underlying class attributes without mapping/reducing over intermediate iterables.

## 2025-02-14 - Optimize Sorting by Filtering First
**Learning:** Found instances where arrays were completely sorted (O(N log N)) and *then* filtered for valid elements using `.where().toList()`. This wastes CPU cycles on sorting invalid elements that will just be discarded anyway.
**Action:** Always filter data in a single O(N) pass to collect valid elements first, and then sort only the valid subset. This drops the sorting complexity to O(V log V) (where V <= N) and avoids allocating arrays for discarded data.

## 2025-02-14 - Prevent array copy in median calculations
**Learning:** Found median calculations using `.take(count).toList()` to create a slice of a sorted array before calculating the median. This creates an unneeded intermediate array and O(K) allocation when the median could be computed directly from indices.
**Action:** When computing medians on a sorted subset (like the bottom 20%), calculate the indices directly on the source array instead of slicing it into a new list.

## 2024-05-19 - Single-Pass Iteration over Chained Iterables in Live Workouts
**Learning:** In Dart/Flutter, using chained Iterable methods like `.where()`, `.map()`, and multiple `.any()` passes on highly active ViewModels (like `LiveWorkoutViewModel`) causes redundant iterations (O(M*N)) and allocates intermediate memory (`toList()`, `toSet()`). In performance-critical reactive classes, manually managing state accumulation in a single-pass loop drastically reduces overhead compared to functional-style pipelines.
**Action:** When aggregating multiple statistics or filtering items in ViewModels handling real-time data tracking (like live workouts), always prefer a single `for` loop that accumulates all flags, lists, and maps simultaneously rather than making multiple passes over the same collection.

## 2025-02-14 - Optimize Computational Pipelines by Replacing Functional Chaining with Single-Pass Loops
**Learning:** In `lib/features/sleep/data/processing/sleep_pipeline_service.dart`, calculating the standard deviation (SD) for rolling mid-sleep points utilized multiple chained array allocations: `.where().toList()`, `.map().toList()`, and `.map().reduce()`. In a reactive computational pipeline processing historical sessions, creating these intermediate arrays creates unnecessary garbage and CPU cycles.
**Action:** When computing standard deviation, variance, or other complex aggregations, replace functional array chaining with a single `for` loop to filter and accumulate the base metrics, followed by a second O(N) loop specifically over the simplified valid dataset. This eliminates redundant arrays and drops iteration complexity.

## 2025-02-15 - Fast Paths in UseCases loops
**Learning:** `CalculateDailyNutritionUseCase` loops over `allSupplements` (which can be a large list) to find any untracked supplements that have logs today, and to find the base caffeine supplement. When most daily doses are for already tracked supplements, this full loop is largely redundant but is executed anyway. Furthermore, Map `update` and `containsKey` incurs redundant hash lookups compared to checking the map directly.
**Action:** When searching an array for matching elements where we know exactly how many elements we need to find (e.g. from a Set difference), keep a running counter and `break` early from the loop once we've found all of them. Also use single hash map lookup and check against `null` instead of `update(..., ifAbsent: ...)` or `containsKey()` then `put()`.

## 2024-05-19 - Dart DateTime/Duration Instantiation in Hot Loops
**Learning:** Instantiating `DateTime` and `Duration` objects inside heavy loops (e.g., when analyzing thousands of pulse samples) causes high object allocation overhead, stressing the Dart garbage collector and leading to measurable performance degradation (taking up to 10x longer).
**Action:** Replace `DateTime`/`Duration` calculations in hot loops with direct 64-bit integer arithmetic using `microsecondsSinceEpoch` and `~/` (integer division).
