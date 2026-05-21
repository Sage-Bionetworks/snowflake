USE SCHEMA {{database_name}}.RDS_LANDING; --noqa: JJ01,PRS,TMP

-- access_approval
CREATE TABLE IF NOT EXISTS lan_synapse_access_approval (
    id                  BIGINT    COMMENT 'Unique identifier for the access approval record',
    requirement_id      BIGINT    COMMENT 'Which requirement this approval satisfies',
    requirement_version BIGINT    COMMENT 'Version number of the access requirement at the time of approval',
    created_by          BIGINT    COMMENT 'Identifier of the user who created this access approval',
    created_on          BIGINT    COMMENT 'Epoch milliseconds when the access approval was created',
    modified_by         BIGINT    COMMENT 'Identifier of the user who last modified this access approval',
    modified_on         BIGINT    COMMENT 'Epoch milliseconds when the access approval was last modified',
    submitter_id        BIGINT    COMMENT 'User ID of the person who submitted the approval request',
    accessor_id         BIGINT    COMMENT 'User ID of the person being granted access',
    expired_on          BIGINT    COMMENT 'Epoch milliseconds when the approval expires. 0 means no expiration.',
    state               VARCHAR   COMMENT 'State of the access approval. Valid values are APPROVED or REVOKED.',
    etag                VARCHAR   COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- acl
CREATE TABLE IF NOT EXISTS lan_synapse_acl (
    id         BIGINT  COMMENT 'Unique identifier for the ACL (Access Control List)',
    owner_id   BIGINT  COMMENT 'ID of the entity or object that this ACL grants access to',
    owner_type VARCHAR COMMENT 'Type of entity or object that owns this ACL',
    created_on BIGINT  COMMENT 'Epoch milliseconds when the ACL was created',
    etag       VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- acl_resource_access
CREATE TABLE IF NOT EXISTS lan_synapse_acl_resource_access (
    id       BIGINT COMMENT 'Unique identifier for this ACL resource access',
    owner_id BIGINT COMMENT 'The ACL identifier',
    group_id BIGINT COMMENT 'The user or team being granted access'
);

-- acl_resource_access_type
CREATE TABLE IF NOT EXISTS lan_synapse_acl_resource_access_type (
    id_oid     BIGINT  COMMENT 'The ACL resource access identifier',
    string_ele VARCHAR COMMENT 'The permission type (e.g., READ, UPDATE, DELETE, CHANGE_PERMISSIONS, DOWNLOAD, CREATE)',
    owner_id   BIGINT  COMMENT 'The ACL identifier'
);

-- data_access_submission
CREATE TABLE IF NOT EXISTS lan_synapse_data_access_submission (
    id                         BIGINT  COMMENT 'Unique identifier for the data access submission',
    access_requirement_id      BIGINT  COMMENT 'The access requirement identifier',
    data_access_request_id     BIGINT  COMMENT 'The data access request identifier',
    research_project_id        BIGINT  COMMENT 'The research project associated with this submission',
    created_by                 BIGINT  COMMENT 'Identifier of the user who made this submission',
    created_on                 BIGINT  COMMENT 'Epoch milliseconds when the submission was created',
    access_requirement_version BIGINT  COMMENT 'Version of the access requirement at the time of submission',
    etag                       VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    submission_serialized      BINARY  COMMENT 'Serialized representation of the complete submission object'
);

-- data_access_submission_accessor_changes
CREATE TABLE IF NOT EXISTS lan_synapse_data_access_submission_accessor_changes (
    submission_id BIGINT  COMMENT 'The data access submission identifier',
    accessor_id   BIGINT  COMMENT 'Identifier of the user whose access is being changed',
    access_type   VARCHAR COMMENT 'Type of access change. One of: GAIN_ACCESS, RENEW_ACCESS, REVOKE_ACCESS'
);

-- data_access_submission_status
CREATE TABLE IF NOT EXISTS lan_synapse_data_access_submission_status (
    submission_id BIGINT  COMMENT 'The data access submission identifier',
    created_by    BIGINT  COMMENT 'Identifier of the user who created this status record',
    created_on    BIGINT  COMMENT 'Epoch milliseconds when the status was created',
    modified_by   BIGINT  COMMENT 'User ID of the person who last modified this status',
    modified_on   BIGINT  COMMENT 'Epoch milliseconds when the submission status was last modified',
    state         VARCHAR COMMENT 'Current state. One of: Submitted, Approved, Rejected, Cancelled',
    reason        BINARY  COMMENT 'Binary blob containing the reason for the current state. Null for records before 2019 due to invalid UTF-8.'
);

-- data_access_submission_submitter
CREATE TABLE IF NOT EXISTS lan_synapse_data_access_submission_submitter (
    id                    BIGINT  COMMENT 'Unique identifier for this submitter record',
    access_requirement_id BIGINT  COMMENT 'The access requirement identifier',
    submitter_id          BIGINT  COMMENT 'User ID of the submitter',
    current_submission_id BIGINT  COMMENT 'The current active data access submission',
    etag                  VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- data_access_request
CREATE TABLE IF NOT EXISTS lan_synapse_data_access_request (
    id                    BIGINT  COMMENT 'Unique identifier for the data access request',
    access_requirement_id BIGINT  COMMENT 'Which access requirement this request is for',
    research_project_id   BIGINT  COMMENT 'The identifier of the research project which this data access request associates with',
    created_by            BIGINT  COMMENT 'Identifier of the user who created this request',
    created_on            BIGINT  COMMENT 'Epoch milliseconds when the request was created',
    modified_by           BIGINT  COMMENT 'Identifier of the user who last modified this request',
    modified_on           BIGINT  COMMENT 'Epoch milliseconds when the request was last modified',
    etag                  VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)',
    request_serialized    BINARY  COMMENT 'Serialized representation of the complete request object'
);

-- access_requirement
CREATE TABLE IF NOT EXISTS lan_synapse_access_requirement (
    id                 BIGINT  COMMENT 'Unique identifier for the access requirement',
    name               VARCHAR COMMENT 'Unique human-readable name for the access requirement',
    concrete_type      VARCHAR COMMENT 'Fully qualified class name for the access requirement type',
    created_by         BIGINT  COMMENT 'Identifier of the user who created this access requirement',
    created_on         BIGINT  COMMENT 'Epoch milliseconds when the access requirement was created',
    current_rev_num    BIGINT  COMMENT 'Current revision number of this access requirement. Revision numbers begin from 0.',
    is_two_fa_required BOOLEAN COMMENT 'Boolean flag indicating whether two-factor authentication is required for this access',
    access_type        VARCHAR COMMENT 'Type of access controlled by this requirement',
    etag               VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- access_requirement_project
CREATE TABLE IF NOT EXISTS lan_synapse_access_requirement_project (
    ar_id      BIGINT COMMENT 'The access requirement identifier',
    project_id BIGINT COMMENT 'The identifier of the project entity which this access requirement associates with'
);

-- access_requirement_revision
CREATE TABLE IF NOT EXISTS lan_synapse_access_requirement_revision (
    owner_id          BIGINT COMMENT 'The access requirement identifier',
    number            BIGINT COMMENT 'Revision number for this version of the access requirement. Revision numbers begin from 0.',
    modified_by       BIGINT COMMENT 'Identifier of the user who created this revision (i.e., modified the access requirement)',
    modified_on       BIGINT COMMENT 'Epoch milliseconds when this revision was created',
    serialized_entity BINARY COMMENT 'Serialized representation of the complete access requirement object at this revision'
);

-- data_access_notification
CREATE TABLE IF NOT EXISTS lan_synapse_data_access_notification (
    id                 BIGINT  COMMENT 'Unique identifier for the notification record',
    notification_type  VARCHAR COMMENT 'Type of notification sent. One of: FIRST_RENEWAL_REMINDER, SECOND_RENEWAL_REMINDER, REVOCATION',
    requirement_id     BIGINT  COMMENT 'The access requirement identifier',
    recipient_id       BIGINT  COMMENT 'User ID of the notification recipient',
    access_approval_id BIGINT  COMMENT 'The identifier of the associated access approval',
    sent_on            BIGINT  COMMENT 'Epoch milliseconds when the notification was sent',
    message_id         VARCHAR COMMENT 'Unique identifier of the message',
    etag               VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);

-- principal_alias
CREATE TABLE IF NOT EXISTS lan_synapse_principal_alias (
    id            BIGINT  COMMENT 'Unique identifier for the principal alias record',
    principal_id  BIGINT  COMMENT 'The globally unique identifier of the principal (user ID or team ID)',
    alias_unique  VARCHAR COMMENT 'Unique normalized alias value used for lookups. Guaranteed to be globally unique across all principals.',
    alias_display VARCHAR COMMENT 'Display version of the alias, preserving original character casing and formatting',
    type          VARCHAR COMMENT 'Type of alias. One of: USER_NAME, TEAM_NAME, USER_EMAIL, USER_OPEN_ID, USER_ORCID',
    etag          VARCHAR COMMENT 'Entity tag for optimistic concurrency control (36-character UUID)'
);