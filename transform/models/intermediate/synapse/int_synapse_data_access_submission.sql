-- This table contains data access submissions and their associated state.
--
-- A data access submission is a copy of a data access request.
-- When a data acccess request is made by a user, an initial
-- data access submission is created. If the user decides to modify
-- their data access request (e.g., because it was rejected), a new
-- data access submission is created.
--
-- A data access request is always tied to a specific access requirement,
-- but not necessarily to the same version of that access requirement.
-- Although a data access request is made by a single user, it may be
-- requesting access for multiple users.

with 

data_access_submission_base as (
    select
        *
    from
        {{ ref('stg_synapse__data_access_submission') }}
),

data_access_submission_status as (
    select
        data_access_submission_id,
        state_modified_by,
        state_modified_on,
        state,
        state_reason
    from
        {{ ref('stg_synapse__data_access_submission_status') }}
),

-- We include the table here for completeness, although
-- it seems to be entirely redundant with information
-- contained in other tables and we don't reference it
-- in the final select statement
data_access_submission_submitter as (
    select
        *
    from
        {{ ref('stg_synapse__data_access_submission_submitter') }}
),

-- Create a single column `accessor_changes`
-- mapping principal IDs to access type for each data access submission
data_access_submission_accessor_changes_aggregated as (
    select
        data_access_submission_id,
        object_agg(principal_id::varchar, to_variant(access_type)) as accessor_changes
    from
        {{ ref('stg_synapse__data_access_submission_accessor_changes') }}
    group by
        data_access_submission_id
)

select
    base.data_access_submission_id,
    base.data_access_request_id,
    base.access_requirement_id,
    base.access_requirement_version,
    base.research_project_id,
    base.created_by,
    base.created_on,
    status.state_modified_by,
    status.state_modified_on,
    status.state,
    status.state_reason,
    base.etag,
    base.data_access_submission_raw,
    accessor_changes_agg.accessor_changes
from
    data_access_submission_base base
left join 
    data_access_submission_status status
using
    (data_access_submission_id)
left join
    data_access_submission_accessor_changes_aggregated accessor_changes_agg
using
    (data_access_submission_id)