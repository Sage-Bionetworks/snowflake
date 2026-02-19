{% docs int_synapse_data_access_submission %}
Intermediate model combining data access submissions with their current status and aggregated accessor changes. A data access submission is a snapshot of an access request at submission time. When users modify rejected requests, new submissions are created, forming a revision history.
{% enddocs %}

{% docs data_access_submission %}
This event table contains all data access submissions and their associated state. A data access submission is created each time a user makes a revision of their data access request.
{% enddocs %}

{% docs col_data_access_submission_id %}
Unique identifier for the data access submission.
{% enddocs %}

{% docs col_submission_data_access_request_id %}
The identifier of the access request that this submission was created from.
{% enddocs %}

{% docs col_access_requirement_id %}
The identifier of the access requirement that the access request associates with.
{% enddocs %}

{% docs col_submission_access_requirement_version %}
Version of the access requirement at the time of submission.
{% enddocs %}

{% docs col_submission_research_project_id %}
The research project associated with this submission.
{% enddocs %}

{% docs col_submission_created_by %}
Identifier of the user who made this submission.
{% enddocs %}

{% docs col_submission_created_on %}
UTC timestamp when the submission was created.
{% enddocs %}

{% docs col_submission_state_modified_by %}
Identifier of the user who last modified the submission status.
{% enddocs %}

{% docs col_submission_state_modified_on %}
UTC timestamp when the submission status was last modified.
{% enddocs %}

{% docs col_submission_state %}
Current state in the submission workflow. One of: 'SUBMITTED', 'APPROVED', 'REJECTED', 'CANCELLED'
{% enddocs %}

{% docs col_submission_state_reason %}
UTF-8 encoded string containing an explanation for the current state, particularly for rejections or cancellations. Null for records before 2019 due to invalid utf-8 characters.
{% enddocs %}

{% docs col_etag %}
Entity tag for optimistic concurrency control (36-character UUID).
{% enddocs %}

{% docs col_data_access_submission_raw %}
Serialized representation of the complete submission object.
{% enddocs %}

{% docs col_submission_accessor_changes %}
A mapping of principal IDs (as strings) to their access type changes (e.g., {'123': 'GAIN_ACCESS', '456': 'RENEW_ACCESS'}). Access types include: 'GAIN_ACCESS', 'RENEW_ACCESS', 'REVOKE_ACCESS'
{% enddocs %}
