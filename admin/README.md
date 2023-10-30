# Database administration

Snowflake is a SaaS service that provides a data warehouse / distributed datawarehouse layer.  Here is an article on [snowflake database management](https://community.snowflake.com/s/article/Database-Administration-on-Snowflake). All admin specific scripts are located in this folder. Each of the following scripts are responsible for different aspects of Snowflake administration.

A GitHub Action is will execute most of the scripts below upon a push into the `main` and/or `dev` branch.

> [!NOTE]
> The follow scripts should all eventually leverage [schemachange](https://github.com/Snowflake-Labs/schemachange) which is a simple python based tool to manage snowflake objects.  It follows an Imperative-style approach to Database Change Management (DCM) and was inspired by the [Flyway database migration tool](https://flywaydb.org/).  [Database change management](https://community.snowflake.com/s/article/A-New-Approach-to-Database-Change-Management-with-Snowflake)

## Users

> [user.sql](users.sql) - User creation

Google SAML integration is enabled for snowflake for Sage Bionetworks google accounts. Currently, there isn't automatic user creation, so users must be added to the users.sql script.

Users are to be created by the `USERADMIN`.  To add a user, created a pull request by adding their Sage Bionetworks email to the users.sql script.  By default, the user will be created with the `PUBLIC` role.  See the Roles section to learn how to grant additonal roles to users so that they can access different resources within snowflake.

```
CREATE USER "...@sagebase.org"
```

> [!NOTE]
> Unfortunately, google workspaces does not support SCIM which means that user management happens within this repository AND google workspaces.  Future direction would be to support jumpcloud SCIM integration with snowflake and/or continue this workflow.

## Roles

> [roles.sql](roles.sql) - Role creation and granting of policies.

For snowflake administrators, please make sure you read this carefully: https://docs.snowflake.com/en/user-guide/security-access-control-overview. Roles are to be created by the `USERADMIN`. The roles.sql file contains a series of SQL statements that create and grant roles to users in a Snowflake database allowing for fine-grained control over access to different schemas and functions within the database.

> [!NOTE]
> This file does not grant roles access to different resources.  That is done in the privileges folder. Future direction would be to support jumpcloud SCIM integration with snowflake to automate role creation and assignment.

## Databases

> [database.sql](databases.sql)

Databases _must be_ created by the `SYSADMIN` role. Different roles can be created for different projects so that certain users have permissions to create schemas and tables under this role. That said, currently it's easiest to have the `SYSADMIN` role also create many of the schemas and tables to ensure the correct security policies are set.

## Warehouses

> [warehouse.sql](warehouses.sql)

Warehouse _must be_ created by the `SYSADMIN` role.  It's important that you include the following parameters in the warehouse creation script.  To track changes to warehouses, we leverage[schemachange](https://github.com/Snowflake-Labs/schemachange).

* `warehouse_type = STANDARD` will ensure that the warehouse is not a multi-cluster warehouse.  Multi-cluster warehouses are not recommended for Sage Bionetworks use cases.
* `warehouse_size = XSMALL` will ensure that the warehouse is the smallest size.  This is recommended for most use cases.
- `auto_suspend = 60` will ensure that the warehouse is suspended after 60 seconds not in use. Auto-suspension for ingestion and transformation is typically recommended to be 1-2 min as they are often processed in scheduled batches, as long as each time query runs for longer than 1 min (per second billing after first min). For the warehouse dedicated to Tableau/Analytics, typically, snowflake recommend longer auto-suspension to allow queries to leverage [cache](https://docs.snowflake.com/en/user-guide/warehouses-considerations#how-does-warehouse-caching-impact-queries) for improved performance hence lower cost. Here is the doc on general [warehouse considerations](https://docs.snowflake.com/en/user-guide/warehouses-considerations).
* `auto_resume = TRUE` will automatically resume when a query is executed
* `initially_suspended = TRUE` will ensure that the warehouse is suspended when it is created.

## Integrations

These are account level integrations

* storage integrations: Integrations from snowflake to S3 buckets.
* OAUTH security integrations: Allow seamless creation to tableau desktop and cloud.
* SAML2 security integration: Allow for integration with google accounts.

## Governance

> [policies.sql](policies.sql)

Governance policies for schemas. As we ingest data, we will need to be mindful of each person's access.  Instead of removing the column all together for downstream users, we can set up masking policies so that the data is obfuscated for certain users.  This is done by creating a policy and then applying it to a column.


## Backup and recovery

> [backup](backup.sql)

As stated in the article in the first paragraph: "Although hugely simplified, it’s important to be able to quickly recover from system or human error, and quickly restore corrupted data."  We leverage snowflake's zero copy cloning feature which creates a clone of the existing database without taking extra storage.

## Resource monitors

This is a WIP. There are resource monitors created manually, but it should be created via code.

## Terraform exploration (PoC)

> [!NOTE]
> Unfortunately the terraform snowflake plugin is not very mature, so we are going to continue updating the SQL until it is more stable. Furthermore, due to the size of Sage Bionetworks, terraform may be an over engineered solution to manage snowflake resources as code.

Terraform is a infrastructure as code technology that allows us to create, update and delete resources.  Be sure to export these local variables and run the terraform script in the admin folder

```
export TF_VAR_snowflake_user=
export TF_VAR_snowflake_pwd=
export TF_VAR_snowflake_account=
```
