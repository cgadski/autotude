-- Time/bc kill
WITH tbl AS (
    SELECT
        handle_key,
        time_bin,
        plane
    FROM players_wide
    NATURAL JOIN ladder_games
    WHERE team > 2
    GROUP BY handle_key, time_bin, plane
)

-- handle
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    0 AS stat,
    'stat' AS repr,
    false AS hidden
FROM tbl
GROUP BY handle_key

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    0 AS stat,
    'stat' AS repr,
    false AS hidden
FROM tbl GROUP BY handle_key, time_bin

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    0 AS stat,
    'stat' AS repr,
    false AS hidden
FROM tbl GROUP BY handle_key, plane

UNION ALL

-- handle, time, plane
SELECT
    handle_key,
    time_bin,
    plane,
    0 AS stat,
    'stat' AS repr,
    false AS hidden
FROM tbl
