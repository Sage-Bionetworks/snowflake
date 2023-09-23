from dotenv import dotenv_values
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
import synapseclient

# SELECT id, parentId, createdOn, name, fileFormat, resourceType, dataSubtype, modifiedBy, individualID, modifiedOn, benefactorId, createdBy, libraryPrep FROM syn16858331
# UNION SELECT id, parentId, createdOn, name, fileFormat, resourceType, dataSubtype, modifiedBy, individualID, modifiedOn, benefactorId, createdBy, libraryPrep FROM syn11346063
# UNION SELECT id, parentId, createdOn, name, fileFormat, resourceType, dataSubtype, modifiedBy, individualID, modifiedOn, benefactorId, createdBy, libraryPrep FROM syn20821313.15
syn = synapseclient.login()

config = dotenv_values(".env")

# nf_portal = syn.tableQuery("select * from syn16858331")
# nf_portal_df = nf_portal.asDataFrame()

# ctx = snowflake.connector.connect(
#     user=config['user'],
#     password=config['password'],
#     account=config['snowflake_account'],
#     database="sage",
#     schema="portal_raw",
#     role="SYSADMIN"
# )

# cs = ctx.cursor()

# table = "NF"

# write_pandas(ctx, nf_portal_df, table, auto_create_table=True)

# query = f"select * from {table} limit 10;"

# cs.execute(query)
# opt = cs.fetch_pandas_all()

## AD

portals = {
    "AD": "syn11346063"
}
for portal_name, synapse_id in portals.items():
    ad_portal = syn.tableQuery(f"select * from {synapse_id}")
    ad_portal_df = ad_portal.asDataFrame()
    ad_portal_df.reset_index(inplace=True, drop="index")

    ctx = snowflake.connector.connect(
        user=config['user'],
        password=config['password'],
        account=config['snowflake_account'],
        database="sage",
        schema="portal_raw",
        role="SYSADMIN"
    )

    cs = ctx.cursor()

    write_pandas(ctx, ad_portal_df, portal_name, auto_create_table=True)

    query = f"select * from {portal_name} limit 10;"

    cs.execute(query)
    opt = cs.fetch_pandas_all()
