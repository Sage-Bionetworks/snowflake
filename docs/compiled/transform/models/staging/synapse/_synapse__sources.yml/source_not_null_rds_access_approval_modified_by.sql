select modified_by
from synapse_data_warehouse.rds_raw.access_approval
where modified_by is null
