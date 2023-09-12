USE ROLE PUBLIC;


// List out all GENIE teams
SELECT distinct ID, name
FROM synapse_data_warehouse.synapse.team_latest
WHERE name ILIKE '%genie%';

// Get all members that are part of GENIE teams


USE ROLE SYSADMIN;

CREATE OR REPLACE VIEW genie.public.genie_members as (
     with genie_mem AS (
        // Only grab team members that are part of the GENIE teams
        select *
        from synapse_data_warehouse.synapse.teammember_latest
        where TEAM_ID in (
            SELECT distinct ID
            FROM synapse_data_warehouse.synapse.team_latest
            WHERE name ILIKE '%genie%'
        )
    )
    select * from genie_mem
    // Join to get the team name
    left join (
        select ID, name from synapse_data_warehouse.synapse.team_latest
    ) team_latest
    on genie_mem.team_id = team_latest.id
);


select name, count(*) as number_of_members
from genie.public.genie_members
group by name;


-- In athena
-- with test as (
--     with genie_mem AS (
--         select *
--         from "teammembersnapshots"
--         where TEAM_ID in (
--             SELECT distinct ID
--             FROM "teamsnapshots"
--             WHERE lower(name) like '%genie%'
--         )
--     )
--     select distinct genie_mem.team_id, genie_mem.member_id, team_latest.name from genie_mem
--     left join (
--         select ID, name from "teamsnapshots"
--     ) team_latest
--     on genie_mem.team_id = team_latest.id
-- )
-- select name, count(*) from test group by name;


USE ROLE SYSADMIN;
USE DATABASE GENIE;
