---
description: "Fetch a Snowflake Streamlit app into this repository and start work using slug-based app selection. Usage: /update-streamlit-dashboard-conversion DATABASE SCHEMA [identifier_or_slug]"
name: "Update Streamlit Dashboard Conversion"
argument-hint: "DATABASE SCHEMA [identifier_or_slug]"
agent: "agent"
---

Work on a Streamlit app from Snowflake in this repository.

Use the skill at [.github/skills/update-streamlit-dashboard-conversion/SKILL.md](.github/skills/update-streamlit-dashboard-conversion/SKILL.md).

Inputs:
- Database: $DATABASE
- Schema: $SCHEMA
- Optional identifier or slug: $IDENTIFIER_OR_SLUG

Requirements:
1. First step must run `.github/skills/update-streamlit-dashboard-conversion/assets/fetch_streamlit_app.sh` directly (via `bash`) to fetch app files.
2. If identifier is missing, list objects, show slug-based choices, and ask user which slug to work on.
3. Communicate app choices and selection by slug (derived from title), not random Snowflake object identifiers.
