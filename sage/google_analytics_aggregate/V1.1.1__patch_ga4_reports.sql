USE SCHEMA google_analytics.public;

CALL CONFIGURE_REPORT(
    REPORT_NAME => 'DEMOGRAPHIC_LOCATION',
    PROPERTY_ID => '311611973',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString,continent,country',
    METRICS => 'totalUsers,activeUsers,active7DayUsers,active28DayUsers,newUsers,sessions,averageSessionDuration,engagedSessions,engagementRate',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);