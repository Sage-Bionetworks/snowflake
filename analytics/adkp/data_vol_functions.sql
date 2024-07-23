create or replace function bytes_to_tb(bytes number)
returns float
as
$$
    (bytes) / power(2, 40)
$$;

create or replace function bytes_to_pb(bytes number)
returns float
as
$$
    (bytes) / power(2, 50)
$$;
