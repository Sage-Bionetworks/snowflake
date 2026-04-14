import streamlit as st
from snowflake.snowpark.context import get_active_session

session = get_active_session()

st.title("Governance Dashboard")
st.caption("Access request and data access submission tracker")

st.header("Submission Status")
st.info("Not yet implemented.")

st.header("Requesters")
st.info("Not yet implemented.")

st.header("Days to Review")
st.info("Not yet implemented.")

st.header("Attempt Number")
st.info("Not yet implemented.")

st.header("Program / Project")
st.info("Not yet implemented.")

st.header("ACT Analyst / Reviewer")
st.info("Not yet implemented.")
