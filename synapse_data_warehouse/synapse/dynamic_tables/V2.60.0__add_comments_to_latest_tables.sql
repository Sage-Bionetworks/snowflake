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

--------------------------------------
------ ACCESSREQUIREMENT_LATEST ------
--------------------------------------
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


--------------------------------------
------ ACL_LATEST ------
--------------------------------------

-- Table comments
COMMENT ON DYNAMIC TABLE ACL_LATEST IS 'This dynamic table, indexed by OWNER_ID, contains the latest snapshot of access control lists (ACLs) for Synapse objects. It is derived from ACLSNAPSHOTS raw data and provides deduplicated, flattened access control information. The table is refreshed daily and contains only the most recent ACL entries for each owner_id from the past 14 days. Each row represents a specific access permission granted to a principal (user or team) on a Synapse object.';

-- Column comments
COMMENT ON COLUMN ACL_LATEST.CHANGE_TIMESTAMP IS 'The timestamp when the change (created/updated) on an access control list was pushed to the queue for snapshotting.';
COMMENT ON COLUMN ACL_LATEST.CHANGE_TYPE IS 'The type of change that occurred on the access control list, e.g., CREATE, UPDATE.';
COMMENT ON COLUMN ACL_LATEST.CREATED_ON IS 'The original creation timestamp of the access control list. This represents when the ACL was first created in Synapse.';
COMMENT ON COLUMN ACL_LATEST.OWNER_ID IS 'The unique identifier of the Synapse object to which the access control list is applied.';
COMMENT ON COLUMN ACL_LATEST.OWNER_TYPE IS 'The type of the Synapse object that the access control list is affecting, e.g., ENTITY, FILE, SUBMISSION, MESSAGE, TEAM.';
COMMENT ON COLUMN ACL_LATEST.SNAPSHOT_DATE IS 'The date when the snapshot was taken, used for data partitioning. This field is derived from SNAPSHOT_TIMESTAMP and should be used in WHERE clauses for efficient querying.';
COMMENT ON COLUMN ACL_LATEST.SNAPSHOT_TIMESTAMP IS 'The timestamp when the snapshot was taken. This is usually after the change happened and represents when the ACL state was captured.';
COMMENT ON COLUMN ACL_LATEST.ACCESS_TYPE IS 'The specific type of access permission granted to the principal. This is extracted from the RESOURCE_ACCESS JSON and represents what actions the principal can perform on the object (e.g., READ, UPDATE, DELETE, ADMIN).';
COMMENT ON COLUMN ACL_LATEST.PRINCIPAL_ID IS 'The unique identifier of the principal (user or team) that has been granted the specified access type on the object. This is extracted from the RESOURCE_ACCESS JSON and represents who has the permission.';


------------------------------------------
------ FILEHANDLEASSOCIATION_LATEST ------
------------------------------------------

-- Table comments
COMMENT ON DYNAMIC TABLE FILEHANDLEASSOCIATION_LATEST IS 'This dynamic table, indexed by FILEHANDLEID and ASSOCIATEID, contains the latest snapshot of file handle associations for Synapse objects. It is derived from FILEHANDLEASSOCIATIONSNAPSHOTS raw data and provides deduplicated file association information. The table is refreshed weekly and contains only the most recent association entries for each filehandleid-associateid pair from the past 14 days. Each row represents a specific file handle association with a Synapse object.';

-- Column comments
COMMENT ON COLUMN FILEHANDLEASSOCIATION_LATEST.ASSOCIATEID IS 'The unique identifier of the Synapse object that wraps the file. This represents the ID of the entity that contains or references the file handle.';
COMMENT ON COLUMN FILEHANDLEASSOCIATION_LATEST.ASSOCIATETYPE IS 'The type of the Synapse object that wraps the file. This indicates what kind of Synapse object is associated with the file handle.';
COMMENT ON COLUMN FILEHANDLEASSOCIATION_LATEST.FILEHANDLEID IS 'The unique identifier of the file handle.';
COMMENT ON COLUMN FILEHANDLEASSOCIATION_LATEST.INSTANCE IS 'The version of the stack that processed the file association. This indicates which version of the Synapse infrastructure processed this file association record.';
COMMENT ON COLUMN FILEHANDLEASSOCIATION_LATEST.STACK IS 'The stack (prod, dev) on which the file handle association was processed.';
COMMENT ON COLUMN FILEHANDLEASSOCIATION_LATEST.TIMESTAMP IS 'The time when the association data was collected.';


--------------------------------------
------ NODE_LATEST ------
--------------------------------------

-- Table comments
COMMENT ON DYNAMIC TABLE NODE_LATEST IS 'This dynamic table, indexed by ID, contains the latest snapshot of Synapse nodes (projects, files, folders, tables, etc.). It is derived from NODESNAPSHOTS raw data and provides deduplicated node information. The table is refreshed daily and contains only the most recent node entries for each ID from the past 30 days. Each row represents a specific Synapse node with its current state and metadata.';

-- Column comments
COMMENT ON COLUMN NODE_LATEST.CHANGE_TYPE IS 'The type of change that occurred on the node, e.g., CREATE, UPDATE.';
COMMENT ON COLUMN NODE_LATEST.CHANGE_TIMESTAMP IS 'The time when the change (created/updated) on the node is pushed to the queue for snapshotting.';
COMMENT ON COLUMN NODE_LATEST.CHANGE_USER_ID IS 'The unique identifier of the user who made the change to the node.';
COMMENT ON COLUMN NODE_LATEST.SNAPSHOT_TIMESTAMP IS 'The time when the snapshot was taken. (It is usually after the change happened).';
COMMENT ON COLUMN NODE_LATEST.ID IS 'The unique identifier of the node.';
COMMENT ON COLUMN NODE_LATEST.BENEFACTOR_ID IS 'The identifier of the (ancestor) node which provides the permissions that apply to this node. Can be the id of the node itself.';
COMMENT ON COLUMN NODE_LATEST.PROJECT_ID IS 'The project where the node resides.';
COMMENT ON COLUMN NODE_LATEST.PARENT_ID IS 'The unique identifier of the parent in the node hierarchy.';
COMMENT ON COLUMN NODE_LATEST.NODE_TYPE IS 'The type of the node. Allowed node types are: project, folder, file, table, link, entityview, dockerrepo, submissionview, dataset, datasetcollection, materializedview, virtualtable.';
COMMENT ON COLUMN NODE_LATEST.CREATED_ON IS 'The creation time of the node.';
COMMENT ON COLUMN NODE_LATEST.CREATED_BY IS 'The unique identifier of the user who created the node.';
COMMENT ON COLUMN NODE_LATEST.MODIFIED_ON IS 'The most recent change time of the node.';
COMMENT ON COLUMN NODE_LATEST.MODIFIED_BY IS 'The unique identifier of the user who last modified the node.';
COMMENT ON COLUMN NODE_LATEST.VERSION_NUMBER IS 'The version of the node on which the change occurred, if applicable.';
COMMENT ON COLUMN NODE_LATEST.FILE_HANDLE_ID IS 'The unique identifier of the file handle if the node is a file, null otherwise.';
COMMENT ON COLUMN NODE_LATEST.NAME IS 'The name of the node.';
COMMENT ON COLUMN NODE_LATEST.IS_PUBLIC IS 'If true, READ permission is granted to all the Synapse users, including the anonymous user, at the time of the snapshot.';
COMMENT ON COLUMN NODE_LATEST.IS_CONTROLLED IS 'If true, an access requirement managed by the ACT is set on the node.';
COMMENT ON COLUMN NODE_LATEST.IS_RESTRICTED IS 'If true, a terms-of-use access requirement is set on the node.';
COMMENT ON COLUMN NODE_LATEST.SNAPSHOT_DATE IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
COMMENT ON COLUMN NODE_LATEST.EFFECTIVE_ARS IS 'The list of access requirement ids that apply to the entity at the time the snapshot was taken.';
COMMENT ON COLUMN NODE_LATEST.ANNOTATIONS IS 'The json representation of the entity annotations assigned by the user.';
COMMENT ON COLUMN NODE_LATEST.DERIVED_ANNOTATIONS IS 'The json representation of the entity annotations that were derived by the schema of the entity.';
COMMENT ON COLUMN NODE_LATEST.VERSION_COMMENT IS 'A short description assigned to this node version.';
COMMENT ON COLUMN NODE_LATEST.VERSION_LABEL IS 'A short label assigned to this node version.';
COMMENT ON COLUMN NODE_LATEST.ALIAS IS 'An alias assigned to a project entity if present.';
COMMENT ON COLUMN NODE_LATEST.ACTIVITY_ID IS 'The reference to the id of an activity assigned to the node.';
COMMENT ON COLUMN NODE_LATEST.COLUMN_MODEL_IDS IS 'For entities that define a table schema (e.g. table, views etc), the list of column ids assigned to the schema.';
COMMENT ON COLUMN NODE_LATEST.SCOPE_IDS IS 'For entities that define a scope (e.g. entity views, submission views etc), the list of entity ids included in the scope.';
COMMENT ON COLUMN NODE_LATEST.ITEMS IS 'For entities that define a fixed list of entity references (e.g. dataset, dataset collections), the list of entity references included in the scope.';
COMMENT ON COLUMN NODE_LATEST.REFERENCE IS 'For Link entities, the reference to the linked target.';
COMMENT ON COLUMN NODE_LATEST.IS_SEARCH_ENABLED IS 'For Table like entities (e.g. EntityView, MaterializedView etc), defines if full text search is enabled on those entities.';
COMMENT ON COLUMN NODE_LATEST.DEFINING_SQL IS 'For tables that are driven by a synapse SQL query (e.g. MaterializedView, VirtualTable), defines the underlying SQL query.';
COMMENT ON COLUMN NODE_LATEST.INTERNAL_ANNOTATIONS IS 'The json representation of the entity internal annotations that are used to store additional data about different types of entity (e.g. dataset checksum, size, count).';
COMMENT ON COLUMN NODE_LATEST.VERSION_HISTORY IS 'The list of entity versions, at the time of the snapshot.';
COMMENT ON COLUMN NODE_LATEST.PROJECT_STORAGE_USAGE IS 'The storage usage information for the project, including size and count metrics.';


--------------------------------------
------ PROJECTSETTING_LATEST ------
--------------------------------------

-- Table comments
COMMENT ON DYNAMIC TABLE PROJECTSETTING_LATEST IS 'This dynamic table, indexed by ID, contains the latest snapshot of project settings for Synapse projects. It is derived from PROJECTSETTINGSNAPSHOTS raw data and provides deduplicated project settings information. The table is refreshed daily and contains only the most recent settings entries for each project ID from the past 14 days. Each row represents a specific project setting with its current configuration.';

-- Column comments
COMMENT ON COLUMN PROJECTSETTING_LATEST.CHANGE_TIMESTAMP IS 'The time when a project settings change (created/updated) occurred.';
COMMENT ON COLUMN PROJECTSETTING_LATEST.CHANGE_TYPE IS 'The type of change that occurred on the project settings, e.g., CREATE, UPDATE, DELETE.';
COMMENT ON COLUMN PROJECTSETTING_LATEST.CHANGE_USER_ID IS 'The id of the user that created, updated the project settings being snapshotted.';
COMMENT ON COLUMN PROJECTSETTING_LATEST.SNAPSHOT_TIMESTAMP IS 'The time when the snapshot was taken. Snapshots are taken after each change event and periodically.';
COMMENT ON COLUMN PROJECTSETTING_LATEST.ID IS 'The unique identifier of the project setting.';
COMMENT ON COLUMN PROJECTSETTING_LATEST.CONCRETE_TYPE IS 'The type of project settings. See https://rest-docs.synapse.org/rest/org/sagebionetworks/repo/model/project/ProjectSetting.html.';
COMMENT ON COLUMN PROJECTSETTING_LATEST.PROJECT_ID IS 'The ID of the project to which the settings apply.';
COMMENT ON COLUMN PROJECTSETTING_LATEST.SETTINGS_TYPE IS 'The short type of the project settings. See https://rest-docs.synapse.org/rest/org/sagebionetworks/repo/model/project/ProjectSetting.html.';
COMMENT ON COLUMN PROJECTSETTING_LATEST.ETAG IS 'UUID issued each time the project settings changes.';
COMMENT ON COLUMN PROJECTSETTING_LATEST.LOCATIONS IS 'The storage location IDs associated with the project setting.';
COMMENT ON COLUMN PROJECTSETTING_LATEST.SNAPSHOT_DATE IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';


--------------------------------------
------ TEAM_LATEST ------
--------------------------------------

-- Table comments
COMMENT ON DYNAMIC TABLE TEAM_LATEST IS 'This dynamic table, indexed by ID, contains the latest snapshot of Synapse teams. It is derived from TEAMSNAPSHOTS raw data and provides deduplicated team information. The table is refreshed daily and contains only the most recent team entries for each ID from the past 30 days. Each row represents a specific team with its current state and membership configuration.';

-- Column comments
COMMENT ON COLUMN TEAM_LATEST.CHANGE_TYPE IS 'The type of change that occurred to the team, e.g., CREATE, UPDATE.';
COMMENT ON COLUMN TEAM_LATEST.CHANGE_TIMESTAMP IS 'The time when any change to the team was made (e.g. create, update or a change to its members).';
COMMENT ON COLUMN TEAM_LATEST.CHANGE_USER_ID IS 'The unique identifier of the user who made the change to the team.';
COMMENT ON COLUMN TEAM_LATEST.SNAPSHOT_TIMESTAMP IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN TEAM_LATEST.ID IS 'The unique identifier of the team.';
COMMENT ON COLUMN TEAM_LATEST.NAME IS 'The name of the team.';
COMMENT ON COLUMN TEAM_LATEST.CAN_PUBLIC_JOIN IS 'If true, a user can join the team without approval of a team manager.';
COMMENT ON COLUMN TEAM_LATEST.CREATED_BY IS 'The unique identifier of the user who created the team.';
COMMENT ON COLUMN TEAM_LATEST.CREATED_ON IS 'The creation time of the team.';
COMMENT ON COLUMN TEAM_LATEST.MODIFIED_BY IS 'The unique identifier of the user who last modified the team.';
COMMENT ON COLUMN TEAM_LATEST.MODIFIED_ON IS 'The time when the team was last modified.';
COMMENT ON COLUMN TEAM_LATEST.SNAPSHOT_DATE IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';


--------------------------------------
------ USERGROUP_LATEST ------
--------------------------------------

-- Table comments
COMMENT ON DYNAMIC TABLE USERGROUP_LATEST IS 'This dynamic table, indexed by ID, contains the latest snapshot of Synapse principals (individual users and groups of users). It is derived from USERGROUPSNAPSHOTS raw data and provides deduplicated user group information. The table is refreshed daily and contains only the most recent entries for each ID from the past 14 days. Each row represents a specific principal (individual user or group) with its current state.';

-- Column comments
COMMENT ON COLUMN USERGROUP_LATEST.CHANGE_TYPE IS 'The type of change that occurred to the user-group, e.g., CREATE, UPDATE.';
COMMENT ON COLUMN USERGROUP_LATEST.CHANGE_TIMESTAMP IS 'The time when the change (creation/update) to the user-group is pushed to the queue for snapshotting.';
COMMENT ON COLUMN USERGROUP_LATEST.CHANGE_USER_ID IS 'The unique identifier of the user who made the change to the user-group.';
COMMENT ON COLUMN USERGROUP_LATEST.SNAPSHOT_TIMESTAMP IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN USERGROUP_LATEST.ID IS 'The unique identifier of user or group.';
COMMENT ON COLUMN USERGROUP_LATEST.IS_INDIVIDUAL IS 'If true, then this user group is an individual user not a team.';
COMMENT ON COLUMN USERGROUP_LATEST.CREATED_ON IS 'The creation time of the user or group.';
COMMENT ON COLUMN USERGROUP_LATEST.SNAPSHOT_DATE IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';


--------------------------------------
------ VERIFICATIONSUBMISSION_LATEST ------
--------------------------------------

-- Table comments
COMMENT ON DYNAMIC TABLE VERIFICATIONSUBMISSION_LATEST IS 'This dynamic table, indexed by ID, contains the latest snapshot of user verification submissions by ACT. It is derived from VERIFICATIONSUBMISSIONSNAPSHOTS raw data and provides deduplicated verification submission information. The table is refreshed daily and contains only the most recent submission entries for each ID from the past 14 days. Each row represents a specific verification submission with its current state and history.';

-- Column comments
COMMENT ON COLUMN VERIFICATIONSUBMISSION_LATEST.CHANGE_TIMESTAMP IS 'The time when the change (created/updated) on a submission is pushed to the queue for snapshotting.';
COMMENT ON COLUMN VERIFICATIONSUBMISSION_LATEST.CHANGE_TYPE IS 'The type of change that occurred on the submission, e.g., CREATE, UPDATE.';
COMMENT ON COLUMN VERIFICATIONSUBMISSION_LATEST.SNAPSHOT_TIMESTAMP IS 'The time when the snapshot was taken (It is usually after the change happened).';
COMMENT ON COLUMN VERIFICATIONSUBMISSION_LATEST.ID IS 'The unique identifier of the submission.';
COMMENT ON COLUMN VERIFICATIONSUBMISSION_LATEST.CREATED_ON IS 'The creation time of the submission.';
COMMENT ON COLUMN VERIFICATIONSUBMISSION_LATEST.CREATED_BY IS 'The unique identifier of the user who created the submission.';
COMMENT ON COLUMN VERIFICATIONSUBMISSION_LATEST.STATE_HISTORY IS 'The sequence of submission states (SUBMITTED, REJECTED, APPROVED) for the submission.';
COMMENT ON COLUMN VERIFICATIONSUBMISSION_LATEST.SNAPSHOT_DATE IS 'The data is partitioned for fast and cost effective queries. The snapshot_timestamp field is converted into a date and stored in the snapshot_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';

--------------------------------------
------ CERTIFIEDQUIZQUESTION_LATEST ------
--------------------------------------

-- Table comments
COMMENT ON DYNAMIC TABLE CERTIFIEDQUIZQUESTION_LATEST IS 'This table contains the latest snapshots of the questions of the certification quiz taken within the last 14 days. With each entry representing a question answered by the user during the quiz.';
