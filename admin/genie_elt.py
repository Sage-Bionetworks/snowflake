import os

from dotenv import dotenv_values
from snowflake.snowpark import Session
import synapseclient

syn = synapseclient.login()

config = dotenv_values("admin/.env")

connection_parameters = {
    "account": config['snowflake_account'],
    "user": config['user'],
    "password": config['password'],
 }

session = Session.builder.configs(connection_parameters).create()


def create_table(database: str, schema: str, table: str, stage: str, filepath: str) -> list:
    """Create a table by uploading a local file to a stage and infering the schema

    Args:
        database (str): Database name
        schema (str): Schema name
        table (str): Table name
        stage (str): Stage name
        filepath (str): File path

    Returns:
        list: List of 10 SQL results
    """
    session.use_database(database)
    session.use_schema(schema)
    session.sql(
        f'CREATE TABLE IF NOT EXISTS {table} (demo STRING)'
    ).collect()

    session.sql(
        f'PUT file://{filepath} @{database}.{schema}.{stage}'
    ).collect()
    session.sql(
        f'CREATE OR REPLACE TABLE {table} USING TEMPLATE ('
            'SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))'
            'WITHIN GROUP (ORDER BY ORDER_ID)'
            'FROM TABLE (INFER_SCHEMA('
            f"LOCATION=>'@{stage}/{os.path.basename(filepath)}',FILE_FORMAT=>'{database}.{schema}.TSV'))"
        ')'
    ).collect()

    session.sql(
        f'COPY INTO {table} '
        f'FROM @{stage}/{os.path.basename(filepath)} '
        f"file_format = (TYPE=CSV FIELD_DELIMITER='\t' SKIP_HEADER = 1)"
    ).collect()
    return session.sql(f"select * from {database}.{schema}.{table} limit 10").collect()

releases = syn.getChildren("syn7844529")
for release in releases:
    release_name = (release['name']
        .replace("Release ", "")
        .replace(".", "_")
        .replace("-public", "")
    )
    release_id = release['id']
    release_files = syn.getChildren(release_id)
    release_file_map = {
        release_file['name']: syn.get(release_file['id'], followLink=True)
        for release_file in release_files
        if release_file['name'].startswith("data_clinical")
    }

    session.use_role("sysadmin")
    session.use_database("genie")
    session.sql(
        f"CREATE SCHEMA IF NOT EXISTS public_{release_name} "
            "WITH MANAGED ACCESS;"
    ).collect()
    session.use_schema(f"public_{release_name}")
    session.sql(
        'CREATE TEMPORARY STAGE IF NOT EXISTS RELEASE_FILES'
    ).collect()
    session.sql(
        'CREATE TEMPORARY FILE FORMAT IF NOT EXISTS TSV '
        "TYPE=CSV FIELD_DELIMITER='\t' RECORD_DELIMITER='\n' "
        "PARSE_HEADER=TRUE"
    ).collect()

    for release_file_key, release_file_ent in release_file_map.items():
        tbl_name = release_file_key.replace("data_", "").replace(".txt", "")
        create_table(database="GENIE",
                     schema=f"public_{release_name}",
                     table=tbl_name,
                     stage="RELEASE_FILES",
                     filepath=release_file_ent.path)


#     session.sql(
#         'CREATE TABLE IF NOT EXISTS "sample" ('
#         "PATIENT_ID STRING,"
#         "SAMPLE_ID STRING,"
#         "AGE_AT_SEQ_REPORT STRING,"
#         "ONCOTREE_CODE STRING,"
#         "SAMPLE_TYPE STRING,"
#         "SEQ_ASSAY_ID STRING,"
#         "CANCER_TYPE STRING,"
#         "CANCER_TYPE_DETAILED STRING,"
#         "SAMPLE_TYPE_DETAILED STRING)"
#     ).collect()
#     session.sql(
#         'CREATE TABLE IF NOT EXISTS "patient" ('
#         "PATIENT_ID STRING,"
#         "SEX STRING,"
#         "PRIMARY_RACE STRING,"
#         "ETHNICITY STRING,"
#         "CENTER STRING,"
#         "INT_CONTACT STRING,"
#         "INT_DOD STRING,"
#         "YEAR_CONTACT STRING,"
#         "DEAD STRING,"
#         "YEAR_DEATH STRING)"
#     ).collect()


# session.read.options({"field_delimiter": ",", "skip_header": 1}).schema(user_schema).csv("@mystage/testCSV.csv")
