-- Snowflake does not enforce primary keys on dynamic tables.
select
    team_id,
    user_id,
    approximate_event_timestamp
from {{ ref('teammember_event') }}
group by team_id, user_id, approximate_event_timestamp
having count(*) > 1

union all

select
    team_id,
    user_id,
    approximate_event_timestamp
from {{ ref('teammember_event') }}
where event_type = 'depart' and is_admin is not null
