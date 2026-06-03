use schema {{database_name}}.rds_landing; --noqa: JJ01,PRS,TMP

-- Suspend root before modifying the graph.
alter task {{database_name}}.rds_landing.refresh_stage_task suspend; --noqa: TMP

-- Create the finalizer task.
create or replace task {{database_name}}.rds_landing.rds_snapshot_finalizer_task --noqa: TMP
    warehouse = 'COMPUTE_XSMALL'
    finalize = '{{database_name}}.rds_landing.refresh_stage_task' --noqa: TMP
as
declare
    v_graph_status  varchar;
    v_loaded        integer default 0;
    v_failed        integer default 0;
    v_total_rows    integer default 0;
    v_failed_names  varchar default '';
    v_run_date      varchar;
    v_message       varchar;
begin
    let graph_json variant := parse_json(
        system$get_task_graph_return_value('{{database_name}}.rds_landing.refresh_stage_task') --noqa: TMP
    );
    v_graph_status := graph_json:state::varchar;
    v_run_date     := to_varchar(current_date(), 'MM/DD/YYYY');

    if (v_graph_status != 'succeeded') then
        v_message := '🔴 RDS snapshot ingestion FAILED — graph state: ' || v_graph_status
            || ' · Run date: ' || v_run_date || ' — [TODO: tag team]';
    else
        select
            coalesce(sum(case when status = 'Loaded' then 1 else 0 end), 0),
            coalesce(sum(case when status != 'Loaded' then 1 else 0 end), 0),
            coalesce(sum(row_count), 0),
            listagg(case when status != 'Loaded' then table_name end, ', ')
                within group (order by table_name)
        into :v_loaded, :v_failed, :v_total_rows, :v_failed_names
        from information_schema.copy_history
        where schema_name = 'RDS_LANDING'
          and last_load_time >= dateadd('hour', -25, current_timestamp());

        if (v_failed = 0) then
            v_message := '✅ RDS snapshot ingestion complete — '
                || v_loaded || '/157 record types loaded · '
                || v_total_rows || ' rows total · Run date: ' || v_run_date;
        else
            v_message := '⚠️ RDS snapshot ingestion completed with errors — '
                || v_loaded || '/157 loaded · '
                || v_failed || ' failed: ' || v_failed_names
                || ' · Run date: ' || v_run_date || ' — [TODO: tag team]';
        end if;
    end if;

    call system$send_snowflake_notification(
        snowflake.notification.text_plain(:v_message),
        snowflake.notification.integration('SLACK_INGEST_UPDATES')
    );

    return :v_message;
end;

alter task {{database_name}}.rds_landing.rds_snapshot_finalizer_task resume; --noqa: TMP

-- Re-enable the full RDS snapshot task graph from the root.
select system$task_dependents_enable('{{database_name}}.rds_landing.refresh_stage_task'); --noqa: JJ01,PRS,TMP