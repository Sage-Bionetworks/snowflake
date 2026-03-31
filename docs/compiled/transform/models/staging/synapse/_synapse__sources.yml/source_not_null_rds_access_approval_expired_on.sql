select expired_on
from synapse_data_warehouse.rds_raw.access_approval
where expired_on is null
