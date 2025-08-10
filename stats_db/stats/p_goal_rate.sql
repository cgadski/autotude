-- Time alive per goal
-- duration reverse
WITH
time_alive AS (
    SELECT name, cast(sum(ticks_alive) AS real) AS time_alive
    FROM ladder_games
    NATURAL JOIN players
    NATURAL JOIN names
    GROUP BY name
),
n_goals AS (
    SELECT name, count() AS goals
    FROM ladder_games
    NATURAL JOIN goals
    NATURAL JOIN players
    NATURAL JOIN names
    GROUP BY name
)
SELECT
    name,
    time_alive / goals AS stat
FROM time_alive
JOIN n_goals USING (name)
WHERE goals > 50
GROUP BY name
ORDER BY stat
