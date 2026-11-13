select
    team_id,
    user_id,
    approximate_event_timestamp,
    event_type,
    is_admin
from
    dynamic_table_refresh_boundary({{ ref('int_synapse_teammember_event') }})
