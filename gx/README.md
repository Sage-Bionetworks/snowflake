# Great Expectations

Follow instructions here: https://docs.greatexpectations.io/docs/oss/tutorials/quickstart/ to get started.

pip install sqlalchemy python-dotenv snowflake-sqlalchemy

1. Be sure to export and create the GX data source environmental variable. Follow these [steps](https://docs.greatexpectations.io/docs/oss/guides/connecting_to_your_data/fluent/database/connect_sql_source_data?sql-database-type=snowflake) to set it up: 

```
export GX_SNOWFLAKE_CONNECTION="snowflake://<USER_NAME>:<PASSWORD>@<ACCOUNT_NAME_OR_LOCATOR>/<DATABASE_NAME>/<SCHEMA_NAME>?warehouse=<WAREHOUSE_NAME>&role=<ROLE_NAME>"
```