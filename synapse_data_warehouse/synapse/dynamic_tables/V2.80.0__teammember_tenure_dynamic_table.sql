USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE teammember_tenure (
    TEAM_ID COMMENT 'The unique identifier of the team.',
    MEMBER_ID COMMENT 'The unique identifier of the Synapse user who was a member of the team.',
    START_TS COMMENT 'Approximate time the user joined the team. NULL if the user was already a member in the earliest snapshot of the team, i.e. the join date is unknown.',
    END_TS COMMENT 'Time of the first team snapshot that no longer included the user, an upper bound on when they left. NULL if the user is still a member.'
)
    TARGET_LAG = '1 day'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'One row per continuous membership period of a user in a team, derived from team member snapshots. A user who leaves and rejoins has multiple rows. Currently limited to team 273957 (Sage employees). Snapshots do not capture removals, so END_TS is only accurate to the snapshot interval.'
AS
WITH team_snapshots AS (
    SELECT
        team_id,
        snapshot_date,
        MIN(snapshot_timestamp) AS snapshot_ts
    FROM {{database_name}}.synapse_raw.teammembersnapshots --noqa: TMP
    WHERE team_id = 273957
    GROUP BY team_id, snapshot_date
),

team_snapshot_seq AS (
    SELECT
        team_id,
        snapshot_date,
        snapshot_ts,
        DENSE_RANK() OVER (PARTITION BY team_id ORDER BY snapshot_date) AS seq
    FROM team_snapshots
),

presence AS (
    SELECT
        s.team_id,
        s.member_id,
        q.seq,
        q.snapshot_ts,
        MIN(s.change_timestamp) AS change_ts
    FROM {{database_name}}.synapse_raw.teammembersnapshots AS s --noqa: TMP
    INNER JOIN team_snapshot_seq AS q
        ON s.team_id = q.team_id AND s.snapshot_date = q.snapshot_date
    WHERE s.team_id = 273957
    GROUP BY s.team_id, s.member_id, q.seq, q.snapshot_ts
),

-- Consecutive snapshot numbers share the same island_id (gaps-and-islands)
islands AS (
    SELECT
        *,
        seq - ROW_NUMBER() OVER (PARTITION BY team_id, member_id ORDER BY seq) AS island_id
    FROM presence
),

periods AS (
    SELECT
        team_id,
        member_id,
        MIN(seq) AS first_seq,
        MAX(seq) AS last_seq,
        MIN(snapshot_ts) AS first_snapshot_ts,
        MIN(change_ts) AS first_change_ts
    FROM islands
    GROUP BY team_id, member_id, island_id
)

SELECT
    p.team_id,
    p.member_id,
    -- A join triggers a snapshot, so the earliest change timestamp approximates the join time
    IFF(p.first_seq = 1, NULL, LEAST(p.first_change_ts, p.first_snapshot_ts)) AS start_ts,
    n.snapshot_ts AS end_ts
FROM periods AS p
LEFT JOIN team_snapshot_seq AS n
    ON p.team_id = n.team_id AND n.seq = p.last_seq + 1;
