"""GENIE ELT pipeline"""
import os

from dotenv import dotenv_values
import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
import synapseclient
import synapseutils as synu


def push_cbio_files_to_snowflake(syn: synapseclient.Synapse, ctx: snowflake.connector.connect, synid: str, structured_data: list):
    """_summary_

    Args:
        ctx (snowflake.connector.connect): _description_
        synid (str): _description_
        structured_data (list): _description_
    """
    folder_ent = syn.get(synid)
    release_name = folder_ent.name.split("-")[0].replace(".", "_")

    release_files = syn.getChildren(synid, includeTypes=["file", "folder", "link"])
    release_file_map = {
        release_file['name']: syn.get(release_file['id'], followLink=True)
        for release_file in release_files
        if release_file['name'].startswith(structured_data) and
        release_file['name'].endswith(("txt", "bed"))
    }
    cs = ctx.cursor()

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
        if tbl_name == "genie_combined.bed":
            tbl_name = "genomic_information"
        elif tbl_name == "genie_cna_hg19.seg":
            tbl_name = "cna_hg19"
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


def push_to_snowflake(ctx: snowflake.connector.connect, table_name: str, df: pd.DataFrame):
    """_summary_

    Args:
        ctx (snowflake.connector.connect): _description_
        synid (str): _description_
        structured_data (list): _description_
    """
    cs = ctx.cursor()
    cs.execute(
        f"CREATE SCHEMA IF NOT EXISTS BPC_NON_DOUBLE_CURATED_DATA WITH MANAGED ACCESS;"
    )
    cs.execute(f"USE SCHEMA BPC_NON_DOUBLE_CURATED_DATA")

    write_pandas(
        ctx,
        df,
        table_name,
        auto_create_table=True,
        quote_identifiers=False,
        overwrite=True
    )

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
    # Exclude data_cna for now
    structured_data = (
        "data_clinical", "data_mutations", "data_fusions"
        "assay_information", "data_cna_hg19", "data_gene_matrix",
        "data_sv", "genomic_information", "genie_combined", "genie_cna_hg19"
    )
    # push_cbio_files_to_snowflake(syn=syn, ctx=ctx, synid="syn61466217", structured_data=structured_data)

    # directory_info = synu.walk(syn, "syn7492881")
    # for dirpath, dirnames, filenames in directory_info:
    #     if len(dirpath[0].split("/")) != 2:
    #         continue
    #     for dirname, dir_synid in dirnames:
    #         # if dirname.endswith("-public") or folder_ent.name.startswith(("1.0", "2.0", "3.0")):
    #         # if not dirname.endswith('-consortium'):
    #         #     continue
    #         if dirname == "16.0-public":
    #             print(dirname)
    #             push_cbio_files_to_snowflake(syn=syn, ctx=ctx, synid=dir_synid, structured_data=structured_data)


    data_table_info = syn.tableQuery("SELECT * FROM syn21446696 where double_curated is not true and table_type = 'data'")
    data_table_info_df = data_table_info.asDataFrame()
    def group_tables(df):
        grouped = {}
        for _, row in df.iterrows():
            name = row['name']
            syn_id = row['id']
            prefix = ' '.join(name.split()[:-2]) if 'Part' in name else name
            if prefix not in grouped:
                grouped[prefix] = []
            grouped[prefix].append((syn_id, name))
        return grouped

    # Apply the grouping function
    grouped_tables = group_tables(data_table_info_df)
    join_columns = ['cohort', 'record_id', 'redcap_repeat_instance']

    # Display the grouped result
    for key, values in grouped_tables.items():
        table_name = key.replace(" ", "_")
        print(table_name)
        group_df = pd.DataFrame()
        for syn_id, name in values:
            print(name)
            new_table_df = syn.tableQuery(f"SELECT * FROM {syn_id}").asDataFrame()
            if group_df.empty:
                group_df = new_table_df
            else:
                group_df = pd.merge(group_df, new_table_df, on=join_columns, how='outer')
            
        push_to_snowflake(ctx=ctx, table_name=table_name, df=group_df)
    ctx.close()


if __name__ == "__main__":
    main()
