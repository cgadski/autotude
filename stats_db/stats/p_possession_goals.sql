-- Goals/10 pos
WITH tbl AS (
    SELECT
        handle_key,
        time_bin_key,
        plane,
        cast(sum(goals) AS real) as goals,
        sum(time_with_ball) as time_with_ball
    FROM players_wide
    GROUP BY handle_key, time_bin_key, plane
)

-- handle
SELECT
    handle_key,
    NULL AS time_bin_key,
    NULL AS plane,
    sum(goals) / (sum(time_with_ball) / (30 * 60)) * 10 AS stat,
    printf('%.1f', sum(goals) / (sum(time_with_ball) / (30 * 60)) * 10)
    || ' | ' || cast(sum(goals) as int) || '#G in ' || sum(time_with_ball) || 'dc' AS repr,
    sum(time_with_ball) < 30 * 60 * 30 AS hidden
FROM tbl
GROUP BY handle_key

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin_key,
    NULL AS plane,
    sum(goals) / (sum(time_with_ball) / (30 * 60)) * 10 AS stat,
    printf('%.1f', sum(goals) / (sum(time_with_ball) / (30 * 60)) * 10)
    || ' | ' || cast(sum(goals) as int) || '#G in ' || sum(time_with_ball) || 'dc' AS repr,
    sum(time_with_ball) < 30 * 60 * 30 AS hidden
FROM tbl GROUP BY handle_key, time_bin_key

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin_key,
    plane,
    sum(goals) / (sum(time_with_ball) / (30 * 60)) * 10 AS stat,
    printf('%.1f', sum(goals) / (sum(time_with_ball) / (30 * 60)) * 10)
    || ' | ' || cast(sum(goals) as int) || '#G in ' || sum(time_with_ball) || 'dc' AS repr,
    sum(time_with_ball) < 30 * 60 * 30 AS hidden
FROM tbl GROUP BY handle_key, plane

UNION ALL

-- handle, time, plane
SELECT
    handle_key,
    time_bin_key,
    plane,
    sum(goals) / (sum(time_with_ball) / (30 * 60)) * 10 AS stat,
    printf('%.1f', sum(goals) / (sum(time_with_ball) / (30 * 60)) * 10)
    || ' | ' || cast(sum(goals) as int) || '#G in ' || sum(time_with_ball) || 'dc' AS repr,
    sum(time_with_ball) < 30 * 60 * 30 AS hidden
FROM tbl GROUP BY handle_key, time_bin_key, plane
