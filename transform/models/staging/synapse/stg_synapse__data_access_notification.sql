with

source as (
    select * from {{ source('rds', 'data_access_notification') }}
),

staging as (
    select
        id as data_access_notification_id,
        notification_type as data_access_notification_type,
        requirement_id as access_requirement_id,
        recipient_id as principal_id,
        access_approval_id as access_requirement_approval_id,
        sent_on,
        message_id,
        etag
    from
        source
)

select * from staging
