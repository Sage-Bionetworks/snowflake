select
    submission_id as unique_field,
    count(*) as n_records

from synapse_data_warehouse.rds_raw.data_access_submission_status
where submission_id is not null
group by submission_id
having count(*) > 1
