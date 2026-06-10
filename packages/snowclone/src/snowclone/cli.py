"""The unified ``snowclone`` command line.

Two subcommands:

* ``snowclone freeze …`` — procure an RBAC-configured zero-copy clone environment.
* ``snowclone melt …``   — tear that clone environment down.

The clone is identified entirely by arguments (``--database`` plus ``--clone-suffix``
or ``--clone-name``); there is no per-database registry.
"""

from __future__ import annotations

import argparse
import logging
import sys

from . import procure, teardown
from .connection import Session

logger = logging.getLogger("snowclone")


def _add_clone_selectors(p: argparse.ArgumentParser) -> None:
    p.add_argument("--clone-suffix", help="Suffix appended to the source name (e.g. a branch name)")
    p.add_argument("--clone-name", help="Explicit clone database name (overrides --clone-suffix)")


def _add_common(p: argparse.ArgumentParser) -> None:
    p.add_argument("--connection-name", default="default", help="snow connection name (default: default)")
    p.add_argument("--dry-run", action="store_true", help="Log mutating SQL without executing it")
    p.add_argument("--verbose", action="store_true", help="Enable debug logging")


def build_parser() -> argparse.ArgumentParser:
    """Build the ``snowclone`` argument parser with the ``create``/``melt`` subcommands."""
    parser = argparse.ArgumentParser(
        prog="snowclone",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = parser.add_subparsers(dest="command", required=True, metavar="{freeze,melt}")

    freeze = sub.add_parser("freeze", help="Procure an RBAC-configured clone environment.")
    freeze.add_argument("--database", required=True, help="Source database to clone (e.g. SAGE)")
    _add_clone_selectors(freeze)
    freeze.add_argument(
        "--developer-role", default="DATA_ENGINEER",
        help="Account role the clone is provisioned for (default: DATA_ENGINEER)",
    )
    freeze.add_argument(
        "--deploy-folder",
        help="schemachange root/config folder (e.g. synapse_data_warehouse, sage). If omitted, the deploy is skipped.",
    )
    _add_common(freeze)

    melt = sub.add_parser("melt", help="Tear down a clone environment (drop the clone DB and its proxy role).")
    melt.add_argument("--database", required=True, help="Source database that was cloned")
    _add_clone_selectors(melt)
    _add_common(melt)

    return parser


def main(argv: list[str] | None = None) -> int:
    """CLI entrypoint: dispatch ``create``/``melt``; returns a process exit code."""
    args = build_parser().parse_args(argv)
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)-7s %(message)s",
    )
    with Session(connection_name=args.connection_name, dry_run=args.dry_run) as session:
        if args.command == "freeze":
            ctx = procure.build_context(args, session)
            logger.info(
                "Procuring clone '%s' of '%s' (proxy=%s, developer=%s, dry_run=%s)",
                ctx.clone_db, ctx.source_db, ctx.proxy_role, ctx.developer_role, args.dry_run,
            )
            procure.procure(ctx)
        else:  # melt
            source_db = procure.sanitize(args.database)
            clone_db = procure.resolve_clone_name(args)
            logger.info("Tearing down clone '%s' of '%s' (dry_run=%s)", clone_db, source_db, args.dry_run)
            teardown.teardown(session, source_db, clone_db)
    logger.info("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
