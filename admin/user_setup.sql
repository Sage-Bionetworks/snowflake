
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
