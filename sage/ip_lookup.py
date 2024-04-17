"""
~40,000 distinct ip addresses recorded "downloading a file" in Q1 of 2024
Using http://ip-api.com/batch API, I was able to extract the information of all ~40000 IP addresses.
This information contains city, country, region, etc which is then stored back into snowflake
for analysis

This eventually could be an Airflow DAG, so not going spending too much time on it
"""
import requests
import time

from dotenv import dotenv_values
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
import pandas as pd
import numpy as np


def get_ip_info(ip_list: list) -> dict:
    """Get IP information from ip-api.com: http://ip-api.com/batch
    
    Args:
        ip_list (list): list of IP addresses
    
    Returns:
        dict: IP information like city, country, region, lat, long, asn, etc
    """
    # HACK this is not great...
    while True:
        try:
            ip_info_response = requests.post('http://ip-api.com/batch', json=ip_list)
        except Exception as err:
            print(ip_info_response.status_code)
            if ip_info_response.status_code == 429:
                pass
            else:
                raise err
        if ip_info_response.status_code == 200:
            return ip_info_response.json()
        # return ip_info

def main():
    """Main function"""
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
        distinct x_forwarded_for as unique_ips
    from
        synapse_data_warehouse.synapse.processedaccess
    where
        x_forwarded_for is not null and
        x_forwarded_for not in (select ip from sage.audit.extracted_ip_info) and
        record_date > DATE('2024-01-01');
        // record_date BETWEEN DATE('2023-01-01') and DATE('2023-06-30');
    """
    cs.execute(query)
    unique_ips = cs.fetch_pandas_all()
    # API only takes a batch size of 100
    batch_size = 100
    result = []

    for batch_number, batch_df in unique_ips.groupby(np.arange(len(unique_ips)) // batch_size):
        print(batch_number)
        ip_list = get_ip_info(batch_df['UNIQUE_IPS'].to_list())
        # API rate limit of 15 per minute
        # Add in sleep to not get throttled
        time.sleep(2.5)
        result.extend(ip_list)

    ip_info_df = pd.DataFrame(result)
    succeeded_ip_info = ip_info_df[ip_info_df['status'] == 'success']

    # These columns do not add value in a snowflake query
    del succeeded_ip_info['status']
    del succeeded_ip_info['message']

    # Renaming columns to be more descriptive or ignoring SQL key words
    succeeded_ip_info.rename(columns={'query': 'ip', 'as': 'asn'}, inplace=True)
    succeeded_ip_info.to_csv('ip_info.csv', index=False)

    write_pandas(
        conn=ctx,
        df=succeeded_ip_info,
        table_name="extracted_ip_info",
        database="SAGE",
        schema="AUDIT",
        auto_create_table=True,
        # overwrite=True,
        quote_identifiers=False
    )
    ctx.close()

if __name__ == "__main__":
    main()