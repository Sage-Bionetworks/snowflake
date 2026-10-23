select
    data_access_submission_id,
    accessor_id,
    accessor_change_type
from {{ ref('int_synapse_accessor_changes') }}
group by
    data_access_submission_id,
    accessor_id,
    accessor_change_type
having count(*) > 1
