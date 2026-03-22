# DBT

A dbt project to transform source data ingested into Snowflake into reusable resources.

dbt works with data that has already been loaded into Snowflake. We can specify transformations of data (see "Models") in a way which align with dbt's source -> staging -> intermediate -> mart paradigm. See the [dbt documentation on project structure](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview) for an overview.

# Use-Cases

We currently only use dbt with Synapse RDS snapshot data.

# Installing and Configuring dbt

The CLI version of dbt is called dbt Core. You can install dbt with the Snowflake adapter via pip by following the instructions [here](https://docs.getdbt.com/docs/core/connect-data-platform/snowflake-setup). As usual, we recommend installing within a virtual environment.

After installing, configure your `~/.dbt/profiles.yml` by following the instructions in the previous link. This is where you can specify both your authentication and deployment environment (i.e., database/schema) information. dbt models can be deployed to any schema which your role has write access to.

# Models

Models are categorized according to their function in the dbt model paradigm.

## Source 
Source data is already loaded into Snowflake tables. Downstream models are precedented on these tables, which are specified in sources files (e.g., [`_synapse__sources.yml`](./models/staging/synapse/_synapse__sources.yml)). These tables can be found in the `SYNAPSE_RDS_SNAPSHOT` database. The schema name determines the Synapse stack which the data is sourced from.

## Staging Models

[Staging models](https://docs.getdbt.com/best-practices/how-we-structure/2-staging) are located in `models/staging/synapse/`. This layer is intended to handle basic transforms and standardization of column names. 

## Intermediate Models

[Intermediate models](https://docs.getdbt.com/best-practices/how-we-structure/3-intermediate) are derived from one or more staging or intermediate models, typically by joining upon their keys. This is the most flexible layer of models, and serves as an intermediary layer between the staging and mart models.

> [!NOTE]
> DBT recommends organizing intermediate models by business domain, rather than with respect to the data's source system. We stray from this recommendation by consolidating our staging models into a "universal" intermediate model that can be used by multiple business domains. For example, [int_synapse_acl.sql](`models/intermediate/synapse/int_synapse_acl.sql`) joins ACL-related tables from the staging models to create a single, unified ACL interface -- rather than having multiple business domains duplicate this logic. 

## Mart Models

[Mart models](https://docs.getdbt.com/best-practices/how-we-structure/4-marts) are models which are meant to be exposed to analysts. These models derive their data from one or more intermediate models.

Mart models are organized into subdirectories based on their target database:
- **`marts/synapse_data_warehouse/`**: Models deployed to the `synapse_data_warehouse` database (or corresponding dev database)
- **`marts/sage/`**: Models deployed to the `sage` database (production only)

# Deployment Environments

This project deploys its models to different databases, each serving a different purpose:

## Synapse Data Warehouse

**Database**: `SYNAPSE_DATA_WAREHOUSE` (production) or `SYNAPSE_DATA_WAREHOUSE_DEV` (staging) or `SYNAPSE_DATA_WAREHOUSE_DEV_{my_branch}` (development).

The majority of models deploy here, including:
- All staging models ([`models/staging/`](./models/staging/))
- All intermediate models ([`models/intermediate/`](./models/intermediate/))
- Mart models in [`models/marts/synapse_data_warehouse/`](./models/marts/synapse_data_warehouse/)

These models are available in both production and development environments, making them suitable for iterative development and testing.

## Sage

**Database**: `SAGE` (production only)

Analyst-friendly models that may depend on Synapse data warehouse models. Models in [`models/marts/sage/`](./models/marts/sage/) deploy here.

> [!IMPORTANT]
> Sage models are configured to deploy **only in production** (`target.name == 'prod'`). They will be automatically skipped in development environments since corresponding test databases may not exist.

# Running DBT

DBT models can be deployed to the databases specified in [`dbt_project.yml`](./dbt_project.yml), and will default to being deployed to the database specified in your DBT profile (`~/.dbt/profiles.yml`). This can be particularly useful when deploying to a development environment, since we don't need to modify any configuration in the DBT project itself.

## Deploy All Models

Because we have models which are intended to deploy to different environments (e.g., the Synapse data warehouse or Sage environments), it's often not practical to deploy all models at once (although it is _possible_, granted we deploy using a powerful enough role):

```bash
dbt run
```

## Deploy by Environment

Use selectors to deploy models for a specific database environment:

```bash
# Deploy only synapse_data_warehouse models
dbt run --selector synapse_data_warehouse

# Deploy only sage models (production only)
dbt run --selector sage
```

For detailed selector configurations, refer to the [selectors.yml](./selectors.yml) file.

## Deploy Specific Models

We can specify a specific model to be deployed as well. dbt will handle the model dependencies:
```bash
dbt run --select stg_synapse__data_access_submission_status
```

You can also target specific directories:
```bash
# Deploy all models in a specific mart directory
dbt run --select intermediate.synapse
dbt run --select marts.synapse_data_warehouse
dbt run --select marts.sage
```

Check out the dbt [docs](https://docs.getdbt.com/reference/node-selection/syntax) to explore all the powerful ways dbt allows us to specify models during deployment.

# Developer Guidelines

For developer guidelines, including structure and style conventions, see [CONTRIBUTING.md](./CONTRIBUTING.md).

### DBT Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
