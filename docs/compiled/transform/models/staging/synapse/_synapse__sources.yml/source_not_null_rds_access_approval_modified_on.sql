select modified_on
from synapse_data_warehouse.rds_raw.access_approval
where modified_on is null
