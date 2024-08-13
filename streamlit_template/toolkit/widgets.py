import pandas as pd
import plotly.express as px
import plotly.graph_objects as go


def plot_unique_users_trend(unique_users_data, width=2000, height=400):

    # Group by PROJECT_ID and sum the DISTINCT_USER_COUNT
    grouped_df = (
        unique_users_data.groupby("PROJECT_ID")["DISTINCT_USER_COUNT"]
        .sum()
        .reset_index()
    )

    # Sort by DISTINCT_USER_COUNT in descending order and get the top 10
    top_projects = grouped_df.sort_values(
        by="DISTINCT_USER_COUNT", ascending=False
    ).head(10)

    fig = go.Figure()
    for i, project in zip(top_projects.index, top_projects["PROJECT_ID"]):

        # Extract the data for the current project
        filtered_df = unique_users_data[unique_users_data["PROJECT_ID"].isin([project])]
        months = pd.to_datetime(filtered_df["ACCESS_MONTH"])
        counts = filtered_df["DISTINCT_USER_COUNT"]

        # Scatter plot for the current project
        fig.add_trace(
            go.Scatter(
                x=months,
                y=list(counts),
                mode="lines+markers",
                name=project,
                line=dict(width=2),
                opacity=0.6,
                hoverinfo="x+y+name",
                hovertemplate="<b>Date</b>: %{x}<br><b>Users</b>: %{y}<extra></extra>",
                showlegend=True,
                visible="legendonly",
            )
        )
    # Calculate the median DISTINCT_USER_COUNT for each month
    median_monthly_counts = (
        unique_users_data.groupby("ACCESS_MONTH")["DISTINCT_USER_COUNT"]
        .median()
        .reset_index()
    )
    median_monthly_counts["ACCESS_MONTH"] = pd.to_datetime(
        median_monthly_counts["ACCESS_MONTH"]
    )

    fig.add_trace(
        go.Scatter(
            x=median_monthly_counts["ACCESS_MONTH"],
            y=median_monthly_counts["DISTINCT_USER_COUNT"],
            mode="lines+markers",
            name="Median",
            line=dict(color="black", width=4),
            hoverinfo="x+y+name",
            hovertemplate="<b>Date</b>: %{x}<br><b>Users</b>: %{y}<extra></extra>",
            visible=True,
        )
    )
    fig.update_layout(
        xaxis_title="Month",
        yaxis_title="Unique Users",
        title="Monthly Unique Users Trend (Click a Project to see more trends)",
        width=width,
        height=height,
    )
    return fig


def plot_download_sizes(download_sizes_df, project_sizes_df, width=2000):

    content_size_mapping = project_sizes_df.set_index("PROJECT_ID")[
        "TOTAL_CONTENT_SIZE"
    ].to_dict()
    download_sizes_df["TOTAL_CONTENT_SIZE"] = download_sizes_df["PROJECT_ID"].map(
        content_size_mapping
    )

    x = [f"project_{str(xx)}" for xx in download_sizes_df["PROJECT_ID"]]
    download_sizes_df = download_sizes_df.sort_values(by="TOTAL_DOWNLOADS")
    fig = go.Figure(
        data=[
            go.Bar(
                x=x,
                y=download_sizes_df["TOTAL_DOWNLOADS"],
                marker=dict(
                    color=download_sizes_df["TOTAL_CONTENT_SIZE"],
                    colorscale="Reds",
                    colorbar=dict(title="Project Size (GB)"),
                ),
                hovertemplate="<b>Project Name:</b> %{x}<br>"
                + "<b>Download Size:</b> %{y} GB<br>"
                + "<b>Project Size:</b> %{marker.color:.2f} GB<extra></extra>",
            )
        ]
    )
    fig.update_layout(
        xaxis_title="Project Name",
        yaxis_title="Download Size (GB)",
        title="Download Size from Unique User Downloads (Ordered)",
        width=width,
    )
    return fig


def plot_popular_entities(popular_entities):
    popular_entities_df = pd.DataFrame(
        list(popular_entities.items()), columns=["Entity Type", "Details"]
    )
    popular_entities_df["Entity Name"] = popular_entities_df["Details"].apply(
        lambda x: x[0]
    )
    popular_entities_df["Unique Users"] = popular_entities_df["Details"].apply(
        lambda x: x[1]
    )
    popular_entities_df = popular_entities_df.drop(columns=["Details"])
    return popular_entities_df


def plot_entity_distribution(entity_distribution):
    entity_df = pd.DataFrame(
        list(entity_distribution.items()), columns=["Entity Type", "Count"]
    )
    fig = px.pie(
        entity_df, names="Entity Type", values="Count", title="Entity Distribution"
    )
    fig.update_layout(
        margin=dict(t=0, b=0, l=0, r=0), title=dict(text="Entity Distribution", x=0.5)
    )
    return fig


def plot_user_downloads_map(locations, width=10000):
    locations_df = pd.DataFrame.from_dict(locations, orient="index")
    locations_df.reset_index(inplace=True)
    locations_df.columns = ["Region", "Latitude", "Longitude", "Most Popular Project"]
    fig = px.scatter_geo(
        locations_df,
        lat="Latitude",
        lon="Longitude",
        text="Region",
        hover_name="Region",
        hover_data={
            "Latitude": False,
            "Longitude": False,
            "Most Popular Project": True,
        },
        size_max=10,
        color=locations_df["Most Popular Project"],
        color_continuous_scale=px.colors.sequential.Plasma,
    )
    fig.update_geos(
        showland=True,
        landcolor="rgb(217, 217, 217)",
        showocean=True,
        oceancolor="LightBlue",
        showcountries=True,
        countrycolor="Black",
        showcoastlines=True,
        coastlinecolor="Black",
    )
    fig.update_layout(
        title="User Downloads by Region",
        geo=dict(
            scope="world", projection=go.layout.geo.Projection(type="natural earth")
        ),
        width=width,
        margin={"r": 0, "t": 0, "l": 0, "b": 0},
    )
    return fig
