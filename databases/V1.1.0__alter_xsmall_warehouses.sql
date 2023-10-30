use role sysadmin;
alter warehouse if exists compute_org rename to compute_xsmall;
alter warehouse if exists compute_xsmall set
auto_suspend = 70;

alter warehouse if exists tableau rename to tableau_xsmall;
