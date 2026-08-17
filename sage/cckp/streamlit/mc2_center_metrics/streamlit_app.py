import datetime as dt
import argparse
import streamlit as st
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session

import tabs.overview as overview
import tabs.trends as trends


def read_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--local-dev",
        action="store_true",
        help=(
            "Run in local development mode. Creates a Snowflake session using the "
            "'default' connection from ~/.snowflake/connections.toml instead of "
            "the active Streamlit in Snowflake (SiS) session. "
            "Usage: streamlit run streamlit_app.py -- --local-dev"
        ),
    )
    return parser.parse_args()


def get_session(local_dev: bool) -> Session:
    if local_dev:
        return Session.builder.config("connection_name", "default").create()

    return get_active_session()


# Set page config
st.set_page_config(page_title="MC2 Center Metrics", layout="wide")

# Title
st.title("MC2 Center Metrics")
st.markdown(
    '<p style="color: #cc0000; font-size: 0.85rem; margin-top: -0.4rem;">'
    "This app is "
    '<a href="https://github.com/Sage-Bionetworks/snowflake/blob/dev/STREAMLIT.md" target="_blank">managed on Github</a>. '
    "Any local edits will not be retained."
    "</p>",
    unsafe_allow_html=True,
)

# Initialize session configured for generated Streamlit apps
args = read_args()
if "session" not in st.session_state:
    st.session_state.session = get_session(args.local_dev)
try:
    st.session_state.session.query_tag = "__generated_streamlit"
except Exception:
    pass

# Prefetch all queries so Snowflake starts executing them before each tab renders.
overview.prefetch()
trends.prefetch()
(
    tab_overview,
    tab_trends,


with tab_overview:
    overview.render()
with tab_trends:
    trends.render()
# Footer
st.markdown("---")
st.markdown(
    "*Dashboard loaded: {}*".format(dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
)
