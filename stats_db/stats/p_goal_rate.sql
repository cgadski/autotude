-- Time alive per goal
-- duration reverse
WITH
time_alive AS (
    SELECT
        handle,
        sum(ticks_alive) AS time_alive
    FROM ladder_games
    NATURAL JOIN players
    NATURAL JOIN handles
    GROUP BY handle
),
n_goals AS (
    SELECT
        handle,
        count() AS goals
    FROM ladder_games
    NATURAL JOIN goals
    NATURAL JOIN players
    NATURAL JOIN handles
    GROUP BY handle
)
SELECT
    handle,
    NULl AS time_bin,
    NULL AS plane,
    time_alive / goals AS stat
FROM time_alive
JOIN n_goals USING (handle)
WHERE goals > 50
GROUP BY handle
ORDER BY stat
