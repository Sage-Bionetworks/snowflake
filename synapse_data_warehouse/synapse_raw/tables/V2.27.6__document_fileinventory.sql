USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE fileinventory IS 'This table contains the S3 inventory of the main synapse bucket, the inventory is a snapshot taken weekly. For more information see https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-inventory.html.';

-- Add column comments
COMMENT ON COLUMN fileinventory.bucket IS 'The object bucket';
COMMENT ON COLUMN fileinventory.key IS 'The object key name (or key) that uniquely identifies the object in the bucket';
COMMENT ON COLUMN fileinventory.encryption_status IS 'The server-side encryption status, depending on what kind of encryption key is used—an Amazon S3 managed (SSE-S3) key, an AWS Key Management Service (AWS KMS) key (SSE-KMS), or a customer-provided key (SSE-C). Set to SSE-S3, SSE-C, SSE-KMS, or NOT-SSE. A status of NOT-SSE means that the object is not encrypted with server-side encryption. For more information, see Protecting data with encryption.';
COMMENT ON COLUMN fileinventory.is_latest IS 'Set to True if the object is the current version of the object';
COMMENT ON COLUMN fileinventory.is_delete_marker IS 'Set to True if the object is a delete marker';
COMMENT ON COLUMN fileinventory.size IS 'The object size in bytes, not including the size of incomplete multipart uploads, object metadata, and delete markers';
COMMENT ON COLUMN fileinventory.last_modified_date IS 'The object creation date or the last modified date, whichever is the latest.';
COMMENT ON COLUMN fileinventory.e_tag IS 'The entity tag (ETag) is a hash of the object. The ETag reflects changes only to the contents of an object, not to its metadata. The ETag can be an MD5 digest of the object data. Whether it is depends on how the object was created and how it is encrypted.';
COMMENT ON COLUMN fileinventory.storage_class IS 'The storage class that is used for storing the object. See https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html';
COMMENT ON COLUMN fileinventory.intelligent_tiering_access_tier IS 'Access tier (frequent or infrequent) of the object if it is stored in the S3 Intelligent-Tiering storage class. See https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html#sc-dynamic-data-access';		
COMMENT ON COLUMN fileinventory.is_multipart_uploaded IS 'Set to True if the object was uploaded as a multipart upload';
COMMENT ON COLUMN fileinventory.snapshot_date IS 'An inventory snapshot is taken on a weekly cadence, the data is partitioned by the snapshot date';				
COMMENT ON COLUMN fileinventory.object_owner IS 'The owner of the object';

