select created_by
from synapse_data_warehouse.rds_raw.access_approval
where created_by is null
