select owner_id
from synapse_data_warehouse.rds_raw.acl_resource_access
where owner_id is null
