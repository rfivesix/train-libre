# Version 1.4.1 — Requirements

Status: planned. This document captures the scope agreed after 1.4.0. It is a requirements and audit brief, not a claim that the changes are implemented.

## Goal

Ship a focused optimisation release before 1.5.0. It should make recovery guidance easier to trust and understand, reduce cognitive load in AI meal results, and make AI food recognition more reliable.

## 1. Recovery tracker: audit, calibration and simplification

### Product outcome

A normal user should be able to answer three questions at a glance: which muscles still need recovery, how soon they can train them again, and why. The detailed inputs remain available on demand rather than competing for attention on every muscle card.

### Audit scope

- Audit the recovery model and its test coverage against current resistance-training evidence. Preserve the non-medical framing.
- Re-evaluate how set count, per-set RIR / RPE, total session fatigue, and primary versus secondary muscle involvement combine into fatigue and recovery time.
- Verify the exercise-to-muscle mapping and movement-pattern handling, including whether movement patterns should influence the user-facing explanation or only the underlying calculation.
- Review boundary cases: low-volume work, failure work, multiple sessions close together, missing RIR / RPE, body-weight and assisted exercises, and exercises with several secondary muscles.
- Document every confirmed model change, its rationale, user-visible effect, migration/recalculation behaviour, and test cases.

### UI direction

- Replace the repeated technical badges visible in the current per-muscle cards with a concise status, readiness indicator, and short plain-language reason.
- Group the screen by actionable state (for example, recover, trainable, fresh) with clear counts and an understandable legend.
- Put diagnostic values such as equivalent sets, time since meaningful load, session-fatigue context, load pressure, RIR influence, and movement-pattern detail behind an expandable “Why?” / details affordance.
- Ensure the body map, group chips, labels, colours, and readiness scale communicate the same state consistently and meet accessibility requirements beyond colour alone.
- Test the revised hierarchy with people unfamiliar with the recovery model; success means they can interpret a card without understanding “equivalent sets” or “session fatigue”.

## 2. AI meal result: calm default view, explicit editing

### Product outcome

After saving or freshly capturing an AI meal, the normal view should read as a simple meal summary. Ingredient-level quantities, matching/validation detail, and other technical information appear only when a person deliberately edits or expands them.

### Requirements

- Audit all AI meal entry, saved-meal, diary, and meal-detail screens for duplicated or unnecessarily technical information.
- Establish one compact default summary: photo when available, meal title, total calories and macros, ingredient count / concise ingredient preview, and a clear edit action.
- Provide a consistently placed, discoverable edit button on every relevant meal screen. Editing must expose ingredients, amounts, database matches, and correction actions without losing existing data.
- Move validation warnings to a clear, non-alarming summary state; surface the exact cause and repair controls in edit/detail only. Blocking validation errors must remain unmistakable before a meal can be saved.
- Keep manual, barcode, template, and AI-created meals visually coherent while retaining source-specific capabilities.
- Validate the revised flow with the reported first-use feedback: users should recognise the meal and find editing without being confronted by the full technical payload.

## 3. AI food recognition: semantic matching and quantity reliability

### Product outcome

Food identification and nutritional totals should improve through stronger deterministic matching and semantic validation, while nutrition values continue to come solely from the local food database.

### Investigation and implementation scope

- Trace representative failures end-to-end: AI extraction, generated search terms, local candidate retrieval, candidate ranking, repair prompt, final selection, portion estimate, and total calories.
- Change the extraction contract so an item can yield several purposeful catalog-search variants when needed (for example: base food, preparation/state, regional or synonym form), rather than relying on one term and its top database result.
- Retrieve and compare candidate sets across those variants. Rank them using the meal context, cooking state, ingredient role, and nutrition plausibility; do not select solely by lexical similarity.
- Strengthen semantic checks before accepting a matched item, especially raw-versus-cooked state, product-versus-generic-food mismatches, implausible energy density, portion size, and whether all chosen ingredients make sense as one dish.
- Use the existing repair loop to request a selection from verified local candidates when confidence or semantic consistency is insufficient. The model must not invent a food, database identity, calories, macros, or an unverified quantity.
- Add a measured evaluation corpus of anonymised or synthetic representative captures. Track identification accuracy, correct cooking-state selection, portion error, total-calorie error, repair frequency, and added token/latency cost before and after the change.
- Keep the experience transparent: show uncertainty and invite quick edits when confidence remains low instead of presenting a questionable match as certain.

## Delivery order

1. Recovery audit and proposed interaction model; research and acceptance criteria approved before changing calibration constants.
2. Compact AI meal presentation and consistent editing flow.
3. AI-recognition evaluation corpus, multi-query candidate retrieval, semantic re-ranking, and validation/repair improvements.

## Decisions intentionally left open

- Exact recovery formula, weights, thresholds, and whether movement patterns add a direct recovery modifier require the audit and evidence review.
- The precise compact meal layout should be selected from implementation prototypes and usability feedback.
- The number of extra catalog queries/candidates must be chosen from measured quality, latency, and BYOK token-cost trade-offs.

## Definition of done

- Automated unit, integration, and UI tests cover every changed calculation and interaction.
- The recovery model retains a visible non-medical disclaimer and human-readable explanation.
- No AI response becomes a nutrition source of truth; persisted totals remain database-derived.
- Existing meals and workout history continue to render and remain editable after upgrading.
- German, English, French, Italian, and Japanese strings and accessibility semantics are updated for user-visible changes.
