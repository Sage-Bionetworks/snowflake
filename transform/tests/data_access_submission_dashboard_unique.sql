select
    data_access_submission_id
from {{ ref('data_access_submission_dashboard') }}
group by
    data_access_submission_id
having count(*) > 1
