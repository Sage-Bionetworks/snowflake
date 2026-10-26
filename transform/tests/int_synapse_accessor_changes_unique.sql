select
    data_access_submission_id,
    accessor_id
from {{ ref('int_synapse_accessor_changes') }}
group by
    data_access_submission_id,
    accessor_id
having count(*) > 1
