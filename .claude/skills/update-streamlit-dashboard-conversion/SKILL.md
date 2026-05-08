---
name: update-streamlit-dashboard-conversion
description: "Fetch and start working on a Snowflake Streamlit app in this repository. Use when user provides a Streamlit database/schema and optionally an identifier, title, or slug. Uses a bundled fetch script asset directly (no runtime copy into sage), maps Snowflake object names to human-friendly title slugs, and mirrors files into sage/<schema>/streamlit/<slug>/."
argument-hint: "DATABASE SCHEMA [IDENTIFIER_OR_SLUG]"
---

# Work On Snowflake Streamlit App

## Purpose

Use this skill to begin Streamlit migration/editing work by first pulling app code from Snowflake into this repository.

The app must be fetched into:

- `sage/<schema_lower>/streamlit/<slug>/`

where `slug` is derived from the Streamlit title and formatted as:

- lowercase
- punctuation/special characters removed
- spaces collapsed to `_`

Example: `Phil's testing dashboard` -> `phils_testing_dashboard`

## Inputs

- Required: database
- Required: schema
- Optional: identifier (may be Snowflake object name, title, or slug)

## Script Execution (Default Configuration)

The fetch script source of truth is the bundled skill asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/fetch_streamlit_app.sh`

Before any fetch action, run this asset script directly with `bash`.

## Required First Step

Always do this step before making any app code edits:

1. Use the bundled asset script directly from `.github/skills/update-streamlit-dashboard-conversion/assets/fetch_streamlit_app.sh`.
2. Resolve which Streamlit object to fetch (details below).
3. Run:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/fetch_first_step.sh`

This script writes files into the title-based slug directory.

## Object Resolution Rules

### If identifier is provided

Try to resolve it in this order using machine-readable output:

1. Exact Snowflake object name match.
2. Slug match derived from Streamlit title.
3. Exact title match.

Use JSON output from Snowflake CLI:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/list_streamlit_json.sh`

For each object, derive slug from the `title` using:

- lowercase
- remove `[^a-z0-9\s_]`
- collapse `[\s_]+` to `_`
- trim `_`

If no unique match, show candidate slugs and ask user to choose.

### If identifier is not provided

Do not auto-pick. Instead:

1. List all Streamlit objects in JSON.
2. Build display rows as `slug (title)`.
3. Present the rows as a clickable multiple-choice list (numbered options the user can click/select).
4. Fetch only after the user selects one.

If the chat surface supports interactive choices, use them. If not, provide a numbered list where each option is a clickable slug label and wait for explicit user selection.

## User Communication Rules

- Always communicate Streamlit options and selections using slug, not random Snowflake object names.
- If Snowflake object name is needed internally (for fetch), keep it internal and avoid leading with it in user-facing text.
- When multiple apps exist, present a concise numbered list of slugs and titles.

## Validation After Fetch

After running the fetch script:

1. Confirm destination directory exists under `sage/<schema_lower>/streamlit/<slug>/`.
2. Confirm key files exist when present in source (typically `streamlit_app.py`, `environment.yml`).
3. Report the selected slug and local path to the user.

## Pin Streamlit Major Version

After fetch validation, ensure each app `environment.yml` pins the Streamlit dependency to a major version.

1. Open the app's `environment.yml`.
2. Ensure dependencies include a pinned major version entry in this format:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/streamlit_major_pin.yml`

3. If `streamlit` is missing, add `- streamlit=1.*` under `dependencies`.
4. If `streamlit` is present but unpinned (or pinned differently), update it to `- streamlit=1.*` unless the user explicitly requests another major version.

## Qualify Unqualified SQL Identifiers

After fetching the app, inspect all SQL queries in the app code for unqualified table/view references (i.e., references that are just a bare name without a `database.schema.` prefix).

### Resolution process

1. Search `SYNAPSE_DATA_WAREHOUSE.information_schema.tables` for each unqualified name:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/lookup_unqualified_tables.sql`

2. For each match found, replace the unqualified reference with the fully qualified lowercase identifier: `synapse_data_warehouse.<schema_lower>.<table_lower>`.

3. If a table/view is **not found** in `SYNAPSE_DATA_WAREHOUSE`, ask the user:
   - Which database it lives in (if unknown).
   - Which schema it lives in (if unknown after checking the database's `information_schema`).

4. After all replacements, validate each unique fully qualified reference by running a lightweight query (e.g., `SELECT ... LIMIT 3`) and confirming the result set is non-empty.

5. Format all fully qualified identifiers as **lowercase**.

## Keep Single SQL Statement Per Query

When a generated query string contains multiple SQL statements, retain only the first statement and remove all subsequent statements.

### Resolution process

1. Inspect each SQL string assigned to a query function.
2. If multiple statements are present, keep content from the start through the first statement terminator.
3. Remove trailing statements entirely rather than commenting them out.
4. Clean up any now-unused parameter transform variables created only for removed statements.
5. Validate the remaining first statement executes successfully and returns a non-empty result set where expected.

## Clean Up Deprecated Streamlit Width Arguments

After conversion edits, remove deprecated `use_container_width` usage from chart/table APIs.

### Resolution process

1. Search app code for `use_container_width=`.
2. Replace each occurrence with the supported `width` argument:
   - `use_container_width=True` -> `width="stretch"`
   - `use_container_width=False` -> `width="content"` (or an explicit integer width when needed)
3. Apply this to Streamlit chart/data display calls (for example `st.line_chart`, `st.bar_chart`, `st.dataframe`) where relevant.
4. Run the app and confirm no immediate deprecation warning about `use_container_width` appears at startup/request time.

## Mirror Local and SiS Session Setup

Generated apps should support both local development and Streamlit in Snowflake (SiS) using the canonical session pattern below.

### Required session pattern

1. Add a `--local-dev` CLI flag via `argparse`.
2. Add `get_session(local_dev: bool)` that:
   - Uses `Session.builder.config("connection_name", "default").create()` for local runs.
   - Uses `get_active_session()` for SiS runs.
3. Initialize the app session through this helper (not `st.connection("snowflake").session()`).
4. Keep existing query-tag behavior when available.

### Canonical implementation snippet

Use the canonical snippet asset instead of inlining code in this skill:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/local_sis_session_pattern.py`

When applying the snippet, preserve existing query-tag behavior in the app when present.

Do not use `st.connection("snowflake").session()` for generated apps.

### Local debug workflow

### Browser Behavior During Validation (Required)

To avoid disrupting the user during validation, enforce the following:

1. During validation, run Streamlit in headless mode.
2. During validation, do **not** open the app in the system/local browser.
3. During validation, use only the integrated VS Code browser tooling to load and inspect the app.
4. Open the system/local browser **only** in the final user review step after validation has passed.

If the app is started without headless mode and opens a local browser tab/window, stop it and re-run headless before continuing validation.

For each app directory:

1. Bootstrap a conda environment from that app's `environment.yml` using non-interactive flags to avoid prompts:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/bootstrap_local_env.sh`

2. Run locally with `--local-dev` from the app directory in headless mode:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/run_local_dev.sh`

3. Validate startup output before proceeding:
   - Confirm Streamlit prints `You can now view your Streamlit app in your browser.`
   - Confirm a `Local URL:` line is present.
   - Confirm there is no immediate traceback in startup logs.

4. Validate key app behavior after startup:
   - Open the app and ensure each query-backed cell renders without a runtime exception.
   - If SQL edits were made, confirm updated queries return non-empty results when expected.

5. Clean up long-running local processes after probe/testing:
   - If run in a background terminal, stop the terminal session after collecting logs.
   - If run in a foreground shell, stop with `Ctrl+C`.

## Capture Local Runtime Errors (General)

After local startup checks, run a log-based smoke test to catch runtime errors broadly.

## Capture In-Browser Runtime Errors (Required)

Startup log scans are necessary but not sufficient. Many Streamlit rendering failures (chart typing, dataframe rendering, Vega errors, widget state exceptions) only appear after the page fully renders.

### Prerequisite

- Ensure browser chat tools are enabled (`workbench.browser.enableChatTools`) so the agent can inspect page state and console events.

### Required in-browser validation process

1. Start the app in a background terminal and keep the terminal ID.
2. Open the reported `Local URL` in the integrated browser only (not the system/local browser).
3. Capture a page snapshot/state using browser-read tools.
4. Treat any of the following as validation failures:
   - UI alert blocks containing `Error:` messages.
   - Console `error` events.
   - Known warning/error signatures tied to broken charts/tables (for example mixed-type chart errors).
5. If no failure is visible initially, interact with critical controls to force render paths:
   - refresh buttons for each query-backed panel
   - key filters/parameters (date bucket/date range)
   - at least one full page reload after interaction
6. Re-capture snapshot/state and re-check for the same failure signals.
7. Report exact evidence when failing:
   - panel name
   - copied error message text
   - whether it appeared in UI, console, or both
8. After a code fix, repeat steps 1-7 and confirm the prior error text/signature is absent.
9. Stop the background app terminal after validation.

### Automated fix loop for generic UI/runtime errors

When an in-browser error is found, follow this loop until resolved or blocked:

1. Reproduce and capture exact error text/signature.
2. Map the error to the corresponding panel/query/chart code.
3. Apply a minimal fix targeted to the failing render path.
4. Validate syntax/compile checks.
5. Re-run local app and in-browser validation.
6. Confirm the specific previous error signature no longer appears.

### Common Streamlit chart/dataframe remediation patterns

- Mixed type chart columns: reshape data so chart inputs are numeric-only series (for example pivot category -> columns, aggregate numeric values).
- Ambiguous chart encoding: specify explicit chart inputs rather than relying on automatic inference.
- Datetime axis issues: normalize to a consistent datetime type before plotting.
- Duplicate columns from query output: deduplicate column names before rendering.
- Empty-frame edge cases: guard with empty checks and render a warning/info state.

### Required smoke-test process

1. Start the app in a background terminal and keep the terminal ID.
2. Open the reported `Local URL` once in the integrated browser to trigger a request.
3. Read terminal output and scan it with the bundled helper script:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/smoke_scan_logs.sh`

4. Treat any script-reported error pattern match as a failed validation step.
5. Report pass/fail with the matched log lines (if any).
6. Stop the background terminal after log collection.

### Optional warning policy

- Also report deprecation warnings (for example `use_container_width` warnings) and either:
  - fail validation when the migration requires warning cleanup, or
  - list as non-blocking follow-up items when not in scope.

When warning cleanup is in scope, run:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/smoke_scan_logs_fail_on_warning.sh`

## Final User Review And Commit Flow (Required)

After validation is complete and before ending the workflow, run a final user-facing handoff.

1. Open the local app URL in the system browser (outside VS Code) for user review.
2. Ask the user for explicit feedback/approval of the Streamlit app.
3. If the user requests changes, apply them and repeat validation before re-requesting approval.
4. Once approved, ask whether the user wants to commit the Streamlit app changes.
5. Only if the user agrees to commit:
    - Update `.github/workflows/ci.yaml` so the app is included in the `deploy_streamlit` job matrix (`strategy.matrix.app`).
    - Add one matrix entry with:
       - `name`: human-readable Streamlit app title (not slug)
       - `path`: `sage/<schema_lower>/streamlit/<slug>`
       - `role`: `sage_<schema_lower>_admin`
    - Use the same `<schema_lower>` value in both `path` and `role`.
    - Avoid duplicate matrix entries for the same app path/title.
6. Create one non-amended commit containing all workflow/app/CI changes with message:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/commit_message.txt`

7. If the user declines commit, do not update `ci.yaml` and do not create a commit.

## Notes

- Prefer `--format JSON` for all `snow` inspection/list/describe commands.
- Avoid parsing pretty-printed table output.
- If no objects are found in the given database/schema, tell the user and ask whether to check another database/schema.
