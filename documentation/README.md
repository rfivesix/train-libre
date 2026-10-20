# Train Libre Documentation

This suite has three sections for different readers. Use the [public documentation site](https://trainlibre.com/docs/) to browse the generated pages.

## User Guide

For people using the app who need task-based instructions, including workouts, plans, nutrition, statistics, notifications, health data, and backups, start with the [User Guide overview](user_guide/overview.md).

For AI-assisted routines, see [Create a workout routine with an AI assistant](user_guide/ai_workout_routines.md) or its [public guide page](https://trainlibre.com/docs/user-guide/ai-workout-routines/). It uses the existing routine import format and the [OpenExerciseDB exercise search](https://rfivesix.github.io/OpenExerciseDB/exercise-search.html) and [JSON catalog](https://rfivesix.github.io/OpenExerciseDB/exercises.json) for exercise IDs.

## Features & Heuristics

These pages explain how user-facing features work, what inputs and rules they use, and where their limitations are. They are not step-by-step user instructions or developer implementation guides. Start with [Feature Capabilities and Privacy Boundaries](features/overview.md), then choose a topic:

- [Bayesian TDEE Estimate and Adaptive Calorie Target](features/bayesian_tdee_estimator.md)
- [Macronutrient Distribution](features/macro_distribution.md)
- [Adaptive Nutrition Goals](features/adaptive_nutrition_goals.md)
- [Macronutrient Analytics](features/macro_analytics.md)
- [Manual Workout Plans](features/manual_workout_plans.md)
- [Workout Progression](features/workout_progression_engine.md)
- [Estimated 1-Rep Max](features/intelligent_workouts.md)
- [Muscle Recovery](features/muscle_recovery_model.md)
- [Sleep Health Score](features/sleep_scoring_engine.md)
- [Workout Live Activity](features/live_activity_workout.md)
- [Meal Capture Pipeline](features/meal_capture_pipeline.md)
- [BYOK AI Meal Capture and Validation](features/byok_ai_validation.md)
- [Depth Scale Hint](features/depth_scale_hint.md)
- [Health Sync and Export](features/health_sync_export.md)

## Developer Documentation

For contributors, start with the [Developer Documentation overview](developer/overview.md). The developer section covers [system architecture and database lifecycle](developer/architecture.md), [data flow and state lifecycle](developer/data_flow_and_state.md), [localization architecture](developer/localization_architecture.md), [food search](developer/food_search.md), and [home-screen widgets](developer/ios_home_screen_widgets.md).

