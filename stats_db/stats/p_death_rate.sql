-- Time per death
-- duration_fine
WITH
tbl AS (
    SELECT
        handle_key,
        time_bin,
        plane,
        cast(sum(deaths) AS REAL) AS deaths,
        cast(sum(time_alive) AS REAL) AS time_alive
    FROM players_wide
    NATURAL JOIN ladder_games
    WHERE team > 2
    GROUP BY handle_key, time_bin, plane
)

-- handle, time, plane
SELECT
    handle_key,
    time_bin,
    plane,
    sum(time_alive) / sum(deaths) || ' | '
    || sum(deaths) || ' deaths',
    false AS hidden
FROM tbl GROUP BY handle_key, time_bin, plane

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(time_alive) / sum(deaths) AS stat,
    false AS hidden
FROM tbl GROUP BY handle_key, time_bin

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(time_alive) / sum(deaths) AS stat,
    false AS hidden
FROM tbl GROUP BY handle_key, plane

UNION ALL

-- handle
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(time_alive) / sum(deaths) AS stat,
    false AS hidden
FROM tbl GROUP BY handle_key
