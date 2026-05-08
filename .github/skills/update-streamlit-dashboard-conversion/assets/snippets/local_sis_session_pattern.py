import argparse
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session


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


args = read_args()
session = get_session(args.local_dev)
