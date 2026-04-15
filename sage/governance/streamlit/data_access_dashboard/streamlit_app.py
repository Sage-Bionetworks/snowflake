import argparse

import streamlit
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session

streamlit.set_page_config(layout="wide")


def read_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--local-dev", action="store_true")
    return parser.parse_args()


def get_session(local_dev):
    if local_dev:
        return Session.builder.config("connection_name", "default").create()

    return get_active_session()


def load_submission_dashboard_data(snowflake_session):
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


def get_dashboard_column_name(column_names, requested_name):
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


def get_unique_column_values(dashboard_data, requested_column_name):
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
    dashboard_data,
    access_requirement_id_exact,
    submitted_by_user_name_exact,
    submission_status_exact,
):
    filtered_data = dashboard_data

    access_requirement_id_column = get_dashboard_column_name(
        filtered_data.columns,
        "access_requirement_id",
    )
    submitted_by_user_name_column = get_dashboard_column_name(
        filtered_data.columns,
        "submitted_by_user_name",
    )
    submission_status_column = get_dashboard_column_name(
        filtered_data.columns,
        "submission_status",
    )

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


def render_submission_dashboard_filters(submission_dashboard_data):
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


def render_access_requests_section(snowflake_session):
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


def main():
    args = read_args()
    session = get_session(args.local_dev)

    streamlit.title("Data Access Dashboard")
    streamlit.caption("Access request and data access submission tracker")

    render_access_requests_section(session)


main()
