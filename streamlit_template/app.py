import streamlit as st
from snowflake.snowpark import Session
import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import plotly.graph_objects as go
import plotly.express as px

from queries import query_entity_distribution, query_project_sizes, query_project_downloads
from widgets import plot_unique_users_trend, plot_download_sizes, plot_popular_entities, plot_entity_distribution
from utils import connect_to_snowflake, get_data_from_snowflake



# Custom CSS for styling
with open('style.css') as f:
    st.markdown(f'<style>{f.read()}</style>', unsafe_allow_html=True)

def main():

    # 1. Retrieve the data using your queries in queries.py
    entity_distribution_df = get_data_from_snowflake(query_entity_distribution)
    project_sizes_df = get_data_from_snowflake(query_project_sizes)
    project_downloads_df = get_data_from_snowflake(query_project_downloads)

    # 2. Transform the data as needed
    project_sizes = dict(PROJECT_ID=list(project_sizes_df['PROJECT_ID']), TOTAL_CONTENT_SIZE=list(project_sizes_df['TOTAL_CONTENT_SIZE']))
    total_data_size = round(sum(project_sizes['TOTAL_CONTENT_SIZE']) / (1024 * 1024 * 1024), 2)
    average_project_size = round(np.mean(project_sizes['TOTAL_CONTENT_SIZE']) / (1024 * 1024 * 1024), 2)

    # 3. Format the app, and visualize the data with your widgets in widgets.py
    # -------------------------------------------------------------------------
    # Row 1 -------------------------------------------------------------------
    st.markdown('### Monthly Overview :calendar:')
    col1, col2, col3 = st.columns([1, 1, 1])
    col1.metric("Total Storage Occupied", f"{total_data_size} GB", "7.2 GB")
    col2.metric("Avg. Project Size", f"{average_project_size} GB", "8.0 GB")
    col3.metric("Annual Cost", "102,000 USD", "10,000 USD")

    # # Row 2 -----------------------------------------------------------------
    st.markdown("### Unique Users Report :bar_chart:")
    # st.plotly_chart(plot_unique_users_trend(unique_users_data))

    # Row 3 -------------------------------------------------------------------
    st.plotly_chart(plot_download_sizes(project_downloads_df, project_sizes_df))

    # Row 4 -------------------------------------------------------------------
    st.markdown("### Entity Trends :pencil:")
    col1, col2 = st.columns(2)
    with col1:
        st.markdown('<div class="element-container">', unsafe_allow_html=True)
        #st.dataframe(plot_popular_entities(popular_entities))
    with col2:
        st.dataframe(entity_distribution_df)

    # # Row 5 -------------------------------------------------------------------
    # st.markdown("### Interactive Map of User Downloads :earth_africa:")
    # st.plotly_chart(plot_user_downloads_map(locations))

if __name__ == "__main__":
    main()