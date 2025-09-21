WITH
total_games AS (
    SELECT map, COUNT() as ct
    FROM replays NATURAL JOIN ladder_games
    GROUP BY map
)
SELECT
map,
COUNT() FILTER (WHERE winner = 3) AS left_wins,
COUNT() FILTER (WHERE winner = 4) AS right_wins,
COUNT() AS total_outcomes,
(CAST(COUNT() FILTER (WHERE winner = 3) AS REAL) / COUNT() - 0.5) /
SQRT(0.25 / COUNT()) AS z_statistic
FROM replays NATURAL JOIN ladder_games
NATURAL JOIN outcomes
JOIN total_games USING (map)
GROUP BY map
ORDER BY total_games.ct DESC;
