with

-- Prototype scope: only the Sage employees team
snapshot_rows as (
    select
        *
    from
        {{ ref('stg_synapse__teammembersnapshots') }}
    where
        team_id = 273957
),

-- Rows of one snapshot differ by milliseconds, so a team snapshot is identified by its date
team_snapshots as (
    select
        team_id,
        snapshot_date,
        min(snapshot_timestamp) as snapshot_timestamp,
        row_number() over (partition by team_id order by snapshot_date) as snapshot_seq
    from
        snapshot_rows
    group by
        team_id, snapshot_date
),

memberships as (
    select
        snapshot_rows.team_id,
        snapshot_rows.user_id,
        team_snapshots.snapshot_seq,
        team_snapshots.snapshot_timestamp,
        max_by(snapshot_rows.is_admin, snapshot_rows.snapshot_timestamp) as is_admin
    from
        snapshot_rows
    inner join
        team_snapshots
        on snapshot_rows.team_id = team_snapshots.team_id
        and snapshot_rows.snapshot_date = team_snapshots.snapshot_date
    group by
        snapshot_rows.team_id, snapshot_rows.user_id,
        team_snapshots.snapshot_seq, team_snapshots.snapshot_timestamp
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
        snapshot_timestamp,
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
        snapshot_timestamp,
        'update' as event_type,
        is_admin
    from
        transitions
    where
        previous_seq = snapshot_seq - 1
        and is_admin != previous_is_admin
),

-- A leave is dated at the first team snapshot that no longer includes the user
leaves as (
    select
        transitions.team_id,
        transitions.user_id,
        next_snapshot.snapshot_timestamp,
        'leave' as event_type,
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
select * from leaves
