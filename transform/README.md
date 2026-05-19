# dbt

[TLDR](#tldr): A dbt project to transform source data in Snowflake into reusable resources.

dbt helps us manage downstream data models derived from existing data in Snowflake. One of the more powerful abstractions of dbt is that it enables us to independently manage how data is modeled from how models are materialized in the data warehouse. To _model our data_, we specify transformations in a way which aligns with dbt's [source -> staging -> intermediate -> mart paradigm](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview). How we _materialize our data models_ as particular object types (tables/views/etc.) in specific databases/schemas is configured separately.

# Use-Cases

We currently only use dbt with Synapse RDS snapshot data.

# Installing and Configuring dbt

The CLI version of dbt is called dbt Core. You can install dbt with the Snowflake adapter via pip by following the instructions [here](https://docs.getdbt.com/docs/core/connect-data-platform/snowflake-setup). As usual, we recommend installing within a virtual environment.

After installing, configure your `~/.dbt/profiles.yml` by following the instructions in the previous link. This is where you can specify both your authentication and deployment environment (i.e., database/schema) information.

> [!IMPORTANT]
> The profile name in `~/.dbt/profiles.yml` must match the `profile` field in `dbt_project.yml`. This project uses `profile: 'transform'`, so your `profiles.yml` must have a top-level key named `transform`.
>
> **Additionally**, for each output (see below example project file), you need to specify the `database` you will be deploying dbt models to. A `schema` must also be set, but we override this value in more specific configurations, so it can be any value.
>
> You can configure multiple outputs with varying database, schema, and other configuration settings and specify which output you would like to use at runtime (e.g., `dbt run --target prod ...`). We recommend configuring a default output which works well with setting up a developer environment, like in the example below. 

An example `~/.dbt/profiles.yml` file:
```
transform:
  target: default
  outputs:
    default:
      type: snowflake
      account: mqzfhld-vp00034
      authenticator: externalbrowser
      user: "me@sagebase.org"
      role: DATA_ENGINEER
      warehouse: COMPUTE_XSMALL
      database: SYNAPSE_DATA_WAREHOUSE_DEV_MY_FEATURE
      schema: DUMMY
      threads: 1
    prod:
      type: snowflake
      database: SYNAPSE_DATA_WAREHOUSE
      ...
```

# Data Models

Models are categorized according to their function in the dbt model paradigm.

## Source 
Source data is already loaded into Snowflake tables and dbt is not involved in their deployment. Downstream models are predicated on these tables, which are specified in sources files (e.g., [`_synapse__sources.yml`](./models/staging/synapse/_synapse__sources.yml)).

## Staging Models

[Staging models](https://docs.getdbt.com/best-practices/how-we-structure/2-staging) are located in `models/staging/synapse/`. This layer is intended to handle basic transforms and standardization of column names. 

## Intermediate Models

[Intermediate models](https://docs.getdbt.com/best-practices/how-we-structure/3-intermediate) are derived from one or more staging or intermediate models, typically by joining upon their keys. This is the most flexible layer of models, and serves as an intermediary layer between the staging and mart models.

> [!NOTE]
> dbt recommends organizing intermediate models by business domain, rather than with respect to the data's source system. We stray from this recommendation by consolidating our staging models into a "universal" intermediate model that can be used by multiple business domains. For example, [`int_synapse_acl.sql`](./models/intermediate/synapse/int_synapse_acl.sql) joins ACL-related tables from the staging models to create a single, unified ACL interface -- rather than having multiple business domains duplicate this logic. 

## Mart Models

[Mart models](https://docs.getdbt.com/best-practices/how-we-structure/4-marts) are models which are meant to be exposed to analysts. These models derive their data from one or more intermediate models.

Mart models are organized into subdirectories based on their target database:
- **`marts/synapse_data_warehouse/`**: Models deployed to the `synapse_data_warehouse` database (or corresponding dev database)
- **`marts/sage/`**: Models deployed to the `sage` database (production only)

# Model Materialization

As mentioned earlier, how a data model is materialized is configured independently of the data model itself. The following sections primarily discuss _where_ we materialize models – since that's most pertinent when deploying models to a development database – although how a model is materialized, whether as a table, view, or something else, is configured in a similar way. See [model properties](https://docs.getdbt.com/reference/model-configs) for all the configuration settings we can make upon data models.

## Deployment Environments

This project deploys its models to different environments, each serving a different subset of data models:

### Synapse Data Warehouse

**Database**: `SYNAPSE_DATA_WAREHOUSE` (production) or `SYNAPSE_DATA_WAREHOUSE_DEV` (staging) or `SYNAPSE_DATA_WAREHOUSE_DEV_{my_branch}` (development).

The majority of models deploy here, including:
- All staging models ([`models/staging/`](./models/staging/))
- All intermediate models ([`models/intermediate/`](./models/intermediate/))
- Mart models in [`models/marts/synapse_data_warehouse/`](./models/marts/synapse_data_warehouse/)

### Sage

**Database**: `SAGE` (production only)

Analyst-friendly models that may depend on Synapse data warehouse models. Models in [`models/marts/sage/`](./models/marts/sage/) deploy here.

## Deploying dbt models

There are multiple ways to configure where a model is deployed to. The following list can be read as a hierarchy, where database/schema configurations in later items supersede any configuration set in preceding items:

* In your dbt profile (`~/.dbt/profiles.yml`) 
* In your dbt project file ([`dbt_project.yml`](./dbt_project.yml)).
* In the model properties file (e.g., [`_synapse__models.yml`](./models/staging/synapse/_synapse__models.yml)) 
* In the model file itself (e.g., [`stg_synapse__data_access_submission_status.sql`](./models/staging/synapse/stg_synapse__data_access_submission_status.sql)).

Most of the time, we haven't configured a model's database in this dbt project. This enables you to easily deploy to a development database by configuring the database once in your `~/.dbt/profiles.yml` file. In cases where the database is configured within this dbt project, you can override the destination database by editing one of the files above.

### Schema configuration

Because we deploy models defined in, for example, [`models/staging/synapse`](./models/staging/synapse/) to a consistent schema, irrespective of the database, we usually configure schemas in [`dbt_project.yml`](./dbt_project.yml) based on the model subdirectory.

Since mart models can be surfaced in a variety of different schemas, even when those models live in the same directory, we typically configure their schema in the model properties file (e.g., [`models/marts/synapse_data_warehouse/_synapse_data_warehouse__models.yml`](./models/marts/synapse_data_warehouse/_synapse_data_warehouse__models.yml)) on a per-model basis.

### Deploy by Environment

While only the Synapse data warehouse environment is relevant for deploying to our development database, we have other environments, too. Use selectors to deploy models to a specific environment:

```bash
# Deploy `synapse_data_warehouse` models
dbt run --selector synapse_data_warehouse

# If your `~/.dbt/profiles.yml` looks like the one in our example above,
# the previous command is equivalent to:
dbt run --target default --selector synapse_data_warehouse

# Deploy only `sage` models
dbt run --selector sage
```

For detailed selector configurations, refer to the [selectors.yml](./selectors.yml) file.

### Deploy Specific Models

We can specify a specific model to be deployed, as well. dbt will also deploy the model dependencies if you prefix the model name with a `+`:
```bash
# Deploy just this model
dbt run --select stg_synapse__data_access_submission_status

# Deploy this model and all upstream models
dbt run --select +stg_synapse__data_access_submission_status
```

You can also select all models within specific directories:
```bash
# Deploy all models under a specific mart directory
dbt run --select intermediate
dbt run --select intermediate.synapse
dbt run --select marts.synapse_data_warehouse
```

Check out the dbt [docs](https://docs.getdbt.com/reference/node-selection/syntax) to explore all the powerful ways dbt allows us to specify models during deployment.

### Deploying non-`synapse_data_warehouse` models to a development database

Whereas selectors can control _which_ model set is deployed, the model config controls _where_ a model is deployed.

To change the destination database, either update the appropriate section in [`dbt_project.yml`](./dbt_project.yml) or comment out `+database` for that section so that the database is inherited via your dbt profile database setting.

For example, to change the database where we deploy `sage` models to:
```
models:
  transform:
    marts:
      sage:
        +database: SYNAPSE_DATA_WAREHOUSE_DEV_MY_FEATURE 
```

To change the destination schema, edit either the dbt project file or the model properties file containing the relevant model (for example, [`models/marts/sage/_sage__models.yml`](./models/marts/sage/_sage__models.yml)) and update the model's `config.schema` value.

For example, you can edit the model property file so that a model is materialized in a schema which actually exists in your development database:

```yaml
models:
  - name: data_access_submission_dashboard
    config:
      schema: synapse
```

# Developer Guidelines

For dbt developer guidelines, including structure and style conventions, see [CONTRIBUTING.md](./CONTRIBUTING.md).

# TLDR

- **dbt**: This project uses dbt to model transformations independently from materialization strategy, following dbt's [source -> staging -> intermediate -> mart paradigm](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview).
- **Use-Cases**: Today, dbt in this repository is focused on Synapse RDS snapshot data.
- **Installing and Configuring dbt**: Install dbt Core with the Snowflake adapter using the official setup guide and configure your profile/targets for development and production workflows: [Snowflake setup](https://docs.getdbt.com/docs/core/connect-data-platform/snowflake-setup).
- **Data Models**: Model layers follow dbt conventions, with [sources](https://docs.getdbt.com/docs/build/sources?version=1.12#selecting-from-a-source) and transformation guidance from the dbt docs on [staging models](https://docs.getdbt.com/best-practices/how-we-structure/2-staging), [intermediate models](https://docs.getdbt.com/best-practices/how-we-structure/3-intermediate), and [mart models](https://docs.getdbt.com/best-practices/how-we-structure/4-marts).
- **Model Materialization**: Deployment behavior is controlled hierarchically through [model properties](https://docs.getdbt.com/reference/model-configs), which can be configured at the user level in the [dbt profiles](https://docs.getdbt.com/docs/local/profiles.yml) file, at the project level in the [dbt project](./dbt_project.yml) file, at the model subdirectory level in a [model property](https://docs.getdbt.com/reference/model-properties) file, or at [the model level](https://docs.getdbt.com/reference/model-configs?version=1.12#apply-configurations-to-one-model-only) using an inline jinja macro. We can define subsets of models to deploy in [`selectors.yml`](./selectors.yml) in conjunction with [selection syntax](https://docs.getdbt.com/reference/node-selection/syntax).
- **Developer Guidelines**: Follow local dbt structure and style conventions in [CONTRIBUTING.md](./CONTRIBUTING.md).

