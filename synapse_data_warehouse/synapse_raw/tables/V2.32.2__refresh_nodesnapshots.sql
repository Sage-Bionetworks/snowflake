-- Configure environment
USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP,CP02
USE WAREHOUSE compute_medium;

SET cutoff_date = '2025-01-22';
SET num_records_to_be_reloaded = (
    SELECT count(*)
    FROM nodesnapshots
    WHERE snapshot_date >= $cutoff_date
);

-- This scripting block is an attempt to avoid any `COPY INTO` action in
-- the unlikely case of a rollback/replay of our database state. For example,
-- if we are deploying our database from scratch -- or more specifically, if
-- we don't have any table data requiring a `version_history` backfill -- we don't
-- want to load data (that's a job for the associated data loading task).
BEGIN 
  -- Check if there are records to reload
  IF ($num_records_to_be_reloaded > 0) THEN
  
    -- Drop records from nodesnapshots based on the cutoff date
    DELETE FROM nodesnapshots
    WHERE snapshot_date >= $cutoff_date;

    -- Execute the COPY INTO command directly within EXECUTE IMMEDIATE
    EXECUTE IMMEDIATE '
    COPY INTO nodesnapshots FROM (
        SELECT
          $1:change_type AS change_type,
          $1:change_timestamp AS change_timestamp,
          $1:change_user_id AS change_user_id,
          $1:snapshot_timestamp AS snapshot_timestamp,
          $1:id AS id,
          $1:benefactor_id AS benefactor_id,
          $1:project_id AS project_id,
          $1:parent_id AS parent_id,
          $1:node_type AS node_type,
          $1:created_on AS created_on,
          $1:created_by AS created_by,
          $1:modified_on AS modified_on,
          $1:modified_by AS modified_by,
          $1:version_number AS version_number,
          $1:file_handle_id AS file_handle_id,
          $1:name AS name,
          $1:is_public AS is_public,
          $1:is_controlled AS is_controlled,
          $1:is_restricted AS is_restricted,
          NULLIF(
              REGEXP_REPLACE(
                  metadata$filename,
                  ''.*nodesnapshots/snapshot_date=(.*)/.*'', ''\\1''
              ),
              ''__HIVE_DEFAULT_PARTITION__''
          ) AS snapshot_date,
          $1:effective_ars AS effective_ars,
          PARSE_JSON(REPLACE(REPLACE($1:annotations, ''\n'', ''\\n''), ''\r'', ''\\r'')) AS annotations,
          PARSE_JSON(REPLACE(REPLACE($1:derived_annotations, ''\n'', ''\\n''), ''\r'', ''\\r'')) AS derived_annotations,
          $1:version_comment AS version_comment,
          $1:version_label AS version_label,
          $1:alias AS alias,
          $1:activity_id AS activity_id,
          PARSE_JSON($1:column_model_ids) AS column_model_ids,
          PARSE_JSON($1:scope_ids) AS scope_ids,
          PARSE_JSON($1:items) AS items,
          PARSE_JSON($1:reference) AS reference,
          $1:is_search_enabled AS is_search_enabled,
          $1:defining_sql AS defining_sql,
          PARSE_JSON(REPLACE(REPLACE($1:internal_annotations, ''\n'', ''\\n''), ''\r'', ''\\r'')) AS internal_annotations,
          PARSE_JSON(REPLACE(REPLACE($1:version_history, ''\n'', ''\\n''), ''\r'', ''\\r'')) AS version_history,
          PARSE_JSON(REPLACE(REPLACE($1:project_storage_usage, ''\n'', ''\\n''), ''\r'', ''\\r'')) AS project_storage_usage
        FROM @{{stage_storage_integration}}_stage/nodesnapshots/
      ) PATTERN = ''.*nodesnapshots/snapshot_date=(2025-01-(2[2-9]|3[0-1])|202[5-9]-.*|20[3-9]d-.*)/.*'' FORCE = TRUE;
    ';
  END IF;
END;
