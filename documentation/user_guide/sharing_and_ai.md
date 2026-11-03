# Share Train Libre data with an AI assistant

Share a selected workout, routine, plan, recipe, or statistics summary through the system share sheet, or export selected history from the Data Hub for analysis in another app. Train Libre shares the content named by the action you choose; the AI app receives it only after you select that app in the share sheet or upload the export there.

## Share an item or statistics summary

1. Open the item or statistics detail you want to share and tap its **Share** action or share icon.
2. Choose a format that suits the receiving app. **Formatted text** is usually easiest for a chat assistant to read. Use a **JSON** option when you want structured content that Train Libre can import again. For a workout, you can also choose an image layout.
3. In the system share sheet, select an AI assistant if it accepts the shared text or file. Otherwise, choose **Copy** where available, or save the file and upload it in the AI app.
4. Review the content in the receiving app before sending your request. Add the question you want answered and identify the dates or period you want analyzed.

Available share actions depend on the screen:

- **Workout Details:** share a workout as an image, formatted text, or portable JSON. JSON can be copied or shared as a file.
- **Routines:** share a web link when available, an image, formatted text, or portable JSON.
- **Training plans and recipes:** share a web link when available, formatted text, or portable JSON.
- **Micronutrients, Water, and Muscle Readiness:** use the share icon on the detail view to share its current summary as text. For the micronutrient data limits, see [Statistics](statistics.md#review-micronutrients).

For a complete walkthrough, see [Use the AI assistant](ai_chat.md). Open the built-in chat via the floating cloud or **AI Chat** in the Add menu. For questions about stored app data, review the requested categories and period and choose **Allow once** or **Deny**. The chat menu also offers automatic approval; when enabled, requests can proceed without a separate approval card. Follow-ups need fresh access. AI responses and proposed changes can be wrong: inspect each proposal and choose **Apply** to save or **Discard** to leave records unchanged. Text chat can fall back to another configured provider, so review the provider settings and privacy notice. See [AI assistant data access](../features/ai_assistant_data_access.md).

The in-app **AI Meal Capture** analyzes a meal description or photos that you provide. The floating AI chat can also prepare a macro-only diary meal when you explicitly ask it to log food; it shows a review card and saves attached photos with the Diary entry after you apply the draft. See [Log food with the AI chat](ai_chat_food_logging.md) and [Configure and use AI Meal Capture](ai_meal_capture.md).

## Share a broader history export

For several records or a longer date history, use **Profile > Settings > Data backup & import** to open the **Data Hub**, then export the relevant records. **Excel Export (.xlsx)** includes separate sheets for nutrition, workouts and exercises, sleep, activity and health data, and measurements. You can also export focused **Nutrition Diary**, **Measurements**, or **Workout History** files. Choose a destination in the system share sheet, then upload that file in the AI app if it accepts that format. See [Exporting and backing up data](exporting_and_backing_up.md#export-selected-history).

Check the export before sharing it: it may include a longer history and more personal detail than a single item or summary. A full backup is designed to restore Train Libre, not for AI analysis. Use a selected export when you want to control which type of history you send.

## Import supported content

If you want to bring an AI-prepared or shared item back into Train Libre, use the portable JSON format for an individual routine, training plan, recipe, or workout. In the Data Hub, choose **Import shared JSON file** or **Paste JSON text**, inspect the preview, and confirm **Import to Train Libre**. Existing items remain in place when these individual items are imported. You can also use an item’s import action in the relevant list; incoming share links show a preview before import.

For an AI-generated routine, follow [Create a workout routine with an AI assistant](ai_workout_routines.md) so exercise IDs and fields match the format Train Libre accepts. For workout history from another app, use the CSV/XLSX importer in [Import workout history and other data](importing_data.md#import-workout-history). Restoring a full backup replaces the data currently in Train Libre; see [Restore a Train Libre backup](importing_data.md#restore-a-train-libre-backup).

When you share data through the system share sheet or upload an export, the receiving app or AI provider handles that content under its own privacy rules. The in-app AI settings govern the app's AI features, while an external receiving service has its own privacy terms; review those terms before sending records.
