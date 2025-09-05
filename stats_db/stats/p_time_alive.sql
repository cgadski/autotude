-- Time played
WITH tbl AS (
    SELECT
        handle_key,
        time_bin,
        plane,
        time_alive
    FROM time_alive
)

-- handle
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(time_alive) / (30 * 60 * 60) AS stat,
    sum(time_alive) || "d" AS repr,
    false AS hidden
FROM tbl GROUP BY handle_key

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(time_alive) / (30 * 60 * 60) AS stat,
    sum(time_alive) || "d" AS repr,
    false AS hidden
FROM tbl GROUP BY handle_key, time_bin

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(time_alive) / (30 * 60 * 60) AS stat,
    sum(time_alive) || "d" AS repr,
    false AS hidden
FROM tbl GROUP BY handle_key, plane

UNION ALL

-- handle, time, plane
SELECT
    handle_key,
    time_bin,
    plane,
    sum(time_alive) / (30 * 60 * 60) AS stat,
    sum(time_alive) || "d" AS repr,
    false AS hidden
FROM tbl GROUP BY handle_key, time_bin, plane
