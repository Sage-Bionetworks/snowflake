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
    v_root_task_id       varchar;
    v_root_task_state    varchar;
    v_graph_run_group_id varchar;
    v_scheduled_time     timestamp_ltz;
    v_query_start_time   timestamp_ltz;
    v_completed_time     timestamp_ltz;
    v_loaded        integer default 0;
    v_failed        integer default 0;
    v_total_rows    integer default 0;
    v_failed_names  varchar default '';
    v_run_date      varchar;
    v_message       varchar;
begin

    -----------------------------------------------------------------------------------------------------------------------
    -- Step 1) Get the latest run of the root task for the graph, and other useful metadata on the graph run such as status.
    -----------------------------------------------------------------------------------------------------------------------
    select
        root_task_id,
        graph_run_group_id,
        state,
        scheduled_time,
        query_start_time,
        completed_time
    into :v_root_task_id, :v_graph_run_group_id, :v_root_task_state, :v_scheduled_time, :v_query_start_time, :v_completed_time
    from snowflake.account_usage.task_history
    where upper(name) = 'REFRESH_STAGE_TASK'
    and upper(database_name) = upper('{{database_name}}')
    qualify row_number() over (order by scheduled_time desc, query_start_time desc) = 1;

    -----------------------------------------------------------------------------------------------------------------------
    -- Step 2) Build and send a Slack notification based on root task state and graph state.
    -----------------------------------------------------------------------------------------------------------------------
    v_run_date := to_varchar(current_date(), 'MM/DD/YYYY');

    if (v_root_task_state = 'FAILED') then
        -- Root task itself failed — graph could not run.
        v_message := '🔴 RDS snapshot ingestion FAILED — root task failed'
            || ' · *Root Task ID*: ' || :v_root_task_id
            || ' · *Graph Run Group ID*: ' || :v_graph_run_group_id
            || ' · *Scheduled Time*: ' || to_varchar(:v_scheduled_time)
            || ' · *Query Start Time*: ' || to_varchar(:v_query_start_time)
            || ' · *Completed Time*: ' || to_varchar(:v_completed_time)
            || ' · *Run date*: ' || v_run_date || ' — @team-dpe';
    elseif (v_root_task_state = 'SUCCEEDED') then
        -- Get the count of loaded record types and total rows loaded.
        select
            coalesce(count(*), 0),
            coalesce(sum(row_count), 0)
        into :v_loaded, :v_total_rows
        from snowflake.account_usage.load_history
        where catalog_name = '{{database_name}}'
        and schema_name = 'RDS_LANDING'
        -- TODO: This filter makes sure we're only counting rows for tasks that loaded stuff after the root task was run,
        --       but it doesn't guarantee that the loads were all part of the same graph run. Find a way to set an upper
        --       bound to ensure all loads are from the same graph run.
        and last_load_time >= :v_scheduled_time;

        -- Get the failed child tasks, if any.
        select
            coalesce(count_if(upper(state) = 'FAILED'), 0),
            listagg(case when upper(state) = 'FAILED' then name end, ', ')
                within group (order by name)
        into :v_failed, :v_failed_names
        from snowflake.account_usage.task_history
        where graph_run_group_id = :v_graph_run_group_id
          and upper(name) != 'RDS_SNAPSHOT_FINALIZER_TASK';

        if (v_failed > 0) then
            -- Root task succeeded but some child tasks failed — partial success.
            v_message := '⚠️ RDS snapshot ingestion completed with errors — '
                || *v_loaded* || '/157 loaded · '
                || *v_failed* || ' failed: ' || v_failed_names
                || ' · *Graph Run Group ID*: ' || :v_graph_run_group_id
                || ' · ' || *v_total_rows* || ' rows total'
                || ' · *Run date*: ' || v_run_date || ' — @team-dpe';
        else
            -- Root task succeeded and all child tasks passed — full success.
            v_message := '✅ RDS snapshot ingestion complete — '
                || *v_loaded* || '/157 record types loaded · '
                || *v_total_rows* || ' rows total · *Run date*: ' || v_run_date;
        end if;
    else
        v_message := '⚠️ No graph status retrieved. DPE team please view task statuses in '
            || 'snowflake.account_usage.task_history'
            || ' · *Run date*: ' || v_run_date || ' — @team-dpe';
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