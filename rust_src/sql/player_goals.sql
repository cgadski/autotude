WITH play_time AS  (
    SELECT name, SUM(ticks_alive) / (30. * 60) AS minutes_alive
    FROM players
    NATURAL JOIN names
    GROUP BY name
),
total_goals AS (
    SELECT name, COUNT() AS n_goals
    FROM goals
    NATURAL JOIN players
    NATURAL JOIN names
    GROUP BY name
)
SELECT name, 10. * n_goals / minutes_alive AS per_10
FROM names
NATURAL JOIN play_time
NATURAL JOIN total_goals
GROUP BY name
ORDER BY per_10 DESC;
