from dotenv import dotenv_values
import great_expectations as gx

context = gx.get_context()

# Define the datasource name
datasource_name = "synapse_data_warehouse_raw"

# Retrieve the existing datasource
try:
    datasource = context.get_datasource(datasource_name)
    print(f"Datasource '{datasource_name}' retrieved successfully.")
except Exception as e:
    print(f"Failed to retrieve datasource '{datasource_name}': {str(e)}")
    config = dotenv_values("../.env")
    user = config["user"]
    password = config["password"]
    snow_account = config["snowflake_account"]
    database = "synapse_data_warehouse_dev"
    my_connection_string = f"snowflake://{user}:{password}@{snow_account}/{database}/synapse?warehouse=compute_xsmall&role=SYSADMIN"

    datasource = context.sources.add_snowflake(
        name=datasource_name,
        connection_string=my_connection_string,  # Or alternatively, individual connection args
    )

asset_name = "node"
asset_table_name = "node_latest"
try:
    table_asset = datasource.get_asset(asset_name)
    # datasource = context.get_datasource(datasource_name)
    # print(f"Datasource '{datasource_name}' retrieved successfully.")
except Exception as e:
    table_asset = datasource.add_table_asset(
        name=asset_name, table_name=asset_table_name
    )

batch_request = table_asset.build_batch_request()

##
expectation_suite_name = "node_latest_expectations"

context.add_or_update_expectation_suite(expectation_suite_name=expectation_suite_name)
validator = context.get_validator(
    batch_request=batch_request,
    expectation_suite_name=expectation_suite_name,
)

columns_to_validate = [
    "ID",
    "PARENT_ID",
    "PROJECT_ID",
    "ACTIVITY_ID",
    "ALIAS",
    "ANNOTATIONS",
    "BENEFACTOR_ID",
    "CHANGE_TIMESTAMP",
    "CHANGE_TYPE",
    "CHANGE_USER_ID",
    "COLUMN_MODEL_IDS",
    "CREATED_BY",
    "CREATED_ON",
    "DEFINING_SQL",
    "DERIVED_ANNOTATIONS",
    "EFFECTIVE_ARS",
    "FILE_HANDLE_ID",
    "INTERNAL_ANNOTATIONS",
    "IS_CONTROLLED",
    "IS_PUBLIC",
    "IS_RESTRICTED",
    "IS_SEARCH_ENABLED",
    "ITEMS",
    "MODIFIED_BY",
    "MODIFIED_ON",
    "NAME",
    "NODE_TYPE",
    "REFERENCE",
    "SCOPE_IDS",
    "SNAPSHOT_DATE",
    "SNAPSHOT_TIMESTAMP",
    "VERSION_COMMENT",
    "VERSION_LABEL",
    "VERSION_NUMBER",
]

for column in columns_to_validate:
    validator.expect_column_values_to_not_be_null(column)

valid_node_types = [
    "materializedview",
    "folder",
    "entityview",
    "submissionview",
    "project",
    "table",
    "dataset",
    "datasetcollection",
    "dockerrepo",
    "virtualtable",
    "file",
    "link",
]

# Add an expectation for the NODE_TYPE column
validator.expect_column_values_to_be_in_set(
    column="NODE_TYPE",
    value_set=valid_node_types,
)
validator.expect_column_values_to_be_unique(column="ID")

# validator.expect_column_pair_values_a_to_be_greater_than_b(
#     column_A="CHANGE_TIMESTAMP",
#     column_B="MODIFIED_ON",
#     or_equal=True
# )

validator.save_expectation_suite(discard_failed_expectations=False)
