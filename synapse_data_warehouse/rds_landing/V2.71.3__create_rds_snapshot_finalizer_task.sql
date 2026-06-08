use schema {{database_name}}.rds_landing; --noqa: JJ01,PRS,TMP

-- Suspend root before modifying the graph.
alter task refresh_stage_task suspend;

-- Create the finalizer task.
create or replace task rds_snapshot_finalizer_task --noqa: TMP
    warehouse = 'COMPUTE_XSMALL'
    finalize = 'refresh_stage_task' --noqa: TMP
as
execute immediate $$
declare
    v_graph_status  varchar;
    v_root_task_id  varchar;
    v_graph_run_group_id varchar;
    v_start_time    timestamp_ltz;
    v_loaded        integer default 0;
    v_failed        integer default 0;
    v_total_rows    integer default 0;
    v_failed_names  varchar default '';
    v_run_date      varchar;
    v_message       varchar;
begin
    v_root_task_id := (
                select root_task_id
                from snowflake.account_usage.task_history
                where upper(name) = upper('refresh_stage_task')
                    and scheduled_time >= dateadd(hour, -25, current_timestamp())
                qualify row_number() over (order by scheduled_time desc) = 1
    );
    v_start_time := (
        select scheduled_time
        from snowflake.account_usage.task_history
        where upper(name) = upper('refresh_stage_task')
        qualify row_number() over (order by scheduled_time desc) = 1
    );

    select graph_run_group_id
    into :v_graph_run_group_id
    from snowflake.account_usage.task_history
    where root_task_id = :v_root_task_id
        and scheduled_time >= :v_start_time
        and scheduled_time <= current_timestamp()
    qualify row_number() over (order by scheduled_time desc) = 1;

    select
        case
                        when count_if(upper(state) = 'FAILED') > 0 then 'failed'
                        when count_if(upper(state) = 'CANCELED') > 0 then 'cancelled'
                        when count_if(upper(state) = 'SUCCEEDED') > 0 then 'succeeded'
            else 'unknown'
        end
    into :v_graph_status
    from snowflake.account_usage.task_history
    where graph_run_group_id = :v_graph_run_group_id;

    v_run_date     := to_varchar(current_date(), 'MM/DD/YYYY');

    if (v_graph_status = 'succeeded') then
        select
            coalesce(count(*), 0),
            coalesce(sum(row_count), 0)
        into :v_loaded, :v_total_rows
        from snowflake.account_usage.load_history
        where schema_name = 'RDS_LANDING'
          and last_load_time >= :v_start_time;

        select
            coalesce(count_if(upper(state) = 'FAILED'), 0),
            listagg(case when upper(state) = 'FAILED' then name end, ', ')
                within group (order by name)
        into :v_failed, :v_failed_names
        from snowflake.account_usage.task_history
        where graph_run_group_id = :v_graph_run_group_id
          and upper(name) != 'RDS_SNAPSHOT_FINALIZER_TASK';

        if (v_failed = 0) then
            v_message := '✅ RDS snapshot ingestion complete — '
                || v_loaded || '/157 record types loaded · '
                || v_total_rows || ' rows total · Run date: ' || v_run_date;
        else
            v_message := '⚠️ RDS snapshot ingestion completed with errors — '
                || v_loaded || '/157 loaded · '
                || v_failed || ' failed: ' || v_failed_names
                || ' - Run date: ' || v_run_date || ' — [TODO: tag team]';
        end if;
    elseif (v_graph_status = 'failed') then
        v_message := '🔴 RDS snapshot ingestion FAILED — graph state: ' || v_graph_status
            || ' · Run date: ' || v_run_date || ' — [TODO: tag team]';
    else
        v_message := '⚠️ No graph status retrieved. DPE team please view task statuses in '
            || 'snowflake.account_usage.task_history'
            || ' · Run date: ' || v_run_date || ' — [TODO: tag team]';
    end if;

    call system$send_snowflake_notification(
        snowflake.notification.text_plain(:v_message),
        -- TODO: point to prod integration when ready
        snowflake.notification.integration('DEV_SLACK_INGEST_UPDATES')
    );

    return :v_message;
end;
$$;

alter task rds_snapshot_finalizer_task resume;

-- Re-enable the full RDS snapshot task graph from the root.
select system$task_dependents_enable('refresh_stage_task');