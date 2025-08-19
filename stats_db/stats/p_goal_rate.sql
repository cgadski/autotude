-- G/10
WITH tbl AS (
    SELECT
        handle_key,
        time_bin,
        plane,
        sum(goals) as goals,
        sum(time_alive) as time_alive
    FROM players_wide
    GROUP BY handle_key, time_bin, plane
)

-- handle
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(goals) / (sum(time_alive) / (30 * 60)) * 10 AS stat,
    printf('%.1f', sum(goals) / (sum(time_alive) / (30 * 60)) * 10)
    || ' | ' || sum(goals) || ' goals in ' || sum(time_alive) || 'dc' AS repr,
    sum(time_alive) < 30 * 60 * 60 AS hidden
FROM tbl
GROUP BY handle_key

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(goals) / (sum(time_alive) / (30 * 60)) * 10 AS stat,
    printf('%.1f', sum(goals) / (sum(time_alive) / (30 * 60)) * 10)
    || ' | ' || sum(goals) || ' goals in ' || sum(time_alive) || 'dc' AS repr,
    sum(time_alive) < 30 * 60 * 60 AS hidden
FROM tbl GROUP BY handle_key, time_bin

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(goals) / (sum(time_alive) / (30 * 60)) * 10 AS stat,
    printf('%.1f', sum(goals) / (sum(time_alive) / (30 * 60)) * 10)
    || ' | ' || sum(goals) || ' goals in ' || sum(time_alive) || 'dc' AS repr,
    sum(time_alive) < 30 * 60 * 60 AS hidden
FROM tbl GROUP BY handle_key, plane

UNION ALL

-- handle, time, plane
SELECT
    handle_key,
    time_bin,
    plane,
    sum(goals) / (sum(time_alive) / (30 * 60)) * 10 AS stat,
    printf('%.1f', sum(goals) / (sum(time_alive) / (30 * 60)) * 10)
    || ' | ' || sum(goals) || ' goals in ' || sum(time_alive) || 'dc' AS repr,
    sum(time_alive) < 30 * 60 * 60 AS hidden
FROM tbl GROUP BY handle_key, time_bin, plane
