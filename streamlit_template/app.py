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

# Setting up the sidebar and interactive user interface
with st.sidebar:
    st.title("HTAN Usage Metrics")
    
    year_list = [2024, 2023, 2022, 2021, 2020, 2019]
    selected_year = st.selectbox("Select a year to view metrics for...", year_list)

    st.write("For questions or comments, please contact jenny.medina@sagebase.org.")

def main():

    center_col, side_col = st.columns((4., 1), gap='medium')

    with center_col:
        # --------------- Row 1: Overview Cards -------------------------

        st.markdown("## Overview")

        # Data retrieval:
        project_downloads_df = get_data_from_snowflake(query_project_downloads())
        project_sizes_df = get_data_from_snowflake(query_project_sizes())

        # Data transformation:
        total_data_size = round(sum(project_sizes_df['PROJECT_SIZE_IN_GIB']), 2)

        # Data visualization:
        col1, col2, col3, col4 = st.columns([1, 1, 1, 1])
        col1.metric("Total Storage Occupied", f"{total_data_size} GB")
        col2.metric("Annual Downloads (Total)", f"2 GB")
        col3.metric("Annual Downloads (External)", f"2 GB")
        col4.metric("Annual Cost", "102,000 USD")

        # ---------------- Row 3: Unique Users Trends -------------------------
        
        st.markdown("#### User Trends")
        
        # Data retrieval:
        unique_users_df = get_data_from_snowflake(query_unique_users(months_back=12))
        
        # Data visualization:
        st.plotly_chart(plot_unique_users_trend(unique_users_df))
    
        # --------------- Row 2: Project Sizes and Downloads -----------------
        # Data visualization:
        st.plotly_chart(plot_download_sizes(project_downloads_df, project_sizes_df))

    with side_col:

        # --------------- Row 1: Overview Cards -------------------------

        st.markdown("#### Entity Distribution")

        # Data retrieval:
        entity_distribution_df = get_data_from_snowflake(query_entity_distribution())

        # Data visualization:
        st.dataframe(entity_distribution_df,
                 column_order=("NODE_TYPE", "NUMBER_OF_FILES"),
                 hide_index=True,
                 width=None,
                 column_config={
                    "NODE_TYPE": st.column_config.TextColumn(
                        "Node Type",
                    ),
                    "NUMBER_OF_FILES": st.column_config.ProgressColumn(
                        "Occurence",
                        format="%f",
                        min_value=0,
                        max_value=max(entity_distribution_df["NUMBER_OF_FILES"]),
                     )}
                 )


if __name__ == "__main__":
    main()
