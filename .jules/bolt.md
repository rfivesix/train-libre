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
