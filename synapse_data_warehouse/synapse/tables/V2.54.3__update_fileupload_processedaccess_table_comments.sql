use schema {{database_name}}.synapse; --noqa: JJ01,PRS,TMP

alter table fileupload
set comment =
'[DEPRECATION NOTICE] This table is being deprecated and will be replaced by ``synapse_event.fileupload_event`` in the near future. Please transition any dependencies accordingly.

This table contains upload records for FileEntity (e.g. a new file creation, upload or update to an existing file) and TableEntity (e.g. an appended row set to an existing table, uploaded file to an existing table). The events are recorded only after the file or change to a table is successfully uploaded.';

alter table processedaccess
set comment =
'[DEPRECATION NOTICE] This table is being deprecated and will be replaced by ``synapse_event.processedaccess_event`` in the near future. Please transition any dependencies accordingly.

The table contains access records. Each record reflects a single API request received by the Synapse server. The recorded data is useful for audits and to analyse API performance such as delays, errors or success rates.';
