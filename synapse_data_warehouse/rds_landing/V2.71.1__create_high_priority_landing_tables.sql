USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

EXECUTE IMMEDIATE $$
DECLARE
    snapshot_folder STRING;
    prefix_base STRING;
    loc_pfx STRING;
    ff STRING;
BEGIN
    -- Update snapshot_folder and prefix_base when a new snapshot is taken.
    -- Adjust the ILIKE condition below to match your actual database name pattern.
    IF (CURRENT_DATABASE() ILIKE '%dev%') THEN
        snapshot_folder := 'dev-583-db-2026-04-01-2026-04-01';
        prefix_base := 'dev583';
    ELSE
        snapshot_folder := 'prod-589-db-2026-05-20';
        prefix_base := 'prod589';
    END IF;

    loc_pfx := '@' || CURRENT_DATABASE()
        || '.RDS_LANDING.RDS_SNAPSHOTS_STAGE/rds-snapshot/'
        || snapshot_folder || '/' || prefix_base || '/' || prefix_base || '.';
    ff := CURRENT_DATABASE() || '.RDS_LANDING.parquet_ff';

    -- access_approval
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_access_approval'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'ACCESS_APPROVAL/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- acl
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_acl'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'ACL/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- acl_resource_access
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_acl_resource_access'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'ACL_RESOURCE_ACCESS/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- acl_resource_access_type
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_acl_resource_access_type'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'ACL_RESOURCE_ACCESS_TYPE/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- data_access_submission
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_data_access_submission'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'DATA_ACCESS_SUBMISSION/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- data_access_submission_accessor_changes
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_data_access_submission_accessor_changes'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'DATA_ACCESS_SUBMISSION_ACCESSOR_CHANGES/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- data_access_submission_status
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_data_access_submission_status'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'DATA_ACCESS_SUBMISSION_STATUS/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- data_access_submission_submitter
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_data_access_submission_submitter'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'DATA_ACCESS_SUBMISSION_SUBMITTER/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- data_access_request
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_data_access_request'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'DATA_ACCESS_REQUEST/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- access_requirement
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_access_requirement'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'ACCESS_REQUIREMENT/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- access_requirement_project
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_access_requirement_project'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'ACCESS_REQUIREMENT_PROJECT/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- access_requirement_revision
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_access_requirement_revision'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'ACCESS_REQUIREMENT_REVISION/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- data_access_notification
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_data_access_notification'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'DATA_ACCESS_NOTIFICATION/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';

    -- principal_alias
    EXECUTE IMMEDIATE
        'CREATE TABLE IF NOT EXISTS lan_synapse_principal_alias'
        || ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA('
        || 'LOCATION => ''' || loc_pfx || 'PRINCIPAL_ALIAS/1/'', FILE_FORMAT => ''' || ff || ''''
        || ')))';
END;
$$;