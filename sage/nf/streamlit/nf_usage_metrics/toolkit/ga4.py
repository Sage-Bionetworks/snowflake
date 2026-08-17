# Google Analytics 4 (GA4)
# IMPORTANT: User-Level and Event-Level Data Retention is only up to 14 months
# Some aggregated data remains available beyond these periods, but detailed user and event data might not
# https://github.com/googleapis/google-cloud-python

import os
import pandas as pd
import logging
from google.analytics.data_v1beta import BetaAnalyticsDataClient
from google.analytics.data_v1beta.types import (
    DateRange,
    Dimension,
    Filter,
    FilterExpression,
    Metric,
    RunReportRequest
)
import streamlit as st
from datetime import datetime, timedelta, date

# Credentials
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'google_creds.json'

synapse_property_id = "311611973"

@st.cache_data()
def query_ga_project_stats(projects, start_date, end_date, ga_property_id=synapse_property_id):
    """
    Query views and users for all pages within a given project and date range with GA4.
    A project will have variable number of pages depending on Wiki content and number of tables, files, etc.
    Since all pages must be prefixed with the project id, 
    e.g. '/Synapse:syn4939902/datasets/' and '/Synapse:syn4939902/discussion/threadId=7606', 
    we use a string filter on the page path.
    
    Args:
        projects: List of project syn ids
        date_range: Tuple of (start_date, end_date) in YYYY-MM-DD format
        ga_property_id: Google Analytics property ID (default: synapse_property_id)
    
    Returns:
        Dictionary with project IDs as keys and their stats as values

    Example:
        jhu_2024 = query_ga_project_stats(['syn4939902'], "2024-01-01", "2024-12-01")
    """
    try:
        client = BetaAnalyticsDataClient()
    except Exception:
        return None
    pstats = {}
    property_path = f"properties/{ga_property_id}"
    
    for project in projects:
        try:
            project_filter = FilterExpression(
                filter=Filter(
                    field_name="pagePath",
                    string_filter=Filter.StringFilter(
                        match_type=Filter.StringFilter.MatchType.CONTAINS,
                        value=project,
                        case_sensitive=False
                    )
                )
            )

            request = RunReportRequest(
                property=property_path,
                dimensions=[Dimension(name="pagePath")],
                metrics=[
                    Metric(name="screenPageViews"),
                    Metric(name="totalUsers")
                ],
                date_ranges=[DateRange(
                    start_date=start_date,
                    end_date=end_date
                )],
                dimension_filter=project_filter
            )

            response = client.run_report(request)

            if not response.rows:
                # logging.info(f"No views found for project {project}")
                pstats[project] = []
                continue

            # Convert response to a more usable format
            results = []
            for row in response.rows:
                results.append({
                    'pagePath': row.dimension_values[0].value,
                    'screenPageViews': int(row.metric_values[0].value),
                    'totalUsers': int(row.metric_values[1].value)
                })

            pstats[project] = results

        except Exception as e:
            # logging.error(f"Error querying project {project}: {e}")
            pstats[project] = None 

    return pstats

def sum_screen_page_views_by_project(data):
    """
    Sums up the total screenPageViews for each project.

    Args:
        data (dict): Output of `query_ga_project_stats`; a dict where keys are project IDs and values are lists of page metrics dictionaries.
                     Each dictionary contains 'pagePath', 'screenPageViews', and 'totalUsers' keys.  
                     Example:
                     {
                         'syn4939902': [
                             {'pagePath': '/Synapse:syn4939902/files/', 'screenPageViews': 411, 'totalUsers': 38},
                             {'pagePath': '/Synapse:syn4939902/datasets/', 'screenPageViews': 357, 'totalUsers': 41},
                             # ... more pages ...
                         ],
                         'syn1234567': [
                             {'pagePath': '/Synapse:syn1234567/files/', 'screenPageViews': 500, 'totalUsers': 50},
                             # ... more pages ...
                         ],
                         # ... more projects ...
                     }

    Returns:
        dict: A dictionary mapping each project ID to its total screenPageViews.
              Example:
              {
                  'syn4939902': 1650,
                  'syn1234567': 500,
                  # ... more projects ...
              }
    """
    project_sums = {}
    
    for project_id, pages in data.items():
        # Initialize total_views for the current project
        total_views = 0
        
        # Skip if pages is None or empty
        if not pages:
            project_sums[project_id] = 0
            continue
            
        # Iterate through each page's metrics
        for page in pages:
            # Extract screenPageViews, defaulting to 0 if not present
            screen_views = page.get('screenPageViews', 0)
            
            # Ensure screen_views is an integer (handles potential data type issues)
            try:
                screen_views = int(screen_views)
            except (ValueError, TypeError):
                screen_views = 0
            
            # Add to the project's total
            total_views += screen_views
        
        # Assign the computed total to the project in the result dictionary
        project_sums[project_id] = total_views
    
    return project_sums

def get_total_page_views(projects, start_date, end_date):
    """
    Wrapper function that translates between types used in dashboard, 
    does additional checking, and queries GA4 data and sums up total screenPageViews by project.

    Args:
        projects (list): List of INTEGER project identifiers (without the 'syn' prefix).
        start_date (date): Start date as date object.
        end_date (date): End date as date object.

    Returns:
        dict: A dictionary mapping each project ID to its total screenPageViews.

    Example:
        jhu_2024 = get_total_page_views([4939902], date(2024, 1, 1), date(2024, 12, 1))
    """
    # Check if start_date is beyond GA4 retention limit
    empty_df = pd.DataFrame(columns=['PROJECT_ID', 'TOTAL_PAGEVIEWS'])
    ga4_retention_limit = datetime.now().date() - timedelta(days=426)
    if start_date < ga4_retention_limit:
        return empty_df

    # Add 'syn' prefix to each project ID
    project_ids = [f'syn{str(project)}' for project in projects]
    start_date_str = start_date.strftime('%Y-%m-%d')
    end_date_str = end_date.strftime('%Y-%m-%d')
    # print(f"Querying GA4 data for projects from {start_date_str} to {end_date_str}: {project_ids}")
    detailed_data = query_ga_project_stats(project_ids, start_date_str, end_date_str)
    if detailed_data is None:
        return empty_df
    summary_data = sum_screen_page_views_by_project(detailed_data)
    df = pd.DataFrame(list(summary_data.items()), columns=['PROJECT_ID', 'TOTAL_PAGEVIEWS'])
    df['PROJECT_ID'] = df['PROJECT_ID'].str.replace('syn', '').astype(int)
    return df
