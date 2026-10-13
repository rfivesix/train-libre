# Configure and use AI Meal Capture

Set up an AI provider, photograph a meal or describe it by typing or voice dictation, review the matched foods, and save the meal to your Diary. Photo and voice input are part of **AI Meal Capture**; they do not send your entire Diary or other app screens to the AI.

## Set up AI Meal Capture

1. Open **Profile > Settings > AI Meal Capture**.
2. Turn on **Enable AI Features**. When this is off, AI actions are hidden in the app; in **Nutrition Explorer**, the search-row action opens the barcode scanner instead of AI Meal Capture.
3. Under **AI Model & Provider**, choose a provider. The available options depend on your device and configuration. Cloud providers require their own API key; the provider and model list can change. For Apple Intelligence, the option appears only on iOS when the system model is available.
4. For a provider that uses a key, enter it in **API Key** and tap **Save Key**. For **Ollama**, enter **Local Model Name**. For **Custom OpenAI Compatible**, enter **Custom Base URL** and **Custom Model Name**; add an API key if your endpoint requires one. Tap **Save Key** or **Save Settings**, then tap **Test** to check the connection.
5. If needed, expand **Advanced Options** and adjust **Request Timeout**. Read the **Privacy** notice on this screen for what is sent for the selected provider.

## Capture a meal

1. In **Diary**, tap **+**, choose **add Food**, then tap the AI action beside the food search field. This opens **AI Meal Capture** when AI features are enabled.
2. Take a photo with the shutter or choose photos from the library. You can add up to four photos. To describe the meal instead, tap the pencil button, enter a description, and tap the check button. You can combine text and photos.
3. To dictate, tap the microphone. Start recording, speak, then tap to finish. Check and correct the transcript, then choose **Use this text**. The app asks for microphone and speech-recognition access when needed. If the device cannot transcribe locally, the screen explains that audio is sent to the system speech recognizer for transcription.
4. Tap **Analyze meal** or **Analyze text**. While the camera is open, barcodes are detected automatically; use the barcode button to pause or resume detection. A recognized product can be logged directly with **Log**.

## Review and save

1. Check each suggested ingredient and its matched catalog food. Tap an ingredient to inspect its match; tap an unmatched item to search for a replacement.
2. To edit the list, tap **Edit**, then adjust an amount, replace or remove an item, or choose **Add item manually**. Amounts are entered in grams. If the match or portion estimate is uncertain, check it against the food and portion you actually ate.
3. Tap the displayed date and time to change when you ate the meal, then choose **Breakfast**, **Lunch**, **Dinner**, or **Snack** and tap **Save to Diary**. The matched foods are added to that time and meal. If some items have no usable catalog match, Train Libre asks whether to save only the matched items; unmatched items are not added.

The analysis estimates ingredients and portions. Train Libre matches those suggestions to its food catalog to calculate nutrition; check the matches and amounts before saving. For how matching and validation work, see [BYOK AI Meal Capture & Validation](../features/byok_ai_validation.md). For capture paths, barcode behavior, voice handling, and data flow, see [Meal Capture Pipeline](../features/meal_capture_pipeline.md). On supported devices, photo capture may also use depth information; see [Depth Scale Hint](../features/depth_scale_hint.md).
