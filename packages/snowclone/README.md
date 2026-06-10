# snowclone — RBAC-configured clone provisioning

Procures a development environment by zero-copy cloning a Snowflake database and
reconfiguring RBAC on the clone, then (optionally) deploying with the database's
normal schemachange. Database-agnostic; used in particular for
`SYNAPSE_DATA_WAREHOUSE`, `SYNAPSE_DATA_WAREHOUSE_DEV`, and `SAGE`.

## Usage

`snowclone` is a [uv workspace](https://docs.astral.sh/uv/concepts/projects/workspaces/)
member. `uv run` syncs the workspace (installing this package editable) and exposes a
single `snowclone` console script with two subcommands — `freeze` and `melt`:

```bash
# Dry run (logs every mutating statement; read-only SHOW queries still execute)
uv run snowclone freeze \
    --database SYNAPSE_DATA_WAREHOUSE_DEV --clone-suffix snow-417 \
    --deploy-folder synapse_data_warehouse --dry-run

# Freeze + deploy
uv run snowclone freeze --database SAGE --clone-suffix snow-512 --deploy-folder sage

# Freeze RBAC only (omit --deploy-folder to skip schemachange)
uv run snowclone freeze --database SAGE --clone-suffix snow-512

# Melt (tear down)
uv run snowclone melt --database SAGE --clone-suffix snow-512
```

(The equivalent module form — `uv run python -m snowclone freeze …` / `… melt …` —
also works once the package is installed.)

The deploy targets the clone purely through the standardized
`SNOWFLAKE_DEPLOY_DATABASE` env var, which the script sets to the clone name and
every `schemachange-config.yml` reads — so there is no per-database wiring beyond
the `--deploy-folder` argument.

The clone is named `{DATABASE}_{suffix}` (sanitized to `[A-Za-z0-9_]`). The proxy
admin role is `{CLONE}_PROXY_ADMIN`. From CI it is driven by
`.github/workflows/procure_clone.yaml` (on-demand) and
`.github/workflows/test_with_clone.yaml` (PR testing of the dev warehouse).

## Why two ownership models, one algorithm

The script keys every decision off `owner_role_type` (`ROLE` vs `DATABASE_ROLE`),
not role names, so the two house styles — and SAGE's non-conforming schemas — are
handled uniformly:

| Source ownership | In the clone | Capture strategy |
|------------------|--------------|------------------|
| `{SCHEMA}_ALL_ADMIN` **database role** (SYNAPSE) | cloned with the DB | take ownership of + be granted the top-level database role (transitive, no per-object work) |
| `{DB}_PROXY_ADMIN` **account role** owns tasks/dynamic tables (SYNAPSE) | account role unchanged | `GRANT OWNERSHIP ON ALL <type>` to the proxy |
| `{SCHEMA}_ADMIN` **account role** (SAGE) | account role unchanged | `GRANT OWNERSHIP ON ALL <type>` to the proxy |
| Streamlit / self-owned | unchanged | skipped; recreated by the deploy |

## Phases (executing role)

1. **Clone** — `CREATE OR REPLACE DATABASE … CLONE …` — `{DATABASE}_ADMIN`.
2. **Revoke residual access**: `REVOKE ALL PRIVILEGES ON DATABASE` from every
   account role except the allowlist (`{DATABASE}_ADMIN` and the proxy). This
   strips database `USAGE`, so those roles can't traverse into the clone — which
   neuters them while the schema/object grants are **retained** for fidelity
   (inert without database `USAGE`). The developer re-derives access via the
   proxy, and the system roles via the developer. `REVOKE ALL PRIVILEGES`
   excludes OWNERSHIP, so nothing is orphaned — `SECURITYADMIN`.
3. **Create proxy** — `CREATE OR REPLACE ROLE {CLONE}_PROXY_ADMIN` — `USERADMIN`.
4. **Grant proxy to developer** — `SECURITYADMIN`.
5. **Capture database-role hierarchy** — for each database role owned by an
   account role: `GRANT OWNERSHIP ON DATABASE ROLE … REVOKE CURRENT GRANTS` +
   `GRANT DATABASE ROLE …` — `SECURITYADMIN`.
6. **Transfer account-role-owned objects** — per `(schema, type)`:
   `GRANT OWNERSHIP ON ALL <type> … COPY CURRENT GRANTS` (preserves the source's
   per-object grants — inert because Phase 2 already removed external USAGE) —
   `SECURITYADMIN`.
7. **Re-point account-role future OWNERSHIP grants** to the proxy; future grants
   held by **database roles** are left intact so new objects keep landing in the
   mirrored hierarchy — `SECURITYADMIN`.
8. **Grant database-level privileges** (`MODIFY, MONITOR, CREATE SCHEMA,
   CREATE DATABASE ROLE`) to the developer role — `SECURITYADMIN`.
9. **Deploy** schemachange against the clone as the developer role.

## Snowflake semantics relied upon

- Cloning a database also clones its **database roles** and the contained objects,
  preserving each object's owning role; account-role-owned objects therefore stay
  owned by the (un-cloned) account role in the clone. Object/schema **grants are
  copied** from the source — hence phase 2.
- Only one role holds `OWNERSHIP` per object. Existing objects transfer with
  `COPY CURRENT GRANTS` (mirror prod's grant structure), while database-role
  ownership is taken with `REVOKE CURRENT GRANTS` (no privileges to preserve on a
  role object, and it avoids re-attaching the original account proxy admin to the
  clone's hierarchy). **Future** grants have nothing to copy, so they are revoked
  from the old grantee then granted to the proxy.
- All ownership transfers run as `SECURITYADMIN` (holds `MANAGE GRANTS`).
- `owner_role_type` is read from `SHOW` output when present; otherwise inferred
  (owner name matching a known database role ⇒ `DATABASE_ROLE`).

## Safety

- `sql.assert_clone()` guards every mutating builder — the script cannot target
  the source database.
- Phase 2 never revokes from the allowlist and ignores per-statement revoke
  failures (e.g. grants made by `ACCOUNTADMIN`).
- `--dry-run` skips all mutations but runs the introspection, so the logged plan
  is accurate.

## Layout

```
packages/snowclone/
  pyproject.toml          # workspace member: deps, console scripts, test group, pytest config
  src/snowclone/          # the importable package (procure, teardown, phases, …)
  tests/                  # unit suite
```

## Testing

```bash
# from this package directory
uv run --group test pytest
# or from the repo root
uv run --package snowclone --group test pytest
```

The suite (`tests/`) is hermetic and fast (~0.1s) — no Snowflake connection is used.
`tests/conftest.py` installs a `snowflake.connector` stub and provides the shared
fixtures/doubles:

- `make_session` / `FakeSession` — records `execute()` calls and routes `query()`
  to canned `SHOW` rows; covers `introspect`, `phases`, `procure`, `teardown`.
- `make_context` — builds a `phases.Context` wired to a `FakeSession`.
- `rows` — `SHOW`-row builders; `fake_connection` — drives the `connection.py` tests.

Pure modules (`sql`, `classify`) are tested directly. The `test` dependency group
and `pytest` config live in this package's `pyproject.toml`.
