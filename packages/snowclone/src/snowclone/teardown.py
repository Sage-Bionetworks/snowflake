"""Teardown core for ``snowclone melt``: drop the clone database and its proxy role.

Argument parsing and dispatch live in :mod:`snowclone.cli`.
"""

from __future__ import annotations

import logging

from . import sql
from .connection import Session
from .phases import USERADMIN

logger = logging.getLogger("snowclone")


def teardown(session: Session, source_db: str, clone_db: str) -> None:
    """Drop the clone database (as the admin role) and its proxy role (as USERADMIN).

    Args:
        session: Active Snowflake session.
        source_db: Source database, used to derive the admin role name.
        clone_db: Clone database to drop (and whose proxy role to drop).
    """
    admin_role = f"{source_db}_ADMIN"
    proxy_role = f"{clone_db}_PROXY_ADMIN"
    logger.info("Dropping clone database %s", clone_db)
    session.execute(sql.drop_database(clone_db), role=admin_role)
    logger.info("Dropping proxy admin role %s", proxy_role)
    session.execute(sql.drop_role(proxy_role), role=USERADMIN)
