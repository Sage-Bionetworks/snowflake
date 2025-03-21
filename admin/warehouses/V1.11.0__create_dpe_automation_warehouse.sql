use role sysadmin;
create warehouse if not exists dpe_automation
warehouse_type = STANDARD
warehouse_size = XSMALL
auto_suspend = 90
auto_resume = TRUE
initially_suspended = TRUE;
