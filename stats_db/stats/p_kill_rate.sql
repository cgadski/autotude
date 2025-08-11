-- Time alive per kill
-- duration_fine reverse
WITH
time_alive AS (
    SELECT handle, cast(sum(ticks_alive) AS real) AS time_alive
    FROM ladder_games
    NATURAL JOIN players
    NATURAL JOIN handles
    GROUP BY handle
),
n_kills AS (
    SELECT who_killed AS handle, count() AS kills
    FROM ladder_games
    NATURAL JOIN named_kills
    GROUP BY handle
)
SELECT
    handle,
    NULL AS time_bin,
    NULL AS plane,
    time_alive / kills AS stat
FROM time_alive
JOIN n_kills USING (handle)
WHERE kills > 1000
GROUP BY handle
ORDER BY stat
