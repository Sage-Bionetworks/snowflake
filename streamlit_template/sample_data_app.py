import streamlit as st
from snowflake.snowpark import Session
import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import plotly.graph_objects as go
import plotly.express as px

# Custom CSS for sage green filled containers and banners
with open('style.css') as f:
    st.markdown(f'<style>{f.read()}</style>', unsafe_allow_html=True)

@st.cache_resource
def connect_to_snowflake():
    session = Session.builder.configs(st.secrets.snowflake).create()
    return session

@st.cache_data
def get_data_from_snowflake(query=""):
    session = connect_to_snowflake()
    node_latest = session.sql(query).to_pandas()
    return node_latest

@st.cache_data
def generate_sample_data():
    total_data_size = round(random.uniform(100, 1000), 2)  # In GB
    average_project_size = round(random.uniform(5, 50), 2)  # In GB
    project_names = [f"Project {i}" for i in range(1, 21)]
    project_sizes = {project: random.uniform(1, 50) for project in project_names}  # Project sizes in GB
    download_sizes = {project: random.randint(10, 1000) for project in project_names}  # Download sizes in GB
    months = pd.date_range(start=datetime.now() - timedelta(days=365), periods=12, freq='M').strftime('%Y-%m').tolist()
    unique_users_data = {project: [random.randint(50, 150) for _ in months] for project in project_names}
    entity_types = ['File', 'Folder', 'Project', 'Table', 'EntityView', 'Link', 'MaterializedView', 'Dataset', 'DatasetCollection']
    entity_distribution = {entity: random.randint(1, 100) for entity in entity_types}
    locations = {
        'North America': {'lat': 54.5260, 'lon': -105.2551, 'most_popular_project': random.choice(project_names)},
        'South America': {'lat': -8.7832, 'lon': -55.4915, 'most_popular_project': random.choice(project_names)},
        'Europe': {'lat': 54.5260, 'lon': 15.2551, 'most_popular_project': random.choice(project_names)},
        'Africa': {'lat': -8.7832, 'lon': 34.5085, 'most_popular_project': random.choice(project_names)},
        'Asia': {'lat': 34.0479, 'lon': 100.6197, 'most_popular_project': random.choice(project_names)},
        'Australia': {'lat': -25.2744, 'lon': 133.7751, 'most_popular_project': random.choice(project_names)},
        'Antarctica': {'lat': -82.8628, 'lon': 135.0000, 'most_popular_project': random.choice(project_names)}
    }
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

def plot_unique_users_trend(unique_users_data, width=2000, height=400):
    top_projects = sorted(unique_users_data, key=lambda k: sum(unique_users_data[k]), reverse=True)[:10]
    months = pd.date_range(start=datetime.now() - timedelta(days=365), periods=12, freq='M').strftime('%Y-%m').tolist()
    fig = go.Figure()
    for i, project in enumerate(top_projects):
        fig.add_trace(go.Scatter(
            x=months,
            y=unique_users_data[project],
            mode='lines+markers',
            name=project,
            line=dict(width=2),
            opacity=0.6,
            hoverinfo='x+y+name',
            hovertemplate='<b>Date</b>: %{x}<br><b>Users</b>: %{y}<extra></extra>',
            showlegend=True,
            visible='legendonly'
        ))
    median_values = np.median([unique_users_data[project] for project in top_projects], axis=0)
    fig.add_trace(go.Scatter(
        x=months,
        y=median_values,
        mode='lines+markers',
        name='Median',
        line=dict(color='black', width=4),
        hoverinfo='x+y+name',
        hovertemplate='<b>Date</b>: %{x}<br><b>Users</b>: %{y}<extra></extra>',
        visible=True
    ))
    fig.update_layout(
        xaxis_title="Month",
        yaxis_title="Unique Users",
        title="Monthly Unique Users Trend (Click a Project to see more trends)",
        width=width, height=height
    )
    return fig

def plot_download_sizes(download_sizes, project_sizes, width=2000):
    download_sizes_df = pd.DataFrame(list(download_sizes.items()), columns=['Project Name', 'Download Size'])
    download_sizes_df['Project Size'] = download_sizes_df['Project Name'].map(project_sizes)
    download_sizes_df = download_sizes_df.sort_values(by='Download Size')
    fig = go.Figure(data=[go.Bar(
        x=download_sizes_df['Project Name'],
        y=download_sizes_df['Download Size'],
        marker=dict(
            color=download_sizes_df['Project Size'],
            colorscale='Reds',
            colorbar=dict(title='Project Size (GB)')
        ),
        hovertemplate='<b>Project Name:</b> %{x}<br>' +
                      '<b>Download Size:</b> %{y} GB<br>' +
                      '<b>Project Size:</b> %{marker.color:.2f} GB<extra></extra>'
    )])
    fig.update_layout(
        xaxis_title="Project Name",
        yaxis_title="Download Size (GB)",
        title="Download Size from Unique User Downloads (Ordered)",
        width=width
    )
    return fig

def plot_popular_entities(popular_entities):
    popular_entities_df = pd.DataFrame(list(popular_entities.items()), columns=['Entity Type', 'Details'])
    popular_entities_df['Entity Name'] = popular_entities_df['Details'].apply(lambda x: x[0])
    popular_entities_df['Unique Users'] = popular_entities_df['Details'].apply(lambda x: x[1])
    popular_entities_df = popular_entities_df.drop(columns=['Details'])
    return popular_entities_df

def plot_entity_distribution(entity_distribution):
    entity_df = pd.DataFrame(list(entity_distribution.items()), columns=['Entity Type', 'Count'])
    fig = px.pie(entity_df, names='Entity Type', values='Count', title='Entity Distribution')
    fig.update_layout(
        margin=dict(t=0, b=0, l=0, r=0),
        title=dict(text='Entity Distribution', x=0.5)
    )
    return fig

def plot_user_downloads_map(locations, width=10000):
    locations_df = pd.DataFrame.from_dict(locations, orient='index')
    locations_df.reset_index(inplace=True)
    locations_df.columns = ['Region', 'Latitude', 'Longitude', 'Most Popular Project']
    fig = px.scatter_geo(
        locations_df,
        lat='Latitude',
        lon='Longitude',
        text='Region',
        hover_name='Region',
        hover_data={'Latitude': False, 'Longitude': False, 'Most Popular Project': True},
        size_max=10,
        color=locations_df['Most Popular Project'],
        color_continuous_scale=px.colors.sequential.Plasma
    )
    fig.update_geos(
        showland=True, landcolor="rgb(217, 217, 217)",
        showocean=True, oceancolor="LightBlue",
        showcountries=True, countrycolor="Black",
        showcoastlines=True, coastlinecolor="Black"
    )
    fig.update_layout(
        title='User Downloads by Region',
        geo=dict(
            scope='world',
            projection=go.layout.geo.Projection(type='natural earth')
        ),
        width=width,
        margin={"r":0,"t":0,"l":0,"b":0}
    )
    return fig

def main():

    total_data_size, average_project_size, project_sizes, download_sizes, unique_users_data, entity_distribution, locations, popular_entities = generate_sample_data()

    # Row 1 -------------------------------------------------------------------
    st.markdown('### Monthly Overview :calendar:')
    col1, col2, col3 = st.columns([1, 1, 1])
    col1.metric("Total Storage Occupied", f"{total_data_size} GB", "7.2 GB")
    col2.metric("Avg. Project Size", f"{average_project_size} GB", "8.0 GB")
    col3.metric("Annual Cost", "102,000 USD", "10,000 USD")

    # Row 2 -------------------------------------------------------------------
    st.markdown("### Unique Users Report :bar_chart:")
    st.plotly_chart(plot_unique_users_trend(unique_users_data))

    # Row 3 -------------------------------------------------------------------
    st.plotly_chart(plot_download_sizes(download_sizes, project_sizes))

    # Row 4 -------------------------------------------------------------------
    st.markdown("### Entity Trends :pencil:")
    col1, col2 = st.columns(2)
    with col1:
        st.markdown('<div class="element-container">', unsafe_allow_html=True)
        st.dataframe(plot_popular_entities(popular_entities))
    with col2:
        st.plotly_chart(plot_entity_distribution(entity_distribution))

    # Row 5 -------------------------------------------------------------------
    st.markdown("### Interactive Map of User Downloads :earth_africa:")
    st.plotly_chart(plot_user_downloads_map(locations))

if __name__ == "__main__":
    main()