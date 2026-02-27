-- This dynamic table contains all data access submissions and their associated state.
select
    *
from
    {{ ref('int_synapse_data_access_submission') }}