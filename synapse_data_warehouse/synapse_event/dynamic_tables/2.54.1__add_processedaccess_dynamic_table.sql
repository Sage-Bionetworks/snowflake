USE SCHEMA {{database_name}}.SYNAPSE_EVENT; --noqa: JJ01,PRS,TMP

CREATE OR REPLACE DYNAMIC TABLE PROCESSEDACCESS_EVENT
    (
        SESSION_ID VARCHAR(16777216) COMMENT 'A unique identifier that the Synapse server assigns for the duration of a session. Sessions are linked to a user, an API key or a token.',
        TIMESTAMP TIMESTAMP_NTZ(9) COMMENT 'The timestamp when the user sends a request to the Synapse server.',
	    USER_ID NUMBER(38,0) COMMENT 'The unique identifier of the Synapse user.',
	    METHOD VARCHAR(16777216) COMMENT 'The http method of the request.',
        REQUEST_URL VARCHAR(16777216) COMMENT 'The url of the request.',
        USER_AGENT VARCHAR(16777216) COMMENT 'The User-Agent header from the http request. See: https://en.wikipedia.org/wiki/User-Agent_header',
        HOST VARCHAR(16777216) COMMENT 'The IP address of the host that made the request.',
        ORIGIN VARCHAR(16777216) COMMENT 'The host name of the portal making the request, e.g., https://staging.synapse.org, https://adknowledgeportal.synapse.org, https://dhealth.synapse.org.',
        X_FORWARDED_FOR VARCHAR(16777216) COMMENT 'The HTTP header x_forwarded_for contains the IP address of the user connecting through a proxy. See: https://en.wikipedia.org/wiki/X-Forwarded-For',
        VIA VARCHAR(16777216) COMMENT 'The HTTP header Via, informs the server of proxies through which the request was sent.',
        THREAD_ID NUMBER(38,0) COMMENT 'The unique identifier of the thread in which the request was processed.',
        ELAPSE_MS NUMBER(38,0) COMMENT 'The total time of processing the user request in milliseconds.',
        SUCCESS BOOLEAN COMMENT 'Indicates if the user request succeeded (true) or failed (false).',
        STACK VARCHAR(16777216) COMMENT 'The stack (prod, dev) on which the request was processed.',
        INSTANCE VARCHAR(16777216) COMMENT 'The version of the stack that processed the request.',
        VM_ID VARCHAR(16777216) COMMENT 'The unique identifier of the Synapse ec2 server in the cluster that processed the request.',
        RETURN_OBJECT_ID VARCHAR(16777216) COMMENT 'The Synapse object identifier which is returned to the user in response body of a GET, PUT or POST API, if available.',
        QUERY_STRING VARCHAR(16777216) COMMENT 'The set of characters tacked onto the end of a URL after the question mark (?).',
        RESPONSE_STATUS NUMBER(38,0) COMMENT 'The response code for the request, e.g., 200, 401, 500. See: https://en.wikipedia.org/wiki/List_of_HTTP_status_codes',
        OAUTH_CLIENT_ID VARCHAR(16777216) COMMENT 'The unique identifier of the oauth client used in the request. It will be empty when the request is not made by an OAuth client.',
        BASIC_AUTH_USERNAME VARCHAR(16777216) COMMENT 'The name of the user who made the request using BASIC authentication method. It will be empty otherwise.',
        AUTH_METHOD VARCHAR(16777216) COMMENT 'The authentication method used by the client. Currently BEARERTOKEN, SESSIONTOKEN, BASIC, APIKEY methods are supported.',
        NORMALIZED_METHOD_SIGNATURE VARCHAR(16777216) COMMENT 'This is the http method followed by a simplified version of the request url (with all IDs extracted).',
        CLIENT VARCHAR(16777216) COMMENT 'The is an alias of the user agent, e.g., WEB, JAVA, PYTHON.',
        CLIENT_VERSION VARCHAR(16777216) COMMENT 'The version of the client used to make the request.',
        ENTITY_ID NUMBER(38,0) COMMENT 'The Synapse object identifier sent by the user in the request url, if any.',
        RECORD_DATE DATE COMMENT 'The data is partitioned for fast and cost effective queries. The timestamp field is converted into a date and stored in the record_date field for partitioning. The date should be used as a condition (WHERE CLAUSE) in the queries.',
    )
    TARGET_LAG = '1 day'
    WAREHOUSE = compute_xsmall
    COMMENT = 'This dynamic table, indexed by the <> columns, contains a history of file upload events on Synapse.'
    AS
    WITH dedup_processedaccess AS (
        SELECT
            ???
        FROM {{database_name}}.SYNAPSE_RAW.PROCESSEDACCESS --noqa: TMP
        QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY ???
                ORDER BY TIMESTAMP DESC, RECORD_DATE DESC
            ) = 1
    )
    SELECT 
        *
    FROM 
        dedup_processedaccess;
