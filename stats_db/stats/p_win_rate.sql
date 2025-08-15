-- Win rate
-- percentage
WITH
tbl AS (
    SELECT
        replay_key,
        handle_key,
        r.time_bin,
        plane,
        1. AS n_games,
        iif(p.team = r.winner, 1., 0.) AS wins
    FROM players_wide p
    NATURAL JOIN handles
    JOIN replays_wide r USING (replay_key)
    JOIN ladder_games USING (replay_key)
    WHERE p.team > 2
    GROUP BY replay_key, handle_key
)

-- handle, time, plane
SELECT
    handle_key,
    time_bin,
    plane,
    sum(wins) / sum(n_games) AS stat,
    cast(cast(sum(wins) as int) as text) || '/' ||
    cast(cast(sum(n_games) as int) as text) AS detail
FROM tbl GROUP BY handle_key, time_bin, plane
HAVING sum(n_games) >= 20

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(wins) / sum(n_games) AS stat,
    cast(cast(sum(wins) as int) as text) || '/' ||
    cast(cast(sum(n_games) as int) as text) AS detail
FROM tbl GROUP BY handle_key, time_bin
HAVING sum(n_games) >= 25

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(wins) / sum(n_games) AS stat,
    cast(cast(sum(wins) as int) as text) || '/' ||
    cast(cast(sum(n_games) as int) as text) AS detail
FROM tbl GROUP BY handle_key, plane
HAVING sum(n_games) >= 50

UNION ALL

-- handle
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(wins) / sum(n_games) AS stat,
    cast(cast(sum(wins) as int) as text) || '/' ||
    cast(cast(sum(n_games) as int) as text) AS detail
FROM tbl
GROUP BY handle_key
HAVING sum(n_games) >= 100
