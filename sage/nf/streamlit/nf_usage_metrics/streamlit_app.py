import argparse
import numpy as np
import pandas as pd
import streamlit as st
import graphviz
from datetime import datetime, timedelta
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session
from sklearn.linear_model import LinearRegression
from sklearn.metrics import r2_score

# local imports
from toolkit.queries import (
    query_project_meta,
    query_project_meta_other_funders,
    query_project_meta_with_initiative,
    query_all_initiatives,
    query_entity_distribution,
    query_project_downloads,
    query_monthly_file_egress,
    query_downloaded_file_meta,
    query_project_sizes,
    query_unique_users,
    query_file_metadata_for_growth,
    query_total_data_size_by_initiative,
    query_top_data_types_by_size,
    query_released_data_by_type,
)
from toolkit.utils import get_data_from_snowflake
from toolkit.widgets import (
    plot_stacked_bar_chart,
    graphviz_status,
    plot_download_sizes,
    plot_monthly_egress,
    plot_download_scatter,
    plot_unique_users_monthly,
    plot_resource_downloads,
    plot_download_sizes_lollipop,
    network_legend,
    plot_network,
    plot_project_pageviews,
    plot_cumulative_data_growth,
    plot_data_type_bar_chart,
    create_data_type_table,
    format_size_metric,
    # TRANSFORMS
    merge_size_and_downloads,
    # PALETTE
    PORTAL_BLUE,
    PORTAL_DARK,
    PINK,
    PURPLE,
    BEIGE,
    TEAL,
    ORANGE,
    LIGHT_BLUE,
    MAGENTA,
    PALE_BLUE,
    OFF_WHITE,
    LAVENDER,
    GREEN,
    NAVY,
    GRAY,
)


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


# Title
st.title("NF Usage Metrics")
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
session = get_session(args.local_dev)
try:
    session.query_tag = "__generated_streamlit"
except Exception:
    pass


# Configure the layout of the Streamlit app page
st.set_page_config(
    layout="wide",
    page_title="NF Analytics",
    page_icon=":bar_chart:",
    initial_sidebar_state="expanded",
)

# Custom CSS for styling
with open("style.css") as f:
    st.markdown(f"<style>{f.read()}</style>", unsafe_allow_html=True)


# Storage only -- approximate intelligent tiering, see aws.amazon.com/s3/pricing/
def calculate_annual_cost(total_data_size_gb):
    monthly_cost_per_gb = 0.021
    months_in_year = 12
    return total_data_size_gb * monthly_cost_per_gb * months_in_year


def main():

    # SIDE BAR --------------------------------------------------------------------------------#

    # Update Mode Selection (Dynamic vs Manual)
    st.sidebar.header("Update Mode")
    update_mode = st.sidebar.radio(
        "Select Update Mode",
        options=["Dynamic Updates", "Manual Updates (Press Go)"],
        key="update_mode",
    )

    # Funder Selection
    st.sidebar.header("Funder")
    funders = st.sidebar.multiselect(
        "Select Funders",
        options=["NTAP", "CTF", "GFF", "Other"],
        default=["NTAP", "CTF", "GFF"],
        key="funders",
    )

    # Initiative Filter
    st.sidebar.header("Initiative Filter")

    # Fetch all initiatives for the dropdown
    try:
        all_initiatives_df = get_data_from_snowflake(query_all_initiatives())
        if not all_initiatives_df.empty:
            # Extract values and clean them (remove quotes)
            initiative_values = [
                str(val).strip('"')
                for val in all_initiatives_df["INITIATIVE_VALUE"].tolist()
            ]
            initiative_values = sorted(initiative_values)
        else:
            initiative_values = []
    except Exception as e:
        st.sidebar.warning(f"Could not load initiatives: {e}")
        initiative_values = []

    # Multi-select for initiatives with help text
    selected_initiatives = st.sidebar.multiselect(
        "Select Initiatives",
        options=initiative_values,
        default=[],
        key="initiatives",
        help="Filter projects by initiative. Leave empty to include all initiatives.",
    )

    # Open Proposal Filter
    st.sidebar.header("Open Proposal Scope")
    open_proposal_only = st.sidebar.checkbox(
        "Open Proposal Projects Only",
        value=False,
        key="open_proposal",
        help="When checked, only shows projects from the 'Open Proposal Program' initiative.",
    )

    # If Open Proposal is checked, override selected_initiatives
    if open_proposal_only:
        selected_initiatives = ["Open Proposal Program"]

    # Fetch Project Metadata for Selected Funders
    if funders:
        project_meta_dfs = []
        for funder in funders:
            if funder == "Other":
                # Get projects from all other funders (not NTAP, CTF, or GFF)
                df = get_data_from_snowflake(query_project_meta_other_funders())
            else:
                # Get projects from the specific funder, optionally filtered by initiative
                if selected_initiatives:
                    df = get_data_from_snowflake(
                        query_project_meta_with_initiative(funder, selected_initiatives)
                    )
                else:
                    df = get_data_from_snowflake(query_project_meta(funder))
            project_meta_dfs.append(df)

        project_meta = pd.concat(project_meta_dfs, ignore_index=True)
        # Remove duplicates in case of overlapping selections
        project_meta = project_meta.drop_duplicates(subset=["PROJECT_ID"], keep="first")

        if project_meta.empty:
            st.warning("No project metadata available for the selected funders.")
            return

        project_names = project_meta["PROJECT_NAME"].unique().tolist()

        # Initialize `project_sizes` to avoid `UnboundLocalError`
        project_sizes = (
            pd.DataFrame()
        )  # Empty DataFrame to avoid referencing before assignment
        project_ids = []  # Initialize project_ids to avoid UnboundLocalError

        # Project Selection Filter (dependent on Funder selection)
        st.sidebar.header("Projects")
        select_all_projects = st.sidebar.checkbox(
            "Select All Projects", value=True, key="select_all_projects"
        )

        # If "Select All Projects" is unchecked, show a list of projects to choose from
        if not select_all_projects:
            selected_projects = st.sidebar.multiselect(
                "Select Projects", options=project_names, key="projects"
            )
        else:
            selected_projects = project_names

        # Date Range Filters
        st.sidebar.header("Date Range")
        end_date = datetime.now().date()
        start_date = end_date - timedelta(
            days=365
        )  # Default start date is one year ago

        # Date range buttons for quick selection
        col1, col2 = st.sidebar.columns(2)
        with col1:
            st.button(
                "Year to Date",
                on_click=lambda: st.session_state.update(
                    {
                        "start_date": datetime(end_date.year, 1, 1).date(),
                        "end_date": end_date,
                    }
                ),
            )
        with col2:
            st.button(
                "Last 30 Days",
                on_click=lambda: st.session_state.update(
                    {"start_date": end_date - timedelta(days=30), "end_date": end_date}
                ),
            )

        start_date = st.sidebar.date_input(
            "Start Date", value=start_date, key="start_date"
        )
        end_date = st.sidebar.date_input("End Date", value=end_date, key="end_date")

        # Data Status Filters
        data_status_filters = []
        if select_all_projects:
            # Data Status Filters
            st.sidebar.header("Data Status")
            available = st.sidebar.checkbox("Available", value=True, key="available")
            partially_available = st.sidebar.checkbox(
                "Partially Available", value=True, key="partially_available"
            )
            rolling_release = st.sidebar.checkbox(
                "Rolling Release", value=True, key="rolling_release"
            )
            under_embargo = st.sidebar.checkbox("Under Embargo", key="under_embargo")
            data_pending = st.sidebar.checkbox("Data Pending", key="data_pending")
            data_not_expected = st.sidebar.checkbox(
                "Data Not Expected", key="data_not_expected"
            )
            none = st.sidebar.checkbox("None", key="none")

            # Append selected data statuses to filter list
            if available:
                data_status_filters.append("Available")
            if partially_available:
                data_status_filters.append("Partially Available")
            if rolling_release:
                data_status_filters.append("Rolling Release")
            if under_embargo:
                data_status_filters.append("Under Embargo")
            if data_pending:
                data_status_filters.append("Data Pending")
            if data_not_expected:
                data_status_filters.append("Data Not Expected")
            if none:
                data_status_filters.append("None")

            # Convenience buttons for selecting "Released" categories or "All"
            def select_released():
                st.session_state.available = True
                st.session_state.partially_available = True
                st.session_state.rolling_release = True
                st.session_state.under_embargo = False
                st.session_state.data_pending = False
                st.session_state.data_not_expected = False
                st.session_state.none = False

            def select_all():
                st.session_state.available = True
                st.session_state.partially_available = True
                st.session_state.rolling_release = True
                st.session_state.under_embargo = True
                st.session_state.data_pending = True
                st.session_state.data_not_expected = True
                st.session_state.none = True

            def clear_selection():
                st.session_state.available = False
                st.session_state.partially_available = False
                st.session_state.rolling_release = False
                st.session_state.under_embargo = False
                st.session_state.data_pending = False
                st.session_state.data_not_expected = False
                st.session_state.none = False

            # Convenience button for selecting "Released" categories
            col1, col2, col3 = st.sidebar.columns([1.5, 1, 1])

            with col1:
                st.button("Projects Released", on_click=select_released, type="primary")
            with col2:
                st.button("✅ Select All", on_click=select_all)
            with col3:
                st.button("❌ Clear", on_click=clear_selection)

        else:
            # If individual projects are selected, do not apply data status filters
            data_status_filters = project_meta["DATA_STATUS"].unique().tolist()

        # Show the "Go" button if the user selected Manual Updates
        if update_mode == "Manual Updates (Press Go)":
            filter_applied = st.sidebar.button("🚀**Go**!", key="apply_filters")
        else:
            filter_applied = True  # Automatically apply filters if in Dynamic mode

        if filter_applied:
            # Temporary solution -- these should be set up via queries
            st.sidebar.header("Deltas")
            comp_user_count = st.sidebar.number_input(
                "Comp User Count", value=0, step=1
            )
            comp_assay_count = st.sidebar.number_input(
                "Comp Assay Count", value=0, step=1
            )

            # Plot Width Slider
            plot_width = st.sidebar.slider(
                "Plot Width", min_value=800, max_value=1800, value=1400
            )

            # Utils
            convert_to_gib = 1024 * 1024 * 1024

            def convert_to_gb(bytes):
                return bytes / (1024 * 1024 * 1024)

            def convert_to_tb(bytes):
                return bytes / (1024 * 1024 * 1024 * 1024)

            # Reference -------------------------------------------------------------------------#

            # Filter projects based on selected funder and projects
            filtered_project_meta = project_meta[
                project_meta["PROJECT_NAME"].isin(selected_projects)
            ]
            if filtered_project_meta.empty:
                st.warning("No projects match the selected filters.")
                return

            if "DATA_STATUS" not in filtered_project_meta.columns:
                st.error("The column 'DATA_STATUS' is missing in the project metadata.")
                return

            project_ids = filtered_project_meta[
                filtered_project_meta["DATA_STATUS"].isin(data_status_filters)
            ]["PROJECT_ID"].tolist()

            if not project_ids:
                st.warning("No projects match the selected data status filters.")
                return

            st.header("Reference Overview")

            with st.expander("Glossary"):
                st.markdown("""
                    #### Project Status

                    - **Active**: The project is in the performance period (between grant start and grant end dates).
                    - **Completed**: The project has reached the grant end date and gone through a closeout process as requested by NTAP.
                    - **Withdrawn**: The project was planned/started but not completed (withdrawn).

                    #### Data Status

                    - **None**: There is no available data for the project.
                    - **Data Not Expected**: There is no available data for the project because data is not expected to be stored for this project.
                    - **Data Pending**: Data is pending for the project, either still being generated or has not yet been uploaded to Synapse yet, so there are no files in the project.
                    - **Under Embargo**: Data is present in the project but not accessible to anyone outside the project admins. When data is first uploaded, the status will change from "Data Pending" to "Under Embargo".
                    - **Rolling Release**: Some data is available for download for the project via rolling release.
                    - **Partially Available**: Some data is available for download for the project.
                    - **Available**: Data is fully available for download for the project.
                    """)

            # Project Reference Table ----------------------------------------------------------#
            with st.expander("Projects included in reporting"):
                reference_df = filtered_project_meta.reset_index(drop=True)
                st.table(reference_df)

            # What does overall project portfolio look like when grouped solely by data status ontology
            st.subheader("Data Status Distribution")
            data_status_flow = graphviz_status(
                filtered_project_meta["DATA_STATUS"].tolist()
            )
            with st.container():
                col1, col2 = st.columns([1, 1])
                with col1:
                    st.graphviz_chart(data_status_flow, use_container_width=True)
                st.markdown(
                    '<div style="padding-bottom: 40px;"></div>', unsafe_allow_html=True
                )

            # How many active vs completed projects, and how many projects are in each data status
            st.subheader(
                "Data Status Distribution, Comparing Active vs. Completed Projects"
            )
            col1, col2, col3 = st.columns([1, 1, 4])
            with col1:
                st.metric(
                    label="Active Projects",
                    value=len(
                        filtered_project_meta[
                            filtered_project_meta["STUDY_STATUS"] == "Active"
                        ]
                    ),
                )
            with col2:
                st.metric(
                    label="Completed Projects",
                    value=len(
                        filtered_project_meta[
                            filtered_project_meta["STUDY_STATUS"] == "Completed"
                        ]
                    ),
                )
            st.plotly_chart(plot_stacked_bar_chart(filtered_project_meta))

            # Data Release Report ---------------------------------------------------------------#
            st.header("Data Release")

            # DF with grouped data
            grouped_df = (
                filtered_project_meta.groupby(["STUDY_STATUS", "DATA_STATUS"])
                .size()
                .reset_index(name="COUNT")
            )

            project_sizes = get_data_from_snowflake(query_project_sizes(project_ids))
            if project_sizes.empty:
                st.warning("No data sizes available for the selected projects.")
                return

            total_data_size_gib = project_sizes["TOTAL_CONTENT_SIZE"].sum()
            total_data_size_tb = convert_to_tb(
                project_sizes["TOTAL_CONTENT_SIZE"].sum()
            )
            average_project_size = round(
                convert_to_gb(np.mean(project_sizes["TOTAL_CONTENT_SIZE"])), 2
            )
            annual_cost = calculate_annual_cost(total_data_size_gib)

            # Metrics
            col1, col2, col3 = st.columns([1, 1, 1])
            col1.metric(
                f"{', '.join(funders)} Projects With Target Data Status",
                f"{len(project_ids)}",
            )
            col2.metric("Total Data in These Projects", f"{total_data_size_tb:,.2f} TB")
            col3.metric("Avg. Project Size", f"{average_project_size} GB")

            # Data Usage Report ---------------------------------------------------------------#
            st.header("Data Usage")
            st.subheader("General Overview")
            if project_ids:
                project_downloads_df = get_data_from_snowflake(
                    query_project_downloads(project_ids, start_date, end_date)
                )
                if project_downloads_df.empty:
                    st.warning("No download data available for the selected projects.")
                else:
                    total_downloads_gb = convert_to_gb(
                        project_downloads_df["TOTAL_DOWNLOADS"].sum()
                    )
                    total_unique_files = project_downloads_df[
                        "TOTAL_UNIQUE_FILEHANDLEIDS"
                    ].sum()

                    # Metrics
                    col1, col2, col3 = st.columns([1, 1, 1])
                    col1.metric("Number of Unique Files Requested", total_unique_files)
                    col2.metric("Total Egressed Data", f"{total_downloads_gb:,.2f} GB")
                    col3.metric(
                        "Avg Downloads for Downloaded File",
                        f"{(total_downloads_gb / total_unique_files) if total_unique_files else 0:,.2f} GB",
                    )

                    # What does egress look like over selected timeframe?
                    monthly_file_egress_df = get_data_from_snowflake(
                        query_monthly_file_egress(project_ids, start_date, end_date)
                    )
                    if not monthly_file_egress_df.empty:
                        monthly_file_egress_df = monthly_file_egress_df.merge(
                            filtered_project_meta[["PROJECT_ID", "PROJECT_NAME"]],
                            on="PROJECT_ID",
                            how="left",
                        )
                        st.plotly_chart(plot_monthly_egress(monthly_file_egress_df))

                    st.subheader("Dissemination By Project")

                    # Add project names
                    project_sizes = project_sizes.merge(
                        filtered_project_meta[["PROJECT_ID", "PROJECT_NAME"]],
                        on="PROJECT_ID",
                        how="left",
                    )

                    merged_df = merge_size_and_downloads(
                        project_sizes, project_downloads_df
                    )
                    merged_df = merged_df.dropna(
                        subset=["TOTAL_CONTENT_SIZE", "TOTAL_DOWNLOADS"]
                    )

                    # Two way display mean for downloads
                    mean_downloads = convert_to_gb(merged_df["TOTAL_DOWNLOADS"].mean())
                    nonzero_downloads = merged_df[merged_df["TOTAL_DOWNLOADS"] > 0]
                    mean_filtered_download = convert_to_gb(
                        nonzero_downloads["TOTAL_DOWNLOADS"].mean()
                    )

                    col1, col2, col3 = st.columns([1, 1, 1])
                    col1.metric(
                        "Number of projects that see downloads",
                        f"{len(project_downloads_df)} out of {len(project_ids)}",
                    )
                    col2.metric(
                        "Mean download size for downloaded projects",
                        f"{mean_filtered_download:,.2f} GB",
                    )

                    st.plotly_chart(plot_download_scatter(merged_df))

                    st.subheader("Characteristics of Disseminated Data")

                    data_meta_df = get_data_from_snowflake(
                        query_downloaded_file_meta(project_ids, start_date, end_date)
                    )
                    if data_meta_df.empty:
                        st.warning("No data available for the selected criteria.")
                    else:
                        # Metrics
                        col1, col2, col3 = st.columns([1, 1, 1])
                        unique_assays = len(data_meta_df["ASSAY"].unique())
                        delta_assays = (
                            unique_assays - comp_assay_count
                            if comp_assay_count is not None
                            else None
                        )
                        col1.metric(
                            "Number of Unique Assays", unique_assays, delta=delta_assays
                        )
                        col2.metric("", "")
                        col3.metric("Avg. ", 3)

                        # What are assays being downloaded?
                        st.plotly_chart(
                            plot_resource_downloads(
                                data_meta_df,
                                resource_column="ASSAY",
                                color=ORANGE,
                                title="Assays Being Downloaded",
                            )
                        )

                        # What are resources being downloaded?
                        st.plotly_chart(
                            plot_resource_downloads(
                                data_meta_df,
                                resource_column="RESOURCE_TYPE",
                                color=PURPLE,
                                title="Resources Being Downloaded",
                            )
                        )

            # User Network -----------------------------------------------------------------------#
            st.header("Users Network")
            if project_ids:
                unique_users_df = get_data_from_snowflake(
                    query_unique_users(project_ids, start_date, end_date)
                )
                if unique_users_df.empty:
                    st.warning(
                        "No unique user data available for the selected projects."
                    )
                else:
                    unique_users_count = unique_users_df["USER_ID"].nunique()
                    avg_users_per_project = (
                        unique_users_count / len(project_downloads_df)
                        if len(project_downloads_df) > 0
                        else 0
                    )

                    # Metrics
                    col1, col2, col3 = st.columns([1, 1, 1])
                    delta_users = (
                        unique_users_count - comp_user_count
                        if comp_user_count is not None
                        else None
                    )
                    col1.metric(
                        "Total Unique Users", unique_users_count, delta=delta_users
                    )
                    col2.metric(
                        "Average Downloaders Per Project",
                        f"{avg_users_per_project:.1f}",
                    )
                    col3.metric(
                        "Avg. Download Size Per User",
                        f"{(total_downloads_gb / unique_users_count) if unique_users_count else 0:,.2f} GB",
                    )

                    # Plot of user network
                    col1, col2, col3 = st.columns([4, 1, 1])
                    with col1:
                        plot_network(unique_users_df)
                    with col2:
                        network_legend()

                    # How many unique users are downloading data for each project monthly?
                    st.plotly_chart(plot_unique_users_monthly(unique_users_df))

                # Cumulative Data Growth ---------------------------------------------------------------#
                st.header("Cumulative Data Growth")
                st.subheader("Data Portal Growth Over Time")
                cumulative_growth_df = get_data_from_snowflake(
                    query_file_metadata_for_growth(project_ids)
                )
                if cumulative_growth_df.empty:
                    st.warning(
                        "No cumulative data growth data available for the selected projects."
                    )
                else:
                    st.plotly_chart(
                        plot_cumulative_data_growth(
                            cumulative_growth_df, width=plot_width
                        )
                    )

                # Google Analytics ---------------------------------------------------------------#
                # Google analytics measurements go here for now
                # 1. Web views --
                # a) Mostly corresponds with top projects by numbers of unique downloaders, but interesting when it doesn't
                # b) Can suggest projects that still have influence/value for non-downloader users such as patients / patient advocates
                # c) Potentially a leading indicator of interest and collaboration for *un-released* projects
                # st.header("Google Analytics")
                # st.subheader("Total Page Views for synapse.org project pages")
                # pageviews_df = get_total_page_views(project_ids, start_date, end_date)
                # pageviews_df = pageviews_df.merge(filtered_project_meta[['PROJECT_ID', 'PROJECT_NAME']], on='PROJECT_ID', how='left')
                # st.table(pageviews_df)
                # st.plotly_chart(plot_project_pageviews(pageviews_df))

                # Initiative Data Metrics ---------------------------------------------------------------#
                st.header("Initiative Data Metrics")

                # Show info box about scope
                scope_description = (
                    "Open Proposal Program only"
                    if open_proposal_only
                    else (
                        f"{len(selected_initiatives)} initiative(s)"
                        if selected_initiatives
                        else "All initiatives"
                    )
                )
                st.info(
                    f"📊 **Current Scope:** {scope_description} | **Projects:** {len(project_ids)}"
                )

                # Total Data Size
                st.subheader("Total Data Size")
                with st.expander("ℹ️ Metric Definition"):
                    st.markdown("""
                    **Total Data Size** aggregates the content size of all files across the scoped projects.
                    - **Size aggregation**: Sum of all file content_size values
                    - **Units**: Displayed in TB (terabytes) with 1 decimal place
                    - **Scope**: Respects both Initiative filter and Open Proposal toggle
                    """)

                total_size_df = get_data_from_snowflake(
                    query_total_data_size_by_initiative(project_ids)
                )
                if (
                    not total_size_df.empty
                    and total_size_df["TOTAL_CONTENT_SIZE"].iloc[0] is not None
                ):
                    total_size_bytes = total_size_df["TOTAL_CONTENT_SIZE"].iloc[0]
                    total_file_count = total_size_df["TOTAL_FILE_COUNT"].iloc[0]
                    size_value, size_unit = format_size_metric(total_size_bytes)

                    col1, col2, col3 = st.columns([1, 1, 1])
                    with col1:
                        st.metric(
                            label="Total Data Size",
                            value=f"{size_value:.1f} {size_unit}",
                            help=f"Exact size: {total_size_bytes:,} bytes",
                        )
                    with col2:
                        st.metric(
                            label="Total Files",
                            value=f"{total_file_count:,}",
                            help="Number of unique files across all scoped projects",
                        )
                    with col3:
                        avg_file_size_mb = (
                            (total_size_bytes / total_file_count / (1024**2))
                            if total_file_count > 0
                            else 0
                        )
                        st.metric(
                            label="Avg File Size",
                            value=f"{avg_file_size_mb:.1f} MB",
                            help="Average size per file",
                        )
                else:
                    st.warning(
                        "No data size information available for the selected projects."
                    )

                # Top 5 Data Types by Size
                st.subheader("Top 5 Data Types by Size")
                with st.expander("ℹ️ Metric Definition"):
                    st.markdown("""
                    **Top Data Types** shows the 5 largest data types (by total size) across scoped projects.
                    - **Data type**: Derived from file 'assay' annotation
                    - **Ranking**: Sorted by total size descending; ties broken by data type name (ascending)
                    - **Limit**: Exactly 5 rows (or fewer if <5 types exist)
                    - **Scope**: Respects both Initiative filter and Open Proposal toggle
                    """)

                top_data_types_df = get_data_from_snowflake(
                    query_top_data_types_by_size(project_ids, limit=5)
                )
                if not top_data_types_df.empty:
                    st.plotly_chart(
                        plot_data_type_bar_chart(
                            top_data_types_df,
                            title="Top 5 Data Types by Size",
                            width=plot_width,
                            color=TEAL,
                        )
                    )

                    # Display table
                    st.markdown("**Detailed Breakdown:**")
                    display_table = create_data_type_table(top_data_types_df)
                    st.table(display_table)
                else:
                    st.warning(
                        "No data type information available for the selected projects."
                    )

                # Released Data Only - Data Size by Type
                st.subheader("Released Data Only - Data Size by Type")
                with st.expander("ℹ️ Metric Definition"):
                    st.markdown("""
                    **Released Data** filters to only projects with released data status before grouping by data type.
                    - **Released statuses**: 'Available', 'Partially Available', 'Rolling Release'
                    - **Data type**: Derived from file 'assay' annotation
                    - **Ranking**: Sorted by total size descending; ties broken by data type name (ascending)
                    - **Limit**: Exactly 5 rows (or fewer if <5 types exist)
                    - **Scope**: Respects both Initiative filter and Open Proposal toggle
                    """)

                released_statuses = [
                    "Available",
                    "Partially Available",
                    "Rolling Release",
                ]
                released_data_df = get_data_from_snowflake(
                    query_released_data_by_type(project_ids, released_statuses, limit=5)
                )
                if not released_data_df.empty:
                    st.plotly_chart(
                        plot_data_type_bar_chart(
                            released_data_df,
                            title="Top 5 Data Types (Released Projects Only)",
                            width=plot_width,
                            color=GREEN,
                        )
                    )

                    # Display table
                    st.markdown("**Detailed Breakdown:**")
                    display_table = create_data_type_table(released_data_df)
                    st.table(display_table)
                else:
                    st.warning(
                        "No released data available for the selected projects, or no data type information available."
                    )

    else:
        st.write("No projects match filters.")

    # col4, col5, col6 = st.columns([1, 1, 1])
    # col4.metric("Avg. Project Size", f"{average_project_size} GB")
    # col5.metric("Annual Storage Cost", f"${annual_cost:,.2f} USD", delta = "10,000 USD")
    # col6.metric("Annual Egress Cost", f"${annual_cost:,.2f} USD", delta = "10,000 USD")

    # plot of downloads over time

    # Row 5 -----------------------------------------------------------------------------#

    # Misc


if __name__ == "__main__":
    main()
