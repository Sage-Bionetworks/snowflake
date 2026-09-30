USE SCHEMA {{database_name}}.synapse_event; --noqa: JJ01,PRS,TMP

-- The association stage is stack-specific within each warehouse database.
CREATE DYNAMIC TABLE IF NOT EXISTS filehandleassociation_event
    TARGET_LAG = '5 hours'
    WAREHOUSE = COMPUTE_XSMALL
    COMMENT = 'This dynamic table, indexed by the ASSOCIATEID, ASSOCIATETYPE and FILEHANDLEID columns, contains every file handle association for each Synapse object.

h2. Associate Types

The conditions under which a new file handle becomes associated with an object depend on ASSOCIATETYPE. Some types are versioned (a prior association is never removed, only added to), while others are a simple column overwrite (the prior association is not recoverable from RDS once replaced, only from the periodic scan history retained here and in FILEHANDLEASSOCIATIONSNAPSHOTS).

h3. FileEntity

A new association is created whenever a new version of the file entity is created, e.g., uploading a new version of a file. Each version carries its own content file handle (and, if applicable, a separate CSV validation result file handle); associations from prior versions are never removed.

h3. TableEntity

A new association is created whenever a row containing a FILEHANDLEID typed column value is appended or updated in the table. This is derived from the table row change history stored in S3, not from any versioned revision of the table itself.

h3. WikiMarkdown

A new association is created whenever the markdown content of a wiki page is edited. Each edit creates a new markdown version with its own file handle holding the rendered content; associations from prior versions are never removed.

h3. WikiAttachment

A new association is created whenever a new file is attached to a wiki page. Attachments are not versioned, but since FILEHANDLEID is part of this types natural key, every distinct file ever attached to the page remains associated.

h3. UserProfileAttachment

A new association is created whenever a user uploads a new profile picture. This is an in place column overwrite with no versioning; the current file handle is always available from RDS_LANDING.USER_PROFILE.PICTURE_ID, but the prior profile picture is not recoverable from RDS once replaced.

h3. TeamAttachment

A new association is created whenever a team icon is changed. Like UserProfileAttachment, this is an in place column overwrite with no versioning; the current file handle is always available from RDS_LANDING.TEAM.ICON, but the prior icon is not recoverable from RDS once replaced.

h3. MessageAttachment

A new association is created whenever a message or comment with file content is sent. The underlying record is created once and never updated, so associations are only ever added.

h3. FormData

A new association is created whenever a form draft is created or an existing drafts file is replaced prior to submission. The underlying record is updated in place, so only the most recently uploaded file remains associated once overwritten; the current file handle is always available from RDS_LANDING.FORM_DATA.FILE_HANDLE_ID, but a replaced draft file is not recoverable from RDS.

h3. SubmissionAttachment

A new association is created whenever a user submits an Evaluation submission that includes file content. Submissions are immutable once created, so associations are only ever added.

h3. VerificationSubmission

A new association is created whenever a user submits, or adds a supporting document to, a verification submission, e.g., proof of identity documentation.

h3. AccessRequirementAttachment

A new association is created whenever a new revision of an access requirement is created, e.g., updating its Data Use Certification template. As with FileEntity, associations from prior revisions are never removed.

h3. DataAccessRequestAttachment and DataAccessSubmissionAttachment

A new association is created whenever a user edits a data access request or submission and adds or changes an attachment or Data Use Certification file. Both objects are updated in place with no revision history, so only the most recently uploaded file handles are discoverable, and only by decoding the serialized blob in RDS_LANDING.DATA_ACCESS_REQUEST.REQUEST_SERIALIZED or RDS_LANDING.DATA_ACCESS_SUBMISSION.SUBMISSION_SERIALIZED; prior associations are only recoverable from the scan history retained here and in FILEHANDLEASSOCIATIONSNAPSHOTS.'
AS
SELECT
    associateid,
    associatetype,
    filehandleid,
    instance,
    stack,
    timestamp
FROM {{database_name}}.synapse_raw.filehandleassociationsnapshots --noqa: JJ01,PRS,TMP
WHERE associateid IS NOT NULL
    AND associatetype IS NOT NULL
    AND filehandleid IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY associateid, associatetype, filehandleid
    ORDER BY timestamp DESC, instance DESC
) = 1;
