USE SCHEMA {{ database_name }}.synapse; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE FUNCTION list_sage_user_tenure()
RETURNS TABLE ("USER_ID" NUMBER, "START_TS" TIMESTAMP_NTZ, "END_TS" TIMESTAMP_NTZ)
LANGUAGE SQL
COMMENT = 'Returns one row per Sage employee membership period with `user_id`, `start_ts` (NULL if unknown) and `end_ts` (NULL if current). Use to exclude employee activity as of the event time.'
AS
$$
SELECT
    member_id AS user_id,
    start_ts,
    end_ts
FROM
    {{ database_name }}.synapse.teammember_tenure
WHERE
    team_id = 273957
$$;
