with

acl_base as (
    select
        *
    from
        {{ ref('stg_synapse__acl') }}
),

acl_resource_access_base as (
    select
        *
    from
        {{ ref('stg_synapse__acl_resource_access') }}
),

acl_resource_access_type as (
    select
        *
    from
        {{ ref('stg_synapse__acl_resource_access_type') }}
),

access_type_by_principal as (
    select
        acl_id,
        principal_id,
        to_variant(
            array_agg(distinct access_type) within group (order by access_type)
        ) as access_type
    from
        acl_resource_access_base
            inner join
        acl_resource_access_type using (acl_id)
    group by
        acl_id, principal_id
),

merged as (
    select
        *
    from
        acl_base
            inner join
        access_type_by_principal using (acl_id) 
)

select
    acl_id,
    object_id,
    object_type,
    created_on,
    etag,
    principal_id,
    access_type
from 
    merged