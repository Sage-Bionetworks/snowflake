USE ROLE ACCOUNTADMIN;

-- GOOGLE_ANALYTICS grants
-- Gives the admin of the GOOGLE_ANALYTICS_AGGREGATE schema the
-- privileges to invoke any stored procedures (like CONFIGURE_REPORT)
GRANT APPLICATION ROLE GOOGLE_ANALYTICS.ADMIN
	TO ROLE GOOGLE_ANALYTICS_AGGREGATE_ADMIN;
-- Developers should have view privileges upon the application
-- Developers won't be able to see procedures because that requires USAGE
GRANT APPLICATION ROLE GOOGLE_ANALYTICS.VIEWER
	TO ROLE DATA_ENGINEER;
