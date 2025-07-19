WITH
total_games AS (
    SELECT map, COUNT() as ct
    FROM replays NATURAL JOIN ladder_games
    GROUP BY map
)
SELECT
    map,
    COUNT() FILTER (WHERE team = 3) AS left_goals,
    COUNT() FILTER (WHERE team = 4) AS right_goals
FROM ladder_games
NATURAL JOIN replays
NATURAL JOIN goals
JOIN total_games USING (map)
GROUP BY map
ORDER BY total_games.ct DESC;
