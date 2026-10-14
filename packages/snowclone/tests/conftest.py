"""Shared pytest fixtures and test doubles for the ``snowclone`` suite.

A lightweight ``snowflake.connector`` stub is installed at import time — before any
``snowclone.*`` module is imported — so the suite is hermetic (only ``pytest``
is required, not the real driver) and the ``connection.py`` tests are deterministic.

Test files use the fixtures below and never import this module directly:

* ``make_session`` — build a :class:`FakeSession` (records executes, routes queries).
* ``make_context`` — build a ``phases.Context`` wired to a ``FakeSession``.
* ``rows`` — namespace of SHOW-row builder functions.
* ``fake_connection`` — factory that monkeypatches the stubbed ``connect`` for
  ``connection.py`` tests.
"""

from __future__ import annotations

import sys
import types

import pytest


# --------------------------------------------------------------------------- #
# Hermetic driver stub. Must run at module import, before snowclone.* loads
# (pytest imports conftest before collecting the tests in this directory).
# --------------------------------------------------------------------------- #
def _install_snowflake_stub() -> None:
    existing = sys.modules.get("snowflake.connector")
    if existing is not None and getattr(existing, "_snowclone_stub", False):
        return

    snowflake = types.ModuleType("snowflake")
    connector = types.ModuleType("snowflake.connector")
    connector._snowclone_stub = True
    errors = types.ModuleType("snowflake.connector.errors")

    class ProgrammingError(Exception):
        def __init__(self, msg: str = "", *args, **kwargs):
            super().__init__(msg)
            self.msg = msg

    class DictCursor:  # marker passed as cursor_class; identity is all we need
        pass

    def connect(**kwargs):  # overridden per-test via the fake_connection fixture
        raise RuntimeError("snowflake.connector.connect called without monkeypatch")

    errors.ProgrammingError = ProgrammingError
    connector.errors = errors
    connector.DictCursor = DictCursor
    connector.connect = connect
    snowflake.connector = connector

    sys.modules["snowflake"] = snowflake
    sys.modules["snowflake.connector"] = connector
    sys.modules["snowflake.connector.errors"] = errors


_install_snowflake_stub()


# --------------------------------------------------------------------------- #
# Test doubles
# --------------------------------------------------------------------------- #
def _route(responses):
    """Turn a ``{statement_substring: rows}`` mapping into a query router.

    SHOW statements are unambiguous by substring because the object keyword
    follows ``SHOW`` (e.g. ``SHOW TABLES IN DATABASE`` is not a substring of
    ``SHOW DYNAMIC TABLES IN DATABASE``). Unmatched statements return ``[]``.
    """
    if responses is None:
        return lambda sql: []
    if callable(responses):
        return responses
    items = list(responses.items())

    def router(sql):
        for key, rows in items:
            if key in sql:
                return rows
        return []

    return router


class FakeSession:
    """Drop-in for ``connection.Session`` that records calls instead of hitting Snowflake.

    Attributes:
        dry_run: Mirrors the real session flag (drives ``Context.introspect_db``).
        executed: ``[(role, sql, ignore_errors), ...]`` from :meth:`execute`.
        queried: ``[(role, sql), ...]`` from :meth:`query`.
    """

    def __init__(self, responses=None, dry_run: bool = False):
        self.dry_run = dry_run
        self._router = _route(responses)
        self.executed: list[tuple] = []
        self.queried: list[tuple] = []

    def query(self, sql, role=None):
        self.queried.append((role, sql))
        return list(self._router(sql))

    def execute(self, sql, role, ignore_errors=False):
        self.executed.append((role, sql, ignore_errors))

    @property
    def executed_sql(self) -> list[str]:
        """Just the SQL strings that were executed, in order."""
        return [sql for _role, sql, _ig in self.executed]


class FakeCursor:
    """Cursor double: appends executed SQL to a shared sink and returns preset rows."""

    def __init__(self, sink: list[str], fetch_rows: list, raise_on: str | None):
        self._sink = sink
        self._rows = fetch_rows
        self._raise_on = raise_on

    def execute(self, sql):
        self._sink.append(sql)
        if self._raise_on and self._raise_on in sql:
            raise sys.modules["snowflake.connector"].errors.ProgrammingError("boom")
        return self

    def fetchall(self):
        return list(self._rows)


class FakeConnection:
    """Connection double for ``connection.py`` tests.

    Attributes:
        executed: Every SQL string run on any cursor (incl. ``USE ROLE``), in order.
        closed: Set True by :meth:`close`.
    """

    def __init__(self, fetch_rows: list | None = None, raise_on: str | None = None):
        self.executed: list[str] = []
        self.closed = False
        self._fetch_rows = fetch_rows or []
        self._raise_on = raise_on

    def cursor(self, cursor_class=None):
        return FakeCursor(self.executed, self._fetch_rows, self._raise_on)

    def close(self):
        self.closed = True


# --------------------------------------------------------------------------- #
# SHOW-row builders (shaped like real Snowflake SHOW output)
# --------------------------------------------------------------------------- #
def db_role_row(name, owner, **extra):
    return {"name": name, "owner": owner, **extra}


def schema_row(name, owner, owner_role_type="ROLE", **extra):
    return {"name": name, "owner": owner, "owner_role_type": owner_role_type, **extra}


def object_row(schema, owner, owner_role_type="ROLE", name="OBJ", **flags):
    """A SHOW <type> row. Pass ``is_dynamic="Y"`` etc. via ``flags``."""
    return {
        "name": name,
        "schema_name": schema,
        "owner": owner,
        "owner_role_type": owner_role_type,
        **flags,
    }


def future_grant_row(privilege="OWNERSHIP", grant_on="TABLE", grant_to="ROLE", grantee_name="R", **extra):
    return {
        "privilege": privilege,
        "grant_on": grant_on,
        "grant_to": grant_to,
        "grantee_name": grantee_name,
        **extra,
    }


def grant_row(privilege="USAGE", granted_to="ROLE", grantee_name="R", **extra):
    return {"privilege": privilege, "granted_to": granted_to, "grantee_name": grantee_name, **extra}


# --------------------------------------------------------------------------- #
# Fixtures
# --------------------------------------------------------------------------- #
@pytest.fixture
def make_session():
    """Factory: ``make_session(responses=None, dry_run=False) -> FakeSession``.

    ``responses`` is a ``{statement_substring: rows}`` mapping or a ``callable(sql)``.
    """
    def _make(responses=None, dry_run: bool = False) -> FakeSession:
        return FakeSession(responses=responses, dry_run=dry_run)

    return _make


@pytest.fixture
def make_context(make_session):
    """Factory: ``make_context(**overrides) -> phases.Context`` wired to a FakeSession.

    Defaults: source_db=SRC, clone_db=SRC_CLONE, admin_role=SRC_ADMIN,
    proxy_role=SRC_CLONE_PROXY_ADMIN, developer_role=DATA_ENGINEER,
    connection_name=default, deploy_folder=None. Pass ``session=`` to supply your
    own FakeSession, or ``dry_run=`` to build one.
    """
    from snowclone import phases

    def _make(session=None, dry_run: bool = False, **overrides):
        if session is None:
            session = make_session(dry_run=dry_run)
        params = dict(
            session=session,
            source_db="SRC",
            clone_db="SRC_CLONE",
            admin_role="SRC_ADMIN",
            proxy_role="SRC_CLONE_PROXY_ADMIN",
            developer_role="DATA_ENGINEER",
            connection_name="default",
            deploy_folder=None,
        )
        params.update(overrides)
        return phases.Context(**params)

    return _make


@pytest.fixture
def rows():
    """Namespace of SHOW-row builders: ``rows.db_role/schema/obj/future/grant``."""
    return types.SimpleNamespace(
        db_role=db_role_row,
        schema=schema_row,
        obj=object_row,
        future=future_grant_row,
        grant=grant_row,
    )


@pytest.fixture
def fake_connection(monkeypatch):
    """Factory: ``fake_connection(fetch_rows=None, raise_on=None) -> FakeConnection``.

    Monkeypatches the stubbed ``snowflake.connector.connect`` to return it, so
    ``connection.Session()`` picks it up.
    """
    connector = sys.modules["snowflake.connector"]

    def _make(fetch_rows=None, raise_on=None) -> FakeConnection:
        conn = FakeConnection(fetch_rows=fetch_rows, raise_on=raise_on)
        monkeypatch.setattr(connector, "connect", lambda **kw: conn)
        return conn

    return _make
