# Rejection classification experiment

The standalone staging view, `stg_synapse__data_access_submission_rejection`, contains only the submission ID and decoded rejection reason for rejected submissions. It retains the status staging model's pre-2019 decoding safeguard. Sampling excludes null and blank reasons. The staging view performs no AI inference.

The category macro defines the agreed 16 labels and their boundary descriptions. Classification uses multi-label output so one submission can contribute to several categories. `Other` covers both unclear explanations and explicitly stated reasons outside the catalog; it can accompany a specific category when the explanation contains an additional unmapped problem.

## Environment

The draft PR workflow creates the feature database and staging view. For this experiment, the production source is copied into the corresponding clone location:

```sql
CREATE OR REPLACE DYNAMIC TABLE
    SYNAPSE_DATA_WAREHOUSE_DEV_SNOW_406_REJECTION_CLASSIFICATION.RDS_RAW.DATA_ACCESS_SUBMISSION_STATUS
    CLONE SYNAPSE_DATA_WAREHOUSE.RDS_RAW.DATA_ACCESS_SUBMISSION_STATUS
    COPY GRANTS;
```

Verify that the cloned dynamic table is suspended before testing. Keep it suspended to retain a stable snapshot. The feature database is recreated by the clone workflow, so subsequent workflow runs can discard the copied source and manually created result tables.

The calling role needs both the Cortex database role and an AI function privilege. `DATA_ENGINEER` already has `SNOWFLAKE.CORTEX_USER`; an account administrator must grant any missing function permission:

```sql
GRANT USE AI FUNCTION AI_CLASSIFY ON ACCOUNT TO ROLE DATA_ENGINEER;
```

This account-level grant is a separate administrative prerequisite, not part of the dbt deployment.

## Execute a sample

Use a local dbt profile whose `clone` target points to the feature database above. From `transform/`, compile a 10-record pilot:

```sh
uv run --group dbt dbt compile --target clone \
  --select data_access_rejection_classification \
  --vars '{"rejection_sample_size": 10, "rejection_sample_seed": 406}' \
  --no-introspect --no-populate-cache
```

Run the compiled SELECT in a manually created table through the Snowflake CLI:

```sql
ALTER SESSION SET QUERY_TAG = 'SNOW-406:pilot-10:v1';
CREATE TABLE
    SYNAPSE_DATA_WAREHOUSE_DEV_SNOW_406_REJECTION_CLASSIFICATION.RDS_RAW.DATA_ACCESS_REJECTION_CLASSIFICATION_10
    AS
    -- Paste the compiled classification SELECT here.
;
```

```sh
uvx --from snowflake-cli snow sql --connection default \
  --database SYNAPSE_DATA_WAREHOUSE_DEV_SNOW_406_REJECTION_CLASSIFICATION \
  --schema RDS_RAW --filename /path/to/manual-sample.sql
```

The classification SELECT calls a paid AI function. Queries against the persisted result table do not repeat inference. Use a new result table when changing a prompt or sampling configuration to preserve the prior results.

Inspect all ten reasons and labels before increasing the sample size. The historical sample uses a deterministic hash of submission ID and seed. Set `rejection_sample_order` to `recent` to order by the raw status modification time. For example, compile a historical sample of 1,000 and a recent sample of 500, then execute each in its own result table.

## Evaluate persisted results

Compile these read-only analyses with `rejection_result_table` set to the unqualified result table name:

- `data_access_rejection_classification_validation`: errors, blank inputs, missing or malformed label arrays, and labels outside the catalog.
- `data_access_rejection_category_distribution`: counts and percentages for all 16 categories, including zero counts. Percentages can sum to more than 100 because classification is multi-label.
- `data_access_rejection_classification_review`: all `Other` assignments and missing labels or errors, with the original explanation for review.

Review the reason text as well as the distribution. Low counts do not demonstrate that a category is unnecessary; a rare policy restriction can still be meaningful. Look for positive examples in the full eligible source before deciding to combine or remove a category. Label keyword-selected samples as targeted examples rather than representative distributions.

Record how many assignments were reviewed, common false positives or omissions, and whether `Other` reflects a real catalog gap or a classification mistake. Keep raw explanations out of the repository and PR because they can contain personal information. Agent review can guide prompt changes, but it is not a governance-reviewed accuracy benchmark.

*This text was generated in whole or part by AI and has been reviewed for correctness by myself.*
