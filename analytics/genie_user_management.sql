USE ROLE PUBLIC;

// List out all GENIE teams
SELECT distinct ID
FROM synapse_data_warehouse.synapse.team_latest
WHERE name ILIKE '%genie%';

// Get all members that are part of GENIE teams
with genie_members AS (
    // Only grab team members that are part of the GENIE teams
    select *
    from synapse_data_warehouse.synapse.teammember_latest
    where TEAM_ID in (
        SELECT distinct ID
        FROM synapse_data_warehouse.synapse.team_latest
        WHERE name ILIKE '%genie%'
    )
)
select * from genie_members
// Join to get the team name
left join (
    select ID, name from synapse_data_warehouse.synapse.team_latest
) team_latest
on genie_members.team_id = team_latest.id;
