SELECT table_schema, table_name, table_type
FROM SYNAPSE_DATA_WAREHOUSE.information_schema.tables
WHERE table_name IN (<UPPERCASE_NAME_LIST>)
ORDER BY table_schema, table_name;
