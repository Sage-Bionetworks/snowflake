USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE PROCEDURE list_downloaders_with_size_by_month(start_record_date VARCHAR, entity_list VARCHAR)
RETURNS TABLE ("USER_ID" NUMBER, "USER_NAME" VARCHAR, "EMAIL" VARCHAR, "SYNAPSE_PROFILE" VARCHAR, "MONTH" NUMBER, "NUM_DOWNLOADS" NUMBER, "SIZE_DOWNLOADS" NUMBER)
LANGUAGE SQL
COMMENT = 'Lists users who downloaded files under `entity_list` on or after `start_record_date`, with download size grouped by month.'
EXECUTE AS OWNER
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
            SELECT fd.user_id, fd.timestamp, fd.association_object_id AS entity_id, fl.content_size AS entity_size
            FROM {{database_name}}.synapse_event.objectdownload_event fd --noqa: JJ01,PRS,TMP
            JOIN filetree ft ON ft.id = fd.association_object_id
            JOIN {{database_name}}.synapse.node_latest nl ON nl.id = ft.id --noqa: JJ01,PRS,TMP
            JOIN {{database_name}}.synapse.file_latest fl ON fl.id = nl.file_handle_id --noqa: JJ01,PRS,TMP
            WHERE fd.association_object_type = 'FileEntity'
              AND ft.node_type = 'file'
              AND fd.record_date >= TO_DATE(:start_record_date)
        ),
        download_summary AS (
            SELECT user_id, MONTH(timestamp) AS "month", COUNT(*) AS num_downloads, SUM(entity_size) AS size_downloads
            FROM download
            GROUP BY user_id, MONTH(timestamp)
        )
        SELECT
            ds.user_id, up.user_name, up.email,
            'https://www.synapse.org/#!Profile:' || ds.user_id AS synapse_profile,
            ds."month", ds.num_downloads, ds.size_downloads
        FROM download_summary ds
        JOIN {{database_name}}.synapse.userprofile_latest up ON up.id = ds.user_id --noqa: JJ01,PRS,TMP
        ORDER BY ds."month", ds.size_downloads DESC
    );
    RETURN TABLE(res);
END;
$$;
