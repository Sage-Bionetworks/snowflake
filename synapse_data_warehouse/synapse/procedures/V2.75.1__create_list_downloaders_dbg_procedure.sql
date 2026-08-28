USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE PROCEDURE list_downloaders_dbg(start_record_date DATE, entity_list VARCHAR)
RETURNS TABLE ("USER_ID" NUMBER, "USER_NAME" VARCHAR, "EMAIL" VARCHAR, "SYNAPSE_PROFILE" VARCHAR, "NUM_DOWNLOADS" NUMBER, "EARLIEST_DOWNLOAD_TIME" TIMESTAMP_NTZ, "LATEST_DOWNLOAD_TIME" TIMESTAMP_NTZ)
LANGUAGE SQL
COMMENT = 'Caller-rights debug variant of list_downloaders. Migrated from deprecated synapse.filedownload to synapse_event.objectdownload_event and rewritten from dynamic SQL to a static parameterized query (SNOW-572); num_downloads now counts distinct (user, object, date) download rows since the source table is deduplicated at that grain, not raw download events.'
EXECUTE AS CALLER
AS
$$
DECLARE
    res RESULTSET;
BEGIN
    res := (
        WITH RECURSIVE filetree (parent_id, id, node_type) AS (
            SELECT NULL, id, node_type
            FROM {{database_name}}.synapse.node_latest --noqa: JJ01,PRS,TMP
            WHERE id IN (SELECT value::NUMBER FROM TABLE(SPLIT_TO_TABLE(:entity_list, ',')))
            UNION ALL
            SELECT fc.parent_id, fc.id, fc.node_type
            FROM {{database_name}}.synapse.node_latest fc --noqa: JJ01,PRS,TMP
            JOIN filetree ft ON ft.id = fc.parent_id
        ),
        download AS (
            SELECT fd.user_id, fd.timestamp, fd.association_object_id AS entity_id
            FROM {{database_name}}.synapse_event.objectdownload_event fd --noqa: JJ01,PRS,TMP
            JOIN filetree ft ON ft.id = fd.association_object_id
            WHERE fd.association_object_type = 'FileEntity'
              AND ft.node_type = 'file'
              AND fd.record_date >= :start_record_date
        ),
        download_summary AS (
            SELECT user_id, COUNT(*) AS num_downloads,
                   MIN(timestamp) AS min_t, MAX(timestamp) AS max_t
            FROM download
            GROUP BY user_id
        )
        SELECT
            ds.user_id, up.user_name, up.email,
            'https://www.synapse.org/#!Profile:' || ds.user_id AS synapse_profile,
            ds.num_downloads, ds.min_t AS earliest_download_time, ds.max_t AS latest_download_time
        FROM download_summary ds
        JOIN {{database_name}}.synapse.userprofile_latest up ON up.id = ds.user_id --noqa: JJ01,PRS,TMP
        ORDER BY ds.min_t, ds.user_id
    );
    RETURN TABLE(res);
END;
$$;
