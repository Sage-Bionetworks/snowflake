"""Tests for the ``procure`` core (name resolution, context build, pipeline order)."""

from __future__ import annotations

import argparse

import pytest

from snowclone import phases, procure


# --------------------------------------------------------------------------- #
# sanitize
# --------------------------------------------------------------------------- #
@pytest.mark.parametrize(
    "raw, expected",
    [
        ("snow-417", "SNOW_417"),
        ("SYNAPSE_DATA_WAREHOUSE_DEV", "SYNAPSE_DATA_WAREHOUSE_DEV"),
        ("a.b c", "A_B_C"),
        ("sage", "SAGE"),
    ],
)
def test_sanitize(raw, expected):
    assert procure.sanitize(raw) == expected


# --------------------------------------------------------------------------- #
# resolve_clone_name
# --------------------------------------------------------------------------- #
def test_resolve_clone_name_explicit_wins():
    args = argparse.Namespace(clone_name="my-clone", clone_suffix="snow-1", database="SAGE")
    assert procure.resolve_clone_name(args) == "MY_CLONE"


def test_resolve_clone_name_from_suffix():
    args = argparse.Namespace(clone_name=None, clone_suffix="snow-1", database="SAGE")
    assert procure.resolve_clone_name(args) == "SAGE_SNOW_1"


def test_resolve_clone_name_neither_raises():
    args = argparse.Namespace(clone_name=None, clone_suffix=None, database="SAGE")
    with pytest.raises(SystemExit):
        procure.resolve_clone_name(args)


# --------------------------------------------------------------------------- #
# build_context
# --------------------------------------------------------------------------- #
def test_build_context(make_session):
    session = make_session()
    args = argparse.Namespace(
        database="SAGE",
        clone_name=None,
        clone_suffix="snow-1",
        developer_role="DATA_ENGINEER",
        connection_name="default",
        deploy_folder="sage",
    )
    ctx = procure.build_context(args, session)
    assert ctx.source_db == "SAGE"
    assert ctx.clone_db == "SAGE_SNOW_1"
    assert ctx.admin_role == "SAGE_ADMIN"
    assert ctx.proxy_role == "SAGE_SNOW_1_PROXY_ADMIN"
    assert ctx.developer_role == "DATA_ENGINEER"
    assert ctx.connection_name == "default"
    assert ctx.deploy_folder == "sage"
    assert ctx.session is session


def test_build_context_clone_equals_source_raises(make_session):
    args = argparse.Namespace(
        database="X",
        clone_name="X",
        clone_suffix=None,
        developer_role="DATA_ENGINEER",
        connection_name="default",
        deploy_folder=None,
    )
    with pytest.raises(SystemExit):
        procure.build_context(args, make_session())


# --------------------------------------------------------------------------- #
# procure (pipeline orchestration order)
# --------------------------------------------------------------------------- #
def test_procure_pipeline_order(monkeypatch, make_context):
    calls: list[str] = []
    import snowclone.introspect as introspect_mod

    for name in [
        "clone",
        "revoke_other_roles",
        "create_proxy",
        "grant_proxy_to_developer",
        "capture_database_roles",
        "transfer_object_ownership",
        "repoint_future_grants",
        "grant_database_privileges",
        "deploy",
    ]:
        monkeypatch.setattr(
            phases,
            name,
            (lambda n: (lambda *a, **k: (calls.append(n), set())[1]))(name),
        )
    monkeypatch.setattr(introspect_mod, "schemas_with_owners", lambda *a, **k: [])

    procure.procure(make_context())

    assert calls == [
        "clone",
        "revoke_other_roles",
        "create_proxy",
        "grant_proxy_to_developer",
        "capture_database_roles",
        "transfer_object_ownership",
        "repoint_future_grants",
        "grant_database_privileges",
        "deploy",
    ]
