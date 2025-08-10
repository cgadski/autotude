-- Time alive per kill
-- duration_fine reverse
WITH
time_alive AS (
    SELECT name, cast(sum(ticks_alive) AS real) AS time_alive
    FROM ladder_games
    NATURAL JOIN players
    NATURAL JOIN names
    GROUP BY name
),
n_kills AS (
    SELECT who_killed AS name, count() AS kills
    FROM ladder_games
    NATURAL JOIN named_kills
    GROUP BY name
)
SELECT
    name,
    time_alive / kills AS stat
FROM time_alive
JOIN n_kills USING (name)
WHERE kills > 1000
GROUP BY name
ORDER BY stat
