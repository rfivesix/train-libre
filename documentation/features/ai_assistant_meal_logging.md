# AI assistant meal logging

The floating assistant can create diary meals from text or from photos attached
to the user's current chat message. This is a direct-estimate path: it does not
search the local food catalog, create barcodes, or pretend its estimates are
catalog facts.

## Intent and review boundary

The intent planner selects meal creation only when the user explicitly asks to
log, add, or save the described food as a diary entry. Asking what is in a
photo, discussing nutrition, or attaching an image without a logging request
does not create a proposal. The planner returns a typed `meal_entry` create
proposal alongside ordinary chat, clarification, and approved-data intents.

The chat renders the proposal using the same expandable review card used for
routine, plan, and recipe changes. The user can inspect the meal name, time,
meal period, item names, amounts, and resulting macros, then apply or discard
the draft. A model response never writes to the Diary on its own. The same
proposal model can be called by another app surface later without tying meal
creation to the chat UI.

## Diary data and estimates

Each proposed item becomes a `MacroEntry` linked to one `MealEntry`. Amounts
are grams, and protein, carbohydrates, fat, and optional sugar, fiber, salt,
and caffeine are values per 100 g. Calories are derived locally from protein,
carbohydrates, and fat using Train Libre's existing 4/4/9 calculation. The
entries have no food-catalog foreign key, barcode, or favorite state, and they
use the same diary totals and detail screens as other macro-only entries.

The payload validator rejects missing required macros, non-finite or negative
values, unreasonable amounts, invalid meal periods, and malformed timestamps.
The repository stores the meal and its macro rows in one transaction. A failed
save removes any image copies created for that attempt, leaving no partial
photo-backed meal. The app assigns a stable record ID before review, so retrying
an apply after an interrupted chat-status update does not add the same meal a
second time.

## Image and provider handling

The app, rather than the model, binds proposal photos to attachment IDs from
the user message that requested logging. On approval, Train Libre verifies that
those attachments belong to the conversation and copies the full-resolution
photo (or its retained preview if the original is unavailable) into meal
storage. The first photo populates the meal's primary photo fields; additional
photos are recorded in capture metadata. Removing the chat later does not
remove diary-owned copies. Rejected proposals create no diary copies.

The meal capture metadata records the selected provider, model, and
`directEstimate` nutrition engine. As with other AI features, providers may
receive the user's text and attached photos under their own processing terms.
All saved values remain editable in the normal meal detail screen.

## Boundaries

This path creates a new meal only. It does not edit or delete existing meals,
read the user's diary to infer missing ingredients, or match foods against the
catalog. It does not attach LiDAR depth measurements, which remain part of the
separate camera-based AI Meal Capture flow. Users can change a saved entry
manually in the Diary. The model's nutrition values are estimates and should be
reviewed before confirmation.
