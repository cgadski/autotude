WITH RECURSIVE
players_by_stem AS (
    SELECT stem, map, COUNT(DISTINCT vapor) AS n_players
    FROM replays
    NATURAL JOIN players
    WHERE team >= 3
    GROUP BY stem
),
real_games AS (
    SELECT stem
    FROM replays
    NATURAL JOIN players_by_stem
    WHERE duration > 30 * 120 -- two minutes
    AND n_players == 8
    AND map != "lobby_4ball"
),
goals_by_map AS (
    SELECT map, count() AS total_goals
    FROM goals
    NATURAL JOIN replays
    NATURAL JOIN real_games
    GROUP BY map
)
SELECT map, team, CAST(count() AS FLOAT) / total_goals, total_goals
FROM goals
NATURAL JOIN replays
NATURAL JOIN real_games
JOIN goals_by_map USING (map)
WHERE team == 3
GROUP BY map, team
ORDER BY total_goals DESC, map, team
LIMIT 20;
