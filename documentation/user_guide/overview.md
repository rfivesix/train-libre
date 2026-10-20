# Train Libre User Guide

Welcome to the Train Libre User Guide. These pages explain how to use the app in practical, step-by-step workflows. This guide is currently written in English; translations can be added later.

Use this guide when you want to know how to complete a task in the app. For details about the logic behind a smart feature, see [Feature Documentation](../features/overview.md). For implementation and architecture, see [Developer Documentation](../developer/overview.md).

## Getting Started

- [Get started with Train Libre](getting_started.md): Set up your profile, units, preferences, and learn the main navigation.
- [Manage app support and privacy settings](settings_and_privacy.md): Use support tools, manage optional usage statistics, and reset local data.

## Workouts

- [Track a workout](tracking_a_workout.md): Start and finish a workout, record exercises and sets, and manage rest.
- [Supersets and edit workout entries](supersets_and_editing.md): Connect exercises into supersets and correct a saved workout.
- [Create and use workout routines](workout_routines.md): Build reusable templates and organize their exercises.
- [Find and create exercises](exercise_catalog.md): Search and filter the catalog or add a custom exercise.
- [Review workout history](workout_history.md): Open, edit, share, or reuse a completed workout.

## Training Plans

- [Create and follow a training plan](training_plans.md): Schedule routines and rest days, handle sessions, and set plan reminders.
- [Set and manage a weight goal](weight_goals.md): Create a goal, review progress, and adjust or retire it.

## Nutrition and Supplements

- [Log food and review calories and macronutrients](logging_food.md): Add foods to the Diary and read your daily totals.
- [Log caffeine and other supplements](logging_supplements.md): Record doses, manage the supplement list, and understand caffeine from drinks.
- [Choose food catalog settings](food_catalogs.md): Select the database region and food display language.
- [Create and reuse recipes](saved_meals.md): Save a meal and add it to the Diary later.
- [Configure and use AI Meal Capture](ai_meal_capture.md): Set up a provider and review a captured meal.
- [Log water and drinks](water_and_drinks.md): Record fluid amounts and review water, sugar, and caffeine totals.
- [Set daily targets](daily_targets.md): Edit calorie, macronutrient, water, and step targets.

## Body Measurements and Statistics

- [Record body weight and other measurements](measurements.md): Enter measurements and review their history and charts.
- [Read the Statistics hub](statistics.md): Navigate the hub, choose its period, and understand its cards.
- [Read training statistics](training_statistics.md): Interpret Training Rhythm, personal bests, and Muscle Groups views.
- [Read Body & Nutrition statistics](body_nutrition_statistics.md): Review weight and nutrition trends, coverage, and chart periods.
- [Connect health data](health_data.md): Enable and sync steps, sleep, pulse, and body measurements.

## Live Activities and Notifications

- [Live Activities and workout updates](live_activities.md): Use the current workout activity or notification and check platform requirements.
- [Manage notifications and reminders](notifications.md): Choose reminders and understand device notification access.
- [Use Train Libre widgets and quick actions](widgets.md): Add Home Screen widgets and Android Quick Settings shortcuts.

## Import, Export, and Your Data

- [Import workout history and other data](importing_data.md): Import workout files, health data, shared items, or restore a backup.
- [Share Train Libre data with an AI assistant](sharing_and_ai.md): Share selected summaries or exports with an AI, and understand how to import supported shared items.
- [Prepare a compatible workout CSV](prepare_csv_files.md): Choose accepted headers, units, and date formats and troubleshoot imports.
- [Exporting and backing up data](exporting_and_backing_up.md): Create restorable backups or export selected history for analysis.

## Writing and Maintaining This Guide

Each task page should explain the goal, any prerequisites, the steps in the app, the expected result, and common questions or errors. Use current app labels and screenshots where they make a workflow easier to follow. Keep instructions task-focused; link to Feature Documentation for algorithm details instead of duplicating them.

When adding a page, register it in `tool/build_docs.py` under the **User Guide** category and link it from this overview. The Markdown source in `documentation/user_guide/` is canonical; generated HTML under `docs/docs/` is built output.
