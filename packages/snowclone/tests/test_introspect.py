"""Unit tests for ``snowclone/introspect.py`` (read-only SHOW parsing)."""

from __future__ import annotations

from snowclone import introspect, sql


# --------------------------------------------------------------------------- #
# _cval
# --------------------------------------------------------------------------- #
def test_cval_exact_key():
    assert introspect._cval({"owner": "X"}, "owner") == "X"


def test_cval_upper_variant():
    assert introspect._cval({"OWNER": "X"}, "owner") == "X"


def test_cval_skips_none_tries_next_key():
    assert introspect._cval({"a": None, "b": "Y"}, "a", "b") == "Y"


def test_cval_missing_returns_none():
    assert introspect._cval({}, "x") is None


# --------------------------------------------------------------------------- #
# database_roles
# --------------------------------------------------------------------------- #
def test_database_roles(make_session, rows):
    session = make_session(
        {
            "SHOW DATABASE ROLES IN DATABASE": [
                rows.db_role("A", "O1"),
                rows.db_role("B", "O2"),
                {"owner": "x"},  # missing name -> skipped
            ]
        }
    )
    result = introspect.database_roles(session, "SRC_CLONE", "SRC_ADMIN")

    assert [r.name for r in result] == ["A", "B"]
    assert [r.owner for r in result] == ["O1", "O2"]


# --------------------------------------------------------------------------- #
# schemas_with_owners
# --------------------------------------------------------------------------- #
def test_schemas_with_owners(make_session, rows):
    session = make_session(
        {
            "SHOW SCHEMAS IN DATABASE": [
                rows.schema("CITATIONS", "SAGE_CITATIONS_ADMIN", "ROLE"),
                rows.schema("FINANCE", "FINANCE_ALL_ADMIN", "DATABASE_ROLE"),
                {"name": "INFORMATION_SCHEMA", "owner": "X"},
                {"name": "NOTYPE", "owner": "Y"},
            ]
        }
    )
    result = introspect.schemas_with_owners(session, "SRC_CLONE", "SRC_ADMIN")

    names = [s.name for s in result]
    assert "INFORMATION_SCHEMA" not in names
    assert names == ["CITATIONS", "FINANCE", "NOTYPE"]

    by_name = {s.name: s for s in result}
    assert by_name["CITATIONS"].owner_role_type == "ROLE"
    assert by_name["FINANCE"].owner_role_type == "DATABASE_ROLE"
    # owner_role_type column absent -> defaults to ROLE
    assert by_name["NOTYPE"].owner_role_type == "ROLE"


# --------------------------------------------------------------------------- #
# owned_objects
# --------------------------------------------------------------------------- #
def test_owned_objects_excludes_dynamic_tables(make_session, rows):
    session = make_session(
        {
            "SHOW TABLES IN DATABASE": [
                rows.obj("S", "O", is_dynamic="N"),
                rows.obj("S", "PROXY", is_dynamic="Y"),  # dynamic table -> dropped
            ]
        }
    )
    result = introspect.owned_objects(session, "SRC_CLONE", set(), "SRC_ADMIN")

    assert list(result.keys()) == ["S"]
    owned = result["S"]
    assert len(owned) == 1
    ot = owned[0]
    assert ot.object_type.label == "TABLE"
    assert ot.count == 1
    assert ot.owners == {("O", "ROLE")}


def test_owned_objects_excludes_materialized_views(make_session, rows):
    session = make_session(
        {
            "SHOW VIEWS IN DATABASE": [
                rows.obj("S", "O", is_materialized="N"),
                rows.obj("S", "MV", is_materialized="Y"),  # materialized view -> dropped
            ]
        }
    )
    result = introspect.owned_objects(session, "SRC_CLONE", set(), "SRC_ADMIN")

    owned = result["S"]
    assert len(owned) == 1
    ot = owned[0]
    assert ot.object_type.label == "VIEW"
    assert ot.count == 1
    assert ot.owners == {("O", "ROLE")}


def test_owned_objects_infers_owner_role_type(make_session, rows):
    session = make_session(
        {
            "SHOW STREAMS IN DATABASE": [
                rows.obj("S", "A_ALL_ADMIN", owner_role_type=None),
                rows.obj("S", "ACCT", owner_role_type=None),
            ]
        }
    )
    result = introspect.owned_objects(
        session, "SRC_CLONE", {"A_ALL_ADMIN"}, "SRC_ADMIN"
    )

    owned = result["S"]
    assert len(owned) == 1
    ot = owned[0]
    assert ot.object_type.label == "STREAM"
    assert ot.count == 2
    assert ot.owners == {
        ("A_ALL_ADMIN", "DATABASE_ROLE"),
        ("ACCT", "ROLE"),
    }


def test_owned_objects_skips_blank_owner_or_schema(make_session, rows):
    session = make_session({"SHOW TABLES IN DATABASE": [{"name": "x"}]})
    result = introspect.owned_objects(session, "SRC_CLONE", set(), "SRC_ADMIN")
    assert result == {}


def test_owned_objects_catches_show_errors(make_session, rows):
    def router(stmt):
        if "SHOW TASKS IN DATABASE" in stmt:
            raise Exception("boom")
        if "SHOW TABLES IN DATABASE" in stmt:
            return [rows.obj("S", "O")]
        return []

    session = make_session(router)
    result = introspect.owned_objects(session, "SRC_CLONE", set(), "SRC_ADMIN")

    assert "S" in result
    labels = {ot.object_type.label for ot in result["S"]}
    assert "TABLE" in labels


# --------------------------------------------------------------------------- #
# future grants
# --------------------------------------------------------------------------- #
def test_future_grants_in_schema(make_session, rows):
    session = make_session(
        {
            "SHOW FUTURE GRANTS IN SCHEMA": [
                rows.future(
                    privilege="OWNERSHIP",
                    grant_on="DYNAMIC_TABLE",
                    grant_to="ROLE",
                    grantee_name="R1",
                )
            ]
        }
    )
    result = introspect.future_grants_in_schema(
        session, "SRC_CLONE", "MYSCHEMA", "SRC_ADMIN"
    )

    assert len(result) == 1
    fg = result[0]
    assert fg.privilege == "OWNERSHIP"
    assert fg.grant_on == "DYNAMIC_TABLE"
    assert fg.grant_to == "ROLE"
    assert fg.grantee_name == "R1"
    assert fg.schema == "MYSCHEMA"


def test_future_grants_in_schema_alternate_keys(make_session):
    # Raw row using granted_on / granted_to instead of grant_on / grant_to.
    raw = {
        "privilege": "OWNERSHIP",
        "granted_on": "TABLE",
        "granted_to": "DATABASE_ROLE",
        "grantee_name": "R2",
    }
    session = make_session({"SHOW FUTURE GRANTS IN SCHEMA": [raw]})
    result = introspect.future_grants_in_schema(
        session, "SRC_CLONE", "S", "SRC_ADMIN"
    )

    fg = result[0]
    assert fg.grant_on == "TABLE"
    assert fg.grant_to == "DATABASE_ROLE"


def test_future_grants_in_database_schema_is_none(make_session, rows):
    session = make_session(
        {"SHOW FUTURE GRANTS IN DATABASE": [rows.future(grantee_name="R")]}
    )
    result = introspect.future_grants_in_database(session, "SRC_CLONE", "SRC_ADMIN")

    assert len(result) == 1
    assert result[0].schema is None


# --------------------------------------------------------------------------- #
# grants_on_database
# --------------------------------------------------------------------------- #
def test_grants_on_database(make_session, rows):
    session = make_session(
        {
            "SHOW GRANTS ON DATABASE": [
                rows.grant(privilege="USAGE", granted_to="ROLE", grantee_name="R1")
            ]
        }
    )
    result = introspect.grants_on_database(session, "SRC_CLONE", "SRC_ADMIN")

    assert len(result) == 1
    g = result[0]
    assert g.privilege == "USAGE"
    assert g.granted_to == "ROLE"
    assert g.grantee_name == "R1"


def test_grants_on_database_grant_to_fallback(make_session):
    # Raw row using grant_to as fallback for granted_to.
    raw = {"privilege": "MODIFY", "grant_to": "DATABASE_ROLE", "grantee_name": "R3"}
    session = make_session({"SHOW GRANTS ON DATABASE": [raw]})
    result = introspect.grants_on_database(session, "SRC_CLONE", "SRC_ADMIN")

    assert result[0].granted_to == "DATABASE_ROLE"
