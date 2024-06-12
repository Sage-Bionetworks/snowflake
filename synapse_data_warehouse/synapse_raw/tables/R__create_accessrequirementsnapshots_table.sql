USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP
USE WAREHOUSE COMPUTE_MEDIUM;

CREATE OR ALTER TABLE ACCESSREQUIREMENTSNAPSHOTS (
    CHANGE_TIMESTAMP TIMESTAMP COMMENT 'The time when the change (created/updated/deleted) on an access requirement is pushed to the queue for snapshotting.',
    CHANGE_TYPE VARCHAR(16777216) COMMENT 'The type of change that occurred on the access requirement, e.g., CREATE, UPDATE, DELETE.',
    CHANGE_USER_ID NUMBER(38,0) COMMENT 'The id of the user that created, updated or deleted the access requirement being snapshotted',
    SNAPSHOT_TIMESTAMP TIMESTAMP COMMENT 'The time when the snapshot was taken (It is usually after the change happened).',
    ID NUMBER(38,0) COMMENT 'The unique identifier of the access requirement.',
    VERSION_NUMBER NUMBER(38,0) COMMENT 'The version of the access requirement. Each time an access requirement is updated a new version is issued.',
    NAME VARCHAR(16777216) COMMENT 'The name assigned to the access requirement.',
    DESCRIPTION VARCHAR(16777216) COMMENT 'The description assigned to the access requirement.',
    CREATED_BY NUMBER(38,0) COMMENT 'The id of the user that created the access requirement.',
    MODIFIED_BY NUMBER(38,0) COMMENT 'The id of the user that modified the access requirement.',
    CREATED_ON TIMESTAMP COMMENT 'The creation time of the access requirement.',
    MODIFIED_ON TIMESTAMP COMMENT 'The most recent change time of the access requirement.',
    ACCESS_TYPE VARCHAR(16777216) COMMENT 'The type of access this access requirement applies to, currently supports only DOWNLOAD (for entities) and PARTICIPATE (for teams).',
    CONCRETE_TYPE VARCHAR(16777216) COMMENT 'The type of access requirement. See https://rest-docs.synapse.org/rest/org/sagebionetworks/repo/model/AccessRequirement.html.',
    SUBJECTS_DEFINED_BY_ANNOTATIONS BOOLEAN COMMENT 'True if the subjects of the access requirement are automatically inferred by derived annotations. If true the subjectIds will be empty.',
    SUBJECTS_IDS ARRAY COMMENT 'The list of objects controlled by this access requirement. If the access_type is DOWNLOAD each element will be an ENTITY, If the access_type is PARTICIPATE each element will be a TEAM. This list is empty if subjects_defined_by_annotations is true.',
    IS_CERTIFIED_USER_REQUIRED BOOLEAN COMMENT 'True if the user certification is required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement and SelfSignAccessRequirement.',
    IS_VALIDATED_PROFILE_REQUIRED BOOLEAN COMMENT 'True if the profile validation is required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement and SelfSignAccessRequirement.',
    IS_DUC_REQUIRED BOOLEAN COMMENT 'True if a Data Use Certificate (DUC) is required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement.',
    IS_IRB_APPROVAL_REQUIRED BOOLEAN COMMENT 'True if an Institutional Review Board (IRB) approval document is required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement.',
    ARE_OTHER_ATTACHMENTS_REQUIRED BOOLEAN COMMENT 'True if additional attachment(s) are required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement.',
    IS_IDU_PUBLIC BOOLEAN COMMENT 'True if the Intended Data Use Statements submitted to gain access to the data will be presented to public. Applies only to ManagedACTAccessRequirement.',
    IS_IDU_REQUIRED BOOLEAN COMMENT 'True the Intended Data Use Statement for a research project is required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement.',
    IS_TWO_FA_REQUIRED BOOLEAN COMMENT 'True if two factor authentication is required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement.',
    DUC_TEMPLATE_FILE_HANDLE_ID NUMBER(38,0) COMMENT 'The id of the file handle containing the DUC template (if a DUC is required) that needs to be filled and signed by users to fulfill the access requirement. Applies only to ManagedACTAccessRequirement.',
    EXPIRATION_PERIOD NUMBER(38,0) COMMENT 'The amount in milliseconds that an approval of this access requirement is valid for. Applies only to ManagedACTAccessRequirement.',
    TERMS_OF_USER VARCHAR(16777216) COMMENT 'The terms of use text. Applies only to TermsOfUseAccessRequirement.',
    ACT_CONTACT_INFO VARCHAR(16777216) COMMENT 'Information on how to contact the Synapse ACT for access approval (external to Synapse). Applies only to ACTAccessRequirement.',
    OPEN_JIRA_ISSUE BOOLEAN COMMENT 'Flag that indicate if a JIRA issue needs to be opened in addition to follow the act_contact_info . Applies only to ACTAccessRequirement.',
    JIRA_KEY VARCHAR(16777216) COMMENT 'The key of the jira issue created for this Access Requirement. Applies only to LockAccessRequirement.',
    SNAPSHOT_DATE DATE COMMENT 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.'
)
CLUSTER BY (SNAPSHOT_DATE)
COMMENT='This table contain snapshots of access requirements. Snapshots are taken when an access requirement is created, updated or deleted. Note: Snapshots are also taken periodically and independently of the changes. The snapshot_timestamp records when the snapshot was taken.'
;
