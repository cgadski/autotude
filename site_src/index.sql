WITH good_games AS (
    SELECT *, count() AS n_goals 
    FROM replays NATURAL JOIN goals 
    WHERE name LIKE "%jaxx%" OR name LIKE "%raxx%" 
    GROUP BY name, replay_id HAVING n_goals >= 5
)
SELECT replay_id, time, map, path, ticks,
    JSON_GROUP_ARRAY(JSON_ARRAY(name, team)) AS players
FROM replays NATURAL JOIN players 
WHERE replay_id IN (SELECT replay_id FROM good_games)
GROUP BY replay_id 
ORDER BY time DESC;
