---
description: "Provision a new analyst schema in the Snowflake SAGE database with full RBAC, migrations, and user grants. Usage: /procure-sage-analyst-schema SCHEMA_NAME [user1,user2,...] [cross-functional-role]"
name: "Procure SAGE Analyst Schema"
argument-hint: "SCHEMA_NAME [analyst_users_csv] [cross_functional_role]"
agent: "agent"
---

Provision a new analyst schema in the Snowflake SAGE database following the established RBAC pattern.

Use the skill at [.github/skills/procure-sage-analyst-schema/SKILL.md](.github/skills/procure-sage-analyst-schema/SKILL.md) to complete this task end-to-end.

**Schema to provision:** $SCHEMA_NAME (if not provided, ask the user)

**Inputs to gather if not provided:**
1. Schema name (e.g. NF, ARK, GENIE, AMP_ALS)
2. Does this schema already exist in Snowflake? (affects ownership grant and schema init)
3. Which users should receive the analyst role? (email prefixes, e.g. `james.moon`)
4. Is there a cross-functional role to inherit the analyst role (e.g. `TECH_PRODUCT`)? Optional.
5. Is there a legacy role to drop (e.g. `<SCHEMA>_ADMIN` predating this naming convention)?
6. Git branch name / Jira ticket number for the commit

**Hard constraints — never skip:**
- Do NOT grant `SAGE_<SCHEMA>_ANALYST` to `DATA_ANALYTICS`
- ALWAYS grant `USAGE ON WAREHOUSE STREAMLIT_XSMALL` to both the admin and analyst roles
