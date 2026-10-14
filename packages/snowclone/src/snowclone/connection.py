"""Snowflake connection handling and a thin SQL-execution session.

Reuses the ``default`` connection written to ``~/.snowflake/connections.toml`` by
the ``configure-snowflake-cli`` GitHub Action (the same connection the ``snow``
CLI and schemachange use), so no credentials are handled here. See
``finance/mip_raw_elt_batch.py`` and ``analytics/portal_elt.py`` for the
established ``snowflake-connector-python`` pattern elsewhere in this repo.
"""

from __future__ import annotations

import logging

import snowflake.connector

logger = logging.getLogger(__name__)


class Session:
    """A Snowflake session that switches roles per statement.

    Two execution paths:

    * :meth:`query` always runs (read-only ``SHOW`` introspection) and returns
      rows as a list of dicts, even in dry-run mode, so classification reflects
      the real database.
    * :meth:`execute` runs mutating DDL; in dry-run mode it logs the statement
      and the role it would run as, but does not execute.
    """

    def __init__(self, connection_name: str = "default", dry_run: bool = False):
        """Open the named connection from ``connections.toml``.

        Args:
            connection_name: Connection profile to use.
            dry_run: If True, :meth:`execute` logs statements instead of running them.
        """
        self.dry_run = dry_run
        logger.info("Connecting to Snowflake using connection '%s'", connection_name)
        self._conn = snowflake.connector.connect(connection_name=connection_name)

    def close(self) -> None:
        """Close the underlying connection."""
        self._conn.close()

    def __enter__(self) -> "Session":
        return self

    def __exit__(self, *exc) -> None:
        self.close()

    def _use_role(self, role: str) -> None:
        # USE ROLE is itself read-only state, safe to run even in dry-run so that
        # subsequent read-only SHOW queries are scoped correctly.
        self._conn.cursor().execute(f"USE ROLE {role}")

    def query(self, sql: str, role: str | None = None) -> list[dict]:
        """Run a read-only statement (e.g. ``SHOW ...``) and return its rows.

        Always executes, even in dry-run, so classification sees the real database.

        Args:
            sql: The read-only statement to run.
            role: Role to assume first, or None to keep the current role.

        Returns:
            Result rows as dicts (one per row).
        """
        if role:
            self._use_role(role)
        logger.debug("QUERY [%s]: %s", role or "current", sql)
        cur = self._conn.cursor(snowflake.connector.DictCursor)
        cur.execute(sql)
        return cur.fetchall()

    def execute(self, sql: str, role: str, ignore_errors: bool = False) -> None:
        """Run a mutating statement as ``role`` (logged but skipped in dry-run).

        Args:
            sql: The statement to run.
            role: Role to assume before running it.
            ignore_errors: If True, log and swallow a statement-level failure
                (used for best-effort revokes of grants made by a role we cannot
                revoke as).
        """
        prefix = "[DRY-RUN] " if self.dry_run else ""
        logger.info("%sEXEC [%s]: %s", prefix, role, sql)
        if self.dry_run:
            return
        self._use_role(role)
        try:
            self._conn.cursor().execute(sql)
        except snowflake.connector.errors.ProgrammingError as err:
            if ignore_errors:
                logger.warning("  ↳ ignored error: %s", err.msg)
                return
            raise
