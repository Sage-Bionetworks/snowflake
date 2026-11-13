with

snapshot_rows as (
    select
        *
    from
        {{ ref('stg_synapse__teammembersnapshots') }}
),

team_snapshot_timestamps as (
    select distinct
        team_id,
        snapshot_timestamp
    from
        snapshot_rows
),

snapshot_gaps as (
    select
        *,
        lag(snapshot_timestamp) over (
            partition by team_id order by snapshot_timestamp
        ) as previous_timestamp
    from
        team_snapshot_timestamps
),

-- Compare adjacent timestamps to keep captures together across clock boundaries.
snapshot_groups as (
    select
        team_id,
        snapshot_timestamp,
        sum(
            case
                when previous_timestamp is null
                    or datediff('millisecond', previous_timestamp, snapshot_timestamp) >= 60000
                    then 1
                else 0
            end
        ) over (
            partition by team_id order by snapshot_timestamp
            rows between unbounded preceding and current row
        ) as snapshot_seq
    from
        snapshot_gaps
),

-- Carry the group start here so member rows need only one join on team and timestamp.
grouped_timestamps as (
    select
        team_id,
        snapshot_seq,
        snapshot_timestamp,
        min(snapshot_timestamp) over (
            partition by team_id, snapshot_seq
        ) as group_timestamp
    from
        snapshot_groups
),

team_snapshots as (
    select distinct
        team_id,
        snapshot_seq,
        group_timestamp as approximate_event_timestamp
    from
        grouped_timestamps
),

memberships as (
    select
        snapshot_rows.team_id,
        snapshot_rows.user_id,
        grouped_timestamps.snapshot_seq,
        grouped_timestamps.group_timestamp as approximate_event_timestamp,
        max_by(snapshot_rows.is_admin, snapshot_rows.snapshot_timestamp) as is_admin
    from
        snapshot_rows
    inner join
        grouped_timestamps
        on snapshot_rows.team_id = grouped_timestamps.team_id
        and snapshot_rows.snapshot_timestamp = grouped_timestamps.snapshot_timestamp
    group by
        snapshot_rows.team_id, snapshot_rows.user_id,
        grouped_timestamps.snapshot_seq, grouped_timestamps.group_timestamp
),

transitions as (
    select
        *,
        lag(snapshot_seq) over (partition by team_id, user_id order by snapshot_seq) as previous_seq,
        lag(is_admin) over (partition by team_id, user_id order by snapshot_seq) as previous_is_admin,
        lead(snapshot_seq) over (partition by team_id, user_id order by snapshot_seq) as next_seq
    from
        memberships
),

joins as (
    select
        team_id,
        user_id,
        approximate_event_timestamp,
        'join' as event_type,
        is_admin
    from
        transitions
    where
        previous_seq is null
        or previous_seq != snapshot_seq - 1
),

updates as (
    select
        team_id,
        user_id,
        approximate_event_timestamp,
        'update' as event_type,
        is_admin
    from
        transitions
    where
        previous_seq = snapshot_seq - 1
        and is_admin is distinct from previous_is_admin
),

-- A departure is dated at the first team snapshot that no longer includes the user
departures as (
    select
        transitions.team_id,
        transitions.user_id,
        next_snapshot.approximate_event_timestamp,
        'depart' as event_type,
        null::boolean as is_admin
    from
        transitions
    inner join
        team_snapshots as next_snapshot
        on transitions.team_id = next_snapshot.team_id
        and next_snapshot.snapshot_seq = transitions.snapshot_seq + 1
    where
        transitions.next_seq is null
        or transitions.next_seq != transitions.snapshot_seq + 1
)

select * from joins
union all
select * from updates
union all
select * from departures
