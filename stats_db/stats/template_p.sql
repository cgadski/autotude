-- Stat name
-- handle
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    'stat' AS stat,
    false AS hidden
FROM tbl
GROUP BY handle_key

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    'stat' AS stat,
    false AS hidden
FROM tbl GROUP BY handle_key, time_bin

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    'stat' AS stat,
    false AS hidden
FROM tbl GROUP BY handle_key, plane

UNION ALL

-- handle, time, plane
SELECT
    handle_key,
    time_bin,
    plane,
    'stat' AS stat,
    false AS hidden
FROM tbl
