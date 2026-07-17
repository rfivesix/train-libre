## 2024-11-20 - Fast Reactive UseCases
**Learning:** `CalculateDailyNutritionUseCase` is executed extremely frequently (e.g. debounced at 16ms in `DiaryViewModel`) on the main thread whenever any diary data changes. Nested loops inside this use case (like iterating over all food entries for every single fluid entry) caused significant performance degradation.
**Action:** Always aim for O(N) complexity in synchronous use cases that are executed reactively in ViewModels. Pre-filter arrays, avoid redundant map lookups, and pull mathematically constant expressions (like `entry.quantityInGrams / 100.0`) out of repeated loops.
## 2024-05-19 - Removed O(N) intermediate lists in calculate_daily_nutrition_use_case.dart
**Learning:** `CalculateDailyNutritionUseCase` runs frequently (e.g., debounced at 16ms) in this codebase, so any memory allocation like `.toList()` or control-flow exceptions (`firstWhere` with `try-catch`) inside it cause significant main-thread blocking overhead.
**Action:** Always favor single-pass `for` loops for data accumulation over chained Iterable methods (`where().toList().forEach()`) in core synchronous UseCases, and strictly avoid control-flow exceptions.
## 2024-11-20 - Set Building over Iterable Pipelines
**Learning:** High-frequency rendering view models often use `where(...).toList()` paired with `.map(...).toSet().toList()` to filter distinct data subsets from a master list (like getting unique IDs from active entities). This O(4N) pipeline generates numerous intermediate arrays to be GC'd.
**Action:** Replace functional-style `.where(...).toList().map(...)` chains with a single `for` loop that evaluates the condition and directly `add`s elements into native `Set` objects, cutting traversal down to O(N) and averting list allocation.
