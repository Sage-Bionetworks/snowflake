from dotenv import dotenv_values
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
import synapseclient


syn = synapseclient.login()

config = dotenv_values(".env")

nf_portal = syn.tableQuery("select * from syn16858331")
nf_portal_df = nf_portal.asDataFrame()

ctx = snowflake.connector.connect(
    user=config['user'],
    password=config['password'],
    account=config['snowflake_account'],
    database="sage_test",
    schema="portal_raw",
    role="SYSADMIN"
)

cs = ctx.cursor()

table = "NF"

write_pandas(ctx, nf_portal_df, table, auto_create_table=True)

query = f"select * from {table} limit 10;"

cs.execute(query)
opt = cs.fetch_pandas_all()
