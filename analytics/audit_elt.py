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
    schema="audit",
    role="SYSADMIN",
    warehouse="compute_xsmall"
)

cs = ctx.cursor()

files = syn.getChildren("syn53180811")
# files = [{"id": "syn55198186", "name": "IT-3518-sage-org-buckets.csv"}]
for file_info in files:
    synapse_id = file_info['id']
    table_name = file_info['name'].replace("-", "_").replace(".csv", "")
    ent = syn.get(file_info['id'])
    # This is for HTAN
    ent_df = pd.read_csv(ent.path)
    if ent_df.get("id") is None:
        print(f"Skipping: {synapse_id} does not have id column")
        continue
    ent_df['id'] = ent_df['id'].drop_duplicates().str.replace('syn', '').astype(int)
    
    write_pandas(
        ctx,
        ent_df,
        table_name,
        auto_create_table=True,
        overwrite=True,
        quote_identifiers=False
    )
cs.close()
