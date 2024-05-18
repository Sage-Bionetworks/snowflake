import great_expectations as gx
from great_expectations.checkpoint import Checkpoint


from dotenv import dotenv_values
config = dotenv_values("../.env")

user=config['user']
password=config['password']
snow_account = config['snowflake_account']
database = "synapse_data_warehouse_dev"
context = gx.get_context()

my_connection_string = f"snowflake://{user}:{password}@{snow_account}/{database}/synapse?warehouse=compute_xsmall&role=SYSADMIN"
datasource_name = "synapse_data_warehouse_raw"

datasource = context.sources.add_snowflake(
    name=datasource_name, 
    connection_string=my_connection_string, # Or alternatively, individual connection args
)

asset_name = "node"
asset_table_name = "node_latest"

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
# validator.expect_column_values_to_be_between(
#     "passenger_count", min_value=1, max_value=6
# )
validator.save_expectation_suite(discard_failed_expectations=False)



my_checkpoint_name = "my_snow_checkpoint"

checkpoint = Checkpoint(
    name=my_checkpoint_name,
    run_name_template="%Y%m%d-%H%M%S-my-run-name-template",
    data_context=context,
    batch_request=batch_request,
    expectation_suite_name=expectation_suite_name,
    # action_list=[
    #     {
    #         "name": "store_validation_result",
    #         "action": {"class_name": "StoreValidationResultAction"},
    #     },
    #     {"name": "update_data_docs", "action": {"class_name": "UpdateDataDocsAction"}},
    # ],
)

context.add_or_update_checkpoint(checkpoint=checkpoint)

checkpoint_result = checkpoint.run()


# checkpoint = context.add_or_update_checkpoint(
#     name="my_quickstart_checkpoint",
#     validator=validator,
# )
# checkpoint_result = checkpoint.run()

# context.view_validation_result(checkpoint_result)
