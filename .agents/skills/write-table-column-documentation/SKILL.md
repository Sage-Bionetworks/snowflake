---
name: write-table-column-documentation
description: Write or review warehouse table and column descriptions in this repository. Use when adding or editing dbt YAML descriptions or schemachange SQL COMMENT statements for developer-facing source, staging, and intermediate objects or analyst-facing tables and models.
---

# Table and column descriptions

Apply this style guide when writing or reviewing warehouse table and column descriptions maintained through dbt or schemachange.

## Location, audience, and scope

- dbt table and column descriptions are typically recorded in `*__models.yml` files. Source table descriptions belong in the source YAML; Synapse sources are declared in `transform/models/staging/synapse/_synapse__sources.yml`. Schemachange-managed objects use SQL `COMMENT` statements or inline DDL comments.
- Match the amount of technical detail to the object's purpose and audience, rather than its management framework. Source tables and staging and intermediate models are for developers. Mart models and other analyst-facing tables should have high-level, mostly non-technical descriptions.
- Information about how data is collected belongs in the source table description. Downstream models may benefit from relevant contextual information drawn from one or more source tables from which they derive.
- Individual field definitions belong in column descriptions. Table descriptions may explain grain, cross-column behavior, aggregate relationships, and event-dependent NULLs when these affect interpretation of the table as a whole.
- Include the guidance below where it materially helps correct use; not every description needs every kind of detail.

## Developer table and model descriptions

For source tables and staging and intermediate models:

- The first sentence should read: "The {layer} [model/table] for {data type} data." Choose `model` or `table` as appropriate and fill in the layer and data type.
- Additional sentences may:
  - Give important contextual information about the data, such as how it was collected (in the source table), the model's grain, or general caveats for use.
  - Briefly state the types of transforms performed or data types sourced from.
  - Include details about the motivation for the specific implementation.

## Analyst table and model descriptions

For mart models and other analyst-facing tables:

- The first sentence should clearly state the type of data contained in the model.
- The second sentence should state the model's grain, identifying the specific `columns` which uniquely identify a row.
- Prefer "one row per ..." to describe grain rather than "indexed by ...", which can suggest a physical index. Distinguish a surrogate primary key from the business grain it represents.
- Additional sentences may give important contextual information about how the data was collected or organized.
- Aggregate models should include these sentences explaining their structure, replacing the bracketed placeholders with the relevant aggregate grain and example statistics:

  > Any columns in this table which contain information about the aggregate itself, such as the particular period, date, or the [aggregate grain] have their column name prefixed with `agg_`. Columns which represent aggregate statistics, such as [...] lack this prefix.

- You may use Confluence wiki markup to better organize long text.

## Row, event, and temporal semantics

- State whether a row represents an individual event, a snapshot, a latest observation, or a deduplicated record. Explain what triggers inclusion, important exclusions (including success or failure coverage), and whether recorded activity only approximates the named action, such as URL generation approximating a download.
- Distinguish changes to an entity from metadata enrichment when both produce rows.
- Distinguish business event, modification, queue, recording, and snapshot timestamps. Describe relevant lag, freshness, deletion handling, and known coverage gaps.
- Explain event-dependent field availability, such as which fields remain populated for DELETE records.

## Aggregate interpretation

- Describe supported temporal grains and non-time aggregation levels, including their dimensions, coverage restrictions, and unsupported combinations. Explain variable row grain when a table contains multiple aggregation levels.
- For each metric, describe its counting unit, population, attribution date, inclusion/exclusion rules, and distinctness or deduplication where relevant.
- Give useful formulas, units, correct denominators, and relationships between metrics. For example, explain how a sum and count produce an average or when two counts are equal.
- Explain misleading ratios or cohort interpretations when metrics count different populations. Different populations may overlap; do not call them disjoint without evidence.
- State important analytical limitations and the kind of data needed to answer unsupported questions, such as a cohort-keyed model.
- Document whether period boundaries are inclusive or exclusive and how special periods such as all-time behave.
- Distinguish period closure from metric stability. Explain the completion condition, whether completed metrics can change on later refreshes, and the conditions required for finality.

## Column descriptions

- For a primary key column in an analyst-facing table or model, preface its description with "PRIMARY KEY." or "PRIMARY KEY (Composite)." as appropriate.
- Reuse established descriptions for data type agnostic fields whose meaning is consistent across tables, such as `snapshot_timestamp`, `stack`, or `instance`. Look for existing definitions in both dbt YAML and schemachange SQL. Adapt descriptions only where the field's semantics or caveats differ; matching column names alone does not establish equivalent meaning.
- Prefer a single sentence for simple Boolean columns: "If true, ..., [otherwise ...]". Additional sentences may explain consequential conditions, exceptions, or caveats.
- The first sentence should clearly state the high-level semantic meaning of the column.
- Additional sentences may:
  - Describe important caveats to interpreting the column's data.
  - Describe when a column applies, how its meaning changes by row type, any fallback behavior, and what NULL or empty values mean. Include relevant units and ranges.
  - For categorical data, list each category if there are fewer than 8 distinct values; otherwise, provide just a few examples. If the meaning of each category is not self-evident, provide a brief definition of each category.

## Practical usage guidance and examples

- Document useful join targets and joining columns, and explain what additional information the join provides.
- Include filtering guidance when it materially helps correct or efficient use. Verify performance and implementation claims, such as partitioning behavior, before documenting them.
- Use small example rows or worked examples when they clarify behavior or consequential distinctions that prose alone may obscure.
