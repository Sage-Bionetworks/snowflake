"""GENIE ELT pipeline"""
import os

from dotenv import dotenv_values
import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
import synapseclient


def main():
    """GENIE ELT pipeline"""
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
    # data_CNA
    structured_data = (
        "data_clinical", "data_mutations",
        "assay_information", "data_cna_hg19", "data_gene_matrix",
        "data_sv", "genomic_information"
    )
    releases = syn.getChildren("syn7844529")
    for release in releases:
        if release['name'] != "Release 15.0-public":
            continue
        print(release['name'])
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
            if release_file['name'].startswith(structured_data) and
            release_file['name'].endswith("txt")
        }

        cs.execute(
            f"CREATE SCHEMA IF NOT EXISTS public_{release_name} WITH MANAGED ACCESS;"
        )
        for release_file_key, release_file_ent in release_file_map.items():
            cs.execute(f"USE SCHEMA public_{release_name}")
            tbl_name = (release_file_key
                .replace("data_", "")
                .replace(".txt", "")
                .replace(".seg", "")
            )
            print(tbl_name)
            table_df = pd.read_csv(
                release_file_ent.path,
                sep="\t",
                comment="#",
                low_memory=False
            )
            write_pandas(
                ctx,
                table_df,
                tbl_name,
                auto_create_table=True,
                quote_identifiers=False,
                overwrite=True
            )

    release_files = syn.getChildren("syn53294438")
    release_name = "16_1"
    release_file_map = {
        release_file['name']: syn.get(release_file['id'], followLink=True)
        for release_file in release_files
        if release_file['name'].startswith(structured_data) and
        release_file['name'].endswith("txt")
    }

    cs.execute(
        f"CREATE SCHEMA IF NOT EXISTS consortium_{release_name} WITH MANAGED ACCESS;"
    )
    cs.execute(f"USE SCHEMA consortium_{release_name}")
    for release_file_key, release_file_ent in release_file_map.items():
        tbl_name = (release_file_key
            .replace("data_", "")
            .replace(".txt", "")
            .replace(".seg", "")
        )
        print(tbl_name)
        table_df = pd.read_csv(
            release_file_ent.path,
            sep="\t",
            comment="#",
            low_memory=False
        )
        write_pandas(
            ctx,
            table_df,
            tbl_name,
            auto_create_table=True,
            quote_identifiers=False,
            overwrite=True
        )
    ctx.close()

if __name__ == "__main__":
    main()
