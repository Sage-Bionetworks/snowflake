USE ROLE SYSADMIN;

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


USE DATABASE GENIE;

SELECT
    clin13_1.SAMPLE_ID as SAMPLE_ID,
    (CASE WHEN clin1.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_1_0_1,
    (CASE WHEN clin2.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_2_0_1,
    (CASE WHEN clin3.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_3_0_0,
    (CASE WHEN clin4.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_4_0,
    (CASE WHEN clin4.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_4_0,
    (CASE WHEN clin4_1.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_4_1,
    (CASE WHEN clin5.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_5_0,
    (CASE WHEN clin6.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_6,
    (CASE WHEN clin6_1.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_6_1,
    (CASE WHEN clin6_2.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_6_2,
    (CASE WHEN clin7.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_7,
    (CASE WHEN clin8.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_8,
    (CASE WHEN clin8_1.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_8_1,
    (CASE WHEN clin9.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_9,
    (CASE WHEN clin9_1.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_9_1,
    (CASE WHEN clin10.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_10,
    (CASE WHEN clin10_1.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_10_1,
    (CASE WHEN clin11.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_11,
    (CASE WHEN clin11_1.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_11_1,
    (CASE WHEN clin12.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_12,
    (CASE WHEN clin12_1.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_12_1,
    (CASE WHEN clin13.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_13,
    (CASE WHEN clin13_1.SAMPLE_ID IS NULL THEN false ELSE true END) AS public_13_1
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