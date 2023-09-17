USE ROLE SYSADMIN;
USE DATABASE GENIE;
USE WAREHOUSE COMPUTE_ORG;

// GENIE user management
// List out all GENIE teams
SELECT distinct ID, name
FROM synapse_data_warehouse.synapse.team_latest
WHERE name ILIKE '%genie%';

// Get all members that are part of GENIE teams

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

SELECT
    clin13_1.SAMPLE_ID as SAMPLE_ID,
    COALESCE(clin1.SAMPLE_ID IS NOT NULL, false) AS public_1_0_1,
    COALESCE(clin2.SAMPLE_ID IS NOT NULL, false) AS public_2_0_1,
    COALESCE(clin3.SAMPLE_ID IS NOT NULL, false) AS public_3_0_0,
    COALESCE(clin4.SAMPLE_ID IS NOT NULL, false) AS public_4_0,
    COALESCE(clin4_1.SAMPLE_ID IS NOT NULL, false) AS public_4_1,
    COALESCE(clin5.SAMPLE_ID IS NOT NULL, false) AS public_5_0,
    COALESCE(clin6.SAMPLE_ID IS NOT NULL, false) AS public_6,
    COALESCE(clin6_1.SAMPLE_ID IS NOT NULL, false) AS public_6_1,
    COALESCE(clin6_2.SAMPLE_ID IS NOT NULL, false) AS public_6_2,
    COALESCE(clin7.SAMPLE_ID IS NOT NULL, false) AS public_7,
    COALESCE(clin8.SAMPLE_ID IS NOT NULL OR clin8_1.SAMPLE_ID IS NOT NULL, false) AS public_8,
    COALESCE(clin9.SAMPLE_ID IS NOT NULL OR clin9_1.SAMPLE_ID IS NOT NULL, false) AS public_9,
    COALESCE(clin10.SAMPLE_ID IS NOT NULL OR clin10_1.SAMPLE_ID IS NOT NULL, false) AS public_10,
    COALESCE(clin11.SAMPLE_ID IS NOT NULL OR clin11_1.SAMPLE_ID IS NOT NULL, false) AS public_11,
    COALESCE(clin12.SAMPLE_ID IS NOT NULL OR clin12_1.SAMPLE_ID IS NOT NULL, false) AS public_12,
    COALESCE(clin13.SAMPLE_ID IS NOT NULL, false) AS public_13
FROM GENIE.PUBLIC_01_0_1.CLINICAL AS clin1
    FULL OUTER JOIN GENIE.PUBLIC_02_0_1.CLINICAL_SAMPLE AS clin2
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_03_0_0.CLINICAL_SAMPLE AS clin3
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_04_0.CLINICAL_SAMPLE AS clin4
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_04_1.CLINICAL_SAMPLE AS clin4_1
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_05_0.CLINICAL_SAMPLE AS clin5
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_06_0.CLINICAL_SAMPLE AS clin6
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_06_1.CLINICAL_SAMPLE AS clin6_1
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_06_2.CLINICAL_SAMPLE AS clin6_2
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_07_0.CLINICAL_SAMPLE AS clin7
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_08_0.CLINICAL_SAMPLE AS clin8
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_08_1.CLINICAL_SAMPLE AS clin8_1
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_09_0.CLINICAL_SAMPLE AS clin9
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_09_1.CLINICAL_SAMPLE AS clin9_1
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_10_0.CLINICAL_SAMPLE AS clin10
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_10_1.CLINICAL_SAMPLE AS clin10_1
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_11_0.CLINICAL_SAMPLE AS clin11
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_11_1.CLINICAL_SAMPLE AS clin11_1
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_12_0.CLINICAL_SAMPLE AS clin12
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_12_1.CLINICAL_SAMPLE AS clin12_1
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_13_0.CLINICAL_SAMPLE AS clin13
        USING (SAMPLE_ID)
    FULL OUTER JOIN GENIE.PUBLIC_13_1.CLINICAL_SAMPLE AS clin13_1
        USING (SAMPLE_ID)
;
