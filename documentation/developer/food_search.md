# Food search: data flow and ranking

## Findings

The old paths differed before ranking even started. Manual search stripped everything except ASCII/German letters and searched only `products.name` and `brand`. The importer chooses the legacy `name` column according to the selected language; the UI can display another translation. Consequently a visible name did not necessarily participate in search. AI search additionally checked all six stored name columns and compact BLS compounds, and its prompt supplied German catalog terminology and synonyms.

Both paths also expanded every word ending in `er` to an unrestricted interior substring with its last two characters removed. `Bier` therefore searched for `bi` too. Source and consumption history could outrank text quality before SQL's 50-row limit. Manual retrieval then regrouped by source, and both pickers regrouped again (custom, base, OFF), undoing text ranking. Alias lookup limited raw alias rows to 30 and inserted them into a reserved tail of the canonical shortlist: duplicate aliases consumed slots and an exact alias could trail weak names. Queries used leading-wildcard scans rather than an index.

The two pickers also gated all search on OFF installation metadata, although usable base/custom foods could already be present. Their asynchronous responses had no protection against older requests completing after newer input, and clearing text did not cancel a pending debounce.

## Installed data and derived index

`BasisDataManager` imports names and available German, English, French, Italian and Japanese translations into `products`. BLS curation imports `food_aliases` into `bls_food_alias_index`, retaining language, identity/broader scope and review status. Retired BLS rows (`legacy`) and OFF rows retained for diary references (`off_retained`) remain accessible by identity but are excluded from search.

`AppDatabase.beforeOpen` creates the versioned `FoodSearchIndex` transactionally on first use and backfills the installed data. There is no change to the generated Drift table schema or to catalog source files. SQLite triggers maintain it for product/alias insert, update, replace and delete, source changes, soft deletion, and user overrides. Recursive triggers are enabled so replacement deletes also maintain the index; ignored inserts do not delete index entries. The index includes the effective override name/brand, matching the returned food. Repeated identical translation fields are omitted to avoid duplicating common OFF names.

Both FTS indexes use SQLite's [FTS5 Unicode tokenizer and prefix indexes](https://www.sqlite.org/fts5.html). The application folds common Latin accents, German umlaut transliterations and sharp S, normalizes punctuation, and preserves Japanese text. German umlauts use `ae/oe/ue`; they are not silently equated with unrelated plain vowels. Compact BLS names and aliases allow joined/spaced compounds. Raw user input never becomes FTS syntax: tokens are quoted and SQL values are bound. No suffix guessing or food-specific exception list is used.

## Manual search

`AddFoodScreen` and `GeneralFoodSelectionScreen` debounce input for 300 ms and call `searchProductsForUser` → `searchProducts` → `_searchCatalog`. Request generations discard outdated results, including during the debounce interval. Clearing cancels pending work. Availability depends on searchable local products, not OFF preferences, and existing BLS/custom foods do not trigger an automatic OFF download prompt.

`_searchCatalog` retrieves indexed candidates with every query token required inside one language variant plus the brand. Tokens from different translations cannot be combined into a fabricated name. Canonical names and alias candidates share one SQL ranking/deduplication stage with per-source partitioning (`ROW_NUMBER() OVER (PARTITION BY source ORDER BY relevance, ...)`):

1. Exact normalized name or approved identity alias (including compact BLS identity).
2. All complete query words, in any order or position; exact unreviewed/broader aliases remain weaker than identity.
3. Word-prefix matches and weaker alias matches.
4. Compact BLS prefix matches.

Candidates are partitioned by source (base, user, off) with each source retaining up to 50 results. Abundant OFF products therefore cannot displace matching BLS staple foods from the result set. In manual search, results are ordered by source priority (base = 0, user = 1, off = 2) and rendered in distinct UI sections via `FoodSearchSections`:
- **Grundnahrungsmittel**: BLS staples offering comprehensive micronutrient and macronutrient data.
- **Eigene Lebensmittel**: User-defined custom foods.
- **Weitere Treffer**: Open Food Facts (OFF) branded and packaged products.

Within each section, the most relevant matches appear first (lexical relevance > history priority > name length > name > barcode). An irrelevant BLS food cannot appear purely due to its source, as FTS requires all query tokens and filters `relevance < 4`. Category search with a nonempty query calls the same retrieval with base/category restrictions applied before its caller-specified limit; empty category browsing retains usage-based ordering. Returned entries carry canonical/localized catalog names and effective user overrides, not renamed alias labels.

## AI selection and repair

`AiMealValidationEngine.defaultMatchLoader` → `fuzzyMatchForAi` uses the same indexed retrieval for the item name, optional `catalogSearchTerm`, and `searchTerms` (at most six distinct supplied terms). A scan-local `AiCatalogSearchSession` shares recent-use scores, caches normalized terms and bounds concurrent reads to four. Generic lookup searches base/custom foods; OFF is a separate lookup only with packaging evidence or the explicit repair fallback policy, so a large OFF result set cannot consume the base shortlist.

Candidate merging retains stronger alias evidence found through a later synonym. `EvaluateFoodSourceUseCase` applies shared lexical ranking and keeps up to 15 candidates per source. Validation still has its domain-specific policy: explicit selections, original packaging evidence, preference for sufficiently close base foods, preparation-state alignment, ambiguity and nutrition checks. Only AI validation interprets a base food's parenthetical stem as an identity shortcut. Word prefixes are partial evidence, not exact identity.

An exact approved identity alias can be an exact AI match. A pending/broader alias alone remains weak retrieval evidence; a pending alias does not silently select a nutrient record. Items needing catalog repair expose at most five validated alternatives via `repairFoods`. `AiRepairCandidate` forwards canonical names, macros, source, real barcode IDs and alias review evidence. The existing repair flow only accepts IDs supplied for that item; original packaging evidence cannot be invented by a repair response.

## Verification and limits

Regression tests cover both retrieval paths, both screens, translations, punctuation and German transliteration, compounds and reversed words, brands, aliases and review evidence, source/category restrictions, ranking before caps, unwanted substrings, missing results, input syntax, overrides, replacements, source retirement, deletion, migration/reopen, OFF eligibility and the repair prompt. The synthetic performance fixture contains 100,001 products, including 12,000 competing prefix matches; it records import/query timing and checks FTS index access without a machine-dependent pass/fail time threshold.

An existing scan-runner test was checked against unmodified Git HEAD: it already failed because its expected validation count omitted the OFF fallback pass. The test now explicitly verifies the base lookup → OFF fallback → repaired-candidate validation sequence.

Synonym and translation coverage depends on the installed catalog. In particular, the legacy checked-in `assets/db/train_libre_base_foods.db` inspected for this audit (not currently included in the pubspec asset list) contains 946 foods and no `food_aliases` table; current BLS curation comes from the separate import/update path. This change does not invent missing synonyms, download catalogs or rewrite food data. There is no general typo correction, morphological stemming or arbitrary interior-substring search. Supported-language Latin folding is explicit, not a universal transliteration engine. Japanese names support literal words/prefixes; there is no Japanese morphological word segmentation. Short prefixes can still have many plausible hits. Manual results (50), AI retrieval (50 per lookup), AI per-source shortlists (15) and repair alternatives (5) remain intentionally bounded. Ambiguous variants still require validation or user selection.

Index construction adds initial disk space and startup/import work, executed in the database worker. Subsequent searches rank indexed hits, not all installed products, though very broad prefixes still cost more. The synthetic desktop benchmark is not a measurement on a phone or a million-product production catalog.
