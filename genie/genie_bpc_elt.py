"""GENIE ELT pipeline"""
import os

from dotenv import dotenv_values
import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
import synapseclient


def create_snowflake_resources(
    ctx: snowflake.connector.connect,
    syn: synapseclient.Synapse,
    cohort: str,
    version: str,
    clinical_synid: str,
    cbioportal_synid: str
):
    cs = ctx.cursor()
    clinical_files = syn.getChildren(clinical_synid)
    cbioportal_files = syn.getChildren(cbioportal_synid)
    schema_name = f"{cohort}_{version}"
    cs.execute(
        f"CREATE SCHEMA IF NOT EXISTS {schema_name} WITH MANAGED ACCESS;"
    )
    cs.execute(f"USE SCHEMA {schema_name}")

    for clinical_file in clinical_files:
        print(clinical_file['name'])
        table_name = clinical_file['name'].replace(".csv", "")
        clinical_entity = syn.get(clinical_file['id'])
        clin_df = pd.read_csv(
            clinical_entity.path,
            comment="#",
            low_memory=False
        )
        write_pandas(
            ctx,
            clin_df,
            table_name,
            auto_create_table=True,
            quote_identifiers=False,
            overwrite=True
        )

    for cbioportal_file in cbioportal_files:
        # print(cbioportal_file['name'])
        table_name = (cbioportal_file['name']
            .replace("data_", "")
            .replace(".txt", "")
            .replace(f"genie_{cohort}_", "")
            .replace("cna_hg19.seg", "seg")
        )
        # TODO: error when uploading SEG file and CNA file
        exclude = ("gene_panel", "meta", "CNA", "case_lists", "seg", "tmb")
        if not table_name.startswith(exclude):
            print(table_name)
            table_ent = syn.get(cbioportal_file['id'])
            table_df = pd.read_csv(
                table_ent.path,
                sep="\t",
                comment="#",
                low_memory=False
            )
            write_pandas(
                ctx,
                table_df,
                table_name,
                auto_create_table=True,
                quote_identifiers=False,
                overwrite=True
            )

def main():
    """GENIE BPC ELT pipeline"""
    syn = synapseclient.login()

    config = dotenv_values("../.env")

    ctx = snowflake.connector.connect(
        user=config['user'],
        password=config['password'],
        account=config['snowflake_account'],
        database="genie",
        role="SYSADMIN",
        warehouse="compute_xsmall"
    )
    cohorts = [
        {
            "cohort": "nsclc",
            "version": "public_02_2",
            "clinical_synid": "syn30358089",
            "cbioportal_synid": "syn30358098"
        },
        {
            "cohort": "crc",
            "version": "public_02_2",
            "clinical_synid": "syn39802567",
            "cbioportal_synid": "syn39802595"
        },
        {
            "cohort": "bladder",
            "version": "consortium_01_1",
            "clinical_synid": "syn28495599",
            "cbioportal_synid": "syn26958249"
        },
        {
            "cohort": "bladder",
            "version": "consortium_01_2",
            "clinical_synid": "syn53018574",
            "cbioportal_synid": "syn53018728"
        },
        {
            "cohort": "brca",
            "version": "consortium_01_1",
            "clinical_synid": "syn26253353",
            "cbioportal_synid": "syn24981909"
        },
        {
            "cohort": "brca",
            "version": "consortium_01_2",
            "clinical_synid": "syn39802381",
            "cbioportal_synid": "syn32299078"
        },
        {
            "cohort": "crc",
            "version": "consortium_01_1",
            "clinical_synid": "syn24166685",
            "cbioportal_synid": "syn23561876"
        },
        {
            "cohort": "crc",
            "version": "consortium_01_2",
            "clinical_synid": "syn26046784",
            "cbioportal_synid": "syn25998993"
        },
        {
            "cohort": "crc",
            "version": "public_preview_02_0",
            "clinical_synid": "syn39802279",
            "cbioportal_synid": "syn30381296"
        },
        {
            "cohort": "nsclc",
            "version": "consortium_01_1",
            "clinical_synid": "syn22418966",
            "cbioportal_synid": "syn22679734"
        },
        {
            "cohort": "nsclc",
            "version": "public_preview_02_0",
            "clinical_synid": "syn27245047",
            "cbioportal_synid": "syn27199149"
        },
        {
            "cohort": "nsclc",
            "version": "consortium_02_1",
            "clinical_synid": "syn25982471",
            "cbioportal_synid": "syn25471745"
        },
        {
            "cohort": "panc",
            "version": "consortium_01_1",
            "clinical_synid": "syn27244194",
            "cbioportal_synid": "syn26288998"
        },
        {
            "cohort": "panc",
            "version": "consortium_01_2",
            "clinical_synid": "syn50612197",
            "cbioportal_synid": "syn50697830"
        },
        {
            "cohort": "prostate",
            "version": "consortium_01_1",
            "clinical_synid": "syn28495574",
            "cbioportal_synid": "syn26471041"
        },
        {
            "cohort": "prostate",
            "version": "consortium_01_2",
            "clinical_synid": "syn50612196",
            "cbioportal_synid": "syn50697637"
        }
    ]

    for cohort_info in cohorts:
        cohort = cohort_info['cohort']
        version = cohort_info['version']
        clinical_synid = cohort_info['clinical_synid']
        cbioportal_synid = cohort_info['cbioportal_synid']
        print(cohort, version)
        create_snowflake_resources(
            ctx=ctx,
            syn=syn,
            cohort=cohort,
            version=version,
            clinical_synid=clinical_synid,
            cbioportal_synid=cbioportal_synid
        )
    ctx.close()

if __name__ == "__main__":
    main()
