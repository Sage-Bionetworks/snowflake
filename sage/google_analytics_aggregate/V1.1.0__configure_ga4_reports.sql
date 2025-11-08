USE ROLE google_analytics_aggregate_admin;
USE SCHEMA google_analytics.public;

CALL CONFIGURE_REPORT(
    REPORT_NAME => 'DEMOGRAPHIC_LOCATION',
    PROPERTY_ID => '311611973',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString,continent,subcontinent,country,region,city',
    METRICS => 'totalUsers,activeUsers,newUsers,sessions,averageSessionDuration,engagedSessions,engagementRate',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'EVENTS',
    PROPERTY_ID => '311611973',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString,eventName',
    METRICS => 'eventValue,eventCount,eventCountPerUser,eventsPerSession',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'VIEWS',
    PROPERTY_ID => '311611973',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString',
    METRICS => 'screenPageViews,screenPageViewsPerSession,screenPageViewsPerUser',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'NEW_VS_RETURNING_VIEWS',
    PROPERTY_ID => '311611973',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString,newVsReturning',
    METRICS => 'screenPageViews,screenPageViewsPerSession,screenPageViewsPerUser',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'SESSION_SOURCE_VIEWS',
    PROPERTY_ID => '311611973',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString,sessionSourceMedium',
    METRICS => 'screenPageViews,screenPageViewsPerSession,screenPageViewsPerUser',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);