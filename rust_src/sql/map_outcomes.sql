WITH
total_games AS (
    SELECT map, COUNT() as ct
    FROM replays NATURAL JOIN ladder_games
    GROUP BY map
)
SELECT
map,
COUNT() FILTER (WHERE winner = 3) AS left_wins,
COUNT() FILTER (WHERE winner = 4) AS right_wins
FROM replays NATURAL JOIN ladder_games
NATURAL JOIN outcomes
JOIN total_games USING (map)
GROUP BY map
ORDER BY total_games.ct DESC;
