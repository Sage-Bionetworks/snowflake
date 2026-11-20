select
    access_requirement_id,
    access_requirement_version
from {{ ref('accessrequirement_event') }}
group by
    access_requirement_id,
    access_requirement_version
having count(*) > 1
