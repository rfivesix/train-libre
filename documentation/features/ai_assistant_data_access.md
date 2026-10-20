# AI assistant: first data-access version

The floating assistant keeps conversations in the app database. Open **Chats**
in the overlay to return to a conversation, or start a new one. Chat history
survives closing the overlay and restarting the app.

Chat normally, or ask about workouts, diary entries, nutrition, steps, sleep, recovery,
measurements, goals, routines, or training plans. Dated data requests accept
`today`, `yesterday`, `last Sunday` (and other weekdays), `this week`,
`last week`, `this month`, `last month`, `last N days`, ISO dates
(`2026-10-18`), German dates (`18.10.2026`), locale-aware slash dates,
and two dates as a range. Dates use the device's local time
zone. The configured model decides whether app records are needed. For data
questions it proposes the smallest useful categories and period, using a
recent bounded period when the user did not state one. Only genuinely
ambiguous requests need a follow-up question. Model proposals are validated
locally before an access request is shown. Goals,
routines, and training plans are current snapshots; historical versions are
not inferred. Recovery is a current estimate based on the app's recent workout
data.

The model may receive the current user message and a short history of earlier
user messages and non-data assistant replies to interpret intent. Previous
data-grounded answers and app records are excluded from this step. Before any
app data are retrieved or sent to a model, the overlay shows the
requested categories and date scope. **Allow once** approves that one request;
**Deny** sends no app records. Pending approvals expire after 30 minutes.
Follow-up questions require a new approval. Prior answers are not included in
later model requests, because they may contain data from an earlier scope.

After a response, **Data access** shows the local audit entry: request and
decision times, provider/model, status, field names, counts, stable record
references, and a SHA-256 hash of each shared category payload. The audit
stores this manifest rather than a second copy of the personal payload. If a
read service is unavailable, the assistant reports the
error and does not send a partial data set. The selected existing provider is
used; on-device generation is available only when that provider is actually
available on the device.

This version reads app data only. It does not create or change records, start
workouts, or execute model-generated commands. Invalid or unsupported model
proposals prompt for clarification. Very large results prompt for a
shorter range before any app records are sent to a model.
