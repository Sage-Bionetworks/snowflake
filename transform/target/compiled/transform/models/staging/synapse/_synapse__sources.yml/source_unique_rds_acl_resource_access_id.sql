select
    id as unique_field,
    count(*) as n_records

from synapse_data_warehouse.rds_raw.acl_resource_access
where id is not null
group by id
having count(*) > 1
