-- add pre-snowflake download records to most recent filedownload table
-- use union rather than union all to remove duplicates (lots in pre-snowflake)
create or replace view sage.ad.all_time_downloads as

select
    id as entity_id,
    user_id,
    record_date
from sage.ad.pre_snowflake_download_records
where node_type = 'file'

union

select
    association_object_id as entity_id,
    user_id,
    record_date
from synapse_data_warehouse.synapse.filedownload
where project_id = '2580853' and association_object_type = 'FileEntity';
