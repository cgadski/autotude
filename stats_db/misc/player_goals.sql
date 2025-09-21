WITH play_time AS  (
    SELECT name, SUM(ticks_alive) / (30. * 60) AS minutes_alive
    FROM players
    NATURAL JOIN handles
    GROUP BY name
),
total_goals AS (
    SELECT name, COUNT() AS n_goals
    FROM goals
    NATURAL JOIN players
    NATURAL JOIN handles
    GROUP BY name
)
SELECT
    name,
    n_goals,
    printf('%.1f', minutes_alive / 60.) AS hours_alive,
    printf('%.2f', 10. * n_goals / minutes_alive) AS per_10
FROM handles
NATURAL JOIN play_time
NATURAL JOIN total_goals
GROUP BY name
ORDER BY n_goals DESC;
