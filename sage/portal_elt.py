from dotenv import dotenv_values
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
import synapseclient
import pandas as pd


syn = synapseclient.login()

config = dotenv_values("../.env")

ctx = snowflake.connector.connect(
    user=config['user'],
    password=config['password'],
    account=config['snowflake_account'],
    database="sage",
    schema="portal_raw",
    role="SYSADMIN",
    warehouse="compute_xsmall"
)

cs = ctx.cursor()

portals = {
    "AD": "syn11346063",
    "PSYCHENCODE": "syn20821313.16",
    "NF": "syn16858331",
    "ELITE": "syn51228429",
    # syn52677746 is the old HTAN table
    "HTAN": "syn52748752",
    "GENIE": "syn52794526",
}

for portal_name, synapse_id in portals.items():
    # HACK: to deal with the version number
    if "." in synapse_id:
        ent = syn.get(synapse_id.split(".")[0])
    else:
        ent = syn.get(synapse_id)
    if isinstance(ent, synapseclient.EntityViewSchema):
        portal = syn.tableQuery(f"select * from {synapse_id}")
        portal_df = portal.asDataFrame()
        portal_df.reset_index(inplace=True, drop="index")
    else:
        # This is for HTAN
        portal_df = pd.read_csv(ent.path)
    # grant and group are reserved key words
    portal_df.rename(columns={"grant": "grants", "group": "groups"}, inplace=True)
    write_pandas(
        ctx,
        portal_df,
        portal_name,
        auto_create_table=True,
        overwrite=True,
        quote_identifiers=False
    )
# ! One time port of HTAN
# htan_ent = syn.get("syn52677746")
# htan_df = pd.read_csv(htan_ent.path)
# write_pandas(ctx, htan_df, "HTAN", auto_create_table=True)
# htan_ent = syn.get("syn52748752")
# htan_df = pd.read_csv(htan_ent.path)
# write_pandas(ctx, htan_df, "HTAN", auto_create_table=True, overwrite=True)

# for portal_name, synapse_id in portals.items():
#     portal = syn.tableQuery(f"select * from {synapse_id}")
#     portal_df = portal.asDataFrame()
#     portal_df.reset_index(inplace=True, drop="index")

#     find_table_query = f"""
#     SELECT *
#     FROM sage.information_schema.tables
#     WHERE TABLE_SCHEMA = 'PORTAL_RAW' AND
#     TABLE_NAME = '{portal_name}';
#     """
#     cs.execute(find_table_query)
#     opt = cs.fetch_pandas_all()
#     # * Get the existing table to get colum names for future column
#     # updates
#     # cursor = cs.execute(f"SELECT * from PORTAL_RAW.{portal_name} limit 5")
#     # df = pd.DataFrame(cursor.description)
#     # If the table is empty, auto create it, otherwise, truncake and overwrite
#     # The rationale for this is that some tables have "grant" and "group" as
#     # and those are reserved column headers.
#     # auto_create_table = opt.empty
#     # write_pandas(ctx, portal_df, portal_name, auto_create_table=auto_create_table, overwrite=True)

#     if opt.empty:
#         write_pandas(ctx, portal_df, portal_name, auto_create_table=True)
#     else:
#         # Create temporary table so we can upsert
#         target_table = f"{portal_name}_TEMP"
#         write_pandas(
#             ctx,
#             portal_df,
#             target_table,
#             auto_create_table=True,
#             table_type="transient",
#             overwrite=True,
#             quote_identifiers=False
#         )

#         # TODO account for schema changes
#         # Upsert into non-temporary tables
#         update_set = [f'"{portal_name}"."{col}" = "{target_table}"."{col}"' for col in portal_df.columns]
#         update_set_str = ",".join(update_set)
#         col_str = ",".join(f'"{col}"' for col in portal_df.columns)
#         to_insert_str = ",".join([f'"{target_table}"."{col}"' for col in portal_df.columns])
#         merge_sql = f"""
#         MERGE INTO {portal_name} USING {target_table}
#             ON {portal_name}."id" = {target_table}."id"
#             when matched then
#                 update set {update_set_str}
#             when not matched then
#             insert
#             ({col_str}) values({to_insert_str});
#         """
#         print(merge_sql)
#         cs.execute(merge_sql)
#         cs.execute(f"DROP TABLE {target_table}")

#     query = f"select * from {portal_name} limit 10;"
#     cs.execute(query)
#     opt = cs.fetch_pandas_all()
