"""GENIE ELT pipeline"""
import os

from dotenv import dotenv_values
import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
import synapseclient


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

    cs = ctx.cursor()
    # releases = syn.getChildren("syn27056697")
    clinical_files = syn.getChildren("syn30358089")
    cbioportal_files = syn.getChildren("syn30358098")

    schema_name = "nsclc_public_02_0"
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
            .replace("genie_nsclc_", "")
            .replace("cna_hg19.seg", "seg")
        )
        # TODO: error when uploading SEG file and CNA file
        exclude = ("gene_panel", "meta", "CNA", "case_lists", "seg")
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


if __name__ == "__main__":
    main()
