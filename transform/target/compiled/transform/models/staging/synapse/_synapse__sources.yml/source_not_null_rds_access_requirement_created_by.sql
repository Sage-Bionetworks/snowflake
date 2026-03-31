select created_by
from synapse_data_warehouse.rds_raw.access_requirement
where created_by is null
