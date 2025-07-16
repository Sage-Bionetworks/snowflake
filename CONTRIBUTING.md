# Contributing Guidelines

Welcome, and thanks for your interest in contributing to the `snowflake` repository! :snowflake:

By contributing, you are agreeing that we may redistribute your work under this [license](https://github.com/Sage-Bionetworks/snowflake?tab=Apache-2.0-1-ov-file).

## Development Rules

There are some things you should make a note of before getting started...

1. **Avoid Repeatable Scripts Without Introducing Objects Through V Scripts**:
   Never use repeatable scripts for tables or any other objects that can potentially be dependencies without first introducing these objects in a V script. This ensures that all dependent objects are properly established in the correct sequence.
2. **Branch Naming Convention**:
   If you plan to run the automated testing described in section [Running CI Jobs for Database Testing](#running-ci-jobs-for-database-testing), your branch name needs to start with `snow-`, otherwise the test deployment will fail.
   
## Getting Started

To start contributing, follow the steps below to set up and develop on your local repository. Please note that you must work
on a branch off the original repository rather than a fork.

----

### 1. Clone the Repository

```bash
git clone https://github.com/Sage-Bionetworks/snowflake
```

----

### 2. Fetch the Latest `dev` Branch

After cloning, navigate to the repository directory:

```bash
cd snowflake
```

Then, fetch the latest updates from the `dev` branch to ensure you’re working with the latest codebase:

```bash
git fetch origin dev
```

----

### 3. Create a New Branch Off `dev`

Create and checkout your feature branch from the latest `dev` branch. Name it based on the Jira ticket number and your feature/fix. For example:

```bash
git checkout -b snow-123-new-feature origin/dev
```

Your branch will now be tracking `origin/dev` which you will merge into once your change is approved and merge conflicts are resolved (if any). For more guidance on how to resolve merge conflicts, [see here](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts/about-merge-conflicts#resolving-merge-conflicts).

----

### 4. Script Versioning

Before creating a new versioned script, always verify the latest applied version in the appropriate `change_history` table:

1. **Database-object SQL scripts**

Check the `<database>.schemachange.change_history` table to find the highest version already applied to your target database:

```sql
select *
from synapse_data_warehouse.schemachange.change_history;
```

Name your new script accordingly (e.g. `V{latest_version+0.1}__your_description.sql`).

2. **Admin scripts (e.g. grant, revoke, maintenance)**

Check the `metadata.schemachange.change_history` table to find the highest version applied for admin operations:

```sql
select *
from metadata.schemachange.change_history;
```

Name your new admin script accordingly (e.g. `V{latest_admin_version+0.1}__admin_task.sql`).

----

### 5. Push to The Remote Branch

Once you've made your changes and committed them locally, push your branch to the remote repository:

```
git push origin snow-123-new-feature
```

----

### 6. Open a Draft Pull Request

After pushing your commits in Step 4 to your remote branch, open a pull request (PR) against the dev branch using the GitHub UI. Start your PR in draft mode, and mark it as ready for review after you've implemented all your necessary changes.

Opening your PR (whether in draft or not) will trigger the automated test workflows described in the next section. We recommend reading that section to understand how to further test your changes, OR if you are not introducing changes to the actual Snowflake data repository and want a way to opt-out of these workflow runs.

----

## Running CI Jobs for Database Testing

This repository includes automated CI jobs designed to validate your changes against a cloned version of the database in an isolated environment on Snowflake. Please follow the instructions below to enable this testing:

----

### 1. Open a Draft Pull Request (if not done already)

The moment your draft PR is created, the `test_with_clone` workflow is triggered automatically for your branch. This workflow performs two primary actions:

* Database Cloning: It creates a zero‑copy clone of the development database and applies your schema changes to this clone.
* Schema Validation: It runs tests against the cloned database to verify that your updates work correctly without affecting the production development environment.

After your changes have been successfully validated, you can mark the PR as Ready for Review to proceed to the next steps.

> [!TIP]
> If you are not making changes that require schemachange to run (e.g. documentation updates, or any changes outside of the
> `synapse_data_warehouse` folder) you can opt-out of these workflow runs by adding the `skip_cloning` label to your PR.

----

### 2. Make A Commit

Once the draft PR is in place, any new commit you push to the branch will re-trigger the `test_with_clone` job. Each commit generates a new database clone where your updated schema is tested. Note the following:

* Per-Commit Testing: Every commit triggers a fresh run of the `test_with_clone` job to ensure that your cloned database always reflects your most recent changes.
* Failsafe Mechanism: To prevent conflicts from rapid, successive commits, the system interrupts any incomplete test runs when a new commit is detected. If you encounter any deployment failures, it may be due to this failsafe interrupting overlapping runs.

By organizing the process in this way, the draft PR creation is clearly established as the initial trigger for testing, followed by commits that update and re-run the tests as needed.

> [!IMPORTANT]
> Your cloned database is a clone of the development database as it exists at the time of cloning. Please be mindful that
> **there may have been changes made to the development database since your last clone**. To see the latest changes on
> the development database, you can view the commit history in the `dev` branch.

----

### 3. Perform Inspection using Snowsight

You can go on Snowsight to perform manual inspection of the changes to your schema in your cloned database. We recommend using a SQL worksheet for manual quality assurance queries, e.g. to ensure there is no row duplication in the new/updated tables.

> [!NOTE]
> * You must have access to the `DATA_ENGINEER` role in order to see your cloned database and the changes within it.
> * Your database will be named after your feature branch so it's easy to find on Snowsight. For example, if your feature branch is called
> `snow-123-new-feature`, your database will be called `SYNAPSE_DATA_WAREHOUSE_DEV_snow_123_new_feature`.

----

### 4. Dropping the Cloned Database

Once your cloned database is created for testing, it will remain open until your PR is closed. Once your PR is closed or merged into its target branch (`dev`),
a job will trigger that automatically drops the cloned database which corresponds to your branch.

> [!NOTE]
> An initial clone of the development database will not incur new resource costs, **HOWEVER**, when a clone deviates from the original
> (e.g. new changes to your schema are applied for testing), the cloned database will begin to incur costs the longer it exists in our warehouse.
> **Please be mindful of the amount of time your PR stays open**, as cloned databases do not get dropped until a PR is merged.

----

Following these guidelines helps maintain a clean, efficient, and well-tested codebase. Thank you for contributing!

