USE SCHEMA {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

ALTER TABLE filedownload
  SET COMMENT = 
  '[DEPRECATION NOTICE] This table is being deprecated and will be replaced by ``synapse_event.objectdownload_event`` in the near future. Please transition any dependencies accordingly.
  The table contain records of all the downloads of the Synapse, e.g., file, zip/package, attachments. The events are recorded only after the pre-signed url for requested download entity is generated.';
