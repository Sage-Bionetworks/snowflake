from dotenv import dotenv_values
import great_expectations as gx

context = gx.get_context()
from expectations.expect_column_values_to_have_list_members import ExpectColumnValuesToHaveListMembers

# Define the datasource name
# datasource_name = "synapse_data_warehouse_raw"
datasource_name = "synapse_data_warehouse"

# Retrieve the existing datasource
datasource = context.get_datasource(datasource_name)
print(f"Datasource '{datasource_name}' retrieved successfully.")

assets = {
    # "node": "node_latest_expectations",
    # "file": "file_latest_expectations",
    "ad_portal": "ad_portal_expectations"
}

for asset_name, expectation_suite_name in assets.items():
    table_asset = datasource.get_asset(asset_name)
    # datasource = context.get_datasource(datasource_name)
    # print(f"Datasource '{datasource_name}' retrieved successfully.")
    batch_request = table_asset.build_batch_request()
    validator = context.get_validator(
        batch_request=batch_request,
        expectation_suite_name=expectation_suite_name,
    )
    my_checkpoint_name = "my_snow_checkpoint"

    checkpoint = context.add_or_update_checkpoint(
        name=my_checkpoint_name,
        validator=validator,
    )
    checkpoint_result = checkpoint.run(run_name=asset_name)


context.view_validation_result(checkpoint_result)
