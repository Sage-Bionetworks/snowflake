USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- * SNOW-11 add user profile snapshots
CREATE TABLE IF NOT EXISTS userprofilesnapshot (
    change_type STRING,
    change_timestamp TIMESTAMP,
    change_user_id NUMBER,
    snapshot_timestamp TIMESTAMP,
    id NUMBER,
    user_name STRING,
    first_name STRING,
    last_name STRING,
    email STRING,
    location STRING,
    company STRING,
    position STRING,
    snapshot_date DATE
)
CLUSTER BY (snapshot_date);

-- * SNOW-1
CREATE TABLE IF NOT EXISTS nodesnapshots (
    change_type STRING,
    change_timestamp TIMESTAMP,
    change_user_id NUMBER,
    snapshot_timestamp TIMESTAMP,
    id NUMBER,
    benefactor_id NUMBER,
    project_id NUMBER,
    parent_id NUMBER,
    node_type STRING,
    created_on TIMESTAMP,
    created_by NUMBER,
    modified_on TIMESTAMP,
    modified_by NUMBER,
    version_number NUMBER,
    file_handle_id NUMBER,
    name STRING,
    is_public BOOLEAN,
    is_controlled BOOLEAN,
    is_restricted BOOLEAN,
    snapshot_date DATE
)
CLUSTER BY (snapshot_date);

-- * SNOW-4 create certified quiz
CREATE TABLE IF NOT EXISTS certifiedquiz (
    response_id NUMBER,
    user_id NUMBER,
    passed BOOLEAN,
    passed_on TIMESTAMP,
    stack STRING,
    instance STRING,
    record_date DATE
)
CLUSTER BY (record_date);

CREATE TABLE IF NOT EXISTS certifiedquizquestion (
    response_id NUMBER,
    question_index NUMBER,
    is_correct BOOLEAN,
    stack STRING,
    instance STRING,
    record_date DATE
)
CLUSTER BY (record_date);

-- * SNOW-5
CREATE TABLE IF NOT EXISTS filedownload (
    timestamp TIMESTAMP,
    user_id NUMBER,
    project_id NUMBER,
    file_handle_id NUMBER,
    downloaded_file_handle_id NUMBER,
    association_object_id NUMBER,
    association_object_type STRING,
    stack STRING,
    instance STRING,
    record_date DATE
)
CLUSTER BY (record_date);

-- * SNOW-2
CREATE TABLE IF NOT EXISTS aclsnapshots (
    change_timestamp TIMESTAMP,
    change_type STRING,
    snapshot_timestamp TIMESTAMP,
    owner_id NUMBER,
    owner_type STRING,
    created_on TIMESTAMP,
    resource_access STRING,
    snapshot_date DATE
)
CLUSTER BY (snapshot_date);

-- * SNOW-9
CREATE TABLE IF NOT EXISTS teamsnapshots (
    change_type STRING,
    change_timestamp TIMESTAMP,
    change_user_id NUMBER,
    snapshot_timestamp TIMESTAMP,
    id NUMBER,
    name STRING,
    can_public_join BOOLEAN,
    created_on TIMESTAMP,
    created_by NUMBER,
    modified_on TIMESTAMP,
    modified_by NUMBER,
    snapshot_date DATE
)
CLUSTER BY (snapshot_date);

-- * SNOW-10 add user group snapshots
CREATE TABLE IF NOT EXISTS usergroupsnapshots (
    change_type STRING,
    change_timestamp TIMESTAMP,
    change_user_id NUMBER,
    snapshot_timestamp TIMESTAMP,
    id NUMBER,
    is_individual BOOLEAN,
    created_on TIMESTAMP,
    snapshot_date DATE
)
CLUSTER BY (snapshot_date);

// Create verification submission snapshots table
CREATE TABLE IF NOT EXISTS verificationsubmissionsnapshots (
    change_timestamp TIMESTAMP,
    change_type STRING,
    snapshot_timestamp TIMESTAMP,
    id NUMBER,
    created_on TIMESTAMP,
    created_by NUMBER,
    state_history STRING,
    snapshot_date DATE
)
CLUSTER BY (snapshot_date);

-- * SNOW-8
CREATE TABLE IF NOT EXISTS teammembersnapshots (
    change_type STRING,
    change_timestamp TIMESTAMP,
    change_user_id NUMBER,
    snapshot_timestamp TIMESTAMP,
    team_id NUMBER,
    member_id NUMBER,
    is_admin BOOLEAN,
    snapshot_date DATE
)
CLUSTER BY (snapshot_date);

CREATE TABLE IF NOT EXISTS fileupload (
    timestamp TIMESTAMP,
    user_id NUMBER,
    project_id NUMBER,
    file_handle_id NUMBER,
    association_object_id NUMBER,
    association_object_type STRING,
    stack STRING,
    instance STRING,
    record_date DATE
)
CLUSTER BY (record_date);

-- * SNOW-6
CREATE TABLE IF NOT EXISTS filesnapshots (
    change_type STRING,
    change_timestamp TIMESTAMP,
    change_user_id NUMBER,
    snapshot_timestamp TIMESTAMP,
    id NUMBER,
    created_by NUMBER,
    created_on TIMESTAMP,
    modified_on TIMESTAMP,
    concrete_type STRING,
    content_md5 STRING,
    content_type STRING,
    file_name STRING,
    storage_location_id NUMBER,
    content_size NUMBER,
    bucket STRING,
    key STRING,
    preview_id NUMBER,
    is_preview BOOLEAN,
    status STRING,
    snapshot_date DATE
)
CLUSTER BY (snapshot_date);

-- * SNOW-7
CREATE TABLE IF NOT EXISTS processedaccess (
    session_id STRING,
    timestamp TIMESTAMP,
    user_id NUMBER,
    method STRING,
    request_url STRING,
    user_agent STRING,
    host STRING,
    origin STRING,
    x_forwarded_for STRING,
    via STRING,
    thread_id NUMBER,
    elapse_ms NUMBER,
    success BOOLEAN,
    stack STRING,
    instance STRING,
    vm_id STRING,
    return_object_id STRING,
    query_string STRING,
    response_status NUMBER,
    oauth_client_id STRING,
    basic_auth_username STRING,
    auth_method STRING,
    normalized_method_signature STRING,
    client STRING,
    client_version STRING,
    entity_id NUMBER,
    record_date DATE
)
CLUSTER BY (record_date);
