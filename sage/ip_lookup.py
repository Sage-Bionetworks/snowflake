"""
~40,000 distinct ip addresses recorded "downloading a file" in Q1 of 2024
Using http://ip-api.com/batch API, I was able to extract the information of all ~40000 IP addresses.
This information contains city, country, region, etc which is then stored back into snowflake
for analysis
"""
from dotenv import dotenv_values
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
import pandas as pd
import numpy as np

import requests

config = dotenv_values("../.env")

ctx = snowflake.connector.connect(
    user=config['user'],
    password=config['password'],
    account=config['snowflake_account'],
    database="synapse_data_warehouse",
    schema="synapse",
    role="SYSADMIN",
    warehouse="compute_xsmall"
)
cs = ctx.cursor()

query = """
select
    distinct processedaccess.x_forwarded_for as unique_ips
from
    synapse_data_warehouse.synapse.filedownload
inner join
    synapse_data_warehouse.synapse.processedaccess
    on filedownload.session_id = processedaccess.session_id
where
    filedownload.record_date between DATE('2024-01-01') and DATE('2024-03-31') and
    processedaccess.record_date between DATE('2024-01-01') and DATE('2024-03-31');
"""

cs.execute(query)
unique_ips = cs.fetch_pandas_all()
import time


def get_ip_info(ip_list: list):
    while True:
        try:
            ip_info_response = requests.post('http://ip-api.com/batch', json=ip_list)
            # time.sleep(0.5)
            # ip_info = 
        except Exception as err:
            print(ip_info_response.status_code)
            if ip_info_response.status_code == 429:
                pass
            else:
                raise err
        if ip_info_response.status_code == 200:
            return ip_info_response.json()
        # return ip_info

batch_size = 100
result = []


for batch_number, batch_df in unique_ips.groupby(np.arange(len(unique_ips)) // batch_size):
    print(batch_number)
    if batch_number <= 72:
        continue
    ip_list = get_ip_info(batch_df['UNIQUE_IPS'].to_list())
    time.sleep(2)
    result.extend(ip_list)

ip_info_df = pd.DataFrame(result)
succeeded_ip_info = ip_info_df[ip_info_df['status'] == 'success']
del succeeded_ip_info['status']
del succeeded_ip_info['message']

succeeded_ip_info.rename(columns={'query': 'ip', 'as': 'asn'}, inplace=True)
succeeded_ip_info.to_csv('ip_info.csv', index=False)

succeeded_ip_info.city.value_counts()


write_pandas(
    conn=ctx,
    df=succeeded_ip_info,
    table_name="extracted_ip_info",
    database="SAGE",
    schema="AUDIT",
    auto_create_table=True,
    overwrite=True,
    quote_identifiers=False
)