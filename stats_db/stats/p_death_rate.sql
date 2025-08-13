-- Time per death
-- duration_fine
WITH
n_deaths AS (
    SELECT who_died AS handle, count() AS kills
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
