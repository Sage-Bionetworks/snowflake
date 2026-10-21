USE SCHEMA {{database_name}}.rds_raw; --noqa: JJ01,PRS,TMP

CREATE FUNCTION gzip_decompress_string(data BINARY)
RETURNS VARCHAR
LANGUAGE PYTHON
STRICT
IMMUTABLE
RUNTIME_VERSION = '3.12'
COMMENT = 'Decodes gzip-compressed UTF-8 text. Snowflake''s built-in SQL function `DECOMPRESS_STRING` does not support gzip.'
HANDLER = 'decompress'
AS
$$
import gzip


def decompress(data):
    return gzip.decompress(data).decode("utf-8")
$$;
