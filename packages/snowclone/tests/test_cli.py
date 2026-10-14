"""Tests for the unified ``snowclone`` CLI (subcommand parsing + dispatch)."""

from __future__ import annotations

import pytest

from snowclone import cli, procure, teardown


# --------------------------------------------------------------------------- #
# Argument parsing
# --------------------------------------------------------------------------- #
def test_requires_a_subcommand():
    with pytest.raises(SystemExit):
        cli.build_parser().parse_args([])


def test_freeze_requires_database():
    with pytest.raises(SystemExit):
        cli.build_parser().parse_args(["freeze"])


def test_melt_requires_database():
    with pytest.raises(SystemExit):
        cli.build_parser().parse_args(["melt"])


def test_freeze_defaults():
    ns = cli.build_parser().parse_args(["freeze", "--database", "SAGE", "--clone-suffix", "snow-1"])
    assert ns.command == "freeze"
    assert ns.database == "SAGE"
    assert ns.developer_role == "DATA_ENGINEER"
    assert ns.connection_name == "default"
    assert ns.dry_run is False
    assert ns.deploy_folder is None
    assert ns.clone_suffix == "snow-1"
    assert ns.clone_name is None


def test_freeze_deploy_folder_and_dry_run():
    ns = cli.build_parser().parse_args(
        ["freeze", "--database", "SAGE", "--deploy-folder", "sage", "--dry-run"]
    )
    assert ns.deploy_folder == "sage"
    assert ns.dry_run is True


def test_melt_args_and_no_freeze_only_options():
    ns = cli.build_parser().parse_args(["melt", "--database", "SAGE", "--clone-name", "X"])
    assert ns.command == "melt"
    assert ns.database == "SAGE"
    assert ns.clone_name == "X"
    # `melt` does not accept the freeze-only options
    assert not hasattr(ns, "deploy_folder")
    assert not hasattr(ns, "developer_role")


# --------------------------------------------------------------------------- #
# Dispatch (Session uses the fake connection; the core funcs are stubbed)
# --------------------------------------------------------------------------- #
def test_main_freeze_dispatches_to_procure(fake_connection, monkeypatch):
    fake_connection()
    captured = {}
    monkeypatch.setattr(procure, "procure", lambda ctx: captured.__setitem__("ctx", ctx))

    rc = cli.main(["freeze", "--database", "SAGE", "--clone-suffix", "snow-1", "--dry-run"])

    assert rc == 0
    ctx = captured["ctx"]
    assert ctx.source_db == "SAGE"
    assert ctx.clone_db == "SAGE_SNOW_1"
    assert ctx.deploy_folder is None
    assert ctx.session.dry_run is True


def test_main_melt_dispatches_to_teardown(fake_connection, monkeypatch):
    fake_connection()
    seen = {}
    monkeypatch.setattr(
        teardown, "teardown",
        lambda session, source_db, clone_db: seen.update(source=source_db, clone=clone_db),
    )

    rc = cli.main(["melt", "--database", "SAGE", "--clone-name", "my-clone"])

    assert rc == 0
    assert seen == {"source": "SAGE", "clone": "MY_CLONE"}
