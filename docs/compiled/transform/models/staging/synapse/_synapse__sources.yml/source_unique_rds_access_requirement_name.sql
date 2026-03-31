select
    name as unique_field,
    count(*) as n_records

from synapse_data_warehouse.rds_raw.access_requirement
where name is not null
group by name
having count(*) > 1
