# Adaptive Nutrition Goals

Train Libre lets users track a long-term body-weight goal alongside daily calorie and macro targets. Goal progress and nutrition recommendations are calculated on device from the user's own logs.

## Goal setup and trajectory

The guided goal flow can use a real weight measurement as its baseline. Users choose a target weight and planned pace, then review the projected date and goal summary before saving. The app supports one active goal; a replacement goal is kept in the goal history rather than silently merged with the previous one. Users can adjust or retire an active goal later.

The goal dashboard presents baseline, current, and target weight, remaining progress, pace, and a projected completion date. Recorded measurements appear against a date-based trajectory.

## Weekly reviews and recommendations

Reviews summarize recent weight and nutrition data. A review needs at least three weigh-ins and four logged calorie days in its seven-day window before it can make a data-backed recommendation. Sparse data is presented as calibration context rather than as a confident adjustment.

When the observed rate differs enough from the planned rate, Train Libre can propose revised calorie and macro targets. The proposal does not change daily targets on its own: the user can apply it, adjust the goal trajectory, or keep current targets. Applying a target proposal updates the targets while preserving the goal and its progress history.

Review cadence is anchored to the goal's start weekday. Optional local reminders can notify users when a review or other goal guidance is ready; notification preferences are managed in Settings.

## Privacy and scope

Goal calculations and records stay in the local app database. Optional usage telemetry reports only coarse event categories and does not include goal text, body-weight values, or calorie figures. Goal guidance is a tracking aid, not medical advice.
