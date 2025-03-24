/* Adding comments to tables missing columns and table descriptions
    - accessrequirement_latest
    - acl_latest
    - filehandleassociation_latest
    - node_latest
    - projectsetting_latest
    - team_latest
    - usergroup_latest
    - verificationsubmission_latest
*/
USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

-- Adding comments to accessrequirement_latest

-- Table comments
COMMENT ON DYNAMIC TABLE ACCESSREQUIREMENT_LATEST IS 'This table, indexed by ID, contains the latest snapshot of access requirements.'; 
-- Column comments
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.CHANGE_TIMESTAMP IS 'The time when the change (created/updated) on an access requirement is pushed to the queue. DELETE change types are not currently captured.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.CHANGE_TYPE IS 'The type of change that occurred on the access requirement, e.g., CREATE, UPDATE.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.CHANGE_USER_ID IS 'The id of the user that created or updated this access requirement snapshot';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.SNAPSHOT_TIMESTAMP IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.ID IS 'The unique identifier of the access requirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.VERSION_NUMBER IS 'The version of the access requirement. Each time an access requirement is updated a new version is issued.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.NAME IS 'The name assigned to the access requirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.DESCRIPTION IS 'The description assigned to the access requirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.CREATED_BY IS 'The id of the user that created the access requirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.MODIFIED_BY IS 'The id of the user that modified the access requirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.CREATED_ON IS 'The creation time of the access requirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.MODIFIED_ON IS 'The most recent change time of the access requirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.ACCESS_TYPE IS 'The type of access this access requirement applies to, currently supports only DOWNLOAD (for entities) and PARTICIPATE (for teams).';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.CONCRETE_TYPE IS 'The type of access requirement. See https://rest-docs.synapse.org/rest/org/sagebionetworks/repo/model/AccessRequirement.html.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.SUBJECTS_DEFINED_BY_ANNOTATIONS IS 'True if the subjects of the access requirement are automatically inferred by derived annotations. If true the subjectIds will be empty."';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.SUBJECTS_IDS IS 'The list of objects controlled by this access requirement. If the access_type is DOWNLOAD each element will be an ENTITY, If the access_type is PARTICIPATE each element will be a TEAM. This list is empty if subjects_defined_by_annotations is true.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.IS_CERTIFIED_USER_REQUIRED IS 'True if the user certification is required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement and SelfSignAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.IS_VALIDATED_PROFILE_REQUIRED IS 'True if the profile validation is required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement and SelfSignAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.IS_DUC_REQUIRED IS 'True if a Data Use Certificate (DUC) is required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.IS_IRB_APPROVAL_REQUIRED IS 'True if an Institutional Review Board (IRB) approval document is required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.ARE_OTHER_ATTACHMENTS_REQUIRED IS 'True if additional attachment(s) are required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.IS_IDU_PUBLIC IS 'True if the Intended Data Use Statements submitted to gain access to the data will be presented to public. Applies only to ManagedACTAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.IS_IDU_REQUIRED IS 'True the Intended Data Use Statement for a research project is required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.IS_TWO_FA_REQUIRED IS 'True if two factor authentication is required to fulfill the access requirement. Applies only to ManagedACTAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.DUC_TEMPLATE_FILE_HANDLE_ID IS 'The id of the file handle containing the DUC template (if a DUC is required) that needs to be filled and signed by users to fulfill the access requirement. Applies only to ManagedACTAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.EXPIRATION_PERIOD IS 'The amount in milliseconds that an approval of this access requirement is valid for. Applies only to ManagedACTAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.TERMS_OF_USER IS 'The terms of use text. Applies only to TermsOfUseAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.ACT_CONTACT_INFO IS 'Information on how to contact the Synapse ACT for access approval (external to Synapse). Applies only to ACTAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.OPEN_JIRA_ISSUE IS 'Flag that indicate if a JIRA issue needs to be opened in addition to follow the act_contact_info . Applies only to ACTAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.JIRA_KEY IS 'The key of the jira issue created for this Access Requirement. Applies only to LockAccessRequirement.';
COMMENT ON COLUMN ACCESSREQUIREMENT_LATEST.SNAPSHOT_DATE IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';