"""Tests for ``snowclone/sql.py`` — pure metadata, builders, and the clone guard."""

from __future__ import annotations

import pytest

from snowclone import sql


def test_system_roles():
    assert isinstance(sql.SYSTEM_ROLES, frozenset)
    assert sql.SYSTEM_ROLES == {
        "ACCOUNTADMIN",
        "SECURITYADMIN",
        "SYSADMIN",
        "USERADMIN",
        "PUBLIC",
    }


@pytest.mark.parametrize(
    "token, expected",
    [
        ("DYNAMIC_TABLE", "DYNAMIC TABLES"),
        ("TABLE", "TABLES"),
        ("table", "TABLES"),  # case-insensitive
        ("NOPE", None),
    ],
)
def test_future_grant_plural(token, expected):
    assert sql.future_grant_plural(token) == expected


def test_assert_clone_ok():
    assert sql.assert_clone("C", "C.SCHEMA") is None


def test_assert_clone_case_insensitive():
    assert sql.assert_clone("C", "c.schema") is None


def test_assert_clone_rejects_non_prefix():
    with pytest.raises(RuntimeError):
        sql.assert_clone("C", "SRC.X")


@pytest.mark.parametrize(
    "actual, expected",
    [
        (sql.clone_database("C", "S"), "CREATE OR REPLACE DATABASE C CLONE S"),
        (sql.create_proxy_role("P"), "CREATE OR REPLACE ROLE P"),
        (sql.grant_role_to_role("R", "T"), "GRANT ROLE R TO ROLE T"),
        (
            sql.take_database_role_ownership("C", "DR", "P"),
            "GRANT OWNERSHIP ON DATABASE ROLE C.DR TO ROLE P REVOKE CURRENT GRANTS",
        ),
        (sql.grant_database_role("C", "DR", "P"), "GRANT DATABASE ROLE C.DR TO ROLE P"),
        (
            sql.transfer_schema_ownership("C", "SCH", "P"),
            "GRANT OWNERSHIP ON SCHEMA C.SCH TO ROLE P COPY CURRENT GRANTS",
        ),
        (
            sql.transfer_all_objects("C", "SCH", "DYNAMIC TABLES", "P"),
            "GRANT OWNERSHIP ON ALL DYNAMIC TABLES IN SCHEMA C.SCH TO ROLE P COPY CURRENT GRANTS",
        ),
        (
            sql.revoke_future_ownership("C", "SCH", "TABLES", "ROLE X"),
            "REVOKE OWNERSHIP ON FUTURE TABLES IN SCHEMA C.SCH FROM ROLE X",
        ),
        (
            sql.grant_future_ownership("C", "SCH", "TABLES", "P"),
            "GRANT OWNERSHIP ON FUTURE TABLES IN SCHEMA C.SCH TO ROLE P",
        ),
        (
            sql.revoke_future_ownership_in_db("C", "TABLES", "ROLE X"),
            "REVOKE OWNERSHIP ON FUTURE TABLES IN DATABASE C FROM ROLE X",
        ),
        (
            sql.grant_future_ownership_in_db("C", "TABLES", "P"),
            "GRANT OWNERSHIP ON FUTURE TABLES IN DATABASE C TO ROLE P",
        ),
        (
            sql.grant_database_privileges("C", "DEV"),
            "GRANT MODIFY, MONITOR, CREATE SCHEMA, CREATE DATABASE ROLE ON DATABASE C TO ROLE DEV",
        ),
        (
            sql.revoke_all_on_database("C", "R"),
            "REVOKE ALL PRIVILEGES ON DATABASE C FROM ROLE R",
        ),
        (sql.drop_database("C"), "DROP DATABASE IF EXISTS C"),
        (sql.drop_role("R"), "DROP ROLE IF EXISTS R"),
    ],
)
def test_builders_exact_strings(actual, expected):
    assert actual == expected


def _find(label):
    return next(ot for ot in sql.OBJECT_TYPES if ot.label == label)


def test_object_types_metadata():
    assert "is_dynamic" in _find("TABLE").exclude_flags
    assert "is_materialized" in _find("VIEW").exclude_flags
    assert _find("STREAMLIT").transferable is False

    dynamic_table = _find("DYNAMIC TABLE")
    assert dynamic_table.transferable is True
    assert dynamic_table.exclude_flags == ()


def test_grant_plural_by_token():
    assert sql._GRANT_PLURAL_BY_TOKEN["DYNAMIC_TABLE"] == "DYNAMIC TABLES"
    assert sql._GRANT_PLURAL_BY_TOKEN["TABLE"] == "TABLES"
