select
    data_access_submission_id,
    principal_id,
    access_type
from {{ ref('int_synapse_accessor_changes') }}
group by
    data_access_submission_id,
    principal_id,
    access_type
having count(*) > 1
