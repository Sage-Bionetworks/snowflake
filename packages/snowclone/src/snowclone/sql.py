"""Object-type metadata, SQL-string builders, and the clone-name safety guard.

Every mutating statement targets only the clone database. :func:`assert_clone`
is called by each builder so a bug can never emit DDL against the source.
"""

from __future__ import annotations

from dataclasses import dataclass

# Account roles that must never have their clone access revoked, and whose
# database-role / object ownership we never disturb. Extended at runtime with
# the original {DATABASE}_ADMIN, the {CLONE}_PROXY_ADMIN, and the developer role.
SYSTEM_ROLES = frozenset(
    {"ACCOUNTADMIN", "SECURITYADMIN", "SYSADMIN", "USERADMIN", "PUBLIC"}
)


@dataclass(frozen=True)
class ObjectType:
    """A schema-scoped Snowflake object class.

    Attributes:
        label: Singular form; also the SHOW-FUTURE-GRANTS token once underscores
            are normalised (e.g. ``DYNAMIC TABLE`` <-> ``DYNAMIC_TABLE``).
        show_keyword: Plural used in ``SHOW <kw> IN DATABASE`` introspection.
        grant_plural: Plural used in ``GRANT OWNERSHIP ON ALL <plural> ...``.
        transferable: Whether ``GRANT OWNERSHIP ON ALL`` is supported. Streamlit
            objects cannot have ownership transferred and are recreated by the
            deploy step instead.
        exclude_flags: SHOW ``is_*`` columns that mark a row as a *more specific*
            object class handled by its own type. ``SHOW TABLES`` also returns
            dynamic/external/iceberg/event tables and ``SHOW VIEWS`` returns
            materialized views; counting those under TABLE/VIEW would emit a
            wrong-class (and hierarchy-detaching) transfer.
    """

    label: str
    show_keyword: str
    grant_plural: str
    transferable: bool = True
    exclude_flags: tuple[str, ...] = ()


# Order is not significant; this is the universe of types we introspect and,
# where account-role-owned, transfer to the proxy admin.
OBJECT_TYPES: tuple[ObjectType, ...] = (
    ObjectType(
        "TABLE", "TABLES", "TABLES",
        exclude_flags=("is_dynamic", "is_external", "is_iceberg", "is_event", "is_hybrid"),
    ),
    ObjectType("EXTERNAL TABLE", "EXTERNAL TABLES", "EXTERNAL TABLES"),
    ObjectType("VIEW", "VIEWS", "VIEWS", exclude_flags=("is_materialized",)),
    ObjectType("MATERIALIZED VIEW", "MATERIALIZED VIEWS", "MATERIALIZED VIEWS"),
    ObjectType("DYNAMIC TABLE", "DYNAMIC TABLES", "DYNAMIC TABLES"),
    ObjectType("STAGE", "STAGES", "STAGES"),
    ObjectType("STREAM", "STREAMS", "STREAMS"),
    ObjectType("TASK", "TASKS", "TASKS"),
    ObjectType("PIPE", "PIPES", "PIPES"),
    ObjectType("FILE FORMAT", "FILE FORMATS", "FILE FORMATS"),
    ObjectType("SEQUENCE", "SEQUENCES", "SEQUENCES"),
    ObjectType("FUNCTION", "USER FUNCTIONS", "FUNCTIONS"),
    ObjectType("PROCEDURE", "PROCEDURES", "PROCEDURES"),
    ObjectType("STREAMLIT", "STREAMLITS", "STREAMLITS", transferable=False),
)

# Map a SHOW-FUTURE-GRANTS ``grant_on`` token (e.g. "DYNAMIC_TABLE") to its
# GRANT plural ("DYNAMIC TABLES"). Tokens use underscores for multiword types.
_GRANT_PLURAL_BY_TOKEN = {
    ot.label.replace(" ", "_"): ot.grant_plural for ot in OBJECT_TYPES
}


def future_grant_plural(grant_on_token: str) -> str | None:
    """Return the GRANT plural for a future-grant ``grant_on`` token.

    Args:
        grant_on_token: A ``SHOW FUTURE GRANTS`` object token (e.g. ``DYNAMIC_TABLE``).

    Returns:
        The plural form (e.g. ``DYNAMIC TABLES``), or None if the type is unknown.
    """
    return _GRANT_PLURAL_BY_TOKEN.get(grant_on_token.upper())


def assert_clone(clone_db: str, target: str) -> None:
    """Refuse to emit DDL whose target is not inside the clone database.

    Args:
        clone_db: The clone database name (the only legal target prefix).
        target: The fully-qualified object the statement would act on.

    Raises:
        RuntimeError: If ``target`` is not within ``clone_db``.
    """
    if not target.upper().startswith(clone_db.upper()):
        raise RuntimeError(
            f"Refusing to operate on '{target}': not within clone '{clone_db}'"
        )


# --------------------------------------------------------------------------- #
# Statement builders. Each returns a single SQL string.
# --------------------------------------------------------------------------- #


def clone_database(clone_db: str, source_db: str) -> str:
    """Return SQL to zero-copy clone ``source_db`` into ``clone_db``."""
    return f"CREATE OR REPLACE DATABASE {clone_db} CLONE {source_db}"


def create_proxy_role(proxy_role: str) -> str:
    """Return SQL to (re)create the proxy admin account role."""
    return f"CREATE OR REPLACE ROLE {proxy_role}"


def grant_role_to_role(role: str, to_role: str) -> str:
    """Return SQL to grant ``role`` to ``to_role``."""
    return f"GRANT ROLE {role} TO ROLE {to_role}"


def take_database_role_ownership(clone_db: str, db_role: str, proxy_role: str) -> str:
    """Return SQL transferring ownership of a clone database role to the proxy."""
    target = f"{clone_db}.{db_role}"
    assert_clone(clone_db, target)
    return (
        f"GRANT OWNERSHIP ON DATABASE ROLE {target} "
        f"TO ROLE {proxy_role} REVOKE CURRENT GRANTS"
    )


def grant_database_role(clone_db: str, db_role: str, proxy_role: str) -> str:
    """Return SQL granting a clone database role to the proxy (for inheritance)."""
    target = f"{clone_db}.{db_role}"
    assert_clone(clone_db, target)
    return f"GRANT DATABASE ROLE {target} TO ROLE {proxy_role}"


def transfer_schema_ownership(clone_db: str, schema: str, proxy_role: str) -> str:
    """Return SQL transferring ownership of a clone schema to the proxy."""
    target = f"{clone_db}.{schema}"
    assert_clone(clone_db, target)
    # COPY CURRENT GRANTS for the same reason as objects: preserve the source's
    # grant structure (inert post Phase 2). Needed for the account-role schema
    # model (SAGE), where the schema itself — not just its objects — is owned by a
    # {schema}_ADMIN account role; without this the proxy could not create objects
    # in the schema (deploy would fail). Database-role-owned schemas (SYNAPSE) are
    # captured via the database role in Phase 5 and never reach here.
    return (
        f"GRANT OWNERSHIP ON SCHEMA {target} "
        f"TO ROLE {proxy_role} COPY CURRENT GRANTS"
    )


def transfer_all_objects(
    clone_db: str, schema: str, grant_plural: str, proxy_role: str
) -> str:
    """Return SQL transferring all objects of one type in a schema to the proxy."""
    target = f"{clone_db}.{schema}"
    assert_clone(clone_db, target)
    # COPY (not REVOKE) CURRENT GRANTS: preserve the source's per-object grant
    # structure so the clone mirrors prod. These copied grants are inert because
    # Phase 2 already revoked database/schema USAGE from every non-allowlisted
    # account role, so they cannot traverse into the clone to exercise them.
    return (
        f"GRANT OWNERSHIP ON ALL {grant_plural} IN SCHEMA {target} "
        f"TO ROLE {proxy_role} COPY CURRENT GRANTS"
    )


def revoke_future_ownership(
    clone_db: str, schema: str, grant_plural: str, grantee_clause: str
) -> str:
    """Return SQL revoking a schema-level future-ownership grant from ``grantee_clause``."""
    target = f"{clone_db}.{schema}"
    assert_clone(clone_db, target)
    return (
        f"REVOKE OWNERSHIP ON FUTURE {grant_plural} IN SCHEMA {target} "
        f"FROM {grantee_clause}"
    )


def grant_future_ownership(
    clone_db: str, schema: str, grant_plural: str, proxy_role: str
) -> str:
    """Return SQL granting a schema-level future-ownership grant to the proxy."""
    target = f"{clone_db}.{schema}"
    assert_clone(clone_db, target)
    return (
        f"GRANT OWNERSHIP ON FUTURE {grant_plural} IN SCHEMA {target} "
        f"TO ROLE {proxy_role}"
    )


def revoke_future_ownership_in_db(
    clone_db: str, grant_plural: str, grantee_clause: str
) -> str:
    """Return SQL revoking a database-level future-ownership grant from ``grantee_clause``."""
    assert_clone(clone_db, clone_db)
    return (
        f"REVOKE OWNERSHIP ON FUTURE {grant_plural} IN DATABASE {clone_db} "
        f"FROM {grantee_clause}"
    )


def grant_future_ownership_in_db(
    clone_db: str, grant_plural: str, proxy_role: str
) -> str:
    """Return SQL granting a database-level future-ownership grant to the proxy."""
    assert_clone(clone_db, clone_db)
    return (
        f"GRANT OWNERSHIP ON FUTURE {grant_plural} IN DATABASE {clone_db} "
        f"TO ROLE {proxy_role}"
    )


def grant_database_privileges(clone_db: str, developer_role: str) -> str:
    """Return SQL granting the developer role non-ownership database privileges."""
    assert_clone(clone_db, clone_db)
    return (
        f"GRANT MODIFY, MONITOR, CREATE SCHEMA, CREATE DATABASE ROLE "
        f"ON DATABASE {clone_db} TO ROLE {developer_role}"
    )


def revoke_all_on_database(clone_db: str, role: str) -> str:
    """Return SQL revoking all (non-ownership) privileges on the clone DB from ``role``."""
    assert_clone(clone_db, clone_db)
    return f"REVOKE ALL PRIVILEGES ON DATABASE {clone_db} FROM ROLE {role}"


def drop_database(clone_db: str) -> str:
    """Return SQL to drop the clone database if it exists."""
    return f"DROP DATABASE IF EXISTS {clone_db}"


def drop_role(role: str) -> str:
    """Return SQL to drop an account role if it exists."""
    return f"DROP ROLE IF EXISTS {role}"
