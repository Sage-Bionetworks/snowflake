import streamlit as st
from snowflake.snowpark import Session


@st.cache_resource
def connect_to_snowflake():
    session = Session.builder.configs(st.secrets.snowflake).create()
    return session


@st.cache_data
def get_data_from_snowflake(query=""):
    session = connect_to_snowflake()
    node_latest = session.sql(query).to_pandas()
    return node_latest
