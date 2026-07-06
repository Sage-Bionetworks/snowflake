import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import networkx as nx
from pyvis.network import Network
from graphviz import Digraph
from collections import Counter
import streamlit as st
import streamlit.components.v1 as components

# Palette

PORTAL_BLUE = "#125E81"
PORTAL_DARK = "#404B63"
PINK = "#E9B4CE"
PURPLE = "#392965"
BEIGE = "#f2d7a6"
TEAL = "#0e8177"
ORANGE = "#bc590b"
LIGHT_BLUE = "#748dcd"
MAGENTA = "#af316c"
PALE_BLUE = "#aac3d4"
OFF_WHITE = "#F0E7E0"
LAVENDER = "#9186B1"
GREEN = "#59A159"
NAVY = "#303C50"
GRAY = "#636E83"
DARK_RED = "#941E24"

# Visualzing the project porfolio ---------------------------#


def plot_stacked_bar_chart(df: pd.DataFrame, width: int = 1400) -> go.Figure:
    """
    Plots a stacked bar chart to show the distribution of project and data statuses.

    Parameters:
    - df (pd.DataFrame): DataFrame containing project and data status information.
    - width (int): Width of the plot.

    Returns:
    - go.Figure: Plotly figure for the stacked bar chart.
    """
    if df.empty:
        st.warning("DataFrame is empty. Please provide a valid dataset.")
        return go.Figure()

    project_status_col = "STUDY_STATUS"
    data_status_col = "DATA_STATUS"

    if project_status_col not in df.columns or data_status_col not in df.columns:
        st.error("DataFrame must contain STUDY_STATUS and DATA_STATUS columns.")
        return go.Figure()

    # Group by PROJECT_STATUS and DATA_STATUS and count occurrences
    status_counts = (
        df.groupby([project_status_col, data_status_col]).size().unstack(fill_value=0)
    )

    # Define colors for each DATA_STATUS
    colors = {
        "Available": "#125e81",
        "Data Not Expected": "#636E83",
        "Data Pending": "#f2d7a6",
        "Partially Available": "#aec6cf",
        "Rolling Release": "#1f77b4",
        "Under Embargo": "#e9b4ce",
    }

    # Create Plotly figure
    fig = go.Figure()

    # Add each DATA_STATUS as a separate trace
    for status in status_counts.columns:
        fig.add_trace(
            go.Bar(
                y=status_counts.index,  # PROJECT_STATUS
                x=status_counts[status],  # Count of each DATA_STATUS
                name=status,
                orientation="h",
                marker=dict(color=colors.get(status, "#333333")),
            )
        )

    # Update layout
    fig.update_layout(
        barmode="stack",
        xaxis_title="Count",
        yaxis_title="Project Status",
        legend_title="Data Status",
        legend=dict(x=1.05, y=1),
        width=width,
        height=400,
        margin=dict(l=100, r=100, t=20, b=50),
    )

    return fig


# Flowchart configuration

leaf_attributes = {
    "Rolling Release": {"fillcolor": "#125e81", "fontcolor": "white"},
    "Partially Available": {"fillcolor": "#125e81", "fontcolor": "white"},
    "Available": {"fillcolor": "#125e81", "fontcolor": "white"},
    "Under Embargo": {"fillcolor": "#e9b4ce", "fontcolor": "black"},
    "Data Pending": {"fillcolor": "#f2d7a6", "fontcolor": "black"},
    "Data Not Expected": {"fillcolor": "#636E83", "fontcolor": "white"},
}

# Define the hierarchy of nodes
hierarchy = {
    "Total projects": {
        "name": "Total projects",
        "fillcolor": "#392965",
        "fontcolor": "white",
        "children": {
            "Data Released": {
                "name": "Data Released",
                "fillcolor": "#125e81",
                "fontcolor": "white",
                "children": {
                    "Rolling Release": {},
                    "Partially Available": {},
                    "Available": {},
                },
            },
            "Data Unreleased": {
                "name": "Data Unreleased",
                "fillcolor": "#af316c",
                "fontcolor": "white",
                "children": {"Under Embargo": {}, "Data Pending": {}},
            },
            "Data Not Expected": {},
        },
    }
}


def count_leaves(data_statuses):
    """
    Counts occurrences of each leaf label in the data_statuses.
    """
    counts = Counter(data_statuses)
    return counts


def process_node(node_name, node_dict, graph, counts):
    """
    Recursively processes each node to build the graph.
    """
    label_name = node_dict.get("name", node_name)
    if "children" in node_dict and node_dict["children"]:
        # Node has children; process them recursively
        total_count = 0
        for child_name, child_dict in node_dict["children"].items():
            child_count = process_node(child_name, child_dict, graph, counts)
            total_count += child_count
            # Create edge from current node to child
            graph.edge(node_name, child_name)
        # Create the current node with the aggregated count
        label = f"{label_name}\n(n={total_count})"
        graph.node(
            node_name,
            label=label,
            fillcolor=node_dict.get("fillcolor", "#FFFFFF"),
            fontcolor=node_dict.get("fontcolor", "white"),
        )
        return total_count
    else:
        # Leaf node; get count from counts dictionary
        count = counts.get(label_name, 0)
        label = f"{label_name}\n(n={count})"
        attributes = leaf_attributes.get(label_name, {})
        graph.node(
            node_name,
            label=label,
            fillcolor=attributes.get("fillcolor", "#FFFFFF"),
            fontcolor=attributes.get("fontcolor", "white"),
        )
        return count


def graphviz_status(data_vector):
    # Count occurrences of each leaf label
    counts = count_leaves(data_vector)
    total_projects = sum(counts.values())

    graph = Digraph("G", format="png")
    graph.attr(rankdir="TD")
    graph.attr("node", shape="box", fontname="Helvetica", style="filled")
    graph.attr("edge", fontname="Helvetica")

    # Update the total projects count
    hierarchy["Total projects"]["total_count"] = total_projects

    # Process the hierarchy starting from the root node
    process_node("Total projects", hierarchy["Total projects"], graph, counts)

    # Set specific nodes on the same rank
    with graph.subgraph() as s:
        s.attr(rank="same")
        s.node("Data Released")
        s.node("Data Unreleased")
        s.node("Data Not Expected")

    return graph


# Plots for downloads ---------------------------------------------------------#


def plot_download_sizes(df, project_sizes_df, width=1600):

    content_size_mapping = project_sizes_df.set_index("PROJECT_ID")[
        "TOTAL_CONTENT_SIZE"
    ].to_dict()
    df["TOTAL_CONTENT_SIZE"] = df["PROJECT_ID"].map(content_size_mapping)

    x = [f"project_{str(xx)}" for xx in df["PROJECT_ID"]]
    df = df.sort_values(by="TOTAL_DOWNLOADS")
    fig = go.Figure(
        data=[
            go.Bar(
                x=x,
                y=df["TOTAL_DOWNLOADS"],
                marker=dict(
                    color=df["TOTAL_CONTENT_SIZE"],
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


def plot_download_sizes_lollipop(df, color=PORTAL_BLUE, width=1600):
    # Sort the DataFrame by 'TOTAL_DOWNLOADS'
    df = df.sort_values(by="TOTAL_DOWNLOADS")
    x = [f"syn{str(xx)}" for xx in df["PROJECT_ID"]]

    # Determine the baseline y0 (a small positive value less than any y)
    y_min = df["TOTAL_DOWNLOADS"].min()
    y0 = (
        y_min / 10
        if y_min > 0
        else df[df["TOTAL_DOWNLOADS"] > 0]["TOTAL_DOWNLOADS"].min() / 10
    )

    # Create line segments for the lollipop sticks
    x_line = []
    y_line = []

    for xi, yi in zip(x, df["TOTAL_DOWNLOADS"]):
        x_line.extend([xi, xi, None])
        y_line.extend([y0, yi, None])

    fig = go.Figure()

    # Add the lines (lollipop sticks)
    fig.add_trace(
        go.Scatter(
            x=x_line,
            y=y_line,
            mode="lines",
            line=dict(color="rgba(0,0,0,0.3)", width=1),
            showlegend=False,
        )
    )

    # Add the markers (lollipop heads)
    fig.add_trace(
        go.Scatter(
            x=x,
            y=df["TOTAL_DOWNLOADS"],
            mode="markers",
            marker=dict(
                size=20,
                color=color,
            ),
            name="Download Size",
        )
    )

    fig.update_layout(
        xaxis_title="Project Name",
        yaxis_title="Log-scaled Download Size (bytes)",
        yaxis_type="log",
        title="Download Sizes Across Projects (Ordered)",
        width=width,
        hovermode="closest",
    )

    fig.update_traces(
        hovertemplate="<b>Project Name:</b> %{x}<br>"
        "<b>Download Size:</b> %{y} bytes<extra></extra>"
    )

    return fig


def plot_monthly_egress(df, key="FILE_COUNT", width=2200):
    fig = go.Figure()
    y_label = key.replace("_", " ").title()
    num_projects = df["PROJECT_NAME"].nunique()

    for project_name in df["PROJECT_NAME"].unique():
        project_df = df[df["PROJECT_NAME"] == project_name]
        fig.add_trace(
            go.Bar(
                x=project_df["ACCESS_MONTH"],
                y=project_df[key],
                name=f"{project_name}",
                hovertemplate="<b>Month:</b> %{x}<br>"
                "<b>Y-axis:</b> %{y}<br>"
                f"<b>Project Name:</b> {project_name}<extra></extra>",
            )
        )

    fig.update_layout(
        xaxis_title="Month",
        yaxis_title="Number of Unique Files",
        title=f"Unique Files Requested by Month For {num_projects} Projects",
        width=width,
        bargap=0.6,
        barmode="stack",
    )

    return fig


def plot_resource_downloads(
    df,
    resource_column,
    color="teal",
    title=None,
    count_column="DOWNLOAD_COUNT",
    width=1600,
    height=600,
):

    df[resource_column] = df[resource_column].fillna("Not Available")
    summarized_df = df.groupby(resource_column)[count_column].sum().reset_index()

    summarized_df = summarized_df.sort_values(count_column, ascending=False)

    fig = go.Figure(
        data=[
            go.Bar(
                x=summarized_df[resource_column],
                y=summarized_df[count_column],
                marker_color=color,
                marker_line_color=color,
                marker_line_width=1.5,
                width=0.2,
            )
        ]
    )

    fig.update_layout(
        title=title or f"{resource_column} Download Counts",
        xaxis_title=resource_column,
        yaxis_title="Download Count",
        width=width,
        height=height,
        xaxis_tickangle=-45,
        hovermode="x unified",
    )

    fig.update_traces(
        hovertemplate=f"<b>{resource_column}:</b> %{{x}}<br><b>Download Count:</b> %{{y}}<extra></extra>"
    )

    return fig


def merge_size_and_downloads(df_size, df_downloads):
    """
    Merges project size and download DataFrames, and prepares data for plotting.

    Parameters:
    - df_size: DataFrame containing 'PROJECT_ID', 'PROJECT_NAME', and 'FILE_CONTENT_SIZE' (project sizes)
    - df_downloads: DataFrame containing 'PROJECT_ID' and 'TOTAL_DOWNLOADS' (downloads)

    Returns:
    - merged_df: DataFrame with merged and processed data
    """
    # Merge the two DataFrames on 'PROJECT_ID'
    merged_df = pd.merge(df_size, df_downloads, on="PROJECT_ID", how="left")

    # Replace NaN values in downloads with zero (projects with no downloads)
    merged_df["TOTAL_DOWNLOADS"] = merged_df["TOTAL_DOWNLOADS"].fillna(0)

    # Truncate PROJECT_NAME to 5 words
    merged_df["TRUNCATED_NAME"] = merged_df["PROJECT_NAME"].apply(
        lambda x: " ".join(x.split()[:5]) + ("..." if len(x.split()) > 5 else "")
    )

    return merged_df


def plot_download_scatter(merged_df):
    """
    Creates a scatter plot comparing project sizes with the number of downloads.

    Parameters:
    - merged_df: DataFrame containing 'PROJECT_ID', 'TRUNCATED_NAME', 'FILE_CONTENT_SIZE', and 'TOTAL_DOWNLOADS'

    Note:
    - This function now uses the merged DataFrame directly.
    """

    # Create the scatter plot
    fig = px.scatter(
        merged_df,
        x="TOTAL_CONTENT_SIZE",
        y="TOTAL_DOWNLOADS",
        labels={
            "TOTAL_CONTENT_SIZE": "Project Size (bytes)",
            "TOTAL_DOWNLOADS": "Total Download Size (bytes)",
        },
        title="Total Project Data Size vs. Total Downloads",
        hover_data=["PROJECT_ID", "PROJECT_NAME"],
        text="TRUNCATED_NAME",
    )

    fig.update_traces(marker=dict(color=DARK_RED, size=15), textposition="top center")
    fig.update_xaxes(type="log")
    fig.update_yaxes(type="log")

    fig.update_layout(width=1600, height=800)

    return fig


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


# Plots for users ---------------------------------------------------------#


def plot_unique_users_monthly(unique_users_data, width=2000, height=600):

    # Summarize unique_users_data to create DISTINCT_USER_COUNT
    summarized_data = (
        unique_users_data.groupby(["PROJECT_ID", "PROJECT_NAME", "ACCESS_MONTH"])
        .agg(DISTINCT_USER_COUNT=("USER_ID", "nunique"))
        .reset_index()
    )

    # Group by PROJECT_NAME and sum the DISTINCT_USER_COUNT
    grouped_df = (
        summarized_data.groupby("PROJECT_NAME")["DISTINCT_USER_COUNT"]
        .sum()
        .reset_index()
    )

    # Sort by DISTINCT_USER_COUNT in descending order and get the top 10
    top_projects = grouped_df.sort_values(
        by="DISTINCT_USER_COUNT", ascending=False
    ).head(10)

    fig = go.Figure()
    for i, project in zip(top_projects.index, top_projects["PROJECT_NAME"]):

        # Extract the data for the current project
        filtered_df = summarized_data[summarized_data["PROJECT_NAME"].isin([project])]
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
                visible=True,
            )
        )

    fig.update_layout(
        xaxis_title="Month",
        yaxis_title="Unique Users",
        title="Monthly Unique Data Downloaders for Top 10 Projects",
        width=width,
        height=height,
    )
    return fig


def plot_network(df):
    df["WEIGHT"] = 1  # Assign a weight of 1 for each interaction
    df_weights = df.groupby(["USER_ID", "PROJECT_ID"])["WEIGHT"].sum().reset_index()

    G = nx.Graph()

    for _, row in df_weights.iterrows():
        user = str(row["USER_ID"])
        project = str(row["PROJECT_ID"])
        weight = int(row["WEIGHT"])

        if not G.has_node(user):
            G.add_node(
                user, label="", color=MAGENTA, size=150
            )  # IMPORTANT -- hide user_ids
        if not G.has_node(project):
            G.add_node(project, label=project, color=TEAL, size=250)

        # Add edges with weights
        G.add_edge(
            user, project, color="gray", weight=weight, title=f"Interactions: {weight}"
        )

    net = Network(height="750px", width="100%", bgcolor="white", font_color="black")

    net.barnes_hut()
    net.from_nx(G)
    # Generate and embed the network graph in Streamlit
    html_content = net.generate_html()
    components.html(html_content, height=800)


def network_legend():
    net = Network(height="100px", width="100%", bgcolor="white", font_color="black")
    net.add_node(
        "legend_user",
        label="Users",
        color=MAGENTA,
        size=5,
        x=-100,
        y=0,
        fixed=True,
        physics=False,
    )
    net.add_node(
        "legend_project",
        label="Projects",
        color=TEAL,
        size=10,
        x=0,
        y=0,
        fixed=True,
        physics=False,
    )
    html_content = net.generate_html()
    components.html(html_content, height=250, width=600)


def plot_project_pageviews(df):
    """
    Bar chart showing top projects ordered by total screen pageviews.

    """
    if df.empty:
        fig = px.bar(
            title="Check that query range falls within retention limit of 14 months and credentials are valid."
        )
        return fig

    # Sort the DataFrame by TotalScreenPageViews in descending order and get top 10
    df_sorted = df.sort_values(by="TOTAL_PAGEVIEWS", ascending=False).head(10)

    # Create the bar chart using Plotly Express
    fig = px.bar(
        df_sorted,
        x="PROJECT_NAME",
        y="TOTAL_PAGEVIEWS",
        title="Page Views for Top 10 Projects",
        labels={"TOTAL_PAGEVIEWS": "Total Page Views", "PROJECT_NAME": "Project"},
        text="TOTAL_PAGEVIEWS",
        color="TOTAL_PAGEVIEWS",
        color_continuous_scale="Blues",
    )

    # Update layout for better aesthetics
    fig.update_layout(
        xaxis_tickangle=-30,
        yaxis=dict(title="Total Page Views"),
        xaxis=dict(
            title="Project",
            ticktext=[
                f"{text[:50]}..." if len(text) > 50 else text
                for text in df_sorted["PROJECT_NAME"]
            ],
            tickvals=list(range(len(df_sorted))),
        ),
        template="plotly_white",
        height=800,
    )

    # Add hover information
    fig.update_traces(
        hovertemplate="<b>Project:</b> "
        + df_sorted["PROJECT_NAME"]
        + "<br>"
        + "<b>Total Page Views:</b> %{y}<extra></extra>"
    )
    return fig


def plot_missing_institution(df, width=1600):
    """
    Plot a horizontal bar chart showing the percentage of projects with missing institution data.

    Args:
        df: DataFrame with columns ['ISSUE_TYPE', 'PERCENTAGE']
        width: Plot width
    """
    if df.empty:
        st.warning("No data available for missing institution plot.")
        return go.Figure()

    # Create horizontal bar chart
    fig = go.Figure(
        data=[
            go.Bar(
                y=df["ISSUE_TYPE"],
                x=df["PERCENTAGE"],
                orientation="h",
                marker_color=[
                    PORTAL_BLUE if x == "Valid" else ORANGE for x in df["ISSUE_TYPE"]
                ],
                text=[f"{p:.1f}%" for p in df["PERCENTAGE"]],
                textposition="auto",
            )
        ]
    )

    fig.update_layout(
        title="Institution Data Completeness",
        xaxis_title="Percentage of Projects",
        yaxis_title="Issue Type",
        width=width,
        height=400,
        margin=dict(l=100, r=50, t=50, b=50),
    )

    return fig


def plot_cumulative_data_growth(df, width=1000, height=700):
    """
    Plot cumulative data growth over time showing both file count and total size.
    Publication-ready formatting with consistent gridlines and appropriate aspect ratio.

    Args:
        df: DataFrame with columns ['created_on', 'content_size']
        width: Plot width (default: 1000 for publication)
        height: Plot height (default: 700 for publication)

    Returns:
        plotly.graph_objects.Figure: Figure with dual y-axes showing cumulative growth
    """
    if df.empty:
        st.warning("No file metadata available for cumulative growth plot.")
        return go.Figure()

    # Ensure we have the required columns
    required_cols = ["CREATED_ON", "CONTENT_SIZE"]
    if not all(col in df.columns for col in required_cols):
        st.error(f"DataFrame must contain columns: {required_cols}")
        return go.Figure()

    # Convert created_on to datetime and sort
    df = df.copy()
    df["CREATED_ON"] = pd.to_datetime(df["CREATED_ON"])
    df = df.sort_values("CREATED_ON").reset_index(drop=True)

    # Remove rows with null content_size
    df = df.dropna(subset=["CONTENT_SIZE"])

    if df.empty:
        st.warning("No valid file data after filtering.")
        return go.Figure()

    # Calculate cumulative values
    df["cumulative_size_bytes"] = df["CONTENT_SIZE"].cumsum()
    df["cumulative_size_tb"] = df["cumulative_size_bytes"] / (1024**4)  # Convert to TB
    df["cumulative_count"] = range(1, len(df) + 1)

    # Extract date for x-axis
    df["date"] = df["CREATED_ON"].dt.date

    # Group by date to get the final values for each day (in case multiple files created same day)
    daily_data = (
        df.groupby("date")
        .agg({"cumulative_size_tb": "last", "cumulative_count": "last"})
        .reset_index()
    )

    # Calculate scaling factor for secondary axis (similar to R code)
    max_count = daily_data["cumulative_count"].max()
    max_size = daily_data["cumulative_size_tb"].max()
    scale_factor = max_size / max_count if max_count > 0 else 1

    # Create figure with secondary y-axis
    fig = go.Figure()

    # Add cumulative size line (primary y-axis)
    fig.add_trace(
        go.Scatter(
            x=daily_data["date"],
            y=daily_data["cumulative_size_tb"],
            mode="lines",
            name="Cumulative Size (TB)",
            line=dict(color=DARK_RED, width=3),
            yaxis="y",
        )
    )

    # Add cumulative count line (secondary y-axis)
    fig.add_trace(
        go.Scatter(
            x=daily_data["date"],
            y=daily_data["cumulative_count"],
            mode="lines",
            name="# of Files",
            line=dict(color=PORTAL_BLUE, width=3),
            yaxis="y2",
        )
    )

    # Update layout with dual y-axes and publication-ready styling
    fig.update_layout(
        title=dict(
            text=f"NF Data Portal: Cumulative Data Growth Over Time<br><sub>Total: {max_size:.1f} TB across {max_count:,} files</sub>",
            x=0.5,
            font=dict(size=18, family="Arial", color="black"),
        ),
        xaxis=dict(
            title=dict(text="Year", font=dict(size=14, family="Arial", color="black")),
            tickfont=dict(size=12, family="Arial", color="black"),
            tickformat="%Y",
            showgrid=True,
            gridwidth=1,
            gridcolor="rgba(128,128,128,0.3)",
            zeroline=False,
            linecolor="black",
            linewidth=1,
            mirror=True,
        ),
        yaxis=dict(
            title=dict(
                text="Cumulative Size (TB)",
                font=dict(color="black", size=14, family="Arial"),
            ),
            tickfont=dict(color="black", size=12, family="Arial"),
            side="left",
            showgrid=True,
            gridwidth=1,
            gridcolor="rgba(128,128,128,0.3)",
            zeroline=False,
            linecolor="black",
            linewidth=1,
            mirror=True,
            # Set consistent tick intervals
            dtick=25,  # 25 TB intervals
        ),
        yaxis2=dict(
            title=dict(
                text="# of Files", font=dict(color="black", size=14, family="Arial")
            ),
            tickfont=dict(color="black", size=12, family="Arial"),
            overlaying="y",
            side="right",
            tickformat=",d",
            showgrid=False,  # Don't show secondary gridlines to avoid conflicts
            zeroline=False,
            linecolor="black",
            linewidth=1,
            mirror=True,
            # Set consistent tick intervals
            dtick=50000,  # 50k file intervals
        ),
        width=width,
        height=height,
        margin=dict(l=100, r=100, t=100, b=80),
        legend=dict(
            x=0.02,
            y=0.98,
            bgcolor="rgba(255,255,255,0.9)",
            bordercolor="rgba(0,0,0,0.5)",
            borderwidth=1,
            font=dict(size=12, family="Arial", color="black"),
        ),
        hovermode="x unified",
        plot_bgcolor="white",
        paper_bgcolor="white",
        # Clean publication-ready styling
        font=dict(family="Arial", size=12, color="black"),
    )

    return fig


# Data Type Metrics Visualizations ---------------------------------------------------------#


def plot_data_type_bar_chart(
    df, title="Data Types by Size", width=1400, height=600, color=PORTAL_BLUE
):
    """
    Creates a bar chart showing data types ranked by size with file counts.

    Args:
        df: DataFrame with columns ['DATA_TYPE', 'TOTAL_SIZE', 'FILE_COUNT']
        title: Chart title
        width: Plot width
        height: Plot height
        color: Bar color

    Returns:
        plotly.graph_objects.Figure: Bar chart figure
    """
    if df.empty:
        st.warning("No data available for data type visualization.")
        return go.Figure()

    # Convert bytes to GB for display
    df = df.copy()
    df["SIZE_GB"] = df["TOTAL_SIZE"] / (1024**3)

    # Sort by size descending
    df = df.sort_values("TOTAL_SIZE", ascending=False)

    # Create bar chart
    fig = go.Figure(
        data=[
            go.Bar(
                x=df["DATA_TYPE"],
                y=df["SIZE_GB"],
                marker_color=color,
                text=[
                    f"{size:.1f} GB<br>{count:,} files"
                    for size, count in zip(df["SIZE_GB"], df["FILE_COUNT"])
                ],
                textposition="outside",
                hovertemplate="<b>%{x}</b><br>"
                + "Size: %{y:.2f} GB<br>"
                + "Files: %{customdata:,}<extra></extra>",
                customdata=df["FILE_COUNT"],
            )
        ]
    )

    fig.update_layout(
        title=dict(text=title, x=0.5, xanchor="center", font=dict(size=16)),
        xaxis_title="Data Type",
        yaxis_title="Total Size (GB)",
        width=width,
        height=height,
        xaxis_tickangle=-45,
        margin=dict(l=80, r=40, t=100, b=120),
        hovermode="x unified",
    )

    return fig


def create_data_type_table(df):
    """
    Creates a formatted table showing data type, size, and file count.

    Args:
        df: DataFrame with columns ['DATA_TYPE', 'TOTAL_SIZE', 'FILE_COUNT']

    Returns:
        DataFrame: Formatted for display
    """
    if df.empty:
        return pd.DataFrame()

    display_df = df.copy()

    # Convert bytes to GB and TB for display
    display_df["SIZE_TB"] = display_df["TOTAL_SIZE"] / (1024**4)
    display_df["SIZE_GB"] = display_df["TOTAL_SIZE"] / (1024**3)

    # Choose appropriate unit based on size
    display_df["FORMATTED_SIZE"] = display_df.apply(
        lambda row: (
            f"{row['SIZE_TB']:.2f} TB"
            if row["SIZE_TB"] >= 1
            else f"{row['SIZE_GB']:.2f} GB"
        ),
        axis=1,
    )

    # Format file count with commas
    display_df["FORMATTED_FILES"] = display_df["FILE_COUNT"].apply(lambda x: f"{x:,}")

    # Create final display dataframe
    result = display_df[["DATA_TYPE", "FORMATTED_SIZE", "FORMATTED_FILES"]].copy()
    result.columns = ["Data Type", "Total Size", "File Count"]

    return result


def format_size_metric(bytes_value):
    """
    Format bytes into human-readable size with appropriate unit.

    Args:
        bytes_value: Size in bytes

    Returns:
        tuple: (formatted_value, unit) e.g., (1.5, "TB")
    """
    if bytes_value >= 1024**4:  # TB
        return bytes_value / (1024**4), "TB"
    elif bytes_value >= 1024**3:  # GB
        return bytes_value / (1024**3), "GB"
    elif bytes_value >= 1024**2:  # MB
        return bytes_value / (1024**2), "MB"
    else:
        return bytes_value, "Bytes"
