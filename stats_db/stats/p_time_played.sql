-- Time played
-- duration
WITH
tbl AS (
    SELECT
        handle_key,
        time_bin,
        plane,
        sum(duration) AS time_played
    FROM players_wide
    NATURAL JOIN ladder_games
    NATURAL JOIN replays
    WHERE team > 2
    GROUP BY handle_key, time_bin, plane
)

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
