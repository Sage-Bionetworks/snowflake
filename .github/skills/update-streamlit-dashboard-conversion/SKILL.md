---
name: update-streamlit-dashboard-conversion
description: "Fetch and start working on a Snowflake Streamlit app in this repository. Use when user provides a Streamlit database/schema and optionally an identifier, title, or slug. Uses a bundled fetch script asset directly (no runtime copy into sage), maps Snowflake object names to human-friendly title slugs, mirrors files into sage/<schema>/streamlit/<slug>/, and always converts fetched apps to warehouse-runtime artifacts."
argument-hint: "DATABASE SCHEMA [IDENTIFIER_OR_SLUG]"
---

# Work On Snowflake Streamlit App

## Purpose

Use this skill to begin Streamlit migration/editing work by first pulling app code from Snowflake into this repository.

The app must be fetched into:

- `sage/<schema_lower>/streamlit/<slug>/`

where `slug` is derived from the Streamlit title and formatted as:

- lowercase
- remove apostrophes used in contractions (for example `Phil's` -> `phils`)
- replace all other non-alphanumeric characters (including spaces/hyphens/punctuation) with `_`
- collapse consecutive `_` into a single `_`
- trim leading/trailing `_`

Examples:
- `Phil's testing dashboard` -> `phils_testing_dashboard`
- `AMP-ALS Usage Metrics` -> `amp_als_usage_metrics`

## Inputs

- Required: database
- Required: schema
- Required: role (use `SAGE_ADMIN`)
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

```bash
source venv/snowflake/bin/activate
DATABASE="<DATABASE>" SCHEMA="<SCHEMA>" OBJECT_NAME="<OBJECT_NAME>" ROLE="<ROLE>" \
  bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/fetch_first_step.sh
```

This script writes files into the title-based slug directory.

If the object does not expose a live version URI, the fetch script automatically falls back to default and then last version URIs.
The script now accepts `ROLE` and forwards it to all `snow` commands.

## Object Resolution Rules

### If identifier is provided

Try to resolve it in this order using machine-readable output:

1. Exact Snowflake object name match.
2. Slug match derived from Streamlit title.
3. Exact title match.

Use JSON output from Snowflake CLI:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/list_streamlit_json.sh`

Run it with `DATABASE` and `SCHEMA` exported in the environment:

```bash
source venv/snowflake/bin/activate
DATABASE="<DATABASE>" SCHEMA="<SCHEMA>" ROLE="<ROLE>" \
  bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/list_streamlit_json.sh
```

For each object, derive slug from the `title` using:

- lowercase
- remove apostrophes (`'`) used in contractions
- replace remaining `[^a-z0-9]` with `_`
- collapse `[_]+` to `_`
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
2. Confirm `streamlit_app.py` exists.
3. Report the selected slug and local path to the user.

## Runtime Detection And Mandatory Warehouse Conversion

This skill must always produce warehouse-runtime app artifacts, even when the source app was created with container runtime.

### Detect source runtime

Run:

```bash
source venv/snowflake/bin/activate
snow streamlit describe "<OBJECT_NAME>" --database "<DATABASE>" --schema "<SCHEMA>" --role "<ROLE>" --format JSON
```

If `runtime_name` is `SYSTEM$ST_CONTAINER_RUNTIME_PY3_11` (or any container runtime), conversion is required.

### Mandatory conversion rules

Before SQL/chart/session edits, normalize to warehouse runtime:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/ensure_warehouse_runtime_and_artifacts.sh`

```bash
source venv/snowflake/bin/activate
DATABASE="<DATABASE>" SCHEMA="<SCHEMA>" OBJECT_NAME="<OBJECT_NAME>" ROLE="<ROLE>" \
  TARGET_ROOT="sage" STREAMLIT_MAJOR="1" \
  bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/ensure_warehouse_runtime_and_artifacts.sh
```

This script is rerunnable and performs all of the following consistently:

1. Detects current runtime and switches to `SYSTEM$WAREHOUSE_RUNTIME` when needed.
2. Verifies runtime after switch and fails fast if not exactly `SYSTEM$WAREHOUSE_RUNTIME`.
3. Creates/normalizes `environment.yml` with:
   - `python=3.11.*`
   - `snowflake-snowpark-python`
   - `streamlit=1.*` (or `STREAMLIT_MAJOR`)
4. Migrates non-Streamlit dependencies from `pyproject.toml` and/or `requirements.txt` into `environment.yml`.
5. Treats `environment.yml` as the deploy dependency source of truth.
6. Removes container-runtime dependency manifests (`pyproject.toml`, `requirements.txt`) from deploy artifacts.
7. Ensures `.streamlit/config.toml` contains the required sleep timeout block:

```toml
[snowflake.sleep]
streamlitSleepTimeoutMinutes = 5
```

8. Rewrites `snowflake.yml` to warehouse-compatible artifacts (`streamlit_app.py`, `environment.yml`, `.streamlit/config.toml`) and removes container-runtime-only packaging references.
9. Sets Streamlit project definition fields explicitly for deploy targeting:
    - Set `query_warehouse: STREAMLIT_XSMALL`.
    - Set `identifier` using object form with:
         - `name`: `<slug>`
         - `database`: `<DATABASE>`
         - `schema`: `<SCHEMA>`

Use this shape under the Streamlit entity:

```yaml
definition_version: 2
entities:
   streamlit_app:
      type: streamlit
      identifier:
         name: <slug>
         database: <DATABASE>
         schema: <SCHEMA>
      query_warehouse: STREAMLIT_XSMALL
      main_file: streamlit_app.py
      artifacts:
         - environment.yml
         - streamlit_app.py
         - .streamlit/config.toml
```

Do not skip this conversion. The workflow is complete only when the local app is warehouse-runtime compatible.

## Pin Streamlit Major Version

After warehouse conversion, ensure each app `environment.yml` pins the Streamlit dependency to a major version.

1. Open the app's `environment.yml`.
2. Ensure dependencies include a pinned major version entry in this format:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/streamlit_major_pin.yml`

3. If you ran `ensure_warehouse_runtime_and_artifacts.sh` above, this pin is already enforced.
4. If not using that script, if `streamlit` is missing, add `- streamlit=1.*` under `dependencies`.
5. If `streamlit` is present but unpinned (or pinned differently), update it to `- streamlit=1.*` unless the user explicitly requests another major version.

## Qualify Unqualified SQL Identifiers

After fetching the app, inspect all SQL queries in the app code for unqualified table/view references (i.e., references that are just a bare name without a `database.schema.` prefix).

### Resolution process

1. Search `SYNAPSE_DATA_WAREHOUSE.information_schema.tables` for each unqualified name:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/lookup_unqualified_tables.sh`

Run it with `TABLE_NAMES` set to a comma-separated list of uppercase names:

```bash
source venv/snowflake/bin/activate
TABLE_NAMES="FILE_LATEST,OBJECTDOWNLOAD_EVENT" \
  bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/lookup_unqualified_tables.sh
```

2. For each match found, replace the unqualified reference with the fully qualified lowercase identifier: `synapse_data_warehouse.<schema_lower>.<table_lower>`.

3. If a table/view is **not found** in `SYNAPSE_DATA_WAREHOUSE`, ask the user:
   - Which database it lives in (if unknown).
   - Which schema it lives in (if unknown after checking the database's `information_schema`).

4. After all replacements, validate each unique fully qualified reference by running a lightweight query (e.g., `SELECT ... LIMIT 3`) and confirming the result set is non-empty.

5. Format all fully qualified identifiers as **lowercase**.

## Replace Deprecated Tables With Event-Based Replacements

After qualifying SQL identifiers, scan all SQL queries in the app code for references to deprecated tables and replace them with their event-based replacements.

### Deprecated table mappings

| Deprecated Table | Replacement Table | Notes |
|-----------------|-------------------|-------|
| `synapse.fileupload` | `synapse_event.fileupload_event` | File upload events |
| `synapse.filedownload` | `synapse_event.objectdownload_event` | File download events (note: table renamed from filedownload to objectdownload) |
| `synapse.processedaccess` | `synapse_event.access_event` | Access/API request events |

### Resolution process

1. Search the app code for any of these deprecated table references (case-insensitive):
   - `fileupload` (when referencing `synapse.fileupload` or `synapse_data_warehouse.synapse.fileupload`)
   - `filedownload` (when referencing `synapse.filedownload` or `synapse_data_warehouse.synapse.filedownload`)
   - `processedaccess` (when referencing `synapse.processedaccess` or `synapse_data_warehouse.synapse.processedaccess`)

2. For each match found, replace with the fully qualified lowercase event table reference:
   - `synapse.fileupload` → `synapse_event.fileupload_event`
   - `synapse_data_warehouse.synapse.fileupload` → `synapse_data_warehouse.synapse_event.fileupload_event`
   - `synapse.filedownload` → `synapse_event.objectdownload_event`
   - `synapse_data_warehouse.synapse.filedownload` → `synapse_data_warehouse.synapse_event.objectdownload_event`
   - `synapse.processedaccess` → `synapse_event.access_event`
   - `synapse_data_warehouse.synapse.processedaccess` → `synapse_data_warehouse.synapse_event.access_event`

3. The replacement tables are clones of the raw tables with the same column names and types, so no query logic changes are needed beyond the table reference.

4. Run a replacement guard to catch common replacement mistakes before query execution checks:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/sql_replacement_guard.sh`

```bash
APP_FILE="sage/<schema_lower>/streamlit/<slug>/streamlit_app.py" \
UNQUALIFIED_NAMES_CSV="fileupload,filedownload,processedaccess" \
DEPRECATED_FQ_CSV="synapse_data_warehouse.synapse.fileupload,synapse_data_warehouse.synapse.filedownload,synapse_data_warehouse.synapse.processedaccess" \
   bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/sql_replacement_guard.sh
```

The guard snippet now supports both environment-variable and positional argument input and is safe to rerun.

The guard must return `PASS: sql replacement guard`. If it fails, fix the reported references and re-run.

5. After all replacements, validate each updated query by running a lightweight test query (e.g., `SELECT * FROM <table> LIMIT 3`) and confirming the result set is non-empty.

6. If a deprecated table reference appears in a comment or documentation string (not an active query), update the comment to reference the new table for accuracy.

## Keep Single SQL Statement Per Query

When a generated query string contains multiple SQL statements, retain only the first statement and remove all subsequent statements.

### Resolution process

1. Inspect each SQL string assigned to a query function.
2. If multiple statements are present, keep content from the start through the first statement terminator.
3. Ensure SQL comments in query strings use Snowflake-compatible syntax (`--` or `/* ... */`), and replace unsupported `//` comment markers when found.
4. Remove trailing statements entirely rather than commenting them out.
5. Clean up any now-unused parameter transform variables created only for removed statements.
6. Validate the remaining first statement executes successfully and returns a non-empty result set where expected.

## Clean Up Deprecated Streamlit Width Arguments

After conversion edits, remove deprecated `use_container_width` usage from chart/table APIs.

### Resolution process

1. Search app code for `use_container_width=`.
2. Replace each occurrence with the supported `width` argument:
   - `use_container_width=True` -> `width="stretch"`
   - `use_container_width=False` -> `width="content"` (or an explicit integer width when needed)
3. Apply this to Streamlit chart/data display calls (for example `st.line_chart`, `st.bar_chart`, `st.dataframe`) where relevant.
4. Run the app and confirm no immediate deprecation warning about `use_container_width` appears at startup/request time.

## Static Chart Input Validation (Required)

Before running the app locally, validate that every chart call receives only numeric (non-index) columns. This step catches mixed-type render errors without requiring a browser and must pass before proceeding to local execution.

### Why this is required

Log-based smoke scans only catch startup-level errors. Streamlit chart rendering failures (mixed column types, Vega errors, etc.) only surface after the page renders in a client — they do not appear in server logs. `WebFetch` and similar fetch tools do not work with `localhost` URLs, so direct in-browser inspection is unreliable in this environment. This static check closes that gap.

### Process

For each `st.bar_chart`, `st.line_chart`, `st.area_chart`, or any other `st.*chart` call in the app:

1. Identify the query function that feeds data to the chart cell.
2. Run the query with representative default parameters via `snow sql --format JSON`.
3. Pipe the result to the validation snippet:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/validate_chart_inputs.py`

```bash
source venv/snowflake/bin/activate
snow sql -q "<QUERY>" --format JSON | \
  mamba run -n <ENV_NAME> python \
    .github/skills/update-streamlit-dashboard-conversion/assets/snippets/validate_chart_inputs.py \
    --index-col <INDEX_COLUMN>
```

4. A `FAIL` result means the chart will raise a render error at runtime. Apply the appropriate remediation before proceeding:
   - Categorical/string column in chart input → pivot to columns (`df.pivot_table(...)`)
   - Duplicate columns → deduplicate before charting
   - Non-1D index input (for example duplicated column selection used as index) → build a dedicated index column (for example `row_number`) and chart a single numeric y-column or explicit x/y pair
5. Re-run the validation script after each fix to confirm `PASS`.
6. Repeat for every chart call site in the app.

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

## Add Managed-On-GitHub Disclaimer Under Title (Required)

After session wiring and before local validation, ensure each generated app includes the managed-on-GitHub disclaimer directly under the page title in `streamlit_app.py`.

### Required placement and content

1. Keep the app title call (for example `st.title(...)` or `streamlit.title(...)`).
2. Insert the disclaimer markdown immediately after the title call.
3. Use the exact disclaimer message and link target from the snippet asset.
4. Keep `unsafe_allow_html=True` enabled for this block.

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/managed_on_github_disclaimer.py`

If the app uses `streamlit` instead of `st`, adapt only the module prefix (`st` vs `streamlit`) and keep the disclaimer text unchanged.

If the disclaimer already exists with identical text/link, do not duplicate it.

### Local debug workflow

### Browser Behavior During Validation (Required)

To avoid disrupting the user during validation, enforce the following:

1. During validation, run Streamlit in headless mode.
2. During validation, do **not** open the app in the system/local browser.
3. During validation, use only the integrated VS Code browser tooling to load and inspect the app.
4. Open the system/local browser **only** in the final user review step after validation has passed.

If the app is started without headless mode and opens a local browser tab/window, stop it and re-run headless before continuing validation.

For each app directory (after warehouse conversion):

1. Bootstrap a local environment from that app's manifests using non-interactive flags to avoid prompts:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/bootstrap_local_env.sh`

```bash
APP_DIR="sage/<schema_lower>/streamlit/<slug>" \
  bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/bootstrap_local_env.sh
```

2. Run locally with `--local-dev` from the app directory in headless mode:

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/run_local_dev.sh`

```bash
APP_DIR="sage/<schema_lower>/streamlit/<slug>" \
  bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/run_local_dev.sh
```

3. Validate startup output and capture the app URL:
   - Confirm Streamlit prints `You can now view your Streamlit app in your browser.`
   - Confirm a `Local URL:` line is present.
    - **Parse and record the exact URL** from the `Local URL:` line — do not assume the port. Streamlit increments the port when a previous process still holds it, so a restarted app may be on a different port than the prior run. Use snippet asset:
       - `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/parse_local_url.sh`
       Extract it with:
     ```bash
          LOG_FILE=/tmp/app.log \
             bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/parse_local_url.sh
     ```
       Or assign directly:
       ```bash
          APP_URL=$(LOG_FILE=/tmp/app.log bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/parse_local_url.sh)
       ```
   - Use `$APP_URL` for all subsequent browser, curl, and smoke-test steps.
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

- The **Static Chart Input Validation** step above must pass for all chart call sites before proceeding here.
- Browser chat tools (`workbench.browser.enableChatTools`) are required for full in-browser inspection. Note: fetch tools including `WebFetch` do not work with `localhost` URLs — they will return errors rather than page content. If browser tools are unavailable, the static chart validation step is the primary render-time gate; skip the in-browser steps below and proceed directly to the smoke-test process.

### Required in-browser validation process

1. Start the app in a background terminal and keep the terminal ID.
2. Open the reported `Local URL` in the integrated browser only (not the system/local browser).
3. Capture a page snapshot/state using browser-read tools.
4. Treat any of the following as validation failures:
   - UI alert blocks containing `Error:` messages.
   - Console `error` events.
   - Known warning/error signatures tied to broken charts/tables (for example mixed-type chart errors).
   - Exception: if failures are transport-only (for example `ERR_CONNECTION_REFUSED`), first verify the app process is still running, then reconnect by reopening the parsed `APP_URL`; fail only if app-level errors persist after reconnect.
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
- Non-1D index/data errors (for example `Index data must be 1-dimensional`): avoid duplicated-column index construction; create an explicit 1D index column and pass a single-value series or explicit x/y frame.
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

```bash
LOG_FILE=/tmp/app.log \
  bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/smoke_scan_logs.sh
```

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

```bash
LOG_FILE=/tmp/app.log \
  bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/smoke_scan_logs_fail_on_warning.sh
```

## Final User Review And Commit Flow (Required)

After validation is complete and before ending the workflow, run a final user-facing handoff.

1. Open the local app URL in the system browser (outside VS Code) for user review.
2. Ask the user for explicit feedback/approval of the Streamlit app.
3. If the user requests changes, apply them and repeat validation before re-requesting approval.
4. Once approved, ask whether the user wants to commit the Streamlit app changes.
5. Only if the user agrees to commit:
    - Confirm the feature branch name and base branch before committing.
    - Resolve the Jira key for branch naming with this exact JQL query shape:
       - `parent = SNOW-428 AND summary ~ "<Streamlit title>"`
    - If exactly one issue matches, use that key.
    - If zero or multiple issues match, stop and ask the user to choose the ticket key before proceeding.
   - Create/switch to branch `<jira-ticket-identifier_lower>-<slug_lower>` before commit, and default branch base and PR target to `dev` unless the user explicitly requests another base. For example, the "Synapse Performance Metrics" Streamlit corresponds to SNOW-452 and should have its changes committed to `snow-452-synapse-performance-metrics`.
   - Ensure the feature branch is based on the same branch that will be used as PR base.
   - Upsert release entries (grant + CI matrix) using the bundled snippet asset:
      - `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/upsert_streamlit_release_entries.sh`

      Run it with:

      ```bash
      APP_TITLE="<Streamlit title>" \
      SCHEMA_LOWER="<schema_lower>" \
      SLUG="<slug>" \
      OBJECT_NAME="<OBJECT_NAME>" \
      bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/upsert_streamlit_release_entries.sh
      ```

      The bundled snippet is rerunnable and handles CI matrix insertion safely.

      This script is rerunnable and idempotent for:
      - `admin/grants.sql`: `GRANT USAGE ON STREAMLIT SAGE.<SCHEMA_UPPER>.<OBJECT_NAME_UPPER> TO ROLE SAGE_<SCHEMA_UPPER>_ANALYST;`
      - `.github/workflows/ci.yaml`: one `deploy_streamlit` matrix entry with:
         - `name`: `<Streamlit title>`
         - `path`: `sage/<schema_lower>/streamlit/<slug>`
         - `role`: `sage_<schema_lower>_admin`

      If the path already exists in the matrix, no duplicate is added.
   - Before committing, format the app file with `black` using the bundled snippet:

      Use snippet asset:

      - `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/format_app.sh`

      ```bash
      APP_FILE="sage/<schema_lower>/streamlit/<slug>/streamlit_app.py" \
        bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/format_app.sh
      ```

      Format only this app file in this step (do not format the entire workspace).
   - Commit scope guard (required): stage **only** the files below for the feature branch PR.
      - Required staged files list:
         - `admin/grants.sql`
         - `.github/workflows/ci.yaml`
         - `sage/<schema_lower>/streamlit/<slug>/streamlit_app.py`
         - `sage/<schema_lower>/streamlit/<slug>/snowflake.yml`
         - `sage/<schema_lower>/streamlit/<slug>/environment.yml`
         - `sage/<schema_lower>/streamlit/<slug>/.streamlit/config.toml`
      - Use explicit staging (do not use `git add .`):

      ```bash
      git add \
        admin/grants.sql \
        .github/workflows/ci.yaml \
        sage/<schema_lower>/streamlit/<slug>/streamlit_app.py \
        sage/<schema_lower>/streamlit/<slug>/snowflake.yml \
        sage/<schema_lower>/streamlit/<slug>/environment.yml \
        sage/<schema_lower>/streamlit/<slug>/.streamlit/config.toml
      ```

      - Verify the staged set contains only those paths:

      ```bash
      git diff --cached --name-only
      ```

      - If any staged path is outside the list above, unstage it before commit.
6. Create one non-amended commit containing all workflow/app/CI changes with message:

```text
Transition <Streamlit title> from dashboard to Streamlit
```

7. Re-root the feature branch onto the PR base branch (`dev` by default) using the bundled snippet asset. This is required to prevent unrelated history/files from the skill branch from leaking into app PRs.

Use snippet asset:

- `.github/skills/update-streamlit-dashboard-conversion/assets/snippets/re_root_feature_branch_to_base.sh`

```bash
FEATURE_BRANCH="<jira-ticket-identifier_lower>-<slug_lower>" \
BASE_BRANCH="dev" \
COMMIT_SHA="HEAD" \
   bash .github/skills/update-streamlit-dashboard-conversion/assets/snippets/re_root_feature_branch_to_base.sh
```

The snippet rewrites the feature branch pointer so it contains only the app commit on top of `origin/<base_branch>`.

8. Push the feature branch to origin. If the branch already exists remotely, use `--force-with-lease`.
9. Open a pull request against the confirmed base branch (default `dev`).
10. Add the `skip_cloning` label to the PR (required for this workflow).
   - If using GitHub CLI:

   ```bash
   gh pr edit --add-label skip_cloning
   ```

   - If creating the PR through API/tooling, include `skip_cloning` in the initial label set.
   - Verify the PR shows the `skip_cloning` label before ending the workflow.
11. The PR title and description ought to follow the same templating used with PR 337.
   - Title format: `[<JIRA-KEY>] <brief action-oriented summary>`
   - Include required template sections: Problem, Solution, Testing
12. If the user declines commit, do not update `admin/grants.sql` or `ci.yaml` and do not create a commit.

## Optional Production Deploy Prompt (Required)

After the Final User Review And Commit Flow completes, always ask the user:

- "Do you want to deploy these Streamlit app changes to production now?"

If the user says yes, deploy using the same command shape used in `.github/workflows/ci.yaml` for `deploy_streamlit`.

Inline deploy helper script:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Required:
#   APP_DIR, ROLE

if [[ -z "${APP_DIR:-}" || -z "${ROLE:-}" ]]; then
   echo "Usage: APP_DIR=<sage/<schema>/streamlit/<slug>> ROLE=<sage_<schema>_admin> bash deploy_streamlit_prod.sh" >&2
   exit 1
fi

if [[ ! -d "${APP_DIR}" ]]; then
   echo "Missing app directory: ${APP_DIR}" >&2
   exit 1
fi

if ! command -v snow >/dev/null 2>&1; then
   REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
   if [[ -f "${REPO_ROOT}/venv/snowflake/bin/activate" ]]; then
      source "${REPO_ROOT}/venv/snowflake/bin/activate"
   fi
fi

if ! command -v snow >/dev/null 2>&1; then
   echo "snow CLI not found. Activate venv/snowflake/bin/activate or install Snowflake CLI." >&2
   exit 1
fi

(
   cd "${APP_DIR}"
   snow streamlit deploy --role "${ROLE}" --replace --prune
)
```

Run it with (after saving the inline script block above to a local file, for example `./deploy_streamlit_prod.sh`):

```bash
APP_DIR="sage/<schema_lower>/streamlit/<slug>" ROLE="sage_<schema_lower>_admin" \
bash ./deploy_streamlit_prod.sh
```

Equivalent direct command (no helper file):

```bash
cd "sage/<schema_lower>/streamlit/<slug>"
snow streamlit deploy --role "sage_<schema_lower>_admin" --replace --prune
```

Execution rules:

1. Run deploy only after explicit user approval.
2. Use the app path and admin role that match the `deploy_streamlit` matrix entry for that app.
3. Report deploy success/failure to the user with relevant command output.
4. If the user says no, skip deploy and end after confirming no production deploy was performed.

## Session Cleanup In `sage` (Required)

After final branch reset (after switching back to `snow-451-streamlit-conversion-skill`), discard untracked session artifacts in `sage/` that were generated during local Streamlit work and are not intended to remain on this branch.

Use:

```bash
git status --short --untracked-files=all sage
git clean -fd sage
git status --short --untracked-files=all sage
```

Rules:

1. Clean only untracked content in `sage/`.
2. Do not remove tracked changes.
3. If any tracked `sage/` changes remain, report them to the user instead of discarding them automatically.
4. Do not run these cleanup commands on the feature branch created for the app PR.

## Final Branch Reset (Required)

Once the normal skill flow is complete (including optional production deploy handling), switch back to:

- `snow-451-streamlit-conversion-skill`

Use:

```bash
git switch snow-451-streamlit-conversion-skill
git branch --show-current
```

Then run the required `sage/` cleanup commands from the section above while on `snow-451-streamlit-conversion-skill`.

Only end the workflow after:

1. confirming the current branch is `snow-451-streamlit-conversion-skill`, and
2. completing the `sage/` cleanup step on that branch.

## Notes

- Prefer `--format JSON` for all `snow` inspection/list/describe commands.
- Avoid parsing pretty-printed table output.
- If no objects are found in the given database/schema, tell the user and ask whether to check another database/schema.
