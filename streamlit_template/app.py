import numpy as np
import streamlit as st
from toolkit.queries import (
    query_entity_distribution,
    query_project_downloads,
    query_project_sizes,
    query_unique_users,
)
from toolkit.utils import get_data_from_snowflake
from toolkit.widgets import plot_download_sizes, plot_unique_users_trend

# Configure the layout of the Streamlit app page
st.set_page_config(layout="wide",
                   page_title="HTAN Analytics",
                   page_icon=":bar_chart:",
                   initial_sidebar_state="expanded")

# Custom CSS for styling
with open("style.css") as f:
    st.markdown(f"<style>{f.read()}</style>", unsafe_allow_html=True)


def main():

    # 1. Retrieve the data using your queries in queries.py
    entity_distribution_df = get_data_from_snowflake(query_entity_distribution())
    project_sizes_df = get_data_from_snowflake(query_project_sizes())
    project_downloads_df = get_data_from_snowflake(query_project_downloads())
    # User input for the number of months
    months_back = st.sidebar.slider("Lookback Range (how many months back to display trends)",
                                    min_value=1,
                                    max_value=24,
                                    value=12)
    # Use the selected months_back in the unique users query
    unique_users_df = get_data_from_snowflake(query_unique_users(months_back))

    # 2. Transform the data as needed
    convert_to_gib = 1024 * 1024 * 1024
    project_sizes = dict(
        PROJECT_ID=list(project_sizes_df["PROJECT_ID"]),
        TOTAL_CONTENT_SIZE=list(project_sizes_df["TOTAL_CONTENT_SIZE"]),
    )
    total_data_size = sum(
        project_sizes["TOTAL_CONTENT_SIZE"]
    )  # round(sum(project_sizes['TOTAL_CONTENT_SIZE']) / convert_to_gib, 2)
    average_project_size = round(
        np.mean(project_sizes["TOTAL_CONTENT_SIZE"]) / convert_to_gib, 2
    )

    # 3. Format the app, and visualize the data with your widgets in widgets.py
    # -------------------------------------------------------------------------
    # Row 1 -------------------------------------------------------------------
    st.markdown("### Monthly Overview :calendar:")
    col1, col2, col3 = st.columns([1, 1, 5])
    col1.metric("Total Storage Occupied", f"{total_data_size} GB", "7.2 GB")
    col2.metric("Avg. Project Size", f"{average_project_size} GB", "8.0 GB")
    col3.metric("Annual Cost", "102,000 USD", "10,000 USD")

    # Row 2 -----------------------------------------------------------------
    st.markdown("### Unique Users Report :bar_chart:")
    st.plotly_chart(plot_unique_users_trend(unique_users_df))

    # Row 3 -------------------------------------------------------------------
    st.plotly_chart(plot_download_sizes(project_downloads_df, project_sizes_df))

    # Row 4 -------------------------------------------------------------------
    st.markdown("### Entity Trends :pencil:")
    st.dataframe(entity_distribution_df)


if __name__ == "__main__":
    main()
