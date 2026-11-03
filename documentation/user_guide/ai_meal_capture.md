# Configure and use AI Meal Capture

Set up an AI provider, photograph a meal or describe it by typing or voice dictation, review the matched foods, and save the meal to your Diary. Photo and voice input are part of **AI Meal Capture**; they do not send your entire Diary or other app screens to the AI.

## Set up AI Meal Capture

1. Open **Profile > Settings > AI Features**.
2. Turn on **Enable AI Features**. When this is off, AI actions are hidden in the app; in **Nutrition Explorer**, the search-row action opens the barcode scanner instead of AI Meal Capture.
3. Under **AI Model & Provider**, choose a provider. The available options depend on your device and configuration. Cloud providers require their own API key; the provider and model list can change. For Apple Intelligence, the option appears only on iOS when the system model is available.
4. For a provider that uses a key, enter it in **API Key** and tap **Save Key**. For **Ollama**, enter **Local Model Name**. For **Custom OpenAI Compatible**, enter **Custom Base URL** and **Custom Model Name**; add an API key if your endpoint requires one. Tap **Save Key** or **Save Settings**, then tap **Test** to check the connection.
5. Under **Nutrition estimation method**, choose **Direct AI estimate** (the default) or **Local food catalog**. Direct estimates save estimated nutrition without finding catalog products; catalog mode matches suggestions to installed foods. Both require review. You can also hide the floating assistant independently with **Show floating AI assistant**; chat remains available from the Add menu.
6. If needed, expand **Advanced Options** and adjust **Request Timeout**. Read the **Privacy** notice on this screen for what is sent for the selected provider.

## Capture a meal

1. In **Diary**, tap **+**, choose **add Food**, then tap the AI action beside the food search field. This opens **AI Meal Capture** when AI features are enabled.
2. Take a photo with the shutter or choose photos from the library. You can add up to four photos. To describe the meal instead, tap the pencil button, enter a description, and tap the check button. You can combine text and photos.
3. To dictate, hold the microphone while speaking and release it to finish. Review the displayed transcript before analysis. The app asks for microphone and speech-recognition access when needed. If the device cannot transcribe locally, the screen explains that audio is sent to the system speech recognizer for transcription.
4. Tap **Analyze meal** or **Analyze text**. While the camera is open, barcodes are detected automatically; use the barcode button to pause or resume detection. A recognized product can be logged directly with **Log**.

## Review and save

1. Check each suggested ingredient, portion and nutrition estimate. In **Local food catalog** mode, inspect the matched food and search for a replacement when needed. In **Direct AI estimate** mode, nutrition is estimated by the AI instead of matched to a catalog product.
2. To edit the list, tap **Edit**, then adjust an amount, replace or remove an item, or choose **Add item manually**. Amounts are entered in grams. If the match or portion estimate is uncertain, check it against the food and portion you actually ate.
3. Tap the displayed date and time to change when you ate the meal, then choose **Breakfast**, **Lunch**, **Dinner**, or **Snack** and tap **Save to Diary**. The matched foods are added to that time and meal. In catalog mode, if some items have no usable match, Train Libre asks whether to save only the matched items; unmatched items are not added.

The analysis estimates ingredients and portions. Direct estimates can also be wrong about nutrition; in catalog mode the selected catalog values determine nutrition. Check amounts and values before saving. For how matching and validation work, see [BYOK AI Meal Capture & Validation](../features/byok_ai_validation.md). For capture paths, barcode behavior, voice handling, and data flow, see [Meal Capture Pipeline](../features/meal_capture_pipeline.md). On supported devices, photo capture may also use depth information; see [Depth Scale Hint](../features/depth_scale_hint.md).
