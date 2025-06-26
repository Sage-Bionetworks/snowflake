USE SCHEMA {{database_name}}.synapse_aggregate; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE OBJECTDOWNLOAD_AGGREGATE 
(
    AGG_PERIOD VARCHAR
        COMMENT 'The aggregate level of the time dimensions (e.g., YEARLY, MONTHLY, DAILY).',
    AGG_LEVEL VARCHAR
        COMMENT 'The aggregate level of the non-time dimensions. This includes (listed in order of decreasing specificity) aggregates for a given object identifier associated with a given project (OBJECT WITHIN PROJECT) and objects which have no project association (OBJECT), as well as aggregates across every object of a given object type associated with a given project (OBJECT TYPE WITHIN PROJECT), every object (regardless of type) associated with a given project (PROJECT), every object of a given type within Synapse (OBJECT TYPE), and, finally, every object within Synapse (ALL OBJECTS). Note that only "FileEntity" and "TableEntity" object types are associated with a project.',
    AGG_YEAR NUMBER
        COMMENT 'PRIMARY KEY (Composite). Year of the aggregation period.',
    AGG_QUARTER NUMBER
        COMMENT 'PRIMARY KEY (Composite). Quarter of the aggregation period.',
    AGG_MONTH NUMBER
        COMMENT 'PRIMARY KEY (Composite). Month of the aggregation period.',
    AGG_DAY NUMBER
        COMMENT 'PRIMARY KEY (Composite). Day of the aggregation period.',
    AGG_PROJECT_ID NUMBER
        COMMENT 'PRIMARY KEY (Composite). The unique identifier of the Synapse project where the entity or object resides. Applicable only when `object_type` is FileEntity or TableEntity.',
    AGG_OBJECT_TYPE VARCHAR
        COMMENT 'PRIMARY KEY (Composite). The type of the Synapse entity or object.',
    AGG_OBJECT_ID NUMBER
        COMMENT 'PRIMARY KEY (Composite). The unique identifier of the Synapse entity or object.',
    AGG_PERIOD_START DATE
        COMMENT 'The start date of the aggregation period.',
    AGG_PERIOD_END DATE
        COMMENT 'The stop date of the aggregation period.',
    AGG_PERIOD_IS_COMPLETE  BOOLEAN  
        COMMENT 'If true, then the aggregation period is complete.',
    USER_DOWNLOAD_COUNT  NUMBER  
        COMMENT 'The number of unique users that have generated a pre-signed URL for this object during the aggregation period. This approximates a download.',
    DOWNLOAD_EVENT_COUNT  NUMBER  
        COMMENT 'The number of download events for this object during the aggregation period. Download events for a given object are on a per user per day basis, hence for daily aggregates this will always be equal to the `USER_DOWNLOAD_COUNT`.'
)
TARGET_LAG = '1 day'
WAREHOUSE = compute_xsmall
COMMENT = 'This table contains download aggregates across yearly, quarterly, monthly, and daily periods. Aggregates for these periods are computed for various combinations of the project, object type, and object identifier dimensions. For ease of reference, each combination is assigned a label in the `agg_level` column.

h3. Understanding Aggregates

Aggregates are computed over specific time periods, as well as over specific cross-sections of other non-time columns or dimensions.

h4. Aggregates over Time Periods

Aggregates over a given time period are labeled in `agg_period`:

* YEARLY
* QUARTERLY
* MONTHLY
* DAILY

h4. Aggregates over Data Dimensions

Aggregates over various non-time, data dimensions are labeled in `agg_level`:

* *OBJECT WITHIN PROJECT* - Aggregates for objects within a given project. This encompasses only "FileEntity" and "TableEntity" `object_type`s.
* *OBJECT* - Aggregates for objects which don\'t associate with a project. This encompasses all other `object_type`s. Note that we do not provide _cross-project_ download aggregates for FileEntity or TableEntity objects.
* *OBJECT TYPE WITHIN PROJECT* - Aggregates for an object type within a given project. This only applies to object types which associate with a project: FileEntity and TableEntity.
* *PROJECT* - Aggregates for _all_ objects within a given project. This encompasses FileEntity and TableEntity object types.
* *OBJECT TYPE* - Aggregates for an object type, regardless of project.
* *ALL OBJECTS* - Aggregates for all objects within Synapse. Note that this encompasses only those object types provided in `object_type`.'
    AS
    WITH user_download_rollup AS (
        SELECT
            -- Extracting our aggregate dimensions from ``record_date`` column
            YEAR(record_date)  AS agg_year,
            QUARTER(record_date) AS agg_quarter,
            MONTH(record_date) AS agg_month,
            DAY(record_date)   AS agg_day,

            -- Use GROUPING to determine which dimensions were rolled up for each row 
            GROUPING(agg_day)   AS g_day,
            GROUPING(agg_month) AS g_month,
            GROUPING(agg_quarter) AS g_quarter,
            GROUPING(agg_year)  AS g_year,

            -- Additional rollup columns
            project_id,
            association_object_id,
            association_object_type,

            -- Computing our aggregates
            COUNT(DISTINCT user_id) AS user_download_count,
            COUNT(*) AS download_event_count
        FROM
            {{ database_name }}.synapse_event.objectdownload_event --noqa: JJ01,PRS,TMP
        WHERE
            -- exclude today’s partial data to avoid confusion in the final table
            RECORD_DATE < (SELECT MAX(RECORD_DATE) FROM {{ database_name }}.synapse_event.objectdownload_event) --noqa: JJ01,PRS,TMP
            -- do not include file/table entities which have no project association
            AND NOT (
                association_object_type IN ('FileEntity', 'TableEntity')
                AND project_id IS NULL
            )
        GROUP BY
            ROLLUP(agg_year, agg_quarter, agg_month, agg_day),
            GROUPING SETS (
                (),                                                 -- 1) aggregates across every object in Synapse
                (project_id),                                       -- 2) aggregates across every object in this project
                (association_object_type),                          -- 3) aggregates across every object of this type in Synapse
                (project_id, association_object_type),              -- 4) aggregates across every object of this type in this project
                -- (association_object_type, association_object_id),   -- 5) aggregates across projects for this object
                (project_id, association_object_type, association_object_id)  -- 6) aggregates for a specific object in a specific project
            )
    ),
    -- Step 2: Determine the aggregate period (grain) and start and end dates
    agg_period_calculations AS (

        SELECT
            agg_year,
            agg_quarter,
            agg_month,
            agg_day,

            -- Create `agg_period` column
            -- Determine granularity based on which dimensions were rolled up
            CASE
                WHEN g_year = 1 AND g_quarter = 1 AND g_month = 1 AND g_day = 1 THEN 'ALL TIME'
                WHEN g_year = 0 AND g_quarter = 1 AND g_month = 1 AND g_day = 1 THEN 'YEARLY'
                WHEN g_year = 0 AND g_quarter = 0 AND g_month = 1 AND g_day = 1 THEN 'QUARTERLY'
                WHEN g_year = 0 AND g_quarter = 0 AND g_month = 0 AND g_day = 1 THEN 'MONTHLY'
                WHEN g_day = 0 THEN 'DAILY'
            END AS agg_period,

            -- Create `agg_level` column
            -- Determine granularity based on which grouping sets were rolled up
            CASE
                WHEN project_id IS NOT NULL AND association_object_type IS NOT NULL AND association_object_id IS NOT NULL
                    THEN 'OBJECT WITHIN PROJECT'
                WHEN project_id IS NOT NULL AND association_object_type IS NOT NULL AND association_object_id IS NULL
                    THEN 'OBJECT TYPE WITHIN PROJECT'
                WHEN project_id IS NOT NULL AND association_object_type IS NULL
                    THEN 'PROJECT'
                -- This covers other object types, but doesn't match table/file aggregates across projects.
                -- The check against table/file aggregates is not relevant, since we don't currently include
                -- the (association_object_type, association_object_id) grouping set, but no harm in including it
                -- to reduce maintenence burden.
                WHEN project_id IS NULL AND association_object_type IS NOT NULL AND association_object_id IS NOT NULL AND association_object_type NOT IN ('TableEntity', 'FileEntity')
                     THEN 'OBJECT'
                WHEN project_id IS NULL AND association_object_type IS NOT NULL AND association_object_id IS NULL
                    THEN 'OBJECT TYPE'
                WHEN project_id IS NULL AND association_object_type IS NULL AND association_object_id IS NULL
                    THEN 'ALL OBJECTS'
            END AS agg_level,

            -- Create `agg_period_start` column
            CASE
                -- First day of the year
                WHEN g_year = 0 AND g_quarter = 1 AND g_month = 1 AND g_day = 1 THEN DATE_FROM_PARTS(agg_year, 1, 1)
                -- First day of the quarter
                WHEN g_year = 0 AND g_quarter = 0 AND g_month = 1 AND g_day = 1 THEN DATE_FROM_PARTS(agg_year, (agg_quarter * 3) - 2, 1)
                -- First day of the month
                WHEN g_year = 0 AND g_quarter = 0 AND g_month = 0 AND g_day = 1 THEN DATE_FROM_PARTS(agg_year, agg_month, 1)
                -- Date
                WHEN g_day = 0 THEN DATE_FROM_PARTS(agg_year, agg_month, agg_day)
            END AS agg_period_start,

            -- Create `agg_period_end` column (inclusive)
            CASE
                -- Last day of the year
                WHEN g_year = 0 AND g_quarter = 1 AND g_month = 1 AND g_day = 1 THEN LAST_DAY(DATE_FROM_PARTS(agg_year, 1, 1), 'YEAR')
                -- Last day of the quarter
                WHEN g_year = 0 AND g_quarter = 0 AND g_month = 1 AND g_day = 1 THEN LAST_DAY(DATE_FROM_PARTS(agg_year, agg_quarter * 3, 1))
                -- Last day of the month
                WHEN g_year = 0 AND g_quarter = 0 AND g_month = 0 AND g_day = 1 THEN LAST_DAY(DATE_FROM_PARTS(agg_year, agg_month, 1))
                -- Date
                WHEN g_day = 0 THEN DATE_FROM_PARTS(agg_year, agg_month, agg_day)
            END AS agg_period_end,
            project_id,
            association_object_id,
            association_object_type,
            user_download_count,
            download_event_count
        FROM user_download_rollup
        -- The following WHERE condition is omitted because we don't include
        -- (association_object_type, association_object_id) among our grouping sets.
        -- The below condition may be useful if we decide to include this grouping set in the future.
        --
        -- Drop records which contain (association_object_type, association_object_id) aggregates for those
        -- project-specific objects (e.g., file and table entities) which have only ever been downloaded
        -- from a single project. Over 99% of aggregates over this grouping set are redundant because most
        -- project-specific objects exist in just one project. This is a nearly 25% reduction in records!
        -- WHERE
        --     -- Our strategy here is to match any aggregates which fit the description above
        --     -- and exclude them from the query results.
        --     NOT (
        --         association_object_id IS NOT NULL
        --         AND association_object_type IS NOT NULL
        --         AND project_id IS NULL
        --         -- Up to this point, we are matching all (association_object_type, association_object_id) aggregates
        --         AND NOT (
        --             -- Exclude from our match objects which have downloads across more than a single project
        --             -- and objects which don't associate with a project. This NOT (A OR B) approach requires our
        --             -- query to do set operations on 20x fewer records than the more direct approach.
        --             -- Check out De Morgan's law if u a real nerd and want to write this like (NOT A) AND (NOT B).

        --             -- Exclude from our match objects which have downloads across more than a single project.
        --             -- Objects which have downloads across more than one project will evaluate to TRUE
        --             -- Objects which have downloads in just one project will evaluate to FALSE
        --             -- Objects which don't associate with a project will evaluate to FALSE
        --             association_object_id IN (
        --                 SELECT 
        --                     association_object_id
        --                 FROM 
        --                     {{database_name}}.synapse_event.filedownload --noqa: JJ01,PRS,TMP
        --                 WHERE
        --                     project_id IS NOT NULL
        --                 GROUP BY 
        --                     association_object_id
        --                 HAVING 
        --                     COUNT(DISTINCT project_id) > 1
        --             )

        --             OR 

        --             -- Exclude from our match objects which don't associate with a project.
        --             -- Objects which have downloads across more than one project will evaluate to FALSE
        --             -- Objects which appear in just one project will evaluate to FALSE
        --             -- Objects which don't associate with a project will evaluate to TRUE.
        --             association_object_id IN (
        --                 SELECT 
        --                     distinct association_object_id
        --                 FROM 
        --                     {{database_name}}.synapse_event.filedownload --noqa: JJ01,PRS,TMP
        --                 WHERE
        --                     project_id IS NULL
        --             )
        --             -- Only objects which appear in a single project will evaluate to FALSE both times!
        --         ) 
        --     )
        --     -- Hence they are the only (association_object_type, association_object_id) aggregates
        --     -- which will be excluded from the results of this CTE.
    )
    -- Step 3: Compose the final table by ordering the columns for easier reading and adding the completion column
    SELECT
        agg_period,
        agg_level,
        agg_year,
        agg_quarter,
        agg_month,
        agg_day,
        project_id as agg_project_id,
        association_object_type as agg_object_type,
        association_object_id as agg_object_id,
        agg_period_start,
        agg_period_end,
        -- 5. Mark the period as complete once today's date is past the stop
        (CURRENT_DATE > agg_period_end) AS agg_period_is_complete,
        user_download_count,
        download_event_count
    FROM agg_period_calculations
    ORDER BY
        agg_year, agg_month, agg_day, agg_object_id, agg_object_type;