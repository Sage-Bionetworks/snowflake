import datetime
import numpy as np
import pandas as pd
import plotly.graph_objects as go
import plotly.express as px

from datetime import timedelta

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

def plot_download_sizes(download_sizes_df, project_sizes_df, width=2000):

    content_size_mapping = project_sizes_df.set_index('PROJECT_ID')['TOTAL_CONTENT_SIZE'].to_dict()
    download_sizes_df['TOTAL_CONTENT_SIZE'] = download_sizes_df['PROJECT_ID'].map(content_size_mapping)

    x = [f"project_{str(xx)}" for xx in download_sizes_df["PROJECT_ID"]]
    download_sizes_df = download_sizes_df.sort_values(by='TOTAL_DOWNLOADS')
    fig = go.Figure(data=[go.Bar(
        x=x,
        y=download_sizes_df['TOTAL_DOWNLOADS'],
        marker=dict(
            color=download_sizes_df['TOTAL_CONTENT_SIZE'],
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