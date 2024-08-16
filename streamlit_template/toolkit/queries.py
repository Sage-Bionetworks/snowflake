def query_entity_distribution(synapse_id=20446927):
    """Returns the number of files for a given project (synapse_id)."""

    return f"""
    with htan_projects as (
        // select distinct cast(replace(NF.projectid, 'syn', '') as INTEGER) as project_id from sage.portal_raw.HTAN
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
        htan_projects
        on NODE_LATEST.project_id = htan_projects.project_id
    group by
        node_type
    order by
        number_of_files DESC;
    """

def query_project_sizes():
    """Return the cumulative size of all projects."""

    return """
    WITH htan_projects AS (
    SELECT
        CAST(scopes.value AS INTEGER) AS project_id
    FROM
        synapse_data_warehouse.synapse.node_latest,
        LATERAL FLATTEN(input => node_latest.scope_ids) scopes
    WHERE
        id = 20446927
    ),
    project_files AS (
    SELECT
    nl.id AS node_id,
    hp.project_id
    FROM
    synapse_data_warehouse.synapse.node_latest nl
    JOIN
    htan_projects hp
    ON
    nl.project_id = hp.project_id
    ),
    file_content_size AS (
    SELECT distinct
        pf.project_id,
        filelatest.id,
        filelatest.content_size
    FROM
        synapse_data_warehouse.synapse.file_latest filelatest
    JOIN
        synapse_data_warehouse.synapse.filedownload filedownload
    ON
        filelatest.id = filedownload.file_handle_id
    JOIN
        project_files pf
    ON
        filedownload.file_handle_id = pf.node_id
    )
    SELECT
        project_id,
        SUM(content_size) AS total_content_size
    FROM
        file_content_size
    GROUP BY
        project_id;
    """

def query_project_downloads():
    """Return the total number of downloads for all projects."""

    return """
    WITH htan_projects AS (
        SELECT
            CAST(scopes.value AS INTEGER) AS project_id
        FROM
            synapse_data_warehouse.synapse.node_latest,
            LATERAL FLATTEN(input => node_latest.scope_ids) scopes
        WHERE
            id = 20446927
    ),
    project_files AS (
        SELECT
            nl.id AS node_id,
            hp.project_id
        FROM
            synapse_data_warehouse.synapse.node_latest nl
        JOIN
            htan_projects hp
        ON
            nl.project_id = hp.project_id
    ),
    file_content_size AS (
        SELECT
            pf.project_id,
            filedownload.file_handle_id,
            filelatest.content_size
        FROM
            project_files pf
        JOIN
            synapse_data_warehouse.synapse.filedownload filedownload
        ON
            pf.node_id = filedownload.file_handle_id
        JOIN
            synapse_data_warehouse.synapse.file_latest filelatest
        ON
            filelatest.id = filedownload.file_handle_id
    )
    SELECT
        project_id,
        SUM(content_size) AS total_downloads
    FROM
        file_content_size
    GROUP BY
        project_id;
    """

def query_unique_users(months_back):
    """Return the number of monthly unique users going back x months (months_back)."""

    return f"""
    WITH htan_projects AS (
        SELECT
            CAST(scopes.value AS INTEGER) AS project_id
        FROM
            synapse_data_warehouse.synapse.node_latest,
            LATERAL FLATTEN(input => node_latest.scope_ids) scopes
        WHERE
            id = 20446927
    ),
    project_files AS (
        SELECT
            nl.id AS node_id,
            hp.project_id
        FROM
            synapse_data_warehouse.synapse.node_latest nl
        JOIN
            htan_projects hp
        ON
            nl.project_id = hp.project_id
    ),
    file_access AS (
        SELECT
            pf.project_id,
            filedownload.user_id,
            DATE_TRUNC('month', filedownload.TIMESTAMP) AS access_month
        FROM
            project_files pf
        JOIN
            synapse_data_warehouse.synapse.filedownload filedownload
        ON
            pf.node_id = filedownload.file_handle_id
        WHERE
            filedownload.TIMESTAMP >= DATEADD(month, -{months_back}, CURRENT_DATE)
    )
    SELECT
        project_id,
        access_month,
        COUNT(DISTINCT user_id) AS distinct_user_count
    FROM
        file_access
    GROUP BY
        project_id,
        access_month
    ORDER BY
        project_id,
        access_month;
    """
