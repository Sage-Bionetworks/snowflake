USE SCHEMA {{database_name}}.synapse;

CREATE OR REPLACE PROCEDURE list_downloaders(start_record_date string, entity_list string)
RETURNS TABLE (user_id integer, c integer, min_t timestamp, max_t timestamp)
LANGUAGE SQL
AS
declare
    rs resultset;
    query_str1 varchar default (
    'with recursive filetree (parent_id, id, node_type) as (
    select null as parent_id, id, node_type
    from node_latest
    where id in (' || :entity_list || ')
    union all
    select fc.parent_id, fc.id, fc.node_type
    from node_latest fc
    join filetree ft on ft.id = fc.parent_id   
    ),');
    query_str2 varchar default    
    'download (user_id, timestamp, entity_id) as (
    select fd.user_id, fd.timestamp, fd.association_object_id as entity_id
    from filedownload fd
    join filetree ft on ft.id = fd.association_object_id
    where fd.association_object_type = \'FileEntity\'
        and ft.node_type = \'file\'
        and fd.record_date >= \'||:start_record_date||\'
    ),';
    query_str3 varchar default
    'download_summary (user_id, c, min_t, max_t) as (
    select user_id, count(*) as c, min(timestamp) as min_t, max(timestamp) as max_t
    from download
    group by user_id
    )';
    query_str4 varchar default
    'select *
    from download_summary
    order by min_t, user_id';
    query_str varchar default (:query_str1 || :query_str2 || :query_str3 || :query_str4);
begin
    rs := (EXECUTE IMMEDIATE :query_str);
    return table(rs);
end;