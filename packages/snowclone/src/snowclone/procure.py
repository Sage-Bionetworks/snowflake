"""Procurement core for ``snowclone freeze``.

Discovers a clone's ownership hierarchy at runtime (rather than hardcoding
schema/role names) and reconfigures it. The database is identified entirely by
arguments — there is no per-database registry. Argument parsing and dispatch live
in :mod:`snowclone.cli`; this module holds the reusable pieces it calls.
"""

from __future__ import annotations

import argparse
import re

from . import phases
from .connection import Session


def sanitize(name: str) -> str:
    """Upper-case ``name`` and replace any non ``[A-Za-z0-9_]`` char with ``_``.

    Matches the sanitization the old ``test_with_clone.yaml`` workflow applied.
    """
    return re.sub(r"[^A-Za-z0-9_]", "_", name).upper()


def resolve_clone_name(args: argparse.Namespace) -> str:
    """Derive the sanitized clone database name from CLI args.

    Returns:
        ``--clone-name`` if given, else ``{database}_{clone_suffix}``.

    Raises:
        SystemExit: If neither ``--clone-name`` nor ``--clone-suffix`` is provided.
    """
    if args.clone_name:
        return sanitize(args.clone_name)
    if not args.clone_suffix:
        raise SystemExit("Provide either --clone-name or --clone-suffix")
    return sanitize(f"{args.database}_{args.clone_suffix}")


def build_context(args: argparse.Namespace, session: Session) -> phases.Context:
    """Build the :class:`phases.Context` from parsed args and an open session."""
    source_db = sanitize(args.database)
    clone_db = resolve_clone_name(args)
    if clone_db == source_db:
        raise SystemExit(f"Clone name '{clone_db}' must differ from source '{source_db}'")
    return phases.Context(
        session=session,
        source_db=source_db,
        clone_db=clone_db,
        admin_role=f"{source_db}_ADMIN",
        proxy_role=f"{clone_db}_PROXY_ADMIN",
        developer_role=args.developer_role,
        connection_name=args.connection_name,
        deploy_folder=args.deploy_folder,
    )


def procure(ctx: phases.Context) -> None:
    """Run the full provisioning sequence (Phases 1–9) for ``ctx``."""
    from . import introspect

    phases.clone(ctx)

    # Schemas (with owners) are enumerated once up front (introspection runs with
    # full visibility) and reused by the revoke, transfer, and future-grant phases.
    # Capture and ownership transfer do not add schemas, so this list stays valid.
    schema_infos = introspect.schemas_with_owners(ctx.session, ctx.introspect_db, role=phases.INTROSPECT)
    schemas = [s.name for s in schema_infos]

    # Isolate the clone first: strip database USAGE from every non-allowlisted
    # account role, before layering on the proxy's control. (Schema/object grants
    # are retained for fidelity — inert without database USAGE.)
    phases.revoke_other_roles(ctx)

    phases.create_proxy(ctx)
    phases.grant_proxy_to_developer(ctx)
    db_role_names = phases.capture_database_roles(ctx)
    phases.transfer_object_ownership(ctx, db_role_names, schema_infos)
    phases.repoint_future_grants(ctx, schemas)
    phases.grant_database_privileges(ctx)
    phases.deploy(ctx)  # no-op when --deploy-folder was not supplied
