## Project

Database-agnostic provisioning of RBAC-configured zero-copy clone environments.
Clones a Snowflake database and reconfigures ownership/grants on the clone so a
developer role controls everything through a single `{CLONE}_PROXY_ADMIN` account
role, then deploys the same schemachange used for the source database.

Generalizes the previously-hardcoded `.github/workflows/test_with_clone.yaml`:
ownership is discovered at **runtime** via `SHOW` introspection, so the workflow
no longer needs editing when a schema is added. Handles both RBAC models:

- **SYNAPSE_DATA_WAREHOUSE[_DEV]** — database-role hierarchy (`{SCHEMA}_ALL_ADMIN`).
- **SAGE** — schema-first account-role ownership (`{SCHEMA}_ADMIN`), including its
  non-conforming schemas (e.g. `AD`, `AUDIT`, Streamlit-only).

See `README.md` for the full algorithm and Snowflake semantics.

## Layout

A uv-workspace member with a `src/` layout. `pyproject.toml` declares its
dependency (the Snowflake connector), the single `snowclone` console script (with
`freeze`/`melt` subcommands), its `test` dependency group, and its pytest config.
Modules live under `src/snowclone/`:

| File | Responsibility |
|------|----------------|
| `src/snowclone/cli.py` | The `snowclone` CLI: `freeze`/`melt` subparsers + dispatch |
| `src/snowclone/__main__.py` | `python -m snowclone …` → `cli.main` |
| `src/snowclone/procure.py` | `freeze` core: name resolution, context build, phase pipeline |
| `src/snowclone/teardown.py` | `melt` core: drops the clone DB and proxy role |
| `src/snowclone/phases.py` | Ordered phase functions + executing-role assignment |
| `src/snowclone/introspect.py` | Read-only `SHOW` queries → dataclasses (no mutation) |
| `src/snowclone/classify.py` | Pure ownership-classification logic (no Snowflake) |
| `src/snowclone/sql.py` | Object-type metadata, SQL builders, clone-name guard |
| `src/snowclone/connection.py` | `snowflake.connector` session; per-statement role switching |
| `tests/` | Hermetic unit suite (one file per module) |

There is **no per-database registry** — the database, developer role, and deploy
folder are all CLI arguments, and the deploy targets the clone purely through the
standardized `SNOWFLAKE_DEPLOY_DATABASE` env var.

## Conventions

- **Invoke via the `snowclone` console script** (uv installs the package, so
  relative imports resolve): `uv run snowclone freeze --database SAGE --clone-suffix
  snow-512` / `uv run snowclone melt …` (the `uv run python -m snowclone freeze …`
  module form also works once installed).
- **Support a new database** with no code change: pass `--database`, and (to
  deploy) `--deploy-folder <its schemachange folder>`. The folder's
  `schemachange-config.yml` must read `SNOWFLAKE_DEPLOY_DATABASE` for its target
  database (as `synapse_data_warehouse/` and `sage/` do).
- **Deploy is opt-in:** schemachange runs only when `--deploy-folder` is given.
- **Executing roles are fixed:** clone → `{DATABASE}_ADMIN`; role create/drop →
  `USERADMIN`; all grants/ownership/revokes → `SECURITYADMIN`; deploy → developer role.
- **Operate only on the clone.** Every mutating SQL builder calls
  `sql.assert_clone()`; never target the source database.
- **Hierarchy-preserving:** capture top-level database roles (cheap, transitive);
  only fall back to per-object `GRANT OWNERSHIP ON ALL` for account-role-owned
  objects. Leave future grants held by database roles intact.
- **Always `--dry-run` first** when changing the logic — read-only `SHOW`
  queries still run, so the logged plan reflects the real database.

## Connection

Reuses the `default` connection in `~/.snowflake/connections.toml` written by the
`configure-snowflake-cli` action — same connection the `snow` CLI and schemachange
use. `uv run snowclone freeze …` installs the package (and its connector
dependency) into the workspace env automatically — no separate install step.

## Testing

`uv run --group test pytest` from this package (or `uv run --package snowclone
--group test pytest` from the repo root) — hermetic (no Snowflake connection;
`conftest.py` stubs `snowflake.connector`). Shared fixtures/doubles live in
`tests/conftest.py`; one test file per module. See `README.md` § Testing.

## Constraints

- Streamlit objects cannot have ownership transferred; they are skipped and
  recreated by the deploy step.
- This is **automation**, not schemachange-managed DDL — it is not deployed by
  `ci.yaml`; it is invoked by the clone workflows.
