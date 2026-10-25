# AI assistant data access and change proposals

The floating assistant stores chat history locally. It can answer ordinary
questions, request a limited read of app data, and prepare supported change
proposals. Model output never directly writes a record.

## Reading app data

For data questions, the intent planner asks for the smallest useful data
categories and date scope. Before any app records are retrieved or sent to a
model, the overlay shows the requested categories and period. **Allow once**
approves that request; **Deny** sends no app records. Pending approvals expire
after 30 minutes. Follow-up questions require new approval. Previous
data-grounded answers and records are excluded from later interpretation.

After approval, selected records are copied into a separate, in-memory SQLite
database in a disposable isolate. The model receives the schema and column
meanings first, then may request read-only SQL queries. The app validates and
runs each query locally and sends only bounded results to the model. Writes,
recursive CTEs, cross joins, table-valued functions, and references outside
the approved snapshot are rejected. Large snapshots and slow queries are
bounded, and a failed read does not send partial records.

The local **Data access** audit records request and decision times,
provider/model, status, queried tables, result fields and row counts,
truncation state, and hashes of SQL and provider-bound results. It stores this
manifest rather than another copy of personal records. The selected provider
is used; on-device generation is available only when that provider is
available on the device.

## Supported changes

The assistant can prepare create or update drafts for routines, training
plans, and recipes. These drafts use the existing portable payload formats,
are locally checked against the required approved record snapshots and
catalogs, and remain pending until the user applies or discards them.

It can also prepare a new `meal_entry` from an explicit food-logging request.
This direct-estimate path does not search the user's food catalog or read their
Diary. It proposes named macro entries with amounts and per-100 g nutrients;
calories are calculated locally using the existing 4/4/9 rule. The meal and
macro rows are validated and saved together only after the user applies the
review card. The new records use the same diary summaries and detail screen as
other macro-only entries. Existing meal changes are not available through this
path.

For an image-based meal, only attachment IDs bound by the app from the current
user message can be copied into the meal. The model cannot select arbitrary
local files or supply file paths. Applying the draft copies each photo into
diary-owned media storage, separate from the chat attachments. Discarding the
draft does not create diary photos or food entries. Provider handling of the
text and photos follows the selected AI provider's terms.

See [AI assistant meal logging](ai_assistant_meal_logging.md) for the meal
payload and persistence rules, and the [AI chat food logging guide](../user_guide/ai_chat_food_logging.md)
for the user workflow.
