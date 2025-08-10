-- Time alive per goal
-- duration reverse
WITH
time_alive AS (
    SELECT
        handle,
        cast(sum(ticks_alive) AS real) AS time_alive
    FROM ladder_games
    NATURAL JOIN players
    NATURAL JOIN handles
    GROUP BY name
),
n_goals AS (
    SELECT handle, count() AS goals
    FROM ladder_games
    NATURAL JOIN goals
    NATURAL JOIN players
    NATURAL JOIN handles
    GROUP BY name
)
SELECT
    handle,
    time_alive / goals AS stat
FROM time_alive
JOIN n_goals USING (name)
WHERE goals > 50
GROUP BY name
ORDER BY stat
