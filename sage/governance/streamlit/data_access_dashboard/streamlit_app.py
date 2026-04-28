import argparse
from dataclasses import dataclass
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


def filter_dataframe(
    data: pd.DataFrame,
    filters: dict[str, Optional[str]],
) -> pd.DataFrame:
    """Apply exact-match filters to a DataFrame.

    Filters are case- and whitespace-insensitive. Entries with a None or empty
    string value are skipped.

    Args:
        data: The unfiltered DataFrame.
        filters: Mapping of actual column name to exact-match filter value.
            Columns not present in the DataFrame are silently skipped.

    Returns:
        A filtered copy of the input DataFrame.
    """
    result = data
    for column, value in filters.items():
        if value and column in result.columns:
            result = result[
                result[column].astype(str).str.strip().str.lower()
                == value.strip().lower()
            ]
    return result


@dataclass
class FilterSpec:
    """Specification for a single dropdown filter in a dashboard section.

    Attributes:
        column_key: Internal key passed to ``get_dashboard_column_name`` to resolve
            the actual column name in the DataFrame.
        label: Display label for the selectbox.
        placeholder: Placeholder text shown when no option is selected.
        key: Unique Streamlit widget key.
    """

    column_key: str
    label: str
    placeholder: str
    key: str


def render_dashboard_filters(
    data: pd.DataFrame,
    filter_specs: list[FilterSpec],
) -> dict[str, Optional[str]]:
    """Render a row of dropdown filters for any set of columns.

    Lays out one selectbox per spec in equal-width columns. Options are derived
    from unique non-blank values in the DataFrame. Specs whose column cannot be
    resolved are silently skipped.

    Args:
        data: The full unfiltered DataFrame, used to populate dropdown options.
        filter_specs: Ordered list of filter specifications to render.

    Returns:
        A dict mapping each resolved column name to the selected filter value,
        or None if no selection was made.
    """
    filters: dict[str, Optional[str]] = {}
    cols = streamlit.columns(len(filter_specs))

    for col, spec in zip(cols, filter_specs):
        column_name = get_dashboard_column_name(data.columns, spec.column_key)
        if not column_name:
            continue
        with col:
            filters[column_name] = streamlit.selectbox(
                spec.label,
                options=get_unique_column_values(data, spec.column_key),
                index=None,
                placeholder=spec.placeholder,
                key=spec.key,
            )

    return filters


def render_submission_dashboard_filters(
    submission_dashboard_data: pd.DataFrame,
) -> dict[str, Optional[str]]:
    """Render the dropdown filters for the submission dashboard.

    Args:
        submission_dashboard_data: The full unfiltered dashboard DataFrame.

    Returns:
        A dict mapping each resolved column name to the selected filter value.
    """
    access_requirement_id_filter = FilterSpec(
        column_key="access_requirement_id",
        label="Access Requirement",
        placeholder="Select access requirement",
        key="access_requirement_id_filter",
    )
    submitted_by_user_name_filter = FilterSpec(
        column_key="submitted_by_user_name",
        label="Submitted By",
        placeholder="Select submitter",
        key="submitted_by_user_name_filter",
    )
    submission_status_filter = FilterSpec(
        column_key="submission_status",
        label="Status",
        placeholder="Select status",
        key="submission_status_filter",
    )
    return render_dashboard_filters(
        submission_dashboard_data,
        [
            access_requirement_id_filter,
            submitted_by_user_name_filter,
            submission_status_filter,
        ],
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
        filters = render_submission_dashboard_filters(submission_dashboard_data)
        filtered_submission_dashboard_data = filter_dataframe(
            submission_dashboard_data, filters
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
    streamlit.markdown(
        '<p style="color: #cc0000; font-size: 0.85rem; margin-top: -0.4rem;">'
        "This app is "
        '<a href="https://github.com/Sage-Bionetworks/snowflake/blob/dev/STREAMLIT.md" target="_blank">managed on Github</a>. '
        "Any local edits will not be retained."
        "</p>",
        unsafe_allow_html=True,
    )

    render_access_requests_section(session)


main()
