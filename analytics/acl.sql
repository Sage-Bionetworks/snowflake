/* From Github Copilot
The script begins with a Common Table Expression (CTE) named
cte that selects the owner_id, created_on, change_timestamp,
and resource_access fields from the aclsnapshots table.
The resource_access field is parsed as JSON and aliased as acl.
The CTE only includes rows where the owner_id is 8016650.

The main SELECT statement then extracts data from this CTE.
It selects the owner_id, created_on, and value fields directly.
It also uses the COALESCE function to select the first non-null
value from a list of possible fields in the value JSON object
for accesstype and principalid. This is done to handle potential
variations in the field names in the JSON object.

The LATERAL FLATTEN function is used to transform the acl JSON
object into a set of rows. The outer=>TRUE argument means that
if acl is an empty array or null, a single row with nulls in the
columns produced by FLATTEN is returned. This is joined with the
CTE to produce the final result set.
*/
with cte as (
    select
        owner_id,
        created_on,
        change_timestamp,
        parse_json(resource_access) as acl
    from
        synapse_data_warehouse.synapse_raw.aclsnapshots
    where
        owner_id = 8016650
)

select
    owner_id, --noqa: RF02
    created_on, --noqa: RF02
    value, --noqa: RF02
    coalesce(
        value:"accesstype"::variant, --noqa: RF02
        value:"accessType"::variant, --noqa: RF02
        value:"accesstype#1"::variant, --noqa: RF02
        value:"accesstype#2"::variant, --noqa: RF02
        value:"accesstype#3"::variant --noqa: RF02
    ) as accesstype,
    coalesce(
        value:"principalId"::number, --noqa: RF02
        value:"principalid"::number, --noqa: RF02
        value:"principalid#1"::number --noqa: RF02
    ) as principalid

from
    cte,
    lateral flatten(acl, outer => TRUE);
