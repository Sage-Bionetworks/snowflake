with

source as (
    select * from {{ source('synapse_raw', 'teammembersnapshots') }}
),

staging as (
    select
        team_id,
        member_id as user_id,
        is_admin,
        snapshot_date,
        snapshot_timestamp
    from
        source
    -- The raw table can contain the same row more than once
    qualify row_number() over (
        partition by team_id, member_id, snapshot_timestamp
        order by change_timestamp desc
    ) = 1
)

select * from staging
