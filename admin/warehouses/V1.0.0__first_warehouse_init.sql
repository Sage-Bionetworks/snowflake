use role sysadmin;
create warehouse if not exists compute_org
warehouse_type = STANDARD
warehouse_size = XSMALL
auto_suspend = 90
auto_resume = TRUE
initially_suspended = TRUE;

create warehouse if not exists compute_medium
warehouse_type = STANDARD
warehouse_size = MEDIUM
auto_suspend = 70
auto_resume = TRUE
initially_suspended = TRUE;

create warehouse if not exists recover_xsmall
warehouse_type = STANDARD
warehouse_size = XSMALL
auto_suspend = 90
auto_resume = TRUE
initially_suspended = TRUE;

// Tableau warehouse should have longer suspect time to leverage caching
create warehouse if not exists tableau
warehouse_type = STANDARD
warehouse_size = XSMALL
auto_suspend = 300
auto_resume = TRUE
initially_suspended = TRUE;
