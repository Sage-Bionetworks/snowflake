USE SCHEMA {{database_name}}.synapse_raw; --noqa: JJ01,PRS,TMP

-- Add table comment
COMMENT ON TABLE processedaccess IS 'The table contains access records. Each record reflects a single API request received by the Synapse server. The recorded data is useful for audits and to analyse API performance such as delays, errors or success rates.';

-- Add column comments
COMMENT ON COLUMN processedaccess.session_id IS 'A unique identifier that the Synapse server assigns for the duration of a session. Sessions are linked to a user, an API key or a token.';
COMMENT ON COLUMN processedaccess.timestamp IS 'The timestamp when the user sends a request to the Synapse server.';
COMMENT ON COLUMN processedaccess.user_id IS 'The unique identifier of the Synapse user.';
COMMENT ON COLUMN processedaccess.method IS 'The http method of the request.';
COMMENT ON COLUMN processedaccess.request_url IS 'The URL of the request.';
COMMENT ON COLUMN processedaccess.user_agent IS 'The User-Agent header from the http request. See: https://en.wikipedia.org/wiki/User-Agent_header';
COMMENT ON COLUMN processedaccess.host IS 'The IP address of the host that made the request.';
COMMENT ON COLUMN processedaccess.origin IS 'The host name of the portal making the request, e.g., https://staging.synapse.org, https://adknowledgeportal.synapse.org, https://dhealth.synapse.org.';
COMMENT ON COLUMN processedaccess.x_forwarded_for IS 'The HTTP header x_forwarded_for contains the IP address of the user connecting through a proxy. See: https://en.wikipedia.org/wiki/X-Forwarded-For';
COMMENT ON COLUMN processedaccess.via IS 'The HTTP header Via, informs the server of proxies through which the request was sent.';
COMMENT ON COLUMN processedaccess.thread_id IS 'The unique identifier of the thread in which the request was processed.';
COMMENT ON COLUMN processedaccess.elapse_ms IS 'The total time of processing the user request in milliseconds.';
COMMENT ON COLUMN processedaccess.success IS 'Indicates if the user request succeeded (true) or failed (false).';
COMMENT ON COLUMN processedaccess.stack IS 'The stack (prod, dev) on which the request was processed.';
COMMENT ON COLUMN processedaccess.instance IS 'The version of the stack that processed the request.';
COMMENT ON COLUMN processedaccess.vm_id IS 'The unique identifier of the Synapse ec2 server in the cluster that processed the request.';
COMMENT ON COLUMN processedaccess.return_object_id IS 'The Synapse object identifier which is returned to the user in response body of a GET, PUT or POST API, if available.';
COMMENT ON COLUMN processedaccess.query_string IS 'The set of characters tacked onto the end of a URL after the question mark (?).';
COMMENT ON COLUMN processedaccess.response_status IS 'The response code for the request, e.g., 200, 401, 500. See: https://en.wikipedia.org/wiki/List_of_HTTP_status_codes';
COMMENT ON COLUMN processedaccess.oauth_client_id IS 'The unique identifier of the oauth client used in the request. It will be empty when the request is not made by an OAuth client.';
COMMENT ON COLUMN processedaccess.basic_auth_username IS 'The name of the user who made the request using BASIC authentication method. It will be empty otherwise.';
COMMENT ON COLUMN processedaccess.auth_method IS 'The authentication method used by the client. Currently BEARERTOKEN, SESSIONTOKEN, BASIC, APIKEY methods are supported.';
COMMENT ON COLUMN processedaccess.normalized_method_signature IS 'This is the http method followed by a simplified version of the request url (with all IDs extracted).';
COMMENT ON COLUMN processedaccess.client IS 'The is an alias of the user agent, e.g., WEB, JAVA, PYTHON.';
COMMENT ON COLUMN processedaccess.client_version IS 'The version of the client used to make the request.';
COMMENT ON COLUMN processedaccess.entity_id IS 'The Synapse object identifier sent by the user in the request url, if any.';
COMMENT ON COLUMN processedaccess.record_date IS 'The data is partitioned for fast and cost effective queries. The timestamp field is converted into a date and stored in the record_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.';
