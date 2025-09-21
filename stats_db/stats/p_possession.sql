-- Pos
WITH tbl AS (
    SELECT
        handle_key,
        time_bin,
        plane,
        cast(sum(time_alive) AS real) AS time_alive,
        cast(sum(time_with_ball) AS real) AS time_with_ball
    FROM players_wide
    GROUP BY handle_key, time_bin, plane
)

-- handle
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(time_with_ball) / sum(time_alive) AS stat,
    printf('%.2f', sum(time_with_ball) / sum(time_alive))
    || ' | ' || sum(time_with_ball) || 'd : '
    || sum(time_alive) || 'dc' AS repr,
    sum(time_alive) < 30 * 60 * 60 AS hidden
FROM tbl
GROUP BY handle_key

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(time_with_ball) / sum(time_alive) AS stat,
    printf('%.2f', sum(time_with_ball) / sum(time_alive))
    || ' | ' || sum(time_with_ball) || 'd : '
    || sum(time_alive) || 'dc' AS repr,
    sum(time_alive) < 30 * 60 * 60 AS hidden
FROM tbl GROUP BY handle_key, time_bin

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(time_with_ball) / sum(time_alive) AS stat,
    printf('%.2f', sum(time_with_ball) / sum(time_alive))
    || ' | ' || sum(time_with_ball) || 'd : '
    || sum(time_alive) || 'dc' AS repr,
    sum(time_alive) < 30 * 60 * 60 AS hidden
FROM tbl GROUP BY handle_key, plane

UNION ALL

-- handle, time, plane
SELECT
    handle_key,
    time_bin,
    plane,
    sum(time_with_ball) / sum(time_alive) AS stat,
    printf('%.2f', sum(time_with_ball) / sum(time_alive))
    || ' | ' || sum(time_with_ball) || 'd : '
    || sum(time_alive) || 'dc' AS repr,
    sum(time_alive) < 30 * 60 * 60 AS hidden
FROM tbl GROUP BY handle_key, time_bin, plane
