"""The ordered provisioning phases. Each runs as the appropriate system role.

Executing roles:
  * clone create/drop            -> {DATABASE}_ADMIN
  * role create/drop             -> USERADMIN
  * all grants / ownership / revokes -> SECURITYADMIN (holds MANAGE GRANTS)
  * deploy (schemachange)        -> {developer_role}
"""

from __future__ import annotations

import logging
import os
import subprocess
from dataclasses import dataclass

from . import classify, introspect, sql
from .connection import Session

logger = logging.getLogger(__name__)

USERADMIN = "USERADMIN"
SECURITYADMIN = "SECURITYADMIN"
# Standardized target-database env var read by every schemachange config
# (synapse_data_warehouse/ and sage/). The deploy phase sets it to the clone so
# schemachange targets the clone — one source of truth, no per-database mapping.
DEPLOY_DB_ENV = "SNOWFLAKE_DEPLOY_DATABASE"
# Read-only SHOW introspection runs as SYSADMIN. Every custom account role is
# inherited by SYSADMIN (see admin/AGENTS.md), so it can see every schema,
# object, and database role in the clone regardless of owner — without the
# account-level reach of ACCOUNTADMIN. (SECURITYADMIN's MANAGE GRANTS covers the
# mutations but not USAGE-style visibility on objects owned by other roles.)
INTROSPECT = "SYSADMIN"


@dataclass
class Context:
    """Resolved inputs and roles shared across all provisioning phases.

    Attributes:
        session: Active Snowflake session.
        source_db: Database being cloned.
        clone_db: Sanitized clone database name.
        admin_role: ``{DATABASE}_ADMIN``; owns and creates the clone.
        proxy_role: ``{CLONE}_PROXY_ADMIN``; the single role that ends up
            controlling the clone.
        developer_role: Account role the clone is provisioned for.
        connection_name: ``snow`` connection name (passed to schemachange).
        deploy_folder: schemachange root/config folder; None skips the deploy.
    """

    session: Session
    source_db: str
    clone_db: str
    admin_role: str
    proxy_role: str
    developer_role: str
    connection_name: str
    deploy_folder: str | None = None

    @property
    def protected_roles(self) -> set[str]:
        """Roles whose object/schema OWNERSHIP we never seize (Phase 6).

        Distinct from ``revoke_allowlist``: ownership cannot be inherited, so
        objects owned by the admin, developer, or a system role are left in place
        rather than transferred to the proxy.
        """
        return sql.SYSTEM_ROLES | {
            self.admin_role.upper(),
            self.proxy_role.upper(),
            self.developer_role.upper(),
        }

    @property
    def revoke_allowlist(self) -> set[str]:
        """Roles whose existing DB/schema GRANTS are NOT revoked in Phase 2.

        Only the source admin (which owns the clone database) and the proxy. The
        developer role re-derives access by inheriting the proxy, and the system
        roles (``SYSADMIN`` in particular) in turn inherit the developer — so none
        of them need to retain a direct grant on the clone.
        """
        return {self.admin_role.upper(), self.proxy_role.upper()}

    @property
    def introspect_db(self) -> str:
        """Database to run read-only SHOW queries against.

        In dry-run the clone is never created, so introspect the source instead —
        the clone is a byte-for-byte copy of it, so the discovered roles, objects,
        and grants (hence the previewed plan) are identical. Emitted SQL still
        targets ``clone_db``.
        """
        return self.source_db if self.session.dry_run else self.clone_db


# --------------------------------------------------------------------------- #

def clone(ctx: Context) -> None:
    """Phase 1: zero-copy clone the source database as the admin role."""
    logger.info("Phase 1: cloning %s -> %s", ctx.source_db, ctx.clone_db)
    ctx.session.execute(sql.clone_database(ctx.clone_db, ctx.source_db), role=ctx.admin_role)


def create_proxy(ctx: Context) -> None:
    """Phase 3: create the clone's proxy admin account role."""
    logger.info("Phase 3: creating proxy admin role %s", ctx.proxy_role)
    ctx.session.execute(sql.create_proxy_role(ctx.proxy_role), role=USERADMIN)


def grant_proxy_to_developer(ctx: Context) -> None:
    """Phase 4: grant the proxy role to the developer role."""
    logger.info("Phase 4: granting %s to %s", ctx.proxy_role, ctx.developer_role)
    ctx.session.execute(
        sql.grant_role_to_role(ctx.proxy_role, ctx.developer_role), role=SECURITYADMIN
    )


def capture_database_roles(ctx: Context) -> set[str]:
    """Phase 5: take ownership of and be granted every top-level database role.

    Returns:
        The names of all database roles in the clone (for ownership inference in
        :func:`transfer_object_ownership`).
    """
    roles = introspect.database_roles(ctx.session, ctx.introspect_db, role=INTROSPECT)
    db_role_names = {r.name for r in roles}
    top_level = classify.top_level_database_roles(roles)
    logger.info(
        "Phase 5: capturing %d top-level database role(s) of %d total",
        len(top_level), len(roles),
    )
    for name in top_level:
        ctx.session.execute(
            sql.take_database_role_ownership(ctx.clone_db, name, ctx.proxy_role),
            role=SECURITYADMIN,
        )
        ctx.session.execute(
            sql.grant_database_role(ctx.clone_db, name, ctx.proxy_role),
            role=SECURITYADMIN,
        )
    return db_role_names


def transfer_object_ownership(
    ctx: Context, db_role_names: set[str], schema_infos: list[introspect.SchemaInfo]
) -> None:
    """Phase 6: transfer account-role-owned schemas and objects to the proxy.

    Schema ownership is transferred first (the container), then per-(schema, type)
    object ownership. Database-role-owned schemas/objects are skipped — they are
    controlled via the captured database-role hierarchy (Phase 5).

    Args:
        ctx: Provisioning context.
        db_role_names: Database-role names from :func:`capture_database_roles`.
        schema_infos: All schemas in the clone with their owners.
    """
    schemas_to_take = classify.account_role_owned_schemas(schema_infos, ctx.proxy_role)
    owned = introspect.owned_objects(
        ctx.session, ctx.introspect_db, db_role_names, role=INTROSPECT
    )
    logger.info(
        "Phase 6: transferring %d account-role-owned schema(s) and objects in %d schema(s)",
        len(schemas_to_take), len(owned),
    )
    for schema in schemas_to_take:
        ctx.session.execute(
            sql.transfer_schema_ownership(ctx.clone_db, schema, ctx.proxy_role),
            role=SECURITYADMIN,
        )
    for schema, owned_types in sorted(owned.items()):
        plurals = classify.object_transfers_for_schema(
            schema, owned_types, ctx.proxy_role, ctx.protected_roles
        )
        for grant_plural in plurals:
            ctx.session.execute(
                sql.transfer_all_objects(ctx.clone_db, schema, grant_plural, ctx.proxy_role),
                role=SECURITYADMIN,
            )


def repoint_future_grants(ctx: Context, schemas: list[str]) -> None:
    """Phase 7: re-point account-role-held future OWNERSHIP grants to the proxy.

    Future grants held by database roles are left intact (hierarchy preserved).
    """
    logger.info("Phase 7: re-pointing account-role future ownership grants")

    def _repoint(fgs: list[introspect.FutureGrant], schema: str | None) -> None:
        for fg in classify.account_role_future_owners(fgs):
            plural = sql.future_grant_plural(fg.grant_on)
            if plural is None:
                logger.warning("  unknown future-grant object type '%s'; skipping", fg.grant_on)
                continue
            grantee_clause = f"ROLE {fg.grantee_name}"
            if schema is None:
                revoke = sql.revoke_future_ownership_in_db(ctx.clone_db, plural, grantee_clause)
                grant = sql.grant_future_ownership_in_db(ctx.clone_db, plural, ctx.proxy_role)
            else:
                revoke = sql.revoke_future_ownership(ctx.clone_db, schema, plural, grantee_clause)
                grant = sql.grant_future_ownership(ctx.clone_db, schema, plural, ctx.proxy_role)
            ctx.session.execute(revoke, role=SECURITYADMIN)
            ctx.session.execute(grant, role=SECURITYADMIN)

    _repoint(introspect.future_grants_in_database(ctx.session, ctx.introspect_db, INTROSPECT), None)
    for schema in schemas:
        _repoint(
            introspect.future_grants_in_schema(ctx.session, ctx.introspect_db, schema, INTROSPECT),
            schema,
        )


def grant_database_privileges(ctx: Context) -> None:
    """Phase 8: grant the developer role non-ownership database privileges."""
    logger.info("Phase 8: granting database-level privileges to %s", ctx.developer_role)
    ctx.session.execute(
        sql.grant_database_privileges(ctx.clone_db, ctx.developer_role), role=SECURITYADMIN
    )


def revoke_other_roles(ctx: Context) -> None:
    """Phase 2: revoke DATABASE-level access from non-allowlisted account roles.

    Runs immediately after the clone so the environment is isolated before the
    proxy's control is layered on. Revoking ``ALL PRIVILEGES`` on the *database*
    strips USAGE, so these roles can no longer traverse into the clone to use any
    schema or object — which neuters them without disturbing the finer-grained
    schema/object grants. Those grants are deliberately retained (here, and via
    ``COPY CURRENT GRANTS`` in Phases 5–6) so the clone mirrors the source's grant
    structure; with no database USAGE they are inert. ``REVOKE ALL PRIVILEGES``
    excludes OWNERSHIP, so nothing is orphaned.
    """
    logger.info("Phase 2: revoking database-level access from non-allowlisted roles")
    allowlist = ctx.revoke_allowlist
    grantees = set()
    for g in introspect.grants_on_database(ctx.session, ctx.introspect_db, INTROSPECT):
        if g.granted_to.upper() != "ROLE":  # leave database roles alone
            continue
        if g.privilege.upper() == "OWNERSHIP":  # not revocable via ALL PRIVILEGES
            continue
        if g.grantee_name.upper() in allowlist:
            continue
        grantees.add(g.grantee_name)
    for role in sorted(grantees):
        ctx.session.execute(
            sql.revoke_all_on_database(ctx.clone_db, role), role=SECURITYADMIN, ignore_errors=True
        )


def deploy(ctx: Context) -> None:
    """Phase 9: run schemachange against the clone as the developer role.

    The clone is targeted purely via the standardized ``SNOWFLAKE_DEPLOY_DATABASE``
    env var, which the schemachange config reads for the database, change-history
    table, and ``database_name`` template var — so no per-database wiring is needed
    here beyond the deploy folder.
    """
    if not ctx.deploy_folder:
        logger.info("Phase 9: no --deploy-folder given; skipping deploy")
        return
    logger.info(
        "Phase 9: deploying %s to %s as %s",
        ctx.deploy_folder, ctx.clone_db, ctx.developer_role,
    )
    env = {**os.environ, DEPLOY_DB_ENV: ctx.clone_db}
    cmd = [
        "schemachange",
        "--connection-name", ctx.connection_name,
        "--root-folder", ctx.deploy_folder,
        "--config-folder", ctx.deploy_folder,
        "--snowflake-role", ctx.developer_role,
    ]
    if ctx.session.dry_run:
        logger.info("[DRY-RUN] would run: %s (%s=%s)", " ".join(cmd), DEPLOY_DB_ENV, ctx.clone_db)
        return
    subprocess.run(cmd, env=env, check=True)
