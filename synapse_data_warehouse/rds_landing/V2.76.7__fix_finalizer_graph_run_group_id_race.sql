use schema {{database_name}}.rds_landing; --noqa: JJ01,PRS,TMP

-- Finalizer previously picked the root task row with the latest scheduled_time, which can match a future
-- not-yet-run occurrence instead of the run being finalized. Pull the current run's graph_run_group_id
-- directly from task runtime context instead.

alter task refresh_rds_snapshots_stage_task suspend;

create or replace task refresh_rds_snapshots_stage_finalizer_task
    user_task_managed_initial_warehouse_size = 'XSMALL'
    finalize = 'refresh_rds_snapshots_stage_task'
as
execute immediate $$
declare
    v_graph_run_group_id varchar;
    v_root_task_id       varchar;
    v_root_task_state    varchar;
    v_root_task_scheduled_time   timestamp_ltz;
    v_root_task_query_start_time timestamp_ltz;
    v_root_task_completed_time   timestamp_ltz;
    v_loaded        integer default 0;
    v_total         integer default 0;
    v_failed        integer default 0;
    v_failed_names  varchar default '';
    v_run_date      varchar;
    v_message       varchar;
begin
    v_graph_run_group_id := system$task_runtime_info('CURRENT_TASK_GRAPH_RUN_GROUP_ID');

    -- Root task's own row for this exact run. The bare (unparameterized) task_history() call has a
    -- narrower default scope that can miss this row entirely, regardless of elapsed time; task_name
    -- widens that scope, and graph_run_group_id picks the exact run rather than the latest by schedule.
    select root_task_id, state, scheduled_time, query_start_time, completed_time
    into :v_root_task_id, :v_root_task_state, :v_root_task_scheduled_time, :v_root_task_query_start_time, :v_root_task_completed_time
    from table(snowflake.information_schema.task_history(task_name => 'REFRESH_RDS_SNAPSHOTS_STAGE_TASK', result_limit => 10000))
    where graph_run_group_id = :v_graph_run_group_id;

    v_run_date := to_varchar(current_date(), 'MM/DD/YYYY');

    if (v_root_task_state in ('FAILED', 'FAILED_AND_AUTO_SUSPENDED', 'CANCELLED')) then
        -- Root task itself failed or was cancelled — graph could not run.
        v_message := '🔴 RDS snapshot ingestion FAILED — root task failed or was cancelled'
            || ' · *Root Task ID*: ' || :v_root_task_id
            || ' · *Graph Run Group ID*: ' || :v_graph_run_group_id
            || ' · *Root Task Scheduled Time*: ' || to_varchar(:v_root_task_scheduled_time)
            || ' · *Root Task Query Start Time*: ' || to_varchar(:v_root_task_query_start_time)
            || ' · *Root Task Completed Time*: ' || to_varchar(:v_root_task_completed_time)
            || ' · *Run date*: ' || v_run_date || ' — @team-dpe';
    elseif (v_root_task_state = 'SUCCEEDED') then
        -- Count COPY_* (record-load) tasks in this specific graph run: succeeded, failed, and total.
        select
            count_if(upper(state) = 'SUCCEEDED'),
            count_if(upper(state) = 'FAILED'),
            count(*),
            listagg(case when upper(state) = 'FAILED' then name end, ', ')
                within group (order by name)
        into :v_loaded, :v_failed, :v_total, :v_failed_names
        from table(snowflake.information_schema.task_history(root_task_id => :v_root_task_id, result_limit => 10000))
        where graph_run_group_id = :v_graph_run_group_id
          and startswith(upper(name), 'COPY_');

        if (v_failed > 0) then
            -- Root task succeeded but some child tasks failed — partial success.
            v_message := '⚠️ RDS snapshot ingestion completed with errors — '
                || '*' || v_loaded || '*' || '/' || v_total || ' record types loaded · '
                || '*' || v_failed || '*' || ' failed: ' || v_failed_names
                || ' · *Graph Run Group ID*: ' || :v_graph_run_group_id
                || ' · *Root Task Scheduled Time*: ' || to_varchar(:v_root_task_scheduled_time)
                || ' · *Root Task Query Start Time*: ' || to_varchar(:v_root_task_query_start_time)
                || ' · *Root Task Completed Time*: ' || to_varchar(:v_root_task_completed_time)
                || ' · *Run date*: ' || v_run_date || ' — @team-dpe';
        else
            -- Root task succeeded and all child tasks passed — full success.
            v_message := '✅ RDS snapshot ingestion complete — '
                || '*' || v_loaded || '*' || '/' || v_total || ' record types loaded · '
                || ' · *Graph Run Group ID*: ' || :v_graph_run_group_id
                || ' · *Root Task Scheduled Time*: ' || to_varchar(:v_root_task_scheduled_time)
                || ' · *Root Task Query Start Time*: ' || to_varchar(:v_root_task_query_start_time)
                || ' · *Root Task Completed Time*: ' || to_varchar(:v_root_task_completed_time)
                || ' · *Run date*: ' || v_run_date;
        end if;
    else
        v_message := '⚠️ No graph status retrieved, or received an unexpected status. DPE team please view task statuses in '
            || 'snowflake.account_usage.task_history'
            || ' · *Graph Run Group ID*: ' || coalesce(:v_graph_run_group_id, 'NULL')
            || ' · *Root Task State*: ' || coalesce(:v_root_task_state, 'NULL')
            || ' · *Run date*: ' || v_run_date || ' — @team-dpe';
    end if;

    call system$send_snowflake_notification(
        snowflake.notification.text_plain(:v_message),
        {% if database_name == 'SYNAPSE_DATA_WAREHOUSE' %} --noqa: JJ01,PRS,TMP
        snowflake.notification.integration('SLACK_INGEST_UPDATES')
        {% else %}
        snowflake.notification.integration('DEV_SLACK_INGEST_UPDATES')
        {% endif %}
    );

    return :v_message;
end;
$$;

alter task refresh_rds_snapshots_stage_finalizer_task resume;

select system$task_dependents_enable('refresh_rds_snapshots_stage_task');
