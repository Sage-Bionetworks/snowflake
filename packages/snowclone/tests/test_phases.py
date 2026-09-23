"""Unit tests for ``snowclone/phases.py`` (ordered provisioning phases).

Each test builds a fresh ``make_context``/``make_session`` so the recorded
``.executed``/``.queried`` lists are isolated. No real Snowflake connection is
used (the driver is stubbed in ``conftest.py``).
"""

from __future__ import annotations

import logging

from snowclone import introspect, phases, sql


# --------------------------------------------------------------------------- #
# Context properties
# --------------------------------------------------------------------------- #
def test_protected_roles(make_context):
    ctx = make_context()
    assert ctx.protected_roles == sql.SYSTEM_ROLES | {
        "SRC_ADMIN",
        "SRC_CLONE_PROXY_ADMIN",
        "DATA_ENGINEER",
    }


def test_revoke_allowlist(make_context):
    ctx = make_context()
    assert ctx.revoke_allowlist == {"SRC_ADMIN", "SRC_CLONE_PROXY_ADMIN"}
    # Developer and system roles are deliberately excluded.
    assert "DATA_ENGINEER" not in ctx.revoke_allowlist
    assert not (sql.SYSTEM_ROLES & ctx.revoke_allowlist)


def test_introspect_db_live_uses_clone(make_context):
    ctx = make_context()
    assert ctx.session.dry_run is False
    assert ctx.introspect_db == "SRC_CLONE"


def test_introspect_db_dry_run_uses_source(make_context):
    ctx = make_context(dry_run=True)
    assert ctx.introspect_db == "SRC"


# --------------------------------------------------------------------------- #
# clone
# --------------------------------------------------------------------------- #
def test_clone(make_context):
    ctx = make_context()
    phases.clone(ctx)
    assert ctx.session.executed == [
        ("SRC_ADMIN", "CREATE OR REPLACE DATABASE SRC_CLONE CLONE SRC", False)
    ]


# --------------------------------------------------------------------------- #
# create_proxy
# --------------------------------------------------------------------------- #
def test_create_proxy(make_context):
    ctx = make_context()
    phases.create_proxy(ctx)
    assert ctx.session.executed == [
        (phases.USERADMIN, "CREATE OR REPLACE ROLE SRC_CLONE_PROXY_ADMIN", False)
    ]


# --------------------------------------------------------------------------- #
# grant_proxy_to_developer
# --------------------------------------------------------------------------- #
def test_grant_proxy_to_developer(make_context):
    ctx = make_context()
    phases.grant_proxy_to_developer(ctx)
    assert ctx.session.executed == [
        (
            phases.SECURITYADMIN,
            "GRANT ROLE SRC_CLONE_PROXY_ADMIN TO ROLE DATA_ENGINEER",
            False,
        )
    ]


# --------------------------------------------------------------------------- #
# grant_database_privileges
# --------------------------------------------------------------------------- #
def test_grant_database_privileges(make_context):
    ctx = make_context()
    phases.grant_database_privileges(ctx)
    assert ctx.session.executed == [
        (
            phases.SECURITYADMIN,
            "GRANT MODIFY, MONITOR, CREATE SCHEMA, CREATE DATABASE ROLE "
            "ON DATABASE SRC_CLONE TO ROLE DATA_ENGINEER",
            False,
        )
    ]


# --------------------------------------------------------------------------- #
# capture_database_roles
# --------------------------------------------------------------------------- #
def test_capture_database_roles(make_session, make_context, rows):
    session = make_session(
        {
            "SHOW DATABASE ROLES IN DATABASE": [
                rows.db_role("A_ALL_ADMIN", "PROXY"),
                rows.db_role("A_CHILD", "A_ALL_ADMIN"),
            ]
        }
    )
    ctx = make_context(session=session)

    result = phases.capture_database_roles(ctx)

    assert result == {"A_ALL_ADMIN", "A_CHILD"}
    # Only the top-level role is captured; the child is covered transitively.
    assert session.executed_sql == [
        "GRANT OWNERSHIP ON DATABASE ROLE SRC_CLONE.A_ALL_ADMIN "
        "TO ROLE SRC_CLONE_PROXY_ADMIN REVOKE CURRENT GRANTS",
        "GRANT DATABASE ROLE SRC_CLONE.A_ALL_ADMIN TO ROLE SRC_CLONE_PROXY_ADMIN",
    ]
    assert all(role == phases.SECURITYADMIN for role, _sql, _ig in session.executed)


# --------------------------------------------------------------------------- #
# transfer_object_ownership
# --------------------------------------------------------------------------- #
def test_transfer_object_ownership_sage_shape(make_session, make_context, rows):
    schema_infos = [
        introspect.SchemaInfo("CITATIONS", "SAGE_CITATIONS_ADMIN", "ROLE"),
        introspect.SchemaInfo("FINANCE", "FINANCE_ALL_ADMIN", "DATABASE_ROLE"),
        introspect.SchemaInfo("AUDIT", "SYSADMIN", "ROLE"),
    ]
    session = make_session(
        {"SHOW TABLES IN DATABASE": [rows.obj("CITATIONS", "SAGE_CITATIONS_ADMIN")]}
    )
    ctx = make_context(session=session)

    phases.transfer_object_ownership(ctx, set(), schema_infos)

    executed = session.executed_sql
    schema_grant = (
        "GRANT OWNERSHIP ON SCHEMA SRC_CLONE.CITATIONS "
        "TO ROLE SRC_CLONE_PROXY_ADMIN COPY CURRENT GRANTS"
    )
    object_grant = (
        "GRANT OWNERSHIP ON ALL TABLES IN SCHEMA SRC_CLONE.CITATIONS "
        "TO ROLE SRC_CLONE_PROXY_ADMIN COPY CURRENT GRANTS"
    )
    assert schema_grant in executed
    assert object_grant in executed
    # FINANCE (database-role owned) and AUDIT (system role) are not transferred.
    assert not any("SRC_CLONE.FINANCE" in s for s in executed)
    assert not any("SRC_CLONE.AUDIT" in s for s in executed)
    # Schema transfer comes before object transfer.
    assert executed.index(schema_grant) < executed.index(object_grant)
    assert all(role == phases.SECURITYADMIN for role, _sql, _ig in session.executed)


def test_transfer_object_ownership_synapse_shape(make_session, make_context, rows):
    schema_infos = [
        introspect.SchemaInfo("SYNAPSE", "SYNAPSE_ALL_ADMIN", "DATABASE_ROLE"),
    ]
    session = make_session(
        {"SHOW DYNAMIC TABLES IN DATABASE": [rows.obj("SYNAPSE", "SRC_PROXY", "ROLE")]}
    )
    ctx = make_context(session=session)

    phases.transfer_object_ownership(ctx, set(), schema_infos)

    executed = session.executed_sql
    # No schema-ownership transfers for database-role-owned schemas.
    assert not any("ON SCHEMA" in s for s in executed)
    assert (
        "GRANT OWNERSHIP ON ALL DYNAMIC TABLES IN SCHEMA SRC_CLONE.SYNAPSE "
        "TO ROLE SRC_CLONE_PROXY_ADMIN COPY CURRENT GRANTS" in executed
    )


# --------------------------------------------------------------------------- #
# repoint_future_grants
# --------------------------------------------------------------------------- #
def test_repoint_future_grants_schema(make_session, make_context, rows):
    session = make_session(
        {
            "SHOW FUTURE GRANTS IN SCHEMA SRC_CLONE.SYNAPSE": [
                rows.future("OWNERSHIP", "DYNAMIC_TABLE", "ROLE", "SRC_PROXY"),
                rows.future("OWNERSHIP", "TABLE", "DATABASE_ROLE", "SYNAPSE_ALL_ADMIN"),
                rows.future("SELECT", "TABLE", "ROLE", "ANALYST"),
            ],
            "SHOW FUTURE GRANTS IN DATABASE": [],
        }
    )
    ctx = make_context(session=session)

    phases.repoint_future_grants(ctx, ["SYNAPSE"])

    executed = session.executed_sql
    assert (
        "REVOKE OWNERSHIP ON FUTURE DYNAMIC TABLES IN SCHEMA SRC_CLONE.SYNAPSE "
        "FROM ROLE SRC_PROXY" in executed
    )
    assert (
        "GRANT OWNERSHIP ON FUTURE DYNAMIC TABLES IN SCHEMA SRC_CLONE.SYNAPSE "
        "TO ROLE SRC_CLONE_PROXY_ADMIN" in executed
    )
    # Database-role-held future grant is left intact.
    assert not any("SYNAPSE_ALL_ADMIN" in s for s in executed)
    # Non-OWNERSHIP grant is ignored.
    assert not any("ANALYST" in s for s in executed)
    assert all(role == phases.SECURITYADMIN for role, _sql, _ig in session.executed)


def test_repoint_future_grants_database_level(make_session, make_context, rows):
    session = make_session(
        {
            "SHOW FUTURE GRANTS IN DATABASE": [
                rows.future("OWNERSHIP", "TABLE", "ROLE", "ACCT")
            ]
        }
    )
    ctx = make_context(session=session)

    phases.repoint_future_grants(ctx, [])

    executed = session.executed_sql
    assert (
        "REVOKE OWNERSHIP ON FUTURE TABLES IN DATABASE SRC_CLONE FROM ROLE ACCT"
        in executed
    )
    assert (
        "GRANT OWNERSHIP ON FUTURE TABLES IN DATABASE SRC_CLONE "
        "TO ROLE SRC_CLONE_PROXY_ADMIN" in executed
    )


def test_repoint_future_grants_unknown_token(make_session, make_context, rows, caplog):
    session = make_session(
        {
            "SHOW FUTURE GRANTS IN DATABASE": [
                rows.future("OWNERSHIP", "WIDGET", "ROLE", "ACCT")
            ]
        }
    )
    ctx = make_context(session=session)

    with caplog.at_level(logging.WARNING, logger=phases.logger.name):
        phases.repoint_future_grants(ctx, [])

    assert session.executed == []  # nothing emitted for the unknown type
    assert any(record.levelno == logging.WARNING for record in caplog.records)


# --------------------------------------------------------------------------- #
# revoke_other_roles
# --------------------------------------------------------------------------- #
def test_revoke_other_roles(make_session, make_context, rows):
    session = make_session(
        {
            "SHOW GRANTS ON DATABASE": [
                rows.grant("USAGE", "ROLE", "DATA_ENGINEER"),
                rows.grant("USAGE", "ROLE", "PUBLIC"),
                rows.grant("USAGE", "ROLE", "SAGE_CITATIONS_ADMIN"),
                rows.grant("OWNERSHIP", "ROLE", "SRC_ADMIN"),
                rows.grant("USAGE", "DATABASE_ROLE", "SOME_DB_ROLE"),
                rows.grant("USAGE", "ROLE", "SRC_CLONE_PROXY_ADMIN"),
            ]
        }
    )
    ctx = make_context(session=session)

    phases.revoke_other_roles(ctx)

    expected = {
        "REVOKE ALL PRIVILEGES ON DATABASE SRC_CLONE FROM ROLE DATA_ENGINEER",
        "REVOKE ALL PRIVILEGES ON DATABASE SRC_CLONE FROM ROLE PUBLIC",
        "REVOKE ALL PRIVILEGES ON DATABASE SRC_CLONE FROM ROLE SAGE_CITATIONS_ADMIN",
    }
    assert set(session.executed_sql) == expected
    for role, _sql, ignore_errors in session.executed:
        assert role == phases.SECURITYADMIN
        assert ignore_errors is True


# --------------------------------------------------------------------------- #
# deploy
# --------------------------------------------------------------------------- #
def test_deploy_no_folder_skips(make_context, monkeypatch):
    calls = []
    monkeypatch.setattr(
        phases.subprocess, "run", lambda *a, **k: calls.append((a, k))
    )
    ctx = make_context()  # deploy_folder None
    phases.deploy(ctx)
    assert calls == []


def test_deploy_dry_run_skips(make_context, monkeypatch):
    calls = []
    monkeypatch.setattr(
        phases.subprocess, "run", lambda *a, **k: calls.append((a, k))
    )
    ctx = make_context(dry_run=True, deploy_folder="sage")
    phases.deploy(ctx)
    assert calls == []


def test_deploy_live_runs_schemachange(make_context, monkeypatch):
    calls = []

    def recorder(*args, **kwargs):
        calls.append((args, kwargs))

    monkeypatch.setattr(phases.subprocess, "run", recorder)
    ctx = make_context(deploy_folder="sage")
    phases.deploy(ctx)

    assert len(calls) == 1
    args, kwargs = calls[0]
    assert args[0] == [
        "schemachange",
        "--connection-name", "default",
        "--root-folder", "sage",
        "--config-folder", "sage",
        "--snowflake-role", "DATA_ENGINEER",
    ]
    assert kwargs["check"] is True
    assert kwargs["env"]["SNOWFLAKE_DEPLOY_DATABASE"] == "SRC_CLONE"
