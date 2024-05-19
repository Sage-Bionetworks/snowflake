from dotenv import dotenv_values
import great_expectations as gx

context = gx.get_context()
from expectations.expect_column_values_to_have_list_members import ExpectColumnValuesToHaveListMembers

# Define the datasource name
datasource_name = "synapse_data_warehouse"

query = """
SELECT
    ID,
    NAME,
    -- annotations from the current portal fileview at syn11346063.2
    ANNOTATIONS:annotations:study:value AS STUDY,
    ANNOTATIONS:annotations:dataType:value AS DATATYPE,
    ANNOTATIONS:annotations:assay:value AS ASSAY,
    ANNOTATIONS:annotations:organ:value[0] AS ORGAN,
    ANNOTATIONS:annotations:tissue:value AS TISSUE,
    ANNOTATIONS:annotations:species:value AS SPECIES,
    ANNOTATIONS:annotations:sex:value AS SEX,
    ANNOTATIONS:annotations:consortium:value[0] AS CONSORTIUM,
    ANNOTATIONS:annotations:grant:value AS GRANTNUMBER,
    ANNOTATIONS:annotations:modelSystemName:value AS MODELSYSTEMNAME,
    ANNOTATIONS:annotations:treatmentType:value[0] AS TREATMENTTYPE,
    ANNOTATIONS:annotations:specimenID:value[0] AS SPECIMENID,
    ANNOTATIONS:annotations:individualIdSource:value[0] AS INDIVIDUALIDSOURCE,
    ANNOTATIONS:annotations:specimenIdSource:value[0] AS SPECIMENIDSOURCE,
    ANNOTATIONS:annotations:resourceType:value[0] AS RESOURCETYPE,
    ANNOTATIONS:annotations:dataSubtype:value[0] AS DATASUBTYPE,
    ANNOTATIONS:annotations:metadataType:value[0] AS METADATATYPE,
    ANNOTATIONS:annotations:assayTarget:value[0] AS ASSAYTARGET,
    ANNOTATIONS:annotations:analysisType:value[0] AS ANALYSISTYPE,
    ANNOTATIONS:annotations:cellType:value AS CELLTYPE,
    ANNOTATIONS:annotations:nucleicAcidSource:value[0] AS NUCLEICACIDSOURCE,
    ANNOTATIONS:annotations:fileFormat:value[0] AS FILEFORMAT,
    ANNOTATIONS:annotations:group:value AS GROUPS,
    ANNOTATIONS:annotations:isModelSystem:value[0] AS ISMODELSYSTEM,
    ANNOTATIONS:annotations:isConsortiumAnalysis:value[0] AS ISCONSORTIUMANALYSIS, -- noqa: LT05
    ANNOTATIONS:annotations:isMultiSpecimen:value[0] AS ISMULTISPECIMEN,
    ANNOTATIONS:annotations:metaboliteType:value AS METABOLITETYPE,
    ANNOTATIONS:annotations:chromosome:value[0] AS CHROMOSOME,
    ANNOTATIONS:annotations:modelSystemType:value[0] AS MODELSYSTEMTYPE,
    ANNOTATIONS:annotations:libraryPrep:value[0] AS LIBRARYPREP,
    -- add some annotations that are not in the current fileview
    ANNOTATIONS:annotations:cohort:value AS COHORT,
    ANNOTATIONS:annotations:dataContributionGroup:value AS DATACONTRIBUTIONGROUP, -- noqa: LT05
    ANNOTATIONS:annotations:dataGenerationSite:value[0] AS DATAGENERATIONSITE,
    ANNOTATIONS:annotations:isSampleExchange:value[0] AS ISSAMPLEEXCHANGE,
    ANNOTATIONS:annotations:batch:value[0] AS BATCH
FROM SYNAPSE_DATA_WAREHOUSE.SYNAPSE.NODE_LATEST
WHERE PROJECT_ID = '2580853' AND NODE_TYPE = 'file';
"""

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
    database = "synapse_data_warehouse"
    my_connection_string = f"snowflake://{user}:{password}@{snow_account}/{database}/synapse?warehouse=compute_xsmall&role=SYSADMIN"

    datasource = context.sources.add_snowflake(
        name=datasource_name, 
        connection_string=my_connection_string, # Or alternatively, individual connection args
    )

asset_name = "ad_portal"
try:
    table_asset = datasource.get_asset(asset_name)
    # datasource = context.get_datasource(datasource_name)
    # print(f"Datasource '{datasource_name}' retrieved successfully.")
except Exception as e:
    table_asset = datasource.add_query_asset(name=asset_name, query=query)

batch_request = table_asset.build_batch_request()
expectation_suite_name = "ad_portal_expectations"

context.add_or_update_expectation_suite(expectation_suite_name=expectation_suite_name)
validator = context.get_validator(
    batch_request=batch_request,
    expectation_suite_name=expectation_suite_name,
)

columns_to_validate = [
    "ID", 
    # "NAME",
    # "STUDY",
    # "DATATYPE",
    # "ASSAY",
    # "ORGAN",
    # "TISSUE",
    # "SPECIES",
    # "SEX",
    # "CONSORTIUM",
    # "GRANTNUMBER",
    # "MODELSYSTEMNAME",
    # "TREATMENTTYPE",
    # "SPECIMENID",
    # "INDIVIDUALIDSOURCE",
    # "SPECIMENIDSOURCE",
    # "RESOURCETYPE",
    # "DATASUBTYPE",
    # "METADATATYPE",
    # "ASSAYTARGET",
    # "ANALYSISTYPE",
    # "CELLTYPE",
    # "NUCLEICACIDSOURCE",
    # "FILEFORMAT",
    # "GROUPS",
    # "ISMODELSYSTEM",
    # "ISCONSORTIUMANALYSIS",
    # "ISMULTISPECIMEN",
    # "METABOLITETYPE",
    # "CHROMOSOME",
    # "MODELSYSTEMTYPE",
    # "LIBRARYPREP",
    # "COHORT",
    # "DATACONTRIBUTIONGROUP",
    # "DATAGENERATIONSITE",
    # "ISSAMPLEEXCHANGE",
    # "BATCH"
]

for column in columns_to_validate:
    validator.expect_column_values_to_not_be_null(column)

# validator.expect_column_values_to_be_in_set(
#     column="datatype",
#     value_set=allowed_values,
# # )
validator.expect_column_values_to_have_list_members(
    column="datatype",
    list_members={
        "Pharmacokinetic Study",
        "analysis",
        "behavior process",
        "chromatinActivity",
        "clinical",
        "demographic",
        "electrophysiology",
        "epigenetics",
        "gene expression",
        "geneExpression",
        "genomicVariants",
        "image",
        "immunoassay",
        "mRNA",
        "metabolomics",
        "metagenomics",
        "proteomics"
    }
)
# Usage of the custom expectation remains the same as in the initial code

validator.save_expectation_suite(discard_failed_expectations=False)
