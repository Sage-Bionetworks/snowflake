-- A temporary increase in max clusters to accomodate Snowflake workshop --
USE ROLE SYSADMIN;
ALTER WAREHOUSE IF EXISTS COMPUTE_XSMALL
    SET MAX_CLUSTER_COUNT = 50;