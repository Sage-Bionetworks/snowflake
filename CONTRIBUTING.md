# Contributing Guidelines

Welcome, and thanks for your interest in contributing to the `snowflake` repository! :snowflake:

By contributing, you are agreeing that we may redistribute your work under this [license](https://github.com/Sage-Bionetworks/snowflake/tree/snow-90-auto-db-clone?tab=License-1-ov-file#).

## Development Rules

There are some things you should make a note of before getting started...

1. **Avoid Repeatable Scripts Without Introducing Objects Through V Scripts**:
   Never use repeatable scripts for tables or any other objects that can potentially be dependencies without first introducing these objects in a V script. This ensures that all dependent objects are properly established in the correct sequence.
2. **Branch Naming Convention**:
   If you plan to run the automated testing described in section [Running CI Jobs for Database Testing](#running-ci-jobs-for-database-testing), your branch name needs to start with `snow-`, otherwise the test deployment will fail.
   
## Getting Started

To start contributing, follow these steps to set up and develop on your local repository:

### 1. Clone the Repository

```bash
git clone https://github.com/Sage-Bionetworks/snowflake
```

### 2. Fetch the Latest `dev` Branch

After cloning, navigate to the repository directory:

```bash
cd snowflake
```

Then, fetch the latest updates from the `dev` branch to ensure you’re working with the latest codebase:

```bash
git fetch origin dev
```

### 3. Create a New Branch Off `dev`

Create and checkout your feature branch from the latest `dev` branch. Name it based on the Jira ticket number and your feature/fix. For example:

```bash
git checkout -b snow-123-new-feature origin/dev
```

Your branch will now be tracking `origin/dev` which you will merge into once your change is approved and merge conflicts are resolved (if any). For more guidance on how to resolve merge conflicts, [see here](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts/about-merge-conflicts#resolving-merge-conflicts).

### 4. Push to The Remote Branch

Once you've made your changes and committed them locally, push your branch to the remote repository:

```
git push origin snow-123-new-feature
```

### 5. Create a Draft Pull Request

In order to initiate automated testing you will need to work on a draft pull request (PR) on GitHub. After pushing your commits to
the remote branch in Step 4, use the GitHub UI to initate a PR and convert it to draft mode.

After testing your changes against `schemachange` using the instructions in [Running CI Jobs for Database Testing](#running-ci-jobs-for-database-testing),
you can then take your PR out of draft mode by marking it as Ready for Review in the GitHub UI.

## Running CI Jobs for Database Testing

This repository includes automated CI jobs to validate changes against a cloned database. If you want to trigger these jobs to test your changes in an isolated database environment on Snowflake, please follow the steps below:

### 1. Add the Label

By default, each new commit you make in a PR will trigger the `create_clone_and_run_schemachange` job to trigger for your branch. This job does two things:

1. Creates a zero-copy clone of the database and runs your proposed schema changes against it.
2. Tests your schema changes on a cloned version of the development database, verifying that your updates work correctly without
affecting the real development database. After the PR is merged, the clone is automatically dropped to free up resources.

> [!IMPORTANT]
> Your cloned database is a clone of the development database as it exists at the time of cloning. Please be mindful that
> **there may have been changes made to the development database since your last clone**. To see the latest changes on
> the development database, you can view the commit history in the `dev` branch.

> [!NOTE]
> By default, every commit you make in your branch will trigger the clone to be created and schemachange to be executed.
> If you are not making changes that require schemachange to run (e.g. documentation updates, or any changes outside of the
> `synapse_data_warehouse` folder) you can opt-out of these workflow runs by adding the `skip_cloning` label to your PR.

### 2. Perform Inspection using Snowsight

You can go on Snowsight to perform manual inspection of the schema changes in your cloned database. We recommend using a SQL worksheet for manual quality assurance queries, e.g. to ensure there is no row duplication in the new/updated tables.

> [!TIP]
> Your database will be named after your feature branch so it's easy to find on Snowsight. For example, if your feature branch is called
> `snow-123-new-feature`, your database might be called `SYNAPSE_DATA_WAREHOUSE_DEV_snow_123_new_feature`.

### 3. Manually Drop the Cloned Database (Optional)

There is a second job in the repository (`drop_clone`) that will drop your branch's database clone once it has been merged into `dev`.
In other words, once your cloned database is created for testing, it will remain open until your PR is closed (unless you manually drop it).

An initial clone of the development database will not incur new resource costs, **HOWEVER**, when a clone deviates from the original
(e.g. new schema changes are applied for testing), the cloned database will begin to incur costs the longer it exists in our warehouse.
**Please be mindful of the amount of time your PR stays open**, as cloned databases do not get dropped until a PR is merged. For example, if your PR is open for >1 week, consider manually dropping your cloned database on Snowflake to avoid unnecessary cost.

> [!NOTE]
> Keep in mind that after dropping your cloned database, you will still have access to it through Snowflake's "Time Travel"
> feature. Your database is retained through "Time Travel" for X amount of time before it is permanently deleted. To see
> how long your database can be accessed after dropping, run the following query in a SQL worksheet on Snowsight and look
> for the keyword `DATA_RETENTION_TIME_IN_DAYS`:
> 
> ```
> SHOW PARAMETERS IN DATABASE <your-database-name>;
> ```

Following these guidelines helps maintain a clean, efficient, and well-tested codebase. Thank you for contributing!
