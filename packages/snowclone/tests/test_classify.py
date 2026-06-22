"""Tests for ``snowclone/classify.py`` — pure ownership classification.

These functions take introspection dataclasses and return plain Python, so the
tests construct the dataclasses directly and need no Snowflake or fixtures.
"""

from __future__ import annotations

import pytest

from snowclone import classify, introspect, sql

# Real ObjectType instances from the canonical metadata.
TABLE = next(o for o in sql.OBJECT_TYPES if o.label == "TABLE")
DYN = next(o for o in sql.OBJECT_TYPES if o.label == "DYNAMIC TABLE")
STREAMLIT = next(o for o in sql.OBJECT_TYPES if o.label == "STREAMLIT")


# --------------------------------------------------------------------------- #
# top_level_database_roles
# --------------------------------------------------------------------------- #
def test_top_level_database_roles_mixed():
    roles = [
        introspect.DatabaseRole("A_ALL_ADMIN", "PROXY"),
        introspect.DatabaseRole("A_CHILD", "A_ALL_ADMIN"),
        introspect.DatabaseRole("B_ALL_ADMIN", "PROXY"),
    ]
    assert classify.top_level_database_roles(roles) == ["A_ALL_ADMIN", "B_ALL_ADMIN"]


def test_top_level_database_roles_case_insensitive_owner():
    roles = [
        introspect.DatabaseRole("CHILD", "a_all_admin"),
        introspect.DatabaseRole("A_ALL_ADMIN", "PROXY"),
    ]
    assert classify.top_level_database_roles(roles) == ["A_ALL_ADMIN"]


def test_top_level_database_roles_empty():
    assert classify.top_level_database_roles([]) == []


# --------------------------------------------------------------------------- #
# object_transfers_for_schema
# --------------------------------------------------------------------------- #
def test_object_transfers_all_database_role_owners_skipped():
    owned = [introspect.OwnedType(TABLE, {("A_ALL_ADMIN", "DATABASE_ROLE")}, 5)]
    assert classify.object_transfers_for_schema("S", owned, "P", set()) == []


def test_object_transfers_account_owner_included():
    owned = [introspect.OwnedType(DYN, {("ACCT", "ROLE")}, 3)]
    assert classify.object_transfers_for_schema("S", owned, "P", set()) == [
        "DYNAMIC TABLES"
    ]


def test_object_transfers_owner_is_proxy_skipped():
    owned = [introspect.OwnedType(DYN, {("P", "ROLE")}, 1)]
    assert classify.object_transfers_for_schema("S", owned, "P", set()) == []


def test_object_transfers_owner_protected_skipped():
    owned = [introspect.OwnedType(DYN, {("SYSADMIN", "ROLE")}, 1)]
    assert classify.object_transfers_for_schema("S", owned, "P", {"SYSADMIN"}) == []


def test_object_transfers_non_transferable_skipped(caplog):
    owned = [introspect.OwnedType(STREAMLIT, {("APP", "ROLE")}, 2)]
    with caplog.at_level("INFO"):
        result = classify.object_transfers_for_schema("S", owned, "P", set())
    assert result == []


def test_object_transfers_mixed_ownership_warns(caplog):
    owned = [
        introspect.OwnedType(
            TABLE, {("A_ALL_ADMIN", "DATABASE_ROLE"), ("ACCT", "ROLE")}, 6
        )
    ]
    with caplog.at_level("WARNING"):
        result = classify.object_transfers_for_schema("S", owned, "P", set())
    assert result == ["TABLES"]
    assert any("mixed" in r.message.lower() for r in caplog.records)


def test_object_transfers_multiple_types_subset():
    owned = [
        introspect.OwnedType(TABLE, {("A_ALL_ADMIN", "DATABASE_ROLE")}, 5),  # skipped
        introspect.OwnedType(DYN, {("ACCT", "ROLE")}, 3),  # included
    ]
    assert classify.object_transfers_for_schema("S", owned, "P", set()) == [
        "DYNAMIC TABLES"
    ]


# --------------------------------------------------------------------------- #
# account_role_owned_schemas
# --------------------------------------------------------------------------- #
def test_account_role_owned_schemas():
    schema_infos = [
        introspect.SchemaInfo("CITATIONS", "SAGE_CITATIONS_ADMIN", "ROLE"),
        introspect.SchemaInfo("FINANCE", "FINANCE_ALL_ADMIN", "DATABASE_ROLE"),
        introspect.SchemaInfo("AUDIT", "SYSADMIN", "ROLE"),
        introspect.SchemaInfo("OWN", "P", "ROLE"),
        introspect.SchemaInfo("SCHEMACHANGE", "SRC_ADMIN", "ROLE"),
    ]
    assert classify.account_role_owned_schemas(schema_infos, "P") == [
        "CITATIONS",
        "SCHEMACHANGE",
    ]


# --------------------------------------------------------------------------- #
# account_role_future_owners
# --------------------------------------------------------------------------- #
def test_account_role_future_owners_filters():
    grants = [
        introspect.FutureGrant("OWNERSHIP", "TABLE", "ROLE", "R1", None),
        introspect.FutureGrant("OWNERSHIP", "TABLE", "DATABASE_ROLE", "DR", None),
        introspect.FutureGrant("SELECT", "TABLE", "ROLE", "R2", None),
    ]
    result = classify.account_role_future_owners(grants)
    assert result == [grants[0]]


def test_account_role_future_owners_case_insensitive():
    fg = introspect.FutureGrant("ownership", "TABLE", "role", "R", "S")
    assert classify.account_role_future_owners([fg]) == [fg]
