# Log food and review calories and macronutrients

Add foods to your Diary, choose the amount and meal, and check how the logged calories and macros compare with your daily targets.

## Add a food

1. In **Diary**, tap the floating **+** button and choose **Food** (or tap **+** inside any meal card). This opens the food search screen (`AddFoodScreen`). If you are adding food within a meal section, that meal is preselected.
2. In the food search screen, use **Catalog Search** (or the **Favorites** and **Custom Foods** tabs) to find or enter the item. For packaged foods, tap the barcode scanner icon in the search bar. The Catalog depends on the food database being available; if it has not been installed, follow the download prompt on the screen.
3. Select the food. In the quantity sheet, enter the amount in grams, choose **Breakfast**, **Lunch**, **Dinner**, or **Snack**, and check the date and time. The amount starts with the product’s portion when available, otherwise 100 g.
4. Tap **Add**. The food appears in the selected meal in **Diary**, and its nutrients contribute to that day’s totals.

The app calculates logged nutrition from the selected food’s database values and the quantity you enter. Catalog values are commonly given per 100 g, so check the food and portion before saving. For a liquid, the amount is in milliliters; the **Add to water intake** option can also record its volume, with sugar and caffeine fields when applicable.

## Create a custom food

If you cannot find an item, switch to the **Custom Foods** tab and tap **Create Food**. Enter its name and nutrient values, then save it. Nutrient fields are recorded per 100 g; use the package label to enter comparable values. You can also use the calorie calculation control to derive calories from protein, carbohydrates, and fat. Custom food values affect new logs; editing the custom food does not change historical logs.

## Read your daily totals

The **At a Glance** summary cards in **Diary** (labeled **AUF EINEN BLICK** in the German UI) show progress bars for **Calories**, **Protein**, **Carbs**, and **Fat** against your daily targets. It also shows water and an optional extra nutrient (fiber, sugar, or salt, configurable in Settings). These totals summarize the selected day. Calories and macros are calculated from foods logged for that day; a missing item or incorrect quantity changes the totals.

Targets are managed separately from food entries. To understand how Train Libre derives calorie and macro recommendations, see [Bayesian TDEE Estimator](../features/bayesian_tdee_estimator.md) and [Macronutrient Distribution](../features/macro_distribution.md). Recommendations do not automatically replace your active targets. For capture options such as meal photos, voice, and barcode behavior, see [Meal Capture Pipeline](../features/meal_capture_pipeline.md).
