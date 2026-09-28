USE ROLE google_analytics_aggregate_admin;
USE SCHEMA google_analytics.public;

-- Agora (property 311630618)
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'AGORA_PAGE',
    PROPERTY_ID => '311630618',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString,landingPage',
    METRICS => 'screenPageViews,activeUsers,userEngagementDuration,bounceRate',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'AGORA_AUDIENCE',
    PROPERTY_ID => '311630618',
    DIMENSIONS => 'date,hostName,newVsReturning,country,deviceCategory,operatingSystem,browser',
    METRICS => 'activeUsers,newUsers,sessions,screenPageViews,userEngagementDuration',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'AGORA_SESSION',
    PROPERTY_ID => '311630618',
    DIMENSIONS => 'date,hostName,sessionSource,sessionMedium,landingPage',
    METRICS => 'sessions,engagedSessions,engagementRate,bounceRate,averageSessionDuration',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'AGORA_EVENT',
    PROPERTY_ID => '311630618',
    DIMENSIONS => 'date,hostName,eventName,pagePath',
    METRICS => 'eventCount,keyEvents,eventValue',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);

-- Model AD Explorer (property 487000216)
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'MODELAD_PAGE',
    PROPERTY_ID => '487000216',
    DIMENSIONS => 'date,hostName,pagePath,pagePathPlusQueryString,landingPage',
    METRICS => 'screenPageViews,activeUsers,userEngagementDuration,bounceRate',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'MODELAD_AUDIENCE',
    PROPERTY_ID => '487000216',
    DIMENSIONS => 'date,hostName,newVsReturning,country,deviceCategory,operatingSystem,browser',
    METRICS => 'activeUsers,newUsers,sessions,screenPageViews,userEngagementDuration',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'MODELAD_SESSION',
    PROPERTY_ID => '487000216',
    DIMENSIONS => 'date,hostName,sessionSource,sessionMedium,landingPage',
    METRICS => 'sessions,engagedSessions,engagementRate,bounceRate,averageSessionDuration',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
CALL CONFIGURE_REPORT(
    REPORT_NAME => 'MODELAD_EVENT',
    PROPERTY_ID => '487000216',
    DIMENSIONS => 'date,hostName,eventName,pagePath',
    METRICS => 'eventCount,keyEvents,eventValue',
    START_DATE => '2020-01-01',
    REFRESH_INTERVAL => 'EVERY 1 DAY',
    KEEP_EMPTY_ROWS => TRUE,
    AVOID_SAMPLING => FALSE
);
