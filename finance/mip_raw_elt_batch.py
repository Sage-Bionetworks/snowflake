import json
import logging
import os

import backoff
import pandas as pd
import requests
from requests.exceptions import RequestException
import snowflake.connector as sc
from snowflake.connector.pandas_tools import write_pandas
import synapseclient
from urllib3.exceptions import RequestError

SECRETS = json.loads(os.getenv("SCHEDULED_JOB_SECRETS"))
SYNAPSE_AUTH_TOKEN = SECRETS["SYNAPSE_AUTH_TOKEN"]
SNOWFLAKE_PRIVATE_KEY = SECRETS["SNOWFLAKE_PRIVATE_KEY"]
MIP_AUTH = SECRETS["MIP_AUTH"]

LOG = logging.getLogger(__name__)
LOG.setLevel(logging.DEBUG)

MIPS_URL_LOGIN_API = "https://login.mip.com/api/v1/sso/mipadv/login"
# https://documentation.mip.com/#/swagger/recursiveTransaction/transactions/recursiveTransactions
LEDGER_API = "https://api.mip.com/api/v1/recursiveTransactions/GeneralLedger/posted"
# https://documentation.mip.com/#/swagger/maintenance/generalLedger/chartOfAccounts
CHART_OF_ACCOUNTS_API = "https://api.mip.com/api/v1/maintain/ChartOfAccounts"
MIPS_URL_LOGOUT_API = "https://api.mip.com/api/security/logout"


@backoff.on_exception(backoff.expo, (RequestError, RequestException), max_time=11)
def _request_login(creds):
    """
    Wrap login request with backoff decorator, using exponential backoff
    and running for at most 11 seconds. With a connection timeout of 4
    seconds, this allows two attempts.
    """
    timeout = 4
    LOG.info("Logging in to upstream API")

    login_response = requests.post(
        MIPS_URL_LOGIN_API,
        json=creds,
        timeout=timeout,
    )
    login_response.raise_for_status()
    token = login_response.json()["AccessToken"]
    return token


@backoff.on_exception(backoff.fibo, (RequestError, RequestException), max_time=28)
def _request_logout(access_token):
    """
    Wrap logout request with backoff decorator, using fibonacci backoff
    and running for at most 28 seconds. With a connection timeout of 6
    seconds, this allows three attempts.

    Prioritize spending time logging out over the other requests because
    failing to log out after successfully logging in will lock us out of
    the API; but CloudFront will only wait a maximum of 60 seconds for a
    response from this lambda.
    """
    timeout = 6
    LOG.info("Logging out of upstream API")

    requests.post(
        MIPS_URL_LOGOUT_API,
        headers={"Authorization-Token": access_token},
        timeout=timeout,
    )


def get_ledgers(
    access_token: str,
    max_session_posted_date: str = "2025-01-24 23:48:49.000",
    page_number: int = 0,
    page_size: int = 20,
) -> list[dict]:
    """Get ledgers from the MIP API

    Args:
        access_token (str): MIP access token
        max_session_posted_date (str, optional): Max session posted date, used to filter for transactions after a specific date. Defaults to "2025-01-24 23:48:49.000".
        page_number (int, optional): _description_. Defaults to 0.
        page_size (int, optional): _description_. Defaults to 20.

    Returns:
        list[dict]: An array of ledgers
    """
    all_ledgers = []
    initial_ledgers = requests.get(
        LEDGER_API,
        headers={
            "Authorization-Token": access_token,
        },
        params={
            "page[number]": str(page_number),
            "page[size]": str(page_size),
            "filter[sessionPostedDate][gt]": max_session_posted_date,
        },
    )
    total_records = initial_ledgers.json()["totalRecords"]
    while len(all_ledgers) < total_records:
        ledgers = requests.get(
            _ledger_api,
            headers={
                "Authorization-Token": access_token,
            },
            params={
                "page[number]": str(page_number),
                "page[size]": str(page_size),
                "filter[sessionPostedDate][gt]": max_session_posted_date,
            },
        )
        page_number += 1
        all_ledgers.extend(ledgers.json()["data"])
    return all_ledgers


def get_chart_of_accounts(
    access_token: str, page_number: int = 0, page_size: int = 20
) -> list:
    """Get chart of accounts from the MIP API. This includes all the program codes

    Args:
        access_token (str): MIP access token
        page_number (int, optional): page number. Defaults to 0.
        page_size (int, optional): page size. Defaults to 20.

    Returns:
        list: List of charts of accounts
    """
    all_ledgers = []
    initial_ledgers = requests.get(
        CHART_OF_ACCOUNTS_API,
        headers={
            "Authorization-Token": access_token,
        },
        params={"page[number]": str(page_number), "page[size]": str(page_size)},
    )
    total_records = initial_ledgers.json()["total"]
    while len(all_ledgers) < total_records:
        ledgers = requests.get(
            CHART_OF_ACCOUNTS_API,
            headers={
                "Authorization-Token": access_token,
            },
            params={"page[number]": str(page_number), "page[size]": str(page_size)},
        )
        page_number += 1
        all_ledgers.extend(ledgers.json()["data"])
    return all_ledgers


def cast_df_types(source_df: pd.DataFrame, target_df: pd.DataFrame) -> pd.DataFrame:
    """Cast source dataframe into target dataframe

    Args:
        source_df (pd.DataFrame): Source dataframe with the expected types
        target_df (pd.DataFrame): Target dataframe to update

    Returns:
        pd.DataFrame: Altered target dataframe with types cast to match source dataframe
    """
    for col, dtype in df.dtypes.items():
        if col in target_df.columns:
            if "int" in str(dtype):
                # Replace empty strings or nulls with NaN, then cast safely
                target_df[col] = (
                    pd.to_numeric(target_df[col], errors="coerce")
                    .fillna(0)
                    .astype(dtype)
                )
            elif "float" in str(dtype):
                target_df[col] = (
                    pd.to_numeric(target_df[col], errors="coerce")
                    .fillna(0)
                    .astype(dtype)
                )
            else:
                target_df[col] = target_df[col].astype(dtype)
    return target_df


def update_ledgers(cs: sc.SnowflakeCursor, ctx: sc.SnowflakeConnection, access_token: str) -> str:
    """Update the ledgers table in Snowflake

    Args:
        cs (sc.SnowflakeCursor): Snowflake cursor object
        ctx (sc.SnowflakeConnection): Snowflake connection object
        access_token (str): MIP access token

    Returns:
        str: Message indicating the result of the ledger update
    """
    results = cs.execute(
        "SELECT MAX(SESSIONPOSTEDDATE) as max_session_posted_date FROM finance.mip_raw.ledgers"
    )
    max_session_posted_date = results.fetchone()[0]
    formatted_dt = max_session_posted_date.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
    ledgers = get_ledgers(
        access_token, max_session_posted_date=formatted_dt, page_size=1000
    )
    if len(ledgers) > 0:
        ledgers_df = pd.DataFrame(ledgers)
        ledgers_df.to_csv("ledgers.csv", index=False)

        results = cs.execute("SELECT * FROM finance.mip_raw.ledgers limit 1")
        df = results.fetch_pandas_all()

        ledgers_df.columns = ledgers_df.columns.str.upper()
        ledgers_df = cast_df_types(df, ledgers_df)
        results = write_pandas(
            ctx, ledgers_df, "ledgers", quote_identifiers=False, use_logical_type=True
        )
        if results[0]:
            return f"ledger appended with {results[2]} rows"
        else:
            return "ledger append failed"
    else:
        return "No new ledgers to append"


def update_chart_of_accounts(cs: sc.SnowflakeCursor, ctx: sc.SnowflakeConnection, access_token: str) -> str:
    """Update the chart of accounts table in Snowflake

    Args:
        cs (sc.SnowflakeCursor): Snowflake cursor object
        ctx (sc.SnowflakeConnection): Snowflake connection object
        access_token (str): MIP access token

    Returns:
        str: Message indicating the result of the chart of accounts update
    """
    results = cs.execute(
        "SELECT count(*) as total_coa FROM finance.mip_raw.chart_of_accounts"
    )
    total_coa = results.fetchone()[0]

    chart_of_accounts = get_chart_of_accounts(access_token, page_size=1000)
    if len(chart_of_accounts) > total_coa:
        chart_of_accounts_df = pd.DataFrame(chart_of_accounts)
        chart_of_accounts_df.to_csv("chart_of_accounts.csv", index=False)
        results = cs.execute("SELECT * FROM finance.mip_raw.chart_of_accounts limit 1")
        df = results.fetch_pandas_all()

        chart_of_accounts_df.columns = chart_of_accounts_df.columns.str.upper()
        chart_of_accounts_df = cast_df_types(df, chart_of_accounts_df)
        results = write_pandas(
            ctx,
            chart_of_accounts_df,
            "chart_of_accounts",
            overwrite=True,
            quote_identifiers=False,
            use_logical_type=True,
        )
        if results[0]:
            return f"Chart of accounts updated with {results[2]} rows"
        else:
            return "Chart of accounts update failed"
    else:
        return "No new chart of accounts to update"


def update_mip_raw_tables():
    """Update MIP raw tables including the general ledger and chart of accounts"""
    access_token = None
    mips_creds = {
        "username": "itops",
        "password": MIP_AUTH,
        "org": "SAGE_24146",
    }
    access_token = _request_login(mips_creds)

    with open("temp.p8", "w") as private_key_f:
        private_key_f.write(SNOWFLAKE_PRIVATE_KEY)

    conn_params = {
        "account": "mqzfhld-vp00034",
        "role": "FINANCE_ADMIN",
        "user": "FINANCE_SERVICE",
        "private_key_file": "temp.p8",
        "private_key_file_pwd": None,
        "warehouse": "COMPUTE_XSMALL",
        "database": "FINANCE",
        "schema": "MIP_RAW",
    }
    ctx = sc.connect(**conn_params)
    cs = ctx.cursor()

    ledger_message = update_ledgers(cs=cs, ctx=ctx, access_token=access_token)
    LOG.info(ledger_message)

    coa_message = update_chart_of_accounts(cs=cs, ctx=ctx, access_token=access_token)
    LOG.info(coa_message)

    syn = synapseclient.login(authToken=SYNAPSE_AUTH_TOKEN)
    syn.sendMessage(
        messageSubject="MIP Raw Tables Update",
        messageBody=f"{ledger_message}\n{coa_message}",
        userIds=[3324230],
    )
    _request_logout(access_token)
    cs.close()
    os.remove("temp.p8")


if __name__ == "__main__":
    update_mip_raw_tables()
