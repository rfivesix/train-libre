# Macronutrient Analytics

Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

The Statistics hub’s Nutrition card previews logged calorie and macronutrient intake for its selected time range. Opening the card passes the selected range, anchor date, and rolling-period setting to the detailed Nutrition statistics screen. This view reports diary data; it does not estimate unlogged intake.

## Time ranges and navigation

The detailed view offers 7-day, 1-month, 3-month, 6-month, 1-year, and maximum-history ranges. Anchored ranges use calendar weeks (Monday through Sunday), months, quarters, half-years, or years. Maximum history begins at January 1, 2020. The rolling option uses a duration ending today; because both endpoints are normalized to calendar dates and included, it can return one more calendar-day row than the duration label suggests. Previous/next controls and the date picker navigate anchored periods; maximum history has no period navigation.

The preview card groups daily values into averages when the selected range contains more than 31 days. The detailed chart keeps one bar per returned calendar date and provides a daily breakdown for dates with nonzero summary data. In the detailed chart, tap a bar to show that day’s values, or press and drag across bars to inspect days; the metric header otherwise shows period averages.

## What is counted

Food diary entries are joined to their local product records and scaled from each product’s per-100-gram nutrition values by the logged quantity. Entries without a matching product record do not contribute. Unlinked fluid entries contribute their recorded calories and their carbohydrate value scaled from grams per 100 ml; linked fluids and fluid entries duplicated by a fluid food entry are skipped. Fluids do not add protein or fat in this summary.

Daily calories and macros are summed, then period averages are calculated over dates with any nonzero calorie or macro data. Dates without logged values are still represented as zero-valued chart rows but are omitted from the detailed breakdown list. If the whole range has no tracked dates, the displayed averages are zero. Calories are rounded to whole kcal in the daily summary; macro values are displayed rounded to whole grams in the header and daily list.

The Nutrition hub also has a separate adaptive-recommendation card that can compare recent logged intake with a generated target. A generated recommendation does not change the active targets until the user applies it. See [Adaptive Nutrition Goals](adaptive_nutrition_goals.md) for that workflow.
