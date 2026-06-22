"""Tests for the ``teardown`` core (drop sequence)."""

from __future__ import annotations

from snowclone import teardown


def test_teardown_drop_sequence(make_session):
    session = make_session()
    teardown.teardown(session, "SAGE", "SAGE_SNOW_1")
    assert session.executed == [
        ("SAGE_ADMIN", "DROP DATABASE IF EXISTS SAGE_SNOW_1", False),
        ("USERADMIN", "DROP ROLE IF EXISTS SAGE_SNOW_1_PROXY_ADMIN", False),
    ]
