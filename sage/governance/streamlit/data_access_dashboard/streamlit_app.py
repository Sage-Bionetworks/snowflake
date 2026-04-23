import argparse
from typing import Optional

import pandas as pd
import streamlit
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session

streamlit.set_page_config(layout="wide")


def read_args() -> argparse.Namespace:
    """Parse command-line arguments.

    Returns:
        Parsed arguments namespace. Includes `local_dev` bool flag.
    """
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
    """Return a Snowflake session appropriate for the runtime environment.

    When running locally, creates a session using the ``default`` connection
    from ``~/.snowflake/connections.toml``. When running in Snowflake (SiS),
    returns the active session provided by the runtime.

    Args:
        local_dev: If True, create a local session; otherwise use the active SiS session.

    Returns:
        An active Snowflake Snowpark Session.
    """
    if local_dev:
        return Session.builder.config("connection_name", "default").create()

    return get_active_session()


def load_submission_dashboard_data(snowflake_session: Session) -> pd.DataFrame:
    """Query the data access submission dashboard view and return results as a DataFrame.

    Fetches all rows from ``SAGE.GOVERNANCE.DATA_ACCESS_SUBMISSION_DASHBOARD``,
    ordered by submission descending. Column names are aliased to human-readable labels.

    Args:
        snowflake_session: An active Snowflake Snowpark Session.

    Returns:
        A pandas DataFrame with aliased columns for display in the dashboard.
    """
    query = """
        SELECT
            access_requirement_id as "Access Requirement",
            access_requirement_version as "Access Requirement Version",
            data_access_request_id as "Data Access Request ID",
            attempt as "Attempt",
            submitted_by_user_name as "Submitted By",
            reviewed_by_user_name as "Reviewed By",
            submission_status as "Status",
            submission_status_reason as "Status Reason"
        FROM sage.governance.data_access_submission_dashboard
        ORDER BY
            data_access_submission_id desc,
            submitted_by_user_name,
            attempt
    """
    return snowflake_session.sql(query).to_pandas()


def get_dashboard_column_name(
    column_names: list[str], requested_name: str
) -> Optional[str]:
    """Resolve an internal column key to the actual aliased column name in a DataFrame.

    SQL column aliases (e.g. ``"Submitted By"``) may differ from the original column
    names used in filter logic. This function maps a known internal key to whichever
    candidate name actually exists in the DataFrame columns.

    Args:
        column_names: The list of column names present in the DataFrame.
        requested_name: An internal key identifying the desired column
            (e.g. ``"submitted_by_user_name"``).

    Returns:
        The matching actual column name, or None if no candidate is found.
    """
    lowered_to_actual = {name.lower(): name for name in column_names}
    candidate_names_by_requested_name = {
        "access_requirement_id": ["access_requirement_id", "access requirement"],
        "submitted_by_user_name": [
            "submitted_by_user_name",
            "submitted by user name",
            "submitted by",
        ],
        "submission_status": [
            "submission_status",
            "status",
        ],
    }

    for candidate_name in candidate_names_by_requested_name.get(requested_name, []):
        actual_name = lowered_to_actual.get(candidate_name.lower())
        if actual_name:
            return actual_name

    return None


def get_unique_column_values(
    dashboard_data: pd.DataFrame, requested_column_name: str
) -> list[str]:
    """Return sorted unique non-blank string values for a column, for use in dropdowns.

    Args:
        dashboard_data: The full unfiltered dashboard DataFrame.
        requested_column_name: An internal key identifying the desired column
            (e.g. ``"submission_status"``).

    Returns:
        A sorted list of unique string values. Returns an empty list if the
        column cannot be resolved.
    """
    actual_column_name = get_dashboard_column_name(
        dashboard_data.columns,
        requested_column_name,
    )
    if not actual_column_name:
        return []

    unique_values = dashboard_data[actual_column_name].dropna().astype(str).str.strip()
    unique_values = unique_values[unique_values != ""].drop_duplicates().tolist()
    unique_values.sort()
    return unique_values


def filter_submission_dashboard_data(
    dashboard_data: pd.DataFrame,
    access_requirement_id_exact: Optional[str],
    submitted_by_user_name_exact: Optional[str],
    submission_status_exact: Optional[str],
) -> pd.DataFrame:
    """Apply exact-match filters to the submission dashboard DataFrame.

    Filters are case- and whitespace-insensitive. A None or empty filter value
    means no filtering is applied for that column.

    Args:
        dashboard_data: The full unfiltered dashboard DataFrame.
        access_requirement_id_exact: Exact access requirement ID to filter by, or None.
        submitted_by_user_name_exact: Exact submitter username to filter by, or None.
        submission_status_exact: Exact submission status to filter by, or None.

    Returns:
        A filtered copy of the input DataFrame.
    """
    access_requirement_id_column = get_dashboard_column_name(
        dashboard_data.columns,
        "access_requirement_id",
    )
    submitted_by_user_name_column = get_dashboard_column_name(
        dashboard_data.columns,
        "submitted_by_user_name",
    )
    submission_status_column = get_dashboard_column_name(
        dashboard_data.columns,
        "submission_status",
    )

    filtered_data = dashboard_data

    if access_requirement_id_exact and access_requirement_id_column:
        filtered_data = filtered_data[
            filtered_data[access_requirement_id_column]
            .astype(str)
            .str.strip()
            .str.lower()
            == access_requirement_id_exact.strip().lower()
        ]

    if submitted_by_user_name_exact and submitted_by_user_name_column:
        filtered_data = filtered_data[
            filtered_data[submitted_by_user_name_column]
            .astype(str)
            .str.strip()
            .str.lower()
            == submitted_by_user_name_exact.strip().lower()
        ]

    if submission_status_exact and submission_status_column:
        filtered_data = filtered_data[
            filtered_data[submission_status_column].astype(str).str.strip().str.lower()
            == submission_status_exact.strip().lower()
        ]

    return filtered_data


def render_submission_dashboard_filters(
    submission_dashboard_data: pd.DataFrame,
) -> tuple[Optional[str], Optional[str], Optional[str]]:
    """Render the three dropdown filters for the submission dashboard.

    Displays selectboxes for Access Requirement, Submitted By, and Status.
    Dropdown options are derived from unique values in the provided DataFrame.

    Args:
        submission_dashboard_data: The full unfiltered dashboard DataFrame,
            used to populate dropdown options.

    Returns:
        A 3-tuple of ``(access_requirement_id_filter, submitted_by_user_name_filter,
        submission_status_filter)``. Each value is the selected string, or None
        if no selection was made.
    """
    filter_col_1, filter_col_2, filter_col_3 = streamlit.columns(3)

    with filter_col_1:
        access_requirement_id_options = get_unique_column_values(
            submission_dashboard_data,
            "access_requirement_id",
        )
        access_requirement_id_filter = streamlit.selectbox(
            "Access Requirement",
            options=access_requirement_id_options,
            index=None,
            placeholder="Select access requirement",
            key="access_requirement_id_filter",
        )

    with filter_col_2:
        submitted_by_user_name_options = get_unique_column_values(
            submission_dashboard_data,
            "submitted_by_user_name",
        )
        submitted_by_user_name_filter = streamlit.selectbox(
            "Submitted By",
            options=submitted_by_user_name_options,
            index=None,
            placeholder="Select submitter",
            key="submitted_by_user_name_filter",
        )

    with filter_col_3:
        submission_status_options = get_unique_column_values(
            submission_dashboard_data,
            "submission_status",
        )
        submission_status_filter = streamlit.selectbox(
            "Status",
            options=submission_status_options,
            index=None,
            placeholder="Select status",
            key="submission_status_filter",
        )

    return (
        access_requirement_id_filter,
        submitted_by_user_name_filter,
        submission_status_filter,
    )


def render_access_requests_section(snowflake_session: Session) -> None:
    """Render the Access Requests section of the dashboard.

    Loads submission data, renders filter controls, applies selected filters,
    and displays the resulting DataFrame with a row count caption.
    Errors are caught and surfaced as a Streamlit error message.

    Args:
        snowflake_session: An active Snowflake Snowpark Session.
    """
    streamlit.header("Access Requests")

    try:
        submission_dashboard_data = load_submission_dashboard_data(snowflake_session)
        (
            access_requirement_id_filter,
            submitted_by_user_name_filter,
            submission_status_filter,
        ) = render_submission_dashboard_filters(submission_dashboard_data)

        filtered_submission_dashboard_data = filter_submission_dashboard_data(
            submission_dashboard_data,
            access_requirement_id_filter,
            submitted_by_user_name_filter,
            submission_status_filter,
        )

        streamlit.caption(
            f"Showing {len(filtered_submission_dashboard_data)} of {len(submission_dashboard_data)} rows"
        )
        streamlit.dataframe(filtered_submission_dashboard_data, width="stretch")
    except Exception as error:
        streamlit.error(f"Failed to load dashboard data: {error}")


def main() -> None:
    """Entry point for the Data Access Dashboard Streamlit app.

    Reads CLI arguments, establishes a Snowflake session, and renders
    the page title, caption, and all dashboard sections.
    """
    args = read_args()
    session = get_session(args.local_dev)

    streamlit.title("Data Access Dashboard")
    streamlit.caption("Access request and data access submission tracker")

    render_access_requests_section(session)


main()
