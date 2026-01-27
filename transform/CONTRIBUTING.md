# Style and Structure

DBT has a [docs section on structure](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview) which we can use (or an AI agent can use) to guide our developer conventions. These are not strict rules, but instead are helpful guidelines for ensuring a consistent developer experience. 

Similarly, there are [separate dbt docs](https://docs.getdbt.com/best-practices/how-we-style/0-how-we-style-our-dbt-projects) for the style of our DBT projects.

The most pertinent structure/style convention we've adopted is in how we organize and name our DBT models. Organization of files in folders can be dependent on model layer (for example, staging vs. intermediate), data source, or business domain. Similar factors influence model file naming conventions. The simplest way to understand how this works in practice is to follow [the pattern already established](./models/) by preexisting models. For more details, see the docs on structure linked above.