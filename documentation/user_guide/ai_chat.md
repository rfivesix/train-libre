# Use the AI assistant

Train Libre's built-in AI chat can answer training and nutrition questions, help you explore your recorded data, and prepare changes for you to review. For example, ask it to compare your logged macros with your targets, check recovery, suggest a meal, or draft a workout routine. Answers and estimates can be wrong, and the assistant does not replace professional advice.

## Set up and open the chat

1. Open **Profile > Settings > AI Features** and turn on **Enable AI Features**.
2. Choose an available provider and model under **AI Model & Provider**. Enter and save an API key when the provider requires one. Use **Test** to check the connection. Provider availability, image support, and costs depend on the provider and model. See [AI setup](ai_meal_capture.md#set-up-ai-meal-capture) for custom endpoints and other settings.
3. Tap the floating AI cloud to open the assistant. If you prefer to hide the cloud, turn off **Show floating AI assistant** in AI Features and open **AI Chat** from the app's **+** menu instead. Hiding the cloud does not disable AI; turning off **Enable AI Features** hides AI entry points.
4. Type a question and send it. An empty chat also offers starter prompts for nutrition, recovery, and meal suggestions; select one to use its question.

You can ask general questions without asking the assistant to inspect your records. For a useful data question, name the period and what you want to compare, for example: “Compare my logged workouts over the last four weeks” or “How do today's calories and macros compare with my targets?” Missing or incomplete logs can make an answer misleading.

## Let the assistant use app data

1. Ask a question that needs your records. The assistant may show a **Data access request** listing the requested categories, period, and purpose.
2. Check the scope. Choose **Allow once** to approve the request or **Decline** to continue without sharing those records. An unanswered request expires after 30 minutes.
3. Read the answer in light of the selected period and available records. For a data-backed answer, open its more-options menu and choose **Data access** to inspect the access status and details.
4. Follow-up questions can require fresh access. Review the new request before approving it, including when it refers to a previous answer.

The chat menu includes **Automatically approve data requests**. When enabled, future requests can be approved without stopping at a permission card. Turn it off in the same menu to review requests individually again. A data-access approval concerns reading the requested records; it does not apply a proposed change.

The configured model receives your message and the approved data returned for the request. Text chat can fall back to another configured provider; a provider or configuration change can affect the recipient. Photos use a separate selected-provider check. Review **AI Features** and the provider's privacy terms before sending sensitive information. The [feature documentation](../features/ai_assistant_data_access.md) explains the access and provider boundaries in more detail.

## Review a proposed change

The assistant can prepare new or revised **routines**, **training plans**, and **recipes**, and can draft a **new meal** for the Diary. Tell it what you want, including constraints and relevant details; for an update, identify the existing item clearly. It may request access to saved items or the relevant local catalog. Review each request and approve only the scope you want to share.

When a proposal appears, expand and inspect it before choosing **Apply** or **Discard**. Check names, exercises, sets and targets, plan days, recipe ingredients and amounts, or meal time and nutrition as appropriate. Applying saves the proposed change; discarding leaves the saved data unchanged. If the proposal is wrong, ask for a correction and review the new draft. Sending another message can supersede an unapplied draft, so review the current card before applying. A newly created training plan is saved inactive; activate it in the plan screen when you are ready.

For examples and task-specific checks, see [AI workout routines](ai_workout_routines.md), [training plans](training_plans.md), [recipes](saved_meals.md), and [logging food with AI chat](ai_chat_food_logging.md). A saved meal can be edited in the Diary afterward. AI chat cannot use its meal proposal to edit an existing meal.

## Attach a photo

Use **Add image** in the composer and choose **Take photo** or **Choose from library**. You can attach up to four images; use the remove control to remove an attachment before sending. Camera and photo-library permissions may be required. Add a question describing what you want the assistant to do, then send it. If you send an image without text, the app supplies a default question that can request a food draft. Images and your message go to the model handling the request.

Image support depends on the selected provider and model. If the app reports that the model does not support images, your draft stays in the composer; select a compatible model or remove the images and try again. To log a photographed meal, explicitly ask for a Diary entry and review the proposal before applying. See [Log food with the AI chat](ai_chat_food_logging.md) for photo storage and nutrition-estimate details.

## Continue a conversation

Use **New chat** in the chat header to start a separate conversation. Open **Chat history** to select an earlier conversation from the **Chats** sidebar. Conversation history is stored locally. On a response, use the copy control to copy the answer; holding it copies the full chat. The retry control requests another response.

If a request fails, check the selected provider, saved credentials, model support and connection in **AI Features**. If a data answer is empty, check the requested dates, the records actually logged, and any relevant health permissions. If a proposal is missing or invalid, give the assistant more specific information and review the next draft; a response alone does not save changes.
