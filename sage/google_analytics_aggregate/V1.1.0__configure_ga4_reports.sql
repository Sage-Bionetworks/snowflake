USE ROLE google_analytics_aggregate_admin;
USE SCHEMA google_analytics.public;

CALL CONFIGURE_REPORT(
    REPORT_NAME => 'DEMOGRAPHIC_LOCATION',
    PROPERTY_ID => '311611973',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString,continent,subcontinent,country',
    METRICS => 'totalUsers,activeUsers,active7DayUsers,active28DayUsers,newUsers,sessions,averageSessionDuration,engagedSessions,engagementRate',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'EVENTS',
    PROPERTY_ID => '311611973',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString,eventName',
    METRICS => 'eventValue,eventCount,eventCountPerUser,eventsPerSession,totalUsers,activeUsers,active7DayUsers,active28DayUsers,newUsers',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'SCREEN_PAGE_VIEWS',
    PROPERTY_ID => '311611973',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString',
    METRICS => 'screenPageViews,screenPageViewsPerSession,screenPageViewsPerUser,totalUsers,activeUsers,active7DayUsers,active28DayUsers,newUsers',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'NEW_VS_RETURNING',
    PROPERTY_ID => '311611973',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString,newVsReturning',
    METRICS => 'screenPageViews,screenPageViewsPerSession,screenPageViewsPerUser,totalUsers,activeUsers,active7DayUsers,active28DayUsers,newUsers',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'SESSION_SOURCE',
    PROPERTY_ID => '311611973',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString,sessionSource,sessionMedium,sessionSourceMedium',
    METRICS => 'screenPageViews,screenPageViewsPerSession,screenPageViewsPerUser,totalUsers,activeUsers,active7DayUsers,active28DayUsers,newUsers',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);