"""Read-only introspection of the clone via ``SHOW`` commands.

All functions return plain dataclasses / dicts so the classification logic in
``classify.py`` stays pure and testable. Nothing here mutates the database.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import TYPE_CHECKING

from . import sql

if TYPE_CHECKING:
    from .connection import Session

logger = logging.getLogger(__name__)

# Snowflake returns lowercase column headers for SHOW; be defensive anyway.
_INFORMATION_SCHEMA = "INFORMATION_SCHEMA"


def _cval(row: dict, *keys: str) -> str | None:
    """Return the first non-null value among ``keys`` (case-insensitively).

    Args:
        row: A SHOW result row.
        *keys: Candidate column names, tried in order.

    Returns:
        The matched value, or None if none of the keys are present.
    """
    for key in keys:
        for variant in (key, key.lower(), key.upper()):
            if variant in row and row[variant] is not None:
                return row[variant]
    return None


@dataclass(frozen=True)
class DatabaseRole:
    """A database role and the role that owns it."""

    name: str
    owner: str  # the role that owns this database role


@dataclass(frozen=True)
class SchemaInfo:
    """A schema with its owner and owner kind (``ROLE`` or ``DATABASE_ROLE``)."""

    name: str
    owner: str
    owner_role_type: str  # ROLE | DATABASE_ROLE


@dataclass
class OwnedType:
    """Distinct owners of a single object type within one schema.

    Attributes:
        object_type: The object class these rows belong to.
        owners: Set of ``(owner_name, owner_role_type)`` pairs seen.
        count: Number of objects of this type in the schema.
    """

    object_type: sql.ObjectType
    owners: set[tuple[str, str]] = field(default_factory=set)
    count: int = 0


@dataclass(frozen=True)
class FutureGrant:
    """A future grant row (``schema`` is None for database-level grants)."""

    privilege: str
    grant_on: str  # token e.g. "DYNAMIC_TABLE"
    grant_to: str  # ROLE | DATABASE_ROLE
    grantee_name: str
    schema: str | None  # None = database-level future grant


@dataclass(frozen=True)
class Grant:
    """A privilege grant on an object (the grantee and its role kind)."""

    privilege: str
    granted_to: str  # ROLE | DATABASE_ROLE | ...
    grantee_name: str


def database_roles(session: Session, clone_db: str, role: str) -> list[DatabaseRole]:
    """Return all database roles in ``clone_db`` with their owners."""
    rows = session.query(f"SHOW DATABASE ROLES IN DATABASE {clone_db}", role=role)
    out: list[DatabaseRole] = []
    for r in rows:
        name = _cval(r, "name")
        owner = _cval(r, "owner") or ""
        if name:
            out.append(DatabaseRole(name=name, owner=owner))
    return out


def schemas_with_owners(session: Session, clone_db: str, role: str) -> list[SchemaInfo]:
    """Return all schemas in ``clone_db`` (excluding INFORMATION_SCHEMA) with owners."""
    rows = session.query(f"SHOW SCHEMAS IN DATABASE {clone_db}", role=role)
    out: list[SchemaInfo] = []
    for r in rows:
        name = _cval(r, "name")
        if not name or name.upper() == _INFORMATION_SCHEMA:
            continue
        out.append(
            SchemaInfo(
                name=name,
                owner=_cval(r, "owner") or "",
                owner_role_type=_cval(r, "owner_role_type") or "ROLE",
            )
        )
    return out


def owned_objects(
    session: Session, clone_db: str, db_role_names: set[str], role: str
) -> dict[str, list[OwnedType]]:
    """Map each schema to its per-object-type ownership summary.

    ``owner_role_type`` is taken from the SHOW output when present, otherwise
    inferred: an owner whose name is a known database role is DATABASE_ROLE,
    else ROLE. Rows belonging to a more specific class (see
    ``ObjectType.exclude_flags``) are dropped.

    Args:
        session: Active session.
        clone_db: Database to introspect.
        db_role_names: Known database-role names, for owner-kind inference.
        role: Role to run the SHOW commands as.

    Returns:
        ``{schema: [OwnedType, ...]}`` with one entry per object type present.
    """
    result: dict[str, list[OwnedType]] = {}
    upper_db_roles = {n.upper() for n in db_role_names}

    for ot in sql.OBJECT_TYPES:
        stmt = f"SHOW {ot.show_keyword} IN DATABASE {clone_db}"
        try:
            rows = session.query(stmt, role=role)
        except Exception as err:  # noqa: BLE001 - some SHOW variants may be unsupported
            logger.warning("Skipping `%s`: %s", stmt, err)
            continue

        per_schema: dict[str, OwnedType] = {}
        for r in rows:
            schema = _cval(r, "schema_name", "schema")
            owner = _cval(r, "owner")
            if not schema or not owner:
                continue  # e.g. functions/procedures with blank owner rows
            # Skip rows that are a more specific object class (e.g. SHOW TABLES
            # also returns dynamic/external tables) — those are handled by their
            # own type, and counting them here would emit a wrong-class transfer.
            if any(_cval(r, flag) == "Y" for flag in ot.exclude_flags):
                continue
            ort = _cval(r, "owner_role_type")
            if not ort:
                ort = "DATABASE_ROLE" if owner.upper() in upper_db_roles else "ROLE"
            bucket = per_schema.setdefault(schema, OwnedType(object_type=ot))
            bucket.owners.add((owner, ort))
            bucket.count += 1

        for schema, bucket in per_schema.items():
            result.setdefault(schema, []).append(bucket)

    return result


def _future_grants(session: Session, stmt: str, schema: str | None, role: str) -> list[FutureGrant]:
    """Run a SHOW FUTURE GRANTS statement and parse rows into FutureGrant."""
    rows = session.query(stmt, role=role)
    out: list[FutureGrant] = []
    for r in rows:
        out.append(
            FutureGrant(
                privilege=_cval(r, "privilege") or "",
                grant_on=_cval(r, "grant_on", "granted_on") or "",
                grant_to=_cval(r, "grant_to", "granted_to") or "",
                grantee_name=_cval(r, "grantee_name") or "",
                schema=schema,
            )
        )
    return out


def future_grants_in_schema(session: Session, clone_db: str, schema: str, role: str) -> list[FutureGrant]:
    """Return future grants defined on one schema."""
    return _future_grants(
        session, f"SHOW FUTURE GRANTS IN SCHEMA {clone_db}.{schema}", schema, role
    )


def future_grants_in_database(session: Session, clone_db: str, role: str) -> list[FutureGrant]:
    """Return database-level future grants on ``clone_db``."""
    return _future_grants(
        session, f"SHOW FUTURE GRANTS IN DATABASE {clone_db}", None, role
    )


def grants_on_database(session: Session, clone_db: str, role: str) -> list[Grant]:
    """Return the privilege grants on the clone database object."""
    return _grants(session, f"SHOW GRANTS ON DATABASE {clone_db}", role)


def _grants(session: Session, stmt: str, role: str) -> list[Grant]:
    """Run a SHOW GRANTS statement and parse rows into Grant."""
    rows = session.query(stmt, role=role)
    out: list[Grant] = []
    for r in rows:
        out.append(
            Grant(
                privilege=_cval(r, "privilege") or "",
                granted_to=_cval(r, "granted_to", "grant_to") or "",
                grantee_name=_cval(r, "grantee_name") or "",
            )
        )
    return out
