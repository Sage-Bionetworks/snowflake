
use role useradmin;

CREATE USER avlinden
    PASSWORD = '',
    LOGIN_NAME = 'avlinden',
    EMAIL = 'abby.vanderlinden@sagebase.org',
    MUST_CHANGE_PASSWORD = TRUE,
    DEFAULT_WAREHOUSE = 'COMPUTE_ORG',
    DEFAULT_ROLE = 'PUBLIC',
    DEFAULT_NAMESPACE = 'SYNAPSE_DATA_WAREHOUSE.TEST_RAW';

CREATE USER avu
    PASSWORD = '',
    LOGIN_NAME = 'avu',
    EMAIL = 'anh.nguyet.vu@sagebase.org',
    MUST_CHANGE_PASSWORD = TRUE,
    DEFAULT_WAREHOUSE = 'COMPUTE_ORG',
    DEFAULT_ROLE = 'PUBLIC',
    DEFAULT_NAMESPACE = 'SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW';

CREATE USER lfoschini
    PASSWORD = '',
    LOGIN_NAME = 'lfoschini',
    EMAIL = 'luca.foschini@sagebase.org',
    MUST_CHANGE_PASSWORD = TRUE,
    DEFAULT_WAREHOUSE = 'COMPUTE_ORG',
    DEFAULT_ROLE = 'PUBLIC',
    DEFAULT_NAMESPACE = 'SYNAPSE_DATA_WAREHOUSE.SYNAPSE_RAW';

CREATE USER psnyder
    PASSWORD = '',
    LOGIN_NAME = 'psnyder',
    EMAIL = 'phil.snyder@sagebase.org',
    MUST_CHANGE_PASSWORD = TRUE,
    DEFAULT_WAREHOUSE = 'COMPUTE_ORG',
    DEFAULT_ROLE = 'recover_admin',
    DEFAULT_NAMESPACE = 'RECOVER.PILOT';

CREATE USER rxu
    PASSWORD = '',
    LOGIN_NAME = 'rxu',
    EMAIL = 'rixing.xu@sagebase.org',
    MUST_CHANGE_PASSWORD = TRUE,
    DEFAULT_WAREHOUSE = 'COMPUTE_ORG',
    DEFAULT_ROLE = 'recover_admin',
    DEFAULT_NAMESPACE = 'RECOVER.PILOT';

CREATE USER xguo
    PASSWORD = '',
    LOGIN_NAME = 'xguo',
    EMAIL = 'xindi.guo@sagebase.org',
    MUST_CHANGE_PASSWORD = TRUE,
    DEFAULT_WAREHOUSE = 'COMPUTE_ORG',
    DEFAULT_ROLE = 'genie_admin',
    DEFAULT_NAMESPACE = 'genie.public_13_1';

CREATE USER cnayan
    PASSWORD = '',
    LOGIN_NAME = 'cnayan',
    EMAIL = 'chelsea.nayan@sagebase.org',
    MUST_CHANGE_PASSWORD = TRUE,
    DEFAULT_WAREHOUSE = 'COMPUTE_ORG',
    DEFAULT_ROLE = 'genie_admin',
    DEFAULT_NAMESPACE = 'genie.public_13_1';
USE ROLE USERADMIN;
CREATE USER apaynter
    PASSWORD = '',
    LOGIN_NAME = 'apaynter',
    EMAIL = 'alex.paynter@sagebase.org',
    MUST_CHANGE_PASSWORD = TRUE,
    DEFAULT_WAREHOUSE = 'COMPUTE_ORG',
    DEFAULT_ROLE = 'genie_admin',
    DEFAULT_NAMESPACE = 'genie.public_13_1';

use role securityadmin;
GRANT ROLE genie_admin

TO USER apaynter;

// ROLE MANAGEMENT
CREATE ROLE recover_admin;
USE ROLE securityadmin;
GRANT CREATE SCHEMA, USAGE on DATABASE RECOVER to ROLE recover_admin;
GRANT CREATE TABLE, USAGE on SCHEMA recover.pilot to ROLE recover_admin;

use role securityadmin;
GRANT ROLE recover_admin TO USER psnyder;
GRANT ROLE recover_admin TO USER rxu;


USE ROLE securityadmin;
GRANT USAGE ON WAREHOUSE recover_xsmall TO ROLE recover_admin;
GRANT ROLE recover_admin TO USER thomasyu888;
