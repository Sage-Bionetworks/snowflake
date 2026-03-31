select created_on
from synapse_data_warehouse.rds_raw.access_approval
where created_on is null
