select sent_on
from synapse_data_warehouse.rds_raw.data_access_notification
where sent_on is null
