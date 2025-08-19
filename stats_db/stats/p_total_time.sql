-- Time played
WITH tbl AS (
    SELECT
        handle_key,
        time_bin,
        plane,
        sum(time_alive) AS time_alive,
        cast(sum(duration) AS real) AS game_duration
    FROM players_wide
    JOIN replays USING (replay_key)
    GROUP BY handle_key, time_bin, plane
)

-- handle
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(time_alive) / sum(game_duration) AS stat,
    format('%.2f', sum(time_alive) / sum(game_duration)) || ' | ' || sum(time_alive) || 'd ' || sum(game_duration) || 'd' AS repr,
    sum(time_alive) < 30 * 60 * 60 AS hidden
FROM tbl
GROUP BY handle_key

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(time_alive) / (30 * 60 * 60) AS stat,
    sum(time_alive) || "d" AS repr,
    sum(time_alive) < 30 * 60 * 60 AS hidden
FROM tbl GROUP BY handle_key, time_bin

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(time_alive) / (30 * 60 * 60) AS stat,
    sum(time_alive) || "d" AS repr,
    sum(time_alive) < 30 * 60 * 60 AS hidden
FROM tbl GROUP BY handle_key, plane

UNION ALL

-- handle, time, plane
SELECT
    handle_key,
    time_bin,
    plane,
    sum(time_alive) / (30 * 60 * 60) AS stat,
    sum(time_alive) || "d" AS repr,
    sum(time_alive) < 30 * 60 * 60 AS hidden
FROM tbl GROUP BY handle_key, time_bin, plane
