USE SCHEMA {{ database_name }}.synapse; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE FUNCTION list_sage_users()
RETURNS TABLE ("USER_ID" NUMBER)
LANGUAGE SQL
COMMENT = 'Returns a table with column `user_id` containing the Synapse user IDs of current Sage employees'
AS
$$
SELECT
    member_id as user_id
FROM
    {{ database_name }}.synapse.teammember_latest
WHERE
    team_id = 273957
$$;
