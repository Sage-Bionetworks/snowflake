"""Pure classification: turn introspection results into a capture plan.

Keys off ``owner_role_type`` rather than role names, so both the
SYNAPSE_DATA_WAREHOUSE (database-role hierarchy) and SAGE (account-role,
schema-first) models — including SAGE's non-conforming schemas — are handled by
the same rules.
"""

from __future__ import annotations

import logging

from . import introspect, sql

logger = logging.getLogger(__name__)


def top_level_database_roles(roles: list[introspect.DatabaseRole]) -> list[str]:
    """Return the database roles owned by an account role (not another DB role).

    Owning and being granted these gives the proxy admin transitive control of the
    whole cloned database-role hierarchy without per-object work.

    Args:
        roles: All database roles discovered in the clone.

    Returns:
        Names of the top-level (account-role-owned) database roles.
    """
    db_role_names = {r.name.upper() for r in roles}
    top: list[str] = []
    for r in roles:
        if r.owner.upper() in db_role_names:
            continue  # child role: covered transitively by capturing its parent
        top.append(r.name)
    return top


def object_transfers_for_schema(
    schema: str,
    owned_types: list[introspect.OwnedType],
    proxy_role: str,
    protected_roles: set[str],
) -> list[str]:
    """Return the GRANT plurals to transfer for one schema.

    Skips object types owned entirely by database roles (captured via the
    database-role hierarchy) or already by the proxy. Warns on a type with mixed
    database-role and account-role ownership, since ``GRANT OWNERSHIP ON ALL``
    would also detach the database-role-owned objects.

    Args:
        schema: Schema being classified.
        owned_types: Per-type ownership summary for the schema.
        proxy_role: The clone proxy admin role.
        protected_roles: Roles whose ownership is left in place.

    Returns:
        Grant plurals (e.g. ``["DYNAMIC TABLES", "TASKS"]``) needing a transfer.
    """
    proxy_upper = proxy_role.upper()
    transfers: list[str] = []
    for owned in owned_types:
        if not owned.object_type.transferable:
            if owned.count:
                logger.info(
                    "  %s.%s: %d %s skipped (ownership not transferable; recreated on deploy)",
                    schema, "", owned.count, owned.object_type.show_keyword,
                )
            continue

        has_db_role = any(ort == "DATABASE_ROLE" for _, ort in owned.owners)
        account_owners = {
            owner for owner, ort in owned.owners
            if ort == "ROLE" and owner.upper() != proxy_upper
            and owner.upper() not in protected_roles
        }
        if not account_owners:
            continue  # all database-role-owned or already proxy/protected -> covered
        if has_db_role:
            logger.warning(
                "  %s: %s has mixed database-role and account-role ownership; "
                "GRANT OWNERSHIP ON ALL will also re-own the database-role objects",
                schema, owned.object_type.grant_plural,
            )
        transfers.append(owned.object_type.grant_plural)
    return transfers


def account_role_owned_schemas(
    schema_infos: list[introspect.SchemaInfo], proxy_role: str
) -> list[str]:
    """Return schemas whose ownership must be transferred to the proxy directly.

    A schema owned by a database role (e.g. SYNAPSE's ``{schema}_ALL_ADMIN``) is
    already controlled via the captured database-role hierarchy, so it is skipped.
    Pure system roles and the proxy itself are also skipped; everything else —
    including ``{schema}_ADMIN`` account roles (SAGE) and the source admin role
    that owns the SCHEMACHANGE schema — is transferred so the proxy can create
    objects there during the deploy.

    Args:
        schema_infos: All schemas in the clone with their owners.
        proxy_role: The clone proxy admin role.

    Returns:
        Names of the schemas to transfer to the proxy.
    """
    proxy_upper = proxy_role.upper()
    out: list[str] = []
    for s in schema_infos:
        if s.owner_role_type.upper() == "DATABASE_ROLE":
            continue
        if s.owner.upper() in sql.SYSTEM_ROLES or s.owner.upper() == proxy_upper:
            continue
        out.append(s.name)
    return out


def account_role_future_owners(future_grants: list[introspect.FutureGrant]) -> list[introspect.FutureGrant]:
    """Return future OWNERSHIP grants currently held by an account role.

    Future grants held by database roles are left intact so newly-deployed
    objects continue to land in the mirrored hierarchy the proxy controls.

    Args:
        future_grants: Future grants to filter.

    Returns:
        The subset that are OWNERSHIP grants held by an account role (to re-point).
    """
    out = []
    for fg in future_grants:
        if fg.privilege.upper() != "OWNERSHIP":
            continue
        if fg.grant_to.upper() == "DATABASE_ROLE":
            continue
        out.append(fg)
    return out
