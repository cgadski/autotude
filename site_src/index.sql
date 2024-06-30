SELECT replay_id, time, map, path, ticks,
    JSON_GROUP_ARRAY(JSON_ARRAY(name, team)) AS players
FROM replays NATURAL JOIN players 
WHERE map = 'ball_4cliff'
GROUP BY replay_id 
HAVING SUM(name = 'geom') > 0 
    -- AND SUM(name LIKE '%ken') > 0
    AND SUM(name LIKE 'Bot %') = 0
ORDER BY time DESC;
