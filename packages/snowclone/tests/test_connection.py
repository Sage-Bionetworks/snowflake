"""Tests for ``snowclone/connection.py``.

Hermetic: ``snowflake.connector`` resolves to the stub installed by ``conftest``,
and the ``fake_connection`` fixture monkeypatches its ``connect`` to return a
``FakeConnection``. Always call ``fake_connection(...)`` before constructing the
``Session`` so the patched ``connect`` is in place.
"""

from __future__ import annotations

import pytest

import snowflake.connector

from snowclone import connection


def test_init_stores_dry_run_and_connects(fake_connection):
    fake_connection()
    s = connection.Session(connection_name="x", dry_run=True)
    assert s.dry_run is True


def test_query_with_role_issues_use_role_then_returns_rows(fake_connection):
    conn = fake_connection(fetch_rows=[{"a": 1}])
    s = connection.Session()
    out = s.query("SHOW X", role="R")
    assert out == [{"a": 1}]
    assert conn.executed == ["USE ROLE R", "SHOW X"]


def test_query_without_role(fake_connection):
    conn = fake_connection(fetch_rows=[])
    s = connection.Session()
    s.query("SHOW Y")
    assert conn.executed == ["SHOW Y"]


def test_execute_dry_run_runs_nothing(fake_connection):
    conn = fake_connection()
    s = connection.Session(dry_run=True)
    s.execute("GRANT ...", role="R")
    assert conn.executed == []


def test_execute_live_use_role_then_sql(fake_connection):
    conn = fake_connection()
    s = connection.Session()
    s.execute("GRANT FOO", role="R")
    assert conn.executed == ["USE ROLE R", "GRANT FOO"]


def test_execute_ignore_errors_swallows(fake_connection):
    fake_connection(raise_on="REVOKE")
    s = connection.Session()
    # "USE ROLE R" does not contain "REVOKE", so only the second statement raises.
    s.execute("REVOKE BAR", role="R", ignore_errors=True)


def test_execute_reraises_without_ignore(fake_connection):
    fake_connection(raise_on="REVOKE")
    s = connection.Session()
    with pytest.raises(snowflake.connector.errors.ProgrammingError):
        s.execute("REVOKE BAR", role="R")


def test_context_manager_closes(fake_connection):
    conn = fake_connection()
    with connection.Session() as s:
        assert s is not None
    assert conn.closed is True
