-- Time played
-- duration

-- handle, time, plane
SELECT
    handle_key,
    time_bin,
    plane,
    time_played AS stat,
    null AS detail
FROM tbl

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(time_played) AS stat,
    null AS detail
FROM tbl GROUP BY handle_key, time_bin

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(time_played) AS stat,
    null AS detail
FROM tbl GROUP BY handle_key, plane

UNION ALL

-- handle
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(time_played) AS stat,
    null AS detail
FROM tbl
GROUP BY handle_key
