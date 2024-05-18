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
    user=config['user']
    password=config['password']
    snow_account = config['snowflake_account']
    database = "synapse_data_warehouse_dev"
    my_connection_string = f"snowflake://{user}:{password}@{snow_account}/{database}/synapse?warehouse=compute_xsmall&role=SYSADMIN"

    datasource = context.sources.add_snowflake(
        name=datasource_name, 
        connection_string=my_connection_string, # Or alternatively, individual connection args
    )

asset_name = "node"
asset_table_name = "node_latest"
try:
    table_asset = datasource.get_asset(asset_name)
    # datasource = context.get_datasource(datasource_name)
    # print(f"Datasource '{datasource_name}' retrieved successfully.")
except Exception as e:
    table_asset = datasource.add_table_asset(name=asset_name, table_name=asset_table_name)

batch_request = table_asset.build_batch_request()

##
expectation_suite_name = "synapse_data_warehouse_expectations"

context.add_or_update_expectation_suite(expectation_suite_name=expectation_suite_name)
validator = context.get_validator(
    batch_request=batch_request,
    expectation_suite_name=expectation_suite_name,
)
validator.expect_column_values_to_not_be_null("ID")
validator.expect_column_values_to_not_be_null("PARENT_ID")
validator.expect_column_values_to_not_be_null("PROJECT_ID")

# validator.expect_column_values_to_be_between(
#     "passenger_count", min_value=1, max_value=6
# )
validator.save_expectation_suite(discard_failed_expectations=False)
