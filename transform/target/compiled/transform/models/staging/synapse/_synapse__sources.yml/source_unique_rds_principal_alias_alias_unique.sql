select
    alias_unique as unique_field,
    count(*) as n_records

from synapse_data_warehouse.rds_raw.principal_alias
where alias_unique is not null
group by alias_unique
having count(*) > 1
