# app/main.py
import streamlit as st
from snowflake.snowpark import Session
import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import plotly.graph_objects as go
import plotly.express as px
import matplotlib.pyplot as plt
# from app.components.sidebar import render_sidebar
# from app.pages import page1, page2

# Set up the main layout and configuration for the Streamlit app
st.set_page_config(page_title="Project Health Dashboard", layout="wide")

# Custom CSS for borders
# Custom CSS for sage green filled containers and banners
with open('style.css') as f:
    st.markdown(f'<style>{f.read()}</style>', unsafe_allow_html=True)

st.title("Digital Trends Dashboard")
@st.cache_resource
def connect_to_snowflake():
    session = Session.builder.configs(st.secrets.snowflake).create()
    return session

def get_data_from_snowflake(query=""):
    session = connect_to_snowflake()
    #query = "SELECT * FROM synapse_data_warehouse.synapse.node_latest LIMIT 5"
    node_latest = session.sql(query).to_pandas()
    return node_latest

#@st.cache_resource
def generate_sample_data():
    # Simulate total data size
    total_data_size = round(random.uniform(100, 1000), 2)  # In GB

    # Simulate average project size
    average_project_size = round(random.uniform(5, 50), 2)  # In GB

    # Simulate project size and download size data for projects
    project_names = [f"Project {i}" for i in range(1, 21)]
    project_sizes = {project: random.uniform(1, 50) for project in project_names}  # Project sizes in GB
    download_sizes = {project: random.randint(10, 1000) for project in project_names}  # Download sizes in GB

    # Simulate unique users data for the last 12 months
    months = pd.date_range(start=datetime.now() - timedelta(days=365), periods=12, freq='M').strftime('%Y-%m').tolist()
    unique_users_data = {project: [random.randint(50, 150) for _ in months] for project in project_names}

    # Simulate entity distribution data for the last 24 hours
    entity_types = ['File', 'Folder', 'Project', 'Table', 'EntityView', 'Link', 'MaterializedView', 'Dataset', 'DatasetCollection']
    entity_distribution = {entity: random.randint(1, 100) for entity in entity_types}

    # Simulate user locations and their most popular projects
    locations = {
        'North America': {'lat': 54.5260, 'lon': -105.2551, 'most_popular_project': random.choice(project_names)},
        'South America': {'lat': -8.7832, 'lon': -55.4915, 'most_popular_project': random.choice(project_names)},
        'Europe': {'lat': 54.5260, 'lon': 15.2551, 'most_popular_project': random.choice(project_names)},
        'Africa': {'lat': -8.7832, 'lon': 34.5085, 'most_popular_project': random.choice(project_names)},
        'Asia': {'lat': 34.0479, 'lon': 100.6197, 'most_popular_project': random.choice(project_names)},
        'Australia': {'lat': -25.2744, 'lon': 133.7751, 'most_popular_project': random.choice(project_names)},
        'Antarctica': {'lat': -82.8628, 'lon': 135.0000, 'most_popular_project': random.choice(project_names)}
    }

    # Simulate popular entities
    popular_entities = {
        'File': ('file1.txt', random.randint(100, 500), random.randint(10, 50)),
        'Folder': ('folder1', random.randint(50, 200), random.randint(5, 30)),
        'Project': ('project1', random.randint(10, 100), random.randint(2, 20)),
        'Table': ('table1', random.randint(20, 150), random.randint(3, 25)),
        'EntityView': ('view1', random.randint(5, 50), random.randint(1, 10)),
        'Link': ('link1', random.randint(1, 20), random.randint(1, 5)),
        'MaterializedView': ('mview1', random.randint(2, 30), random.randint(1, 8)),
        'Dataset': ('dataset1', random.randint(3, 40), random.randint(1, 12)),
        'DatasetCollection': ('collection1', random.randint(1, 10), random.randint(1, 3)),
    }

    return total_data_size, average_project_size, project_sizes, download_sizes, unique_users_data, entity_distribution, locations, popular_entities

def main():

    # Generate sample data
    total_data_size, average_project_size, project_sizes, download_sizes, unique_users_data, entity_distribution, locations, popular_entities = generate_sample_data()

    # Row 1
    st.markdown('### Monthly Overview :calendar:')
    col1, col2, col3 = st.columns([1, 1, 15])
    col1.metric("Total Storage Occupied", f"{total_data_size} GB", "7.2 GB")
    col2.metric("Avg. Project Size", f"{average_project_size} GB", "8.0 GB")
    col3.metric("Annual Cost", "102,000 USD", "10,000 USD")

    # Row 2
    st.markdown("### Unique Users Report :bar_chart:")
    
    # Display line plot of unique users trend over 12 months for top 10 projects and median

    # Select top 10 projects based on the total number of unique users in the past 12 months
    top_projects = sorted(unique_users_data, key=lambda k: sum(unique_users_data[k]), reverse=True)[:10]
    months = pd.date_range(start=datetime.now() - timedelta(days=365), periods=12, freq='M').strftime('%Y-%m').tolist()

    fig2 = go.Figure()

    # Plot each of the top 10 projects
    for i, project in enumerate(top_projects):
        fig2.add_trace(go.Scatter(
            x=months,
            y=unique_users_data[project],
            mode='lines+markers',
            name=project,
            line=dict(width=2),
            opacity=0.6,  # Make the lines translucent by default
            hoverinfo='x+y+name',
            hovertemplate='<b>Date</b>: %{x}<br><b>Users</b>: %{y}<extra></extra>',
            showlegend=True,
            visible='legendonly'  # Only the first line is visible by default
        ))

    # Calculate and plot the median trend line
    median_values = np.median([unique_users_data[project] for project in top_projects], axis=0)
    fig2.add_trace(go.Scatter(
        x=months,
        y=median_values,
        mode='lines+markers',
        name='Median',
        line=dict(color='black', width=4),
        hoverinfo='x+y+name',
        hovertemplate='<b>Date</b>: %{x}<br><b>Users</b>: %{y}<extra></extra>',
        visible=True
    ))

    # Update layout to include buttons for toggling visibility
    fig2.update_layout(
        xaxis_title="Month",
        yaxis_title="Unique Users",
        title="Monthly Unique Users Trend (Click a Project to see more trends)",
        width=1000, height=400,

    )

    st.plotly_chart(fig2)

    # Display bar chart of download sizes with project size color bar
    download_sizes_df = pd.DataFrame(list(download_sizes.items()), columns=['Project Name', 'Download Size'])
    download_sizes_df['Project Size'] = download_sizes_df['Project Name'].map(project_sizes)
    download_sizes_df = download_sizes_df.sort_values(by='Download Size')

    fig1 = go.Figure(data=[go.Bar(
        x=download_sizes_df['Project Name'],
        y=download_sizes_df['Download Size'],
        marker=dict(
            color=download_sizes_df['Project Size'],
            colorscale='Reds',
            colorbar=dict(
                title='Project Size (GB)'
            )
        ),
        hovertemplate='<b>Project Name:</b> %{x}<br>' +
                      '<b>Download Size:</b> %{y} GB<br>' +
                      '<b>Project Size:</b> %{marker.color:.2f} GB<extra></extra>'
    )])
    fig1.update_layout(
        xaxis_title="Project Name",
        yaxis_title="Download Size (GB)",
        title="Download Size from Unique User Downloads (Ordered)",
        width=1000  # Adjust the width to make the chart more narrow
    )
    st.plotly_chart(fig1)

    st.markdown("### Entities Analysis: Most Popular Entities :chart:")
    col1, col2, col3 = st.columns([1, 1, 9])
    with col1:
        # Display most popular entities as a DataFrame
        popular_entities_df = pd.DataFrame(list(popular_entities.items()), columns=['Entity Type', 'Details'])
        popular_entities_df['Entity Name'] = popular_entities_df['Details'].apply(lambda x: x[0])
        popular_entities_df['Unique Users'] = popular_entities_df['Details'].apply(lambda x: x[1])
        popular_entities_df = popular_entities_df.drop(columns=['Details'])

        st.markdown('<div class="element-container">', unsafe_allow_html=True)
        st.dataframe(popular_entities_df)


    with col2:
        # Display pie chart of entity distribution
        entity_df = pd.DataFrame(list(entity_distribution.items()), columns=['Entity Type', 'Count'])
        fig4 = px.pie(entity_df, names='Entity Type', values='Count', title='Entity Distribution')
        fig4.update_layout(
        margin=dict(t=0, b=0, l=0, r=0),  # Remove white space around the pie chart
        title=dict(text='Entity Distribution', x=0.5)  # Center the title if needed)
        )
        st.plotly_chart(fig4)



    # Display interactive map of user downloads
    st.header("Interactive Map of User Downloads")
    locations_df = pd.DataFrame.from_dict(locations, orient='index')
    locations_df.reset_index(inplace=True)
    locations_df.columns = ['Region', 'Latitude', 'Longitude', 'Most Popular Project']

    fig3 = px.scatter_geo(
        locations_df,
        lat='Latitude',
        lon='Longitude',
        text='Region',
        hover_name='Region',
        hover_data={'Latitude': False, 'Longitude': False, 'Most Popular Project': True},
        size_max=10,
        color=locations_df['Most Popular Project'],  # Different colors for different projects
        color_continuous_scale=px.colors.sequential.Plasma  # Choose a color scale
    )

    fig3.update_geos(
        showland=True, landcolor="rgb(217, 217, 217)",
        showocean=True, oceancolor="LightBlue",
        showcountries=True, countrycolor="Black",
        showcoastlines=True, coastlinecolor="Black"
    )

    fig3.update_layout(
        title='User Downloads by Region',
        geo=dict(
            scope='world',
            projection=go.layout.geo.Projection(type='natural earth')
        ),
        width=800,  # Adjust the width to make the chart more narrow
        margin={"r":0,"t":0,"l":0,"b":0}  # Remove white space around the map
    )

    st.plotly_chart(fig3)

# Entry point for the Streamlit application
if __name__ == "__main__":
    main()