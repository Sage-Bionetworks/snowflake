# DBT

A dbt project to transform source data ingested into Snowflake into reusable resources.

dbt works with data that has already been loaded into Snowflake. We can specify transformations of data (see "Models") in a way which align with dbt's source -> staging -> intermediate -> mart paradigm. See the [dbt documentation on project structure](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview) for an overview.

# Use-Cases

We currently only use dbt with Synapse RDS snapshot data.

# Installing and Configuring dbt

The CLI version of dbt is called dbt Core. You can install dbt with the Snowflake adapter via pip by following the instructions [here](https://docs.getdbt.com/docs/core/connect-data-platform/snowflake-setup). As usual, we recommend installing within a virtual environment.

After installing, configure your `~/.dbt/profiles.yml` by following the instructions in the previous link. This is where you can specify both your authentication and deployment environment (i.e., database/schema) information. dbt models can be deployed to any schema which your role has write access to.

# Models

Models are categorized according to their function in the dbt model paradigm. The source data for our models lives in the database and schema specified in [`dbt_project.yml`](./dbt_project.yml).

## Source 
Source data is already loaded into Snowflake tables. Downstream models are precedented on these tables, which are specified in `models/staging/synapse/_synapse__sources.yml`. These tables can be found in either the `SYNAPSE_568_SNAPSHOT.RAW` schema (for production data) or the `SYNAPSE_DATA_WAREHOUSE_DEV_SNOW_366_SYNAPSE_SNAPSHOT_POC.RDS_SNAPSHOT` schema (for dev data - which _might not contain every source table_).

## Staging Models

[Staging models](https://docs.getdbt.com/best-practices/how-we-structure/2-staging) are located in `models/staging/synapse/`. This layer is intended to handle basic transforms, primarily around standardizing column names. 

## Intermediate Models

[Intermediate models](https://docs.getdbt.com/best-practices/how-we-structure/3-intermediate) are derived from one or more staging or intermediate models, typically by joining upon their keys. This is the most flexible layer of models, and serves as an intermediary layer between the staging and mart models.

> [!NOTE]
> DBT recommends organizing intermediate models by business domain, rather than with respect to the data's source system. We sometimes slightly stray from this recommendation by first consolidating our source tables into a "universal" model that can be used by multiple business domains. For example, `models/intermediate/synapse/int_synapse_acl.sql` joins ACL-related tables from the source data to create a single, unified ACL interface -- rather than having multiple business domains duplicate this logic. 

## Mart Models

[Mart models](https://docs.getdbt.com/best-practices/how-we-structure/4-marts) are models which are designed with a specific business function in mind and are meant to be exposed to analysts. These models derive their data from one or more intermediary models.

# Running DBT

DBT models can be deployed to the schema specified in [`dbt_project.yml`](./dbt_project.yml) like so:
```
dbt run
```

We can specify a specific model to be deployed as well. dbt will handle the model dependencies:
```
dbt run --select stg_synapse__data_access_submission_status
```

# Developer Guidelines

For developer guidelines, including structure and style conventions, see [CONTRIBUTING.md](./CONTRIBUTING.md).

### DBT Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
