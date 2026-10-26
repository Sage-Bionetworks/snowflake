with

accessor_changes as (
    select
        data_access_submission_id,
        accessor_id,
        accessor_change_type,
        access_requirement_id,
        access_requirement_version_reviewed_against as access_requirement_version,
        state_modified_on as change_established_on,
        access_expires_on
    from dynamic_table_refresh_boundary({{ ref('int_synapse_accessor_changes') }})
    where state = 'Approved'
),

access_grants as (
    select
        accessor_id,
        access_requirement_id,
        access_requirement_version,
        access_expires_on,
        lead(change_established_on) over (
            partition by access_requirement_id, accessor_id
            order by change_established_on, data_access_submission_id
        ) as next_grant_on
    from accessor_changes
    where accessor_change_type in ('GAIN_ACCESS', 'RENEW_ACCESS')
),

lifecycle_events as (
    select
        accessor_id,
        access_requirement_id,
        access_requirement_version,
        accessor_change_type as event_type,
        change_established_on as event_on
    from accessor_changes

    union all

    select
        accessor_id,
        access_requirement_id,
        access_requirement_version,
        'EXPIRED_ACCESS' as event_type,
        access_expires_on as event_on
    from access_grants
    where
        access_expires_on < current_date
        -- A later grant supersedes expiration only if it was established before or at expiration.
        and (next_grant_on is null or next_grant_on > access_expires_on)
),

event_rollup as (
    select
        year(event_on) as agg_year,
        quarter(event_on) as agg_quarter,
        month(event_on) as agg_month,
        day(event_on) as agg_day,
        grouping(agg_day) as g_day,
        grouping(agg_month) as g_month,
        grouping(agg_quarter) as g_quarter,
        grouping(agg_year) as g_year,
        access_requirement_id,
        access_requirement_version,
        count(case when event_type = 'GAIN_ACCESS' then 1 end) as gain_access_count,
        count(distinct case when event_type = 'GAIN_ACCESS' then accessor_id end) as gain_access_user_count,
        count(case when event_type = 'RENEW_ACCESS' then 1 end) as renew_access_count,
        count(distinct case when event_type = 'RENEW_ACCESS' then accessor_id end) as renew_access_user_count,
        count(case when event_type = 'REVOKE_ACCESS' then 1 end) as revoke_access_count,
        count(distinct case when event_type = 'REVOKE_ACCESS' then accessor_id end) as revoke_access_user_count,
        count(case when event_type = 'EXPIRED_ACCESS' then 1 end) as expired_access_count,
        count(distinct case when event_type = 'EXPIRED_ACCESS' then accessor_id end) as expired_access_user_count
    from lifecycle_events
    where access_requirement_version is not null
    group by
        rollup(agg_year, agg_quarter, agg_month, agg_day),
        access_requirement_id,
        access_requirement_version
),

agg_period_calculations as (
    select
        access_requirement_id,
        access_requirement_version,
        agg_year,
        agg_quarter,
        agg_month,
        agg_day,
        case
            when g_year = 1 then 'ALL TIME'
            when g_quarter = 1 then 'YEARLY'
            when g_month = 1 then 'QUARTERLY'
            when g_day = 1 then 'MONTHLY'
            else 'DAILY'
        end as agg_period,
        case
            when g_year = 0 and g_quarter = 1 then date_from_parts(agg_year, 1, 1)
            when g_quarter = 0 and g_month = 1 then date_from_parts(agg_year, (agg_quarter * 3) - 2, 1)
            when g_month = 0 and g_day = 1 then date_from_parts(agg_year, agg_month, 1)
            when g_day = 0 then date_from_parts(agg_year, agg_month, agg_day)
        end as agg_period_start,
        case
            when g_year = 0 and g_quarter = 1 then last_day(date_from_parts(agg_year, 1, 1), 'YEAR')
            when g_quarter = 0 and g_month = 1 then last_day(date_from_parts(agg_year, agg_quarter * 3, 1))
            when g_month = 0 and g_day = 1 then last_day(date_from_parts(agg_year, agg_month, 1))
            when g_day = 0 then date_from_parts(agg_year, agg_month, agg_day)
        end as agg_period_end,
        gain_access_count,
        gain_access_user_count,
        renew_access_count,
        renew_access_user_count,
        revoke_access_count,
        revoke_access_user_count,
        expired_access_count,
        expired_access_user_count
    from event_rollup
)

select
    agg_period,
    agg_year,
    agg_quarter,
    agg_month,
    agg_day,
    access_requirement_id as agg_access_requirement_id,
    access_requirement_version as agg_access_requirement_revision,
    agg_period_start,
    agg_period_end,
    coalesce(current_date > agg_period_end, false) as agg_period_is_complete,
    md5(concat_ws('~',
        agg_period,
        coalesce(to_varchar(agg_year), '_'),
        coalesce(to_varchar(agg_quarter), '_'),
        coalesce(to_varchar(agg_month), '_'),
        coalesce(to_varchar(agg_day), '_'),
        to_varchar(access_requirement_id),
        to_varchar(access_requirement_version)
    )) as agg_row_id,
    gain_access_count,
    gain_access_user_count,
    renew_access_count,
    renew_access_user_count,
    revoke_access_count,
    revoke_access_user_count,
    expired_access_count,
    expired_access_user_count
from agg_period_calculations
