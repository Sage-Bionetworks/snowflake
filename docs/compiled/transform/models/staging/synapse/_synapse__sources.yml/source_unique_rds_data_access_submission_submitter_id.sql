select
    id as unique_field,
    count(*) as n_records

from synapse_data_warehouse.rds_raw.data_access_submission_submitter
where id is not null
group by id
having count(*) > 1
