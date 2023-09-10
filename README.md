# snowflake

This repository will house all the configuration, and data exploration of data that will be often executed.  Configurations include warehouse, database, schema, table, user, role and other configurations. The managed access of snowflake will be governed by [RBAC](https://medium.com/snowflake/managed-access-schema-framework-in-rbac-1b63341be418)

## Connecting to Snowflake

> [!IMPORTANT]
> The Sage snowflake overlords see all, please make sure you are careful with your queries.  Always use `limit` when you are exploring tables!

Follow the steps below to get access to snowflake: https://mqzfhld-vp00034.snowflakecomputing.com

1. Ask internally at Sage for snowflake access.  You are permitted to explore in the UI, but long standing views and tables should be created via PR and will be created via the SYSADMIN role by users that can assume the sysadmin privilege.
1. Enable vscode snowflake extension. Follow instructions here https://docs.snowflake.com/en/user-guide/vscode-ext.  Note: the worksheets that you create in snowflake do not automatically get transfered into github, so we encourage using this extension to add version control to your SQL.
1. Follow the instructions in the vscode extension to connect to snowflake.  I recommend setting up your ~/.snowflake/config file.
1. Look at examples in the analytics/exploration.sql to see how you can query the warehouse.

## Contributing

If there is a query you expect to run frequently, lets contribute it to the analytics folder!


## Administration

### Data Architecture
This is just a test, but I am going to attempt to follow the [medallion data architecture](https://www.databricks.com/glossary/medallion-architecture). 

```mermaid
graph TD;
    Bronze: AWS Glue-->Silver;
    Silver: Snowflake-->Gold;
    Gold: Snowflake;
```

### User/Role Management
Users and roles are to be created by the `useradmin`, and the code is contained in [here](admin/user_setup.sql).  To add a user, we want to use the first initial and last name.

```
CREATE USER flastname
    PASSWORD = 'generate_one',
    LOGIN_NAME = 'flastname',
    EMAIL = '...@sagebase.org',
    MUST_CHANGE_PASSWORD = TRUE,
    DEFAULT_WAREHOUSE = 'COMPUTE_ORG',
    DEFAULT_ROLE = 'PUBLIC';
```
