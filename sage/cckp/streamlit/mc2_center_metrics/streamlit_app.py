import datetime as dt
import argparse
import streamlit as st
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session

import tabs.datasets as datasets
import tabs.files_browser as files_browser
import tabs.mc2_center as mc2_center
import tabs.overview as overview
import tabs.trends as trends
import tabs.users as users


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

# Styling
st.markdown("""
<style>
    h4 {
        text-align: center;
    }
</style>
""", unsafe_allow_html=True)


_, col_logo, _ = st.columns([2, 1, 2])
with col_logo:
    st.image("mc2-logo.png", width='stretch')
st.markdown("#### Metrics Dashboard")
st.markdown(
    f'<p style="text-align: center; font-size: 0.8rem; color: grey;">'
    f"Dashboard loaded: {dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
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
datasets.prefetch()
users.prefetch()
files_browser.prefetch()
mc2_center.prefetch()

with st.sidebar:
    st.caption("HELP & DEFINITIONS")
    with st.expander("What is a download?"):
        st.markdown(
            """
            A "download" is recorded whenever a file's content is accessed via the Synapse web
            UI or API.

            This includes both direct file downloads and full file previews on Synapse (such as images
            PDFs, or small text files). For large files that cannot be fully previewed, only the direct
            downloads are counted.
            """
        )
    with st.expander("What is an external user?"):
        st.markdown(
            """
            An "external user" is defined as any Synapse account where the registered email
            does not end in `@sagebase.org` or `@sagebionetworks.org`.

            It may be possible for a Sage employee to be categorized as "external" if they are
            using a non-Sage email in their account.
            """
        )
    with st.expander("What is a public file?"):
        st.markdown(
            """
            A "public file" is any file that can be viewed by anyone on the web.
            
            It does not necessarily mean the file is open for unrestricted download (a.k.a. `OPEN_DATA`).
            """
        )
    with st.expander("What is a dataset?"):
        st.markdown(
            """
            In this dashboard, a "dataset" is any entity with a type of `dataset` or `datasetcollection`.
            
            Legacy datasets uploaded as `file` or `folder` types are excluded from the total datasets count
            and the **Datasets Browser**, but will automatically be included once they are converted to the
            `dataset` or `datasetcollection` type.
            """
        )
    with st.expander("What is a dataset download?"):
        st.markdown(
            """
            A "dataset download" is counted whenever a file _inside_ that dataset is downloaded. Dataset
            nodes themselves don't have downloadable content; the counts reflect the files they contain.

            Each unique filehandle is counted once per dataset, even if it is referenced by multiple file
            entities within that dataset.
            """
        )
    with st.expander("How do I report an issue or request a metric?"):
        st.markdown(
            """
            Please reach out to Savitha or Verena on Slack!

            We're happy to answer questions, investigate missing data, or discuss new metric requests as
            we continue improving this dashboard.
            """
        )

(
    tab_overview,
    tab_trends,
    tab_datasets,
    tab_browser,
    tab_users,
    tab_mc2_center,
) = st.tabs(["Overview", "Trends", "Datasets", "Files Browser", "External Users", "MC2 Center Project"])


with tab_overview:
    overview.render()
with tab_trends:
    trends.render()
with tab_datasets:
    datasets.render()
with tab_users:
    users.render()
with tab_browser:
    files_browser.render()
with tab_mc2_center:
    mc2_center.render()

st.divider()
st.caption("\* \"Public\" means the entity is viewable by anyone on the web. This does not necessarily mean it can be downloaded.")
st.markdown(
    '<p style="color: #cc0000; font-size: 0.8rem;">'
    "This app is "
    '<a href="https://github.com/Sage-Bionetworks/snowflake/blob/dev/STREAMLIT.md" target="_blank">managed on GitHub</a>. '
    "Any local edits will not be retained."
    "</p>",
    unsafe_allow_html=True,
)
