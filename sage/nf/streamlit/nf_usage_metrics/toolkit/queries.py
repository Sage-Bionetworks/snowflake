PROJECT_VIEW_ID = 52677631
# DCC and DPE accounts excluded from external reuse metrics

STAFF_USERIDS = [
    # NF STAFF
    3421893, # NF-service account
    3389310, # Jineta Banerjee
    3342573, # Robert Allaway
    3434950, # ANV
    3459953, # Christina Conrad
    3514384, # James Moon
    3510065, # Aditya Nath
    # 3441340, # Sasha Scott, @anngvu: The only exception is Sasha Scott since she technically does not do DCC work and is considered a real data reuser.
    
    # DPE STAFF
    3324230, # Tom Yu
    3460442, # Rixing Xu
    3458117, # Brad Macdonald
    3434599, # Dan Lu
    3440247, # Sophia Jobe
    3342492, # Phil Snyder
    3481671, # Bryan Fauble
    3489628, # Jenny Medina
    3441756  # Loren Wolfe
    ]

def query_project_meta(funder="NTAP"):
        """Return project metadata for projects funded by given funder."""
        
        where_clause = f"WHERE CONTAINS(funder, '{funder}')" if funder != 'all' else ""

        return f"""
        WITH project_scope AS (
            SELECT
                CAST(scopes.value AS INTEGER) AS scope_id
            FROM
                synapse_data_warehouse.synapse.node_latest,
                LATERAL FLATTEN(input => node_latest.scope_ids) scopes
            WHERE
                id = {PROJECT_VIEW_ID}
        )
        SELECT
            nl.id AS project_id,
            JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.studyName.value[0]') AS project_name,
            JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.fundingAgency.value') AS funder,
            ARRAY_TO_STRING(PARSE_JSON(JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.studyLeads.value')), ', ') AS study_leads,
            JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.studyStatus.value[0]') AS study_status,
            JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.dataStatus.value[0]') AS data_status
        FROM
            synapse_data_warehouse.synapse.node_latest nl
        JOIN
            project_scope ps ON nl.id = ps.scope_id
        {where_clause}
        ORDER BY
            project_name;
        """


def query_project_meta_other_funders():
    """Return project metadata for projects funded by funders other than NTAP, CTF, or GFF."""
    
    return f"""
    WITH project_scope AS (
        SELECT
            CAST(scopes.value AS INTEGER) AS scope_id
        FROM
            synapse_data_warehouse.synapse.node_latest,
            LATERAL FLATTEN(input => node_latest.scope_ids) scopes
        WHERE
            id = {PROJECT_VIEW_ID}
    )
    SELECT
        nl.id AS project_id,
        JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.studyName.value[0]') AS project_name,
        JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.fundingAgency.value') AS funder,
        ARRAY_TO_STRING(PARSE_JSON(JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.studyLeads.value')), ', ') AS study_leads,
        JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.studyStatus.value[0]') AS study_status,
        JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.dataStatus.value[0]') AS data_status
    FROM
        synapse_data_warehouse.synapse.node_latest nl
    JOIN
        project_scope ps ON nl.id = ps.scope_id
    WHERE
        JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.fundingAgency.value') IS NOT NULL
        AND NOT CONTAINS(JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.fundingAgency.value'), 'NTAP')
        AND NOT CONTAINS(JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.fundingAgency.value'), 'CTF')
        AND NOT CONTAINS(JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.fundingAgency.value'), 'GFF')
    ORDER BY
        project_name;
    """


def query_project_sizes(project_ids):
    """Return the summarized file content sizes of given projects."""

    project_list = ', '.join(f"'{id}'" for id in project_ids)

    return f"""
    
    WITH project_files AS (
    SELECT
        nl.file_handle_id AS file_handle_id,
        nl.project_id,
    FROM
        synapse_data_warehouse.synapse.node_latest nl
    WHERE
        nl.project_id IN ({project_list})
    ),
    file_content_size AS (
    SELECT
        pf.project_id,
        filelatest.id,
        filelatest.content_size
    FROM
        synapse_data_warehouse.synapse.file_latest filelatest
    JOIN
        project_files pf
    ON
        filelatest.id = pf.file_handle_id
    )
    SELECT
        project_id,
        SUM(content_size) AS total_content_size
    FROM
        file_content_size
    GROUP BY
        project_id;
    """


# https://sagebionetworks.jira.com/wiki/spaces/PLFM/pages/3043590158/Reconcile+Synapse+Download+Records+with+S3+Egress+charges

def query_project_downloads(project_ids, start_date, end_date, excluded_users=STAFF_USERIDS):
    """Return the summarized content size of file downloads for given projects within timeframe."""

    project_list = ', '.join(f"'{id}'" for id in project_ids)

    return f"""
    WITH download_data AS (
        SELECT
            objectdownload_event.project_id,
            objectdownload_event.file_handle_id,
            objectdownload_event.user_id,
            objectdownload_event.record_date,
            filelatest.content_size
        FROM
            synapse_data_warehouse.synapse_event.objectdownload_event objectdownload_event
        JOIN
            synapse_data_warehouse.synapse.file_latest filelatest
        ON
            filelatest.id = objectdownload_event.file_handle_id
        WHERE
            objectdownload_event.project_id IN ({project_list})
            AND objectdownload_event.record_date BETWEEN '{start_date}' AND '{end_date}'
            -- AND file_handle_id = downloaded_file_handle_id     
            AND objectdownload_event.user_id NOT IN ({','.join(map(str, excluded_users))})
    )
    SELECT
        project_id,
        SUM(content_size) AS total_downloads,
        COUNT(DISTINCT file_handle_id) AS total_unique_filehandleids
    FROM
        download_data
    GROUP BY
        project_id;
    """


def query_downloaded_file_meta(project_ids, start_date, end_date, excluded_users=STAFF_USERIDS):
    """Return summary characteristics (assay type, resource type) of files downloaded for the given projects and timeframe."""

    project_list = ', '.join(f"'{id}'" for id in project_ids)

    return f"""
    WITH project_files AS (
        SELECT
            nl.file_handle_id AS file_handle_id,
            nl.project_id,
            JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.assay.value[0]') AS Assay,
            JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.resourceType.value[0]') AS Resource_Type
        FROM
            synapse_data_warehouse.synapse.node_latest nl
        WHERE
            nl.project_id IN ({project_list})
    ),
    downloaded_file_meta AS (
        SELECT
            pf.project_id,
            pf.Assay,
            pf.Resource_Type,
            objectdownload_event.file_handle_id
        FROM
            project_files pf
        JOIN
            synapse_data_warehouse.synapse_event.objectdownload_event objectdownload_event
        ON
            pf.file_handle_id = objectdownload_event.file_handle_id
        JOIN
            synapse_data_warehouse.synapse.file_latest filelatest
        ON
            filelatest.id = objectdownload_event.file_handle_id
        WHERE
            objectdownload_event.record_date between '{start_date}' and '{end_date}'
            -- AND file_handle_id = downloaded_file_handle_id
            AND objectdownload_event.user_id NOT IN ({','.join(map(str, STAFF_USERIDS))})
    )
    SELECT
        Assay,
        Resource_Type,
        COUNT(DISTINCT file_handle_id) AS download_count
    FROM
        downloaded_file_meta
    GROUP BY
        Assay,
        Resource_Type
    ORDER BY
        download_count DESC
    """


def query_monthly_file_egress(project_ids, start_date, end_date, excluded_users=STAFF_USERIDS):
    """Return summary monthly egress (number of unique files, size of data) for given projects and timeframe."""

    project_list = ', '.join(f"'{id}'" for id in project_ids)

    return f"""
   
    WITH egressed_files AS (
    SELECT
        objectdownload_event.file_handle_id, 
        objectdownload_event.user_id,
        objectdownload_event.record_date,
        objectdownload_event.project_id,
        filelatest.content_size
    FROM synapse_data_warehouse.synapse_event.objectdownload_event objectdownload_event
    JOIN
        synapse_data_warehouse.synapse.file_latest filelatest
    ON
        filelatest.id = objectdownload_event.file_handle_id
    WHERE
        objectdownload_event.record_date between '{start_date}' and '{end_date}'
        -- AND objectdownload_event.file_handle_id = objectdownload_event.downloaded_file_handle_id
        AND objectdownload_event.project_id IN ({project_list})
        AND objectdownload_event.user_id NOT IN ({','.join(map(str, excluded_users))})
    )
    SELECT
        project_id,
        DATE_TRUNC('month', record_date) AS access_month,
        COUNT(DISTINCT file_handle_id) AS file_count,
        -- SUM(content_size) AS total_downloads,
        COUNT(DISTINCT user_id) as unique_user_count
    FROM egressed_files
    GROUP BY
        project_id,
        access_month
    ORDER BY
        access_month,
        project_id
    """
 

def query_unique_users(project_ids, start_date, end_date, excluded_users=STAFF_USERIDS):
    """
    Characterize monthly unique user (downloader) interactions for given projects and timeframe.
    Note: This query **does not** return summarized data. Data should be summarized downstream.
    """

    project_list = ', '.join(f"'{id}'" for id in project_ids)

    return f"""
    WITH project_files AS (
    SELECT
        nl.file_handle_id AS file_handle_id,
        nl.project_id,
        JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.studyName.value[0]') AS project_name,
    FROM
        synapse_data_warehouse.synapse.node_latest nl
    WHERE
        nl.project_id IN ({project_list})
    ),
    file_access AS (
        SELECT
            pf.project_id,
            pf.project_name,
            objectdownload_event.user_id,
            DATE_TRUNC('month', objectdownload_event.TIMESTAMP) AS access_month
        FROM
            project_files pf
        JOIN
            synapse_data_warehouse.synapse_event.objectdownload_event objectdownload_event
        ON
            pf.file_handle_id = objectdownload_event.file_handle_id
        WHERE
            objectdownload_event.record_date between '{start_date}' and '{end_date}'
            AND objectdownload_event.user_id NOT IN ({','.join(map(str, excluded_users))})
    )
    SELECT distinct
        project_id,
        project_name,
        access_month,
        user_id
    FROM
        file_access
    """


def query_entity_distribution(synapse_id):
    """Returns number of files for a given project (synapse_id)."""

    return f"""
    
    with projects as (
        select
            cast(scopes.value as integer) as project_id
        from
            synapse_data_warehouse.synapse.node_latest,
            lateral flatten(input => node_latest.scope_ids) scopes
        where
            id = {synapse_id}
    )
    SELECT
        node_type,
        count(*) as number_of_files,
        count(*) * 100.0 / SUM(COUNT(*)) OVER () AS percentage_of_total
    FROM
        SYNAPSE_DATA_WAREHOUSE.SYNAPSE.NODE_LATEST
    JOIN
        projects
        on NODE_LATEST.project_id = projects.project_id
    group by
        node_type
    order by
        number_of_files DESC;
    """


def query_flag_missing_institution():
    """Return projects where PI's email or institution information is missing or unclear."""
    return """
    -- Step 1: Extract NF Project IDs
    WITH nf_project_scope AS (
        SELECT
            CAST(scopes.value AS INTEGER) AS scope_id
        FROM
            synapse_data_warehouse.synapse.node_latest,
            LATERAL FLATTEN(input => node_latest.scope_ids) scopes
        WHERE
            id = 52677631
    ),

    -- Step 2: Align PI Emails with NF Projects
    project_nodes AS (
        SELECT
            nl.id AS project_id,
            nl.name AS project_name,
            nl.created_by AS pi_user_id,
            up.email AS pi_email,
            COALESCE(up.company, up.location) AS pi_institution
        FROM
            synapse_data_warehouse.synapse.node_latest nl
        LEFT JOIN
            synapse_data_warehouse.synapse.userprofile_latest up
            ON nl.created_by = up.id
        WHERE
            nl.node_type = 'project'
    ),

    -- Step 3: Filter and Flag Issues
    flagged_projects AS (
        SELECT
            pn.project_id,
            pn.project_name,
            pn.pi_user_id,
            pn.pi_email,
            pn.pi_institution,
            CASE
                WHEN pn.pi_email IS NULL THEN 'Missing Email'
                WHEN pn.pi_institution IS NULL THEN 'Missing Institution'
                WHEN LOWER(pn.pi_institution) LIKE '%unknown%' OR LOWER(pn.pi_institution) LIKE '%n/a%' THEN 'Unclear Institution'
                ELSE 'Valid'
            END AS issue_type
        FROM
            project_nodes pn
        JOIN
            nf_project_scope nps
        ON
            pn.project_id = nps.scope_id
    )

    -- Step 4: Output Filtered Results
    SELECT *
    FROM flagged_projects
    WHERE issue_type != 'Valid'
    ORDER BY issue_type, project_name;
    """


def query_access_requirements():
    """Return access requirements for NF projects."""
    return """
    -- 1) Get NF Project IDs
    WITH nf_project_scope AS (
        SELECT
            CAST(scopes.value AS INTEGER) AS scope_id
        FROM
            synapse_data_warehouse.synapse.node_latest,
            LATERAL FLATTEN(input => node_latest.scope_ids) scopes
        WHERE
            id = 52677631
    ),

    -- 2) Flatten the effective_ars array to extract each AR ID
    nf_projects_with_ar AS (
        SELECT
            nl.id AS entity_id,
            nl.name AS entity_name,
            CAST(ar.value AS INTEGER) AS ar_id
        FROM
            synapse_data_warehouse.synapse.node_latest nl
            JOIN nf_project_scope nps ON nl.id = nps.scope_id
            CROSS JOIN LATERAL FLATTEN(input => nl.effective_ars) ar
    )

    -- 3) Join AR IDs to accessrequirement_latest for requirement details
    SELECT
        p.entity_id,
        p.entity_name,
        a.id AS ar_id,
        a.name AS ar_name,
        a.is_duc_required,
        a.is_irb_approval_required,
        a.is_idu_required,
        a.is_certified_user_required,
        a.is_validated_profile_required,
        a.is_two_fa_required
    FROM nf_projects_with_ar p
    JOIN synapse_data_warehouse.synapse.accessrequirement_latest a
        ON p.ar_id = a.id
    ORDER BY p.entity_id, a.id;
    """


def query_file_metadata_for_growth(project_ids):
    """Return individual file metadata with creation dates and sizes for cumulative growth analysis."""
    
    project_list = ', '.join(f"'{id}'" for id in project_ids)
    
    return f"""
    SELECT
        nl.project_id,
        nl.file_handle_id,
        nl.created_on,
        filelatest.content_size
    FROM
        synapse_data_warehouse.synapse.node_latest nl
    JOIN
        synapse_data_warehouse.synapse.file_latest filelatest
    ON
        filelatest.id = nl.file_handle_id
    WHERE
        nl.project_id IN ({project_list})
        AND nl.file_handle_id IS NOT NULL
        AND filelatest.content_size IS NOT NULL
        AND filelatest.content_size > 0
    ORDER BY
        nl.created_on;
    """


def query_all_initiatives():
    """Return all unique initiative values from project annotations."""
    return f"""
    SELECT DISTINCT 
        f.value AS initiative_value
    FROM 
        SYNAPSE_DATA_WAREHOUSE.SYNAPSE.NODE_LATEST,
        LATERAL FLATTEN(input => annotations:annotations:initiative:value) f
    WHERE 
        node_type = 'project' 
        AND annotations:annotations:initiative IS NOT NULL
    ORDER BY 
        initiative_value
    """


def query_project_meta_with_initiative(funder="NTAP", initiatives=None):
    """Return project metadata for projects filtered by funder and optionally by initiative."""
    
    where_clauses = []
    
    if funder != 'all':
        where_clauses.append(f"CONTAINS(funder, '{funder}')")
    
    # Add initiative filter if provided
    if initiatives and len(initiatives) > 0:
        # Create initiative filter for any of the selected initiatives
        initiative_conditions = []
        for init in initiatives:
            # Escape quotes in the initiative value
            escaped_init = init.replace('"', '\\"')
            initiative_conditions.append(f"ARRAY_CONTAINS('{escaped_init}'::VARIANT, PARSE_JSON(JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.initiative.value')))")
        
        initiative_filter = "(" + " OR ".join(initiative_conditions) + ")"
        where_clauses.append(initiative_filter)
    
    where_clause = "WHERE " + " AND ".join(where_clauses) if where_clauses else ""

    return f"""
    WITH project_scope AS (
        SELECT
            CAST(scopes.value AS INTEGER) AS scope_id
        FROM
            synapse_data_warehouse.synapse.node_latest,
            LATERAL FLATTEN(input => node_latest.scope_ids) scopes
        WHERE
            id = {PROJECT_VIEW_ID}
    )
    SELECT
        nl.id AS project_id,
        JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.studyName.value[0]') AS project_name,
        JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.fundingAgency.value') AS funder,
        ARRAY_TO_STRING(PARSE_JSON(JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.studyLeads.value')), ', ') AS study_leads,
        JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.studyStatus.value[0]') AS study_status,
        JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.dataStatus.value[0]') AS data_status,
        JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.initiative.value') AS initiative
    FROM
        synapse_data_warehouse.synapse.node_latest nl
    JOIN
        project_scope ps ON nl.id = ps.scope_id
    {where_clause}
    ORDER BY
        project_name;
    """


def query_total_data_size_by_initiative(project_ids):
    """
    Q1: Return total data size across scoped projects.
    Aggregates content size of all files in the specified projects.
    """
    
    project_list = ', '.join(f"'{id}'" for id in project_ids)
    
    return f"""
    WITH project_files AS (
        SELECT
            nl.file_handle_id AS file_handle_id,
            nl.project_id
        FROM
            synapse_data_warehouse.synapse.node_latest nl
        WHERE
            nl.project_id IN ({project_list})
            AND nl.file_handle_id IS NOT NULL
    ),
    file_content_size AS (
        SELECT
            pf.project_id,
            filelatest.id,
            filelatest.content_size
        FROM
            synapse_data_warehouse.synapse.file_latest filelatest
        JOIN
            project_files pf
        ON
            filelatest.id = pf.file_handle_id
        WHERE
            filelatest.content_size IS NOT NULL
    )
    SELECT
        SUM(content_size) AS total_content_size,
        COUNT(DISTINCT id) AS total_file_count
    FROM
        file_content_size;
    """


def query_top_data_types_by_size(project_ids, limit=5):
    """
    Q2: Return top N data types by size across scoped projects.
    Groups by assay annotation and returns ranked list with size and file count.
    """
    
    project_list = ', '.join(f"'{id}'" for id in project_ids)
    
    return f"""
    WITH project_files AS (
        SELECT
            nl.file_handle_id AS file_handle_id,
            nl.project_id,
            JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.assay.value[0]') AS data_type
        FROM
            synapse_data_warehouse.synapse.node_latest nl
        WHERE
            nl.project_id IN ({project_list})
            AND nl.file_handle_id IS NOT NULL
    ),
    file_with_size AS (
        SELECT
            pf.data_type,
            filelatest.id AS file_handle_id,
            filelatest.content_size
        FROM
            synapse_data_warehouse.synapse.file_latest filelatest
        JOIN
            project_files pf
        ON
            filelatest.id = pf.file_handle_id
        WHERE
            filelatest.content_size IS NOT NULL
            AND pf.data_type IS NOT NULL
    )
    SELECT
        COALESCE(data_type, 'Unknown') AS data_type,
        SUM(content_size) AS total_size,
        COUNT(DISTINCT file_handle_id) AS file_count
    FROM
        file_with_size
    GROUP BY
        data_type
    ORDER BY
        total_size DESC,
        data_type ASC
    LIMIT {limit};
    """


def query_released_data_by_type(project_ids, released_statuses=None, limit=5):
    """
    Q3: Return data types by size for released data only.
    Filters to projects with released data status and groups by assay type.
    """
    
    if released_statuses is None:
        released_statuses = ['Available', 'Partially Available', 'Rolling Release']
    
    project_list = ', '.join(f"'{id}'" for id in project_ids)
    status_list = ', '.join(f"'{status}'" for status in released_statuses)
    
    return f"""
    WITH released_projects AS (
        SELECT
            nl.id AS project_id
        FROM
            synapse_data_warehouse.synapse.node_latest nl
        WHERE
            nl.id IN ({project_list})
            AND nl.node_type = 'project'
            AND JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.dataStatus.value[0]') IN ({status_list})
    ),
    project_files AS (
        SELECT
            nl.file_handle_id AS file_handle_id,
            nl.project_id,
            JSON_EXTRACT_PATH_TEXT(nl.ANNOTATIONS, 'annotations.assay.value[0]') AS data_type
        FROM
            synapse_data_warehouse.synapse.node_latest nl
        JOIN
            released_projects rp ON nl.project_id = rp.project_id
        WHERE
            nl.file_handle_id IS NOT NULL
    ),
    file_with_size AS (
        SELECT
            pf.data_type,
            filelatest.id AS file_handle_id,
            filelatest.content_size
        FROM
            synapse_data_warehouse.synapse.file_latest filelatest
        JOIN
            project_files pf
        ON
            filelatest.id = pf.file_handle_id
        WHERE
            filelatest.content_size IS NOT NULL
            AND pf.data_type IS NOT NULL
    )
    SELECT
        COALESCE(data_type, 'Unknown') AS data_type,
        SUM(content_size) AS total_size,
        COUNT(DISTINCT file_handle_id) AS file_count
    FROM
        file_with_size
    GROUP BY
        data_type
    ORDER BY
        total_size DESC,
        data_type ASC
    LIMIT {limit};
    """


def query_user_demographics(project_ids, start_date, end_date, excluded_users=STAFF_USERIDS):
    """
    Return user profile info (company, email, location) for all non-staff downloaders
    within the given projects and date window. Used to classify users by sector
    (Academic/Industry/International) per NTAP feedback on the Task 2.4 Project
    Analytics Report.
    """
    project_list = ", ".join(f"'{id}'" for id in project_ids)
    excluded = ", ".join(map(str, excluded_users))

    return f"""
    WITH downloaders AS (
        SELECT DISTINCT od.user_id
        FROM synapse_data_warehouse.synapse_event.objectdownload_event od
        WHERE od.project_id IN ({project_list})
          AND od.record_date BETWEEN '{start_date}' AND '{end_date}'
          AND od.user_id NOT IN ({excluded})
    )
    SELECT
        d.user_id,
        up.company,
        up.email,
        up.location
    FROM downloaders d
    LEFT JOIN synapse_data_warehouse.synapse.userprofile_latest up
        ON up.id = d.user_id
    WHERE (up.email IS NULL
       OR (up.email NOT ILIKE '%@sagebase.org'
           AND up.email NOT ILIKE '%@sagebionetworks.org'))
    """
