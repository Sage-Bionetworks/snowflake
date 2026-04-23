# Streamlit Development Guidelines

This document covers local development and deployment of Streamlit in Snowflake (SiS) apps in this repository.

## Overview

Streamlit apps live under `sage/<project>/streamlit/<app-name>/`. Each app directory contains:

```text
sage/<project>/streamlit/<app-name>/
├── streamlit_app.py        # Main entry point: app logic, data loading, filtering, and UI rendering
├── environment.yml         # Conda environment definition: pins Python and package versions for local dev and SiS runtime alignment
├── snowflake.yml           # Snowflake CLI entity config: specifies the target database, schema, warehouse, and artifacts to upload
└── .streamlit/
    └── config.toml         # Streamlit runtime config: e.g. session timeout and other Snowflake-specific settings
```

## Local Development

### Prerequisites

Install [Miniforge](https://github.com/conda-forge/miniforge) and follow the [official installation instructions](https://github.com/conda-forge/miniforge?tab=readme-ov-file#unix-like-platforms-macos-linux--wsl) to initialize your shell.

### Set Up the Environment

> [!WARNING]
> Do not activate this environment while another Python virtual environment is active (for example `venv`, `virtualenv`, or another conda/mamba env). Deactivate any currently active Python environment first.

From the app directory:

```bash
mamba env create -f environment.yml
mamba activate <env-name>
```

To update an existing environment after `environment.yml` changes:

```bash
mamba env update -n <env-name> -f environment.yml --prune
```

### Python Version

Pin Python to **3.11** in `environment.yml` to match the Snowflake Streamlit runtime. Also pin the major version of any other packages used in your Streamlit app:

```yaml
dependencies:
    - python=3.11.*
    - streamlit=1.*
    - snowflake-snowpark-python
```

### Run the App Locally

```bash
streamlit run streamlit_app.py -- --local-dev
```

The `--local-dev` flag switches the Snowflake session from `get_active_session()` (SiS only) to a local connection via `~/.snowflake/connections.toml`. Ensure you have a `[default]` connection entry there.

See [sage/governance/streamlit/data_access_dashboard/streamlit_app.py](sage/governance/streamlit/data_access_dashboard/streamlit_app.py) for a working example of `--local-dev` argument parsing and local-vs-SiS session selection.

The app can be configured to auto-refresh on file save — no restart needed for code changes. Restart only when:
- `environment.yml` changes
- launch-level settings change
- the process enters a bad state

## Code Organization

Streamlit apps should be structured with clear separation of concerns:

1. **Bootstrap** — `read_args()`, `get_session()`, `set_page_config()`
2. **Data access** — one function per query, returning a pandas DataFrame
3. **Column/option helpers** — column name resolution and dropdown option generation
4. **Filter logic** — pure functions that apply filters to DataFrames
5. **UI rendering** — `render_<section>_filters()`, `render_<section>_section()`
6. **`main()`** — thin orchestrator, called at the bottom of the file

Keep rendering functions free of business logic, and keep filter functions free of Streamlit calls.

## Deployment

Apps are deployed using the [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index) (`snow`).

From the app directory:

```bash
snow streamlit deploy --replace --prune [--connection <connection-name>]
```

The `snowflake.yml` in each app directory defines the target database, schema, warehouse, and artifacts to upload.

## RBAC and Ownership

Streamlit objects have an RBAC peculiarity: Snowflake does not support `GRANT OWNERSHIP`
or `GRANT OWNERSHIP ON FUTURE` for `STREAMLIT` objects.

Because ownership cannot be reassigned via grants, ensure the correct role is active at
creation time by including a `USE ROLE <schema_admin_role>;` statement before any
`CREATE ... STREAMLIT` statements so the app is created with the schema admin role as owner.

Other object grants are unaffected. Standard grants and future grants for non-ownership
privileges (for example `USAGE`) continue to work normally.

## Snowflake Runtime Constraints

- Python version: **3.11**
- Package versions must be available in the [Snowflake Anaconda channel](https://repo.anaconda.com/pkgs/snowflake)
- `snowflake.snowpark.context.get_active_session()` is only available inside SiS — use `snowflake.snowpark.Session` for local development
- `streamlit.set_page_config()` must be the first Streamlit call in the script

For an end-to-end example of these runtime patterns, see [sage/governance/streamlit/data_access_dashboard/streamlit_app.py](sage/governance/streamlit/data_access_dashboard/streamlit_app.py).
