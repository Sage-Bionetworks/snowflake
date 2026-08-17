from requests import session

import streamlit as st
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session

@st.cache_resource
def connect_to_snowflake():
    """
    Establishes and caches a connection to Snowflake.
    This function uses Streamlit's @st.cache_resource decorator to cache the 
    Snowflake connection so that:
    
    1. The connection is created only once and reused across multiple 
       reruns of the Streamlit app.
    2. The same connection object is shared across all users of the app.
    3. The connection persists until the Streamlit server is stopped or 
       the cache is cleared.

    Returns:
        Session: A cached Snowflake session object.
    """
    try:
        session = Session.builder.configs(st.secrets.snowflake).create()
    except Exception:
        session = get_active_session()
    
    # session.sql("USE WAREHOUSE COMPUTE_XSMALL;").collect()
    try:
        session.query_tag = "__generated_streamlit"
    except Exception:
        pass
    return session


@st.cache_data()
def get_data_from_snowflake(query=""):
    """
    Wrapper to retrieve data from Snowflake based on the provided SQL query with caching and automatic conversion of data to pandas DataFrame.
    Caching is useful for improving the performance and minimizing costs.
    """
    session = connect_to_snowflake()
    df = session.sql(query).to_pandas()
    return df
