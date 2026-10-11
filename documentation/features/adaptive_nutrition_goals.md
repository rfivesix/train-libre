# Adaptive Nutrition Goals

> Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

Train Libre lets users track a body-weight goal alongside daily calorie and macro targets. Goal progress and adaptive nutrition recommendations are produced from measurements and diary data stored by the app.

## Goal setup and trajectory

The guided goal flow records a baseline weight, target, planned pace, and (when selected) a projected date. A baseline may come from a saved measurement or a manually entered value. The app keeps one active body-composition goal; creating a replacement supersedes the previous goal and keeps its record in goal history. Users can revise or retire an active goal.

The goal dashboard presents baseline, current, and target weight, remaining progress, pace, and projected completion information. Recorded measurements are compared with a date-based trajectory. These are tracking summaries, not assessments of health or a prediction guarantee.

## Weekly reviews

The review window is seven completed days and is aligned to the active goal's start weekday. It ends on the day before that check-in weekday. The app creates a review when its goal-review synchronizer runs (including at app startup); this is not a guaranteed notification at a particular time. It creates a review for the latest due window, rather than backfilling every past week.

A review can still be created with sparse data, but it is marked as calibrating/insufficient. The review's basic data gate is at least three weight observations, at least four logged-intake days, and an available observed weight rate. Meeting that gate does not by itself authorize a nutrition adjustment: the review also evaluates trajectory status, difference from planned rate, whether logged intake differs from the current calorie target, and whether the required remaining rate passes the app's safety bound. The review may recommend keeping targets, collecting more data, changing the goal trajectory, or adjusting nutrition targets. These thresholds are product rules, not clinical standards.

## Applying recommendations

Generating a review does not automatically change active targets. The review screen's explicit apply action recalculates the current adaptive recommendation and applies its calorie and macro targets. If the goal is behind schedule or its target date needs review, the action can also propose a revised pace/date; a changed target date requires confirmation before it is saved.

The screen's “keep current” action is not a promise to leave calorie and macro targets unchanged: its current implementation recalculates and applies the latest recommendation, then dismisses the review. The separate “continue logging” action defers a review without applying targets. From the review, users can also edit the goal plan; saving that edit triggers a recommendation recalculation and application.

## Reminders and stored state

Review records, goal records, and their status/history are stored in the local database. The adaptive recommendation snapshot and settings are stored separately in local preferences. Weekly review reminders are local notifications controlled by Settings (enabled by default); a due review is marked as notified after that synchronization pass even if reminders are disabled or notification permission is unavailable, so enabling them later affects future reviews.

## Privacy and scope

Goal and recommendation values remain in local app storage. If the user has opted in to usage telemetry, review-completion events send trajectory status, confidence, decision, bucketed observation/intake counts, calorie-adjustment direction, and a macro-adjustment flag. Recommendation-generation events send counts, window length, sample-size/confidence indicators, warning level, and quality flags. These events do not include exact body-weight or calorie values. Telemetry is optional and is not needed to calculate or apply recommendations.
