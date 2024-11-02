WITH good_games AS (
    SELECT *
    FROM replays
    ORDER BY -time LIMIT 100
)
SELECT replay_id, time, map, path, ticks,
    JSON_GROUP_ARRAY(JSON_ARRAY(name, team)) AS players
FROM good_games NATURAL JOIN players
GROUP BY replay_id
ORDER BY time DESC;
